import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../models/sensor_data.dart';
import '../../../models/trend_alert.dart';
import '../../../models/agronomic/sensor_health.dart';
import '../../providers/app_providers.dart';

/// Sensor drift/health diagnostics card.
///
/// Vivía en la pestaña Agronomía, pero es diagnóstico de hardware, no consejo
/// de cultivo — por eso se muestra en Sistema → Mi dispositivo (Eje 3.2).
class SensorHealthCard extends ConsumerWidget {
  const SensorHealthCard({super.key});

  static const _sensors = ['ph', 'conductividad', 'temperatura'];

  List<SensorReading> _readings(List<SensorData> history, String key) {
    return history
        .map((s) {
          final double? v = switch (key) {
            'ph' => s.ph,
            'conductividad' => s.conductividad,
            'temperatura' => s.temperatura,
            _ => null,
          };
          return v == null
              ? null
              : SensorReading(value: v, timestamp: s.timestamp);
        })
        .whereType<SensorReading>()
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final service = ref.watch(agronomicServiceProvider);
    final history = ref.watch(historyStreamProvider).value ?? const [];

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, size: 18, color: c.primary),
              const SizedBox(width: AppTokens.spacingSm),
              Text(
                'Salud de sensores',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingSm),
          for (var i = 0; i < _sensors.length; i++) ...[
            _HealthRow(
              c: c,
              health: service.detectDrift(
                _sensors[i],
                _readings(history, _sensors[i]),
              ),
            ),
            if (i < _sensors.length - 1)
              Divider(color: c.cardBorder, height: AppTokens.spacingLg),
          ],
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.c, required this.health});

  final AppColorScheme c;
  final SensorHealth health;

  Color get _color => switch (health.status) {
        SensorHealthStatus.ok => c.success,
        SensorHealthStatus.warning => c.warning,
        SensorHealthStatus.critical => c.error,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTokens.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    health.sensorLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    child: Text(
                      health.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                health.recommendation,
                style: TextStyle(
                  fontSize: 12.5,
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
