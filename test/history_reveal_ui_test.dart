import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/history_reveal.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/result/case_solved_screen.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Historical Fiction Mystery PART 2: REAL HISTORY / IN THIS MYSTERY on the
/// Case Closed file. No season in the game is historical yet, so a reveal is
/// laid on London's Case 01 through its provider (the one the generator's
/// `SeasonContent.historyReveals` feeds); without it the file is as before.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  final e = catalog.firstWhere((c) => c.id == 'ep01');

  const reveal = HistoryReveal(
    realHistory: [
      HistoryLine(
        rookie: 'King Sejong made new letters in 1443.',
        junior: 'In 1443, King Sejong created a new set of letters.',
        master: 'In 1443, King Sejong devised an entirely new alphabet.',
      ),
    ],
    inThisMystery: [
      HistoryLine(
        rookie: 'The lost page is made up.',
        junior: 'The missing page was invented for this case.',
        master: 'The vanished page is an invention of this mystery.',
      ),
    ],
    sources: [
      HistorySource(publisher: 'National Institute of Korean History', title: 'Annals, 1443', url: 'https://example.org/annals'),
    ],
  );

  Future<SharedPreferences> open(WidgetTester t, {HistoryReveal? history, Difficulty level = Difficulty.rookie, Size size = const Size(390, 844), double textScale = 1, bool settled = false}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    final overrides = await testOverrides(prefs: {
      AppConstants.progressKeyFor(e.id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions) m.id],
        startedAt: DateTime(2026, 9, 29, 10),
        completedAt: DateTime(2026, 9, 29, 10, 30),
        playMillis: 0,
      ).toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [e.id]).toJson()),
    });
    await t.pumpWidget(ProviderScope(
      overrides: [
        ...overrides,
        if (history != null) historyRevealProvider(e.id).overrideWithValue(history),
        seasonDifficultyProvider(e.seasonId).overrideWithValue(level),
      ],
      child: const WorldMysteryApp(),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first).read(routerProvider).go(settled ? Routes.solvedSettled : Routes.solved);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await wait(t, const Duration(milliseconds: 3200));
    return SharedPreferences.getInstance();
  }

  testWidgets('a standard season: no reveal, the file as before', (t) async {
    expect(SeasonCatalog.historyReveal(e.id), isNull, reason: 'no season in the game is historical');
    await open(t);
    expect(find.text('CASE CLOSED'), findsOneWidget);
    expect(find.byKey(const ValueKey('history-reveal')), findsNothing);
    expect(find.text('REAL HISTORY'), findsNothing);
  });

  testWidgets('REAL HISTORY above IN THIS MYSTERY, apart, under the case report', (t) async {
    await open(t, history: reveal);
    expect(find.byKey(const ValueKey('history-reveal')), findsOneWidget);
    expect(find.text('King Sejong made new letters in 1443.'), findsOneWidget);
    expect(find.text('The lost page is made up.'), findsOneWidget);
    expect(find.text('Made up for this game.'), findsOneWidget);
    final report = t.getTopLeft(find.text('CASE REPORT')).dy;
    final real = t.getTopLeft(find.text('REAL HISTORY')).dy;
    final made = t.getTopLeft(find.text('IN THIS MYSTERY')).dy;
    expect([report < real, real < t.getTopLeft(find.text('King Sejong made new letters in 1443.')).dy, made > t.getTopLeft(find.text('King Sejong made new letters in 1443.')).dy], [true, true, true],
        reason: 'the real history first, the made-up part after it, never mixed');
    expect(t.getSemantics(find.text('REAL HISTORY')), isSemantics(isHeader: true));
    expect(t.getSemantics(find.text('IN THIS MYSTERY')), isSemantics(isHeader: true));
  });

  for (final (level, real, made) in [
    (Difficulty.junior, 'In 1443, King Sejong created a new set of letters.', 'The missing page was invented for this case.'),
    (Difficulty.master, 'In 1443, King Sejong devised an entirely new alphabet.', 'The vanished page is an invention of this mystery.'),
  ]) {
    testWidgets('told at the season\'s level: ${level.label}', (t) async {
      await open(t, history: reveal, level: level);
      expect(find.text(real), findsOneWidget);
      expect(find.text(made), findsOneWidget);
      expect(find.text('King Sejong made new letters in 1443.'), findsNothing);
    });
  }

  testWidgets('SOURCES opens where it comes from; back closes it and stays on the file', (t) async {
    await open(t, history: reveal);
    final sources = find.byKey(const ValueKey('history-sources'));
    await t.ensureVisible(sources);
    await t.pump();
    expect(t.getSize(sources).height, greaterThanOrEqualTo(48));
    await t.tap(sources);
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('National Institute of Korean History'), findsOneWidget);
    expect(find.text('https://example.org/annals'), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('National Institute of Korean History'), findsNothing);
    expect(find.text('CASE CLOSED'), findsOneWidget);
    await t.ensureVisible(sources);
    await t.tap(sources);
    await wait(t, const Duration(milliseconds: 400));
    await t.tap(find.text('CLOSE'));
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('National Institute of Korean History'), findsNothing);
  });

  testWidgets('a small phone, large text: nothing overflows, every line reachable', (t) async {
    await open(t, history: reveal, size: const Size(320, 568), textScale: 1.6);
    expect(t.takeException(), isNull);
    final last = find.text('The lost page is made up.');
    await t.ensureVisible(last);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(t.getRect(last).right, lessThanOrEqualTo(320));
  });

  testWidgets('come back to (the app reopened on it): still there; no save written for it', (t) async {
    final prefs = await open(t, history: reveal, settled: true);
    expect(find.byKey(const ValueKey('history-reveal')), findsOneWidget);
    expect(prefs.getKeys().where((k) => k.toLowerCase().contains('history')), isEmpty);
  });
}
