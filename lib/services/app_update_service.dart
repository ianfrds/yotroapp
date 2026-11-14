import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/changelog_model.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_update_dialog.dart';

class ReleaseInfo {
  final String tagName;
  final String version;
  final String body;
  final String apkUrl;
  final int? apkSize;

  const ReleaseInfo({
    required this.tagName,
    required this.version,
    required this.body,
    required this.apkUrl,
    this.apkSize,
  });
}

class AppUpdateService {
  static const String owner = 'ianfrds';
  static const String repo = 'yotroapp';

  /// Compare two semantic version strings (e.g. "2.0.1" vs "2.0.0")
  static bool isNewerVersion(String latest, String current) {
    try {
      final cleanLatest =
          latest.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();
      final cleanCurrent =
          current.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();

      final latestParts =
          cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts =
          cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxParts =
          math.max(3, math.max(latestParts.length, currentParts.length));
      while (latestParts.length < maxParts) {
        latestParts.add(0);
      }
      while (currentParts.length < maxParts) {
        currentParts.add(0);
      }

      for (int i = 0; i < maxParts; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch latest release from either GitHub Releases API or version.json manifest
  static Future<ReleaseInfo?> getLatestRelease() async {
    if (kIsWeb) return null;

    ReleaseInfo? releaseFromManifest;
    ReleaseInfo? releaseFromApi;

    try {
      releaseFromManifest = await _fetchFromRawManifest();
    } catch (e) {
      debugPrint('[AppUpdateService] Gagal memeriksa manifest version.json: $e');
    }

    try {
      releaseFromApi = await _fetchFromGitHubReleases();
    } catch (e) {
      debugPrint('[AppUpdateService] Gagal memeriksa GitHub Releases: $e');
    }

    if (releaseFromApi == null) return releaseFromManifest;
    if (releaseFromManifest == null) return releaseFromApi;

    if (isNewerVersion(releaseFromManifest.version, releaseFromApi.version)) {
      return releaseFromManifest;
    }
    return releaseFromApi;
  }

  /// Fetch release metadata from raw version.json manifest in main branch
  static Future<ReleaseInfo?> _fetchFromRawManifest() async {
    final url = Uri.parse(
        'https://raw.githubusercontent.com/$owner/$repo/main/version.json');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    final request = await client.getUrl(url);
    request.headers.set('User-Agent', 'YotroApp-Updater');

    final response = await request.close();
    if (response.statusCode != 200) {
      return null;
    }

    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final version = (data['version'] as String? ?? '').trim();
    if (version.isEmpty) return null;

    final releaseNotes =
        data['release_notes'] as String? ?? 'Pembaruan aplikasi Yotro.';
    final apkUrl = data['download_url'] as String? ??
        'https://github.com/$owner/$repo/releases/download/v$version/yotro-app.apk';
    final apkSize = data['apk_size'] as int?;

    return ReleaseInfo(
      tagName: 'v$version',
      version: version,
      body: releaseNotes,
      apkUrl: apkUrl,
      apkSize: apkSize,
    );
  }

  /// Fetch latest release from GitHub Releases API
  static Future<ReleaseInfo?> _fetchFromGitHubReleases() async {
    final url = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/releases/latest');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    final request = await client.getUrl(url);
    request.headers.set('Accept', 'application/vnd.github.v3+json');
    request.headers.set('User-Agent', 'YotroApp-Updater');

    final response = await request.close();
    if (response.statusCode != 200) {
      debugPrint('[AppUpdateService] GitHub API status: ${response.statusCode}');
      return null;
    }

    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final tagName = data['tag_name'] as String? ?? '';
    final releaseNotes =
        data['body'] as String? ?? 'Pembaruan aplikasi Yotro.';
    final assets = data['assets'] as List<dynamic>? ?? [];

    String? apkUrl;
    int? apkSize;

    Map<String, dynamic>? selectedAsset;
    for (final rawAsset in assets) {
      final asset = rawAsset as Map<String, dynamic>;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name == 'yotro-app.apk') {
        selectedAsset = asset;
        break;
      }
      if (selectedAsset == null && name.endsWith('.apk')) {
        selectedAsset = asset;
      }
    }
    if (selectedAsset != null) {
      apkUrl = selectedAsset['browser_download_url'] as String?;
      apkSize = selectedAsset['size'] as int?;
    }

    if (apkUrl == null) {
      apkUrl =
          'https://github.com/$owner/$repo/releases/download/$tagName/yotro-app.apk';
    }

    final version = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();

    return ReleaseInfo(
      tagName: tagName,
      version: version,
      body: releaseNotes,
      apkUrl: apkUrl,
      apkSize: apkSize,
    );
  }

  /// Get current running version
  static Future<String> getCurrentVersion() async {
    if (kIsWeb) return ChangelogData.currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version.isNotEmpty
          ? packageInfo.version
          : ChangelogData.currentVersion;
    } catch (_) {
      return ChangelogData.currentVersion;
    }
  }

  /// Main method to check and prompt for updates
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool manualTrigger = false,
  }) async {
    if (kIsWeb) {
      if (manualTrigger) {
        AppSnackBar.show(
          context,
          'Versi Web selalu mutakhir secara otomatis.',
          type: SnackBarType.info,
        );
      }
      return;
    }

    try {
      final currentVersion = await getCurrentVersion();
      final latest = await getLatestRelease();

      if (!context.mounted) return;

      if (latest != null && isNewerVersion(latest.version, currentVersion)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AppUpdateDialog(
            releaseInfo: latest,
            currentVersion: currentVersion,
          ),
        );
      } else {
        if (manualTrigger) {
          AppSnackBar.show(
            context,
            'Anda sudah menggunakan versi terbaru (v$currentVersion).',
            type: SnackBarType.success,
          );
        }
      }
    } catch (e) {
      if (manualTrigger && context.mounted) {
        AppSnackBar.show(
          context,
          'Gagal memeriksa pembaruan: $e',
          type: SnackBarType.danger,
        );
      }
    }
  }

  /// Download APK with redirect support and launch package installer
  static Future<void> downloadAndInstall({
    required String apkUrl,
    required Function(int received, int total) onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    Uri targetUri = Uri.parse(apkUrl);
    HttpClientResponse? response;
    int redirects = 0;

    while (redirects < 5) {
      final request = await client.getUrl(targetUri);
      request.followRedirects = false;
      request.headers.set('User-Agent', 'YotroApp-Updater');
      response = await request.close();

      if ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          response.headers.value(HttpHeaders.locationHeader) != null) {
        final loc = response.headers.value(HttpHeaders.locationHeader)!;
        targetUri = targetUri.resolve(loc);
        redirects++;
        continue;
      }
      break;
    }

    if (response == null || response.statusCode != 200) {
      throw Exception(
          'Server mengembalikan kode status ${response?.statusCode ?? 'null'}');
    }

    final total = response.contentLength;
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/yotro-update.apk');

    if (await file.exists()) {
      await file.delete();
    }

    final sink = file.openWrite();
    int received = 0;

    await response.listen((chunk) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received, total);
    }).asFuture();

    await sink.close();

    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
