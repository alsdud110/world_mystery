import 'dart:convert';

import '../../data/models/difficulty.dart';

/// Puzzle Engine 2.0's rules (`docs/PUZZLE_ENGINE_V2_PART3_DESIGN.md` §3):
/// what a puzzle is made of (its spec), where the detective has got to (its
/// state), and every move in between — in plain Dart, no Flutter, so the
/// game's widgets and the season tools (`dart run`) play by the very same
/// rules. Nothing here judges, rewards or saves: the page sends
/// [PuzzleRules.answerOf] to `GameController.submitAnswer` (judged by
/// `AnswerChecker`, paid once a mission), and saves [PuzzleSession.saved]
/// with `GameController.recordPuzzleState`, as every engine before it.
abstract class PuzzleRules<Spec, State, Action> {
  const PuzzleRules();

  /// The puzzle's kind, in its saved states (`timeline`).
  String get kind;

  /// The shape of [stateToJson]: a saved state of another version starts
  /// the puzzle afresh.
  int get stateVersion;

  /// What is wrong with [spec] (empty: it can be played).
  List<SpecIssue> validate(Spec spec);

  /// How the puzzle opens.
  State initial(Spec spec);

  /// [action] played on [state]. A move the puzzle does not allow is
  /// [Applied.rejected], [state] unchanged: never an exception.
  Applied<State> apply(Spec spec, State state, Action action);

  /// Everything is in place: the answer can be checked.
  bool isComplete(Spec spec, State state);

  /// What [state] answers, as the mission's `answer` is written.
  String answerOf(Spec spec, State state);

  /// The right answer, as the mission's `answer` is written.
  String answer(Spec spec);

  /// The puzzle as it is once solved: what a solved mission shows when it
  /// is opened again.
  State solved(Spec spec);

  Object? stateToJson(State state);

  /// [json] as a state of [spec], or null when it is none (another spec,
  /// an older shape, a hand-edited save): the puzzle then starts afresh.
  State? stateFromJson(Spec spec, Object? json);

  /// What is the same at every level: ids, places, the answer — never words.
  Object? structure(Spec spec);

  /// The words of [spec] by where they are: each level writes its own.
  Map<String, String> texts(Spec spec);

  /// The ids of the puzzle's own parts, with where each is.
  List<(String, String)> elementIds(Spec spec);
}

/// What is wrong with a spec: its kind ([code]), where, and why.
class SpecIssue {
  const SpecIssue(this.code, this.path, this.message);

  final String code;
  final String path;
  final String message;

  SpecIssue at(String prefix) => SpecIssue(code, '$prefix.$path', message);

  @override
  String toString() => '[$code] $path: $message';
}

/// A move the puzzle does not allow, and why (for the page to say, or to
/// ignore).
class Rejection {
  const Rejection(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '[$code] $message';
}

/// A move played: the state after it, or the state as it was and why not.
class Applied<S> {
  const Applied.accepted(this.state) : rejection = null;
  const Applied.rejected(this.state, Rejection this.rejection);

  final S state;
  final Rejection? rejection;

  bool get accepted => rejection == null;
}

/// A puzzle's state as `GameProgress.puzzleStates` keeps it, by mission id:
/// `pv2:<kind>:<version>:<json>`. Any other string — another engine's, an
/// older version, a broken one — reads as nothing, and the puzzle starts
/// afresh (the contract every engine's `decode` keeps).
abstract final class PuzzleStateCodec {
  static const prefix = 'pv2';

  static String encode<Spec, S>(PuzzleRules<Spec, S, dynamic> rules, S state) =>
      '$prefix:${rules.kind}:${rules.stateVersion}:${jsonEncode(rules.stateToJson(state))}';

  static S? decode<Spec, S>(PuzzleRules<Spec, S, dynamic> rules, Spec spec, String? saved) {
    final head = '$prefix:${rules.kind}:${rules.stateVersion}:';
    if (saved == null || !saved.startsWith(head)) return null;
    try {
      return rules.stateFromJson(spec, jsonDecode(saved.substring(head.length)));
    } on FormatException {
      return null;
    }
  }
}

/// A puzzle being played on a page: its rules, its spec, its state.
/// Immutable: every move gives a new session. A solved mission's session is
/// read-only, laid out as solved — opened again, nothing is played twice.
class PuzzleSession<Spec, S, A> {
  const PuzzleSession._(this.rules, this.spec, this.state, {required this.readOnly, required this.restored});

  /// The session a page opens: solved ([solved], the mission completed) as
  /// [PuzzleRules.solved]; else as [saved] left it, or afresh.
  factory PuzzleSession.open(PuzzleRules<Spec, S, A> rules, Spec spec, {String? saved, bool solved = false}) {
    if (solved) return PuzzleSession._(rules, spec, rules.solved(spec), readOnly: true, restored: false);
    final back = PuzzleStateCodec.decode<Spec, S>(rules, spec, saved);
    return PuzzleSession._(rules, spec, back ?? rules.initial(spec), readOnly: false, restored: back != null);
  }

