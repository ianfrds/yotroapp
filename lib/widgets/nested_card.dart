import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NestedCard extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? action;
  final Widget? actionWidget;
  final VoidCallback? onActionTap;
  final Widget child;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? innerMargin;
  final EdgeInsetsGeometry? innerPadding;
  final Color? outerColor;
  final Color? innerColor;
  final double outerRadius;
  final double innerRadius;
  final Border? outerBorder;
  final Border? innerBorder;

  const NestedCard({
    super.key,
    this.title,
    this.titleWidget,
    this.action,
    this.actionWidget,
    this.onActionTap,
    required this.child,
    this.headerPadding,
    this.innerMargin,
    this.innerPadding,
    this.outerColor,
    this.innerColor,
    this.outerRadius = 26.0,
    this.innerRadius = 20.0,
    this.outerBorder,
    this.innerBorder,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null ||
        titleWidget != null ||
        action != null ||
        actionWidget != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOuter = outerColor ?? (isDark ? const Color(0xFF0C131D) : const Color(0xFFFFFFFF));
    final effectiveInner = innerColor ?? (isDark ? const Color(0xFF131A26) : const Color(0xFFF1F3F5));
    final effectiveOuterBorder = outerBorder ?? Border.all(
      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
    );
    final effectiveInnerBorder = innerBorder ?? Border.all(
      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE5E7EB),
    );
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final actionColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: effectiveOuter,
        borderRadius: BorderRadius.circular(outerRadius),
        border: effectiveOuterBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Padding(
              padding: headerPadding ?? const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (titleWidget != null)
                    Expanded(child: titleWidget!)
                  else if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: GoogleFonts.interTight(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (actionWidget != null)
                    actionWidget!
                  else if (action != null)
                    InkWell(
                      onTap: onActionTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              action!,
                              style: GoogleFonts.manrope(
                                color: actionColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: actionColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Container(
            margin: innerMargin ??
                (hasHeader
                    ? const EdgeInsets.fromLTRB(6, 0, 6, 6)
                    : const EdgeInsets.all(6)),
            padding: innerPadding,
            decoration: BoxDecoration(
              color: effectiveInner,
              borderRadius: BorderRadius.circular(innerRadius),
              border: effectiveInnerBorder,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
