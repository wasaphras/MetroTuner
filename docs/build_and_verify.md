# Build, sign, and verify MetroTuner

This document covers **release** Android APKs and **release** iOS IPAs. Never commit keystores, passwords, or `key.properties`.

## Android — release APK

### 1. Prerequisites

- Flutter SDK (stable), Android SDK (`flutter doctor`).
- JDK (for `keytool` and `apksigner`).

### 2. Create a release keystore (once)

From the project root (or any secure directory):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Store `upload-keystore.jks` **outside the repo** or under `android/` only if listed in `.gitignore` (see `android/.gitignore` — use a unique name if you prefer).
- Remember the store password, key password, and alias.

### 3. `key.properties` (gitignored) — read this carefully

**The file must live at `android/key.properties`**, next to the `android/app` folder. Gradle does **not** read `key.properties` in the **project root**. If you created it in the wrong place, move it:

```bash
mv key.properties android/key.properties
```

Copy the example and edit the values (not the property names):

```bash
cp android/key.properties.example android/key.properties
```

#### What each line means

| Property | Plain English |
|----------|----------------|
| **`storePassword`** | Password for the **`.jks` file itself** — the *first* password `keytool` asked when you created the keystore. |
| **`keyPassword`** | Password for the **one private key inside** that file. `keytool` asks again at the end; if you pressed **Enter** to use the *same* password as the keystore, this is **the same string** as `storePassword`. **If you only ever chose one password, put that exact password on both `storePassword` and `keyPassword` lines.** |
| **`keyAlias`** | The **name** of the key — **not a password**. It must match the `-alias` you used (e.g. `upload` if you followed the command above). If you forgot: run `keytool -list -keystore /path/to/your.jks` (enter the keystore password) and read the **Alias name** line. |
| **`storeFile`** | Where the `.jks` file lives, as a path **relative to the `android/` folder**. Example: `upload-keystore.jks` means the file must be exactly `android/upload-keystore.jks`. If the file is somewhere else, adjust (e.g. `../keys/my.jks` from `android/`, or an absolute path). |

#### Minimal example (one password for everything)

If your password is `MySecret123`, your alias is `upload`, and the file is `android/upload-keystore.jks`:

```properties
storePassword=MySecret123
keyPassword=MySecret123
keyAlias=upload
storeFile=upload-keystore.jks
```

Do **not** leave the placeholder text from `key.properties.example` (`your-store-password`, `REPLACE_*`, etc.). Gradle will fail signing if passwords are wrong.

#### If the build still fails

1. **Wrong password / alias** — Run `keytool -list -v -keystore android/upload-keystore.jks` (use your real path). Enter the keystore password; confirm the **Alias name** matches `keyAlias` in `key.properties`.
2. **File not found** — Confirm the `.jks` exists at `android/<storeFile>` (or fix `storeFile`).
3. **Unrelated Flutter/Gradle error** — If the error mentions `kotlin-compiler-*.salive` or `flutter_tools/gradle`, that is a **Flutter SDK install/permissions** issue on your machine, not `key.properties`. Fix your Flutter install or use a user-writable SDK (see [README](../README.md)).

The Gradle build applies release signing only when `android/key.properties` exists and is valid. Without a valid `key.properties`, you can temporarily **rename or remove** `android/key.properties` so release builds use the debug key (for testing the rest of the toolchain).

### 4. Build release APK

```bash
flutter pub get
flutter build apk --release
```

Output (single APK):

`build/app/outputs/flutter-apk/app-release.apk`

### 5. Verify APK signature

Use `apksigner` from Android build-tools (version may differ):

```bash
"$ANDROID_HOME/build-tools/35.0.0/apksigner" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

You should see **Signer #1 certificate** and **SHA-256 digest** of the signing certificate. Publish that **SHA-256** fingerprint in the README and GitHub Release notes so users can confirm they have your build.

Compare with your keystore:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Look for **SHA256** under **Certificate fingerprints**.

### 6. APK permissions (release)

```bash
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Expect **`android.permission.RECORD_AUDIO`** for MetroTuner; release builds should **not** list `INTERNET` (see [README](../README.md)).

---

## iOS — release IPA

GitHub-hosted **Linux** runners cannot produce signed IPAs. Build on **macOS** with Xcode.

### 1. Signing in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Choose your **Team** (Apple Developer Program or personal team).
4. Ensure a unique **Bundle Identifier** if needed.

### 2. Build IPA

```bash
flutter build ipa --release
```

Artifacts appear under `build/ios/ipa/`. Distribution steps depend on whether you use Ad Hoc, Enterprise, or TestFlight; for sideloading without the App Store, many users rely on **AltStore**, **Sideloadly**, or similar — see their current documentation.

