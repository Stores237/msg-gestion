import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/ui.dart';

class _PinField extends StatelessWidget {
  const _PinField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: validator,
        style: const TextStyle(
          fontSize: 22,
          letterSpacing: 8,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          filled: true,
          fillColor: c.surfaceCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MsgRadius.md),
          ),
        ),
      ),
    );
  }
}

/// Choose a new PIN. [forced]: after logging in with a temporary PIN (the
/// back button is hidden — the member must pick their own). [currentPin]
/// is known right after login, so it isn't asked again.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key, this.forced = false, this.currentPin});
  final bool forced;
  final String? currentPin;

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await RepositoryLocator.instance.auth.changePin(
        currentPin: widget.currentPin ?? _current.text,
        newPin: _new.text,
      );
      await RepositoryLocator.instance.authSession.rememberPin(_new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.pinChanged)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    String? four(String? v) => (v ?? '').length == 4 ? null : l.pinFourDigits;
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: widget.forced ? l.choosePinTitle : l.changePin,
                back: !widget.forced,
                small: true,
              ),
              Expanded(
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (widget.forced)
                        Text(
                          l.choosePinForced,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: c.textSecondary,
                          ),
                        ),
                      if (widget.currentPin == null)
                        _PinField(
                          key: const Key('pin-current'),
                          controller: _current,
                          label: l.currentPin,
                          validator: four,
                        ),
                      _PinField(
                        key: const Key('pin-new'),
                        controller: _new,
                        label: l.newPin,
                        validator: four,
                      ),
                      _PinField(
                        key: const Key('pin-confirm'),
                        controller: _confirm,
                        label: l.confirmPin,
                        validator: (v) =>
                            four(v) ?? (v == _new.text ? null : l.pinMismatch),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          key: const Key('pin-error'),
                          style: TextStyle(
                            color: c.alert,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('pin-save'),
                        onPressed: _busy ? null : _save,
                        child: Text(l.save),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Code oublié ?": text a code, then code + new PIN. Until SMS exists the
/// server answers sms_unavailable and the member is told to ask the secretary.
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({
    super.key,
    required this.phone,
    required this.acceptedTerms,
  });
  final String phone;

  /// The conditions version ticked on the login screen.
  final int acceptedTerms;

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on UnknownMember catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } catch (e) {
      if (mounted) setState(() => _error = describeError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    await RepositoryLocator.instance.auth.forgotPin(widget.phone);
    if (mounted) setState(() => _sent = true);
  });

  Future<void> _confirmPin() async {
    if (!_form.currentState!.validate()) return;
    await _run(() async {
      await RepositoryLocator.instance.auth.forgotPinConfirm(
        phone: widget.phone,
        code: _code.text.trim(),
        newPin: _new.text,
        acceptedTerms: widget.acceptedTerms,
      );
      // The lock screen checks this PIN from now on.
      await RepositoryLocator.instance.authSession.rememberPin(_new.text);
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    String? four(String? v) => (v ?? '').length == 4 ? null : l.pinFourDigits;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: l.forgotTitle, back: true, small: true),
            Expanded(
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      '${l.forgotIntro}\n${widget.phone}',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: c.textSecondary,
                      ),
                    ),
                    if (_sent) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          key: const Key('forgot-code'),
                          controller: _code,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: l.smsCode,
                            counterText: '',
                            filled: true,
                            fillColor: c.surfaceCard,
                          ),
                          validator: (v) =>
                              (v ?? '').length == 6 ? null : l.required,
                        ),
                      ),
                      _PinField(
                        key: const Key('forgot-new'),
                        controller: _new,
                        label: l.newPin,
                        validator: four,
                      ),
                      _PinField(
                        key: const Key('forgot-confirm'),
                        controller: _confirm,
                        label: l.confirmPin,
                        validator: (v) =>
                            four(v) ?? (v == _new.text ? null : l.pinMismatch),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        key: const Key('forgot-error'),
                        style: TextStyle(
                          color: c.alert,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('forgot-submit'),
                      onPressed: _busy ? null : (_sent ? _confirmPin : _send),
                      child: Text(_sent ? l.save : l.sendCode),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
