# MetroTuner — scratchpad / orientation

Personal hobby project: Flutter metronome + chromatic tuner. Privacy-ish by default — no network in the release APK, no analytics, mic only when you explicitly start the tuner.

---

## What’s actually in the app

**Metronome**

- BPM, time signatures, start/stop, tap tempo.
- Timing is “real” (monotonic clock + scheduled delays), not a UI timer pretending to be audio; clicks through SoLoud.
- Pretty beat sweep + flash on beats without melting the widget tree every frame.
- **Metronome sound** screen (from the Metronome tab): beat vs downbeat pitch, 440 vs 432 Hz, fake/analog waveforms, click length, echo/room vibes, preview that matches playback math.

**Tuner**

- `record` + YIN in Dart, ignores super quiet frames.
- Vertical chromatic strip (~C2–C6), cents + colors, big readouts.
- Strip snaps to **left or right** edge in Settings.
- Mic on but no pitch for a moment? Strip **holds** the last note instead of spasming; Stop resets.

**Shell**

- Dark theme, bottom nav, `IndexedStack` so tabs remember their state.
- Portrait-only (fight me).

**Android**

- Basically `RECORD_AUDIO` + paranoid network XML + backup off. No Firebase fanfic.

**Repo reality**

- **Android + iOS** = the point. **Web** = leftover playground. **Windows/macOS** = evicted.
- **Ship:** push tag `vX.Y.Z` matching `pubspec` version name → GitHub Actions builds **metrotuner-vX.Y.Z.apk**. iOS IPA = manual Mac adventure ([.github/workflows/release.yml](.github/workflows/release.yml), [docs/build_and_verify.md](docs/build_and_verify.md)).

---

## Stack (cheat sheet)

| | |
|--|--|
| UI | Flutter |
| State | Riverpod |
| Clicks | flutter_soloud |
| Mic | record + permission_handler |
| Pitch | YIN in `lib/core/pitch/pitch_yin.dart` |
| Lint | very_good_analysis |
| CI | Actions: test on push/PR, APK on tags |

---

## Folder tour

```
MetroTuner/
├── android/   ios/   web/     # web = optional
├── lib/       # features, core, ui
├── test/   integration_test/
├── tool/      # coverage script, keystore helper
├── docs/
├── .github/
├── plan.md   README.md   CONTRIBUTING.md
└── pubspec.yaml
```

Deep dive on audio: [docs/architecture.md](docs/architecture.md).

---

## Hard no

- Cloud accounts, ads, IAP, analytics/crash spam.
- Sneaky / background mic.
- Play Store as “the mission” (APK sideload / Releases is the vibe).

---

## Maybe someday

- **Metronome in the background** — keep ticking when the app is not in the foreground, with a **persistent notification** (or OS-appropriate media controls) so playback can be **stopped from there** without opening MetroTuner. Expect Android foreground-service / notification-channel work and iOS background-audio rules; still **zero promises** on timeline.
- Alternate tunings, fancy polyrhythm UI, tuner oscilloscope, whatever — same **zero promises**.

---

## Random facts for future me / contributors

| | |
|--|--|
| Branch | `main` |
| Remote | `git@github.com:wasaphras/MetroTuner.git` |
| Android id | `com.metrotuner` |

Arch Linux: see README if Gradle screams about Flutter in `/usr/lib`. Emulators: [docs/testing.md](docs/testing.md).

**Bad security news?** Don’t splash it in a public issue first — GitHub Security private report or private message. (Same text as README, sorry for duplicate.)

---

## Ancient history

All the original “Phase 0–9” milestones are in the past. The sections above are the living truth.

---

*Bump this file when something meaningful changes so nobody has to archaeology the git log.*
