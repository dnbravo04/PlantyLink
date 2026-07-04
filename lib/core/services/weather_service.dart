import 'package:dio/dio.dart';

/// Current weather for the user's city, fetched from Open-Meteo
/// (free, no API key). Gives the profile's `ciudad` field real utility:
/// ambient context next to the greenhouse readings.
class WeatherInfo {
  final String ciudad;
  final double tempC;
  final double humidity;
  final int weatherCode;

  const WeatherInfo({
    required this.ciudad,
    required this.tempC,
    required this.humidity,
    required this.weatherCode,
  });

  /// Human description of the WMO weather code, in Spanish.
  String get descripcion => switch (weatherCode) {
        0 => 'Despejado',
        1 || 2 => 'Parcialmente nublado',
        3 => 'Nublado',
        45 || 48 => 'Niebla',
        >= 51 && <= 57 => 'Llovizna',
        >= 61 && <= 67 => 'Lluvia',
        >= 71 && <= 77 => 'Nieve',
        >= 80 && <= 82 => 'Chubascos',
        >= 95 => 'Tormenta',
        _ => 'Nublado',
      };

  bool get isRainy => weatherCode >= 51;
  bool get isClear => weatherCode <= 1;
}

class WeatherService {
  static const _ttl = Duration(minutes: 30);
  static final _cache = <String, (DateTime, WeatherInfo)>{};

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Resolves [ciudad] to coordinates and fetches current conditions.
  /// Returns null when the city can't be geocoded or the network fails —
  /// the UI simply hides the weather chip.
  Future<WeatherInfo?> fetchForCity(String ciudad) async {
    final key = ciudad.trim().toLowerCase();
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.$1) < _ttl) {
      return cached.$2;
    }

    try {
      final geo = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {'name': ciudad, 'count': 1, 'language': 'es'},
      );
      final results = geo.data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final place = results.first as Map<String, dynamic>;

      final weather = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': place['latitude'],
          'longitude': place['longitude'],
          'current': 'temperature_2m,relative_humidity_2m,weather_code',
        },
      );
      final current = weather.data['current'] as Map<String, dynamic>;
      final info = WeatherInfo(
        ciudad: place['name'] as String? ?? ciudad,
        tempC: (current['temperature_2m'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
      );
      _cache[key] = (DateTime.now(), info);
      return info;
    } catch (_) {
      return null;
    }
  }
}
