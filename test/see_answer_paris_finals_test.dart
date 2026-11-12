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
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/widgets/detective_tips.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// See the Answer on Paris's finals played on the night page with a puzzle
/// of their own: the four canvases (Case 02) and the evidence boards (Case
/// 03, and Case 08's after the torn paper), and the map of Paris (Case 06).
void main() {
  final all = MockEpisodeRepository.bundled();
  final s1 = [for (final e in all) if (e.seasonId == SeasonIds.london) e];
  final paris = [for (final e in all) if (e.seasonId == SeasonIds.paris) e];

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

  for (final caseId in const ['s2_ep02', 's2_ep03', 's2_ep06', 's2_ep08']) {
    testWidgets('$caseId: the final offers its answer and shows it', (t) async {
      const size = Size(390, 844);
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      GameProgress solved(Episode e) => GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions) m.id],
        startedAt: DateTime(2026, 10, 20, 10),
        completedAt: DateTime(2026, 10, 20, 10, 30),
        playMillis: 0,
      );
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
            for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
            AppConstants.seasonStorageKey: jsonEncode(
              SeasonProgress(activeEpisodeId: s1.last.id, solvedEpisodeIds: [for (final e in s1) e.id]).toJson(),
            ),
          }),
          seasonPreviewProvider.overrideWithValue(true),
        ],
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const WorldMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in paris.takeWhile((e) => e.id != caseId)) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
      }
      final e = paris.firstWhere((e) => e.id == caseId);
      expect(game.openEpisode(e.id), isTrue);
      game.startInvestigation();
      for (final m in e.missions) {
        game.submitAnswer(m, m.answer);
      }
      final m = e.finalMission;
      ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      for (var i = 0; i < m.hints.length; i++) {
        game.useHint(m);
      }
      ref.read(walletProvider.notifier).rewardCompletedAd('finals');
      ref.read(walletProvider.notifier).unlockAnswer(m);
      await wait(t, const Duration(milliseconds: 400));

      final offer = find.text(answerButtonLabel);
      expect(offer, findsOneWidget, reason: '$caseId: every hint read, the answer is offered');
      await reveal(t, offer);
      await t.tap(offer);
      await wait(t, const Duration(milliseconds: 800));
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await wait(t, const Duration(milliseconds: 500));
      final picture = find.byKey(const ValueKey('answer-picture'));
      expect(picture, findsOneWidget);
      expect(t.takeException(), isNull, reason: '$caseId: nothing overflows');
      final shown = t.getRect(picture);
      expect(shown.top, greaterThanOrEqualTo(0));
      expect(shown.bottom, lessThanOrEqualTo(size.height));
      await capture(t, 'final_$caseId');
      expect(ref.read(gameControllerProvider).isCompleted(m.id), isFalse, reason: 'still the detective\'s to solve');
    });
  }
}
