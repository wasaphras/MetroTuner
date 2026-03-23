# MetroTuner

Hey — this is a **hobby** Flutter app I made: a **metronome** + **chromatic tuner** for Android and iOS. I wanted something that actually respects privacy (no analytics, no Play-services baggage, no network permission in the release APK) and only uses the mic when you tap **Start** on the tuner. If that sounds useful, cool; if not, also fine.

- **Code:** [github.com/wasaphras/MetroTuner](https://github.com/wasaphras/MetroTuner)
- **License:** [MIT](LICENSE) — do what you want, just don’t blame me if your cat eats the APK
- **Want to hack on it?** [CONTRIBUTING.md](CONTRIBUTING.md)

**Phones** are the real target (Android + iOS in the repo). **Releases** = signed **APKs** on GitHub. iOS is there for whenever someone has a Mac handy. **Web** folder = “I left the door unlocked if you wanna peek,” not a supported product.

**Features in a nutshell**

- Tuner: vertical pitch strip; stick it on the **left or right** in Settings (saved on your phone).
- Pick an **accent color** (presets or DIY RGB) — also local only.
- Metronome: BPM, meters, tap tempo, plus a whole **Metronome sound** screen (pitches, A4 vs 432 crowd, waveforms, echo-y stuff) from the Metronome tab.

## Screenshots

Toss pictures in [docs/screenshots/](docs/screenshots/) when you have them. No screenshot police.

## Privacy

- Release APK isn’t trying to talk to the internet — you can double-check with `aapt` ([docs/build_and_verify.md](docs/build_and_verify.md)).
- Mic = **only** after you hit **Start** on the tuner; background the app and it stops.
- No accounts, no cloud, no ads, no “please send us your soul” SDKs.

### If you find something scary

Security/privacy bug that could hurt people? Please **don’t** drop it in a public issue first. Use GitHub **Security → Report a vulnerability** if it’s there, or DM the maintainer through GitHub. Normal broken stuff → [Issues](https://github.com/wasaphras/MetroTuner/issues) is perfect.

### Android permission

| Permission | Why |
|------------|-----|
| `RECORD_AUDIO` | Tuner. Only after you start and maybe allow the OS prompt. |

Plus the usual “no cleartext, tight network config, backup off” Android hygiene. No Firebase circus.

## What you need

- [Flutter](https://docs.flutter.dev/get-started/install) (stable is fine)
- Android SDK and/or Xcode if you’re building for real devices

App stays **portrait**. Life’s too short for landscape metronomes (for now).

**Arch / CachyOS rant:** distro Flutter under `/usr/lib/flutter` is often owned by root and Gradle gets sad. Easiest fix: clone Flutter into `~`, put `~/flutter/bin` on `PATH`:

```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc   # or ~/.bashrc
source ~/.zshrc
flutter doctor
```

Then `which flutter` should be your home copy, not `/usr/bin/whatever`.

## Build & run

```bash
git clone git@github.com:wasaphras/MetroTuner.git
cd MetroTuner
flutter pub get
flutter analyze
flutter test
flutter run
```

| Target | Rough idea |
|--------|------------|
| Android emulator | `flutter emulators --launch …` then `flutter run` |
| Real Android | USB + dev mode → `flutter run` (best for mic feel) |
| iOS | Simulator/device + `flutter run -d …` |

More detail: [docs/testing.md](docs/testing.md).

**Ship an APK:** [docs/build_and_verify.md](docs/build_and_verify.md). Tag `v1.2.3` matching `pubspec.yaml` → CI spits out `metrotuner-v1.2.3.apk`. First time? There’s a [checklist](docs/build_and_verify.md#phase-9-maintainer-checklist) for keys & secrets.

### Coverage (when you touch the mathy bits)

```bash
flutter test --coverage
bash tool/verify_core_coverage.sh
```

Optional full local sweep (analyze, tests, and the core coverage gate if `coverage/lcov.info` exists): `bash tool/run_code_hygiene.sh`.

Pitch / scheduler / note math needs to stay ≥80% on the scoped files — [CONTRIBUTING.md](CONTRIBUTING.md).

### Sanity-check a release APK

```bash
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

You want `RECORD_AUDIO`, not surprise `INTERNET`.

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

| | SHA-256 (signing cert) |
|--|-------------------------|
| Current published key (verify your build matches) | `501d9fbd634c4a49916087c0f3cd4c8beeb206cdeb2bfc1dddaa9380759dd8c9` |

## Icons

Changed `assets/icon/app_icon.png`?

```bash
dart run flutter_launcher_icons
```

## Docs index

| | |
|--|--|
| What exists + random notes | [plan.md](plan.md) |
| How audio & YIN work | [docs/architecture.md](docs/architecture.md) |
| Emulators, integration tests | [docs/testing.md](docs/testing.md) |
| Keys, APK, GitHub Releases | [docs/build_and_verify.md](docs/build_and_verify.md) |

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) — the short version: be nice, run the tests, don’t commit your keystore. ✌️
