import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fluid Wave Orb Visualizer.
/// Renders an ethereal, glowing multi-lobed resonant audio orb matching the user's design.
/// Two intertwined harmonic ribbons (5 lobes) glow in electric sapphire/cyan,
/// undulating and rotating fluidly with speech sound level.
class CircularSpectrumVisualizer extends StatefulWidget {
  final bool isListening;
  final double soundLevel; // normalized 0.0 to 1.0 (or dB)
  final VoidCallback? onCenterTap;
  final double size;

  const CircularSpectrumVisualizer({
    super.key,
    required this.isListening,
    this.soundLevel = 0.0,
    this.onCenterTap,
    this.size = 220.0,
  });

  @override
  State<CircularSpectrumVisualizer> createState() => _CircularSpectrumVisualizerState();
}

class _CircularSpectrumVisualizerState extends State<CircularSpectrumVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CircularSpectrumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft volumetric bloom
              if (widget.isListening)
                Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0066FF).withOpacity(isDark ? 0.25 : 0.12),
                        const Color(0xFF38BDF8).withOpacity(isDark ? 0.10 : 0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),

              // Fluid Harmonic Wave Painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _FluidWaveOrbPainter(
                  progress: _controller.value,
                  isListening: widget.isListening,
                  soundLevel: widget.soundLevel,
                  isDark: isDark,
                ),
              ),

              // Center core button with mic icon
              GestureDetector(
                onTap: widget.onCenterTap,
                child: Container(
                  width: widget.size * 0.32,
                  height: widget.size * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isDark ? const Color(0xFF091322) : Colors.white).withOpacity(0.85),
                    border: Border.all(
                      color: widget.isListening
                          ? const Color(0xFF38BDF8).withOpacity(0.55)
                          : (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF0066FF) : const Color(0xFF38BDF8))
                            .withOpacity(widget.isListening ? 0.35 : 0.08),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                      color: widget.isListening
                          ? const Color(0xFF38BDF8)
                          : (isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B)),
                      size: widget.size * 0.13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FluidWaveOrbPainter extends CustomPainter {
  final double progress;
  final bool isListening;
  final double soundLevel;
  final bool isDark;

  _FluidWaveOrbPainter({
    required this.progress,
    required this.isListening,
    required this.soundLevel,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.28;

    final normalizedLevel = soundLevel.clamp(0.0, 1.0);
    // Dynamic amplitude: increases with sound level when speaking
    final double amplitude = isListening
        ? (baseRadius * 0.22 + normalizedLevel * baseRadius * 0.35)
        : (baseRadius * 0.12);

    final angleStep = (2 * math.pi) / 120;

    // Build Loop 1 and Loop 2 (intertwined 5-lobed resonant harmonic loops)
    final path1 = Path();
    final path2 = Path();
    final path3 = Path(); // third subtle harmonic ring

    final rotationPhase = progress * 2 * math.pi;

    for (int i = 0; i <= 120; i++) {
      final theta = i * angleStep;

      // 5-lobed standing wave + second harmonic
      final waveA1 = math.sin(5 * theta + rotationPhase);
      final waveB1 = math.cos(3 * theta - rotationPhase * 0.8) * 0.35;
      final r1 = baseRadius + amplitude * (waveA1 + waveB1);

      // Loop 2 is phase-shifted by PI (creating the crossing mobius knots)
      final waveA2 = math.sin(5 * theta + rotationPhase + math.pi);
      final waveB2 = math.cos(3 * theta + rotationPhase * 0.8) * 0.35;
      final r2 = baseRadius + amplitude * (waveA2 + waveB2);

      // Loop 3: faint inner guide orbital
      final waveA3 = math.sin(4 * theta - rotationPhase * 1.2) * 0.5;
      final r3 = baseRadius * 0.85 + amplitude * 0.35 * waveA3;

      final p1 = Offset(center.dx + r1 * math.cos(theta), center.dy + r1 * math.sin(theta));
      final p2 = Offset(center.dx + r2 * math.cos(theta), center.dy + r2 * math.sin(theta));
      final p3 = Offset(center.dx + r3 * math.cos(theta), center.dy + r3 * math.sin(theta));

      if (i == 0) {
        path1.moveTo(p1.dx, p1.dy);
        path2.moveTo(p2.dx, p2.dy);
        path3.moveTo(p3.dx, p3.dy);
      } else {
        path1.lineTo(p1.dx, p1.dy);
        path2.lineTo(p2.dx, p2.dy);
        path3.lineTo(p3.dx, p3.dy);
      }
    }
    path1.close();
    path2.close();
    path3.close();

    // 1. Draw Outer Ethereal Bloom (Layer 1)
    if (isListening) {
      final outerGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0)
        ..color = const Color(0xFF0066FF).withOpacity(isDark ? 0.40 : 0.22);
      canvas.drawPath(path1, outerGlowPaint);
      canvas.drawPath(path2, outerGlowPaint);

      // 2. Mid Glow Paint (Layer 2)
      final midGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0)
        ..color = const Color(0xFF38BDF8).withOpacity(isDark ? 0.70 : 0.45);
      canvas.drawPath(path1, midGlowPaint);
      canvas.drawPath(path2, midGlowPaint);

      // Subtle third guide path
      final guidePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF38BDF8).withOpacity(isDark ? 0.25 : 0.15);
      canvas.drawPath(path3, guidePaint);
    } else {
      // Resting subtle glow
      final idleGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
        ..color = (isDark ? const Color(0xFF0066FF) : const Color(0xFF38BDF8)).withOpacity(0.20);
      canvas.drawPath(path1, idleGlowPaint);
      canvas.drawPath(path2, idleGlowPaint);
    }

    // 3. Crisp High-Brightness Core Ribbons (Layer 3)
    final corePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = isListening
          ? (isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0284C7))
          : (isDark ? const Color(0xFF8EA4BE).withOpacity(0.4) : const Color(0xFF94A3B8).withOpacity(0.4));
    canvas.drawPath(path1, corePaint1);

    final corePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = isListening
          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9))
          : (isDark ? const Color(0xFF8EA4BE).withOpacity(0.3) : const Color(0xFF94A3B8).withOpacity(0.3));
    canvas.drawPath(path2, corePaint2);
  }

  @override
  bool shouldRepaint(covariant _FluidWaveOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isListening != isListening ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isDark != isDark;
  }
}
