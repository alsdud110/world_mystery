import 'package:flutter/foundation.dart';

import '../../data/mock/season_catalog.dart';
import '../../data/models/case_talk.dart';
import '../../data/models/clock_puzzle.dart';
import '../../data/models/mission.dart';
import '../../data/models/scene_deduction.dart';
import '../../data/models/letter_puzzles.dart';
import '../../data/models/river_puzzles.dart';
import '../../data/models/tower_puzzles.dart';
import '../../data/models/abbesses_puzzles.dart';
import 'widgets/archive_drawers.dart';
import 'widgets/blotter_mirror.dart';
import 'widgets/hold_rack.dart';
import 'widgets/clockwork_garden.dart';
import 'widgets/label_assembly.dart';
import 'widgets/morning_sketches.dart';
import 'widgets/star_records.dart';
import 'widgets/torn_slip.dart';
import 'widgets/clock_question.dart';
import 'widgets/clock_wall.dart';
import 'widgets/dial_lock.dart';
import 'widgets/dialogue_investigation.dart';
import 'widgets/fly_rail.dart';
import '../../data/models/scene_inspect.dart';
import 'widgets/investigation_search.dart';
import '../../data/models/station_clocks.dart';
import '../../data/models/painter_puzzles.dart';
import 'widgets/keeper_ledger.dart';
import 'widgets/reveal_layer.dart';
import 'widgets/spot_differences.dart';
import 'widgets/station_clocks.dart';
import 'widgets/studio_match.dart';
import 'widgets/trail_order.dart';
import 'widgets/lens_inspect.dart';
import 'widgets/lift_route.dart';
import 'widgets/light_board.dart';
import 'widgets/show_strip.dart';
import 'widgets/mark_compare.dart';
import 'widgets/painter_corner.dart';
import 'widgets/plan_route.dart';
import 'widgets/river_marks.dart';
import 'widgets/tower_records.dart';
import 'widgets/question_widgets.dart';
import 'widgets/scene_deduction.dart';
import 'widgets/scene_explore.dart';
import 'widgets/shape_match_board.dart';
import 'widgets/shown_answer.dart';
import 'widgets/syllable_board.dart';
import 'widgets/timeline_board.dart';

/// Whether [m] is played on the puzzle page itself (a question, a clock, a
/// board), not in a scene of its own. [caseTalk]: its talk with one person,
/// as the page reads it (the game's provider).
bool playedOnThePage(Mission m, {TalkScene? caseTalk}) =>
    caseTalk == null &&
    SeasonCatalog.investigation(m) == null &&
    SeasonCatalog.dialogue(m) == null &&
    SeasonCatalog.easySteps(m) == null &&
    SeasonCatalog.stationClocks(m) == null &&
    SeasonCatalog.compare(m) == null &&
    SeasonCatalog.studio(m) == null &&
    SeasonCatalog.layer(m) == null &&
    SeasonCatalog.records(m) == null &&
    SeasonCatalog.lift(m) == null &&
    SeasonCatalog.dialLock(m) == null &&
    SeasonCatalog.riverMarks(m) == null &&
    SeasonCatalog.keeperHut(m) == null &&
    SeasonCatalog.quayBoxes(m) == null &&
    SeasonCatalog.markCompare(m) == null &&
    SeasonCatalog.clockWall(m) == null &&
    SeasonCatalog.blotter(m) == null &&
    SeasonCatalog.holdRack(m) == null &&
    SeasonCatalog.planRoute(m) == null &&
    SeasonCatalog.archive(m) == null &&
    SeasonCatalog.showStrip(m) == null &&
    SeasonCatalog.lightBoard(m) == null &&
    SeasonCatalog.flyRail(m) == null &&
    SeasonCatalog.cornerChoice(m) == null &&
    SeasonCatalog.morningSketches(m) == null &&
    SeasonCatalog.tornSlip(m) == null &&
    SeasonCatalog.trialMap(m) == null &&
    SeasonCatalog.gearBoard(m) == null &&
    SeasonCatalog.makerMarks(m) == null &&
    SeasonCatalog.drumTape(m) == null &&
    SeasonCatalog.cityClocks(m) == null &&
    SeasonCatalog.shadowCheck(m) == null &&
    SeasonCatalog.explore(m) == null &&
    SeasonCatalog.deduction(m) == null &&
    SeasonCatalog.decode(m) == null &&
    SeasonCatalog.inspection(m) == null;

