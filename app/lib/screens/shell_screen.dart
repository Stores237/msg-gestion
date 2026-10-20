import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import 'home_screen.dart';

/// Bottom navigation with only the tabs the server granted (design: "la
/// barre d’onglets change avec le rôle"). Never computed client-side: the
/// role matrix lives in the back-office and the server applies it.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.me});

  final Me me;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static (IconData, IconData, String Function(AppLocalizations)) _def(AppTab t) => switch (t) {
        AppTab.accueil => (Icons.home_outlined, Icons.home, (l) => l.tabHome),
        AppTab.membres => (Icons.people_outline, Icons.people, (l) => l.tabMembers),
        AppTab.finances => (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, (l) => l.tabFinances),
        AppTab.calendrier => (Icons.calendar_today_outlined, Icons.calendar_today, (l) => l.tabCalendar),
        AppTab.annonces => (Icons.campaign_outlined, Icons.campaign, (l) => l.tabAnnouncements),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = widget.me.tabs.isEmpty ? const [AppTab.accueil] : widget.me.tabs;
    final current = tabs[_index.clamp(0, tabs.length - 1)];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: current == AppTab.accueil ? HomeScreen(me: widget.me) : _ComingSoon(title: _def(current).$3(l)),
      ),
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: _index.clamp(0, tabs.length - 1),
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(key: Key('tab-${t.name}'), icon: Icon(_def(t).$1), selectedIcon: Icon(_def(t).$2), label: _def(t).$3(l)),
              ],
            ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
                  child: Icon(Icons.hourglass_empty, size: 28, color: c.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(l.comingSoonTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l.comingSoonBody, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: c.textSecondary)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
