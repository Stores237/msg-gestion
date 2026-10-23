import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/pin_pad.dart';
import 'pin_screens.dart';
import 'shell_screen.dart';

/// Login step 2 (design: "Connexion · code PIN"). Submits on the 4th digit.
/// The server counts the attempts and locks the account; this screen only
/// shows what the server said.
class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({super.key, required this.lookup});

  final PhoneLookup lookup;

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  String _pin = '';
  String? _error;
  bool _locked = false;
  bool _busy = false;

  void _digit(String d) {
    if (_busy || _locked) return;
    // After a wrong PIN the four red dots stay visible until the next key,
    // which starts a fresh attempt.
    if (_error != null) {
      _pin = '';
      _error = null;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _submit();
  }

  void _delete() {
    if (_busy || _pin.isEmpty) return;
    setState(() {
      _pin = _error != null ? '' : _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final repos = RepositoryLocator.instance;
    try {
      final mustChange = await repos.auth.loginWithPin(
        phone: widget.lookup.phone,
        pin: _pin,
      );
      // The lock screen checks this PIN when the app reopens.
      if (!mustChange) await repos.authSession.rememberPin(_pin);
      if (mustChange && mounted) {
        // Temporary PIN from the secretary: pick a personal one first.
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SetPinScreen(forced: true, currentPin: _pin),
          ),
        );
      }
      final me = await repos.profile.fetchMe();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ShellScreen(me: me)),
        (_) => false,
      );
    } on AccountLocked catch (e) {
      setState(() {
        _error = describeError(context, e);
        _locked = true;
      });
    } on PinFailure catch (e) {
      setState(() => _error = describeError(context, e));
    } catch (e) {
      // Network or server failure: not the member's fault, keep nothing.
      setState(() => _pin = '');
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.back,
                  iconSize: 22,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  widget.lookup.phone,
                  style: TextStyle(fontSize: 14, color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l.pinTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l.pinGreeting(widget.lookup.firstName),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            PinDots(filled: _pin.length, error: _error != null),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: _error == null
                  ? (_busy
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : null)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 14, color: c.alert),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _error!,
                            key: const Key('pin-error'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.alert,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            PinKeypad(
              onDigit: _digit,
              onDelete: _delete,
              enabled: !_busy && !_locked,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('forgot-pin'),
              onPressed: () async {
                final done = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ForgotPinScreen(phone: widget.lookup.phone),
                  ),
                );
                if (done != true || !context.mounted) return;
                final me = await RepositoryLocator.instance.profile.fetchMe();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => ShellScreen(me: me)),
                  (_) => false,
                );
              },
              child: Text(l.pinForgot),
            ),
          ],
        ),
      ),
    );
  }
}
