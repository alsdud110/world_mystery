import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/generated/generated_seasons.g.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'reading_finders.dart';

/// The openings of the seasons made from their plans (Rome, New York):
/// their words at each level, their own pictures, and the shared opening
/// page playing them.
void main() {
  // Every season made from its plans (Rome on): a new one is held to the same.
  final made = [for (final s in generatedSeasons) s.id];

  /// The scenes' words, in the order the opening shows them.
  List<List<String>> scenes(SeasonPrologue p) => [
        [p.city],
        p.cases,
        p.separate,
        [p.question, p.bigger],
        p.promise,
        [p.firstCaseLine],
      ];

  SeasonPrologue at(String id, Difficulty level) => DifficultyContent.seasonAt(SeasonCatalog.byId(id)!, level).prologue;

  group('the words and pictures', () {
    for (final id in made) {
      test('$id: every scene written, four pieces, every picture on disk', () {
        final p = SeasonCatalog.byId(id)!.season.prologue;
        expect(p.isPlayable, isTrue);
        expect(p.pieces, hasLength(4));
        for (final f in [...p.pieces, p.firstCasePicture, if (p.hero.isNotEmpty) p.hero]) {
          expect(File(f).existsSync(), isTrue, reason: f);
        }
        // Played, with its own city at night.
        expect(p.hero, isNotEmpty);
        expect(p.heroPixels, const Size(1024, 1536));
        expect(SeasonCatalog.byId(id)!.season.playsPrologue, isTrue);
      });

      test('$id: as many lines at every level; Junior and Master write every scene again', () {
        final base = scenes(at(id, Difficulty.rookie));
        expect(at(id, Difficulty.rookie).city, SeasonCatalog.byId(id)!.season.prologue.city, reason: 'Rookie is the plan\'s own');
        for (final level in Difficulty.values) {
          final words = scenes(at(id, level));
          for (final (i, scene) in words.indexed) {
            expect(scene, hasLength(base[i].length), reason: 'scene ${i + 1} at ${level.name}');
          }
          expect(at(id, level).pieces, at(id, Difficulty.rookie).pieces, reason: 'the pictures stay');
        }
        for (var i = 0; i < 6; i++) {
          expect({for (final level in Difficulty.values) scenes(at(id, level))[i].join('|')}, hasLength(3), reason: 'scene ${i + 1}');
        }
      });

      test('$id: the mood only, at every level: no one of the season named', () {
        final names = {
          for (final s in SeasonCatalog.byId(id)!.episodes.values)
            for (final c in (s['characters'] as List? ?? const []))
              if (c is Map && c['name'] is String) ...(c['name'] as String).toLowerCase().split(' ').where((w) => w.length > 3),
        };
        for (final level in Difficulty.values) {
          final all = [for (final s in scenes(at(id, level))) ...s].join(' ').toLowerCase();
          for (final name in {...names, 'valli', 'livia', 'dexter', 'eleanor', 'lark'}) {
            expect(all, isNot(contains(name)), reason: '$name at ${level.name}');
          }
        }
      });
    }

    test('the levels check finds nothing wrong with any season\'s own lines', () {
      expect([for (final s in SeasonCatalog.all) ...DifficultyContent.problemsOf(s)].where((p) => p.contains('season.')), isEmpty);
    });
  });

  group('the opening page', () {
    late WidgetRef appRef;

    bool shows(String file) => find
        .byWidgetPredicate((w) {
          if (w is! Image) return false;
          final image = w.image;
          final source = image is ResizeImage ? image.imageProvider : image;
          return source is AssetImage && source.assetName == file;
        })
        .evaluate()
        .isNotEmpty;

    /// The app on season [id], its own words at [level] (`seasonInfoProvider`
    /// as the season's level gives it), on its opening page.
    Future<Season> pumpApp(WidgetTester t, String id, Difficulty level) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final content = SeasonCatalog.byId(id)!;
      final season = DifficultyContent.seasonAt(content, level);
      expect(season.playsPrologue, isTrue);
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
            // The detective, on the season's first case too.
            AppConstants.progressKeyFor(content.episodes.keys.first): jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
          }),
          selectedSeasonIdProvider.overrideWith(() => _Playing(id)),
          seasonInfoProvider.overrideWithValue(season),
        ],
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(routerProvider).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 2000));
      return season;
    }

    for (final id in made) {
      for (final level in [Difficulty.rookie, Difficulty.master]) {
        testWidgets('$id at ${level.name}: its city, its pieces, its map, its first case', (t) async {
          final season = await pumpApp(t, id, level);
          final p = season.prologue;
          expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString(), Routes.prologue);
          expect(findText(season.city.toUpperCase()), findsOneWidget);
          expect(shows(p.hero), isTrue, reason: 'its city, not London');
          expect(find.text('LONDON'), findsNothing);
          for (final (i, words) in scenes(p).indexed) {
            for (final line in words) {
              expect(findText(line), findsOneWidget, reason: 'scene ${i + 1}: $line');
            }
            if (i == 1 || i == 2) {
              for (final f in p.pieces) {
                expect(shows(f), isTrue, reason: 'scene ${i + 1}: $f');
              }
            }
            if (i < 4) {
              await t.tap(find.text('NEXT ›'));
              await wait(t, const Duration(milliseconds: 2800));
            } else if (i == 4) {
              expect(findText(season.tagline), findsOneWidget);
              await t.tap(find.text('ACCEPT THE CASE'));
              await wait(t, const Duration(milliseconds: 1800));
            }
          }
          expect(shows(p.firstCasePicture), isTrue);
          expect(find.text('START CASE 01'), findsOneWidget);
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 3));
        });
      }
    }

    testWidgets('without its city at night, a season made from its plans opens no opening page', (t) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final content = SeasonCatalog.byId(SeasonIds.rome)!;
      final season = Season.fromJson({
        ...content.info,
        'prologue': {...content.info['prologue'] as Map}..remove('hero'),
      });
      expect(season.playsPrologue, isFalse);
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
            AppConstants.progressKeyFor('s3_ep01'): jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
          }),
          selectedSeasonIdProvider.overrideWith(() => _Playing(SeasonIds.rome)),
          seasonInfoProvider.overrideWithValue(season),
        ],
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      appRef.read(routerProvider).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 1500));
      expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString(), isNot(Routes.prologue));
      expect(find.text('NEXT ›'), findsNothing);
      await wait(t, const Duration(seconds: 3));
    });
  });
}

/// Season [id] played, whatever the saves say.
class _Playing extends SelectedSeasonNotifier {
  _Playing(this.id);

  final String id;

  @override
  String build() => id;
}
