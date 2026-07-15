import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_page_route.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/units.dart';
import '../../models/device_info.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';
import '../providers/app_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/trend_alert_provider.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/animated_app_card.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/shimmer_placeholder.dart';
import '../widgets/common/user_avatar.dart';
import '../widgets/dashboard/illuminated_button.dart';
import '../widgets/dashboard/simple_metric.dart';
import '../widgets/dashboard/sensor_card.dart';
import 'calibration_screen.dart';
import 'scheduling_screen.dart';
import 'settings/preferences_screen.dart';
import 'settings/profile_settings_screen.dart';

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
    final units = ref.watch(unitsProvider);
    final staleness =
        ref.watch(dataStalenessProvider).value ?? DataStaleness.none;
    final isHydro = ref.watch(isHydroDeviceProvider);

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

      // In-app toast for new trend alerts. Beginners get an actionable plain
      // message; advanced users get the technical prediction (Eje 2.2).
      ref.listen<TrendAlertState>(trendAlertProvider, (prev, next) {
        final previous = prev?.alerts ?? const <TrendAlert>[];
        final isNovato = ref.read(experienceProvider) == 'novato';
        for (final alert in next.alerts) {
          final isNew = !previous.any((a) =>
              a.sensorKey == alert.sensorKey &&
              a.thresholdType == alert.thresholdType);
          if (isNew) {
            AppToast.show(
              context,
              message:
                  isNovato ? _friendlyAlertMessage(alert) : alert.message,
              type: ToastType.warning,
            );
          }
        }
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
                      ref.read(selectedTabIndexProvider.notifier).select(3);
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
          ref.invalidate(weatherProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 12),
              _buildHeader(
                  context, plantaAsync, sensorAsync, userAsync, staleness, c),
              const SizedBox(height: 10),
              _buildWeatherChip(ref, units, c),
              const SizedBox(height: 10),
              _QuickActions(isHydro: isHydro),
              const SizedBox(height: 10),
              _DashboardViewToggle(visualizationMode: visualizationMode),
              const SizedBox(height: 16),
              _buildMetrics(sensorAsync, profileAsync, visualizationMode,
                  units, isHydro, staleness.freshness, c),
              const SizedBox(height: 8),
              _buildActuators(sensorAsync, ref, c),
              const SizedBox(height: 8),
              _buildAlert(sensorAsync, profileAsync, isHydro, c),
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
    BuildContext context,
    AsyncValue<String> plantaAsync,
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<Map<String, dynamic>> userAsync,
    DataStaleness staleness,
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
        // Avatar (photo → Google picture → initial) — tap for account menu
        GestureDetector(
          onTap: () {
            AppHaptics.light();
            _showAccountSheet(context, userAsync.value ?? const {});
          },
          child: UserAvatar(
              user: userAsync.value ?? const {}, size: 42, radius: 14),
        ),
        const SizedBox(width: 12),
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
        _buildConnectionChip(staleness, c),
      ],
    );
  }

  /// Connection chip driven by data freshness (age of the last reading), not
  /// by the firmware-written `conectado` boolean, which never flips back to
  /// false when the ESP32 dies (Eje 4 / ROADMAP Fase 1).
  Widget _buildConnectionChip(DataStaleness staleness, AppColorScheme c) {
    final (color, label) = switch (staleness.freshness) {
      DataFreshness.live => (c.success, 'Conectado'),
      DataFreshness.stale => (
          c.warning,
          'Datos de hace ${staleness.ageMinutes} min',
        ),
      DataFreshness.offline => (
          c.error,
          staleness.hasData ? 'Desconectado' : 'Sin datos',
        ),
    };
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
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Weather (uses the profile's ciudad) ─────────────────────────────────

  Widget _buildWeatherChip(WidgetRef ref, UnitsPrefs units, AppColorScheme c) {
    final weather = ref.watch(weatherProvider).value;
    if (weather == null) return const SizedBox.shrink();

    final icon = weather.isClear
        ? Icons.wb_sunny_rounded
        : weather.isRainy
            ? Icons.water_drop_rounded
            : Icons.cloud_rounded;
    final iconColor = weather.isClear
        ? c.warning
        : weather.isRainy
            ? c.info
            : c.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          // Expanded + ellipsis: long descriptions/cities must never overflow
          // the chip (fixes "OVERFLOWED BY N PIXELS").
          Expanded(
            child: Text(
              '${units.formatTemp(weather.tempC)}${units.tempUnit} · '
              '${weather.descripcion}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.location_on_outlined, size: 13, color: c.textMuted),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '${weather.ciudad} · ${weather.humidity.round()}% HR',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: c.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account sheet (avatar menu) ─────────────────────────────────────────

  void _showAccountSheet(BuildContext context, Map<String, dynamic> user) {
    final c = AppColors.of(context);
    final authUser = FirebaseAuth.instance.currentUser;
    final nombre = user['nombre']?.toString() ?? 'Usuario';
    final identity = authUser?.email ?? authUser?.phoneNumber ?? '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            UserAvatar(user: user, size: 64, radius: 20),
            const SizedBox(height: 10),
            Text(nombre,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            if (identity.isNotEmpty)
              Text(identity,
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.cardBorder),
            ListTile(
              leading: Icon(Icons.person_outline_rounded, color: c.primary),
              title: Text('Perfil y cuenta',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) => const ProfileSettingsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.tune_rounded, color: c.info),
              title: Text('Preferencias',
                  style: TextStyle(color: c.textPrimary, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    AppPageRoute(
                        builder: (_) => const PreferencesScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: c.error),
              title: Text('Cerrar sesión',
                  style: TextStyle(color: c.error, fontSize: 14)),
              onTap: () async {
                Navigator.pop(ctx);
                await GoogleSignIn.instance.signOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Metrics ─────────────────────────────────────────────────────────────

  Widget _buildMetrics(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
    String visualizationMode,
    UnitsPrefs units,
    bool isHydro,
    DataFreshness freshness,
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
          return SimpleMetricsGrid(
            sensor: sensor,
            profile: profile,
            units: units,
            showHydro: isHydro,
            freshness: freshness,
          );
        }

        final ecVal = sensor.ecNormalized;

        return Column(
          children: [
            // Cultivo en tierra: humedad de suelo/ambiente (solo si el
            // dispositivo las reporta — soil-first, ROADMAP_PRODUCTO.md P1).
            if (sensor.humedadSuelo != null || sensor.humedadAire != null) ...[
              Row(children: [
                if (sensor.humedadSuelo != null)
                  Expanded(
                    child: AnimatedAppCard(
                      delay: 0,
                      child: SensorCard(
                        label: 'Humedad de suelo',
                        value: sensor.humedadSuelo!.toStringAsFixed(0),
                        numericValue: sensor.humedadSuelo!,
                        valueFormatter: (v) => v.toStringAsFixed(0),
                        unit: '%',
                        icon: Icons.grass_rounded,
                        statusColor:
                            _soilColor(sensor.humedadSuelo!, profile, c),
                        isInRange: _soilInRange(sensor.humedadSuelo!, profile),
                        freshness: freshness,
                      ),
                    ),
                  ),
                if (sensor.humedadSuelo != null && sensor.humedadAire != null)
                  const SizedBox(width: 10),
                if (sensor.humedadAire != null)
                  Expanded(
                    child: AnimatedAppCard(
                      delay: 80,
                      child: SensorCard(
                        label: 'Humedad ambiente',
                        value: sensor.humedadAire!.toStringAsFixed(0),
                        numericValue: sensor.humedadAire!,
                        valueFormatter: (v) => v.toStringAsFixed(0),
                        unit: '%',
                        icon: Icons.water_drop_outlined,
                        statusColor: c.primary,
                        isInRange: true,
                        freshness: freshness,
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(
                child: AnimatedAppCard(
                  delay: 0,
                  child: SensorCard(
                    label: 'Temperatura',
                    value: units.formatTemp(sensor.temperatura ?? 0.0),
                    numericValue: sensor.temperatura ?? 0.0,
                    valueFormatter: units.formatTemp,
                    unit: units.tempUnit,
                    icon: Icons.thermostat_outlined,
                    statusColor: _tempColor(sensor.temperatura ?? 0, c),
                    isInRange: true,
                    freshness: freshness,
                  ),
                ),
              ),
              // pH solo aplica a hidroponía — un dispositivo de suelo no lo
              // mide y el default 7.0 "perfecto" del modelo es engañoso.
              if (isHydro) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedAppCard(
                    delay: 80,
                    child: SensorCard(
                      label: 'pH',
                      value: (sensor.ph ?? 0).toStringAsFixed(1),
                      numericValue: sensor.ph ?? 0.0,
                      valueFormatter: (v) => v.toStringAsFixed(1),
                      unit: '',
                      icon: Icons.science_outlined,
                      statusColor: _phColor(sensor.ph ?? 0, profile, c),
                      isInRange: profile == null ||
                          ((sensor.ph ?? 0) >= profile.phMin &&
                              (sensor.ph ?? 0) <= profile.phMax),
                      freshness: freshness,
                    ),
                  ),
                ),
              ],
            ]),
            if (isHydro) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: AnimatedAppCard(
                    delay: 160,
                    child: SensorCard(
                      label: 'Conductividad',
                      value: units.formatEc(ecVal),
                      numericValue: ecVal,
                      valueFormatter: units.formatEc,
                      unit: units.ecUnit,
                      icon: Icons.electric_bolt_outlined,
                      statusColor: _ecColor(ecVal, profile, c),
                      isInRange: profile == null ||
                          (ecVal >= profile.ecMin && ecVal <= profile.ecMax),
                      freshness: freshness,
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
                  freshness: freshness,
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
                  freshness: freshness,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── Alerts ──────────────────────────────────────────────────────────────

  // ── Actuator controls ───────────────────────────────────────────────────

  /// Actuator controls, soil-first (Eje 2.3).
  ///
  /// Las dosificadoras de ácido/base se eliminaron de la UI: dosificar
  /// química es un caso avanzado sin hardware detrás hoy (ROADMAP P1/P4).
  /// Quedan los actuadores que un cultivo real tiene: bomba de riego (caso
  /// base, suelo o hidro) y bomba de fertilizante/nutrientes (hidro o si el
  /// dispositivo la declara en `info/actuadores`).
  Widget _buildActuators(
    AsyncValue<SensorData> sensorAsync,
    WidgetRef ref,
    AppColorScheme c,
  ) {
    final sensor = sensorAsync.value;
    if (sensor == null) return const SizedBox.shrink();

    final info = ref.watch(deviceInfoProvider).value ?? const DeviceInfo();
    final isHydro = ref.watch(isHydroDeviceProvider);
    final showWater = info.isEmpty || info.hasActuator('bomba_agua');
    final showFert = info.hasActuator('bomba_fertilizante') ||
        (info.isEmpty && isHydro);
    if (!showWater && !showFert) return const SizedBox.shrink();

    void toggle(String pumpId, bool current) {
      ref.read(sensorRepositoryProvider)?.togglePump(pumpId, !current);
    }

    Widget button({
      required String label,
      required IconData icon,
      required Color color,
      required String pumpId,
      required bool? active,
      bool? auto,
      bool? override,
    }) {
      final isActive = active ?? false;
      return Expanded(
        child: IlluminatedButton(
          label: label,
          icon: icon,
          color: color,
          isActive: isActive,
          isAutoMode: auto ?? false,
          isManualOverride: override ?? false,
          onTap: () => toggle(pumpId, isActive),
        ),
      );
    }

    return AnimatedAppCard(
      delay: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riego',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            if (showWater)
              button(
                label: 'Regar ahora',
                icon: Icons.water_drop_rounded,
                color: c.info,
                pumpId: 'bomba_agua',
                active: sensor.bombaAgua,
                auto: sensor.bombaAguaAuto,
                override: sensor.bombaAguaManualOverride,
              ),
            if (showWater && showFert) const SizedBox(width: 10),
            if (showFert)
              button(
                label: 'Nutrientes',
                icon: Icons.eco_rounded,
                color: c.success,
                pumpId: 'bomba_fertilizante',
                active: sensor.bombaFertilizante,
                auto: sensor.bombaFertilizanteAuto,
                override: sensor.bombaFertilizanteManualOverride,
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAlert(
    AsyncValue<SensorData> sensorAsync,
    AsyncValue<PlantProfile?> profileAsync,
    bool isHydro,
    AppColorScheme c,
  ) {
    // La alerta de EC solo tiene sentido en hidroponía.
    if (!isHydro) return const SizedBox.shrink();
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
              child: GestureDetector(
                onTap: () {
                  AppHaptics.light();
                  ref.read(selectedTabIndexProvider.notifier).select(1);
                },
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
                      Icon(Icons.chevron_right_rounded, color: c.warning, size: 18),
                    ],
                  ),
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

  /// Eje 1.2: solo <20 % es alerta (error); de 20 % en adelante el nivel se
  /// considera óptimo y usa el color primario de marca.
  Color _levelColor(double level, AppColorScheme c) {
    if (level < 20) return c.error;
    return c.primary;
  }

  bool _soilInRange(double v, PlantProfile? profile) {
    final min = profile?.humedadSueloMin;
    final max = profile?.humedadSueloMax;
    if (min != null && v < min) return false;
    if (max != null && v > max) return false;
    return true;
  }

  Color _soilColor(double v, PlantProfile? profile, AppColorScheme c) {
    return _soilInRange(v, profile) ? c.success : c.warning;
  }

  String _levelLabel(double level) {
    if (level < 20) return 'Nivel crítico';
    return 'Nivel óptimo';
  }

  /// Eje 2.2: traduce una alerta de tendencia técnica a una acción concreta
  /// que un principiante pueda ejecutar sin conocer el sensor detrás.
  String _friendlyAlertMessage(TrendAlert alert) {
    final rising = alert.thresholdType == 'max';
    return switch (alert.sensorKey) {
      'nivel_agua_tanque' =>
        'El agua se está acabando. Rellena el tanque pronto.',
      'nivel_fertilizante_tanque' =>
        'Queda poco fertilizante. Rellénalo cuando puedas.',
      'temperatura' => rising
          ? 'Está haciendo mucho calor para tu planta. Dale sombra o ventilación.'
          : 'Hace frío para tu planta. Aléjala de corrientes de aire.',
      'ph' =>
        'El agua se está desequilibrando. Revisa la pestaña Agronomía.',
      'conductividad' => rising
          ? 'Hay demasiado nutriente en el agua. Agrega agua limpia.'
          : 'Faltan nutrientes en el agua. Agrega fertilizante.',
      'humedad_suelo' => rising
          ? 'El suelo se está encharcando. Pausa el riego.'
          : 'El suelo se está secando. Riega tu planta pronto.',
      _ => alert.message,
    };
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
              ref.read(visualizationModeProvider.notifier).set('tecnica');
            },
          ),
          _buildSegment(
            label: 'Resumen',
            icon: Icons.grid_view_rounded,
            selected: visualizationMode == 'sencilla',
            c: c,
            onTap: () {
              AppHaptics.selection();
              ref.read(visualizationModeProvider.notifier).set('sencilla');
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

// ── Quick actions chip row ────────────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  final bool isHydro;
  const _QuickActions({required this.isHydro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ActionChip(
            icon: Icons.tune_rounded,
            label: 'Calibrar',
            color: c.info,
            c: c,
            onTap: () {
              AppHaptics.light();
              Navigator.push(context,
                  AppPageRoute(builder: (_) => const CalibrationScreen()));
            },
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.schedule_rounded,
            label: 'Programar',
            color: c.success,
            c: c,
            onTap: () {
              AppHaptics.light();
              Navigator.push(context,
                  AppPageRoute(builder: (_) => const SchedulingScreen()));
            },
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.show_chart_rounded,
            label: 'Historial',
            color: c.accent,
            c: c,
            onTap: () {
              AppHaptics.light();
              ref.read(selectedTabIndexProvider.notifier).select(1);
            },
          ),
          if (isHydro) ...[
            const SizedBox(width: 8),
            _ActionChip(
              icon: Icons.eco_rounded,
              label: 'Agronomía',
              color: c.primary,
              c: c,
              onTap: () {
                AppHaptics.light();
                ref.read(selectedTabIndexProvider.notifier).select(2);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppColorScheme c;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.c,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.cardBackground,
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
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
