import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final int? selectedIndex;
  final double baseRo;
  final double baseRi;
  final double cornerRadius;
  final Color emptyTrackColor;

  const DonutChartPainter({
    required this.values,
    required this.colors,
    this.selectedIndex,
    this.baseRo = 112.0,
    this.baseRi = 68.0,
    this.cornerRadius = 6.0,
    this.emptyTrackColor = const Color(0xFF202A38),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = values.fold<double>(0.0, (sum, v) => sum + v);

    if (total <= 0) {
      // Empty placeholder ring
      final bgPaint = Paint()
        ..color = emptyTrackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (baseRo - baseRi);
      canvas.drawCircle(center, (baseRo + baseRi) / 2, bgPaint);
      return;
    }

    final count = values.length;

    // Single segment: full annular circle
    if (count == 1) {
      final path = Path()
        ..addOval(Rect.fromCircle(center: center, radius: baseRo))
        ..addOval(Rect.fromCircle(center: center, radius: baseRi));
      path.fillType = PathFillType.evenOdd;
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[0]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      return;
    }

    // Angular gap between wedges (approx 3.5 degrees)
    const gap = 3.5 * math.pi / 180.0;
    double currentAngle = -math.pi / 2;

    for (int i = 0; i < count; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final isSelected = i == selectedIndex;

      // When selected, give subtle outward push and slight expansion
      final push = isSelected ? 3.5 : 0.0;
      final rO = isSelected ? (baseRo + 2.5) : baseRo;
      final rI = isSelected ? (baseRi - 1.5) : baseRi;

      final effGap = math.min(gap, sweep * 0.35);
      final startAngle = currentAngle + (effGap / 2);
      final endAngle = currentAngle + sweep - (effGap / 2);
      final span = endAngle - startAngle;

      if (span > 0.04) {
        final midAngle = (startAngle + endAngle) / 2;
        final segCenter = push > 0
            ? center +
                Offset(push * math.cos(midAngle), push * math.sin(midAngle))
            : center;

        final path = _buildAnnularWedge(
          center: segCenter,
          rO: rO,
          rI: rI,
          startAngle: startAngle,
          endAngle: endAngle,
          cornerRadius: cornerRadius,
        );

        final paint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

        canvas.drawPath(path, paint);
      }

      currentAngle += sweep;
    }
  }

  Path _buildAnnularWedge({
    required Offset center,
    required double rO,
    required double rI,
    required double startAngle,
    required double endAngle,
    required double cornerRadius,
  }) {
    final span = endAngle - startAngle;
    final effRc = math.min(
      cornerRadius,
      math.min((rO - rI) / 3.0, (rI * span) / 3.0),
    );

    final so = math.sqrt(
      math.max(0.0, math.pow(rO - effRc, 2) - math.pow(effRc, 2)),
    );
    final si = math.sqrt(
      math.max(0.0, math.pow(rI + effRc, 2) - math.pow(effRc, 2)),
    );

    final u0 = Offset(math.cos(startAngle), math.sin(startAngle));
    final n0 = Offset(-math.sin(startAngle), math.cos(startAngle));
    final u1 = Offset(math.cos(endAngle), math.sin(endAngle));
    final n1 = Offset(math.sin(endAngle), -math.cos(endAngle));

    final Cf_os = center +
        Offset(so * u0.dx + effRc * n0.dx, so * u0.dy + effRc * n0.dy);
    final Cf_oe = center +
        Offset(so * u1.dx + effRc * n1.dx, so * u1.dy + effRc * n1.dy);
    final Cf_is = center +
        Offset(si * u0.dx + effRc * n0.dx, si * u0.dy + effRc * n0.dy);
    final Cf_ie = center +
        Offset(si * u1.dx + effRc * n1.dx, si * u1.dy + effRc * n1.dy);

    final path = Path();

    // 1. Straight line along start ray from inner to outer
    final T_ray_is = center + Offset(si * u0.dx, si * u0.dy);
    final T_ray_os = center + Offset(so * u0.dx, so * u0.dy);
    path.moveTo(T_ray_is.dx, T_ray_is.dy);
    path.lineTo(T_ray_os.dx, T_ray_os.dy);

    // 2. Fillet 1 (outer start): from start ray to outer circular arc
    final a_f1_start = math.atan2(-n0.dy, -n0.dx);
    final a_f1_end = math.atan2(Cf_os.dy - center.dy, Cf_os.dx - center.dx);
    final sw_f1 = (a_f1_end - a_f1_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_os, radius: effRc),
      a_f1_start,
      sw_f1,
      false,
    );

    // 3. Outer circular arc from Fillet 1 to Fillet 2
    final a_f2_start_outer =
        math.atan2(Cf_oe.dy - center.dy, Cf_oe.dx - center.dx);
    final sw_outer = (a_f2_start_outer - a_f1_end) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: center, radius: rO),
      a_f1_end,
      sw_outer,
      false,
    );

    // 4. Fillet 2 (outer end): from outer circular arc to end ray
    final a_f2_end = math.atan2(-n1.dy, -n1.dx);
    final sw_f2 = (a_f2_end - a_f2_start_outer) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_oe, radius: effRc),
      a_f2_start_outer,
      sw_f2,
      false,
    );

    // 5. Straight line along end ray from outer to inner
    final T_ray_ie = center + Offset(si * u1.dx, si * u1.dy);
    path.lineTo(T_ray_ie.dx, T_ray_ie.dy);

    // 6. Fillet 3 (inner end): from end ray to inner circular arc
    final a_f3_start = math.atan2(-n1.dy, -n1.dx);
    final a_f3_end =
        math.atan2(-(Cf_ie.dy - center.dy), -(Cf_ie.dx - center.dx));
    final sw_f3 = (a_f3_end - a_f3_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_ie, radius: effRc),
      a_f3_start,
      sw_f3,
      false,
    );

    // 7. Inner circular arc from Fillet 3 to Fillet 4 (runs counter-clockwise)
    final a_inner_start =
        math.atan2(Cf_ie.dy - center.dy, Cf_ie.dx - center.dx);
    final a_inner_end =
        math.atan2(Cf_is.dy - center.dy, Cf_is.dx - center.dx);
    var sw_inner = a_inner_end - a_inner_start;
    if (sw_inner > 0) sw_inner -= 2 * math.pi;
    path.arcTo(
      Rect.fromCircle(center: center, radius: rI),
      a_inner_start,
      sw_inner,
      false,
    );

    // 8. Fillet 4 (inner start): from inner circular arc to start ray
    final a_f4_start =
        math.atan2(-(Cf_is.dy - center.dy), -(Cf_is.dx - center.dx));
    final a_f4_end = math.atan2(-n0.dy, -n0.dx);
    final sw_f4 = (a_f4_end - a_f4_start) % (2 * math.pi);
    path.arcTo(
      Rect.fromCircle(center: Cf_is, radius: effRc),
      a_f4_start,
      sw_f4,
      false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.baseRo != baseRo ||
        oldDelegate.baseRi != baseRi ||
        oldDelegate.emptyTrackColor != emptyTrackColor;
  }
}

