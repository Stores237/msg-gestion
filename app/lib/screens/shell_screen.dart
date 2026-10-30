import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import '../data/current_user.dart';
import '../data/offline.dart';
import '../data/repository_locator.dart';
import '../data/theme_controller.dart';
import '../widgets/sync_widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import 'announcements/announcements_screen.dart';
import 'calendar/calendar_screen.dart';
import 'finances/finances_screen.dart';
import 'home_screen.dart';
import 'lock_screen.dart';
import 'members/members_screen.dart';
import 'sign_out.dart';

/// Bottom navigation with only the tabs the server granted (design: "la
/// barre d’onglets change avec le rôle"). Never computed client-side: the
/// role matrix lives in the back-office and the server applies it.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.me});

  final Me me;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  Timer? _flushTimer;
  int _index = 0;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    currentUser.value = widget.me;
    // After this frame: the whole app rebuilds in the group's colour.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ThemeController.instance.setGroupColor(
        ThemeController.parse(widget.me.group?.color),
        ThemeController.parse(widget.me.group?.color2),
      ),
    );
    WidgetsBinding.instance.addObserver(this);
    RepositoryLocator.instance.authSession.addListener(_onAuth);
    // While saves wait for the network, try again every 30 s.
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (OfflineState.instance.pending > 0) {
        RepositoryLocator.instance.apiClient.flushOutbox();
      }
    });
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    RepositoryLocator.instance.authSession.removeListener(_onAuth);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _left = false;

  /// The account was opened on another phone (one phone at a time): this
  /// one leaves at once, whatever screen is open, and says why.
  void _onAuth() {
    final session = RepositoryLocator.instance.authSession;
    if (_left || session.isLoggedIn || session.endedBy != 'other_device') {
      return;
    }
    _left = true;
    leaveSession(
      Navigator.of(context, rootNavigator: true),
      notice: AppLocalizations.of(context).signedOutOtherDevice,
    );
  }

  DateTime? _hiddenAt;
  bool _locking = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _hiddenAt ??= DateTime.now();
    if (state != AppLifecycleState.resumed) return;
    final hidden = _hiddenAt;
    _hiddenAt = null;
    // Back after a while in the background: the PIN again (LockScreen).
    if (hidden != null &&
        DateTime.now().difference(hidden) >= LockScreen.lockAfter &&
        RepositoryLocator.instance.authSession.isLoggedIn &&
        !_locking) {
      _locking = true;
      LockScreen.show(
        Navigator.of(context, rootNavigator: true),
      ).whenComplete(() => _locking = false);
    }
    if (OfflineState.instance.pending > 0) {
      RepositoryLocator.instance.apiClient.flushOutbox();
    }
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

  /// Each tab gets width / count. Under ~72 dp a slot can't hold
  /// "Calendrier" enlarged: labels go to 11 sp with no enlargement there.
  static Widget _narrowBar(BuildContext context, int count, Widget bar) {
    final slot = MediaQuery.sizeOf(context).width / count;
    if (slot >= 72) {
      return MediaQuery.withClampedTextScaling(maxScaleFactor: 1.1, child: bar);
    }
    final theme = Theme.of(context).navigationBarTheme;
    return MediaQuery.withNoTextScaling(
      child: NavigationBarTheme(
        data: theme.copyWith(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => theme.labelTextStyle?.resolve(s)?.copyWith(fontSize: 11),
          ),
        ),
        child: bar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = _tabs;
    final index = _index.clamp(0, tabs.length - 1);
    // Accueil's dark band reaches up under the status bar (light icons).
    final home = tabs[index] == AppTab.accueil;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: home || dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            Container(
              color: home ? context.msg.header : null,
              child: const SafeArea(bottom: false, child: NetBar()),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: KeyedSubtree(
                  key: ValueKey(tabs[index]),
                  child: _screen(tabs[index]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: tabs.length < 2
          ? null
          // Up to five tabs share the width: the bar keeps its labels on
          // one line even when the phone's text is set large (the screens
          // above still follow the phone's setting).
          : _narrowBar(
              context,
              tabs.length,
              NavigationBar(
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
            ),
    );
  }
}
