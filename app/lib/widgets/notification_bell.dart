import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../screens/notifications_screen.dart';
import '../theme/tokens.dart';

/// Bell with a red dot when something is unread (design: IconBtn bell + dot).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final (n, _) = await RepositoryLocator.instance.notifications.list();
      if (mounted) setState(() => _unread = n);
    } catch (_) {
      // The dot is a hint; no network just means no dot.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return IconButton(
      key: const Key('bell'),
      tooltip: l.notifications,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        _refresh();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (_unread > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                key: const Key('bell-dot'),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.alert,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surfaceBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
