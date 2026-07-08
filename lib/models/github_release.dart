class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.body,
    required this.htmlUrl,
    required this.assets,
  });

  final String tagName;
  final String body;
  final String htmlUrl;
  final List<GitHubReleaseAsset> assets;

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'];
    final assets = rawAssets is List
        ? rawAssets
            .whereType<Map<String, dynamic>>()
            .map(GitHubReleaseAsset.fromJson)
            .toList(growable: false)
        : const <GitHubReleaseAsset>[];

    return GitHubRelease(
      tagName: (json['tag_name'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      htmlUrl: (json['html_url'] ?? '').toString(),
      assets: assets,
    );
  }
}

class GitHubReleaseAsset {
  const GitHubReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.contentType,
    required this.size,
  });

  final String name;
  final String browserDownloadUrl;
  final String contentType;
  final int size;

  bool get isApk => name.toLowerCase().endsWith('.apk');

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GitHubReleaseAsset(
      name: (json['name'] ?? '').toString(),
      browserDownloadUrl: (json['browser_download_url'] ?? '').toString(),
      contentType: (json['content_type'] ?? '').toString(),
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}
