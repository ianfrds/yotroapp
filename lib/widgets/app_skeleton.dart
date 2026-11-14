import 'package:flutter/material.dart';

/// Animated shimmer wrapper that sweeps a highlight gradient across its child.
class AppSkeletonShimmer extends StatefulWidget {
  final Widget child;

  const AppSkeletonShimmer({
    super.key,
    required this.child,
  });

  @override
  State<AppSkeletonShimmer> createState() => _AppSkeletonShimmerState();
}

class _AppSkeletonShimmerState extends State<AppSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF18202C) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF283548) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = bounds.width;
            final progress = _controller.value;
            final dx = progress * (width * 2) - width;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: dx / width),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Generic rectangular skeleton placeholder.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1E2837) : const Color(0xFFE2E8F0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton placeholder matching the Dashboard Hero Balance Card.
class SkeletonHeroCard extends StatelessWidget {
  const SkeletonHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121824) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFE2E8F0);

    return AppSkeletonShimmer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonBox(width: 90, height: 14, borderRadius: 6),
                SkeletonBox(width: 70, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 14),
            const SkeletonBox(width: 190, height: 34, borderRadius: 8),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: SkeletonBox(height: 52, borderRadius: 12),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SkeletonBox(height: 52, borderRadius: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder matching a single TransactionTile.
class SkeletonTransactionTile extends StatelessWidget {
  const SkeletonTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final circleColor =
        isDark ? const Color(0xFF1E2837) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 11, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 72, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Skeleton placeholder rendering a column of TransactionTile rows.
class SkeletonTransactionList extends StatelessWidget {
  final int count;

  const SkeletonTransactionList({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.04)
        : const Color(0xFFF1F5F9);

    return AppSkeletonShimmer(
      child: Column(
        children: List.generate(count, (index) {
          return Column(
            children: [
              const SkeletonTransactionTile(),
              if (index < count - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 64,
                  endIndent: 14,
                  color: dividerColor,
                ),
            ],
          );
        }),
      ),
    );
  }
}
