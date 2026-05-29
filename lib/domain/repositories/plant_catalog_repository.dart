import '../../data/api/perenual_models.dart';
import '../../models/agronomic/enriched_plant_profile.dart';
import '../../models/plant_profile.dart';

/// Repository for Perenual API plant search and the user's saved catalog.
///
/// Implementations are responsible for:
/// - Routing API calls through the Perenual REST client.
/// - Caching API responses in Firebase to reduce redundant network calls.
/// - Mapping raw Firebase catalog entries back to [PlantProfile] objects.
abstract class PlantCatalogRepository {
  /// Search Perenual for species matching [query].
  /// Returns an empty list on network failure (non-throwing).
  Future<List<PerenualSpecies>> searchSpecies(String query, {int page = 1});

  /// Fetch a [PlantProfile] enriched with Perenual detail for [perenualId].
  /// Falls back to a non-enriched profile when [perenualId] is null or the
  /// network call fails.
  Future<EnrichedPlantProfile> getEnrichedProfile(
    PlantProfile plant, {
    int? perenualId,
  });

  /// Live stream of the user's saved plant catalog from Firebase.
  Stream<List<PlantProfile>> get userCatalogStream;

  /// Persist [plant] to the user's Firebase catalog.
  Future<void> saveToUserCatalog(PlantProfile plant, {int? perenualId});

  /// Remove the plant named [nombre] from the user's Firebase catalog.
  Future<void> removeFromUserCatalog(String nombre);
}
