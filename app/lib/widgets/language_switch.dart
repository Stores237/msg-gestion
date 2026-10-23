import 'package:flutter/material.dart';

import '../data/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';

/// FR | EN toggle. Takes effect immediately and is remembered.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  /// On the dark band of Accueil.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final l = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return Semantics(
      label: l.language,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onDark
              ? Colors.white.withValues(alpha: 0.12)
              : c.surfaceSunken,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (code, label, full) in [
              ('fr', 'FR', l.languageFrench),
              ('en', 'EN', l.languageEnglish),
            ])
              Semantics(
                button: true,
                selected: current == code,
                label: full,
                child: InkWell(
                  key: Key('lang-$code'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => LocaleController.instance.setLanguage(code),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 36,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: current == code
                          ? (onDark ? Colors.white : c.surfaceCard)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: current == code
                              ? (onDark ? c.header : c.textPrimary)
                              : (onDark ? Colors.white : c.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
