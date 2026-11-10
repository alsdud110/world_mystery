import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 06 "The Emperor's Secret Letter" (PART 3, docs/SEOUL_CASE02_12_REDESIGN_PLAN.md):
/// the note's way out read from mixed-up lines, one knock time ("as soon
/// as"), and a final talk in which each of Yi Jun's three worries is
/// answered by this case's own evidence. Same game at every level.
void main() {
  Episode episode([Difficulty level = Difficulty.rookie]) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep06']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('M2: the lines are out of order (Rookie: in order); Start and the relation words give one way, at every level', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep06_m2', level);
      expect(m.answer, 'library,well,west_gate,lane', reason: level.label);
      expect(m.options.map((o) => o.id).join(','), isNot(startsWith('library')), reason: '${level.label}: never the answer order');
      final lines = m.letter.split('\n');
      // Rookie reads the way in order (2026-11-10); Junior and Master out of it.
      if (level == Difficulty.rookie) {
        expect(lines.first, startsWith('Start'), reason: 'Rookie: the way in order');
      } else {
        expect(lines.first, isNot(contains('Start')), reason: '${level.label}: the start is not the first line');
      }
      expect(m.letter, contains('Start behind the library hall'), reason: level.label);
      expect(m.letter, contains('big front gate all day'), reason: level.label);
      expect(m.letter, contains('Do not cross the throne hall'), reason: level.label);
      for (final wrong in ['throne,well,west_gate,lane', 'library,well,front_gate,lane', 'library,west_gate,well,lane']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${level.label} $wrong');
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
    }
  });

  test('M3: "as soon as" leaves one time, 06:50; 07:00 is told too late', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep06_m3', level);
      expect(m.answer, '0650', reason: level.label);
      expect(m.letter, contains('the 6:40 walk has passed'), reason: level.label);
      expect(m.question, contains('07:00'), reason: '${level.label}: the leading zero shown');
      for (final wrong in ['0640', '0700', '0720', '0610']) {
        expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${level.label} $wrong');
        expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${level.label} $wrong');
      }
    }
  });

  test("Final: Yi Jun's three worries, each answered by one card of this case (three cards, lit only from the third miss)", () {
    final fin = mission('s5_ep06_final');
    expect(fin.type, MissionType.examine);
    expect(fin.answer, 'unseen');
    expect(fin.hints, hasLength(2));
    final talk = season5Content.talks['s5_ep06_final']!;
    expect(talk.presents.map((p) => p.id), ['thread', 'gate', 'door']);
    expect(talk.finishWhen, {'thread', 'gate', 'door'});
    final right = {'thread': 's5_ep06_e1', 'gate': 's5_ep06_e2', 'door': 's5_ep06_e3'};
    for (final p in talk.presents) {
      expect(p.accepted, {right[p.id]}, reason: p.id);
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.every((e) => e.startsWith('s5_ep06_')), isTrue, reason: '${p.id}: this case only');
      expect(p.choices.first, isNot(right[p.id]), reason: '${p.id}: the right card is not first');
      expect(p.litAfter, 3, reason: p.id);
      expect(p.tell, isNotNull, reason: p.id);
    }
  });

  test('stands alone: no other case, no water drop, no letter lock word, at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
      ].join('\n');
      for (final w in ['water drop', 'Bun-i', 'letter box', '1895', 'FORCED', 'Mrs. Kang']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
      expect(ep.intro.join(' '), contains('1897'), reason: '${level.label}: why an Emperor, told here');
    }
  });
}
