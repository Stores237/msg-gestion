import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../models/announcement.dart';
import '../../widgets/ui.dart';
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
    final a = widget.item.copyWith(unread: false);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
