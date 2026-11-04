import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/pilot/seoul_pilot.dart';
import 'package:world_mystery/features/mission/widgets/syllable_board.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

/// Seoul Pilot Case 01, Mission 3: the note's four groups put back
/// together on `SyllableBoard` at the smallest phone (320×568), text ×1 and
/// ×1.6 — every piece a 48 dp target on screen, the letters the app's own
/// text, each move saved, the solved note read-only — at every level.
void main() {
  const m3 = 's7_ep01_m3';

  Future<List<String>> open(WidgetTester t, SyllableSpec spec, {double text = 1, bool solved = false, String? saved, ValueChanged<String>? onSubmit}) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final saves = <String>[];
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 568), textScaler: TextScaler.linear(text)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SyllableBoard(spec: spec, solved: solved, saved: saved, onSaved: saves.add, onSubmit: onSubmit),
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    return saves;
  }

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(ValueKey(key));
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  for (final level in Difficulty.values) {
    final spec = level == Difficulty.rookie ? seoulPilotSeason.syllables[m3]! : seoulPilotSeason.variants[level]!.syllables[m3]!;
    for (final text in [1.0, 1.6]) {
      testWidgets('${level.label}, 320×568, text ×$text: every piece on screen and 48 dp; built group by group into 서고 지붕', (t) async {
        String? sent;
        final saves = await open(t, spec, text: text, onSubmit: (a) => sent = a);
        expect(t.takeException(), isNull);
        for (final b in spec.blocks) {
          expect(find.text(b.line), findsOneWidget, reason: 'Taek\'s words for ${b.id} at ${level.label}');
          for (final l in VowelLine.values) {
            final r = t.getRect(find.byKey(ValueKey('syllable-line-${b.id}-${l.name}')));
            expect(r.width >= 48 && r.height >= 48, isTrue, reason: '${b.id} ${l.name}: $r');
            expect(r.left >= 0 && r.right <= 320, isTrue, reason: '${b.id} ${l.name} inside the screen: $r');
          }
        }
        // READ THE NOTE waits for every group.
        expect(t.widget<GestureDetector>(find.descendant(of: find.byKey(const ValueKey('syllable-check')), matching: find.byType(GestureDetector)).first).onTap, isNull);
        for (final b in spec.blocks) {
          final (line, dot) = Hangul.partsOf(b.vowel)!;
          await tap(t, 'syllable-line-${b.id}-${line.name}');
          for (final d in Hangul.dotsFor(line)) {
            final r = t.getRect(find.byKey(ValueKey('syllable-dot-${b.id}-${d.name}')));
            expect(r.width >= 48 && r.height >= 48 && r.right <= 320, isTrue, reason: '${b.id} dot ${d.name}: $r');
          }
          if (dot != VowelDot.none) await tap(t, 'syllable-dot-${b.id}-${dot.name}');
          expect(find.text(Hangul.compose(b.initial, b.vowel, b.finalConsonant)!), findsWidgets, reason: '${b.id} written');
        }
        expect(saves.last, startsWith('pv2:syllables:1:'));
        await tap(t, 'syllable-check');
        expect(sent, '서고지붕');
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('a dot before its line is refused, said under the board; opened again as it was saved', (t) async {
    final spec = seoulPilotSeason.syllables[m3]!;
    final saves = await open(t, spec);
    await tap(t, 'syllable-line-one-standing');
    expect(find.byKey(const ValueKey('syllable-dot-one-above')), findsNothing, reason: 'a standing line takes its dot left or right');
    await tap(t, 'syllable-dot-one-left');
    expect(find.text('서'), findsWidgets);
    final again = await open(t, spec, saved: saves.last);
    expect(again, isEmpty);
    expect(find.text('서'), findsWidgets, reason: 'the saved group back');
    final semantics = t.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp(r'^Group 1: written 서')), findsOneWidget);
    expect(find.bySemanticsLabel("Group 1: the sky's dot left the line"), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('solved: the note as it was written, nothing to play', (t) async {
    await open(t, seoulPilotSeason.syllables[m3]!, solved: true);
    expect(find.text('서고지붕'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-check')), findsNothing);
  });
}
