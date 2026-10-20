import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import 'announcements/announcements_screen.dart';
import 'calendar/calendar_screen.dart';
import 'finances/finances_screen.dart';
import 'home_screen.dart';
import 'members/members_screen.dart';

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
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    currentUser.value = widget.me;
  }

  static (IconData, IconData, String Function(AppLocalizations)) _def(
    AppTab t,
  ) => switch (t) {
    AppTab.accueil => (Icons.home_outlined, Icons.home, (l) => l.tabHome),
    AppTab.membres => (Icons.people_outline, Icons.people, (l) => l.tabMembers),
    AppTab.finances => (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      (l) => l.tabFinances,
    ),
    AppTab.calendrier => (
      Icons.calendar_today_outlined,
      Icons.calendar_today,
      (l) => l.tabCalendar,
    ),
    AppTab.annonces => (
      Icons.campaign_outlined,
      Icons.campaign,
      (l) => l.tabAnnouncements,
    ),
  };

  List<AppTab> get _tabs =>
      widget.me.tabs.isEmpty ? const [AppTab.accueil] : widget.me.tabs;

  void _openTab(AppTab t) {
    final i = _tabs.indexOf(t);
    if (i >= 0) setState(() => _index = i);
  }

  Widget _screen(AppTab t) => switch (t) {
    AppTab.accueil => HomeScreen(me: widget.me, onOpenTab: _openTab),
    AppTab.membres => MembersScreen(me: widget.me),
    AppTab.calendrier => CalendarScreen(me: widget.me),
    AppTab.annonces => AnnouncementsScreen(
      me: widget.me,
      onUnreadChanged: (n) => setState(() => _unread = n),
    ),
    AppTab.finances => FinancesScreen(me: widget.me),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = _tabs;
    final index = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: KeyedSubtree(
          key: ValueKey(tabs[index]),
          child: _screen(tabs[index]),
        ),
      ),
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(
                    key: Key('tab-${t.name}'),
                    icon: Badge(
                      isLabelVisible: t == AppTab.annonces && _unread > 0,
                      label: Text('$_unread'),
                      child: Icon(_def(t).$1),
                    ),
                    selectedIcon: Icon(_def(t).$2),
                    label: _def(t).$3(l),
                  ),
              ],
            ),
    );
  }
}
