import 'package:flutter/painting.dart';

/// Points gagnés.
const xpPerCheck = 10;
const xpPerfectDay = 30;
const xpPerTip = 5;

/// Nombre de rappels cochés dans la journée pour garder sa flamme.
const streakMinChecks = 5;

class Level {
  const Level(this.number, this.name, this.minXp);

  final int number;
  final String name;
  final int minXp;
}

const levels = [
  Level(1, 'Goutte', 0),
  Level(2, 'Flaque', 100),
  Level(3, 'Ruisseau', 250),
  Level(4, 'Rivière', 500),
  Level(5, 'Cascade', 900),
  Level(6, 'Lac', 1400),
  Level(7, 'Fleuve', 2000),
  Level(8, 'Mer', 3000),
  Level(9, 'Océan', 4500),
];

Level levelFor(int xp) => levels.lastWhere((l) => xp >= l.minXp);

Level? nextLevel(Level level) =>
    level.number < levels.length ? levels[level.number] : null;

enum Achievement {
  firstSip(
    'Première gorgée',
    'Coche ton premier rappel',
    'assets/icons/drop.svg',
    Color(0xFF1CB0F6),
  ),
  perfectDay(
    'Journée parfaite',
    'Coche les 7 rappels d\'une journée',
    'assets/icons/star.svg',
    Color(0xFFFFC800),
  ),
  streak3(
    'En feu',
    'Garde ta flamme 3 jours de suite',
    'assets/icons/flame.svg',
    Color(0xFFFF9600),
  ),
  streak7(
    'Semaine de feu',
    'Garde ta flamme 7 jours de suite',
    'assets/icons/flame.svg',
    Color(0xFFFF4B4B),
  ),
  streak30(
    'Inarrêtable',
    'Garde ta flamme 30 jours de suite',
    'assets/icons/crown.svg',
    Color(0xFFCE82FF),
  ),
  earlyBird(
    'Lève-tôt',
    'Bois au rappel de 7h',
    'assets/icons/sunrise.svg',
    Color(0xFFFF9600),
  ),
  nightOwl(
    'Sprint final',
    'Bois au rappel de 19h',
    'assets/icons/moon.svg',
    Color(0xFF8E7CF0),
  ),
  liters10(
    '10 litres',
    'Bois 10 litres au total',
    'assets/icons/xp.svg',
    Color(0xFF1CB0F6),
  ),
  liters50(
    '50 litres',
    'Bois 50 litres au total',
    'assets/icons/trophy.svg',
    Color(0xFFFFC800),
  ),
  allTips(
    'Expert des reins',
    'Lis toutes les leçons',
    'assets/icons/book.svg',
    Color(0xFF58CC02),
  );

  const Achievement(this.title, this.description, this.icon, this.color);

  final String title;
  final String description;
  final String icon;
  final Color color;
}

/// Ce qu'une action vient de rapporter, pour la fête à l'écran.
class Reward {
  const Reward({
    this.xp = 0,
    this.goalReached = false,
    this.badges = const [],
    this.levelUp,
  });

  final int xp;
  final bool goalReached;
  final List<Achievement> badges;
  final Level? levelUp;
}
