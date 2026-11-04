import 'dart:io';

import 'package:world_mystery/puzzles_v2/core/syllable_rules.dart';
import 'package:world_mystery/puzzles_v2/core/timeline_rules.dart';

import '../asset_optimizer/image_file.dart';
import 'content_hash.dart';
import 'palette_facts.dart';
import 'plan_ids.dart';
import 'plan_models.dart';

/// One thing a plan lacks to be made into the game's content: which kind
/// ([code]), where ([path], as `$.missions[1].play.hints`) and why.
class PlayIssue {
  const PlayIssue(this.code, this.path, this.message, {this.inSeason = false, this.blocking = true});

  final String code;
  final String path;
  final String message;

  /// In the season plan (its places), not the case plan.
  final bool inSeason;

  /// Whether it stops the generator. A story picture not made yet
  /// (`story_picture_missing`, STEP 3-15A) does not: the puzzle plays
  /// without it, its line shows no face until it is made.
  final bool blocking;

  @override
  String toString() => '[$code] ${inSeason ? 'season ' : ''}$path: $message';
}

/// What the Dart generator (`generate_case.dart`) needs of a case plan and
/// its season plan before it writes anything (STEP 3-8): the words the game
/// shows (`play`), a picture for every place, and a puzzle it can make.
///
/// Never the game's own content rules again: whether a hint gives the
/// answer away, links and answers are judged right is
/// `SeasonContentValidator`'s, run on the generated content by the tests.
/// Here only what the generator turns into game data, and the one rule the
/// plans keep looser than the game ([minChoiceOptions]).
///
/// A plan with no `play` still keeps its format and structure: this check
/// runs only when a case is to be generated (or `validate_plan --playable`).
abstract final class PlayCheck {
  /// A choice of fewer is "a guess, not a choice" to the game's validator
  /// (`season_content_validator.dart`); the plans accept two while planned
  /// (`PuzzleSelectionCheck`). `play_check_test` keeps the two numbers equal.
  static const minChoiceOptions = 3;

  /// `AppConstants.maxHints`.
  static const maxHints = 2;

  /// The puzzles the generator makes now, by palette id, and the table its
  /// scene is written into (null: played from its mission type). The text
  /// puzzles of STEP 3-8 (the mission page's own question widgets, the final
  /// page's dials), and since STEP 3-13 the puzzles played on pictures whose
  /// engines take a season's own files: a look round (`explore`), a search
  /// (`search`), a talk with witnesses (`dialogue`) and a picture choice
  /// (its options' `picture`).
  static const generatable = <String, String?>{
    'text_choice': null,
    'order_sequence': null,
    'word_entry': null,
    'letter_tile_lock': null,
    'combo_dial_lock': null,
    'picture_choice': null,
    'scene_explore_choose': 'explores',
    'dark_room_search': 'investigations',
    'witness_compare': 'dialogues',
    'timeline_board': 'timelines',
    'syllable_compose': 'syllables',
    // Puzzle Engine 2.0 STEP 1: engines the game already plays, now made from plans.
    'number_entry': null,
    'trace_deduction': 'deductions',
    'lens_inspect_word': 'inspections',
    'record_mismatch': 'records',
    'evidence_talk': 'talks',
  };

  /// The generatable puzzles that need pictures beyond the place's.
  static const pictured = {
    'picture_choice', 'scene_explore_choose', 'dark_room_search', 'witness_compare', //
    'trace_deduction', 'lens_inspect_word', 'record_mismatch', 'evidence_talk',
  };

  /// A story picture (a talk's or an ending's face) not on disk: never
  /// blocking (STEP 3-15A).
  static const storyPictureMissing = 'story_picture_missing';

  /// The `play` key a table's scene is written under.
  static const sceneKeys = {
    'explores': 'explore', 'investigations': 'search', 'dialogues': 'dialogue', 'timelines': 'timeline', 'syllables': 'syllables', //
    'deductions': 'traces', 'inspections': 'inspect', 'records': 'records', 'talks': 'interview',
  };

  static const _choiceTypes = {'multipleChoice', 'imageChoice', 'canvasChoice'};

  /// The types `AnswerChecker` reads `Mission.orderFeedback` for.
  static const _orderTypes = {'sequence', 'letterLock', 'wordInput', 'numberCode', 'finalCode', 'examine'};

  static final _glossaryWord = RegExp(r"^[a-z][a-z'-]*$");

