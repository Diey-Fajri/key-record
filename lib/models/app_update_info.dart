/// Metadata for app updates stored in Firestore at `app_updates/current`.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.apkStoragePath,
    required this.forceUpdate,
    required this.minimumVersion,
  });

  /// Target version available for download, for example `1.0.1`.
  final String latestVersion;

  /// Human-readable release notes shown in the update dialog.
  final String releaseNotes;

  /// Firebase Storage path (or gs:// URL) to the APK.
  final String apkStoragePath;

  /// Direct HTTP/HTTPS URL to the APK (for GitHub-hosted download links).
  final String apkUrl;

  /// If true, user should not skip the update.
  final bool forceUpdate;

  /// Optional minimum app version allowed to continue using the app.
  final String minimumVersion;

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> data) {
    final latestVersion = (data['latestVersion'] ?? '').toString().trim();
    final apkStoragePath = (data['apkStoragePath'] ?? data['storagePath'] ?? '').toString().trim();
    final apkUrl = (data['apkUrl'] ?? data['downloadUrl'] ?? '').toString().trim();
    final releaseNotes = (data['releaseNotes'] ?? '').toString().trim();
    final forceUpdate = data['forceUpdate'] == true;
    final minimumVersion = (data['minimumVersion'] ?? '').toString().trim();

    return AppUpdateInfo(
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      apkStoragePath: apkStoragePath,
      apkUrl: apkUrl,
      forceUpdate: forceUpdate,
      minimumVersion: minimumVersion,
    );
  }
}