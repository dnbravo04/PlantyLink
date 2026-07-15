import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// A rectangular button that illuminates when active.
///
/// Replaces native Switch/Toggle for pump and actuator controls.
/// Off state: dark background, subtle border, muted icon.
/// On state: tinted background, bright border, pulsing glow shadow, colored icon
///   with a subtle rotation.
/// Loading state: shimmer border effect.
class IlluminatedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isAutoMode;
  final bool isManualOverride;

  const IlluminatedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.isAutoMode = false,
    this.isManualOverride = false,
  });

  @override
  State<IlluminatedButton> createState() => _IlluminatedButtonState();
}

class _IlluminatedButtonState extends State<IlluminatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.isActive) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(IlluminatedButton old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isActive && old.isActive) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onTap?.call();
            },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          // Pulse glow intensity: 0.2 → 0.45 when active
          final glowAlpha = widget.isActive
              ? 0.2 + _pulseCtrl.value * 0.25
              : 0.0;
          // Subtle icon rotation: 0° → 8° when active
          final iconAngle = widget.isActive
              ? _pulseCtrl.value * 8 * (math.pi / 180)
              : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.color.withValues(alpha: 0.15)
                  : c.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isActive ? widget.color : c.cardBorder,
                width: widget.isActive ? 2 : 1.5,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: glowAlpha),
                        blurRadius: 8 + _pulseCtrl.value * 6,
                        spreadRadius: _pulseCtrl.value * 2,
                      ),
                    ]
                  : null,
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.color,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: iconAngle,
                        child: AnimatedScale(
                          scale: widget.isActive ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.isManualOverride
                                ? Icons.back_hand
                                : widget.icon,
                            color: widget.isActive
                                ? widget.color
                                : c.textMuted,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.isActive
                                ? widget.color
                                : c.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isAutoMode && !widget.isManualOverride) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AUTO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                            ),
                          ),
                        ),
                      ],
                      if (widget.isManualOverride) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MAN',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: c.warning,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? widget.color
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isActive
                                ? widget.color
                                : c.textMuted,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
