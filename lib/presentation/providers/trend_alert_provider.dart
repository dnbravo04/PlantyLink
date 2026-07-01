import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../core/services/notification_service.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';
import 'app_providers.dart';

class TrendAlertState {
  final List<TrendAlert> alerts;
  final String? error;

  const TrendAlertState({
    this.alerts = const [],
    this.error,
  });

  TrendAlertState copyWith({
    List<TrendAlert>? alerts,
    String? error,
  }) {
    return TrendAlertState(
      alerts: alerts ?? this.alerts,
      error: error,
    );
  }
}

class TrendNotifier extends Notifier<TrendAlertState> {
  // Last 5 readings per sensor key — used for linear regression.
  final Map<String, List<SensorReading>> _readingsHistory = {};

  // Deduplication: tracks when each sensor last fired an alert.
  // A new alert for the same sensor is suppressed within this window.
  static const _minAlertInterval = Duration(minutes: 2);
  final Map<String, DateTime> _lastAlertTime = {};

  @override
  TrendAlertState build() => const TrendAlertState();

  void addSensorReading(SensorData sensorData) {
    final now = DateTime.now();
    _addReading('temperatura', sensorData.temperatura, now);
    _addReading('ph', sensorData.ph, now);
    _addReading('conductividad', sensorData.conductividad, now);
    _addReading('nivel_agua_tanque', sensorData.nivelAguaTanque, now);
    _addReading(
      'nivel_fertilizante_tanque',
      sensorData.nivelFertilizanteTanque,
      now,
    );
  }

  void _addReading(String key, double? value, DateTime timestamp) {
    if (value == null) return;
    _readingsHistory[key] ??= [];
    final readings = _readingsHistory[key]!;
    readings.add(SensorReading(value: value, timestamp: timestamp));
    if (readings.length > 5) readings.removeAt(0);
  }

  Future<void> checkTrendAlerts(PlantProfile? profile) async {
    if (profile == null) return;

    // Respect the user's alerts toggle — read the cached value (sync).
    final alertsEnabled = ref.read(alertsEnabledProvider).value ?? true;
    if (!alertsEnabled) {
      // Clear any lingering active alerts when the user disables notifications.
      if (state.alerts.isNotEmpty) state = const TrendAlertState();
      return;
    }

    // Do NOT set isLoading — keep the current alert list visible during the
    // check to avoid flicker on every 3-second sensor tick.
    try {
      final alerts = <TrendAlert>[];

      // Use plant-profile thresholds for water/fertilizer floors.
      final sensorsConfig = <Map<String, Object?>>[
        {'key': 'temperatura', 'min': profile.tempMin, 'max': profile.tempMax},
        {'key': 'ph', 'min': profile.phMin, 'max': profile.phMax},
        {'key': 'conductividad', 'min': profile.ecMin, 'max': profile.ecMax},
        {
          'key': 'nivel_agua_tanque',
          'min': profile.nivelAguaMin,
          'max': null,
        },
        {
          'key': 'nivel_fertilizante_tanque',
          'min': profile.nivelFertilizanteMin,
          'max': null,
        },
      ];

      for (final sensor in sensorsConfig) {
        final key = sensor['key'] as String;
        final readings = _readingsHistory[key];
        if (readings == null || readings.length < 5) continue;

        final alert = TrendCalculator.checkTrendAlert(
          readings,
          key,
          sensor['min'] as double?,
          sensor['max'] as double?,
        );

        if (alert != null && _shouldFireAlert(key)) {
          alerts.add(alert);
          _lastAlertTime[key] = DateTime.now();
          // Persist to Firebase only in production (demo mode has no auth).
          if (!kDemoMode) {
            ref.read(historyServiceProvider)?.saveAlert(alert);
          }
          // Fire a local push notification so the user is alerted even when
          // the app is in the background or on a different tab.
          NotificationService.instance.showTrendAlert(key, alert.message);
        }
      }

      state = state.copyWith(alerts: alerts, error: null);
    } catch (e) {
      state = state.copyWith(
        error: 'Error al verificar tendencias: $e',
      );
    }
  }

  /// Returns true if [sensorKey] is eligible for a new alert (i.e. the
  /// minimum inter-alert interval has elapsed since the last one).
  bool _shouldFireAlert(String sensorKey) {
    final last = _lastAlertTime[sensorKey];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _minAlertInterval;
  }

  void dismissAlert(TrendAlert alert) {
    final updated = state.alerts.where((a) => a != alert).toList();
    state = state.copyWith(alerts: updated);
  }

  void clearAlerts() {
    state = const TrendAlertState();
  }
}

final trendAlertProvider =
    NotifierProvider<TrendNotifier, TrendAlertState>(() {
  return TrendNotifier();
});
