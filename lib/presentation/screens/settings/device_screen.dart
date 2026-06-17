import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../models/sensor_data.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../../app.dart';
import '../calibration_screen.dart';
import '../scheduling_screen.dart';

/// Device status, reconnection, calibration, and scheduling access.
class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final sensorAsync = ref.watch(sensorProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Mi dispositivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildDeviceStatusCard(sensorAsync, c, context),
          const SizedBox(height: 16),
          _buildNavRow(
            icon: Icons.tune_rounded,
            color: c.info,
            title: 'Calibración de sensores',
            subtitle: 'pH y EC de 2 puntos',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CalibrationScreen())),
            c: c,
          ),
          const SizedBox(height: 8),
          _buildNavRow(
            icon: Icons.schedule_rounded,
            color: c.success,
            title: 'Programación de actuadores',
            subtitle: 'Bombas, ventiladores',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SchedulingScreen())),
            c: c,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(
      AsyncValue<SensorData> sensorAsync, AppColorScheme c, BuildContext context) {
    return sensorAsync.when(
      data: (sensor) {
        final connected = sensor.conectado ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Row(children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: connected ? c.success : c.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (connected ? c.success : c.error)
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  connected ? 'ESP32 conectado' : 'ESP32 desconectado',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.cardBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline, color: c.textSecondary, size: 16),
                ),
                const SizedBox(width: 12),
                Text('Versión 1.0.0',
                    style: TextStyle(fontSize: 13, color: c.textSecondary)),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.onboardingEsp32),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reconectar ESP32',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.info,
                    side: BorderSide(color: c.cardBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
      error: (_, _) =>
          Text('Error al cargar estado', style: TextStyle(color: c.textSecondary)),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorScheme c,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(color: c.textMuted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: c.textMuted),
        onTap: onTap,
      ),
    );
  }
}
