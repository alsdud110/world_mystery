import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/case_talk.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/shape_match.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/core/utils/audio_service.dart' show MockAudioService;
import 'package:world_mystery/features/mission/widgets/shape_match_board.dart';
import 'package:world_mystery/features/mission/widgets/syllable_board.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';

import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';
import '../../tool/season_packs/season_manifests.dart' show appOnlySeasonFiles;
import '../full_playthrough_test.dart' show tapText, wait;
import '../helpers.dart' show findReadableContaining;
import 'single_case.dart';
import '../reading_finders.dart';

/// Seoul Case 01 V4, The King's Secret Letters (docs/SEOUL_CASE01_V4_GAME_DESIGN.md):
/// Bun-i's letter to her mother. M1 finds what she wants to say, M2 how
/// sounds become letters, M3 her first word, the final her letter, then the
/// name of the letters. Each mission's result is used by a later one.
void main() {
  final season = season5Content;
  const m2 = 's5_ep01_m2', fin = 's5_ep01_final';
  const e1 = 's5_ep01_e1', e2 = 's5_ep01_e2', e3 = 's5_ep01_e3', e4 = 's5_ep01_e4';
  const papers = ['어마', '엄마', '엄머', '고마워요', '미안해요', '잘 가요'];

  Episode episode(String id, Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes[id]!, 'seasonId': season.id}),
    level,
    patches: season.casePatches,
  );
  TalkScene talk(Difficulty level) => (level == Difficulty.rookie ? season.talkMissions : season.variants[level]!.talkMissions)[fin]!.before!;
  ShapeMatchSpec shapes(Difficulty level) => level == Difficulty.rookie ? season.shapes[m2]! : season.variants[level]!.shapes[m2]!;

  group('the same case at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode('s5_ep01', level);
      test('${level.label}: the answers, two free hints each, the same ids', () {
        expect([for (final m in ep.allMissions) m.answer], ['thanks', 'mieum:lips,nieun:tongue,ieung:throat', '엄마', 'eomma,gomawoyo']);
        for (final m in ep.allMissions) {
          expect(m.hints, hasLength(2), reason: m.id);
        }
        expect([for (final m in ep.allMissions) m.evidence?.id], [e1, e2, e3, e4]);
        expect(ep.missions[0].clue?.id, 's5_ep01_c1', reason: 'Bun-i\'s water drop, read by Cases 02 and 11');
      });

      test('${level.label}: every wrong answer is answered in English, none gives the answer away', () {
        final m = ep.allMissions;
        for (final o in m[0].options.where((o) => o.id != 'thanks')) {
          expect(AnswerChecker.feedbackFor(m[0], o.id), isNotNull, reason: 'M1 ${o.id}');
        }
        // M2: every wrong pair a player can lay (5 letters on 3 pictures) has its line.
        final spec = shapes(level);
        for (final l in spec.letters) {
          for (final p in spec.pictures) {
            final pair = '${l.id}:${p.id}';
            if (m[1].answer.split(',').contains(pair)) continue;
            expect(m[1].feedback[pair], isNotNull, reason: 'M2 $pair');
          }
        }
        for (final wrong in ['eoma,gomawoyo', 'eommeo,gomawoyo', 'eomma,mianhaeyo', 'eomma,jalgayo', 'gomawoyo,eomma']) {
          final line = AnswerChecker.feedbackFor(m[3], wrong);
          expect(line, isNotNull, reason: 'final $wrong');
          expect(line!.contains('THANK YOU') || line.contains('고마워요'), isFalse, reason: 'final $wrong: the answer never said');
        }
        expect([for (final o in m[3].options) o.label], unorderedEquals(papers));
      });

      test('${level.label}: the King asks for Bun-i\'s message, then her first word', () {
        final t = talk(level);
        expect([for (final p in t.presents) '${p.id}:${p.accepted.join(',')}'], ['what:$e1', 'written:$e3']);
        expect(t.presents[1].requires, {'what'});
        for (final p in t.presents) {
          expect(p.choices, hasLength(2), reason: p.id);
        }
      });

      test('${level.label}: the final uses all three missions: the message, the mouth, the first word', () {
        final f = ep.finalMission;
        expect(f.letter, allOf(contains('엄마'), contains('마'), contains('미'), contains('가요')));
        expect(ep.missions[2].evidence!.description, contains('엄마'), reason: 'the first word to find on the practice papers');
        expect(ep.missions[0].evidence!.description.toLowerCase(), contains('thank you'), reason: 'the message to find among Sora\'s words');
        expect(ep.missions[1].evidence!.description, allOf(contains('ㅁ'), contains('ㄱ')), reason: '마 is not 가: the lips, not the back of the tongue');
      });
    }

    for (final level in Difficulty.values) {
      test('${level.label}: M1 — each wrong drawing is ruled out by the note itself, THANK YOU by what Mom does', () {
        final m = episode('s5_ep01', level).missions[0];
        final words = m.letter.toLowerCase();
        expect(words, allOf(contains('not leaving'), contains('tomorrow')), reason: 'GOODBYE: she is not going away');
        expect(words, anyOf(contains('broke nothing'), contains("didn't break anything"), contains('broken anything')), reason: 'SORRY: nothing done wrong');
        expect(words, allOf(contains('gives me'), contains('never')), reason: 'THANK YOU: given so much, never a word back');
        // The wrong drawings' lines point back to those words.
        expect(m.options.firstWhere((o) => o.id == 'sorry').feedback!.toLowerCase(), anyOf(contains('broke'), contains('break')));
        expect(m.options.firstWhere((o) => o.id == 'bye').feedback!.toLowerCase(), contains('leaving'));
      });

      test('${level.label}: Final — every Sora word is named by a block, so the choice is Bun-i\'s message, not a block', () {
        final f = episode('s5_ep01', level).finalMission;
        final sora = [for (final l in f.letter.split('\n')) if (l.startsWith('Sora:')) l];
        expect(sora, hasLength(3), reason: 'thank you, I\'m sorry, goodbye: each its block');
        expect(sora.join(' '), allOf(contains('마'), contains('미'), contains('가요')));
        expect(sora.join(' ').toLowerCase(), allOf(contains('thank you'), contains("i'm sorry"), contains('goodbye')));
        // A wrong word names what it means and asks for Bun-i's message (Mission 1).
        for (final wrong in ['eomma,mianhaeyo', 'eomma,jalgayo']) {
          expect(AnswerChecker.feedbackFor(f, wrong), contains('Bun-i'), reason: wrong);
        }
        expect(f.hints.last, contains("Bun-i's Message"), reason: 'the second hint sends the player to M1\'s evidence');
      });
    }

    test('the evidence and the clue say the same at every level (later cases recall them)', () {
      final eps = [for (final l in Difficulty.values) episode('s5_ep01', l)];
      for (final m in eps.first.allMissions) {
        final i = eps.first.allMissions.indexOf(m);
        expect({for (final e in eps) e.allMissions[i].evidence?.description}, hasLength(1), reason: m.id);
      }
    });
  });

  group('the ending: the name, then the letter at dawn', () {
    for (final level in Difficulty.values) {
      test('${level.label}: the name told after the letter; Bun-i teaches her mother; the box', () {
        final lines = (level == Difficulty.rookie ? season.endings : season.variants[level]!.endings)[fin]!;
        final texts = [for (final l in lines) l.text];
        final name = texts.indexWhere((x) => x.contains('훈민정음') && x.contains('訓民正音') && x.contains('Hunminjeongeum'));
        // Rookie says it in a child's words: the next morning.
        final dawn = texts.indexWhere((x) => x.contains(level == Difficulty.rookie ? 'morning' : 'dawn'));
        expect(name, greaterThan(0), reason: 'the name shown in three ways');
        expect(dawn, greaterThan(name), reason: 'the name first, then the dawn');
        for (final syllable in ['훈', '민', '정', '음']) {
          expect(texts.sublist(name, dawn).any((x) => RegExp('$syllable( is| means|,)').hasMatch(x)), isTrue, reason: '$syllable explained');
        }
        expect(texts.any((x) => x.contains('엄… 마')), isTrue, reason: 'her mother reads her own name for herself');
        for (final l in lines.skip(dawn)) {
          expect(l.background, endsWith('ending_mother_letter.webp'), reason: l.text);
        }
        for (final l in lines.take(dawn)) {
          expect(l.background, endsWith('final_kings_study.webp'), reason: l.text);
        }
        expect(lines.last.text, contains('wooden box'), reason: 'the letter kept in the box (the keepers\' box of Cases 08 and 12)');
      });
    }
  });

  group('Case 01 keeps its own story; later cases stand alone', () {
    test('Bun-i\'s mark and Sora\'s board: its five shapes and its added line', () {
      final c1 = episode('s5_ep01', Difficulty.rookie).missions[0].clue!;
      expect(c1.title, 'Bun-i\'s Mark');
      expect(c1.value, 'a water drop');
      final board = episode('s5_ep01', Difficulty.rookie).missions[1].evidence!;
      expect(board.description, allOf(contains('ㅁ'), contains('ㄴ'), contains('ㅇ'), contains('ㄱ'), contains('ㅅ'), contains('stronger sound adds a line')));
    });

    for (final level in Difficulty.values) {
      test('${level.label}: Case 08\'s ending tells its own story, not Bun-i\'s letter', () {
        final words = [for (final l in (level == Difficulty.rookie ? season.endings : season.variants[level]!.endings)['s5_ep08_final']!) l.text].join(' | ');
        expect(words, isNot(contains('엄마')));
        expect(words, isNot(contains('Bun-i')));
        expect(words, isNot(contains('letter box')));
      });
    }
  });

  group('pictures and voices', () {
    const dir = 'assets/seasons/season_05_seoul/cases/case_01';
    final pictures = [
      for (final n in ['m1_picture_memo', 'm2_mouth_lips', 'm2_mouth_tongue', 'm2_mouth_throat', 'm3_writing_desk', 'final_kings_study', 'intro_side_gate', 'ending_mother_letter']) '$dir/$n.webp',
    ];
    final voices = [
      for (final n in ['mieum', 'nieun', 'a', 'eo', 'eom', 'ma', 'eomma', 'gomawoyo', 'hunminjeongeum']) '$dir/audio/$n.m4a',
    ];
    test('every picture on disk and in the Seoul pack; every voice in the app (pubspec)', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final packed = {for (final f in seasonPackManifests['season_05_seoul']!.files) f.path};
      for (final f in pictures) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(packed, contains(f));
        expect(appOnlySeasonFiles, isNot(contains(f)));
        expect(pubspec, isNot(contains('    - $f\n')), reason: f);
      }
      for (final f in voices) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(appOnlySeasonFiles, contains(f));
        expect(pubspec, contains('    - $f\n'), reason: f);
      }
    });
  });

  group('M2 on a phone: letters laid on the mouth', () {
    Future<List<String>> open(WidgetTester t, ShapeMatchSpec spec, {double text = 1, String? solved}) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final sent = <String>[];
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(320, 568), textScaler: TextScaler.linear(text)),
          child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: ShapeMatchBoard(spec: spec, onSubmit: sent.add, solvedAnswer: solved))),
        ),
      ));
      await t.pumpAndSettle();
      return sent;
    }

    Future<void> tap(WidgetTester t, String key) async {
      final f = find.byKey(ValueKey(key));
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
    }

    for (final level in Difficulty.values) {
      for (final text in [1.0, 1.6]) {
        testWidgets('${level.label}, 320×568, text ×$text: every tile 48 dp on screen; laid, moved, picked up, then checked', (t) async {
          final spec = shapes(level);
          final sent = await open(t, spec, text: text);
          expect(t.takeException(), isNull);
          for (final l in spec.letters) {
            final r = t.getRect(find.byKey(ValueKey('shape-letter-${l.id}')));
            expect(r.width >= 48 && r.height >= 48 && r.left >= 0 && r.right <= 320, isTrue, reason: '${l.id}: $r');
          }
          for (final p in spec.pictures) {
            expect(findText(p.name), findsOneWidget, reason: p.id);
          }
          expect(find.text('?'), findsNWidgets(3));
          expect(t.widget<GestureDetector>(find.descendant(of: find.byKey(const ValueKey('shape-check')), matching: find.byType(GestureDetector)).first).onTap, isNull, reason: 'CHECK waits for every picture');
          // ㄱ laid on the tongue, then ㄴ on it in its place: ㄱ is free again.
          await tap(t, 'shape-letter-giyeok');
          expect(find.text('Now tap the picture ㄱ copies.'), findsOneWidget);
          await tap(t, 'shape-picture-tongue');
          await tap(t, 'shape-letter-nieun');
          await tap(t, 'shape-picture-tongue');
          // ㅁ laid on the throat, picked up again, laid on the lips.
          await tap(t, 'shape-letter-mieum');
          await tap(t, 'shape-picture-throat');
          await tap(t, 'shape-picture-throat');
          await tap(t, 'shape-picture-lips');
          await tap(t, 'shape-letter-ieung');
          await tap(t, 'shape-picture-throat');
          await tap(t, 'shape-check');
          expect(sent, ['mieum:lips,nieun:tongue,ieung:throat']);
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('solved: the letters on their pictures, nothing to play', (t) async {
      await open(t, shapes(Difficulty.rookie), solved: 'mieum:lips,nieun:tongue,ieung:throat');
      expect(find.byKey(const ValueKey('shape-check')), findsNothing);
      expect(find.byKey(const ValueKey('shape-letter-mieum')), findsNothing);
      for (final g in ['ㅁ', 'ㄴ', 'ㅇ']) {
        expect(findText(g), findsOneWidget, reason: g);
      }
    });
  });

  for (final level in Difficulty.values) {
    testWidgets('${level.label}, 320×568: the King\'s talk, back to the map, the app reopened, then the letter\'s papers', (t) async {
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

      // The first question answered, back to the map, straight in again: the second question.
      await open();
      await card(e1);
      await t.tap(find.byTooltip('Back to map'));
      await wait(t, const Duration(milliseconds: 3000));
      expect(find.text('OPEN THE FINAL CASE'), findsWidgets, reason: 'on the map');
      await open();
      expect(find.byKey(ValueKey('case-talk-choice-$e3')), findsOneWidget, reason: 'the second question, not the first again');

      // Closed and opened again: a wrong card is no wrong answer; then her first word.
      c = await one.open(t, prefs, fresh: false, size: size);
      await open();
      await card(e2);
      expect(wrong(), 0, reason: 'a card that does not fit is never a wrong answer');
      await card(e3);
      expect(done(), isFalse, reason: 'the talk alone does not close the final');
      await t.tap(find.byKey(const ValueKey('case-talk-finish')));
      await wait(t, const Duration(milliseconds: 1500));
      for (final paper in papers) {
        expect(findText(paper), findsWidgets, reason: paper);
      }

      // 미안해요 refused with its line, then the letter.
      await p.answer(m, 'eomma,mianhaeyo');
      expect([done(), wrong()], [false, 1]);
      expect(findReadableContaining('I\'M SORRY'), findsWidgets, reason: 'the wrong word read, and Bun-i\'s message asked for');
      for (var i = 0; i < 4 && find.text('Start again').hitTestable().evaluate().isEmpty; i++) {
        if (find.text('TRY AGAIN').evaluate().isNotEmpty) {
          await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        } else {
          await t.tapAt(const Offset(160, 80));
          await wait(t, const Duration(milliseconds: 600));
        }
      }
      await tapText(t, 'Start again', after: const Duration(milliseconds: 300));
      await p.answer(m);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(), isTrue);
      expect(t.takeException(), isNull);
    });
  }

  group('an old save (the four groups of 2026-11-07) opened in V4', () {
    test('the old M3 board state is not this board\'s: it opens empty, never broken', () {
      final spec = season.syllables['s5_ep01_m3']!;
      // 정음, as the old board saved it: its first sounds ㅈ and ㅇ, ㅇ and ㅁ under them.
      const old = [['standing', 'left', 'ㅈ', 'ㅇ'], ['flat', 'none', 'ㅇ', 'ㅁ']];
      expect(const SyllableRules().stateFromJson(spec, old), isNull);
      final session = PuzzleSession.open(const SyllableRules(), spec, saved: 'pv2:syllables:1:${jsonEncode(old)}');
      expect(session.state, const SyllableRules().initial(spec));
    });

    testWidgets('missions solved in the old case stay solved; the next one opens', (t) async {
      final one = SingleCase(season, 's5_ep01')..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await one.open(t, prefs, fresh: true, size: const Size(320, 568));
      final ctrl = c.read(gameControllerProvider.notifier);
      for (final m in one.episode.missions.take(2)) {
        ctrl.submitAnswer(m, m.answer);
      }
      ctrl.recordPuzzleState('s5_ep01_m3', 'pv2:syllables:1:[["standing","left","ㅈ","ㅇ"],["flat","none","ㅇ","ㅁ"]]');
      c = await one.open(t, prefs, fresh: false, size: const Size(320, 568));
      final p = CasePlayer(t, season);
      final m3 = one.episode.missions[2];
      await p.toPuzzle(m3);
      expect(t.takeException(), isNull);
      expect(find.text('BLOCK 1'), findsOneWidget, reason: 'the V4 board, empty');
      await p.answer(m3);
      expect(c.read(gameControllerProvider).isCompleted(m3.id), isTrue);
    });
  });

  testWidgets('320×568: back from every step of every mission returns to the map, nothing lost, then played', (t) async {
    final one = SingleCase(season, 's5_ep01')..register();
    addTearDown(one.unregister);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = await one.open(t, prefs, fresh: true, size: const Size(320, 568));
    final p = CasePlayer(t, season);
    for (final m in one.episode.missions) {
      await p.toPuzzle(m);
      // Back, step by step (puzzle, letter, place), to the map.
      for (var i = 0; i < 6 && find.byTooltip('Back').evaluate().isNotEmpty; i++) {
        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 900));
      }
      if (find.byTooltip('Back to map').evaluate().isNotEmpty) {
        await t.tap(find.byTooltip('Back to map'));
        await wait(t, const Duration(milliseconds: 2500));
      }
      expect(find.bySemanticsLabel(RegExp('^GO TO ')), findsWidgets, reason: '${m.id}: on the map');
      expect(c.read(gameControllerProvider).isCompleted(m.id), isFalse, reason: m.id);
      expect(t.takeException(), isNull, reason: m.id);
      // In again: the mission opens where it was left, its puzzle (nothing to read again).
      await t.tap(find.bySemanticsLabel('GO TO ${m.location}'));
      await wait(t, const Duration(milliseconds: 2800));
      for (final step in ['INVESTIGATE', 'TAP TO OPEN', 'SOLVE THE PUZZLE']) {
        if (findText(step).evaluate().isNotEmpty) await tapText(t, step, after: const Duration(milliseconds: 1500));
      }
      await p.answer(m);
      expect(c.read(gameControllerProvider).isCompleted(m.id), isTrue, reason: m.id);
      await p.onToMap();
    }
  });

  testWidgets('320×568: M1\'s picture note can be dragged and pinched', (t) async {
    final one = SingleCase(season, 's5_ep01')..register();
    addTearDown(one.unregister);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await one.open(t, prefs, fresh: true, size: const Size(320, 568));
    final p = CasePlayer(t, season);
    final m1 = one.episode.missions[0];
    await p.toPuzzle(m1);
    final viewer = find.byType(InteractiveViewer);
    expect(viewer, findsOneWidget);
    Matrix4 zoom() => t.widget<InteractiveViewer>(viewer).transformationController!.value.clone();
    final start = zoom();
    await t.drag(viewer, const Offset(-80, 0));
    await wait(t, const Duration(milliseconds: 600));
    expect(zoom(), isNot(start), reason: 'dragged sideways');
    final centre = t.getCenter(viewer);
    final a = await t.startGesture(centre - const Offset(20, 0));
    final b = await t.startGesture(centre + const Offset(20, 0), pointer: 7);
    await a.moveBy(const Offset(-40, 0));
    await b.moveBy(const Offset(40, 0));
    await a.up();
    await b.up();
    await wait(t, const Duration(milliseconds: 600));
    expect(zoom().getMaxScaleOnAxis(), greaterThan(start.getMaxScaleOnAxis()), reason: 'pinched closer');
    expect(t.takeException(), isNull);
  });

  group('M3\'s word said aloud', () {
    test('only Case 01 M3 has a voice: the whole word, its file checked by ear-free transcription (docs §5.2)', () {
      expect({for (final e in season.syllables.entries) if (e.value.voice != null) e.key: e.value.voice}, {'s5_ep01_m3': 'assets/seasons/season_05_seoul/cases/case_01/audio/eomma.m4a'});
      for (final l in Difficulty.values.skip(1)) {
        expect(season.variants[l]!.syllables['s5_ep01_m3']!.voice, season.syllables['s5_ep01_m3']!.voice, reason: l.label);
      }
    });

    testWidgets('LISTEN says the word; without a player, no button', (t) async {
      final heard = <String>[];
      final spec = season.syllables['s5_ep01_m3']!;
      Future<void> pump({ValueChanged<String>? onListen}) => t.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: SyllableBoard(spec: spec, onListen: onListen))),
      ));
      await pump(onListen: heard.add);
      await t.tap(find.byKey(const ValueKey('syllable-listen')));
      expect(heard, [spec.voice]);
      await pump();
      expect(find.byKey(const ValueKey('syllable-listen')), findsNothing);
    });

    test('a voice is never said with the sound off', () async {
      var on = false;
      final audio = MockAudioService(isEnabled: () => on);
      await audio.playVoice('assets/x.m4a');
      on = true;
      await audio.playVoice('assets/y.m4a');
      expect(audio.voices, ['assets/y.m4a']);
    });
  });
}