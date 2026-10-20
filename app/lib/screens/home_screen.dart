import 'package:flutter/material.dart';

import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/msg_logo.dart';
import 'login_phone_screen.dart';

/// Accueil. For now: greeting, the member's active roles, and sign-out.
/// The design's cards (prochain service, contributions, annonces) arrive
/// with their modules.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.me});

  final Me me;

  Future<void> _logout(BuildContext context) async {
    await RepositoryLocator.instance.auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPhoneScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final main = me.roles.where((r) => r.slug != 'membre').map((r) => r.name).toList();
    final sub = [main.isEmpty ? 'Garde' : main.first, if (me.age != null && me.age! < 18) l.ageYears(me.age!)].join(' · ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(children: [
          const MsgLogo(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.helloName(me.firstName), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 13, color: c.textSecondary)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.myRoles.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: c.surfaceCard, borderRadius: BorderRadius.circular(MsgRadius.lg)),
          child: Column(children: [
            if (me.roles.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 18), child: Text(l.noRole, style: TextStyle(color: c.textSecondary))),
            for (final (i, r) in me.roles.indexed)
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: c.borderSubtle))),
                child: Row(children: [
                  Expanded(child: Text(r.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  if (r.endsOn != null)
                    Text(MaterialLocalizations.of(context).formatShortDate(r.endsOn!), style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          key: const Key('logout'),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: Text(l.logout),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder(), foregroundColor: c.primaryText, side: BorderSide(color: c.primary, width: 1.5)),
        ),
      ],
    );
  }
}
