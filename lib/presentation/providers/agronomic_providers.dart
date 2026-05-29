import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_keys.dart';
import '../../core/services/catalog_service.dart';
import '../../data/api/api_interceptors.dart';
import '../../data/api/perenual_api.dart';
import '../../data/repositories/plant_catalog_repository_impl.dart';
import '../../domain/repositories/plant_catalog_repository.dart';
import '../../domain/services/agronomic_service.dart';

// ── HTTP client ───────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(ApiLoggingInterceptor());
  return dio;
});

// ── Perenual API client ───────────────────────────────────────────────────────

final perenualApiProvider = Provider<PerenualApi>((ref) {
  return PerenualApi(ref.watch(dioProvider));
});

// ── Supporting services ───────────────────────────────────────────────────────

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService();
});

final agronomicServiceProvider = Provider<AgronomicService>((ref) {
  return AgronomicService();
});

// ── Repository ────────────────────────────────────────────────────────────────

final plantCatalogRepositoryProvider = Provider<PlantCatalogRepository>((ref) {
  return PlantCatalogRepositoryImpl(
    api: ref.watch(perenualApiProvider),
    catalogService: ref.watch(catalogServiceProvider),
    agronomicService: ref.watch(agronomicServiceProvider),
    apiKey: kPerenualApiKey,
  );
});

// ── UI-facing async providers ─────────────────────────────────────────────────

/// Stream of the authenticated user's saved plant catalog.
final userCatalogStreamProvider = StreamProvider(
  (ref) => ref.watch(plantCatalogRepositoryProvider).userCatalogStream,
);
