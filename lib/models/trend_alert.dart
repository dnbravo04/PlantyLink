class TrendAlert {
  final String sensorKey;
  final String message;
  final double currentValue;
  final double predictedValue;
  final double slope;
  final DateTime timestamp;
  final String thresholdType;

  const TrendAlert({
    required this.sensorKey,
    required this.message,
    required this.currentValue,
    required this.predictedValue,
    required this.slope,
    required this.timestamp,
    required this.thresholdType,
  });

  Map<String, dynamic> toMap() {
    return {
      'sensor_key': sensorKey,
      'message': message,
      'current_value': currentValue,
      'predicted_value': predictedValue,
      'slope': slope,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'threshold_type': thresholdType,
      'event': 'alerta_tendencia',
    };
  }
}

class SensorReading {
  final double value;
  final DateTime timestamp;

  const SensorReading({
    required this.value,
    required this.timestamp,
  });
}

class TrendCalculator {
  static const int _readingsCount = 5;
  static const Duration _predictionTime = Duration(minutes: 5);

  /// Calcula la pendiente usando regresión lineal simple
  static double _calculateSlope(List<SensorReading> readings) {
    if (readings.length < 2) return 0;

    final n = readings.length.toDouble();
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < readings.length; i++) {
      final x = readings[i].timestamp.millisecondsSinceEpoch.toDouble();
      final y = readings[i].value;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Predice el valor después del tiempo especificado
  static double _predictValue(
    List<SensorReading> readings,
    Duration predictionTime,
  ) {
    if (readings.isEmpty) return 0;

    final slope = _calculateSlope(readings);
    final lastReading = readings.last;
    final timeDiff = predictionTime.inMilliseconds.toDouble();
    
    return lastReading.value + (slope * timeDiff);
  }

  /// Verifica si hay tendencia de alerta para un sensor
  static TrendAlert? checkTrendAlert(
    List<SensorReading> readings,
    String sensorKey,
    double? minValue,
    double? maxValue,
  ) {
    if (readings.length < _readingsCount) return null;
    if (minValue == null && maxValue == null) return null;

    final slope = _calculateSlope(readings);
    final predictedValue = _predictValue(readings, _predictionTime);
    final currentValue = readings.last.value;

    // Verificar si el valor predicho excede los límites
    if (maxValue != null && predictedValue > maxValue) {
      return TrendAlert(
        sensorKey: sensorKey,
        message: _getTrendMessage(sensorKey, 'subiendo', maxValue),
        currentValue: currentValue,
        predictedValue: predictedValue,
        slope: slope,
        timestamp: DateTime.now(),
        thresholdType: 'max',
      );
    }

    if (minValue != null && predictedValue < minValue) {
      return TrendAlert(
        sensorKey: sensorKey,
        message: _getTrendMessage(sensorKey, 'bajando', minValue),
        currentValue: currentValue,
        predictedValue: predictedValue,
        slope: slope,
        timestamp: DateTime.now(),
        thresholdType: 'min',
      );
    }

    return null;
  }

  static String _getTrendMessage(String sensorKey, String direction, double threshold) {
    final sensorNames = {
      'temperatura': 'Temperatura',
      'ph': 'pH',
      'conductividad': 'Conductividad',
      'nivel_agua_tanque': 'Nivel de agua',
      'nivel_fertilizante_tanque': 'Nivel de fertilizante',
    };

    final sensorName = sensorNames[sensorKey] ?? sensorKey;
    final thresholdStr = threshold.toStringAsFixed(1);
    
    return '$sensorName $direction rápido... (predicción: $thresholdStr en 5 min)';
  }
}
