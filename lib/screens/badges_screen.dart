import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../hydration_controller.dart';
import '../models/game.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';

/// Niveau et badges gagnés.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final level = controller.level;
        final next = nextLevel(level);
        final xp = controller.xp;
        final unlocked = controller.stats.badges;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              const Text('Succès', style: Duo.title),
              const SizedBox(height: 16),
              DuoCard(
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/crown.svg', width: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Niveau ${level.number} · ${level.name}',
                            style: Duo.heading,
                          ),
                          const SizedBox(height: 8),
                          DuoProgressBar(
                            value: next == null
                                ? 1
                                : (xp - level.minXp) /
                                    (next.minXp - level.minXp),
                            color: Duo.gold,
                            height: 14,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            next == null
                                ? '$xp XP · niveau maximum !'
                                : '$xp / ${next.minXp} XP · prochain : '
                                    '${next.name}',
                            style: Duo.body.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'BADGES · ${unlocked.length}/${Achievement.values.length}',
                style: Duo.label,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
                children: [
                  for (final badge in Achievement.values)
                    _BadgeTile(
                      badge: badge,
                      unlocked: unlocked.contains(badge),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlocked});

  final Achievement badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? badge.color : Duo.border;
    return Tooltip(
      message: badge.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(color, Colors.black, 0.15)!,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: unlocked ? Colors.white : Duo.snow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? SvgPicture.asset(badge.icon, width: 36, height: 36)
                  : SvgPicture.asset(
                      'assets/icons/lock.svg',
                      width: 28,
                      height: 28,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: Duo.heading.copyWith(
              fontSize: 14,
              color: unlocked ? Duo.text : Duo.gray,
            ),
          ),
        ],
      ),
    );
  }
}
