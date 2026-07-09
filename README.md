# key-record

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase App Update System

This app now uses Firebase for in-app APK updates instead of GitHub Releases.

### 1) Upload APK to Firebase Storage

Upload your release APK to a known path, for example:

- `updates/android/app-release.apk`

### 2) Create Firestore metadata document

Create/update this document:

- Collection: `app_updates`
- Document: `current`

Recommended fields:

- `latestVersion` (string) Example: `1.0.1`
- `releaseNotes` (string) Example: `Bug fixes and performance improvements`
- `apkStoragePath` (string) Example: `updates/android/app-release.apk`
- `forceUpdate` (bool, optional) Example: `true`
- `minimumVersion` (string, optional) Example: `1.0.0`

### 3) Runtime behavior

- App startup checks `app_updates/current` automatically.
- Settings page "Check for Updates" checks the same document manually.
- If a newer version is found, the dialog shows current version, latest version, and release notes.
- APK is downloaded from Firebase Storage with progress, then Android installer is launched.
- If `forceUpdate` is true or installed version is below `minimumVersion`, update is treated as mandatory.
