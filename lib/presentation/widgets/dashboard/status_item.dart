import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal status chip used in the system status panel.
class StatusItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final IconData icon;
  final Color color;

  const StatusItem({
    super.key,
    required this.title,
    required this.isActive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [color, color.withValues(alpha: 0.8)]
                    : [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isActive ? color : Colors.grey,
                  isActive
                      ? color.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              isActive ? 'Activo' : 'Inactivo',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
