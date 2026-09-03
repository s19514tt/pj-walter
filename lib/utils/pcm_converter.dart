import 'dart:typed_data';

/// PCM16（リトルエンディアン）の生データを、指定サンプルレートのモノラルに変換する。
///
/// `record`パッケージは要求した`RecordConfig`をハードウェア都合で書き換えることが
/// あり（例: Chromeは`AudioContext`の実サンプルレート48kHzが採用される、Androidは
/// 入力デバイスの対応チャンネル数に合わせてステレオになる）、PCMの生バイト列からは
/// その実フォーマットを判別できない。実フォーマットのままWAVヘッダーに16kHz/monoと
/// 書いてしまうと再生速度・音程がずれ、Geminiの文字起こしが意味不明な文章になる。
/// そのため`GeminiSpeechInputService`は実フォーマットをこの関数で16kHzモノラルに
/// 揃えてから[buildWavBytes]に渡す。
///
/// [sourceSampleRate]と[targetSampleRate]が等しくチャンネル数が1の場合は
/// 変換不要なので[pcmData]をそのまま返す。フレーム単位に満たない端数バイトは捨てる。
Uint8List convertPcm16(
  Uint8List pcmData, {
  required int sourceSampleRate,
  required int sourceChannels,
  required int targetSampleRate,
}) {
  assert(sourceSampleRate > 0 && targetSampleRate > 0 && sourceChannels > 0);
  if (sourceSampleRate == targetSampleRate && sourceChannels == 1) {
    return pcmData;
  }

  final mono = _downmixToMono(pcmData, sourceChannels);
  if (mono.isEmpty) return Uint8List(0);
  if (sourceSampleRate == targetSampleRate) return _toBytes(mono);

  return _toBytes(_resample(mono, sourceSampleRate, targetSampleRate));
}

/// インターリーブされた各チャンネルを平均してモノラル1チャンネルにまとめる。
Int16List _downmixToMono(Uint8List pcmData, int channels) {
  final source = ByteData.sublistView(pcmData);
  final bytesPerFrame = channels * 2;
  final frameCount = pcmData.length ~/ bytesPerFrame;
  final mono = Int16List(frameCount);

  for (var i = 0; i < frameCount; i++) {
    final base = i * bytesPerFrame;
    if (channels == 1) {
      mono[i] = source.getInt16(base, Endian.little);
      continue;
    }
    var sum = 0;
    for (var c = 0; c < channels; c++) {
      sum += source.getInt16(base + c * 2, Endian.little);
    }
    mono[i] = (sum / channels).round();
  }
  return mono;
}

Int16List _resample(Int16List mono, int sourceSampleRate, int targetSampleRate) {
  final ratio = sourceSampleRate / targetSampleRate;
  final outCount = (mono.length / ratio).floor();
  if (outCount == 0) return Int16List(0);

  final out = Int16List(outCount);
  if (targetSampleRate < sourceSampleRate) {
    // ダウンサンプル: 出力1サンプルが対応する入力区間を平均する。
    // 単純な間引きだと折り返し雑音が乗り認識精度が落ちるため、簡易ローパスを兼ねる。
    for (var i = 0; i < outCount; i++) {
      final start = (i * ratio).floor();
      var end = ((i + 1) * ratio).ceil();
      if (end > mono.length) end = mono.length;
      var sum = 0;
      for (var j = start; j < end; j++) {
        sum += mono[j];
      }
      out[i] = (sum / (end - start)).round();
    }
  } else {
    // アップサンプル: 線形補間で埋める。
    for (var i = 0; i < outCount; i++) {
      final pos = i * ratio;
      final index = pos.floor();
      final frac = pos - index;
      final current = mono[index];
      final next = index + 1 < mono.length ? mono[index + 1] : current;
      out[i] = (current + (next - current) * frac).round();
    }
  }
  return out;
}

Uint8List _toBytes(Int16List samples) {
  final bytes = Uint8List(samples.length * 2);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < samples.length; i++) {
    view.setInt16(i * 2, samples[i], Endian.little);
  }
  return bytes;
}
