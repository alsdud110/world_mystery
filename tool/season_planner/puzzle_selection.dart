import '../season_gen/palette_facts.dart';
import '../season_gen/plan_models.dart';
import '../season_gen/play_check.dart';

/// What a mission's case material is about, as [PuzzleSelector] reads it.
enum PuzzleTrait {
  /// When things happened, in what order (years, before / after).
  chronology,

  /// Two papers of the same thing (a record, a log, a notice) to set side by side.
  documents,

  /// What people said (a witness, a claim) to weigh.
  testimony,

  /// Marks left at the place (footprints, scratches, something hidden).
  scene,

  /// Words written on a thing (a label, an inscription, a plaque).
  inscription,

  /// Who did what with whom, which thing is whose (people, places, evidence linked).
  relations,

  /// A number to put in, read in the words (a time or a year alone is not:
  /// they are said in most cases).
  number,
}

/// One trait found: its cue words, and whether the player reads them by
/// then ([shown]: in the mission's own words) or only the dossier's facts
/// say them (never enough to choose a puzzle on: history the player was
/// never told is memory, not deduction).
class TraitFound {
  const TraitFound(this.trait, this.cues, {required this.shown});

  final PuzzleTrait trait;
  final List<String> cues;
  final bool shown;

  Map<String, Object?> toJson() => {'trait': trait.name, 'cues': cues, 'from': shown ? 'words' : 'factsOnly'};
}

/// A puzzle considered for a mission: its score and why.
class Candidate {
  const Candidate(this.paletteId, this.score, this.why);

  final String paletteId;
  final int score;
  final String why;

  Map<String, Object?> toJson() => {'paletteId': paletteId, 'score': score, 'why': why};
}

/// The selector's answer for one mission.
class MissionSelection {
  const MissionSelection({
    required this.caseId,
    required this.missionId,
    required this.surface,
    required this.traits,
    required this.factIds,
    required this.candidates,
    required this.selected,
    required this.reason,
    required this.planned,
  });

  final String caseId;
  final String missionId;
  final PlanSurface surface;
  final List<TraitFound> traits;
  final List<String> factIds;
  final List<Candidate> candidates;

  /// Null: no puzzle the generator makes fits (reported, never picked at random).
  final String? selected;
  final String reason;

  /// The plan's own choice.
  final String? planned;

  Map<String, Object?> toJson() => {
    'caseId': caseId,
    'missionId': missionId,
    'surface': surface.name,
    'traits': [for (final t in traits) t.toJson()],
    'factIds': factIds,
    'candidates': [for (final c in candidates) c.toJson()],
    'selected': selected,
    'reason': reason,
    'planned': planned,
    'plannedIsSelected': planned != null && planned == selected,
  };
}

/// Chooses a puzzle for each mission of a historical season by rules, never
/// by chance (Puzzle Engine 2.0 STEP 1): the traits its words show, the
/// puzzles each trait calls for — only those the generator makes and the
/// page can play ([PlayCheck.generatable], the palette's surfaces) — then
/// the season's variety (one kind at most once a case, a third of the
/// season at most, never the same kind in the same place of the case
/// before). Ties keep [_order]. The plan's own choice is compared with it;
/// Claude writes the plan, the selector proposes and reports.
abstract final class PuzzleSelector {
  /// Where a historical season keeps the selection (written by `plan_season check`).
  static const fileName = 'planning/puzzle_selection.json';

  /// Each trait's puzzles, best first. `deduction_board` (an evidence
  /// board for relations) is not made by the generator yet: relations are
  /// shown as evidence to a person, or two witnesses compared.
  static const byTrait = <PuzzleTrait, List<String>>{
    PuzzleTrait.chronology: ['timeline_board', 'order_sequence'],
    PuzzleTrait.documents: ['record_mismatch', 'text_choice'],
    PuzzleTrait.testimony: ['witness_compare', 'evidence_talk'],
    PuzzleTrait.scene: ['trace_deduction', 'dark_room_search', 'scene_explore_choose'],
    PuzzleTrait.inscription: ['lens_inspect_word', 'word_entry'],
    PuzzleTrait.relations: ['evidence_talk', 'witness_compare'],
    PuzzleTrait.number: ['number_entry', 'combo_dial_lock'],
  };

