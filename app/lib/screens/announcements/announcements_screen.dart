import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/announcement.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/errors.dart';
import '../../widgets/ui.dart';
import 'announcement_detail_screen.dart';
import 'compose_screen.dart';
import 'read_receipts_sheet.dart';

/// Announcements tab (design: "Annonces · fil"): pinned first, green dot
/// for unread; the sender sees how many have read it.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({
    super.key,
    required this.me,
    this.onUnreadChanged,
  });
  final Me me;
  final ValueChanged<int>? onUnreadChanged;

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  static const _filters = ['all', 'convocations', 'unread', 'sent'];
  int _filter = 0;
  AnnouncementFeed? _feed;
  Object? _error;

  bool get _canWrite => widget.me.can('announcements.posts', 'create');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feed = await RepositoryLocator.instance.announcements.feed(
        filter: _filters[_filter],
      );
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _error = null;
      });
      widget.onUnreadChanged?.call(feed.unread);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _open(Announcement a) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AnnouncementDetailScreen(item: a)),
    );
    _load();
  }

  Future<void> _compose() async {
    final sent = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ComposeScreen()));
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final feed = _feed;
    final labels = [
      l.filterAnnAll,
      l.filterConvocations,
      l.filterUnread(feed?.unread ?? 0),
      if (_canWrite) l.filterSent,
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _canWrite
          ? FloatingActionButton.extended(
              key: const Key('compose'),
              onPressed: _compose,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.compose),
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          ScreenHeader(title: l.tabAnnouncements, sync: true),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  FilterChips(
                    labels: labels,
                    selected: _filter,
                    onSelected: (i) {
                      setState(() => _filter = i);
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_error != null && feed == null)
                    EmptyState(
                      icon: Icons.cloud_off_outlined,
                      error: true,
                      title: l.loadError,
                      text: describeError(context, _error!),
                      action: FilledButton(
                        onPressed: _load,
                        child: Text(l.retry),
                      ),
                    )
                  else if (feed == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (feed.items.isEmpty)
                    _filters[_filter] == 'unread'
                        ? EmptyState(
                            icon: Icons.inbox_outlined,
                            title: l.allRead,
                            text: l.allReadBody,
                          )
                        : EmptyState(
                            icon: Icons.campaign_outlined,
                            title: l.noAnnouncements,
                            text: l.allReadBody,
                          )
                  else
                    for (final a in feed.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnnouncementCard(
                          key: Key('ann-${a.id}'),
                          item: a,
                          onTap: () => _open(a),
                          onReads: a.readCount == null
                              ? null
                              : () => showReadReceipts(context, a),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
