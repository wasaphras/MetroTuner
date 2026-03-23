import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/metronome/metronome_scheduler.dart';

void main() {
  group('MetronomeScheduler', () {
    test('beatIntervalMicros at 120 BPM is 500ms', () {
      expect(MetronomeScheduler.beatIntervalMicros(120), 500000);
    });

    test('delayUntilBeatMicros is zero for first beat at elapsed zero', () {
      expect(
        MetronomeScheduler.delayUntilBeatMicros(
          beatIndex: 0,
          bpm: 120,
          elapsedMicros: 0,
        ),
        0,
      );
    });

    test('delayUntilBeatMicros catches up when elapsed is late', () {
      expect(
        MetronomeScheduler.delayUntilBeatMicros(
          beatIndex: 1,
          bpm: 120,
          elapsedMicros: 600000,
        ),
        0,
      );
    });

    test('isDownbeat every N beats', () {
      expect(
        MetronomeScheduler.isDownbeat(beatIndex: 0, beatsPerBar: 4),
        true,
      );
      expect(
        MetronomeScheduler.isDownbeat(beatIndex: 3, beatsPerBar: 4),
        false,
      );
      expect(
        MetronomeScheduler.isDownbeat(beatIndex: 4, beatsPerBar: 4),
        true,
      );
    });

    test('clampBpm enforces range', () {
      expect(MetronomeScheduler.clampBpm(10), MetronomeScheduler.minBpm);
      expect(MetronomeScheduler.clampBpm(400), MetronomeScheduler.maxBpm);
      expect(MetronomeScheduler.clampBpm(100), 100);
    });

    test('delayUntilBeatMicros for later beat when on time', () {
      expect(
        MetronomeScheduler.delayUntilBeatMicros(
          beatIndex: 2,
          bpm: 120,
          elapsedMicros: 1000000,
        ),
        0,
      );
    });

    test('beatIntervalMicros at 60 BPM is one second', () {
      expect(MetronomeScheduler.beatIntervalMicros(60), 1000000);
    });

    test('isDownbeat with triple meter', () {
      expect(
        MetronomeScheduler.isDownbeat(beatIndex: 3, beatsPerBar: 3),
        true,
      );
      expect(
        MetronomeScheduler.isDownbeat(beatIndex: 1, beatsPerBar: 3),
        false,
      );
    });

    test('delayUntilBeatMicros with half-beat phase: first beat at T/2', () {
      const bpm = 120;
      final interval = MetronomeScheduler.beatIntervalMicros(bpm);
      final half = interval ~/ 2;
      expect(
        MetronomeScheduler.delayUntilBeatMicros(
          beatIndex: 0,
          bpm: bpm,
          elapsedMicros: 0,
          phaseOffsetMicros: half,
        ),
        half,
      );
    });

    test('delayUntilBeatMicros with phase: second beat waits one interval', () {
      const bpm = 120;
      final interval = MetronomeScheduler.beatIntervalMicros(bpm);
      final half = interval ~/ 2;
      expect(
        MetronomeScheduler.delayUntilBeatMicros(
          beatIndex: 1,
          bpm: bpm,
          elapsedMicros: half,
          phaseOffsetMicros: half,
        ),
        interval,
      );
    });

    test('pendulumSweep01 center at half interval', () {
      const interval = 500000;
      expect(
        MetronomeScheduler.pendulumSweep01(
          elapsedMicros: interval ~/ 2,
          beatIntervalMicros: interval,
        ),
        closeTo(0.5, 1e-9),
      );
      expect(
        MetronomeScheduler.pendulumSweep01(
          elapsedMicros: interval + interval ~/ 2,
          beatIntervalMicros: interval,
        ),
        closeTo(0.5, 1e-9),
      );
    });

    test('pendulumSweep01 alternates direction at beat boundaries', () {
      const interval = 500000;
      expect(
        MetronomeScheduler.pendulumSweep01(
          elapsedMicros: 0,
          beatIntervalMicros: interval,
        ),
        0,
      );
      // Start of beat 1 (R→L): position at right.
      expect(
        MetronomeScheduler.pendulumSweep01(
          elapsedMicros: interval,
          beatIntervalMicros: interval,
        ),
        1,
      );
    });
  });
}
