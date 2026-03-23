import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists concert A4 (440 Hz) vs alternate 432 Hz for tuner + metronome clicks.
class ReferenceConcertPitchNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  Future<void> loadFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final resolved = _resolveConcertFromPrefs(p);
      state = resolved;
      await p.setBool(kGeneralConcertA4PrefsKey, resolved);
      if (p.containsKey(kMetronomeClickConcertA4PrefsKey)) {
        await p.remove(kMetronomeClickConcertA4PrefsKey);
      }
    } on Object {
      // Tests / platforms without prefs: keep default.
    }
  }

  static bool _resolveConcertFromPrefs(SharedPreferences p) {
    if (p.containsKey(kGeneralConcertA4PrefsKey)) {
      return p.getBool(kGeneralConcertA4PrefsKey) ?? true;
    }
    if (p.containsKey(kMetronomeClickConcertA4PrefsKey)) {
      return p.getBool(kMetronomeClickConcertA4PrefsKey) ?? true;
    }
    final a4Hz = p.getDouble(kMetronomeClickA4HzPrefsKey);
    return inferConcertA4FromLegacyA4Hz(a4Hz);
  }

  Future<void> setConcertA4({required bool concert}) async {
    state = concert;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(kGeneralConcertA4PrefsKey, concert);
    } on Exception {
      // Best-effort only.
    }
  }
}

final referenceConcertPitchProvider =
    NotifierProvider<ReferenceConcertPitchNotifier, bool>(
      ReferenceConcertPitchNotifier.new,
    );
