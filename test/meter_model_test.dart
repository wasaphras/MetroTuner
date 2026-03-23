import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/metronome/metronome_models.dart';

void main() {
  group('Meter', () {
    test('rejects invalid beats per bar', () {
      expect(() => Meter(0, 4), throwsArgumentError);
      expect(() => Meter(17, 4), throwsArgumentError);
    });

    test('rejects invalid denominator', () {
      expect(() => Meter(4, 3), throwsArgumentError);
      expect(() => Meter(4, 32), throwsArgumentError);
    });

    test('equality by value', () {
      expect(Meter(4, 4), equals(Meter.fourFour));
      expect(Meter(5, 4) == Meter.fourFour, isFalse);
    });
  });
}
