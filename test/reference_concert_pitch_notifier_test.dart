import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/features/settings/reference_concert_pitch_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReferenceConcertPitchNotifier.loadFromPrefs', () {
    test('defaults to true when no keys', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(referenceConcertPitchProvider.notifier).loadFromPrefs();
      expect(container.read(referenceConcertPitchProvider), isTrue);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool(kGeneralConcertA4PrefsKey), isTrue);
    });

    test('migrates from metronome_click_concert_a4 false', () async {
      SharedPreferences.setMockInitialValues({
        kMetronomeClickConcertA4PrefsKey: false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(referenceConcertPitchProvider.notifier).loadFromPrefs();
      expect(container.read(referenceConcertPitchProvider), isFalse);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool(kGeneralConcertA4PrefsKey), isFalse);
      expect(p.containsKey(kMetronomeClickConcertA4PrefsKey), isFalse);
    });

    test('general key wins over legacy metronome key', () async {
      SharedPreferences.setMockInitialValues({
        kGeneralConcertA4PrefsKey: true,
        kMetronomeClickConcertA4PrefsKey: false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(referenceConcertPitchProvider.notifier).loadFromPrefs();
      expect(container.read(referenceConcertPitchProvider), isTrue);
    });

    test('infers from legacy a4 hz when no bool keys', () async {
      SharedPreferences.setMockInitialValues({
        kMetronomeClickA4HzPrefsKey: 432.0,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(referenceConcertPitchProvider.notifier).loadFromPrefs();
      expect(container.read(referenceConcertPitchProvider), isFalse);
    });
  });

  group('setConcertA4', () {
    test('persists general key', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(referenceConcertPitchProvider.notifier).setConcertA4(
            concert: false,
          );
      expect(container.read(referenceConcertPitchProvider), isFalse);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool(kGeneralConcertA4PrefsKey), isFalse);
    });
  });
}
