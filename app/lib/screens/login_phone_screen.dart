import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/errors.dart';
import '../widgets/language_switch.dart';
import '../widgets/msg_logo.dart';
import '../widgets/notice.dart';
import 'login_pin_screen.dart';

/// Login step 1 (design: "Connexion · numéro"). The server normalises the
/// number; the client only rejects input that can't possibly be one.
class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _plausible(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final raw = _controller.text.trim();
    if (!_plausible(raw)) {
      setState(() => _error = l.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final lookup = await RepositoryLocator.instance.auth.lookupPhone(raw);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LoginPinScreen(lookup: lookup)));
    } on UnknownMember catch (e) {
      setState(() => _error = describeError(context, e));
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          children: [
            const Row(
              children: [MsgLogo(size: 64), Spacer(), LanguageSwitch()],
            ),
            const SizedBox(height: 24),
            Text(
              l.welcome,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              l.loginIntro,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.phoneLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('phone-field'),
              controller: _controller,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d +]')),
              ],
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '6 XX XX XX XX',
                filled: true,
                fillColor: c.surfaceCard,
                errorText: _error,
                errorMaxLines: 3,
                helperText: _error == null ? l.phoneHint : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MsgRadius.md),
                  borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MsgRadius.md),
                  borderSide: BorderSide(color: c.borderSubtle, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MsgRadius.md),
                  borderSide: BorderSide(color: c.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('phone-continue'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(l.continueButton),
            ),
            const SizedBox(height: 24),
            Notice(text: l.noAccountNotice),
          ],
        ),
      ),
    );
  }
}
