import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_text.dart';
import 'package:world_mystery/widgets/paper.dart';

/// A place's name in the display face draws its numbers in the reading face
/// (IM Fell's old-style "4" read as a letter on a phone: Case 04's
/// "PLATFORM 4"). Only the figures change; the words keep their face.
void main() {
  TextSpan spanOf(WidgetTester t, String plain) =>
      t.widget<Text>(find.byWidgetPredicate((w) => w is Text && w.textSpan?.toPlainText() == plain)).textSpan! as TextSpan;

  testWidgets('a page heading draws "PLATFORM 4" with lining figures', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: PageHeading(title: 'PLATFORM 4'))));
    final span = spanOf(t, 'PLATFORM 4');
    expect(span.style!.fontFamily, AppText.display);
    final parts = span.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text), ['PLATFORM ', '4']);
    expect(parts.first.style, isNull, reason: 'the words keep the heading face');
    expect(parts.last.style!.fontFamily, AppText.body);
  });

  testWidgets('a name without numbers is one span, as before', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: PageHeading(title: 'THE PLATFORMS'))));
    final span = spanOf(t, 'THE PLATFORMS');
    expect(span.children, isNull);
    expect(span.style!.fontFamily, AppText.display);
  });

  test('1, 4, 7 and a time are all set in the reading face', () {
    for (final text in ['PLATFORM 1', 'PLATFORM 7', 'GALLERY 8', 'THE 9:30 TO EDINBURGH']) {
      final span = AppText.liningDigits(text, AppText.placeTitle());
      final figures = span.children!.cast<TextSpan>().where((p) => p.style != null);
      expect(figures, isNotEmpty, reason: text);
      for (final f in figures) {
        expect(f.style!.fontFamily, AppText.body, reason: text);
        expect(RegExp(r'^[0-9:.]+$').hasMatch(f.text!), isTrue, reason: text);
      }
    }
  });
}
