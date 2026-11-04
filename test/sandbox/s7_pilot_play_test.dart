import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import 'generated/s7_seoulpilot/s7_seoulpilot_cases.g.dart';
import 'generated/s7_seoulpilot/s7_seoulpilot_history.g.dart';
import 'generated/s7_seoulpilot/s7_seoulpilot_levels.g.dart';
import 'generated/s7_seoulpilot/s7_seoulpilot_season.g.dart';
import 'single_case.dart';

/// Seoul Pilot Case 01, approved and made, played alone in the real app at
/// every level: a wrong order and a hint, a wrong pair of lines, the traces
/// noted, the app opened again, the final's evidence, paid once, and the
/// Case Closed file with its REAL HISTORY apart from IN THIS MYSTERY.
void main() {
  final season = SeasonContent(
    info: s7SeoulpilotInfoJson,
    episodes: s7SeoulpilotEpisodes,
    places: s7SeoulpilotPlaces,
    released: false,
    storyGreeting: s7SeoulpilotStoryGreeting,
    learning: s7SeoulpilotLearning,
    languageTopics: s7SeoulpilotLanguageTopics,
    evidenceLinks: s7SeoulpilotEvidenceLinks,
    explores: s7SeoulpilotExplores,
    investigations: s7SeoulpilotInvestigations,
    dialogues: s7SeoulpilotDialogues,
    timelines: s7SeoulpilotTimelines,
    deductions: s7SeoulpilotDeductions,
    records: s7SeoulpilotRecords,
    talks: s7SeoulpilotTalks,
    talkMissions: s7SeoulpilotTalkMissions,
    discoveries: s7SeoulpilotDiscoveries,
    endings: s7SeoulpilotEndings,
    historyReveals: s7SeoulpilotHistoryReveals,
    casePatches: s7SeoulpilotCasePatches,
    variants: s7SeoulpilotVariants,
    writtenLevels: s7SeoulpilotWrittenLevels,
    infoLevels: s7SeoulpilotInfoLevels,
  );

  test('the pilot as the game takes it: valid, a reveal, not one of the game\'s seasons', () {
    expect(SeasonContentValidator.validate(season), isEmpty);
    expect(season.historyReveals.keys, ['s7_ep01']);
    expect(SeasonCatalog.all.any((s) => s.id == season.id), isFalse);
  });

  for (final level in Difficulty.values) {
    testWidgets('s7_ep01 at ${level.label}: from its opening to the Case Closed file', (t) async {
      final one = SingleCase(season, 's7_ep01', level: level)..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await one.open(t, prefs, fresh: true);
      final p = CasePlayer(t, season);
      final ep = one.episode;
      bool done(String id) => c.read(gameControllerProvider).isCompleted(id);
      int wrong(String id) => c.read(gameControllerProvider).wrongAnswers[id] ?? 0;
      expect(c.read(currentDifficultyProvider), level);

      // M1, the timeline: two free cards swapped, the try-again sheet, a hint, then put right.
      final m1 = ep.missions[0];
      final spec = season.timelines[m1.id]!;
      final order = Mission.sequenceIds(m1.answer);
      final free = [for (final (i, id) in order.indexed) if (spec.card(id)?.anchor == null) i];
      final (i, j) = (free[0], free[1]);
      final miss = [...order]..[i] = order[j]..[j] = order[i];
      await p.toPuzzle(m1);
      await p.answer(m1, miss.join(','));
      expect(wrong(m1.id), 1, reason: p.play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 900));
      expect(c.read(gameControllerProvider).hintsFor(m1.id), 1, reason: p.play.texts());
      expect(findReadableContaining(m1.hints.first), findsWidgets, reason: 'the hint at ${level.label}');
      final before = c.read(walletProvider).balance;
      for (final k in [j, i]) {
        await t.ensureVisible(find.byKey(ValueKey('timeline-slot-$k')));
        await t.tap(find.byKey(ValueKey('timeline-slot-$k')));
        await wait(t, const Duration(milliseconds: 200));
      }
      await t.ensureVisible(find.text('CHECK THE ORDER'));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('CHECK THE ORDER'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(m1.id), isTrue, reason: p.play.texts());
      expect(c.read(walletProvider).balance - before, greaterThan(0));
      await p.onToMap();

      // Closed and opened again: M1 kept, M2 still open, M1 never paid twice.
      c = await one.open(t, prefs, fresh: false);
      expect([done(m1.id), done(ep.missions[1].id)], [true, false]);
      expect(c.read(gameControllerProvider.notifier).submitAnswer(m1, m1.answer).coins, 0, reason: 'paid once');

      // M2, the records: a wrong pair, TRY AGAIN, the WHY pair.
      final m2 = ep.missions[1];
      final r = season.records[m2.id]!;
      final other = r.first.lines.firstWhere((l) => '${l.id}:${l.id}' != m2.answer).id;
      await p.toPuzzle(m2);
      await p.answer(m2, '$other:$other');
      expect([done(m2.id), wrong(m2.id)], [false, 1], reason: p.play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await p.answer(m2);
      expect(done(m2.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      // M3, the traces: noted on the picture, then the right place.
      final m3 = ep.missions[2];
      await p.toPuzzle(m3);
      await p.answer(m3);
      expect(done(m3.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      // The final: the three pieces of evidence, the case closed.
      await p.solveFinal(ep.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(ep.finalMission.id), isTrue, reason: p.play.texts());
      // Its Discovery Moment, then the ending read line by line (its typing skipped).
      await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
      bool closing() => find.text('CLOSE THE CASE').evaluate().isNotEmpty || find.text('SEE MY CASE REPORT').evaluate().isNotEmpty;
      for (var n = 0; n < 12 && !closing(); n++) {
        if (find.text('NEXT').evaluate().isNotEmpty) {
          await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
        } else {
          await t.tapAt(const Offset(200, 300));
          await wait(t, const Duration(milliseconds: 900));
        }
      }
      if (find.text('CLOSE THE CASE').evaluate().isNotEmpty) await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue, reason: p.play.texts());
      expect(find.text('CASE 01 COMPLETE'), findsOneWidget, reason: p.play.texts());
      for (var n = 0; n < 4 && find.text('SEE MY CASE REPORT').hitTestable().evaluate().isEmpty; n++) {
        await t.tapAt(t.getCenter(find.byType(Scaffold).last));
        await wait(t, const Duration(milliseconds: 1200));
      }
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: p.play.texts());

      // The reveal at the level: real history, then what this mystery made up.
      final reveal = season.historyReveals['s7_ep01']!;
      final real = find.text('REAL HISTORY'), made = find.text('IN THIS MYSTERY');
      await t.ensureVisible(made);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.getTopLeft(real).dy, lessThan(t.getTopLeft(made).dy));
      for (final line in [...reveal.realHistory, ...reveal.inThisMystery]) {
        expect(findReadableContaining(line.at(level)), findsWidgets, reason: '${level.label}: "${line.at(level)}"');
      }
      final sources = find.byKey(const ValueKey('history-sources'));
      await t.ensureVisible(sources);
      await t.tap(sources);
      await wait(t, const Duration(milliseconds: 400));
      expect(find.text(reveal.sources.first.publisher), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }
}
