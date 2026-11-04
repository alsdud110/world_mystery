import 'dart:convert';
import 'dart:io';

import 'case_levels.dart';
import 'plan_files.dart';
import 'plan_models.dart';

/// How a season is made: `planning/brief.json`'s `mode`. No brief, or a
/// brief with no `mode`, is the standard mode, exactly as before the mode
/// existed. A `mode` this tool does not know, or a brief that does not read,
/// is a [FormatException]: a season that may be historical is never taken
/// for a standard one (its checks and its gate would be skipped).
enum SeasonMode {
  standard,

  /// Historical Fiction Mystery: real history, a made-up mystery. Its facts
  /// are kept in `planning/history_dossier.json` ([HistoryDossier]) and
  /// checked automatically before anything is paid for ([HistoryGate]).
  historicalFictionMystery;

  static const historicalName = 'historical_fiction_mystery';
  static const briefPath = 'planning/brief.json';

  static SeasonMode of(String seasonDir) {
    final json = _brief(seasonDir);
    if (json == null || !json.containsKey('mode')) return standard;
    if (json['mode'] == historicalName) return historicalFictionMystery;
    throw FormatException('$briefPath: mode ${jsonEncode(json['mode'])} is not a mode '
        '(leave it out for the standard mode, or "$historicalName")');
  }

  /// The brief of [seasonDir], or null when there is none.
  static Map<dynamic, dynamic>? _brief(String seasonDir) {
    final file = File('$seasonDir/$briefPath');
    if (!file.existsSync()) return null;
    final Object? json;
    try {
      json = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      throw FormatException('$briefPath: not JSON (${e.message})');
    }
    if (json is! Map) throw const FormatException('$briefPath: not an object');
    return json;
  }
}

/// A fact's status as written in the dossier: `source_checked` once its
/// sources are opened and quoted (every source rule then held), the only
/// status a puzzle or reveal may rest on.
enum FactStatus {
  draft('draft'),
  sourceChecked('source_checked'),
  rejected('rejected');

  const FactStatus(this.json);

  final String json;
}

/// What a source is: the first two count as the authoritative one a fact needs.
const sourceKinds = {'primary', 'public_institution', 'academic', 'press', 'other'};
const _authoritative = {'primary', 'public_institution'};

/// One thing the dossier check found. [pending]: allowed while planning, but
/// it stops the paid steps (a fact still a draft) or the game (a level not
/// written).
enum HistoryLevel { error, pending }

class HistoryIssue {
  const HistoryIssue(this.level, this.code, this.where, this.message, {this.target});

  final HistoryLevel level;
  final String code;
  final String where;
  final String message;

  /// The fact, case (of a reveal) or mission (of a puzzle) it is about.
  final String? target;

  @override
  String toString() => '[$code] $where: $message';
}

/// A fact with its status as written.
class HistoryFactState {
  const HistoryFactState(this.json, this.written);

  final Map<dynamic, dynamic> json;
  final FactStatus? written;

  String get factId => json['factId'] as String;

  /// Its sources checked: a ground for puzzles and reveals.
  bool get checked => written == FactStatus.sourceChecked;
}

/// After a solve: what is real (checked facts) and what the mystery made
/// up, each line at every level (`rookie`, `junior`, `master`), and the
/// sources of the facts named.
class HistoryRevealData {
  const HistoryRevealData(this.realHistory, this.inThisMystery, this.sources);

  final List<Map<String, String>> realHistory;
  final List<Map<String, String>> inThisMystery;

  /// `publisher`, `title`, and `url` or `citation`.
  final List<Map<String, String>> sources;
}

class HistoryReport {
  HistoryReport(this.issues, this.facts, this.reveals, this.puzzles);

  final List<HistoryIssue> issues;
  final Map<String, HistoryFactState> facts;
  final Map<String, HistoryRevealData> reveals;

  /// The dossier's puzzles (mission ids) found in their cases.
  final Set<String> puzzles;

  Iterable<HistoryIssue> get errors => issues.where((i) => i.level == HistoryLevel.error);

  Map<String, Object?> get summary => {
    'facts': facts.length,
    for (final s in FactStatus.values) s.json: facts.values.where((f) => f.written == s).length,
    'puzzles': puzzles.length,
    'reveals': reveals.length,
    'errors': errors.length,
    'pending': issues.where((i) => i.level == HistoryLevel.pending).length,
  };
}

