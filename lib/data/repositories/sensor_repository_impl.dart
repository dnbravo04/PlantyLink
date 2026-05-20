import '../../core/firebase_service.dart';
import '../../core/demo_data_service.dart';
import '../../models/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';

/// Routes sensor streams to either Firebase (production) or
/// [DemoDataService] (development/demo fallback).
///
/// Exactly one source is active at a time:
///   - [_demo] != null  →  all streams come from in-memory simulation.
///   - [_demo] == null  →  all streams come from Firebase.
///
/// Firebase is never written to by [DemoDataService].
class SensorRepositoryImpl implements SensorRepository {
  final FirebaseService _firebase;
  final DemoDataService? _demo;

  /// Set [demoService] only in development/demo builds.
  /// Leave it null in production so Firebase is used exclusively.
  SensorRepositoryImpl({
    required FirebaseService firebaseService,
    DemoDataService? demoService,
  })  : _firebase = firebaseService,
        _demo = demoService;

  bool get _isDemoMode => _demo != null;

  // ── SensorRepository interface ───────────────────────────────────────────

  @override
  Stream<SensorData> get sensorStream =>
      _isDemoMode ? _demo!.sensorStream : _firebase.sensorStream;

  @override
  Stream<List<SensorData>> get historyStream {
    if (_isDemoMode) {
      return _demo!.historyStream.map(
        (list) => list.map(SensorData.fromMap).toList(),
      );
    }
    // Firebase history — adapt however FirebaseService exposes it.
    // If FirebaseService has its own historyStream, prefer that; otherwise
    // derive a single-item list from the live sensor stream as a placeholder.
    return _firebase.sensorStream.map((data) => [data]);
  }

  // ── Pump / automation controls ───────────────────────────────────────────
  //
  // In demo mode the pump toggle is reflected locally (in-memory).
  // In production it goes through Firebase.

  @override
  Future<void> togglePump(String pumpId, bool active) async {
    if (_isDemoMode) {
      _demo!.togglePump(pumpId, active);
      return;
    }
    switch (pumpId) {
      case 'bomba_agua':
        await _firebase.controlarBombaAgua(active);
      case 'bomba_fertilizante':
        await _firebase.controlarBombaFertilizante(active);
      case 'bomba_dosificadora_acido':
        await _firebase.controlarDosificadoraAcido(active);
      case 'bomba_dosificadora_basico':
        await _firebase.controlarDosificadoraBasico(active);
      default:
        throw ArgumentError('Unknown pumpId: $pumpId');
    }
  }

  @override
  Future<void> setAutoWatering(bool active) async {
    if (_isDemoMode) {
      // Auto-watering is a Firebase-only concept; ignore in demo mode.
      return;
    }
    await _firebase.activarRiegoAutomatico(active);
  }
}