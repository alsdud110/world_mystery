import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 10 "The Two Watches" after PART 4 (docs/SEOUL_CASE02_12_REDESIGN_PLAN.md
/// §C3 Case 10): M3 HOUR from Yun's words, the final Haesu's record proved
/// line by line with this case's three cards, one watch in one place, and no
/// other case's box, mark or people, at every level.
void main() {
  Episode episode([Difficulty level = Difficulty.rookie]) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep10']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('M3: HOUR, read from the long hand going round one more time; near misses have their own line', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep10_m3', level);
      expect(m.type, MissionType.wordInput, reason: level.label);
      expect(m.answer, 'HOUR', reason: level.label);
      expect(m.letter, allOf(contains('long hand'), contains('one more time'), contains('one more ____')), reason: level.label);
      for (final ok in ['hour', 'ONE HOUR', 'an hour']) {
        expect(AnswerChecker.isCorrect(m, ok), isTrue, reason: '${level.label} $ok');
      }
      for (final wrong in ['MINUTE', 'DAY', 'WEEK', 'YEAR', 'TIME']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${level.label} $wrong');
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
      // The answer is never said before it is typed.
      final before = [...m.story, m.letter, m.question, ...m.hints].join('\n');
      expect(before.toUpperCase(), isNot(contains('HOUR')), reason: level.label);
    }
  });

  test('Final: three lines, each proved by one card of this case; three cards each, the right one never first twice', () {
    final talk = season5Content.talks['s5_ep10_final']!;
    expect(talk.answer, 'why');
    expect([for (final p in talk.presents) p.id], ['after', 'whose', 'why']);
    final accepted = {for (final p in talk.presents) p.id: p.accepted.single};
    expect(accepted, {'after': 's5_ep10_e1', 'whose': 's5_ep10_e2', 'why': 's5_ep10_e3'});
    for (final p in talk.presents) {
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.toSet(), {'s5_ep10_e1', 's5_ep10_e2', 's5_ep10_e3'}, reason: '${p.id}: only this case');
      expect(p.litAfter, 3, reason: p.id);
      expect(p.tell, isNotNull, reason: p.id);
    }
    expect({for (final p in talk.presents) p.choices.indexOf(p.accepted.single)}, hasLength(3), reason: 'the right card moves');
    expect(mission('s5_ep10_final').hints, hasLength(2));
  });

  test('one watch in one place: Kim Gu holds it, never one on the table too', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letter, ...m.transition],
      ].join('\n');
      expect(text, isNot(matches(RegExp(r'watch(es)? (lies|lie|is|are) on the (table|desk)', caseSensitive: false))), reason: level.label);
      expect(mission('s5_ep10_m2', level).letter, contains("Mr. Kim's fingers"), reason: level.label);
    }
  });

  test('stands alone: no box, mark or people of another case, at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
      ].join('\n');
      for (final w in ['box', 'water drop', 'keeper', 'Miri', 'Bitna', 'Bun-i', 'Aunae', 'nineteen']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
    }
  });
}
