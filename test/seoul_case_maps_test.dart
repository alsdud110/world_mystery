import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:world_mystery/features/mission_map/widgets/map_pin.dart';
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
  // V4 (2026-11-07): Bun-i at the kitchen well first, Sora's lesson by the inner gate.
  's5_ep01_m1': ('The Kitchen Well', Offset(1310 / 1536, 425 / 1024)),
  's5_ep01_m2': ('The Inner Gate', Offset(768 / 1536, 760 / 1024)),
  's5_ep01_m3': ('The Writing Room', Offset(1280 / 1536, 205 / 1024)),
  's5_ep01_final': ("The King's Study", Offset(265 / 1536, 365 / 1024)),
};

/// Cases 02-12 on their own maps: each mission's place and spot, in pixels.
const ownMaps = <String, Map<String, (String, double, double)>>{
  's5_ep02': {
    's5_ep02_m1': ('The Store Room', 335, 650),
    's5_ep02_m2': ('The Store Room', 430, 400),
    's5_ep02_m3': ('The Turtle Ship', 1240, 570),
    's5_ep02_final': ('The Turtle Ship', 1030, 625),
  },
  's5_ep03': {
    's5_ep03_m1': ('The Stone Yard', 715, 620),
    's5_ep03_m2': ('The Drawing Room', 255, 285),
    's5_ep03_m3': ('The Stone Yard', 930, 730),
    's5_ep03_final': ('The New Wall', 1190, 285),
  },
  's5_ep04': {
    's5_ep04_m1': ('The Timber Yard', 290, 660),
    's5_ep04_m2': ('The Yard Office', 810, 790),
    's5_ep04_m3': ('The Palace Site', 960, 460),
    's5_ep04_final': ('The Palace Site', 1160, 300),
  },
  's5_ep05': {
    's5_ep05_m1': ('The Lamp House', 705, 905),
    's5_ep05_m2': ("The Queen's Court", 1047, 360),
    's5_ep05_m3': ("The Queen's Court", 1175, 265),
    's5_ep05_final': ("Jangandang, The King's Hall", 345, 345),
  },
  's5_ep06': {
    's5_ep06_m1': ('The Palace Garden', 1027, 400),
    's5_ep06_m2': ('The Palace Garden', 1100, 853),
    's5_ep06_m3': ('The West Lane', 640, 640),
    's5_ep06_final': ("Yi Jun's House", 287, 640),
  },
  's5_ep07': {
    's5_ep07_m1': ("Mrs. Kang's Inn", 215, 840),
    's5_ep07_m2': ('The Station Tea Room', 1013, 433),
    's5_ep07_m3': ('Harbin Station', 1180, 288), // Mr. Pak on the platform (2026-11-11)
    's5_ep07_final': ("Mrs. Kang's Inn", 820, 587),
  },
  's5_ep08': {
    's5_ep08_m1': ('Aunae Market', 360, 640),
    's5_ep08_m2': ("Gwan-sun's Home", 1130, 725),
    's5_ep08_m3': ("Gwan-sun's Home", 1240, 660),
    's5_ep08_final': ('Maebong Hill', 833, 160),
  },
  's5_ep09': {
    's5_ep09_m1': ('A Lane in Shanghai', 360, 693),
    's5_ep09_m2': ('The Government Office', 967, 330),
    's5_ep09_m3': ('The Government Office', 1150, 350),
    's5_ep09_final': ('The Government Office', 1345, 400),
  },
  's5_ep10': {
    's5_ep10_m1': ('A Small House in Shanghai', 237, 768),
    's5_ep10_m2': ('A Small House in Shanghai', 554, 782),
    's5_ep10_m3': ('A Small House in Shanghai', 963, 824),
    's5_ep10_final': ("Haesu's Room", 1236, 210),
  },
  's5_ep11': {
    's5_ep11_m1': ("Yun's Room", 196, 342),
    's5_ep11_m2': ("Yun's Room", 680, 230),
    's5_ep11_m3': ('The College Hall', 1257, 321),
    's5_ep11_final': ('The College Gate', 691, 824),
  },
  's5_ep12': {
    's5_ep12_m1': ('The Government Office', 335, 279),
    's5_ep12_m2': ("Bitna's Room", 1131, 398),
    's5_ep12_m3': ('The Government Office', 691, 237),
    's5_ep12_final': ('The River Steps', 1145, 824),
  },
};

