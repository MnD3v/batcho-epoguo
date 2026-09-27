import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/game.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/reward_feedback.dart';
import '../widgets/share_card.dart';

/// Les leçons illustrées sur les reins.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key, required this.controller});

  final HydrationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final read = controller.stats.readTips.length;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              const Text('Leçons sur tes reins', style: Duo.title),
              const SizedBox(height: 6),
              Text(
                '$read/${kidneyTips.length} lues · +$xpPerTip XP par leçon',
                style: Duo.body,
              ),
              const SizedBox(height: 10),
              DuoProgressBar(
                value: read / kidneyTips.length,
                color: Duo.blue,
                height: 12,
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < kidneyTips.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DuoCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TipScreen(controller: controller, index: i),
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          kidneyTips[i].asset,
                          width: 84,
                          height: 70,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            kidneyTips[i].title,
                            style: Duo.heading.copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        controller.isTipRead(i)
                            ? const GameIcon('check_badge', size: 30)
                            : Text(
                                '+$xpPerTip XP',
                                style: Duo.label.copyWith(color: Duo.blue),
                              ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TipScreen extends StatelessWidget {
  const TipScreen({super.key, required this.controller, required this.index});

  final HydrationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tip = kidneyTips[index];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Duo.gray,
                    size: 30,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Partager la leçon',
                  onPressed: () => shareLesson(context, tip),
                  icon: const GameIcon('share', size: 30),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  SvgPicture.asset(tip.asset, height: 200),
                  const SizedBox(height: 16),
                  Text(
                    tip.title,
                    style: Duo.title,
                    textAlign: TextAlign.center,
                  ),
                  Center(child: SpeakButton(text: tip.fullText)),
                  Text(
                    tip.text,
                    style: Duo.body.copyWith(fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  for (final (i, section) in tip.sections.indexed) ...[
                    _SectionCard(number: i + 1, section: section),
                    const SizedBox(height: 12),
                  ],
                  if (tip.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _KeyPoints(points: tip.keyPoints),
                  ],
                  const SizedBox(height: 16),
                  DuoButton.outline(
                    label: 'Partager cette leçon',
                    icon: 'share',
                    onPressed: () => shareLesson(context, tip),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    healthDisclaimer,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Duo.gray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Duo.border, width: 2)),
              ),
              padding: const EdgeInsets.all(20),
              child: DuoButton(
                label: 'J\'ai compris',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final reward = await controller.markTipRead(index);
                  if (context.mounted) await showReward(context, reward);
                  navigator.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une partie de la leçon, numérotée comme une étape.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.section});

  final int number;
  final TipSection section;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Duo.blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: Duo.font,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.heading, style: Duo.heading),
                const SizedBox(height: 4),
                Text(
                  section.text,
                  style: Duo.body.copyWith(fontSize: 15, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « À retenir » : les points clés de la leçon.
class _KeyPoints extends StatelessWidget {
  const _KeyPoints({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Duo.greenLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Duo.green, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À RETENIR',
            style: Duo.label.copyWith(color: Duo.greenDark),
          ),
          const SizedBox(height: 8),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GameIcon('check_badge', size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: Duo.heading.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
