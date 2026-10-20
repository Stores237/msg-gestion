import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum NoticeTone { info, ok, warn, alert }

/// Inline notice block (design: .notice). Always icon + text, never colour alone.
class Notice extends StatelessWidget {
  const Notice({super.key, required this.text, this.tone = NoticeTone.info});

  final String text;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    final (bg, fg, icon) = switch (tone) {
      NoticeTone.info => (c.surfaceSunken, c.textSecondary, Icons.info_outline),
      NoticeTone.ok => (c.primaryTint, c.primaryText, Icons.check_circle_outline),
      NoticeTone.warn => (c.warnTint, c.warnText, Icons.warning_amber_rounded),
      NoticeTone.alert => (c.alertTint, c.alert, Icons.error_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MsgRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: c.textPrimary))),
        ],
      ),
    );
  }
}
