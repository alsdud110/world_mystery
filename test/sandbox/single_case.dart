import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game_master/dev_session.dart' show pilotOverrides;
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import '../mission_play.dart';
import 'sandbox_play.dart';
import '../reading_finders.dart';

/// One case of a generated sandbox season, alone in the real app, for the
/// tests only (Seoul Pilot Case 01): the season given beside the game's own
/// with that one case (so it is the season's first, open), Paris's map lent
/// for its pins, the game's own missions, puzzles, Case Closed file and
/// `GameController` — the overrides developer mode's pilot uses too
/// (`pilotOverrides`); the saved data is the test's own (mock preferences).
///
/// It takes content already made: a historical season's is made only once
/// its history is approved (`HistoryGate`, the generator), so before that
/// there is nothing here to play.
class SingleCase {
  SingleCase(this.season, this.caseId, {this.level = Difficulty.standard});

  final SeasonContent season;
  final String caseId;

  /// The detective's level: the case in its words ([SeasonContent.casePatches]).
  final Difficulty level;

  String get seasonId => season.id;
  Episode get episode => DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes[caseId]!, 'seasonId': seasonId}),
    level,
    patches: season.casePatches,
  );

  List<Override> overrides() => [
    ...pilotOverrides(season, caseId, level),
    operatorToolsAvailableProvider.overrideWithValue(true),
  ];

  /// Its places and tables found as the game's own ([SeasonCatalog.testSeasons]); undone by [unregister].
  void register() {
    SeasonCatalog.testPlaces.addAll(season.places);
    SeasonCatalog.testSeasons.add(season);
  }

  void unregister() {
    SeasonCatalog.testPlaces.clear();
    SeasonCatalog.testSeasons.clear();
  }

  /// The app opened on [size] (logical) with [prefs]: [fresh], a new
  /// detective and the case begun from its opening; else back on the map
  /// as it was saved (the app opened again).
  Future<ProviderContainer> open(WidgetTester t, SharedPreferences prefs, {required bool fresh, Size size = const Size(390, 844)}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final c = ProviderContainer(overrides: [...await testOverridesFor(prefs), ...overrides()]);
    addTearDown(c.dispose);
    c.read(seasonPreviewSwitchProvider.notifier).set(true);
    final ctrl = c.read(gameControllerProvider.notifier);
    if (fresh) ctrl.createDetective('Kim', DetectiveAvatar.girl, difficulty: level);
    expect(ctrl.openSeason(seasonId), isTrue);
    expect(ctrl.openEpisode(caseId), isTrue, reason: '$caseId is the season\'s one case: open');
    if (fresh) {
      ctrl.settleSeasonLevel(); // as its first intro does, before the intro is marked seen
      ctrl.startInvestigation();
    }
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
    await wait(t);
    if (fresh) {
      c.read(routerProvider).go(Routes.intro);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'SKIP ›');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
    } else {
      c.read(routerProvider).go(Routes.map);
    }
    await wait(t, const Duration(milliseconds: 2500));
    return c;
  }
}

/// A case's missions played with each engine's own controls, the answers
/// the missions' own data (nothing solved behind the screen).
class CasePlayer {
  CasePlayer(this.t, this.season);

  final WidgetTester t;
  final SeasonContent season;
  late final play = SandboxPlay(t);
  final mp = MissionPlay();

