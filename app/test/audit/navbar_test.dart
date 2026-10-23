// The bottom bar's labels stay on one line, whatever the width, language
// and text size.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/screens/shell_screen.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  for (final lang in ['fr', 'en']) {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          'nav labels on one line: $lang ${width.toInt()}dp ×$scale',
          (tester) async {
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
                  ),
                ),
              ),
            );
            await tester.runAsync(GoogleFonts.pendingFonts);
            await tester.pumpAndSettle();
            final labels = find.descendant(
              of: find.byType(NavigationBar),
              matching: find.byType(RichText),
            );
            expect(labels, findsWidgets);
            for (final e in labels.evaluate()) {
              final p = e.renderObject! as RenderParagraph;
              final text = p.text.toPlainText();
              if (text.trim().isEmpty || RegExp(r'^\d+$').hasMatch(text)) {
                continue;
              }
              final lines = p
                  .getBoxesForSelection(
                    TextSelection(baseOffset: 0, extentOffset: text.length),
                  )
                  .map((b) => b.top.round())
                  .toSet()
                  .length;
              expect(lines, 1, reason: '"$text" wraps onto $lines lines');
              expect(p.didExceedMaxLines, isFalse, reason: '"$text" is cut');
            }
          },
        );
      }
    }
  }
}
