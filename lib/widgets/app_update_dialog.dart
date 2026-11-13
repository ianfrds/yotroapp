import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/changelog_model.dart';
import '../services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final ReleaseInfo releaseInfo;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.releaseInfo,
    required this.currentVersion,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    try {
      await AppUpdateService.downloadAndInstall(
        apkUrl: widget.releaseInfo.apkUrl,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _receivedBytes = received;
              _totalBytes = total;
              if (total > 0) {
                _progress = (received / total).clamp(0.0, 1.0);
              }
            });
          }
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Gagal memasang pembaruan: $e';
        });
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getUserFriendlyReleaseNotes() {
    // 1. Check local ChangelogData first for matching version
    final changelog = ChangelogData.getRelease(widget.releaseInfo.tagName);
    if (changelog != null) {
      final items = [...changelog.features, ...changelog.improvements];
      if (items.isNotEmpty) {
        return items.map((e) => '• $e').join('\n');
      }
    }

    final raw = widget.releaseInfo.body.trim();
    if (raw.isEmpty) {
      return '• Pembaruan performa dan efisiensi aplikasi yang lebih optimal.\n• Penyempurnaan tata letak tombol dan antarmuka pengguna.\n• Peningkatan stabilitas pencatatan data.';
    }

    // 2. Filter raw body: remove URLs, markdown links, git commit hashes, PR merge text
    final lines = raw.split('\n');
    final cleanLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip github comparison or commit links
      if (trimmed.contains('http://') ||
          trimmed.contains('https://') ||
          trimmed.toLowerCase().contains('full changelog') ||
          trimmed.toLowerCase().startsWith('merge pull request') ||
          trimmed.toLowerCase().startsWith('merge branch')) {
        continue;
      }
      // If line is markdown header, remove hashes
      final sanitized = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      if (sanitized.isNotEmpty) {
        cleanLines.add(sanitized.startsWith('•') || sanitized.startsWith('-')
            ? sanitized
            : '• $sanitized');
      }
    }

    if (cleanLines.isEmpty) {
      return '• Pembaruan performa dan efisiensi aplikasi yang lebih optimal.\n• Penyempurnaan tata letak tombol dan antarmuka pengguna.\n• Peningkatan stabilitas pencatatan data.';
    }

    return cleanLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0C131D) : Colors.white;
    final innerBg = isDark ? const Color(0xFF131A26) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon & Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF02539A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF02539A).withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF55C7FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembaruan Tersedia',
                        style: GoogleFonts.interTight(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Versi ${widget.releaseInfo.tagName} • Terpasang v${widget.currentVersion}',
                        style: GoogleFonts.manrope(
                          color: mutedColor,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Release Notes Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: innerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Pembaruan:',
                      style: GoogleFonts.manrope(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getUserFriendlyReleaseNotes(),
                      style: GoogleFonts.manrope(
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar / Size Info
            if (_isDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mengunduh berkas APK...',
                        style: GoogleFonts.manrope(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.interTight(
                          color: const Color(0xFF55C7FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF02539A)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_totalBytes > 0)
                    Text(
                      '${_formatSize(_receivedBytes)} / ${_formatSize(_totalBytes)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.manrope(
                        color: mutedColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFFCA5A5),
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            if (!_isDownloading)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: mutedColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Nanti Saja',
                            maxLines: 1,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _startDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF02539A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _errorMessage != null ? 'Coba Lagi' : 'Update Now',
                            maxLines: 1,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
