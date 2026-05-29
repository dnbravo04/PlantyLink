import 'package:dio/dio.dart';
import '../../core/services/catalog_service.dart';
import '../../data/api/perenual_api.dart';
import '../../data/api/perenual_models.dart';
import '../../domain/repositories/plant_catalog_repository.dart';
import '../../domain/services/agronomic_service.dart';
import '../../models/agronomic/enriched_plant_profile.dart';
import '../../models/plant_profile.dart';

class PlantCatalogRepositoryImpl implements PlantCatalogRepository {
  final PerenualApi _api;
  final CatalogService _catalogService;
  final AgronomicService _agronomicService;
  final String _apiKey;

  PlantCatalogRepositoryImpl({
    required PerenualApi api,
    required CatalogService catalogService,
    required AgronomicService agronomicService,
    required String apiKey,
  })  : _api = api,
        _catalogService = catalogService,
        _agronomicService = agronomicService,
        _apiKey = apiKey;

  // ── Search ─────────────────────────────────────────────────────────────────

  @override
  Future<List<PerenualSpecies>> searchSpecies(
    String query, {
    int page = 1,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Clave de API de Perenual no configurada. '
        'Agrega --dart-define=PERENUAL_API_KEY=<tu_clave> al ejecutar la app, '
        'o coloca la clave en lib/core/api_keys.dart (_kDevOverride).',
      );
    }
    try {
      final response = await _api.searchSpecies(_apiKey, query, page: page);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Error buscando plantas: ${e.message}');
    }
  }

  // ── Enriched profile ───────────────────────────────────────────────────────

  @override
  Future<EnrichedPlantProfile> getEnrichedProfile(
    PlantProfile plant, {
    int? perenualId,
  }) async {
    if (perenualId == null) {
      return _agronomicService.enrichPlant(plant, null);
    }

    // 1. Cache hit?
    final cached = await _catalogService.getCachedSpecies(perenualId);
    if (cached != null) {
      try {
        final detail = PerenualSpeciesDetail.fromJson(cached);
        return _agronomicService.enrichPlant(plant, detail);
      } catch (_) {
        // Malformed cache — fall through to API.
      }
    }

    // 2. Fetch from Perenual, then cache.
    try {
      final detail = await _api.getSpeciesDetail(perenualId, _apiKey);
      await _catalogService.cacheSpecies(perenualId, detail.toJson());
      return _agronomicService.enrichPlant(plant, detail);
    } on DioException catch (_) {
      // Network failure: return un-enriched profile rather than throwing.
      return _agronomicService.enrichPlant(plant, null);
    }
  }

  // ── User catalog ───────────────────────────────────────────────────────────

  @override
  Stream<List<PlantProfile>> get userCatalogStream {
    return _catalogService.userCatalogStream.map(
      (items) => items.map((m) => PlantProfile.fromMap(m)).toList(),
    );
  }

  @override
  Future<void> saveToUserCatalog(PlantProfile plant, {int? perenualId}) async {
    final data = Map<String, dynamic>.from(plant.toMap());
    if (perenualId != null) data['perenual_id'] = perenualId;
    await _catalogService.savePlantToCatalog(data);
  }

  @override
  Future<void> removeFromUserCatalog(String nombre) async {
    await _catalogService.removePlantFromCatalog(nombre);
  }
}
