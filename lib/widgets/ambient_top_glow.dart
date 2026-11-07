import 'package:flutter/material.dart';

/// Reusable atmospheric sapphire ambient glow at the top center of the screen.
/// Radiates from top center and seamlessly blends into the dark canvas (#1C2229).
class AmbientTopGlow extends StatelessWidget {
  final double height;

  const AmbientTopGlow({
    super.key,
    this.height = 480.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -1.0),
              radius: 1.25,
              colors: [
                Color(0xFF034A8C), // Deep sapphire peak at top center
                Color(0xFF023668),
                Color(0xFF062343),
                Color(0x001C2229), // Seamless blend to dark canvas #1C2229
              ],
              stops: [0.0, 0.35, 0.68, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

