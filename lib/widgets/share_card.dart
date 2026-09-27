import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_links.dart';
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
        headline: headline,
        detail: detail,
        icon: icon,
        inviteCode: inviteCode,
      ),
    );

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
    required this.headline,
    required this.detail,
    required this.icon,
    required this.inviteCode,
  });

  final String headline;
  final String detail;
  final String icon;
  final String? inviteCode;

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
          text: shareText(inviteCode: widget.inviteCode),
          files: [
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'bois-et-vis.png',
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _card,
              child: ShareCard(
                headline: widget.headline,
                detail: widget.detail,
                icon: widget.icon,
                inviteCode: widget.inviteCode,
              ),
            ),
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
