# KeyRecord App

KeyRecord is a Flutter-based key management application with Firebase-backed persistence, event logging, and real-time notification support.

## Latest Update

### Version
Current application version: 1.0.2+3

## New Features

### Firebase Cloud Messaging (FCM) Notification System
The app now includes a Firebase Cloud Messaging notification pipeline for key-related activity.

- The Flutter app creates notification documents in the Firestore collection `notifications`.
- A standalone Node.js notification server listens to Firestore changes.
- Firebase Admin SDK sends FCM messages to topic `security_all`.
- Firebase Cloud Functions are not used.

Flow:

Flutter App
→ Firestore notifications
→ Node.js Notification Server
→ Firebase Admin SDK
→ FCM
→ User devices

### Notification Activities Supported
The following actions generate notifications:

- Register new key
- Take key / handover
- Return key
- Mark no return
- Edit key details
- Delete key
- Lost key
- Damaged key
- Not Available status
- Maintenance flow
- Replacement flow
- Receive key flow

## Key Status
The app supports the following key statuses:

- Available
- In Use
- Lost
- Damaged
- Not Available

Status notes:

- Lost means the key existed but cannot be found.
- Not Available means the key or physical key does not exist, but the door is still recorded in the system.

## Firestore Collections
The main Firestore collections used by the app are:

- `keys`
- `notifications`
- `event_log`
- `saved_persons`

## Notification Document Format
Notification documents written by the Flutter app follow this structure:

```json
{
  "title": "Example title",
  "body": "Example body",
  "type": "activity_type",
  "createdAt": "FieldValue.serverTimestamp()",
  "fcmSent": false
}
```

## Node.js Notification Server
A standalone notification server is located in the `/server` directory.

Responsibilities:

- Uses Firebase Admin SDK
- Watches the Firestore `notifications` collection
- Sends FCM messages to the `security_all` topic
- Requires a local `serviceAccountKey.json` file

Security note:

- Do not upload `serviceAccountKey.json` to GitHub.

## Update History

### Recent Updates
- Added an FCM notification architecture without Firebase Cloud Functions
- Added notification creation for key activities
- Added the Not Available key status
- Improved key status filtering and editing
- Maintained existing event log tracking

---

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
