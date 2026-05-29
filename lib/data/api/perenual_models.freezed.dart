// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'perenual_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PerenualListResponse {

 List<PerenualSpecies> get data;@JsonKey(name: 'current_page') int get currentPage;@JsonKey(name: 'last_page') int get lastPage; int get total;
/// Create a copy of PerenualListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualListResponseCopyWith<PerenualListResponse> get copyWith => _$PerenualListResponseCopyWithImpl<PerenualListResponse>(this as PerenualListResponse, _$identity);

  /// Serializes this PerenualListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualListResponse&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),currentPage,lastPage,total);

@override
String toString() {
  return 'PerenualListResponse(data: $data, currentPage: $currentPage, lastPage: $lastPage, total: $total)';
}


}

/// @nodoc
abstract mixin class $PerenualListResponseCopyWith<$Res>  {
  factory $PerenualListResponseCopyWith(PerenualListResponse value, $Res Function(PerenualListResponse) _then) = _$PerenualListResponseCopyWithImpl;
@useResult
$Res call({
 List<PerenualSpecies> data,@JsonKey(name: 'current_page') int currentPage,@JsonKey(name: 'last_page') int lastPage, int total
});




}
/// @nodoc
class _$PerenualListResponseCopyWithImpl<$Res>
    implements $PerenualListResponseCopyWith<$Res> {
  _$PerenualListResponseCopyWithImpl(this._self, this._then);

  final PerenualListResponse _self;
  final $Res Function(PerenualListResponse) _then;

/// Create a copy of PerenualListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<PerenualSpecies>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PerenualListResponse].
extension PerenualListResponsePatterns on PerenualListResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualListResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualListResponse value)  $default,){
final _that = this;
switch (_that) {
case _PerenualListResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualListResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PerenualSpecies> data, @JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualListResponse() when $default != null:
return $default(_that.data,_that.currentPage,_that.lastPage,_that.total);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PerenualSpecies> data, @JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total)  $default,) {final _that = this;
switch (_that) {
case _PerenualListResponse():
return $default(_that.data,_that.currentPage,_that.lastPage,_that.total);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PerenualSpecies> data, @JsonKey(name: 'current_page')  int currentPage, @JsonKey(name: 'last_page')  int lastPage,  int total)?  $default,) {final _that = this;
switch (_that) {
case _PerenualListResponse() when $default != null:
return $default(_that.data,_that.currentPage,_that.lastPage,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualListResponse implements PerenualListResponse {
  const _PerenualListResponse({required final  List<PerenualSpecies> data, @JsonKey(name: 'current_page') required this.currentPage, @JsonKey(name: 'last_page') required this.lastPage, this.total = 0}): _data = data;
  factory _PerenualListResponse.fromJson(Map<String, dynamic> json) => _$PerenualListResponseFromJson(json);

 final  List<PerenualSpecies> _data;
@override List<PerenualSpecies> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override@JsonKey(name: 'current_page') final  int currentPage;
@override@JsonKey(name: 'last_page') final  int lastPage;
@override@JsonKey() final  int total;

/// Create a copy of PerenualListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualListResponseCopyWith<_PerenualListResponse> get copyWith => __$PerenualListResponseCopyWithImpl<_PerenualListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualListResponse&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),currentPage,lastPage,total);

@override
String toString() {
  return 'PerenualListResponse(data: $data, currentPage: $currentPage, lastPage: $lastPage, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PerenualListResponseCopyWith<$Res> implements $PerenualListResponseCopyWith<$Res> {
  factory _$PerenualListResponseCopyWith(_PerenualListResponse value, $Res Function(_PerenualListResponse) _then) = __$PerenualListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PerenualSpecies> data,@JsonKey(name: 'current_page') int currentPage,@JsonKey(name: 'last_page') int lastPage, int total
});




}
/// @nodoc
class __$PerenualListResponseCopyWithImpl<$Res>
    implements _$PerenualListResponseCopyWith<$Res> {
  __$PerenualListResponseCopyWithImpl(this._self, this._then);

  final _PerenualListResponse _self;
  final $Res Function(_PerenualListResponse) _then;

/// Create a copy of PerenualListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,}) {
  return _then(_PerenualListResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<PerenualSpecies>,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PerenualSpecies {

 int get id;@JsonKey(name: 'common_name') String get commonName;@JsonKey(name: 'scientific_name') List<String> get scientificName; String get cycle; String get watering; List<String> get sunlight;@JsonKey(name: 'default_image') PerenualImage? get defaultImage;
/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualSpeciesCopyWith<PerenualSpecies> get copyWith => _$PerenualSpeciesCopyWithImpl<PerenualSpecies>(this as PerenualSpecies, _$identity);

  /// Serializes this PerenualSpecies to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualSpecies&&(identical(other.id, id) || other.id == id)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other.scientificName, scientificName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.watering, watering) || other.watering == watering)&&const DeepCollectionEquality().equals(other.sunlight, sunlight)&&(identical(other.defaultImage, defaultImage) || other.defaultImage == defaultImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,commonName,const DeepCollectionEquality().hash(scientificName),cycle,watering,const DeepCollectionEquality().hash(sunlight),defaultImage);

@override
String toString() {
  return 'PerenualSpecies(id: $id, commonName: $commonName, scientificName: $scientificName, cycle: $cycle, watering: $watering, sunlight: $sunlight, defaultImage: $defaultImage)';
}


}

/// @nodoc
abstract mixin class $PerenualSpeciesCopyWith<$Res>  {
  factory $PerenualSpeciesCopyWith(PerenualSpecies value, $Res Function(PerenualSpecies) _then) = _$PerenualSpeciesCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'common_name') String commonName,@JsonKey(name: 'scientific_name') List<String> scientificName, String cycle, String watering, List<String> sunlight,@JsonKey(name: 'default_image') PerenualImage? defaultImage
});


$PerenualImageCopyWith<$Res>? get defaultImage;

}
/// @nodoc
class _$PerenualSpeciesCopyWithImpl<$Res>
    implements $PerenualSpeciesCopyWith<$Res> {
  _$PerenualSpeciesCopyWithImpl(this._self, this._then);

  final PerenualSpecies _self;
  final $Res Function(PerenualSpecies) _then;

/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? commonName = null,Object? scientificName = null,Object? cycle = null,Object? watering = null,Object? sunlight = null,Object? defaultImage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self.scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as List<String>,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as String,watering: null == watering ? _self.watering : watering // ignore: cast_nullable_to_non_nullable
as String,sunlight: null == sunlight ? _self.sunlight : sunlight // ignore: cast_nullable_to_non_nullable
as List<String>,defaultImage: freezed == defaultImage ? _self.defaultImage : defaultImage // ignore: cast_nullable_to_non_nullable
as PerenualImage?,
  ));
}
/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerenualImageCopyWith<$Res>? get defaultImage {
    if (_self.defaultImage == null) {
    return null;
  }

  return $PerenualImageCopyWith<$Res>(_self.defaultImage!, (value) {
    return _then(_self.copyWith(defaultImage: value));
  });
}
}


