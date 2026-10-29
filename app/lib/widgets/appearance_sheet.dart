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
                  _CustomSwatch(
                    key: const Key('color-custom'),
                    current: t.myColor,
                    onPicked: (c) => t.choose(c),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // A gradient (owner, 2026-10-29): Accueil's header goes from
              // the main colour to a second one.
              Container(
                key: const Key('color-preview'),
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MsgRadius.md),
                  gradient: LinearGradient(colors: [c.header, c.headerEnd]),
                ),
                child: Text(
                  l.preview,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SwitchListTile(
                key: const Key('gradient-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.gradient),
                subtitle: Text(l.gradientHint),
                value: t.seed2 != null,
                onChanged: (on) => on
                    ? t.choose(t.seed, second: t.seed2 ?? _secondFor(t.seed))
                    : t.choose(t.seed, plain: true),
              ),
              if (t.seed2 != null)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (i, color) in ThemeController.palette.indexed)
                      _Swatch(
                        key: Key('color2-$i'),
                        color: color,
                        label: l.secondColorN(i + 1),
                        selected: t.seed2 == color,
                        onTap: () => t.choose(t.seed, second: color),
                      ),
                    _CustomSwatch(
                      key: const Key('color2-custom'),
                      current: t.seed2,
                      onPicked: (c) => t.choose(t.seed, second: c),
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

/// A second colour that differs from [c]: the next one in the palette.
Color _secondFor(Color c) {
  const p = ThemeController.palette;
  final i = p.indexOf(c);
  return p[(i < 0 ? 1 : i + 2) % p.length];
}

/// "Autre…": any colour, from a hue and a shade.
class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({
    super.key,
    required this.current,
    required this.onPicked,
  });
  final Color? current;
  final ValueChanged<Color> onPicked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final custom =
        current != null && !ThemeController.palette.contains(current);
    return Semantics(
      button: true,
      selected: custom,
      label: l.otherColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () async {
          final picked = await showDialog<Color>(
            context: context,
            builder: (_) => _ColorDialog(initial: current ?? c.primary),
          );
          if (picked != null) onPicked(picked);
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: custom ? current : null,
              gradient: custom
                  ? null
                  : const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Colors.purple,
                        Colors.red,
                      ],
                    ),
              border: Border.all(
                color: custom ? c.textPrimary : Colors.transparent,
                width: 3,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Icon(
              custom ? Icons.check : Icons.add,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDialog extends StatefulWidget {
  const _ColorDialog({required this.initial});
  final Color initial;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late HSLColor _hsl = HSLColor.fromColor(widget.initial);

  // Kept between 20 % and 45 % light: white text stays readable on it.
  Color get _color => _hsl
      .withLightness(_hsl.lightness.clamp(0.2, 0.45))
      .withSaturation(_hsl.saturation.clamp(0.35, 1))
      .toColor();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.otherColor),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('custom-color-preview'),
            height: 56,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(MsgRadius.md),
            ),
          ),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: Text(l.hue)),
          Slider(
            key: const Key('custom-hue'),
            value: _hsl.hue,
            max: 360,
            activeColor: _color,
            onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
          ),
          Align(alignment: Alignment.centerLeft, child: Text(l.shade)),
          Slider(
            key: const Key('custom-shade'),
            value: _hsl.lightness.clamp(0.2, 0.45),
            min: 0.2,
            max: 0.45,
            activeColor: _color,
            onChanged: (v) => setState(() => _hsl = _hsl.withLightness(v)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('custom-color-ok'),
          onPressed: () => Navigator.of(context).pop(_color),
          child: Text(l.choose),
        ),
      ],
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
