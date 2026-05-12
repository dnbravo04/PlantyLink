import '../../models/sensor_data.dart';

/// Abstract repository for sensor data and actuator controls.
///
/// Implementations can read from Firebase, local cache, or simulated sources.
/// This abstraction allows the UI to remain agnostic of the data source.
abstract class SensorRepository {
  /// Real-time stream of current sensor readings.
  Stream<SensorData> get sensorStream;

  /// Real-time stream of the last 60 history entries as parsed SensorData.
  Stream<List<SensorData>> get historyStream;

  /// Toggle a specific pump by its identifier.
  ///
  /// Supported identifiers:
  /// - `bomba_agua`
  /// - `bomba_fertilizante`
  /// - `bomba_dosificadora_acido`
  /// - `bomba_dosificadora_basico`
  Future<void> togglePump(String pumpId, bool active);

  /// Enable or disable automatic watering.
  Future<void> setAutoWatering(bool active);
}
