import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_update_info.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.update,
    required this.isUpdateAvailable,
    required this.isForceUpdate,
    required this.minimumVersion,
  });

  final String currentVersion;
  final String latestVersion;
  final AppUpdateInfo update;
  final bool isUpdateAvailable;
  final bool isForceUpdate;
  final String minimumVersion;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateConfigValidationResult {
  const UpdateConfigValidationResult({
    required this.exists,
    required this.missingFields,
    required this.errors,
    required this.apkUrlResolved,
  });

  final bool exists;
  final List<String> missingFields;
  final List<String> errors;
  final bool apkUrlResolved;

  bool get isValid => exists && missingFields.isEmpty && errors.isEmpty && apkUrlResolved;
}

class AppUpdateService {
  AppUpdateService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Dio? dio,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _dio = dio ?? Dio();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Dio _dio;

  DocumentReference<Map<String, dynamic>> get _currentUpdateDoc =>
      _firestore.collection('app_updates').doc('current');

  /// Verifies required update metadata and checks that APK source resolves.
  Future<UpdateConfigValidationResult> validateCurrentUpdateConfig() async {
    final missingFields = <String>[];
    final errors = <String>[];
    var apkUrlResolved = false;

    final snapshot = await _currentUpdateDoc.get();
    if (!snapshot.exists) {
      return const UpdateConfigValidationResult(
        exists: false,
        missingFields: <String>[],
        errors: <String>['Document app_updates/current does not exist.'],
        apkUrlResolved: false,
      );
    }

    final data = snapshot.data();
    if (data == null) {
      return const UpdateConfigValidationResult(
        exists: true,
        missingFields: <String>[],
        errors: <String>['Document app_updates/current is empty.'],
        apkUrlResolved: false,
      );
    }

    final latestVersion = (data['latestVersion'] ?? '').toString().trim();
    final apkStoragePath =
        (data['apkStoragePath'] ?? data['storagePath'] ?? '').toString().trim();
    final apkUrl = (data['apkUrl'] ?? data['downloadUrl'] ?? '').toString().trim();

    if (latestVersion.isEmpty) {
      missingFields.add('latestVersion');
    }
    if (apkStoragePath.isEmpty && apkUrl.isEmpty) {
      missingFields.add('apkStoragePath or apkUrl');
    }

    if (apkUrl.isNotEmpty) {
      if (!_looksLikeHttpUrl(apkUrl)) {
        errors.add('apkUrl must be a valid HTTP/HTTPS URL.');
      } else {
        apkUrlResolved = true;
      }
    }

    if (!apkUrlResolved && apkStoragePath.isNotEmpty) {
      if (_looksLikeHttpUrl(apkStoragePath)) {
        apkUrlResolved = true;
      } else {
        try {
          await _resolveStorageReference(apkStoragePath).getDownloadURL();
          apkUrlResolved = true;
        } catch (error) {
          errors.add('Unable to resolve APK in Storage: $error');
        }
      }
    }

    return UpdateConfigValidationResult(
      exists: true,
      missingFields: missingFields,
      errors: errors,
      apkUrlResolved: apkUrlResolved,
    );
  }

  /// Reads update metadata from Firestore and compares versions.
  Future<UpdateCheckResult> checkForUpdate({required String currentVersion}) async {
    final snapshot = await _currentUpdateDoc.get();
    if (!snapshot.exists) {
      throw const AppUpdateException('Update metadata is missing at app_updates/current.');
    }

    final data = snapshot.data();
    if (data == null) {
      throw const AppUpdateException('Update metadata is empty.');
    }

    final update = AppUpdateInfo.fromFirestore(data);
    if (update.latestVersion.isEmpty) {
      throw const AppUpdateException('Field latestVersion is required in app_updates/current.');
    }
    if (update.apkStoragePath.isEmpty && update.apkUrl.isEmpty) {
      throw const AppUpdateException('Field apkStoragePath or apkUrl is required in app_updates/current.');
    }

    final latestVersion = _normalizeVersion(update.latestVersion);
    final installedVersion = _normalizeVersion(currentVersion);
    final minimumVersion = _normalizeVersion(update.minimumVersion);
    final hasUpdate = _compareVersions(installedVersion, latestVersion) < 0;
    final belowMinimum = minimumVersion.isNotEmpty
        ? _compareVersions(installedVersion, minimumVersion) < 0
        : false;
    final isForceUpdate = update.forceUpdate || belowMinimum;

    return UpdateCheckResult(
      currentVersion: installedVersion,
      latestVersion: latestVersion,
      update: update,
      isUpdateAvailable: hasUpdate || belowMinimum,
      isForceUpdate: isForceUpdate,
      minimumVersion: minimumVersion,
    );
  }

  /// Downloads the APK and launches Android installer.
  Future<void> downloadAndInstallApk(
    AppUpdateInfo update, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final downloadUrl = await _resolveDownloadUrl(update);
    final fileName = _extractFileName(downloadUrl) ?? 'app-release.apk';

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';

    try {
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(minutes: 1),
        ),
      );
    } catch (error) {
      throw AppUpdateException('Failed to download APK: $error');
    }

    if (!Platform.isAndroid) {
      throw const AppUpdateException('APK installation is only supported on Android devices.');
    }

    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done) {
      throw AppUpdateException('Downloaded APK but failed to open installer: ${openResult.message}');
    }
  }

  Reference _resolveStorageReference(String rawPath) {
    final path = rawPath.trim();
    if (path.startsWith('gs://') || path.contains('firebasestorage.googleapis.com')) {
      return _storage.refFromURL(path);
    }
    return _storage.ref(path);
  }

  Future<String> _resolveDownloadUrl(AppUpdateInfo update) async {
    if (update.apkUrl.isNotEmpty) {
      return update.apkUrl.trim();
    }

    final rawPath = update.apkStoragePath.trim();
    if (_looksLikeHttpUrl(rawPath)) {
      return rawPath;
    }

    return await _resolveStorageReference(rawPath).getDownloadURL();
  }

  String? _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (_) {
      // ignore invalid URIs
    }
    return null;
  }

  bool _looksLikeHttpUrl(String rawPath) {
    final path = rawPath.trim().toLowerCase();
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _normalizeVersion(String version) {
    final withoutV = version.trim().toLowerCase().startsWith('v')
        ? version.trim().substring(1)
        : version.trim();
    final withoutBuild = withoutV.split('+').first;
    return withoutBuild;
  }

  int _compareVersions(String left, String right) {
    final leftParts = _toVersionParts(left);
    final rightParts = _toVersionParts(right);
    final maxLength = leftParts.length > rightParts.length ? leftParts.length : rightParts.length;

    for (var index = 0; index < maxLength; index += 1) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }

  List<int> _toVersionParts(String version) {
    final clean = version.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) {
      return const <int>[0];
    }
    return clean
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }
}