/// `planning/history_dossier.json`: the season's real history, a case at a
/// time, with the sources of every fact, the made-up mystery, which facts
/// each puzzle rests on and why its answer is the only one, and what is
/// told after the solve at each level. The writer's file (the game reads
/// only the reveals, through the generator).
///
/// ```json
/// {"schemaVersion": 1, "seasonId": "s5_seoul", "cases": [{
///   "caseId": "s5_ep01", "subject": "…", "period": "1443–1446", "location": "Gyeongbokgung, Seoul",
///   "facts": [{"factId": "s5_ep01_h1", "statement": "…", "status": "draft | source_checked | rejected",
///     "sources": [{"kind": "primary", "publisher": "…", "title": "…", "url": "https://…" | "citation": "…",
///                  "quote": "…" | "location": "…", "checkedAt": "2026-11-04"}],
///     "conflict": {"status": "none | resolved | unresolved", "note": "…"}}],
///   "fiction": ["…"],
///   "puzzles": [{"puzzleId": "s5_ep01_m2", "factIds": ["s5_ep01_h1"], "answer": "…",
///     "clues": [{"text": "1443", "missionId": "s5_ep01_m1"}], "derivation": "…",
///     "whyNot": {"<wrong option id>": "…"} | "whyOnly": "…"}],
///   "learningObjectives": ["…"],
///   "reveal": {"realHistory": [{"text": "…", "junior": "…", "master": "…", "factIds": ["s5_ep01_h1"]}],
///              "inThisMystery": [{"text": "…", "junior": "…", "master": "…"}]}
/// }]}
/// ```
abstract final class HistoryDossier {
  static const path = 'planning/history_dossier.json';
  static const schemaVersion = 1;

  static final factId = RegExp(r'^(s[1-9][0-9]*_ep[0-9]{2})_h[1-9][0-9]*$');
  static final _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _year = RegExp(r'(?<![0-9])(1[0-9]{3}|20[0-9]{2})(?![0-9])');

  static const _top = {'schemaVersion', 'seasonId', 'cases'};
  static const _case = {'caseId', 'subject', 'period', 'location', 'facts', 'fiction', 'puzzles', 'learningObjectives', 'reveal', 'notes'};
  static const _fact = {'factId', 'statement', 'status', 'sources', 'conflict', 'notes'};
  static const _source = {'kind', 'publisher', 'title', 'url', 'citation', 'quote', 'location', 'checkedAt'};
  static const _puzzle = {'puzzleId', 'factIds', 'fiction', 'answer', 'clues', 'derivation', 'whyNot', 'whyOnly'};
  static const _clue = {'text', 'missionId'};
  static const _line = {'text', 'junior', 'master'};

  /// Every fact of the dossier [json] (as read), by id; later ones of a
  /// repeated id are left out (the check reports them).
  static Map<String, Map<dynamic, dynamic>> factsOf(Object? json) {
    final out = <String, Map<dynamic, dynamic>>{};
    if (json is! Map || json['cases'] is! List) return out;
    for (final c in json['cases'] as List) {
      if (c is! Map || c['facts'] is! List) continue;
      for (final f in c['facts'] as List) {
        if (f is Map && f['factId'] is String) out.putIfAbsent(f['factId'] as String, () => f);
      }
    }
    return out;
  }

  /// Why [fact] cannot be `source_checked`: the source
  /// rules a tool can see. Whether the sources truly are independent, say
  /// what is claimed and are read rightly stays a person's judgement.
  static List<String> sourceProblems(Map<dynamic, dynamic> fact) {
    final out = <String>[];
    final sources = fact['sources'] is List ? [for (final s in fact['sources'] as List) if (s is Map) s] : const <Map>[];
    if (sources.length < 2) out.add('${sources.length} source(s): two independent sources at least');
    final publishers = {for (final s in sources) if (s['publisher'] is String) _norm(s['publisher'] as String)}..remove('');
    if (sources.length >= 2 && publishers.length < 2) out.add('every source is of one publisher: two independent sources at least');
    if (!sources.any((s) => _authoritative.contains(s['kind']))) {
      out.add('no source is primary or public_institution (a record of the time, or a state or public body)');
    }
    for (final (i, s) in sources.indexed) {
      final url = s['url'], citation = s['citation'];
      final urlOk = url is String && RegExp(r'^https?://\S+$').hasMatch(url);
      if (!urlOk && !(citation is String && citation.trim().isNotEmpty)) out.add('sources[$i]: neither a url (http/https) nor a citation');
      if (!_text(s['quote']) && !_text(s['location'])) out.add('sources[$i]: neither a quote nor a location (page, article, line) that bears the fact out');
      if (s['checkedAt'] is! String || !_date.hasMatch(s['checkedAt'] as String) || DateTime.tryParse(s['checkedAt'] as String) == null) {
        out.add('sources[$i]: no checkedAt (YYYY-MM-DD): a source not opened is not checked');
      }
    }
    final conflict = fact['conflict'];
    if (conflict is! Map) {
      out.add('no conflict record: whether the sources disagree is to be written down');
    } else if (conflict['status'] == 'unresolved') {
      out.add('the sources disagree and it is unresolved: ${conflict['note'] ?? ''}');
    } else if (conflict['status'] == 'resolved' && !_text(conflict['note'])) {
      out.add('conflict resolved, but no note says how');
    }
    return out;
  }

