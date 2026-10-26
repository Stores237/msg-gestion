import 'package:flutter/material.dart';

import '../data/biometrics.dart';
import '../data/current_user.dart';
import '../data/offline.dart';
import '../data/group_controller.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import '../widgets/dates.dart';
import '../widgets/labels.dart';
import '../widgets/language_switch.dart';
import '../widgets/appearance_sheet.dart';
import '../widgets/my_photo.dart';
import '../widgets/ui.dart';
import 'help_screens.dart';
import 'login_phone_screen.dart';
import 'pin_screens.dart';

/// "Mon compte" (opened from the avatar on Accueil): roles, language, sign-out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.me});
  final Me me;

  Future<void> _logout(BuildContext context) async {
    final pending = OfflineState.instance.pending;
    if (pending > 0) {
      // Signing out erases what waits on the phone (it is this member's).
      final l = AppLocalizations.of(context);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(l.logoutPending(pending)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel),
            ),
            TextButton(
              key: const Key('logout-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.logout),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await RepositoryLocator.instance.auth.logout();
    await OfflineState.instance.forget();
    await GroupController.instance.select(null);
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
                      // Tap to change: the member's own picture.
                      Semantics(
                        button: true,
                        label: l.myPhoto,
                        child: InkWell(
                          key: const Key('my-photo'),
                          customBorder: const CircleBorder(),
                          onTap: () => changeMyPhoto(context),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: currentUser,
                                builder: (context, cur, _) => MemberAvatar(
                                  name: me.fullName,
                                  status: me.status,
                                  diaspora: me.isDiaspora,
                                  photo: (cur ?? me).photo,
                                  size: 72,
                                ),
                              ),
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.surfaceBg,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        key: const Key('change-photo'),
                        lead: const Icon(Icons.account_circle_outlined),
                        title: Text(l.myPhoto),
                        chevron: true,
                        onTap: () => changeMyPhoto(context),
                      ),
                      ListRow(
                        key: const Key('open-appearance-account'),
                        lead: const Icon(Icons.palette_outlined),
                        title: Text(l.appearance),
                        chevron: true,
                        onTap: () => showAppearanceSheet(context),
                      ),
                      const _BiometricRow(),
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
                  const HelpAboutSection(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('logout'),
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: Text(l.logout),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                      foregroundColor: c.alert,
                      side: BorderSide(color: c.alert, width: 1.5),
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

/// "Déverrouiller avec l’empreinte ou le visage": shown when the phone has
/// one enrolled; turning it on asks for it once, to be sure it works.
class _BiometricRow extends StatefulWidget {
  const _BiometricRow();

  @override
  State<_BiometricRow> createState() => _BiometricRowState();
}

class _BiometricRowState extends State<_BiometricRow> {
  bool? _available;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await Biometrics.instance.available();
    final on = await RepositoryLocator.instance.authSession.biometricEnabled;
    if (!mounted) return;
    setState(() {
      _available = available;
      _on = on;
    });
  }

  Future<void> _toggle(bool want) async {
    final l = AppLocalizations.of(context);
    if (want && !await Biometrics.instance.authenticate(l.biometricReason)) {
      return;
    }
    await RepositoryLocator.instance.authSession.setBiometric(want);
    if (mounted) setState(() => _on = want);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_available == null) return const SizedBox.shrink();
    return ListRow(
      key: const Key('biometric-row'),
      lead: const Icon(Icons.fingerprint),
      title: Text(l.biometricUnlock),
      subtitle: Text(_available! ? l.biometricHint : l.biometricUnavailable),
      trailing: Switch(
        key: const Key('biometric-switch'),
        value: _on && _available!,
        onChanged: _available! ? _toggle : null,
      ),
    );
  }
}
