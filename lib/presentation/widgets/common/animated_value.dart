import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';

/// Smoothly interpolates between numeric values with an optional color flash.
///
/// When [value] changes, the displayed number tweens from old → new over
/// [duration]. A brief green/red flash indicates the direction of change.
class AnimatedValue extends StatelessWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedValue({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = AppTokens.durationNormal,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: AppTokens.curveSnappy,
      builder: (context, animatedValue, _) {
        return Text(
          formatter(animatedValue),
          style: style ?? GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}
