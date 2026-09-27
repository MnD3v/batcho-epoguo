import 'dart:convert';
import 'dart:io';

import '../models/city.dart';

/// Température maximale prévue aujourd'hui.
abstract class WeatherService {
  Future<double?> todayMax(City city);
}

/// Open-Meteo : gratuit, sans clé, quelques octets par jour.
class OpenMeteoWeather implements WeatherService {
  @override
  Future<double?> todayMax(City city) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'daily': 'temperature_2m_max',
        'timezone': 'auto',
        'forecast_days': '1',
      });
      final response = await (await client.getUrl(uri)).close();
      if (response.statusCode != 200) return null;
      return parseTodayMax(await response.transform(utf8.decoder).join());
    } catch (_) {
      return null; // Pas de réseau : pas de mode chaleur aujourd'hui.
    } finally {
      client.close();
    }
  }
}

/// `{"daily": {"temperature_2m_max": [36.4]}}` → 36.4
double? parseTodayMax(String body) {
  final daily = (jsonDecode(body) as Map<String, dynamic>)['daily'];
  if (daily is! Map) return null;
  final values = daily['temperature_2m_max'];
  if (values is! List || values.isEmpty) return null;
  return (values.first as num?)?.toDouble();
}
