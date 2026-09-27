/// Ce que la personne boit à chaque rappel.
enum DrinkType {
  pureWater(
    label: 'Pure water',
    singular: 'pure water',
    plural: 'pure water',
    asset: 'assets/drinks/pure_water.svg',
    sizesMl: [500],
  ),
  glass(
    label: 'Verre',
    singular: 'verre',
    plural: 'verres',
    asset: 'assets/drinks/glass.svg',
    sizesMl: [200, 250, 300, 330],
  ),
  bottle(
    label: 'Bouteille',
    singular: 'bouteille',
    plural: 'bouteilles',
    asset: 'assets/drinks/bottle.svg',
    sizesMl: [330, 500, 750, 1000],
  );

  const DrinkType({
    required this.label,
    required this.singular,
    required this.plural,
    required this.asset,
    required this.sizesMl,
  });

  final String label;
  final String singular;
  final String plural;
  final String asset;

  /// Contenances proposées ; une seule valeur veut dire contenance fixe.
  final List<int> sizesMl;

  int get defaultSizeMl => sizesMl.length == 1 ? sizesMl.first : sizesMl[1];

  String units(int count) => '$count ${count > 1 ? plural : singular}';
}

class DrinkSettings {
  const DrinkSettings({
    required this.type,
    required this.unitMl,
    required this.unitsPerReminder,
  });

  factory DrinkSettings.defaults(DrinkType type) => DrinkSettings(
    type: type,
    unitMl: type.defaultSizeMl,
    unitsPerReminder: 1,
  );

  final DrinkType type;
  final int unitMl;
  final int unitsPerReminder;

  /// Quantité bue à chaque rappel coché.
  int get doseMl => unitMl * unitsPerReminder;

  /// Ex. « 2 verres (0,5 L) ».
  String get doseLabel =>
      '${type.units(unitsPerReminder)} (${formatLiters(doseMl)})';

  DrinkSettings copyWith({
    DrinkType? type,
    int? unitMl,
    int? unitsPerReminder,
  }) => DrinkSettings(
    type: type ?? this.type,
    unitMl: unitMl ?? this.unitMl,
    unitsPerReminder: unitsPerReminder ?? this.unitsPerReminder,
  );
}

/// 500 → « 0,5 L », 1750 → « 1,75 L ».
String formatLiters(int ml) {
  var text = (ml / 1000).toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '${text.replaceAll('.', ',')} L';
}