  /// The dossier of [seasonDir] checked against its [season] and its case
  /// plans ([casePaths], by case id).
  static HistoryReport check(String seasonDir, SeasonPlan season, Map<String, String> casePaths) {
    final issues = <HistoryIssue>[];
    final facts = <String, HistoryFactState>{};
    final reveals = <String, HistoryRevealData>{};
    final found = <String>{};
    void add(HistoryLevel l, String code, String at, String m, {String? target}) =>
        issues.add(HistoryIssue(l, code, at.isEmpty ? path : '$path $at', m, target: target));
    void error(String code, String at, String m, {String? target}) => add(HistoryLevel.error, code, at, m, target: target);
    HistoryReport done() => HistoryReport(issues, facts, reveals, found);

    final file = File('$seasonDir/$path');
    if (!file.existsSync()) {
      error('history_dossier_missing', '', 'a historical season keeps its facts and sources here: nothing is made without it');
      return done();
    }
    final Object? json;
    try {
      json = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      error('history_invalid', '', 'not JSON: ${e.message}');
      return done();
    }
    if (json is! Map) {
      error('history_invalid', r'$', 'not an object');
      return done();
    }
    void fields(Map<dynamic, dynamic> o, Set<String> known, List<String> required, String at, {String? target}) {
      for (final k in o.keys) {
        if (!known.contains(k)) error('history_field_unknown', '$at.$k', 'not a field here', target: target);
      }
      for (final k in required) {
        final v = o[k];
        if (v == null || v is String && v.trim().isEmpty || v is List && v.isEmpty) error('history_field_missing', '$at.$k', 'missing', target: target);
      }
    }

    fields(json, _top, ['seasonId', 'cases'], r'$');
    if (json['schemaVersion'] != schemaVersion) error('history_invalid', r'$.schemaVersion', 'must be $schemaVersion');
    if (json['seasonId'] != season.seasonId) error('history_invalid', r'$.seasonId', '${json['seasonId']}, not ${season.seasonId}');
    final cases = [for (final c in json['cases'] is List ? json['cases'] as List : const []) c];

    // The facts first: puzzles of a later case may rest on an earlier one's.
    final byCase = <String, Map<dynamic, dynamic>>{};
    for (final (i, c) in cases.indexed) {
      final at = '\$.cases[$i]';
      if (c is! Map) {
        error('history_invalid', at, 'not an object');
        continue;
      }
      fields(c, _case, ['caseId', 'subject', 'period', 'location', 'facts', 'fiction', 'puzzles', 'learningObjectives', 'reveal'], at);
      final caseId = c['caseId'];
      if (caseId is! String) continue;
      if (!season.caseIds.contains(caseId)) {
        error('history_case_unknown', '$at.caseId', '$caseId is not a case of ${season.seasonId}');
        continue;
      }
      if (byCase.containsKey(caseId)) error('history_case_twice', '$at.caseId', '$caseId has two entries');
      byCase[caseId] = c;
      for (final (j, f) in (c['facts'] is List ? c['facts'] as List : const []).indexed) {
        final fat = '$at.facts[$j]';
        if (f is! Map) {
          error('history_invalid', fat, 'not an object');
          continue;
        }
        final id = f['factId'];
        fields(f, _fact, ['factId', 'statement', 'status', 'sources', 'conflict'], fat, target: id is String ? id : null);
        if (id is! String) continue;
        if (factId.firstMatch(id)?[1] != caseId) {
          error('history_fact_id', '$fat.factId', '$id: a fact of $caseId is ${caseId}_h<n>');
          continue;
        }
        if (facts.containsKey(id)) {
          error('history_fact_twice', '$fat.factId', '$id is given twice');
          continue;
        }
        final written = FactStatus.values.where((s) => s.json == f['status']).firstOrNull;
        if (written == null) {
          error('history_status_unknown', '$fat.status', '${f['status']}: draft, source_checked or rejected', target: id);
        }
        for (final (k, s) in (f['sources'] is List ? f['sources'] as List : const []).indexed) {
          if (s is! Map) {
            error('history_invalid', '$fat.sources[$k]', 'not an object', target: id);
            continue;
          }
          fields(s, _source, ['kind', 'publisher', 'title'], '$fat.sources[$k]', target: id);
          if (s['kind'] != null && !sourceKinds.contains(s['kind'])) {
            error('history_source_kind', '$fat.sources[$k].kind', '${s['kind']}: one of ${sourceKinds.join(', ')}', target: id);
          }
        }
        if (f['conflict'] case final Map<dynamic, dynamic> x when !const {'none', 'resolved', 'unresolved'}.contains(x['status'])) {
          error('history_conflict_status', '$fat.conflict.status', '${x['status']}: none, resolved or unresolved', target: id);
        }
        final problems = sourceProblems(f);
        if (written == FactStatus.sourceChecked) {
          for (final p in problems) {
            error('history_source_rule', fat, '$id is source_checked, but $p', target: id);
          }
        } else if (written == FactStatus.draft) {
          add(HistoryLevel.pending, 'history_fact_draft', fat, '$id is a draft${problems.isEmpty ? '' : ': ${problems.join('; ')}'}', target: id);
        }
        facts[id] = HistoryFactState(f, written);
      }
    }
    // Every case written (the only ones ever made: the game takes all twelve
    // written, `game_cases_missing`; a pilot or a slice its own).
    for (final id in season.caseIds) {
      if (!byCase.containsKey(id) && File(casePaths[id] ?? '').existsSync()) {
        error('history_case_missing', r'$.cases', '$id has no entry: every case of a historical season rests on real history');
      }
    }

    // The play order: a clue is read before (or in) the puzzle it serves.
    final order = <String>[];
    final plans = <String, (CasePlan, Object?)>{};
    for (final id in season.caseIds) {
      final p = casePaths[id];
      if (p == null || !File(p).existsSync()) continue;
      try {
        final raw = PlanFiles.readJson(p);
        final plan = CasePlan.fromJson(raw);
        plans[id] = (plan, raw);
        order.addAll([for (final m in plan.allMissions) m.missionId]);
      } on Object {
        continue; // its own checks say why
      }
    }
    final levels = <String, CaseLevels?>{};
    CaseLevels? levelsOf(String caseId) => levels.putIfAbsent(caseId, () {
      try {
        return CaseLevels.load(casePaths[caseId]!);
      } on Object {
        return null;
      }
    });
    String caseOf(String missionId) => plans.keys.firstWhere((id) => missionId.startsWith('${id}_'), orElse: () => '');

    /// [missionId]'s words at Rookie and, when written, at Junior and Master.
    Map<String, String> wordsOf(String missionId) {
      final c = caseOf(missionId);
      if (c.isEmpty) return const {};
      final raw = plans[c]!.$2;
      final l = levelsOf(c);
      return {
        'rookie': _missionText(raw, missionId),
        if (l != null)
          for (final level in PlanLevel.values) level.name: _missionText(l.apply(raw, level), missionId),
      };
    }

    // The years a dossier holds up: in its facts (none rejected) and the made-up lines.
    final supported = <String>{
      for (final f in facts.values)
        if (f.written != FactStatus.rejected) ..._year.allMatches('${f.json['statement'] ?? ''}').map((m) => m[1]!),
      for (final c in byCase.values)
        for (final x in c['fiction'] is List ? c['fiction'] as List : const []) ..._year.allMatches('$x').map((m) => m[1]!),
    };

    // Facts a puzzle or a reveal uses: there, not rejected, and source-checked before anything is paid for.
    void uses(Object? ids, String at, String what, String target) {
      if (ids is! List || ids.isEmpty) {
        error('history_fact_unlinked', at, '$what names no fact', target: target);
        return;
      }
      for (final id in ids) {
        final f = facts[id];
        if (f == null) {
          error('history_fact_unknown', at, '$id is no fact of the dossier', target: target);
        } else if (f.written == FactStatus.rejected) {
          error('history_fact_rejected', at, '$id is rejected: never a ground for $what', target: target);
        } else if (!f.checked) {
          add(HistoryLevel.pending, 'history_fact_unchecked', at, '$what rests on $id, ${f.written?.json}: its sources are checked first (source_checked)', target: target);
        }
      }
    }

    for (final (i, c) in cases.indexed) {
      if (c is! Map || c['caseId'] is! String || !byCase.containsKey(c['caseId'])) continue;
      final caseId = c['caseId'] as String;
      final at = '\$.cases[$i]';
      if (c['fiction'] is List && (c['fiction'] as List).any((x) => !_text(x))) error('history_invalid', '$at.fiction', 'one line of text each');

      // No year in the case's words, wrong answers and hints included, that the dossier does not hold up.
      if (plans[caseId] case (final plan, _)) {
        for (final m in plan.allMissions) {
          for (final MapEntry(key: level, value: text) in wordsOf(m.missionId).entries) {
            for (final y in {..._year.allMatches(text).map((x) => x[1]!)}) {
              if (!supported.contains(y)) {
                error('history_year_unsupported', '$at (${m.missionId}, $level)',
                    '${m.missionId} says $y: no fact of the dossier nor a fiction line of $caseId holds it up — a wrong year, or one to declare',
                    target: m.missionId);
              }
            }
          }
        }
      }

      final puzzles = c['puzzles'] is List ? c['puzzles'] as List : const [];
      for (final (j, p) in puzzles.indexed) {
        final pat = '$at.puzzles[$j]';
        if (p is! Map) {
          error('history_invalid', pat, 'not an object');
          continue;
        }
        final pid = '${p['puzzleId']}';
        // A puzzle rests on checked facts, or says it is made up (fiction:
        // true, no history in it).
        final made = p['fiction'] == true;
        fields(p, _puzzle, ['puzzleId', if (!made) 'factIds', 'answer', 'clues', 'derivation'], pat, target: pid);
        if (made && p['factIds'] is List && (p['factIds'] as List).isNotEmpty) {
          error('history_puzzle_source', '$pat.fiction', '$pid: facts and fiction both: one or the other', target: pid);
        } else if (!made) {
          uses(p['factIds'], '$pat.factIds', 'puzzle $pid', pid);
        }
        final (plan, _) = plans[caseId] ?? (null, null);
        final mission = plan?.allMissions.where((m) => m.missionId == pid).firstOrNull;
        if (plan != null && mission == null) {
          error('history_puzzle_unknown', '$pat.puzzleId', '$pid is no mission of $caseId', target: pid);
          continue;
        }
        if (mission == null) continue;
        found.add(pid);
        final spec = mission.puzzle.answerSpec;
        final answer = '${p['answer'] ?? ''}';
        final label = spec.options.where((o) => o.id == spec.answer).firstOrNull?.label;
        if (answer != spec.answer && answer != label) {
          error('history_answer_mismatch', '$pat.answer', '"$answer", but $pid\'s plan answers "${spec.answer}"', target: pid);
        }

        // One answer only: every wrong option ruled out, or why nothing else fits.
        if (spec.options.any((o) => o.id == spec.answer)) {
          final whyNot = p['whyNot'] is Map ? p['whyNot'] as Map : const {};
          for (final o in spec.options) {
            if (o.id != spec.answer && !_text(whyNot[o.id])) {
              error('history_uniqueness_missing', '$pat.whyNot', '"${o.id}" is wrong: say which words of the game rule it out', target: pid);
            }
          }
          for (final k in whyNot.keys) {
            if (k == spec.answer || !spec.options.any((o) => o.id == k)) error('history_uniqueness_missing', '$pat.whyNot.$k', 'not a wrong option of $pid', target: pid);
          }
        } else if (!_text(p['whyOnly'])) {
          error('history_uniqueness_missing', '$pat.whyOnly', 'say why no other ${spec.answer.length > 1 ? 'word or code' : 'answer'} fits', target: pid);
        }

        // A year as the answer is never known beforehand: the game says it first.
        final yearAnswer = RegExp(r'^\s*(1[0-9]{3}|20[0-9]{2})\s*$').firstMatch(spec.answer)?[1];
        if (yearAnswer != null && order.contains(pid)) {
          final before = order.sublist(0, order.indexOf(pid) + 1);
          if (!before.any((m) => _shows(wordsOf(m)['rookie'] ?? '', yearAnswer))) {
            error('history_answer_unshown', '$pat.answer', 'the answer $yearAnswer is in no words read before or in $pid: it would take history the player was never told', target: pid);
          }
        }

        for (final (k, clue) in (p['clues'] is List ? p['clues'] as List : const []).indexed) {
          final cat = '$pat.clues[$k]';
          if (clue is! Map) {
            error('history_invalid', cat, 'not an object', target: pid);
            continue;
          }
          fields(clue, _clue, ['text'], cat, target: pid);
          final text = clue['text'];
          if (text is! String || text.trim().isEmpty) continue;
          final where = clue['missionId'] as String? ?? pid;
          if (!order.contains(where)) {
            error('history_clue_mission', '$cat.missionId', '$where is no mission of the season', target: pid);
            continue;
          }
          if (order.indexOf(where) > order.indexOf(pid)) {
            error('history_clue_late', '$cat.missionId', '$where comes after $pid: the clue is not read before the answer', target: pid);
            continue;
          }
          final words = wordsOf(where);
          if (!_shows(words['rookie']!, text)) {
            error('history_clue_not_shown', cat, '"$text" is not in $where\'s words: the player never reads it', target: pid);
            continue;
          }
          if (words.length == 1) {
            add(HistoryLevel.pending, 'history_levels_pending', cat, '${caseOf(where)} has no levels.json yet: "$text" is checked at Junior and Master once it does', target: pid);
            continue;
          }
          for (final level in PlanLevel.values) {
            if (!_shows(words[level.name]!, text)) {
              error('history_clue_not_shown_at_level', cat, '"$text" is not in $where\'s words at ${level.name}: that level never gives the clue', target: pid);
            }
          }
        }
      }
      if (!puzzles.any((p) => p is Map && p['fiction'] != true)) error('history_case_unlinked', '$at.puzzles', '$caseId: no puzzle rests on its history');

      // The reveal: REAL HISTORY from checked facts only, IN THIS MYSTERY apart, each line at every level.
      final reveal = c['reveal'];
      if (reveal is! Map) continue;
      fields(reveal, const {'realHistory', 'inThisMystery'}, ['realHistory', 'inThisMystery'], '$at.reveal', target: caseId);
      Map<String, String>? line(Object? r, String rat, Set<String> known) {
        if (r is! Map) {
          error('history_invalid', rat, 'not an object', target: caseId);
          return null;
        }
        fields(r, known, ['text', 'junior', 'master'], rat, target: caseId);
        if (!_text(r['text']) || !_text(r['junior']) || !_text(r['master'])) return null;
        final words = {'rookie': r['text'] as String, 'junior': r['junior'] as String, 'master': r['master'] as String};
        for (final problem in _levelProblems(words)) {
          error('history_reveal_level', rat, problem, target: caseId);
        }
        return words;
      }

      final real = <Map<String, String>>[];
      final cited = <String>{};
      for (final (k, r) in (reveal['realHistory'] is List ? reveal['realHistory'] as List : const []).indexed) {
        final rat = '$at.reveal.realHistory[$k]';
        final words = line(r, rat, {..._line, 'factIds'});
        if (r is! Map) continue;
        uses(r['factIds'], '$rat.factIds', 'the REAL HISTORY line', caseId);
        final ids = [for (final x in r['factIds'] is List ? r['factIds'] as List : const []) if (x is String) x];
        cited.addAll(ids);
        if (words == null) continue;
        // A year in REAL HISTORY is one its own facts say: nothing made up slips in.
        final said = {for (final x in ids) ..._year.allMatches('${facts[x]?.json['statement'] ?? ''}').map((m) => m[1]!)};
        for (final y in {..._year.allMatches(words.values.join(' ')).map((m) => m[1]!)}) {
          if (!said.contains(y)) error('history_reveal_unsupported', rat, 'says $y, which none of its facts (${ids.join(', ')}) says', target: caseId);
        }
        real.add(words);
      }
      final made = [
        for (final (k, r) in (reveal['inThisMystery'] is List ? reveal['inThisMystery'] as List : const []).indexed)
          ?line(r, '$at.reveal.inThisMystery[$k]', _line),
      ];
      final sources = <String, Map<String, String>>{};
      for (final id in cited) {
        for (final s in facts[id]?.json['sources'] is List ? facts[id]!.json['sources'] as List : const []) {
          if (s is! Map) continue;
          final entry = {
            for (final k in const ['publisher', 'title', 'url', 'citation'])
              if (_text(s[k])) k: (s[k] as String).trim(),
          };
          sources.putIfAbsent('${entry['publisher']}|${entry['title']}|${entry['url'] ?? entry['citation']}', () => entry);
        }
      }
      reveals[caseId] = HistoryRevealData(real, made, [for (final k in sources.keys.toList()..sort()) sources[k]!]);
    }
    // Timelines (Puzzle Engine 2.0): each a puzzle of the dossier; every card
    // says where it comes from (checked facts, or made up) — a card set
    // aside included, so no false history is ever a wrong card; a fixed
    // card's time is its facts'.
    final dossierPuzzles = {
      for (final c in byCase.values)
        for (final p in c['puzzles'] is List ? c['puzzles'] as List : const [])
          if (p is Map && p['puzzleId'] is String) p['puzzleId'] as String: p,
    };
    // Every puzzle of a historical season goes through the same checks
    // (STEP 1): a mission the dossier does not list is never in the game.
    for (final (plan, _) in plans.values) {
      for (final m in plan.allMissions) {
        if (!dossierPuzzles.containsKey(m.missionId)) {
          add(HistoryLevel.pending, 'history_puzzle_unlisted', '(cases/${plan.caseId} ${m.missionId})',
              '${m.missionId} (${m.puzzle.paletteId}) is no puzzle of the dossier: list it, on its facts or as made up (fiction: true)',
              target: m.missionId);
        }
      }
    }
    for (final MapEntry(key: caseId, value: (_, raw)) in plans.entries) {
      if (raw is! Map) continue;
      for (final m in [...?(raw['missions'] as List?), raw['final']].whereType<Map>()) {
        final t = m['play'] is Map ? (m['play'] as Map)['timeline'] : null;
        if (t is! Map || m['missionId'] is! String) continue;
        final mid = m['missionId'] as String;
        final at = '(cases/$caseId $mid.play.timeline)';
        final entry = dossierPuzzles[mid];
        if (entry == null) {
          error('history_timeline_unreviewed', at, '$mid is a timeline of a historical season: a puzzle of the dossier, its facts listed', target: mid);
        }
        final listed = {for (final x in entry?['factIds'] is List ? entry!['factIds'] as List : const []) x};
        for (final (i, c) in (t['cards'] is List ? t['cards'] as List : const []).indexed) {
          if (c is! Map) continue;
          final cat = '$at.cards[$i]';
          final ids = [for (final x in c['factIds'] is List ? c['factIds'] as List : const []) if (x is String) x];
          final fiction = c['fiction'] == true;
          if (ids.isEmpty == !fiction) {
            error('history_timeline_card_source', cat,
                ids.isEmpty
                    ? '${c['id']}: a card of real history names its checked facts (factIds); a made-up one says so (fiction: true)'
                    : '${c['id']}: facts and fiction both: one or the other',
                target: mid);
          }
          if (ids.isNotEmpty) {
            uses(ids, '$cat.factIds', 'the card ${c['id']}', mid);
            for (final id in ids.where((x) => !listed.contains(x))) {
              error('history_timeline_fact_unlisted', cat, '$id is not in the puzzle $mid\'s factIds: its checks would never see the fact', target: mid);
            }
          }
          final years = {for (final y in _year.allMatches('${c['anchor'] ?? ''}')) y[1]!};
          final said = fiction
              ? supported
              : {for (final id in ids) ..._year.allMatches('${facts[id]?.json['statement'] ?? ''}').map((y) => y[1]!)};
          for (final y in years.where((y) => !said.contains(y))) {
            error('history_timeline_anchor_unsupported', '$cat.anchor',
                fiction ? '$y on a made-up card: a fiction line of the case declares it' : '$y, which none of its facts (${ids.join(', ')}) says', target: mid);
          }
        }
      }
    }
    return done();
  }

