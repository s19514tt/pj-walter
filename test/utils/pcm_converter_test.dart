import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/utils/pcm_converter.dart';

/// int16サンプル列をPCM16(LE)のバイト列にする。
Uint8List pcm(List<int> samples) {
  final bytes = Uint8List(samples.length * 2);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < samples.length; i++) {
    view.setInt16(i * 2, samples[i], Endian.little);
  }
  return bytes;
}

/// PCM16(LE)のバイト列をint16サンプル列に戻す。
List<int> samplesOf(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  return [
    for (var i = 0; i < bytes.length ~/ 2; i++) view.getInt16(i * 2, Endian.little),
  ];
}

void main() {
  group('convertPcm16', () {
    test('同一レート・モノラルなら入力をそのまま返す', () {
      final input = pcm([100, -100, 200, -200]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 16000,
        sourceChannels: 1,
        targetSampleRate: 16000,
      );

      expect(identical(result, input), isTrue);
    });

    test('ステレオを各チャンネルの平均でモノラルにまとめる', () {
      // L/R交互のインターリーブ（L=100,R=200 / L=-100,R=-200）
      final input = pcm([100, 200, -100, -200]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 16000,
        sourceChannels: 2,
        targetSampleRate: 16000,
      );

      expect(samplesOf(result), [150, -150]);
    });

    test('48kHz→16kHzでサンプル数が1/3になる', () {
      final input = pcm(List<int>.generate(4800, (i) => i % 1000));

      final result = convertPcm16(
        input,
        sourceSampleRate: 48000,
        sourceChannels: 1,
        targetSampleRate: 16000,
      );

      expect(samplesOf(result), hasLength(1600));
    });

    test('ダウンサンプルは間引きではなく区間平均になる', () {
      // 48kHz→16kHzなので出力1サンプルにつき入力3サンプルを平均する
      final input = pcm([0, 30, 60, 300, 330, 360]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 48000,
        sourceChannels: 1,
        targetSampleRate: 16000,
      );

      expect(samplesOf(result), [30, 330]);
    });

    test('48kHzステレオを16kHzモノラルへ一度に変換できる', () {
      // 3フレーム×2ch。各フレームの平均は 10, 20, 30 → 平均20の1サンプルになる
      final input = pcm([0, 20, 10, 30, 20, 40]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 48000,
        sourceChannels: 2,
        targetSampleRate: 16000,
      );

      expect(samplesOf(result), [20]);
    });

    test('アップサンプルは線形補間で埋める', () {
      final input = pcm([0, 300]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 8000,
        sourceChannels: 1,
        targetSampleRate: 16000,
      );

      expect(samplesOf(result), [0, 150, 300, 300]);
    });

    test('出力サンプルが1つも作れない短さなら空を返す', () {
      final input = pcm([100]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 48000,
        sourceChannels: 1,
        targetSampleRate: 16000,
      );

      expect(result, isEmpty);
    });

    test('フレーム単位に満たない端数バイトは捨てられる', () {
      // 3バイト = 1サンプル(2バイト) + 端数1バイト
      final input = Uint8List.fromList([0x10, 0x00, 0x7F]);

      final result = convertPcm16(
        input,
        sourceSampleRate: 16000,
        sourceChannels: 2,
        targetSampleRate: 16000,
      );

      expect(result, isEmpty);
    });
  });
}
