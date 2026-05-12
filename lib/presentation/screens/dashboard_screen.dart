import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/dashboard/circular_metric.dart';
import '../widgets/dashboard/illuminated_button.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorProvider);
    final plantaAsync = ref.watch(plantaActivaProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final sensorRepo = ref.read(sensorRepositoryProvider);

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(plantaAsync, sensorAsync, context),
              const SizedBox(height: 20),
              _buildMetrics(sensorAsync, profileAsync),
              const SizedBox(height: 8),
              _buildAlert(sensorAsync, profileAsync),
              const SizedBox(height: 16),
              _buildPumpControls(sensorAsync, sensorRepo),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    AsyncValue<String> plantaAsync,
    AsyncValue<SensorData> sensorAsync,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HydroTrack',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            plantaAsync.when(
              loading: () => const Text(
                '...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              error: (_, _) => const Text(
                'Sin cultivo',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              data: (planta) => GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/plantas'),
                child: Text(
                  planta,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildEsp32Chip(sensorAsync),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.history_outlined,
          onTap: () => Navigator.pushNamed(context, '/history'),
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.eco_outlined,
          onTap: () => Navigator.pushNamed(context, '/plantas'),
        ),
        const SizedBox(width: 8),
        _IconButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildEsp32Chip(AsyncValue<SensorData> sensorAsync) {
    return sensorAsync.when(
      data: (sensor) {
        final connected = sensor.conectado ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Conectado' : 'Desconectado',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetrics(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
  ) {
    return sensorAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
        ),
      ),
      error: (_, _) => const Center(
        child: Text(
          'Error de conexión',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (sensor) {
        final profile = profileAsync.valueOrNull;
        final ecRaw = sensor.conductividad ?? 0;
        final ecVal = ecRaw > 10 ? ecRaw / 1000 : ecRaw;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 12,
          children: [
            CircularMetric(
              value: sensor.temperatura ?? 0,
              maxValue: 50,
              unit: '\u00b0C',
              label: 'Temp',
              color: _tempColor(sensor.temperatura ?? 0),
              icon: Icons.thermostat_outlined,
            ),
            CircularMetric(
              value: sensor.ph ?? 0,
              maxValue: 14,
              unit: '',
              label: 'pH',
              color: _phColor(sensor.ph ?? 0, profile),
              icon: Icons.science_outlined,
            ),
            CircularMetric(
              value: ecVal,
              maxValue: 3,
              unit: 'mS/cm',
              label: 'EC',
              color: _ecColor(ecVal, profile),
              icon: Icons.electric_bolt_outlined,
            ),
            CircularMetric(
              value: sensor.nivelAguaTanque ?? 0,
              maxValue: 100,
              unit: '%',
              label: 'Agua',
              color: _levelColor(sensor.nivelAguaTanque ?? 0),
              icon: Icons.water_drop_outlined,
            ),
            CircularMetric(
              value: sensor.nivelFertilizanteTanque ?? 0,
              maxValue: 100,
              unit: '%',
              label: 'Fertilizante',
              color: _levelColor(sensor.nivelFertilizanteTanque ?? 0),
              icon: Icons.eco_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlert(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
  ) {
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return sensorAsync.when(
          data: (sensor) {
            final ecRaw = sensor.conductividad ?? 0;
            final ec = ecRaw > 10 ? ecRaw / 1000 : ecRaw;
            final outOfRange = ec < profile.ecMin || ec > profile.ecMax;
            if (!outOfRange) return const SizedBox.shrink();
            return Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EC ${ec.toStringAsFixed(2)} mS/cm fuera de rango. '
                    'Óptimo: ${profile.ecMin} – ${profile.ecMax} mS/cm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPumpControls(
    AsyncValue<SensorData> sensorAsync,
    SensorRepository sensorRepo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Control de Bombas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        sensorAsync.when(
          loading: () => const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const Text(
            'Error',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          data: (sensor) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: [
              IlluminatedButton(
                label: 'Agua',
                icon: Icons.water_drop,
                isActive: sensor.bombaAgua ?? false,
                color: AppColors.info,
                onTap: () => sensorRepo.togglePump('bomba_agua', true),
              ),
              IlluminatedButton(
                label: 'Fertilizante',
                icon: Icons.eco,
                isActive: sensor.bombaFertilizante ?? false,
                color: AppColors.accent,
                onTap: () => sensorRepo.togglePump('bomba_fertilizante', true),
              ),
              IlluminatedButton(
                label: 'Ácido',
                icon: Icons.science,
                isActive: sensor.bombaDosificadoraAcido ?? false,
                color: AppColors.warning,
                onTap: () => sensorRepo.togglePump('bomba_dosificadora_acido', true),
              ),
              IlluminatedButton(
                label: 'Base',
                icon: Icons.local_drink,
                isActive: sensor.bombaDosificadoraBasico ?? false,
                color: AppColors.success,
                onTap: () => sensorRepo.togglePump('bomba_dosificadora_basico', true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _tempColor(double temp) {
    if (temp < 15 || temp > 30) return AppColors.error;
    return AppColors.success;
  }

  Color _phColor(double ph, PlantProfile? profile) {
    if (profile == null) return AppColors.success;
    if (ph < profile.phMin || ph > profile.phMax) return AppColors.error;
    return AppColors.success;
  }

  Color _ecColor(double ec, PlantProfile? profile) {
    if (profile == null) return AppColors.success;
    if (ec < profile.ecMin || ec > profile.ecMax) return AppColors.error;
    return AppColors.success;
  }

  Color _levelColor(double level) {
    if (level < 20) return AppColors.error;
    if (level < 50) return AppColors.warning;
    return AppColors.success;
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}
