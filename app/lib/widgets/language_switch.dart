import 'package:flutter/material.dart';

import '../data/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

/// FR | EN toggle. Takes effect immediately and is remembered.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return Semantics(
      label: l.language,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (code, label, full) in [('fr', 'FR', l.languageFrench), ('en', 'EN', l.languageEnglish)])
            Semantics(
              button: true,
              selected: current == code,
              label: full,
              child: InkWell(
                key: Key('lang-$code'),
                borderRadius: BorderRadius.circular(999),
                onTap: () => LocaleController.instance.setLanguage(code),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: current == code ? c.surfaceCard : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: ExcludeSemantics(
                    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: current == code ? c.textPrimary : c.textSecondary)),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