  /// What is wrong with a line's [words] at its levels: the same numbers and
  /// names at every level, and Junior's and Master's own English.
  static List<String> _levelProblems(Map<String, String> words) {
    final out = <String>[];
    Set<String> numbers(String s) => {for (final m in RegExp(r'[0-9]+').allMatches(s)) m[0]!};
    // A name: a capitalised word not opening a sentence.
    Set<String> names(String s) => {
      for (final m in RegExp(r"(?<![.!?]\s)(?<!^)\b([A-Z][A-Za-z'-]+)").allMatches(s.trim())) m[1]!,
    };
    final rookie = words['rookie']!;
    for (final level in const ['junior', 'master']) {
      final w = words[level]!;
      final (n, rn) = (numbers(w), numbers(rookie));
      if (n.length != rn.length || !n.containsAll(rn)) {
        out.add('$level has the numbers ${numbers(w).join(', ')}, Rookie ${numbers(rookie).join(', ')}: every level says the same years and numbers');
      }
      final missing = names(rookie).where((n) => !w.contains(n)).toList();
      if (missing.isNotEmpty) out.add('$level leaves out ${missing.join(', ')}: every level names the same people and places');
      if (w.trim() == rookie.trim() && rookie.split(RegExp(r'\s+')).length >= 6) out.add('$level is Rookie\'s line again: write it in its own English');
    }
    return out;
  }

