import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../models/announcement.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';
import 'compose_screen.dart';
import 'read_receipts_sheet.dart';

/// Full announcement. Opening it marks it read (best effort: offline
/// just leaves the dot until next time).
class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({super.key, required this.item});
  final Announcement item;

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late Announcement _item = widget.item;

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ComposeScreen(existing: _item)),
    );
    if (saved != true || !mounted) return;
    try {
      final fresh = await RepositoryLocator.instance.announcements.get(
        _item.id,
      );
      if (mounted) setState(() => _item = fresh);
    } catch (_) {
      // The list reloads on return anyway.
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    try {
      await RepositoryLocator.instance.announcements.delete(_item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.announcementDeleted)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.item.unread) {
      RepositoryLocator.instance.announcements
          .markRead(widget.item.id)
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = _item.copyWith(unread: false);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: '', back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  AnnouncementCard(
                    item: a,
                    onReads: a.readCount == null
                        ? null
                        : () => showReadReceipts(context, a),
                  ),
                  OwnerActions(
                    canEdit: a.canEdit,
                    canDelete: a.canDelete,
                    confirmText: l.deleteAnnouncementConfirm(a.title),
                    onEdit: _edit,
                    onDelete: _delete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
