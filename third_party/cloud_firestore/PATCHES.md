# cloud_firestore 5.6.12: Android transaction timeout backport

This directory vendors the runtime sources from the published `cloud_firestore` 5.6.12 archive (pub.dev archive SHA-256: `2d33da4465bdb81b6685c41b535895065adcb16261beb398f5f3bbc623979e9c`). The upstream license is retained in `LICENSE`. Example apps, dartpad, and upstream tests are omitted. `pubspec.yaml` in the app selects this copy using a relative path override, so a normal `flutter pub get` and Android Studio build include the fix on every checkout. The global Pub cache is not modified.

## Applied patch

Backport of Firebase FlutterFire [commit 168172a889c0d08c0b618d7ef68d9c5ce503dc40](https://github.com/firebase/flutterfire/commit/168172a889c0d08c0b618d7ef68d9c5ce503dc40), PR #18668, issue #18666:

- `android/.../streamhandler/TransactionStreamHandler.java`: throw on timeout/interruption, so the native transaction aborts instead of being committed. Preserve the nested `FirebaseFirestoreException` so callers still receive `deadline-exceeded`.
- `android/.../FlutterFirebaseFirestorePlugin.java`: convert a `Throwable` from `transactionGet` into a Flutter error rather than letting it terminate the Android process.

Only these two upstream source files differ. Dart APIs, Firebase dependencies, and the iOS/macOS/Windows sources are unchanged. A major FlutterFire upgrade would also change Firebase Core/Auth and Apple SDK requirements; this backport fixes the Android crash within the current compatibility range.

## Verification and removal

The Android regression test is `android/app/src/androidTest/kotlin/jp/ac/chibakoudai/citapp/firestore/FirestoreTransactionTimeoutTest.kt`. It uses a named Firebase app and a local Firestore emulator, delays a second read until after the callback timeout, verifies `deadline-exceeded`, and checks that a subsequent transaction succeeds. It never uses production data. See `docs/ANDROID_CRASH_INVESTIGATION_2026-09-17.md` for commands and results.

When upgrading the complete Firebase dependency group to versions containing #18668 (Firestore changelog: 6.10.0), remove this override and directory after running the Android regression and app tests and checking Apple deployment requirements. Do not replace this patch with a larger timeout or a Dart-only catch.
