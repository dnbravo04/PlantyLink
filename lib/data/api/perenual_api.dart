import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'perenual_models.dart';

part 'perenual_api.g.dart';

@RestApi(baseUrl: 'https://perenual.com')
abstract class PerenualApi {
  factory PerenualApi(Dio dio, {String? baseUrl}) = _PerenualApi;

  /// Search species by common/scientific name.
  /// [query] can be empty to list all species.
  @GET('/api/species-list')
  Future<PerenualListResponse> searchSpecies(
    @Query('key') String apiKey,
    @Query('q') String query, {
    @Query('page') int page = 1,
  });

  /// Full detail for a single species — includes description, care level, etc.
  @GET('/api/species/{id}')
  Future<PerenualSpeciesDetail> getSpeciesDetail(
    @Path('id') int id,
    @Query('key') String apiKey,
  );

  /// Care guide sections (watering, sunlight, fertilizing, pruning) for a species.
  @GET('/api/species-care-guide-list')
  Future<PerenualCareGuideResponse> getCareGuides(
    @Query('species_id') int speciesId,
    @Query('key') String apiKey,
  );
}
