import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_links.dart';
import '../data/kidney_tips.dart';
import '../theme/duo.dart';
import 'duo_widgets.dart';

/// Partage une image de sa progression (WhatsApp en tête de liste).
Future<void> shareProgress(
  BuildContext context, {
  required String headline,
  required String detail,
  String icon = 'assets/icons/flame.svg',
  String? inviteCode,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _ShareSheet(
        text: shareText(inviteCode: inviteCode),
        fileName: 'bois-et-vis.png',
        card: ShareCard(
          headline: headline,
          detail: detail,
          icon: icon,
          inviteCode: inviteCode,
        ),
      ),
    );

/// Partage une leçon avec son image résumé (WhatsApp en tête de liste).
Future<void> shareLesson(BuildContext context, KidneyTip tip) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _ShareSheet(
        text: lessonShareText(tip),
        fileName: 'lecon-bois-et-vis.png',
        card: LessonShareCard(tip: tip),
      ),
    );

/// Texte envoyé avec l'image résumé d'une leçon.
String lessonShareText(KidneyTip tip) => [
      '📚 Leçon Bois & Vis : ${tip.title}',
      '',
      tip.text,
      if (tip.keyPoints.isNotEmpty) ...[
        '',
        'À retenir :',
        for (final point in tip.keyPoints) '✅ $point',
      ],
      '',
      shareText(),
    ].join('\n');

/// Texte envoyé avec l'image (ou seul, pour une invitation).
String shareText({String? inviteCode, String? challengeCode}) {
  final lines = [
    'Je bois mon eau avec Bois & Vis 💧 et je protège mes reins.',
    if (challengeCode != null)
      'Rejoins mon défi de la semaine avec le code $challengeCode !',
    if (inviteCode != null)
      'Mon code d\'invitation : $inviteCode (+50 XP pour toi et moi).',
    appStoreLink,
  ];
  return lines.join('\n');
}

/// Partage un simple texte (invitation à un défi).
Future<void> shareInvite({String? inviteCode, String? challengeCode}) =>
    SharePlus.instance.share(
      ShareParams(
        text: shareText(inviteCode: inviteCode, challengeCode: challengeCode),
      ),
    );

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.card,
    required this.text,
    required this.fileName,
  });

  /// L'image partagée.
  final Widget card;
  final String text;
  final String fileName;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(
        ShareParams(
          text: widget.text,
          files: [
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: widget.fileName,
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Partage : $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(key: _card, child: widget.card),
            const SizedBox(height: 16),
            DuoButton(
              label: _busy ? 'Un instant…' : 'Partager sur WhatsApp',
              icon: 'share',
              onPressed: _busy ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}

/// L'image partagée : Reno, le chiffre fort et l'invitation.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.headline,
    required this.detail,
    required this.icon,
    this.inviteCode,
  });

  final String headline;
  final String detail;
  final String icon;
  final String? inviteCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Duo.blueLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Duo.blue, width: 3),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/mascot/mascot_cheer.svg', height: 110),
              const SizedBox(width: 8),
              SvgPicture.asset(icon, height: 56),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: Duo.title.copyWith(color: Duo.blueDark, fontSize: 26),
          ),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center, style: Duo.body),
          const SizedBox(height: 14),
          Text(
            inviteCode == null
                ? 'Bois & Vis · bois ton eau, protège tes reins'
                : 'Rejoins-moi sur Bois & Vis · code $inviteCode',
            textAlign: TextAlign.center,
            style: Duo.label.copyWith(color: Duo.green, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Image résumé d'une leçon : illustration, titre et points à retenir.
class LessonShareCard extends StatelessWidget {
  const LessonShareCard({super.key, required this.tip});

  final KidneyTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Duo.blue, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Duo.blue,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const GameIcon('book', size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  'LEÇON BOIS & VIS',
                  style: Duo.label.copyWith(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            color: Duo.blueLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SvgPicture.asset(tip.asset, height: 130),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: Text(
              tip.title,
              textAlign: TextAlign.center,
              style: Duo.title.copyWith(color: Duo.blueDark, fontSize: 22),
            ),
          ),
          if (tip.keyPoints.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              decoration: BoxDecoration(
                color: Duo.greenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'À RETENIR',
                    style: Duo.label.copyWith(
                      color: Duo.greenDark,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final point in tip.keyPoints)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GameIcon('check_badge', size: 22),
                          const SizedBox(width: 8),
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
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/icons/kidney.svg', height: 26),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Bois & Vis · bois ton eau, protège tes reins',
                    style: Duo.label.copyWith(color: Duo.green, fontSize: 12),
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
