import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 03 PART 2 (docs/SEOUL_CASE02_12_REDESIGN_PLAN.md, Case 03):
/// the final asks who tied the warning note, by three conditions read in the
/// case (saw Jeong's drawing, can write, in the yard at night). The same
/// game at every level, in different English; nothing of another case.
void main() {
  Episode at(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep03']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, Difficulty level) => at(level).allMissions.firstWhere((m) => m.id == id);
  String shown(Episode ep) => [
    ...ep.intro,
    for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition, m.successMessage],
  ].join('\n');

  test('the final: who tied the note, Okbun, among four, at every level', () {
    for (final level in Difficulty.values) {
      final fin = mission('s5_ep03_final', level);
      expect(fin.type, MissionType.multipleChoice, reason: level.label);
      expect(fin.answer, 'okbun', reason: level.label);
      expect(fin.options.map((o) => o.id), ['clerk', 'okbun', 'gwak', 'carpenter'], reason: '${level.label}: never the answer first');
      expect(AnswerChecker.isCorrect(fin, 'okbun'), isTrue);
      for (final wrong in ['clerk', 'gwak', 'carpenter']) {
        expect(AnswerChecker.isCorrect(fin, wrong), isFalse);
        expect(AnswerChecker.feedbackFor(fin, wrong), isNotNull, reason: '${level.label} $wrong: says which condition fails');
      }
      // Every condition is on the final's own page.
      expect(fin.letter, contains('tied to the rope in the night'), reason: level.label);
      expect(fin.letter, contains('I never go into the drawing room.'), reason: level.label);
      expect(fin.letter, contains('I cannot read or write'), reason: level.label);
      expect(fin.letter, contains('The yard gate is shut at night'), reason: level.label);
    }
  });

  test('the note came after the carpenter changed the drawing (M1), and only three come into the drawing room (M2)', () {
    for (final level in Difficulty.values) {
      final m1 = mission('s5_ep03_m1', level);
      expect(m1.answer, 'start,lift,copy,note,fail', reason: level.label);
      expect(m1.letter, contains("after the carpenter's work"), reason: level.label);
      expect(m1.letter.split('\n').first, isNot(contains('1794')), reason: '${level.label}: the log is not in time order');
      expect(m1.transition.join(' '), contains('water carriers'), reason: level.label);
      final m2 = mission('s5_ep03_m2', level);
      expect(m2.answer, 'gate_wheels', reason: level.label);
      expect(m2.story.join(' '), allOf(contains('cannot read'), contains('the girl who brings water')), reason: level.label);
    }
  });

  test('the same answers at every level, in different English', () {
    final r = at(Difficulty.rookie), j = at(Difficulty.junior), m = at(Difficulty.master);
    for (final (i, mr) in r.allMissions.indexed) {
      expect(j.allMissions[i].answer, mr.answer);
      expect(m.allMissions[i].answer, mr.answer);
      expect(j.allMissions[i].options.map((o) => o.id), mr.options.map((o) => o.id));
      expect(m.allMissions[i].options.map((o) => o.id), mr.options.map((o) => o.id));
    }
    expect(j.intro, isNot(r.intro));
    expect(m.intro, isNot(j.intro));
    final fr = r.allMissions.last, fj = j.allMissions.last, fm = m.allMissions.last;
    expect({fr.letter, fj.letter, fm.letter}, hasLength(3), reason: 'three Englishes for one final');
    expect({fr.question, fj.question, fm.question}, hasLength(3));
  });

  test('no answer told before it is asked, and nothing of another case', () {
    for (final level in Difficulty.values) {
      final ep = at(level);
      final beforeFinal = [
        ...ep.intro,
        for (final m in ep.allMissions.take(3)) ...[...m.story, m.letter, ...m.transition],
      ].join('\n');
      expect(beforeFinal, isNot(contains('Okbun')), reason: '${level.label}: her name first comes with the four in the final');
      final text = shown(ep);
      for (final w in ['Seok', 'Bun-i', '1592', '1446', 'Duri', 'keeper', 'letter box', 'same mark', 'record chest']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
    }
  });
}
