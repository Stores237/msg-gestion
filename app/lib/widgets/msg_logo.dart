import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The movement's mark: "MSG" set in white on the primary green.
/// Stands in until a drawn logo exists; every placement uses this widget,
/// so swapping in an image later is a one-file change.
class MsgLogo extends StatelessWidget {
  const MsgLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Semantics(
      label: 'MSG',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(size > 60 ? 24 : 12)),
        child: ExcludeSemantics(
          child: Text(
            'MSG',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.3, letterSpacing: size * 0.01),
          ),
        ),
      ),
    );
  }
}
