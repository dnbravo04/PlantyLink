import '../../core/demo_data_service.dart';
import '../../core/services/profile_service.dart';
import '../../models/plant_profile.dart';
import '../../domain/repositories/plant_repository.dart';

/// Implementation of [PlantRepository] backed by [ProfileService] (production)
/// or [DemoDataService] (demo mode).
///
/// In demo mode, all plant data is self-contained in [DemoDataService]:
///   - [activePlantNameStream] and [activePlantProfileStream] derive from
///     [DemoDataService.activePlantStream], which updates when [changePlant]
///     is called and emits the current plant immediately to new subscribers.
///   - [selectPlant] calls [DemoDataService.changePlant] (no Firebase write).
///   - [updateThresholds] is a no-op in demo mode.
class PlantRepositoryImpl implements PlantRepository {
  final ProfileService _profileService;
  final DemoDataService? _demo;

  PlantRepositoryImpl({
    required ProfileService profileService,
    DemoDataService? demoService,
  })  : _profileService = profileService,
        _demo = demoService;

  bool get _isDemoMode => _demo != null;

  // ── PlantRepository interface ─────────────────────────────────────────────

  @override
  Stream<String> get activePlantNameStream {
    if (_isDemoMode) {
      return _demo!.activePlantStream
          .map((p) => p.nombre)
          .distinct();
    }
    return _profileService.plantaActivaStream;
  }

  @override
  Stream<PlantProfile?> get activePlantProfileStream {
    if (_isDemoMode) {
      return _demo!.activePlantStream
          .map((p) => p as PlantProfile?)
          .distinct();
    }
    return _profileService.thresholdsStream.map((map) {
      if (map.isEmpty) return null;
      try {
        return PlantProfile.fromMap(map);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  List<PlantProfile> get availablePlants => PlantCatalog.plantas;

  @override
  Future<void> selectPlant(PlantProfile plant) async {
    if (_isDemoMode) {
      final index = PlantCatalog.plantas
          .indexWhere((p) => p.nombre == plant.nombre);
      if (index >= 0) _demo!.changePlant(index);
      return;
    }
    await _profileService.activarPerfil(plant);
  }

  @override
  Future<void> updateThresholds(Map<String, dynamic> thresholds) async {
    if (_isDemoMode) return; // Threshold persistence is Firebase-only.
    await _profileService.updateProfileThresholds(thresholds);
  }
}