  /// Puzzles played with the hands (CLAUDE.md §20: one a case at least).
  static const handsOn = {
    'timeline_board', 'order_sequence', 'record_mismatch', 'trace_deduction', 'dark_room_search', 'scene_explore_choose', //
    'lens_inspect_word', 'letter_tile_lock', 'combo_dial_lock', 'number_entry', 'syllable_compose',
  };

  static const plainChoice = 'text_choice';

  /// The tie-break order: the palette's.
  static final _order = [for (final p in PaletteFacts.all) p.id];

  static final _year = RegExp(r'(?<![0-9])(1[0-9]{3}|20[0-9]{2})(?![0-9])');

  /// Each trait's cue words (whole words, any case). A trait counts with
  /// [_least] cues or more.
  static final _cues = <PuzzleTrait, RegExp>{
    PuzzleTrait.chronology: RegExp(r'\b(before|after|then|first|later|earlier|next|finally|until|since|years? later|the year)\b', caseSensitive: false),
    PuzzleTrait.documents: RegExp(r'\b(records?|logs?|register|notices?|ledgers?|copy|copies|documents?|reports?|lists?|does not match|do not match|differ(?:ent|s)?)\b', caseSensitive: false),
    PuzzleTrait.testimony: RegExp(r'\b(said|says|told|claims?|claimed|witness(?:es)?|saw|heard|answered|swears?)\b', caseSensitive: false),
    PuzzleTrait.scene: RegExp(r'\b(footprints?|marks?|traces?|scratch(?:es)?|hidden|stains?|mud|muddy|behind|underneath)\b', caseSensitive: false),
    PuzzleTrait.inscription: RegExp(r'\b(labels?|inscriptions?|carved|engraved|plaques?|written on|signs?)\b', caseSensitive: false),
    PuzzleTrait.relations: RegExp(r'\b(wrote|owner|belongs?|belonged|gave|sent|took|whose|who)\b', caseSensitive: false),
    PuzzleTrait.number: RegExp(r'\b(how many|number|count|times|hundred|thousand|twenty|thirty|forty|fifty)\b', caseSensitive: false),
  };

  static const _least = {
    PuzzleTrait.chronology: 2,
    PuzzleTrait.documents: 2,
    PuzzleTrait.testimony: 2,
    PuzzleTrait.scene: 2,
    PuzzleTrait.inscription: 1,
    PuzzleTrait.relations: 2,
    PuzzleTrait.number: 1,
  };

  /// The words the player reads in [m] before its puzzle: its story, its
  /// letter and its question (never its puzzle's own scene, which follows
  /// the choice).
  static String wordsOf(MissionPlan m) {
    final w = m.play;
    if (w == null) return '';
    return [...w.story, ?w.letterIntro, ?w.letter, ?w.question].join('\n');
  }

  /// The traits of [words] (and of [facts], the statements of the facts
  /// the mission rests on, recorded but never chosen on alone).
  static List<TraitFound> traitsOf(String words, String facts) {
    List<String> cues(PuzzleTrait t, String text) {
      final out = <String>{for (final m in _cues[t]!.allMatches(text)) m[0]!.toLowerCase()};
      if (t == PuzzleTrait.chronology) out.addAll({for (final m in _year.allMatches(text)) m[1]!});
      return out.toList()..sort();
    }

    return [
      for (final t in PuzzleTrait.values)
        if (cues(t, words) case final c when c.length >= _least[t]!)
          TraitFound(t, c, shown: true)
        else if (cues(t, facts) case final c when c.length >= _least[t]!)
          TraitFound(t, c, shown: false),
    ];
  }