  /// Everything [plan] and [season] lack to be generated. [root]: the
  /// repository's root, the places' files are read from.
  static List<PlayIssue> casePlan(CasePlan plan, SeasonPlan season, {String root = '.'}) {
    final out = <PlayIssue>[];
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    void missing(String path) => issue('play_field_missing', path, 'missing');

    final places = <String, PlacePlan>{};
    for (final (i, p) in season.places.indexed) {
      final at = '\$.places[$i]';
      if (PlanIds.seasonOfScoped(p.placeId) != season.seasonId) {
        out.add(PlayIssue('place_invalid', '$at.placeId', '${p.placeId} is not a place of ${season.seasonId}', inSeason: true));
      }
      if (places.containsKey(p.placeId)) {
        out.add(PlayIssue('place_invalid', '$at.placeId', '${p.placeId} given twice', inSeason: true));
      }
      places[p.placeId] = p;
      if (!File('$root/${p.file}').existsSync()) {
        out.add(PlayIssue('place_file_missing', '$at.file', '${p.file} is not on disk', inSeason: true));
      }
    }

    final c = plan.play;
    if (c == null) {
      issue('play_missing', r'$.play', "the case's words (intro, caseSummary) are not written");
    } else {
      if (c.intro.isEmpty) missing(r'$.play.intro');
      if (c.caseSummary == null) missing(r'$.play.caseSummary');
      for (final word in c.glossary.keys) {
        if (!_glossaryWord.hasMatch(word)) issue('play_range', '\$.play.glossary.$word', 'not one word in lower case');
      }
    }

    final all = plan.allMissions;
    for (final (i, m) in all.indexed) {
      final at = m.isFinal ? r'$.final' : '\$.missions[$i]';
      final p = m.puzzle;
      final type = p.missionType;
      final id = p.paletteId;
      final made = id != null &&
          generatable.containsKey(id) &&
          p.engineTable == generatable[id] &&
          (pictured.contains(id) ? p.status != PuzzleStatus.devRequest : p.status == PuzzleStatus.ready);
      if (!made) {
        issue('generate_unsupported', '$at.puzzle.paletteId',
            '${id ?? 'no palette puzzle'} (${p.status.name}${p.engineTable == null ? '' : ', table ${p.engineTable}'}): the generator makes ${[for (final MapEntry(:key, :value) in generatable.entries) value == null ? key : '$key ($value)'].join(', ')} only');
      }
      if (_choiceTypes.contains(type) && p.answerSpec.options.length < minChoiceOptions) {
        issue('play_choice_few', '$at.puzzle.answerSpec.options',
            '${p.answerSpec.options.length} options: the game asks for at least $minChoiceOptions (a guess, not a choice)');
      }
      if (!places.containsKey(m.placeId)) {
        issue('place_unregistered', '$at.placeId', '${m.placeId} has no picture in the season plan (places)');
      }

      final w = m.play;
      if (w == null) {
        issue('play_missing', '$at.play', "the mission's words are not written");
        continue;
      }
      final pa = '$at.play';
      for (final (key, value) in [
        ('title', w.title),
        ('location', w.location),
        ('letterIntro', w.letterIntro),
        ('letter', w.letter),
        ('question', w.question),
        ('successMessage', w.successMessage),
      ]) {
        if (value == null) missing('$pa.$key');
      }
      if (w.story.isEmpty) missing('$pa.story');
      if (w.hints.isEmpty) {
        missing('$pa.hints');
      } else if (w.hints.length > maxHints) {
        issue('play_range', '$pa.hints', '${w.hints.length} hints (1 to $maxHints)');
      }
      if (m.isFinal && w.transition.isEmpty) missing('$pa.transition');
      if (w.mapX == null) missing('$pa.mapX');
      if (w.mapY == null) missing('$pa.mapY');
      if (w.evidence == null) missing('$pa.evidence');

      // The notebook clue: written for the clue the mission leaves, and only then.
      if (m.clueOutputs.clue != null && w.clue == null) missing('$pa.clue');
      if (m.clueOutputs.clue == null && w.clue != null) {
        issue('play_clue_mismatch', '$pa.clue', 'the mission leaves no clue (clueOutputs.clue)');
      }

      void symbol(String path, String? key) {
        if (key != null && !PaletteFacts.dialSymbols.contains(key)) {
          issue('play_symbol_unknown', path, '"$key" is not a GameSymbol (${PaletteFacts.dialSymbols.join(', ')})');
        }
      }

      symbol('$pa.clue.symbol', w.clue?.symbol);
      symbol('$pa.evidence.icon', w.evidence?.icon);
      for (final (j, s) in (w.evidence?.symbols ?? const <String>[]).indexed) {
        symbol('$pa.evidence.symbols[$j]', s);
      }

      if (_choiceTypes.contains(type) && w.feedback.isNotEmpty) {
        issue('play_range', '$pa.feedback', "a choice's wrong-answer lines are its options' (puzzle.answerSpec.options[].feedback)");
      }
      if (w.orderFeedback != null && !_orderTypes.contains(type)) {
        issue('play_range', '$pa.orderFeedback', 'a $type is never in the wrong order');
      }
      if (w.lockTitle != null && type != 'letterLock') {
        issue('play_range', '$pa.lockTitle', 'a $type has no letter lock to name');
      }
      if (w.hideOptionNames != null && type != 'imageChoice') {
        issue('play_range', '$pa.hideOptionNames', 'a $type shows no pictures to name');
      }
      _pictures(m, at, root, out);
      _timeline(m, at, out);
      _syllables(m, at, out);
      _numberCode(m, at, out);
      _traces(m, at, root, out);
      _inspect(m, at, root, out);
      _records(m, at, root, out);
      _interview(plan, m, at, root, out);
      _aroundPuzzle(plan, m, at, root, out);

      // The notebook evidence a mission recalls: one, found before (the clue graph's).
      final recalls = [for (final c in m.clueInputs) if (c.use == ClueUse.recall) c];
      if (recalls.length > 1) {
        issue('play_recall', '$at.clueInputs', '${recalls.length} recall inputs: the game recalls one piece of evidence');
      } else if (recalls.length == 1 && !PlanIds.evidence.hasMatch(recalls.single.ref)) {
        issue('play_recall', '$at.clueInputs', 'recalls ${recalls.single.ref}: the game recalls evidence (an _e id)');
      } else if (recalls.isEmpty && w.recall != null) {
        issue('play_recall', '$pa.recall', 'the mission has no recall input');
      }

      final links = [for (final c in m.clueInputs) if (c.use == ClueUse.evidenceLink) c];
      if (links.length > 1) {
        issue('play_link', '$at.clueInputs', '${links.length} evidence links: its evidence is matched to one');
      } else if (links.length == 1) {
        if (!PlanIds.evidence.hasMatch(links.single.ref)) issue('play_link', '$at.clueInputs', 'links ${links.single.ref}: evidence is matched to evidence');
        if (w.evidenceLinkLine == null) missing('$pa.evidenceLinkLine');
      } else if (w.evidenceLinkLine != null) {
        issue('play_link', '$pa.evidenceLinkLine', 'the mission has no evidenceLink input');
      }
    }
    return out;
  }

