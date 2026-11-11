import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 09 "The Spy in the Shanghai Office", PART 3
/// (docs/SEOUL_CASE02_12_REDESIGN_PLAN.md §C2 Case 09): the light that
/// went on at eleven, the night guard with no key, Mr. Nam's three claims
/// refuted with this case's own cards, and the copy found in his coat.
void main() {
  Episode ep([Difficulty level = Difficulty.rookie]) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep09']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => ep(level).allMissions.firstWhere((m) => m.id == id);

  test('M1: the light went ON at eleven; 0100, and every likely slip has its line', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep09_m1', level);
      expect(m.letter.toLowerCase(), contains('go on'), reason: level.label);
      expect(m.letter, isNot(contains('water drop')), reason: level.label);
      expect(AnswerChecker.isCorrect(m, '0100'), isTrue, reason: level.label);
      for (final wrong in ['1300', '2300', '0300', '1100', '0200']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${level.label} $wrong');
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
    }
  });

  test('M3: the guard has no key, the right name is not the last line; NAM only', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep09_m3', level);
      expect(m.letter, contains('no office key'), reason: level.label);
      expect(m.letter.split('\n').last, isNot(contains('Nam')), reason: level.label);
      expect(AnswerChecker.isCorrect(m, 'NAM GIHO'), isTrue);
      for (final wrong in ['SEO', 'PAK', 'HAESU', 'GUARD']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: wrong);
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
    }
  });

  test("Final: three of Mr. Nam's claims, each refuted by one of three cards of this case; the copy is found", () {
    final talk = season5Content.talks['s5_ep09_final']!;
    expect(talk.presents.map((p) => p.id), ['when', 'how', 'who']);
    expect(talk.finishWhen, {'when', 'how', 'who'});
    final right = {'when': 's5_ep09_e1', 'how': 's5_ep09_e2', 'who': 's5_ep09_e3'};
    for (final p in talk.presents) {
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.every((id) => id.startsWith('s5_ep09_')), isTrue, reason: '${p.id}: this case only');
      expect(p.accepted, {right[p.id]}, reason: p.id);
      expect(p.litAfter, 3, reason: p.id);
      expect(p.tell, isNotNull, reason: p.id);
    }
    for (final level in Difficulty.values) {
      final fin = mission('s5_ep09_final', level);
      expect(fin.answer, 'copy_found', reason: level.label);
      expect(fin.letter, allOf(contains('Nothing was copied.'), contains('I went home at nine pm.')), reason: level.label);
      expect(fin.hints, hasLength(2), reason: level.label);
      expect(fin.transition.join(' '), contains('never left Shanghai'), reason: level.label);
    }
  });

  test('C09 stands alone at every level: no box, water drop, keeper or other case', () {
    for (final level in Difficulty.values) {
      final e = ep(level);
      final text = [
        ...e.intro,
        for (final m in e.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition, m.successMessage],
      ].join('\n');
      for (final w in ['water drop', 'keeper', 'box from', 'Gyeongsun', 'Aunae', 'Bun-i', 'Miri', 'has left Shanghai']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
      expect(e.intro.join(' '), contains('March First Movement'), reason: level.label);
    }
  });
}
