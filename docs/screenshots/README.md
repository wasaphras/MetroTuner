# Screenshots and recordings

Store **screenshots** or short **screen recordings** here for the main [README](../../README.md).

## Current assets (referenced by the README)

| File | Description |
|------|-------------|
| `tuner.png` | Tuner tab — pitch strip, readouts, **Start**. |
| `metronome.png` | Metronome tab — tempo, time signature, **Metronome sound**, transport. |
| `settings.png` | Settings → General — accent color, concert pitch (440/432 Hz), pitch strip side. |

Use **PNG** or **WebP**. Keep file sizes reasonable for GitHub (compress if a capture is huge).

## Regenerating (Android emulator)

From the project root, with the app running on a device/emulator:

```bash
adb exec-out screencap -p > docs/screenshots/tuner.png
```

Navigate in the app, then repeat for other filenames. Use `adb shell wm size` if you need to tune `input tap` coordinates for navigation.