  final PuzzleRules<Spec, S, A> rules;
  final Spec spec;
  final S state;

  /// The mission is solved: shown, never played.
  final bool readOnly;

  /// Opened as a save left it.
  final bool restored;

  /// [action] played: the session after it, and why not when it was not.
  (PuzzleSession<Spec, S, A>, Rejection?) play(A action) {
    if (readOnly) return (this, const Rejection('solved', 'the mission is solved: its puzzle is shown, not played'));
    final r = rules.apply(spec, state, action);
    return (r.accepted ? PuzzleSession._(rules, spec, r.state, readOnly: false, restored: restored) : this, r.rejection);
  }

  /// What `GameController.recordPuzzleState` keeps.
  String get saved => PuzzleStateCodec.encode<Spec, S>(rules, state);

  bool get complete => rules.isComplete(spec, state);

  /// What `GameController.submitAnswer` is given.
  String get answer => rules.answerOf(spec, state);
}

/// Checks a spec's ids and its levels.
abstract final class PuzzleSpecCheck {
  /// A part's own id: short, lower case, never a plan's id.
  static final elementId = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

  /// The plans' ids — missions, clues, evidence, facts (`s5_ep01_m2`,
  /// `s5_ep01_h1`, …) — all begin with their season: a part's id never does.
  static final _planScoped = RegExp(r'^s[0-9]+_');

  /// What is wrong with [ids] (each with where it is): not an id, given
  /// twice, a plan's id, or one of [reserved] (the season's mission and fact
  /// ids, when known).
  static List<SpecIssue> ids(List<(String, String)> ids, {Set<String> reserved = const {}}) {
    final out = <SpecIssue>[];
    final seen = <String>{};
    for (final (path, id) in ids) {
      if (!elementId.hasMatch(id)) {
        out.add(SpecIssue('id_invalid', path, '"$id": a lower-case id (a-z, 0-9, _), 32 characters at most'));
      } else if (_planScoped.hasMatch(id) || reserved.contains(id)) {
        out.add(SpecIssue('id_reserved', path, '"$id" is a plan\'s id (a mission\'s, a clue\'s, evidence\'s or a fact\'s): a part has its own'));
      }
      if (!seen.add(id)) out.add(SpecIssue('id_duplicate', path, '"$id" is given twice'));
    }
    return out;
  }

  /// What is wrong with a puzzle's [levels]: one at every level, each
  /// playable, its ids sound, and the same game at every level — the same
  /// [PuzzleRules.structure] and answer as Rookie's, every word written.
  static List<SpecIssue> levels<Spec>(PuzzleRules<Spec, dynamic, dynamic> rules, Map<Difficulty, Spec> levels, {Set<String> reserved = const {}}) {
    final out = <SpecIssue>[];
    for (final d in Difficulty.values) {
      if (!levels.containsKey(d)) out.add(SpecIssue('level_missing', d.storageId, 'no ${d.label} puzzle: every level plays it'));
    }
    final rookie = levels[Difficulty.rookie];
    for (final MapEntry(key: d, value: spec) in levels.entries) {
      out.addAll([for (final i in rules.validate(spec)) i.at(d.storageId)]);
      out.addAll([for (final i in ids(rules.elementIds(spec), reserved: reserved)) i.at(d.storageId)]);
      final texts = rules.texts(spec);
      for (final MapEntry(key: path, value: words) in texts.entries) {
        if (words.trim().isEmpty) out.add(SpecIssue('text_missing', '${d.storageId}.$path', 'no words'));
      }
      if (rookie == null || d == Difficulty.rookie) continue;
      if (jsonEncode(rules.structure(spec)) != jsonEncode(rules.structure(rookie))) {
        out.add(SpecIssue('level_changes_game', d.storageId, 'not the same puzzle as Rookie\'s: only the words change with the level'));
      }
      if (rules.answer(spec) != rules.answer(rookie)) {
        out.add(SpecIssue('level_changes_answer', d.storageId, '"${rules.answer(spec)}", Rookie "${rules.answer(rookie)}": every level has the one answer'));
      }
      final paths = rules.texts(rookie).keys.toSet();
      if (texts.keys.toSet().difference(paths).isNotEmpty || paths.difference(texts.keys.toSet()).isNotEmpty) {
        out.add(SpecIssue('level_changes_game', d.storageId, 'its words are not where Rookie\'s are'));
      }
    }
    return out;
  }

  /// What is wrong with [spec] as mission [missionId]'s puzzle whose
  /// `answer` is [missionAnswer]: the puzzle answers what the mission is
  /// checked against.
  static List<SpecIssue> mission<Spec>(PuzzleRules<Spec, dynamic, dynamic> rules, Spec spec, {required String missionId, required String missionAnswer}) => [
    if (rules.answer(spec) != missionAnswer)
      SpecIssue('answer_mismatch', missionId, 'the puzzle answers "${rules.answer(spec)}", the mission is checked against "$missionAnswer"'),
  ];
}
