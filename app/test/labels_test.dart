import 'package:flutter_test/flutter_test.dart';
import 'package:msg_gestion/l10n/app_localizations_en.dart';
import 'package:msg_gestion/l10n/app_localizations_fr.dart';
import 'package:msg_gestion/widgets/labels.dart';

void main() {
  test("a group's own activity types show as the group wrote them", () {
    final fr = AppLocalizationsFr();
    final en = AppLocalizationsEn();
    // Default kept: translated.
    expect(eventKindLabel(en, 'messe', 'Messe'), en.kindMass);
    // Renamed by the group, or its own: shown as written.
    expect(
      eventKindLabel(en, 'assise', 'Assise hebdomadaire'),
      'Assise hebdomadaire',
    );
    expect(eventKindLabel(fr, 'repetition', 'Répétition'), 'Répétition');
    expect(dressLabel(fr, 'aube', 'Aube'), 'Aube');
    expect(dressLabel(fr, ''), fr.dressNone);
  });
}
