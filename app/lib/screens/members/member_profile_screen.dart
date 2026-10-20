import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/current_user.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/member.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/launch.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';

/// Member profile (design: "Profil membre"). What the server held back is
/// announced with a restricted block, never just missing.
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});
  final int memberId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.profile, back: true, small: true),
            Expanded(
              child: AsyncView<MemberDetail>(
                load: () => RepositoryLocator.instance.members.get(memberId),
                builder: (context, m, reload) => RefreshIndicator(
                  onRefresh: reload,
                  child: _ProfileBody(m: m, reload: reload),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  bool get canEdit =>
      currentUser.value?.can('members.profile', 'change') ?? false;
  bool get canPropose =>
      canEdit ||
      (currentUser.value?.can('calendar.planning', 'change') ?? false);

  Future<void> _pickPhoto(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    try {
      await RepositoryLocator.instance.members.uploadPhoto(
        m.summary.id,
        bytes: await picked.readAsBytes(),
        filename: picked.name,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.photoSaved)));
      reload();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _proposeRole(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final List<(String, String)> roles;
    try {
      roles = await RepositoryLocator.instance.members.requestableRoles();
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
      return;
    }
    if (!context.mounted) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _ProposeRoleSheet(memberId: m.summary.id, roles: roles),
    );
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.roleRequestSent)));
    }
  }

  Future<void> _resetPin(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final name = m.summary.fullName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.resetPin),
        content: Text(l.resetPinConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('reset-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final pin = await RepositoryLocator.instance.members.resetPin(
        m.summary.id,
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l.resetPin),
          content: Text(
            l.resetPinDone(name, pin),
            key: const Key('reset-done'),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  const _ProfileBody({required this.m, required this.reload});
  final MemberDetail m;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    final s = m.summary;
    final roles = s.roles.map((r) => roleLabel(l, r.slug, r.name)).toList();
    final sub = [
      roles.isEmpty ? l.roleGuard : roles.join(', '),
      if (s.age != null && s.isMinor) l.ageYears(s.age!),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Semantics(
              button: canEdit,
              label: canEdit
                  ? (s.photo == null ? l.addPhoto : l.changePhoto)
                  : null,
              child: InkWell(
                key: const Key('profile-photo'),
                customBorder: const CircleBorder(),
                onTap: canEdit ? () => _pickPhoto(context) : null,
                child: MemberAvatar(
                  name: s.fullName,
                  status: s.status,
                  diaspora: s.isDiaspora,
                  size: 72,
                  photo: s.photo,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Badge2(
                        memberStatusLabel(l, s.status),
                        tone: statusTone(s.status),
                      ),
                      if (s.isMinor) Badge2(l.minor),
                      if (s.isDiaspora)
                        Badge2(
                          s.city.isEmpty
                              ? l.diaspora
                              : '${l.diaspora} · ${s.city}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (m.phone != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('call'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => openUri(context, telUri(m.phone!)),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text(l.call),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('sms'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => openUri(context, smsUri(m.phone!)),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l.message),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SectionLabel(l.information),
        const SizedBox(height: 8),
        GroupCard(
          children: [
            if (m.phone != null)
              ListRow(title: SelectableText(m.phone!), subtitle: Text(l.phone)),
            ListRow(
              title: Text(d.fullDate(m.joinedOn)),
              subtitle: Text(l.joinedOn),
            ),
            if (m.birthDate != null)
              ListRow(
                title: Text(d.fullDate(m.birthDate!)),
                subtitle: Text(l.birthDate),
              ),
          ],
        ),
        if (m.parent != null) ...[
          const SizedBox(height: 20),
          SectionLabel(l.parentOrGuardian),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              ListRow(
                lead: const IconChip(Icons.person_outline),
                title: Text(
                  m.parent!.name.isEmpty ? m.parent!.phone : m.parent!.name,
                ),
                subtitle: Text(
                  [
                    if (m.parent!.relation.isNotEmpty) m.parent!.relation,
                    m.parent!.phone,
                  ].join(' · '),
                ),
              ),
            ],
          ),
        ],
        if (m.restricted.contains('minor_contacts')) ...[
          const SizedBox(height: 20),
          RestrictedBlock(text: l.restrictedMinorContacts),
        ],
        if (currentUser.value?.can('members.profile', 'change') ?? false) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('reset-pin'),
            onPressed: () => _resetPin(context),
            icon: const Icon(Icons.lock_reset),
            label: Text(l.resetPin),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
          ),
        ],
        if (m.attendance != null && m.attendance!.of > 0) ...[
          const SizedBox(height: 20),
          SectionLabel(l.presenceLast4),
          const SizedBox(height: 8),
          GroupCard(
            children: [
              ListRow(
                key: const Key('presence-summary'),
                title: Text(
                  l.presenceSummary(
                    m.attendance!.present,
                    m.attendance!.absent,
                    m.attendance!.excused,
                  ),
                ),
                subtitle: m.attendance!.last == null
                    ? null
                    : Text(
                        l.lastOn(Dates(context).fullDate(m.attendance!.last!)),
                      ),
              ),
            ],
          ),
        ],
        if (canPropose) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('propose-role'),
            onPressed: () => _proposeRole(context),
            icon: const Icon(Icons.badge_outlined),
            label: Text(l.proposeRole),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
          ),
        ],
        if (m.restricted.contains('contributions')) ...[
          const SizedBox(height: 20),
          SectionLabel(l.contributions),
          const SizedBox(height: 8),
          RestrictedBlock(text: l.restrictedContributions),
        ],
      ],
    );
  }
}

class _ProposeRoleSheet extends StatefulWidget {
  const _ProposeRoleSheet({required this.memberId, required this.roles});
  final int memberId;
  final List<(String, String)> roles;

  @override
  State<_ProposeRoleSheet> createState() => _ProposeRoleSheetState();
}

class _ProposeRoleSheetState extends State<_ProposeRoleSheet> {
  String? _role;
  DateTime _from = DateTime.now();
  DateTime? _to;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    if (_role == null || _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.required)));
      return;
    }
    setState(() => _busy = true);
    try {
      await RepositoryLocator.instance.members.requestRole(
        widget.memberId,
        role: _role!,
        reason: _reason.text.trim(),
        startsOn: _from,
        endsOn: _to,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = Dates(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.proposeRole, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('propose-role-select'),
            isExpanded: true,
            initialValue: _role,
            hint: Text(l.proposeRole),
            items: [
              for (final (slug, name) in widget.roles)
                DropdownMenuItem(
                  value: slug,
                  child: Text(roleLabel(l, slug, name)),
                ),
            ],
            onChanged: (v) => setState(() => _role = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _from,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime(2100),
                    );
                    if (p != null) setState(() => _from = p);
                  },
                  child: Text('${l.fromDate} ${d.shortDate(_from)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _to ?? _from,
                      firstDate: _from,
                      lastDate: DateTime(2100),
                    );
                    setState(() => _to = p);
                  },
                  child: Text(
                    _to == null
                        ? l.toDate
                        : '${l.toDate.split(' ').first} ${d.shortDate(_to!)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('propose-reason'),
            controller: _reason,
            decoration: InputDecoration(labelText: l.reasonRequired),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('propose-send'),
            onPressed: _busy ? null : _send,
            child: Text(l.sendRequest),
          ),
        ],
      ),
    );
  }
}