  /// The words the player reads in [missionId] of the case plan [raw]: what
  /// the levels count as words (`CaseLevels`), never ids or match keys.
  static String _missionText(Object? raw, String missionId) {
    if (raw is! Map) return '';
    final missions = [...?(raw['missions'] as List?), raw['final']];
    final m = missions.whereType<Map>().where((m) => m['missionId'] == missionId).firstOrNull;
    if (m == null) return '';
    // A record's values are the same at every level (not a level's words),
    // but read all the same: what is compared is history's or declared made up.
    final records = m['play'] is Map ? (m['play'] as Map)['records'] : null;
    final values = [
      if (records is Map)
        for (final d in [records['first'], records['second']].whereType<Map>())
          for (final l in (d['lines'] is List ? d['lines'] as List : const []).whereType<Map>()) '${l['value']}',
    ];
    return [...CaseLevels.rookieLines({'missions': [m]}), ...values].join('\n');
  }

  /// [clue] read as words in [text]: not inside another word, case and spaces aside.
  static bool _shows(String text, String clue) {
    final words = RegExp.escape(clue.trim()).replaceAll(RegExp(r'\s+'), r'\s+');
    final before = RegExp(r'^\w').hasMatch(clue.trim()) ? r'(?<!\w)' : '';
    final after = RegExp(r'\w$').hasMatch(clue.trim()) ? r'(?!\w)' : '';
    return RegExp('$before$words$after', caseSensitive: false).hasMatch(text);
  }

