import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/tower_puzzles.dart';
import 'package:world_mystery/data/season5/season5_content.dart';


/// Seoul Case 11, M2 redesigned (docs/SEOUL_CASE11_STORY_REVIEW.md, option
/// A): Yun's list against the keeper's card. Three lines agree word for
/// word, the string line is not true, and the card's last words make it
/// black and white keys; the piano is first seen in M3, whose lock reads
/// its numbers on the list. The same game at every level.
void main() {
  final season = season5Content;
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes['s5_ep11']!, 'seasonId': season.id}),
    level,
    patches: season.casePatches,
  );
  RecordsScene records(Difficulty level) => (level == Difficulty.rookie ? season.records : season.variants[level]!.records)['s5_ep11_m2']!;

  group('the content, at every level', () {
    for (final level in Difficulty.values) {
      test(level.label, () {
        final ep = episode(level);
        final [m1, m2, m3] = ep.missions;
        final fin = ep.finalMission;

        // M2: two records, one line not true, its pair the answer; the agreeing pairs each told why.
        expect(m2.type, MissionType.matchPairs);
        expect(m2.answer, 'string:string');
        final s = records(level);
        String value(RecordDoc d, String id) => d.lines.firstWhere((l) => l.id == id).value;
        expect([for (final l in s.first.lines) l.id], ['copy', 'for', 'poems', 'string']);
        for (final id in ['copy', 'for', 'poems']) {
          expect(value(s.second, id), value(s.first, id), reason: '$id agrees word for word');
          expect(AnswerChecker.isCorrect(m2, '$id:$id'), isFalse);
          expect(AnswerChecker.feedbackFor(m2, '$id:$id'), isNotNull, reason: '${level.label} $id');
        }
        expect([value(s.first, 'string'), value(s.second, 'string')], ['WHITE', 'BLACK AND WHITE']);
        expect([value(s.first, 'copy'), value(s.first, 'poems'), value(s.first, 'for')], ['2 OF 3', '18 + 1 OPENING', 'JEONG BYEONG-UK']);
        expect(s.second.note, 'It is safe under keys of these colours.', reason: 'the card\'s last words, the same at every level');
        expect(AnswerChecker.isCorrect(m2, 'string:string'), isTrue);
        expect(m2.letter, allOf(contains('line by line'), contains('not true')));

        // The piano is never named before M3; M3 shows it, black and white.
        final m2Words = [...m2.story, m2.letterIntro, m2.letter, m2.question, ...m2.hints, ...m2.feedback.values, m2.successMessage, ...m2.transition];
        expect(m2Words.where((w) => w.toLowerCase().contains('piano')), isEmpty, reason: level.label);
        expect(m1.transition.last, contains('card'), reason: 'M1 hands on to the card');

        // PART 4 (redesign): M3 finds the piano (PIANO); the lock moved to
        // the final, read on Yun's list (319). KOREAN is gone.
        expect(m3.answer, 'PIANO');
        expect(m3.recall, isNull);
        expect(fin.answer, '319');
        expect(fin.letter, contains('215'), reason: 'an example that is not the answer');
        for (final wrong in ['219', '318', '119']) {
          expect(AnswerChecker.feedbackFor(fin, wrong), isNotNull, reason: '${level.label} $wrong');
        }

        // No Hangeul stroke riddle left in the case.
        for (final m in ep.allMissions) {
          expect([m.letter, ...m.hints].any((w) => w.contains("SORA'S BOARD") || w.contains('stronger')), isFalse, reason: m.id);
        }
      });
    }

    test('the same game at every level: answers, choices and record lines', () {
      final r = episode(Difficulty.rookie);
      for (final level in [Difficulty.junior, Difficulty.master]) {
        final e = episode(level);
        expect([for (final m in e.allMissions) m.answer], [for (final m in r.allMissions) m.answer]);
        for (final (a, b) in [(records(level).first, records(Difficulty.rookie).first), (records(level).second, records(Difficulty.rookie).second)]) {
          expect([for (final l in a.lines) (l.id, l.label, l.value)], [for (final l in b.lines) (l.id, l.label, l.value)]);
        }
      }
      expect(season.syllables.keys.where((id) => id.startsWith('s5_ep11_')), isEmpty);
    });
  });
  // The case played through (M1 → M2 → M3 → Final talk → 319) is
  // s5_seoul_c11_redesign_test.dart.
}
