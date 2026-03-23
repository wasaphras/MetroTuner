# Contributing

## The vibe

- Don’t be a jerk in issues/PRs. We’re all hobbyists here.
- Disagree with ideas, not with people.
- If you wouldn’t say it to someone at a jam session, maybe don’t type it.
- That’s it. No 10-page policy PDF.

## Before you code

- Peek at [README.md](README.md) and [plan.md](plan.md) so you know what this app is *trying* to be.
- Linter: [analysis_options.yaml](analysis_options.yaml) (`very_good_analysis`) — it’s strict; that’s on purpose.
- **Sketchy security / privacy thing?** Don’t post it publicly first. GitHub **Security** tab → private report, or ping the maintainer on GitHub. Everything else: [Issues](https://github.com/wasaphras/MetroTuner/issues).
- Templates: [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/) · [.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)

## Setup

1. [Flutter](https://docs.flutter.dev/get-started/install), stable channel. (Arch users: see README if system Flutter hates Gradle.)
2. `flutter pub get`
3. Before you open a PR:
   - `dart fix --apply` if you touched Dart
   - `flutter analyze` — **zero** problems please
   - `flutter test`
   - Touched **pitch math, BPM scheduling, or note mapping**? Also `flutter test --coverage` + `bash tool/verify_core_coverage.sh`

Integration tests need a device/emulator: [docs/testing.md](docs/testing.md).

## Style

- Copy the patterns in the files around your change.
- Smaller PRs = easier merges.
- Please don’t add dependencies that drag in analytics, ads, or “phone home” networking without a heads-up ([plan.md](plan.md) has the spirit of the thing).

## Commits

Loosely [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`. Example: `fix: metronome flash on beat 1`

## PRs

1. Branch off `main` unless we talked otherwise.
2. Say what you did and why.
3. Green analyze + tests.
4. Update tests when behavior changes.
5. **Never** commit keystores, real `key.properties`, API keys, or your home folder path. `.git/info/exclude` is your friend for local junk.

## Questions?

[Issues](https://github.com/wasaphras/MetroTuner/issues). Feature ideas, bugs, “how does X work” — all good.