  /// Every mission of [plans] (in play order), each chosen after the ones
  /// before it. [facts]: mission id → the dossier's facts it rests on (id → statement).
  static List<MissionSelection> select(List<CasePlan> plans, {Map<String, Map<String, String>> facts = const {}}) {
    final total = [for (final p in plans) ...p.allMissions].length;
    final cap = (total / 3).ceil();
    final used = <String, int>{};
    final out = <MissionSelection>[];
    List<String?> before = const [];
    for (final c in plans) {
      final mine = <String?>[];
      for (final (i, m) in c.allMissions.indexed) {
        final surface = m.isFinal ? PlanSurface.finalMission : PlanSurface.mission;
        final f = facts[m.missionId] ?? const {};
        final traits = traitsOf(wordsOf(m), f.values.join('\n'));
        final shown = [for (final t in traits) if (t.shown) t.trait];
        final scores = <String, int>{};
        final why = <String, List<String>>{};
        for (final t in shown) {
          // Ranked among those this page plays (a first choice it cannot play moves the next up).
          final playable = [
            for (final id in byTrait[t]!)
              if (PlayCheck.generatable.containsKey(id) && (PaletteFacts.lookup(id)?.supports(surface) ?? false)) id,
          ];
          for (final (rank, id) in playable.indexed) {
            scores[id] = (scores[id] ?? 0) + 10 - 3 * rank;
            (why[id] ??= []).add('${t.name}${rank == 0 ? '' : ' (second choice)'}');
          }
        }
        final candidates = <Candidate>[];
        for (final id in scores.keys) {
          var s = scores[id]!;
          final notes = [...why[id]!];
          // CLAUDE.md §20: a plain choice only when nothing more hands-on fits as well.
          if (id == plainChoice) {
            s -= 2;
            notes.add('a plain choice');
          }
          if (mine.contains(id)) {
            s -= 8;
            notes.add('already in this case');
          }
          if ((used[id] ?? 0) >= cap) {
            s -= 8;
            notes.add('a third of the season already');
          }
          if (i < before.length && before[i] == id) {
            s -= 4;
            notes.add('the same place of the case before');
          }
          candidates.add(Candidate(id, s, notes.join('; ')));
        }
        candidates.sort((a, b) => b.score != a.score ? b.score - a.score : _order.indexOf(a.paletteId) - _order.indexOf(b.paletteId));
        final best = candidates.firstOrNull;
        final selected = best != null && best.score > 0 ? best.paletteId : null;
        final hidden = [for (final t in traits) if (!t.shown) t.trait.name];
        final reason = selected == null
            ? (shown.isEmpty
                ? 'no trait its words show${hidden.isEmpty ? '' : ' (the facts alone say ${hidden.join(', ')}: never chosen on what the player is not told)'}: write the clue into the case, or choose by hand and say why'
                : 'the puzzles its words call for (${shown.map((t) => t.name).join(', ')}) are none the generator makes on this page, or all are used up')
            : '${best!.why}${hidden.isEmpty ? '' : ' (not chosen on the facts alone: ${hidden.join(', ')})'}';
        if (selected != null) used[selected] = (used[selected] ?? 0) + 1;
        mine.add(selected);
        out.add(MissionSelection(
          caseId: c.caseId,
          missionId: m.missionId,
          surface: surface,
          traits: traits,
          factIds: f.keys.toList()..sort(),
          candidates: candidates,
          selected: selected,
          reason: reason,
          planned: m.puzzle.paletteId,
        ));
      }
      before = mine;
    }
    return out;
  }

  /// What a person still reads for a puzzle of [paletteId] (the checks
  /// hold its data; whether it is fair to a child is a reading).
  static String reviewOf(String? paletteId) => switch (paletteId) {
    'timeline_board' => 'whether the lines read put the cards in one order',
    'trace_deduction' => 'whether every trace points to the one place, and no other place fits',
    'lens_inspect_word' => 'whether the letter describes one exhibit only, and the word is guessed from its meaning',
    'record_mismatch' => 'whether the lines that differ are a contradiction worth finding',
    'evidence_talk' => 'whether the evidence asked for is the only piece that answers each prompt',
    'number_entry' => 'whether the number is read in the words, never known beforehand',
    'witness_compare' => 'whether only the two statements agree on the thing',
    'syllable_compose' => 'whether each group\'s words build one vowel only, and the note reads as words',
    _ => 'whether the words lead to the answer, and only to it',
  };
}
