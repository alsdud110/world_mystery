import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
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
import 'package:world_mystery/features/mission/widgets/evidence_recall.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/letter_card.dart';
import 'package:world_mystery/widgets/mission_words.dart';
import 'package:world_mystery/widgets/typewriter_text.dart';

import 'full_playthrough_test.dart' show hearTalk, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;
import 'reading_finders.dart';

/// Season 1 dialogue feedback, PART B (2026-11-03): Case 11's mask shows its
/// word on the mask; the taxi driver and the stranger talk to the detective
/// (the shared `CaseTalk`), the driver's words read again from the puzzle;
/// the stranger's card stays a card, Case 01's Old Letter brought beside it
/// at Rookie; the stranger's mask comes off with the solve (his face never
/// shown); Case 12's iron door opens with the solve. Answers never change.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);
  Mission at(String id, Difficulty level) {
    final e = DifficultyContent.episodeAt(byId(id.split('_').first), level);
    return e.allMissions.firstWhere((m) => m.id == id);
  }

  group('data', () {
    test('Case 11: the answers and the puzzle words stay as they were', () {
      for (final level in Difficulty.values) {
        expect(at('ep11_m2', level).answer, 'MIDNIGHT', reason: '$level');
        expect(at('ep11_m2', level).letter, 'THGINDIM', reason: '$level');
        expect(at('ep11_m3', level).answer, 'a', reason: '$level');
        expect(at('ep11_final', level).answer, 'd', reason: '$level');
        expect(at('ep11_final', level).options.firstWhere((o) => o.id == 'd').label, 'The Shadow');
        expect(at('ep12_final', level).answer, '487', reason: '$level');
      }
      expect('THGINDIM'.split('').reversed.join(), 'MIDNIGHT');
    });

    test('Case 11 M2: Rookie and Junior say "backwards" on the puzzle; Master leaves it to the story', () {
      expect(at('ep11_m2', Difficulty.rookie).question, contains('backwards'));
      expect(at('ep11_m2', Difficulty.junior).question, contains('backwards'));
      expect(at('ep11_m2', Difficulty.master).question, isNot(contains('backwards')));
      for (final level in Difficulty.values) {
        final m = at('ep11_m2', level);
        expect(m.story.join(' '), contains('backwards'), reason: '$level: the story says it at every level');
        expect(m.question, isNot(contains('MIDNIGHT')), reason: '$level: never the answer');
        // Solved: the notebook ties it to Case 10's warning.
        expect(m.clue!.note, contains("Raven's Warning"), reason: '$level');
        expect(m.clue!.note, contains('Case 10'), reason: '$level');
      }
      // The warning it points to says midnight.
      expect(byId('ep10').finalMission.evidence!.inscription, contains('MIDNIGHT'));
    });

    test("Case 11 M2's mask: the word is set by the game over the mask's blank brow", () {
      final m = ArtAssets.inscriptions['ep11_m2']!;
      expect(m.file, 'assets/seasons/season_01_london/objects/white_mask_inside.webp');
      expect(m.text.left, greaterThan(0));
      expect(m.text.right, lessThan(1));
      expect(missingAssets([m.file]), isEmpty);
      expect(ArtAssets.inscriptions.keys, {'ep11_m2'});
    });

    test("Case 11 M3: the taxi driver says the letter's own lines, at every level", () {
      for (final level in Difficulty.values) {
        final m = at('ep11_m3', level);
        final talk = SeasonCatalog.speech(m)!.talkOf(m, 'Luna').before!;
        expect(talk.speaker.name, 'TAXI DRIVER');
        expect(talk.opening.map((l) => l.text), [
          'He ran north, to a big station.',
          'It has two big arches and a clock tower.',
          'He kept saying: I love trains, I love trains!',
        ]);
        expect(talk.opening.every((l) => l.voice == TalkVoice.speaker), isTrue);
        expect(talk.finishWhen, isEmpty, reason: 'listened to, then the puzzle');
        expect(talk.speaker.portrait('base'), 'assets/seasons/season_01_london/characters/taxi_driver.webp');
      }
      expect(MissionWords.rereadLabel(at('ep11_m3', Difficulty.rookie)), 'Hear It Again');
      expect(MissionWords.rereadLabel(at('ep11_m2', Difficulty.rookie)), 'Look Again');
      expect(MissionWords.rereadLabel(at('ep11_m1', Difficulty.rookie)), 'Reread Letter');
    });

    test("Case 11 final: the stranger's greeting from the story, his name never said", () {
      final said = {
        Difficulty.rookie: ['Hello again, Detective Luna.', 'Do you remember me?'],
        Difficulty.junior: ['Hello again, Detective Luna.', 'Do you still remember me?'],
        Difficulty.master: ['We meet again, Detective Luna.', 'Do you remember me?'],
      };
      for (final level in Difficulty.values) {
        final m = at('ep11_final', level);
        final speech = SeasonCatalog.speech(m)!;
        expect(speech.fromStory, isTrue);
        final talk = speech.talkOf(m, 'Luna').before!;
        expect(talk.speaker.name, 'THE STRANGER');
        expect([for (final l in talk.opening) if (l.voice == TalkVoice.speaker) l.text], said[level], reason: '$level');
        expect(talk.opening.first.voice, TalkVoice.narrator);
        expect(talk.opening.last.text, m.letterIntro, reason: '$level: the card is handed over last');
        final words = [talk.goal, talk.speaker.name, talk.speaker.description, for (final l in talk.opening) l.text].join(' ');
        expect(words.toLowerCase(), isNot(contains('shadow')), reason: '$level: the answer is never said before it');
        // The card stays a paper: its words are untouched.
        expect(m.letter, contains('I left you a letter in a suitcase.'));
      }
    });

    test("Case 11 final: Case 01's Old Letter is the recall (shown at Rookie only)", () {
      final recall = byId('ep11').finalMission.recall!;
      expect(recall.evidenceId, 'e01');
      expect(byId('ep01').missions.first.evidence!.id, 'e01');
      for (final line in [recall.title, recall.prompt, recall.miss]) {
        expect(line!.toLowerCase(), isNot(contains('shadow')));
      }
    });

    test('Season 1 only: no other season has a speech', () {
      for (final s in SeasonCatalog.all) {
        if (s.id != season1Content.id) expect(s.speeches, isEmpty, reason: s.id);
      }
      // PART B's two, and PART C's ten (2026-11-03: every Season 1 person who
      // talks to the detective; see s1_dialogue_part_c_test).
      expect(season1Content.speeches.keys, {
        'ep11_m3', 'ep11_final',
        'ep02_final', 'ep03_m3', 'ep07_final', 'ep08_final', 'ep09_m1', 'ep09_m2', 'ep10_m1', 'ep10_final', 'ep12_m1', 'ep12_m2',
      });
      // Every picture a talk shows is in the bundle (its place, its faces).
      expect(
        missingAssets([
          for (final sp in season1Content.speeches.values) ...[?sp.background, ...sp.speaker.portraits.values],
        ]),
        isEmpty,
      );
    });

    test('a quoted story line becomes the lines said; a plain one, the narrator', () {
      final lines = MissionSpeech.storyLines('"Hello again, Detective Luna," he says. "Do you remember me?"');
      expect(lines.map((l) => l.text), ['Hello again, Detective Luna.', 'Do you remember me?']);
      expect(MissionSpeech.storyLines('The stranger smiles and bows.').single.voice, TalkVoice.narrator);
      expect(MissionSpeech.spokenLines('"One.\n\nTwo."'), ['One.', 'Two.']);
    });

    test("the new pictures: the stranger's two, the open door, the driver, the mask", () {
      expect(ArtAssets.scene(Artwork.maskedStranger), endsWith('characters/stranger_masked.webp'));
      expect(ArtAssets.scene(Artwork.maskedStranger, solved: 1), endsWith('characters/stranger_unmasked.webp'));
      expect(ArtAssets.scene(Artwork.ironDoor), endsWith('objects/small_iron_door.webp'));
      expect(ArtAssets.scene(Artwork.ironDoor, solved: 1), endsWith('objects/small_iron_door_open.webp'));
      expect(ArtAssets.sceneLabel(Artwork.maskedStranger, solved: 1)!.toLowerCase(), isNot(contains('shadow')));
      expect(ArtAssets.sceneLabel(Artwork.ironDoor, solved: 1), contains('open'));
      expect(
        missingAssets([
          ...ArtAssets.solvedScenes.values,
          ArtAssets.scene(Artwork.maskedStranger)!,
          'assets/seasons/season_01_london/characters/taxi_driver.webp',
        ]),
        isEmpty,
      );
    });
  });

  group('screens', () {
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

    /// The app on [e] at [level] (earlier cases solved), [done] its missions
    /// done, opened at [route].
    Future<void> open(
      WidgetTester t,
      Episode e,
      String route, {
      required List<String> done,
      Difficulty level = Difficulty.rookie,
      bool solved = false,
      String? opened,
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
          AppConstants.progressKeyFor(e.id): progress(done, solved: solved, opened: opened, examined: examined),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(
              activeEpisodeId: e.id,
              solvedEpisodeIds: [for (final x in earlier) x.id, if (solved) e.id],
              difficulty: level,
            ).toJson(),
          ),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: WorldMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      app = ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first);
      app.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 1500));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    /// Every picture on screen decoded (a capture shows them, not blanks).
    Future<void> decodePictures(WidgetTester t) async {
      for (final e in find.byType(Image).evaluate()) {
        await t.runAsync(() => precacheImage((e.widget as Image).image, e));
      }
      await t.pump();
    }

    Set<String> shownAssets(WidgetTester t) {
      String? nameOf(ImageProvider p) => switch (p) {
            AssetImage(:final assetName) => assetName,
            ResizeImage(:final imageProvider) => nameOf(imageProvider),
            _ => null,
          };
      return {for (final w in t.widgetList<Image>(find.byType(Image))) ?nameOf(w.image)};
    }

    Future<void> tapText(WidgetTester t, String text, [Duration after = const Duration(milliseconds: 1500)]) async {
      await t.ensureVisible(findText(text).last);
      await t.tap(findText(text).last);
      await wait(t, after);
    }

    Finder key(String k) => find.byKey(ValueKey(k));
    Iterable<String> talkSaid(WidgetTester t) => t.widgetList<TypewriterText>(find.byType(TypewriterText)).map((w) => w.text);
    List<String> m11(String suffix) => [for (final m in byId('ep11').missions.takeWhile((m) => m.id != 'ep11_$suffix')) m.id];

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag Case 11 M2: the word on the mask itself, read out letter by letter', (t) async {
        final semantics = t.ensureSemantics();
        await open(t, byId('ep11'), Routes.mission('ep11_m2'), done: m11('m2'), size: size);
        await tapText(t, 'INVESTIGATE');
        expect(find.byType(EnvelopeReveal), findsNothing, reason: 'no letter: the mask');
        expect(find.byType(InscribedObject), findsOneWidget);
        expect(find.descendant(of: key('inscribed-words'), matching: find.text('THGINDIM')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'white mask\. Written on it: T H G I N D I M$')), findsOneWidget);
        expect(shownAssets(t), contains('assets/seasons/season_01_london/objects/white_mask_inside.webp'));
        // The words sit on the mask, inside the screen.
        final words = t.getRect(key('inscribed-words'));
        final mask = t.getRect(find.byType(InscribedObject));
        expect(words.left, greaterThanOrEqualTo(mask.left));
        expect(words.right, lessThanOrEqualTo(mask.right));
        expect(mask.right, lessThanOrEqualTo(size.width));
        await decodePictures(t);
        await capture(t, 's1b_ep11_m2_mask_$tag');
        await tapText(t, 'SOLVE THE PUZZLE');
        expect(findReadable(at('ep11_m2', Difficulty.rookie).question), findsOneWidget);
        // The mask, looked at again from the puzzle.
        await tapText(t, 'Look Again');
        expect(find.byType(InscribedObject), findsOneWidget);
        await decodePictures(t);
        await capture(t, 's1b_ep11_m2_look_again_$tag');
        expect(t.takeException(), isNull);
        semantics.dispose();
      });

      testWidgets('$tag Case 11 M3: the taxi driver talks, then the puzzle; his words heard again', (t) async {
        await open(t, byId('ep11'), Routes.mission('ep11_m3'), done: m11('m3'), size: size);
        await tapText(t, 'INVESTIGATE');
        expect(key('case-talk-line'), findsOneWidget);
        expect(find.descendant(of: key('case-talk-line'), matching: find.text('TAXI DRIVER')), findsOneWidget);
        expect(shownAssets(t), contains('assets/seasons/season_01_london/characters/taxi_driver.webp'));
        await decodePictures(t);
        await capture(t, 's1b_ep11_m3_talk_$tag');
        // Left in the middle, the talk is kept where it was.
        await wait(t, const Duration(seconds: 3));
        await t.tap(key('case-talk-next'));
        await wait(t, const Duration(seconds: 3));
        expect(app.read(gameControllerProvider).puzzleStateOf(TalkMission.beforeKey('ep11_m3')), isNotNull);
        await hearTalk(t);
        expect(app.read(gameControllerProvider).hasExamined(TalkMission.beforeKey('ep11_m3')), isTrue);
        // Straight to the puzzle: the driver's words are not a letter again.
        expect(find.text('TAP TO OPEN'), findsNothing);
        expect(find.byType(EnvelopeReveal), findsNothing);
        expect(find.text('CHECK ANSWER'), findsOneWidget);
        await tapText(t, 'Hear It Again');
        expect(find.byType(SpokenWordsCard), findsOneWidget);
        expect(find.byType(LetterCard), findsNothing);
        expect(findReadableContaining('two big arches and a clock tower'), findsOneWidget);
        await decodePictures(t);
        await capture(t, 's1b_ep11_m3_hear_again_$tag');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('Case 11 M3, the talk heard before (a restart): INVESTIGATE goes to the puzzle', (t) async {
      await open(t, byId('ep11'), Routes.mission('ep11_m3'), done: m11('m3'), examined: [TalkMission.beforeKey('ep11_m3')]);
      await tapText(t, 'INVESTIGATE');
      expect(key('case-talk-line'), findsNothing);
      expect(find.text('CHECK ANSWER'), findsOneWidget);
    });

    testWidgets('Case 11 M3 solved in an old save: its words in the talk card, not a letter', (t) async {
      await open(t, byId('ep11'), Routes.mission('ep11_m3'), done: [...m11('m3'), 'ep11_m3']);
      expect(key('case-talk-line'), findsNothing, reason: 'a solved mission never plays its talk');
      expect(find.byType(SpokenWordsCard), findsOneWidget);
      expect(find.byType(LetterCard), findsNothing);
    });

    for (final level in Difficulty.values) {
      testWidgets('Case 11 final at ${level.name}: the stranger talks, then his card; the Old Letter at Rookie only',
          (t) async {
        final e = byId('ep11');
        await open(t, e, Routes.finalMission, done: [for (final m in e.missions) m.id], level: level);
        expect(key('case-talk-line'), findsOneWidget);
        expect(shownAssets(t), contains('assets/seasons/season_01_london/characters/stranger_masked.webp'));
        // The narrator first (he bows), then he speaks: his plate never names him.
        await wait(t, const Duration(seconds: 3));
        await t.tap(key('case-talk-next'));
        await wait(t, const Duration(seconds: 3));
        expect(find.descendant(of: key('case-talk-line'), matching: find.text('THE STRANGER')), findsOneWidget);
        await decodePictures(t);
        await capture(t, 's1b_ep11_final_talk_${level.name}');
        for (var i = 0; i < 6 && key('case-talk-next').evaluate().isNotEmpty; i++) {
          expect(talkSaid(t).join(' ').toLowerCase(), isNot(contains('shadow')));
          await t.tap(key('case-talk-next'));
          await wait(t, const Duration(seconds: 3));
        }
        expect(talkSaid(t).join(' ').toLowerCase(), isNot(contains('shadow')));
        await hearTalk(t);
        expect(key('case-talk-line'), findsNothing);
        // The card is a card; the greeting is not told again.
        final m = at('ep11_final', level);
        expect(find.byType(LetterCard), findsOneWidget);
        expect(findReadable(m.letterIntro), findsOneWidget);
        expect(findReadable(m.story.last), findsNothing);
        expect(shownAssets(t), contains('assets/seasons/season_01_london/characters/stranger_masked.webp'));
        expect(shownAssets(t), isNot(contains('assets/seasons/season_01_london/characters/stranger_unmasked.webp')));
        // Case 01's Old Letter is brought beside the card at every level
        // (device feedback 2026-11-03; it was Rookie's only).
        expect(find.byType(EvidenceRecallDock), findsOneWidget);
        await decodePictures(t);
        await capture(t, 's1b_ep11_final_card_${level.name}');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('Case 11 final solved (a revisit): the mask in his hand, no talk again', (t) async {
      final e = byId('ep11');
      await open(t, e, Routes.finalMission, done: [for (final m in e.allMissions) m.id], solved: true);
      expect(key('case-talk-line'), findsNothing);
      final shown = shownAssets(t);
      expect(shown, contains('assets/seasons/season_01_london/characters/stranger_unmasked.webp'));
      expect(shown, isNot(contains('assets/seasons/season_01_london/characters/stranger_masked.webp')));
      await decodePictures(t);
      await capture(t, 's1b_ep11_final_solved');
    });

    testWidgets('Case 12 final: the iron door shut before the answer', (t) async {
      final e = byId('ep12');
      await open(t, e, Routes.finalMission, done: [for (final m in e.missions) m.id]);
      final shown = shownAssets(t);
      expect(shown, contains('assets/seasons/season_01_london/objects/small_iron_door.webp'));
      expect(shown, isNot(contains('assets/seasons/season_01_london/objects/small_iron_door_open.webp')));
      await decodePictures(t);
      await capture(t, 's1b_ep12_final_before');
    });

    testWidgets('Case 12 final solved (a revisit after a restart): the iron door open', (t) async {
      final e = byId('ep12');
      await open(t, e, Routes.finalMission, done: [for (final m in e.allMissions) m.id], solved: true);
      final shown = shownAssets(t);
      expect(shown, contains('assets/seasons/season_01_london/objects/small_iron_door_open.webp'));
      expect(shown, isNot(contains('assets/seasons/season_01_london/objects/small_iron_door.webp')));
      expect(find.bySemanticsLabel(RegExp('The small iron door stands open')), findsWidgets);
      await decodePictures(t);
      await capture(t, 's1b_ep12_final_after');
    });
  });
}
