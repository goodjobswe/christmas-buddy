# Android releases

The supported development baseline is Flutter 3.29.3 / Dart 3.7.2, with the Android SDK and Java 21. Dependencies are pinned by `pubspec.lock`.

## Signing

Release builds require `android/key.properties`; they never fall back to the debug key. Copy `android/key.properties.example`, fill in your local values, and put the keystore at the configured path. Relative keystore paths resolve from `android/app`.

To create a key for your own distribution, use the JDK's `keytool` and supply passwords at its prompts:

```sh
keytool -genkeypair -v -keystore android/app/christmas-buddy-release.jks -storetype JKS -keyalg RSA -keysize 3072 -validity 10000 -alias release
```

The official GitHub release uses its own dedicated key. Keep encrypted backups of that keystore and its passwords: future updates must use the same key. Keys and `android/key.properties` are ignored by Git and must never be uploaded as release assets. A newly generated key cannot update installations signed by another key, including the original Google Play release.

## Verify and build

1. Update the version and build number in `pubspec.yaml` and the changelog.
2. Run `flutter pub get`, `flutter analyze` and `flutter test`.
3. Build with `flutter build apk --release`. Do not supply `FAKE_DATE` or a screenshot entry point.
4. Verify the APK with Android SDK `apksigner verify --verbose --print-certs`, checking that it is signed with the dedicated release certificate. Use `aapt dump badging` and `aapt dump permissions` to check version, minimum SDK and permissions.
5. Install on an Android device or isolated emulator, then check startup, settings, lists, notifications, sharing and About. Keep any existing user data when testing.
6. Copy the APK as `christmas-buddy-VERSION-android.apk` and generate its SHA-256 checksum.
7. Commit and push, tag that exact commit as `vVERSION`, then create a GitHub release with the APK, checksum and notes. Keep repository visibility unchanged unless explicitly requested.

The APK supports armeabi-v7a, arm64-v8a and x86_64. A GitHub release is not a Google Play submission. Any future Play upload needs a separate review of signing continuity and current store requirements.
