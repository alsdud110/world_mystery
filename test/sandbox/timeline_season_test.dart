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
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/timeline_rules.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/season_cases.dart';
import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import 'generated/s8_timeline/s8_timeline_cases.g.dart';
import 'generated/s8_timeline/s8_timeline_season.g.dart';
import 'sandbox_play.dart';

/// Puzzle Engine 2.0 PART 3C: a timeline made by the season factory from
/// its plan (`test/sandbox/plans/s8_timeline/`, the sandbox's Case 01 with
/// its Mission 2 a timeline), checked by the game's validator and played in
/// the real app. A test-only season: never in `SeasonCatalog.all`.
void main() {
  const plans = 'test/sandbox/plans/s8_timeline';
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

  group('made by the factory', () {
    test('what the plans make now, byte for byte, the same twice', () {
      Generated make() => CaseGenerator.sandbox(seasonPath: '$plans/season.plan.json', casePaths: SeasonCases.of('$plans/season.plan.json'));
      final made = make();
      expect(GeneratedFiles.stale('test/sandbox/generated/$seasonId', made.files), isEmpty,
          reason: 'run: dart run tool/season_gen/generate_season.dart --season $plans/season.plan.json --target sandbox');
      expect(make().files, made.files);
    });

    test('the game\'s validator takes it whole; its timeline the mission\'s', () {
      expect(SeasonContentValidator.validate(season), isEmpty);
      final m = episodes().first.missions[1];
      final spec = season.timelines[m.id]!;
      expect([m.type, const TimelineRules().answer(spec), m.answer], [MissionType.sequence, 'key,tom,bell,lee', 'key,tom,bell,lee']);
      expect(const TimelineRules().validate(spec), isEmpty);
      expect(SeasonCatalog.all.any((s) => s.id == seasonId), isFalse);
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
        expect(ctrl.openEpisode('s8_ep01'), isTrue);
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

    Finder slot(int i) => find.byKey(ValueKey('timeline-slot-$i'));
    Finder card(String id) => find.byKey(ValueKey('timeline-card-$id'));
    Future<void> tap(WidgetTester t, Finder f) async {
      await t.ensureVisible(f);
      await wait(t, const Duration(milliseconds: 200));
      await t.tap(f);
      await wait(t, const Duration(milliseconds: 200));
    }

    String label(WidgetTester t, Finder f) => t.getSemantics(f).label;

    testWidgets('Mission 1, then the timeline: wrong, a hint, closed and opened again, right, paid once, shown solved', (t) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await open(t, prefs, fresh: true);
      final play = SandboxPlay(t);
      final [m1, m2, ...] = c.read(currentEpisodeProvider).missions;

      await play.toPuzzle(m1);
      await play.answer(m1, m1.answer);
      await play.onToMap(m1);

      // The timeline the factory made: the key fixed at 9:00, the rest on the table.
      await play.toPuzzle(m2);
      expect(label(t, slot(0)), contains('fixed, 9:00, THE KEY'), reason: play.texts());
      for (final id in ['tom', 'bell', 'lee', 'cat']) {
        expect(card(id), findsOneWidget, reason: id);
      }

      // Wrong: Mr. Bell before Tom; the cat set aside.
      for (final (id, i) in [('bell', 1), ('tom', 2), ('lee', 3)]) {
        await tap(t, card(id));
        await tap(t, slot(i));
      }
      await tap(t, card('cat'));
      await tap(t, find.byKey(const ValueKey('timeline-pile')));
      await tap(t, find.text('CHECK THE ORDER'));
      expect(find.textContaining('Who came after Tom?'), findsWidgets, reason: 'the plan\'s own wrong-order line: ${play.texts()}');
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      expect(find.text('CHECK THIS ONE'), findsOneWidget);
      expect(find.byKey(const ValueKey('timeline-problem-line')), findsOneWidget);
      await tap(t, find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 900));
      expect(findReadableContaining('Look for first, after and last.'), findsWidgets, reason: play.texts());

      // Closed and opened again: the cards as they were left.
      final saved = c.read(gameControllerProvider).puzzleStateOf(m2.id);
      expect(PuzzleStateCodec.decode(const TimelineRules(), season.timelines[m2.id]!, saved)!.slots, ['key', 'bell', 'tom', 'lee']);
      c = await open(t, prefs, fresh: false);
      await t.tap(find.bySemanticsLabel('GO TO ${m2.location}'));
      await wait(t, const Duration(milliseconds: 2800));
      expect(label(t, slot(1)), contains('MR. BELL'), reason: play.texts());
      expect(label(t, card('cat')), contains('not part of it'));

      // Right: Tom and Mr. Bell swapped.
      final before = c.read(walletProvider).balance;
      await tap(t, slot(2));
      await tap(t, slot(1));
      await tap(t, find.text('CHECK THE ORDER'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCompleted(m2.id), isTrue, reason: play.texts());
      final paid = c.read(walletProvider).balance - before;
      expect(paid, greaterThan(0));
      await play.onToMap(m2);
      expect(c.read(gameControllerProvider.notifier).submitAnswer(m2, m2.answer).coins, 0);
      expect(c.read(walletProvider).balance - before, paid);

      // Opened again: the timeline as it happened.
      c.read(routerProvider).go(Routes.mission(m2.id));
      await wait(t, const Duration(milliseconds: 1500));
      // Under the solved page's words and clue: scrolled to.
      await t.dragUntilVisible(find.text('WHAT HAPPENED'), find.byType(ListView).first, const Offset(0, -300));
      await t.pump();
      expect(find.text('WHAT HAPPENED'), findsOneWidget);
      expect(find.text('CHECK THE ORDER'), findsNothing);
      expect([for (var i = 0; i < 4; i++) label(t, slot(i)).contains(['THE KEY', 'TOM', 'MR. BELL', 'MRS. LEE'][i])], [true, true, true, true]);
    });
  });
}