  /// From the map to [m]'s puzzle: its place, INVESTIGATE, and the letter
  /// when it has one (a scene engine opens on its scene).
  Future<void> toPuzzle(Mission m) async {
    await play.toPlace(m);
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 1200));
    // The person's talk before the puzzle, heard to its finish.
    if (SeasonCatalog.talkMission(m)?.before case final before?) await _heardTo(before.finishLabel);
    for (final step in ['TAP TO OPEN', 'SOLVE THE PUZZLE']) {
      if (findText(step).evaluate().isNotEmpty) await tapText(t, step, after: const Duration(milliseconds: 1500));
    }
  }

  /// [answer] put into [m]'s puzzle (by default its own), on its engine.
  Future<void> answer(Mission m, [String? answer]) async {
    final a = answer ?? m.answer;
    if (season.timelines[m.id] case final spec?) {
      final kept = Mission.sequenceIds(a);
      for (final (i, id) in kept.indexed) {
        if (spec.card(id)?.anchor != null) continue; // fixed in its slot
        await _tap(find.byKey(ValueKey('timeline-card-$id')));
        await _tap(find.byKey(ValueKey('timeline-slot-$i')));
      }
      for (final c in spec.cards.where((c) => c.discard)) {
        await _tap(find.byKey(ValueKey('timeline-card-${c.id}')));
        await _tap(find.byKey(const ValueKey('timeline-pile')));
      }
      await _tap(find.text('CHECK THE ORDER'));
    } else if (season.records[m.id] case final scene?) {
      final [first, second] = a.split(':');
      for (final key in [
        'record-tab-${scene.second.id}', 'record-tab-${scene.first.id}', 'line-${scene.first.id}-$first', //
        'record-tab-${scene.second.id}', 'line-${scene.second.id}-$second', 'records-check',
      ]) {
        await mp.tapKey(t, key);
      }
    } else if (season.deductions[m.id] case final scene?) {
      await mp.noteClues(t, scene);
      await mp.chooseAndSearch(t, scene, a);
    } else if (season.variants[m.difficulty]?.syllables[m.id] ?? season.syllables[m.id] case final spec?) {
      // Each group's vowel as the note [a] writes it: its line, then its dot.
      // On a paper whose sounds are chosen, each place tapped first, then its
      // first sound and the sound at its bottom too.
      for (final (i, b) in spec.blocks.indexed) {
        if (b.given) continue;
        final code = a.codeUnitAt(i) - 0xAC00;
        final vowel = Hangul.vowels[code ~/ 28 % 21];
        final (line, dot) = Hangul.partsOf(vowel)!;
        if (spec.choosesSounds) {
          await _tap(find.byKey(ValueKey('syllable-cell-${b.id}')));
          await _tap(find.byKey(ValueKey('syllable-sound-${b.id}-${Hangul.initials[code ~/ 588]}')));
        }
        await _tap(find.byKey(ValueKey('syllable-line-${b.id}-${line.name}')));
        if (dot != VowelDot.none || spec.choosesSounds) await _tap(find.byKey(ValueKey('syllable-dot-${b.id}-${dot.name}')));
        if (spec.choosesSounds && spec.bottoms.isNotEmpty) {
          final bottom = Hangul.finals[code % 28];
          await _tap(find.byKey(ValueKey('syllable-bottom-${b.id}-${bottom.isEmpty ? 'none' : bottom}')));
        }
      }
      await _tap(find.byKey(const ValueKey('syllable-check')));
    } else if (season.shapes.containsKey(m.id)) {
      // Each letter tapped, then the picture it goes on; then CHECK.
      for (final [letter, picture] in [for (final p in Mission.sequenceIds(a)) p.split(':')]) {
        await _tap(find.byKey(ValueKey('shape-letter-$letter')));
        await _tap(find.byKey(ValueKey('shape-picture-$picture')));
      }
      await _tap(find.byKey(const ValueKey('shape-check')));
    } else if (season.inspections[m.id] case final scene?) {
      await mp.openInspectLabel(t, scene);
      await mp.writeOnLabel(t, a);
    } else {
      await play.answer(m, a);
      return;
    }
    await wait(t, const Duration(milliseconds: 1200));
    // The person's talk after the find (its face), heard to its finish.
    if (SeasonCatalog.talkMission(m)?.after case final after? when a == m.answer) await _heardTo(after.finishLabel);
  }

  /// A talk's lines heard (its typing skipped) to [finishLabel], tapped.
  Future<void> _heardTo(String finishLabel) async {
    for (var i = 0; i < 30 && findText(finishLabel).evaluate().isEmpty; i++) {
      if (find.text('NEXT').evaluate().isNotEmpty) {
        await tapText(t, 'NEXT', after: const Duration(milliseconds: 400));
      } else {
        await t.tapAt(const Offset(160, 300)); // its typing skipped
        await wait(t, const Duration(milliseconds: 600));
      }
    }
    expect(findText(finishLabel), findsWidgets, reason: 'the talk heard to $finishLabel: ${play.texts()}');
    await tapText(t, finishLabel, after: const Duration(milliseconds: 1200));
  }

  /// The Discovery Moment, the scene after it (its typing skipped) when
  /// there is one, and the map again.
  Future<void> onToMap() async {
    await wait(t, const Duration(milliseconds: 2800));
    await tapText(t, 'CONTINUE INVESTIGATION', after: const Duration(milliseconds: 1500));
    if (find.text('TO THE MAP').evaluate().isEmpty) {
      await t.tapAt(const Offset(200, 400)); // skip typing
      await wait(t, const Duration(milliseconds: 900));
    }
    await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
    await wait(t, const Duration(milliseconds: 3200));
    // The next lead's pin, or (after the last mission) the final's.
    expect(find.bySemanticsLabel(RegExp('^GO TO ')).evaluate().isNotEmpty || find.text('OPEN THE FINAL CASE').evaluate().isNotEmpty, isTrue, reason: play.texts());
  }

  /// The final opened from the map and solved: a talk shown its evidence
  /// (each step's first accepted card, in [TalkScene] order), else its answer.
  Future<void> solveFinal(Mission fin) async {
    if (season.talks[fin.id] case final talk?) {
      await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
      await heard();
      for (final step in talk.finishWhen) {
        await mp.tapKey(t, 'case-talk-choice-${talk.present(step)!.accepted.first}', after: const Duration(milliseconds: 600));
        await heard();
      }
      await mp.tapKey(t, 'case-talk-finish', after: const Duration(milliseconds: 1500));
    } else if (SeasonCatalog.talkMission(fin)?.before case final before? when before.presents.isNotEmpty) {
      // Evidence shown in turn, then the final's puzzle on its page.
      await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
      await heard();
      for (final p in before.presents) {
        await mp.tapKey(t, 'case-talk-choice-${p.accepted.first}', after: const Duration(milliseconds: 600));
        await heard();
      }
      await mp.tapKey(t, 'case-talk-finish', after: const Duration(milliseconds: 1500));
      await answer(fin);
    } else {
      await play.toFinal(fin);
      await play.answer(fin, fin.answer);
    }
  }

  /// The talk's lines heard to its next choice.
  Future<void> heard() async {
    for (var i = 0; i < 30 && find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty; i++) {
      await mp.tapKey(t, 'case-talk-next', after: const Duration(milliseconds: 500));
    }
  }

  Future<void> _tap(Finder f) async {
    await t.ensureVisible(f);
    await wait(t, const Duration(milliseconds: 200));
    await t.tap(f);
    await wait(t, const Duration(milliseconds: 200));
  }
}