  static bool _text(Object? v) => v is String && v.trim().isNotEmpty;
  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');
}

/// The one door to the paid steps of a historical season and to the game.
/// Empty: nothing stands in the way (always so in the standard mode).
abstract final class HistoryGate {
  /// Not yet needed before the pictures: written after them.
  static const _forGameOnly = {'history_levels_pending', 'history_puzzle_unlisted'};

  /// What stops [seasonDir]'s paid steps (pictures, sounds): its dossier
  /// whole and every fact its puzzles and reveals rest on source-checked.
  /// With [game], what stops the season going into the game: that, and
  /// every level written. Only the automatic checks: no person's approval.
  static List<String> blockers(String seasonDir, {bool game = false}) {
    final dir = seasonDir.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    try {
      if (SeasonMode.of(dir) == SeasonMode.standard) return const [];
    } on FormatException catch (e) {
      return ['the season\'s mode cannot be told: ${e.message}'];
    }
    final SeasonPlan season;
    try {
      season = PlanFiles.loadSeasonPlan('$dir/season.plan.json');
    } on Object catch (e) {
      return ['season.plan.json does not read: $e'];
    }
    final report = HistoryDossier.check(dir, season, {for (final id in season.caseIds) id: '$dir/cases/$id/case.plan.json'});
    return [
      for (final i in report.issues)
        if (i.level == HistoryLevel.error ||
            (i.code != 'history_fact_draft' && (game || !_forGameOnly.contains(i.code))))
          '$i',
    ];
  }