/// Paris's scenes laid on the puzzle page: each with everything looked at
/// and its answer set.
AnswerPicture? _parisPicture(Mission m, ValueChanged<String>? onSent) {
  Future<void> sent(String answer) async => onSent?.call(answer);
  // Two records compared: the line picked on each ("first:second").
  if (SeasonCatalog.records(m) case final scene?) {
    final lines = m.answer.split(':');
    if (lines.length != 2) return null;
    return AnswerPicture(
      TowerRecords(
        scene: scene,
        mission: m,
        progress: TowerPuzzleProgress()
          ..picked[scene.first.id] = lines[0]
          ..picked[scene.second.id] = lines[1],
        read: {for (final d in scene.docs) d.id},
        onRead: (_) {},
        onChanged: () {},
        onSubmit: sent,
      ),
    );
  }
  // The lift: the stop chosen.
  if (SeasonCatalog.lift(m) case final scene?) {
    return AnswerPicture(
      LiftRoute(
        scene: scene,
        mission: m,
        progress: TowerPuzzleProgress()..picked['stop'] = m.answer,
        read: const {LiftScene.plateId, LiftScene.logId},
        onRead: (_) {},
        onChanged: () {},
        onSubmit: sent,
      ),
    );
  }
  // A padlock: each dial on its symbol.
  if (SeasonCatalog.dialLock(m) case final scene?) {
    final dials = [for (final id in Mission.sequenceIds(m.answer)) scene.symbols.indexWhere((s) => s.id == id)];
    if (dials.contains(-1)) return null;
    return AnswerPicture(DialLock(scene: scene, mission: m, dials: dials, onSet: (_) {}, onSubmit: sent));
  }
  // The quay wall: the mark chosen.
  if (SeasonCatalog.riverMarks(m) case final scene?) {
    return AnswerPicture(
      RiverMarks(
        scene: scene,
        mission: m,
        read: {for (final x in scene.marks) x.id, RiverMarksScene.backId},
        onRead: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The keeper's ledger: the box circled.
  if (SeasonCatalog.keeperHut(m) case final scene?) {
    return AnswerPicture(
      KeeperHut(
        scene: scene,
        mission: m,
        at: HutStep.ledger,
        circled: m.answer,
        onAt: (_) {},
        onCircle: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The workbench: the stamp chosen.
  if (SeasonCatalog.markCompare(m) case final scene?) {
    return AnswerPicture(
      MarkCompare(
        scene: scene,
        mission: m,
        compared: {for (final s in scene.seals) s.id},
        onCompared: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The wall of clocks: the clock chosen.
  if (SeasonCatalog.clockWall(m) case final scene?) {
    return AnswerPicture(
      ClockWall(
        scene: scene,
        mission: m,
        watched: true,
        looked: {for (final c in scene.clocks) c.id},
        onWatched: () {},
        onLooked: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The blotter under the glass: the note chosen.
  if (SeasonCatalog.blotter(m) case final scene?) {
    return AnswerPicture(
      BlotterMirror(
        scene: scene,
        mission: m,
        read: {for (final n in scene.notes) n.id},
        onRead: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The plan: the letter at the door chosen.
  if (SeasonCatalog.planRoute(m) case final scene?) {
    return AnswerPicture(
      PlanRoutePuzzle(scene: scene, mission: m, reached: PlanStep.values.toSet(), onReached: (_) {}, onSubmit: sent),
    );
  }
  // The fly rail: the backdrop let down.
  if (SeasonCatalog.flyRail(m) case final scene?) {
    return AnswerPicture(
      FlyRailPuzzle(
        scene: scene,
        mission: m,
        lowered: {for (final b in scene.rail.ropes) b.id},
        onLowered: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The painter's corners: the corner shown.
  if (SeasonCatalog.cornerChoice(m) case final scene?) {
    return AnswerPicture(
      PainterCornerPuzzle(
        scene: scene,
        mission: m,
        looked: {for (final c in scene.corners) c.id},
        onLooked: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The rack: the right tag up close, turned over.
  if (SeasonCatalog.holdRack(m) case final scene?) {
    if (!scene.rack.tags.any((t) => t.id == m.answer)) return null;
    return AnswerPicture(HoldRackAnswer(scene: scene, mission: m), dark: true, sends: false);
  }
  // The archive: the envelope the corner fits, the corner laid on it.
  if (SeasonCatalog.archive(m) case final scene?) {
    if (!scene.envelopes.any((e) => e.id == m.answer)) return null;
    return AnswerPicture(ArchiveAnswer(scene: scene, mission: m), dark: true, sends: false);
  }
  // The show's papers: the strip where the show fits.
  if (SeasonCatalog.showStrip(m) case final scene?) {
    return AnswerPicture(ShowStripPuzzle(scene: scene, mission: m, onSubmit: sent));
  }
  // The lighting desk: the levers as in the photo.
  if (SeasonCatalog.lightBoard(m) case final scene?) {
    return AnswerPicture(LightBoardPuzzle(scene: scene, mission: m, onPhoto: () {}, onSubmit: sent));
  }
  // The green boxes' label: each piece in its slot ("piece:slot").
  if (SeasonCatalog.quayBoxes(m) case final scene?) {
    final placed = <String, String>{
      for (final pair in Mission.sequenceIds(m.answer))
        if (pair.split(':') case [final piece, final slot]) slot: piece,
    };
    return AnswerPicture(
      LabelAssembly(
        scene: scene,
        mission: m,
        tried: {for (final b in scene.boxes) BoxesScene.boxKey(b.id)},
        onTry: (_) {},
        placed: placed,
        onPlaced: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The morning sketches: in order, every change found, the question answered.
  if (SeasonCatalog.morningSketches(m) case final scene?) {
    final state = SketchState(placed: scene.order, ordered: true, found: {for (final c in scene.changes) c.id});
    return AnswerPicture(
      MorningSketchesPuzzle(scene: scene, mission: m, state: state, onState: (_) {}, onSubmit: sent),
      question: MorningSketchesPuzzle.headingOf(scene, m, state),
    );
  }
  // The torn slip: unfolded, every part marked as it is.
  if (SeasonCatalog.tornSlip(m) case final scene?) {
    return AnswerPicture(
      TornSlipPuzzle(
        scene: scene,
        mission: m,
        state: SlipState(
          opened: scene.folds,
          same: {for (final p in scene.partsMarked(FormMark.same)) p.id},
          missing: {for (final p in scene.partsMarked(FormMark.missing)) p.id},
        ),
        onState: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The garden's boards: every piece where it belongs.
  if (SeasonCatalog.trialMap(m) case final scene?) {
    return AnswerPicture(
      TrialMapPuzzle(scene: scene, placed: {for (final x in scene.models) x.id: x.spot}, onPlaced: (_) {}, onSubmit: sent),
    );
  }
  if (SeasonCatalog.gearBoard(m) case final scene?) {
    return AnswerPicture(
      GearBoardPuzzle(scene: scene, placed: {for (final s in scene.slots) s.id: s.size}, onPlaced: (_) {}, onSubmit: sent),
    );
  }
  if (SeasonCatalog.makerMarks(m) case final scene?) {
    return AnswerPicture(
      MakerMarksPuzzle(
        scene: scene,
        joined: {
          for (final mark in scene.marks)
            for (final p in scene.paper)
              if (scene.same(mark.id, p.id)) mark.id: p.id,
        },
        onJoined: (_) {},
        onSubmit: sent,
      ),
    );
  }
  // The observatory's records: every jump, clock and shadow found.
  if (SeasonCatalog.drumTape(m) case final scene?) {
    return AnswerPicture(
      DrumTapePuzzle(scene: scene, pulled: true, found: scene.jumps, onPulled: () {}, onFound: (_) {}, onSubmit: sent),
    );
  }
  if (SeasonCatalog.cityClocks(m) case final scene?) {
    return AnswerPicture(
      CityClocksPuzzle(
        scene: scene,
        found: {for (final c in scene.photo.clocks) c.id},
        sorted: {for (final c in scene.photo.clocks) c.id: scene.trayOf(c)},
        trialMap: null,
        onChanged: (_, _) {},
        onSubmit: sent,
      ),
    );
  }
  if (SeasonCatalog.shadowCheck(m) case final scene?) {
    return AnswerPicture(
      ShadowCheckPuzzle(scene: scene, matched: {for (final p in scene.photos) p.id}, onMatched: (_) {}, onSubmit: sent),
    );
  }
  return null;
}

/// A clock's time from an answer as it is checked ("817": 8:17).
ClockTime? clockTimeOfAnswer(String answer) {
  final digits = answer.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 3) return null;
  final cut = digits.length - 2;
  return ClockTime.at(int.parse(digits.substring(0, cut)), int.parse(digits.substring(cut)));
}

/// A mission's puzzle with its answer entered, for the answer's picture
/// ([showAnswerPicture]): the puzzle's own widgets, set as the detective
/// would have set them. Null for a puzzle that has none: one that shows its
/// own answer as it is played (small steps), or whose picture is not made
/// yet. (A final case's page adds its own: `FinalMissionScreen`.)
///
/// [onSent]: told what the picture's puzzle would send as its answer (a
/// test presses its button); the game leaves it out, and nothing is sent.
AnswerPicture? answerPictureOf(Mission m, {TalkScene? caseTalk, ValueChanged<String>? onSent}) {
  void sent(String answer) => onSent?.call(answer);
  // A place looked round: its posters, the right one chosen.
  if (SeasonCatalog.explore(m) case final scene?) {
    return AnswerPicture(ExploreAnswer(scene: scene, mission: m), sends: false);
  }
  // A place searched: everything found, marked where it was.
  if (SeasonCatalog.investigation(m) case final scene?) {
    return AnswerPicture(
      InvestigationSearch(
        scene: scene,
        found: [for (final f in scene.finds) f.id],
        onFound: (_) {},
        onComplete: sent,
        hints: m.hints,
        hintsShown: m.hints.length,
        onHint: () async => false,
        guideShown: true,
        onGuideDone: () {},
      ),
      page: true,
      sends: false,
    );
  }
  // Exhibits under the glass: all examined, the label open, its word written.
  if (SeasonCatalog.inspection(m) case final scene?) {
    return AnswerPicture(
      LensInspect(
        scene: scene,
        mission: m,
        progress: InspectProgress()
          ..examined.addAll([for (final s in scene.spots) s.id])
          ..labelRead = true
          ..open = scene.label.id,
        onChanged: () {},
        onSubmit: (word) async => sent(word),
        onReread: () {},
        hintsShown: m.hints.length,
        onHint: () async => false,
        wrongPulse: 0,
      ),
      page: true,
    );
  }
  // A station hall: every clock looked at, the board read, the right clock chosen.
  if (SeasonCatalog.stationClocks(m) case final scene?) {
    return AnswerPicture(
      StationClocks(
        scene: scene,
        mission: m,
        progress: StationClocksProgress()
          ..looked.addAll([for (final c in scene.clocks) c.optionId, scene.board.id, scene.desk.id])
          ..open = scene.desk.id
          ..chosen = m.answer
          ..guideShown = true,
        onChanged: () {},
        onExamined: (_) {},
        onChoose: (id) async {
          sent(id);
        },
        hintsShown: m.hints.length,
        onHint: () async => false,
        wrongPulse: 0,
      ),
      page: true,
    );
  }
  // Two pictures compared: every difference found, marked.
  if (SeasonCatalog.compare(m) case final scene?) {
    return AnswerPicture(
      SpotDifferences(
        scene: scene,
        mission: m,
        progress: PicturePuzzleProgress()
          ..found.addAll(Mission.sequenceIds(m.answer))
          ..guideShown = true,
        onChanged: () {},
        onFound: (_) {},
        onComplete: () async {},
        onReread: () {},
        hintsShown: m.hints.length,
        onHint: () async => false,
      ),
      page: true,
      sends: false,
    );
  }
  // A studio: every painting looked at, each note joined to its painting.
  if (SeasonCatalog.studio(m) case final scene?) {
    final progress = PicturePuzzleProgress()
      ..found.addAll([for (final p in scene.paintings) p.id])
      ..guideShown = true
      ..matchDemoShown = true
      ..open = 'match';
    for (final pair in Mission.sequenceIds(m.answer)) {
      if (pair.split(':') case [final note, final picture]) progress.pairs[note] = picture;
    }
    return AnswerPicture(
      StudioMatch(
        scene: scene,
        mission: m,
        progress: progress,
        onChanged: () {},
        onFound: (_) {},
        onSubmit: (a) async {
          sent(a);
        },
        hintsShown: m.hints.length,
        onHint: () async => false,
        wrongPulse: 0,
      ),
      page: true,
    );
  }
  // A sketch under its paint: uncovered, every thing on it found.
  if (SeasonCatalog.layer(m) case final scene?) {
    return AnswerPicture(
      RevealLayer(
        scene: scene,
        mission: m,
        progress: PicturePuzzleProgress()
          ..found.addAll(Mission.sequenceIds(m.answer))
          ..guideShown = true,
        revealed: 1,
        onChanged: () {},
        onReveal: (_) {},
        onFound: (_) {},
        onComplete: () async {},
        onReread: () {},
        hintsShown: m.hints.length,
        onHint: () async => false,
      ),
      page: true,
      sends: false,
    );
  }
  // A talk: every statement heard, the two that answer it chosen.
  if (SeasonCatalog.dialogue(m) case final scene?) {
    return AnswerPicture(DialogueAnswer(scene: scene), question: scene.goal, sends: false);
  }
  // A place read for its traces: every clue noted, the right place chosen.
  if (SeasonCatalog.deduction(m) case final scene?) {
    return AnswerPicture(
      SceneDeduction(
        scene: scene,
        mission: m,
        progress: DeductionProgress()
          ..noted.addAll([for (final c in scene.clues) c.id])
          ..chosen = m.answer
          ..guideShown = true,
        onChanged: () {},
        onChoose: sent,
        hintsShown: m.hints.length,
        onHint: () {},
        wrongPulse: 0,
      ),
      page: true,
    );
  }
  if (_parisPicture(m, onSent) case final picture?) return picture;
  if (!playedOnThePage(m, caseTalk: caseTalk)) return null;
  if (SeasonCatalog.clock(m) case final clock?) {
    final time = clockTimeOfAnswer(m.answer);
    if (time == null) return null;
    return AnswerPicture(
      ClockQuestion(puzzle: clock, time: time, moved: true, onChanged: (_) {}, onSubmit: sent),
      question: clock.question,
    );
  }
  // Traces tapped in order on their place.
  if (SeasonCatalog.trail(m) case final scene?) {
    return AnswerPicture(
      TrailOrderQuestion(
        mission: m,
        scene: scene,
        order: Mission.sequenceIds(m.answer),
        onChanged: (_) {},
        onSubmit: sent,
      ),
    );
  }
  if (SeasonCatalog.timeline(m) case final spec?) return AnswerPicture(TimelineBoard(spec: spec, solved: true));
  if (SeasonCatalog.syllable(m) case final spec?) return AnswerPicture(SyllableBoard(spec: spec, solved: true));
  if (SeasonCatalog.shape(m) case final spec?) return AnswerPicture(ShapeMatchBoard(spec: spec, solvedAnswer: m.answer));
  return switch (m.type) {
    MissionType.multipleChoice ||
    MissionType.wordInput ||
    MissionType.numberCode ||
    MissionType.finalCode ||
    MissionType.imageChoice ||
    MissionType.sequence ||
    MissionType.letterLock => AnswerPicture(questionFor(m, sent)),
    _ => null,
  };
}
