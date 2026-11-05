import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StandardScreenHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? actionWidget;

  const StandardScreenHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBack,
    this.actionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backBtnBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0);
    final backBtnBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD1D5DB);
    final backIconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBackButton) ...[
                InkWell(
                  onTap: onBack ?? () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: backBtnBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: backBtnBorder),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: backIconColor,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionWidget != null) ...[
          const SizedBox(width: 8),
          actionWidget!,
        ],
      ],
    );
  }
}
