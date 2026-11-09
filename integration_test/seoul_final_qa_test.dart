import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/assets/season_pack_downloads.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission/widgets/question_widgets.dart' show PuzzleKey;
import 'package:world_mystery/core/assets/season_pack_bundle.dart' show SeasonPack;

import '../test/helpers.dart' show testOverrides;

/// Seoul's final stabilisation (2026-11-09) on a device or simulator: the
/// screens the redesign changed, played as a child plays them and captured
/// by the app itself (`takeScreenshot`), written on the host by
/// `test_driver/seoul_final_qa_driver.dart` under
/// `qa/screenshots/seoul_final/<width>x<height>/`.
///
/// * Case 04 M3: every trace and place of the new picture found by a tap at
///   its measured spot (panned to when off screen), a miss on bare stone,
///   the cart searched.
/// * Case 11's final: Miri's talk (two wrong cards, the line that says what
///   to read again, the right one), the lock (219 refused and kept, Clear,
///   319), the ending, and the final opened again.
/// * Case 12: M2's letters (a wrong order, then the right one and the
///   riddle), M3 (814 refused, 815), the final's talk and lock (NIGHT
///   refused with its line, LIGHT), the ending.
/// * The three-card talks of Cases 02, 06, 07, 09 and 10: the cards on
///   screen, a card lit only from the third miss.
///
/// Missions before a captured screen are answered through the controller.
/// The game runs on in-memory saves (`testOverrides`); the Seoul picture pack
/// is downloaded as the app downloads it (HTTPS, read only).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final seoul = [for (final e in MockEpisodeRepository.bundled()) if (e.seasonId == SeasonIds.seoul) e];
  Mission mission(String id) => seoul.expand((e) => e.allMissions).firstWhere((m) => m.id == id);

  testWidgets('Seoul: the redesigned screens, played and captured', (t) async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      ...await testOverrides(),
      seasonPackSetupProvider.overrideWithValue(await SeasonPackSetup.fromEnvironment(prefs)),
      seasonPacksInAppProvider.overrideWithValue(false),
    ]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Minyoung', DetectiveAvatar.girl);
    c.read(seasonPreviewSwitchProvider.notifier).set(true);
    c.read(operatorAccessSwitchProvider.notifier).set(true); // later cases opened directly
    expect(ctrl.openSeason(SeasonIds.seoul), isTrue);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(1500);
    // The Seoul pack, as a player downloads it (skipped when already on the device).
    if (!c.read(seasonPacksProvider).contains(SeasonPack.seoul.folder)) {
      await c.read(seasonPacksProvider.notifier).download(SeasonIds.seoul);
    }
    expect(c.read(seasonPacksProvider), contains(SeasonPack.seoul.folder), reason: 'the Seoul pack is installed');
    await binding.convertFlutterSurfaceToImage();
    await pause(300);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    final tag = '${size.width.round()}x${size.height.round()}';

    Future<void> shot(String name) async {
      await pause(600);
      await binding.takeScreenshot('$tag/$name');
      await pause(150);
    }

    var timeouts = 0;
    Future<void> until(Finder f, {int limitMs = 15000}) async {
      for (var waited = 0; waited < limitMs && f.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
      if (f.evaluate().isEmpty) await shot('timeout_${++timeouts}');
      expect(f, findsWidgets, reason: 'waiting for $f');
    }

    Future<void> tapF(Finder f, {int after = 600}) async {
      await until(f);
      await Scrollable.ensureVisible(t.element(f.last), alignment: 0.5);
      await pause(250);
      await t.tap(f.last);
      await pause(after);
    }

    Future<void> tapKey(String key, {int after = 600}) => tapF(find.byKey(ValueKey(key)), after: after);
    Future<void> tapText(String text, {int after = 600}) => tapF(find.text(text), after: after);
    bool done(String id) => c.read(gameControllerProvider).isCompleted(id);
    bool shown(String text) => find.textContaining(text).evaluate().isNotEmpty;

    /// A talk's lines heard, up to its next choice (or its finish).
    Future<void> heard() async {
      for (var i = 0; i < 40 && find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty; i++) {
        await tapKey('case-talk-next', after: 450);
      }
    }

    /// [id] opened and begun as a player begins it: its intro, then I'M READY.
    /// The case before it is closed first (its answers given through the
    /// controller), as a new case is never begun over an unfinished one.
    String? current;
    Future<void> openCase(String id) async {
      if (current case final prev?) {
        for (final m in seoul.firstWhere((e) => e.id == prev).allMissions) {
          if (!done(m.id)) ctrl.submitAnswer(m, SeasonCatalog.caseTalk(m)?.answer ?? m.answer);
        }
        c.read(routerProvider).go(Routes.map);
        await pause(1500);
      }
      current = id;
      expect(ctrl.openEpisode(id), isTrue);
      c.read(routerProvider).go(Routes.intro);
      await pause(1500);
      await tapText('SKIP ›', after: 1200);
      await tapText("I'M READY", after: 2500);
    }

    /// Straight to [m]'s place, as the map's GO opens it, then on through
    /// whatever comes first (INVESTIGATE, a talk, the letter) to [puzzle].
    Future<void> toPlace(Mission m, Finder puzzle) async {
      // A solve's moment still up: closed as a player closes it.
      for (var i = 0; i < 4; i++) {
        if (find.text('CONTINUE INVESTIGATION').evaluate().isNotEmpty) {
          await tapText('CONTINUE INVESTIGATION', after: 1500);
        } else if (find.text('TO THE MAP').evaluate().isNotEmpty) {
          await tapText('TO THE MAP', after: 1500);
        } else {
          break;
        }
      }
      c.read(routerProvider).go(Routes.mission(m.id));
      await pause(1500);
      for (var i = 0; i < 80 && puzzle.evaluate().isEmpty; i++) {
        if (find.text('INVESTIGATE').evaluate().isNotEmpty) {
          await tapText('INVESTIGATE', after: 1500);
        } else if (find.byKey(const ValueKey('case-talk-next')).evaluate().isNotEmpty) {
          await tapKey('case-talk-next', after: 400);
        } else if (find.byKey(const ValueKey('case-talk-finish')).evaluate().isNotEmpty) {
          await tapKey('case-talk-finish', after: 1500);
        } else if (find.text('TAP TO OPEN').evaluate().isNotEmpty) {
          await tapText('TAP TO OPEN', after: 1500);
        } else if (find.text('SOLVE THE PUZZLE').evaluate().isNotEmpty) {
          await tapText('SOLVE THE PUZZLE', after: 1500);
        } else {
          await pause(300);
        }
      }
      await until(puzzle);
    }

    void answered(Mission m) => ctrl.submitAnswer(m, m.answer);

    Future<void> toFinal() async {
      for (var i = 0; i < 4; i++) {
        if (find.text('CONTINUE INVESTIGATION').evaluate().isNotEmpty) {
          await tapText('CONTINUE INVESTIGATION', after: 1500);
        } else if (find.text('TO THE MAP').evaluate().isNotEmpty) {
          await tapText('TO THE MAP', after: 1500);
        } else {
          break;
        }
      }
      c.read(routerProvider).go(Routes.finalMission);
      await pause(2500);
    }

    // QA_REST=true: only what was not yet seen on a device (C12 M3 and the
    // final, the three-card talks); the rest is answered through the controller.
    const rest = bool.fromEnvironment('QA_REST');
    Future<void> code(String digits) async {
      for (final d in digits.split('')) {
        await tapF(find.widgetWithText(PuzzleKey, d), after: 200);
      }
    }

    if (!rest) {
    // ── Case 04 M3: the traces on the new picture ─────────────────────────
    await openCase('s5_ep04');
    final m3 = mission('s5_ep04_m3');
    for (final m in seoul.firstWhere((e) => e.id == 's5_ep04').missions.take(2)) {
      answered(m);
    }
    await toPlace(m3, find.byKey(const ValueKey('deduction-picture')));
    await pause(1500);
    await shot('c04_m3_opening');
    final scene = SeasonCatalog.deduction(m3)!;
    final viewer = t.getRect(find.byType(InteractiveViewer));

    /// [point] (fractions of the picture) on screen; dragged into view first
    /// when it is outside the viewer (a phone shows part of the place).
    Future<Offset> onScreen(Offset point) async {
      Offset at() {
        final box = t.getRect(find.byKey(const ValueKey('deduction-picture')));
        return Offset(box.left + point.dx * box.width, box.top + point.dy * box.height);
      }

      var p = at();
      if (!viewer.deflate(24).contains(p)) {
        await t.drag(find.byType(InteractiveViewer), viewer.center - p);
        await pause(700);
        p = at();
      }
      expect(viewer.contains(p), isTrue, reason: 'reachable: $point at $p in $viewer');
      return p;
    }

    for (final (i, clue) in scene.clues.indexed) {
      await t.tapAt(await onScreen(clue.areas.first.center));
      await pause(900);
      await shot('c04_m3_clue_${clue.id}');
      expect(shown(clue.line), isTrue, reason: '${clue.id}: its line shown after a tap at its spot');
      // Noted: the count on screen, and after the last, the choosing of the place.
      expect(i + 1 < scene.clues.length ? shown('CLUES ${i + 1} / ${scene.clues.length}') : shown('YOUR NOTES'), isTrue, reason: '${clue.id}: noted');
    }
    // A miss: bare stone, bottom middle (no trace, no place there).
    await t.tapAt(await onScreen(const Offset(0.48, 0.95)));
    await pause(700);
    expect(shown(scene.missLine) || shown(scene.notPlaceLine), isTrue, reason: 'a tap on bare stone says so');
    await shot('c04_m3_miss');
    await t.tapAt(await onScreen(scene.placeOf(m3.answer).areas.first.center));
    await pause(700);
    await shot('c04_m3_cart_chosen');
    await tapKey('deduction-search', after: 2500);
    expect(done(m3.id), isTrue, reason: 'the cart searched: M3 solved');
    await shot('c04_m3_solved');

    // ── Case 11's final: the talk, then the lock ──────────────────────────
    await openCase('s5_ep11');
    final c11 = seoul.firstWhere((e) => e.id == 's5_ep11');
    for (final m in c11.missions) {
      answered(m);
    }
    await toFinal();
    await heard();
    await shot('c11_final_talk_cards');
    final present = SeasonCatalog.talkMission(c11.finalMission)!.before!.presents.single;
    final wrong = [for (final e in present.choices) if (!present.accepted.contains(e)) e];
    await tapKey('case-talk-choice-${wrong[0]}', after: 1200);
    await heard();
    await shot('c11_final_talk_miss1');
    await tapKey('case-talk-choice-${wrong[1]}', after: 1200);
    await heard();
    expect(shown(present.tell!), isTrue, reason: 'two misses: what to read again');
    await shot('c11_final_talk_miss2_tell');
    await tapKey('case-talk-choice-${present.accepted.first}', after: 1200);
    await heard();
    await tapKey('case-talk-finish', after: 2500);
    await shot('c11_final_lock');

    await code('219');
    await tapText('UNLOCK', after: 1500);
    expect(done(c11.finalMission.id), isFalse);
    await shot('c11_final_219_refused');
    await tapText('TRY AGAIN', after: 900);
    expect(find.text('2'), findsWidgets, reason: 'the wrong code stays to be changed');
    await shot('c11_final_219_kept');
    await tapF(find.bySemanticsLabel('Clear'), after: 400);
    await code('319');
    await tapText('UNLOCK', after: 3500);
    expect(done(c11.finalMission.id), isTrue, reason: '319 opens the lock');
    await shot('c11_final_solved');
    c.read(routerProvider).go(Routes.map);
    await pause(1500);
    await toFinal();
    await shot('c11_final_opened_again');
    expect(done(c11.finalMission.id), isTrue, reason: 'still solved after coming back');

    }

    // ── Case 12: M2's letters, M3's radio, the final's lock ───────────────
    await openCase('s5_ep12');
    final c12 = seoul.firstWhere((e) => e.id == 's5_ep12');
    final [c12m1, c12m2, c12m3] = c12.missions;
    answered(c12m1);
    if (rest) answered(c12m2);
    if (!rest) {
    await toPlace(c12m2, find.byKey(const ValueKey('timeline-board')));
    await shot('c12_m2_board');
    final spec = SeasonCatalog.timeline(c12m2)!;
    Future<void> order(List<String> ids) async {
      for (final (i, id) in ids.indexed) {
        if (spec.card(id)?.anchor != null) continue;
        await tapKey('timeline-card-$id', after: 300);
        await tapKey('timeline-slot-$i', after: 300);
      }
      for (final card in spec.cards.where((card) => card.discard)) {
        await tapKey('timeline-card-${card.id}', after: 300);
        await tapKey('timeline-pile', after: 300);
      }
      await tapText('CHECK THE ORDER', after: 1500);
    }

    final right = Mission.sequenceIds(c12m2.answer);
    await order([right[0], right[3], right[1], right[2]]); // the moon letter too early
    expect(done(c12m2.id), isFalse);
    expect(shown('The sun gives it'), isFalse, reason: 'the riddle is not read before the order is right');
    await shot('c12_m2_wrong_order');
    if (find.text('TRY AGAIN').evaluate().isNotEmpty) await tapText('TRY AGAIN', after: 900);
    // The cards stay where they were laid: taken back with Undo, as a child does.
    for (var i = 0; i < 8 && find.text('Undo').evaluate().isNotEmpty; i++) {
      await tapText('Undo', after: 300);
    }
    await shot('c12_m2_undone');
    await order(right);
    expect(done(c12m2.id), isTrue);
    await pause(2500);
    await shot('c12_m2_solved');
    }
    await toPlace(c12m3, find.text('UNLOCK'));
    await code('814');
    await tapText('UNLOCK', after: 1500);
    expect(done(c12m3.id), isFalse, reason: "814 is the 'may' day");
    await shot('c12_m3_814');
    await tapText('TRY AGAIN', after: 900);
    await tapF(find.bySemanticsLabel('Clear'), after: 400);
    await code('815');
    await tapText('UNLOCK', after: 2500);
    expect(done(c12m3.id), isTrue);
    await toFinal();
    await heard();
    for (final p in SeasonCatalog.talkMission(c12.finalMission)!.before!.presents) {
      await shot('c12_final_cards_${p.id}');
      await tapKey('case-talk-choice-${p.accepted.first}', after: 1200);
      await heard();
    }
    await tapKey('case-talk-finish', after: 2500);
    await shot('c12_final_lock');
    Future<void> spell(String word) async {
      for (final l in word.split('')) {
        await tapF(find.bySemanticsLabel('Letter $l'), after: 250);
      }
    }

    await spell('NIGHT');
    await shot('c12_final_night_set');
    await tapText('OPEN THE LOCK', after: 1500);
    expect(done(c12.finalMission.id), isFalse);
    expect(shown(c12.finalMission.feedback['NIGHT']!), isTrue, reason: "NIGHT's own line");
    await shot('c12_final_night_refused');
    await tapText('TRY AGAIN', after: 900);
    for (var i = 4; i >= 0; i--) {
      await tapKey('lock-slot-$i', after: 200); // each letter back out
    }
    await spell('LIGHT');
    await tapText('OPEN THE LOCK', after: 4000);
    expect(done(c12.finalMission.id), isTrue);
    await shot('c12_final_solved');

    // ── The three-card talks ──────────────────────────────────────────────
    for (final id in ['s5_ep02', 's5_ep06', 's5_ep07', 's5_ep09', 's5_ep10']) {
      await openCase(id);
      final e = seoul.firstWhere((e) => e.id == id);
      for (final m in e.missions) {
        answered(m);
      }
      await toFinal();
      await heard();
      await shot('${id}_final_cards');
      final talk = SeasonCatalog.caseTalk(e.finalMission) ?? SeasonCatalog.talkMission(e.finalMission)!.before!;
      final p = talk.presents.first;
      // A question asked first when the cards wait for it.
      for (final q in talk.questions) {
        if (find.byKey(ValueKey('case-talk-choice-${p.choices.first}')).evaluate().isNotEmpty) break;
        if (find.byKey(ValueKey('case-talk-q-${q.id}')).evaluate().isEmpty) continue;
        await tapKey('case-talk-q-${q.id}', after: 800);
        await heard();
      }
      expect(find.byKey(ValueKey('case-talk-choice-${p.choices.first}')), findsOneWidget, reason: '$id: the first cards on screen');
      expect(p.choices, hasLength(3), reason: id);
      for (final ch in p.choices) {
        expect(find.byKey(ValueKey('case-talk-choice-$ch')), findsOneWidget, reason: '$id: card $ch on screen');
      }
      final miss = p.choices.firstWhere((ch) => !p.accepted.contains(ch));
      for (var i = 1; i <= 3; i++) {
        await tapKey('case-talk-choice-$miss', after: 1000);
        await heard();
        if (i == 2) await shot('${id}_final_miss2');
      }
      await shot('${id}_final_miss3_lit');
    }
  });
}
