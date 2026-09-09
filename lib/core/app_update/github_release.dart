/// Release GitHub da cui l'app può installare un APK.
class GithubRelease {
  const GithubRelease({
    required this.tagName,
    required this.versionName,
    required this.versionCode,
    required this.assetName,
    required this.downloadUrl,
    required this.apiAssetUrl,
    this.notes = '',
    this.size = 0,
  });

  final String tagName;
  final String versionName;
  final int versionCode;
  final String assetName;
  final String downloadUrl;
  final String apiAssetUrl;
  final String notes;
  final int size;

  /// Android installa solo un versionCode strettamente maggiore.
  bool isNewerThan({required int installedCode}) {
    return versionCode > installedCode;
  }
}

class GithubAsset {
  const GithubAsset({
    required this.name,
    required this.downloadUrl,
    required this.apiUrl,
    this.size = 0,
  });

  final String name;
  final String downloadUrl;
  final String apiUrl;
  final int size;

  bool get isApk => name.toLowerCase().endsWith('.apk');
}

/// Tag `v1.0.1+2` → nome 1.0.1, codice 2. Tag `v1.0.1` → solo nome.
({String versionName, int versionCode}) parseReleaseTag(String tag) {
  var raw = tag.trim();
  if (raw.startsWith('v') || raw.startsWith('V')) {
    raw = raw.substring(1);
  }
  var versionName = raw;
  var versionCode = 0;
  final plus = raw.indexOf('+');
  if (plus >= 0) {
    versionName = raw.substring(0, plus);
    versionCode = int.tryParse(raw.substring(plus + 1).trim()) ?? 0;
  }
  return (versionName: versionName, versionCode: versionCode);
}

GithubAsset? pickApkAsset(
  List<GithubAsset> assets, {
  required List<String> preferredAbis,
}) {
  final apks = [for (final asset in assets) if (asset.isApk) asset];
  if (apks.isEmpty) {
    return null;
  }
  for (final abi in preferredAbis) {
    final needle = abi.toLowerCase();
    for (final asset in apks) {
      if (asset.name.toLowerCase().contains(needle)) {
        return asset;
      }
    }
  }
  for (final asset in apks) {
    final name = asset.name.toLowerCase();
    if (name.contains('app-release.apk') || name.contains('universal')) {
      return asset;
    }
  }
  return apks.first;
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return {for (final entry in value.entries) '${entry.key}': entry.value};
}

GithubRelease? parseGithubReleaseJson(
  Map<String, Object?> json, {
  required List<String> preferredAbis,
}) {
  final tagName = json['tag_name'] as String? ?? '';
  if (tagName.isEmpty) {
    return null;
  }
  final parsed = parseReleaseTag(tagName);
  final rawAssets = json['assets'];
  final assets = <GithubAsset>[];
  if (rawAssets is List) {
    for (final item in rawAssets) {
      final map = _asMap(item);
      if (map == null) {
        continue;
      }
      final name = map['name'] as String? ?? '';
      final download = map['browser_download_url'] as String? ?? '';
      final apiUrl = map['url'] as String? ?? download;
      final sizeRaw = map['size'];
      final size = sizeRaw is num ? sizeRaw.toInt() : 0;
      if (name.isEmpty || download.isEmpty) {
        continue;
      }
      assets.add(
        GithubAsset(
          name: name,
          downloadUrl: download,
          apiUrl: apiUrl,
          size: size,
        ),
      );
    }
  }
  final asset = pickApkAsset(assets, preferredAbis: preferredAbis);
  if (asset == null) {
    return null;
  }
  return GithubRelease(
    tagName: tagName,
    versionName: parsed.versionName,
    versionCode: parsed.versionCode,
    assetName: asset.name,
    downloadUrl: asset.downloadUrl,
    apiAssetUrl: asset.apiUrl,
    notes: json['body'] as String? ?? '',
    size: asset.size,
  );
}
