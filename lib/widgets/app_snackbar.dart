import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType {
  info,
  success,
  warning,
  danger,
}

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    Color iconColor;
    IconData iconData;

    switch (type) {
      case SnackBarType.success:
        iconColor = const Color(0xFF34D399);
        iconData = Icons.check_circle_rounded;
        break;
      case SnackBarType.danger:
        iconColor = const Color(0xFFFF6B7A);
        iconData = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        iconColor = const Color(0xFFFBBF24);
        iconData = Icons.warning_rounded;
        break;
      case SnackBarType.info:
      default:
        iconColor = const Color(0xFF55C7FF);
        iconData = Icons.info_rounded;
        break;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF131A26),
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A3545), width: 1),
        ),
        duration: duration,
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              key: const Key('btn_close_snackbar'),
              onTap: () {
                messenger.hideCurrentSnackBar();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF94A3B8),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

