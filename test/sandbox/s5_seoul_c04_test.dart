import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 04 "The Palace of a Thousand Logs" (PART 2, docs/SEOUL_CASE02_12_REDESIGN_PLAN.md
/// Case 04): the stroke rule taught in the case, the yard book's two counts,
/// the traces to Mr. Pyo's cart, and the Daewongun's three questions, each
/// answered by one of three cards of this case only, at every level.
void main() {
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep04']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('Intro: the case is set up on its own, and never gives M1 away (no "gates")', () {
    for (final level in Difficulty.values) {
      final intro = episode(level).intro.join('\n');
      expect(intro, contains('1866'), reason: level.label);
      expect(intro, contains("King's father"), reason: level.label);
      expect(intro.toLowerCase(), isNot(contains('gate')), reason: level.label);
    }
  });

  test('M1: the stroke rule is read in this case, GATES only', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep04_m1', level);
      expect(m.letter, contains('a stronger sound adds one line'), reason: level.label);
      expect(m.letter, isNot(contains('Sora')), reason: level.label);
      expect(m.answer, 'GATES', reason: level.label);
      expect(AnswerChecker.isCorrect(m, 'HALLS'), isFalse);
      expect(AnswerChecker.feedbackFor(m, 'HALLS'), isNotNull, reason: level.label);
    }
  });

  test('M2: twelve to two and six to sixteen: ten, never said before the answer', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep04_m2', level);
      expect(m.letter, allOf(contains('다 logs: six'), contains('다 logs: sixteen'), contains('twelve'), contains('two')), reason: level.label);
      expect(m.answer, '10');
      for (final wrong in ['12', '16', '02', '06']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${level.label} $wrong');
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
      expect([...episode(level).intro, ...mission('s5_ep04_m1', level).story].join(' ').toLowerCase(), isNot(contains('ten ')), reason: level.label);
    }
  });

  test("M3: the traces lead to Mr. Pyo's cart; each trace is a line of the letter", () {
    final scene = season5Content.deductions['s5_ep04_m3']!;
    expect(scene.picture, endsWith('case_04/palace_site_traces.webp'));
    expect(scene.places.map((p) => p.optionId), ['hall', 'cart', 'gate']);
    expect(scene.clues.map((c) => c.id), ['carry', 'tracks', 'dust']);
    expect(season5Content.timelines.containsKey('s5_ep04_m3'), isFalse, reason: 'the timeline is gone');
    for (final level in Difficulty.values) {
      final m = mission('s5_ep04_m3', level);
      expect(m.answer, 'cart', reason: level.label);
      expect(m.letter, contains('Logs to sell leave by the east gate'), reason: level.label);
      expect(m.letter, contains('Pale wood dust'), reason: level.label);
      for (final o in m.options.where((o) => o.id != m.answer)) {
        expect(o.feedback, isNotNull, reason: '${level.label} ${o.id}');
      }
    }
  });

  test("Final: three questions, three cards each, this case's evidence only, lit from the third miss", () {
    final talk = season5Content.talks['s5_ep04_final']!;
    expect(talk.presents.map((p) => p.id), ['p_mark2', 'p_cut2', 'p_writer2']);
    expect(talk.finishWhen, {'p_mark2', 'p_cut2', 'p_writer2'});
    expect(talk.answer, 'rebuilt');
    expect(talk.questions.map((q) => q.id), containsAll(['why', 'q_cost']));
    final want = {'p_mark2': 's5_ep04_e1', 'p_cut2': 's5_ep04_e3', 'p_writer2': 's5_ep04_e2'};
    for (final p in talk.presents) {
      expect(p.accepted, {want[p.id]}, reason: p.id);
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.every((e) => e.startsWith('s5_ep04_')), isTrue, reason: p.id);
      expect(p.choices.first, isNot(want[p.id]), reason: '${p.id}: the right card is never first');
      expect(p.litAfter, 3, reason: p.id);
      expect(p.tell, isNotNull, reason: p.id);
    }
    for (final level in Difficulty.values) {
      final m = mission('s5_ep04_final', level);
      expect(m.letter, allOf(contains('One new cut turns 나 into 다'), contains('with a chisel'), contains('only a pine tree')), reason: level.label);
      expect(m.letter, isNot(contains('water drop')), reason: level.label);
      expect(m.hints, hasLength(2), reason: level.label);
    }
  });

  test('No other case: no Sora, no 1592/1795 notes, no "But why?", at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
      ].join('\n');
      for (final w in ['Sora', 'Bun-i', 'keeper', 'letter box', '1795', 'But why?', 'same water drop']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
    }
  });
}
