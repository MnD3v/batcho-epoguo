import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../services/auth_service.dart';
import '../social_controller.dart';
import '../widgets/account_prompt.dart';
import '../widgets/share_card.dart';
import '../models/plan.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/evolution_chart.dart';
import 'settings_screen.dart';

/// Statistiques et réglages des alertes.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.auth,
    required this.social,
  });

  final HydrationController controller;
  final AuthService auth;
  final SocialController social;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stats = controller.stats;
        final profile = controller.profile;
        final plan = controller.plan!;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/mascot/mascot_happy.svg',
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.firstName ?? 'Mon profil',
                          style: Duo.title,
                        ),
                        if (profile != null && profile.email.isNotEmpty)
                          Text(
                            profile.email,
                            style: Duo.body.copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          'Niveau ${controller.level.number} · '
                          '${controller.level.name}',
                          style: Duo.body.copyWith(color: Duo.goldDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Paramètres',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SettingsScreen(controller: controller, auth: auth),
                      ),
                    ),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Duo.gray,
                      size: 30,
                    ),
                  ),
                ],
              ),
              if (controller.uid == null) ...[
                const SizedBox(height: 16),
                AccountCta(auth: auth, controller: controller),
              ],
              const SizedBox(height: 20),
              const Text('STATISTIQUES', style: Duo.label),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _Stat(
                    icon: 'assets/icons/flame.svg',
                    value: '${controller.streak}',
                    label: 'Jours de flamme',
                  ),
                  _Stat(
                    icon: 'assets/icons/xp.svg',
                    value: '${controller.xp}',
                    label: 'XP au total',
                  ),
                  _Stat(
                    icon: 'assets/icons/drop.svg',
                    value: formatLiters(stats.totalMl),
                    label: 'Bus au total',
                  ),
                  _Stat(
                    icon: 'assets/icons/star.svg',
                    value: '${stats.perfectDays}',
                    label: 'Journées parfaites',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Meilleure série : ${controller.bestStreak} jour'
                '${controller.bestStreak > 1 ? 's' : ''} · Jours de repos : '
                '${controller.freezes}/2 (1 gagné tous les 7 jours)',
                style: Duo.body.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 14),
              DuoButton(
                label: 'Partager ma progression',
                icon: Icons.share_rounded,
                onPressed: () => shareProgress(
                  context,
                  headline: controller.streak > 0
                      ? '${controller.streak} jour'
                          '${controller.streak > 1 ? 's' : ''} de flamme !'
                      : '${formatLiters(stats.totalMl)} d\'eau bus !',
                  detail: 'Niveau ${controller.level.number} · '
                      '${controller.level.name} · ${controller.xp} XP',
                  inviteCode: social.referralCode,
                ),
              ),
              const SizedBox(height: 24),
              EvolutionSection(controller: controller),
              const SizedBox(height: 24),
              const Text('MES ALERTES', style: Duo.label),
              const SizedBox(height: 10),
              DuoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.rhythm.label} · ${formatLiters(plan.goalMl)} '
                      'par jour',
                      style: Duo.heading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in plan.reminders)
                          Text(
                            '${r.time}  ${formatLiters(r.ml)}',
                            style: Duo.body.copyWith(
                              fontSize: 14,
                              color: Duo.blueDark,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                healthDisclaimer,
                style: TextStyle(fontSize: 12, color: Duo.gray, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 30, height: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Duo.heading.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Duo.body.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
