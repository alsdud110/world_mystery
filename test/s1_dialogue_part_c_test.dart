import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season1/season1_speeches.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/mission_speech.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/widgets/letter_card.dart';
import 'package:world_mystery/widgets/mission_words.dart';

import 'full_playthrough_test.dart' show hearTalk, wait;
import 'helpers.dart';

/// Season 1 dialogue feedback, PART C (2026-11-03): every Season 1 person
/// who talks to the detective is heard on the shared `CaseTalk` (their
/// portrait, their name plate), never read as a letter: Mrs Bell, the
/// cleaner, Inspector Grey, Mrs Robin, the head butler, Guard Carl and the
/// Ravenmaster. Case 12 M2: Grey's words are said; the arrivals board stays
/// a paper. Answers, hints and saves never change.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);
  Mission at(String id, Difficulty level) {
    final e = DifficultyContent.episodeAt(byId(id.split('_').first), level);
    return e.allMissions.firstWhere((m) => m.id == id);
  }

  const london = 'assets/seasons/season_01_london/characters';
  // Mission → (name plate, portrait, answer at every level).
  const scenes = {
    'ep02_final': ('MRS BELL', '$london/mrs_bell.webp', '917'),
    'ep03_m3': ('CLEANER', '$london/cleaner.webp', 'shop,stairs,cafe,door'),
    'ep07_final': ('INSPECTOR GREY', '$london/inspector_grey.webp', 'b'),
    'ep08_final': ('MRS ROBIN', '$london/mrs_robin.webp', 'c'),
    'ep09_m1': ('HEAD BUTLER', '$london/head_butler.webp', 'c'),
    'ep09_m2': ('GUARD CARL', '$london/guard_carl.webp', 'ANNA'),
    'ep10_m1': ('RAVENMASTER', '$london/ravenmaster.webp', 'c'),
    'ep10_final': ('RAVENMASTER', '$london/ravenmaster.webp', 'clockmaker,stop,bigben,midnight'),
    'ep12_m1': ('MRS BELL', '$london/mrs_bell.webp', 'd'),
  };
  // What each answer is in words: never on a name plate, a goal or a
  // portrait's description before it is found.
  const spoilers = {
    'ep02_final': ['9:17', '917', 'nine'],
    'ep03_m3': ['shop', 'stairs'],
    'ep07_final': ['gate'],
    'ep08_final': ['button', 'gallery', 'miss rose'],
    'ep09_m1': ["guard's key", 'gold'],
    'ep09_m2': ['anna'],
    'ep10_m1': ['poppy', 'gold ring', 'smallest'],
    'ep10_final': ['clockmaker', 'midnight'],
    'ep12_m1': ['brass', 'eight', 'stamp'],
    'ep12_m2': ['11:40', '1140', 'platform 4', 'paris'],
  };

  group('data', () {
    test('the nine scenes: their person, their portrait, the letter said line by line, at every level', () {
      for (final MapEntry(key: id, value: (name, portrait, answer)) in scenes.entries) {
        for (final level in Difficulty.values) {
          final m = at(id, level);
          final speech = SeasonCatalog.speech(m)!;
          expect(speech.saysLetter, isTrue, reason: '$id: the letter is what is said');
          final talk = speech.talkOf(m, 'Luna').before!;
          expect(talk.speaker.name, name, reason: id);
          expect(talk.speaker.portrait('base'), portrait, reason: id);
          expect(talk.finishWhen, isEmpty, reason: '$id: listened to, then the puzzle');
          // The level's own words, said: nothing written twice.
          final said = [for (final l in talk.opening) if (l.voice == TalkVoice.speaker) l.text];
          final letterLines = MissionSpeech.spokenLines(m.letter.replaceAll('{detectiveName}', 'Luna'));
          expect(said.sublist(said.length - letterLines.length), letterLines, reason: '$id at $level');
          // A final has no story page: its story opens the talk.
          if (m.finale) {
            expect(talk.opening.first.text, isNot(letterLines.first), reason: '$id: the story first');
          } else {
            expect(said, letterLines, reason: '$id: the story is its own page');
          }
          expect(m.answer, answer, reason: '$id at $level: the answer never moves');
          expect(MissionWords.rereadLabel(m), 'Hear It Again', reason: id);
        }
      }
    });

    test('no name plate, goal or portrait says an answer before it is found', () {
      for (final MapEntry(key: id, value: words) in spoilers.entries) {
        for (final level in Difficulty.values) {
          final talk = SeasonCatalog.speech(at(id, level))!.talkOf(at(id, level), 'Luna').before!;
          final shown = [talk.goal, talk.speaker.name, talk.speaker.description].join(' ').toLowerCase();
          for (final w in words) {
            expect(shown, isNot(contains(w)), reason: '$id at $level: "$w"');
          }
        }
      }
    });

    test('one person, one look: the same portrait wherever they talk', () {
      final byName = <String, Set<String>>{};
      for (final sp in season1Speeches.values) {
        byName.putIfAbsent(sp.speaker.name, () => {}).addAll(sp.speaker.portraits.values);
      }
      for (final MapEntry(key: name, value: files) in byName.entries) {
        expect(files, hasLength(1), reason: name);
      }
      expect(byName['MRS BELL'], {'$london/mrs_bell.webp'});
      expect(byName['INSPECTOR GREY'], {'$london/inspector_grey.webp'});
      expect(byName['RAVENMASTER'], {'$london/ravenmaster.webp'}, reason: 'the man, not raven_master.webp (a raven)');
    });

    test('Case 12 M2: Grey says his line; the board stays a paper, each shown once, at every level', () {
      for (final level in Difficulty.values) {
        final m = at('ep12_m2', level);
        final speech = SeasonCatalog.speech(m)!;
        expect(speech.inLetter, isTrue);
        expect(speech.saysLetter, isFalse, reason: 'the board is still read');
        final talk = speech.talkOf(m, 'Luna').before!;
        expect(talk.speaker.name, 'INSPECTOR GREY');
        expect(talk.opening.map((l) => l.text),
            ['The Clockmaker always arrives on the platform with the small red clock, after the train from Edinburgh.']);
        final paper = speech.paperOf(m);
        expect(paper, startsWith('ARRIVALS'));
        for (final train in ['10:15  from York — Platform 4', '11:04  from Edinburgh — Platform 9', '11:40  from Paris — Platform 4', '11:55  from Oxford — Platform 7']) {
          expect(paper, contains(train), reason: '$level: every train on the board');
        }
        expect(paper, isNot(contains('Grey')), reason: '$level: his words are not written again');
        expect(paper, isNot(contains('small red clock')));
        expect(MissionWords.paperOf(m), paper);
        expect(MissionWords.rereadLabel(m), 'Reread Letter');
        // The mission's own words are untouched (the cross-case tests read them).
        expect(m.letter, contains('Inspector Grey: "The Clockmaker always arrives'));
        expect(m.answer, '1140');
      }
    });

    test('papers stay papers: the missions kept as letters have no talk', () {
      for (final id in [
        'ep03_m1', 'ep03_m2', 'ep03_final', 'ep05_m1', 'ep05_m3', 'ep06_m3', 'ep08_m2', 'ep10_m3', 'ep11_m1', 'ep12_m3',
      ]) {
        expect(season1Speeches.containsKey(id), isFalse, reason: id);
        expect(MissionWords.rereadLabel(at(id, Difficulty.rookie)), isNot('Hear It Again'), reason: id);
      }
    });

    test('every picture a talk shows is in the bundle', () {
      expect(
        missingAssets([
          for (final sp in season1Speeches.values) ...[?sp.background, ...sp.speaker.portraits.values],
        ]),
        isEmpty,
      );
      expect(season1Speeches.values.every((sp) => sp.background != null), isTrue, reason: 'each over its place');
    });
  });

  testWidgets('the seven new portraits decode, 1024×1536', (t) async {
    for (final file in {for (final (_, p, _) in scenes.values) p, '$london/inspector_grey.webp'}) {
      final size = await t.runAsync(() async {
        final bytes = await rootBundle.load(file);
        final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      });
      expect(size, const Size(1024, 1536), reason: file);
    }
  });

  group('screens', () {
    String progress(List<String> done, {bool solved = false, String? opened, List<String> examined = const []}) =>
        jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          examined: examined,
          missionStartedAt: opened == null ? const {} : {opened: DateTime(2026, 11, 3, 10)},
          startedAt: DateTime(2026, 11, 3, 10),
          completedAt: solved ? DateTime(2026, 11, 3, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    late ProviderContainer app;

    Future<void> open(
      WidgetTester t,
      Episode e,
      String route, {
      required List<String> done,
      Difficulty level = Difficulty.rookie,
      bool solved = false,
      List<String> examined = const [],
      Size size = const Size(360, 640),
    }) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final earlier = [for (final x in season) if (x.seasonId == e.seasonId && x.number < e.number) x];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
          AppConstants.progressKeyFor(e.id): progress(done, solved: solved, examined: examined),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(
              activeEpisodeId: e.id,
              solvedEpisodeIds: [for (final x in earlier) x.id, if (solved) e.id],
              difficulty: level,
            ).toJson(),
          ),
        }),
        child: const WorldMysteryApp(),
      ));
      await wait(t, const Duration(milliseconds: 300));
      app = ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first);
      app.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 1500));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    Future<void> tapText(WidgetTester t, String text) async {
      await t.ensureVisible(find.text(text).last);
      await t.tap(find.text(text).last);
      await wait(t, const Duration(milliseconds: 1500));
    }

    Finder key(String k) => find.byKey(ValueKey(k));
    List<String> before(String id) {
      final e = byId(id.split('_').first);
      return [for (final m in e.missions.takeWhile((m) => m.id != id)) m.id];
    }

    Set<String> shownAssets(WidgetTester t) {
      String? nameOf(ImageProvider p) => switch (p) {
            AssetImage(:final assetName) => assetName,
            ResizeImage(:final imageProvider) => nameOf(imageProvider),
            _ => null,
          };
      return {for (final w in t.widgetList<Image>(find.byType(Image))) ?nameOf(w.image)};
    }

    for (final id in ['ep03_m3', 'ep09_m1', 'ep09_m2', 'ep10_m1', 'ep12_m1']) {
      testWidgets('$id: the person talks, then the puzzle; their words heard again', (t) async {
        final (name, portrait, _) = scenes[id]!;
        await open(t, byId(id.split('_').first), Routes.mission(id), done: before(id));
        await tapText(t, 'INVESTIGATE');
        expect(key('case-talk-line'), findsOneWidget);
        expect(find.descendant(of: key('case-talk-line'), matching: find.text(name)), findsOneWidget);
        expect(shownAssets(t), contains(portrait));
        await hearTalk(t);
        expect(app.read(gameControllerProvider).hasExamined(TalkMission.beforeKey(id)), isTrue);
        // Straight to the puzzle: the words are not a letter again.
        expect(find.text('TAP TO OPEN'), findsNothing);
        expect(find.byType(EnvelopeReveal), findsNothing);
        expect(findReadable(at(id, Difficulty.rookie).question), findsOneWidget);
        await tapText(t, 'Hear It Again');
        expect(find.byType(SpokenWordsCard), findsOneWidget);
        expect(find.byType(LetterCard), findsNothing);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('a talk heard before (a restart): INVESTIGATE goes to the puzzle', (t) async {
      await open(t, byId('ep09'), Routes.mission('ep09_m2'), done: before('ep09_m2'), examined: [TalkMission.beforeKey('ep09_m2')]);
      await tapText(t, 'INVESTIGATE');
      expect(key('case-talk-line'), findsNothing);
      expect(find.text('CHECK ANSWER'), findsOneWidget);
    });

    testWidgets('a mission solved in an old save: its words in the talk card, no talk, no letter', (t) async {
      await open(t, byId('ep10'), Routes.mission('ep10_m1'), done: [...before('ep10_m1'), 'ep10_m1']);
      expect(key('case-talk-line'), findsNothing);
      expect(find.byType(SpokenWordsCard), findsOneWidget);
      expect(find.byType(LetterCard), findsNothing);
    });

    testWidgets('Case 12 M2: Grey talks, then the board (without his words); both read again, once', (t) async {
      await open(t, byId('ep12'), Routes.mission('ep12_m2'), done: before('ep12_m2'));
      await tapText(t, 'INVESTIGATE');
      expect(find.descendant(of: key('case-talk-line'), matching: find.text('INSPECTOR GREY')), findsOneWidget);
      expect(shownAssets(t), contains('$london/inspector_grey.webp'));
      await hearTalk(t);
      // The board is a paper, read as always.
      await tapText(t, 'TAP TO OPEN');
      expect(findReadableContaining('11:40  from Paris'), findsOneWidget);
      expect(findReadableContaining('small red clock'), findsNothing, reason: 'said, not written again');
      await tapText(t, 'SOLVE THE PUZZLE');
      await tapText(t, 'Reread Letter');
      expect(find.byType(SpokenWordsCard), findsOneWidget);
      expect(find.byType(LetterCard), findsOneWidget);
      expect(findReadableContaining('small red clock'), findsOneWidget);
      expect(findReadableContaining('11:40  from Paris'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    for (final id in ['ep02_final', 'ep07_final', 'ep08_final', 'ep10_final']) {
      for (final level in Difficulty.values) {
        testWidgets('$id at ${level.name}: the talk, then the puzzle with the words in their card', (t) async {
          final (name, portrait, answer) = scenes[id]!;
          final e = byId(id.split('_').first);
          await open(t, e, Routes.finalMission, done: [for (final m in e.missions) m.id], level: level);
          expect(key('case-talk-line'), findsOneWidget);
          // The story first (the narrator), then the person: their plate.
          for (var i = 0; i < 4 && find.descendant(of: key('case-talk-line'), matching: find.text(name)).evaluate().isEmpty; i++) {
            await wait(t, const Duration(seconds: 3));
            await t.tap(key('case-talk-next'));
            await wait(t, const Duration(seconds: 2));
          }
          expect(find.descendant(of: key('case-talk-line'), matching: find.text(name)), findsOneWidget);
          expect(shownAssets(t), contains(portrait));
          await hearTalk(t);
          expect(key('case-talk-line'), findsNothing);
          expect(app.read(gameControllerProvider).hasExamined(TalkMission.beforeKey(id)), isTrue);
          // Their words in their card, not a letter; the story not told again.
          final m = at(id, level);
          expect(find.byType(SpokenWordsCard), findsOneWidget);
          expect(find.byType(LetterCard), findsNothing);
          expect(findReadable(m.story.first), findsNothing);
          // Heard again from the puzzle.
          await tapText(t, 'Hear It Again');
          expect(find.byType(SpokenWordsCard), findsNWidgets(2));
          expect(find.byType(LetterCard), findsNothing);
          await tapText(t, 'BACK TO THE LOCKS');
          // The puzzle still answers: wrong first, then right.
          final c = app.read(gameControllerProvider.notifier);
          expect(c.submitAnswer(m, answer == 'b' ? 'a' : 'b').result, SubmitResult.tryAgain);
          expect(c.submitAnswer(m, answer).result, SubmitResult.correct);
          await wait(t, const Duration(seconds: 2));
          expect(key('case-talk-line'), findsNothing);
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('Case 08 final: the evidence chosen on the page solves it, after the talk', (t) async {
      final e = byId('ep08');
      await open(t, e, Routes.finalMission, done: [for (final m in e.missions) m.id]);
      await hearTalk(t);
      await tapText(t, 'Red Button');
      await tapText(t, 'CHECK ANSWER');
      expect(app.read(gameControllerProvider).isCompleted('ep08_final'), isTrue);
    });

    testWidgets('a final solved (a revisit): no talk again', (t) async {
      final e = byId('ep02');
      await open(t, e, Routes.finalMission, done: [for (final m in e.allMissions) m.id], solved: true);
      expect(key('case-talk-line'), findsNothing);
    });
  });
}
