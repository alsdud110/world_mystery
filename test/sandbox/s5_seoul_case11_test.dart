import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/mock/season_catalog.dart' show SeasonContent;
import 'package:world_mystery/data/models/tower_puzzles.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart' show operatorAccessProvider;

import '../full_playthrough_test.dart' show tapText, wait;
import 'single_case.dart';

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
        expect(m2.transition.join(' ').toLowerCase(), allOf(contains('keys of these colours'), contains('black and white keys')));
        expect(m1.transition.last, contains('card'), reason: 'M1 hands on to the card');
        expect(m3.story.join(' '), allOf(contains('piano'), contains('black and white')));

        // M3: the lock read on Yun's list (recalled), 319 as before.
        expect(m3.answer, '319');
        expect(m3.recall, isNotNull);
        expect(m3.letter, allOf(contains('2 of 3'), contains('18 + 1 opening poem')));
        expect(AnswerChecker.isCorrect(m3, '319'), isTrue);
        for (final wrong in ['219', '318', '119']) {
          expect(AnswerChecker.feedbackFor(m3, wrong), isNotNull, reason: '${level.label} $wrong');
        }

        // Final unchanged: KOREAN.
        expect(fin.answer, 'KOREAN');
        expect(AnswerChecker.isCorrect(fin, 'korean'), isTrue);

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

  for (final level in Difficulty.values) {
    testWidgets('s5_ep11 at ${level.label}: M1 → M2 (an agreeing pair refused) → M3 (219 refused) → Final', (t) async {
      final one = _Case11(season, level)..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = await one.open(t, prefs, fresh: true);
      final p = CasePlayer(t, season);
      final ep = one.episode;
      bool done(String id) => c.read(gameControllerProvider).isCompleted(id);
      int wrong(String id) => c.read(gameControllerProvider).wrongAnswers[id] ?? 0;

      final [m1, m2, m3] = ep.missions;
      await p.toPuzzle(m1);
      await p.answer(m1);
      expect(done(m1.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      await p.toPuzzle(m2);
      await p.answer(m2, 'poems:poems');
      expect([done(m2.id), wrong(m2.id)], [false, 1], reason: p.play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await p.answer(m2);
      expect(done(m2.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      await p.toPuzzle(m3);
      await p.answer(m3, '219');
      expect([done(m3.id), wrong(m3.id)], [false, 1], reason: p.play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await p.answer(m3);
      expect(done(m3.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      await p.solveFinal(ep.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(ep.finalMission.id), isTrue, reason: p.play.texts());
      expect(t.takeException(), isNull);
    });
  }
}

/// Case 11 opened alone: the cases before it are not played here (the whole
/// season in order is `test/generated_seasons_test.dart`), so it is opened
/// as the operator opens any case.
class _Case11 extends SingleCase {
  _Case11(SeasonContent season, Difficulty level) : super(season, 's5_ep11', level: level);

  @override
  List<Override> overrides() => [...super.overrides(), operatorAccessProvider.overrideWithValue(true)];
}
