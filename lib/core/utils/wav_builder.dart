import 'dart:typed_data';

/// PCM16（リトルエンディアン、非圧縮）の生データに44バイトのWAVヘッダーを
/// 付与し、再生・送信可能なWAVファイルのバイト列を組み立てる。
///
/// `GeminiSpeechInputService`が`record`パッケージの`startStream`で
/// メモリ上に蓄積したPCMチャンクをWAVファイルとしてGemini音声認識API
/// （[GeminiService.transcribe]、mimeType `audio/wav`）に渡すために使う。
/// `dart:io`のFile書き込みを経由しないため、Webを含む全プラットフォームで動く。
Uint8List buildWavBytes(
  List<int> pcmData, {
  int sampleRate = 16000,
  int channels = 1,
}) {
  const bitsPerSample = 16;
  final data = pcmData is Uint8List ? pcmData : Uint8List.fromList(pcmData);
  final dataLength = data.length;
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;

  final header = ByteData(44)
    ..setUint8(0, 0x52) // 'R'
    ..setUint8(1, 0x49) // 'I'
    ..setUint8(2, 0x46) // 'F'
    ..setUint8(3, 0x46) // 'F'
    ..setUint32(4, 36 + dataLength, Endian.little) // ChunkSize
    ..setUint8(8, 0x57) // 'W'
    ..setUint8(9, 0x41) // 'A'
    ..setUint8(10, 0x56) // 'V'
    ..setUint8(11, 0x45) // 'E'
    ..setUint8(12, 0x66) // 'f'
    ..setUint8(13, 0x6D) // 'm'
    ..setUint8(14, 0x74) // 't'
    ..setUint8(15, 0x20) // ' '
    ..setUint32(16, 16, Endian.little) // Subchunk1Size（PCMは16固定）
    ..setUint16(20, 1, Endian.little) // AudioFormat（1 = PCM）
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, byteRate, Endian.little)
    ..setUint16(32, blockAlign, Endian.little)
    ..setUint16(34, bitsPerSample, Endian.little)
    ..setUint8(36, 0x64) // 'd'
    ..setUint8(37, 0x61) // 'a'
    ..setUint8(38, 0x74) // 't'
    ..setUint8(39, 0x61) // 'a'
    ..setUint32(40, dataLength, Endian.little); // Subchunk2Size

  final bytes = Uint8List(44 + dataLength)
    ..setRange(0, 44, header.buffer.asUint8List())
    ..setRange(44, 44 + dataLength, data);
  return bytes;
}
