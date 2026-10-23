import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Four dots; red when the last attempt was wrong (design: .pin.err).
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.error = false});

  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Semantics(
      label: '$filled chiffre${filled > 1 ? 's' : ''} sur 4',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              key: ValueKey('pin-dot-$i'),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? (error ? c.alert : c.textPrimary) : null,
                border: i < filled
                    ? null
                    : Border.all(color: c.borderStrong, width: 2),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3×4 keypad, 60 dp keys. The fingerprint key works when [onBiometric] is
/// given (lock screen, biometric unlock turned on); otherwise it is shown
/// disabled so the layout matches the design.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
    this.onBiometric,
  });

  final VoidCallback? onBiometric;

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget key(String d) =>
        _Key(label: d, onTap: enabled ? () => onDigit(d) : null);
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [for (final d in row) Expanded(child: key(d))],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _Key(
                key: const Key('key-fingerprint'),
                icon: Icons.fingerprint,
                semantic: l.keypadFingerprint,
                ghost: true,
                onTap: enabled ? onBiometric : null,
              ),
            ),
            Expanded(child: key('0')),
            Expanded(
              child: _Key(
                icon: Icons.backspace_outlined,
                semantic: l.keypadDelete,
                ghost: true,
                onTap: enabled ? onDelete : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    this.label,
    this.icon,
    this.semantic,
    this.ghost = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final String? semantic;
  final bool ghost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        button: true,
        label: semantic ?? label,
        child: Material(
          color: ghost ? Colors.transparent : c.surfaceCard,
          elevation: ghost ? 0 : 0.5,
          borderRadius: BorderRadius.circular(MsgRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(MsgRadius.md),
            onTap: onTap,
            child: SizedBox(
              height: 60,
              child: Center(
                child: label != null
                    ? Text(
                        label!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          fontFeatures: tabular,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 24,
                        color: onTap == null ? c.textTertiary : c.textPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
