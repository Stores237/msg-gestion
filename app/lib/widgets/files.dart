import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/file_store.dart';
import '../data/repositories/finances_repository.dart';
import '../l10n/app_localizations.dart';
import 'dates.dart';
import 'errors.dart';
import '../theme/tokens.dart';

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

bool _offline(Object e) => e is NetworkException || e is FileUnavailable;

/// Today as 2026-10-29, for file names.
String fileDate() => DateTime.now().toIso8601String().substring(0, 10);

String mimeFor(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.pdf')) return 'application/pdf';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// A PDF (report, statement, cash book, attachment): downloaded, kept in
/// Téléchargements, copied to the phone's Download/Huddle and opened.
/// Without network, the copy kept last time opens instead.
///
/// With [about], the member is first told what the document is and says
/// yes before the download starts (owner, 2026-11-02: "user don't know what
/// they are downloading"). With [periodLink] instead of [link], that window
/// also offers a period (owner, 2026-11-03).
Future<void> openDocument(
  BuildContext context, {
  required String source,
  required String name,
  Future<String> Function()? link,
  Future<String> Function(ExportPeriod? period)? periodLink,
  String mime = 'application/pdf',
  String? about,
}) async {
  assert(link != null || periodLink != null);
  final l = AppLocalizations.of(context);
  ExportPeriod? period;
  if (about != null) {
    final choice = await confirmDownload(
      context,
      name: name,
      about: about,
      withPeriod: periodLink != null,
    );
    if (choice == null) return;
    period = choice.period;
  }
  if (!context.mounted) return;
  if (period != null) {
    // Its own file and offline copy: another period is another document.
    source = '$source-${period.slug}';
    name = name.endsWith('.pdf')
        ? '${name.substring(0, name.length - 4)} (${period.slug}).pdf'
        : '$name (${period.slug})';
  }
  final fetch = periodLink != null ? () => periodLink(period) : link!;
  final store = FileStore.instance;
  DownloadedFile file;
  String? note;
  try {
    file = await store.keep(
      source: source,
      name: name,
      mime: mime,
      url: await fetch(),
    );
    note = await store.saveToPhone(file) ? l.savedToDownloads : null;
  } catch (e) {
    final kept = _offline(e) ? store.bySource(source) : null;
    if (kept == null) {
      if (context.mounted) showErrorSnack(context, e);
      return;
    }
    file = kept;
    if (context.mounted) {
      note = l.offlineCopyOf(Dates(context).dayMonth(kept.savedAt));
    }
  }
  if (!context.mounted) return;
  await showDownloaded(context, file, note: note);
}

/// The member's answer in the download window.
class DownloadChoice {
  const DownloadChoice([this.period]);

  /// null = everything.
  final ExportPeriod? period;
}

/// "Télécharger ce document ?": its name, what it holds, where it goes, and
/// with [withPeriod] the period it covers. null = Annuler.
Future<DownloadChoice?> confirmDownload(
  BuildContext context, {
  required String name,
  required String about,
  bool withPeriod = false,
}) {
  return showDialog<DownloadChoice>(
    context: context,
    builder: (context) =>
        _DownloadAsk(name: name, about: about, withPeriod: withPeriod),
  );
}

enum _Span { all, thisMonth, lastMonth, thisYear, custom }

class _DownloadAsk extends StatefulWidget {
  const _DownloadAsk({
    required this.name,
    required this.about,
    required this.withPeriod,
  });
  final String name;
  final String about;
  final bool withPeriod;

  @override
  State<_DownloadAsk> createState() => _DownloadAskState();
}

class _DownloadAskState extends State<_DownloadAsk> {
  _Span _span = _Span.all;
  DateTimeRange? _custom;

  ExportPeriod? get _period {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(now.year, now.month);
    return switch (_span) {
      _Span.all => null,
      _Span.thisMonth => ExportPeriod(from: first, to: today),
      _Span.lastMonth => ExportPeriod(
        from: DateTime(now.year, now.month - 1),
        to: first.subtract(const Duration(days: 1)),
      ),
      _Span.thisYear => ExportPeriod(from: DateTime(now.year), to: today),
      _Span.custom =>
        _custom == null
            ? null
            : ExportPeriod(from: _custom!.start, to: _custom!.end),
    };
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _custom,
    );
    if (r != null && mounted) {
      setState(() {
        _custom = r;
        _span = _Span.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final p = _period;
    Widget chip(_Span s, String label, Key key) => ChoiceChip(
      key: key,
      label: Text(label),
      selected: _span == s,
      onSelected: (_) =>
          s == _Span.custom ? _pickRange() : setState(() => _span = s),
    );
    return AlertDialog(
      key: const Key('download-ask'),
      icon: const Icon(Icons.picture_as_pdf_outlined),
      title: Text(l.downloadAskTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(widget.about),
            if (widget.withPeriod) ...[
              const SizedBox(height: 16),
              Text(
                l.periodLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip(_Span.all, l.periodAll, const Key('period-all')),
                  chip(
                    _Span.thisMonth,
                    l.periodThisMonth,
                    const Key('period-month'),
                  ),
                  chip(
                    _Span.lastMonth,
                    l.periodLastMonth,
                    const Key('period-last-month'),
                  ),
                  chip(
                    _Span.thisYear,
                    l.periodThisYear,
                    const Key('period-year'),
                  ),
                  chip(
                    _Span.custom,
                    l.periodCustom,
                    const Key('period-custom'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p == null
                    ? l.periodWhole
                    : l.periodRange(d.fullDate(p.from!), d.fullDate(p.to!)),
                key: const Key('period-text'),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l.downloadAskWhere,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('confirm-download'),
          onPressed: () => Navigator.of(context).pop(DownloadChoice(p)),
          child: Text(l.download),
        ),
      ],
    );
  }
}

/// Opens a kept file: photos in the app, PDFs in the phone's viewer.
Future<void> showDownloaded(
  BuildContext context,
  DownloadedFile file, {
  String? note,
}) async {
  final l = AppLocalizations.of(context);
  if (file.isImage) {
    final bytes = await FileStore.instance.read(file);
    if (!context.mounted) return;
    if (bytes == null) return _snack(context, l.openFileFailed);
    if (note != null) _snack(context, note);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KeptPhotoScreen(name: file.name, bytes: bytes),
      ),
    );
    return;
  }
  final opened = await FileStore.instance.openFile(file);
  if (!context.mounted) return;
  if (!opened) {
    _snack(context, l.noPdfViewer);
  } else if (note != null) {
    _snack(context, note);
  }
}

/// "Télécharger" on a photo: kept in Téléchargements and copied to the
/// phone's Pictures/Huddle (its gallery).
Future<void> downloadPhoto(BuildContext context, String url) async {
  final l = AppLocalizations.of(context);
  try {
    final name = Uri.parse(url).pathSegments.lastOrNull ?? 'photo.jpg';
    final file = await FileStore.instance.keep(
      source: 'photo-${FileStore.keyFor(url)}',
      name: 'Huddle-$name',
      mime: mimeFor(name),
      url: url,
    );
    final onPhone = await FileStore.instance.saveToPhone(file);
    if (context.mounted) {
      _snack(context, onPhone ? l.photoSavedToGallery : l.keptInDownloads);
    }
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}

/// A downloaded photo, full screen, from the phone.
class KeptPhotoScreen extends StatelessWidget {
  const KeptPhotoScreen({super.key, required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(name, style: const TextStyle(fontSize: 15)),
    ),
    body: InteractiveViewer(
      maxScale: 5,
      child: Center(child: Image.memory(bytes, key: const Key('kept-photo'))),
    ),
  );
}
