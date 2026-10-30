import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/me.dart';
import '../../theme/tokens.dart';
import '../../widgets/errors.dart';
import '../../widgets/pin_pad.dart';
import '../../widgets/ui.dart';

/// The finance code in front of Finances (owner, 2026-10-30): when the group
/// requires it, a second 4-digit code, separate from the PIN, opens the tab
/// for five minutes. Chosen and reset with the PIN.
class FinanceGate extends StatefulWidget {
  const FinanceGate({super.key, required this.me, required this.child});
  final Me me;
  final Widget child;

  static const open = Duration(minutes: 5);
  static DateTime? _openUntil;

  /// Closed again (sign-out, app locked).
  static void lock() => _openUntil = null;

  @override
  State<FinanceGate> createState() => _FinanceGateState();
}

class _FinanceGateState extends State<FinanceGate> {
  late bool _codeSet = widget.me.financeCodeSet;
  bool _choosing = false;
  String _code = '';
  String? _error;
  bool _busy = false;

  bool get _required => widget.me.group?.financeCodeRequired ?? false;

  bool get _isOpen {
    final until = FinanceGate._openUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _opened() => setState(() {
    FinanceGate._openUntil = DateTime.now().add(FinanceGate.open);
  });

  void _digit(String d) {
    if (_busy) return;
    setState(() {
      if (_error != null) {
        _code = '';
        _error = null;
      }
      if (_code.length < 4) _code += d;
    });
    if (_code.length == 4) _check();
  }

  void _delete() {
    if (_busy || _code.isEmpty) return;
    setState(() {
      _code = _error != null ? '' : _code.substring(0, _code.length - 1);
      _error = null;
    });
  }

  Future<void> _check() async {
    final l = AppLocalizations.of(context);
    final repos = RepositoryLocator.instance;
    setState(() => _busy = true);
    try {
      await repos.auth.checkFinanceCode(_code);
      await repos.authSession.rememberFinanceCode(_code);
      if (mounted) _opened();
    } on NetworkException {
      // Offline: the last code the server accepted on this phone.
      final ok = await repos.authSession.checkFinanceCodeLocally(_code);
      if (!mounted) return;
      if (ok == true) {
        _opened();
      } else {
        setState(
          () => _error = ok == null
              ? l.financeCodeOffline
              : l.financeCodeWrong(0),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_required || _isOpen) return widget.child;
    if (!_codeSet || _choosing) {
      return _ChooseCode(
        first: !_codeSet,
        onCancel: _codeSet ? () => setState(() => _choosing = false) : null,
        onSaved: () {
          _codeSet = true;
          _choosing = false;
          _opened();
        },
      );
    }
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return ListView(
      key: const Key('finance-gate'),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      children: [
        Center(child: IconChip(Icons.lock_outline, tone: Tone.amber, size: 56)),
        const SizedBox(height: 16),
        Text(
          l.financeCodeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          l.financeCodeSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: c.textSecondary),
        ),
        const SizedBox(height: 20),
        PinDots(filled: _code.length, error: _error != null),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Center(
            child: Text(
              _error ?? '',
              key: const Key('finance-code-error'),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.alert, fontSize: 14),
            ),
          ),
        ),
        PinKeypad(onDigit: _digit, onDelete: _delete, enabled: !_busy),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('finance-code-forgot'),
          onPressed: () => setState(() => _choosing = true),
          child: Text(l.financeCodeForgot),
        ),
      ],
    );
  }
}

/// Choose (first time) or reset the finance code: PIN, new code twice.
class _ChooseCode extends StatefulWidget {
  const _ChooseCode({
    required this.first,
    required this.onSaved,
    this.onCancel,
  });
  final bool first;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;

  @override
  State<_ChooseCode> createState() => _ChooseCodeState();
}

class _ChooseCodeState extends State<_ChooseCode> {
  final _pin = TextEditingController();
  final _code = TextEditingController();
  final _again = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    _code.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (code.length != 4 || _pin.text.trim().length != 4) {
      setState(() => _error = l.financeCodeFourDigits);
      return;
    }
    if (code != _again.text.trim()) {
      setState(() => _error = l.financeCodeMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final repos = RepositoryLocator.instance;
    try {
      await repos.auth.setFinanceCode(pin: _pin.text.trim(), code: code);
      await repos.authSession.rememberFinanceCode(code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.financeCodeSaved)));
      widget.onSaved();
    } on PinFailure catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController ctl, String label, String key) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: Key(key),
      controller: ctl,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: InputDecoration(labelText: label, counterText: ''),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    return ListView(
      key: const Key('finance-code-choose'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        Text(
          l.financeCodeChooseTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          l.financeCodeChooseBody,
          style: TextStyle(fontSize: 14, color: c.textSecondary),
        ),
        const SizedBox(height: 16),
        _field(_pin, l.financeCodeYourPin, 'fc-pin'),
        _field(_code, l.financeCodeNew, 'fc-code'),
        _field(_again, l.financeCodeConfirm, 'fc-again'),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              key: const Key('fc-error'),
              style: TextStyle(color: c.alert),
            ),
          ),
        FilledButton(
          key: const Key('fc-save'),
          onPressed: _busy ? null : _save,
          child: Text(l.financeCodeSave),
        ),
        if (widget.onCancel != null)
          TextButton(onPressed: widget.onCancel, child: Text(l.cancel)),
      ],
    );
  }
}
