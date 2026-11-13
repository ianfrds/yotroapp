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
      final cleanLatest = latest.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();
      final cleanCurrent = current.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxParts = math.max(3, math.max(latestParts.length, currentParts.length));
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

  /// Fetch latest release from GitHub Releases API
  static Future<ReleaseInfo?> getLatestRelease() async {
    if (kIsWeb) return null;

    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
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
      final releaseNotes = data['body'] as String? ?? 'Pembaruan aplikasi Yotro.';
      final assets = data['assets'] as List<dynamic>? ?? [];

      String? apkUrl;
      int? apkSize;

      // Find APK asset
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          apkSize = asset['size'] as int?;
          // Prioritize arm64 or main yotro-app.apk
          if (name.contains('arm64') || name == 'yotro-app.apk') {
            break;
          }
        }
      }

      if (apkUrl == null) {
        // Fallback to release tag direct download
        apkUrl = 'https://github.com/$owner/$repo/releases/download/$tagName/yotro-app.apk';
      }

      final version = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();

      return ReleaseInfo(
        tagName: tagName,
        version: version,
        body: releaseNotes,
        apkUrl: apkUrl,
        apkSize: apkSize,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Gagal memeriksa rilis: $e');
      return null;
    }
  }

  /// Get current running version
  static Future<String> getCurrentVersion() async {
    if (kIsWeb) return ChangelogData.currentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version.isNotEmpty ? packageInfo.version : ChangelogData.currentVersion;
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
        // Show update dialog
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

  /// Download APK with real-time stream progress and launch package installer
  static Future<void> downloadAndInstall({
    required String apkUrl,
    required Function(int received, int total) onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    final request = await client.getUrl(Uri.parse(apkUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan kode status ${response.statusCode}');
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

    // Trigger Android package installer via FileProvider
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
