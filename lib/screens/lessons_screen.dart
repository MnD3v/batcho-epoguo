import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/kidney_tips.dart';
import '../hydration_controller.dart';
import '../models/game.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/reward_feedback.dart';

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
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Duo.green,
                                size: 30,
                              )
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
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Duo.gray,
                  size: 30,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  SvgPicture.asset(tip.asset, height: 220),
                  const SizedBox(height: 20),
                  Text(
                    tip.title,
                    style: Duo.title,
                    textAlign: TextAlign.center,
                  ),
                  Center(
                    child: SpeakButton(text: '${tip.title}. ${tip.text}'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip.text,
                    style: Duo.body.copyWith(fontSize: 17),
                    textAlign: TextAlign.center,
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
