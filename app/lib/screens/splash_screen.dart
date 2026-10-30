import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/group_controller.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/msg_logo.dart';
import 'lock_screen.dart';
import 'login_phone_screen.dart';
import 'sign_out.dart';
import 'pin_screens.dart';
import 'shell_screen.dart';

/// Restores the stored session and routes to the shell or to login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Object? _error;

  /// Retries (network error, group fallback) don't ask the PIN again.
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    final repos = RepositoryLocator.instance;
    await repos.authSession.bootstrap();
    if (!mounted) return;
    if (!repos.authSession.isLoggedIn) {
      _go(const LoginPhoneScreen());
      return;
    }
    // The PIN (or fingerprint) before anything else. A session opened
    // before the lock existed has no PIN to check against: sign in once.
    if (!_unlocked) {
      if (!await repos.authSession.canUnlock) {
        await repos.authSession.clear();
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        _go(const LoginPhoneScreen());
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).unlockSignInAgain),
          ),
        );
        return;
      }
      if (!mounted) return;
      final ok = await LockScreen.show(Navigator.of(context));
      if (ok != true || !mounted) return; // signed out from the lock screen
      _unlocked = true;
    }
    try {
      var me = await repos.profile.fetchMe();
      if (me.pinMustChange && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SetPinScreen(forced: true)),
        );
        me = await repos.profile.fetchMe();
      }
      if (mounted) _go(ShellScreen(me: me));
    } on ApiException catch (e) {
      // A super admin's account works only in the back-office: drop the
      // session, and the login screen says why on the next attempt.
      if (e.code == 'backoffice_only') await repos.authSession.clear();
      // No longer in the remembered group: fall back to the first one.
      if (e.code == 'not_in_group') {
        await GroupController.instance.select(null);
        if (mounted) unawaited(_start());
        return;
      }
      // Opened on another phone since: leave, and say why.
      if (repos.authSession.endedBy == 'other_device' && mounted) {
        final notice = AppLocalizations.of(context).signedOutOtherDevice;
        await leaveSession(Navigator.of(context), notice: notice);
        return;
      }
      // Session no longer valid server-side (refresh failed and cleared).
      if (!repos.authSession.isLoggedIn || e.statusCode == 401) {
        if (mounted) _go(const LoginPhoneScreen());
      } else if (mounted) {
        setState(() => _error = e);
      }
    } on NetworkException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _go(Widget screen) => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(MsgSpace.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const MsgLogo(size: 112),
                    const SizedBox(height: 24),
                    Text(
                      l.appTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.platformTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l.motto.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: _error == null
                  ? Column(
                      children: [
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(999),
                            color: c.primary,
                            backgroundColor: c.surfaceSunken,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.splashPreparing,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          describeError(context, _error!),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _start, child: Text(l.retry)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
