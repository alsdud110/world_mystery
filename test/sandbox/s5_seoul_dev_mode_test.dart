import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game_master/dev_session.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import '../developer_session_test.dart' show enterDeveloperMode, openGameMaster, path, player, pumpGame, session, snapshot, tapKey;
import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import 'single_case.dart';

/// SEOUL — CASE 01 (Season 5) as a person reaches it in developer mode:
/// the Game Master's page, a level, a test session of its own on the case's
/// file, then the case played through its own pages to the Case Closed file
/// and its REAL HISTORY. The player's saves stay byte for byte, and Seoul is
/// in the player's game once, as one of its seasons (never a second copy).
void main() {
  tearDown(() {
    SeasonCatalog.testSeasons.clear();
    SeasonCatalog.testPlaces.clear();
  });

  Future<void> enterPilot(WidgetTester t, Difficulty level) async {
    await tapKey(t, 'seoul-pilot-${level.storageId}');
    await wait(t, const Duration(milliseconds: 900));
    expect(path(t), Routes.caseFile(seoulCase01Id));
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsOneWidget);
    expect(session(t).read(devSessionProvider)!.pilot, isTrue);
    expect(session(t).read(detectiveProfileProvider).difficulty, level);
  }

  for (final (level, size) in [
    (Difficulty.rookie, const Size(320, 568)),
    (Difficulty.junior, const Size(390, 844)),
    (Difficulty.master, const Size(320, 568)),
  ]) {
    testWidgets('${level.label} at ${size.width.toInt()}: from the Game Master to the Case Closed file, the player\'s saves untouched', (t) async {
      final storage = await pumpGame(t, player());
      t.view.physicalSize = size * 3;
      await wait(t);
      final before = snapshot(storage);
      await enterDeveloperMode(t);
      await enterPilot(t, level);

      final c = session(t);
      await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
      await wait(t, const Duration(milliseconds: 2500));
      expect(c.read(currentDifficultyProvider), level);

      final p = CasePlayer(t, season5Content);
      final ep = c.read(currentEpisodeProvider);
      expect(ep.id, seoulCase01Id);
      for (final m in ep.missions) {
        await p.toPuzzle(m);
        await p.answer(m);
        expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: '${m.id}: ${p.play.texts()}');
        final e = t.takeException();
        expect(e, isNull, reason: '${m.id}: ${e is FlutterError ? e.toStringDeep() : e}');
        await p.onToMap();
      }
      await p.solveFinal(ep.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCompleted(ep.finalMission.id), isTrue, reason: p.play.texts());
      // The ending (Bun-i at dawn), its Discovery Moment, then the case closed.
      bool closing() => find.text('CLOSE THE CASE').evaluate().isNotEmpty || find.text('SEE MY CASE REPORT').evaluate().isNotEmpty;
      for (var n = 0; n < 24 && !closing(); n++) {
        if (find.text('CONTINUE INVESTIGATION').evaluate().isNotEmpty) {
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
        } else if (find.text('NEXT').evaluate().isNotEmpty) {
          await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
        } else {
          await t.tapAt(Offset(size.width / 2, size.height / 2.5));
          await wait(t, const Duration(milliseconds: 900));
        }
      }
      if (find.text('CLOSE THE CASE').evaluate().isNotEmpty) await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue, reason: p.play.texts());
      for (var n = 0; n < 4 && find.text('SEE MY CASE REPORT').hitTestable().evaluate().isEmpty; n++) {
        await t.tapAt(t.getCenter(find.byType(Scaffold).last));
        await wait(t, const Duration(milliseconds: 1200));
      }
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: p.play.texts());
      final reveal = season5Content.historyReveals[seoulCase01Id]!;
      await t.ensureVisible(find.text('IN THIS MYSTERY'));
      await wait(t, const Duration(milliseconds: 300));
      for (final line in [...reveal.realHistory, ...reveal.inThisMystery]) {
        expect(findReadableContaining(line.at(level)), findsWidgets, reason: '${level.label}: "${line.at(level)}"');
      }
      final err = t.takeException();
      expect(err, isNull, reason: err is FlutterError ? err.diagnostics.map((d) => d.toString()).join('\n') : '$err');

      // Out of developer mode: the player's game as it was, Seoul in it once
      // and the test session's solve nowhere in it.
      c.read(routerProvider).go(Routes.gameMaster);
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'EXIT DEVELOPER MODE', after: const Duration(milliseconds: 900));
      expect(snapshot(storage), before);
      expect(session(t).read(seasonsProvider).where((s) => s.id == season5Content.id), hasLength(1));
      expect(session(t).read(allEpisodesProvider).where((e) => e.id == seoulCase01Id), hasLength(1));
      expect(session(t).read(progressRepositoryProvider).loadSeason(season5Content.id).isSolved(seoulCase01Id), isFalse);
    });
  }

  test('the pilot\'s own pictures: no London or Paris picture; every one on disk, none with writing drawn by hand', () {
    String all(Object? o) => '$o';
    final made = [
      for (final p in season5Content.places.values) p.file,
      for (final d in season5Content.deductions.values) d.picture,
      for (final t in season5Content.talks.values) ...[all(t.background), ...t.speaker.portraits.values],
      for (final t in season5Content.talkMissions.values) for (final s in [?t.before, ?t.after]) ...s.speaker.portraits.values,
      for (final e in season5Content.endings.values) for (final l in e) ...[l.background, ?l.portrait],
      ...season5Content.introBackdrops.values,
    ];
    expect(made, isNotEmpty);
    for (final f in made) {
      expect(f, isNot(matches(RegExp('season_0[1-4]_'))), reason: f);
    }
    for (final f in made.where((f) => f.startsWith('assets/'))) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
    expect(season5Content.introBackdrops[seoulCase01Id], 'assets/seasons/season_05_seoul/cover/kings_study.webp');
    // Case 01's evidence is drawn with its words (no picture of the first
    // design is left wired); the later cases' evidence pictures are their own.
    expect(ArtAssets.evidencePictures.keys.where((id) => id.startsWith('s5_ep01_')), isEmpty);
  });

  testWidgets('another level from inside the pilot: a new session at that level, from the case\'s start', (t) async {
    final storage = await pumpGame(t, player());
    final before = snapshot(storage);
    await openGameMaster(t);
    expect(find.byKey(const ValueKey('seoul-pilot')), findsNothing, reason: 'the player\'s own Game Master: developer mode first');
    await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
    await enterPilot(t, Difficulty.rookie);
    final first = session(t);
    final m1 = first.read(currentEpisodeProvider).missions.first;
    first.read(gameControllerProvider.notifier)
      ..startInvestigation()
      ..submitAnswer(m1, m1.answer);
    expect(first.read(gameControllerProvider).isCompleted(m1.id), isTrue);

    await openGameMaster(t);
    // TEST LEVEL inside the pilot starts it again at that level.
    await tapText(t, Difficulty.master.label, after: const Duration(milliseconds: 900));
    expect(path(t), Routes.caseFile(seoulCase01Id));
    final again = session(t);
    expect(identical(again, first), isFalse);
    expect(again.read(detectiveProfileProvider).difficulty, Difficulty.master);
    expect(again.read(gameControllerProvider).isCompleted(m1.id), isFalse);
    expect(snapshot(storage), before);
  });
}
