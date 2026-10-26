import 'package:flutter/material.dart';

import '../data/biometrics.dart';
import '../data/current_user.dart';
import '../data/offline.dart';
import '../data/group_controller.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/msg_logo.dart';
import '../widgets/pin_pad.dart';
import 'login_phone_screen.dart';

/// Asked when the app opens on a saved session, and when it comes back
/// after [lockAfter] in the background (owner, 2026-10-23). The PIN is
/// checked on the phone (AuthSession.checkPin), so it works offline; the
/// fingerprint or face works too when the member turned it on.
/// Pops `true` once unlocked; after too many wrong PINs the session is
/// closed and the member signs in again with their number.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  /// Background time after which the PIN is asked again (tests shorten it).
  static Duration lockAfter = const Duration(minutes: 2);

  /// Shows the lock above everything; true once unlocked (null when the
  /// member signed out from it instead).
  static Future<bool?> show(NavigatorState nav) => nav.push(
    PageRouteBuilder<bool>(
      pageBuilder: (_, _, _) => const LockScreen(),
      transitionDuration: Duration.zero,
    ),
  );

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _bio = false;

  @override
  void initState() {
    super.initState();
    _setUpBiometrics();
  }

  Future<void> _setUpBiometrics() async {
    final on =
        await RepositoryLocator.instance.authSession.biometricEnabled &&
        await Biometrics.instance.available();
    if (!mounted || !on) return;
    setState(() => _bio = true);
    await _biometric(); // straight away: one touch and the app is open
  }

  Future<void> _biometric() async {
    final ok = await Biometrics.instance.authenticate(
      AppLocalizations.of(context).biometricReason,
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  void _digit(String d) {
    if (_busy) return;
    if (_error != null) {
      _pin = '';
      _error = null;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _check();
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    setState(() {
      _pin = _error != null ? '' : _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final left = await RepositoryLocator.instance.authSession.checkPin(_pin);
    if (!mounted) return;
    if (left == null) {
      Navigator.of(context).pop(true);
      return;
    }
    if (left == 0) {
      await _signOut(l.unlockTooMany);
      return;
    }
    setState(() {
      _busy = false;
      _error = l.unlockWrong(left);
    });
  }

  Future<void> _signOut([String? message]) async {
    final repos = RepositoryLocator.instance;
    await repos.authSession.clear();
    await OfflineState.instance.forget();
    await GroupController.instance.select(null);
    currentUser.value = null;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPhoneScreen()),
      (_) => false,
    );
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('lock-screen'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            children: [
              const Center(child: MsgLogo(size: 56)),
              const SizedBox(height: 20),
              Text(
                l.unlockTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                l.unlockSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              PinDots(filled: _pin.length, error: _error != null),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    _error ?? '',
                    key: const Key('unlock-error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.alert, fontSize: 14),
                  ),
                ),
              ),
              PinKeypad(
                onDigit: _digit,
                onDelete: _delete,
                enabled: !_busy,
                onBiometric: _bio ? _biometric : null,
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('unlock-sign-out'),
                onPressed: () => _signOut(),
                child: Text(l.unlockOtherAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