  /// What stops a file made at [output] (from [root], or absolute under it):
  /// the paid-step blockers of the historical season it belongs to — its
  /// plans' folder, its picture work folder, or its asset root (the brief's
  /// or the manifest's `assetRoot`). A file of no historical season (a
  /// standard season's, a test picture, any other) is never stopped here.
  static List<String> forOutput(String root, String output) {
    final base = Directory(root).absolute.path.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    var rel = output.replaceAll(r'\', '/');
    if (rel.startsWith('$base/')) rel = rel.substring(base.length + 1);
    rel = rel.replaceFirst(RegExp(r'^(\./)+'), '');
    final seasons = Directory('$base/content_pipeline/seasons');
    if (!seasons.existsSync()) return const [];
    for (final d in seasons.listSync().whereType<Directory>()) {
      final id = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final roots = <String>{'content_pipeline/seasons/$id', 'content_pipeline/asset_work/$id'};
      try {
        if (SeasonMode.of(d.path) == SeasonMode.standard) continue;
        final brief = SeasonMode._brief(d.path);
        if (brief?['assetRoot'] case final String r) roots.add(r);
      } on FormatException {
        // a mode that cannot be told: its own folders are stopped (blockers says why)
      }
      final manifest = File('${d.path}/assets.manifest.json');
      if (manifest.existsSync()) {
        try {
          if (jsonDecode(manifest.readAsStringSync()) case {'assetRoot': final String r}) roots.add(r);
        } on FormatException {
          // the manifest's own checks say so
        }
      }
      if (roots.any((r) => rel == r || rel.startsWith('${r.replaceAll(RegExp(r'/$'), '')}/'))) return blockers(d.path);
    }
    return const [];
  }
}
