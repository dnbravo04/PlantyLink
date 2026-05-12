import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// A rectangular button that illuminates when active.
///
/// Replaces native Switch/Toggle for pump and actuator controls.
/// Off state: dark background, subtle border, muted icon.
/// On state: tinted background, bright border, glowing shadow, colored icon.
class IlluminatedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const IlluminatedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.cardBorder,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isActive ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      color: isActive ? color : AppColors.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? color : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? color : AppColors.textMuted,
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
