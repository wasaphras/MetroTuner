# Screenshots and recordings

Store **screenshots** or short **screen recordings** here for the main [README](../../README.md).

## Current assets (referenced by the README)

| File | Description |
|------|-------------|
| `tuner.png` | Tuner tab — pitch strip, readouts, **Start**. |
| `metronome.png` | Metronome tab — tempo, time signature, **Metronome sound**, transport. |
| `settings.png` | Settings → General — accent, concert pitch (440/432 Hz), pitch strip side, version footer. |

Use **PNG** or **WebP**. Keep file sizes reasonable for GitHub (compress if a capture is huge).

## Regenerating (recommended: release APK + adb)

Use a **release** build so fonts and semantics match the store build.

```bash
flutter build apk --release
adb shell wm size 1080x2400
flutter install -d <deviceId>
adb shell monkey -p com.metrotuner.metrotuner -c android.intent.category.LAUNCHER 1
# Wait for UI, then:
adb exec-out screencap -p > docs/screenshots/tuner.png
adb shell input tap 810 2242   # Metronome tab (center of right half of bottom nav on 1080×2400)
sleep 2
adb exec-out screencap -p > docs/screenshots/metronome.png
adb shell input tap 270 2242   # Tuner tab
sleep 2
adb shell input tap 1017 137   # Settings (toolbar, adjust if your status bar differs)
sleep 2
adb exec-out screencap -p > docs/screenshots/settings.png
```

Re-dump the UI if taps miss: `adb shell uiautomator dump /sdcard/ui.xml` then `adb exec-out cat /sdcard/ui.xml`.

The [`test/readme_screenshots_test.dart`](../../test/readme_screenshots_test.dart) **smoke test** follows the same tab flow in widget tests (no golden PNG comparison).

## Regenerating (single capture)

With the app already on the right screen:

```bash
adb exec-out screencap -p > docs/screenshots/tuner.png
```
