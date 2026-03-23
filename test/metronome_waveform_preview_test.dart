import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/audio/soloud_waveform_math.dart';
import 'package:metrotuner/features/settings/metronome_waveform_preview.dart';

void main() {
  group('soloudWaveformSampleRaw', () {
    test('square matches SoLoud half-planes', () {
      expect(soloudWaveformSampleRaw(0, 0.1), closeTo(-0.5, 1e-9));
      expect(soloudWaveformSampleRaw(0, 0.6), closeTo(0.5, 1e-9));
    });

    test('sine at quarter period', () {
      expect(
        soloudWaveformSampleRaw(2, 0.25),
        closeTo(0.5, 1e-9),
      );
    });

    test('jaws is silent after first quarter', () {
      expect(soloudWaveformSampleRaw(5, 0.3), closeTo(-0.5, 1e-9));
    });
  });

  group('metronomeWaveformSample', () {
    test('returns values in range for waveform indices 0–8', () {
      for (var i = 0; i <= 8; i++) {
        for (var k = 0; k < 20; k++) {
          final t = k / 20;
          final y = metronomeWaveformSample(i, t);
          expect(y, inInclusiveRange(-1.0, 1.0));
        }
      }
    });

    test('square wave differs from sine away from zero crossing', () {
      final sq = metronomeWaveformSample(0, 0.05);
      final sine = metronomeWaveformSample(2, 0.05);
      expect((sq - sine).abs(), greaterThan(0.1));
    });

    test('normalized is double SoLoud raw (clamped)', () {
      final raw = soloudWaveformSampleRaw(1, 0.2);
      expect(metronomeWaveformSample(1, 0.2), closeTo((raw * 2).clamp(-1.0, 1.0), 1e-9));
    });
  });

  group('fSaw series', () {
    test('matches direct formula at p=0.17', () {
      const p = 0.17;
      var f = 0.0;
      for (var i = 1; i < 15; i++) {
        if (i.isOdd) {
          f += (1.0 / (math.pi * i)) * math.sin(p * 2 * math.pi * i);
        } else {
          f -= (1.0 / (math.pi * i)) * math.sin(p * 2 * math.pi * i);
        }
      }
      expect(soloudWaveformSampleRaw(8, p), closeTo(f, 1e-9));
    });
  });
}