/// Adds pattern-matching-related methods to [PerenualSpecies].
extension PerenualSpeciesPatterns on PerenualSpecies {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualSpecies value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualSpecies() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualSpecies value)  $default,){
final _that = this;
switch (_that) {
case _PerenualSpecies():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualSpecies value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualSpecies() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualSpecies() when $default != null:
return $default(_that.id,_that.commonName,_that.scientificName,_that.cycle,_that.watering,_that.sunlight,_that.defaultImage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)  $default,) {final _that = this;
switch (_that) {
case _PerenualSpecies():
return $default(_that.id,_that.commonName,_that.scientificName,_that.cycle,_that.watering,_that.sunlight,_that.defaultImage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)?  $default,) {final _that = this;
switch (_that) {
case _PerenualSpecies() when $default != null:
return $default(_that.id,_that.commonName,_that.scientificName,_that.cycle,_that.watering,_that.sunlight,_that.defaultImage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualSpecies implements PerenualSpecies {
  const _PerenualSpecies({required this.id, @JsonKey(name: 'common_name') this.commonName = '', @JsonKey(name: 'scientific_name') final  List<String> scientificName = const [], this.cycle = '', this.watering = '', final  List<String> sunlight = const [], @JsonKey(name: 'default_image') this.defaultImage}): _scientificName = scientificName,_sunlight = sunlight;
  factory _PerenualSpecies.fromJson(Map<String, dynamic> json) => _$PerenualSpeciesFromJson(json);

@override final  int id;
@override@JsonKey(name: 'common_name') final  String commonName;
 final  List<String> _scientificName;
@override@JsonKey(name: 'scientific_name') List<String> get scientificName {
  if (_scientificName is EqualUnmodifiableListView) return _scientificName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scientificName);
}

@override@JsonKey() final  String cycle;
@override@JsonKey() final  String watering;
 final  List<String> _sunlight;
@override@JsonKey() List<String> get sunlight {
  if (_sunlight is EqualUnmodifiableListView) return _sunlight;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sunlight);
}

@override@JsonKey(name: 'default_image') final  PerenualImage? defaultImage;

/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualSpeciesCopyWith<_PerenualSpecies> get copyWith => __$PerenualSpeciesCopyWithImpl<_PerenualSpecies>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualSpeciesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualSpecies&&(identical(other.id, id) || other.id == id)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other._scientificName, _scientificName)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.watering, watering) || other.watering == watering)&&const DeepCollectionEquality().equals(other._sunlight, _sunlight)&&(identical(other.defaultImage, defaultImage) || other.defaultImage == defaultImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,commonName,const DeepCollectionEquality().hash(_scientificName),cycle,watering,const DeepCollectionEquality().hash(_sunlight),defaultImage);

@override
String toString() {
  return 'PerenualSpecies(id: $id, commonName: $commonName, scientificName: $scientificName, cycle: $cycle, watering: $watering, sunlight: $sunlight, defaultImage: $defaultImage)';
}


}

/// @nodoc
abstract mixin class _$PerenualSpeciesCopyWith<$Res> implements $PerenualSpeciesCopyWith<$Res> {
  factory _$PerenualSpeciesCopyWith(_PerenualSpecies value, $Res Function(_PerenualSpecies) _then) = __$PerenualSpeciesCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'common_name') String commonName,@JsonKey(name: 'scientific_name') List<String> scientificName, String cycle, String watering, List<String> sunlight,@JsonKey(name: 'default_image') PerenualImage? defaultImage
});


@override $PerenualImageCopyWith<$Res>? get defaultImage;

}
/// @nodoc
class __$PerenualSpeciesCopyWithImpl<$Res>
    implements _$PerenualSpeciesCopyWith<$Res> {
  __$PerenualSpeciesCopyWithImpl(this._self, this._then);

  final _PerenualSpecies _self;
  final $Res Function(_PerenualSpecies) _then;

/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? commonName = null,Object? scientificName = null,Object? cycle = null,Object? watering = null,Object? sunlight = null,Object? defaultImage = freezed,}) {
  return _then(_PerenualSpecies(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self._scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as List<String>,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as String,watering: null == watering ? _self.watering : watering // ignore: cast_nullable_to_non_nullable
as String,sunlight: null == sunlight ? _self._sunlight : sunlight // ignore: cast_nullable_to_non_nullable
as List<String>,defaultImage: freezed == defaultImage ? _self.defaultImage : defaultImage // ignore: cast_nullable_to_non_nullable
as PerenualImage?,
  ));
}

/// Create a copy of PerenualSpecies
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerenualImageCopyWith<$Res>? get defaultImage {
    if (_self.defaultImage == null) {
    return null;
  }

  return $PerenualImageCopyWith<$Res>(_self.defaultImage!, (value) {
    return _then(_self.copyWith(defaultImage: value));
  });
}
}


