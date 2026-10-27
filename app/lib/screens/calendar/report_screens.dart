import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/current_user.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/tokens.dart';
import '../../widgets/attachments.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/launch.dart';
import '../../widgets/notice.dart';
import '../../widgets/ui.dart';

/// The chef de groupe's report on an event (owner, 2026-10-27): handed in
/// within 24 h of the end, in the app or as a PDF, to the formateur with
/// the formateur adjoint, secrétaire général, censeur général and
/// vice-censeur in copy. No design existed: built from the event detail's
/// cards and the announcement composer.

(String, Tone) reportBadge(AppLocalizations l, String status) =>
    switch (status) {
      'submitted' => (l.reportBadgeSubmitted, Tone.green),
      'late' => (l.reportBadgeLate, Tone.amber),
      'missing' => (l.reportBadgeMissing, Tone.red),
      _ => (l.reportBadgePending, Tone.amber),
    };

/// "Rapport du chef de groupe" on the event detail: status, deadline, and
/// the chef's or the readers' action.
class ReportSection extends StatelessWidget {
  const ReportSection({super.key, required this.event, required this.onDone});
  final CalendarEvent event;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final e = event;
    final due = e.reportDueAt;
    final isChef = e.chefId != null && e.chefId == currentUser.value?.id;
    final (badge, tone) = reportBadge(l, e.reportStatus);
    final line = switch (e.reportStatus) {
      'submitted' => l.reportHandedIn,
      'late' => l.reportHandedInLate,
      'missing' when due != null => l.reportMissingSince(d.fullDateTime(due)),
      'pending' when due != null && isChef && !e.canReport =>
        l.reportChefBefore(d.fullDateTime(due)),
      'pending' when due != null => l.reportDue(d.fullDateTime(due)),
      _ => badge,
    };
    Future<void> open(Widget screen) async {
      final changed = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => screen));
      if (changed == true) onDone();
    }

    final done = e.reportStatus == 'submitted' || e.reportStatus == 'late';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l.reportSection),
        const SizedBox(height: 8),
        GroupCard(
          children: [
            ListRow(
              key: const Key('report-status'),
              lead: IconChip(Icons.assignment_outlined, tone: tone),
              // The chef is named in the card above; this row is the status.
              title: Text(line),
              subtitle: e.reportReadBy == null
                  ? null
                  : Row(
                      key: const Key('report-locked'),
                      children: [
                        const Icon(Icons.lock_outline, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l.reportReadBy(
                              e.reportReadBy!.isEmpty ? '—' : e.reportReadBy!,
                            ),
                          ),
                        ),
                      ],
                    ),
              trailing: Badge2(badge, tone: tone),
            ),
            if (e.canReadReport)
              ListRow(
                key: const Key('report-read'),
                lead: const Icon(Icons.description_outlined),
                title: Text(l.readReport),
                chevron: true,
                onTap: () => open(ReportViewScreen(event: e)),
              ),
          ],
        ),
        if (e.canReport) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('report-write'),
            onPressed: () => open(ReportFormScreen(event: e, editing: done)),
            icon: const Icon(Icons.edit_note),
            label: Text(done ? l.editReport : l.writeReport),
          ),
        ],
      ],
    );
  }
}

