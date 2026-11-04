import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

const _spec = SyllableSpec(blocks: [
  SyllableBlock(id: 'one', initial: 'ㅅ', vowel: 'ㅓ', line: 'a standing line, a dot on its left'),
  SyllableBlock(id: 'two', initial: 'ㄱ', vowel: 'ㅗ', line: 'a flat line, a dot on top'),
  SyllableBlock(id: 'three', initial: 'ㅈ', vowel: 'ㅣ', line: 'only a standing line'),
  SyllableBlock(id: 'four', initial: 'ㅂ', vowel: 'ㅜ', finalConsonant: 'ㅇ', line: 'a flat line, a dot under it'),
]);

void main() {
  const rules = SyllableRules();

  test('Unicode joins the sounds the book joins', () {
    expect(Hangul.compose('ㅅ', 'ㅓ'), '서');
    expect(Hangul.compose('ㅂ', 'ㅜ', 'ㅇ'), '붕');
    expect(Hangul.compose('ㆍ', 'ㅓ'), isNull);
    expect([for (final l in VowelLine.values) for (final d in VowelDot.values) Hangul.vowelOf(l, d)].nonNulls.toList(), ['ㅡ', 'ㅗ', 'ㅜ', 'ㅣ', 'ㅓ', 'ㅏ']);
    expect(Hangul.partsOf('ㅐ'), isNull);
  });

  test('a spec that plays, and one that does not', () {
    expect(rules.validate(_spec), isEmpty);
    expect(rules.answer(_spec), '서고지붕');
    final bad = rules.validate(const SyllableSpec(blocks: [
      SyllableBlock(id: 'a', initial: 'ㆍ', vowel: 'ㅐ', finalConsonant: '', line: ' '),
    ]));
    expect(bad.map((i) => i.code), containsAll(['syllables_size', 'syllables_initial', 'syllables_vowel', 'syllables_final', 'field_missing']));
  });

  test('moves: a line, a dot on it, never a dot off its line', () {
    var s = PuzzleSession.open(rules, _spec);
    expect(s.complete, isFalse);
    var (n, why) = s.play(const SetVowelDot(0, VowelDot.left));
    expect(why?.code, 'dot_without_line');
    (n, why) = s.play(const SetVowelLine(0, VowelLine.standing));
    s = n;
    (n, why) = s.play(const SetVowelDot(0, VowelDot.above));
    expect(why?.code, 'dot_misplaced');
    (s, _) = s.play(const SetVowelDot(0, VowelDot.left));
    expect(rules.written(_spec, s.state, 0), '서');
    expect(rules.written(_spec, s.state, 1), 'ㄱ');
    // A new line takes the dot off.
    (s, _) = s.play(const SetVowelLine(0, VowelLine.flat));
    expect(s.state.pieces[0], const SyllablePiece(VowelLine.flat));
    (s, _) = s.play(const ClearVowel(0));
    expect(s.state.pieces[0], const SyllablePiece());
  });

  test('a full note is the mission\'s answer; a wrong group is pointed at', () {
    var s = PuzzleSession.open(rules, _spec);
    for (final a in const [
      SetVowelLine(0, VowelLine.standing), SetVowelDot(0, VowelDot.right), // 사: wrong side
      SetVowelLine(1, VowelLine.flat), SetVowelDot(1, VowelDot.above),
      SetVowelLine(2, VowelLine.standing),
      SetVowelLine(3, VowelLine.flat), SetVowelDot(3, VowelDot.below),
    ]) {
      (s, _) = s.play(a);
    }
    expect(s.complete, isTrue);
    expect(s.answer, '사고지붕');
    expect(rules.firstProblem(_spec, s.state), 0);
    (s, _) = s.play(const SetVowelDot(0, VowelDot.left));
    expect(s.answer, rules.answer(_spec));
    expect(rules.firstProblem(_spec, s.state), isNull);
    expect(AnswerChecker.normalize(s.answer), '서고지붕', reason: 'Hangul is kept, never read as nothing');
    expect(AnswerChecker.normalize('east!'), 'EAST');
  });

  test('saved, opened again; a broken or foreign save starts afresh; solved is read-only', () {
    var s = PuzzleSession.open(rules, _spec);
    (s, _) = s.play(const SetVowelLine(3, VowelLine.flat));
    (s, _) = s.play(const SetVowelDot(3, VowelDot.below));
    final back = PuzzleSession.open(rules, _spec, saved: s.saved);
    expect(back.restored, isTrue);
    expect(back.state, s.state);
    expect(s.saved, startsWith('pv2:syllables:1:'));
    for (final broken in ['pv2:syllables:1:[[', 'pv2:syllables:1:[["flat","left"],[null,"none"],[null,"none"],[null,"none"]]', 'pv2:timeline:1:{}', 'x']) {
      expect(PuzzleSession.open(rules, _spec, saved: broken).restored, isFalse, reason: broken);
    }
    final done = PuzzleSession.open(rules, _spec, solved: true);
    expect(done.answer, '서고지붕');
    expect(done.play(const ClearVowel(0)).$2?.code, 'solved');
  });

  test('levels change words only', () {
    const junior = SyllableSpec(blocks: [
      SyllableBlock(id: 'one', initial: 'ㅅ', vowel: 'ㅓ', line: 'x'),
      SyllableBlock(id: 'two', initial: 'ㄱ', vowel: 'ㅗ', line: 'x'),
      SyllableBlock(id: 'three', initial: 'ㅈ', vowel: 'ㅣ', line: 'x'),
      SyllableBlock(id: 'four', initial: 'ㅂ', vowel: 'ㅜ', finalConsonant: 'ㅇ', line: 'x'),
    ]);
    expect(PuzzleSpecCheck.levels(rules, {Difficulty.rookie: _spec, Difficulty.junior: junior, Difficulty.master: _spec}), isEmpty);
    const changed = SyllableSpec(blocks: [
      SyllableBlock(id: 'one', initial: 'ㅅ', vowel: 'ㅏ', line: 'x'),
      SyllableBlock(id: 'two', initial: 'ㄱ', vowel: 'ㅗ', line: 'x'),
    ]);
    expect(PuzzleSpecCheck.levels(rules, {Difficulty.rookie: _spec, Difficulty.junior: changed, Difficulty.master: _spec}).map((i) => i.code), contains('level_changes_game'));
  });
}
