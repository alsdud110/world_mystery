import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/theme/app_tokens.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/widgets/clue_card.dart';
import 'package:world_mystery/widgets/evidence_card.dart';
import 'package:world_mystery/widgets/reading_text_scale.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Larger system text: a clue's words in the notebook and an evidence's
/// words in its close look grow up to [AppTextScale.reading]; the rest of
/// the page keeps [AppTextScale.page]. Nothing overflows on a small phone.
void main() {
  final ep01 = MockEpisodeRepository.bundled().first;

  Future<void> openNotebook(WidgetTester t, Size size, double textScale) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    late WidgetRef ref;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {
        AppConstants.progressKeyFor(ep01.id): jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: [for (final m in ep01.missions) m.id],
          startedAt: DateTime(2026, 10, 1, 10),
          playMillis: 0,
        ).toJson()),
        AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: ep01.id).toJson()),
      }),
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
    ref.read(routerProvider).go(Routes.notebook);
    await wait(t, const Duration(milliseconds: 1500));
  }

  double scaleAt(WidgetTester t, Finder f) => MediaQuery.textScalerOf(t.element(f)).scale(10) / 10;

  double readingScale(double system) => system.clamp(0, AppTextScale.reading);
  double pageScale(double system) => system.clamp(0, AppTextScale.page);

  for (final (size, system) in const [(Size(320, 568), 2.0), (Size(360, 640), 2.0), (Size(390, 844), 1.5), (Size(360, 640), 1.0)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}@$system';

    testWidgets('notebook clues $tag: the clue words grow, the page keeps its cap, nothing overflows', (t) async {
      await openNotebook(t, size, system);
      expect(t.takeException(), isNull);
      final card = find.byType(ClueCard).first;
      expect(scaleAt(t, find.descendant(of: card, matching: find.byType(Text)).first), closeTo(readingScale(system), 0.001));
      expect(scaleAt(t, find.text('DETECTIVE NOTEBOOK')), closeTo(pageScale(system), 0.001), reason: 'the page title keeps the cap');
      expect(scaleAt(t, find.text('CLUES')), closeTo(pageScale(system), 0.001), reason: 'the tabs keep the cap');
      // Every clue card, down to the end of the list.
      for (var i = 0; i < 12; i++) {
        await t.drag(find.byType(ClueCard).first, const Offset(0, -300));
        await wait(t, const Duration(milliseconds: 200));
        expect(t.takeException(), isNull, reason: 'no overflow while scrolling');
      }
    });

    testWidgets('evidence close look $tag: its words grow, CLOSE stays on screen, nothing overflows', (t) async {
      await openNotebook(t, size, system);
      await t.tap(find.text('EVIDENCE'));
      await wait(t, const Duration(milliseconds: 800));
      final tiles = find.byType(EvidenceTile);
      final count = tiles.evaluate().length;
      expect(count, greaterThan(0));
      for (var i = 0; i < count; i++) {
        final tile = tiles.at(i);
        await Scrollable.ensureVisible(t.element(tile), alignment: 0.5);
        await wait(t, const Duration(milliseconds: 300));
        await t.tap(tile);
        await wait(t, const Duration(milliseconds: 800));
        expect(t.takeException(), isNull, reason: 'evidence $i: no overflow');
        final reading = find.byType(ReadingTextScale);
        expect(reading, findsWidgets);
        final words = find.descendant(of: reading.first, matching: find.byWidgetPredicate((w) => w is RichText)).first;
        expect(scaleAt(t, words), closeTo(readingScale(system), 0.001), reason: 'evidence $i: its words');
        expect(scaleAt(t, find.text('EVIDENCE').last), closeTo(pageScale(system), 0.001), reason: 'evidence $i: its heading');
        final close = find.text('CLOSE');
        final rect = t.getRect(close);
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: 'evidence $i: CLOSE on screen');
        await t.tap(close);
        await wait(t, const Duration(milliseconds: 800));
      }
    });
  }
}
