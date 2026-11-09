import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_colors.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/mission/widgets/syllable_board.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

/// Seoul Case 01, Mission 3 (V4): Bun-i's first word, 엄마, built block by
/// block, left to right (`SyllableBoard`, `SyllableSpec.row`) at the
/// smallest phone (320×568), text ×1 and ×1.6 — every piece a 48 dp target
/// on screen, each block's sound shown as it is built, the letters the
/// app's own text, each move saved, the solved word read-only — at every
/// level. A wrong word is refused and answered in English.
void main() {
  const m3 = 's5_ep01_m3';
  const rules = SyllableRules();

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

  void target(WidgetTester t, String key) {
    final r = t.getRect(find.byKey(ValueKey(key)));
    expect(r.width >= 48 && r.height >= 48 && r.left >= 0 && r.right <= 320, isTrue, reason: '$key: $r');
  }

  /// [spec]'s blocks written into the places [at] gives them (block index → syllable).
  SyllableState written(SyllableSpec spec, Map<int, String> at) {
    var s = rules.initial(spec);
    for (final MapEntry(key: i, value: syllable) in at.entries) {
      final code = syllable.codeUnitAt(0) - 0xAC00;
      final (line, dot) = Hangul.partsOf(Hangul.vowels[code ~/ 28 % 21])!;
      final f = Hangul.finals[code % 28];
      for (final a in <SyllableAction>[SetFirstSound(i, Hangul.initials[code ~/ 588]), SetVowelLine(i, line), SetVowelDot(i, dot), SetBottomSound(i, f.isEmpty ? null : f)]) {
        final r = rules.apply(spec, s, a);
        s = r.state;
      }
    }
    return s;
  }

  for (final level in Difficulty.values) {
    final spec = level == Difficulty.rookie ? season5Content.syllables[m3]! : season5Content.variants[level]!.syllables[m3]!;
    for (final text in [1.0, 1.6]) {
      testWidgets('${level.label}, 320×568, text ×$text: every piece on screen and 48 dp; built block by block into 엄마', (t) async {
        String? sent;
        final saves = await open(t, spec, text: text, onSubmit: (a) => sent = a);
        expect(t.takeException(), isNull);
        for (final b in spec.blocks) {
          expect(find.text(b.line), findsOneWidget, reason: 'the sound of ${b.id} at ${level.label}');
        }
        // READ THE WORD waits for every block.
        expect(find.text('READ THE WORD'), findsOneWidget);
        expect(t.widget<GestureDetector>(find.descendant(of: find.byKey(const ValueKey('syllable-check')), matching: find.byType(GestureDetector)).first).onTap, isNull);
        for (final b in spec.blocks) {
          await tap(t, 'syllable-cell-${b.id}');
          for (final s in spec.sounds) {
            target(t, 'syllable-sound-${b.id}-$s');
          }
          await tap(t, 'syllable-sound-${b.id}-${b.initial}');
          final (line, dot) = Hangul.partsOf(b.vowel)!;
          for (final l in VowelLine.values) {
            target(t, 'syllable-line-${b.id}-${l.name}');
          }
          await tap(t, 'syllable-line-${b.id}-${line.name}');
          for (final d in Hangul.dotsFor(line)) {
            target(t, 'syllable-dot-${b.id}-${d.name}');
          }
          await tap(t, 'syllable-dot-${b.id}-${dot.name}');
          for (final f in ['none', ...spec.lastSounds]) {
            target(t, 'syllable-bottom-${b.id}-$f');
          }
          await tap(t, 'syllable-bottom-${b.id}-${b.finalConsonant ?? 'none'}');
          final syllable = Hangul.compose(b.initial, b.vowel, b.finalConsonant)!;
          expect(find.text(syllable), findsWidgets, reason: '${b.id} written');
          expect(find.text('says "${Hangul.reading(syllable)}"'), findsOneWidget, reason: '${b.id}: its sound shown');
        }
        expect(saves.last, startsWith('pv2:syllables:1:'));
        await tap(t, 'syllable-check');
        expect(sent, '엄마');
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('the paper: two blocks side by side, left to right, named BLOCK 1 and 2, each saying its sound; opened again as saved', (t) async {
    final spec = season5Content.syllables[m3]!;
    expect(spec.row, isTrue);
    final saves = await open(t, spec);
    final cell = {for (final b in spec.blocks) b.id: t.getCenter(find.byKey(ValueKey('syllable-cell-${b.id}')))};
    expect(cell['eom']!.dx, lessThan(cell['ma']!.dx), reason: 'eom first, on the left, as words are written today');
    expect(cell['eom']!.dy, cell['ma']!.dy, reason: 'one row');
    expect([for (var i = 0; i < 2; i++) spec.placeName(i)], ['BLOCK 1', 'BLOCK 2']);
    expect(find.text('TOP'), findsNothing);
    await tap(t, 'syllable-cell-eom');
    for (final row in ['FIRST SOUND', 'VOWEL · LINE', 'LAST SOUND (AT THE BOTTOM)']) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    expect(find.byKey(const ValueKey('syllable-bottom-eom-ㅇ')), findsNothing, reason: 'no last ㅇ: in 1446 that was another letter');
    await tap(t, 'syllable-sound-eom-ㅇ');
    await tap(t, 'syllable-line-eom-standing');
    expect(find.text('VOWEL · DOT'), findsOneWidget);
    await tap(t, 'syllable-dot-eom-left');
    expect(find.text('어'), findsWidgets);
    expect(find.text('says "eo"'), findsOneWidget, reason: 'the sound heard so far');
    await tap(t, 'syllable-bottom-eom-ㅁ');
    expect(find.text('엄'), findsWidgets);
    expect(find.text('says "eom"'), findsOneWidget);
    final again = await open(t, spec, saved: saves.last);
    expect(again, isEmpty);
    expect(find.text('엄'), findsWidgets, reason: 'the saved block back');
    final semantics = t.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp(r'^block 1 of the paper: written 엄')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('solved: the word as it was written, nothing to play', (t) async {
    await open(t, season5Content.syllables[m3]!, solved: true);
    expect(find.text('엄마'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-check')), findsNothing);
  });

  test('the readings are the Revised Romanization of each block', () {
    expect({for (final w in ['엄', '마', '어', '언', '암', '멈', '머', '맘', '음', '정', '거']) w: Hangul.reading(w)},
        {'엄': 'eom', '마': 'ma', '어': 'eo', '언': 'eon', '암': 'am', '멈': 'meom', '머': 'meo', '맘': 'mam', '음': 'eum', '정': 'jeong', '거': 'geo'});
    expect(Hangul.reading('ㅓ'), 'eo');
    expect(Hangul.reading('ㅇ'), '', reason: 'a lone first sound reads as nothing yet');
  });

  test('every wrong word the plan answers is refused, in English, at every level', () {
    final spec = season5Content.syllables[m3]!;
    for (final level in Difficulty.values) {
      final m = DifficultyContent.episodeAt(
        Episode.fromJson({...season5Content.episodes['s5_ep01']!, 'seasonId': season5Content.id}),
        level,
        patches: season5Content.casePatches,
      ).allMissions.firstWhere((m) => m.id == m3);
      expect(m.answer, '엄마');
      expect(m.feedback.keys, containsAll(['어마', '언마', '암마', '멈마', '엄머', '엄맘', '마엄']));
      for (final wrong in m.feedback.keys) {
        if (wrong == '마엄') continue; // no block order to build: the blocks are where they are
        expect(rules.answerOf(spec, written(spec, {0: wrong[0], 1: wrong[1]})), wrong, reason: '$wrong can be built');
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: wrong);
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
        expect(RegExp(r'[a-z]').hasMatch(AnswerChecker.feedbackFor(m, wrong)!), isTrue, reason: 'answered in English');
      }
      expect(AnswerChecker.isCorrect(m, rules.answerOf(spec, written(spec, {0: '엄', 1: '마'}))), isTrue);
    }
  });

  // Rookie R1 (docs/SEOUL_ROOKIE_AUDIT.md): Cases 01 and 02 read the
  // King's letters the same way, each taught in its own case (PART 1A:
  // Case 02 has the sailors' letter board, not Sora's). (Case 11's riddle was replaced by Yun's
  // list on 2026-11-07: test/sandbox/s5_seoul_case11_test.dart.)
  group('The mouth letters in Cases 01 and 02', () {
    Episode episode(String caseId, Difficulty level) => DifficultyContent.episodeAt(
      Episode.fromJson({...season5Content.episodes[caseId]!, 'seasonId': season5Content.id}),
      level,
      patches: season5Content.casePatches,
    );
    Mission mission(String caseId, String id, Difficulty level) => episode(caseId, level).allMissions.firstWhere((m) => m.id == id);
    SyllableSpec? syllables(String id, Difficulty level) =>
        level == Difficulty.rookie ? season5Content.syllables[id] : season5Content.variants[level]!.syllables[id];

    test('Rookie says "+ 1 line" in both, never "step stronger"; tongue and lips or throat in each glossary', () {
      for (final (caseId, ids) in [('s5_ep01', ['s5_ep01_m2', m3]), ('s5_ep02', ['s5_ep02_m2'])]) {
        final ep = episode(caseId, Difficulty.rookie);
        for (final id in ids) {
          final m = ep.allMissions.firstWhere((m) => m.id == id);
          final words = [m.letter, m.question, ...m.hints, ...m.feedback.values, ?m.orderFeedback, ...?syllables(id, Difficulty.rookie)?.blocks.map((b) => b.line)];
          for (final w in words) {
            expect(w.contains('step stronger') || w.contains('steps stronger'), isFalse, reason: '$id: "$w"');
          }
        }
        expect(ep.glossary.keys, containsAll(caseId == 's5_ep01' ? ['tongue', 'throat'] : ['tongue', 'lips']), reason: caseId);
      }
      expect(mission('s5_ep01', 's5_ep01_m2', Difficulty.rookie).question, contains('picture it copies'), reason: 'V4: letters laid on the mouth they copy');
      for (final level in Difficulty.values) {
        final board = mission('s5_ep02', 's5_ep02_m2', level).letter;
        expect(board, allOf(contains('ㅁ'), contains('ㅂ'), isNot(contains('Sora'))), reason: 'Case 02 teaches its own board: ${level.label}');
      }
    });
  });

  group('Case 02 M2: the first group is an example, up to Junior', () {
    SyllableSpec note(Difficulty level) =>
        level == Difficulty.rookie ? season5Content.syllables['s5_ep02_m2']! : season5Content.variants[level]!.syllables['s5_ep02_m2']!;

    for (final level in [Difficulty.rookie, Difficulty.junior]) {
      testWidgets('${level.label}: 거 is written and stays; the others build 거북선', (t) async {
        final spec = note(level);
        String? sent;
        await open(t, spec, onSubmit: (a) => sent = a);
        expect(find.text('거'), findsOneWidget);
        expect(find.text('TOP · EXAMPLE'), findsOneWidget);
        await tap(t, 'syllable-cell-one');
        expect(find.byKey(const ValueKey('syllable-editor-one')), findsNothing, reason: 'an example has no pieces');
        for (final b in spec.blocks.where((b) => !b.given)) {
          await tap(t, 'syllable-cell-${b.id}');
          await tap(t, 'syllable-sound-${b.id}-${b.initial}');
          final (line, dot) = Hangul.partsOf(b.vowel)!;
          await tap(t, 'syllable-line-${b.id}-${line.name}');
          await tap(t, 'syllable-dot-${b.id}-${dot.name}');
          await tap(t, 'syllable-bottom-${b.id}-${b.finalConsonant}');
        }
        await tap(t, 'syllable-check');
        expect(sent, '거북선');
      });
    }

    testWidgets('Master: every place is blank', (t) async {
      final spec = note(Difficulty.master);
      expect(spec.blocks.where((b) => b.given), isEmpty);
      await open(t, spec);
      expect(find.text('거'), findsNothing);
      await tap(t, 'syllable-cell-one');
      expect(find.byKey(const ValueKey('syllable-editor-one')), findsOneWidget);
    });

    test('a save from before the example still shows it written', () {
      final spec = note(Difficulty.rookie);
      final old = rules.stateFromJson(spec, [for (final _ in spec.blocks) [null, 'none']])!;
      expect(rules.written(spec, old, 0), '거');
      expect(rules.written(spec, old, 1), isEmpty);
      expect(rules.apply(spec, old, const ClearVowel(0)).rejection?.code, 'block_given');
    });

    for (final text in [1.0, 1.6]) {
      testWidgets('320×568, text ×$text: a place taken up blinks, settles tinted, and its pieces come on screen', (t) async {
        await open(t, note(Difficulty.rookie), text: text);
        final cell = find.byKey(const ValueKey('syllable-cell-three'));
        await t.ensureVisible(cell);
        await t.pumpAndSettle();
        await t.tap(cell);
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        Color fill() => (t.widget<Container>(find.byKey(const ValueKey('syllable-cell-writing'))).decoration! as BoxDecoration).color!;
        final blinking = fill();
        await t.pumpAndSettle();
        expect(blinking, isNot(fill()));
        expect(fill(), isNot(AppColors.paperLight));
        final first = t.getRect(find.byKey(const ValueKey('syllable-sound-three-ㄱ')));
        expect(first.top >= 0 && first.bottom <= 568, isTrue, reason: 'FIRST SOUND on screen: $first');
      });
    }
  });
}
