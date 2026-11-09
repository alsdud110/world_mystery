import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/mock/season_catalog.dart' show SeasonContent;
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart' show operatorAccessProvider;

import '../full_playthrough_test.dart' show tapText, wait;
import 'single_case.dart';

/// Seoul Case 11 redesigned (PART 4, docs/SEOUL_CASE02_12_REDESIGN_PLAN.md
/// §C3): M1 WATER (Miri's sign), M2 Yun's list against Miri's card, M3
/// PIANO (keys of black and white), and the final: Miri's talk, then her
/// lock 319, read only on this case's list. The same game at every level.
void main() {
  final season = season5Content;
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes['s5_ep11']!, 'seasonId': season.id}),
    level,
    patches: season.casePatches,
  );

  group('the content, at every level', () {
    for (final level in Difficulty.values) {
      test(level.label, () {
        final ep = episode(level);
        final [m1, m2, m3] = ep.missions;
        final fin = ep.finalMission;
        final all = [...ep.intro, for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition]].join('\n');

        // M1: Miri's sign, from what Yun says; never told before it is found.
        expect(m1.answer, 'WATER');
        expect(m1.letter, allOf(contains('red spine'), contains('brings water')), reason: level.label);
        expect(m1.letter, isNot(contains('drop of ____')), reason: 'Yun does not say what he has not seen');
        for (final w in ['INK', 'RAIN']) {
          expect(AnswerChecker.feedbackFor(m1, w), isNotNull, reason: '${level.label} $w');
        }

        // M2 kept: the string line, the card's last words.
        expect(m2.answer, 'string:string');
        expect(m2.transition.join(' '), contains('keys of these colours'));
        expect([...m2.story, m2.letter, ...m2.transition].join(' ').toLowerCase(), isNot(contains('piano')), reason: 'M3 reasons out the piano');

        // M3: PIANO, from the two meanings of keys and the colours.
        expect(m3.type, MissionType.wordInput);
        expect(m3.answer, 'PIANO');
        expect(m3.letter, allOf(contains('keys of these colours'), contains('all black'), contains('They have no keys.')));
        for (final ok in ['piano', 'THE PIANO', 'piano keys']) {
          expect(AnswerChecker.isCorrect(m3, ok), isTrue, reason: '${level.label} $ok');
        }
        for (final wrong in ['KEYS', 'DOOR KEYS', 'JACKETS', 'SHIRTS', 'CLOTHES', 'LANTERN', 'STAGE']) {
          expect(AnswerChecker.isCorrect(m3, wrong), isFalse);
          expect(AnswerChecker.feedbackFor(m3, wrong), isNotNull, reason: '${level.label} $wrong');
        }
        expect(m3.recall, isNull, reason: "Yun's list is shown in the final's talk instead");

        // Final: 319, every number on this case's list; never written before.
        expect(fin.type, MissionType.numberCode);
        expect(fin.answer, '319');
        expect(fin.letter, allOf(contains('2 of 3'), contains('18 + 1 opening poem'), contains('side by side'), contains('215')));
        expect(fin.letter.split('\n'), hasLength(4), reason: 'the same four lines at every level');
        expect(all, isNot(contains('319')), reason: level.label);
        expect(all.toLowerCase(), isNot(contains('nineteen')), reason: level.label);
        for (final wrong in ['119', '219', '318', '215']) {
          expect(AnswerChecker.feedbackFor(fin, wrong), isNotNull, reason: '${level.label} $wrong');
        }
        expect(AnswerChecker.feedbackFor(fin, '193'), fin.orderFeedback);

        // Standalone: no other case's people, box or letters.
        for (final w in ['Bun-i', 'Haesu', 'keeper', 'letter box', 'King Sejong', 'Chongqing', 'Sora']) {
          expect(all, isNot(contains(w)), reason: '${level.label}: $w');
        }
      });
    }

    test("the final's talk: Yun's list is the card to show; Miri's card and the box are not", () {
      final talk = season.talkMissions['s5_ep11_final']!.before!;
      final list = talk.presents.single;
      expect(list.choices, ['s5_ep11_e1', 's5_ep11_e3', 's5_ep11_e2']);
      expect(list.accepted, {'s5_ep11_e2'});
      expect(list.litAfter, 3);
    });

    test('the same game at every level: answers and the number of lines', () {
      final r = episode(Difficulty.rookie);
      for (final level in [Difficulty.junior, Difficulty.master]) {
        final e = episode(level);
        expect([for (final m in e.allMissions) m.answer], [for (final m in r.allMissions) m.answer]);
        expect([for (final m in e.allMissions) m.letter.split('\n').length], [for (final m in r.allMissions) m.letter.split('\n').length]);
        expect(e.finalMission.letter, isNot(r.finalMission.letter), reason: '${level.label}: its own English');
      }
    });
  });

  for (final level in Difficulty.values) {
    testWidgets('s5_ep11 at ${level.label}: M1 → M2 → M3 (KEYS refused) → Final talk → 219 refused → 319', (t) async {
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
      await p.answer(m3, 'KEYS');
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

class _Case11 extends SingleCase {
  _Case11(SeasonContent season, Difficulty level) : super(season, 's5_ep11', level: level);

  @override
  List<Override> overrides() => [...super.overrides(), operatorAccessProvider.overrideWithValue(true)];
}
