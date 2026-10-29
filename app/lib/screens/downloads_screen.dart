import 'package:flutter/material.dart';

import '../data/file_store.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/attachments.dart';
import '../widgets/dates.dart';
import '../widgets/files.dart';
import '../widgets/ui.dart';

/// Mon compte → Téléchargements (owner, 2026-10-29): the photos and PDFs
/// downloaded or opened, readable without network; copy one to the
/// phone's folders, or delete it.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = FileStore.instance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.downloads, back: true, small: true),
            Expanded(
              child: FutureBuilder(
                future: store.load(),
                builder: (context, _) => ListenableBuilder(
                  listenable: store,
                  builder: (context, _) => _list(context, store.downloads),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<DownloadedFile> files) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          l.downloadsHint,
          style: TextStyle(fontSize: 13, height: 1.4, color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          EmptyState(
            key: const Key('downloads-empty'),
            icon: Icons.download_outlined,
            title: l.downloadsEmpty,
            text: l.downloadsEmptyHint,
          )
        else
          GroupCard(
            children: [
              for (final f in files)
                ListRow(
                  key: Key('download-${f.path}'),
                  lead: Icon(
                    f.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: f.isPdf ? c.alert : c.primaryText,
                  ),
                  title: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      fileSize(l, f.size),
                      d.dayMonth(f.savedAt),
                      if (f.onPhone) l.onThePhone,
                    ].join(' · '),
                  ),
                  trailing: PopupMenuButton<String>(
                    key: Key('download-menu-${f.path}'),
                    onSelected: (v) => v == 'delete'
                        ? FileStore.instance.delete(f)
                        : _saveToPhone(context, f),
                    itemBuilder: (_) => [
                      if (!f.onPhone)
                        PopupMenuItem(
                          value: 'phone',
                          child: Text(l.saveToPhone),
                        ),
                      PopupMenuItem(
                        key: const Key('download-delete'),
                        value: 'delete',
                        child: Text(l.deleteFile),
                      ),
                    ],
                  ),
                  onTap: () => showDownloaded(context, f),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _saveToPhone(BuildContext context, DownloadedFile f) async {
    final l = AppLocalizations.of(context);
    final ok = await FileStore.instance.saveToPhone(f);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? l.saveToPhoneFailed
              : f.isImage
              ? l.photoSavedToGallery
              : l.savedToDownloads,
        ),
      ),
    );
  }
}
