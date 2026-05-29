// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perenual_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PerenualListResponse _$PerenualListResponseFromJson(
  Map<String, dynamic> json,
) => _PerenualListResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => PerenualSpecies.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentPage: (json['current_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PerenualListResponseToJson(
  _PerenualListResponse instance,
) => <String, dynamic>{
  'data': instance.data,
  'current_page': instance.currentPage,
  'last_page': instance.lastPage,
  'total': instance.total,
};

_PerenualSpecies _$PerenualSpeciesFromJson(
  Map<String, dynamic> json,
) => _PerenualSpecies(
  id: (json['id'] as num).toInt(),
  commonName: json['common_name'] as String? ?? '',
  scientificName:
      (json['scientific_name'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  cycle: json['cycle'] as String? ?? '',
  watering: json['watering'] as String? ?? '',
  sunlight:
      (json['sunlight'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  defaultImage: json['default_image'] == null
      ? null
      : PerenualImage.fromJson(json['default_image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PerenualSpeciesToJson(_PerenualSpecies instance) =>
    <String, dynamic>{
      'id': instance.id,
      'common_name': instance.commonName,
      'scientific_name': instance.scientificName,
      'cycle': instance.cycle,
      'watering': instance.watering,
      'sunlight': instance.sunlight,
      'default_image': instance.defaultImage,
    };

_PerenualSpeciesDetail _$PerenualSpeciesDetailFromJson(
  Map<String, dynamic> json,
) => _PerenualSpeciesDetail(
  id: (json['id'] as num).toInt(),
  commonName: json['common_name'] as String? ?? '',
  scientificName:
      (json['scientific_name'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  description: json['description'] as String? ?? '',
  cycle: json['cycle'] as String? ?? '',
  watering: json['watering'] as String? ?? '',
  sunlight:
      (json['sunlight'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  growthRate: json['growth_rate'] as String? ?? '',
  careLevel: json['care_level'] as String? ?? '',
  indoor: json['indoor'] as bool? ?? false,
  flowers: json['flowers'] as bool? ?? false,
  fruits: json['fruits'] as bool? ?? false,
  edibleFruit: json['edible_fruit'] as bool? ?? false,
  droughtTolerant: json['drought_tolerant'] as bool? ?? false,
  pruningMonth:
      (json['pruning_month'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  defaultImage: json['default_image'] == null
      ? null
      : PerenualImage.fromJson(json['default_image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PerenualSpeciesDetailToJson(
  _PerenualSpeciesDetail instance,
) => <String, dynamic>{
  'id': instance.id,
  'common_name': instance.commonName,
  'scientific_name': instance.scientificName,
  'description': instance.description,
  'cycle': instance.cycle,
  'watering': instance.watering,
  'sunlight': instance.sunlight,
  'growth_rate': instance.growthRate,
  'care_level': instance.careLevel,
  'indoor': instance.indoor,
  'flowers': instance.flowers,
  'fruits': instance.fruits,
  'edible_fruit': instance.edibleFruit,
  'drought_tolerant': instance.droughtTolerant,
  'pruning_month': instance.pruningMonth,
  'default_image': instance.defaultImage,
};

_PerenualImage _$PerenualImageFromJson(Map<String, dynamic> json) =>
    _PerenualImage(
      originalUrl: json['original_url'] as String? ?? '',
      regularUrl: json['regular_url'] as String? ?? '',
      mediumUrl: json['medium_url'] as String? ?? '',
      smallUrl: json['small_url'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
    );

Map<String, dynamic> _$PerenualImageToJson(_PerenualImage instance) =>
    <String, dynamic>{
      'original_url': instance.originalUrl,
      'regular_url': instance.regularUrl,
      'medium_url': instance.mediumUrl,
      'small_url': instance.smallUrl,
      'thumbnail': instance.thumbnail,
    };

_PerenualCareGuideResponse _$PerenualCareGuideResponseFromJson(
  Map<String, dynamic> json,
) => _PerenualCareGuideResponse(
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => PerenualCareGuide.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PerenualCareGuideResponseToJson(
  _PerenualCareGuideResponse instance,
) => <String, dynamic>{'data': instance.data};

_PerenualCareGuide _$PerenualCareGuideFromJson(Map<String, dynamic> json) =>
    _PerenualCareGuide(
      id: (json['id'] as num).toInt(),
      speciesId: (json['species_id'] as num).toInt(),
      commonName: json['common_name'] as String? ?? '',
      section:
          (json['section'] as List<dynamic>?)
              ?.map(
                (e) => PerenualCareSection.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PerenualCareGuideToJson(_PerenualCareGuide instance) =>
    <String, dynamic>{
      'id': instance.id,
      'species_id': instance.speciesId,
      'common_name': instance.commonName,
      'section': instance.section,
    };

_PerenualCareSection _$PerenualCareSectionFromJson(Map<String, dynamic> json) =>
    _PerenualCareSection(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );

Map<String, dynamic> _$PerenualCareSectionToJson(
  _PerenualCareSection instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'description': instance.description,
};
