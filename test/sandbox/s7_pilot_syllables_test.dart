import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/pilot/seoul_pilot.dart';
import 'package:world_mystery/features/mission/widgets/syllable_board.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

/// Seoul Pilot Case 01, Mission 3: the note put back together on its paper
/// (`SyllableBoard`, down the page from the right) at the smallest phone
/// (320×568), text ×1 and ×1.6 — every piece a 48 dp target on screen, the
/// letters the app's own text, each move saved, the solved note read-only —
/// at every level. And the language rule (English is the tool): a player
/// who reads Korean but not the English cannot write the note.
void main() {
  const m3 = 's7_ep01_m3', m2 = 's7_ep01_m2', fin = 's7_ep01_final';
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

  /// [spec]'s groups written into the places [at] gives them (block index → syllable).
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
    final spec = level == Difficulty.rookie ? seoulPilotSeason.syllables[m3]! : seoulPilotSeason.variants[level]!.syllables[m3]!;
    for (final text in [1.0, 1.6]) {
      testWidgets('${level.label}, 320×568, text ×$text: every piece on screen and 48 dp; built place by place into 서고 지붕', (t) async {
        String? sent;
        final saves = await open(t, spec, text: text, onSubmit: (a) => sent = a);
        expect(t.takeException(), isNull);
        for (final b in spec.blocks) {
          expect(find.text(b.line), findsOneWidget, reason: 'Taek\'s words for ${b.id} at ${level.label}');
        }
        // READ THE NOTE waits for every group.
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
          if (dot != VowelDot.none) await tap(t, 'syllable-dot-${b.id}-${dot.name}');
          if (b.finalConsonant case final f?) await tap(t, 'syllable-bottom-${b.id}-$f');
          expect(find.text(Hangul.compose(b.initial, b.vowel, b.finalConsonant)!), findsWidgets, reason: '${b.id} written');
        }
        expect(saves.last, startsWith('pv2:syllables:1:'));
        await tap(t, 'syllable-check');
        expect(sent, '서고지붕');
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('the paper: the first column on the right, places named by where they are; opened again as saved', (t) async {
    final spec = seoulPilotSeason.syllables[m3]!;
    final saves = await open(t, spec);
    final cell = {for (final b in spec.blocks) b.id: t.getCenter(find.byKey(ValueKey('syllable-cell-${b.id}')))};
    expect(cell['one']!.dx, greaterThan(cell['three']!.dx), reason: 'Group 1 is in the right column');
    expect(cell['one']!.dy, lessThan(cell['two']!.dy), reason: 'Group 2 is under Group 1');
    expect([for (var i = 0; i < 4; i++) spec.placeName(i)], ['TOP RIGHT', 'BOTTOM RIGHT', 'TOP LEFT', 'BOTTOM LEFT']);
    expect(find.textContaining(RegExp(r'^GROUP \d')), findsNothing, reason: 'no place is named by its group\'s number');
    await tap(t, 'syllable-cell-one');
    await tap(t, 'syllable-sound-one-ㅅ');
    await tap(t, 'syllable-line-one-standing');
    expect(find.byKey(const ValueKey('syllable-dot-one-above')), findsNothing, reason: 'a standing line takes its dot left or right');
    await tap(t, 'syllable-dot-one-left');
    expect(find.text('서'), findsWidgets);
    final again = await open(t, spec, saved: saves.last);
    expect(again, isEmpty);
    expect(find.text('서'), findsWidgets, reason: 'the saved group back');
    final semantics = t.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp(r'^top right of the paper: written 서')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('solved: the note as it was written, nothing to play', (t) async {
    await open(t, seoulPilotSeason.syllables[m3]!, solved: true);
    expect(find.text('서고지붕'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-check')), findsNothing);
  });

  group('a player who reads Korean, not the English', () {
    final spec = seoulPilotSeason.syllables[m3]!;
    Episode episode(Difficulty level) => DifficultyContent.episodeAt(
      Episode.fromJson({...seoulPilotSeason.episodes['s7_ep01']!, 'seasonId': seoulPilotSeason.id}),
      level,
      patches: seoulPilotSeason.casePatches,
    );
    Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);
    final hangulWord = RegExp(r'[가-힣]');

    test('M3: nothing of a group is given, and no place names its group', () {
      final s = rules.initial(spec);
      expect([for (var i = 0; i < 4; i++) rules.written(spec, s, i)], ['', '', '', ''], reason: 'no first sound written in: the words are not shown');
      expect(spec.sounds.toSet(), containsAll(['ㅅ', 'ㄱ', 'ㅈ', 'ㅂ', 'ㅇ']));
    });

    test('M3: 서고 지붕 known and written across the page, or from the left, is not the note', () {
      final m = mission(m3);
      // Rows, left to right: 서 고 / 지 붕 (top left, top right, bottom left, bottom right).
      final across = written(spec, {2: '서', 0: '고', 3: '지', 1: '붕'});
      expect(rules.isComplete(spec, across), isTrue);
      expect(rules.answerOf(spec, across), '고붕서지');
      expect(AnswerChecker.isCorrect(m, '고붕서지'), isFalse);
      expect(AnswerChecker.feedbackFor(m, '고붕서지'), contains('across the page'));
      // Columns from the left: 서 지 / 고 붕.
      expect(rules.answerOf(spec, written(spec, {2: '서', 3: '고', 0: '지', 1: '붕'})), '지붕서고');
      expect(AnswerChecker.isCorrect(m, '지붕서고'), isFalse);
      // Down from the right, as Sora's English says.
      expect(AnswerChecker.isCorrect(m, rules.answerOf(spec, written(spec, {0: '서', 1: '고', 2: '지', 3: '붕'}))), isTrue);
    });

    test('M2: the board\'s English decides each letter, among letters a glance would take', () {
      for (final level in Difficulty.values) {
        final m = mission(m2, level);
        expect(m.options.length, 9, reason: 'four tiles that are not in the note');
        expect(m.answer, 'siot,giyeok,jieut,bieup,ieung');
        for (final wrong in ['siot,giyeok,chieut,bieup,ieung', 'siot,giyeok,jieut,pieup,ieung', 'siot,giyeok,jieut,mieum,ieung', 'siot,nieun,jieut,bieup,ieung']) {
          expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: wrong);
          expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong answered in English');
        }
        // Taek names parts of the mouth, never a shape a Korean eye matches on the tiles.
        for (final shape in ['corner', 'lid', 'horn', 'tooth ']) {
          expect(m.letter.contains(shape), isFalse, reason: '${level.label}: "$shape" in M2\'s letter');
        }
      }
    });

    test('no Hangul word in any mission\'s words, nor in the King\'s talk: the note alone holds it', () {
      for (final level in Difficulty.values) {
        for (final m in episode(level).allMissions) {
          for (final w in [m.letter, m.question, ...m.hints, m.successMessage, ...m.feedback.values, ?m.orderFeedback, ?m.evidence?.description]) {
            expect(hangulWord.hasMatch(w), isFalse, reason: '${level.label} ${m.id}: "$w"');
          }
        }
      }
      // Every line of the King's talk, at every level (the plan's words and their levels).
      final talk = seoulPilotSeason.talks[fin]!;
      final lines = [
        for (final q in talk.questions) ...[q.text, ...q.beat.map((l) => l.text)],
        for (final p in talk.presents) ...[p.prompt, ...p.beat.map((l) => l.text), p.miss.text, ?p.tell],
      ];
      expect(lines, isNotEmpty);
      for (final l in lines) {
        expect(hangulWord.hasMatch(l), isFalse, reason: 'the King\'s talk: "$l"');
      }
    });
  });
}