/// @nodoc
mixin _$PerenualSpeciesDetail {

 int get id;@JsonKey(name: 'common_name') String get commonName;@JsonKey(name: 'scientific_name') List<String> get scientificName; String get description; String get cycle; String get watering; List<String> get sunlight;@JsonKey(name: 'growth_rate') String get growthRate;@JsonKey(name: 'care_level') String get careLevel; bool get indoor; bool get flowers; bool get fruits;@JsonKey(name: 'edible_fruit') bool get edibleFruit;@JsonKey(name: 'drought_tolerant') bool get droughtTolerant;@JsonKey(name: 'pruning_month') List<String> get pruningMonth;@JsonKey(name: 'default_image') PerenualImage? get defaultImage;
/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualSpeciesDetailCopyWith<PerenualSpeciesDetail> get copyWith => _$PerenualSpeciesDetailCopyWithImpl<PerenualSpeciesDetail>(this as PerenualSpeciesDetail, _$identity);

  /// Serializes this PerenualSpeciesDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualSpeciesDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other.scientificName, scientificName)&&(identical(other.description, description) || other.description == description)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.watering, watering) || other.watering == watering)&&const DeepCollectionEquality().equals(other.sunlight, sunlight)&&(identical(other.growthRate, growthRate) || other.growthRate == growthRate)&&(identical(other.careLevel, careLevel) || other.careLevel == careLevel)&&(identical(other.indoor, indoor) || other.indoor == indoor)&&(identical(other.flowers, flowers) || other.flowers == flowers)&&(identical(other.fruits, fruits) || other.fruits == fruits)&&(identical(other.edibleFruit, edibleFruit) || other.edibleFruit == edibleFruit)&&(identical(other.droughtTolerant, droughtTolerant) || other.droughtTolerant == droughtTolerant)&&const DeepCollectionEquality().equals(other.pruningMonth, pruningMonth)&&(identical(other.defaultImage, defaultImage) || other.defaultImage == defaultImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,commonName,const DeepCollectionEquality().hash(scientificName),description,cycle,watering,const DeepCollectionEquality().hash(sunlight),growthRate,careLevel,indoor,flowers,fruits,edibleFruit,droughtTolerant,const DeepCollectionEquality().hash(pruningMonth),defaultImage);

@override
String toString() {
  return 'PerenualSpeciesDetail(id: $id, commonName: $commonName, scientificName: $scientificName, description: $description, cycle: $cycle, watering: $watering, sunlight: $sunlight, growthRate: $growthRate, careLevel: $careLevel, indoor: $indoor, flowers: $flowers, fruits: $fruits, edibleFruit: $edibleFruit, droughtTolerant: $droughtTolerant, pruningMonth: $pruningMonth, defaultImage: $defaultImage)';
}


}

/// @nodoc
abstract mixin class $PerenualSpeciesDetailCopyWith<$Res>  {
  factory $PerenualSpeciesDetailCopyWith(PerenualSpeciesDetail value, $Res Function(PerenualSpeciesDetail) _then) = _$PerenualSpeciesDetailCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'common_name') String commonName,@JsonKey(name: 'scientific_name') List<String> scientificName, String description, String cycle, String watering, List<String> sunlight,@JsonKey(name: 'growth_rate') String growthRate,@JsonKey(name: 'care_level') String careLevel, bool indoor, bool flowers, bool fruits,@JsonKey(name: 'edible_fruit') bool edibleFruit,@JsonKey(name: 'drought_tolerant') bool droughtTolerant,@JsonKey(name: 'pruning_month') List<String> pruningMonth,@JsonKey(name: 'default_image') PerenualImage? defaultImage
});


$PerenualImageCopyWith<$Res>? get defaultImage;

}
/// @nodoc
class _$PerenualSpeciesDetailCopyWithImpl<$Res>
    implements $PerenualSpeciesDetailCopyWith<$Res> {
  _$PerenualSpeciesDetailCopyWithImpl(this._self, this._then);

  final PerenualSpeciesDetail _self;
  final $Res Function(PerenualSpeciesDetail) _then;

/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? commonName = null,Object? scientificName = null,Object? description = null,Object? cycle = null,Object? watering = null,Object? sunlight = null,Object? growthRate = null,Object? careLevel = null,Object? indoor = null,Object? flowers = null,Object? fruits = null,Object? edibleFruit = null,Object? droughtTolerant = null,Object? pruningMonth = null,Object? defaultImage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self.scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as String,watering: null == watering ? _self.watering : watering // ignore: cast_nullable_to_non_nullable
as String,sunlight: null == sunlight ? _self.sunlight : sunlight // ignore: cast_nullable_to_non_nullable
as List<String>,growthRate: null == growthRate ? _self.growthRate : growthRate // ignore: cast_nullable_to_non_nullable
as String,careLevel: null == careLevel ? _self.careLevel : careLevel // ignore: cast_nullable_to_non_nullable
as String,indoor: null == indoor ? _self.indoor : indoor // ignore: cast_nullable_to_non_nullable
as bool,flowers: null == flowers ? _self.flowers : flowers // ignore: cast_nullable_to_non_nullable
as bool,fruits: null == fruits ? _self.fruits : fruits // ignore: cast_nullable_to_non_nullable
as bool,edibleFruit: null == edibleFruit ? _self.edibleFruit : edibleFruit // ignore: cast_nullable_to_non_nullable
as bool,droughtTolerant: null == droughtTolerant ? _self.droughtTolerant : droughtTolerant // ignore: cast_nullable_to_non_nullable
as bool,pruningMonth: null == pruningMonth ? _self.pruningMonth : pruningMonth // ignore: cast_nullable_to_non_nullable
as List<String>,defaultImage: freezed == defaultImage ? _self.defaultImage : defaultImage // ignore: cast_nullable_to_non_nullable
as PerenualImage?,
  ));
}
/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerenualImageCopyWith<$Res>? get defaultImage {
    if (_self.defaultImage == null) {
    return null;
  }

  return $PerenualImageCopyWith<$Res>(_self.defaultImage!, (value) {
    return _then(_self.copyWith(defaultImage: value));
  });
}
}


