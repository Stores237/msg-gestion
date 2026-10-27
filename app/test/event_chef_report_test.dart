import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/main.dart';
import 'package:msg_gestion/models/event.dart';
import 'package:msg_gestion/screens/calendar/attendance_screen.dart';
import 'package:msg_gestion/screens/calendar/event_detail_screen.dart';
import 'package:msg_gestion/screens/calendar/event_form_screen.dart';
import 'package:msg_gestion/widgets/ui.dart';

import 'fakes.dart';
import 'helpers.dart';

/// Owner, 2026-10-27: "Autre" named by the author; Messe intérieure /
/// extérieure; a chef de groupe designated with the event, who reports to
/// the formateur within 24 h (in the app or as a PDF).
void main() {
  Future<void> chooseKind(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// The form opened from a page, as in the app (saving pops it).
  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MsgApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-form'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventFormScreen(initialDay: DateTime.now()),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-form')));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('save-event')));
    await tester.pumpAndSettle();
  }

  testWidgets('a mass needs inside/outside and a chef; Autre needs a name', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('f-title')), 'Grand-messe');
    await chooseKind(tester, 'Messe');
    await save(tester);
    expect(find.text('Choisissez intérieur ou extérieur.'), findsOneWidget);
    expect(find.text('Désignez le chef de groupe.'), findsOneWidget);
    expect(f.events.events, hasLength(1)); // nothing sent

    await tester.tap(find.byKey(const Key('f-scope-exterieur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('f-chef')));
    await tester.pumpAndSettle();
    // Only active members can lead: the one on leave isn't offered.
    expect(find.byKey(const Key('pick-member-2')), findsNothing);
    await tester.tap(find.byKey(const Key('pick-member-3')));
    await tester.pumpAndSettle();
    expect(find.text('Ateba Sandrine'), findsOneWidget);
    await save(tester);
    final made = f.events.events.last;
    expect((made.kind, made.scope, made.chefId), ('messe', 'exterieur', 3));

    // "Autre": the author names it.
    await openForm(tester);
    await tester.enterText(find.byKey(const Key('f-title')), 'Kermesse');
    await chooseKind(tester, 'Autre');
    expect(find.byKey(const Key('f-kind-other')), findsOneWidget);
    expect(find.byKey(const Key('f-scope-interieur')), findsNothing);
  });

  testWidgets('a meeting has no chef de groupe', (tester) async {
    final f = await setUpApp(tester);
    await openForm(tester);
    await chooseKind(tester, 'Réunion');
    expect(find.byKey(const Key('f-chef')), findsNothing);
    await tester.enterText(find.byKey(const Key('f-title')), 'Bureau');
    await save(tester);
    expect(f.events.events.last.chefId, isNull);
  });

  testWidgets('Messe extérieure is told apart on the card', (tester) async {
    await setUpApp(tester);
    final e = CalendarEvent(
      id: 9,
      kind: 'messe',
      title: 'Messe à Bonabéri',
      startsAt: DateTime(2026, 11, 1, 9),
      place: '',
      dress: '',
      notes: '',
      scope: 'exterieur',
      chefName: 'Ateba S.',
    );
    await tester.pumpWidget(
      MsgApp(
        home: Scaffold(body: EventCard(event: e)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EXTÉRIEUR'), findsOneWidget);
    expect(find.text('Chef de groupe : Ateba S.'), findsOneWidget);
  });

  testWidgets('the chef writes the report; it can then be read', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    final now = DateTime.now();
    f.events.events = [
      CalendarEvent(
        id: 1,
        kind: 'assise',
        title: 'Assise',
        startsAt: now.subtract(const Duration(hours: 3)),
        endsAt: now.subtract(const Duration(hours: 1)),
        place: '',
        dress: '',
        notes: '',
        chefId: 1,
        chefName: 'Ingrid N.',
        reportStatus: 'pending',
        reportDueAt: now.add(const Duration(hours: 23)),
        canReport: true,
      ),
    ];
    await tester.pumpWidget(
      MsgApp(home: EventDetailScreen(eventId: 1, me: fakeMe())),
    );
    await tester.pumpAndSettle();
    expect(find.text('ATTENDU'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('report-write')), 200);
    await tester.tap(find.byKey(const Key('report-write')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Envoyé au formateur ; en copie'),
      findsOneWidget,
    );
    // Neither text nor PDF: said, nothing sent.
    await tester.tap(find.byKey(const Key('report-send')));
    await tester.pumpAndSettle();
    expect(find.text('Écrivez le rapport ou joignez un PDF.'), findsOneWidget);
    expect(f.events.submitted, isEmpty);
    await tester.enterText(
      find.byKey(const Key('report-text')),
      'RAS. 8 gardes présents.',
    );
    await tester.tap(find.byKey(const Key('report-send')));
    await tester.pumpAndSettle();
    expect(f.events.submitted.single, (1, 'RAS. 8 gardes présents.', null));
    // Back on the event: handed in, and readable.
    expect(find.text('REMIS'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('report-read')), 200);
    await tester.tap(find.byKey(const Key('report-read')));
    await tester.pumpAndSettle();
    expect(find.text('RAS. 8 gardes présents.'), findsOneWidget);
    expect(find.text('Par Ingrid N., chef de groupe'), findsOneWidget);
  });

  lineupAndLockTests();
}

void lineupAndLockTests() {
  CalendarEvent mass({Duty? myDuty, String? readBy, bool canReport = false}) =>
      CalendarEvent(
        id: 1,
        kind: 'messe',
        title: 'Messe dominicale',
        startsAt: DateTime.now().add(const Duration(hours: 3)),
        place: '',
        dress: '',
        notes: '',
        scope: 'interieur',
        chefId: 7,
        chefName: 'Ateba S.',
        reportStatus: readBy == null ? 'pending' : 'submitted',
        reportDueAt: DateTime.now().add(const Duration(days: 1)),
        reportReadBy: readBy,
        canReport: canReport,
        hasLineup: true,
        myDuty: myDuty,
      );

  testWidgets('roll call lists the lineup with each post highlighted', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.events.lineup = true;
    f.events.sheet
      ..clear()
      ..addAll([
        AttendanceRow(
          member: 7,
          fullName: 'Ateba Sandrine',
          isDiaspora: false,
          status: '',
          reason: '',
          duty: const Duty(chef: true),
        ),
        AttendanceRow(
          member: 10,
          fullName: 'Eboa Lionel',
          isDiaspora: false,
          status: '',
          reason: '',
          duty: const Duty(post: 'premiere_centrale', side: 'pariso'),
        ),
      ]);
    await tester.pumpWidget(MsgApp(home: AttendanceScreen(event: mass())));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lineup-only')), findsOneWidget);
    expect(find.byKey(const Key('att-7-chef')), findsOneWidget);
    expect(find.text('PREMIÈRE CENTRALE · PARISO'), findsOneWidget);
    expect(find.text('INTÉRIEUR'), findsOneWidget);
  });

  testWidgets('my presence: my post, or not on duty without the absence '
      'button', (tester) async {
    final f = await setUpApp(tester);
    f.events.events = [
      mass(
        myDuty: const Duty(post: 'controle', side: 'yapoma'),
      ),
    ];
    await tester.pumpWidget(
      MsgApp(home: EventDetailScreen(eventId: 1, me: fakeMe())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('my-duty')), 200);
    expect(find.textContaining('VOTRE POSTE'), findsOneWidget);
    expect(find.byKey(const Key('warn-absence')), findsOneWidget);

    f.events.events = [mass()];
    await tester.pumpWidget(
      MsgApp(
        home: EventDetailScreen(key: UniqueKey(), eventId: 1, me: fakeMe()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('not-on-duty')), 200);
    expect(find.byKey(const Key('warn-absence')), findsNothing);
  });

  testWidgets('a report opened by the bureau shows it is locked', (
    tester,
  ) async {
    final f = await setUpApp(tester);
    f.events.events = [mass(readBy: 'Nyobe C.')];
    await tester.pumpWidget(
      MsgApp(home: EventDetailScreen(eventId: 1, me: fakeMe())),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('report-locked')),
      200,
    );
    expect(
      find.text('Ouvert par Nyobe C. : ne peut plus être modifié'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-write')), findsNothing);
  });
}
