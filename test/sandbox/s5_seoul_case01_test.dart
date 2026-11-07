import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/mock/season1/season1_deductions.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/mission/widgets/scene_deduction.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart' show findReadableContaining;
import '../mission_play.dart';
import 'single_case.dart';

/// Seoul Case 01, the four groups of Hunminjeongeum (docs/SEOUL_CASE01_REDESIGN_PLAN.md):
/// the groups found as 훈, 음, 정, 민 and built by their meanings. Stage A is
/// the King's talk before the final's puzzle (`talkMissions`), Stage B the
/// name's tiles on the final's page.
void main() {
  final season = season5Content;
  const fin = 's5_ep01_final', e1 = 's5_ep01_e1', e2 = 's5_ep01_e2', e3 = 's5_ep01_e3';
  const tiles = {'TEACH', 'LEARN', 'RIGHT', 'SOUND', 'GATE', '민', '문', '만', '빈'};

  Episode episode(String id, Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes[id]!, 'seasonId': season.id}),
    level,
    patches: season.casePatches,
  );
  TalkScene talk(Difficulty level) => (level == Difficulty.rookie ? season.talkMissions : season.variants[level]!.talkMissions)[fin]!.before!;

  group('the same case at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode('s5_ep01', level);
      final m = ep.finalMission;

      test('${level.label}: the answers, the nine tiles, two hints each', () {
        expect([for (final x in ep.allMissions) x.answer], ['c', 'ieung,eu,mieum', '정음', 'teach,min,right,sound']);
        expect(m.options.map((o) => o.label).toSet(), tiles);
        expect(m.codeLength, 4);
        for (final x in ep.allMissions) {
          expect(x.hints, hasLength(2), reason: x.id);
        }
      });

      test('${level.label}: the name is never given before it is built', () {
        final before = [
          for (final x in ep.missions) ...[x.letter, x.question, ...x.hints, ...x.story, ...x.transition, ?x.clue?.value, ?x.clue?.note],
          m.letter, m.question, ...m.hints, ...m.story, ...m.feedback.values, ?m.orderFeedback,
          for (final l in talk(level).opening) l.text,
          for (final p in talk(level).presents) ...[p.prompt, ...p.beat.map((l) => l.text), p.miss.text, ?p.tell],
        ].join('\n');
        expect(before.contains('훈민정음'), isFalse);
        expect(before.contains('Hunminjeongeum'), isFalse);
        expect(m.transition.join(' '), contains('훈민정음'), reason: 'said once it is built');
        expect(m.transition.join(' '), contains('The right sounds, to teach the people'));
      });

      test('${level.label}: M1 never says what 훈 means: Sora teaches, the player joins the two', () {
        final m1 = ep.missions[0];
        final said = [m1.letter, m1.question, ...m1.hints, ...m1.story, ...m1.transition, m1.clue!.note, m1.evidence!.description].join('\n');
        expect(RegExp(r'\bmeans?\b', caseSensitive: false).hasMatch(said), isFalse, reason: said);
        expect(said.contains('TEACH'), isFalse);
        expect(said, contains('what Sora does for her'));
        expect(m1.transition.join(' '), contains('teach'), reason: 'what Sora does, in the words of the story');
      });

      test('${level.label}: every wrong tile is answered, none gives a tile away', () {
        for (final wrong in ['learn,min,right,sound', 'gate,min,right,sound', 'teach,mun,right,sound', 'teach,man,right,sound', 'teach,bin,right,sound']) {
          expect(AnswerChecker.isCorrect(m, wrong), isFalse, reason: wrong);
          final line = AnswerChecker.feedbackFor(m, wrong);
          expect(line, isNotNull, reason: wrong);
          expect(line!.contains('TEACH') || line.contains('teach'), isFalse, reason: line);
        }
        expect(AnswerChecker.feedbackFor(m, 'min,teach,right,sound'), m.orderFeedback, reason: 'the right tiles out of order');
        expect(AnswerChecker.isCorrect(m, 'teach,min,right,sound'), isTrue);
      });

      test('${level.label}: nothing of the old note is left in the case', () {
        final said = File('content_pipeline/seasons/s5_seoul/cases/s5_ep01/levels.json').readAsStringSync();
        for (final w in ['서고', '지붕', 'roof', 'first column']) {
          expect(said.contains(w), isFalse, reason: w);
        }
      });

      test('${level.label}: the talk: e1 asked for twice, in turn', () {
        final t = talk(level);
        expect(t.presents.map((p) => p.id), ['who', 'how', 'people']);
        expect(t.finishWhen, {'who', 'how', 'people'});
        expect(t.finishLabel, 'CONTINUE', reason: 'one label at every level');
        expect(t.present('how')!.requires, {'who'});
        expect(t.present('people')!.requires, {'how'});
        var p = TalkProgress.start;
        expect(p.presents(t).map((x) => x.id), ['who'], reason: 'one question open at a time');
        (p, _) = p.show(t, e1);
        expect(p.done, ['who']);
        final (missed, fits) = p.show(t, e1);
        expect([fits, missed.done], [false, ['who']], reason: 'e1 does not answer how she learned');
        (p, _) = p.show(t, e2);
        (p, _) = p.show(t, e1);
        expect(p.done, ['who', 'how', 'people'], reason: 'e1 again, for the third question');
        expect(p.finished(t), isTrue);
      });
    }

    test('J and M say the talk in their own words; its steps are the same', () {
      final r = talk(Difficulty.rookie);
      expect(talk(Difficulty.master).present('people')!.beat.first.text, isNot(r.present('people')!.beat.first.text));
      expect(talk(Difficulty.junior).present('people')!.beat.first.text, isNot(r.present('people')!.beat.first.text));
    });
  });

  group('what later cases read of it', () {
    for (final level in Difficulty.values) {
      test('${level.label}: Cases 08 and 12 name the note as it now is', () {
        final c8 = SeasonCatalog.caseEnding(episode('s5_ep08', level).finalMission)!.map((l) => l.text).join(' ');
        expect(c8, contains('훈민정음'));
        expect(c8.contains('서고'), isFalse);
        final card = season.timelines['s5_ep12_m2'];
        expect(card, isNotNull);
      });
    }

    test('the ids later cases name are kept, Sora\'s board word for word', () {
      final ep = episode('s5_ep01', Difficulty.rookie);
      expect([for (final m in ep.missions) m.evidence!.id], [e1, e2, e3]);
      expect(ep.missions[1].evidence!.name, "Sora's Lesson Board");
      expect(ep.missions[1].evidence!.description, 'The first letters copy the tongue, the mouth, the teeth and the throat. A stronger sound adds a line.');
      expect(ep.missions[2].evidence!.name, "Bun-i's Note");
      expect(ep.missions[0].clue!.note, contains('Bun-i carries water'));
    });

    test('Case 12\'s card names the name of the letters, not a roof', () {
      final card = season.timelines['s5_ep12_m2']!.card('bun_i')!;
      expect(card.text, contains('name of the letters'));
    });
  });

  for (final level in Difficulty.values) {
    testWidgets('${level.label}, 320×568: the talk, back to the map, the app reopened, then the tiles', (t) async {
      const size = Size(320, 568);
      final one = SingleCase(season, 's5_ep01', level: level)..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await one.open(t, prefs, fresh: true, size: size);
      final p = CasePlayer(t, season);
      final ep = one.episode;
      for (final m in ep.missions) {
        await p.toPuzzle(m);
        await p.answer(m);
        await p.onToMap();
      }
      final m = ep.finalMission;
      bool done() => c.read(gameControllerProvider).isCompleted(m.id);
      int wrong() => c.read(gameControllerProvider).wrongAnswers[m.id] ?? 0;
      Future<void> heard() async {
        for (var i = 0; i < 8 && find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty; i++) {
          await t.tap(find.byKey(const ValueKey('case-talk-next')));
          await wait(t, const Duration(milliseconds: 500));
        }
      }

      Future<void> card(String id) async {
        final f = find.byKey(ValueKey('case-talk-choice-$id'));
        expect(f, findsOneWidget, reason: id);
        await t.ensureVisible(f);
        await t.tap(f);
        await wait(t, const Duration(milliseconds: 600));
        await heard();
      }

      Future<void> open() async {
        await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
        await heard();
      }

      // Stage A: a question answered, back to the map (the app bar), then
      // straight in again (no app restart): the talk where it was. Then the
      // same with Android back.
      await open();
      await card(e1);
      await t.tap(find.byTooltip('Back to map'));
      await wait(t, const Duration(milliseconds: 3000));
      expect(find.text('OPEN THE FINAL CASE'), findsWidgets, reason: 'on the map');
      await open();
      expect(find.byKey(ValueKey('case-talk-choice-$e2')), findsOneWidget, reason: 'the second question, not the first again');
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 3000));
      expect(find.text('OPEN THE FINAL CASE'), findsWidgets, reason: 'Android back: on the map');
      await open();
      expect(find.byKey(ValueKey('case-talk-choice-$e2')), findsOneWidget, reason: 'still the second question');
      await card(e2);

      // Closed and opened again: still the third question; a wrong card is no wrong answer.
      c = await one.open(t, prefs, fresh: false, size: size);
      await open();
      await card(e3);
      expect(wrong(), 0, reason: 'a card that does not fit is never a wrong answer');
      await card(e1);
      expect(done(), isFalse, reason: 'the talk alone does not close the final');
      await t.tap(find.byKey(const ValueKey('case-talk-finish')));
      await wait(t, const Duration(milliseconds: 1500));

      // Stage B: the app opened again: straight to the tiles, the talk heard.
      c = await one.open(t, prefs, fresh: false, size: size);
      await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
      expect(find.byKey(const ValueKey('case-talk-finish')), findsNothing);
      for (final tile in tiles) {
        expect(find.text(tile), findsWidgets, reason: tile);
      }
      expect(t.takeException(), isNull);

      // Stage B: back to the map and in again (no restart): the tiles again.
      await t.tap(find.byTooltip('Back to map'));
      await wait(t, const Duration(milliseconds: 3000));
      await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 2800));
      expect(find.byKey(const ValueKey('case-talk-finish')), findsNothing, reason: 'the talk stays heard');
      for (final tile in tiles) {
        expect(find.text(tile), findsWidgets, reason: tile);
      }

      // LEARN refused with its line, a hint, then the name.
      await p.answer(m, 'learn,min,right,sound');
      expect([done(), wrong()], [false, 1]);
      // The try-again sheet's hint (the final page's own way to a hint).
      await tapText(t, 'GET MORE HINTS', after: const Duration(milliseconds: 900));
      expect(c.read(gameControllerProvider).hintsFor(m.id), 1);
      expect(findReadableContaining(m.hints.first), findsWidgets, reason: 'the first hint shown');
      for (var i = 0; i < 4 && find.text('Start again').hitTestable().evaluate().isEmpty; i++) {
        await t.tapAt(const Offset(160, 80));
        await wait(t, const Duration(milliseconds: 600));
      }
      await tapText(t, 'Start again', after: const Duration(milliseconds: 300));
      await p.answer(m);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(), isTrue);
      expect(t.takeException(), isNull);
    });
  }

  group('read on a phone (UX pass)', () {
    // The app's own fonts: the page's heights as a phone lays them out.
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

    for (final level in Difficulty.values) {
      final ep = episode('s5_ep01', level);
      test('${level.label}: M3 names the board\'s own places and rows; the final shows the name, then the dawn', () {
        final m3 = ep.missions[2];
        final spec = season.variants[level]?.syllables[m3.id] ?? season.syllables[m3.id]!;
        expect(spec.blocks.first.line, startsWith('Group 1 (TOP):'));
        expect(spec.blocks.first.line, contains('AT THE BOTTOM: the throat.'));
        expect(spec.blocks.last.line, startsWith('Group 2 (BOTTOM):'));
        expect(m3.question, allOf(contains('TOP or BOTTOM'), contains('AT THE BOTTOM')));
        final ending = SeasonCatalog.caseEnding(ep.finalMission)!;
        expect(ending.first.text, contains('훈민정음 (訓民正音)'), reason: 'the name first, as soon as it is built');
        expect(ending[1].text, startsWith('At dawn'));
        expect(ep.finalMission.transition.where((l) => l.contains('turn over')), isEmpty, reason: 'said once, in the ending');
      });

      test('${level.label}: M1\'s places carry their groups and a view of their own', () {
        final scene = season.variants[level]?.deductions[ep.missions[0].id] ?? season.deductions[ep.missions[0].id]!;
        expect({for (final p in scene.places) p.optionId: p.chip}, {'a': '혼', 'b': '운', 'c': '훈'});
        for (final p in scene.places) {
          expect(ep.missions[0].options.firstWhere((o) => o.id == p.optionId).label, endsWith(p.chip!));
          expect(scene.choosing!.contains(p.mark), isTrue, reason: p.optionId);
        }
      });
    }

    test('every other read place keeps its view and its plain markers', () {
      final others = {...season1Deductions, for (final e in season.deductions.entries) if (e.key != 's5_ep01_m1') e.key: e.value};
      expect(others, isNotEmpty);
      for (final MapEntry(:key, :value) in others.entries) {
        expect(value.choosing, isNull, reason: key);
        expect(value.rereadLetter, isFalse, reason: key);
        expect(value.places.every((p) => p.chip == null), isTrue, reason: key);
      }
    });

    for (final (level, size, scale) in [
      (Difficulty.rookie, const Size(320, 568), 1.0),
      (Difficulty.rookie, const Size(375, 667), 1.0),
      (Difficulty.rookie, const Size(390, 844), 1.0),
      (Difficulty.rookie, const Size(430, 932), 1.0),
      (Difficulty.rookie, const Size(320, 568), 1.3),
      (Difficulty.master, const Size(320, 568), 1.3),
    ]) {
      testWidgets('${level.label} ${size.width.toInt()}×${size.height.toInt()} text ×$scale: M1\'s three places in view with their groups; the letter again; M2\'s letters large', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final one = SingleCase(season, 's5_ep01', level: level)..register();
        addTearDown(one.unregister);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await one.open(t, prefs, fresh: true, size: size);
        final p = CasePlayer(t, season);
        final mp = MissionPlay();
        final m1 = one.episode.missions[0];
        final scene = season.variants[level]?.deductions[m1.id] ?? season.deductions[m1.id]!;
        await p.toPuzzle(m1);
        await mp.noteClues(t, scene);
        await wait(t, const Duration(milliseconds: 600));
        final view = t.getRect(find.descendant(of: find.byType(SceneDeduction), matching: find.byType(InteractiveViewer)));
        for (final id in ['a', 'b', 'c']) {
          final r = t.getRect(find.byKey(ValueKey('place-$id')));
          expect(view.contains(r.topLeft) && view.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue, reason: '$id: $r in $view');
        }
        for (final (id, chip) in [('a', '혼'), ('b', '운'), ('c', '훈')]) {
          expect(find.descendant(of: find.byKey(ValueKey('place-$id')), matching: find.text(chip)), findsOneWidget, reason: 'shown before a place is chosen');
        }
        expect(find.textContaining('Your choice'), findsNothing);

        await tapText(t, 'Reread Letter', after: const Duration(milliseconds: 900));
        expect(findReadableContaining('Taek '), findsWidgets, reason: 'the letter, with Taek\'s shapes');
        await tapText(t, 'BACK TO THE PUZZLE', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('place-c')), findsOneWidget, reason: 'the places as they were');

        await mp.chooseAndSearch(t, scene, m1.answer);
        await wait(t, const Duration(milliseconds: 1200));
        expect(one.episode.missions.first.id, m1.id);
        await p.onToMap();

        await p.toPuzzle(one.episode.missions[1]);
        for (final jamo in ['ㅇ', 'ㅡ', 'ㅁ']) {
          final text = t.widget<Text>(find.text(jamo).last);
          expect(text.style!.fontSize, greaterThanOrEqualTo(28), reason: jamo);
        }
        expect(t.takeException(), isNull);
      });
    }
  });

  test('Stage A is the only talk read on a final; its type is the mission\'s', () {
    expect(episode('s5_ep01', Difficulty.rookie).finalMission.type, MissionType.sequence);
    expect(SeasonCatalog.all.where((s) => s.talkMissions.keys.any((id) => id.endsWith('_final'))).map((s) => s.id), [season.id]);
    expect(season.talkMissions.keys.where((id) => id.endsWith('_final')), [fin]);
  });
}
