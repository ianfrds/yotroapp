import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Smooth circular audio spectrum used by the voice recorder.
///
/// While the microphone is recording but the input is silent, the visualizer
/// remains a thin circular outline with a slow travelling highlight. Voice
/// energy expands that outline into a continuous radial waveform.
class CircularSpectrumVisualizer extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final VoidCallback? onCenterTap;
  final double size;

  const CircularSpectrumVisualizer({
    super.key,
    required this.isListening,
    this.soundLevel = 0,
    this.onCenterTap,
    this.size = 220,
  });

  @override
  State<CircularSpectrumVisualizer> createState() =>
      _CircularSpectrumVisualizerState();
}

class _CircularSpectrumVisualizerState extends State<CircularSpectrumVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _motionController;
  late final AnimationController _energyController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _syncWithInput(immediate: true);
  }

  @override
  void didUpdateWidget(covariant CircularSpectrumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.soundLevel != widget.soundLevel) {
      _syncWithInput();
    }
  }

  double get _gatedEnergy {
    if (!widget.isListening) return 0;
    final input = widget.soundLevel.clamp(0.0, 1.0);
    const noiseGate = .065;
    if (input <= noiseGate) return 0;
    final normalized = ((input - noiseGate) / (1 - noiseGate)).clamp(0.0, 1.0);
    return math.pow(normalized, .76).toDouble();
  }

  void _syncWithInput({bool immediate = false}) {
    final target = _gatedEnergy;

    if (widget.isListening) {
      if (!_motionController.isAnimating) _motionController.repeat();
    } else {
      _motionController.stop();
    }

    if (immediate) {
      _energyController.value = target;
      return;
    }

    final isAttack = target > _energyController.value;
    _energyController.duration = Duration(
      milliseconds: isAttack ? 80 : 240,
    );
    _energyController.animateTo(
      target,
      curve: isAttack ? Curves.easeOutCubic : Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: widget.onCenterTap != null,
      label: widget.isListening
          ? 'Perekaman aktif. Ketuk spektrum untuk menjeda.'
          : 'Perekaman dijeda. Ketuk spektrum untuk melanjutkan.',
      child: GestureDetector(
        key: const Key('voice_spectrum_surface'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onCenterTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _motionController,
            _energyController,
          ]),
          builder: (context, _) {
            return RepaintBoundary(
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _CircularSpectrumPainter(
                  progress: _motionController.value,
                  isListening: widget.isListening,
                  voiceEnergy: _energyController.value,
                  isDark: isDark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularSpectrumPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final double voiceEnergy;
  final bool isDark;

  const _CircularSpectrumPainter({
    required this.progress,
    required this.isListening,
    required this.voiceEnergy,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    final radius = side * .305;
    final energy = voiceEnergy.clamp(0.0, 1.0);
    final phase = progress * math.pi * 2;
    final spectrumBounds = Rect.fromCircle(center: center, radius: radius);

    final outlineColor = isDark
        ? Colors.white.withValues(alpha: isListening ? .42 : .16)
        : const Color(0xFF0F172A).withValues(alpha: isListening ? .34 : .14);
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..isAntiAlias = true
      ..color = outlineColor;
    canvas.drawCircle(center, radius, outlinePaint);

    // Standby movement: the geometry stays perfectly circular while a narrow
    // highlight travels over the outline. This runs whenever recording is on.
    if (isListening) {
      final standbyPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            const Color(0x0055C7FF),
            const Color(0xFF55C7FF).withValues(alpha: .72),
            Colors.white.withValues(alpha: .92),
            const Color(0x0055C7FF),
            Colors.transparent,
          ],
          stops: const [0, .58, .78, .84, .9, 1],
          transform: GradientRotation(phase),
        ).createShader(spectrumBounds);
      canvas.drawCircle(center, radius, standbyPaint);
    }

    if (energy <= .002) return;

    const sampleCount = 144;
    final innerPoints = <Offset>[];
    final outerPoints = <Offset>[];
    final amplitude = side * (.014 + .082 * energy) * energy;

    for (var index = 0; index < sampleCount; index++) {
      final angle = (index / sampleCount) * math.pi * 2;
      final harmonic = math.sin(angle * 3 - phase * 1.4) * .42 +
          math.sin(angle * 7 + phase * 2.05) * .28 +
          math.cos(angle * 11 - phase * 2.6) * .18 +
          math.sin(angle * 17 + phase * 1.2) * .12;
      final response = (.28 + harmonic.abs() * .72).clamp(0.0, 1.0);
      final outerRadius = radius + amplitude * response;
      final innerRadius = radius - amplitude * (.12 + response * .2);

      outerPoints.add(Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      ));
      innerPoints.add(Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      ));
    }

    final outerPath = _smoothClosedPath(outerPoints);
    final innerPath = _smoothClosedPath(innerPoints);

    // Fine radial filaments give the ring a spectrum texture without the
    // jagged visual produced by large equalizer bars.
    final filamentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .55
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = (isDark ? const Color(0xFF55C7FF) : const Color(0xFF02539A))
          .withValues(alpha: .1 + energy * .18);
    for (var index = 0; index < sampleCount; index += 2) {
      canvas.drawLine(innerPoints[index], outerPoints[index], filamentPaint);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + energy * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..color = const Color(0xFF147DFF).withValues(alpha: .12 * energy);
    canvas.drawPath(outerPath, glowPaint);

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9 + energy * .75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = (isDark ? const Color(0xFF7DDCFF) : const Color(0xFF02539A))
          .withValues(alpha: .56 + energy * .32);
    canvas.drawPath(outerPath, outerPaint);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = (isDark ? Colors.white : const Color(0xFF147DFF))
          .withValues(alpha: .18 + energy * .18);
    canvas.drawPath(innerPath, innerPaint);
  }

  Path _smoothClosedPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    final firstMidpoint = Offset.lerp(points.last, points.first, .5)!;
    path.moveTo(firstMidpoint.dx, firstMidpoint.dy);
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final midpoint = Offset.lerp(current, next, .5)!;
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CircularSpectrumPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.voiceEnergy != voiceEnergy ||
        oldDelegate.isDark != isDark;
  }
}