  /// The pictures [m] is played on beyond its place's (STEP 3-13): its
  /// scene, the one its engine table reads, and its picture options. Every
  /// file must be on disk at the size the plan gives it (a picture not made
  /// yet stops the generator: `asset_file_missing`, never a stand-in), and
  /// every place on a picture inside it, as its own pixels.
  static void _pictures(MissionPlan m, String at, String root, List<PlayIssue> out) {
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    final p = m.puzzle;
    final w = m.play!;
    final pa = '$at.play';
    final a = p.answerSpec;
    final optionIds = {for (final o in a.options) o.id};

    void file(String path, String f, {(int, int)? size}) {
      final disk = File('$root/$f');
      if (!disk.existsSync()) {
        issue('asset_file_missing', path, '$f is not on disk: a picture still to be made');
        return;
      }
      if (size == null) return;
      final got = imageSize(disk);
      if (got == null) {
        issue('asset_unreadable', path, '$f is not a picture the game can open (PNG, WebP or JPEG, read whole)');
      } else if (got case (final width, final height) when (width, height) != size) {
        issue('asset_size_mismatch', path, '$f is ${width}x$height, not ${size.$1}x${size.$2}: places on it are measured on the file');
      }
    }

    void picture(String path, PicturePlan pic) => file('$path.file', pic.file, size: (pic.width, pic.height));

    // The picture a scene's places are on (STEP 3-15A): measured on the
    // drawn file, that very file. A place a prompt put somewhere is never
    // played as if it were measured.
    void measured(String path, PicturePlan pic) {
      final disk = File('$root/${pic.file}');
      if (!disk.existsSync()) return;
      if (pic.measuredOn == null) {
        issue('coordinates_unmeasured', '$path.measuredOn',
            'the places on ${pic.file} are not measured on the drawn picture: measure them, then write its sha256 here');
      } else if (ContentHash.ofBytes(disk.readAsBytesSync()) != pic.measuredOn) {
        issue('coordinates_stale', '$path.measuredOn', '${pic.file} changed since its places were measured: measure them again');
      }
    }

    bool inside(PicturePlan pic, double x, double y) => x >= 0 && y >= 0 && x <= pic.width && y <= pic.height;
    void point(String path, PicturePlan pic, ScenePoint pt) {
      if (!inside(pic, pt.x, pt.y)) issue('scene_area_invalid', path, '(${pt.x}, ${pt.y}) is off the ${pic.width}x${pic.height} picture');
    }

    void rect(String path, PicturePlan pic, SceneRect r) {
      if (!inside(pic, r.left, r.top) || !inside(pic, r.right, r.bottom) || r.left >= r.right || r.top >= r.bottom) {
        issue('scene_area_invalid', path, '[${r.left}, ${r.top}, ${r.right}, ${r.bottom}] is no rectangle on the ${pic.width}x${pic.height} picture');
      }
    }

    void rects(String path, PicturePlan pic, List<SceneRect> rs) {
      for (final (i, r) in rs.indexed) {
        rect('$path[$i]', pic, r);
      }
    }

    void unique(String path, Iterable<String> ids, String what) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) issue('scene_invalid', path, '$what "$id" given twice');
      }
    }

    // The scene its engine table reads, and no other.
    final table = p.engineTable;
    for (final MapEntry(key: t, value: _) in w.scenes.entries) {
      if (t != table) issue('play_scene_mismatch', '$pa.${sceneKeys[t]}', 'a scene for $t, but the puzzle is played ${table == null ? 'from its type' : 'on $table'}');
    }
    if (table != null && sceneKeys.containsKey(table) && !w.scenes.containsKey(table)) {
      issue('play_field_missing', '$pa.${sceneKeys[table]}', 'missing: the $table scene its engine is played on');
    }

    // A picture choice: a picture for each option, and words for it.
    for (final (i, o) in a.options.indexed) {
      final oa = '$at.puzzle.answerSpec.options[$i]';
      if (p.missionType == 'imageChoice') {
        if (o.picture case final f?) {
          file('$oa.picture', f);
        } else {
          issue('play_field_missing', '$oa.picture', 'missing: a picture choice shows a picture for each option');
        }
        if (o.altText == null) issue('play_field_missing', '$oa.altText', 'missing: what the picture shows, for screen readers');
      } else if (o.picture != null) {
        issue('play_range', '$oa.picture', 'a ${p.missionType} shows no picture for its options');
      }
    }

    if (w.explore case final s? when table == 'explores') {
      final sa = '$pa.explore';
      picture('$sa.picture', s.picture);
      measured('$sa.picture', s.picture);
      point('$sa.guideAt', s.picture, s.guideAt);
      if (s.inside case final r?) rect('$sa.inside', s.picture, r);
      if (s.opening case final r?) rect('$sa.opening', s.picture, r);
      unique('$sa.spots', [for (final x in s.spots) x.id], 'spot');
      final ids = {for (final x in s.spots) x.id};
      for (final kind in ['document', 'choice']) {
        final n = s.spots.where((x) => x.kind == kind).length;
        if (n != 1) issue('scene_invalid', '$sa.spots', '$n spots of kind $kind: one holds the ${kind == 'document' ? 'letter' : 'choice'}');
      }
      for (final (i, x) in s.spots.indexed) {
        final xa = '$sa.spots[$i]';
        rects('$xa.areas', s.picture, x.areas);
        point('$xa.mark', s.picture, x.mark);
        if (x.kind == 'note' && x.line == null) issue('play_field_missing', '$xa.line', 'missing: a note says what is seen');
        if (x.requires case final need?) {
          if (!ids.contains(need) || need == x.id) issue('scene_invalid', '$xa.requires', '"$need" is no other spot of the scene');
          if (x.lockedLine == null) issue('play_field_missing', '$xa.lockedLine', 'missing: what it says before "$need" is looked at');
        }
      }
      for (final (i, o) in s.others.indexed) {
        rects('$sa.others[$i].areas', s.picture, o.areas);
      }
      unique('$sa.choices', [for (final c in s.choices) c.optionId], 'choice');
      final chosen = {for (final c in s.choices) c.optionId};
      if (!(chosen.length == optionIds.length && chosen.containsAll(optionIds))) {
        issue('scene_answer_mismatch', '$sa.choices', 'pictures for ${chosen.join(', ')}, but the options are ${optionIds.join(', ')}');
      }
      for (final (i, c) in s.choices.indexed) {
        file('$sa.choices[$i].picture', c.picture, size: s.choicePixels);
      }
    }

    if (w.search case final s? when table == 'investigations') {
      final sa = '$pa.search';
      picture('$sa.picture', s.picture);
      measured('$sa.picture', s.picture);
      point('$sa.guideAt', s.picture, s.guideAt);
      if (s.inside case final r?) rect('$sa.inside', s.picture, r);
      if (s.opening case final r?) rect('$sa.opening', s.picture, r);
      unique('$sa.finds', [for (final f in s.finds) f.id], 'find');
      for (final (i, f) in s.finds.indexed) {
        final fa = '$sa.finds[$i]';
        rects('$fa.areas', s.picture, f.areas);
        point('$fa.at', s.picture, f.at);
        picture('$fa.picture', f.picture);
        // The search is read from the letter: each thing where its line says.
        if (w.letter != null && !w.letter!.contains(f.reportLine)) {
          issue('scene_text_mismatch', '$fa.reportLine', 'not a line of the letter, word for word: the search is read there');
        }
      }
      for (final (i, o) in s.spots.indexed) {
        rects('$sa.spots[$i].areas', s.picture, o.areas);
      }
    }

    if (w.dialogue case final s? when table == 'dialogues') {
      final sa = '$pa.dialogue';
      file('$sa.background', s.background);
      unique('$sa.questions', [for (final q in s.questions) q.id], 'question');
      unique('$sa.witnesses', [for (final x in s.witnesses) x.id], 'witness');
      final questions = {for (final q in s.questions) q.id};
      for (final (i, x) in s.witnesses.indexed) {
        final xa = '$sa.witnesses[$i]';
        file('$xa.portrait', x.portrait);
        final asked = x.answers.keys.toSet();
        if (!(asked.length == questions.length && asked.containsAll(questions))) {
          issue('scene_invalid', '$xa.answers', 'answers ${asked.join(', ')}: every witness answers every question (${questions.join(', ')})');
        }
      }
      final statements = s.statements;
      final d = s.deduction;
      final da = '$sa.deduction';
      if (!questions.contains(d.topic)) issue('scene_invalid', '$da.topic', '"${d.topic}" is no question of the talk');
      final pair = [for (final id in d.pair) statements[id]];
      for (final (i, id) in d.pair.indexed) {
        if (pair[i] == null) {
          issue('scene_answer_mismatch', '$da.pair[$i]', '"$id" is no statement (an answer with a thing, <witness>.<question>)');
        } else if (pair[i]!.$2 != d.topic) {
          issue('scene_answer_mismatch', '$da.pair[$i]', '"$id" is not about ${d.topic}');
        }
      }
      if (pair.every((x) => x != null)) {
        final [(w1, _, a1), (w2, _, a2)] = [for (final x in pair) x!];
        if (w1.id == w2.id) issue('scene_answer_mismatch', '$da.pair', 'two statements of one witness: two witnesses agree');
        if (a1.thing != a2.thing) issue('scene_answer_mismatch', '$da.pair', '"${a1.thing}" and "${a2.thing}": the two that answer it describe the same thing');
        // The pair is the one answer: no other two statements about the
        // topic describe the same thing (the game accepts the pair only).
        final about = [for (final MapEntry(:key, :value) in statements.entries) if (value.$2 == d.topic) (key, value.$3.thing)];
        for (final (i, (k1, t1)) in about.indexed) {
          for (final (k2, t2) in about.skip(i + 1)) {
            if (t1 == t2 && !{k1, k2}.containsAll(d.pair)) {
              issue('scene_ambiguous', '$da.pair', '$k1 and $k2 also describe "$t1" about ${d.topic}: one pair answers it');
            }
          }
        }
      }
      for (final (i, id) in d.then.indexed) {
        if (!statements.containsKey(id)) issue('scene_invalid', '$da.then[$i]', '"$id" is no statement');
      }
      if (d.then.isNotEmpty) {
        for (final k in TalkDeductionPlan.thenLines) {
          if (!d.lines.containsKey(k)) issue('play_field_missing', '$da.$k', 'missing: said while the statements still to find are asked for');
        }
      }
      if ((d.witnesses ?? 2) > s.witnesses.length) {
        issue('scene_invalid', '$da.witnesses', '${d.witnesses} witnesses to hear, of ${s.witnesses.length}');
      }
    }
  }

  /// A note in the new letters (`syllable_compose`, table `syllables`): its
  /// own rules (`SyllableRules.validate`, the game's), the note its answer,
  /// and every group's words read where the player puts it together.
  static void _syllables(MissionPlan m, String at, List<PlayIssue> out) {
    final w = m.play;
    final s = w?.syllables;
    if (w == null || s == null || m.puzzle.engineTable != 'syllables') return;
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    final sa = '$at.play.syllables';
    final spec = SyllableSpec(blocks: [
      for (final b in s.blocks) SyllableBlock(id: b.id, initial: b.initial, vowel: b.vowel, finalConsonant: b.finalConsonant, line: b.line),
    ]);
    const rules = SyllableRules();
    for (final i in rules.validate(spec)) {
      issue(i.code, '$sa${i.path.substring(1)}', i.message);
    }
    if (rules.answer(spec) != m.puzzle.answerSpec.answer) {
      issue('syllables_answer_mismatch', '$at.puzzle.answerSpec.answer', '"${m.puzzle.answerSpec.answer}", but the groups write "${rules.answer(spec)}"');
    }
    if (m.puzzle.missionType != 'wordInput') issue('syllables_type', '$at.puzzle.missionType', 'a note answers a wordInput, not ${m.puzzle.missionType}');
  }

  /// Cards a timeline may hold (Puzzle Engine 2.0): to place, fixed by
  /// their time, not part of it.
  static const timelinePlaced = (2, 6), timelineAnchors = (1, 3), timelineAside = 2;

  /// A timeline to put back together (`timeline_board`, table `timelines`):
  /// its own rules (`TimelineRules.validate`, the game's: one order the words
  /// and times allow, nothing that contradicts it), its size, its options
  /// the cards, every card to place ordered by the case's words (never by
  /// elimination alone), those words read in the mission, and the puzzle
  /// played through move by move as the page plays it. Whether a player
  /// reasons their way there is a person's reading, never this check's.
  static void _timeline(MissionPlan m, String at, List<PlayIssue> out) {
    final w = m.play;
    final s = w?.timeline;
    if (w == null || s == null || m.puzzle.engineTable != 'timelines') return;
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    final a = m.puzzle.answerSpec;
    final sa = '$at.play.timeline';
    final placed = [for (final c in s.cards) if (c.anchor == null && !c.discard) c];
    final anchors = [for (final c in s.cards) if (c.anchor != null && !c.discard) c];
    final aside = [for (final c in s.cards) if (c.discard) c];
    if (placed.length < timelinePlaced.$1 || placed.length > timelinePlaced.$2) {
      issue('timeline_size', '$sa.cards', '${placed.length} card(s) to place: ${timelinePlaced.$1} to ${timelinePlaced.$2}');
    }
    if (anchors.length < timelineAnchors.$1 || anchors.length > timelineAnchors.$2) {
      issue('timeline_size', '$sa.cards', '${anchors.length} card(s) fixed by their time: ${timelineAnchors.$1} to ${timelineAnchors.$2}');
    }
    if (aside.length > timelineAside) issue('timeline_size', '$sa.cards', '${aside.length} cards not part of it: $timelineAside at most');

    // The options are the cards, in their order, by their titles.
    final sameOptions = a.options.length == s.cards.length &&
        [for (var i = 0; i < s.cards.length; i++) a.options[i].id == s.cards[i].id && a.options[i].label == s.cards[i].title].every((x) => x);
    if (!sameOptions) issue('timeline_options_mismatch', '$at.puzzle.answerSpec.options', 'one option per card, in the cards\' order, labelled with its title');
    if (w.orderFeedback == null) issue('play_field_missing', '$at.play.orderFeedback', 'missing: what a wrong order is told');

    final spec = TimelineSpec(
      cards: [for (final c in s.cards) TimelineCard(id: c.id, title: c.title, text: c.text, anchor: c.anchor, discard: c.discard, evidence: c.evidence)],
      order: [for (final id in a.answer.split(',')) id.trim()],
      relations: [for (final r in s.relations) TimelineRelation(earlier: r.earlier, later: r.later, line: r.line)],
    );
    const rules = TimelineRules();
    final problems = rules.validate(spec);
    for (final i in problems) {
      issue(i.code, '$sa ${i.path}', i.message);
    }
    if (a.codeLength case final n? when n != spec.order.length) issue('timeline_order_mismatch', '$at.puzzle.answerSpec.codeLength', '$n, but ${spec.order.length} cards are in the order');

    // Each card to place is ordered by the case's words.
    for (final c in placed) {
      if (!s.relations.any((r) => r.earlier == c.id || r.later == c.id)) {
        issue('timeline_card_unrelated', '$sa.cards', '${c.id}: no line of the case says what it came before or after (its place is never known from the words)');
      }
    }
    // Those words are read in the mission: its letter or story, word for word.
    final read = [w.letterIntro, w.letter, ...w.story, w.question, w.prompt].whereType<String>().join('\n');
    String flat(String x) => x.replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final (i, r) in s.relations.indexed) {
      if (!flat(read).contains(flat(r.line))) {
        issue('timeline_line_unread', '$sa.relations[$i].line', '"${r.line}" is not in the mission\'s letter or story, word for word: the player never reads it');
      }
    }

    // Played through, as the page plays it: every card put in its place, the rest set aside.
    if (problems.isEmpty) {
      var state = rules.initial(spec);
      var played = true;
      for (final (i, id) in spec.order.indexed) {
        if (spec.anchors.containsKey(i)) continue;
        final r = rules.apply(spec, state, PlaceCard(id, i));
        played &= r.accepted;
        state = r.state;
      }
      for (final c in aside) {
        final r = rules.apply(spec, state, DiscardCard(c.id));
        played &= r.accepted;
        state = r.state;
      }
      if (!played || !rules.isComplete(spec, state) || rules.answerOf(spec, state) != rules.answer(spec)) {
        issue('timeline_unplayable', sa, 'its order cannot be put together with the page\'s moves');
      }
    }
  }

  // ── Existing engines made from plans (Puzzle Engine 2.0 STEP 1) ────────

  /// A picture a scene is played on: on disk at its size, its places
  /// measured on that very file (as `_pictures` holds a look round's).
  static void _scenePicture(String path, PicturePlan pic, String root, List<PlayIssue> out, {bool measured = true}) {
    final disk = File('$root/${pic.file}');
    if (!disk.existsSync()) {
      out.add(PlayIssue('asset_file_missing', '$path.file', '${pic.file} is not on disk: a picture still to be made'));
      return;
    }
    final got = imageSize(disk);
    if (got == null) {
      out.add(PlayIssue('asset_unreadable', '$path.file', '${pic.file} is not a picture the game can open (PNG, WebP or JPEG, read whole)'));
    } else if (got != (pic.width, pic.height)) {
      out.add(PlayIssue('asset_size_mismatch', '$path.file', '${pic.file} is ${got.$1}x${got.$2}, not ${pic.width}x${pic.height}: places on it are measured on the file'));
    }
    if (!measured) return;
    if (pic.measuredOn == null) {
      out.add(PlayIssue('coordinates_unmeasured', '$path.measuredOn', 'the places on ${pic.file} are not measured on the drawn picture: measure them, then write its sha256 here'));
    } else if (ContentHash.ofBytes(disk.readAsBytesSync()) != pic.measuredOn) {
      out.add(PlayIssue('coordinates_stale', '$path.measuredOn', '${pic.file} changed since its places were measured: measure them again'));
    }
  }

  static bool _on(PicturePlan pic, double x, double y) => x >= 0 && y >= 0 && x <= pic.width && y <= pic.height;

  static void _areas(String path, PicturePlan pic, List<SceneRect> rs, List<PlayIssue> out) {
    for (final (i, r) in rs.indexed) {
      if (!_on(pic, r.left, r.top) || !_on(pic, r.right, r.bottom) || r.left >= r.right || r.top >= r.bottom) {
        out.add(PlayIssue('scene_area_invalid', '$path[$i]', '[${r.left}, ${r.top}, ${r.right}, ${r.bottom}] is no rectangle on the ${pic.width}x${pic.height} picture'));
      }
    }
  }

  static void _spot(String path, PicturePlan pic, ScenePoint p, List<PlayIssue> out) {
    if (!_on(pic, p.x, p.y)) out.add(PlayIssue('scene_area_invalid', path, '(${p.x}, ${p.y}) is off the ${pic.width}x${pic.height} picture'));
  }

  static bool _inAny(ScenePoint p, Iterable<SceneRect> rs) => rs.any((r) => p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom);

  static void _uniqueIds(String path, Iterable<String> ids, String what, List<PlayIssue> out) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) out.add(PlayIssue('scene_invalid', path, '$what "$id" given twice'));
    }
  }

  /// The letter's lines as the game reads a note (blank lines left out).
  static List<String> letterLines(String? letter) => [
    for (final l in (letter ?? '').split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];

  /// A number put in on the keypad (`number_entry`, `numberCode`): digits
  /// only, as many as its code's length; a time (`codeFormat: time`) four,
  /// hours and minutes of a clock. Whether the number is read in the case is
  /// the planner's (`english_check`) and, in a historical season, the
  /// dossier's (`history_answer_unshown`).
  static void _numberCode(MissionPlan m, String at, List<PlayIssue> out) {
    final p = m.puzzle;
    if (p.paletteId != 'number_entry') return;
    final a = p.answerSpec;
    final pa = '$at.puzzle.answerSpec';
    if (p.missionType != 'numberCode') out.add(PlayIssue('play_range', '$at.puzzle.missionType', '${p.missionType}: a number on the keypad is a numberCode'));
    if (!RegExp(r'^[0-9]+$').hasMatch(a.answer)) {
      out.add(PlayIssue('number_answer_invalid', '$pa.answer', '"${a.answer}": the keypad puts in digits only'));
      return;
    }
    if (a.codeLength == null) {
      out.add(PlayIssue('play_field_missing', '$pa.codeLength', 'missing: how many digits the keypad takes'));
    } else if (a.codeLength != a.answer.length) {
      out.add(PlayIssue('number_answer_invalid', '$pa.codeLength', '${a.codeLength}, but the answer has ${a.answer.length} digits'));
    }
    if (a.codeFormat == 'time') {
      final ok = a.answer.length == 4 && int.parse(a.answer.substring(0, 2)) < 24 && int.parse(a.answer.substring(2)) < 60;
      if (!ok) out.add(PlayIssue('number_answer_invalid', '$pa.answer', '"${a.answer}": a time is four digits, HHMM'));
    }
    if (a.options.isNotEmpty) out.add(PlayIssue('play_range', '$pa.options', 'a keypad shows no options'));
    for (final k in m.play?.feedback.keys ?? const <String>[]) {
      if (!RegExp(r'^[0-9]+$').hasMatch(k)) out.add(PlayIssue('play_range', '$at.play.feedback.$k', 'a wrong number\'s line is keyed by the digits put in'));
    }
  }

  /// A place read for its traces (`trace_deduction`, table `deductions`):
  /// its picture measured; every trace's note a line of the letter, word for
  /// word; its places the options, one each; the guide on no trace and no
  /// place (it shows how to look, never where).
  static void _traces(MissionPlan m, String at, String root, List<PlayIssue> out) {
    final s = m.play?.traces;
    if (s == null || m.puzzle.engineTable != 'deductions') return;
    final sa = '$at.play.traces';
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    if (m.puzzle.missionType != 'multipleChoice') issue('play_range', '$at.puzzle.missionType', '${m.puzzle.missionType}: a place chosen is a multipleChoice');
    _scenePicture('$sa.picture', s.picture, root, out);
    _spot('$sa.guideAt', s.picture, s.guideAt, out);
    for (final (k, r) in [('inside', s.inside), ('opening', s.opening)]) {
      if (r != null) _areas('$sa.$k', s.picture, [r], out);
    }
    if (s.clues.length < 2 || s.clues.length > 5) issue('scene_invalid', '$sa.clues', '${s.clues.length} trace(s): 2 to 5, each pointing the same way');
    _uniqueIds('$sa.clues', [for (final c in s.clues) c.id], 'trace', out);
    final lines = letterLines(m.play!.letter);
    for (final (i, c) in s.clues.indexed) {
      _areas('$sa.clues[$i].areas', s.picture, c.areas, out);
      _spot('$sa.clues[$i].mark', s.picture, c.mark, out);
      if (!lines.contains(c.line.trim())) issue('scene_text_mismatch', '$sa.clues[$i].line', 'not a line of the letter, word for word: the traces are the detective\'s notes');
    }
    for (final (i, o) in s.others.indexed) {
      _areas('$sa.others[$i].areas', s.picture, o.areas, out);
    }
    _uniqueIds('$sa.places', [for (final p in s.places) p.optionId], 'place', out);
    final options = {for (final o in m.puzzle.answerSpec.options) o.id};
    final chosen = {for (final p in s.places) p.optionId};
    if (!(chosen.length == options.length && chosen.containsAll(options))) {
      issue('scene_answer_mismatch', '$sa.places', 'places for ${chosen.join(', ')}, but the options are ${options.join(', ')}');
    }
    for (final (i, p) in s.places.indexed) {
      _areas('$sa.places[$i].areas', s.picture, p.areas, out);
      _spot('$sa.places[$i].mark', s.picture, p.mark, out);
    }
    if (_inAny(s.guideAt, [for (final c in s.clues) ...c.areas, for (final p in s.places) ...p.areas])) {
      issue('scene_invalid', '$sa.guideAt', 'on a trace or a place: the first ripple shows how to look, never where');
    }
  }

  /// Exhibits under the glass (`lens_inspect_word`, table `inspections`):
  /// one exhibit the letter describes (`match`) and its label (`label`,
  /// opened by the match); every line of the letter but the one to answer
  /// ([InspectPlan.taskLine]) confirmed by something examined, that line
  /// by nothing (the typed word answers it); the answer a word.
  static void _inspect(MissionPlan m, String at, String root, List<PlayIssue> out) {
    final s = m.play?.inspect;
    if (s == null || m.puzzle.engineTable != 'inspections') return;
    final sa = '$at.play.inspect';
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    if (m.puzzle.missionType != 'wordInput') issue('play_range', '$at.puzzle.missionType', '${m.puzzle.missionType}: the label\'s word is a wordInput');
    _scenePicture('$sa.picture', s.picture, root, out);
    _spot('$sa.lensAt', s.picture, s.lensAt, out);
    if (s.inside case final r?) _areas('$sa.inside', s.picture, [r], out);
    _uniqueIds('$sa.spots', [for (final x in s.spots) x.id], 'spot', out);
    final ids = {for (final x in s.spots) x.id};
    for (final kind in ['match', 'label']) {
      final n = s.spots.where((x) => x.kind == kind).length;
      if (n != 1) issue('scene_invalid', '$sa.spots', '$n spots of kind $kind: one ${kind == 'match' ? 'exhibit the letter describes' : 'label, where the word is written'}');
    }
    final lines = letterLines(m.play!.letter);
    if (s.taskLine >= lines.length) issue('scene_invalid', '$sa.taskLine', 'line ${s.taskLine}, but the letter has ${lines.length} lines');
    final confirmed = <int>{};
    for (final (i, x) in s.spots.indexed) {
      final xa = '$sa.spots[$i]';
      _areas('$xa.areas', s.picture, x.areas, out);
      for (final c in x.checks) {
        if (c >= lines.length) issue('scene_invalid', '$xa.checks', 'line $c, but the letter has ${lines.length} lines');
        if (c == s.taskLine) issue('scene_invalid', '$xa.checks', 'line $c is the one the typed word answers: nothing examined confirms it');
      }
      confirmed.addAll(x.checks);
      if (x.requires case final need?) {
        if (!ids.contains(need) || need == x.id) issue('scene_invalid', '$xa.requires', '"$need" is no other spot of the scene');
        if (x.lockedLine == null) issue('play_field_missing', '$xa.lockedLine', 'missing: what the glass shows before "$need" is examined');
      }
      if (x.kind == 'label' && x.requires != s.spots.where((y) => y.kind == 'match').firstOrNull?.id) {
        issue('scene_invalid', '$xa.requires', 'the label opens once its exhibit (the match) is examined');
      }
    }
    for (var l = 0; l < lines.length; l++) {
      if (l != s.taskLine && !confirmed.contains(l)) issue('scene_invalid', '$sa.spots', 'line $l of the letter ("${lines[l]}") is confirmed by nothing examined');
    }
    if (_inAny(s.lensAt, [for (final x in s.spots) ...x.areas])) issue('scene_invalid', '$sa.lensAt', 'over a spot: the glass waits on nothing');
    if (!RegExp(r"^[A-Za-z][A-Za-z' -]*$").hasMatch(m.puzzle.answerSpec.answer)) {
      issue('play_range', '$at.puzzle.answerSpec.answer', '"${m.puzzle.answerSpec.answer}": the label\'s missing word is a word');
    }
  }

  /// Two records compared (`record_mismatch`, table `records`): both
  /// pictures on disk, the sheets' corners and the parts shown on them,
  /// every line a row; the options the lines the records share (by id, in
  /// the first record's order), and exactly one of them disagreeing — the
  /// answer `<id>:<id>`.
  static void _records(MissionPlan m, String at, String root, List<PlayIssue> out) {
    final s = m.play?.records;
    if (s == null || m.puzzle.engineTable != 'records') return;
    final sa = '$at.play.records';
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    if (m.puzzle.missionType != 'matchPairs') issue('play_range', '$at.puzzle.missionType', '${m.puzzle.missionType}: a pair of lines picked is a matchPairs');
    if (s.first.id == s.second.id) issue('scene_invalid', '$sa.second.id', 'the two records share the id "${s.first.id}"');
    for (final (k, d) in [('first', s.first), ('second', s.second)]) {
      final da = '$sa.$k';
      // The words are the app's, written on the blank: corners measured on the drawn file.
      _scenePicture('$da.picture', d.picture, root, out);
      _areas('$da.crop', d.picture, [d.crop], out);
      for (final (i, c) in d.sheet.corners.indexed) {
        _spot('$da.sheet.corners[$i]', d.picture, c, out);
      }
      final sh = d.sheet;
      if (sh.rows.length < d.lines.length) issue('scene_invalid', '$da.sheet.rows', '${sh.rows.length} rows for ${d.lines.length} lines: a row each');
      final (fw, fh) = sh.flat;
      final inFlat = [sh.title.left, sh.title.right, sh.labelLeft, sh.labelRight, sh.valueLeft, sh.valueRight].every((x) => x <= fw) &&
          [sh.title.top, sh.title.bottom, ...sh.rows.map((r) => r + sh.rowHeight)].every((y) => y <= fh);
      if (!inFlat || sh.labelLeft >= sh.labelRight || sh.valueLeft >= sh.valueRight || sh.labelRight > sh.valueLeft) {
        issue('scene_area_invalid', '$da.sheet', 'its title, rows and columns lie inside the sheet face on (${fw}x$fh), label before value');
      }
      _uniqueIds('$da.lines', [for (final l in d.lines) l.id], 'line', out);
    }
    final second = {for (final l in s.second.lines) l.id: l};
    final shared = [for (final l in s.first.lines) if (second.containsKey(l.id)) l];
    final options = [for (final o in m.puzzle.answerSpec.options) o.id];
    if (options.join(',') != [for (final l in shared) l.id].join(',')) {
      issue('scene_answer_mismatch', '$at.puzzle.answerSpec.options', 'one option per line both records have, in the first record\'s order (${[for (final l in shared) l.id].join(', ')})');
    }
    String norm(String v) => v.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
    final differ = [for (final l in shared) if (norm(l.value) != norm(second[l.id]!.value)) l.id];
    if (differ.length != 1) {
      issue('records_ambiguous', sa, '${differ.isEmpty ? 'no line' : differ.join(', ')} disagree${differ.length == 1 ? 's' : ''}: exactly one pair of lines answers it');
    } else if (m.puzzle.answerSpec.answer != '${differ.single}:${differ.single}') {
      issue('scene_answer_mismatch', '$at.puzzle.answerSpec.answer', '"${m.puzzle.answerSpec.answer}", but the lines that disagree are ${differ.single}:${differ.single}');
    }
  }

  /// A talk in which evidence is shown (`evidence_talk`, table `talks`):
  /// with a person of the case; its steps' ids its own and none the
  /// opening's; what opens a step and what finishes it steps of the talk;
  /// every piece asked for evidence the detective holds by then (of this
  /// case before this mission, or of a case before it), a piece offered as
  /// a card among them; the answer the talk's own (an examine).
  static void _interview(CasePlan plan, MissionPlan m, String at, String root, List<PlayIssue> out) {
    final s = m.play?.interview;
    if (s == null || m.puzzle.engineTable != 'talks') return;
    final sa = '$at.play.interview';
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    if (m.puzzle.missionType != 'examine') issue('play_range', '$at.puzzle.missionType', '${m.puzzle.missionType}: a talk is played as an examine');
    if (!plan.characters.contains(s.speaker)) issue('play_story_person', '$sa.speaker', '"${s.speaker}" is not a character of the case (characters)');
    if (s.portrait case final f? when !File('$root/$f').existsSync()) {
      out.add(PlayIssue(storyPictureMissing, '$sa.portrait', '$f is not on disk: shown with no face until it is made', blocking: false));
    }
    final steps = [for (final q in s.questions) q.id, for (final p in s.presents) p.id];
    _uniqueIds(sa, steps, 'step', out);
    if (steps.contains('opening')) issue('scene_invalid', sa, '"opening" is the talk\'s opening, never a step');
    for (final id in s.finishWhen) {
      if (!steps.contains(id)) issue('scene_invalid', '$sa.finishWhen', '"$id" is no step of the talk');
    }
    for (final p in s.presents) {
      if (!s.finishWhen.contains(p.id)) issue('scene_invalid', '$sa.finishWhen', '"${p.id}" is evidence asked for: the talk finishes once it is shown');
    }
    final held = <String>{};
    final numbers = PlanIds.caseNumbers(plan.caseId);
    for (final x in plan.allMissions) {
      if (x.missionId == m.missionId) break;
      held.add(x.clueOutputs.evidence);
    }
    bool holds(String e) {
      if (held.contains(e)) return true;
      final of = PlanIds.caseNumbers(PlanIds.caseOfChild(e) ?? '');
      return numbers != null && of != null && of.$1 == numbers.$1 && of.$2 < numbers.$2;
    }

    void requires(String path, List<String> ids) {
      for (final id in ids) {
        if (!steps.contains(id)) issue('scene_invalid', path, '"$id" is no step of the talk');
      }
    }

    for (final (i, q) in s.questions.indexed) {
      requires('$sa.questions[$i].requires', q.requires);
    }
    for (final (i, p) in s.presents.indexed) {
      final pa = '$sa.presents[$i]';
      requires('$pa.requires', p.requires);
      for (final e in p.accepted) {
        if (!holds(e)) issue('talk_evidence_unheld', '$pa.accepted', '$e is not in the notebook by ${m.missionId}: evidence of an earlier mission or case');
      }
      if (p.offered.isNotEmpty) {
        if (p.offered.length != 2) issue('scene_invalid', '$pa.offered', '${p.offered.length} card(s): two to pick from');
        if (!p.offered.any(p.accepted.contains)) issue('scene_answer_mismatch', '$pa.offered', 'none of the cards is the evidence asked for');
        for (final e in p.offered) {
          if (!holds(e)) issue('talk_evidence_unheld', '$pa.offered', '$e is not in the notebook by ${m.missionId}');
        }
      } else if (p.tell != null) {
        issue('play_range', '$pa.tell', 'said over the cards: a present with no cards (offered) has none');
      }
    }
  }

  /// The story around [m]'s puzzle (STEP 3-13B), each part optional: the
  /// talks before and after a mission's puzzle with a person of the case,
  /// its own Discovery Moment (the game's timing rule: what was seen before
  /// the puzzle is never "found"), a final's ending. Each only where its
  /// page plays it.
  static void _aroundPuzzle(CasePlan plan, MissionPlan m, String at, String root, List<PlayIssue> out) {
    void issue(String code, String path, String message) => out.add(PlayIssue(code, path, message));
    final w = m.play!;
    final pa = '$at.play';
    final people = plan.characters.toSet();

    void person(String path, String id) {
      if (!people.contains(id)) issue('play_story_person', path, '"$id" is not a character of the case (characters)');
    }

    // A face is the story's, never the puzzle's (STEP 3-15A): one not made
    // yet is reported, and the line is written without it.
    void portrait(String path, String? f) {
      if (f != null && !File('$root/$f').existsSync()) {
        out.add(PlayIssue(storyPictureMissing, path, '$f is not on disk: shown with no face until it is made', blocking: false));
      }
    }

    if (w.talk case final t?) {
      final ta = '$pa.talk';
      if (m.isFinal) {
        issue('play_range', ta, "a final's page has no talk around its puzzle (its words after the answer are its ending)");
      } else if (t.before == null && t.after == null) {
        issue('play_field_missing', ta, 'missing: a talk before the puzzle, after it, or both');
      }
      person('$ta.speaker', t.speaker);
      portrait('$ta.portrait', t.portrait);
    }

    if (w.discovery case final d?) {
      final da = '$pa.discovery';
      if (m.isFinal) issue('play_range', da, "a final has no Discovery Moment (its page opens the case's own lock)");
      if (d.detail == d.title) issue('play_range', '$da.detail', 'says its title again: why it matters, or where it leads');
      if (d.note != null && d.note == d.detail) issue('play_range', '$da.note', 'says the detail again');
      final before = d.timingOrDefault == 'beforePuzzle';
      if (before && (d.type == 'evidenceFound' || d.type == 'clueFound')) {
        issue('play_range', '$da.type', 'what was seen before the puzzle is confirmed or noted, never found');
      }
      if (before && d.showEvidence == true) issue('play_range', '$da.showEvidence', 'evidence held before the puzzle is never laid out as new');
      if (d.type == 'evidenceFound' && (d.timingOrDefault != 'fromPuzzle' || d.showEvidence != true)) {
        issue('play_range', '$da.type', 'evidence found is found by the puzzle (timing fromPuzzle) and shown (showEvidence)');
      }
      final words = w.evidence?.inscription;
      if (d.showEvidence == true && words != null && d.detail.contains(words)) {
        issue('play_range', '$da.detail', 'says what the evidence card shows');
      }
    }

    if (w.ending.isNotEmpty) {
      if (!m.isFinal) issue('play_range', '$pa.ending', 'a mission has no ending (the person reacts in its talk after)');
      final numbers = PlanIds.caseNumbers(plan.caseId);
      for (final (i, l) in w.ending.indexed) {
        final la = '$pa.ending[$i]';
        if (l.by == TalkBy.speaker) {
          if (l.speaker case final s?) {
            person('$la.speaker', s);
          } else {
            issue('play_field_missing', '$la.speaker', "missing: who says a speaker's line");
          }
        } else {
          if (l.speaker != null) issue('play_range', '$la.speaker', "a ${l.by.name}'s line names no speaker");
          if (l.portrait != null) issue('play_range', '$la.portrait', "a ${l.by.name}'s line shows no face");
        }
        portrait('$la.portrait', l.portrait);
        // Evidence the detective holds by then: of this case, or one before it.
        if (l.evidence case final e?) {
          final of = PlanIds.caseNumbers(PlanIds.caseOfChild(e) ?? '');
          if (numbers == null || of == null || of.$1 != numbers.$1 || of.$2 > numbers.$2) {
            issue('play_range', '$la.evidence', '$e is not evidence of ${plan.caseId} or a case before it');
          } else if (of.$2 == numbers.$2 && !{for (final x in plan.allMissions) x.clueOutputs.evidence}.contains(e)) {
            issue('play_range', '$la.evidence', '$e is no evidence of ${plan.caseId}');
          }
        }
      }
    }
  }

  /// Every picture file [m] shows beyond its place's, with where the plan
  /// names it (its JSON path from the mission, `.play.explore.picture.file`):
  /// its scene's pictures (the one its engine table reads) and its options'.
  static List<(String, String)> pictureFiles(MissionPlan m) => [...puzzlePictureFiles(m), ...storyPictureFiles(m)];

  /// The pictures [m]'s puzzle cannot be played without (STEP 3-15A): its
  /// scene, its choices, its witnesses. Asked for in `assetNeeds`; one not
  /// on disk stops the generator (`asset_file_missing`).
  static List<(String, String)> puzzlePictureFiles(MissionPlan m) {
    final w = m.play;
    return [
      for (final (i, o) in m.puzzle.answerSpec.options.indexed)
        if (o.picture case final f?) ('.puzzle.answerSpec.options[$i].picture', f),
      if (w?.explore case final s? when m.puzzle.engineTable == 'explores') ...[
        ('.play.explore.picture.file', s.picture.file),
        for (final (i, c) in s.choices.indexed) ('.play.explore.choices[$i].picture', c.picture),
      ],
      if (w?.search case final s? when m.puzzle.engineTable == 'investigations') ...[
        ('.play.search.picture.file', s.picture.file),
        for (final (i, f) in s.finds.indexed) ('.play.search.finds[$i].picture.file', f.picture.file),
      ],
      if (w?.dialogue case final s? when m.puzzle.engineTable == 'dialogues') ...[
        ('.play.dialogue.background', s.background),
        for (final (i, x) in s.witnesses.indexed) ('.play.dialogue.witnesses[$i].portrait', x.portrait),
      ],
      if (w?.traces case final s? when m.puzzle.engineTable == 'deductions') ('.play.traces.picture.file', s.picture.file),
      if (w?.inspect case final s? when m.puzzle.engineTable == 'inspections') ('.play.inspect.picture.file', s.picture.file),
      if (w?.records case final s? when m.puzzle.engineTable == 'records') ...[
        ('.play.records.first.picture.file', s.first.picture.file),
        ('.play.records.second.picture.file', s.second.picture.file),
      ],
    ];
  }

  /// The faces of the story around [m]'s puzzle (STEP 3-13B): its talk's and
  /// its ending's. The puzzle plays without them (STEP 3-15A), so they are
  /// not its `assetNeeds`; one not on disk is `story_picture_missing`.
  static List<(String, String)> storyPictureFiles(MissionPlan m) {
    final w = m.play;
    return [
      if (w?.talk?.portrait case final f?) ('.play.talk.portrait', f),
      if (w?.interview?.portrait case final f? when m.puzzle.engineTable == 'talks') ('.play.interview.portrait', f),
      for (final (i, l) in (w?.ending ?? const <EndingLinePlan>[]).indexed)
        if (l.portrait case final f?) ('.play.ending[$i].portrait', f),
    ];
  }

  /// A picture file's width and height (PNG, or the game's WebP or JPEG,
  /// read whole), or null when it is not a valid picture.
  static (int, int)? imageSize(File f) {
    try {
      final info = ImageFileCheck.file(f.path);
      return (info.width, info.height);
    } on ImageFileProblem {
      return null;
    }
  }
}
