import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/timeline_rules.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart';
import 'sandbox_play.dart';
import 'sandbox_season.dart';

/// Puzzle Engine 2.0 PART 3B: a timeline played as a mission of the real
/// app — its page, `submitAnswer`, `recordPuzzleState`, hints, the try-again
/// sheet, the Discovery Moment, the solved page — with the sandbox's Case
/// 01 Mission 1 made a timeline for the test only (no season of the game
/// has one). Its words at each level are its own; the order is one.
void main() {
  final base = sandboxContent;
  final caseJson = jsonDecode(jsonEncode(base.episodes['s9_ep01'])) as Map<String, dynamic>;
  final m1Json = (caseJson['missions'] as List).first as Map<String, dynamic>;
  final m1 = m1Json['id'] as String;

  TimelineSpec spec(String level) => TimelineSpec(
    cards: [
      const TimelineCard(id: 'gauge', title: 'THE GAUGE', text: 'A bronze cup for the rain.', anchor: '1441'),
      TimelineCard(id: 'letter', title: 'THE LETTER', text: switch (level) {
        'junior' => 'The clerk writes a letter to the palace.',
        'master' => 'The clerk sends a carefully worded letter to the palace.',
        _ => 'The clerk writes to the palace.',
      }),
      const TimelineCard(id: 'bridge', title: 'THE BRIDGE', text: 'A stone marks the water.'),
      const TimelineCard(id: 'book', title: 'THE BOOK', text: 'The new letters are shared.', anchor: '1446'),
      const TimelineCard(id: 'list', title: 'A SHOPPING LIST', text: 'Rice and tea.', discard: true),
    ],
    order: const ['gauge', 'letter', 'bridge', 'book'],
    relations: [
      TimelineRelation(earlier: 'letter', later: 'bridge', line: level == 'master' ? 'Only once the letter had arrived was a stone set by the bridge.' : 'After the letter, a stone was set by the bridge.'),
    ],
  );

  m1Json
    ..['type'] = 'sequence'
    ..['answer'] = 'gauge,letter,bridge,book'
    ..['codeLength'] = 4
    ..['question'] = 'Put what happened in order.'
    ..['options'] = [
      for (final c in spec('rookie').cards) {'id': c.id, 'label': c.title},
    ]
    ..['orderFeedback'] = 'Read the clerk\'s letter again: what came after it?'
    ..remove('feedback');

  SeasonContent content({Map<Difficulty, SeasonContent>? variants}) => SeasonContent(
    info: base.info,
    episodes: {...base.episodes, 's9_ep01': caseJson},
    places: base.places,
    released: false,
    storyGreeting: base.storyGreeting,
    learning: base.learning,
    languageTopics: base.languageTopics,
    evidenceLinks: base.evidenceLinks,
    talkMissions: base.talkMissions,
    discoveries: base.discoveries,
    endings: base.endings,
    timelines: {m1: spec('rookie')},
    variants: variants ??
        {
          Difficulty.junior: SeasonContent(info: const {}, episodes: const {}, timelines: {m1: spec('junior')}),
          Difficulty.master: SeasonContent(info: const {}, episodes: const {}, timelines: {m1: spec('master')}),
        },
  );
  final season = content();
  List<Episode> episodes() => [for (final json in season.episodes.values) Episode.fromJson(json)];

  setUp(() {
    SeasonCatalog.testPlaces.addAll(season.places);
    SeasonCatalog.testSeasons.add(season);
  });
  tearDown(() {
    SeasonCatalog.testPlaces.clear();
    SeasonCatalog.testSeasons.clear();
  });

  List<Override> overrides({Difficulty? level}) => [
    seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, season.season]),
    allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), ...episodes()]),
    seasonMapsProvider.overrideWithValue({...SeasonMap.bySeason, sandboxSeasonId: SeasonMap.paris}),
    seasonReleasedProvider.overrideWithValue((id) => id == sandboxSeasonId || seasonReleased(id)),
    operatorToolsAvailableProvider.overrideWithValue(true),
    if (level != null) seasonDifficultyProvider(sandboxSeasonId).overrideWithValue(level),
  ];

  test('the game\'s validator takes it, and refuses a level that changes the game', () {
    expect(SeasonContentValidator.validate(season), isEmpty);
    final swapped = TimelineSpec(cards: spec('master').cards, order: const ['gauge', 'bridge', 'letter', 'book'],
        relations: const [TimelineRelation(earlier: 'bridge', later: 'letter', line: 'x')]);
    final broken = content(variants: {Difficulty.master: SeasonContent(info: const {}, episodes: const {}, timelines: {m1: swapped})});
    expect([for (final i in SeasonContentValidator.validate(broken)) i.rule], containsAll(['engine']));
    expect(SeasonContentValidator.validate(broken).map((i) => i.message).join(), contains('level_changes_answer'));
  });

  test('each level finds its own words, the one order', () {
    final m = Episode.fromJson(season.episodes['s9_ep01']!).missions.first;
    for (final (d, words) in [
      (Difficulty.rookie, 'The clerk writes to the palace.'),
      (Difficulty.junior, 'The clerk writes a letter to the palace.'),
      (Difficulty.master, 'The clerk sends a carefully worded letter to the palace.'),
    ]) {
      final leveled = Mission.fromJson(m.toJson(), difficulty: d);
      final found = SeasonCatalog.timeline(leveled)!;
      expect(found.card('letter')!.text, words, reason: d.name);
      expect(const TimelineRules().answer(found), m.answer, reason: d.name);
    }
  });

  group('played in the real app', () {
    Future<(ProviderContainer, SharedPreferences)> open(WidgetTester t, {SharedPreferences? prefs, Difficulty? level, bool fresh = true}) async {
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      if (prefs == null) SharedPreferences.setMockInitialValues({});
      final p = prefs ?? await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [...await testOverridesFor(p), ...overrides(level: level)]);
      addTearDown(c.dispose);
      c.read(seasonPreviewSwitchProvider.notifier).set(true);
      final ctrl = c.read(gameControllerProvider.notifier);
      if (fresh) ctrl.createDetective('Kim', DetectiveAvatar.girl);
      expect(ctrl.openSeason(sandboxSeasonId), isTrue);
      if (fresh) {
        expect(ctrl.openEpisode('s9_ep01'), isTrue);
        ctrl.startInvestigation();
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));
      await wait(t);
      if (fresh) {
        // A case begins with its Story Intro, then the map.
        c.read(routerProvider).go(Routes.intro);
        await wait(t, const Duration(milliseconds: 1500));
        await tapText(t, 'SKIP ›');
        await tapText(t, "I'M READY", after: const Duration(milliseconds: 2000));
      } else {
        c.read(routerProvider).go(Routes.map);
      }
      await wait(t, const Duration(milliseconds: 2500));
      return (c, p);
    }

    Mission mission(ProviderContainer c) => c.read(currentEpisodeProvider).missions.first;
    Finder slot(int i) => find.byKey(ValueKey('timeline-slot-$i'));
    Finder card(String id) => find.byKey(ValueKey('timeline-card-$id'));
    Future<void> tap(WidgetTester t, Finder f) async {
      await t.ensureVisible(f);
      await wait(t, const Duration(milliseconds: 200));
      await t.tap(f);
      await wait(t, const Duration(milliseconds: 200));
    }

    String label(WidgetTester t, Finder f) => t.getSemantics(f).label;
    TimelineState? saved(ProviderContainer c) =>
        PuzzleStateCodec.decode(const TimelineRules(), spec('rookie'), c.read(gameControllerProvider).puzzleStateOf(m1));

    testWidgets('placed, left, come back to, closed, opened again; wrong, then right; paid once; shown solved', (t) async {
      var (c, prefs) = await open(t);
      final play = SandboxPlay(t);
      final m = mission(c);
      expect(m.id, m1);
      await play.toPuzzle(m);
      expect(find.byKey(const ValueKey('timeline-board')), findsOneWidget, reason: play.texts());

      // Two cards placed (the wrong way round), the list set aside: saved as they go.
      await tap(t, card('bridge'));
      await tap(t, slot(1));
      await tap(t, card('letter'));
      await tap(t, slot(2));
      await tap(t, card('list'));
      await tap(t, find.byKey(const ValueKey('timeline-pile')));
      expect(saved(c)!.slots, ['gauge', 'bridge', 'letter', 'book']);
      expect(saved(c)!.discarded, {'list'});

      // Back to the letter, then the puzzle again: as it was left.
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 900));
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
      expect(label(t, slot(1)), contains('THE BRIDGE'), reason: play.texts());

      // The app closed and opened again on the same storage: as it was left.
      (c, prefs) = await open(t, prefs: prefs, fresh: false);
      // GO TO the place: the mission page goes on where it was left, the puzzle itself.
      await t.tap(find.bySemanticsLabel('GO TO ${mission(c).location}'));
      await wait(t, const Duration(milliseconds: 2800));
      expect(find.byKey(const ValueKey('timeline-board')), findsOneWidget, reason: play.texts());
      expect(label(t, slot(2)), contains('THE LETTER'));
      expect(label(t, card('list')), contains('not part of it'));

      // Wrong: the try-again sheet with the mission's own line, the hint offered, the card out of place marked.
      await tap(t, find.text('CHECK THE ORDER'));
      expect(find.textContaining('what came after it?'), findsWidgets, reason: play.texts());
      expect(find.textContaining('Hint'), findsWidgets, reason: 'a hint is offered: ${play.texts()}');
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      expect(find.text('CHECK THIS ONE'), findsOneWidget);
      expect(c.read(gameControllerProvider).wrongAnswers[m1], 1);
      expect(c.read(gameControllerProvider).isCompleted(m1), isFalse);

      // A hint, as every puzzle's.
      await tap(t, find.text('Get a Free Hint'));
      await wait(t, const Duration(milliseconds: 900));
      expect(c.read(gameControllerProvider).hintsFor(m1), 1, reason: play.texts());
      expect(findReadableContaining(mission(c).hints.first), findsWidgets, reason: 'the hint shown: ${play.texts()}');

      // Right: the two swapped; paid.
      final coinsBefore = c.read(walletProvider).balance;
      await tap(t, slot(2));
      await tap(t, slot(1));
      await tap(t, find.text('CHECK THE ORDER'));
      await wait(t, const Duration(milliseconds: 1500));
      final progress = c.read(gameControllerProvider);
      expect(progress.isCompleted(m1), isTrue, reason: play.texts());
      final paid = c.read(walletProvider).balance - coinsBefore;
      expect(paid, greaterThan(0));
      await play.onToMap(mission(c));

      // The same answer again (a double tap, a second page): nothing more paid.
      final again = c.read(gameControllerProvider.notifier).submitAnswer(mission(c), mission(c).answer);
      expect([again.result, again.coins], [SubmitResult.correct, 0]);
      expect(c.read(walletProvider).balance - coinsBefore, paid);

      // Opened again: SOLVED, the timeline as it happened, nothing to play.
      c.read(routerProvider).go(Routes.mission(m1));
      await wait(t, const Duration(milliseconds: 1500));
      final solved = find.byKey(ValueKey('timeline-solved-$m1'));
      expect(solved, findsOneWidget, reason: play.texts());
      await t.ensureVisible(solved);
      await t.pump();
      expect(find.text('WHAT HAPPENED'), findsOneWidget);
      expect(find.text('CHECK THE ORDER'), findsNothing);
      expect(label(t, slot(1)), contains('THE LETTER'));
    });

    testWidgets('a broken save opens the puzzle afresh, never stuck', (t) async {
      final (c, _) = await open(t);
      c.read(gameControllerProvider.notifier).recordPuzzleState(m1, 'pv2:timeline:1:{"s":["gauge"');
      final play = SandboxPlay(t);
      await play.toPuzzle(mission(c));
      expect(label(t, slot(1)), 'Place 2 of 4, empty');
      expect(card('letter'), findsOneWidget);
    });

    testWidgets('Master: its own words on the cards, the same places', (t) async {
      final (c, _) = await open(t, level: Difficulty.master);
      final play = SandboxPlay(t);
      final m = mission(c);
      expect(m.difficulty, Difficulty.master);
      await play.toPuzzle(m);
      expect(label(t, card('letter')), contains('carefully worded letter'));
      expect(label(t, slot(0)), contains('fixed, 1441'));
    });
  });
}
