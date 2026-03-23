import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/pitch/note_math.dart';

void main() {
  group('NoteMath', () {
    test('A4 reference is 440 Hz', () {
      expect(NoteMath.midiToHz(69), closeTo(440, 0.001));
    });

    test('nearestNoteAndCents at exact A4', () {
      final r = NoteMath.nearestNoteAndCents(440);
      expect(r.label, 'A4');
      expect(r.cents, closeTo(0, 0.01));
    });

    test('known frequencies map to expected labels', () {
      final cases = <double, String>{
        261.63: 'C4',
        293.66: 'D4',
        329.63: 'E4',
        349.23: 'F4',
        392.0: 'G4',
      };
      for (final e in cases.entries) {
        final r = NoteMath.nearestNoteAndCents(e.key);
        expect(r.label, e.value, reason: 'for ${e.key} Hz');
      }
    });

    test('cents stay within fifty for nearby frequencies', () {
      final hz = 440 * math.pow(2, 0.3 / 12) as double;
      final r = NoteMath.nearestNoteAndCents(hz);
      expect(r.cents.abs() <= 50, isTrue);
    });

    test('midiToChromaticLabel matches chromatic names', () {
      expect(NoteMath.midiToChromaticLabel(36), 'C2');
      expect(NoteMath.midiToChromaticLabel(69), 'A4');
      expect(NoteMath.midiToChromaticLabel(72), 'C5');
      expect(NoteMath.midiToChromaticLabel(84), 'C6');
    });

    test('hzToMidi roundtrips midiToHz at A4', () {
      const midi = 69.0;
      final hz = NoteMath.midiToHz(midi);
      expect(NoteMath.hzToMidi(hz), closeTo(midi, 1e-9));
    });

    test('hzToMidi for C4', () {
      expect(NoteMath.hzToMidi(261.63), closeTo(60, 0.02));
    });

    test('nearestNoteAndCents clamps cents at boundary', () {
      final hz = 440 * math.pow(2, 55 / 1200) as double;
      final r = NoteMath.nearestNoteAndCents(hz);
      expect(r.cents.abs() <= 50, isTrue);
    });
  });
}
