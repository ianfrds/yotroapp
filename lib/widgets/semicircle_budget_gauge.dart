import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SemicircleBudgetGauge extends StatelessWidget {
  final double remainingBudget;
  final double totalBudget;
  final double spentAmount;
  final String formattedRemaining;
  final String formattedTotal;
  final String formattedSpent;
  final double usagePercentage;
  final bool isOver;
  final bool isWarn;
  final String? dateRange;
  final int? daysRemaining;

  const SemicircleBudgetGauge({
    super.key,
    required this.remainingBudget,
    required this.totalBudget,
    required this.spentAmount,
    required this.formattedRemaining,
    required this.formattedTotal,
    required this.formattedSpent,
    required this.usagePercentage,
    required this.isOver,
    required this.isWarn,
    this.dateRange,
    this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine gauge arc color based on financial status
    final Color progressColor = isOver
        ? const Color(0xFFEF4444)
        : (isWarn ? const Color(0xFFF59E0B) : const Color(0xFF0066FF));

    final Color trackColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE2E8F0);

    final Color primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color mutedTextColor = isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B);

    // Compute dynamic date range if not explicitly provided
    final now = DateTime.now();
    final effectiveDateRange = dateRange ?? () {
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final fD = firstDay.day.toString().padLeft(2, '0');
      final fM = firstDay.month.toString().padLeft(2, '0');
      final lD = lastDay.day.toString().padLeft(2, '0');
      final lM = lastDay.month.toString().padLeft(2, '0');
      return '$fD/$fM/${firstDay.year} - $lD/$lM/${lastDay.year}';
    }();

    final effectiveDays = daysRemaining ?? () {
      final lastDay = DateTime(now.year, now.month + 1, 0);
      return math.max(0, lastDay.day - now.day);
    }();

    // Progress normalized 0.0 to 1.0
    final double progress = totalBudget > 0
        ? (spentAmount / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Date Range Header
        Center(
          child: Text(
            effectiveDateRange,
            style: GoogleFonts.manrope(
              color: mutedTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Semicircle Speedometer Gauge with Center Info
        Center(
          child: SizedBox(
            width: 270,
            height: 148,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Custom Painted Semicircle Arc & Indicator Thumb
                CustomPaint(
                  size: const Size(270, 148),
                  painter: _SemicircleGaugePainter(
                    progress: progress,
                    progressColor: progressColor,
                    trackColor: trackColor,
                    strokeWidth: 14.0,
                  ),
                ),

                // Center Information inside Dome
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Anggaran Tersisa',
                        style: GoogleFonts.manrope(
                          color: mutedTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedRemaining,
                        style: GoogleFonts.interTight(
                          color: primaryTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          effectiveDays > 0 ? '$effectiveDays Hari Lagi' : 'Hari Terakhir',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. Sub-card: Total Anggaran vs Terpakai (2-column with dotted divider)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // Total Anggaran Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Anggaran',
                      style: GoogleFonts.manrope(
                        color: mutedTextColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTotal,
                      style: GoogleFonts.interTight(
                        color: primaryTextColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Dotted Vertical Divider
              _DottedVerticalDivider(
                height: 32,
                color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1),
              ),

              // Terpakai Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Terpakai',
                      style: GoogleFonts.manrope(
                        color: mutedTextColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedSpent,
                      style: GoogleFonts.interTight(
                        color: primaryTextColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SemicircleGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _SemicircleGaugePainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gauge center is bottom-center with stroke padding
    final center = Offset(size.width / 2, size.height - 10);
    final radius = (size.width / 2) - strokeWidth;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc: 180 degrees from math.pi (left) to 2*math.pi (right)
    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Active progress arc
    final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
    if (sweepAngle > 0.005) {
      canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);

      // Indicator thumb knob at current progress angle
      final currentAngle = math.pi + sweepAngle;
      final thumbX = center.dx + radius * math.cos(currentAngle);
      final thumbY = center.dy + radius * math.sin(currentAngle);
      final thumbCenter = Offset(thumbX, thumbY);

      // White filled circle
      final thumbFillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(thumbCenter, 8.5, thumbFillPaint);

      // Accent border circle
      final thumbBorderPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(thumbCenter, 8.5, thumbBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SemicircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _DottedVerticalDivider extends StatelessWidget {
  final double height;
  final Color color;

  const _DottedVerticalDivider({
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(2, height),
      painter: _DottedLinePainter(color: color),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 3.0;
    const double dashSpace = 3.0;
    double startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, math.min(startY + dashHeight, size.height)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