/// Adds pattern-matching-related methods to [PerenualSpeciesDetail].
extension PerenualSpeciesDetailPatterns on PerenualSpeciesDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualSpeciesDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualSpeciesDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualSpeciesDetail value)  $default,){
final _that = this;
switch (_that) {
case _PerenualSpeciesDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualSpeciesDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualSpeciesDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String description,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'growth_rate')  String growthRate, @JsonKey(name: 'care_level')  String careLevel,  bool indoor,  bool flowers,  bool fruits, @JsonKey(name: 'edible_fruit')  bool edibleFruit, @JsonKey(name: 'drought_tolerant')  bool droughtTolerant, @JsonKey(name: 'pruning_month')  List<String> pruningMonth, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualSpeciesDetail() when $default != null:
return $default(_that.id,_that.commonName,_that.scientificName,_that.description,_that.cycle,_that.watering,_that.sunlight,_that.growthRate,_that.careLevel,_that.indoor,_that.flowers,_that.fruits,_that.edibleFruit,_that.droughtTolerant,_that.pruningMonth,_that.defaultImage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String description,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'growth_rate')  String growthRate, @JsonKey(name: 'care_level')  String careLevel,  bool indoor,  bool flowers,  bool fruits, @JsonKey(name: 'edible_fruit')  bool edibleFruit, @JsonKey(name: 'drought_tolerant')  bool droughtTolerant, @JsonKey(name: 'pruning_month')  List<String> pruningMonth, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)  $default,) {final _that = this;
switch (_that) {
case _PerenualSpeciesDetail():
return $default(_that.id,_that.commonName,_that.scientificName,_that.description,_that.cycle,_that.watering,_that.sunlight,_that.growthRate,_that.careLevel,_that.indoor,_that.flowers,_that.fruits,_that.edibleFruit,_that.droughtTolerant,_that.pruningMonth,_that.defaultImage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'common_name')  String commonName, @JsonKey(name: 'scientific_name')  List<String> scientificName,  String description,  String cycle,  String watering,  List<String> sunlight, @JsonKey(name: 'growth_rate')  String growthRate, @JsonKey(name: 'care_level')  String careLevel,  bool indoor,  bool flowers,  bool fruits, @JsonKey(name: 'edible_fruit')  bool edibleFruit, @JsonKey(name: 'drought_tolerant')  bool droughtTolerant, @JsonKey(name: 'pruning_month')  List<String> pruningMonth, @JsonKey(name: 'default_image')  PerenualImage? defaultImage)?  $default,) {final _that = this;
switch (_that) {
case _PerenualSpeciesDetail() when $default != null:
return $default(_that.id,_that.commonName,_that.scientificName,_that.description,_that.cycle,_that.watering,_that.sunlight,_that.growthRate,_that.careLevel,_that.indoor,_that.flowers,_that.fruits,_that.edibleFruit,_that.droughtTolerant,_that.pruningMonth,_that.defaultImage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualSpeciesDetail implements PerenualSpeciesDetail {
  const _PerenualSpeciesDetail({required this.id, @JsonKey(name: 'common_name') this.commonName = '', @JsonKey(name: 'scientific_name') final  List<String> scientificName = const [], this.description = '', this.cycle = '', this.watering = '', final  List<String> sunlight = const [], @JsonKey(name: 'growth_rate') this.growthRate = '', @JsonKey(name: 'care_level') this.careLevel = '', this.indoor = false, this.flowers = false, this.fruits = false, @JsonKey(name: 'edible_fruit') this.edibleFruit = false, @JsonKey(name: 'drought_tolerant') this.droughtTolerant = false, @JsonKey(name: 'pruning_month') final  List<String> pruningMonth = const [], @JsonKey(name: 'default_image') this.defaultImage}): _scientificName = scientificName,_sunlight = sunlight,_pruningMonth = pruningMonth;
  factory _PerenualSpeciesDetail.fromJson(Map<String, dynamic> json) => _$PerenualSpeciesDetailFromJson(json);

@override final  int id;
@override@JsonKey(name: 'common_name') final  String commonName;
 final  List<String> _scientificName;
@override@JsonKey(name: 'scientific_name') List<String> get scientificName {
  if (_scientificName is EqualUnmodifiableListView) return _scientificName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scientificName);
}

@override@JsonKey() final  String description;
@override@JsonKey() final  String cycle;
@override@JsonKey() final  String watering;
 final  List<String> _sunlight;
@override@JsonKey() List<String> get sunlight {
  if (_sunlight is EqualUnmodifiableListView) return _sunlight;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sunlight);
}

@override@JsonKey(name: 'growth_rate') final  String growthRate;
@override@JsonKey(name: 'care_level') final  String careLevel;
@override@JsonKey() final  bool indoor;
@override@JsonKey() final  bool flowers;
@override@JsonKey() final  bool fruits;
@override@JsonKey(name: 'edible_fruit') final  bool edibleFruit;
@override@JsonKey(name: 'drought_tolerant') final  bool droughtTolerant;
 final  List<String> _pruningMonth;
@override@JsonKey(name: 'pruning_month') List<String> get pruningMonth {
  if (_pruningMonth is EqualUnmodifiableListView) return _pruningMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pruningMonth);
}

@override@JsonKey(name: 'default_image') final  PerenualImage? defaultImage;

/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualSpeciesDetailCopyWith<_PerenualSpeciesDetail> get copyWith => __$PerenualSpeciesDetailCopyWithImpl<_PerenualSpeciesDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualSpeciesDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualSpeciesDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other._scientificName, _scientificName)&&(identical(other.description, description) || other.description == description)&&(identical(other.cycle, cycle) || other.cycle == cycle)&&(identical(other.watering, watering) || other.watering == watering)&&const DeepCollectionEquality().equals(other._sunlight, _sunlight)&&(identical(other.growthRate, growthRate) || other.growthRate == growthRate)&&(identical(other.careLevel, careLevel) || other.careLevel == careLevel)&&(identical(other.indoor, indoor) || other.indoor == indoor)&&(identical(other.flowers, flowers) || other.flowers == flowers)&&(identical(other.fruits, fruits) || other.fruits == fruits)&&(identical(other.edibleFruit, edibleFruit) || other.edibleFruit == edibleFruit)&&(identical(other.droughtTolerant, droughtTolerant) || other.droughtTolerant == droughtTolerant)&&const DeepCollectionEquality().equals(other._pruningMonth, _pruningMonth)&&(identical(other.defaultImage, defaultImage) || other.defaultImage == defaultImage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,commonName,const DeepCollectionEquality().hash(_scientificName),description,cycle,watering,const DeepCollectionEquality().hash(_sunlight),growthRate,careLevel,indoor,flowers,fruits,edibleFruit,droughtTolerant,const DeepCollectionEquality().hash(_pruningMonth),defaultImage);

