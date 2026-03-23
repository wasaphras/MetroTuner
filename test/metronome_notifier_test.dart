import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/metronome/metronome_models.dart';
import 'package:metrotuner/core/metronome/metronome_scheduler.dart';
import 'package:metrotuner/features/metronome/metronome_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('MetronomeNotifier setBpm clamps to valid range', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(metronomeProvider.notifier)..setBpm(5);
    expect(
      container.read(metronomeProvider).bpm,
      MetronomeScheduler.minBpm,
    );
    notifier.setBpm(500);
    expect(
      container.read(metronomeProvider).bpm,
      MetronomeScheduler.maxBpm,
    );
  });

  test('MetronomeNotifier start then stop clears running flag', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(metronomeProvider.notifier)
      ..setBpm(240)
      ..start();
    expect(container.read(metronomeProvider).isRunning, true);
    container.read(metronomeProvider.notifier).stop();
    expect(container.read(metronomeProvider).isRunning, false);
  });

  test('MetronomeNotifier stop cancels pending beat; flash gen stable', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      try {
        container.read(metronomeProvider.notifier)
          ..setBpm(240)
          ..start();
        container.read(metronomeProvider.notifier).stop();
        final gen = container.read(metronomeProvider).beatFlashGeneration;
        async.elapse(const Duration(seconds: 10));
        expect(
          container.read(metronomeProvider).beatFlashGeneration,
          gen,
        );
      } finally {
        container.dispose();
      }
    });
  });

  test('MetronomeNotifier preset meter updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(metronomeProvider.notifier).setMeter(Meter.threeFour);
    expect(
      container.read(metronomeProvider).meter,
      Meter.threeFour,
    );
  });

  test('MetronomeNotifier custom meter updates state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(metronomeProvider.notifier).setMeter(Meter(5, 4));
    expect(
      container.read(metronomeProvider).meter,
      Meter(5, 4),
    );
    expect(
      container.read(metronomeProvider).meter.beatsPerBar,
      5,
    );
  });
}
