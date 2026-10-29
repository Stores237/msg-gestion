import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/announcement.dart';
import '../theme/tokens.dart';
import 'files.dart';

String fileSize(AppLocalizations l, int bytes) => bytes < 1024 * 1024
    ? l.sizeKb((bytes / 1024).ceil())
    : l.sizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));

/// Attachment row (design: .file): icon, name, type · size. Tap downloads
/// it (kept in Téléchargements, readable offline) and opens it.
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isPdf,
    this.onTap,
    this.trailing,
  });
  final String name;
  final String subtitle;
  final bool isPdf;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Material(
      color: c.surfaceSunken,
      borderRadius: BorderRadius.circular(MsgRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                  size: 20,
                  color: isPdf ? c.alert : c.primaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AttachmentList extends StatelessWidget {
  const AttachmentList({super.key, required this.items});
  final List<AttachmentInfo> items;

  Future<void> _open(BuildContext context, AttachmentInfo a) => openDocument(
    context,
    source: 'att-${a.id}',
    name: a.name,
    mime: a.contentType,
    link: () async => a.url,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        for (final a in items)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AttachmentTile(
              key: Key('att-file-${a.id}'),
              name: a.name,
              subtitle: '${a.isPdf ? 'PDF' : 'Image'} · ${fileSize(l, a.size)}',
              isPdf: a.isPdf,
              onTap: () => _open(context, a),
            ),
          ),
      ],
    );
  }
}
