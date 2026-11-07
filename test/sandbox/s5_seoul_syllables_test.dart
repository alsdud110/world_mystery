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

/// Seoul Case 01, Mission 3: Bun-i's last paper put back together
/// (`SyllableBoard`, one group above the other) at the smallest phone
/// (320×568), text ×1 and ×1.6 — every piece a 48 dp target on screen, the
/// letters the app's own text, each move saved, the solved note read-only —
/// at every level. And the language rule (English is the tool): a player
/// who reads Korean but not the English cannot write the note.
void main() {
  const m3 = 's5_ep01_m3', m2 = 's5_ep01_m2', fin = 's5_ep01_final';
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
    final spec = level == Difficulty.rookie ? season5Content.syllables[m3]! : season5Content.variants[level]!.syllables[m3]!;
    for (final text in [1.0, 1.6]) {
      testWidgets('${level.label}, 320×568, text ×$text: every piece on screen and 48 dp; built place by place into 정음', (t) async {
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
        expect(sent, '정음');
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('the paper: one group above the other, places named by where they are; opened again as saved', (t) async {
    final spec = season5Content.syllables[m3]!;
    final saves = await open(t, spec);
    final cell = {for (final b in spec.blocks) b.id: t.getCenter(find.byKey(ValueKey('syllable-cell-${b.id}')))};
    expect(cell['one']!.dy, lessThan(cell['two']!.dy), reason: 'Group 1 is at the top, as Sora\'s lesson says');
    expect([for (var i = 0; i < 2; i++) spec.placeName(i)], ['TOP', 'BOTTOM']);
    expect(find.textContaining(RegExp(r'^GROUP \d')), findsNothing, reason: 'no place is named by its group\'s number');
    await tap(t, 'syllable-cell-one');
    await tap(t, 'syllable-sound-one-ㅈ');
    await tap(t, 'syllable-line-one-standing');
    expect(find.byKey(const ValueKey('syllable-dot-one-above')), findsNothing, reason: 'a standing line takes its dot left or right');
    await tap(t, 'syllable-dot-one-left');
    expect(find.text('저'), findsWidgets);
    final again = await open(t, spec, saved: saves.last);
    expect(again, isEmpty);
    expect(find.text('저'), findsWidgets, reason: 'the saved group back');
    final semantics = t.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp(r'^top of the paper: written 저')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('solved: the note as it was written, nothing to play', (t) async {
    await open(t, season5Content.syllables[m3]!, solved: true);
    expect(find.text('정음'), findsOneWidget);
    expect(find.byKey(const ValueKey('syllable-check')), findsNothing);
  });

  group('a player who reads Korean, not the English', () {
    final spec = season5Content.syllables[m3]!;
    Episode episode(Difficulty level) => DifficultyContent.episodeAt(
      Episode.fromJson({...season5Content.episodes['s5_ep01']!, 'seasonId': season5Content.id}),
      level,
      patches: season5Content.casePatches,
    );
    Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);
    final hangulWord = RegExp(r'[가-힣]');

    test('M3: nothing of a group is given, and no place names its group', () {
      final s = rules.initial(spec);
      expect([for (var i = 0; i < 2; i++) rules.written(spec, s, i)], ['', ''], reason: 'no first sound written in: the words are not shown');
      expect(spec.sounds.toSet(), containsAll(['ㅈ', 'ㅅ', 'ㅊ', 'ㅇ', 'ㅁ', 'ㄴ']));
      expect(spec.blocks.where((b) => b.given), isEmpty);
    });

    test('M3: Group 2 has no words of its own: only the slate of Mission 2 fills it', () {
      for (final level in Difficulty.values) {
        final blocks = (level == Difficulty.rookie ? spec : season5Content.variants[level]!.syllables[m3]!).blocks;
        expect(blocks[1].line, contains('slate'), reason: level.label);
        for (final w in ['throat', 'mouth', 'flat line', 'ㅇ', 'ㅁ', 'ㅡ']) {
          expect(blocks[1].line.contains(w), isFalse, reason: '${level.label}: "$w"');
        }
      }
      expect(season5Content.episodes['s5_ep01']!['missions'], isNotNull);
    });

    test('M3: a wrong group is refused and answered in English', () {
      final m = mission(m3);
      expect(m.answer, '정음');
      for (final wrong in ['성음', '청음', '장음', '정응', '음정']) {
        final (a, b) = (wrong[0], wrong[1]);
        expect(rules.answerOf(spec, written(spec, {0: a, 1: b})), wrong);
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: wrong);
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: wrong);
      }
      expect(AnswerChecker.isCorrect(m, rules.answerOf(spec, written(spec, {0: '정', 1: '음'}))), isTrue);
    });

    test('M2: the board\'s English decides each letter, among letters a glance would take', () {
      for (final level in Difficulty.values) {
        final m = mission(m2, level);
        expect(m.options.length, 9, reason: 'six tiles that are not in the group');
        expect(m.answer, 'ieung,eu,mieum');
        for (final wrong in ['ieung,eu,bieup', 'ieung,o,mieum', 'ieung,i,mieum', 'siot,eu,mieum', 'nieun,eu,mieum']) {
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
      final talk = season5Content.talkMissions[fin]!.before!;
      final lines = [
        for (final l in talk.opening) l.text,
        for (final p in talk.presents) ...[p.prompt, ...p.beat.map((l) => l.text), p.miss.text, ?p.tell],
      ];
      expect(lines, isNotEmpty);
      for (final l in lines) {
        expect(hangulWord.hasMatch(l), isFalse, reason: 'the King\'s talk: "$l"');
      }
    });
  });

  // Rookie R1 (docs/SEOUL_ROOKIE_AUDIT.md): Cases 01 and 02 read the
  // King's letters the same way. (Case 11's riddle was replaced by Yun's
  // list on 2026-11-07: test/sandbox/s5_seoul_case11_test.dart.)
  group('Sora\'s board in Cases 01 and 02', () {
    Episode episode(String caseId, Difficulty level) => DifficultyContent.episodeAt(
      Episode.fromJson({...season5Content.episodes[caseId]!, 'seasonId': season5Content.id}),
      level,
      patches: season5Content.casePatches,
    );
    Mission mission(String caseId, String id, Difficulty level) => episode(caseId, level).allMissions.firstWhere((m) => m.id == id);
    SyllableSpec? syllables(String id, Difficulty level) =>
        level == Difficulty.rookie ? season5Content.syllables[id] : season5Content.variants[level]!.syllables[id];

    test('Rookie says "+ 1 line" in both, never "step stronger"; tongue and gums in each glossary', () {
      for (final (caseId, ids) in [('s5_ep01', ['s5_ep01_m2', m3]), ('s5_ep02', ['s5_ep02_m2'])]) {
        final ep = episode(caseId, Difficulty.rookie);
        for (final id in ids) {
          final m = ep.allMissions.firstWhere((m) => m.id == id);
          final words = [m.letter, m.question, ...m.hints, ...m.feedback.values, ?m.orderFeedback, ...?syllables(id, Difficulty.rookie)?.blocks.map((b) => b.line)];
          for (final w in words) {
            expect(w.contains('step stronger') || w.contains('steps stronger'), isFalse, reason: '$id: "$w"');
          }
        }
        expect(ep.glossary.keys, containsAll(['tongue', 'gums']), reason: caseId);
      }
      expect(mission('s5_ep01', 's5_ep01_m2', Difficulty.rookie).question, contains('3 letters'), reason: 'one group, three letters');
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
