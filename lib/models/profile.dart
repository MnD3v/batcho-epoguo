/// Ce que la personne dit de ses habitudes au premier lancement.
class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.email,
    required this.usualIntake,
    required this.difficulties,
  });

  final String firstName;
  final String email;
  final UsualIntake usualIntake;
  final Set<Difficulty> difficulties;
}

enum UsualIntake {
  lessThan1L('Moins de 1 L', 'assets/drinks/glass.svg'),
  about1_5L('Environ 1,5 L', 'assets/drinks/pure_water.svg'),
  about2L('Environ 2 L', 'assets/drinks/bottle.svg'),
  moreThan2L('Plus de 2 L', 'assets/icons/xp.svg');

  const UsualIntake(this.label, this.icon);

  final String label;
  final String icon;
}

enum Difficulty {
  forget(
    'J\'oublie de boire',
    'Pas de souci : je sonne à chaque alerte pour te le rappeler.',
  ),
  noDesire(
    'Je n\'ai pas soif, pas envie',
    'N\'attends pas la soif : quelques gorgées à chaque alerte suffisent.',
  ),
  noWaterNearby(
    'Pas d\'eau à côté de moi',
    'Garde une bouteille ou un pure water près de toi dès le matin.',
  ),
  tooBusy(
    'Je suis trop occupé(e)',
    'Une alerte, un verre, 30 secondes : c\'est tout ce qu\'il faut.',
  );

  const Difficulty(this.label, this.advice);

  final String label;

  /// Conseil de Reno pour cette difficulté.
  final String advice;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());
