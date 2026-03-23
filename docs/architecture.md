# Architecture

## Audio engine

MetroTuner uses [SoLoud](https://pub.dev/packages/flutter_soloud) via a singleton facade, `AudioEngine` (`lib/core/audio/audio_engine.dart`).

### Initialization

- `bootstrapMetrotuner()` (`lib/bootstrap.dart`) runs `WidgetsFlutterBinding.ensureInitialized()` then `AudioEngine.instance.ensureInitialized()` before `runApp`. Shared by `main()` and integration tests so startup stays consistent.
- SoLoud is configured with a **512-sample** output buffer for lower click latency (smaller buffers increase underrun risk on slow devices).
- If native init fails (e.g. some test hosts), `AudioEngine` catches errors and leaves `_nativeReady == false`; playback becomes a no-op until a successful init (the app still runs).

### Shutdown and resources

- **Pause / hide:** `AppLifecycleListener` on `MetroTunerApp` stops the metronome and calls `TunerNotifier.stop()` so the microphone stream ends.
- **Detach:** On `onDetach`, the metronome is stopped, `tunerProvider` is **invalidated** (recorder disposed), and `AudioEngine.dispose()` releases SoLoud and waveform handles.

### Metronome output

- Two waveform sources (accent vs normal) are built with `loadWaveform` (no external sound assets). Timbre presets are **synthesized** waveforms (not sampled instruments); labels describe character, not acoustic fidelity.
- User settings: independent **beat** and **downbeat** MIDI pitch, **concert A4 (440 Hz) vs 432 Hz** toggle, timbre preset (or custom waveform), click duration, and Room + Echo (both map to one SoLoud echo filter). Stored in `MetronomeClickSoundSettings` (`lib/core/audio/metronome_click_sound_settings.dart`) via `SharedPreferences`. Legacy prefs (single base pitch + accent offset + A4 slider) migrate on load. After init, `AudioEngine.applyClickSoundSettings` updates frequencies (`NoteMath.midiToHz`), waveform shape (`SoLoud.setWaveform`), and waveform scale (fixed at 1; SoLoud’s non–super-wave path does not apply scale to the main oscillator). `playMetronomeClick` awaits `play()` with **per-instance volume** (0.35 beat / 0.55 downbeat), applies per-voice echo wet/delay/decay via `metronomeEchoParamsFromSliders` (`lib/core/audio/metronome_echo_mapping.dart`) when not on Web, and `scheduleStop` truncates the click to the chosen duration (downbeat uses a slightly longer gate). Mono sources use the echo filter for room/slapback; freeverb is not used because it requires stereo sources.
- Clicks are triggered from the metronome controller after `MetronomeScheduler` timing; playback is tied to the audio device clock, not `Timer.periodic`.
- On the metronome sound screen, **Wave preview** (`lib/features/settings/metronome_waveform_preview.dart`) draws the waveform **using the same math as SoLoud** `Misc::generateWaveform` (ported in `lib/core/audio/soloud_waveform_math.dart`) across the click length at the beat pitch, with cycle counts in the caption; a small **echo schematic** (qualitative) uses the same wet/delay/decay mapping as playback. Web builds do not apply the echo filter; the schematic is hidden when effects are inert.

## Metronome timing

Beats are **not** driven by `Timer.periodic`. The metronome controller uses a monotonic `Stopwatch` and, for each beat index, computes the delay until the next anchor time (`MetronomeScheduler` in `lib/core/metronome/metronome_scheduler.dart`). Each step schedules a **one-shot** `Future.delayed` so timing self-corrects if a callback runs late. Actual click playback goes through SoLoud’s `play()`, which aligns to the device audio buffer (see flutter_soloud metronome example discussion in upstream docs).

### Metronome UI (sweep and flash)

- **Pendulum / beat sweep** (`BeatSweepBar` in `lib/features/metronome/metronome_page.dart`): While transport is running, a **`Ticker`** drives a **local `setState`** on the paint layer only (~once per frame) so the dot moves smoothly. Position comes from `MetronomeNotifier.transportElapsedMicros` (the same `Stopwatch` as scheduling) and `MetronomeScheduler.pendulumSweep01`—**not** from Riverpod on every frame, so the rest of the tree is not notified each tick.
- **Beat flash:** `MetronomeState.beatFlashGeneration` increments on each audible beat; only the flash subtree `select`s that field. `MetronomePage` watches BPM, meter, and `isRunning` **without** `beatFlashGeneration` so the main layout does not rebuild every beat.
- **Tradeoff:** The sweep follows the Stopwatch timeline in Dart; click playback is scheduled with `Timer` + SoLoud’s buffer (see **Latency** above). Small UI vs. DAC latency is expected; use headphones on device to judge.

## State

Metronome transport and parameters are held in a Riverpod `Notifier` (`lib/features/metronome/metronome_notifier.dart`). The tuner uses `TunerNotifier` (`lib/features/tuner/tuner_notifier.dart`), which owns a `TunerAudioController` and exposes `pitchStream` results to the UI.

## Settings UI

The gear action opens a **full-screen** `SettingsPage` (`lib/features/settings/settings_page.dart`) pushed on the root navigator, with **General** only (accent color, tuner pitch-strip edge, and the privacy line). The layout scales to fit the viewport without scrolling. `openSettings` and `AppSettingsButton` live in that file; accent presets and `AccentColorSection` remain in `accent_settings.dart`.

Metronome click synthesis, dual pitch rows, A4 reference, effects, shape preview, and audio preview use `MetronomeClickSoundSettings` / `MetronomeClickSoundSection` on a **separate full-screen** `MetronomeSoundPage` (`lib/features/metronome/metronome_sound_page.dart`, scrollable) opened from **Metronome sound** on the Metronome tab (below transport, not from the gear menu). The main Metronome and Tuner tabs use viewport-filling `Column`/`Row` layouts with `Expanded`/`Flexible` (no scroll); **Settings** uses a `ConstrainedBox` without letterboxing the whole page.

## Latency

On real hardware, listen with headphones and adjust tempo; the 512-sample buffer targets low click latency. If you hear underruns (dropouts), try a less aggressive buffer size in a future iteration (see flutter_soloud docs).

## Pitch detection (tuner engine)

### Capture and framing

- `TunerAudioController` (`lib/core/pitch/tuner_audio_controller.dart`) uses the [`record`](https://pub.dev/packages/record) plugin with **PCM16** mono at **44.1 kHz** (default `RecordConfig` sample rate). `permission_handler` requests `Permission.microphone` before `startStream`.
- Incoming bytes are buffered into **2048** samples per frame; each frame is converted to float `[-1, 1]` and passed to `PitchDetector`.

### YIN algorithm

Implementation: `lib/core/pitch/pitch_yin.dart`.

- **Reference:** Cheveigné & Kawahara, *YIN, a fundamental frequency estimator for speech and music*, JASA 2002 ([DOI 10.1121/1.1458024](https://doi.org/10.1121/1.1458024)). The implementation follows the **cumulative mean normalized difference function (CMND)** and searches for a **local minimum** in τ (lag) space.
- **Search range:** τ is derived from `minHz` / `maxHz` and clamped to the buffer length so lag stays valid.
- **Why “first” minimum below threshold:** Scanning from **low τ** (high frequency) and taking the **first** local minimum under **0.2** reduces picking **subharmonics** (a global minimum often favors a lower pitch).
- **Refinement:** When the minimum is not at the search edge, a **parabolic** fit on the difference function around the best τ improves Hz resolution; if the denominator is near zero, the code falls back to `sampleRate / τ`.

### Gating and note mapping

- `PitchDetector` rejects frames whose **RMS** is below **0.002** (normalized float) so noisy/quiet input does not produce a pitch.
- `NoteMath` maps Hz to the nearest chromatic label and **cents** in **−50…+50** relative to that note (equal temperament, **A4 = 440 Hz** by default).

### Lifecycle

- `start()` begins streaming; `stop()` cancels the subscription and calls `AudioRecorder.stop()`; `dispose()` releases the recorder.
- The tuner **Start / Stop** controls when the mic is active; backgrounding the app stops metronome and tuner (user must tap **Start** again after returning).

## Lifecycle summary (app shell)

| Event | Metronome | Tuner / mic | Audio |
|-------|-----------|-------------|--------|
| Pause / hide | Stopped | Stopped | SoLoud stays up until detach |
| Detach | Stopped | Provider invalidated (recorder disposed) | `AudioEngine.dispose()` |

## App shell and navigation

- **Theme:** Dark-first `ThemeData` in `lib/ui/theme/app_theme.dart` (`MaterialApp` uses `ThemeMode.dark`).
- **Navigation:** `AppShell` (`lib/app_shell.dart`) uses a **bottom `NavigationBar`** and an **`IndexedStack`** so Metronome and Tuner remain in the tree (state preserved when switching tabs).
- **Tuner UI:** `TunerPage` + `PitchStrip` (`lib/features/tuner/`) show a chromatic ruler (MIDI 36–84, **C2–C6**), cent ticks, smooth motion from detected pitch, center “in tune” line, and readouts for note, cents, and Hz. While the mic is **on**, if a frame has no pitch (e.g. gating / silence), the strip **holds the last measured MIDI** instead of snapping to a fixed rest; **Stop** clears that hold back to the default rest position.

## Launcher icon

Source artwork: **`assets/icon/app_icon.png`** (1024×1024). Regenerate platform icons after changing it:

```bash
dart run flutter_launcher_icons
```