@override
String toString() {
  return 'PerenualSpeciesDetail(id: $id, commonName: $commonName, scientificName: $scientificName, description: $description, cycle: $cycle, watering: $watering, sunlight: $sunlight, growthRate: $growthRate, careLevel: $careLevel, indoor: $indoor, flowers: $flowers, fruits: $fruits, edibleFruit: $edibleFruit, droughtTolerant: $droughtTolerant, pruningMonth: $pruningMonth, defaultImage: $defaultImage)';
}


}

/// @nodoc
abstract mixin class _$PerenualSpeciesDetailCopyWith<$Res> implements $PerenualSpeciesDetailCopyWith<$Res> {
  factory _$PerenualSpeciesDetailCopyWith(_PerenualSpeciesDetail value, $Res Function(_PerenualSpeciesDetail) _then) = __$PerenualSpeciesDetailCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'common_name') String commonName,@JsonKey(name: 'scientific_name') List<String> scientificName, String description, String cycle, String watering, List<String> sunlight,@JsonKey(name: 'growth_rate') String growthRate,@JsonKey(name: 'care_level') String careLevel, bool indoor, bool flowers, bool fruits,@JsonKey(name: 'edible_fruit') bool edibleFruit,@JsonKey(name: 'drought_tolerant') bool droughtTolerant,@JsonKey(name: 'pruning_month') List<String> pruningMonth,@JsonKey(name: 'default_image') PerenualImage? defaultImage
});


@override $PerenualImageCopyWith<$Res>? get defaultImage;

}
/// @nodoc
class __$PerenualSpeciesDetailCopyWithImpl<$Res>
    implements _$PerenualSpeciesDetailCopyWith<$Res> {
  __$PerenualSpeciesDetailCopyWithImpl(this._self, this._then);

  final _PerenualSpeciesDetail _self;
  final $Res Function(_PerenualSpeciesDetail) _then;

/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? commonName = null,Object? scientificName = null,Object? description = null,Object? cycle = null,Object? watering = null,Object? sunlight = null,Object? growthRate = null,Object? careLevel = null,Object? indoor = null,Object? flowers = null,Object? fruits = null,Object? edibleFruit = null,Object? droughtTolerant = null,Object? pruningMonth = null,Object? defaultImage = freezed,}) {
  return _then(_PerenualSpeciesDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,scientificName: null == scientificName ? _self._scientificName : scientificName // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cycle: null == cycle ? _self.cycle : cycle // ignore: cast_nullable_to_non_nullable
as String,watering: null == watering ? _self.watering : watering // ignore: cast_nullable_to_non_nullable
as String,sunlight: null == sunlight ? _self._sunlight : sunlight // ignore: cast_nullable_to_non_nullable
as List<String>,growthRate: null == growthRate ? _self.growthRate : growthRate // ignore: cast_nullable_to_non_nullable
as String,careLevel: null == careLevel ? _self.careLevel : careLevel // ignore: cast_nullable_to_non_nullable
as String,indoor: null == indoor ? _self.indoor : indoor // ignore: cast_nullable_to_non_nullable
as bool,flowers: null == flowers ? _self.flowers : flowers // ignore: cast_nullable_to_non_nullable
as bool,fruits: null == fruits ? _self.fruits : fruits // ignore: cast_nullable_to_non_nullable
as bool,edibleFruit: null == edibleFruit ? _self.edibleFruit : edibleFruit // ignore: cast_nullable_to_non_nullable
as bool,droughtTolerant: null == droughtTolerant ? _self.droughtTolerant : droughtTolerant // ignore: cast_nullable_to_non_nullable
as bool,pruningMonth: null == pruningMonth ? _self._pruningMonth : pruningMonth // ignore: cast_nullable_to_non_nullable
as List<String>,defaultImage: freezed == defaultImage ? _self.defaultImage : defaultImage // ignore: cast_nullable_to_non_nullable
as PerenualImage?,
  ));
}

/// Create a copy of PerenualSpeciesDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerenualImageCopyWith<$Res>? get defaultImage {
    if (_self.defaultImage == null) {
    return null;
  }

  return $PerenualImageCopyWith<$Res>(_self.defaultImage!, (value) {
    return _then(_self.copyWith(defaultImage: value));
  });
}
}


/// @nodoc
mixin _$PerenualImage {

@JsonKey(name: 'original_url') String get originalUrl;@JsonKey(name: 'regular_url') String get regularUrl;@JsonKey(name: 'medium_url') String get mediumUrl;@JsonKey(name: 'small_url') String get smallUrl; String get thumbnail;
/// Create a copy of PerenualImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualImageCopyWith<PerenualImage> get copyWith => _$PerenualImageCopyWithImpl<PerenualImage>(this as PerenualImage, _$identity);

  /// Serializes this PerenualImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualImage&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl)&&(identical(other.regularUrl, regularUrl) || other.regularUrl == regularUrl)&&(identical(other.mediumUrl, mediumUrl) || other.mediumUrl == mediumUrl)&&(identical(other.smallUrl, smallUrl) || other.smallUrl == smallUrl)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalUrl,regularUrl,mediumUrl,smallUrl,thumbnail);

@override
String toString() {
  return 'PerenualImage(originalUrl: $originalUrl, regularUrl: $regularUrl, mediumUrl: $mediumUrl, smallUrl: $smallUrl, thumbnail: $thumbnail)';
}


}

