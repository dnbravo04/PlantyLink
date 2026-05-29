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
  final SensorStreamService _sensorService;
  final ControlService _controlService;
  final HistoryService _historyService;
  final DemoDataService? _demo;

  // ── Production history recorder ──────────────────────────────────────────
  StreamSubscription<SensorData>? _historyWriterSub;
  DateTime? _lastHistoryWrite;

  SensorRepositoryImpl({
    required SensorStreamService sensorStreamService,
    required ControlService controlService,
    required HistoryService historyService,
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
      _isDemoMode ? _demo!.sensorStream : _sensorService.sensorStream;

  @override
  Stream<List<SensorData>> get historyStream {
    if (_isDemoMode) {
      return _demo!.historyStream.map(
        (list) => list.map(SensorData.fromMap).toList(),
      );
    }
    return _historyService.historyStream;
  }

  @override
  Future<void> togglePump(String pumpId, bool active) async {
    if (_isDemoMode) {
      _demo!.togglePump(pumpId, active);
      return;
    }
    // Map repository pump IDs to Firebase control keys.
    // Throws ArgumentError for unknown IDs — callers must handle.
    switch (pumpId) {
      case 'bomba_agua':
        await _controlService.setPump('bomba_agua', active);
      case 'bomba_fertilizante':
        await _controlService.setPump('bomba_fertilizante', active);
      case 'bomba_dosificadora_acido':
        await _controlService.setPump('bomba_dosificadora_acido', active);
      case 'bomba_dosificadora_basico':
        await _controlService.setPump('bomba_dosificadora_basico', active);
      default:
        throw ArgumentError('Unknown pumpId: $pumpId');
    }
  }

  @override
  Future<void> setAutoWatering(bool active) async {
    if (_isDemoMode) return; // Auto-watering is a Firebase-only concept.
    await _controlService.setAutoWatering(active);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Cancel the background history recorder. Called by the Riverpod provider
  /// via [ref.onDispose].
  void dispose() {
    _historyWriterSub?.cancel();
    _historyWriterSub = null;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Subscribe to the live sensor stream and write a snapshot to `history/`
  /// at most once every 30 s in production mode.
  void _startHistoryRecorder() {
    _historyWriterSub = _sensorService.sensorStream.listen((data) {
      final now = DateTime.now();
      if (_lastHistoryWrite == null ||
          now.difference(_lastHistoryWrite!) >=
              const Duration(seconds: 30)) {
        _lastHistoryWrite = now;
        _historyService.appendSensorReading(data); // fire-and-forget OK
      }
    });
  }
}
