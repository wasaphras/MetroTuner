import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/pitch/pitch_detector.dart';

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
  test('PitchDetector returns null for quiet frame', () {
    final buf = Float32List(2048);
    expect(PitchDetector.analyzeFrame(buf, 44100), isNull);
  });

  test('PitchDetector maps 440 Hz to A4', () {
    final buf = _sine(hz: 440, sampleRate: 44100, n: 4096);
    final r = PitchDetector.analyzeFrame(buf, 44100);
    expect(r, isNotNull);
    expect(r!.noteLabel, 'A4');
    expect(r.centsFromNearest.abs() < 10, isTrue);
    expect(r.rms > PitchDetector.minRms, isTrue);
  });

  test('PitchDetector returns null for empty frame', () {
    expect(PitchDetector.analyzeFrame(Float32List(0), 44100), isNull);
  });

  test('PitchDetector respects custom A4 reference', () {
    final buf = _sine(hz: 415, sampleRate: 44100, n: 4096);
    final r = PitchDetector.analyzeFrame(buf, 44100, a4Hz: 415);
    expect(r, isNotNull);
    expect(r!.noteLabel, 'A4');
    expect(r.centsFromNearest.abs() < 5, isTrue);
  });
}
