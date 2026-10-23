import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/me.dart';
import '../../models/member.dart';
import '../../theme/tokens.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';
import 'access_requests_screen.dart';
import 'request_access_screen.dart';
import 'bureau_screen.dart';
import 'member_profile_screen.dart';

/// Members tab (design: "Membres · liste"): search, status filters with
/// counts, the bureau, and the list. Add button for roles that may register.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.me});
  final Me me;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  static const _filters = [null, 'actif', 'conge', 'classe', 'diaspora'];
  final _search = TextEditingController();
  Timer? _debounce;
  int _filter = 0;
  MemberPage? _page;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final f = _filters[_filter];
    try {
      final page = await RepositoryLocator.instance.members.list(
        query: _search.text.trim(),
        status: f == 'diaspora' ? null : f,
        diaspora: f == 'diaspora',
      );
      if (!mounted) return;
      setState(() {
        _page = page;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RequestAccessScreen()),
    );
    if (created == true && mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AccessRequestsScreen()));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final counts = _page?.counts ?? const MemberCounts();
    final canAdd = widget.me.can('members.profile', 'create');
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              key: const Key('add-member'),
              onPressed: _add,
              icon: const Icon(Icons.person_add_alt),
              label: Text(l.requestAccess),
              backgroundColor: c.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          ScreenHeader(
            title: l.tabMembers,
            sync: true,
            subtitle: _page == null ? null : l.membersSubtitle(counts.all),
            actions: [
              if (canAdd)
                IconButton(
                  key: const Key('open-access-requests'),
                  tooltip: l.accessRequestsTitle,
                  icon: const Icon(Icons.how_to_reg_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccessRequestsScreen(),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  TextField(
                    key: const Key('member-search'),
                    controller: _search,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.membersSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: c.surfaceCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: c.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(color: c.borderSubtle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChips(
                    labels: [
                      l.filterAll(counts.all),
                      l.filterActive(counts.active),
                      l.filterLeave(counts.leave),
                      l.filterRetired(counts.retired),
                      l.filterDiaspora(counts.diaspora),
                    ],
                    selected: _filter,
                    onSelected: (i) {
                      setState(() => _filter = i);
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  GroupCard(
                    children: [
                      ListRow(
                        key: const Key('bureau-row'),
                        lead: const IconChip(Icons.shield_outlined),
                        title: Text(l.theBureau),
                        subtitle: Text(l.theBureauSub),
                        chevron: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BureauScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_error != null && _page == null)
                    EmptyState(
                      icon: Icons.cloud_off_outlined,
                      error: true,
                      title: l.loadError,
                      action: FilledButton(
                        onPressed: _load,
                        child: Text(l.retry),
                      ),
                    )
                  else if (_page == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_page!.members.isEmpty)
                    EmptyState(
                      icon: Icons.person_search_outlined,
                      title: l.noMembersFound,
                    )
                  else
                    GroupCard(
                      children: [
                        for (final m in _page!.members) MemberRow(member: m),
                      ],
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

class MemberRow extends StatelessWidget {
  const MemberRow({super.key, required this.member});
  final MemberSummary member;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = member;
    final role = m.roles.isNotEmpty
        ? roleLabel(l, m.roles.first.slug, m.roles.first.name)
        : null;
    final sub = [
      role ?? l.guardSince(m.joinedYear),
      if (m.isDiaspora && m.city.isNotEmpty) m.city,
      if (m.isMinor && m.age != null) l.ageYears(m.age!),
    ].join(' · ');
    return ListRow(
      key: Key('member-${m.id}'),
      lead: MemberAvatar(
        name: m.fullName,
        status: m.status,
        diaspora: m.isDiaspora,
        photo: m.photo,
      ),
      title: Text(m.fullName),
      subtitle: Text(sub),
      trailing: m.status != 'actif'
          ? Badge2(memberStatusLabel(l, m.status), tone: statusTone(m.status))
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: m.id)),
      ),
    );
  }
}
