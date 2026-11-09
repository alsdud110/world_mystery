import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 02 PART 2 (docs/SEOUL_CASE02_12_REDESIGN_PLAN.md §C1 Case 02):
/// the final proves with this case's three cards that Seok saved the powder
/// from the rain (a judgment, not a spelled name); the same game at every
/// level, in different English; nothing told before its own puzzle; no
/// other case's people or things.
void main() {
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep02']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('the final: four sentences, Seok moved all twelve barrels out of the rain; each wrong one has its line', () {
    for (final level in Difficulty.values) {
      final fin = mission('s5_ep02_final', level);
      expect(fin.type, MissionType.multipleChoice, reason: level.label);
      expect(fin.answer, 'seok', reason: level.label);
      expect(fin.options.map((o) => o.id), ['thief', 'shiproof', 'seok', 'ham'], reason: 'never the answer first (${level.label})');
      final right = fin.options.firstWhere((o) => o.id == 'seok').label;
      expect(right, allOf(contains('all twelve barrels'), contains('out of the rain')), reason: level.label);
      for (final o in fin.options.where((o) => o.id != 'seok')) {
        expect(AnswerChecker.isCorrect(fin, o.id), isFalse, reason: '${level.label} ${o.id}');
        expect(AnswerChecker.feedbackFor(fin, o.id), isNotNull, reason: '${level.label} ${o.id}');
      }
      expect(AnswerChecker.isCorrect(fin, 'seok'), isTrue, reason: level.label);
    }
  });

  test('the talk before the final: three cards each, all of this case, the right one lit only from the third miss', () {
    final talk = season5Content.talkMissions['s5_ep02_final']!.before!;
    expect(talk.presents.map((p) => p.id), ['p_danger', 'p_how', 'p_count']);
    final accepted = {for (final p in talk.presents) p.id: p.accepted.single};
    expect(accepted, {'p_danger': 's5_ep02_e1', 'p_how': 's5_ep02_e2', 'p_count': 's5_ep02_e3'});
    for (final p in talk.presents) {
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.every((e) => e.startsWith('s5_ep02_')), isTrue, reason: '${p.id}: this case only');
      expect(p.choices.first, isNot(p.accepted.single), reason: '${p.id}: never the answer first');
      expect(p.litAfter, 3, reason: p.id);
      expect(p.tell, isNotNull, reason: p.id);
    }
  });

  test('the same game at every level, in different English', () {
    final r = episode(Difficulty.rookie);
    for (final level in [Difficulty.junior, Difficulty.master]) {
      final e = episode(level);
      for (final (a, b) in [for (var i = 0; i < r.allMissions.length; i++) (r.allMissions[i], e.allMissions[i])]) {
        expect(b.answer, a.answer, reason: '${a.id} ${level.label}');
        expect(b.options.map((o) => o.id), a.options.map((o) => o.id), reason: '${a.id} ${level.label}');
      }
      expect(e.intro, isNot(r.intro), reason: level.label);
      expect(mission('s5_ep02_final', level).question, isNot(mission('s5_ep02_final').question), reason: level.label);
      expect(mission('s5_ep02_m1', level).question, isNot(mission('s5_ep02_m1').question), reason: level.label);
    }
  });

  test('nothing told before its own puzzle: the count (twelve) not before M3, the judgment not before the final', () {
    for (final level in Difficulty.values) {
      final e = episode(level);
      final m1 = e.allMissions.first;
      final beforeM3 = [...e.intro, for (final m in e.allMissions.take(2)) ...[...m.story, m.letter, m.question, ...m.hints, ...m.transition]].join('\n');
      expect(beforeM3.toLowerCase(), isNot(contains('twelve')), reason: level.label);
      expect(beforeM3, isNot(contains('12')), reason: level.label);
      expect(m1.options.first.id, isNot(m1.answer), reason: 'M1 never lists the answer first (${level.label})');
      final m3 = e.allMissions[2];
      expect([...m3.story, m3.letter].join('\n').toLowerCase(), isNot(contains('twelve')), reason: 'M3 asks for the count (${level.label})');
    }
  });

  test('stands alone: no other case\'s people, things or ids, at every level', () {
    for (final level in Difficulty.values) {
      final e = episode(level);
      final text = [
        ...e.intro,
        for (final m in e.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition, m.successMessage],
      ].join('\n');
      for (final w in ['Bun-i', 'Sora', 'keeper', 'letter box', '1446', 'same mark', 's5_ep01', 'Haesu', 'Miri']) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
    }
  });
}
