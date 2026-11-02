import 'package:flutter/material.dart';

import '../data/theme_controller.dart';
import '../models/me.dart';
import '../theme/tokens.dart';
import 'store_image.dart';

/// A group's logo, like a Slack workspace's icon (owner, 2026-11-02): the
/// picture its président or the back-office set, else its sigle or
/// initials on the group's colour.
class GroupLogo extends StatelessWidget {
  const GroupLogo({super.key, required this.group, this.size = 40});
  final GroupInfo group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 4);
    final logo = group.logo;
    if (logo != null && logo.isNotEmpty) {
      return Semantics(
        label: group.name,
        image: true,
        child: ClipRRect(
          borderRadius: radius,
          child: Image(
            key: Key('group-logo-${group.id}'),
            image: StoreImage(logo),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _initials(context, radius),
          ),
        ),
      );
    }
    return Semantics(
      label: group.name,
      image: true,
      child: _initials(context, radius),
    );
  }

  Widget _initials(BuildContext context, BorderRadius radius) {
    final bg = ThemeController.parse(group.color) ?? context.msg.primary;
    final text = group.initials.isEmpty ? '?' : group.initials;
    return Container(
      key: Key('group-initials-${group.id}'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * (text.length > 3 ? 0.24 : 0.3),
                letterSpacing: size * 0.01,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
