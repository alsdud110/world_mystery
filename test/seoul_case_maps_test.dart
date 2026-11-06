import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/mission_map/mission_map_screen.dart';
import 'package:world_mystery/features/season/widgets/season_props.dart';

import '../tool/season_gen/content_hash.dart';
import '../tool/season_gen/plan_check.dart';
import '../tool/season_gen/plan_files.dart';
import '../tool/season_gen/plan_models.dart';
import 'helpers.dart';
import 'multi_season_test.dart' show assetOf;

const palaceMap = 'assets/seasons/season_05_seoul/locations/map/palace_map.webp';
const seasonMapFile = 'assets/seasons/season_05_seoul/locations/map/season_map.webp';
const seasonPlan = 'content_pipeline/seasons/s5_seoul/season.plan.json';
const case01Plan = 'content_pipeline/seasons/s5_seoul/cases/s5_ep01/case.plan.json';

/// Case 01's missions at their places, measured on the palace map's pixels.
const case01Spots = <String, (String, Offset)>{
  's5_ep01_m1': ('The Inner Gate', Offset(768 / 1536, 760 / 1024)),
  's5_ep01_m2': ('The Well Yard', Offset(1310 / 1536, 425 / 1024)),
  's5_ep01_m3': ('The Writing Room', Offset(1280 / 1536, 205 / 1024)),
  's5_ep01_final': ('The Book Hall', Offset(265 / 1536, 365 / 1024)),
};

