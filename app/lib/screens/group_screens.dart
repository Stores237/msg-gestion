import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/group_controller.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/group_logo.dart';
import '../widgets/huddle_logo.dart';
import '../widgets/my_photo.dart' show pickPhoto;
import '../widgets/ui.dart';
import 'splash_screen.dart';

/// Huddle, like Slack (owner, 2026-11-02): someone in several groups picks
/// one after signing in, as Slack lists your workspaces. The choice is
/// remembered; one group goes straight in.
class GroupPickScreen extends StatelessWidget {
  const GroupPickScreen({super.key, required this.groups});
  final List<GroupInfo> groups;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('group-pick'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            children: [
              const Center(child: HuddleWordmark(size: 40)),
              const SizedBox(height: 28),
              Text(
                l.chooseGroup,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                l.chooseGroupHint,
                style: TextStyle(fontSize: 15, color: c.textSecondary),
              ),
              const SizedBox(height: 16),
              GroupCard(
                children: [
                  for (final g in groups)
                    ListRow(
                      key: Key('pick-group-${g.id}'),
                      lead: GroupLogo(group: g, size: 44),
                      title: Text(g.name),
                      chevron: true,
                      onTap: () => Navigator.of(context).pop(g.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// After signing in or opening the app: in several groups and none chosen
/// yet → the pick screen, then the account as seen in that group.
Future<Me> chooseGroupIfNeeded(NavigatorState nav, Me me) async {
  if (GroupController.instance.id != null || me.groups.length < 2) {
    if (GroupController.instance.id == null && me.group != null) {
      await GroupController.instance.select(me.group!.id);
    }
    return me;
  }
  final picked = await nav.push<int>(
    MaterialPageRoute(builder: (_) => GroupPickScreen(groups: me.groups)),
  );
  await GroupController.instance.select(picked ?? me.group?.id);
  return RepositoryLocator.instance.profile.fetchMe();
}

/// The group line of Accueil, tapped: switch group (logos, like Slack's
/// workspace list) and, for the président, the group's name and logo.
Future<void> showGroupSheet(BuildContext context, Me me) async {
  final l = AppLocalizations.of(context);
  final canEdit = me.can('group.profile', 'change');
  final picked = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            me.groups.length > 1 ? l.chooseGroup : l.groupLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final g
              in me.groups.isEmpty && me.group != null
                  ? [me.group!]
                  : me.groups)
            ListTile(
              key: Key('group-${g.id}'),
              contentPadding: EdgeInsets.zero,
              leading: GroupLogo(group: g, size: 40),
              title: Text(g.name),
              trailing: g.id == me.group?.id
                  ? Icon(Icons.check_circle, color: context.msg.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(g.id),
            ),
          if (canEdit)
            ListTile(
              key: const Key('edit-group'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: Text(l.groupProfileTitle),
              subtitle: Text(l.groupProfileHint),
              onTap: () => Navigator.of(context).pop(-1),
            ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  if (picked == -1) {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GroupProfileScreen(group: me.group!)),
    );
    if (changed == true && context.mounted) _restart(context);
    return;
  }
  if (picked == me.group?.id) return;
  await GroupController.instance.select(picked);
  if (context.mounted) _restart(context);
}

/// Start again in the group as it now is: its roles, tabs, name and logo.
void _restart(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const SplashScreen()),
  (_) => false,
);

/// The président changes the group's name, sigle and logo (the
/// group.profile right; the super admin does it in the back-office).
class GroupProfileScreen extends StatefulWidget {
  const GroupProfileScreen({super.key, required this.group});
  final GroupInfo group;

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  late GroupInfo _group = widget.group;
  late final _name = TextEditingController(text: widget.group.name);
  late final _short = TextEditingController(text: widget.group.shortName);
  bool _busy = false;
  bool _changed = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _short.dispose();
    super.dispose();
  }

  Future<void> _logo() async {
    final l = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('logo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.photoFromGallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              key: const Key('logo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.photoFromCamera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if ((_group.logo ?? '').isNotEmpty)
              ListTile(
                key: const Key('logo-remove'),
                leading: const Icon(Icons.delete_outline),
                title: Text(l.groupLogoRemove),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final repo = RepositoryLocator.instance.profile;
    setState(() => _busy = true);
    try {
      GroupInfo g;
      if (choice == 'remove') {
        g = await repo.removeGroupLogo();
      } else {
        final picked = await pickPhoto(
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (picked == null) return;
        g = await repo.uploadGroupLogo(bytes: picked.$1, filename: picked.$2);
      }
      if (!mounted) return;
      setState(() {
        _group = g;
        _changed = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.groupLogoSaved)));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l.groupNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RepositoryLocator.instance.profile.updateGroup(
        name: name,
        shortName: _short.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.groupProfileSaved)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l.groupProfileTitle, back: true, small: true),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GroupLogo(group: _group, size: 96),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            key: const Key('change-logo'),
                            onPressed: _busy ? null : _logo,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(l.groupLogoChange),
                          ),
                          Text(
                            l.groupLogoHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('group-name'),
                      controller: _name,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: l.groupName),
                    ),
                    TextField(
                      key: const Key('group-short'),
                      controller: _short,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l.groupShortName,
                        helperText: l.groupShortNameHint,
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          key: const Key('group-error'),
                          style: TextStyle(color: c.alert),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('group-save'),
                      onPressed: _busy ? null : _save,
                      child: Text(l.save),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
