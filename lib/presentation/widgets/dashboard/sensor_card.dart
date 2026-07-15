import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../providers/data_staleness_provider.dart';
import '../common/animated_value.dart';
import '../common/pulsing_dot.dart';

/// Compact card for a single sensor reading (pH, Temp, EC).
/// Features a colored left-edge accent bar, animated value, and pulsing status dot.
///
/// [freshness] dims the numeric value and calms the status dot when the data
/// is stale or the device is offline, so frozen readings never look live.
class SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color statusColor;
  final bool isInRange;
  final DataFreshness freshness;
  final double? numericValue;
  final String Function(double)? valueFormatter;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.statusColor,
    required this.isInRange,
    this.freshness = DataFreshness.live,
    this.numericValue,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final valueColor = switch (freshness) {
      DataFreshness.live => c.textPrimary,
      DataFreshness.stale => c.textMuted,
      DataFreshness.offline => c.textDisabled,
    };
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: c.cardBorder, width: 1),
        boxShadow: AppTokens.shadowSubtle(c.isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Row(
          children: [
            // Left accent bar
            Container(width: 4, color: statusColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Label + value
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: c.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          numericValue != null && valueFormatter != null
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedValue(
                                      value: numericValue!,
                                      formatter: valueFormatter!,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: valueColor,
                                        height: 1.1,
                                      ),
                                    ),
                                    if (unit.isNotEmpty)
                                      Text(
                                        ' $unit',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: c.textMuted,
                                        ),
                                      ),
                                  ],
                                )
                              : RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: value,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: valueColor,
                                          height: 1.1,
                                        ),
                                      ),
                                      if (unit.isNotEmpty)
                                        TextSpan(
                                          text: ' $unit',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: c.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                    // Pulsing status dot — severity follows data freshness.
                    switch (freshness) {
                      DataFreshness.live => PulsingDot(
                          color: statusColor,
                          isOffline: !isInRange && statusColor == c.textMuted,
                        ),
                      DataFreshness.stale => PulsingDot(
                          color: c.warning,
                          pulseDuration: const Duration(seconds: 3),
                        ),
                      DataFreshness.offline => PulsingDot(
                          color: c.textMuted,
                          isOffline: true,
                        ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal fill-bar card for tank levels (water, fertilizer).
/// Features animated fill with a subtle wave effect on the surface.
class TankLevelCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final double percent; // 0.0–100.0
  final IconData icon;
  final Color color;
  final DataFreshness freshness;

  const TankLevelCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.percent,
    required this.icon,
    required this.color,
    this.freshness = DataFreshness.live,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = (percent / 100).clamp(0.0, 1.0);
    final percentColor = switch (freshness) {
      DataFreshness.live => color,
      DataFreshness.stale => c.textMuted,
      DataFreshness.offline => c.textDisabled,
    };

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: c.cardBorder, width: 1),
        boxShadow: AppTokens.shadowSubtle(c.isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w700, color: percentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fill bar with wave overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: c.cardBorder,
                  ),
                  // Animated fill
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final fillWidth = constraints.maxWidth * fill;
                      return AnimatedContainer(
                        duration: AppTokens.durationSlow,
                        curve: AppTokens.curveSnappy,
                        height: 10,
                        width: fillWidth,
                        child: _WaveFillBar(color: color, isCritical: percent < 20),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Animated wave fill inside the tank bar.
class _WaveFillBar extends StatefulWidget {
  final Color color;
  final bool isCritical;

  const _WaveFillBar({required this.color, required this.isCritical});

  @override
  State<_WaveFillBar> createState() => _WaveFillBarState();
}

class _WaveFillBarState extends State<_WaveFillBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _WavePainter(
            color: widget.color,
            phase: _ctrl.value * 2 * math.pi,
            isCritical: widget.isCritical,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double phase;
  final bool isCritical;

  _WavePainter({
    required this.color,
    required this.phase,
    required this.isCritical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color.withValues(alpha: 0.7), color],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, 0);

    // Small wave on the right edge (surface of liquid)
    final waveHeight = isCritical ? 2.0 : 1.2;
    for (double x = 0; x <= size.width; x++) {
      final y = math.sin((x / size.width) * 4 * math.pi + phase) * waveHeight;
      path.lineTo(x, size.height * 0.3 + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      phase != old.phase || color != old.color;
}
