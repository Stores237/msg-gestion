import 'package:flutter/material.dart';

/// Huddle, the platform (owner, 2026-11-02): the app's own mark, like
/// Slack's. Drawn from design/brand/huddle-mark.svg (170 × 170 units): a
/// dark bar, a green arch over it, an orange dot. A group's own logo is
/// [GroupLogo], shown once inside the group.
class HuddleMark extends StatelessWidget {
  const HuddleMark({super.key, this.size = 40, this.onDark});
  final double size;

  /// On a dark background the bar turns white (like Slack's light
  /// variant); by default it follows the theme.
  final bool? onDark;

  static const dark = Color(0xFF1B1D24);
  static const green = Color(0xFF0E9F8F);
  static const orange = Color(0xFFE8553D);

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Huddle',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(dark ? Colors.white : HuddleMark.dark),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.bar);
  final Color bar;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 170);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(45.5, 27.5),
      const Offset(45.5, 147.5),
      stroke..color = bar,
    );
    final arch = Path()
      ..moveTo(45.5, 102)
      ..arcToPoint(
        const Offset(124.5, 102),
        radius: const Radius.circular(39.5),
      )
      ..lineTo(124.5, 147.5);
    canvas.drawPath(arch, stroke..color = HuddleMark.green);
    canvas.drawCircle(
      const Offset(123.5, 29.5),
      20.5,
      Paint()..color = HuddleMark.orange,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.bar != bar;
}

/// The mark and "huddle" in lowercase, as on the brand sheet.
class HuddleWordmark extends StatelessWidget {
  const HuddleWordmark({super.key, this.size = 40, this.onDark});
  final double size;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HuddleMark(size: size, onDark: dark),
        SizedBox(width: size * 0.18),
        ExcludeSemantics(
          child: Text(
            'huddle',
            style: TextStyle(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: -size * 0.012,
              height: 1,
              color: dark ? Colors.white : HuddleMark.dark,
            ),
          ),
        ),
      ],
    );
  }
}
