// Accueil's dark band, the app colour (group's or the member's own) and
// header buttons pinned to the right.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/data/theme_controller.dart';
import 'package:msg_gestion/theme/tokens.dart';
import 'package:msg_gestion/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'helpers.dart';

Color _primary(WidgetTester tester) => Theme.of(
  tester.element(find.byKey(const Key('home-header'))),
).extension<MsgColors>()!.primary;

void main() {
  testWidgets('Accueil header: greeting, role chip, FR/EN, gear, bell', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        roles: const [
          {'slug': 'president', 'name': 'Président', 'kind': 'bureau'},
        ],
      ),
    );
    expect(find.byKey(const Key('home-name')), findsOneWidget);
    expect(find.text('PRÉSIDENT'), findsOneWidget);
    expect(find.byKey(const Key('lang-en')), findsOneWidget);
    expect(find.byKey(const Key('bell')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();
    expect(find.text('PRESIDENT'), findsOneWidget);
  });

  testWidgets('the group colour, then the member’s own, colour the app', (
    tester,
  ) async {
    await setUpApp(tester);
    final me = fakeMe(
      groups: const [
        {'id': 1, 'name': 'Chorale', 'color': '#1E5AA8'},
      ],
    );
    await pumpShell(tester, me);
    expect(_primary(tester), const Color(0xFF1E5AA8));

    await tester.tap(find.byKey(const Key('open-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('color-5')));
    await tester.pumpAndSettle();
    expect(_primary(tester), ThemeController.palette[5]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('msg_color'), ThemeController.palette[5].toARGB32());

    await tester.tap(find.byKey(const Key('color-group')));
    await tester.pumpAndSettle();
    expect(_primary(tester), const Color(0xFF1E5AA8));
    expect(prefs.getInt('msg_color'), isNull);
  });

  for (final width in [320.0, 411.0]) {
    testWidgets('header buttons sit at the right edge (${width.toInt()}dp)', (
      tester,
    ) async {
      await setUpApp(tester);
      await pumpShell(
        tester,
        fakeMe(
          tabs: const ['accueil', 'finances'],
          permissions: const {
            'finances.cashbook': ['view', 'export'],
          },
        ),
      );
      tester.view.physicalSize = Size(width * 3, 2400);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-finances')));
      await tester.pumpAndSettle();
      final buttons = find.descendant(
        of: find.byType(ScreenHeader),
        matching: find.byType(IconButton),
      );
      expect(buttons, findsNWidgets(3)); // ⚙, statement and PDF
      final right = tester.getRect(buttons.last).right;
      expect(width - right, lessThan(24), reason: 'right edge at $right');
    });
  }

  testWidgets('gradient: the group’s second colour, then the member’s own', (
    tester,
  ) async {
    await setUpApp(tester);
    await pumpShell(
      tester,
      fakeMe(
        groups: const [
          {'id': 1, 'name': 'Chorale', 'color': '#1E5AA8', 'color2': '#8E1B3A'},
        ],
      ),
    );
    MsgColors colors() => Theme.of(
      tester.element(find.byKey(const Key('home-header'))),
    ).extension<MsgColors>()!;
    BoxDecoration header() =>
        tester
                .widget<Container>(find.byKey(const Key('home-header')))
                .decoration!
            as BoxDecoration;
    expect(header().gradient, isNotNull);
    expect(colors().headerEnd, isNot(colors().header));

    await tester.tap(find.byKey(const Key('open-appearance')));
    await tester.pumpAndSettle();
    // Plain: no gradient.
    await tester.tap(find.byKey(const Key('gradient-switch')));
    await tester.pumpAndSettle();
    expect(ThemeController.instance.seed2, isNull);
    expect(colors().headerEnd, colors().header);
    // Gradient again, with a second colour from the palette.
    await tester.tap(find.byKey(const Key('gradient-switch')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('color2-6')));
    await tester.tap(find.byKey(const Key('color2-6')));
    await tester.pumpAndSettle();
    expect(ThemeController.instance.seed2, ThemeController.palette[6]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('msg_color2'), ThemeController.palette[6].toARGB32());
  });

  testWidgets('Autre couleur: any colour from hue and shade', (tester) async {
    await setUpApp(tester);
    await pumpShell(tester, fakeMe());
    await tester.tap(find.byKey(const Key('open-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('color-custom')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('custom-hue')), const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('custom-color-ok')));
    await tester.pumpAndSettle();
    final mine = ThemeController.instance.myColor!;
    expect(ThemeController.palette, isNot(contains(mine)));
    expect(_primary(tester), mine);
    // Dark enough for white text.
    expect(HSLColor.fromColor(mine).lightness, lessThanOrEqualTo(0.451));
  });
}
