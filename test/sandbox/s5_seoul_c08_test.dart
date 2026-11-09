import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 08 "The Fire on the Hill" (PART 3): Mission 3 chooses the
/// note's writer by two things (letters and mark); the final's dial is set by
/// the detective, from the two clues it pictures (map: the plan's night
/// before; clock: the messengers' day). Same game at every level.
void main() {
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep08']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, Difficulty level) => episode(level).allMissions.firstWhere((m) => m.id == id);

  for (final level in Difficulty.values) {
    group(level.label, () {
      test('M3: a choice, not a spelled name; only Gyeongsun matches both features, every wrong one is told why', () {
        final m = mission('s5_ep08_m3', level);
        expect(m.type, MissionType.multipleChoice);
        expect(m.answer, 'gyeongsun');
        expect(m.options.map((o) => o.id), ['sunja', 'gwansun', 'gyeongsun', 'okhui'], reason: 'never the answer first');
        for (final wrong in ['sunja', 'gwansun', 'okhui']) {
          expect(AnswerChecker.isCorrect(m, wrong), isFalse);
          expect(AnswerChecker.feedbackFor(m, wrong), isNotNull, reason: wrong);
        }
        // Sunja shares one feature (only Hangeul), so the second (the mark) decides.
        final sunja = m.letter.split('\n').firstWhere((l) => l.startsWith("Sunja's"));
        expect(sunja, allOf(contains('only in Hangeul'), contains('flower')));
        final gyeongsun = m.letter.split('\n').firstWhere((l) => l.startsWith("Gyeongsun's"));
        expect(gyeongsun, allOf(contains('only in Hangeul'), matches(RegExp('[Aa] small flame sits by her name'))));
      });

      test('Final: the dials picture their clues; the letter never gives the date away', () {
        final f = mission('s5_ep08_final', level);
        expect(f.answer, '311');
        expect(f.dialSymbols, ['map', 'map', 'clock']);
        expect(f.letter, contains('March has thirty-one days.'));
        // Both clues are needed: neither the day of the march nor "the night before" is in the letter.
        expect(f.letter, isNot(contains('first of April')));
        expect(f.letter, isNot(contains('night before')));
        for (final wrong in ['131', '301', '302', '312', '012']) {
          expect(AnswerChecker.isCorrect(f, wrong), isFalse);
          expect(AnswerChecker.feedbackFor(f, wrong), isNotNull, reason: wrong);
        }
        final ms = episode(level).allMissions;
        expect(ms.firstWhere((m) => m.id == 's5_ep08_m1').clue!.symbol, 'clock');
        expect(ms.firstWhere((m) => m.id == 's5_ep08_m2').clue!.symbol, 'map');
      });

      test('Final: Gyeongsun asks, the detective locks: no line says she set it herself', () {
        final f = mission('s5_ep08_final', level);
        final words = [...f.story, f.letterIntro, f.letter, f.question, f.successMessage].join('\n');
        expect(words, isNot(contains('I set the lock')));
        expect(words, isNot(contains('The lock is set')));
        expect(f.story.last, startsWith('"Set the lock'));
        expect(f.successMessage, contains('locked'));
      });

      test('stands alone: no Bun-i, letter box, keepers or water drop', () {
        final e = episode(level);
        final text = [
          ...e.intro,
          for (final m in e.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition, m.successMessage],
        ].join('\n');
        for (final w in ['Bun-i', 'letter box', 'keeper', 'water drop', '엄마', '1446']) {
          expect(text, isNot(contains(w)), reason: w);
        }
      });
    });
  }
}