String mapFile(String caseId) => 'assets/seasons/season_05_seoul/locations/map/case_${caseId.substring(5)}_map.webp';

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

    test('every Seoul case has its own map, each on its own file', () {
      final files = {for (var n = 1; n <= 12; n++) seoul.forCase('s5_ep${n.toString().padLeft(2, '0')}').artwork};
      expect(files, hasLength(12));
      expect(files, isNot(contains(seasonMapFile)));
      expect(files.every((f) => File(f).existsSync()), isTrue);
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

    for (final MapEntry(key: caseId, value: spots) in ownMaps.entries) {
      test('$caseId is played on its own map, each mission at its spot, on the file it was measured on', () {
        final episode = seoulCase(caseId);
        final map = seoul.forCase(caseId);
        expect(map.artwork, mapFile(caseId));
        expect(map.pixels, const Size(1536, 1024));
        final planned = PlanFiles.loadSeasonPlan(seasonPlan).art!.caseMaps[caseId]!;
        expect(planned.measuredOn, ContentHash.ofBytes(File(map.artwork).readAsBytesSync()));
        final places = MapWorld.places(episode, map: map);
        expect(places.keys, unorderedEquals(spots.keys));
        for (final MapEntry(key: id, value: (name, x, y)) in spots.entries) {
          expect(places[id], Offset(x / 1536, y / 1024), reason: id);
          expect(map.landmarkFor(id, caseId)!.name, name, reason: id);
          expect(episode.allMissions.firstWhere((m) => m.id == id).location.toLowerCase(), name.toLowerCase(), reason: id);
        }
        expect({for (final p in places.values) p}, hasLength(4), reason: 'four missions, four pins, even at two places');
      });
    }

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
      expect(seasonIssues(json), [contains('too close to s5_ep01_m1')]);
    });

    test('a mission left off, a mission at another place, a mission of another case', () {
      expect(caseIssues(plan((c) => c['landmarks'][3]['missions'] = {})), [contains('s5_ep01_final has no spot')]);
      expect(caseIssues(plan((c) => c['landmarks'][3]['name'] = 'The Library')), [contains("happens at THE KING'S STUDY")]);
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
    // The game's letters: whether a name fits is a question of their widths.
    setUpAll(() async {
      for (final (family, file) in [
        ('Sentient', 'Sentient-Variable.ttf'),
        ('IMFellEnglishSC', 'IMFellEnglishSC-Regular.ttf'),
        ('LibreBaskerville', 'LibreBaskerville.ttf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load('assets/fonts/$file'))).load();
      }
    });

    Future<ProviderContainer> play(String caseId, {String season = SeasonIds.seoul}) async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.boy);
      // The seasons before it finished: Seoul is open.
      final repo = c.read(progressRepositoryProvider);
      for (final (before, prefix) in [(SeasonIds.london, 'ep'), (SeasonIds.paris, 's2_ep'), (SeasonIds.rome, 's3_ep'), (SeasonIds.newyork, 's4_ep')]) {
        if (before == season) break;
        final ids = [for (var n = 1; n <= 12; n++) '$prefix${n.toString().padLeft(2, '0')}'];
        repo.saveSeason(SeasonProgress(activeEpisodeId: ids.last, solvedEpisodeIds: ids), before);
      }
      c.invalidate(seasonProvider);
      expect(ctrl.openSeason(season), isTrue);
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
      final c = await play('s5_ep01');
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(shows(palaceMap), isTrue);
      expect(shows(seasonMapFile), isFalse);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m2')), findsNothing);
      // The Kitchen Well is named by its pin; the others are not open yet.
      for (final name in ['The Kitchen Well', 'The Inner Gate', 'The Writing Room', "The King's Study"]) {
        expect(named(name), findsNothing, reason: name);
      }
      expect(find.text("YOU'RE HERE", findRichText: true), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('a solved place keeps its name, the next one is named by its pin, the rest stay hidden', (t) async {
      final c = await play('s5_ep01');
      addTearDown(c.dispose);
      solve(c, 's5_ep01_m1');
      await pumpMap(t, c);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m2')), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s5_ep01_m3')), findsNothing);
      expect(named('The Kitchen Well'), findsOneWidget);
      for (final name in ['The Inner Gate', 'The Writing Room', "The King's Study"]) {
        expect(named(name), findsNothing, reason: name);
      }
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    for (final caseId in ownMaps.keys) {
      testWidgets('$caseId opens on its own map, the places not open yet not named', (t) async {
        final c = await play(caseId);
        addTearDown(c.dispose);
        await pumpMap(t, c);
        expect(shows(mapFile(caseId)), isTrue);
        expect(shows(seasonMapFile), isFalse);
        expect(shows(palaceMap), isFalse);
        for (final (name, _, _) in ownMaps[caseId]!.values) {
          expect(named(name), findsNothing, reason: name);
        }
        expect(t.takeException(), isNull);
        await t.pump(const Duration(seconds: 3));
      });
    }

    for (final (caseId, name) in [('s5_ep09', 'THE GOVERNMENT OFFICE'), ('s5_ep10', 'A SMALL HOUSE IN SHANGHAI')]) {
      testWidgets('a long place name under the pin loses no word: $name', (t) async {
        final c = await play(caseId);
        addTearDown(c.dispose);
        solve(c, '${caseId}_m1');
        await pumpMap(t, c);
        await t.pump(const Duration(seconds: 3)); // the pin opens first
        final lettering = t.widget<MapLettering>(find.byWidgetPredicate((w) => w is MapLettering && w.text == name));
        final painter = TextPainter(
          text: TextSpan(text: lettering.text, style: lettering.style),
          maxLines: lettering.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: MapPin.width);
        expect(painter.didExceedMaxLines, isFalse);
        painter.dispose();
        expect(t.takeException(), isNull);
        await t.pump(const Duration(seconds: 3));
      });
    }

    testWidgets('a season without case maps still plays on its season map, every place named', (t) async {
      final newYork = SeasonMap.forSeason(SeasonIds.newyork)!;
      final c = await play('s4_ep03', season: SeasonIds.newyork);
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(shows(newYork.artwork), isTrue);
      expect(shows(seasonMapFile), isFalse);
      // The current pin names its own place; the season map names every other one, as it always did.
      final here = SeasonMap.landmarkOf(seoulCase('s4_ep03').allMissions.first.id)!;
      for (final l in newYork.landmarks) {
        expect(named(l.name), l == here ? findsNothing : findsOneWidget, reason: l.name);
      }
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });
  });
}
