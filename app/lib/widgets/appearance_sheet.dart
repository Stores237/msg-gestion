import 'package:flutter/material.dart';

import '../data/theme_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'language_switch.dart';
import 'ui.dart';

/// Apparence (gear on Accueil, or Mon compte): language and the app's
/// colour for this phone.
Future<void> showAppearanceSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const _AppearanceSheet(),
);

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final t = ThemeController.instance;
    return ListenableBuilder(
      listenable: t,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.appearance, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.language,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const LanguageSwitch(),
                ],
              ),
              const SizedBox(height: 24),
              SectionLabel(l.appColor),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Swatch(
                    key: const Key('color-group'),
                    color: t.groupColor ?? ThemeController.fallback,
                    label: l.groupColorChoice,
                    selected: t.myColor == null,
                    onTap: () => t.choose(null),
                    wide: true,
                  ),
                  for (final (i, color) in ThemeController.palette.indexed)
                    _Swatch(
                      key: Key('color-$i'),
                      color: color,
                      label: l.colorN(i + 1),
                      selected: t.myColor == color,
                      onTap: () => t.choose(color),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l.appColorHint,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// "Couleur du groupe" shows its name next to the dot.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final dot = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.textPrimary : Colors.transparent,
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 22)
          : null,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ExcludeSemantics(
            child: wide
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      dot,
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : dot,
          ),
        ),
      ),
    );
  }
}
