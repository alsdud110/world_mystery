import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/features/mission/widgets/letter_lock.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Rookie PART R2 (docs/SEOUL_ROOKIE_AUDIT.md): six missions read
/// less before their first move, and still hold every clue their answer
/// needs, on the words the game shows. Junior and Master read as before.
void main() {
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes[id.substring(0, 7)]!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  ).allMissions.firstWhere((m) => m.id == id);
  int words(Mission m) => RegExp(r"[A-Za-z][A-Za-z'\-]*").allMatches([...m.story, m.letterIntro, m.letter, m.question].join(' ')).length;

  void answers(Mission m, Map<String, bool> wrongHasFeedback) {
    expect(AnswerChecker.isCorrect(m, m.answer), isTrue, reason: m.id);
    for (final MapEntry(key: wrong, value: told) in wrongHasFeedback.entries) {
      expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: '${m.id} $wrong');
      if (told) expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: '${m.id} $wrong');
    }
  }

  test('Rookie reads less than Junior on each of the six; the answers are the same at every level', () {
    for (final id in ['s5_ep02_m1', 's5_ep05_m2', 's5_ep05_final', 's5_ep07_m2', 's5_ep09_m2', 's5_ep11_m3']) {
      final r = mission(id);
      expect(words(r), lessThan(words(mission(id, Difficulty.junior))), reason: id);
      for (final level in Difficulty.values) {
        expect(mission(id, level).answer, r.answer, reason: '$id ${level.label}');
      }
    }
  });

  test('C02 M1: the report still says where each thing is, and why wet powder matters', () {
    final m = mission('s5_ep02_m1');
    final report = season5Content.investigations[m.id]!;
    for (final f in report.finds) {
      expect(m.letter, contains(f.reportLine), reason: 'the report and the search say the same: ${f.id}');
    }
    expect(m.letter, contains('under the hole in the roof'));
    expect(m.hints.last, contains('wet powder will not fire'));
    answers(m, {'straw': false, 'note': false});
    for (final o in m.options.where((o) => o.id != m.answer)) {
      expect(o.feedback, isNotNull, reason: o.id);
    }
  });

  test('C05 Ending: Rookie says "hold back" in plain words; Junior and Master keep it', () {
    String line(Difficulty level) => (level == Difficulty.rookie ? season5Content.endings : season5Content.variants[level]!.endings)['s5_ep05_final']!
        .map((e) => e.text)
        .firstWhere((t) => t.startsWith('In 1895, the Queen'));
    expect(line(Difficulty.rookie), contains("to stop Japan's power from growing"));
    expect(line(Difficulty.junior), contains("hold back Japan's power"));
  });

  test('C05 M2 and C07 M2: every line a wrong card points back to is in the words read', () {
    for (final id in ['s5_ep05_m2', 's5_ep07_m2']) {
      final m = mission(id);
      final spec = season5Content.timelines[id]!;
      for (final r in spec.relations) {
        expect(m.letter, contains(r.line), reason: '$id: ${r.earlier} before ${r.later}');
      }
      expect(spec.order.join(','), m.answer, reason: id);
    }
    expect(mission('s5_ep05_m2').letter, contains('main gate saw nothing'), reason: 'why the main gate card is set aside');
    expect(mission('s5_ep07_m2').letter, contains('goods train'), reason: 'why the goods train card is left out');
  });

  // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c05_test.dart.

  test('C09 M2: the report still says where each thing is, and which one holds the names', () {
    final m = mission('s5_ep09_m2');
    for (final f in season5Content.investigations[m.id]!.finds) {
      expect(m.letter, contains(f.reportLine), reason: f.id);
    }
    expect(m.letter, contains('Names are pressed into it.'));
    for (final o in m.options.where((o) => o.id != m.answer)) {
      expect(o.feedback, isNotNull, reason: o.id);
    }
    answers(m, {'key': false, 'ink': false});
  });

  // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c11_redesign_test.dart.

  // PART R3: history words said plainly at Rookie; Junior and Master read as before.
  group('R3', () {
    // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c06_test.dart.

    // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c09_test.dart.

    // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c10_test.dart.

    // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c11_redesign_test.dart.

    test('C12 M3: the radio in plain words; the date and the card kept', () {
      final m = mission('s5_ep12_m3');
      expect(m.letter, isNot(contains('Allies')));
      expect(m.letter, contains('the fifteenth of August'));
      expect(m.letter, contains('August is month eight'));
      answers(m, {'715': true, '814': true, '915': true, '158': false});
      // PART 1B: the fourteenth is only a 'may' day, ruled out by Mother's rule read in the same letter.
      expect(m.letter, contains("'May' is not enough."));
      expect(m.letter, contains('The fourteenth'));
      expect(AnswerChecker.feedbackFor(m, '814'), contains("'may' is not enough"));
    });

    test('C12 stands alone: no other case\'s evidence, people or season box, at every level', () {
      for (final level in Difficulty.values) {
        final ep = DifficultyContent.episodeAt(
          Episode.fromJson({...season5Content.episodes['s5_ep12']!, 'seasonId': season5Content.id}),
          level,
          patches: season5Content.casePatches,
        );
        expect(ep.title, 'The Box That Waited', reason: level.label);
        expect(ep.title.toUpperCase(), isNot(contains('LIGHT')), reason: level.label);
        final text = [
          ...ep.intro,
          for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
        ].join('\n');
        for (final w in ['Bun-i', 'Haesu', 'Miri', 'Sora', 'keeper', 'water drop', 'water-drop', 'letter box']) {
          expect(text, isNot(contains(w)), reason: '${level.label}: $w');
        }
        // 815 and LIGHT are never shown before their own puzzles.
        final beforeM3 = [...ep.intro, for (final m in ep.allMissions.take(2)) ...[...m.story, m.letter, ...m.transition]].join('\n');
        expect(beforeM3, isNot(contains('8.15')), reason: level.label);
        expect(beforeM3.toUpperCase(), isNot(contains('LIGHT')), reason: level.label);
        final fin = ep.allMissions.last;
        expect(fin.answer, 'LIGHT', reason: level.label);
        expect(fin.letter, allOf(contains('The sun gives it.'), contains('At night, it goes away.')), reason: level.label);
      }
    });

    test('C12 Final (PART 1.5): seven tiles, five slots, two extra; every word they make has its own line, at every level', () {
      for (final level in Difficulty.values) {
        final fin = mission('s5_ep12_final', level);
        expect(fin.options.map((o) => o.label).join(), 'NHTIRGL', reason: level.label);
        expect(LetterLockQuestion.slotCount(fin), 5, reason: level.label);
        expect(fin.letter, contains('Two tiles are extra.'), reason: level.label);
        expect(AnswerChecker.isCorrect(fin, 'LIGHT'), isTrue, reason: level.label);
        for (final w in ['NIGHT', 'RIGHT', 'THING', 'GLINT', 'GIRTH']) {
          expect(AnswerChecker.isCorrect(fin, w), isFalse, reason: '${level.label} $w');
          final line = AnswerChecker.feedbackFor(fin, w);
          expect(line, isNotNull, reason: '${level.label} $w');
          expect(line!.toUpperCase(), isNot(contains('LIGHT')), reason: '${level.label} $w: never the answer');
        }
        // M2: the riddle is in pieces on the backs, said before the order is set.
        final m2 = mission('s5_ep12_m2', level);
        expect(m2.letter, contains('one piece on each'), reason: level.label);
        expect(m2.transition.first, contains('in order'), reason: level.label);
      }
    });

    // Superseded by the PART 2–4 redesign; its final is tested in test/sandbox/s5_seoul_c05_test.dart.

    test('words a Rookie line shows have their meaning, at every level', () {
      for (final (caseId, words) in [
        ('s5_ep06', ['moss', 'knelt', 'dusk', 'silk']),
        ('s5_ep09', ['bureau', 'pressed']),
        ('s5_ep10', ['clerk', 'provisional']),
        ('s5_ep11', ['choice']),
      ]) {
        for (final level in Difficulty.values) {
          final ep = DifficultyContent.episodeAt(
            Episode.fromJson({...season5Content.episodes[caseId]!, 'seasonId': season5Content.id}),
            level,
            patches: season5Content.casePatches,
          );
          expect(ep.glossary.keys, containsAll(words), reason: '$caseId ${level.label}');
        }
      }
    });
  });
}
