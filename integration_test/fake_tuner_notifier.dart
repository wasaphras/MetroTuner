import 'package:metrotuner/features/tuner/tuner_notifier.dart';

/// Test double for integration tests: no microphone; toggles transport only.
class FakeTunerNotifier extends TunerNotifier {
  @override
  TunerState build() => TunerState.initial();

  @override
  Future<void> start() async {
    state = state.copyWith(
      isRunning: true,
      permissionDenied: false,
      startFailed: false,
      clearPitch: true,
    );
  }

  @override
  Future<void> stop() async {
    state = state.copyWith(
      isRunning: false,
      clearPitch: true,
    );
  }
}
