import 'package:flutter/material.dart';

import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/access_request.dart';
import '../../theme/tokens.dart';
import '../../widgets/dates.dart';
import '../../widgets/errors.dart';
import '../../widgets/labels.dart';
import '../../widgets/ui.dart';

/// "Demandes d'accès": the leader follows their requests to the MSG
/// partner and, once an access is created, sees the temporary PIN once to
/// hand it over.
class AccessRequestsScreen extends StatelessWidget {
  const AccessRequestsScreen({super.key});

  Future<void> _reveal(
    BuildContext context,
    AccessRequestItem r,
    Future<void> Function() reload,
  ) async {
    final l = AppLocalizations.of(context);
    try {
      final p = await RepositoryLocator.instance.members.revealAccessPin(r.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l.tempPinTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.pin,
                key: const Key('temp-pin'),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.tempPinBody(p.fullName, p.phone)),
            ],
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
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final d = Dates(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.accessRequestsTitle, back: true, small: true),
            Expanded(
              child: AsyncView<List<AccessRequestItem>>(
                load: RepositoryLocator.instance.members.accessRequests,
                builder: (context, items, reload) => RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (items.isEmpty)
                        EmptyState(
                          icon: Icons.how_to_reg_outlined,
                          title: l.noAccessRequests,
                        )
                      else
                        GroupCard(
                          children: [
                            for (final r in items)
                              ListRow(
                                key: Key('access-${r.id}'),
                                title: Text(r.fullName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${roleLabel(l, r.role, r.roleName)} · '
                                      '${d.dayMonth(r.createdAt)}',
                                    ),
                                    if (r.status == 'refused' &&
                                        r.decisionNote.isNotEmpty)
                                      Text(
                                        r.decisionNote,
                                        style: TextStyle(
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    if (r.approved && !r.pinReady)
                                      Text(
                                        l.accessExistingAccount,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        r.pending
                                            ? Badge2(
                                                l.accessPending,
                                                tone: Tone.amber,
                                              )
                                            : r.approved
                                            ? Badge2(
                                                l.accessApproved,
                                                tone: Tone.green,
                                              )
                                            : Badge2(
                                                l.accessRefused,
                                                tone: Tone.red,
                                              ),
                                        if (r.pinReady)
                                          FilledButton.tonal(
                                            key: Key('reveal-${r.id}'),
                                            onPressed: () =>
                                                _reveal(context, r, reload),
                                            child: Text(l.showTempPin),
                                          ),
                                      ],
                                    ),
                                  ],
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
