import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';

/// Seoul Case 05 "The Lights of Geoncheonggung" after PART 2: the King calls
/// the detective; Lady Han's unsigned note; her account told out of order;
/// the rope found under the Queen's steps; the final reads the strangers'
/// board (dots counted like the rope's knots) to the Queen's door.
void main() {
  Episode episode([Difficulty level = Difficulty.rookie]) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep05']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('Intro: the King called the detective; one palace name only', () {
    for (final level in Difficulty.values) {
      final intro = episode(level).intro.join('\n');
      expect(intro, contains('the King has'), reason: level.label);
      expect(intro, isNot(contains('Gyeongbokgung')), reason: level.label);
      expect(intro, isNot(contains('guest')), reason: level.label);
    }
  });

  test('M1: the note has no name; the dark was made', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep05_m1', level);
      expect(m.letter, contains('two strangers'), reason: level.label);
      expect(m.letter, isNot(contains('— Han')), reason: level.label);
      expect(m.transition.join(' '), isNot(contains('signed')), reason: level.label);
      expect(m.answer, 'belt');
    }
  });

  test('M2: told out of order, the answer still one; the flat board foreshadowed', () {
    final m = mission('s5_ep05_m2');
    final ids = [for (final o in m.options) o.id];
    expect(ids.where((i) => i != 'guards').join(','), isNot(m.answer), reason: 'never listed in the answer order');
    expect(m.answer, 'lit,lamphouse,dark,gate,hall,back');
    // Rookie reads the night in time order (2026-11-10); Junior and Master start at the end.
    expect(m.letter.split('\n').first, startsWith('The lamp man lit the lamps at 8:00'), reason: 'Rookie: in time order');
    for (final level in Difficulty.values) {
      final l = mission('s5_ep05_m2', level);
      if (level != Difficulty.rookie) {
        expect(l.letter.split('\n').first, startsWith('The lamp man came back at 9:00'), reason: '${level.label}: the account starts at the end');
      }
      expect(l.letter, contains('flat board'), reason: level.label);
      expect(l.letter, allOf(contains('main gate'), contains('saw nothing')), reason: level.label);
      expect(l.transition.join(' '), contains("Queen's steps"), reason: level.label);
    }
  });

  test('M3: 37 from the knot rule, at every level', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep05_m3', level);
      expect(m.answer, '37');
      expect(m.letter, contains('A big knot is ten steps'), reason: level.label);
      expect(m.transition.join(' '), contains('flat board'), reason: level.label);
    }
  });

  test("Final: the board's circled door is the Queen's; each wrong picture says why; history after the answer", () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep05_final', level);
      expect(m.type, MissionType.multipleChoice, reason: level.label);
      expect(m.answer, 'queen');
      expect([for (final o in m.options) o.id], ['king', 'lamp', 'queen']);
      expect(m.letter, allOf(contains('a door with a circle'), contains('big dot'), contains('like the knots on the rope')), reason: level.label);
      for (final wrong in ['king', 'lamp']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse);
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
      // Nothing before the answer names the Queen's door as the circled one.
      expect([...m.story, m.letter, ...m.hints].join(' '), isNot(contains("circle is the Queen")), reason: level.label);
      expect(m.transition.join(' '), contains('Russia'), reason: level.label);
    }
  });

  test('stands alone: no other case named, no letter box, no family letters', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
      ].join('\n');
      for (final w in ['Duri', 'Bun-i', 'Seok', 'keeper', 'letter box', 'our letters', '1866']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
    }
  });
}
