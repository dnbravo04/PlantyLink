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
  Future<({List<PerenualSpecies> results, int totalPages})> searchSpecies(
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
      return (results: response.data, totalPages: response.lastPage);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw Exception('Clave de API inválida o plan insuficiente.');
      }
      if (status == 429) {
        throw Exception('Límite de solicitudes excedido. Intenta más tarde.');
      }
      final detail = e.message?.isNotEmpty == true
          ? e.message
          : e.error?.toString() ?? e.type.name;
      throw Exception('Error de red: $detail');
    } catch (e) {
      // Perenual free plan sometimes returns {"data": "Upgrade Plan..."} — a
      // String instead of an array — which causes a JSON parse/type error here.
      final msg = e.toString();
      if (msg.contains('Upgrade') || msg.contains('upgrade') || msg.contains('type')) {
        throw Exception(
          'Plan de API insuficiente. Actualiza tu plan en perenual.com o usa el catálogo local.',
        );
      }
      throw Exception('Error al procesar la respuesta de la API.');
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

    // ── Check both caches in parallel ─────────────────────────────────────
    final (cachedSpecies, cachedGuide) = await (
      _catalogService.getCachedSpecies(perenualId),
      _catalogService.getCachedCareGuide(perenualId),
    ).wait;

    // ── Species detail ─────────────────────────────────────────────────────
    PerenualSpeciesDetail? detail;

    if (cachedSpecies != null) {
      try {
        detail = PerenualSpeciesDetail.fromJson(cachedSpecies);
      } catch (_) {}
    }

    // ── Care guide ─────────────────────────────────────────────────────────
    List<PerenualCareSection> careSections = [];

    if (cachedGuide != null) {
      try {
        careSections =
            cachedGuide.map((m) => PerenualCareSection.fromJson(m)).toList();
      } catch (_) {}
    }

    // ── Fetch from API for whatever is missing (parallel) ──────────────────
    if ((detail == null || cachedGuide == null) && _apiKey.isNotEmpty) {
      final futures = await (
        detail == null
            ? _api.getSpeciesDetail(perenualId, _apiKey).then<Object?>((d) => d).catchError((_) => null)
            : Future<Object?>.value(null),
        cachedGuide == null
            ? _api.getCareGuides(perenualId, _apiKey).then<Object?>((r) => r).catchError((_) => null)
            : Future<Object?>.value(null),
      ).wait;

      if (detail == null && futures.$1 is PerenualSpeciesDetail) {
        detail = futures.$1 as PerenualSpeciesDetail;
        await _catalogService.cacheSpecies(perenualId, detail.toJson());
      }

      if (cachedGuide == null && futures.$2 is PerenualCareGuideResponse) {
        final guide = futures.$2 as PerenualCareGuideResponse;
        if (guide.data.isNotEmpty) {
          careSections = guide.data.first.section;
          if (careSections.isNotEmpty) {
            await _catalogService.cacheCareGuide(
              perenualId,
              careSections.map((s) => s.toJson()).toList(),
            );
          }
        }
      }
    }

    return _agronomicService.enrichPlant(plant, detail, careSections: careSections);
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
