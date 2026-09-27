import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/game.dart';
import '../models/plan.dart';
import '../services/social_repository.dart';
import '../services/auth_service.dart';
import '../social_controller.dart';
import '../widgets/account_prompt.dart';
import '../theme/duo.dart';
import '../widgets/duo_widgets.dart';
import '../widgets/reward_feedback.dart';
import '../widgets/share_card.dart';

/// Défis de la semaine entre amis et parrainage.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.social, required this.auth});

  final SocialController social;
  final AuthService auth;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  SocialController get _s => widget.social;

  Future<void> _refresh() async {
    final reward = await _s.refresh();
    if (reward != null && mounted) {
      await showReward(
        context,
        reward,
        message: 'Un ami a rejoint Bois & Vis grâce à ton code !',
      );
    }
  }

  Future<void> _askCode({
    required String title,
    required String label,
    required String action,
    required Future<Object?> Function(String) run,
    bool code = true,
  }) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _InputSheet(
        title: title,
        label: label,
        action: action,
        code: code,
        run: run,
      ),
    );
    if (result is Reward && mounted) await showReward(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final week = _s.hydration.weekKey;
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                const Text('Amis', style: Duo.title),
                const SizedBox(height: 12),
                const MascotSays(
                  pose: 'mascot_cheer',
                  size: 90,
                  text: 'Défie tes amis : qui boit le plus cette semaine ?',
                ),
                if (!_s.signedIn) ...[
                  const SizedBox(height: 16),
                  AccountCta(
                    auth: widget.auth,
                    controller: _s.hydration,
                    text: 'Crée ton compte pour défier tes amis et gagner '
                        '+$referralBonusXp XP avec ton code d\'invitation.',
                  ),
                ] else
                  ..._friendsContent(week),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _friendsContent(String week) => [
        if (_s.error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(
            _s.error!,
            icon: _s.offline ? 'offline' : 'warning',
          ),
        ],
        const SizedBox(height: 16),
        for (final challenge in _s.challenges) ...[
          _ChallengeCard(
            challenge: challenge,
            week: week,
            myUid: _s.me.uid,
            onInvite: () => shareInvite(
              challengeCode: challenge.code,
              inviteCode: _s.referralCode,
            ),
            onLeave: () => _s.leave(challenge.code),
          ),
          const SizedBox(height: 12),
        ],
        if (_s.challenges.isEmpty && !_s.loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Aucun défi pour l\'instant. Crée le tien ou rejoins '
              'celui d\'un ami !',
              style: Duo.body.copyWith(fontSize: 15),
            ),
          ),
        DuoButton(
          label: 'Créer un défi',
          color: Duo.blue,
          shadow: Duo.blueDark,
          onPressed: () => _askCode(
            title: 'Nouveau défi',
            label: 'Nom du défi (ex. Famille)',
            action: 'Créer',
            code: false,
            run: _s.create,
          ),
        ),
        const SizedBox(height: 10),
        DuoButton.outline(
          label: 'Rejoindre avec un code',
          onPressed: () => _askCode(
            title: 'Rejoindre un défi',
            label: 'Code du défi',
            action: 'Rejoindre',
            run: _s.join,
          ),
        ),
        const SizedBox(height: 28),
        const Text('INVITER DES AMIS', style: Duo.label),
        const SizedBox(height: 10),
        _ReferralCard(
          code: _s.referralCode,
          onShare: () => shareInvite(inviteCode: _s.referralCode),
        ),
        if (!_s.alreadyReferred) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _askCode(
                title: 'Un ami t\'a invité ?',
                label: 'Son code d\'invitation',
                action: 'Valider (+$referralBonusXp XP)',
                run: _s.redeem,
              ),
              child: Text(
                'J\'AI UN CODE D\'INVITATION',
                style: Duo.label.copyWith(color: Duo.blue),
              ),
            ),
          ),
        ],
      ];
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.week,
    required this.myUid,
    required this.onInvite,
    required this.onLeave,
  });

  final Challenge challenge;
  final String week;
  final String myUid;
  final VoidCallback onInvite;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final ranking = challenge.ranking(week);
    return DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/trophy.svg', width: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(challenge.name, style: Duo.heading),
              ),
              PopupMenuButton<String>(
                tooltip: 'Options du défi',
                icon: const Icon(Icons.more_vert_rounded, color: Duo.gray),
                onSelected: (_) => onLeave(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'leave', child: Text('Quitter le défi')),
                ],
              ),
            ],
          ),
          Text(
            'Code ${challenge.code} · cette semaine',
            style: Duo.body.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < ranking.length; i++)
            _RankRow(
              rank: i + 1,
              member: ranking[i],
              isMe: ranking[i].uid == myUid,
            ),
          const SizedBox(height: 10),
          DuoButton.outline(
            label: 'Inviter sur WhatsApp',
            icon: 'add_friend',
            onPressed: onInvite,
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.member,
    required this.isMe,
  });

  final int rank;
  final ChallengeMember member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => Duo.gold,
      2 => Duo.gray,
      3 => Duo.orange,
      _ => Duo.border,
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Duo.blueLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: medal,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontFamily: Duo.font,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? '${member.name} (toi)' : member.name,
              style: Duo.heading.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatLiters(member.ml),
            style: Duo.heading.copyWith(fontSize: 15, color: Duo.blueDark),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.code, required this.onShare});

  final String? code;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: Duo.greenLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '+$referralBonusXp XP pour toi et pour chaque ami qui s\'inscrit '
            'avec ton code',
            style: Duo.heading.copyWith(fontSize: 15, color: Duo.greenDark),
          ),
          const SizedBox(height: 10),
          Center(
            child: SelectableText(
              code ?? '······',
              style: Duo.title.copyWith(
                letterSpacing: 6,
                color: Duo.greenDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          DuoButton(
            label: 'Partager mon code',
            icon: 'share',
            onPressed: code == null ? null : onShare,
          ),
        ],
      ),
    );
  }
}

/// Petite fenêtre : un champ et un bouton (code ou nom de défi).
class _InputSheet extends StatefulWidget {
  const _InputSheet({
    required this.title,
    required this.label,
    required this.action,
    required this.code,
    required this.run,
  });

  final String title;
  final String label;
  final String action;
  final bool code;
  final Future<Object?> Function(String) run;

  @override
  State<_InputSheet> createState() => _InputSheetState();
}

class _InputSheetState extends State<_InputSheet> {
  final _text = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => !widget.code || normalizeCode(_text.text).length == 6;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.run(_text.text);
      if (mounted) Navigator.of(context).pop(result);
    } on SocialException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Pas de connexion. Réessaie.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Duo.heading),
          const SizedBox(height: 16),
          DuoTextField(
            controller: _text,
            label: widget.label,
            capitalization: widget.code
                ? TextCapitalization.characters
                : TextCapitalization.sentences,
            action: TextInputAction.done,
            onChanged: () => setState(() => _error = null),
            onSubmitted: _valid ? _submit : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 16),
          DuoButton(
            label: widget.action,
            onPressed: _valid && !_busy ? _submit : null,
          ),
        ],
      ),
    );
  }
}
