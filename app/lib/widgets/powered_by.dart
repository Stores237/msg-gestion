import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// The developer's mark: "S" for STORES, in the text colour rather than
/// the group's colour (so it never reads as part of a group's identity, and
/// inverts in dark mode). Every
/// placement uses this widget: a drawn logo later is a one-file change.
class StoresLogo extends StatelessWidget {
  const StoresLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.msg;
    return Semantics(
      label: 'STORES',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: ExcludeSemantics(
          child: Text(
            'S',
            style: TextStyle(
              color: c.surfaceCard,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.62,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Propulsé par STORES" and "Version 0.1.0 (18)": the app's signature
/// and version, from the build itself (pubspec `version`, see RELEASING.md).
class PoweredBy extends StatelessWidget {
  const PoweredBy({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final small = TextStyle(fontSize: 12, color: c.textSecondary);
    return Column(
      key: const Key('powered-by'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.poweredBy, style: small),
            const SizedBox(width: 6),
            const StoresLogo(size: 18),
            const SizedBox(width: 4),
            Text(
              'STORES',
              style: small.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) {
            final p = snap.data;
            if (p == null) return const SizedBox(height: 16);
            return Text(
              l.appVersion(p.version, p.buildNumber),
              key: const Key('app-version'),
              style: small.copyWith(fontFeatures: tabular),
            );
          },
        ),
      ],
    );
  }
}
