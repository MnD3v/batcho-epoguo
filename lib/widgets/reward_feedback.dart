import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/game.dart';
import '../theme/duo.dart';
import 'duo_widgets.dart';
import 'motion.dart';
import 'share_card.dart';

const _praises = [
  'Excellent !',
  'Bien joué !',
  'Super !',
  'Parfait !',
  'Tes reins te disent merci !',
  'Continue comme ça !',
];

/// Panneau vert en bas de l'écran après une bonne action, puis la fête en
/// plein écran si l'objectif du jour, un niveau ou un badge vient de tomber.
Future<void> showReward(
  BuildContext context,
  Reward reward, {
  String? message,
}) async {
  if (reward.xp <= 0 && reward.badges.isEmpty) return;
  final praise = _praises[math.Random().nextInt(_praises.length)];
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Duo.greenLight,
    barrierColor: Colors.black26,
    shape: const RoundedRectangleBorder(),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Le verre se remplit : c'est bu !
                const GlassFill(level: 0.92, from: 0.1, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    praise,
                    style: Duo.title.copyWith(color: Duo.greenDark),
                  ),
                ),
                if (reward.xp > 0)
                  PopIn(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/xp.svg',
                          width: 28,
                          height: 28,
                        ),
                        const SizedBox(width: 6),
                        CountUp(
                          value: reward.xp,
                          prefix: '+',
                          suffix: ' XP',
                          style: const TextStyle(
                            fontFamily: Duo.font,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Duo.blueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(message, style: Duo.body.copyWith(color: Duo.greenDark)),
            ],
            const SizedBox(height: 18),
            DuoButton(
              label: 'Continuer',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (reward.worthCelebrating) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CelebrationScreen(reward: reward),
      ),
    );
  }
}

class CelebrationScreen extends StatelessWidget {
  const CelebrationScreen({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final level = reward.levelUp;
    final milestone = reward.streakMilestone;
    final title = milestone != null
        ? '$milestone jours de flamme !'
        : reward.goalReached
            ? 'Objectif du jour atteint !'
            : level != null
                ? 'Niveau ${level.number} : ${level.name} !'
                : reward.freezeEarned && reward.badges.isEmpty
                    ? 'Jour de repos gagné !'
                    : reward.badges.length > 1
                        ? 'Nouveaux badges !'
                        : 'Nouveau badge !';
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  const AnimatedMascot(pose: 'mascot_cheer', size: 200),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Duo.title.copyWith(color: Duo.gold, fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  if (milestone != null)
                    Text(
                      '$milestone jours d\'affilée : tes reins te disent merci !',
                      textAlign: TextAlign.center,
                      style: Duo.body,
                    )
                  else if (reward.goalReached)
                    const Text(
                      'Toutes tes alertes sont cochées. Reno est au top de sa forme !',
                      textAlign: TextAlign.center,
                      style: Duo.body,
                    ),
                  if (level != null && reward.goalReached)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Et tu passes au niveau ${level.number} : ${level.name} !',
                        textAlign: TextAlign.center,
                        style: Duo.body.copyWith(color: Duo.blueDark),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (reward.xp > 0)
                        _StatBox(
                          label: 'XP gagnés',
                          value: '+${reward.xp}',
                          color: Duo.gold,
                          icon: 'assets/icons/xp.svg',
                        ),
                      if (reward.freezeEarned)
                        const _StatBox(
                          label: 'Jour de repos',
                          value: '+1',
                          color: Duo.blue,
                          icon: 'assets/icons/freeze.svg',
                        ),
                      for (final badge in reward.badges)
                        _StatBox(
                          label: 'Badge',
                          value: badge.title,
                          color: badge.color,
                          icon: badge.icon,
                        ),
                    ],
                  ),
                  const Spacer(),
                  DuoButton.outline(
                    label: 'Partager',
                    icon: Icons.share_rounded,
                    onPressed: () => shareProgress(
                      context,
                      headline: title,
                      detail: reward.badges.isNotEmpty
                          ? 'Badge « ${reward.badges.first.title} »'
                          : 'Je bois mon eau et je protège mes reins.',
                      icon: reward.badges.isNotEmpty
                          ? reward.badges.first.icon
                          : 'assets/icons/flame.svg',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DuoButton(
                    label: 'Continuer',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pluie de gouttes et d'étoiles.
        const Positioned.fill(child: ConfettiRain()),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label.toUpperCase(),
              style: Duo.label.copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SvgPicture.asset(icon, width: 32, height: 32),
                const SizedBox(height: 6),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: Duo.heading.copyWith(color: color, fontSize: 17),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
