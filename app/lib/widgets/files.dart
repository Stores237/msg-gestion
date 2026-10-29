import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/file_store.dart';
import '../l10n/app_localizations.dart';
import 'dates.dart';
import 'errors.dart';

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
/// Téléchargements, copied to the phone's Download/MSG and opened. Without
/// network, the copy kept last time opens instead.
Future<void> openDocument(
  BuildContext context, {
  required String source,
  required String name,
  required Future<String> Function() link,
  String mime = 'application/pdf',
}) async {
  final l = AppLocalizations.of(context);
  final store = FileStore.instance;
  DownloadedFile file;
  String? note;
  try {
    file = await store.keep(
      source: source,
      name: name,
      mime: mime,
      url: await link(),
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
/// phone's Pictures/MSG (its gallery).
Future<void> downloadPhoto(BuildContext context, String url) async {
  final l = AppLocalizations.of(context);
  try {
    final name = Uri.parse(url).pathSegments.lastOrNull ?? 'photo.jpg';
    final file = await FileStore.instance.keep(
      source: 'photo-${FileStore.keyFor(url)}',
      name: 'MSG-$name',
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
