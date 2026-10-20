import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/member.dart';
import '../../widgets/dates.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';
import 'member_profile_screen.dart';

class BureauScreen extends StatelessWidget {
  const BureauScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.theBureau, back: true, small: true),
            Expanded(
              child: AsyncView<List<BureauEntry>>(
                load: RepositoryLocator.instance.members.bureau,
                builder: (context, rows, reload) => RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      GroupCard(
                        children: [
                          for (final r in rows)
                            ListRow(
                              lead: MemberAvatar(
                                name: r.member.fullName,
                                status: r.member.status,
                              ),
                              title: Text(
                                roleLabel(l, r.role.slug, r.role.name),
                              ),
                              subtitle: Text(
                                [
                                  r.member.fullName,
                                  if (r.endsOn != null)
                                    l.mandateUntil(
                                      Dates(context).shortDate(r.endsOn!),
                                    ),
                                ].join(' · '),
                              ),
                              chevron: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MemberProfileScreen(
                                    memberId: r.member.id,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