/// Reading a report: who, when, on time or late, the text and the PDF.
class ReportViewScreen extends StatelessWidget {
  const ReportViewScreen({super.key, required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    final c = context.msg;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.reportTitle, back: true, small: true),
            Expanded(
              child: AsyncView<EventReport>(
                load: () => RepositoryLocator.instance.events.report(event.id),
                builder: (context, r, reload) {
                  final (badge, tone) = reportBadge(
                    l,
                    r.late ? 'late' : 'submitted',
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      EventTypeLine(event: event),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GroupCard(
                        children: [
                          ListRow(
                            lead: const Icon(Icons.shield_outlined),
                            title: Text(l.reportBy(r.authorName ?? '—')),
                            subtitle: Text(
                              r.late
                                  ? l.reportLateOn(
                                      d.fullDateTime(r.submittedAt),
                                    )
                                  : l.reportSubmittedOn(
                                      d.fullDateTime(r.submittedAt),
                                    ),
                            ),
                            trailing: Badge2(badge, tone: tone),
                          ),
                          if (r.readAt != null)
                            ListRow(
                              key: const Key('report-opened'),
                              lead: const Icon(Icons.lock_outline),
                              title: Text(
                                l.reportOpenedOn(
                                  r.readByName ?? '—',
                                  d.fullDateTime(r.readAt!),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (r.body.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SelectionArea(
                          child: Text(
                            r.body,
                            key: const Key('report-body'),
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (r.fileUrl != null) ...[
                        const SizedBox(height: 16),
                        AttachmentTile(
                          key: const Key('report-pdf'),
                          name: r.fileName,
                          subtitle: 'PDF',
                          isPdf: true,
                          onTap: () => openUri(context, Uri.parse(r.fileUrl!)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Notice(text: l.reportRecipients),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Writing the report (the chef): the text, a PDF, or both. Laid out like
/// the announcement composer.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.event,
    this.editing = false,
  });
  final CalendarEvent event;
  final bool editing;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _body = TextEditingController();
  (String, List<int>)? _pdf;
  String _existingPdf = '';
  bool _busy = false;
  String? _error;

  static const _maxBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    if (widget.editing) {
      RepositoryLocator.instance.events
          .report(widget.event.id)
          .then((r) {
            if (!mounted) return;
            setState(() {
              if (_body.text.isEmpty) _body.text = r.body;
              _existingPdf = r.fileName;
            });
          })
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final l = AppLocalizations.of(context);
    final List<PlatformFile> picked;
    try {
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
      return;
    }
    if (picked.isEmpty) return;
    final p = picked.first;
    if ((await p.length() ?? 0) > _maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.fileTooLarge)));
      }
      return;
    }
    final bytes = await p.readAsBytes();
    if (mounted) {
      setState(() {
        _pdf = (p.name, bytes);
        _error = null;
      });
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final body = _body.text.trim();
    if (body.isEmpty && _pdf == null && _existingPdf.isEmpty) {
      setState(() => _error = l.reportEmpty);
      return;
    }
    setState(() => _busy = true);
    try {
      await RepositoryLocator.instance.events.submitReport(
        widget.event.id,
        body: body,
        pdf: _pdf,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.reportSent)));
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
    final e = widget.event;
    final late = e.reportStatus == 'missing';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: widget.editing ? l.editReport : l.writeReport,
              back: true,
              small: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  EventTypeLine(event: e),
                  const SizedBox(height: 4),
                  Text(
                    e.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (e.reportDueAt != null && !late) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.reportDue(Dates(context).fullDateTime(e.reportDueAt!)),
                      style: TextStyle(fontSize: 14, color: c.textSecondary),
                    ),
                  ],
                  if (late) ...[
                    const SizedBox(height: 12),
                    Notice(text: l.reportLateWarning, tone: NoticeTone.warn),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 6),
                    child: Text(
                      l.reportBodyLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextField(
                    key: const Key('report-text'),
                    controller: _body,
                    maxLines: 10,
                    minLines: 6,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: InputDecoration(
                      hintText: l.reportBodyHint,
                      filled: true,
                      fillColor: c.surfaceCard,
                      errorText: _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MsgRadius.md),
                        borderSide: BorderSide(
                          color: c.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(MsgRadius.md),
                        borderSide: BorderSide(
                          color: c.borderSubtle,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pdf != null || _existingPdf.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AttachmentTile(
                        key: const Key('report-picked'),
                        name: _pdf?.$1 ?? _existingPdf,
                        subtitle: _pdf == null
                            ? 'PDF'
                            : fileSize(l, _pdf!.$2.length),
                        isPdf: true,
                        trailing: _pdf == null
                            ? null
                            : IconButton(
                                tooltip: l.removeFile,
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _pdf = null),
                              ),
                      ),
                    ),
                  GroupCard(
                    children: [
                      ListRow(
                        key: const Key('report-attach'),
                        lead: const IconChip(Icons.attach_file, tone: Tone.red),
                        title: Text(l.reportAttachPdf),
                        subtitle: Text(l.pdfOnly),
                        onTap: _pickPdf,
                      ),
                      ListRow(
                        lead: const IconChip(
                          Icons.groups_outlined,
                          tone: Tone.neutral,
                        ),
                        title: Text(l.reportRecipients),
                        subtitle: Text(l.reportLockNote),
                      ),
                    ],
                  ),
                ],
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
                child: FilledButton(
                  key: const Key('report-send'),
                  onPressed: _busy ? null : _send,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.sendReport),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
