import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 'generated/s8_timeline/s8_timeline_cases.g.dart';
import 'generated/s8_timeline/s8_timeline_season.g.dart';
import 'sandbox_play.dart';
import '../reading_finders.dart';

/// Puzzle Engine 2.0 STEP 1: five engines the game already played, made by
/// the season factory from a plan (`test/sandbox/plans/s8_timeline/cases/s8_ep02`):
/// two records compared, a keypad, traces read, the magnifying glass, and a
/// final talk in which evidence is shown — checked by the game's validator
/// and played in the real app with each engine's own controls.
void main() {
  const seasonId = 's8_timeline';
  final season = SeasonContent(
    info: s8TimelineInfoJson,
    episodes: s8TimelineEpisodes,
    places: s8TimelinePlaces,
    released: false,
    storyGreeting: s8TimelineStoryGreeting,
    learning: s8TimelineLearning,
    languageTopics: s8TimelineLanguageTopics,
    evidenceLinks: s8TimelineEvidenceLinks,
    explores: s8TimelineExplores,
    investigations: s8TimelineInvestigations,
    dialogues: s8TimelineDialogues,
    timelines: s8TimelineTimelines,
    deductions: s8TimelineDeductions,
    inspections: s8TimelineInspections,
    records: s8TimelineRecords,
    talks: s8TimelineTalks,
    talkMissions: s8TimelineTalkMissions,
    discoveries: s8TimelineDiscoveries,
    endings: s8TimelineEndings,
  );
  List<Episode> episodes() => [for (final json in season.episodes.values) Episode.fromJson(json)];
  Episode ep02() => episodes().firstWhere((e) => e.id == 's8_ep02');

  group('made by the factory', () {
    test("the game's validator takes it whole; each mission on its engine's table", () {
      expect(SeasonContentValidator.validate(season), isEmpty);
      final [m1, m2, m3, m4] = ep02().missions;
      final fin = ep02().finalMission;
      expect([m1.type, m2.type, m3.type, m4.type, fin.type],
          [MissionType.matchPairs, MissionType.numberCode, MissionType.multipleChoice, MissionType.wordInput, MissionType.examine]);
      expect(season.records.keys, [m1.id]);
      expect(season.deductions.keys, [m3.id]);
      expect(season.inspections.keys, [m4.id]);
      expect(season.talks.keys, [fin.id]);
      expect(season.talks[fin.id]!.answer, fin.answer);
    });

    test('one answer each: only the times disagree, only the stone, only the word', () {
      final [m1, m2, m3, m4] = ep02().missions;
      final ids = [for (final l in season.records[m1.id]!.first.lines) l.id];
      for (final a in ids) {
        for (final b in ids) {
          expect(AnswerChecker.isCorrect(m1, '$a:$b'), '$a:$b' == 'time:time', reason: '$a:$b');
        }
      }
      expect([AnswerChecker.isCorrect(m2, '417'), AnswerChecker.isCorrect(m2, '470')], [true, false]);
      expect([for (final o in m3.options) AnswerChecker.isCorrect(m3, o.id)], [false, true, false]);
      expect([AnswerChecker.isCorrect(m4, 'stone'), AnswerChecker.isCorrect(m4, 'STONE'), AnswerChecker.isCorrect(m4, 'rock')], [true, true, false]);
    });
  });

  group('played in the real app', () {
    setUp(() {
      SeasonCatalog.testPlaces.addAll(season.places);
      SeasonCatalog.testSeasons.add(season);
    });
    tearDown(() {
      SeasonCatalog.testPlaces.clear();
      SeasonCatalog.testSeasons.clear();
    });

    List<Override> overrides() => [
      seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, season.season]),
      allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...episodes()]),
      seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, seasonId: SeasonMap.paris}),
      seasonReleasedProvider.overrideWithValue((id) => id == seasonId || seasonReleased(id)),
      operatorToolsAvailableProvider.overrideWithValue(true),
    ];

    Future<ProviderContainer> open(WidgetTester t, SharedPreferences prefs, {required bool fresh}) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...overrides()]);
      addTearDown(c.dispose);
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      final ctrl = c.read(gameControllerProvider.notifier);
      if (fresh) ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(seasonId), isTrue);
      if (fresh) {
        // Case 01 is the timeline's (timeline_season_test): solved here to open Case 02.
        expect(ctrl.openEpisode('s8_ep01'), isTrue);
        for (final m in episodes().first.allMissions) {
          ctrl.submitAnswer(m, m.answer);
        }
        expect(ctrl.openEpisode('s8_ep02'), isTrue);
        ctrl.startInvestigation();
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      if (fresh) {
        c.read(routerProvider).go(Routes.intro);
        await wait(t, const Duration(milliseconds: 1500));
        await tapText(t, 'SKIP ›');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
      } else {
        c.read(routerProvider).go(Routes.map);
      }
      await wait(t, const Duration(milliseconds: 2500));
      return c;
    }

    testWidgets('records, keypad, traces, glass, then the talk: each solved with its own controls, saved, paid once', (t) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await open(t, prefs, fresh: true);
      final play = SandboxPlay(t);
      final mp = MissionPlay();
      final [m1, m2, m3, m4] = c.read(currentEpisodeProvider).missions;
      final fin = c.read(currentEpisodeProvider).finalMission;
      expect(c.read(currentEpisodeProvider).id, 's8_ep02');
      bool done(Mission m) => c.read(gameControllerProvider).isCompleted(m.id);
      // A scene engine may open on its scene, with no sealed letter first.
      Future<void> toPuzzle(Mission m) async {
        await play.toPlace(m);
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 1200));
        for (final step in ['TAP TO OPEN', 'SOLVE THE PUZZLE']) {
          if (findText(step).evaluate().isNotEmpty) await tapText(t, step, after: const Duration(milliseconds: 1500));
        }
      }

      // The Discovery Moment, then the map (these missions have no scene after).
      Future<void> onToMap() async {
        await wait(t, const Duration(milliseconds: 2800));
        await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
        if (find.text('TO THE MAP').evaluate().isNotEmpty) await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
        await wait(t, const Duration(milliseconds: 3200));
        expect(find.bySemanticsLabel(RegExp('^GO TO ')), findsWidgets, reason: play.texts());
      }

      // M1 — two records: each read, a wrong pair first, then the times.
      await toPuzzle(m1);
      for (final key in ['record-tab-log', 'record-tab-notice', 'line-notice-date', 'record-tab-log', 'line-log-date', 'records-check']) {
        await mp.tapKey(t, key);
      }
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      for (final key in ['record-tab-notice', 'line-notice-time', 'record-tab-log', 'line-log-time', 'records-check']) {
        await mp.tapKey(t, key);
      }
      await wait(t, const Duration(milliseconds: 1000));
      expect(done(m1), isTrue, reason: play.texts());
      await onToMap();

      // M2 — the keypad: its digits in the wrong order (the plan's line), then 417.
      await toPuzzle(m2);
      await play.wrong(m2, '714', line: 'Read the number words again.');
      await play.answer(m2, '417');
      expect(done(m2), isTrue, reason: play.texts());
      await onToMap();

      // M3 — the traces: all three noted, the bench (wrong), then the stone.
      await toPuzzle(m3);
      final traces = season.deductions[m3.id]!;
      await mp.noteClues(t, traces);
      await mp.chooseAndSearch(t, traces, 'a');
      await wait(t, const Duration(milliseconds: 500));
      expect(find.text('Not quite!'), findsOneWidget, reason: play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await mp.chooseAndSearch(t, traces, 'b');
      await wait(t, const Duration(milliseconds: 1200));
      expect(done(m3), isTrue, reason: play.texts());
      await onToMap();

      // M4 — the glass: the slab, its label, the word.
      await toPuzzle(m4);
      final room = season.inspections[m4.id]!;
      await mp.openInspectLabel(t, room);
      await mp.writeOnLabel(t, 'stone');
      await wait(t, const Duration(milliseconds: 1200));
      expect(done(m4), isTrue, reason: play.texts());

      // Closed and opened again: the four solved, the final next.
      c = await open(t, prefs, fresh: false);
      expect([for (final m in [m1, m2, m3, m4]) c.read(gameControllerProvider).isCompleted(m.id)], [true, true, true, true]);
      expect(c.read(gameControllerProvider).isCompleted(fin.id), isFalse);

      // The final talk: the wrong card, then the log; the toolbox; the case closed.
      final talk = season.talks[fin.id]!;
      final before = c.read(walletProvider).balance;
      await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
      Future<void> heard() async {
        for (var i = 0; i < 8 && find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty; i++) {
          await mp.tapKey(t, 'case-talk-next', after: const Duration(milliseconds: 500));
        }
      }

      await heard();
      expect(find.byKey(const ValueKey('case-talk-choice-s8_ep02_e2')), findsOneWidget, reason: play.texts());
      await mp.tapKey(t, 'case-talk-choice-s8_ep02_e2', after: const Duration(milliseconds: 600));
      await heard();
      expect(done(fin), isFalse, reason: 'a miss is never wrong, never solved');
      await mp.tapKey(t, 'case-talk-choice-s8_ep02_e1', after: const Duration(milliseconds: 600));
      await heard();
      expect(talk.present('tools')!.accepted, {'s8_ep02_e3'});
      await mp.tapKey(t, 'case-talk-choice-s8_ep02_e3', after: const Duration(milliseconds: 600));
      await heard();
      await mp.tapKey(t, 'case-talk-finish', after: const Duration(milliseconds: 1500));
      expect(done(fin), isTrue, reason: play.texts());
      final paid = c.read(walletProvider).balance - before;
      expect(paid, greaterThan(0));
      expect(c.read(gameControllerProvider.notifier).submitAnswer(fin, fin.answer).coins, 0);
      expect(c.read(walletProvider).balance - before, paid);
      expect(t.takeException(), isNull);
    });
  });
}

