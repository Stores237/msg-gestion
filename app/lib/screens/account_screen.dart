import 'package:flutter/material.dart';

import '../data/current_user.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/labels.dart';
import '../widgets/language_switch.dart';
import '../widgets/ui.dart';
import 'login_phone_screen.dart';
import 'pin_screens.dart';

/// "Mon compte" (opened from the avatar on Accueil): roles, language, sign-out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.me});
  final Me me;

  Future<void> _logout(BuildContext context) async {
    await RepositoryLocator.instance.auth.logout();
    currentUser.value = null;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPhoneScreen()),
      (_) => false,
    );
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
            ScreenHeader(title: l.myAccount, back: true, small: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      MemberAvatar(
                        name: me.fullName,
                        status: me.status,
                        diaspora: me.isDiaspora,
                        size: 64,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          me.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionLabel(l.myRoles),
                  const SizedBox(height: 8),
                  GroupCard(
                    children: [
                      if (me.roles.isEmpty)
                        ListRow(
                          title: Text(
                            l.noRole,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ),
                      for (final r in me.roles)
                        ListRow(
                          title: Text(roleLabel(l, r.slug, r.name)),
                          subtitle: r.endsOn == null
                              ? null
                              : Text(l.mandateUntil(d.shortDate(r.endsOn!))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GroupCard(
                    children: [
                      ListRow(
                        title: Text(l.language),
                        trailing: const LanguageSwitch(),
                      ),
                      ListRow(
                        key: const Key('change-pin'),
                        lead: const Icon(Icons.pin_outlined),
                        title: Text(l.changePin),
                        chevron: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SetPinScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('logout'),
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: Text(l.logout),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      foregroundColor: c.primaryText,
                      side: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
