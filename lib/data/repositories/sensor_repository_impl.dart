import 'dart:async';
import '../../core/demo_data_service.dart';
import '../../core/services/sensor_stream_service.dart';
import '../../core/services/control_service.dart';
import '../../core/services/history_service.dart';
import '../../models/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';

/// Routes sensor streams to either Firebase (production) or
/// [DemoDataService] (development/demo fallback).
///
/// In production mode ([demoService] is null):
///   - [sensorStream] reads live from Firebase `sensors/`.
///   - [historyStream] reads from Firebase `history/` via [HistoryService].
///   - A periodic recorder writes sensor snapshots to `history/` every 30 s
///     so the history screen has data even when the ESP32 doesn't archive it.
///
/// In demo mode ([demoService] is non-null):
///   - All data comes from in-memory simulation.
///   - No Firebase reads or writes ever occur.
class SensorRepositoryImpl implements SensorRepository {
  final SensorStreamService? _sensorService;
  final ControlService? _controlService;
  final HistoryService? _historyService;
  final DemoDataService? _demo;

  // ── Production history recorder ──────────────────────────────────────────
  StreamSubscription<SensorData>? _historyWriterSub;
  DateTime? _lastHistoryWrite;

  SensorRepositoryImpl({
    SensorStreamService? sensorStreamService,
    ControlService? controlService,
    HistoryService? historyService,
    DemoDataService? demoService,
  })  : _sensorService = sensorStreamService,
        _controlService = controlService,
        _historyService = historyService,
        _demo = demoService {
    if (!_isDemoMode) _startHistoryRecorder();
  }

  bool get _isDemoMode => _demo != null;

  // ── SensorRepository interface ───────────────────────────────────────────

  @override
  Stream<SensorData> get sensorStream =>
      _isDemoMode ? _demo!.sensorStream : _sensorService!.sensorStream;

  @override
  Stream<List<SensorData>> get historyStream {
    if (_isDemoMode) {
      return _demo!.historyStream.map(
        (list) => list.map(SensorData.fromMap).toList(),
      );
    }
    return _historyService!.historyStream;
  }

  @override
  Future<void> togglePump(String pumpId, bool active) async {
    if (_isDemoMode) {
      _demo!.togglePump(pumpId, active);
      return;
    }
    final ctrl = _controlService!;
    switch (pumpId) {
      case 'bomba_agua':
        await ctrl.setPump('bomba_agua', active);
      case 'bomba_fertilizante':
        await ctrl.setPump('bomba_fertilizante', active);
      case 'bomba_dosificadora_acido':
        await ctrl.setPump('bomba_dosificadora_acido', active);
      case 'bomba_dosificadora_basico':
        await ctrl.setPump('bomba_dosificadora_basico', active);
      default:
        throw ArgumentError('Unknown pumpId: $pumpId');
    }
  }

  @override
  Future<void> setAutoWatering(bool active) async {
    if (_isDemoMode) return;
    await _controlService!.setAutoWatering(active);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Cancel the background history recorder. Called by the Riverpod provider
  /// via [ref.onDispose].
  void dispose() {
    _historyWriterSub?.cancel();
    _historyWriterSub = null;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Subscribe to the live sensor stream and write a snapshot to
  /// `devices/{esp32Id}/history/` at most once every 30 s in production mode.
  void _startHistoryRecorder() {
    final sensor = _sensorService;
    final history = _historyService;
    if (sensor == null || history == null) return;
    _historyWriterSub = sensor.sensorStream.listen((data) {
      final now = DateTime.now();
      if (_lastHistoryWrite == null ||
          now.difference(_lastHistoryWrite!) >=
              const Duration(seconds: 30)) {
        _lastHistoryWrite = now;
        history.appendSensorReading(data); // fire-and-forget OK
      }
    });
  }
}