void main() {
  final seoul = SeasonMap.forSeason(SeasonIds.seoul)!;
  Episode seoulCase(String id) => MockEpisodeRepository.bundled().firstWhere((e) => e.id == id);

  group('a case\'s own map', () {
    test('Case 01 is played on the palace map, measured on the very file', () {
      final map = seoul.forCase('s5_ep01');
      expect(map.artwork, palaceMap);
      expect(map.pixels, const Size(1536, 1024));
      expect(map.aspect, 3 / 2);
      final planned = PlanFiles.loadSeasonPlan(seasonPlan).art!.caseMaps['s5_ep01']!;
      expect(planned.measuredOn, ContentHash.ofBytes(File(palaceMap).readAsBytesSync()));
    });

    test('a case without its own map stays on the season map', () {
      for (var n = 2; n <= 12; n++) {
        final id = 's5_ep${n.toString().padLeft(2, '0')}';
        expect(seoul.forCase(id), same(seoul), reason: id);
      }
    });

    test('the season keeps its map on every other screen', () {
      expect(seoul.artwork, seasonMapFile);
      expect(SeasonMap.ofMission('s5_ep01_m1')!.artwork, seasonMapFile);
      expect(MapPrint.ofSeason(SeasonIds.seoul).file, seasonMapFile, reason: 'the season board');
      expect(SeasonMap.landmarkOf('s5_ep01_m1')!.name, 'The Royal Palace, Hanyang');
    });

    test('Case 01\'s four missions stand at their four places, apart', () {
      final episode = seoulCase('s5_ep01');
      final map = seoul.forCase(episode.id);
      final places = MapWorld.places(episode, map: map);
      expect(places.keys, unorderedEquals(case01Spots.keys));
      for (final MapEntry(key: id, value: (name, at)) in case01Spots.entries) {
        expect(places[id], at, reason: id);
        expect(map.landmarkFor(id, episode.id)!.name, name, reason: id);
        expect(episode.allMissions.firstWhere((m) => m.id == id).location.toLowerCase(), name.toLowerCase(), reason: id);
      }
      expect({for (final p in places.values) p}, hasLength(4));
    });

    test('the other seasons have none: their places are as they were', () {
      for (final id in [SeasonIds.london, SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork]) {
        final map = SeasonMap.forSeason(id)!;
        expect(map.caseMaps, isEmpty, reason: id);
        expect(map.missionPoints, isEmpty, reason: id);
        for (final e in MockEpisodeRepository.bundled().where((e) => e.seasonId == id)) {
          expect(map.forCase(e.id), same(map), reason: e.id);
        }
      }
    });
  });

  group('the plan check', () {
    Map<String, Object?> plan(void Function(Map<String, dynamic> case01) change) {
      final json = PlanFiles.readJson(seasonPlan) as Map<String, dynamic>;
      change((json['art'] as Map<String, dynamic>)['caseMaps']['s5_ep01'] as Map<String, dynamic>);
      return json;
    }

    List<String> seasonIssues(Map<String, Object?> json) => [for (final i in PlanCheck.season(SeasonPlan.fromJson(json))) i.message];

    List<String> caseIssues(Map<String, Object?> json) =>
        [for (final i in PlanCheck.casePlan(PlanFiles.loadCasePlan(case01Plan), season: SeasonPlan.fromJson(json))) i.message];

    test('finds nothing wrong in Seoul\'s plan', () {
      expect(seasonIssues(plan((_) {})), isEmpty);
      expect(caseIssues(plan((_) {})), isEmpty);
    });

    test('a spot where no pin fits', () {
      final json = plan((c) => c['landmarks'][2]['missions']['s5_ep01_m3'] = [1280, 100]);
      expect(seasonIssues(json), [contains('a pin fits in')]);
    });

    test('two spots on top of each other', () {
      final json = plan((c) => c['landmarks'][2]['missions']['s5_ep01_m3'] = [1310, 440]);
      expect(seasonIssues(json), [contains('too close to s5_ep01_m2')]);
    });

    test('a mission left off, a mission at another place, a mission of another case', () {
      expect(caseIssues(plan((c) => c['landmarks'][3]['missions'] = {})), [contains('s5_ep01_final has no spot')]);
      expect(caseIssues(plan((c) => c['landmarks'][3]['name'] = 'The Library')), [contains('happens at THE BOOK HALL')]);
      expect(caseIssues(plan((c) => c['landmarks'][3]['missions']['s5_ep02_m1'] = [300, 500])), [contains('s5_ep02_m1 is not a mission')]);
    });

    test('a case the season does not have', () {
      final json = PlanFiles.readJson(seasonPlan) as Map<String, dynamic>;
      final maps = (json['art'] as Map<String, dynamic>)['caseMaps'] as Map<String, dynamic>;
      maps['s5_ep13'] = maps['s5_ep01'];
      expect(seasonIssues(json), [contains('s5_ep13 is not a case')]);
    });
  });

  group('on the map page', () {
    Future<ProviderContainer> playSeoul(String caseId) async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.boy);
      // The seasons before it finished: Seoul is open.
      final repo = c.read(progressRepositoryProvider);
      for (final (season, prefix) in [(SeasonIds.london, 'ep'), (SeasonIds.paris, 's2_ep'), (SeasonIds.rome, 's3_ep'), (SeasonIds.newyork, 's4_ep')]) {
        final ids = [for (var n = 1; n <= 12; n++) '$prefix${n.toString().padLeft(2, '0')}'];
        repo.saveSeason(SeasonProgress(activeEpisodeId: ids.last, solvedEpisodeIds: ids), season);
      }
      c.invalidate(seasonProvider);
      expect(ctrl.openSeason(SeasonIds.seoul), isTrue);
      if (caseId != 's5_ep01') c.read(operatorAccessSwitchProvider.notifier).set(true); // open a later case
      expect(c.read(gameControllerProvider.notifier).openEpisode(caseId), isTrue);
      c.read(gameControllerProvider.notifier).startInvestigation();
      return c;
    }

    void solve(ProviderContainer c, String missionId) {
      final ctrl = c.read(gameControllerProvider.notifier);
      final m = c.read(currentEpisodeProvider).allMissions.firstWhere((m) => m.id == missionId);
      ctrl.markMissionStarted(m.id);
      expect(ctrl.submitAnswer(m, m.answer).result, SubmitResult.correct);
    }

    Future<void> pumpMap(WidgetTester t, ProviderContainer c) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: MissionMapScreen())));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump(const Duration(milliseconds: 1500));
    }

    bool shows(String artwork) => find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == artwork).evaluate().isNotEmpty;
    Finder named(String name) => find.byKey(ValueKey('landmark-name-$name'));

    testWidgets('Case 01 opens on the palace map, no place named before it is open', (t) async {
      final c = await playSeoul('s5_ep01');
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(shows(palaceMap), isTrue);
      expect(shows(seasonMapFile), isFalse);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m2')), findsNothing);
      // The Inner Gate is named by its pin; the others are not open yet.
      for (final name in ['The Inner Gate', 'The Well Yard', 'The Writing Room', 'The Book Hall']) {
        expect(named(name), findsNothing, reason: name);
      }
      expect(find.text("YOU'RE HERE", findRichText: true), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('a solved place keeps its name, the next one is named by its pin, the rest stay hidden', (t) async {
      final c = await playSeoul('s5_ep01');
      addTearDown(c.dispose);
      solve(c, 's5_ep01_m1');
      await pumpMap(t, c);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m2')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m3')), findsNothing);
      expect(named('The Inner Gate'), findsOneWidget);
      for (final name in ['The Well Yard', 'The Writing Room', 'The Book Hall']) {
        expect(named(name), findsNothing, reason: name);
      }
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('moving to a case without its own map brings back the season map and its names', (t) async {
      final c = await playSeoul('s5_ep02');
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(shows(seasonMapFile), isTrue);
      expect(shows(palaceMap), isFalse);
      expect(named('Harbin'), findsOneWidget, reason: 'the season map names every place, as it always did');
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });
  });
}
