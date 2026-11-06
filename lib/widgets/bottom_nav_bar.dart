import 'dart:math' as math;
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onAddTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final systemBottomInset = MediaQuery.of(context).padding.bottom;
    final bottomInset = math.max(systemBottomInset, 14.0);

    const barTop = 32.0;
    const barHeight = 68.0;
    final totalHeight = barTop + barHeight + bottomInset;

    const fabDiameter = 58.0;
    const fabCy = barTop + 1.5;
    const fabTop = fabCy - (fabDiameter / 2.0);

    const notchHalfWidth = 54.0;
    const notchDepth = 39.0;
    const c1 = 15.0;
    const c2 = 28.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarBg = isDark ? const Color(0xFF0F141A) : const Color(0xFFFFFFFF);
    final navBarBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final indicatorColor = isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.35);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Notched Slate Bar Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _NotchedNavBarPainter(
                barColor: navBarBg,
                borderColor: navBarBorder,
                barTop: barTop,
                topCornerRadius: 26.0,
                notchHalfWidth: notchHalfWidth,
                notchDepth: notchDepth,
                c1: c1,
                c2: c2,
              ),
            ),
          ),

          // 2. Navigation Icons Row (5 perfectly equidistant slots)
          Positioned(
            left: 0,
            right: 0,
            top: barTop + 10.0,
            height: 48.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  // Slot 0: Beranda
                  Expanded(
                    child: Center(
                      child: _buildNavItem(
                        context: context,
                        index: 0,
                        icon: Icons.grid_view_rounded,
                        tooltip: 'Beranda',
                      ),
                    ),
                  ),

                  // Slot 1: Riwayat Transaksi
                  Expanded(
                    child: Center(
                      child: _buildNavItem(
                        context: context,
                        index: 1,
                        icon: Icons.description_rounded,
                        tooltip: 'Riwayat Transaksi',
                      ),
                    ),
                  ),

                  // Slot 2: Reserved Center Notch Slot
                  const Expanded(
                    child: SizedBox.shrink(),
                  ),

                  // Slot 3: Laporan Keuangan
                  Expanded(
                    child: Center(
                      child: _buildNavItem(
                        context: context,
                        index: 4,
                        icon: Icons.pie_chart_rounded,
                        tooltip: 'Laporan Keuangan',
                      ),
                    ),
                  ),

                  // Slot 4: Profil & Pengaturan
                  Expanded(
                    child: Center(
                      child: _buildNavItem(
                        context: context,
                        index: 5,
                        icon: Icons.person_rounded,
                        tooltip: 'Profil & Pengaturan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Center Elevated Plus Button
          Positioned(
            top: fabTop,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: fabDiameter,
                height: fabDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF025EA8), Color(0xFF014786)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF014786).withOpacity(0.20),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

          // 4. Subtle Home Indicator Bar (Mobile & Web Runner)
          if (systemBottomInset == 0)
            Positioned(
              bottom: 6.0,
              child: Container(
                width: 136.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onIndexChanged(index),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 46,
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotchedNavBarPainter extends CustomPainter {
  final Color barColor;
  final Color borderColor;
  final double barTop;
  final double topCornerRadius;
  final double notchHalfWidth;
  final double notchDepth;
  final double c1;
  final double c2;

  const _NotchedNavBarPainter({
    required this.barColor,
    required this.borderColor,
    required this.barTop,
    required this.topCornerRadius,
    required this.notchHalfWidth,
    required this.notchDepth,
    required this.c1,
    required this.c2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;

    // Full closed path for shadow and background fill
    final path = Path();
    path.moveTo(0, barTop + topCornerRadius);
    path.arcToPoint(
      Offset(topCornerRadius, barTop),
      radius: Radius.circular(topCornerRadius),
      clockwise: true,
    );
    path.lineTo(cx - notchHalfWidth, barTop);
    path.cubicTo(
      cx - notchHalfWidth + c1,
      barTop,
      cx - c2,
      barTop + notchDepth,
      cx,
      barTop + notchDepth,
    );
    path.cubicTo(
      cx + c2,
      barTop + notchDepth,
      cx + notchHalfWidth - c1,
      barTop,
      cx + notchHalfWidth,
      barTop,
    );
    path.lineTo(size.width - topCornerRadius, barTop);
    path.arcToPoint(
      Offset(size.width, barTop + topCornerRadius),
      radius: Radius.circular(topCornerRadius),
      clockwise: true,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Drop shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.20), 6.0, false);

    // Fill background
    final fillPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Top border outline
    final borderPath = Path()
      ..moveTo(0, barTop + topCornerRadius)
      ..arcToPoint(
        Offset(topCornerRadius, barTop),
        radius: Radius.circular(topCornerRadius),
        clockwise: true,
      )
      ..lineTo(cx - notchHalfWidth, barTop)
      ..cubicTo(
        cx - notchHalfWidth + c1,
        barTop,
        cx - c2,
        barTop + notchDepth,
        cx,
        barTop + notchDepth,
      )
      ..cubicTo(
        cx + c2,
        barTop + notchDepth,
        cx + notchHalfWidth - c1,
        barTop,
        cx + notchHalfWidth,
        barTop,
      )
      ..lineTo(size.width - topCornerRadius, barTop)
      ..arcToPoint(
        Offset(size.width, barTop + topCornerRadius),
        radius: Radius.circular(topCornerRadius),
        clockwise: true,
      );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _NotchedNavBarPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.barTop != barTop ||
        oldDelegate.topCornerRadius != topCornerRadius ||
        oldDelegate.notchHalfWidth != notchHalfWidth ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.c1 != c1 ||
        oldDelegate.c2 != c2;
  }
}
