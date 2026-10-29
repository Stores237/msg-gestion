import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'appearance_sheet.dart';
import 'language_switch.dart';
import 'notification_bell.dart';
import 'ui.dart';

/// The dark band at the top of Accueil (owner's reference, 2026-10-23):
/// avatar and greeting, FR/EN, Apparence and the bell, the member's role
/// as a gold chip, and a row of diamonds. Its colour follows the app's.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.firstName,
    required this.fullName,
    required this.role,
    required this.onOpenAccount,
    this.photo,
  });

  final String? photo;

  final String firstName;
  final String fullName;
  final String role;
  final VoidCallback onOpenAccount;

  static const gold = Color(0xFFD6A84A);
  static const clay = Color(0xFFD9774F);

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.goodMorning;
    if (h < 18) return l.goodAfternoon;
    return l.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.msg;
    final gear = IconButton(
      key: const Key('open-appearance'),
      tooltip: l.appearance,
      style: onDarkButton,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => showAppearanceSheet(context),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        key: const Key('home-header'),
        decoration: BoxDecoration(
          color: c.header,
          // The group's or the member's second colour (owner, 2026-10-29).
          gradient: c.headerEnd == c.header
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.header, c.headerEnd],
                ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
        child: LayoutBuilder(
          builder: (context, box) {
            // On a narrow phone FR/EN moves down next to the role chip so
            // the first name keeps its room.
            final roomy = box.maxWidth >= 380;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: l.openAccount,
                      child: InkWell(
                        key: const Key('open-account'),
                        customBorder: const CircleBorder(),
                        onTap: onOpenAccount,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: MemberAvatar(
                            name: fullName,
                            photo: photo,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(l),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: gold.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            firstName,
                            key: const Key('home-name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (roomy) ...[
                      const LanguageSwitch(onDark: true),
                      const SizedBox(width: 6),
                    ],
                    gear,
                    const SizedBox(width: 6),
                    const NotificationBell(onDark: true),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        key: const Key('role-chip'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF241C0E),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                role.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF241C0E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!roomy) ...[
                      const SizedBox(width: 8),
                      const LanguageSwitch(onDark: true),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const ExcludeSemantics(child: DiamondRow()),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A row of outlined diamonds with a dot inside, gold and clay in turn,
/// filling the width.
class DiamondRow extends StatelessWidget {
  const DiamondRow({super.key, this.height = 14});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _Diamonds()),
  );
}

class _Diamonds extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const w = 22.0, gap = 10.0;
    final h = size.height;
    final n = ((size.width + gap) / (w + gap)).floor();
    if (n <= 0) return;
    // Spread the leftover space so the row ends flush on both sides.
    final step = n > 1 ? (size.width - w) / (n - 1) : 0.0;
    for (var i = 0; i < n; i++) {
      final color = i.isEven ? HomeHeader.gold : HomeHeader.clay;
      final cx = w / 2 + i * step, cy = h / 2;
      final path = Path()
        ..moveTo(cx - w / 2, cy)
        ..lineTo(cx, cy - h / 2)
        ..lineTo(cx + w / 2, cy)
        ..lineTo(cx, cy + h / 2)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_Diamonds old) => false;
}
