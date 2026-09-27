import 'package:bois_et_vis/data/hydration_store.dart';
import 'package:bois_et_vis/hydration_controller.dart';
import 'package:bois_et_vis/models/city.dart';
import 'package:bois_et_vis/services/read_aloud.dart';
import 'package:bois_et_vis/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class FakeWeather implements WeatherService {
  FakeWeather(this.max);

  final double? max;
  int calls = 0;

  @override
  Future<double?> todayMax(City city) async {
    calls++;
    return max;
  }
}

void main() {
  test('réponse d\'Open-Meteo', () {
    expect(
      parseTodayMax(
        '{"daily":{"time":["2026-09-27"],"temperature_2m_max":[36.4]}}',
      ),
      36.4,
    );
    expect(parseTodayMax('{"daily":{"temperature_2m_max":[]}}'), isNull);
    expect(parseTodayMax('{"error":true}'), isNull);
  });

  test('texte lu à voix haute : sans emojis, litres en toutes lettres', () {
    expect(
      speakable('Awa, lève-toi et bois 0,5 L ! 💧🔥'),
      'Awa, lève-toi et bois 0,5 litre !',
    );
    expect(speakable('Bois 1 L'), 'Bois 1 litre');
    expect(speakable('1,75 L sur 2,5 L'), '1,75 litre sur 2,5 litres');
  });

  Future<(HydrationController, FakeWeather)> make(double? max) async {
    SharedPreferences.setMockInitialValues(setUpPrefs);
    final weather = FakeWeather(max);
    final c = HydrationController(
      store: await HydrationStore.load(),
      scheduler: FakeScheduler(),
      weather: weather,
      clock: () => DateTime(2026, 9, 27, 10),
    );
    return (c, weather);
  }

  test('mode chaleur : une requête par jour, conseil au-delà de 35 °C',
      () async {
    final (c, weather) = await make(37.2);
    expect(c.city, isNull);
    await c.refreshWeather();
    expect(weather.calls, 0); // pas de ville, pas de requête

    await c.setCity(cities.first);
    expect(c.city?.name, 'Lomé');
    expect(c.todayMax, 37.2);
    expect(c.isHotToday, isTrue);
    await c.refreshWeather();
    expect(weather.calls, 1); // déjà connue aujourd'hui
  });

  test('pas de réseau : pas de mode chaleur', () async {
    final (c, _) = await make(null);
    await c.setCity(cities.first);
    expect(c.todayMax, isNull);
    expect(c.isHotToday, isFalse);
  });

  test('journée normale : pas d\'alerte chaleur', () async {
    final (c, _) = await make(31);
    await c.setCity(cities.first);
    expect(c.isHotToday, isFalse);
  });
}
