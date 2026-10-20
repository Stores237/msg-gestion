import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

const _narrowNbsp = ' ';

/// 186500 → "186 500" (narrow no-break space, as in the design).
String groupDigits(int n) => n.abs().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => _narrowNbsp,
);

/// "186 500 FCFA", with "+ " / "− " when [sign].
String fcfa(int n, {bool sign = false}) {
  final prefix = sign ? (n < 0 ? '− ' : '+ ') : (n < 0 ? '− ' : '');
  return '$prefix${groupDigits(n)} FCFA';
}

/// Amount with the currency smaller and greyer (design: Amt).
class Amount extends StatelessWidget {
  const Amount(
    this.value, {
    super.key,
    this.sign = false,
    this.size = 15,
    this.weight = FontWeight.w700,
    this.color,
  });
  final int value;
  final bool sign;
  final double size;
  final FontWeight weight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final prefix = sign ? (value < 0 ? '− ' : '+ ') : (value < 0 ? '− ' : '');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$prefix${groupDigits(value)}'),
          TextSpan(
            text: ' FCFA',
            style: TextStyle(
              fontSize: size * 0.78,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
      maxLines: 1,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? c.textPrimary,
        fontFeatures: tabular,
      ),
    );
  }
}
