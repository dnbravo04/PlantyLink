import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/sensor_data.dart';
import '../../models/plant_profile.dart';
import '../../models/trend_alert.dart';
import '../../core/firebase_constants.dart';

class TrendAlertState {
  final List<TrendAlert> alerts;
  final bool isLoading;
  final String? error;

  const TrendAlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  TrendAlertState copyWith({
    List<TrendAlert>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return TrendAlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TrendNotifier extends Notifier<TrendAlertState> {
  // Almacenamiento de las últimas 5 lecturas por sensor
  final Map<String, List<SensorReading>> _readingsHistory = {};

  @override
  TrendAlertState build() => const TrendAlertState();

  void addSensorReading(SensorData sensorData) {
    final now = DateTime.now();

    // Agregar lecturas actuales al historial
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

  void _addReading(String sensorKey, double? value, DateTime timestamp) {
    if (value == null) return;

    final reading = SensorReading(value: value, timestamp: timestamp);

    _readingsHistory[sensorKey] ??= [];
    final readings = _readingsHistory[sensorKey]!;
    readings.add(reading);

    // Mantener solo las últimas 5 lecturas
    if (readings.length > 5) {
      readings.removeAt(0);
    }
  }

  Future<void> checkTrendAlerts(PlantProfile? profile) async {
    if (profile == null) return;

    state = const TrendAlertState(isLoading: true, error: null);

    try {
      final alerts = <TrendAlert>[];

      // Verificar tendencia para cada sensor
      final sensorsConfig = [
        {'key': 'temperatura', 'min': profile.tempMin, 'max': profile.tempMax},
        {'key': 'ph', 'min': profile.phMin, 'max': profile.phMax},
        {'key': 'conductividad', 'min': profile.ecMin, 'max': profile.ecMax},
        {
          'key': 'nivel_agua_tanque',
          'min': 20.0, // Mínimo 20% de agua
          'max': null,
        },
        {
          'key': 'nivel_fertilizante_tanque',
          'min': 20.0, // Mínimo 20% de fertilizante
          'max': null,
        },
      ];

      for (final sensor in sensorsConfig) {
        final readings = _readingsHistory[sensor['key'] as String];
        if (readings != null && readings.length >= 5) {
          final alert = TrendCalculator.checkTrendAlert(
            readings,
            sensor['key'] as String,
            sensor['min'] as double?,
            sensor['max'] as double?,
          );

          if (alert != null) {
            alerts.add(alert);
            // Guardar alerta en history
            await _saveAlertToHistory(alert);
          }
        }
      }

      state = TrendAlertState(alerts: alerts, isLoading: false);
    } catch (e) {
      state = TrendAlertState(
        isLoading: false,
        error: 'Error al verificar tendencias: $e',
      );
    }
  }

  Future<void> _saveAlertToHistory(TrendAlert alert) async {
    try {
      final db = FirebaseDatabase.instanceFor(
        databaseURL: kFirebaseDatabaseUrl,
        app: Firebase.app(),
      );
      final historyRef = db.ref('history').push();
      await historyRef.set(alert.toMap());
    } catch (e) {
      // Error al guardar no debe interrumpir el flujo
      debugPrint('Error guardando alerta en history: $e');
    }
  }

  void clearAlerts() {
    state = const TrendAlertState();
  }
}

// Provider para TrendNotifier
final trendAlertProvider = NotifierProvider<TrendNotifier, TrendAlertState>(() {
  return TrendNotifier();
});

// Provider para el stream de alertas de tendencia
final trendAlertsStreamProvider = StreamProvider<List<TrendAlert>>((ref) {
  final db = FirebaseDatabase.instanceFor(
    databaseURL: kFirebaseDatabaseUrl,
    app: Firebase.app(),
  );

  return db
      .ref('history')
      .orderByChild('event')
      .equalTo('alerta_tendencia')
      .limitToLast(10)
      .onValue
      .map((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
        final alerts = <TrendAlert>[];

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              alerts.add(
                TrendAlert(
                  sensorKey: value['sensor_key'] as String,
                  message: value['message'] as String,
                  currentValue: (value['current_value'] as num).toDouble(),
                  predictedValue: (value['predicted_value'] as num).toDouble(),
                  slope: (value['slope'] as num).toDouble(),
                  timestamp: DateTime.fromMillisecondsSinceEpoch(
                    value['timestamp'] as int,
                  ),
                  thresholdType: value['threshold_type'] as String,
                ),
              );
            } catch (e) {
              debugPrint('Error parsing alert: $e');
            }
          }
        });

        return alerts..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
});
