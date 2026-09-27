import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/drink.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import 'onboarding_screen.dart';

/// Statistiques et réglages de la boisson.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stats = controller.stats;
        final settings = controller.settings!;
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
                        const Text('Mon profil', style: Duo.title),
                        Text(
                          'Niveau ${controller.level.number} · '
                          '${controller.level.name}',
                          style: Duo.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                '${controller.bestStreak > 1 ? 's' : ''}',
                style: Duo.body.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text('MA BOISSON', style: Duo.label),
              const SizedBox(height: 10),
              DuoCard(
                child: Row(
                  children: [
                    SvgPicture.asset(settings.type.asset, width: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(settings.doseLabel, style: Duo.heading),
                          Text(
                            'à chaque rappel · objectif '
                            '${formatLiters(controller.goalMl)}',
                            style: Duo.body.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DuoButton(
                label: 'Modifier ma boisson',
                color: Duo.blue,
                shadow: Duo.blueDark,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OnboardingScreen(
                      controller: controller,
                      isFirstRun: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DuoButton.outline(
                label: 'Tester un rappel',
                icon: Icons.notifications_active_rounded,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.scheduler.requestPermission();
                  await controller.scheduler.showTest(settings);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Notification d\'essai envoyée'),
                    ),
                  );
                },
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
