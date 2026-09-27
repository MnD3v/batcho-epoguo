/// Villes proposées pour la météo (pas besoin du GPS).
class City {
  const City(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}

const cities = [
  // Togo
  City('Lomé', 6.1375, 1.2123),
  City('Aného', 6.2333, 1.6000),
  City('Tsévié', 6.4261, 1.2133),
  City('Kpalimé', 6.9000, 0.6333),
  City('Atakpamé', 7.5333, 1.1333),
  City('Sokodé', 8.9833, 1.1333),
  City('Kara', 9.5511, 1.1861),
  City('Dapaong', 10.8622, 0.2076),
  // Afrique de l'Ouest et centrale
  City('Cotonou', 6.3654, 2.4183),
  City('Porto-Novo', 6.4969, 2.6289),
  City('Accra', 5.6037, -0.1870),
  City('Lagos', 6.5244, 3.3792),
  City('Abidjan', 5.3600, -4.0083),
  City('Ouagadougou', 12.3714, -1.5197),
  City('Niamey', 13.5116, 2.1254),
  City('Bamako', 12.6392, -8.0029),
  City('Dakar', 14.7167, -17.4677),
  City('Conakry', 9.6412, -13.5784),
  City('Douala', 4.0511, 9.7679),
  City('Yaoundé', 3.8480, 11.5021),
  City('Libreville', 0.4162, 9.4673),
  City('Kinshasa', -4.4419, 15.2663),
];

City? cityNamed(String? name) =>
    cities.where((c) => c.name == name).firstOrNull;

/// À partir de cette température, Reno conseille de boire plus.
const hotDayCelsius = 35.0;

/// Verres en plus conseillés les jours de forte chaleur.
const hotDayExtraGlasses = 2;
