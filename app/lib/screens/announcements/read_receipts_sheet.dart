import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/announcement.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';

/// Who has / hasn't read an announcement (design: "Accusés de lecture").
Future<void> showReadReceipts(BuildContext context, Announcement a) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => _Receipts(item: a, scroll: scroll),
    ),
  );
}

class _Receipts extends StatefulWidget {
  const _Receipts({required this.item, required this.scroll});
  final Announcement item;
  final ScrollController scroll;

  @override
  State<_Receipts> createState() => _ReceiptsState();
}

class _ReceiptsState extends State<_Receipts> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AsyncView<List<ReadReceipt>>(
      load: () =>
          RepositoryLocator.instance.announcements.receipts(widget.item.id),
      builder: (context, rows, _) {
        final unread = rows.where((r) => !r.read).toList();
        final read = rows.where((r) => r.read).toList();
        final shown = _tab == 0 ? unread : read;
        return ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l.readBy(read.length, rows.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Seg2(
              options: [l.notReadYet(unread.length), l.readTab(read.length)],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 12),
            if (unread.isNotEmpty) ...[
              FilledButton.tonalIcon(
                key: const Key('remind-unread'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () async {
                  try {
                    final n = await RepositoryLocator.instance.announcements
                        .remindUnread(widget.item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.remindedDone(n))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) showErrorSnack(context, e);
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(l.remindUnread(unread.length)),
              ),
              const SizedBox(height: 12),
            ],
            GroupCard(
              children: [
                for (final r in shown)
                  ListRow(
                    lead: MemberAvatar(name: r.fullName, size: 36),
                    title: Text(r.fullName),
                    subtitle: Text(r.read ? l.readStatus : l.unreadDot),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
