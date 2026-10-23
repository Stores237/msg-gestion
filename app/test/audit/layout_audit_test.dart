// Layout audit: every main screen at phone widths, with normal and large
// text, in French and English. Any overflow fails the test and is listed
// with the screen it happened on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/shell_screen.dart';

import '../fakes.dart';
import '../helpers.dart';

const _all = {
  'members.profile': ['view', 'create', 'change'],
  'members.minor_contacts': ['view'],
  'finances.cashbook': ['view', 'create', 'change', 'delete', 'export'],
  'finances.solidarity': ['view', 'create', 'change', 'export'],
  'finances.report': ['view', 'export'],
  'calendar.events': ['view', 'create', 'change'],
  'calendar.attendance': ['view', 'change'],
  'calendar.planning': ['view', 'create', 'change'],
  'announcements.posts': ['view', 'create', 'change'],
};

void main() {
  for (final lang in ['fr', 'en']) {
    for (final width in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('layout $lang ${width.toInt()}dp ×$scale', (tester) async {
          final problems = <String>[];
          var step = 'start';
          final previous = FlutterError.onError;
          FlutterError.onError = (d) {
            final text = d.exceptionAsString().split('\n').first;
            final lines = d.toDiagnosticsNode().toStringDeep().split('\n');
            final i = lines.indexWhere((l) => l.contains('creator:'));
            final where = i < 0
                ? ''
                : lines
                      .sublist(i, (i + 6).clamp(0, lines.length))
                      .join(' ')
                      .replaceAll(RegExp(r'\s+'), ' ');
            problems.add(
              '[$step] $text :: ${where.length > 900 ? where.substring(0, 900) : where}',
            );
          };
          try {
            await setUpApp(tester);
            tester.platformDispatcher.localesTestValue = [Locale(lang)];
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            tester.view.physicalSize = Size(width * 3, 2400);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MsgApp(
                home: ShellScreen(
                  me: fakeMe(
                    tabs: const [
                      'accueil',
                      'membres',
                      'finances',
                      'calendrier',
                      'annonces',
                    ],
                    permissions: _all,
                    welcome:
                        'Bienvenue au Mouvement Garde Suisse. Service, ordre, accueil : merci de servir avec nous.',
                    groups: const [
                      {'id': 1, 'name': 'Mouvement Garde Suisse'},
                      {'id': 2, 'name': 'Chorale Sainte-Cécile de Bonapriso'},
                    ],
                  ),
                ),
              ),
            );
            await tester.runAsync(GoogleFonts.pendingFonts);
            await tester.pumpAndSettle();

            Future<void> go(String name, Finder f) async {
              step = name;
              if (f.evaluate().isEmpty) {
                problems.add('[$name] not found: $f');
                return;
              }
              await tester.ensureVisible(f.first);
              await tester.pumpAndSettle();
              await tester.tap(f.first, warnIfMissed: false);
              await tester.pumpAndSettle();
            }

            Future<void> back() async {
              final nav = tester.state<NavigatorState>(
                find.byType(Navigator).last,
              );
              nav.pop();
              await tester.pumpAndSettle();
            }

            step = 'home';
            await go('account', find.byKey(const Key('open-account')));
            await back();
            await go('notifications', find.byKey(const Key('bell')));
            await back();
            await go('members', find.byKey(const Key('tab-membres')));
            await go('member profile', find.text('Ewane Brice'));
            await back();
            await go('request access', find.byKey(const Key('add-member')));
            await back();
            await go(
              'access requests',
              find.byKey(const Key('open-access-requests')),
            );
            await back();
            await go('finances', find.byKey(const Key('tab-finances')));
            await go('collections', find.byKey(const Key('seg-1')));
            await go('report', find.byKey(const Key('seg-2')));
            await go('cash book', find.byKey(const Key('seg-0')));
            await go('new entry', find.byKey(const Key('new-entry')));
            await back();
            await go('calendar', find.byKey(const Key('tab-calendrier')));
            await go('agenda', find.byKey(const Key('seg-1')));
            await go('event detail', find.text('Assise hebdomadaire'));
            await back();
            await go('planning', find.byKey(const Key('seg-2')));
            await go('new event', find.byKey(const Key('tab-calendrier')));
            await go('month', find.byKey(const Key('seg-0')));
            await go('event form', find.byKey(const Key('new-event')));
            await back();
            await go('announcements', find.byKey(const Key('tab-annonces')));
            await go('compose', find.byKey(const Key('compose')));
            await back();
          } finally {
            FlutterError.onError = previous;
          }
          // Ignore the image-loading noise of fake photo URLs.
          final real = problems
              .where(
                (p) =>
                    !p.contains('HTTP request failed') &&
                    !p.contains('NetworkImage'),
              )
              .toList();
          expect(real, isEmpty, reason: real.join('\n'));
        });
      }
    }
  }
}
