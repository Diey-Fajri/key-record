import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../models/github_release.dart';

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.release,
    required this.isUpdateAvailable,
  });

  final String currentVersion;
  final String latestVersion;
  final GitHubRelease release;
  final bool isUpdateAvailable;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateService {
  AppUpdateService({
    required this.owner,
    required this.repository,
    http.Client? client,
    Dio? dio,
  })  : _client = client ?? http.Client(),
        _dio = dio ?? Dio();

  final String owner;
  final String repository;
  final http.Client _client;
  final Dio _dio;

  Uri get _latestReleaseUri =>
      Uri.parse('https://api.github.com/repos/$owner/$repository/releases/latest');

  Future<UpdateCheckResult> checkForUpdate({required String currentVersion}) async {
    if (owner.trim().isEmpty || repository.trim().isEmpty) {
      throw const AppUpdateException('GitHub owner/repository is not configured.');
    }

    final response = await _client.get(
      _latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw const AppUpdateException(
          'No GitHub release found. Create a release first in your repository.',
        );
      }
      throw AppUpdateException(
        'GitHub API failed (${response.statusCode}). Please try again later.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppUpdateException('Invalid response from GitHub Releases API.');
    }

    final release = GitHubRelease.fromJson(decoded);
    if (release.tagName.trim().isEmpty) {
      throw const AppUpdateException('Latest release tag is missing.');
    }

    final latestVersion = _normalizeVersion(release.tagName);
    final installedVersion = _normalizeVersion(currentVersion);
    final hasUpdate = _compareVersions(installedVersion, latestVersion) < 0;

    return UpdateCheckResult(
      currentVersion: installedVersion,
      latestVersion: latestVersion,
      release: release,
      isUpdateAvailable: hasUpdate,
    );
  }

  Future<void> downloadAndInstallApk(
    GitHubRelease release, {
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    GitHubReleaseAsset? apkAsset;
    for (final asset in release.assets) {
      if (asset.isApk) {
        apkAsset = asset;
        break;
      }
    }

    if (apkAsset == null || apkAsset.browserDownloadUrl.trim().isEmpty) {
      throw const AppUpdateException('No APK asset found in this GitHub release.');
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${apkAsset.name}';

    try {
      await _dio.download(
        apkAsset.browserDownloadUrl,
        filePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(minutes: 1),
        ),
      );
    } catch (_) {
      throw const AppUpdateException('Failed to download APK. Please check your connection.');
    }

    if (!Platform.isAndroid) {
      await openReleasePage(release);
      return;
    }

    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done) {
      throw AppUpdateException('Downloaded APK but failed to open installer: ${openResult.message}');
    }
  }

  Future<void> openReleasePage(GitHubRelease release) async {
    final url = release.htmlUrl.trim();
    if (url.isEmpty) {
      throw const AppUpdateException('Release page URL is missing.');
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const AppUpdateException('Unable to open release page.');
    }
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
