import 'package:flutter/material.dart';
import '../../../core/app_config.dart';
import '../../../core/theme/app_colors.dart';

/// Inline notice shown on screens whose actions write to the device
/// (calibration, scheduling) and are therefore no-ops in demo mode.
/// Renders nothing in production builds.
class DemoModeBanner extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const DemoModeBanner({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    if (!kDemoMode) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: c.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo demo: esta pantalla requiere un ESP32 real, los cambios no se guardan.',
              style: TextStyle(
                  color: c.warning, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
