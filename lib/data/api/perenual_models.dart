import 'package:freezed_annotation/freezed_annotation.dart';

part 'perenual_models.freezed.dart';
part 'perenual_models.g.dart';

// ── List response wrapper ────────────────────────────────────────────────────

@freezed
abstract class PerenualListResponse with _$PerenualListResponse {
  const factory PerenualListResponse({
    required List<PerenualSpecies> data,
    @JsonKey(name: 'current_page') required int currentPage,
    @JsonKey(name: 'last_page') required int lastPage,
    @Default(0) int total,
  }) = _PerenualListResponse;

  factory PerenualListResponse.fromJson(Map<String, dynamic> json) =>
      _$PerenualListResponseFromJson(json);
}

// ── Species summary (from list endpoint) ────────────────────────────────────

@freezed
abstract class PerenualSpecies with _$PerenualSpecies {
  const factory PerenualSpecies({
    required int id,
    @JsonKey(name: 'common_name') @Default('') String commonName,
    @JsonKey(name: 'scientific_name') @Default([]) List<String> scientificName,
    @Default('') String cycle,
    @Default('') String watering,
    @Default([]) List<String> sunlight,
    @JsonKey(name: 'default_image') PerenualImage? defaultImage,
  }) = _PerenualSpecies;

  factory PerenualSpecies.fromJson(Map<String, dynamic> json) =>
      _$PerenualSpeciesFromJson(json);
}

// ── Species detail (from /api/species/{id}) ──────────────────────────────────

@freezed
abstract class PerenualSpeciesDetail with _$PerenualSpeciesDetail {
  const factory PerenualSpeciesDetail({
    required int id,
    @JsonKey(name: 'common_name') @Default('') String commonName,
    @JsonKey(name: 'scientific_name') @Default([]) List<String> scientificName,
    @Default('') String description,
    @Default('') String cycle,
    @Default('') String watering,
    @Default([]) List<String> sunlight,
    @JsonKey(name: 'growth_rate') @Default('') String growthRate,
    @JsonKey(name: 'care_level') @Default('') String careLevel,
    @Default(false) bool indoor,
    @Default(false) bool flowers,
    @Default(false) bool fruits,
    @JsonKey(name: 'edible_fruit') @Default(false) bool edibleFruit,
    @JsonKey(name: 'drought_tolerant') @Default(false) bool droughtTolerant,
    @JsonKey(name: 'pruning_month') @Default([]) List<String> pruningMonth,
    @JsonKey(name: 'default_image') PerenualImage? defaultImage,
  }) = _PerenualSpeciesDetail;

  factory PerenualSpeciesDetail.fromJson(Map<String, dynamic> json) =>
      _$PerenualSpeciesDetailFromJson(json);
}

// ── Image URLs ───────────────────────────────────────────────────────────────

@freezed
abstract class PerenualImage with _$PerenualImage {
  const factory PerenualImage({
    @JsonKey(name: 'original_url') @Default('') String originalUrl,
    @JsonKey(name: 'regular_url') @Default('') String regularUrl,
    @JsonKey(name: 'medium_url') @Default('') String mediumUrl,
    @JsonKey(name: 'small_url') @Default('') String smallUrl,
    @Default('') String thumbnail,
  }) = _PerenualImage;

  factory PerenualImage.fromJson(Map<String, dynamic> json) =>
      _$PerenualImageFromJson(json);
}

// ── Care guide response ──────────────────────────────────────────────────────

@freezed
abstract class PerenualCareGuideResponse with _$PerenualCareGuideResponse {
  const factory PerenualCareGuideResponse({
    @Default([]) List<PerenualCareGuide> data,
  }) = _PerenualCareGuideResponse;

  factory PerenualCareGuideResponse.fromJson(Map<String, dynamic> json) =>
      _$PerenualCareGuideResponseFromJson(json);
}

@freezed
abstract class PerenualCareGuide with _$PerenualCareGuide {
  const factory PerenualCareGuide({
    required int id,
    @JsonKey(name: 'species_id') required int speciesId,
    @JsonKey(name: 'common_name') @Default('') String commonName,
    @Default([]) List<PerenualCareSection> section,
  }) = _PerenualCareGuide;

  factory PerenualCareGuide.fromJson(Map<String, dynamic> json) =>
      _$PerenualCareGuideFromJson(json);
}

@freezed
abstract class PerenualCareSection with _$PerenualCareSection {
  const factory PerenualCareSection({
    @Default(0) int id,
    @Default('') String type,
    @Default('') String description,
  }) = _PerenualCareSection;

  factory PerenualCareSection.fromJson(Map<String, dynamic> json) =>
      _$PerenualCareSectionFromJson(json);
}
