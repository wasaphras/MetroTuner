import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/audio/metronome_click_preset.dart';
import 'package:metrotuner/core/audio/metronome_click_sound_settings.dart';
import 'package:metrotuner/features/settings/metronome_click_settings.dart';
import 'package:metrotuner/features/settings/metronome_click_sound_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });
  group('metronomeClickSoundSettingsFromPrefs', () {
    test('uses defaults when all null', () {
      final s = metronomeClickSoundSettingsFromPrefs();
      expect(s.beatMidi, kMetronomeClickDefaultBeatMidi);
      expect(s.downbeatMidi, kMetronomeClickDefaultDownbeatMidi);
      expect(s.waveformIndex, 3);
      expect(s.preset, MetronomeClickPreset.classic);
      expect(s.clickDurationMs, 16);
      expect(s.reverb, 0);
      expect(s.echo, 0);
    });

    test('clamps beat MIDI to range', () {
      final s = metronomeClickSoundSettingsFromPrefs(beatMidi: 10);
      expect(s.beatMidi, kMetronomeClickMidiMin);
      final t = metronomeClickSoundSettingsFromPrefs(beatMidi: 200);
      expect(t.beatMidi, kMetronomeClickMidiMax);
    });

    test('clamps downbeat MIDI to range', () {
      final s = metronomeClickSoundSettingsFromPrefs(downbeatMidi: 10);
      expect(s.downbeatMidi, kMetronomeClickMidiMin);
    });

    test('rejects invalid waveform index', () {
      final s = metronomeClickSoundSettingsFromPrefs(waveformIndex: 99);
      expect(s.waveformIndex, 3);
    });

    test('clamps duration and effect amounts', () {
      final s = metronomeClickSoundSettingsFromPrefs(
        clickDurationMs: 1,
        reverb: 2,
        echo: -1,
      );
      expect(s.clickDurationMs, kMetronomeClickDurationMsMin);
      expect(s.reverb, 1);
      expect(s.echo, 0);
    });

    test('preset index maps to enum', () {
      final s = metronomeClickSoundSettingsFromPrefs(presetIndex: 2);
      expect(s.preset, MetronomeClickPreset.clap);
    });
  });

  group('metronomeClickSoundSettingsFromLegacyPrefs', () {
    test('maps base and offset to beat and downbeat', () {
      final s = metronomeClickSoundSettingsFromLegacyPrefs(
        baseMidi: 69,
        accentOffsetSemitones: -12,
      );
      expect(s.beatMidi, 69);
      expect(s.downbeatMidi, 57);
    });
  });

  group('inferConcertA4FromLegacyA4Hz', () {
    test('null defaults to concert', () {
      expect(inferConcertA4FromLegacyA4Hz(null), isTrue);
    });

    test('440 maps to concert', () {
      expect(inferConcertA4FromLegacyA4Hz(440), isTrue);
    });

    test('432 maps to alternate', () {
      expect(inferConcertA4FromLegacyA4Hz(432), isFalse);
    });
  });

  group('effectiveWaveformIndex', () {
    test('custom uses stored waveformIndex', () {
      const s = MetronomeClickSoundSettings(
        beatMidi: kMetronomeClickDefaultBeatMidi,
        downbeatMidi: kMetronomeClickDefaultDownbeatMidi,
        waveformIndex: 3,
        preset: MetronomeClickPreset.custom,
        clickDurationMs: 16,
        reverb: 0,
        echo: 0,
      );
      expect(s.effectiveWaveformIndex, 3);
    });

    test('bell uses sine index', () {
      const s = MetronomeClickSoundSettings(
        beatMidi: kMetronomeClickDefaultBeatMidi,
        downbeatMidi: kMetronomeClickDefaultDownbeatMidi,
        waveformIndex: 0,
        preset: MetronomeClickPreset.bell,
        clickDurationMs: 16,
        reverb: 0,
        echo: 0,
      );
      expect(s.effectiveWaveformIndex, MetronomeClickPreset.bell.waveformIndex);
    });
  });

  group('MetronomeClickSoundSettings Hz', () {
    test('beat and downbeat Hz at concert pitch', () {
      const s = MetronomeClickSoundSettings(
        beatMidi: 69,
        downbeatMidi: 57,
        waveformIndex: 3,
        preset: MetronomeClickPreset.classic,
        clickDurationMs: 16,
        reverb: 0,
        echo: 0,
      );
      expect(s.normalHz(440), closeTo(440, 0.1));
      expect(s.accentHz(440), closeTo(220, 0.1));
    });

    test('clamped downbeat MIDI respects range', () {
      const s = MetronomeClickSoundSettings(
        beatMidi: 48,
        downbeatMidi: 40,
        waveformIndex: 3,
        preset: MetronomeClickPreset.classic,
        clickDurationMs: 16,
        reverb: 0,
        echo: 0,
      );
      expect(s.clampedDownbeatMidi, kMetronomeClickMidiMin);
    });
  });

  testWidgets('MetronomeClickSoundSection shows preview buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetronomeClickSoundSection(),
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const Key('metronome_click_preview_normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metronome_click_preview_accent')),
      findsOneWidget,
    );
  });

  testWidgets('MetronomeClickSoundNotifier keeps reverb and echo when duration changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetronomeClickSoundSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MetronomeClickSoundSection)),
    );
    final notifier = container.read(metronomeClickSoundProvider.notifier);
    await notifier.setSettings(
      container.read(metronomeClickSoundProvider).copyWith(
            reverb: 0.4,
            echo: 0.35,
            clickDurationMs: 16,
          ),
    );
    await tester.pump();

    await notifier.setSettings(
      container.read(metronomeClickSoundProvider).copyWith(
            clickDurationMs: 55,
          ),
    );
    await tester.pump();

    final after = container.read(metronomeClickSoundProvider);
    expect(after.clampedClickDurationMs, 55);
    expect(after.reverb, 0.4);
    expect(after.echo, 0.35);
  });
}
