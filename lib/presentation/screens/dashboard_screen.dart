import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../providers/app_providers.dart';
import '../providers/trend_alert_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/dashboard/illuminated_button.dart';
import '../widgets/dashboard/simple_metric.dart';
import '../widgets/dashboard/sensor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(sensorProvider);
    final plantaAsync = ref.watch(plantaActivaProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final visualizationMode = ref.watch(visualizationModeProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final sensorRepo = ref.read(sensorRepositoryProvider);

    // Trigger trend checks only when sensorProvider emits a new value —
    // not on every build. ref.listen is the correct Riverpod pattern for
    // side effects from provider changes.
    ref.listen<AsyncValue<SensorData>>(sensorProvider, (_, next) {
      next.whenData((sensor) {
        final trendNotifier = ref.read(trendAlertProvider.notifier);
        trendNotifier.addSensorReading(sensor);
        trendNotifier.checkTrendAlerts(
          ref.read(activePlantProfileProvider).value,
        );
      });
    });

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
              _buildMetrics(sensorAsync, profileAsync, visualizationMode),
              const SizedBox(height: 8),
              _buildAlert(sensorAsync, profileAsync),
              const SizedBox(height: 8),
              _buildTrendAlerts(ref),
              const SizedBox(height: 16),
              _buildPumpControls(sensorAsync, sensorRepo, connectivityAsync),
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
    final c = AppColors.of(context);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            plantaAsync.when(
              loading: () => Text(
                'Cargando...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              error: (_, _) => Text(
                'PlantyLink',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              data: (planta) => Text(
                planta,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildEsp32Chip(sensorAsync, c),
      ],
    );
  }

  Widget _buildEsp32Chip(AsyncValue<SensorData> sensorAsync, dynamic c) {
    return sensorAsync.when(
      data: (sensor) {
        final connected = sensor.conectado ?? false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: connected ? c.success : c.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? c.success : c.error)
                          .withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Conectado' : 'Sin conexión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
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
    String visualizationMode,
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
        final profile = profileAsync.value;

        if (visualizationMode == 'sencilla') {
          return SimpleMetricsGrid(sensor: sensor, profile: profile);
        }

        final ecRaw = sensor.conductividad ?? 0;
        final ecVal = ecRaw > 10 ? ecRaw / 1000 : ecRaw;

        return Column(
          children: [
            // 2×2 grid for critical sensors
            Row(children: [
              Expanded(
                child: SensorCard(
                  label: 'Temperatura',
                  value: (sensor.temperatura ?? 0).toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat_outlined,
                  statusColor: _tempColor(sensor.temperatura ?? 0),
                  isInRange: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SensorCard(
                  label: 'pH',
                  value: (sensor.ph ?? 0).toStringAsFixed(1),
                  unit: '',
                  icon: Icons.science_outlined,
                  statusColor: _phColor(sensor.ph ?? 0, profile),
                  isInRange: profile == null ||
                      ((sensor.ph ?? 0) >= profile.phMin &&
                          (sensor.ph ?? 0) <= profile.phMax),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: SensorCard(
                  label: 'Conductividad',
                  value: ecVal.toStringAsFixed(2),
                  unit: 'mS/cm',
                  icon: Icons.electric_bolt_outlined,
                  statusColor: _ecColor(ecVal, profile),
                  isInRange: profile == null ||
                      (ecVal >= profile.ecMin && ecVal <= profile.ecMax),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // Tank levels as fill bars
            TankLevelCard(
              label: 'Tanque de agua',
              sublabel: _levelLabel(sensor.nivelAguaTanque ?? 0),
              percent: sensor.nivelAguaTanque ?? 0,
              icon: Icons.water_drop_rounded,
              color: _levelColor(sensor.nivelAguaTanque ?? 0),
            ),
            const SizedBox(height: 10),
            TankLevelCard(
              label: 'Fertilizante',
              sublabel: _levelLabel(sensor.nivelFertilizanteTanque ?? 0),
              percent: sensor.nivelFertilizanteTanque ?? 0,
              icon: Icons.eco_rounded,
              color: _levelColor(sensor.nivelFertilizanteTanque ?? 0),
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

  Widget _buildTrendAlerts(WidgetRef ref) {
    final trendState = ref.watch(trendAlertProvider);
    final alerts = trendState.alerts;

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas de tendencia',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.message,
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPumpControls(
    AsyncValue<SensorData> sensorAsync,
    SensorRepository sensorRepo,
    AsyncValue<bool> connectivityAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Control de Bombas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            connectivityAsync.when(
              data: (isOnline) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOnline ? 'En línea' : 'Sin conexión',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
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
            'Error de conexión',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          data: (sensor) {
            final isOnline = connectivityAsync.value ?? true;

            if (!isOnline) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Controles deshabilitados - Sin conexión a internet',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPumpGrid(sensor, sensorRepo, enabled: false),
                ],
              );
            }

            return _buildPumpGrid(sensor, sensorRepo, enabled: true);
          },
        ),
      ],
    );
  }

  /// Builds the 2×2 pump grid. When [enabled] is false every button's
  /// [onTap] is null so taps are ignored while offline.
  Widget _buildPumpGrid(
    SensorData sensor,
    SensorRepository sensorRepo, {
    required bool enabled,
  }) {
    return GridView.count(
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
          // Toggle: pass the OPPOSITE of the current state.
          onTap: enabled
              ? () => sensorRepo.togglePump(
                    'bomba_agua',
                    !(sensor.bombaAgua ?? false),
                  )
              : null,
          isAutoMode: sensor.bombaAguaAuto ?? false,
          isManualOverride: sensor.bombaAguaManualOverride ?? false,
        ),
        IlluminatedButton(
          label: 'Fertilizante',
          icon: Icons.eco,
          isActive: sensor.bombaFertilizante ?? false,
          color: AppColors.accent,
          onTap: enabled
              ? () => sensorRepo.togglePump(
                    'bomba_fertilizante',
                    !(sensor.bombaFertilizante ?? false),
                  )
              : null,
          isAutoMode: sensor.bombaFertilizanteAuto ?? false,
          isManualOverride: sensor.bombaFertilizanteManualOverride ?? false,
        ),
        IlluminatedButton(
          label: 'Ácido',
          icon: Icons.science,
          isActive: sensor.bombaDosificadoraAcido ?? false,
          color: AppColors.warning,
          onTap: enabled
              ? () => sensorRepo.togglePump(
                    'bomba_dosificadora_acido',
                    !(sensor.bombaDosificadoraAcido ?? false),
                  )
              : null,
          isAutoMode: sensor.dosificadoraAcidoAuto ?? false,
          isManualOverride: sensor.dosificadoraAcidoManualOverride ?? false,
        ),
        IlluminatedButton(
          label: 'Base',
          icon: Icons.local_drink,
          isActive: sensor.bombaDosificadoraBasico ?? false,
          color: AppColors.success,
          onTap: enabled
              ? () => sensorRepo.togglePump(
                    'bomba_dosificadora_basico',
                    !(sensor.bombaDosificadoraBasico ?? false),
                  )
              : null,
          isAutoMode: sensor.dosificadoraBaseAuto ?? false,
          isManualOverride: sensor.dosificadoraBaseManualOverride ?? false,
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

  String _levelLabel(double level) {
    if (level < 20) return 'Nivel crítico';
    if (level < 50) return 'Nivel bajo';
    return 'Nivel óptimo';
  }
}
