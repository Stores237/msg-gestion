import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/member.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
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
                  child: _ProfileBody(m: m),
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
  const _ProfileBody({required this.m});
  final MemberDetail m;

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
            MemberAvatar(
              name: s.fullName,
              status: s.status,
              diaspora: s.isDiaspora,
              size: 72,
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
