# Local testing on a dev machine

This guide walks through running MetroTuner on your PC: **Android emulator** (virtual phone) or a **physical Android device**. The app targets **phones** (Android + iOS); use an emulator or device for accurate layout and behavior.

## Prerequisites

- Flutter installed and on your `PATH` (`flutter doctor`).
- Android SDK (often via Android Studio). Typical location: `~/Android/Sdk`.

Developers on Linux hosts can follow [Flutter install — Linux](https://docs.flutter.dev/get-started/install/linux)

## Put Android tools on your PATH (optional but convenient)

Add these to your shell profile (e.g. `~/.zshrc`):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

Reload the shell, then `which emulator` and `which adb` should resolve.

## Android emulator (virtual phone)

### 1. List available virtual devices

```bash
emulator -list-avds
```

If `emulator` is not found, use the full path:

```bash
"$HOME/Android/Sdk/emulator/emulator" -list-avds
```

### 2. Start an emulator

Replace `Your_AVD_Name` with a name from the previous step (for example `Medium_Phone_API_36.1`):

```bash
emulator -avd Your_AVD_Name &
```

If the window is blank or graphics fail, try software rendering:

```bash
emulator -avd Your_AVD_Name -gpu swiftshader_indirect &
```

Wait until the boot animation finishes and the home screen appears.

### 3. Confirm the device is visible

```bash
flutter devices
```

You should see something like `sdk gphone64 x86 64 (mobile) • emulator-5554`.

### 4. Run the app from the project root

```bash
cd /path/to/MetroTuner
flutter pub get
flutter run -d emulator-5554
```

If the device id differs, copy it from `flutter devices` and use `flutter run -d <device_id>`.

Hot reload: press `r` in the terminal where `flutter run` is active. Hot restart: `R`. Quit: `q`.

## Physical Android device

1. Enable **Developer options** and **USB debugging** on the phone.
2. Connect via USB and accept the debugging prompt on the device.
3. Run `adb devices` — the device should show as `device`.
4. Run `flutter run -d <device_id>`.

## Troubleshooting

| Issue | What to try |
|------|----------------|
| `emulator: command not found` | Add `$ANDROID_HOME/emulator` to `PATH` or use the full path to `emulator`. |
| Emulator slow | Close other heavy apps; use a smaller AVD; ensure KVM is enabled. |
| `No devices` | Start the emulator first; run `adb kill-server` then `adb start-server`. |

## Automated tests

From the repo root:

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
./tool/verify_core_coverage.sh
```

Core logic coverage (pitch + BPM scheduler helpers, excluding `tuner_audio_controller.dart`) must be **≥ 80%** line coverage; the script fails if not.

### Integration test (full app flow)

Runs on a **device or emulator** (not the VM-only `flutter_tester` host for plugin-heavy flows). Pick a target from `flutter devices`, then:

```bash
flutter test integration_test/ -d <device_id>
```

The integration harness exercises metronome start/stop and tuner start/stop (with a fake tuner notifier).

### Optional: duplicate code scan (local only)

CI does not run duplicate detection. The old open-source `dart_code_metrics` package is discontinued; [DCM](https://dcm.dev/) is a separate commercial CLI if you want Dart-aware checks.

For a quick text-based duplicate report, use [jscpd](https://github.com/kucherenko/jscpd) via Node and keep any wrapper script under `private/` (that directory is gitignored). Example (expect false positives on repetitive widget trees; raise `--min-lines` if needed):

```bash
npx --yes jscpd lib test --min-lines 8 --reporters console
```

### Release APK permissions audit

After `flutter build apk --release`, confirm only expected permissions are declared:

```bash
# Adjust path if using split APKs or a different output name
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

For a privacy build you want **`android.permission.RECORD_AUDIO`** only (no `INTERNET` in the release artifact). `aapt` is on your `PATH` via Android SDK build-tools (e.g. `$ANDROID_HOME/build-tools/<version>/aapt`).

## Manual verification (Phase 7)

Record what you ran before a release. Update the table when you test on a platform.

| Platform | Tested (date / version) |
|----------|---------------------------|
| GrapheneOS | — |
| Stock Android | — |
| iOS Simulator | — |
| Physical iOS | — |

## Related docs

- [Flutter install — Linux](https://docs.flutter.dev/get-started/install/linux)
- [Run Flutter on an emulator](https://docs.flutter.dev/get-started/install/macos#set-up-the-android-emulator)
