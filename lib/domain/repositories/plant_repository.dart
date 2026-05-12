import '../../models/plant_profile.dart';

/// Abstract repository for plant profile management.
///
/// Provides access to the plant catalog and the currently active plant profile.
abstract class PlantRepository {
  /// Stream of the currently active plant name.
  Stream<String> get activePlantNameStream;

  /// Stream of the active plant's full profile thresholds.
  Stream<PlantProfile?> get activePlantProfileStream;

  /// List of all available plants in the catalog.
  List<PlantProfile> get availablePlants;

  /// Set a plant as the active profile.
  Future<void> selectPlant(PlantProfile plant);

  /// Update threshold values on the active profile without changing the plant name.
  Future<void> updateThresholds(Map<String, dynamic> thresholds);
}
