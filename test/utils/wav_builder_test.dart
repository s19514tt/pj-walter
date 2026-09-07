import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pj_walter/core/utils/wav_builder.dart';

void main() {
  group('buildWavBytes', () {
    test('44バイトのヘッダー＋PCMデータのバイト列を生成する', () {
      final pcm = Uint8List.fromList(List<int>.generate(2000, (i) => i % 256));

      final wav = buildWavBytes(pcm, sampleRate: 16000, channels: 1);

      expect(wav.length, 44 + pcm.length);
      // PCM本体がヘッダー直後にそのまま書き込まれている
      expect(wav.sublist(44), pcm);
    });

    test('RIFF/WAVE/fmt /dataの各識別子が正しい位置に書き込まれる', () {
      final pcm = Uint8List.fromList(List<int>.generate(10, (i) => i));
      final wav = buildWavBytes(pcm);

      String ascii(int start, int len) =>
          String.fromCharCodes(wav.sublist(start, start + len));

      expect(ascii(0, 4), 'RIFF');
      expect(ascii(8, 4), 'WAVE');
      expect(ascii(12, 4), 'fmt ');
      expect(ascii(36, 4), 'data');
    });

    test('16kHz mono 16bitの各フィールド値が正しい', () {
      final pcm = Uint8List.fromList(List<int>.generate(100, (i) => i));
      final wav = buildWavBytes(pcm, sampleRate: 16000, channels: 1);
      final byteData = ByteData.sublistView(wav);

      // ChunkSize = 36 + データ長
      expect(byteData.getUint32(4, Endian.little), 36 + pcm.length);
      // Subchunk1Size（fmtチャンク長）= 16固定（PCM）
      expect(byteData.getUint32(16, Endian.little), 16);
      // AudioFormat = 1（PCM）
      expect(byteData.getUint16(20, Endian.little), 1);
      // NumChannels
      expect(byteData.getUint16(22, Endian.little), 1);
      // SampleRate
      expect(byteData.getUint32(24, Endian.little), 16000);
      // ByteRate = SampleRate * NumChannels * BitsPerSample/8
      expect(byteData.getUint32(28, Endian.little), 16000 * 1 * 16 ~/ 8);
      // BlockAlign = NumChannels * BitsPerSample/8
      expect(byteData.getUint16(32, Endian.little), 1 * 16 ~/ 8);
      // BitsPerSample
      expect(byteData.getUint16(34, Endian.little), 16);
      // Subchunk2Size（データ長）
      expect(byteData.getUint32(40, Endian.little), pcm.length);
    });

    test('ステレオ・別サンプルレートでもByteRate/BlockAlignが正しく計算される', () {
      final pcm = Uint8List.fromList(List<int>.generate(400, (i) => i % 256));
      final wav = buildWavBytes(pcm, sampleRate: 44100, channels: 2);
      final byteData = ByteData.sublistView(wav);

      expect(byteData.getUint16(22, Endian.little), 2);
      expect(byteData.getUint32(24, Endian.little), 44100);
      expect(byteData.getUint32(28, Endian.little), 44100 * 2 * 16 ~/ 8);
      expect(byteData.getUint16(32, Endian.little), 2 * 16 ~/ 8);
    });

    test('空データでも44バイトのヘッダーのみ生成される', () {
      final wav = buildWavBytes(const []);

      expect(wav.length, 44);
      final byteData = ByteData.sublistView(wav);
      expect(byteData.getUint32(4, Endian.little), 36);
      expect(byteData.getUint32(40, Endian.little), 0);
    });
  });
}
