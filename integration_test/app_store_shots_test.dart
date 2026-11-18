import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/assets/season_pack_downloads.dart';
import 'package:world_mystery/core/assets/season_pack_local.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/widgets/typewriter_text.dart';

import '../test/helpers.dart' show testOverrides;

/// App Store screenshots: the game on in-memory saves (detective Alex,
/// Rookie), brought to each scene, captured by the host (simctl) through
/// a file handshake (see `shot`).
///   SHOTS=a,b,c  (--dart-define) the scenes to capture; default: the six.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  const shotList = String.fromEnvironment('SHOTS');
  final wanted = shotList.isEmpty ? null : shotList.split(',').toSet();

  final all = MockEpisodeRepository.bundled();
  Episode ep(String id) => all.firstWhere((e) => e.id == id);
  List<Episode> ofSeason(String s) => [for (final e in all) if (e.seasonId == s) e];

  testWidgets('app store scenes', (t) async {
    final prefs = await SharedPreferences.getInstance();
    final local = await LocalSeasonPacks.forThisRun();
    expect(local?.problem(), isNull);
    final c = ProviderContainer(overrides: [
      ...await testOverrides(),
      seasonPackSetupProvider.overrideWithValue(local == null ? await SeasonPackSetup.fromEnvironment(prefs) : null),
      seasonPacksInAppProvider.overrideWithValue(local != null),
      localSeasonPacksProvider.overrideWithValue(local),
    ]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Alex', DetectiveAvatar.boy, difficulty: Difficulty.rookie);
    c.read(seasonPreviewSwitchProvider.notifier).set(true); // any season enterable, no label
    final repo = c.read(progressRepositoryProvider);
    final now = DateTime.now().subtract(const Duration(days: 3));

    /// The first [n] cases of [seasonId] solved (every mission done), the
    /// next one open, as a player who played them leaves them.
    void solved(String seasonId, int n) {
      final cases = ofSeason(seasonId);
      var season = repo.loadSeason(seasonId);
      repo.transaction(() {
        for (final e in cases.take(n)) {
          repo.save(
            GameProgress(
              detectiveName: 'Alex',
              introSeen: true,
              completedMissionIds: [for (final m in e.allMissions) m.id],
              startedAt: now,
              completedAt: now.add(const Duration(minutes: 14)),
              playMillis: 14 * 60 * 1000,
            ),
            e.id,
          );
          season = season.markSolved(e.id);
        }
        if (n < cases.length) {
          season = season.copyWith(activeEpisodeId: cases[n].id);
          // The open case knows the detective too (no Create Your Detective page).
          repo.save(GameProgress(detectiveName: 'Alex', startedAt: now), cases[n].id);
        }
        repo.saveSeason(season, seasonId);
      });
    }

    const londonSolved = int.fromEnvironment('LONDON', defaultValue: 12);
    const parisSolved = int.fromEnvironment('PARIS', defaultValue: 5);
    const seoulSolved = int.fromEnvironment('SEOUL', defaultValue: 3);
    solved(SeasonIds.london, londonSolved);
    solved(SeasonIds.paris, parisSolved);
    solved(SeasonIds.seoul, seoulSolved);
    c.read(seasonProvider.notifier).reload();
    c.invalidate(gameControllerProvider);

    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(2000);
    final router = c.read(routerProvider);

    // The host captures the simulator (simctl) when asked through a file in
    // SHOT_SYNC (a simulator app reads and writes the Mac's folders), and
    // answers with done.<name>; the scene waits for it.
    const sync = String.fromEnvironment('SHOT_SYNC');
    Future<void> shot(String name, {int settle = 2500}) async {
      await pause(settle);
      final done = File('$sync/done.$name');
      File('$sync/request').writeAsStringSync(name);
      for (var i = 0; i < 300 && !done.existsSync(); i++) {
        await pause(100);
      }
      expect(done.existsSync(), isTrue, reason: 'host captured $name');
      await pause(200);
    }

    bool want(String name) => wanted == null || wanted.contains(name);

    Future<void> go(String location, {int settle = 1500}) async {
      router.go(location);
      await pause(settle);
    }

    Future<void> tapText(String text, {int after = 800}) async {
      final f = find.text(text);
      for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
        await pause(100);
      }
      expect(f, findsWidgets, reason: 'waiting for "$text"');
      await t.tap(f.last);
      await pause(after);
    }

    bool has(String text) => find.text(text).evaluate().isNotEmpty;
    bool hasKey(String key) => find.byKey(ValueKey(key)).evaluate().isNotEmpty;
    Future<void> tapKey(String key, {int after = 500}) async {
      await t.tap(find.byKey(ValueKey(key)).last);
      await pause(after);
    }

    /// Case [id] opened, a still-locked one too (operator access on for the
    /// moment, off again: its stamp never shows).
    void open(String id) {
      if (c.read(gameControllerProvider.notifier).openEpisode(id)) return;
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(c.read(gameControllerProvider.notifier).openEpisode(id), isTrue, reason: 'open $id');
      c.read(operatorAccessSwitchProvider.notifier).set(false);
    }

    /// The current season switched to [seasonId], its case [id] opened and
    /// begun (intro skipped, I'M READY), the missions before [upTo] done.
    Future<void> inCase(String seasonId, String id, {String? upTo}) async {
      expect(ctrl.openSeason(seasonId), isTrue, reason: 'enter $seasonId');
      await pause(300);
      open(id);
      await pause(300);
      final ctl = c.read(gameControllerProvider.notifier);
      if (!c.read(gameControllerProvider).introSeen) ctl.startInvestigation();
      if (upTo != null) {
        for (final m in ep(id).allMissions) {
          if (m.id == upTo) break;
          if (!c.read(gameControllerProvider).isCompleted(m.id)) {
            ctl.submitAnswer(m, SeasonCatalog.caseTalk(m)?.answer ?? m.answer);
          }
        }
      }
      await pause(300);
    }

    /// Through whatever a place shows first (INVESTIGATE, a talk, the
    /// letter) to its puzzle; stops when nothing more opens.
    Future<void> toPuzzle() async {
      for (var i = 0; i < 12; i++) {
        if (has('INVESTIGATE')) {
          await tapText('INVESTIGATE', after: 1500);
        } else if (hasKey('case-talk-next')) {
          await tapKey('case-talk-next', after: 400);
        } else if (hasKey('case-talk-finish')) {
          await tapKey('case-talk-finish', after: 1500);
        } else if (has('TAP TO OPEN')) {
          await tapText('TAP TO OPEN', after: 1500);
        } else if (has('SOLVE THE PUZZLE')) {
          await tapText('SOLVE THE PUZZLE', after: 1500);
        } else {
          return;
        }
      }
    }

    // ---- scenes -------------------------------------------------------
    if (want('world_map')) {
      await go(Routes.worldMap, settle: 3000);
      await shot('01_world_map');
    }
    if (want('world_map_paris')) {
      expect(ctrl.openSeason(SeasonIds.paris), isTrue);
      await go(Routes.worldMap, settle: 3000);
      await shot('01_world_map_paris');
      await tapKey('world-map-zoom-out', after: 1500);
      await shot('01_world_map_paris_out', settle: 1000);
    }
    if (want('case_files_paris')) {
      expect(ctrl.openSeason(SeasonIds.paris), isTrue);
      await go(Routes.episodes);
      await shot('02_case_files_paris');
    }
    if (want('case_files_seoul')) {
      expect(ctrl.openSeason(SeasonIds.seoul), isTrue);
      await go(Routes.episodes);
      await shot('02_case_files_seoul');
    }
    if (want('case_files_london')) {
      expect(ctrl.openSeason(SeasonIds.london), isTrue);
      await go(Routes.episodes);
      await shot('02_case_files_london');
    }
    // Story intros: the first page of each.
    const intros = String.fromEnvironment('INTROS', defaultValue: '');
    for (final id in intros.split(',').where((s) => s.isNotEmpty)) {
      final seasonId = ep(id).seasonId;
      expect(ctrl.openSeason(seasonId), isTrue);
      open(id);
      await go(Routes.episodes, settle: 800); // a new intro page, not the last one
      await go(Routes.intro, settle: 2500);
      await shot('03_intro_$id', settle: 1500);
      // one page on
      if (has('NEXT ›')) {
        await tapText('NEXT ›', after: 1500);
        await shot('03_intro_${id}_p2', settle: 1000);
      }
    }
    // Story scenes after a mission: STORY=<missionId>,... (the mission is
    // marked done first).
    const stories = String.fromEnvironment('STORIES', defaultValue: '');
    for (final mid in stories.split(',').where((s) => s.isNotEmpty)) {
      final e = all.firstWhere((e) => e.allMissions.any((m) => m.id == mid));
      await inCase(e.seasonId, e.id, upTo: mid);
      final m = ep(e.id).allMissions.firstWhere((m) => m.id == mid);
      final ctl = c.read(gameControllerProvider.notifier);
      if (!c.read(gameControllerProvider).isCompleted(mid)) ctl.submitAnswer(m, SeasonCatalog.caseTalk(m)?.answer ?? m.answer);
      await go(Routes.story(mid), settle: 1000);
      // Its lines typed out to STORY_END (a text on the last line), then the
      // capture at once: before anything comes over the picture.
      const end = String.fromEnvironment('STORY_END');
      bool typed() {
        // The typewriter draws its remainder transparent: the shown span.
        for (final e in find.descendant(of: find.byType(TypewriterText), matching: find.byType(Text)).evaluate()) {
          final span = (e.widget as Text).textSpan;
          if (span is TextSpan && span.children != null && span.children!.isNotEmpty) {
            final shown = (span.children!.first as TextSpan).text ?? '';
            if (shown.endsWith(end)) return true;
          }
        }
        return false;
      }
      if (end.isNotEmpty) {
        for (var i = 0; i < 600 && !typed(); i++) {
          await pause(25);
        }
      }
      await shot('03_story_$mid', settle: end.isEmpty ? 3000 : 0);
    }
    // Missions: MISSIONS=<missionId>,...  opened at their puzzle, unsolved.
    const missions = String.fromEnvironment('MISSIONS', defaultValue: '');
    for (final mid in missions.split(',').where((s) => s.isNotEmpty)) {
      final e = all.firstWhere((e) => e.allMissions.any((m) => m.id == mid));
      await inCase(e.seasonId, e.id, upTo: mid);
      final m = ep(e.id).allMissions.firstWhere((m) => m.id == mid);
      // A solve's moment still up (a mission answered through the
      // controller): closed as a player closes it.
      for (var i = 0; i < 4; i++) {
        if (has('CONTINUE INVESTIGATION')) {
          await tapText('CONTINUE INVESTIGATION', after: 1500);
        } else if (has('TO THE MAP')) {
          await tapText('TO THE MAP', after: 1500);
        } else {
          break;
        }
      }
      await go(m.isFinal ? Routes.finalMission : Routes.mission(mid), settle: 2000);
      await shot('04_place_$mid', settle: 1000);
      await toPuzzle();
      await shot('05_puzzle_$mid', settle: 1500);
      // The crown card (London Case 01 M5): looked at, its code examined (the
      // message), then taken (the discovery card).
      if (mid == 'm05' && hasKey('decode-picture')) {
        Offset at(double fx, double fy) {
          final box = t.getRect(find.byKey(const ValueKey('decode-picture')));
          return Offset(box.left + fx * box.width, box.top + fy * box.height);
        }
        await t.tapAt(at(700 / 1536, 930 / 1024));
        await pause(1200);
        await t.tapAt(at(810 / 1536, 560 / 1024));
        await pause(1200);
        await tapKey('decode-examine', after: 3500);
        await shot('05_decoded_$mid', settle: 500);
        await tapKey('decode-take', after: 2500);
        await shot('05_discovery_$mid', settle: 500);
      }
      // A final's page scrolls: its locks and the notebook under them, too.
      if (m.isFinal && has('OPEN MY NOTEBOOK')) {
        await t.scrollUntilVisible(find.text('OPEN MY NOTEBOOK'), 200, scrollable: find.byType(Scrollable).first);
        await shot('05_puzzle_${mid}_locks', settle: 1500);
      }
    }
    // Routes: ROUTES=<location>|...  each opened and captured (the notebook's
    // BADGES tab too).
    const routes = String.fromEnvironment('ROUTES', defaultValue: '');
    for (final r in routes.split('|').where((s) => s.isNotEmpty)) {
      await go(r, settle: 3500);
      final name = r.replaceAll(RegExp('[^a-zA-Z0-9]+'), '_');
      await shot('07_route_$name');
      if (has('BADGES')) {
        await tapText('BADGES', after: 1500);
        await shot('07_route_${name}_badges');
      }
    }
    if (want('board_london')) {
      await go(Routes.worldMap, settle: 800); // off any case page before the season changes
      expect(ctrl.openSeason(SeasonIds.london), isTrue);
      await go(Routes.season, settle: 3500);
      await shot('06_board_london');
    }
    if (want('board_paris')) {
      expect(ctrl.openSeason(SeasonIds.paris), isTrue);
      await go(Routes.season, settle: 3500);
      await shot('06_board_paris');
    }
    if (want('notebook')) {
      expect(ctrl.openSeason(SeasonIds.london), isTrue);
      open('ep12');
      await go(Routes.notebook, settle: 2500);
      await shot('06_notebook_london');
      await go(Routes.archive, settle: 2500);
      await shot('06_archive_london');
    }
    if (want('archives')) {
      await go(Routes.seasons, settle: 2500);
      await shot('06_detective_archives');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
