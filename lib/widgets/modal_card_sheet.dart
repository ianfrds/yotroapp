import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<T?> showModalCardSheet<T>({
  required BuildContext context,
  required String title,
  IconData? titleIcon,
  Color? titleIconColor,
  Widget? headerAction,
  EdgeInsetsGeometry innerPadding = const EdgeInsets.all(16),
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withOpacity(0.65),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final bottomPadding = MediaQuery.of(ctx).padding.bottom;
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset + 12 : (bottomPadding > 0 ? bottomPadding + 8 : 16),
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C131D) : const Color(0xFFF4F5F7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.55 : 0.15),
                blurRadius: 28,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Handle Pill
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 14, 8),
                  child: Row(
                    children: [
                      if (titleIcon != null) ...[
                        Icon(
                          titleIcon,
                          color: titleIconColor ?? (isDark ? const Color(0xFF8CA7C5) : const Color(0xFF475569)),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.interTight(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (headerAction != null)
                        headerAction
                      else
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF475569),
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Inner Nested Card matching NestedCard margin (8px) and radius (20px)
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131A26) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: innerPadding,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

