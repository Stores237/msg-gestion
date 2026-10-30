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

  @visibleForTesting
  static void debugReset() {
    _openUntil = null;
    _askedLatest = null;
  }

  /// What the server said last (the back-office switch and the member's own
  /// may change while the app is open).
  static bool? _askedLatest;

  /// Finance figures may show (Accueil): no code needed, or opened lately.
  static bool showsFigures(Me me) {
    if (!(_askedLatest ?? me.financeCodeAsked)) return true;
    final until = _openUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  @override
  State<FinanceGate> createState() => _FinanceGateState();
}

class _FinanceGateState extends State<FinanceGate> {
  late Me _me = widget.me;
  late bool _codeSet = widget.me.financeCodeSet;
  bool _choosing = false;
  String _code = '';
  String? _error;
  bool _busy = false;

  /// Re-reading the settings when Finances opens: switched on in the
  /// back-office a minute ago must count now, not at the next app start.
  bool _checking = true;

  bool get _required => _me.financeCodeAsked;

  @override
  void initState() {
    super.initState();
    if (_isOpen) {
      _checking = false;
      return;
    }
    RepositoryLocator.instance.profile
        .fetchMe()
        .then((me) {
          FinanceGate._askedLatest = me.financeCodeAsked;
          if (mounted) {
            setState(() {
              _me = me;
              _codeSet = me.financeCodeSet;
              _checking = false;
            });
          }
        })
        .catchError((Object _) {
          // Offline: what the app knew when it started.
          if (mounted) setState(() => _checking = false);
        });
  }

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
    if (_isOpen) return widget.child;
    if (_checking) return const Center(child: CircularProgressIndicator());
    if (!_required) return widget.child;
    if (!_codeSet || _choosing) {
      return FinanceCodeForm(
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
class FinanceCodeForm extends StatefulWidget {
  const FinanceCodeForm({
    super.key,
    required this.first,
    required this.onSaved,
    this.onCancel,
  });
  final bool first;
  final VoidCallback onSaved;
  final VoidCallback? onCancel;

  @override
  State<FinanceCodeForm> createState() => _FinanceCodeFormState();
}

class _FinanceCodeFormState extends State<FinanceCodeForm> {
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

/// Finances → ⚙ (owner, 2026-10-30): change one's finance code, and ask for
/// it on one's own Finances even when the group doesn't require it.
class FinanceSettingsScreen extends StatefulWidget {
  const FinanceSettingsScreen({super.key, required this.me});
  final Me me;

  @override
  State<FinanceSettingsScreen> createState() => _FinanceSettingsScreenState();
}

class _FinanceSettingsScreenState extends State<FinanceSettingsScreen> {
  late Me _me = widget.me;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final me = await RepositoryLocator.instance.profile.fetchMe();
      FinanceGate._askedLatest = me.financeCodeAsked;
      if (mounted) setState(() => _me = me);
    } catch (_) {
      // Offline: the settings as last known.
    }
  }

  Future<bool> _chooseCode() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ScreenHeader(
                  title: AppLocalizations.of(context).financeCodeChooseTitle,
                  back: true,
                  small: true,
                ),
                Expanded(
                  child: FinanceCodeForm(
                    first: !_me.financeCodeSet,
                    onSaved: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (done == true) {
      // The member just typed it: Finances stays open.
      FinanceGate._openUntil = DateTime.now().add(FinanceGate.open);
      await _refresh();
    }
    return done == true;
  }

  Future<void> _switch(bool on) async {
    final l = AppLocalizations.of(context);
    final auth = RepositoryLocator.instance.auth;
    if (on && !_me.financeCodeSet && !await _chooseCode()) return;
    if (!mounted) return;
    var code = '';
    if (!on) {
      final typed = await showDialog<String>(
        context: context,
        builder: (_) => const _CodeDialog(),
      );
      if (typed == null || !mounted) return;
      code = typed;
    }
    setState(() => _busy = true);
    try {
      await auth.switchFinanceCode(on: on, code: code);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(on ? l.financeCodeTurnedOn : l.financeCodeTurnedOff),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final forced = _me.group?.financeCodeRequired ?? false;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: l.financeSettingsTitle,
              back: true,
              small: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  GroupCard(
                    children: [
                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
                          key: const Key('finance-code-switch'),
                          contentPadding: EdgeInsets.zero,
                          value: forced || _me.financeCodeOn,
                          onChanged: forced || _busy ? null : _switch,
                          title: Text(l.financeCodeAskTitle),
                          subtitle: Text(
                            forced ? l.financeCodeForced : l.financeCodeAskHint,
                          ),
                        ),
                      ),
                      ListRow(
                        key: const Key('finance-code-change'),
                        lead: const IconChip(
                          Icons.password,
                          tone: Tone.neutral,
                        ),
                        title: Text(
                          _me.financeCodeSet
                              ? l.financeCodeChange
                              : l.financeCodeChooseTitle,
                        ),
                        subtitle: Text(l.financeCodeChangeHint),
                        chevron: true,
                        onTap: _busy ? null : _chooseCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.financeCodeAbout,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
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

/// The current finance code, to turn it off.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.financeCodeTurnOffTitle),
      content: TextField(
        key: const Key('finance-code-current'),
        controller: _code,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: InputDecoration(
          labelText: l.financeCodeTitle,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('finance-code-current-ok'),
          onPressed: () => Navigator.of(context).pop(_code.text.trim()),
          child: Text(l.confirm),
        ),
      ],
    );
  }
}