### 3. Publishing IPA on GitHub Releases

Upload the `.ipa` as a **manual** release asset if you build on a Mac. CI currently ships **Android APK only**. Do not commit provisioning profiles or `.p12` files.

---

## GitHub Actions — release APK on tags

Pushing a semver tag `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`) triggers [.github/workflows/release.yml](../.github/workflows/release.yml). The tag **must match** the version **before** `+` in [pubspec.yaml](../pubspec.yaml) (e.g. tag `v1.0.0` requires `version: 1.0.0+…`). The workflow builds a signed APK named `metrotuner-<tag>.apk` and **creates or updates** the GitHub **Release** for that tag (not only a lightweight tag).

**Tags vs Releases:** GitHub always offers **Source code** (zip/tar.gz) on tag pages; those are **not** the app. If the Release workflow fails (usually missing signing secrets), you will see a **tag** but **no** `.apk` under **Releases**. Tools such as **Obtanium** need the **`metrotuner-v*.apk`** asset on a successful Release.

**Retry without a new tag:** After adding the secrets below, open **Actions → Release → Run workflow**, enter the existing tag (e.g. `v1.0.0`), and run. You can also **Re-run failed jobs** on the run that was triggered by the tag push.

Required **repository secrets** (names only):

| Secret | Purpose |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias (e.g. `upload`) |

The workflow writes `android/key.properties` and the keystore file during the job; they are **not** committed.

---

## Published release fingerprint

When you have a stable release key, add its **SHA-256** certificate fingerprint here and in [README.md](../README.md):

| Release | SHA-256 (certificate) |
|---------|------------------------|
| Current release key (local signed APK) | `501d9fbd634c4a49916087c0f3cd4c8beeb206cdeb2bfc1dddaa9380759dd8c9` |

## Tagging a version (e.g. `v1.0.0`)

1. Ensure `main` is green (`flutter analyze`, `flutter test`, coverage script).
2. Generate a release keystore if you have not already (see above); configure GitHub Actions secrets for the workflow.
3. Create an annotated tag and push:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

4. The [release workflow](../.github/workflows/release.yml) builds a signed APK (`metrotuner-v1.0.0.apk` for tag `v1.0.0`) and attaches it to the GitHub Release (marked **latest**).
5. Edit the generated release notes: list features, known limitations, and **verification steps** (`apksigner verify --print-certs` + expected SHA-256). Attach an **IPA** manually only if you built one on a Mac.

---

## Phase 9 maintainer checklist

The repo already has Gradle signing, `key.properties.example`, and [`.github/workflows/release.yml`](../.github/workflows/release.yml). **You must do the following on your machine or on GitHub** — keystores and passwords cannot be created or stored in the repo.

### A. One-time: create the release keystore (never commit it)

Run (answer the prompts; remember passwords and alias):

```bash
cd /path/to/MetroTuner
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep `upload-keystore.jks` **out of git** (it is covered by `android/.gitignore` patterns if you name it `*.jks` in `android/` — confirm with `git status`).

### B. One-time: local signing file for builds on your PC

```bash
cp android/key.properties.example android/key.properties
# Edit android/key.properties with real passwords and storeFile=upload-keystore.jks
```

### C. One-time: GitHub Actions secrets (for automated releases on `vMAJOR.MINOR.PATCH` tags)

In **GitHub → your repo → Settings → Secrets and variables → Actions → New repository secret**, add:

| Secret name | Value |
|-------------|--------|
| `ANDROID_KEYSTORE_BASE64` | Output of `./tool/prepare_github_keystore_secret.sh android/upload-keystore.jks` (paste the whole line) |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password from `keytool` |
| `ANDROID_KEY_PASSWORD` | Key password (often same as store password) |
| `ANDROID_KEY_ALIAS` | e.g. `upload` |

### D. Verify locally before tagging (optional but recommended)

```bash
flutter build apk --release
BT="$(ls "$ANDROID_HOME/build-tools" | sort -V | tail -1)"
"$ANDROID_HOME/build-tools/$BT/apksigner" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

The **SHA-256** in both outputs should match. Add that hex string to [README.md](../README.md) and to the GitHub Release description after the first successful release.

### E. Publish a version: tag and push

```bash
git checkout main
git pull
git tag -a v1.0.0 -m "MetroTuner v1.0.0"
git push origin v1.0.0
```

The **Release** workflow runs, uploads `metrotuner-v1.0.0.apk` (for that tag), and prints the certificate in the Actions log — use that **SHA-256** line in the README.

### F. iOS IPA (optional)

Requires **macOS + Xcode + Apple Developer** (or personal team). Not built on Linux CI. After `flutter build ipa --release`, upload the `.ipa` manually to the same GitHub Release as the APK.
