import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// A shimmering placeholder that mimics the shape of content while loading.
///
/// Use [ShimmerPlaceholder.card] for full card skeletons and
/// [ShimmerPlaceholder.line] for inline text placeholders.
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
  });

  /// A card-shaped shimmer (e.g. sensor card skeleton).
  const ShimmerPlaceholder.card({
    super.key,
    this.width = double.infinity,
    this.height = 72,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTokens.radiusLg)),
  });

  /// A line-shaped shimmer (e.g. text placeholder).
  const ShimmerPlaceholder.line({
    super.key,
    this.width = 120,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppTokens.radiusSm)),
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final baseColor = c.isDark
        ? c.cardBorder
        : const Color(0xFFE8E5DC);
    final highlightColor = c.isDark
        ? c.cardBackground.withValues(alpha: 0.6)
        : const Color(0xFFF5F0E8);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-1.0 + 2.0 * _ctrl.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built shimmer layout matching the dashboard sensor cards.
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 2x2 sensor card skeletons
        const Row(children: [
          Expanded(child: ShimmerPlaceholder.card(height: 78)),
          SizedBox(width: 10),
          Expanded(child: ShimmerPlaceholder.card(height: 78)),
        ]),
        const SizedBox(height: 10),
        const ShimmerPlaceholder.card(height: 78),
        const SizedBox(height: 10),
        // Tank level skeletons
        const ShimmerPlaceholder.card(height: 90),
        const SizedBox(height: 10),
        const ShimmerPlaceholder.card(height: 90),
      ],
    );
  }
}
