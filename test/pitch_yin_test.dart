import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/pitch/pitch_yin.dart';

Float32List _sine({
  required double hz,
  required int sampleRate,
  required int n,
}) {
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    out[i] = 0.45 * math.sin(2 * math.pi * hz * i / sampleRate);
  }
  return out;
}

void main() {
  group('PitchYin', () {
    test('detects 440 Hz sine in long frame', () {
      const sr = 44100;
      final buf = _sine(hz: 440, sampleRate: sr, n: 8192);
      final f = PitchYin.estimateHz(buf, sr);
      expect(f, closeTo(440, 5));
    });

    test('detects 220 Hz sine', () {
      const sr = 44100;
      final buf = _sine(hz: 220, sampleRate: sr, n: 8192);
      final f = PitchYin.estimateHz(buf, sr);
      expect(f, closeTo(220, 5));
    });

    test('near-silence returns null', () {
      const sr = 44100;
      final buf = Float32List(4092);
      expect(PitchYin.estimateHz(buf, sr), isNull);
    });

    test('buffer shorter than eight samples returns null', () {
      expect(PitchYin.estimateHz(Float32List(4), 44100), isNull);
    });

    test('invalid search range returns null when tauMax <= tauMin', () {
      const sr = 44100;
      final buf = _sine(hz: 440, sampleRate: sr, n: 8192);
      expect(
        PitchYin.estimateHz(
          buf,
          sr,
          minHz: 15000,
          maxHz: 20000,
        ),
        isNull,
      );
    });
  });
}
