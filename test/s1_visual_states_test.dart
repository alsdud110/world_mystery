import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/evidence_card.dart';
import 'package:world_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show hearTalk, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;
import 'reading_finders.dart';

/// Season 1 device feedback, PART C: the pictures that change with the solve
/// (Case 05's iron chest opens on the map fragment; Case 10's raven caws
/// once) and the pictures a puzzle is read from (Case 04's black wax seal,
/// Case 07's map pieces, Case 09's keys, Case 10's ravens and word papers).
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  group('data', () {
    test('Case 05 and Case 10: the solved picture is the same view, another file', () {
      expect(ArtAssets.scene(Artwork.ironChest), endsWith('objects/iron_chest.webp'));
      expect(ArtAssets.scene(Artwork.ironChest, solved: 1), endsWith('objects/iron_chest_open.webp'));
      expect(ArtAssets.scene(Artwork.raven), endsWith('characters/raven_master.webp'));
      expect(ArtAssets.scene(Artwork.raven, solved: 1), endsWith('characters/raven_master_caw.webp'));
      expect(ArtAssets.sceneLabel(Artwork.ironChest, solved: 0), contains('shut'));
      expect(ArtAssets.sceneLabel(Artwork.ironChest, solved: 1), contains('open'));
      expect(ArtAssets.sceneLabel(Artwork.raven, solved: 1), contains('caws'));
      // Only these (and Case 02's drawn hands) change; Case 11's stranger
      // and Case 12's iron door joined them (S1 dialogue feedback PART B).
      expect(ArtAssets.changesWhenSolved,
          {Artwork.clockFace, Artwork.ironChest, Artwork.raven, Artwork.maskedStranger, Artwork.ironDoor});
    });

    test("Case 04: the black wax seal on R.'s letters and in the notebook, no other case's", () {
      expect(ArtAssets.letterSeals.keys, {'ep04_m1', 'ep04_m3', 'ep04_final'});
      expect(ArtAssets.letterSeals.values.toSet(), {ArtAssets.blackWaxSeal});
      expect(ArtAssets.evidencePictures['ep04_e1'], ArtAssets.blackWaxSeal);
    });

    test('Case 07: the map pieces, joined, and the old map are the evidence pictures', () {
      final e = byId('ep07');
      final m3 = e.missionById('ep07_m3')!;
      for (final o in m3.options) {
        expect(o.picture, 'assets/seasons/season_01_london/cases/case_07/map_piece_${o.id}.webp', reason: o.id);
        expect(o.altText, isNotEmpty, reason: o.id);
      }
      expect(m3.answer, 'station,park,river');
      expect(ArtAssets.evidencePictures['ep07_e1'], endsWith('map_piece_river.webp'));
      expect(ArtAssets.evidencePictures['ep07_e2'], endsWith('map_piece_station.webp'));
      expect(ArtAssets.evidencePictures['ep05_e4'], endsWith('map_piece_park.webp'));
      expect(ArtAssets.evidencePictures['ep07_e3'], endsWith('map_joined.webp'));
      expect(ArtAssets.evidencePictures['ep07_e4'], endsWith('old_london_map.webp'));
    });

    test('Case 09 M1: four keys as pictures, the answer and the labels kept', () {
      final m1 = byId('ep09').missionById('ep09_m1')!;
      expect(m1.type, MissionType.imageChoice);
      expect(m1.answer, 'c');
      expect(m1.options.map((o) => o.label), ["The maid's key", "The cook's key", "The guard's key", "The King's key"]);
      for (final o in m1.options) {
        expect(o.picture, startsWith('assets/seasons/season_01_london/cases/case_09/key_'), reason: o.id);
        expect(o.altText, isNotEmpty, reason: o.id);
      }
      expect(m1.hideOptionNames, isFalse, reason: 'the names stay under the pictures');
    });

    test('Case 10 M1 and M2: four ravens and four papers as pictures, answers kept', () {
      final e = byId('ep10');
      final m1 = e.missionById('ep10_m1')!;
      expect(m1.type, MissionType.imageChoice);
      expect(m1.answer, 'c');
      expect(m1.options.map((o) => o.label), ['Jubilee', 'Merlin', 'Poppy', 'Harris']);
      for (final o in m1.options) {
        expect(o.picture, 'assets/seasons/season_01_london/cases/case_10/raven_${o.label.toLowerCase()}.webp');
        expect(o.altText, isNotEmpty);
      }
      final m2 = e.missionById('ep10_m2')!;
      expect(m2.answer, 'north,tower,bridge,three');
      for (final o in m2.options) {
        expect(o.picture, 'assets/seasons/season_01_london/cases/case_10/word_${o.id}.webp');
        expect(o.label, o.id.toUpperCase(), reason: 'the word stays under its picture');
      }
      // The final's warning: Poppy caws once, after the papers are read.
      expect(e.finalMission.transition.join(' '), contains('caws'));
    });

    test('every new picture is in the bundle', () {
      final files = [
        ArtAssets.blackWaxSeal,
        ...ArtAssets.solvedScenes.values,
        for (final id in ['ep07_m3', 'ep09_m1', 'ep10_m1', 'ep10_m2'])
          for (final o in season.expand((e) => e.allMissions).firstWhere((m) => m.id == id).options) o.picture!,
        for (final id in ['ep05_e4', 'ep07_e1', 'ep07_e2', 'ep07_e3', 'ep07_e4']) ArtAssets.evidencePictures[id]!,
      ];
      expect(missingAssets(files), isEmpty);
    });
  });

  group('screens', () {
    setUpAll(() async {
      for (final (family, files) in [
        ('Sentient', ['Sentient-Variable.ttf']),
        ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
        ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
      ]) {
        final loader = FontLoader(family);
        for (final f in files) {
          loader.addFont(rootBundle.load('assets/fonts/$f'));
        }
        await loader.load();
      }
    });

    String progress(List<String> done, {bool solved = false, String? opened}) => jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          missionStartedAt: opened == null ? const {} : {opened: DateTime(2026, 10, 7, 10)},
          startedAt: DateTime(2026, 10, 7, 10),
          completedAt: solved ? DateTime(2026, 10, 7, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    /// The app opened on [e]'s final, its missions done; [solved]: the final
    /// too (a revisit after a restart).
    Future<void> openFinal(WidgetTester t, Episode e, {bool solved = false}) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final earlier = [for (final x in season) if (x.seasonId == e.seasonId && x.number < e.number) x];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
          AppConstants.progressKeyFor(e.id): progress([for (final m in solved ? e.allMissions : e.missions) m.id], solved: solved),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id, if (solved) e.id]).toJson(),
          ),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: WorldMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first).read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      // A person who talks first (Case 10's Ravenmaster, PART C): heard.
      await hearTalk(t);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    /// The app opened on mission [missionId] of [e] (the missions before it
    /// done); [opened]: its letter already read.
    Future<void> openMission(WidgetTester t, Episode e, String missionId, {bool opened = true}) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final earlier = [for (final x in season) if (x.seasonId == e.seasonId && x.number < e.number) x];
      final done = [for (final m in e.missions.takeWhile((m) => m.id != missionId)) m.id];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
          AppConstants.progressKeyFor(e.id): progress(done, opened: opened ? missionId : null),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id]).toJson(),
          ),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: WorldMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first).read(routerProvider).go(Routes.mission(missionId));
      await wait(t, const Duration(milliseconds: 1500));
      // A person who says the letter (the butler, the Ravenmaster, PART C): heard.
      await hearTalk(t);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    /// Every picture on screen decoded (a capture shows them, not blanks).
    Future<void> decodePictures(WidgetTester t) async {
      for (final e in find.byType(Image).evaluate()) {
        final w = e.widget as Image;
        await t.runAsync(() => precacheImage(w.image, e));
      }
      await t.pump();
    }

    /// The asset names of the pictures on screen.
    Set<String> shownAssets(WidgetTester t) {
      String? nameOf(ImageProvider p) => switch (p) {
            AssetImage(:final assetName) => assetName,
            ResizeImage(:final imageProvider) => nameOf(imageProvider),
            _ => null,
          };
      return {
        for (final w in t.widgetList<Image>(find.byType(Image))) ?nameOf(w.image),
      };
    }

    testWidgets("Case 04 M1: the envelope's seal is the black wax raven", (t) async {
      await openMission(t, byId('ep04'), 'ep04_m1', opened: false);
      await t.ensureVisible(find.text('INVESTIGATE'));
      await t.tap(find.text('INVESTIGATE'));
      await wait(t, const Duration(milliseconds: 1500));
      await decodePictures(t);
      await capture(t, 'ep04_m1_envelope');
      expect(shownAssets(t), contains(ArtAssets.blackWaxSeal));
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets("Case 03 M2's letter keeps the game's own wax seal", (t) async {
      await openMission(t, byId('ep03'), 'ep03_m2', opened: false);
      await t.ensureVisible(find.text('INVESTIGATE'));
      await t.tap(find.text('INVESTIGATE'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(find.byType(EnvelopeReveal), findsOneWidget);
      expect(shownAssets(t), isNot(contains(ArtAssets.blackWaxSeal)));
      await wait(t, const Duration(seconds: 2));
    });

    for (final (caseId, missionId, folder) in [
      ('ep07', 'ep07_m3', 'case_07/map_piece_'),
      ('ep09', 'ep09_m1', 'case_09/key_'),
      ('ep10', 'ep10_m1', 'case_10/raven_'),
      ('ep10', 'ep10_m2', 'case_10/word_'),
    ]) {
      testWidgets('$missionId: its four (or three) things as pictures, named, on a small phone', (t) async {
        final e = byId(caseId);
        await openMission(t, e, missionId);
        final puzzle = find.text('CHECK ANSWER');
        if (puzzle.evaluate().isEmpty) {
          await t.scrollUntilVisible(puzzle, 300, scrollable: find.byType(Scrollable).first);
          await wait(t);
        }
        await t.ensureVisible(puzzle);
        await wait(t);
        await decodePictures(t);
        await capture(t, '${missionId}_pictures');
        final m = e.missionById(missionId)!;
        final shown = shownAssets(t);
        for (final o in m.options) {
          expect(shown, contains(o.picture), reason: '${o.id}: $shown');
          expect(findTextContaining(o.label), findsWidgets, reason: o.label);
        }
        expect(shown.where((a) => a.contains(folder)), hasLength(m.options.length));
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }

    for (final id in ['ep05_e4', 'ep07_e1', 'ep07_e2', 'ep07_e3', 'ep07_e4']) {
      testWidgets('$id: the close look shows the map picture whole, its words under it', (t) async {
        t.view.physicalSize = const Size(360, 640) * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final evidence = season.expand((e) => e.allEvidence).firstWhere((v) => v.id == id);
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: RepaintBoundary(
            key: const ValueKey('shot'),
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: TextButton(onPressed: () => showEvidenceZoom(context, evidence), child: const Text('look')),
                  ),
                ),
              ),
            ),
          ),
        ));
        await t.tap(find.text('look'));
        await wait(t);
        await decodePictures(t);
        await capture(t, '${id}_zoom');
        expect(find.byKey(ValueKey('evidence-print-$id')), findsOneWidget);
        expect(find.byKey(ValueKey('evidence-paper-$id')), findsNothing, reason: 'no longer words on a blank map');
        expect(findReadable(evidence.inscription!), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    for (final (caseId, shut, open) in [
      ('ep05', 'objects/iron_chest.webp', 'objects/iron_chest_open.webp'),
      ('ep10', 'characters/raven_master.webp', 'characters/raven_master_caw.webp'),
    ]) {
      testWidgets('$caseId final, before the answer: $shut', (t) async {
        await openFinal(t, byId(caseId));
        await capture(t, '${caseId}_final_before');
        final shown = shownAssets(t);
        expect(shown.any((a) => a.endsWith(shut)), isTrue, reason: '$shown');
        expect(shown.any((a) => a.endsWith(open)), isFalse);
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('$caseId final, solved (a revisit after a restart): $open', (t) async {
        await openFinal(t, byId(caseId), solved: true);
        await capture(t, '${caseId}_final_after');
        final shown = shownAssets(t);
        expect(shown.any((a) => a.endsWith(open)), isTrue, reason: '$shown');
        expect(shown.any((a) => a.endsWith(shut)), isFalse);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}