/// @nodoc
abstract mixin class $PerenualImageCopyWith<$Res>  {
  factory $PerenualImageCopyWith(PerenualImage value, $Res Function(PerenualImage) _then) = _$PerenualImageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'original_url') String originalUrl,@JsonKey(name: 'regular_url') String regularUrl,@JsonKey(name: 'medium_url') String mediumUrl,@JsonKey(name: 'small_url') String smallUrl, String thumbnail
});




}
/// @nodoc
class _$PerenualImageCopyWithImpl<$Res>
    implements $PerenualImageCopyWith<$Res> {
  _$PerenualImageCopyWithImpl(this._self, this._then);

  final PerenualImage _self;
  final $Res Function(PerenualImage) _then;

/// Create a copy of PerenualImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalUrl = null,Object? regularUrl = null,Object? mediumUrl = null,Object? smallUrl = null,Object? thumbnail = null,}) {
  return _then(_self.copyWith(
originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,regularUrl: null == regularUrl ? _self.regularUrl : regularUrl // ignore: cast_nullable_to_non_nullable
as String,mediumUrl: null == mediumUrl ? _self.mediumUrl : mediumUrl // ignore: cast_nullable_to_non_nullable
as String,smallUrl: null == smallUrl ? _self.smallUrl : smallUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PerenualImage].
extension PerenualImagePatterns on PerenualImage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualImage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualImage value)  $default,){
final _that = this;
switch (_that) {
case _PerenualImage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualImage value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualImage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'original_url')  String originalUrl, @JsonKey(name: 'regular_url')  String regularUrl, @JsonKey(name: 'medium_url')  String mediumUrl, @JsonKey(name: 'small_url')  String smallUrl,  String thumbnail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualImage() when $default != null:
return $default(_that.originalUrl,_that.regularUrl,_that.mediumUrl,_that.smallUrl,_that.thumbnail);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'original_url')  String originalUrl, @JsonKey(name: 'regular_url')  String regularUrl, @JsonKey(name: 'medium_url')  String mediumUrl, @JsonKey(name: 'small_url')  String smallUrl,  String thumbnail)  $default,) {final _that = this;
switch (_that) {
case _PerenualImage():
return $default(_that.originalUrl,_that.regularUrl,_that.mediumUrl,_that.smallUrl,_that.thumbnail);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'original_url')  String originalUrl, @JsonKey(name: 'regular_url')  String regularUrl, @JsonKey(name: 'medium_url')  String mediumUrl, @JsonKey(name: 'small_url')  String smallUrl,  String thumbnail)?  $default,) {final _that = this;
switch (_that) {
case _PerenualImage() when $default != null:
return $default(_that.originalUrl,_that.regularUrl,_that.mediumUrl,_that.smallUrl,_that.thumbnail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualImage implements PerenualImage {
  const _PerenualImage({@JsonKey(name: 'original_url') this.originalUrl = '', @JsonKey(name: 'regular_url') this.regularUrl = '', @JsonKey(name: 'medium_url') this.mediumUrl = '', @JsonKey(name: 'small_url') this.smallUrl = '', this.thumbnail = ''});
  factory _PerenualImage.fromJson(Map<String, dynamic> json) => _$PerenualImageFromJson(json);

@override@JsonKey(name: 'original_url') final  String originalUrl;
@override@JsonKey(name: 'regular_url') final  String regularUrl;
@override@JsonKey(name: 'medium_url') final  String mediumUrl;
@override@JsonKey(name: 'small_url') final  String smallUrl;
@override@JsonKey() final  String thumbnail;

/// Create a copy of PerenualImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualImageCopyWith<_PerenualImage> get copyWith => __$PerenualImageCopyWithImpl<_PerenualImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualImage&&(identical(other.originalUrl, originalUrl) || other.originalUrl == originalUrl)&&(identical(other.regularUrl, regularUrl) || other.regularUrl == regularUrl)&&(identical(other.mediumUrl, mediumUrl) || other.mediumUrl == mediumUrl)&&(identical(other.smallUrl, smallUrl) || other.smallUrl == smallUrl)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalUrl,regularUrl,mediumUrl,smallUrl,thumbnail);

@override
String toString() {
  return 'PerenualImage(originalUrl: $originalUrl, regularUrl: $regularUrl, mediumUrl: $mediumUrl, smallUrl: $smallUrl, thumbnail: $thumbnail)';
}


}

/// @nodoc
abstract mixin class _$PerenualImageCopyWith<$Res> implements $PerenualImageCopyWith<$Res> {
  factory _$PerenualImageCopyWith(_PerenualImage value, $Res Function(_PerenualImage) _then) = __$PerenualImageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'original_url') String originalUrl,@JsonKey(name: 'regular_url') String regularUrl,@JsonKey(name: 'medium_url') String mediumUrl,@JsonKey(name: 'small_url') String smallUrl, String thumbnail
});




}
/// @nodoc
class __$PerenualImageCopyWithImpl<$Res>
    implements _$PerenualImageCopyWith<$Res> {
  __$PerenualImageCopyWithImpl(this._self, this._then);

  final _PerenualImage _self;
  final $Res Function(_PerenualImage) _then;

/// Create a copy of PerenualImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalUrl = null,Object? regularUrl = null,Object? mediumUrl = null,Object? smallUrl = null,Object? thumbnail = null,}) {
  return _then(_PerenualImage(
originalUrl: null == originalUrl ? _self.originalUrl : originalUrl // ignore: cast_nullable_to_non_nullable
as String,regularUrl: null == regularUrl ? _self.regularUrl : regularUrl // ignore: cast_nullable_to_non_nullable
as String,mediumUrl: null == mediumUrl ? _self.mediumUrl : mediumUrl // ignore: cast_nullable_to_non_nullable
as String,smallUrl: null == smallUrl ? _self.smallUrl : smallUrl // ignore: cast_nullable_to_non_nullable
as String,thumbnail: null == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PerenualCareGuideResponse {

 List<PerenualCareGuide> get data;
/// Create a copy of PerenualCareGuideResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualCareGuideResponseCopyWith<PerenualCareGuideResponse> get copyWith => _$PerenualCareGuideResponseCopyWithImpl<PerenualCareGuideResponse>(this as PerenualCareGuideResponse, _$identity);

  /// Serializes this PerenualCareGuideResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualCareGuideResponse&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'PerenualCareGuideResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class $PerenualCareGuideResponseCopyWith<$Res>  {
  factory $PerenualCareGuideResponseCopyWith(PerenualCareGuideResponse value, $Res Function(PerenualCareGuideResponse) _then) = _$PerenualCareGuideResponseCopyWithImpl;
@useResult
$Res call({
 List<PerenualCareGuide> data
});




}
/// @nodoc
class _$PerenualCareGuideResponseCopyWithImpl<$Res>
    implements $PerenualCareGuideResponseCopyWith<$Res> {
  _$PerenualCareGuideResponseCopyWithImpl(this._self, this._then);

  final PerenualCareGuideResponse _self;
  final $Res Function(PerenualCareGuideResponse) _then;

/// Create a copy of PerenualCareGuideResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<PerenualCareGuide>,
  ));
}

}


