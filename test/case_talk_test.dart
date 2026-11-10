import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/widgets/case_talk.dart';
import 'package:world_mystery/features/mission/widgets/evidence_recall.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'helpers.dart';

/// CaseTalk, the talk with one person of Season 2's Cases 11–12: questions
/// asked, evidence shown from the notebook, the person's face changing, new
/// questions opening, and the talk saved in the case save's puzzle states
/// (no key of its own). Played here on a talk made for the test only: the
/// cases' own talks are not in the game yet, and no mission of the game
/// changes.
void main() {
  // A talk for the test (not a case's): two questions, one opened by the
  // other; a piece of evidence to show; a name learnt on the way.
  final scene = TalkScene(
    id: 'test_talk',
    speaker: const TalkSpeaker(
      id: 'man',
      name: 'MR TEST',
      hiddenName: '???',
      revealedBy: 'show',
      portraits: {'base': 'missing/base.png', 'nervous': 'missing/nervous.png'},
    ),
    goal: 'Find out what he hid.',
    opening: const [
      TalkLine.narrator('A man waits by the door.'),
      TalkLine('Hello, detective.'),
    ],
    questions: const [
      TalkQuestion(
        id: 'who',
        text: 'Who are you?',
        beat: [TalkLine("Don't ask me."), TalkLine('Find out with clues.')],
      ),
      TalkQuestion(
        id: 'why',
        text: 'Why did you hide it?',
        requires: {'show'},
        beat: [TalkLine('I was afraid.', mood: 'nervous')],
      ),
    ],
    presents: const [
      TalkPresent(
        id: 'show',
        prompt: 'Show him what you found.',
        requires: {'who'},
        accepted: {'right'},
        beat: [TalkLine('That box was locked!', mood: 'nervous'), TalkLine('All right.')],
        misses: {'close': TalkLine('That is not mine.')},
      ),
    ],
    finishWhen: {'show', 'why'},
    answer: 'q:done',
  );

  group('the talk, step by step (data only)', () {
    test('the opening, line by line; the face and the name as they are now', () {
      var p = TalkProgress.start;
      expect(p.current(scene)!.voice, TalkVoice.narrator);
      expect(p.beatOver(scene), isFalse);
      expect(p.questions(scene), isNotEmpty, reason: 'listed, shown once the beat is said');
      p = p.next(scene);
      expect(p.current(scene)!.text, 'Hello, detective.');
      expect(p.beatOver(scene), isTrue);
      expect(p.openingSeen, isTrue);
      expect(p.speakerName(scene), '???');
      expect(p.mood(scene), 'base');
    });

    test('a question opens only once what it needs is done', () {
      var p = TalkProgress.start.skip(scene);
      expect(p.questions(scene).map((q) => q.id), ['who']);
      expect(p.presents(scene), isEmpty, reason: 'nothing to show before the first question');
      expect(p.ask(scene, 'why'), p, reason: 'not open yet: nothing happens');
      p = p.ask(scene, 'who');
      expect(p.beatId, 'who');
      expect(p.line, 0);
      expect(p.done, ['who']);
      expect(p.nextPresent(scene)!.id, 'show');
      // Asked again: the same answer, done once.
      p = p.skip(scene).ask(scene, 'who');
      expect(p.done, ['who']);
    });

    test('the right evidence: its reaction, the face it brings, the name learnt, a new question', () {
      var p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (shown, fits) = p.show(scene, 'right');
      expect(fits, isTrue);
      p = shown;
      expect(p.beatId, 'show');
      expect(p.mood(scene), 'nervous');
      expect(p.next(scene).mood(scene), 'nervous', reason: 'a line without a mood keeps the face before it');
      expect(p.speakerName(scene), 'MR TEST');
      expect(p.questions(scene).map((q) => q.id), ['who', 'why']);
      expect(p.presents(scene), isEmpty, reason: 'shown once');
      expect(p.finished(scene), isFalse);
      p = p.ask(scene, 'why');
      expect(p.finished(scene), isTrue);
    });

    test('other evidence: the line for it, or the general one; never done, never wrong', () {
      final p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (close, fits) = p.show(scene, 'close');
      expect(fits, isFalse);
      expect(close.beatId, TalkProgress.missId('show', 'close'));
      expect(close.current(scene)!.text, 'That is not mine.');
      expect(close.done, ['who']);
      final (other, _) = p.show(scene, 'nothing_like_it');
      expect(other.current(scene)!.text, "I don't see what that means.");
      expect(other.nextPresent(scene)!.id, 'show', reason: 'still to be shown');
      expect(other.speakerName(scene), '???');
    });

    test('saved as a short string and read back as it was; anything strange starts afresh', () {
      final p = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'right').$1.next(scene);
      final raw = p.encode();
      expect(TalkProgress.decode(raw, scene), p);
      final miss = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'close').$1;
      expect(TalkProgress.decode(miss.encode(), scene), miss, reason: 'after the person answered a piece');
      expect(TalkProgress.decode(null, scene), TalkProgress.start);
      expect(TalkProgress.decode('not json', scene), TalkProgress.start);
      expect(TalkProgress.decode('[1,2]', scene), TalkProgress.start);
      final odd = TalkProgress.decode('{"d":["who","gone","who"],"b":"gone","l":9}', scene);
      expect(odd.done, ['who'], reason: 'unknown steps dropped, none twice');
      expect(odd.beatId, TalkScene.openingId);
      expect(odd.line, 1, reason: 'within the beat');
      expect(odd.openingSeen, isTrue);
    });

    test("the talk's save is an entry of the puzzle states, kept across a restart", () {
      expect(caseTalkStateKey('s2_ep11_m1'), 's2_ep11_m1:talk');
      final p = TalkProgress.start.skip(scene).ask(scene, 'who');
      final saved = const GameProgress().copyWith(puzzleStates: {caseTalkStateKey('m'): p.encode(), 'm': 'its puzzle'});
      final again = GameProgress.fromJson(saved.toJson());
      expect(TalkProgress.decode(again.puzzleStateOf(caseTalkStateKey('m')), scene), p);
      expect(again.puzzleStateOf('m'), 'its puzzle', reason: "the mission's own puzzle is kept apart");
    });

    test('Paris: only Case 11\'s final is played as a case talk; Seoul: its evidence-talk finals; Season 1 keeps its talk', () {
      final talked = [
        for (final e in MockEpisodeRepository.bundled())
          for (final m in e.allMissions)
            if (SeasonCatalog.caseTalk(m) != null) m.id,
      ];
      expect(talked.where((id) => !id.startsWith('s5_')), ['s2_ep11_final'], reason: 'hand-made seasons');
      // Seoul's finals played as a talk (PART 2–4 redesign); the others have a talk before their puzzle.
      expect(talked.where((id) => id.startsWith('s5_')), ['s5_ep04_final', 's5_ep06_final', 's5_ep07_final', 's5_ep09_final', 's5_ep10_final']);
      expect(season1Content.talks, isEmpty);
      expect(season1Content.talkMissions, isEmpty);
      expect(season1Content.dialogues.keys, ['ep06_m1']);
    });
  });

  group("Season 1's Clockmaker's watch in Season 2 (ep12_e4)", () {
    final all = MockEpisodeRepository.bundled();

    test('evidence ids never repeat across seasons', () {
      final ids = [for (final e in all) for (final v in e.allEvidence) v.id];
      expect(ids.toSet().length, ids.length);
      expect([for (final e in all) if (e.seasonId == SeasonIds.paris) ...e.allEvidence.map((v) => v.id)].every((id) => id.startsWith('s2_')), isTrue);
    });

    List<String> held({required bool solved, bool reference = false, String? playing}) => [
      for (final h in earlierSeasonEvidence(
        ids: const ['ep12_e4'],
        allEpisodes: all,
        seasonId: playing ?? SeasonIds.paris,
        solved: (e) => solved && e.id == 'ep12',
        reference: reference,
      ))
        '${h.evidence.id}|${h.evidence.name}|${h.episode.id}|${h.location}',
    ];

    test("held when Season 1's Case 12 is solved (as every Season 2 player's is)", () {
      expect(held(solved: true), ["ep12_e4|The Clockmaker's Watch|ep12|${all.firstWhere((e) => e.id == 'ep12').finalMission.location}"]);
    });

    test('not held when it is not solved; shown for reference in operator access or the season preview', () {
      expect(held(solved: false), isEmpty);
      expect(held(solved: false, reference: true), hasLength(1));
    });

    test('never as an earlier season while Season 1 itself is played', () {
      expect(held(solved: true, playing: AppConstants.firstSeasonId), isEmpty);
    });
  });

  group('the talk on screen', () {
    Future<(List<TalkProgress>, List<String>)> pumpTalk(
      WidgetTester t, {
      TalkProgress start = TalkProgress.start,
      String? pick,
      TalkScene? talk,
    }) async {
      final saved = <TalkProgress>[];
      final finished = <String>[];
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: CaseTalk(
                scene: talk ?? scene,
                progress: start,
                onProgress: saved.add,
                onFinish: () => finished.add('done'),
                pickEvidence: (_) async => pick,
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      return (saved, finished);
    }

    Future<void> tapKey(WidgetTester t, String key) async {
      await t.ensureVisible(find.byKey(ValueKey(key)));
      await t.tap(find.byKey(ValueKey(key)));
      // The new line comes a frame later (showing evidence waits for the
      // notebook), then is typed out.
      await t.pump();
      await t.pump(const Duration(seconds: 3));
    }

    testWidgets('the opening, then a question, its answer, and the next one opened', (t) async {
      final (saved, _) = await pumpTalk(t);
      expect(find.text('A man waits by the door.'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-name')), findsNothing, reason: "the narrator's line has no name plate");
      expect(find.byKey(const ValueKey('case-talk-q-who')), findsNothing, reason: 'nothing to choose while a line is said');
      await tapKey(t, 'case-talk-next');
      expect(find.text('"Hello, detective."'), findsOneWidget);
      expect(find.text('???'), findsOneWidget, reason: 'his name is not known yet');
      expect(find.byKey(const ValueKey('case-talk-show')), findsNothing, reason: 'nothing to show before the first question');
      await tapKey(t, 'case-talk-q-who');
      expect(find.text('"Don\'t ask me."'), findsOneWidget);
      expect(saved.last.done, ['who']);
      await tapKey(t, 'case-talk-line');
      expect(find.text('"Find out with clues."'), findsOneWidget);
      expect(find.text('Show him what you found.'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-show')), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-q-why')), findsNothing);
    });

    testWidgets('the right evidence: the reaction, the name, the new question; then the way on', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (saved, finished) = await pumpTalk(t, start: start, pick: 'right');
      await tapKey(t, 'case-talk-show');
      expect(find.text('"That box was locked!"'), findsOneWidget);
      expect(find.text('MR TEST'), findsOneWidget, reason: 'his name, learnt from the evidence');
      expect(saved.last.done, ['who', 'show']);
      await tapKey(t, 'case-talk-next');
      await tapKey(t, 'case-talk-q-why');
      expect(find.text('"I was afraid."'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-finish')), findsOneWidget);
      await tapKey(t, 'case-talk-finish');
      await tapKey(t, 'case-talk-finish');
      expect(finished, ['done'], reason: 'once');
    });

    testWidgets('other evidence: what he says to it; it can be shown again', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      final (saved, _) = await pumpTalk(t, start: start, pick: 'close');
      await tapKey(t, 'case-talk-show');
      expect(find.text('"That is not mine."'), findsOneWidget);
      expect(find.text('???'), findsOneWidget);
      expect(saved.last.done, ['who']);
      expect(find.byKey(const ValueKey('case-talk-show')), findsOneWidget, reason: 'still to be shown');
    });

    testWidgets('a talk left anywhere opens there again (a restart)', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene).show(scene, 'right').$1;
      final again = TalkProgress.decode(start.encode(), scene);
      await pumpTalk(t, start: again);
      expect(find.text('"That box was locked!"'), findsOneWidget);
      expect(find.text('MR TEST'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-skip')), findsNothing, reason: 'not heard to its end yet');
    });

    testWidgets('a beat heard before can be skipped', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      await pumpTalk(t, start: start);
      await tapKey(t, 'case-talk-q-who');
      expect(find.byKey(const ValueKey('case-talk-skip')), findsOneWidget);
      await tapKey(t, 'case-talk-skip');
      expect(find.text('"Find out with clues."'), findsOneWidget);
    });

    testWidgets('no portrait: nothing stands in for the person, and the talk goes on', (t) async {
      final bare = TalkScene(
        id: 'bare',
        speaker: const TalkSpeaker(id: 'x', name: 'NOBODY'),
        goal: 'A goal.',
        opening: const [TalkLine('Hi.')],
        questions: const [TalkQuestion(id: 'q', text: 'Why?', beat: [TalkLine('Because.')])],
        finishWhen: const {'q'},
      );
      await pumpTalk(t, talk: bare);
      expect(find.byType(Image), findsNothing);
      expect(find.byKey(const ValueKey('case-talk-portrait')), findsNothing);
      await tapKey(t, 'case-talk-q-q');
      expect(find.text('"Because."'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-finish')), findsOneWidget);
    });

    testWidgets('a portrait file that is not there yet leaves the space empty', (t) async {
      await pumpTalk(t);
      expect(find.byKey(const ValueKey('case-talk-portrait')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('the talk log reads back what was said', (t) async {
      final start = TalkProgress.start.skip(scene).ask(scene, 'who').skip(scene);
      await pumpTalk(t, start: start);
      await tapKey(t, 'case-talk-log');
      expect(find.byKey(const ValueKey('case-talk-log-sheet')), findsOneWidget);
      expect(find.text('Who are you?'), findsWidgets);
      expect(find.text('???: Find out with clues.'), findsOneWidget);
    });
  });

  testWidgets("the notebook sheet shows an earlier season's piece under its city, and gives what is taken", (t) async {
    final all = MockEpisodeRepository.bundled();
    final watch = earlierSeasonEvidence(
      ids: const ['ep12_e4'],
      allEpisodes: all,
      seasonId: SeasonIds.paris,
      solved: (_) => true,
      reference: false,
    );
    String? taken = 'none';
    await t.pumpWidget(
      ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => taken = await showEvidencePicker(context, ask: 'Which clue will you show?', earlier: watch),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Which clue will you show?'), findsOneWidget);
    expect(find.textContaining('LONDON · CASE 12'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('recall-pick-ep12_e4')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const ValueKey('recall-pick-ep12_e4')));
    await t.pumpAndSettle();
    expect(taken, 'ep12_e4');
  });
  // PART 1.5 (Seoul redesign): three or four cards to pick from, a "read it
  // again" line before any card is lit, and the mission's hints on the talk.
  group('cards to pick from, and hints', () {
    // The game's own fonts (the test font draws every letter a full square:
    // names would measure far wider than on a phone).
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

    final ev = [for (final e in MockEpisodeRepository.bundled().first.allEvidence) e.id];
    TalkScene cards(int n, {int litAfter = 2}) => TalkScene(
      id: 'test_cards',
      speaker: const TalkSpeaker(id: 'man', name: 'MR TEST', portraits: {}),
      goal: 'Show the right clue.',
      opening: const [TalkLine('Show me.')],
      presents: [
        TalkPresent(
          id: 'pick',
          prompt: 'Which clue proves it?',
          accepted: {ev[1]},
          beat: const [TalkLine('Yes, that one.')],
          choices: ev.take(n).toList(),
          tell: 'Read the clue about the door again.',
          litAfter: litAfter,
        ),
      ],
      finishWhen: const {'pick'},
    );

    Future<List<int>> pump(WidgetTester t, TalkScene scene, {Size size = const Size(320, 568), List<String> hints = const []}) async {
      t.view.physicalSize = size * t.view.devicePixelRatio;
      addTearDown(t.view.reset);
      final asked = <int>[];
      var shown = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: CaseTalk(
                  scene: scene,
                  progress: TalkProgress.start.skip(scene),
                  onProgress: (_) {},
                  onFinish: () {},
                  hints: hints,
                  hintsShown: shown,
                  onHint: hints.isEmpty ? null : () => setState(() => asked.add(++shown)),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      return asked;
    }

    BoxDecoration? glow(WidgetTester t, String id) => t
        .widget<AnimatedContainer>(find.descendant(of: find.byKey(ValueKey('case-talk-choice-$id')), matching: find.byType(AnimatedContainer)).first)
        .decoration as BoxDecoration?;
    bool lit(WidgetTester t, String id) => glow(t, id)!.border == null && glow(t, id)!.boxShadow!.first.blurRadius == 18;

    Future<void> choose(WidgetTester t, String id) async {
      await t.ensureVisible(find.byKey(ValueKey('case-talk-choice-$id')));
      await t.tap(find.byKey(ValueKey('case-talk-choice-$id')));
      await t.pump();
      await t.pump(const Duration(seconds: 3));
    }

    for (final n in [3, 4]) {
      testWidgets('$n cards fit a 320-wide phone: three in a row, four two to a row', (t) async {
        await pump(t, cards(n));
        for (final id in ev.take(n)) {
          expect(find.byKey(ValueKey('case-talk-choice-$id')), findsOneWidget);
        }
        final a = t.getTopLeft(find.byKey(ValueKey('case-talk-choice-${ev[0]}')));
        final b = t.getTopLeft(find.byKey(ValueKey('case-talk-choice-${ev[1]}')));
        final c = t.getTopLeft(find.byKey(ValueKey('case-talk-choice-${ev[2]}')));
        expect(a.dy, b.dy, reason: 'the first two side by side');
        if (n == 3) {
          expect(c.dy, a.dy, reason: 'three: one row');
        } else {
          expect(c.dy, greaterThan(a.dy), reason: 'four: the third on the next row');
        }
        final size = t.getSize(find.byKey(ValueKey('case-talk-choice-${ev[0]}')));
        expect(size.width, greaterThanOrEqualTo(n == 3 ? 80 : 120), reason: 'a finger-sized card');
        expect(size.height, greaterThanOrEqualTo(48));
        expect(t.takeException(), isNull, reason: 'nothing overflows');
      });
    }

    testWidgets("every Seoul talk's cards at 320 wide: each evidence name whole, nothing overflows", (t) async {
      final talks = [
        for (final e in MockEpisodeRepository.bundled().where((e) => e.id.startsWith('s5_')))
          for (final m in e.allMissions) ?(SeasonCatalog.caseTalk(m) ?? SeasonCatalog.talkMission(m)?.before),
      ];
      var sets = 0;
      for (final talk in talks) {
        for (final p in talk.presents.where((p) => p.choices.length > 1)) {
          sets++;
          final scene = TalkScene(
            id: 'seoul_${p.id}',
            speaker: const TalkSpeaker(id: 'man', name: 'MR TEST', portraits: {}),
            goal: 'Show the right clue.',
            opening: const [TalkLine('Show me.')],
            presents: [TalkPresent(id: p.id, prompt: p.prompt, accepted: p.accepted, beat: const [TalkLine('Yes.')], choices: p.choices)],
            finishWhen: {p.id},
          );
          await pump(t, scene);
          for (final id in p.choices) {
            final name = t.renderObject<RenderParagraph>(find.descendant(of: find.byKey(ValueKey('case-talk-choice-name-$id')), matching: find.byType(RichText)));
            expect(name.didExceedMaxLines, isFalse, reason: '${p.id} $id: its name is cut');
          }
          expect(t.takeException(), isNull, reason: p.id);
        }
      }
      expect(sets, greaterThanOrEqualTo(15), reason: 'every Seoul present with cards was laid out');
    });

    testWidgets('litAfter 3: the second miss says what to read again, no card lit; the third lights it', (t) async {
      await pump(t, cards(3, litAfter: 3));
      await choose(t, ev[0]);
      await choose(t, ev[2]);
      expect(find.text('Read the clue about the door again.'), findsOneWidget);
      expect(lit(t, ev[1]), isFalse, reason: 'not lit after two misses');
      await choose(t, ev[0]);
      expect(lit(t, ev[1]), isTrue, reason: 'the safety net, from the third');
      await choose(t, ev[1]);
      expect(find.text('"Yes, that one."'), findsOneWidget, reason: 'the right card still goes on');
    });

    testWidgets('the default (two cards, litAfter 2) lights the right card after the second miss, as before', (t) async {
      await pump(t, cards(2));
      await choose(t, ev[0]);
      expect(lit(t, ev[1]), isFalse);
      await choose(t, ev[0]);
      expect(lit(t, ev[1]), isTrue);
    });

    testWidgets("a talk with the mission's hints: the hint link opens them one by one", (t) async {
      final asked = await pump(t, cards(2), size: const Size(390, 844), hints: const ['Think about the door.', 'The key card.']);
      expect(find.byKey(const ValueKey('case-talk-hint')), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('case-talk-hint')));
      await t.tap(find.byKey(const ValueKey('case-talk-hint')));
      await t.pump(const Duration(seconds: 1));
      expect(asked, [1]);
      expect(find.textContaining('Think about the door.'), findsOneWidget);
    });

    testWidgets('no hints given: no hint link (every talk before)', (t) async {
      await pump(t, cards(2));
      expect(find.byKey(const ValueKey('case-talk-hint')), findsNothing);
    });
  });

  group('who speaks shows (2026-11-10)', () {
    test('the detective\'s face follows what they say', () {
      expect(detectiveFaceFor('I will. Good morning, Mr. Yun.'), DetectiveExpression.greeting);
      expect(detectiveFaceFor('Who are you?'), DetectiveExpression.asking);
      expect(detectiveFaceFor('Why?', presenting: true), DetectiveExpression.asking, reason: 'a question even while showing');
      expect(detectiveFaceFor('This paper was under his copy.', presenting: true), DetectiveExpression.showing);
      expect(detectiveFaceFor('I will find it, Your Majesty.'), DetectiveExpression.reassuring);
      expect(detectiveFaceFor('Then I will find that note.'), DetectiveExpression.reassuring);
      expect(detectiveFaceFor('And the flame is by your name!'), DetectiveExpression.surprised);
      expect(detectiveFaceFor('Let us look at every mark.'), DetectiveExpression.explaining);
    });

    test('every face of both detectives is in the app, its medallion inside the picture', () {
      for (final avatar in DetectiveAvatar.values) {
        for (final e in DetectiveExpression.values) {
          expect(File(ArtAssets.detective(avatar, e)).existsSync(), isTrue, reason: ArtAssets.detective(avatar, e));
          final c = ArtAssets.detectiveCrop(avatar, e);
          final box = Offset.zero & c.pixels;
          expect(box.contains(c.centre - Offset(c.radius, c.radius)) && box.contains(c.centre + Offset(c.radius - 1, c.radius - 1)), isTrue, reason: '$avatar $e');
        }
      }
    });

    test('every talk portrait has its copy without paper in its season\'s pack', () {
      final packed = {for (final m in seasonPackManifests.values) for (final f in m.files) f.path};
      for (final e in MockEpisodeRepository.bundled()) {
        for (final m in e.allMissions) {
          final talk = SeasonCatalog.talkMission(m);
          for (final s in [talk?.before, talk?.after, SeasonCatalog.caseTalk(m)]) {
            for (final p in s?.speaker.portraits.values ?? const <String>[]) {
              expect(packed, contains(ArtAssets.talkCutout(p)), reason: '${m.id}: $p');
            }
          }
        }
      }
    });

    // How big one of the two stands on the stage (1: two thirds, 0.5: one third).
    double stage(WidgetTester t, String who) =>
        t.widget<Transform>(find.byKey(ValueKey('case-talk-stage-$who'))).transform.entry(0, 0);

    testWidgets('the person\'s portrait for their lines, the player\'s detective for theirs', (t) async {
      final talk = TalkScene(
        id: 'who_speaks',
        speaker: const TalkSpeaker(id: 'man', name: 'MR TEST', portraits: {'base': 'missing/base.png'}),
        goal: 'Find out.',
        opening: const [TalkLine('Hello, detective.'), TalkLine.detective('Who are you?')],
        finishWhen: const {},
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(
            home: Scaffold(body: CaseTalk(scene: talk, progress: TalkProgress.start, onProgress: (_) {}, onFinish: () {})),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      expect(find.byKey(const ValueKey('case-talk-portrait-missing/base.png')), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-detective-asking')), findsNothing);
      expect(find.byKey(const ValueKey('case-talk-card')), findsOneWidget);
      expect(stage(t, 'person'), moreOrLessEquals(2 * stage(t, 'detective')), reason: 'the person speaks: two thirds');
      await t.tap(find.byKey(const ValueKey('case-talk-line')));
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(milliseconds: 300)); // the person's portrait fades out
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Who are you?'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-detective-asking')), findsOneWidget);
      // Both on the stage; the speaker has two thirds of it.
      expect(stage(t, 'detective'), moreOrLessEquals(2 * stage(t, 'person')), reason: 'the detective speaks: two thirds');
      expect(find.text('YOU'), findsOneWidget);
      expect(find.byKey(const ValueKey('case-talk-card-detective')), findsOneWidget, reason: 'the detective\'s words on their own card');
    });
  });
}
