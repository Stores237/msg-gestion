import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/group_controller.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/announcement.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/attachments.dart';
import '../../widgets/photo_frame.dart';
import '../../widgets/ui.dart';

/// A file chosen in the composer, uploaded after the announcement exists.
class PickedFile {
  PickedFile(this.name, this.bytes);
  final String name;
  final List<int> bytes;
}

/// "Rédiger une annonce": announcement or convocation (linked to an
/// upcoming event), optionally pinned. Goes to every member. With
/// [existing], "Modifier l’annonce" (its author, or whoever manages posts).
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, this.existing});
  final Announcement? existing;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _kind = 0; // 0 annonce, 1 convocation
  CalendarEvent? _event;
  bool _pinned = false;
  bool _busy = false;
  bool _eventMissing = false;
  final List<PickedFile> _files = [];

  /// Photos framed 4:3, ≤ 2 MB (owner, 2026-10-28), sent after the files.
  final List<FramedPhoto> _photos = [];

  Future<void> _addPhoto() async {
    final l = AppLocalizations.of(context);
    if (_photos.length >= photosPerAnnouncement) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.photosLimit)));
      return;
    }
    final p = await addFramedPhoto(context);
    if (p != null && mounted) setState(() => _photos.add(p));
  }

  bool get _editing => widget.existing != null;

  // "Brouillon" (design: new announcement → Brouillon): kept on this phone,
  // one per group, until it is sent.
  String get _draftKey =>
      'announcement_draft_g${GroupController.instance.id ?? 0}';

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString('$_draftKey.title') ?? '';
      final b = prefs.getString('$_draftKey.body') ?? '';
      if ((t.isEmpty && b.isEmpty) || !mounted) return;
      setState(() {
        _title.text = t;
        _body.text = b;
        _kind = prefs.getInt('$_draftKey.kind') ?? 0;
      });
      final l = AppLocalizations.of(context);
      // Replaces "Brouillon enregistré" if it is still showing.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.draftRestored)));
    } catch (_) {
      // No local storage: start empty.
    }
  }

  Future<void> _saveDraft() async {
    final l = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_draftKey.title', _title.text);
      await prefs.setString('$_draftKey.body', _body.text);
      await prefs.setInt('$_draftKey.kind', _kind);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.draftSaved)));
    Navigator.of(context).pop(false);
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in ['title', 'body', 'kind']) {
        await prefs.remove('$_draftKey.$k');
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    if (a == null) {
      _restoreDraft();
      return;
    }
    _title.text = a.title;
    _body.text = a.body;
    _kind = a.isConvocation ? 1 : 0;
    _pinned = a.pinned;
    if (a.eventId != null) {
      // Enough of the linked event to show and keep it.
      _event = CalendarEvent(
        id: a.eventId!,
        kind: '',
        title: a.eventTitle ?? '',
        startsAt: a.eventStartsAt ?? a.createdAt,
        place: '',
        dress: '',
        notes: '',
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickEvent() async {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final List<CalendarEvent> events;
    try {
      events = await RepositoryLocator.instance.events.list(
        from: now,
        to: now.add(const Duration(days: 120)),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      return;
    }
    if (!mounted) return;
    final d = Dates(context);
    final picked = await showModalBottomSheet<CalendarEvent>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shrinkWrap: true,
        children: [
          Text(l.chooseEvent, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (events.isEmpty) Text(l.noEventsUpcoming),
          for (final e in events)
            ListRow(
              key: Key('pick-${e.id}'),
              title: Text(e.title),
              subtitle: Text(d.fullDateTime(e.startsAt)),
              onTap: () => Navigator.of(context).pop(e),
            ),
        ],
      ),
    );
    if (picked != null) {
      setState(() {
        _event = picked;
        _eventMissing = false;
      });
    }
  }

  static const _maxBytes = 10 * 1024 * 1024;

  Future<void> _pickFile() async {
    final l = AppLocalizations.of(context);
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        // Pictures go through "Ajouter une photo" and its frame.
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      return;
    }
    for (final p in picked) {
      if ((await p.length() ?? 0) > _maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.fileTooLarge)));
        }
        continue;
      }
      final bytes = await p.readAsBytes();
      if (mounted) setState(() => _files.add(PickedFile(p.name, bytes)));
    }
  }

  Future<void> _send() async {
    final formOk = _form.currentState!.validate();
    setState(() => _eventMissing = _kind == 1 && _event == null);
    if (!formOk || _eventMissing) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      final repo = RepositoryLocator.instance.announcements;
      final kind = _kind == 1 ? 'convocation' : 'annonce';
      final eventId = _kind == 1 ? _event?.id : null;
      final created = _editing
          ? await repo.update(
              widget.existing!.id,
              kind: kind,
              title: _title.text.trim(),
              body: _body.text.trim(),
              eventId: eventId,
            )
          : await repo.create(
              kind: kind,
              title: _title.text.trim(),
              body: _body.text.trim(),
              eventId: eventId,
              pinned: _pinned,
            );
      for (final f in [
        ..._files,
        for (final p in _photos) PickedFile(p.name, p.bytes),
      ]) {
        try {
          await repo.attach(created.id, bytes: f.bytes, filename: f.name);
        } catch (_) {
          // The announcement is out; say which file is missing.
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.attachmentFailed(f.name))));
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? l.announcementUpdated : l.announcementSent),
        ),
      );
      if (!_editing) await _clearDraft();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: c.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MsgRadius.md),
        borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
      ),
    );
    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        t,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: _editing ? l.editAnnouncement : l.newAnnouncement,
              back: true,
              small: true,
              actions: [
                if (!_editing)
                  TextButton(
                    key: const Key('a-draft'),
                    onPressed: _busy ? null : _saveDraft,
                    child: Text(l.keepDraft),
                  ),
              ],
            ),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Seg2(
                      options: [l.kindAnnouncement, l.kindConvocation],
                      selected: _kind,
                      onChanged: (i) => setState(() => _kind = i),
                    ),
                    label(l.eventTitle),
                    TextFormField(
                      key: const Key('a-title'),
                      controller: _title,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.required : null,
                      decoration: deco(),
                    ),
                    label(l.message),
                    TextFormField(
                      key: const Key('a-body'),
                      controller: _body,
                      maxLines: 6,
                      decoration: deco(),
                    ),
                    const SizedBox(height: 16),
                    if (_photos.isNotEmpty) ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: photoRatio,
                        children: [
                          for (final (i, p) in _photos.indexed)
                            Stack(
                              key: Key('picked-photo-$i'),
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    MsgRadius.md,
                                  ),
                                  child: Image.memory(
                                    p.bytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton.filledTonal(
                                    tooltip: l.removeFile,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        setState(() => _photos.removeAt(i)),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (final (i, f) in _files.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AttachmentTile(
                          key: Key('picked-$i'),
                          name: f.name,
                          subtitle: fileSize(l, f.bytes.length),
                          isPdf: f.name.toLowerCase().endsWith('.pdf'),
                          trailing: IconButton(
                            tooltip: l.removeFile,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _files.removeAt(i)),
                          ),
                        ),
                      ),
                    GroupCard(
                      children: [
                        if (_kind == 1)
                          ListRow(
                            key: const Key('a-event'),
                            lead: IconChip(
                              Icons.event_available_outlined,
                              tone: _eventMissing ? Tone.red : Tone.green,
                            ),
                            title: Text(_event?.title ?? l.chooseEvent),
                            subtitle: _eventMissing
                                ? Text(
                                    l.eventRequired,
                                    style: TextStyle(color: c.alert),
                                  )
                                : (_event == null
                                      ? Text(l.linkedEvent)
                                      : Text(
                                          Dates(
                                            context,
                                          ).fullDateTime(_event!.startsAt),
                                        )),
                            chevron: true,
                            onTap: _pickEvent,
                          ),
                        ListRow(
                          key: const Key('a-photo'),
                          lead: const IconChip(
                            Icons.add_photo_alternate_outlined,
                            tone: Tone.green,
                          ),
                          title: Text(l.addPhoto),
                          subtitle: Text(l.addPhotoHint),
                          trailing: _photos.isEmpty
                              ? null
                              : Badge2(
                                  '${_photos.length}/$photosPerAnnouncement',
                                ),
                          onTap: _addPhoto,
                        ),
                        ListRow(
                          key: const Key('a-attach'),
                          lead: const IconChip(
                            Icons.attach_file,
                            tone: Tone.red,
                          ),
                          title: Text(l.attachFile),
                          subtitle: Text(l.attachPdfHint),
                          onTap: _pickFile,
                        ),
                        ListRow(
                          lead: const IconChip(
                            Icons.groups_outlined,
                            tone: Tone.neutral,
                          ),
                          title: Text(l.recipientsAll),
                        ),
                        if (!_editing)
                          ListRow(
                            title: Text(l.pinOnTop),
                            trailing: Switch(
                              key: const Key('a-pin'),
                              value: _pinned,
                              onChanged: (v) => setState(() => _pinned = v),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.borderSubtle)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('a-send'),
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    _editing
                        ? l.save
                        : (_kind == 1 ? l.sendConvocation : l.sendAnnouncement),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