/// Adds pattern-matching-related methods to [PerenualCareGuideResponse].
extension PerenualCareGuideResponsePatterns on PerenualCareGuideResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualCareGuideResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualCareGuideResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualCareGuideResponse value)  $default,){
final _that = this;
switch (_that) {
case _PerenualCareGuideResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualCareGuideResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualCareGuideResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PerenualCareGuide> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualCareGuideResponse() when $default != null:
return $default(_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PerenualCareGuide> data)  $default,) {final _that = this;
switch (_that) {
case _PerenualCareGuideResponse():
return $default(_that.data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PerenualCareGuide> data)?  $default,) {final _that = this;
switch (_that) {
case _PerenualCareGuideResponse() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualCareGuideResponse implements PerenualCareGuideResponse {
  const _PerenualCareGuideResponse({final  List<PerenualCareGuide> data = const []}): _data = data;
  factory _PerenualCareGuideResponse.fromJson(Map<String, dynamic> json) => _$PerenualCareGuideResponseFromJson(json);

 final  List<PerenualCareGuide> _data;
@override@JsonKey() List<PerenualCareGuide> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of PerenualCareGuideResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualCareGuideResponseCopyWith<_PerenualCareGuideResponse> get copyWith => __$PerenualCareGuideResponseCopyWithImpl<_PerenualCareGuideResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualCareGuideResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualCareGuideResponse&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'PerenualCareGuideResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class _$PerenualCareGuideResponseCopyWith<$Res> implements $PerenualCareGuideResponseCopyWith<$Res> {
  factory _$PerenualCareGuideResponseCopyWith(_PerenualCareGuideResponse value, $Res Function(_PerenualCareGuideResponse) _then) = __$PerenualCareGuideResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PerenualCareGuide> data
});




}
/// @nodoc
class __$PerenualCareGuideResponseCopyWithImpl<$Res>
    implements _$PerenualCareGuideResponseCopyWith<$Res> {
  __$PerenualCareGuideResponseCopyWithImpl(this._self, this._then);

  final _PerenualCareGuideResponse _self;
  final $Res Function(_PerenualCareGuideResponse) _then;

/// Create a copy of PerenualCareGuideResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_PerenualCareGuideResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<PerenualCareGuide>,
  ));
}


}


/// @nodoc
mixin _$PerenualCareGuide {

 int get id;@JsonKey(name: 'species_id') int get speciesId;@JsonKey(name: 'common_name') String get commonName; List<PerenualCareSection> get section;
/// Create a copy of PerenualCareGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualCareGuideCopyWith<PerenualCareGuide> get copyWith => _$PerenualCareGuideCopyWithImpl<PerenualCareGuide>(this as PerenualCareGuide, _$identity);

  /// Serializes this PerenualCareGuide to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualCareGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other.section, section));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,speciesId,commonName,const DeepCollectionEquality().hash(section));

@override
String toString() {
  return 'PerenualCareGuide(id: $id, speciesId: $speciesId, commonName: $commonName, section: $section)';
}


}

/// @nodoc
abstract mixin class $PerenualCareGuideCopyWith<$Res>  {
  factory $PerenualCareGuideCopyWith(PerenualCareGuide value, $Res Function(PerenualCareGuide) _then) = _$PerenualCareGuideCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'species_id') int speciesId,@JsonKey(name: 'common_name') String commonName, List<PerenualCareSection> section
});




}
/// @nodoc
class _$PerenualCareGuideCopyWithImpl<$Res>
    implements $PerenualCareGuideCopyWith<$Res> {
  _$PerenualCareGuideCopyWithImpl(this._self, this._then);

  final PerenualCareGuide _self;
  final $Res Function(PerenualCareGuide) _then;

/// Create a copy of PerenualCareGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? speciesId = null,Object? commonName = null,Object? section = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as List<PerenualCareSection>,
  ));
}

}


