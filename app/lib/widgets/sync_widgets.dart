import 'package:flutter/material.dart';

import '../data/offline.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'dates.dart';

/// Dark banner on top while offline (design: .netbar), with what waits.
class NetBar extends StatelessWidget {
  const NetBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return ListenableBuilder(
      listenable: OfflineState.instance,
      builder: (context, _) {
        final s = OfflineState.instance;
        if (s.online) return const SizedBox.shrink();
        return Container(
          key: const Key('netbar'),
          width: double.infinity,
          color: c.ink800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.pending > 0 ? l.offlinePending(s.pending) : l.offlineBar,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

/// "Synchronisé · dernière synchronisation 14:32" under a tab title
/// (design: SyncLine): synced, syncing, offline, failed + Réessayer.
class SyncLine extends StatelessWidget {
  const SyncLine({super.key});

  String _when(BuildContext context, DateTime? t) {
    final l = AppLocalizations.of(context);
    if (t == null) return l.never;
    final d = Dates(context);
    final now = DateTime.now();
    return t.year == now.year && t.month == now.month && t.day == now.day
        ? d.time(t)
        : '${d.dayMonth(t)}, ${d.time(t)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return ListenableBuilder(
      listenable: OfflineState.instance,
      builder: (context, _) {
        final s = OfflineState.instance;
        final (icon, color, text) = s.lastError != null
            ? (Icons.warning_amber_rounded, c.alert, l.syncFailed)
            : s.syncing
            ? (Icons.sync, c.textSecondary, l.syncing)
            : !s.online
            ? (
                Icons.cloud_off,
                c.textSecondary,
                l.offlineSince(_when(context, s.lastSync)),
              )
            : (
                Icons.check,
                c.primaryText,
                l.syncedAt(_when(context, s.lastSync)),
              );
        return Row(
          key: const Key('syncline'),
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: s.lastError != null ? c.alert : c.textSecondary,
                ),
              ),
            ),
            if (s.lastError != null || (!s.online && s.pending > 0))
              TextButton(
                key: const Key('sync-retry'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  s.lastError = null;
                  RepositoryLocator.instance.apiClient.flushOutbox();
                },
                child: Text(l.retry, style: const TextStyle(fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}
