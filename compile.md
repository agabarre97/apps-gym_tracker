# Android APK compile handoff

This file documents all Android build/debugging work done so you can continue on another PC with another agent.

## 1) What was changed in the project

### `android/settings.gradle`
- Fixed Flutter SDK path closure invocation:
  - `settings.ext.flutterSdkPath = flutterSdkPath()` (was missing `()` before).
- Updated Android toolchain plugin versions:
  - `com.android.application` -> `8.6.0`
  - `org.jetbrains.kotlin.android` -> `2.2.0`

### `android/gradle/wrapper/gradle-wrapper.properties`
- Updated Gradle wrapper:
  - `distributionUrl=.../gradle-8.10.2-all.zip`

### `android/app/build.gradle`
- Updated SDK targets required by plugins:
  - `compileSdk = 36`
  - `targetSdk = 36`
- Removed explicit `ndkVersion = flutter.ndkVersion` to avoid forcing unavailable NDK versions.

### `android/local.properties`
- Switched Android SDK directory to a user-writable SDK:
  - `sdk.dir=/home/agabarre/.android-sdk`

## 2) What was installed locally (current machine)

Installed into user SDK (`/home/agabarre/.android-sdk`) using `sdkmanager`:
- `platform-tools`
- `platforms;android-34`
- `platforms;android-36`
- `build-tools;33.0.1`
- `build-tools;34.0.0`
- `build-tools;36.0.0`
- `ndk;25.1.8937393`

Licenses were accepted using:
- `ANDROID_SDK_ROOT=/home/agabarre/.android-sdk`
- `ANDROID_HOME=/home/agabarre/.android-sdk`

## 3) Important environment caveats discovered

1. `which sdkmanager` returned `/usr/bin/sdkmanager` (Python wrapper), not Android cmdline-tools.
2. That wrapper defaulted to `/opt/android-sdk` and failed with permission errors.
3. On this machine, `/home/agabarre/.cache/sdkmanager` was root-owned, causing additional permission errors.
4. Workaround used: run `sdkmanager` with a temporary `HOME` and explicit Android SDK env vars.

## 4) Reproducible setup commands for another machine

From repo root:

```bash
cd /home/agabarre/agabarre/gym_tracker
```

### 4.1 Prepare user SDK dir
```bash
mkdir -p "$HOME/.android-sdk"
mkdir -p "$HOME/tmp-sdk-home"
```

### 4.2 Ensure env vars (important)
```bash
export ANDROID_SDK_ROOT="$HOME/.android-sdk"
export ANDROID_HOME="$HOME/.android-sdk"
```

### 4.3 Accept licenses (with isolated HOME to avoid cache permission issues)
```bash
yes | HOME="$HOME/tmp-sdk-home" ANDROID_SDK_ROOT="$HOME/.android-sdk" ANDROID_HOME="$HOME/.android-sdk" sdkmanager --sdk_root="$HOME/.android-sdk" --licenses
```

### 4.4 Install required components
```bash
HOME="$HOME/tmp-sdk-home" ANDROID_SDK_ROOT="$HOME/.android-sdk" ANDROID_HOME="$HOME/.android-sdk" sdkmanager --install \
  "platform-tools" \
  "platforms;android-34" \
  "platforms;android-36" \
  "build-tools;33.0.1" \
  "build-tools;34.0.0" \
  "build-tools;36.0.0" \
  "ndk;25.1.8937393"
```

### 4.5 Build APK
```bash
ANDROID_SDK_ROOT="$HOME/.android-sdk" ANDROID_HOME="$HOME/.android-sdk" make build-apk
```

### 4.6 Fast repeat builds (recommended)
After a successful first build, use cached dependency mode:

```bash
ANDROID_SDK_ROOT="$HOME/.android-sdk" ANDROID_HOME="$HOME/.android-sdk" make build-apk-fast
```

Equivalent direct command:

```bash
ANDROID_SDK_ROOT="$HOME/.android-sdk" ANDROID_HOME="$HOME/.android-sdk" flutter build apk --no-pub
```

## 5) Last known failure point before handoff

Before the last toolchain updates, build failed at `:share_plus:compileReleaseKotlin` due to Kotlin metadata mismatch:
- dependency compiled with Kotlin `2.2.0`
- project Kotlin plugin was `1.8.22`

This is why Kotlin plugin was upgraded to `2.2.0` and AGP/Gradle were updated.

## 6) Next verification steps on new machine

1. Run:
   - `flutter doctor -v`
   - `ANDROID_SDK_ROOT=$HOME/.android-sdk ANDROID_HOME=$HOME/.android-sdk make build-apk`
2. Confirm APK exists:
   - `build/app/outputs/flutter-apk/app-release.apk`
3. For next iterations, prefer:
   - `ANDROID_SDK_ROOT=$HOME/.android-sdk ANDROID_HOME=$HOME/.android-sdk make build-apk-fast`
4. If build still fails, collect:
   - full console output
   - `android/settings.gradle`
   - `android/gradle/wrapper/gradle-wrapper.properties`
   - `android/app/build.gradle`
   - `android/local.properties`

## 7) Build performance observed on this machine

- Cold-ish build (`make build-apk`): ~3 minutes wall time.
- Warm build (`flutter build apk --no-pub`): ~7 seconds wall time.
- Recommendation: use one full build after toolchain changes, then switch to `--no-pub` for daily loops.

