import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../hydration_controller.dart';
import '../services/auth_service.dart';
import '../theme/duo.dart';
import '../social_controller.dart';
import '../widgets/reward_feedback.dart';
import 'badges_screen.dart';
import 'friends_screen.dart';
import 'lessons_screen.dart';
import 'path_screen.dart';
import 'profile_screen.dart';

/// Écran principal avec la barre d'onglets du bas.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.controller,
    required this.auth,
    required this.social,
  });

  final HydrationController controller;
  final AuthService auth;
  final SocialController social;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _tabs = [
    ('assets/icons/home.svg', 'Parcours'),
    ('assets/icons/book.svg', 'Leçons'),
    ('assets/icons/friends.svg', 'Amis'),
    ('assets/icons/trophy.svg', 'Succès'),
    ('assets/icons/kidney.svg', 'Profil'),
  ];

  Future<void> _select(int tab) async {
    setState(() => _tab = tab);
    if (_tabs[tab].$2 != 'Amis') return;
    // Les défis bougent pendant qu'on est ailleurs : on les recharge.
    final reward = await widget.social.refresh();
    if (reward != null && mounted) {
      await showReward(
        context,
        reward,
        message: 'Un ami a rejoint Bois & Vis grâce à ton code !',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          PathScreen(controller: c, auth: widget.auth),
          LessonsScreen(controller: c),
          FriendsScreen(social: widget.social, auth: widget.auth),
          BadgesScreen(controller: c),
          ProfileScreen(
            controller: c,
            auth: widget.auth,
            social: widget.social,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Duo.border, width: 2)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == _tab,
                      button: true,
                      label: _tabs[i].$2,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => _select(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                i == _tab ? Duo.blueLight : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: i == _tab ? Duo.blue : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: SvgPicture.asset(
                            _tabs[i].$1,
                            height: 34,
                            key: ValueKey('tab_${_tabs[i].$2}'),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
