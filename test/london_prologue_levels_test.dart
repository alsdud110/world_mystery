import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season1/season1_mock.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'reading_finders.dart';

void main() {
  /// The scenes' words, in the order the opening shows them.
  List<List<String>> scenes(SeasonPrologue p) => [
        [p.city],
        p.cases,
        p.separate,
        [p.question, p.bigger],
        p.promise,
        [p.firstCaseLine],
      ];

  SeasonPrologue at(Difficulty level) => SeasonPrologue.fromJson(season1PrologueAt(level));

  group('the words at each level', () {
    test('Rookie is the base, and the base is the season\'s own', () {
      expect(season1PrologueAt(Difficulty.rookie), season1PrologueJson);
      expect(season1InfoJson['prologue'], season1PrologueJson);
    });

    test('as many lines in every scene; the first case\'s picture stays', () {
      final base = scenes(at(Difficulty.rookie));
      for (final level in Difficulty.values) {
        final words = scenes(at(level));
        for (final (i, scene) in words.indexed) {
          expect(scene, hasLength(base[i].length), reason: 'scene ${i + 1} at ${level.name}');
          expect(scene.every((s) => s.isNotEmpty), isTrue, reason: 'scene ${i + 1} at ${level.name}');
        }
        expect(at(level).firstCasePicture, 'crown', reason: level.name);
      }
    });

    test('Junior and Master have words of their own in every scene', () {
      for (var i = 0; i < 6; i++) {
        expect({for (final level in Difficulty.values) scenes(at(level))[i].join('|')}, hasLength(3), reason: 'scene ${i + 1}');
      }
    });

    test('Rookie\'s lines are the shortest', () {
      int longest(Difficulty level) => [for (final s in scenes(at(level))) ...s].map((s) => s.length).reduce((a, b) => a > b ? a : b);
      expect(longest(Difficulty.rookie), lessThanOrEqualTo(longest(Difficulty.junior)));
      expect(longest(Difficulty.junior), lessThanOrEqualTo(longest(Difficulty.master)));
    });

    test('the mood only, at every level: no one named, nothing told before its time', () {
      for (final level in Difficulty.values) {
        final all = [for (final s in scenes(at(level))) ...s].join(' ').toLowerCase();
        for (final secret in ['raven', 'clockmaker', 'paris', 'grey', 'robin', 'rose', 'the shadow', 'crown']) {
          expect(all, isNot(contains(secret)), reason: '$secret at ${level.name}');
        }
      }
    });
  });

  group('the level it is played at', () {
    late WidgetRef appRef;

    Future<void> pumpApp(WidgetTester t, Difficulty level) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep01', difficulty: level).toJson()),
        }),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(routerProvider).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 2000));
    }

    for (final level in Difficulty.values) {
      testWidgets('London at ${level.name}: its words in every scene', (t) async {
        await pumpApp(t, level);
        expect(appRef.read(seasonDifficultyProvider(SeasonIds.london)), level);
        for (final (i, words) in scenes(at(level)).indexed) {
          for (final line in words) {
            expect(findText(line), findsOneWidget, reason: 'scene ${i + 1} at ${level.name}: $line');
          }
          if (i < 4) {
            await t.tap(find.text('NEXT ›'));
            await wait(t, const Duration(milliseconds: 2800));
          } else if (i == 4) {
            await t.tap(find.text('ACCEPT THE CASE'));
            await wait(t, const Duration(milliseconds: 1800));
          }
        }
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}
