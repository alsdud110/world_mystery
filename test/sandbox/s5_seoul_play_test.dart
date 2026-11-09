import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import 'single_case.dart';

/// Seoul (Season 5) Case 01 V4, The King's Secret Letters, played alone in
/// the real app at every level: Bun-i's picture note (a wrong drawing, a
/// hint), the app opened again, the letters laid on the mouth with a wrong
/// pair, her first word with a wrong block, King Sejong's two questions and
/// her letter's two papers, paid once, the ending at dawn, and the Case
/// Closed file with its REAL HISTORY apart from IN THIS MYSTERY.
void main() {
  final season = season5Content;

  test('Season 5 as the game takes it: valid, a reveal, one of the game\'s seasons, once', () {
    expect(SeasonContentValidator.validate(season), isEmpty);
    // A reveal for every case (the season whole since 2026-11-06).
    expect(season.historyReveals.keys, [for (var n = 1; n <= 12; n++) 's5_ep${n.toString().padLeft(2, '0')}']);
    expect([for (final s in SeasonCatalog.all) if (s.id == season.id) s], [same(season)]);
    // Case 01's engines: the picture note's traces, the letters on the mouth, the first word, the King's talk before the letter's papers.
    expect(season.deductions.keys.where((id) => id.startsWith('s5_ep01_')), ['s5_ep01_m1']);
    expect(season.shapes.keys.where((id) => id.startsWith('s5_ep01_')), ['s5_ep01_m2']);
    expect(season.syllables.keys.where((id) => id.startsWith('s5_ep01_')), ['s5_ep01_m3']);
    expect(season.talks.keys.where((id) => id.startsWith('s5_ep01_')), isEmpty);
    expect(season.talkMissions['s5_ep01_final']!.before!.presents.map((p) => p.id), ['what', 'written']);
    expect(const SyllableRules().answer(season.syllables['s5_ep01_m3']!), '엄마');
  });

  for (final level in Difficulty.values) {
    testWidgets('s5_ep01 at ${level.label}: from its opening to the Case Closed file', (t) async {
      final one = SingleCase(season, 's5_ep01', level: level)..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await one.open(t, prefs, fresh: true);
      final p = CasePlayer(t, season);
      final ep = one.episode;
      bool done(String id) => c.read(gameControllerProvider).isCompleted(id);
      int wrong(String id) => c.read(gameControllerProvider).wrongAnswers[id] ?? 0;
      expect(c.read(currentDifficultyProvider), level);

      // M1, Bun-i's picture note: SORRY chosen, the try-again sheet, a hint, then THANK YOU.
      final m1 = ep.missions[0];
      expect(m1.answer, 'thanks');
      await p.toPuzzle(m1);
      await p.answer(m1, 'sorry');
      expect(wrong(m1.id), 1, reason: p.play.texts());
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await t.ensureVisible(find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 900));
      expect(c.read(gameControllerProvider).hintsFor(m1.id), 1, reason: p.play.texts());
      final before = c.read(walletProvider).balance;
      await p.answer(m1);
      expect(done(m1.id), isTrue, reason: p.play.texts());
      expect(c.read(walletProvider).balance - before, greaterThan(0));
      await p.onToMap();

      // Closed and opened again: M1 kept, M2 still open, M1 never paid twice.
      c = await one.open(t, prefs, fresh: false);
      expect([done(m1.id), done(ep.missions[1].id)], [true, false]);
      expect(c.read(gameControllerProvider.notifier).submitAnswer(m1, m1.answer).coins, 0, reason: 'paid once');

      // M2, the letters on the mouth: ㄱ on the tongue refused with its own line, then the three pairs.
      final m2 = ep.missions[1];
      expect(m2.type, MissionType.matchPairs);
      expect(m2.answer, 'mieum:lips,nieun:tongue,ieung:throat');
      await p.toPuzzle(m2);
      const wrongPairs = 'mieum:lips,giyeok:tongue,ieung:throat';
      await p.answer(m2, wrongPairs);
      expect([done(m2.id), wrong(m2.id)], [false, 1], reason: p.play.texts());
      expect(findReadableContaining(AnswerChecker.feedbackFor(m2, wrongPairs)!), findsWidgets, reason: 'the wrong pair answered in English');
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await p.answer(m2);
      expect(done(m2.id), isTrue, reason: p.play.texts());
      await p.onToMap();

      // M3, Bun-i's first word: 어마 (no last sound) refused, its block pointed at; then 엄마.
      final m3 = ep.missions[2];
      await p.toPuzzle(m3);
      await p.answer(m3, '어마');
      expect([done(m3.id), wrong(m3.id)], [false, 1], reason: p.play.texts());
      expect(find.text('BLOCK 1 · CHECK'), findsOneWidget, reason: 'the wrong block pointed at');
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      await p.answer(m3);
      expect(done(m3.id), isTrue, reason: p.play.texts());
      expect(c.read(gameControllerProvider).puzzleStateOf(m3.id), startsWith('pv2:syllables:1:'), reason: 'every move saved');
      await p.onToMap();

      // The final: King Sejong's two questions, then the letter's two papers.
      await p.solveFinal(ep.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(ep.finalMission.id), isTrue, reason: p.play.texts());
      // The ending (the name, then Bun-i at dawn), its Discovery Moment, then the case closed.
      bool closing() => find.text('CLOSE THE CASE').evaluate().isNotEmpty || find.text('SEE MY CASE REPORT').evaluate().isNotEmpty;
      var heardBunI = false;
      for (var n = 0; n < 48 && !closing(); n++) {
        heardBunI |= findReadableContaining('Thank you, Mom!').evaluate().isNotEmpty;
        if (find.text('CONTINUE INVESTIGATION').evaluate().isNotEmpty) {
          await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
        } else if (find.text('NEXT').evaluate().isNotEmpty) {
          await tapText(t, 'NEXT', after: const Duration(milliseconds: 600));
        } else {
          await t.tapAt(const Offset(200, 300));
          await wait(t, const Duration(milliseconds: 900));
        }
      }
      if (find.text('CLOSE THE CASE').evaluate().isNotEmpty) await tapText(t, 'CLOSE THE CASE', after: const Duration(milliseconds: 1500));
      expect(heardBunI || level != Difficulty.rookie, isTrue, reason: 'Bun-i\'s line at dawn');
      expect(c.read(gameControllerProvider).isCaseSolved, isTrue, reason: p.play.texts());
      expect(find.text('CASE 01 COMPLETE'), findsOneWidget, reason: p.play.texts());
      for (var n = 0; n < 4 && find.text('SEE MY CASE REPORT').hitTestable().evaluate().isEmpty; n++) {
        await t.tapAt(t.getCenter(find.byType(Scaffold).last));
        await wait(t, const Duration(milliseconds: 1200));
      }
      await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
      expect(find.text('CASE CLOSED'), findsOneWidget, reason: p.play.texts());

      // The reveal at the level: real history, then what this mystery made up.
      final reveal = season.historyReveals['s5_ep01']!;
      final real = find.text('REAL HISTORY'), made = find.text('IN THIS MYSTERY');
      await t.ensureVisible(made);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.getTopLeft(real).dy, lessThan(t.getTopLeft(made).dy));
      for (final line in [...reveal.realHistory, ...reveal.inThisMystery]) {
        expect(findReadableContaining(line.at(level)), findsWidgets, reason: '${level.label}: "${line.at(level)}"');
      }
      expect(reveal.inThisMystery.any((l) => l.at(level).contains('King Sejong')), isTrue, reason: 'the King\'s words said to be made up');
      final sources = find.byKey(const ValueKey('history-sources'));
      await t.ensureVisible(sources);
      await wait(t, const Duration(milliseconds: 600));
      await t.ensureVisible(sources);
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(sources);
      await wait(t, const Duration(milliseconds: 400));
      expect(reveal.sources.map((x) => x.publisher).toSet().any((name) => findReadableContaining(name).evaluate().isNotEmpty), isTrue, reason: 'its sources listed: ${p.play.texts()}');
      expect(t.takeException(), isNull);
    });
  }
}
