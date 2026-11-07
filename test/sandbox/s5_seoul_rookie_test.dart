import 'package:flutter_test/flutter_test.dart';
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

  test('C05 Final: Lady Han names both countries, and which one the Queen holds back', () {
    final m = mission('s5_ep05_final');
    expect(m.letter, contains("hold back Japan's power"));
    expect(m.letter, contains('Russia'));
    expect(m.letter, contains('37 steps'));
    answers(m, {'RUSSIA': true, 'CHINA': true, 'KOREA': true});
  });

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

  test('C11 M3: the lock\'s rule told step by step, its numbers read on Yun\'s list (M2), an example that is not the answer', () {
    final m = mission('s5_ep11_m3');
    for (final clue in ['side by side', 'First: the number of copies', 'Then: the number of poems in each copy', 'Look at my list again', 'copy 2 of 3', '18 + 1 opening poem']) {
      expect(m.letter, contains(clue));
    }
    expect(m.letter, isNot(contains('319')));
    expect(m.letter, isNot(contains('nineteen')));
    expect(m.answer, '319');
    answers(m, {'119': true, '219': true, '318': true, '215': false});
    // The rule at every level: the copies, then each copy's poems (18 + 1), side by side.
    for (final level in Difficulty.values) {
      final l = mission('s5_ep11_m3', level).letter;
      expect([l.contains('2 of 3'), l.contains('18 + 1 opening poem'), l.contains('side by side')], [true, true, true], reason: level.label);
    }
  });

  // PART R3: history words said plainly at Rookie; Junior and Master read as before.
  group('R3', () {
    test('C06 Final: FORCED as a plain verb in the gap, the treaty\'s facts kept', () {
      final m = mission('s5_ep06_final');
      expect(m.letter, contains('Japan made Korea sign it. Korea did not choose it.'));
      expect(m.letter, contains('Japan ______ Korea to sign it.'));
      expect(m.answer, 'FORCED');
      expect(AnswerChecker.isCorrect(m, 'FORCED'), isTrue);
      expect(AnswerChecker.isCorrect(m, 'FORDEC'), isFalse);
      expect(m.orderFeedback, contains('Japan ____ Korea to sign it.'), reason: 'the feedback says the gap as the letter does');
      expect(mission('s5_ep06_final', Difficulty.junior).letter, contains('on Korea'), reason: 'Junior unchanged');
    });

    test('C09 Final: the fourth question without "in exile"; the police report still answers it', () {
      final talk = season5Content.talks['s5_ep09_final']!;
      final protect = talk.presents.firstWhere((p) => p.id == 'protect');
      expect(protect.prompt, isNot(contains('exile')));
      expect(protect.prompt, contains('so far from home'));
      expect(mission('s5_ep09_final').letter, contains('The police guard the government and watch for spies.'));
    });

    test('C10 Final: the year still read from words; 1919 and the date refused', () {
      final m = mission('s5_ep10_final');
      expect(m.letter, contains('nineteen thirty-two'));
      expect(m.letter, contains('After that day'));
      expect(m.letter, contains('Chinese leaders began to help our government strongly.'));
      expect(RegExp(r'\d{4}').hasMatch(m.letter), isFalse, reason: 'no year written in numbers');
      answers(m, {'1919': true, '0429': true});
    });

    test('C11 Final: a choice subject explained; the language still the player\'s to name', () {
      final m = mission('s5_ep11_final');
      expect(m.letter, contains('choice subject'));
      expect(m.letter, contains('Many schools stopped teaching it.'));
      expect(m.letter, isNot(contains('Korean language')));
      answers(m, {'JAPANESE': true, 'HANGEUL': true, 'CHINESE': true, 'ENGLISH': true});
    });

    test('C12 M3: the radio in plain words; the date and the card kept', () {
      final m = mission('s5_ep12_m3');
      expect(m.letter, isNot(contains('Allies')));
      expect(m.letter, contains('the fifteenth of August'));
      expect(m.letter, contains('August is month eight'));
      answers(m, {'715': true, '814': true, '915': true, '158': false});
    });

    test('C05 Final: "hold back" kept as written, told once in plain words at Rookie only', () {
      final rookie = mission('s5_ep05_final').letter;
      expect(rookie, contains("hold back Japan's power."));
      expect(rookie.split('\n').last, startsWith('(To hold back = to stop'));
      for (final level in [Difficulty.junior, Difficulty.master]) {
        expect(mission('s5_ep05_final', level).letter, isNot(contains('To hold back')), reason: level.label);
      }
    });

    test('words a Rookie line shows have their meaning, at every level', () {
      for (final (caseId, words) in [
        ('s5_ep06', ['moss', 'knelt', 'dusk', 'silk']),
        ('s5_ep09', ['bureau', 'pressed']),
        ('s5_ep10', ['attacked']),
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
