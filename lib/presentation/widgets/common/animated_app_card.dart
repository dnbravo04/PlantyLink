import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// A card wrapper that fades + slides in from below on first build.
///
/// Use [delay] for stagger effects: each card in a list gets a
/// progressively larger delay so they cascade into view.
class AnimatedAppCard extends StatefulWidget {
  final Widget child;
  final int delay; // milliseconds before animation starts
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;

  const AnimatedAppCard({
    super.key,
    required this.child,
    this.delay = 0,
    this.padding = const EdgeInsets.all(0),
    this.borderRadius,
  });

  @override
  State<AnimatedAppCard> createState() => _AnimatedAppCardState();
}

class _AnimatedAppCardState extends State<AnimatedAppCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppTokens.durationSlow,
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: AppTokens.curveSnappy);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppTokens.curveSnappy));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(AppTokens.radiusLg);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: radius,
            border: Border.all(color: c.cardBorder, width: 1),
            boxShadow: AppTokens.shadowSubtle(c.isDark),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
