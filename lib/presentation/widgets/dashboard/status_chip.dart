import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal status chip used in the system status panel.
class StatusChip extends StatelessWidget {
  final String title;
  final bool isActive;
  final IconData icon;
  final Color color;

  const StatusChip({
    super.key,
    required this.title,
    required this.isActive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? color : AppColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? color : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
