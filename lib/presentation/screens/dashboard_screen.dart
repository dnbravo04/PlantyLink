import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/haptics.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';
import '../providers/app_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/trend_alert_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/animated_app_card.dart';
import '../widgets/common/shimmer_placeholder.dart';
import '../widgets/dashboard/simple_metric.dart';
import '../widgets/dashboard/sensor_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final sensorAsync = ref.watch(sensorProvider);
    final plantaAsync = ref.watch(plantaActivaProvider);
    final profileAsync = ref.watch(activePlantProfileProvider);
    final visualizationMode = ref.watch(visualizationModeProvider);
    final userAsync = ref.watch(userProfileProvider);

    final sensorRepo = ref.read(sensorRepositoryProvider);

    if (sensorRepo != null) {
      ref.listen<AsyncValue<SensorData>>(sensorProvider, (_, next) {
        next.whenData((sensor) {
          final trendNotifier = ref.read(trendAlertProvider.notifier);
          trendNotifier.addSensorReading(sensor);
          trendNotifier.checkTrendAlerts(
            ref.read(activePlantProfileProvider).value,
          );
        });
      });
    }

    // ── Empty state: no device linked ──
    if (sensorRepo == null) {
      return AppScaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustrated empty state
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primary.withValues(alpha: 0.08),
                    ),
                    child: Icon(Icons.eco_rounded, size: 56, color: c.primary.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 24),
                  Text('Sin dispositivo vinculado',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    'Vincula tu ESP32 para comenzar a\nmonitorear tu cultivo en tiempo real.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: c.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      AppHaptics.light();
                      ref.read(selectedTabIndexProvider.notifier).select(2);
                    },
                    icon: const Icon(Icons.memory_rounded, size: 18),
                    label: const Text('Ir a Sistema'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.cardBackground,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          // Force re-read — Riverpod stream will emit new data
          ref.invalidate(sensorProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),
              _buildHeader(plantaAsync, sensorAsync, userAsync, c),
              const SizedBox(height: 16),
              _DashboardViewToggle(visualizationMode: visualizationMode),
              const SizedBox(height: 16),
              _buildMetrics(sensorAsync, profileAsync, visualizationMode, c),
              const SizedBox(height: 8),
              _buildAlert(sensorAsync, profileAsync, c),
              const SizedBox(height: 8),
              _buildTrendAlerts(ref, c),
              _buildAlertHistory(ref, context, c),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with user name ─────────────────────────────────────────────

  Widget _buildHeader(
    AsyncValue<String> plantaAsync,
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<Map<String, dynamic>> userAsync,
    AppColorScheme c,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    final userName = userAsync.whenOrNull(
      data: (u) => u['nombre']?.toString(),
    );
    final greetingText = userName != null && userName.isNotEmpty
        ? '$greeting, $userName'
        : greeting;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        if (userName != null && userName.isNotEmpty) ...[
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary, c.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                userName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingText,
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
                    fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary,
                  ),
                ),
                error: (_, _) => Text(
                  'PlantyLink',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary,
                  ),
                ),
                data: (planta) => Text(
                  planta,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800, color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              sensorAsync.when(
                data: (sensor) => Text(
                  'Última lectura: ${DateFormat('HH:mm:ss').format(sensor.timestamp)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textMuted),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => Text(
                  'Sin datos',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
        _buildEsp32Chip(sensorAsync, c),
      ],
    );
  }

  Widget _buildEsp32Chip(AsyncValue<SensorData> sensorAsync, AppColorScheme c) {
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
                      color: (connected ? c.success : c.error).withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                connected ? 'Conectado' : 'Sin conexión',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary,
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

  // ── Metrics ─────────────────────────────────────────────────────────────

  Widget _buildMetrics(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
    String visualizationMode,
    AppColorScheme c,
  ) {
    return sensorAsync.when(
      loading: () => const DashboardShimmer(),
      error: (_, _) => Center(
        child: Text('Error de conexión', style: TextStyle(color: c.textSecondary)),
      ),
      data: (sensor) {
        final profile = profileAsync.value;

        if (visualizationMode == 'sencilla') {
          return SimpleMetricsGrid(sensor: sensor, profile: profile);
        }

        final ecVal = sensor.ecNormalized;

        return Column(
          children: [
            Row(children: [
              Expanded(
                child: AnimatedAppCard(
                  delay: 0,
                  child: SensorCard(
                    label: 'Temperatura',
                    value: (sensor.temperatura ?? 0).toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat_outlined,
                    statusColor: _tempColor(sensor.temperatura ?? 0, c),
                    isInRange: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedAppCard(
                  delay: 80,
                  child: SensorCard(
                    label: 'pH',
                    value: (sensor.ph ?? 0).toStringAsFixed(1),
                    unit: '',
                    icon: Icons.science_outlined,
                    statusColor: _phColor(sensor.ph ?? 0, profile, c),
                    isInRange: profile == null ||
                        ((sensor.ph ?? 0) >= profile.phMin &&
                            (sensor.ph ?? 0) <= profile.phMax),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: AnimatedAppCard(
                  delay: 160,
                  child: SensorCard(
                    label: 'Conductividad',
                    value: ecVal.toStringAsFixed(2),
                    unit: 'mS/cm',
                    icon: Icons.electric_bolt_outlined,
                    statusColor: _ecColor(ecVal, profile, c),
                    isInRange: profile == null ||
                        (ecVal >= profile.ecMin && ecVal <= profile.ecMax),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            AnimatedAppCard(
              delay: 240,
              child: TankLevelCard(
                label: 'Tanque de agua',
                sublabel: _levelLabel(sensor.nivelAguaTanque ?? 0),
                percent: sensor.nivelAguaTanque ?? 0,
                icon: Icons.water_drop_rounded,
                color: _levelColor(sensor.nivelAguaTanque ?? 0, c),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedAppCard(
              delay: 320,
              child: TankLevelCard(
                label: 'Fertilizante',
                sublabel: _levelLabel(sensor.nivelFertilizanteTanque ?? 0),
                percent: sensor.nivelFertilizanteTanque ?? 0,
                icon: Icons.eco_rounded,
                color: _levelColor(sensor.nivelFertilizanteTanque ?? 0, c),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Alerts ──────────────────────────────────────────────────────────────

  Widget _buildAlert(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
    AppColorScheme c,
  ) {
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return sensorAsync.when(
          data: (sensor) {
            final ec = sensor.ecNormalized;
            final outOfRange = ec < profile.ecMin || ec > profile.ecMax;
            if (!outOfRange) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(color: c.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: c.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EC ${ec.toStringAsFixed(2)} mS/cm fuera de rango. '
                      'Óptimo: ${profile.ecMin} – ${profile.ecMax} mS/cm',
                      style: TextStyle(
                        fontSize: 12, color: c.warning, fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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

  Widget _buildTrendAlerts(WidgetRef ref, AppColorScheme c) {
    final trendState = ref.watch(trendAlertProvider);
    final alerts = trendState.alerts;

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas de tendencia',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...alerts.map(
          (alert) => Dismissible(
            key: ValueKey(alert.hashCode),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              AppHaptics.light();
              ref.read(trendAlertProvider.notifier).dismissAlert(alert);
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: c.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Icon(Icons.delete_outline_rounded, color: c.error, size: 20),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(color: c.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: c.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.message,
                        style: TextStyle(
                          fontSize: 12, color: c.warning, fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }

  Widget _buildAlertHistory(WidgetRef ref, BuildContext context, AppColorScheme c) {
    final alerts = ref.watch(alertHistoryProvider).value ?? [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: Icon(Icons.history_rounded, color: c.textMuted, size: 18),
          title: Text(
            'Historial de alertas (${alerts.length})',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted,
            ),
          ),
          children: alerts.take(5).map((a) => _AlertHistoryTile(alert: a, c: c)).toList(),
        ),
      ),
    );
  }

  // ── Color helpers ─────────────────────────────────────────────────────

  Color _tempColor(double temp, AppColorScheme c) {
    if (temp < 15 || temp > 30) return c.error;
    return c.success;
  }

  Color _phColor(double ph, PlantProfile? profile, AppColorScheme c) {
    if (profile == null) return c.success;
    if (ph < profile.phMin || ph > profile.phMax) return c.error;
    return c.success;
  }

  Color _ecColor(double ec, PlantProfile? profile, AppColorScheme c) {
    if (profile == null) return c.success;
    if (ec < profile.ecMin || ec > profile.ecMax) return c.error;
    return c.success;
  }

  Color _levelColor(double level, AppColorScheme c) {
    if (level < 20) return c.error;
    if (level < 50) return c.warning;
    return c.success;
  }

  String _levelLabel(double level) {
    if (level < 20) return 'Nivel crítico';
    if (level < 50) return 'Nivel bajo';
    return 'Nivel óptimo';
  }
}

// ── Dashboard view toggle (segmented control) ──────────────────────────────

class _DashboardViewToggle extends ConsumerWidget {
  final String visualizationMode;
  const _DashboardViewToggle({required this.visualizationMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          _buildSegment(
            label: 'Detalle',
            icon: Icons.speed_outlined,
            selected: visualizationMode != 'sencilla',
            c: c,
            onTap: () {
              AppHaptics.selection();
              ref.read(profileServiceProvider)?.updateUserSettings(
                  {'modo_visualizacion': 'tecnica'});
            },
          ),
          _buildSegment(
            label: 'Resumen',
            icon: Icons.grid_view_rounded,
            selected: visualizationMode == 'sencilla',
            c: c,
            onTap: () {
              AppHaptics.selection();
              ref.read(profileServiceProvider)?.updateUserSettings(
                  {'modo_visualizacion': 'sencilla'});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required IconData icon,
    required bool selected,
    required AppColorScheme c,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppTokens.durationFast,
          curve: AppTokens.curveSnappy,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16,
                  color: selected ? c.primary : c.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? c.primary : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert history row ──────────────────────────────────────────────────────────

class _AlertHistoryTile extends StatelessWidget {
  final TrendAlert alert;
  final AppColorScheme c;

  const _AlertHistoryTile({required this.alert, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: c.warning, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(alert.timestamp),
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}
