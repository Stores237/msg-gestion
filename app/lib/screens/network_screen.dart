import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/profile_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/errors.dart';
import '../widgets/group_logo.dart';
import '../widgets/ui.dart';
import 'network_sharing_screens.dart';

/// Réseau (owner, 2026-11-03): groups linked in levels, like the MGS's
/// parish groups, zones paroissiales and dioceses. Everyone sees where the
/// group stands; the président (group.profile) joins an umbrella group with
/// its code, leaves it, and in an umbrella group invites. The umbrella only
/// informs the groups under it.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  NetworkInfo? _info;
  Object? _error;
  bool _busy = false;

  ProfileRepository get _repo => RepositoryLocator.instance.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _repo.network();
      if (!mounted) return;
      setState(() {
        _info = info;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _join({bool twin = false}) async {
    final l = AppLocalizations.of(context);
    final preview = await showDialog<(String, InvitationPreview)>(
      context: context,
      builder: (_) => _JoinDialog(twin: twin),
    );
    if (preview == null || !mounted) return;
    final (code, from) = preview;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('join-ask'),
        title: Text(
          twin
              ? l.groupNetTwinAskTitle(from.group.name)
              : l.groupNetJoinAskTitle(from.group.name),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GroupLogo(group: from.group, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        from.group.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          from.levelName,
                          from.network,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      if (from.parents.isNotEmpty)
                        Text(l.groupNetUnder(from.parents.join(' › '))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(twin ? l.groupNetTwinAskBody : l.groupNetJoinAskBody),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            key: const Key('join-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(twin ? l.groupNetTwin : l.groupNetJoin),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      final info = twin
          ? await _repo.joinTwin(code)
          : await _repo.joinNetwork(code);
      if (!mounted) return;
      setState(() => _info = info);
      _snack(
        twin
            ? l.groupNetTwinned(from.group.name)
            : l.groupNetJoined(from.group.name),
      );
    });
  }

  Future<void> _leave(NetworkGroup parent) async {
    final l = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _LeaveDialog(parent: parent.group.name),
    );
    if (reason == null || !mounted) return;
    await _run(() async {
      final info = await _repo.leaveNetwork(reason);
      if (!mounted) return;
      setState(() => _info = info);
      _snack(l.groupNetLeft(parent.group.name));
    });
  }

  Future<void> _endTwin(NetworkGroup other) async {
    final l = AppLocalizations.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _LeaveDialog(parent: other.group.name, twin: true),
    );
    if (reason == null || !mounted) return;
    await _run(() async {
      final info = await _repo.endTwin(other.group.id, reason);
      if (!mounted) return;
      setState(() => _info = info);
      _snack(l.groupNetTwinEnded(other.group.name));
    });
  }

  Future<void> _invite({bool twin = false}) async {
    Invitation? inv;
    await _run(() async {
      inv = await _repo.createInvitation(twin: twin);
      await _load();
    });
    if (inv != null && mounted) await _showCode(inv!, twin: twin);
  }

  Future<void> _showCode(Invitation inv, {bool twin = false}) {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('invite-dialog'),
        title: Text(twin ? l.groupNetTwinCodeTitle : l.groupNetInviteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              inv.code,
              key: const Key('invite-code'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (twin ? l.groupNetTwinCodeHint : l.groupNetInviteHint)(
                Dates(context).fullDate(inv.expiresAt),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('invite-copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inv.code));
              Navigator.of(context).pop();
              _snack(l.groupNetCodeCopied);
            },
            icon: const Icon(Icons.copy),
            label: Text(l.copy),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(Invitation inv) async {
    final l = AppLocalizations.of(context);
    await _run(() async {
      await _repo.revokeInvitation(inv.code);
      await _load();
      if (mounted) _snack(l.groupNetCodeRevoked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final info = _info;
    Widget groupRow(
      NetworkGroup g,
      String key, {
      String? extra,
      VoidCallback? onTap,
    }) => ListRow(
      key: Key(key),
      lead: GroupLogo(group: g.group, size: 36),
      title: Text(g.group.name),
      subtitle: Text(
        [g.levelName, ?extra].where((s) => s.isNotEmpty).join(' · '),
      ),
      chevron: onTap != null,
      onTap: onTap,
    );
    String sharesText(List<String> kinds) => kinds.isEmpty
        ? l.groupNetSharesNone
        : l.groupNetSharesList(
            kinds.map((k) => sharingKindLabel(l, k).toLowerCase()).join(', '),
          );
    void open(NetworkGroup g) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SharedGroupScreen(groupId: g.group.id)),
    );
    Widget sharingRow(
      Map<String, String> sh,
      String audience,
      String sub,
    ) => ListRow(
      key: Key(audience == 'up' ? 'network-sharing' : 'sharing-$audience'),
      lead: const Icon(Icons.visibility_outlined),
      title: Text(
        sh.values.every((v) => v == 'none')
            ? l.groupNetSharesNone
            : l.groupNetSharesList(
                [
                  for (final k in SharingSettings.kinds)
                    if ((sh[k] ?? 'none') != 'none')
                      '${sharingKindLabel(l, k).toLowerCase()} (${sharingLevelLabel(l, sh[k]!).toLowerCase()})',
                ].join(', '),
              ),
      ),
      subtitle: Text(sub),
      chevron: true,
      onTap: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => SharingScreen(audience: audience)),
        );
        if (saved == true) _load();
      },
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.groupNetTitle, back: true, small: true),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: info == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                describeError(context, _error!),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        key: const Key('network-screen'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          Text(
                            info.networkName == null
                                ? l.groupNetNone
                                : l.groupNetIn(
                                    info.networkName!,
                                    info.levelName,
                                  ),
                            key: const Key('network-name'),
                            style: TextStyle(
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                          if (info.levels.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              info.levels.join(' › '),
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SectionLabel(l.groupNetAbove),
                          const SizedBox(height: 8),
                          if (info.parents.isEmpty)
                            Text(
                              l.groupNetNoParent,
                              style: TextStyle(color: c.textSecondary),
                            )
                          else
                            GroupCard(
                              children: [
                                for (final g in info.parents)
                                  groupRow(g, 'network-parent-${g.group.id}'),
                              ],
                            ),
                          if (info.canManage) ...[
                            const SizedBox(height: 12),
                            if (info.parents.isEmpty)
                              OutlinedButton.icon(
                                key: const Key('network-join'),
                                onPressed: _busy ? null : _join,
                                icon: const Icon(Icons.link),
                                label: Text(l.groupNetJoinWithCode),
                                style: _stadium,
                              )
                            else
                              TextButton.icon(
                                key: const Key('network-leave'),
                                onPressed: _busy
                                    ? null
                                    : () => _leave(info.parents.first),
                                icon: Icon(Icons.link_off, color: c.alert),
                                label: Text(
                                  l.groupNetLeave(
                                    info.parents.first.group.name,
                                  ),
                                  style: TextStyle(color: c.alert),
                                ),
                              ),
                          ],
                          if (info.sharing != null ||
                              info.sharingNeighbours != null ||
                              info.sharingTwins != null) ...[
                            const SizedBox(height: 24),
                            SectionLabel(l.groupNetSharingTitle),
                            const SizedBox(height: 8),
                            GroupCard(
                              children: [
                                if (info.sharing case final sh?)
                                  sharingRow(
                                    sh,
                                    'up',
                                    l.groupNetSharingWith(
                                      info.parents.first.group.name,
                                    ),
                                  ),
                                if (info.sharingNeighbours case final sh?)
                                  sharingRow(
                                    sh,
                                    'neighbours',
                                    l.groupNetSharingNeighbours,
                                  ),
                                if (info.sharingTwins case final sh?)
                                  sharingRow(
                                    sh,
                                    'twins',
                                    l.groupNetSharingTwins,
                                  ),
                              ],
                            ),
                          ],
                          if (info.parents.isNotEmpty ||
                              info.children.isNotEmpty ||
                              info.neighbours.isNotEmpty ||
                              info.twins.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            GroupCard(
                              children: [
                                ListRow(
                                  key: const Key('network-requests'),
                                  lead: IconChip(
                                    Icons.mark_email_unread_outlined,
                                    tone: info.requestsWaiting > 0
                                        ? Tone.amber
                                        : Tone.neutral,
                                  ),
                                  title: Text(l.srTitle),
                                  subtitle: Text(l.srRowHint),
                                  trailing: info.requestsWaiting > 0
                                      ? Badge2(
                                          '${info.requestsWaiting}',
                                          tone: Tone.amber,
                                        )
                                      : null,
                                  chevron: true,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ShareRequestsScreen(),
                                      ),
                                    );
                                    _load();
                                  },
                                ),
                              ],
                            ),
                          ],
                          if (info.children.isNotEmpty || info.canInvite) ...[
                            const SizedBox(height: 24),
                            SectionLabel(l.groupNetBelow(info.children.length)),
                            const SizedBox(height: 8),
                            if (info.totals case final t?) ...[
                              Text(
                                l.groupNetTotals(
                                  t.members,
                                  t.sharingMembers,
                                  t.groups,
                                ),
                                key: const Key('network-totals'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (info.children.isEmpty)
                              Text(
                                l.groupNetNoChildren,
                                style: TextStyle(color: c.textSecondary),
                              )
                            else
                              GroupCard(
                                children: [
                                  for (final g in info.children)
                                    groupRow(
                                      g,
                                      'network-child-${g.group.id}',
                                      extra: [
                                        if (g.waiting) l.groupNetWaiting,
                                        if (g.below > 0)
                                          l.groupNetGroupsBelow(g.below),
                                        g.shares.isEmpty
                                            ? l.groupNetSharesNone
                                            : l.groupNetSharesList(
                                                g.shares
                                                    .map(
                                                      (k) => sharingKindLabel(
                                                        l,
                                                        k,
                                                      ).toLowerCase(),
                                                    )
                                                    .join(', '),
                                              ),
                                      ].join(' · '),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => SharedGroupScreen(
                                            groupId: g.group.id,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                          if (info.canInvite) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: const Key('network-invite'),
                              onPressed: _busy ? null : _invite,
                              icon: const Icon(Icons.group_add_outlined),
                              label: Text(l.groupNetInvite),
                              style: _stadium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.groupNetInviteAbout,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                            if (info.invitations.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SectionLabel(l.groupNetPendingCodes),
                              const SizedBox(height: 8),
                              GroupCard(
                                children: [
                                  for (final inv in info.invitations)
                                    ListRow(
                                      key: Key('invitation-${inv.code}'),
                                      title: Text(
                                        inv.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      subtitle: Text(
                                        l.groupNetCodeUntil(
                                          Dates(
                                            context,
                                          ).fullDate(inv.expiresAt),
                                        ),
                                      ),
                                      onTap: () => _showCode(inv),
                                      trailing: IconButton(
                                        key: Key('revoke-${inv.code}'),
                                        tooltip: l.groupNetRevoke,
                                        onPressed: _busy
                                            ? null
                                            : () => _revoke(inv),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                          if (info.neighbours.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            SectionLabel(l.groupNetNeighbours),
                            const SizedBox(height: 8),
                            GroupCard(
                              children: [
                                for (final g in info.neighbours)
                                  groupRow(
                                    g,
                                    'neighbour-${g.group.id}',
                                    extra: sharesText(g.shares),
                                    onTap: () => open(g),
                                  ),
                              ],
                            ),
                          ],
                          if (info.twins.isNotEmpty || info.canManage) ...[
                            const SizedBox(height: 24),
                            SectionLabel(l.groupNetTwins),
                            const SizedBox(height: 8),
                            if (info.twins.isEmpty)
                              Text(
                                l.groupNetNoTwins,
                                style: TextStyle(color: c.textSecondary),
                              )
                            else
                              GroupCard(
                                children: [
                                  for (final g in info.twins)
                                    ListRow(
                                      key: Key('twin-${g.group.id}'),
                                      lead: GroupLogo(group: g.group, size: 36),
                                      title: Text(g.group.name),
                                      subtitle: Text(sharesText(g.shares)),
                                      onTap: () => open(g),
                                      trailing: info.canManage
                                          ? IconButton(
                                              key: Key(
                                                'end-twin-${g.group.id}',
                                              ),
                                              tooltip: l.groupNetTwinEnd,
                                              onPressed: _busy
                                                  ? null
                                                  : () => _endTwin(g),
                                              icon: Icon(
                                                Icons.link_off,
                                                color: c.alert,
                                              ),
                                            )
                                          : null,
                                    ),
                                ],
                              ),
                            if (info.canManage) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      key: const Key('twin-invite'),
                                      onPressed: _busy
                                          ? null
                                          : () => _invite(twin: true),
                                      icon: const Icon(
                                        Icons.handshake_outlined,
                                      ),
                                      label: Text(l.groupNetTwinInvite),
                                      style: _stadium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      key: const Key('twin-join'),
                                      onPressed: _busy
                                          ? null
                                          : () => _join(twin: true),
                                      icon: const Icon(Icons.input),
                                      label: Text(l.groupNetTwinAccept),
                                      style: _stadium,
                                    ),
                                  ),
                                ],
                              ),
                              for (final inv in info.twinInvitations)
                                ListRow(
                                  key: Key('twin-code-${inv.code}'),
                                  title: Text(
                                    inv.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  subtitle: Text(
                                    l.groupNetCodeUntil(
                                      Dates(context).fullDate(inv.expiresAt),
                                    ),
                                  ),
                                  onTap: () => _showCode(inv, twin: true),
                                  trailing: IconButton(
                                    key: Key('revoke-${inv.code}'),
                                    tooltip: l.groupNetRevoke,
                                    onPressed: _busy
                                        ? null
                                        : () => _revoke(inv),
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                            ],
                          ],
                          const SizedBox(height: 24),
                          Text(
                            l.groupNetAbout,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final _stadium = OutlinedButton.styleFrom(
  minimumSize: const Size.fromHeight(48),
  shape: const StadiumBorder(),
);

/// Type the umbrella's code; it is checked (who invites) before anything
/// is joined.
class _JoinDialog extends StatefulWidget {
  const _JoinDialog({this.twin = false});
  final bool twin;

  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    final code = _code.text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (code.length != 8) {
      setState(() => _error = l.groupNetCodeLength);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final from = await RepositoryLocator.instance.profile.previewInvitation(
        code,
        twin: widget.twin,
      );
      if (mounted) Navigator.of(context).pop((code, from));
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.twin ? l.groupNetTwinAccept : l.groupNetJoinWithCode),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.twin ? l.groupNetTwinJoinHint : l.groupNetJoinHint),
          const SizedBox(height: 12),
          TextField(
            key: const Key('join-code'),
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: 9,
            decoration: InputDecoration(
              hintText: 'ABCD-EFGH',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _check(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('join-check'),
          onPressed: _busy ? null : _check,
          child: Text(l.continueButton),
        ),
      ],
    );
  }
}

class _LeaveDialog extends StatefulWidget {
  const _LeaveDialog({required this.parent, this.twin = false});
  final String parent;
  final bool twin;

  @override
  State<_LeaveDialog> createState() => _LeaveDialogState();
}

class _LeaveDialogState extends State<_LeaveDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.twin
            ? l.groupNetTwinEndTitle(widget.parent)
            : l.groupNetLeave(widget.parent),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.twin ? l.groupNetTwinEndBody : l.groupNetLeaveBody),
          const SizedBox(height: 12),
          TextField(
            key: const Key('leave-reason'),
            controller: _reason,
            maxLength: 300,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l.reasonRequired,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('leave-confirm'),
          style: FilledButton.styleFrom(backgroundColor: context.msg.alert),
          onPressed: () {
            final r = _reason.text.trim();
            if (r.length < 3) {
              setState(() => _error = l.groupNetLeaveReason);
              return;
            }
            Navigator.of(context).pop(r);
          },
          child: Text(l.groupNetLeaveConfirm),
        ),
      ],
    );
  }
}