/// Adds pattern-matching-related methods to [PerenualCareGuide].
extension PerenualCareGuidePatterns on PerenualCareGuide {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualCareGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualCareGuide() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualCareGuide value)  $default,){
final _that = this;
switch (_that) {
case _PerenualCareGuide():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualCareGuide value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualCareGuide() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'species_id')  int speciesId, @JsonKey(name: 'common_name')  String commonName,  List<PerenualCareSection> section)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualCareGuide() when $default != null:
return $default(_that.id,_that.speciesId,_that.commonName,_that.section);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'species_id')  int speciesId, @JsonKey(name: 'common_name')  String commonName,  List<PerenualCareSection> section)  $default,) {final _that = this;
switch (_that) {
case _PerenualCareGuide():
return $default(_that.id,_that.speciesId,_that.commonName,_that.section);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'species_id')  int speciesId, @JsonKey(name: 'common_name')  String commonName,  List<PerenualCareSection> section)?  $default,) {final _that = this;
switch (_that) {
case _PerenualCareGuide() when $default != null:
return $default(_that.id,_that.speciesId,_that.commonName,_that.section);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualCareGuide implements PerenualCareGuide {
  const _PerenualCareGuide({required this.id, @JsonKey(name: 'species_id') required this.speciesId, @JsonKey(name: 'common_name') this.commonName = '', final  List<PerenualCareSection> section = const []}): _section = section;
  factory _PerenualCareGuide.fromJson(Map<String, dynamic> json) => _$PerenualCareGuideFromJson(json);

@override final  int id;
@override@JsonKey(name: 'species_id') final  int speciesId;
@override@JsonKey(name: 'common_name') final  String commonName;
 final  List<PerenualCareSection> _section;
@override@JsonKey() List<PerenualCareSection> get section {
  if (_section is EqualUnmodifiableListView) return _section;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_section);
}


/// Create a copy of PerenualCareGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualCareGuideCopyWith<_PerenualCareGuide> get copyWith => __$PerenualCareGuideCopyWithImpl<_PerenualCareGuide>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualCareGuideToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualCareGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.commonName, commonName) || other.commonName == commonName)&&const DeepCollectionEquality().equals(other._section, _section));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,speciesId,commonName,const DeepCollectionEquality().hash(_section));

@override
String toString() {
  return 'PerenualCareGuide(id: $id, speciesId: $speciesId, commonName: $commonName, section: $section)';
}


}

/// @nodoc
abstract mixin class _$PerenualCareGuideCopyWith<$Res> implements $PerenualCareGuideCopyWith<$Res> {
  factory _$PerenualCareGuideCopyWith(_PerenualCareGuide value, $Res Function(_PerenualCareGuide) _then) = __$PerenualCareGuideCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'species_id') int speciesId,@JsonKey(name: 'common_name') String commonName, List<PerenualCareSection> section
});




}
/// @nodoc
class __$PerenualCareGuideCopyWithImpl<$Res>
    implements _$PerenualCareGuideCopyWith<$Res> {
  __$PerenualCareGuideCopyWithImpl(this._self, this._then);

  final _PerenualCareGuide _self;
  final $Res Function(_PerenualCareGuide) _then;

/// Create a copy of PerenualCareGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? speciesId = null,Object? commonName = null,Object? section = null,}) {
  return _then(_PerenualCareGuide(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as int,commonName: null == commonName ? _self.commonName : commonName // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self._section : section // ignore: cast_nullable_to_non_nullable
as List<PerenualCareSection>,
  ));
}


}


/// @nodoc
mixin _$PerenualCareSection {

 int get id; String get type; String get description;
/// Create a copy of PerenualCareSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerenualCareSectionCopyWith<PerenualCareSection> get copyWith => _$PerenualCareSectionCopyWithImpl<PerenualCareSection>(this as PerenualCareSection, _$identity);

  /// Serializes this PerenualCareSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerenualCareSection&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,description);

@override
String toString() {
  return 'PerenualCareSection(id: $id, type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class $PerenualCareSectionCopyWith<$Res>  {
  factory $PerenualCareSectionCopyWith(PerenualCareSection value, $Res Function(PerenualCareSection) _then) = _$PerenualCareSectionCopyWithImpl;
@useResult
$Res call({
 int id, String type, String description
});




}
/// @nodoc
class _$PerenualCareSectionCopyWithImpl<$Res>
    implements $PerenualCareSectionCopyWith<$Res> {
  _$PerenualCareSectionCopyWithImpl(this._self, this._then);

  final PerenualCareSection _self;
  final $Res Function(PerenualCareSection) _then;

/// Create a copy of PerenualCareSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PerenualCareSection].
extension PerenualCareSectionPatterns on PerenualCareSection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerenualCareSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerenualCareSection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerenualCareSection value)  $default,){
final _that = this;
switch (_that) {
case _PerenualCareSection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerenualCareSection value)?  $default,){
final _that = this;
switch (_that) {
case _PerenualCareSection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerenualCareSection() when $default != null:
return $default(_that.id,_that.type,_that.description);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String description)  $default,) {final _that = this;
switch (_that) {
case _PerenualCareSection():
return $default(_that.id,_that.type,_that.description);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String description)?  $default,) {final _that = this;
switch (_that) {
case _PerenualCareSection() when $default != null:
return $default(_that.id,_that.type,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerenualCareSection implements PerenualCareSection {
  const _PerenualCareSection({this.id = 0, this.type = '', this.description = ''});
  factory _PerenualCareSection.fromJson(Map<String, dynamic> json) => _$PerenualCareSectionFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String type;
@override@JsonKey() final  String description;

/// Create a copy of PerenualCareSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerenualCareSectionCopyWith<_PerenualCareSection> get copyWith => __$PerenualCareSectionCopyWithImpl<_PerenualCareSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerenualCareSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerenualCareSection&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,description);

@override
String toString() {
  return 'PerenualCareSection(id: $id, type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class _$PerenualCareSectionCopyWith<$Res> implements $PerenualCareSectionCopyWith<$Res> {
  factory _$PerenualCareSectionCopyWith(_PerenualCareSection value, $Res Function(_PerenualCareSection) _then) = __$PerenualCareSectionCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String description
});




}
/// @nodoc
class __$PerenualCareSectionCopyWithImpl<$Res>
    implements _$PerenualCareSectionCopyWith<$Res> {
  __$PerenualCareSectionCopyWithImpl(this._self, this._then);

  final _PerenualCareSection _self;
  final $Res Function(_PerenualCareSection) _then;

/// Create a copy of PerenualCareSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? description = null,}) {
  return _then(_PerenualCareSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
