/// The season content pipeline's intermediate models (STEP 3-2): what an AI
/// plans for a season before any of it becomes the game's Dart content.
///
/// Plans are never read by the game. They live under
/// `content_pipeline/seasons/<seasonId>/` as JSON; the game's own models
/// (`Season`, `Episode`, `Mission`, `SeasonContent`) stay as they are, and
/// a later step turns an approved plan into them.
///
/// Two layers of rules:
/// * **Format** — [SeasonPlan.fromJson] and [CasePlan.fromJson]: keys, types,
///   enums, id formats, counts. The same rules as the JSON Schemas in
///   `schema/`, rule for rule (`season_gen_schema_test` checks both reject
///   the same documents). Unknown keys are rejected.
/// * **Structure** — `PlanCheck`: how a plan's parts relate (a case's id and
///   number, its missions' order, its season's acts). What a JSON Schema
///   cannot say.
///
/// Not here: the palette fit (STEP 3-3, `PuzzleSelectionCheck`), the clue
/// graph (STEP 3-4, `ClueGraphCheck`), the approvals (STEP 3-5,
/// `SeasonApprovals`, kept beside the plans); not yet: the levels' words and
/// asset requests. A plan names what they will use (clue ids,
/// palette ids, asset ids) and, once written (STEP 3-8, optional), the
/// words the game shows (`play`) and its places' pictures (`places`):
/// whether they are all there is `PlayCheck`'s.
library;

import 'plan_ids.dart';

/// The plans' schema version: a plan of another version is rejected.
const planSchemaVersion = 1;

/// The cases a season plan has: three acts of four.
const plannedCasesPerSeason = 12;
const actsPerSeason = 3;
const casesPerAct = 4;

/// The missions a case has before its final. The game sets no bound; London
/// Case 01 has five, every other London and Paris case three.
const minMissionsPerCase = 1;
const maxMissionsPerCase = 5;

/// Words the game's own enums are written with (plans hold them as text).
/// `season_gen_schema_test` keeps them equal to the game's enums.
abstract final class PlanVocabulary {
  /// `MissionType` (lib/data/models/mission.dart).
  static const missionTypes = [
    'multipleChoice',
    'wordInput',
    'numberCode',
    'imageChoice',
    'examine',
    'finalCode',
    'sequence',
    'letterLock',
    'spotDifferences',
    'matchPairs',
    'revealLayer',
    'canvasChoice',
  ];

  /// `LanguageDependency` (lib/data/models/learning.dart).
  static const dependencies = ['essential', 'helpful', 'exposure', 'low'];

  /// `LearningLevel`.
  static const learningLevels = ['exposure', 'comprehension', 'application', 'recall'];

  /// `LanguageSkill`.
  static const skills = ['vocabulary', 'sentenceMeaning', 'grammarInContext'];

  /// `Mission.codeFormat`: the formats the game reads.
  static const codeFormats = ['time'];
}

/// A plan that does not keep the format: where ([path], as `$.acts[0]`) and why.
class PlanFormatException implements Exception {
  const PlanFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'PlanFormatException: $path: $message';
}

/// The page a puzzle is played on (`PuzzleSurface` of the palette).
enum PlanSurface { mission, finalMission }

/// Whether a puzzle can be made now.
enum PuzzleStatus {
  /// Its engine is in the palette and it needs no picture to be made.
  ready,

  /// Its engine is in the palette; its pictures are still to be made.
  awaitingAssets,

  /// No engine plays it yet: a development request, never generated.
  devRequest,
}

/// How a mission uses a clue it is given (STEP 3-1 §5.2). Only ways the game
/// can play today. Every use asks for a clue found before (`ClueGraphCheck`).
enum ClueUse {
  /// The answer is worked out from the clue's value.
  answerDerivation,

  /// The evidence is shown in a talk (`TalkScene`).
  talkPresent,

  /// The evidence is matched to this one (`SeasonContent.evidenceLinks`).
  evidenceLink,

  /// The evidence is brought from the notebook (`Mission.recall`): a help only.
  recall,

  /// The English of an earlier mission is read again (`LearningObjective.recallFrom`).
  learningRecall,

  /// The story only mentions it.
  textMention,
}

// ── Reading ──────────────────────────────────────────────────────────────

/// Reads one JSON object at [path], key by key; [done] rejects any key not read.
class _Reader {
  _Reader(Object? json, this.path) : _map = _object(json, path);

  static Map<String, Object?> _object(Object? json, String path) {
    if (json is! Map) throw PlanFormatException(path, 'not an object');
    return {for (final e in json.entries) '${e.key}': e.value};
  }

  final String path;
  final Map<String, Object?> _map;
  final _read = <String>{};

  String _at(String key) => '$path.$key';

  Never _fail(String key, String message) => throw PlanFormatException(_at(key), message);

  Object? _required(String key) {
    _read.add(key);
    if (!_map.containsKey(key)) _fail(key, 'missing');
    return _map[key];
  }

  bool _has(String key) {
    _read.add(key);
    return _map.containsKey(key);
  }

  static String _text(Object? v, String at, RegExp? pattern, List<String>? oneOf) {
    if (v is! String) throw PlanFormatException(at, 'not text');
    if (v.isEmpty) throw PlanFormatException(at, 'empty');
    if (pattern != null && !pattern.hasMatch(v)) throw PlanFormatException(at, '"$v" is not of the form ${pattern.pattern}');
    if (oneOf != null && !oneOf.contains(v)) throw PlanFormatException(at, '"$v" is not one of ${oneOf.join(', ')}');
    return v;
  }

  String str(String key, {RegExp? pattern, List<String>? oneOf}) => _text(_required(key), _at(key), pattern, oneOf);

  String? optStr(String key, {RegExp? pattern, List<String>? oneOf}) =>
      _has(key) ? _text(_map[key], _at(key), pattern, oneOf) : null;

  /// A key that must be there, its value text or null.
  String? nullableStr(String key, {RegExp? pattern}) {
    final v = _required(key);
    return v == null ? null : _text(v, _at(key), pattern, null);
  }

  int integer(String key, {int? min, int? max, int? only}) => _int(_required(key), _at(key), min: min, max: max, only: only);

  int? optInt(String key, {int? min}) => _has(key) ? _int(_map[key], _at(key), min: min) : null;

  double? optNum(String key, {double? min, double? max}) {
    if (!_has(key)) return null;
    final v = _map[key];
    if (v is! num) _fail(key, 'not a number');
    if (min != null && v < min) _fail(key, '$v is under $min');
    if (max != null && v > max) _fail(key, '$v is over $max');
    return v.toDouble();
  }

  bool? optBool(String key) {
    if (!_has(key)) return null;
    final v = _map[key];
    if (v is! bool) _fail(key, 'not true or false');
    return v;
  }

  /// An optional object of text by text: empty when not given.
  Map<String, String> optTextMap(String key) {
    if (!_has(key)) return const {};
    final at = _at(key);
    return {for (final e in _object(_map[key], at).entries) e.key: _text(e.value, '$at.${e.key}', null, null)};
  }

  /// An optional object of objects, by key: empty when not given.
  Map<String, T> optObjMap<T>(String key, T Function(Object? json, String path) parse) {
    if (!_has(key)) return const {};
    final at = _at(key);
    return {for (final e in _object(_map[key], at).entries) e.key: parse(e.value, '$at.${e.key}')};
  }

  static int _int(Object? json, String at, {int? min, int? max, int? only}) {
    // As JSON Schema reads it: 2.0 is the whole number 2.
    final v = json is double && json == json.truncateToDouble() && json.isFinite ? json.toInt() : json;
    if (v is! int) throw PlanFormatException(at, 'not a whole number');
    if (only != null && v != only) throw PlanFormatException(at, '$v, not $only');
    if (min != null && v < min) throw PlanFormatException(at, '$v is under $min');
    if (max != null && v > max) throw PlanFormatException(at, '$v is over $max');
    return v;
  }

  E enumOf<E extends Enum>(String key, List<E> values) {
    final name = str(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    _fail(key, '"$name" is not one of ${values.map((v) => v.name).join(', ')}');
  }

  List<Object?> _list(Object? v, String at, int? min, int? max) {
    if (v is! List) throw PlanFormatException(at, 'not a list');
    if (min != null && v.length < min) throw PlanFormatException(at, '${v.length} items, at least $min');
    if (max != null && v.length > max) throw PlanFormatException(at, '${v.length} items, at most $max');
    return v;
  }

  List<String> _strings(Object? v, String at, {int? min, int? max, RegExp? pattern, bool unique = false}) {
    final list = _list(v, at, min, max);
    final out = [for (final (i, x) in list.indexed) _text(x, '$at[$i]', pattern, null)];
    if (unique && out.toSet().length != out.length) throw PlanFormatException(at, 'an item given twice');
    return out;
  }

  List<String> strings(String key, {int? min, int? max, RegExp? pattern, bool unique = false}) =>
      _strings(_required(key), _at(key), min: min, max: max, pattern: pattern, unique: unique);

  /// An optional list: empty when not given.
  List<String> optStrings(String key, {RegExp? pattern, bool unique = false}) =>
      _has(key) ? _strings(_map[key], _at(key), pattern: pattern, unique: unique) : const [];

  T obj<T>(String key, T Function(Object? json, String path) parse) => parse(_required(key), _at(key));

  T? optObj<T>(String key, T Function(Object? json, String path) parse) => _has(key) ? parse(_map[key], _at(key)) : null;

  List<T> objs<T>(String key, T Function(Object? json, String path) parse, {int? min, int? max}) {
    final at = _at(key);
    return [for (final (i, x) in _list(_required(key), at, min, max).indexed) parse(x, '$at[$i]')];
  }

  List<T> optObjs<T>(String key, T Function(Object? json, String path) parse) {
    if (!_has(key)) return const [];
    final at = _at(key);
    return [for (final (i, x) in _list(_map[key], at, null, null).indexed) parse(x, '$at[$i]')];
  }

  List<double> _numbers(Object? v, String at, int count) {
    final list = _list(v, at, count, count);
    return [
      for (final (i, x) in list.indexed)
        if (x is num && x.isFinite) x.toDouble() else throw PlanFormatException('$at[$i]', 'not a number'),
    ];
  }

  /// A point on a picture, `[x, y]` in its pixels.
  ScenePoint point(String key) => ScenePoint._(_numbers(_required(key), _at(key), 2));

  /// Points on a picture, by key.
  Map<String, ScenePoint> pointMap(String key) {
    final at = _at(key);
    return {for (final e in _object(_required(key), at).entries) e.key: ScenePoint._(_numbers(e.value, '$at.${e.key}', 2))};
  }

  ScenePoint? optPoint(String key) => _has(key) ? ScenePoint._(_numbers(_map[key], _at(key), 2)) : null;

  /// A rectangle on a picture, `[left, top, right, bottom]` in its pixels.
  SceneRect? optRect(String key) => _has(key) ? SceneRect._(_numbers(_map[key], _at(key), 4)) : null;

  /// One rectangle or more.
  List<SceneRect> rects(String key) {
    final at = _at(key);
    return [for (final (i, x) in _list(_required(key), at, 1, null).indexed) SceneRect._(_numbers(x, '$at[$i]', 4))];
  }

  /// A rectangle, `[left, top, right, bottom]`.
  SceneRect rect(String key) => SceneRect._(_numbers(_required(key), _at(key), 4));

  /// A number (whole or not).
  double number(String key, {double? min}) => optNum(key, min: min) ?? _fail(key, 'missing');

  /// Numbers, at least one.
  List<double> numbers(String key) {
    final at = _at(key);
    final list = _list(_required(key), at, 1, null);
    return _numbers(list, at, list.length);
  }

  /// Whole numbers (none when not given), each once.
  List<int> optInts(String key, {int min = 0}) {
    if (!_has(key)) return const [];
    final at = _at(key);
    final out = [for (final (i, x) in _list(_map[key], at, null, null).indexed) _int(x, '$at[$i]', min: min)];
    if (out.toSet().length != out.length) _fail(key, 'an item given twice');
    return out;
  }

  /// Rejects the keys no one asked for.
  void done() {
    final unknown = _map.keys.where((k) => !_read.contains(k)).toList();
    if (unknown.isNotEmpty) throw PlanFormatException(_at(unknown.first), 'not a field of this plan');
  }
}

/// Lays an optional list into [json] only when it has something.
void _putList(Map<String, Object?> json, String key, List<Object?> list) {
  if (list.isNotEmpty) json[key] = list;
}

void _putText(Map<String, Object?> json, String key, String? value) {
  if (value != null) json[key] = value;
}

void _putMap(Map<String, Object?> json, String key, Map<String, Object?> map) {
  if (map.isNotEmpty) json[key] = map;
}

void _version(_Reader r) {
  final v = r.integer('schemaVersion');
  if (v != planSchemaVersion) r._fail('schemaVersion', 'version $v is not supported (this tool reads version $planSchemaVersion)');
}

// ── SeasonPlan ───────────────────────────────────────────────────────────

/// The truth behind the whole season, for the writers (never shown as is).
class MainMystery {
  const MainMystery({required this.truth, required this.culprit, required this.motive, required this.revealCase});

  final String truth;
  final String culprit;
  final String motive;

  /// The case that shows it (a case id of the season).
  final String revealCase;

  factory MainMystery.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MainMystery(
      truth: r.str('truth'),
      culprit: r.str('culprit'),
      motive: r.str('motive'),
      revealCase: r.str('revealCase', pattern: PlanIds.caseId),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'truth': truth, 'culprit': culprit, 'motive': motive, 'revealCase': revealCase};
}

/// Someone of the season's story.
class CharacterPlan {
  const CharacterPlan({
    required this.charId,
    required this.name,
    required this.role,
    required this.firstCase,
    this.revealCase,
    this.secretUntil,
  });

  /// Its id in the season plan (`emile`).
  final String charId;
  final String name;

  /// What the story says they are.
  final String role;

  /// The case they first appear in.
  final String firstCase;

  /// The case their true part is shown in; null: they have none to show.
  final String? revealCase;

  /// The case before which something of theirs (a name, a face) is never
  /// told; null: nothing is kept back.
  final String? secretUntil;

  factory CharacterPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = CharacterPlan(
      charId: r.str('charId', pattern: PlanIds.local),
      name: r.str('name'),
      role: r.str('role'),
      firstCase: r.str('firstCase', pattern: PlanIds.caseId),
      revealCase: r.optStr('revealCase', pattern: PlanIds.caseId),
      secretUntil: r.optStr('secretUntil', pattern: PlanIds.caseId),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'charId': charId, 'name': name, 'role': role, 'firstCase': firstCase};
    _putText(json, 'revealCase', revealCase);
    _putText(json, 'secretUntil', secretUntil);
    return json;
  }
}

/// A place of the season's map.
class LocationPlan {
  const LocationPlan({required this.locId, required this.name, required this.landmarkKey});

  final String locId;
  final String name;

  /// The map landmark it is drawn as (the name of its `MapLandmark` value).
  final String landmarkKey;

  factory LocationPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LocationPlan(
      locId: r.str('locId', pattern: PlanIds.local),
      name: r.str('name'),
      landmarkKey: r.str('landmarkKey', pattern: PlanIds.landmark),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'locId': locId, 'name': name, 'landmarkKey': landmarkKey};
}

/// One act: its theme and its four cases, in order.
class ActPlan {
  const ActPlan({required this.actId, required this.theme, required this.caseIds});

  final String actId;
  final String theme;
  final List<String> caseIds;

  factory ActPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ActPlan(
      actId: r.str('actId', pattern: PlanIds.act),
      theme: r.str('theme'),
      caseIds: r.strings('caseIds', min: casesPerAct, max: casesPerAct, pattern: PlanIds.caseId, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'actId': actId, 'theme': theme, 'caseIds': caseIds};
}

/// Who is revealed on the season board, after which case (`SeasonFigure`).
class FigurePlan {
  const FigurePlan({required this.after, required this.figure, required this.label});

  final String after;
  final String figure;
  final String label;

  factory FigurePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = FigurePlan(
      after: r.str('after', pattern: PlanIds.caseId),
      figure: r.str('figure'),
      label: r.str('label'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'after': after, 'figure': figure, 'label': label};
}

/// The season's opening, in the keys of the game's `SeasonPrologue` JSON:
/// its words (Rookie's; Junior's and Master's in `season.levels.json`) and
/// its pictures — [hero] for the first scene, one of [pieces] for each of
/// [cases], and the first case's picture (files).
class ProloguePlan {
  const ProloguePlan({
    this.city,
    this.cases = const [],
    this.separate = const [],
    this.question,
    this.bigger,
    this.promise = const [],
    this.firstCase,
    this.hero,
    this.pieces = const [],
  });

  final String? city;
  final List<String> cases;
  final List<String> separate;
  final String? question;
  final String? bigger;
  final List<String> promise;
  final ({String picture, String line})? firstCase;
  final ({String file, int width, int height})? hero;
  final List<String> pieces;

  /// Every line the opening says, in the order the game shows them (the
  /// game's `SeasonPrologue.linesOf`).
  List<String> get lines => [
    ?city,
    ...cases,
    ...separate,
    ?question,
    ?bigger,
    ...promise,
    ?firstCase?.line,
  ];

  factory ProloguePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ProloguePlan(
      city: r.optStr('city'),
      cases: r.optStrings('cases'),
      separate: r.optStrings('separate'),
      question: r.optStr('question'),
      bigger: r.optStr('bigger'),
      promise: r.optStrings('promise'),
      firstCase: r.optObj('firstCase', (json, path) {
        final f = _Reader(json, path);
        final out = (picture: f.str('picture'), line: f.str('line'));
        f.done();
        return out;
      }),
      hero: r.optObj('hero', (json, path) {
        final f = _Reader(json, path);
        final file = f.str('file');
        final pixels = f.obj('pixels', (json, path) {
          final p = _Reader(json, path);
          final out = (p.integer('width', min: 1), p.integer('height', min: 1));
          p.done();
          return out;
        });
        f.done();
        return (file: file, width: pixels.$1, height: pixels.$2);
      }),
      pieces: r.optStrings('pieces'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'city', city);
    _putList(json, 'cases', cases);
    _putList(json, 'separate', separate);
    _putText(json, 'question', question);
    _putText(json, 'bigger', bigger);
    _putList(json, 'promise', promise);
    if (firstCase case final f?) json['firstCase'] = {'picture': f.picture, 'line': f.line};
    if (hero case final h?) {
      json['hero'] = {
        'file': h.file,
        'pixels': {'width': h.width, 'height': h.height},
      };
    }
    _putList(json, 'pieces', pieces);
    return json;
  }
}

/// A season place's picture (the game's `ScenePlace`): a mission names it
/// by its [placeId] (`Mission.sceneKey`). Its pixel size is the file's.
class PlacePlan {
  const PlacePlan({required this.placeId, required this.file, required this.width, required this.height, this.locId});

  final String placeId;

  /// The bundled asset, from the repository's root (`assets/…`).
  final String file;
  final int width;
  final int height;

  /// The season location it is in (a `locations[].locId`), for the season
  /// map: a mission at this place is pinned at that location's landmark
  /// (`art.map`). Null: the place is on no map yet.
  final String? locId;

  factory PlacePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = r.obj('pixels', _pixels);
    final place = PlacePlan(
      placeId: r.str('placeId', pattern: PlanIds.place),
      file: r.str('file', pattern: PlanIds.assetFile),
      width: out.$1,
      height: out.$2,
      locId: r.optStr('locId', pattern: PlanIds.local),
    );
    r.done();
    return place;
  }

  Map<String, Object?> toJson() => {
    'placeId': placeId,
    'file': file,
    'pixels': {'width': width, 'height': height},
    'locId': ?locId,
  };
}

/// The season's own pictures outside its cases (the Rome integration):
/// its cover, its map and its city on the World Map. What the game
/// registers for the season beside its content (`SeasonCover`,
/// `SeasonMap`, `WorldCity`), made by `generate_case.dart --target game`.
/// Each part is optional while the season is drawn; a season without its
/// map cannot be entered (`SeasonAvailability`).
class SeasonArtPlan {
  const SeasonArtPlan({this.cover, this.map, this.caseMaps = const {}, this.worldCity, this.introBackdrops = const {}});

  final CoverPlan? cover;
  final MapPlan? map;

  /// A case's own Mission Map, by case id; a case without one is played on
  /// [map], which stays the season's map on every other screen.
  final Map<String, CaseMapPlan> caseMaps;
  final WorldCityPlan? worldCity;

  /// A case's picture behind its opening, by case id
  /// (`SeasonContent.introBackdrops`); a case without one shows its place.
  final Map<String, String> introBackdrops;

  factory SeasonArtPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = SeasonArtPlan(
      cover: r.optObj('cover', CoverPlan.fromJson),
      map: r.optObj('map', MapPlan.fromJson),
      caseMaps: r.optObjMap('caseMaps', CaseMapPlan.fromJson),
      worldCity: r.optObj('worldCity', WorldCityPlan.fromJson),
      introBackdrops: r.optTextMap('introBackdrops'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    if (cover case final c?) 'cover': c.toJson(),
    if (map case final m?) 'map': m.toJson(),
    if (caseMaps.isNotEmpty) 'caseMaps': {for (final e in caseMaps.entries) e.key: e.value.toJson()},
    if (worldCity case final w?) 'worldCity': w.toJson(),
    if (introBackdrops.isNotEmpty) 'introBackdrops': introBackdrops,
  };
}

/// The season's cover (portrait, no text) and how the screens frame it:
/// `SeasonCover`'s fields. Alignments are `[x, y]`, each -1 to 1.
class CoverPlan {
  const CoverPlan({
    required this.file,
    required this.width,
    required this.height,
    this.archiveLook = const ScenePoint(0, 0),
    this.crop = const ScenePoint(0, 0),
    this.push = const ScenePoint(0, 0),
  });

  final String file;
  final int width;
  final int height;
  final ScenePoint archiveLook;
  final ScenePoint crop;
  final ScenePoint push;

  factory CoverPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final size = r.obj('pixels', _pixels);
    ScenePoint align(String key) {
      final p = r.optPoint(key) ?? const ScenePoint(0, 0);
      if (p.x.abs() > 1 || p.y.abs() > 1) throw PlanFormatException('$path.$key', 'an alignment is -1 to 1');
      return p;
    }

    final out = CoverPlan(
      file: r.str('file', pattern: PlanIds.assetFile),
      width: size.$1,
      height: size.$2,
      archiveLook: align('archiveLook'),
      crop: align('crop'),
      push: align('push'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'file': file,
    'pixels': {'width': width, 'height': height},
    'archiveLook': archiveLook.toJson(),
    'crop': crop.toJson(),
    'push': push.toJson(),
  };
}

/// The season's Mission Map: its artwork (streets and landmarks drawn, no
/// names, no pins) and where each location's landmark is drawn on it, in
/// its pixels, measured on the very file ([measuredOn]).
class MapPlan {
  const MapPlan({required this.file, required this.width, required this.height, required this.landmarks, this.measuredOn});

  final String file;
  final int width;
  final int height;

  /// `sha256:<hex>` of the file the landmarks were measured on.
  final String? measuredOn;
  final List<MapLandmarkPlan> landmarks;

  factory MapPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final size = r.obj('pixels', _pixels);
    final out = MapPlan(
      file: r.str('file', pattern: PlanIds.assetFile),
      width: size.$1,
      height: size.$2,
      measuredOn: r.optStr('measuredOn', pattern: RegExp(r'^sha256:[0-9a-f]{64}$')),
      landmarks: r.objs('landmarks', MapLandmarkPlan.fromJson, min: 1),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'file': file,
    'pixels': {'width': width, 'height': height},
    'measuredOn': ?measuredOn,
    'landmarks': [for (final l in landmarks) l.toJson()],
  };
}

/// A location's landmark on the map: the centre of its drawing, in pixels.
class MapLandmarkPlan {
  const MapLandmarkPlan({required this.locId, required this.at});

  final String locId;
  final ScenePoint at;

  factory MapLandmarkPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MapLandmarkPlan(locId: r.str('locId', pattern: PlanIds.local), at: r.point('at'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'locId': locId, 'at': at.toJson()};
}

/// A case's own Mission Map: its artwork, the places of the case drawn on
/// it, and where each mission stands, in its pixels, measured on the very
/// file ([measuredOn]). One artwork may serve several cases.
class CaseMapPlan {
  const CaseMapPlan({required this.file, required this.width, required this.height, required this.measuredOn, required this.landmarks});

  final String file;
  final int width;
  final int height;

  /// `sha256:<hex>` of the file the places were measured on.
  final String measuredOn;
  final List<CaseMapLandmarkPlan> landmarks;

  factory CaseMapPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final size = r.obj('pixels', _pixels);
    final out = CaseMapPlan(
      file: r.str('file', pattern: PlanIds.assetFile),
      width: size.$1,
      height: size.$2,
      measuredOn: r.str('measuredOn', pattern: RegExp(r'^sha256:[0-9a-f]{64}$')),
      landmarks: r.objs('landmarks', CaseMapLandmarkPlan.fromJson, min: 1),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'file': file,
    'pixels': {'width': width, 'height': height},
    'measuredOn': measuredOn,
    'landmarks': [for (final l in landmarks) l.toJson()],
  };
}

/// A place on a case's own map: [name] (its missions' `play.location`),
/// lettered at [at] (a little below its spots: a solved mark at its point
/// would leave no room for the name), and each of its [missions]' spots.
class CaseMapLandmarkPlan {
  const CaseMapLandmarkPlan({required this.spotId, required this.name, required this.at, required this.missions});

  final String spotId;
  final String name;
  final ScenePoint at;
  final Map<String, ScenePoint> missions;

  factory CaseMapLandmarkPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = CaseMapLandmarkPlan(
      spotId: r.str('spotId', pattern: PlanIds.local),
      name: r.str('name'),
      at: r.point('at'),
      missions: r.pointMap('missions'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'spotId': spotId,
    'name': name,
    'at': at.toJson(),
    'missions': {for (final e in missions.entries) e.key: e.value.toJson()},
  };
}

/// The season's city on the World Map (`WorldCity`): its id (one of
/// `WorldCities`' when the city is already drawn there as coming soon), its
/// latitude and longitude, and, when its landmark is on the World Map
/// artwork, where its pin's tip goes (in that artwork's 1983 × 793 pixels).
class WorldCityPlan {
  const WorldCityPlan({required this.cityId, required this.latitude, required this.longitude, this.mapAt});

  final String cityId;
  final double latitude;
  final double longitude;
  final ScenePoint? mapAt;

  factory WorldCityPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = WorldCityPlan(
      cityId: r.str('cityId', pattern: PlanIds.local),
      latitude: r.optNum('latitude', min: -90, max: 90) ?? (throw PlanFormatException('$path.latitude', 'missing')),
      longitude: r.optNum('longitude', min: -180, max: 180) ?? (throw PlanFormatException('$path.longitude', 'missing')),
      mapAt: r.optPoint('mapAt'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'cityId': cityId,
    'latitude': latitude,
    'longitude': longitude,
    if (mapAt case final p?) 'mapAt': p.toJson(),
  };
}

/// A whole season, planned: its mystery, people, places and acts.
///
/// The game's `Season` reads every field but its number and title
/// tolerantly (a missing one is empty). The plan asks for more at once (the
/// mystery, acts, people, places) and leaves the words the season says
/// ([prologue], [outro], [finale], [figures]) optional while it is planned:
/// they are required by the Dart generation step (STEP 3-6: [outro] and
/// [finale] written, [figures] given), and [prologue] once a new season
/// has an opening page of its own (STEP 3-10).
class SeasonPlan {
  const SeasonPlan({
    required this.seasonId,
    required this.number,
    required this.city,
    required this.title,
    required this.tagline,
    required this.mainMystery,
    required this.characters,
    required this.locations,
    required this.acts,
    this.plannedCases = plannedCasesPerSeason,
    this.prologue,
    this.outro = const [],
    this.finale = const [],
    this.figures = const [],
    this.languageArc = const [],
    this.places = const [],
    this.storyGreeting,
    this.art,
    this.notes = const [],
  });

  final String seasonId;
  final int number;
  final String city;
  final String title;
  final String tagline;
  final int plannedCases;
  final MainMystery mainMystery;
  final List<CharacterPlan> characters;
  final List<LocationPlan> locations;
  final List<ActPlan> acts;
  final ProloguePlan? prologue;
  final List<String> outro;
  final List<String> finale;
  final List<FigurePlan> figures;

  /// The season's English, act by act (a line each, for the writers).
  final List<String> languageArc;

  /// The pictures of the places its missions happen at (`SeasonContent.places`):
  /// needed once a case is made into the game's content (`PlayCheck`).
  final List<PlacePlan> places;

  /// `SeasonContent.storyGreeting` as written (null: not given, the game's
  /// own true).
  final bool? storyGreeting;

  /// Its cover, map and World Map city, once drawn (the game target).
  final SeasonArtPlan? art;

  /// Anything the writers or a reviewer should know (never content).
  final List<String> notes;

  /// Every case id of the acts, in order.
  List<String> get caseIds => [for (final a in acts) ...a.caseIds];

  factory SeasonPlan.fromJson(Object? json, {String path = r'$'}) {
    final r = _Reader(json, path);
    _version(r);
    final out = SeasonPlan(
      seasonId: r.str('seasonId', pattern: PlanIds.season),
      number: r.integer('number', min: 1),
      city: r.str('city'),
      title: r.str('title'),
      tagline: r.str('tagline'),
      plannedCases: r.integer('plannedCases', only: plannedCasesPerSeason),
      mainMystery: r.obj('mainMystery', MainMystery.fromJson),
      characters: r.objs('characters', CharacterPlan.fromJson, min: 1),
      locations: r.objs('locations', LocationPlan.fromJson, min: 1),
      acts: r.objs('acts', ActPlan.fromJson, min: actsPerSeason, max: actsPerSeason),
      prologue: r.optObj('prologue', ProloguePlan.fromJson),
      outro: r.optStrings('outro'),
      finale: r.optStrings('finale'),
      figures: r.optObjs('figures', FigurePlan.fromJson),
      languageArc: r.optStrings('languageArc'),
      places: r.optObjs('places', PlacePlan.fromJson),
      storyGreeting: r.optBool('storyGreeting'),
      art: r.optObj('art', SeasonArtPlan.fromJson),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'schemaVersion': planSchemaVersion,
      'seasonId': seasonId,
      'number': number,
      'city': city,
      'title': title,
      'tagline': tagline,
      'plannedCases': plannedCases,
      'mainMystery': mainMystery.toJson(),
      'characters': [for (final c in characters) c.toJson()],
      'locations': [for (final l in locations) l.toJson()],
      'acts': [for (final a in acts) a.toJson()],
    };
    if (prologue case final p?) json['prologue'] = p.toJson();
    _putList(json, 'outro', outro);
    _putList(json, 'finale', finale);
    _putList(json, 'figures', [for (final f in figures) f.toJson()]);
    _putList(json, 'languageArc', languageArc);
    _putList(json, 'places', [for (final p in places) p.toJson()]);
    if (storyGreeting != null) json['storyGreeting'] = storyGreeting;
    if (art case final a?) json['art'] = a.toJson();
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── CasePlan ─────────────────────────────────────────────────────────────

/// A case's words as the game shows them (`Episode`, its keys): written
/// into the plan, never made up by the generator. Every field is optional
/// while the case is planned; `PlayCheck` asks for what the game needs.
class CasePlayPlan {
  const CasePlayPlan({
    this.objectives = const [],
    this.intro = const [],
    this.caseSummary,
    this.place,
    this.keyWords = const [],
    this.glossary = const {},
  });

  /// The case file's briefing; the plan's `goal` when empty.
  final List<String> objectives;

  /// The Story Intro's lines.
  final List<String> intro;

  /// The Case Solved report's line (the game's London line when missing).
  final String? caseSummary;
  final String? place;
  final List<String> keyWords;

  /// A word (lower case) → its meaning.
  final Map<String, String> glossary;

  factory CasePlayPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = CasePlayPlan(
      objectives: r.optStrings('objectives'),
      intro: r.optStrings('intro'),
      caseSummary: r.optStr('caseSummary'),
      place: r.optStr('place'),
      keyWords: r.optStrings('keyWords'),
      glossary: r.optTextMap('glossary'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putList(json, 'objectives', objectives);
    _putList(json, 'intro', intro);
    _putText(json, 'caseSummary', caseSummary);
    _putText(json, 'place', place);
    _putList(json, 'keyWords', keyWords);
    _putMap(json, 'glossary', glossary);
    return json;
  }
}

/// A case's language topic (the game's `CaseLanguageTopic`).
class LearningGoal {
  const LearningGoal({required this.title, required this.titleKo});

  final String title;
  final String titleKo;

  factory LearningGoal.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LearningGoal(title: r.str('title'), titleKo: r.str('titleKo'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'title': title, 'titleKo': titleKo};
}

/// One case, planned: its story, its missions in order and its final.
class CasePlan {
  const CasePlan({
    required this.caseId,
    required this.seasonId,
    required this.number,
    required this.actId,
    required this.title,
    required this.synopsis,
    required this.goal,
    required this.characters,
    required this.locations,
    required this.missions,
    required this.finalMission,
    required this.hook,
    required this.learningGoal,
    this.play,
    this.notes = const [],
  });

  final String caseId;
  final String seasonId;
  final int number;
  final String actId;
  final String title;

  /// The case file's lines (`Episode.synopsis`).
  final List<String> synopsis;

  /// What the detective sets out to find (for the writers).
  final String goal;

  /// Its people and places: ids of its season plan.
  final List<String> characters;
  final List<String> locations;

  /// Its missions before the final, in play order (`m1`, `m2`…).
  final List<MissionPlan> missions;

  /// Its final (JSON key `final`).
  final MissionPlan finalMission;

  /// What it leaves unanswered (`Episode.hook`).
  final String hook;
  final LearningGoal learningGoal;

  /// Its words as the game shows them; null while only its structure is planned.
  final CasePlayPlan? play;
  final List<String> notes;

  /// Its missions and its final, in play order.
  List<MissionPlan> get allMissions => [...missions, finalMission];

  factory CasePlan.fromJson(Object? json, {String path = r'$'}) {
    final r = _Reader(json, path);
    _version(r);
    final out = CasePlan(
      caseId: r.str('caseId', pattern: PlanIds.caseId),
      seasonId: r.str('seasonId', pattern: PlanIds.season),
      number: r.integer('number', min: 1, max: plannedCasesPerSeason),
      actId: r.str('actId', pattern: PlanIds.act),
      title: r.str('title'),
      synopsis: r.strings('synopsis', min: 1),
      goal: r.str('goal'),
      characters: r.strings('characters', pattern: PlanIds.local, unique: true),
      locations: r.strings('locations', min: 1, pattern: PlanIds.local, unique: true),
      missions: r.objs('missions', MissionPlan.fromJson, min: minMissionsPerCase, max: maxMissionsPerCase),
      finalMission: r.obj('final', MissionPlan.fromJson),
      hook: r.str('hook'),
      learningGoal: r.obj('learningGoal', LearningGoal.fromJson),
      play: r.optObj('play', CasePlayPlan.fromJson),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'schemaVersion': planSchemaVersion,
      'caseId': caseId,
      'seasonId': seasonId,
      'number': number,
      'actId': actId,
      'title': title,
      'synopsis': synopsis,
      'goal': goal,
      'characters': characters,
      'locations': locations,
      'missions': [for (final m in missions) m.toJson()],
      'final': finalMission.toJson(),
      'hook': hook,
      'learningGoal': learningGoal.toJson(),
    };
    if (play case final p?) json['play'] = p.toJson();
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── MissionPlan ──────────────────────────────────────────────────────────

/// A clue a mission is given: what it names, and how it is used.
class ClueInput {
  const ClueInput({required this.ref, required this.use, this.note});

  /// A clue, evidence or fact id (of this case or an earlier one).
  final String ref;
  final ClueUse use;
  final String? note;

  factory ClueInput.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueInput(
      ref: r.str('ref', pattern: PlanIds.clueRef),
      use: r.enumOf('use', ClueUse.values),
      note: r.optStr('note'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'ref': ref, 'use': use.name};
    _putText(json, 'note', note);
    return json;
  }
}

/// What a mission leaves the detective: its notebook clue (`Mission.clue`),
/// its evidence (`Mission.evidence`) and the story facts it shows.
class ClueOutputs {
  const ClueOutputs({required this.evidence, this.clue, this.facts = const []});

  final String? clue;
  final String evidence;
  final List<String> facts;

  factory ClueOutputs.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueOutputs(
      clue: r.optStr('clue', pattern: PlanIds.clue),
      evidence: r.str('evidence', pattern: PlanIds.evidence),
      facts: r.optStrings('facts', pattern: PlanIds.fact, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'clue', clue);
    json['evidence'] = evidence;
    _putList(json, 'facts', facts);
    return json;
  }
}

/// What a mission is designed to do with English: the game's
/// `LearningObjective`, field for field (its enums by name).
class LearningPlan {
  const LearningPlan({
    required this.dependency,
    required this.level,
    required this.objective,
    this.skill,
    this.expressions = const [],
    this.recallFrom,
  });

  final String dependency;
  final String level;

  /// One sentence for the parent report, in Korean.
  final String objective;
  final String? skill;
  final List<String> expressions;

  /// The earlier mission whose English is read again.
  final String? recallFrom;

  factory LearningPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = LearningPlan(
      dependency: r.str('dependency', oneOf: PlanVocabulary.dependencies),
      level: r.str('level', oneOf: PlanVocabulary.learningLevels),
      objective: r.str('objective'),
      skill: r.optStr('skill', oneOf: PlanVocabulary.skills),
      expressions: r.optStrings('expressions'),
      recallFrom: r.optStr('recallFrom', pattern: PlanIds.mission),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'dependency': dependency, 'level': level, 'objective': objective};
    _putText(json, 'skill', skill);
    _putList(json, 'expressions', expressions);
    _putText(json, 'recallFrom', recallFrom);
    return json;
  }
}

/// The notebook clue's words (`Clue`, its id the mission's `clueOutputs.clue`).
class ClueText {
  const ClueText({required this.title, required this.value, required this.note, this.symbol});

  final String title;
  final String value;
  final String note;

  /// A `GameSymbol` key.
  final String? symbol;

  factory ClueText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ClueText(title: r.str('title'), value: r.str('value'), note: r.str('note'), symbol: r.optStr('symbol'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'title': title, 'value': value, 'note': note};
    _putText(json, 'symbol', symbol);
    return json;
  }
}

/// The evidence's words (`Evidence`, its id the mission's `clueOutputs.evidence`).
class EvidenceText {
  const EvidenceText({required this.name, required this.icon, required this.description, this.inscription, this.symbols = const []});

  final String name;

  /// A `GameSymbol` key.
  final String icon;
  final String description;
  final String? inscription;

  /// `GameSymbol` keys.
  final List<String> symbols;

  factory EvidenceText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = EvidenceText(
      name: r.str('name'),
      icon: r.str('icon'),
      description: r.str('description'),
      inscription: r.optStr('inscription'),
      symbols: r.optStrings('symbols'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'name': name, 'icon': icon, 'description': description};
    _putText(json, 'inscription', inscription);
    _putList(json, 'symbols', symbols);
    return json;
  }
}

/// The words of a recall card (`EvidenceRecall`, its evidence the mission's
/// one `recall` clue input).
class RecallText {
  const RecallText({this.title, this.prompt, this.feedback = const {}, this.miss});

  final String? title;
  final String? prompt;

  /// Evidence id → a line for it picked instead.
  final Map<String, String> feedback;
  final String? miss;

  factory RecallText.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = RecallText(title: r.optStr('title'), prompt: r.optStr('prompt'), feedback: r.optTextMap('feedback'), miss: r.optStr('miss'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'title', title);
    _putText(json, 'prompt', prompt);
    _putMap(json, 'feedback', feedback);
    _putText(json, 'miss', miss);
    return json;
  }
}

// ── Scenes (STEP 3-13) ───────────────────────────────────────────────────
//
// A mission played on a picture: what its engine's table entry holds
// (`ExploreScene`, `InvestigationScene`, `DialogueScene`), with places on
// its pictures in the pictures' own pixels, as they are measured on the
// file. The generator turns them into fractions of the picture (the game's
// `ScenePixels.rect`), so a tap lands on the same spot at every screen size
// and every crop the engine makes (`inside`, `opening`).

/// A point on a picture, in its pixels.
class ScenePoint {
  ScenePoint._(List<double> xy) : x = xy[0], y = xy[1];
  const ScenePoint(this.x, this.y);

  final double x;
  final double y;

  List<num> toJson() => [_whole(x), _whole(y)];
}

/// A rectangle on a picture, in its pixels.
class SceneRect {
  SceneRect._(List<double> ltrb) : left = ltrb[0], top = ltrb[1], right = ltrb[2], bottom = ltrb[3];
  const SceneRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  List<num> toJson() => [_whole(left), _whole(top), _whole(right), _whole(bottom)];
}

List<List<num>> _rectsJson(List<SceneRect> rects) => [for (final r in rects) r.toJson()];

/// A whole number of pixels as a whole number (`282`, never `282.0`).
num _whole(double v) => v == v.truncateToDouble() ? v.toInt() : v;

/// A picture file and its size in pixels (the file's own: `PlayCheck`
/// reads it).
class PicturePlan {
  const PicturePlan({required this.file, required this.width, required this.height, this.measuredOn});

  /// From the repository's root (`assets/…`).
  final String file;
  final int width;
  final int height;

  /// The file's hash (`sha256:…`) when the places on it were measured on
  /// the drawn picture (STEP 3-15A). Null: not measured yet (the places are
  /// where a prompt put things). A scene's places are played only when this
  /// is its file's hash now (`PlayCheck`: `coordinates_unmeasured`,
  /// `coordinates_stale`).
  final String? measuredOn;

  static final _hash = RegExp(r'^sha256:[0-9a-f]{64}$');

  factory PicturePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final size = r.obj('pixels', _pixels);
    final out = PicturePlan(
      file: r.str('file', pattern: PlanIds.assetFile),
      width: size.$1,
      height: size.$2,
      measuredOn: r.optStr('measuredOn', pattern: _hash),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'file': file,
    'pixels': {'width': width, 'height': height},
    'measuredOn': ?measuredOn,
  };
}

(int, int) _pixels(Object? json, String path) {
  final p = _Reader(json, path);
  final size = (p.integer('width', min: 1), p.integer('height', min: 1));
  p.done();
  return size;
}

/// A place on a picture that holds nothing (`InvestigationSpot`): a tap
/// says why.
class EmptySpotPlan {
  const EmptySpotPlan({required this.label, required this.areas, required this.line});

  /// What it is, for screen readers.
  final String label;
  final List<SceneRect> areas;
  final String line;

  factory EmptySpotPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = EmptySpotPlan(label: r.str('label'), areas: r.rects('areas'), line: r.str('line'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'label': label, 'areas': _rectsJson(areas), 'line': line};
}

/// The kinds of `ExploreKind`.
const exploreKinds = ['document', 'note', 'choice'];

/// A thing to look at when the place is looked round (`ExploreSpot`).
class ExploreSpotPlan {
  const ExploreSpotPlan({
    required this.id,
    required this.kind,
    required this.title,
    required this.label,
    required this.areas,
    required this.mark,
    this.line,
    this.requires,
    this.lockedLine,
    this.unreadLine,
  });

  final String id;

  /// `document` (holds the mission's letter), `note` (a line worth
  /// remembering) or `choice` (opens the puzzle's pictures).
  final String kind;
  final String title;

  /// What it is, for screen readers.
  final String label;
  final List<SceneRect> areas;

  /// Where its small glass sits.
  final ScenePoint mark;
  final String? line;
  final String? requires;
  final String? lockedLine;
  final String? unreadLine;

  factory ExploreSpotPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ExploreSpotPlan(
      id: r.str('id', pattern: PlanIds.local),
      kind: r.str('kind', oneOf: exploreKinds),
      title: r.str('title'),
      label: r.str('label'),
      areas: r.rects('areas'),
      mark: r.point('mark'),
      line: r.optStr('line'),
      requires: r.optStr('requires', pattern: PlanIds.local),
      lockedLine: r.optStr('lockedLine'),
      unreadLine: r.optStr('unreadLine'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'kind': kind,
      'title': title,
      'label': label,
      'areas': _rectsJson(areas),
      'mark': mark.toJson(),
    };
    _putText(json, 'line', line);
    _putText(json, 'requires', requires);
    _putText(json, 'lockedLine', lockedLine);
    _putText(json, 'unreadLine', unreadLine);
    return json;
  }
}

/// One picture of a look round's choice (`ExplorePicture`), for its option.
class ExploreChoicePlan {
  const ExploreChoicePlan({required this.optionId, required this.picture, required this.description});

  final String optionId;

  /// Its file, from the repository's root.
  final String picture;

  /// What it shows, for screen readers (never which one is right).
  final String description;

  factory ExploreChoicePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ExploreChoicePlan(
      optionId: r.str('optionId'),
      picture: r.str('picture', pattern: PlanIds.assetFile),
      description: r.str('description'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'optionId': optionId, 'picture': picture, 'description': description};
}

/// A mission played by looking round its place (`ExploreScene`, table
/// `explores`): the letter is found in the picture, then the puzzle's
/// option chosen among its pictures.
class ExplorePlan {
  const ExplorePlan({
    required this.picture,
    required this.place,
    required this.task,
    required this.nextTask,
    required this.missLine,
    required this.guideAt,
    required this.spots,
    required this.choiceTitle,
    required this.choiceHow,
    required this.choicePixels,
    required this.choices,
    this.others = const [],
    this.inside,
    this.opening,
    this.documentLabel,
  });

  final PicturePlan picture;

  /// The place, for screen readers.
  final String place;
  final String task;
  final String nextTask;
  final String missLine;
  final ScenePoint guideAt;
  final List<ExploreSpotPlan> spots;
  final List<EmptySpotPlan> others;
  final String choiceTitle;
  final String choiceHow;

  /// The size of every choice picture (one shape for all).
  final (int, int) choicePixels;
  final List<ExploreChoicePlan> choices;
  final SceneRect? inside;
  final SceneRect? opening;
  final String? documentLabel;

  factory ExplorePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = ExplorePlan(
      picture: r.obj('picture', PicturePlan.fromJson),
      place: r.str('place'),
      task: r.str('task'),
      nextTask: r.str('nextTask'),
      missLine: r.str('missLine'),
      guideAt: r.point('guideAt'),
      spots: r.objs('spots', ExploreSpotPlan.fromJson, min: 2),
      others: r.optObjs('others', EmptySpotPlan.fromJson),
      choiceTitle: r.str('choiceTitle'),
      choiceHow: r.str('choiceHow'),
      choicePixels: r.obj('choicePixels', _pixels),
      choices: r.objs('choices', ExploreChoicePlan.fromJson, min: 2),
      inside: r.optRect('inside'),
      opening: r.optRect('opening'),
      documentLabel: r.optStr('documentLabel'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'picture': picture.toJson(),
      'place': place,
      'task': task,
      'nextTask': nextTask,
      'missLine': missLine,
      'guideAt': guideAt.toJson(),
      'spots': [for (final s in spots) s.toJson()],
    };
    _putList(json, 'others', [for (final o in others) o.toJson()]);
    json['choiceTitle'] = choiceTitle;
    json['choiceHow'] = choiceHow;
    json['choicePixels'] = {'width': choicePixels.$1, 'height': choicePixels.$2};
    json['choices'] = [for (final c in choices) c.toJson()];
    if (inside case final r?) json['inside'] = r.toJson();
    if (opening case final r?) json['opening'] = r.toJson();
    _putText(json, 'documentLabel', documentLabel);
    return json;
  }
}

/// A thing to find in a searched room (`InvestigationFind`).
class SearchFindPlan {
  const SearchFindPlan({
    required this.id,
    required this.name,
    required this.title,
    required this.reportLine,
    required this.spot,
    required this.areas,
    required this.foundLine,
    required this.picture,
    required this.at,
    required this.width,
    this.squash,
    this.turn,
  });

  final String id;
  final String name;
  final String title;

  /// The letter's line that says where it is, word for word.
  final String reportLine;

  /// Where it is, for screen readers (the place, never the thing).
  final String spot;
  final List<SceneRect> areas;
  final String foundLine;

  /// The thing, cut out, laid on the room where it was found.
  final PicturePlan picture;

  /// Its centre on the room, and its width on the room (in the room's pixels).
  final ScenePoint at;
  final double width;
  final double? squash;
  final double? turn;

  factory SearchFindPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = SearchFindPlan(
      id: r.str('id', pattern: PlanIds.local),
      name: r.str('name'),
      title: r.str('title'),
      reportLine: r.str('reportLine'),
      spot: r.str('spot'),
      areas: r.rects('areas'),
      foundLine: r.str('foundLine'),
      picture: r.obj('picture', PicturePlan.fromJson),
      at: r.point('at'),
      width: r.optNum('width', min: 1) ?? r._fail('width', 'missing'),
      squash: r.optNum('squash', min: 0.1, max: 1),
      turn: r.optNum('turn', min: -3.2, max: 3.2),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'name': name,
      'title': title,
      'reportLine': reportLine,
      'spot': spot,
      'areas': _rectsJson(areas),
      'foundLine': foundLine,
      'picture': picture.toJson(),
      'at': at.toJson(),
      'width': _whole(width),
    };
    if (squash != null) json['squash'] = squash;
    if (turn != null) json['turn'] = turn;
    return json;
  }
}

/// A mission played by searching its place for what its letter lists
/// (`InvestigationScene`, table `investigations`): the last thing found
/// answers the puzzle.
class SearchPlan {
  const SearchPlan({
    required this.picture,
    required this.task,
    required this.documentTitle,
    required this.missLine,
    required this.doneLine,
    required this.arrival,
    required this.guideAt,
    required this.finds,
    this.spots = const [],
    this.opening,
    this.inside,
    this.startLabel,
    this.documentLabel,
  });

  final PicturePlan picture;
  final String task;
  final String documentTitle;
  final String missLine;
  final String doneLine;
  final List<String> arrival;
  final ScenePoint guideAt;
  final List<SearchFindPlan> finds;
  final List<EmptySpotPlan> spots;
  final SceneRect? opening;
  final SceneRect? inside;
  final String? startLabel;
  final String? documentLabel;

  factory SearchPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = SearchPlan(
      picture: r.obj('picture', PicturePlan.fromJson),
      task: r.str('task'),
      documentTitle: r.str('documentTitle'),
      missLine: r.str('missLine'),
      doneLine: r.str('doneLine'),
      arrival: r.strings('arrival', min: 1),
      guideAt: r.point('guideAt'),
      finds: r.objs('finds', SearchFindPlan.fromJson, min: 1),
      spots: r.optObjs('spots', EmptySpotPlan.fromJson),
      opening: r.optRect('opening'),
      inside: r.optRect('inside'),
      startLabel: r.optStr('startLabel'),
      documentLabel: r.optStr('documentLabel'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'picture': picture.toJson(),
      'task': task,
      'documentTitle': documentTitle,
      'missLine': missLine,
      'doneLine': doneLine,
      'arrival': arrival,
      'guideAt': guideAt.toJson(),
      'finds': [for (final f in finds) f.toJson()],
    };
    _putList(json, 'spots', [for (final s in spots) s.toJson()]);
    if (opening case final r?) json['opening'] = r.toJson();
    if (inside case final r?) json['inside'] = r.toJson();
    _putText(json, 'startLabel', startLabel);
    _putText(json, 'documentLabel', documentLabel);
    return json;
  }
}

/// A question any witness can be asked (`DialogueQuestion`).
class TalkQuestionPlan {
  const TalkQuestionPlan({required this.id, required this.text});

  final String id;
  final String text;

  factory TalkQuestionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TalkQuestionPlan(id: r.str('id', pattern: PlanIds.local), text: r.str('text'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'id': id, 'text': text};
}

/// A witness's answer to one question. With [thing], it is a statement
/// written in the notes (`DialogueStatement`, its id `<witness>.<question>`):
/// two statements match when their things are the same.
class TalkAnswerPlan {
  const TalkAnswerPlan({required this.line, this.thing});

  final String line;
  final String? thing;

  factory TalkAnswerPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TalkAnswerPlan(line: r.str('line'), thing: r.optStr('thing'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'line': line};
    _putText(json, 'thing', thing);
    return json;
  }
}

/// A witness (`DialogueSpeaker`).
class TalkWitnessPlan {
  const TalkWitnessPlan({
    required this.id,
    required this.name,
    required this.title,
    required this.portrait,
    required this.description,
    required this.greeting,
    required this.answers,
    this.face,
  });

  final String id;
  final String name;
  final String title;

  /// Their portrait file, from the repository's root.
  final String portrait;

  /// What the portrait shows, for screen readers.
  final String description;
  final String greeting;

  /// By question id.
  final Map<String, TalkAnswerPlan> answers;

  /// Where their face is in the portrait, as fractions (0..1).
  final (double, double)? face;

  factory TalkWitnessPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final answersAt = '$path.answers';
    final out = TalkWitnessPlan(
      id: r.str('id', pattern: PlanIds.local),
      name: r.str('name'),
      title: r.str('title'),
      portrait: r.str('portrait', pattern: PlanIds.assetFile),
      description: r.str('description'),
      greeting: r.str('greeting'),
      answers: {
        for (final e in _Reader._object(r._required('answers'), answersAt).entries)
          e.key: TalkAnswerPlan.fromJson(e.value, '$answersAt.${e.key}'),
      },
      face: r.optObj('face', (json, path) {
        final f = _Reader(json, path);
        final out = (f.optNum('x', min: 0, max: 1) ?? f._fail('x', 'missing'), f.optNum('y', min: 0, max: 1) ?? f._fail('y', 'missing'));
        f.done();
        return out;
      }),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'name': name,
      'title': title,
      'portrait': portrait,
      'description': description,
      'greeting': greeting,
      'answers': {for (final MapEntry(:key, :value) in answers.entries) key: value.toJson()},
    };
    if (face case (final x, final y)) json['face'] = {'x': x, 'y': y};
    return json;
  }
}

/// The deduction that ends a talk (`DialogueDeduction`); its answer is the
/// puzzle's (`answerSpec.answer`).
class TalkDeductionPlan {
  const TalkDeductionPlan({
    required this.topic,
    required this.pair,
    required this.lines,
    this.then = const [],
    this.witnesses,
  });

  /// The question id the two matching statements answer.
  final String topic;

  /// The two statement ids (`<witness>.<question>`) that answer it.
  final List<String> pair;

  /// Statements still to be found once it is made.
  final List<String> then;
  final int? witnesses;

  /// Its lines, by the game's names ([requiredLines], then [thenLines]).
  final Map<String, String> lines;

  static const requiredLines = [
    'askLine', 'anotherLine', 'readyLine', 'compareGoal', 'compareHow', //
    'matchLine', 'offTopicLine', 'checkLine', 'differentLine', 'retryLine',
  ];

  /// Said only when [then] has statements.
  static const thenLines = ['thenGoal', 'thenHow', 'doneLine', 'notesLine'];

  factory TalkDeductionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TalkDeductionPlan(
      topic: r.str('topic', pattern: PlanIds.local),
      pair: r.strings('pair', min: 2, max: 2, unique: true),
      then: r.optStrings('then', unique: true),
      witnesses: r.optInt('witnesses', min: 1),
      lines: {
        for (final k in requiredLines) k: r.str(k),
        for (final k in thenLines) k: ?r.optStr(k),
      },
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'topic': topic, 'pair': pair};
    _putList(json, 'then', then);
    if (witnesses != null) json['witnesses'] = witnesses;
    for (final k in [...requiredLines, ...thenLines]) {
      _putText(json, k, lines[k]);
    }
    return json;
  }
}

/// A mission played by talking to its witnesses (`DialogueScene`, table
/// `dialogues`): questions asked, statements written down, two compared.
class DialoguePlan {
  const DialoguePlan({
    required this.place,
    required this.background,
    required this.goal,
    required this.how,
    required this.guide,
    required this.questions,
    required this.witnesses,
    required this.deduction,
  });

  final String place;

  /// The place behind the people, from the repository's root.
  final String background;
  final String goal;
  final String how;
  final String guide;
  final List<TalkQuestionPlan> questions;
  final List<TalkWitnessPlan> witnesses;
  final TalkDeductionPlan deduction;

  /// `<witness>.<question>` of every answer that is a statement.
  Map<String, (TalkWitnessPlan, String, TalkAnswerPlan)> get statements => {
    for (final w in witnesses)
      for (final MapEntry(key: q, value: a) in w.answers.entries)
        if (a.thing != null) '${w.id}.$q': (w, q, a),
  };

  factory DialoguePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = DialoguePlan(
      place: r.str('place'),
      background: r.str('background', pattern: PlanIds.assetFile),
      goal: r.str('goal'),
      how: r.str('how'),
      guide: r.str('guide'),
      questions: r.objs('questions', TalkQuestionPlan.fromJson, min: 1),
      witnesses: r.objs('witnesses', TalkWitnessPlan.fromJson, min: 2),
      deduction: r.obj('deduction', TalkDeductionPlan.fromJson),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'place': place,
    'background': background,
    'goal': goal,
    'how': how,
    'guide': guide,
    'questions': [for (final q in questions) q.toJson()],
    'witnesses': [for (final w in witnesses) w.toJson()],
    'deduction': deduction.toJson(),
  };
}

/// A mission's words as the game shows them (`Mission`, its keys). What the
/// plan already holds (its id, order, place, type, answer, options) is not
/// repeated here. Every field is optional while the mission is planned;
/// `PlayCheck` asks for what the game needs.
// ── Around the puzzle (STEP 3-13B) ───────────────────────────────────────

/// Who says a line of a talk or an ending (the game's `TalkVoice`): the
/// person talked to, the detective (YOU), or the story's narrator.
enum TalkBy { speaker, detective, narrator }

/// One short line of a talk around a puzzle (`TalkLine`).
class TalkLinePlan {
  const TalkLinePlan({required this.by, required this.text});

  final TalkBy by;
  final String text;

  factory TalkLinePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TalkLinePlan(by: r.enumOf('by', TalkBy.values), text: r.str('text'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'by': by.name, 'text': text};
}

/// The talk before or after a puzzle: its lines, and the button that goes
/// on from it (the game's CONTINUE when not given).
class TalkPartPlan {
  const TalkPartPlan({required this.lines, this.finishLabel, this.presents = const []});

  final List<TalkLinePlan> lines;
  final String? finishLabel;

  /// The evidence to show, each once, before the talk goes on (the talk
  /// before a final's puzzle only: `PlayCheck`). Empty: only listened to.
  final List<InterviewPresentPlan> presents;

  factory TalkPartPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TalkPartPlan(
      lines: r.objs('lines', TalkLinePlan.fromJson, min: 1),
      finishLabel: r.optStr('finishLabel'),
      presents: r._has('presents') ? r.objs('presents', InterviewPresentPlan.fromJson, min: 1) : const [],
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'lines': [for (final l in lines) l.toJson()]};
    _putText(json, 'finishLabel', finishLabel);
    if (presents.isNotEmpty) json['presents'] = [for (final p in presents) p.toJson()];
    return json;
  }
}

/// The talks around a mission's puzzle with one person of the case
/// (`TalkMission`): [before] it, [after] it, or both. Its place and the
/// picture behind it are the mission's own; [portrait] is the person's
/// picture (none: no portrait is shown, never a stand-in).
class MissionTalkPlan {
  const MissionTalkPlan({required this.speaker, this.portrait, required this.goal, this.before, this.after});

  /// A charId of the case's characters (their name from the season plan).
  final String speaker;
  final String? portrait;

  /// What the detective is finding out, one line over the talk.
  final String goal;
  final TalkPartPlan? before;
  final TalkPartPlan? after;

  factory MissionTalkPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MissionTalkPlan(
      speaker: r.str('speaker', pattern: PlanIds.local),
      portrait: r.optStr('portrait', pattern: PlanIds.assetFile),
      goal: r.str('goal'),
      before: r.optObj('before', TalkPartPlan.fromJson),
      after: r.optObj('after', TalkPartPlan.fromJson),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'speaker': speaker};
    _putText(json, 'portrait', portrait);
    json['goal'] = goal;
    if (before case final b?) json['before'] = b.toJson();
    if (after case final a?) json['after'] = a.toJson();
    return json;
  }
}

/// A mission's own Discovery Moment (`Discovery`): what was found
/// ([title]), why it matters and where it leads ([detail]).
class DiscoveryPlan {
  const DiscoveryPlan({
    required this.type,
    this.timing,
    required this.title,
    required this.detail,
    this.note,
    this.showEvidence,
    this.seasonClue,
  });

  /// The game's `DiscoveryType` names (its fallback, a solved puzzle, is
  /// what a mission without a discovery shows).
  static const types = ['evidenceFound', 'clueFound', 'clueConfirmed', 'deduction', 'newLead', 'storyDiscovery'];

  /// The game's `DiscoveryTiming` names.
  static const timings = ['beforePuzzle', 'fromPuzzle', 'afterPuzzle'];

  final String type;

  /// When the detective first had it (null: from the puzzle).
  final String? timing;
  final String title;
  final String detail;

  /// A fact seen before the puzzle the notebook keeps (shown small).
  final String? note;

  /// Lay the mission's evidence on screen (only evidence the puzzle puts in
  /// the detective's hands).
  final bool? showEvidence;
  final bool? seasonClue;

  String get timingOrDefault => timing ?? 'fromPuzzle';

  factory DiscoveryPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = DiscoveryPlan(
      type: r.str('type', oneOf: types),
      timing: r.optStr('timing', oneOf: timings),
      title: r.str('title'),
      detail: r.str('detail'),
      note: r.optStr('note'),
      showEvidence: r.optBool('showEvidence'),
      seasonClue: r.optBool('seasonClue'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'type': type};
    _putText(json, 'timing', timing);
    json['title'] = title;
    json['detail'] = detail;
    _putText(json, 'note', note);
    if (showEvidence != null) json['showEvidence'] = showEvidence;
    if (seasonClue != null) json['seasonClue'] = seasonClue;
    return json;
  }
}

/// One line of a final's ending (`EndingLine`), over the final's place: a
/// [speaker]'s (a charId of the case, with their [portrait] if any), the
/// detective's or the narrator's, a piece of [evidence] laid over it.
class EndingLinePlan {
  const EndingLinePlan({required this.by, required this.text, this.speaker, this.portrait, this.evidence});

  final TalkBy by;
  final String text;
  final String? speaker;
  final String? portrait;
  final String? evidence;

  factory EndingLinePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = EndingLinePlan(
      by: r.enumOf('by', TalkBy.values),
      text: r.str('text'),
      speaker: r.optStr('speaker', pattern: PlanIds.local),
      portrait: r.optStr('portrait', pattern: PlanIds.assetFile),
      evidence: r.optStr('evidence', pattern: PlanIds.evidence),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'by': by.name, 'text': text};
    _putText(json, 'speaker', speaker);
    _putText(json, 'portrait', portrait);
    _putText(json, 'evidence', evidence);
    return json;
  }
}

/// A timeline's card (Puzzle Engine 2.0, `timeline_board`; `TimelineCard`).
/// An [anchor] (its time, written on it) is fixed in its place; a [discard]
/// is not part of what happened. In a historical season each card says
/// where it comes from: [factIds] (approved facts of its dossier) or
/// [fiction] (made up for the mystery).
class TimelineCardPlan {
  const TimelineCardPlan({required this.id, required this.title, required this.text, this.anchor, this.discard = false, this.evidence, this.factIds = const [], this.fiction = false});

  final String id;
  final String title;
  final String text;
  final String? anchor;
  final bool discard;
  final String? evidence;
  final List<String> factIds;
  final bool fiction;

  static final _factId = RegExp(r'^s[1-9][0-9]*_ep[0-9]{2}_h[1-9][0-9]*$');

  factory TimelineCardPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TimelineCardPlan(
      id: r.str('id', pattern: PlanIds.local),
      title: r.str('title'),
      text: r.str('text'),
      anchor: r.optStr('anchor'),
      discard: r.optBool('discard') ?? false,
      evidence: r.optStr('evidence', pattern: PlanIds.evidence),
      factIds: r.optStrings('factIds', pattern: _factId, unique: true),
      fiction: r.optBool('fiction') ?? false,
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'title': title, 'text': text};
    _putText(json, 'anchor', anchor);
    if (discard) json['discard'] = true;
    _putText(json, 'evidence', evidence);
    _putList(json, 'factIds', factIds);
    if (fiction) json['fiction'] = true;
    return json;
  }
}

/// What the case's words say of two cards: [earlier] came before [later].
/// [line] is those words, read in the mission (its letter, word for word).
class TimelineRelationPlan {
  const TimelineRelationPlan({required this.earlier, required this.later, required this.line});

  final String earlier;
  final String later;
  final String line;

  factory TimelineRelationPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TimelineRelationPlan(earlier: r.str('earlier', pattern: PlanIds.local), later: r.str('later', pattern: PlanIds.local), line: r.str('line'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'earlier': earlier, 'later': later, 'line': line};
}

/// A timeline to put back together (`TimelineSpec`, table `timelines`): its
/// cards and the words that order them. The order is the puzzle's answer
/// (`answerSpec.answer`, a sequence's), its options the cards.
class TimelinePlan {
  const TimelinePlan({required this.cards, required this.relations});

  final List<TimelineCardPlan> cards;
  final List<TimelineRelationPlan> relations;

  factory TimelinePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TimelinePlan(
      cards: r.objs('cards', TimelineCardPlan.fromJson, min: 3, max: 11),
      relations: r.objs('relations', TimelineRelationPlan.fromJson, min: 1),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'cards': [for (final c in cards) c.toJson()],
    'relations': [for (final x in relations) x.toJson()],
  };
}

/// One written group of a note in the new letters (`SyllableBlock`): its
/// first sound, the vowel to build, the sound under it, and the words that
/// tell how its vowel looked ([line], read in the mission). [given]: it comes
/// already written, as an example (at Rookie and Junior, never at Master).
class SyllableBlockPlan {
  const SyllableBlockPlan({required this.id, required this.initial, required this.vowel, this.finalConsonant, required this.line, this.given = false});

  final String id;
  final String initial;
  final String vowel;
  final String? finalConsonant;
  final String line;
  final bool given;

  factory SyllableBlockPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = SyllableBlockPlan(
      id: r.str('id', pattern: PlanIds.local),
      initial: r.str('initial'),
      vowel: r.str('vowel'),
      finalConsonant: r.optStr('final'),
      line: r.str('line'),
      given: r.optBool('given') ?? false,
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'initial': initial, 'vowel': vowel};
    _putText(json, 'final', finalConsonant);
    json['line'] = line;
    if (given) json['given'] = true;
    return json;
  }
}

/// A note in the new letters to put back together (`SyllableSpec`, table
/// `syllables`; Puzzle Engine 2.0): its groups in the note's order. The
/// note they write is the puzzle's answer (a `wordInput`'s). In a
/// historical season its sources are the puzzle's, in the dossier.
class SyllablesPlan {
  const SyllablesPlan({required this.blocks, this.sounds = const [], this.columnHeight});

  final List<SyllableBlockPlan> blocks;

  /// The first sounds the player chooses from (empty: each group's is given).
  final List<String> sounds;

  /// Groups in a column, written down the page from the right (null: one row).
  final int? columnHeight;

  factory SyllablesPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = SyllablesPlan(
      blocks: r.objs('blocks', SyllableBlockPlan.fromJson, min: 2, max: 6),
      sounds: r.optStrings('sounds', unique: true),
      columnHeight: r.optInt('columnHeight', min: 1),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'blocks': [for (final b in blocks) b.toJson()],
    if (sounds.isNotEmpty) 'sounds': sounds,
    'columnHeight': ?columnHeight,
  };
}

// ── Existing engines made by the generator (Puzzle Engine 2.0 STEP 1) ────

/// A trace in a [TracesPlan]'s picture (`DeductionClue`): its [line] is one
/// line of the mission's letter, word for word.
class TraceCluePlan {
  const TraceCluePlan({required this.id, required this.label, required this.areas, required this.mark, required this.line, this.sketch});

  /// `TraceSketch` names: a trace the app draws, the picture lacking it.
  static const sketches = ['inkDrops', 'hair', 'paperCorner', 'waterRing', 'waterDrops', 'copiedScrap'];

  final String id;
  final String label;
  final List<SceneRect> areas;
  final ScenePoint mark;
  final String line;
  final String? sketch;

  factory TraceCluePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TraceCluePlan(
      id: r.str('id', pattern: PlanIds.local),
      label: r.str('label'),
      areas: r.rects('areas'),
      mark: r.point('mark'),
      line: r.str('line'),
      sketch: r.optStr('sketch', oneOf: sketches),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() =>
      {'id': id, 'label': label, 'areas': _rectsJson(areas), 'mark': mark.toJson(), 'line': line, 'sketch': ?sketch};
}

/// A place the thing could be (`DeductionPlace`), standing for an option.
class TracePlacePlan {
  const TracePlacePlan({required this.optionId, required this.areas, required this.mark, this.chip});

  final String optionId;
  final List<SceneRect> areas;
  final ScenePoint mark;

  /// Letters shown by its marker while choosing (`DeductionPlace.chip`):
  /// part of its option's label.
  final String? chip;

  factory TracePlacePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TracePlacePlan(optionId: r.str('optionId'), areas: r.rects('areas'), mark: r.point('mark'), chip: r.optStr('chip'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'optionId': optionId, 'areas': _rectsJson(areas), 'mark': mark.toJson(), 'chip': ?chip};
}

/// A place read for its traces (`DeductionScene`, table `deductions`,
/// `trace_deduction`): every trace noted, then the one place they all
/// point to chosen in the picture — the puzzle's option.
class TracesPlan {
  const TracesPlan({
    required this.picture,
    required this.place,
    required this.task,
    required this.chooseTask,
    required this.missLine,
    required this.notPlaceLine,
    required this.guideAt,
    required this.clues,
    required this.places,
    this.others = const [],
    this.inside,
    this.opening,
    this.choosing,
    this.rereadLetter = false,
  });

  final PicturePlan picture;
  final String place;
  final String task;
  final String chooseTask;
  final String missLine;
  final String notPlaceLine;
  final ScenePoint guideAt;
  final List<TraceCluePlan> clues;
  final List<TracePlacePlan> places;
  final List<EmptySpotPlan> others;
  final SceneRect? inside;
  final SceneRect? opening;

  /// What is shown whole once choosing (`DeductionScene.choosing`), when
  /// the places lie outside [opening].
  final SceneRect? choosing;

  /// The letter one tap away while reading (`DeductionScene.rereadLetter`).
  final bool rereadLetter;

  factory TracesPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = TracesPlan(
      picture: r.obj('picture', PicturePlan.fromJson),
      place: r.str('place'),
      task: r.str('task'),
      chooseTask: r.str('chooseTask'),
      missLine: r.str('missLine'),
      notPlaceLine: r.str('notPlaceLine'),
      guideAt: r.point('guideAt'),
      clues: r.objs('clues', TraceCluePlan.fromJson, min: 1),
      places: r.objs('places', TracePlacePlan.fromJson, min: 1),
      others: r.optObjs('others', EmptySpotPlan.fromJson),
      inside: r.optRect('inside'),
      opening: r.optRect('opening'),
      choosing: r.optRect('choosing'),
      rereadLetter: r.optBool('rereadLetter') ?? false,
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'picture': picture.toJson(),
      'place': place,
      'task': task,
      'chooseTask': chooseTask,
      'missLine': missLine,
      'notPlaceLine': notPlaceLine,
      'guideAt': guideAt.toJson(),
      'clues': [for (final c in clues) c.toJson()],
      'places': [for (final p in places) p.toJson()],
    };
    _putList(json, 'others', [for (final o in others) o.toJson()]);
    if (inside case final r?) json['inside'] = r.toJson();
    if (opening case final r?) json['opening'] = r.toJson();
    if (choosing case final r?) json['choosing'] = r.toJson();
    if (rereadLetter) json['rereadLetter'] = true;
    return json;
  }
}

/// The kinds of `InspectKind`.
const inspectKinds = ['exhibit', 'match', 'label', 'hidden'];

/// A thing to look at under the glass (`InspectSpot`). [checks]: the lines
/// of the mission's letter (their index, blank lines not counted) it confirms.
class InspectSpotPlan {
  const InspectSpotPlan({
    required this.id,
    required this.kind,
    required this.title,
    required this.label,
    required this.areas,
    required this.line,
    this.checks = const [],
    this.requires,
    this.lockedLine,
  });

  final String id;
  final String kind;
  final String title;
  final String label;
  final List<SceneRect> areas;
  final String line;
  final List<int> checks;
  final String? requires;
  final String? lockedLine;

  factory InspectSpotPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = InspectSpotPlan(
      id: r.str('id', pattern: PlanIds.local),
      kind: r.str('kind', oneOf: inspectKinds),
      title: r.str('title'),
      label: r.str('label'),
      areas: r.rects('areas'),
      line: r.str('line'),
      checks: r.optInts('checks'),
      requires: r.optStr('requires', pattern: PlanIds.local),
      lockedLine: r.optStr('lockedLine'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'kind': kind, 'title': title, 'label': label, 'areas': _rectsJson(areas), 'line': line};
    _putList(json, 'checks', checks);
    _putText(json, 'requires', requires);
    _putText(json, 'lockedLine', lockedLine);
    return json;
  }
}

/// Exhibits examined under a magnifying glass (`InspectScene`, table
/// `inspections`, `lens_inspect_word`): the one the letter describes leads
/// to its label, where the word ([taskLine], the letter's line still to
/// answer) is written — the puzzle's typed answer.
class InspectPlan {
  const InspectPlan({
    required this.picture,
    required this.place,
    required this.task,
    required this.nextTask,
    required this.dragGuide,
    required this.tapGuide,
    required this.missLine,
    required this.spots,
    required this.labelTitle,
    required this.labelRoom,
    required this.labelWorn,
    required this.taskLine,
    required this.lensAt,
    this.inside,
  });

  final PicturePlan picture;
  final String place;
  final String task;
  final String nextTask;
  final String dragGuide;
  final String tapGuide;
  final String missLine;
  final List<InspectSpotPlan> spots;
  final String labelTitle;
  final String labelRoom;
  final String labelWorn;
  final int taskLine;
  final ScenePoint lensAt;
  final SceneRect? inside;

  factory InspectPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = InspectPlan(
      picture: r.obj('picture', PicturePlan.fromJson),
      place: r.str('place'),
      task: r.str('task'),
      nextTask: r.str('nextTask'),
      dragGuide: r.str('dragGuide'),
      tapGuide: r.str('tapGuide'),
      missLine: r.str('missLine'),
      spots: r.objs('spots', InspectSpotPlan.fromJson, min: 2),
      labelTitle: r.str('labelTitle'),
      labelRoom: r.str('labelRoom'),
      labelWorn: r.str('labelWorn'),
      taskLine: r.integer('taskLine', min: 0),
      lensAt: r.point('lensAt'),
      inside: r.optRect('inside'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'picture': picture.toJson(),
      'place': place,
      'task': task,
      'nextTask': nextTask,
      'dragGuide': dragGuide,
      'tapGuide': tapGuide,
      'missLine': missLine,
      'spots': [for (final s in spots) s.toJson()],
      'labelTitle': labelTitle,
      'labelRoom': labelRoom,
      'labelWorn': labelWorn,
      'taskLine': taskLine,
      'lensAt': lensAt.toJson(),
    };
    if (inside case final r?) json['inside'] = r.toJson();
    return json;
  }
}

/// A line of a record (`RecordLine`): its [id] the option it stands for.
/// Its [value] is the same at every level (what is compared).
class RecordLinePlan {
  const RecordLinePlan({required this.id, required this.label, required this.value});

  final String id;
  final String label;
  final String value;

  factory RecordLinePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = RecordLinePlan(id: r.str('id', pattern: PlanIds.local), label: r.str('label'), value: r.str('value'));
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'value': value};
}

/// Where a record's words go on its blank paper (`PaperQuad` and
/// `RecordLayout`): the sheet's four corners on the picture (pixels,
/// clockwise from the top left) and its own size face on ([flat]); the
/// title box, each line's row and the columns in [flat]'s units.
class RecordSheetPlan {
  const RecordSheetPlan({
    required this.corners,
    required this.flat,
    required this.title,
    required this.rows,
    required this.rowHeight,
    required this.labelLeft,
    required this.labelRight,
    required this.valueLeft,
    required this.valueRight,
    this.noteRow,
    this.noteLeft,
    this.reach,
    this.ink,
  });

  final List<ScenePoint> corners;
  final (double, double) flat;
  final SceneRect title;
  final List<double> rows;
  final double rowHeight;
  final double labelLeft;
  final double labelRight;
  final double valueLeft;
  final double valueRight;
  final double? noteRow;
  final double? noteLeft;
  final double? reach;
  final double? ink;

  factory RecordSheetPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final at = r._at('corners');
    final corners = [for (final (i, x) in r._list(r._required('corners'), at, 4, 4).indexed) ScenePoint._(r._numbers(x, '$at[$i]', 2))];
    final flat = r._numbers(r._required('flat'), r._at('flat'), 2);
    final out = RecordSheetPlan(
      corners: corners,
      flat: (flat[0], flat[1]),
      title: r.rect('title'),
      rows: r.numbers('rows'),
      rowHeight: r.number('rowHeight', min: 1),
      labelLeft: r.number('labelLeft', min: 0),
      labelRight: r.number('labelRight', min: 0),
      valueLeft: r.number('valueLeft', min: 0),
      valueRight: r.number('valueRight', min: 0),
      noteRow: r.optNum('noteRow', min: 0),
      noteLeft: r.optNum('noteLeft', min: 0),
      reach: r.optNum('reach', min: 0),
      ink: r.optNum('ink', min: 0.1, max: 1),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'corners': [for (final c in corners) c.toJson()],
    'flat': [_whole(flat.$1), _whole(flat.$2)],
    'title': title.toJson(),
    'rows': [for (final x in rows) _whole(x)],
    'rowHeight': _whole(rowHeight),
    'labelLeft': _whole(labelLeft),
    'labelRight': _whole(labelRight),
    'valueLeft': _whole(valueLeft),
    'valueRight': _whole(valueRight),
    if (noteRow case final v?) 'noteRow': _whole(v),
    if (noteLeft case final v?) 'noteLeft': _whole(v),
    if (reach case final v?) 'reach': _whole(v),
    'ink': ?ink,
  };
}

/// A record found at the place (`RecordDoc`): its blank paper [picture]
/// (shown as [crop], pixels), and the words the app writes on it.
class RecordDocPlan {
  const RecordDocPlan({
    required this.id,
    required this.name,
    required this.picture,
    required this.crop,
    required this.sheet,
    required this.title,
    required this.lines,
    required this.label,
    this.note,
  });

  final String id;
  final String name;
  final PicturePlan picture;
  final SceneRect crop;
  final RecordSheetPlan sheet;
  final String title;
  final List<RecordLinePlan> lines;
  final String label;
  final String? note;

  factory RecordDocPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = RecordDocPlan(
      id: r.str('id', pattern: PlanIds.local),
      name: r.str('name'),
      picture: r.obj('picture', PicturePlan.fromJson),
      crop: r.rect('crop'),
      sheet: r.obj('sheet', RecordSheetPlan.fromJson),
      title: r.str('title'),
      lines: r.objs('lines', RecordLinePlan.fromJson, min: 2),
      label: r.str('label'),
      note: r.optStr('note'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'name': name,
      'picture': picture.toJson(),
      'crop': crop.toJson(),
      'sheet': sheet.toJson(),
      'title': title,
      'lines': [for (final l in lines) l.toJson()],
      'label': label,
    };
    _putText(json, 'note', note);
    return json;
  }
}

/// Two records of the same thing (`RecordsScene`, table `records`,
/// `record_mismatch`): the pair of lines that disagree is picked, as the
/// puzzle's answer `<first line id>:<second line id>`.
class RecordsPlan {
  const RecordsPlan({required this.first, required this.second, required this.readTask, required this.compareTask, required this.checkLabel});

  final RecordDocPlan first;
  final RecordDocPlan second;
  final String readTask;
  final String compareTask;
  final String checkLabel;

  factory RecordsPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = RecordsPlan(
      first: r.obj('first', RecordDocPlan.fromJson),
      second: r.obj('second', RecordDocPlan.fromJson),
      readTask: r.str('readTask'),
      compareTask: r.str('compareTask'),
      checkLabel: r.str('checkLabel'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() => {
    'first': first.toJson(),
    'second': second.toJson(),
    'readTask': readTask,
    'compareTask': compareTask,
    'checkLabel': checkLabel,
  };
}

/// A question asked in an [InterviewPlan] (`TalkQuestion`): its [lines] the answer.
class InterviewQuestionPlan {
  const InterviewQuestionPlan({required this.id, required this.text, required this.lines, this.requires = const []});

  final String id;
  final String text;
  final List<TalkLinePlan> lines;
  final List<String> requires;

  factory InterviewQuestionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = InterviewQuestionPlan(
      id: r.str('id', pattern: PlanIds.local),
      text: r.str('text'),
      lines: r.objs('lines', TalkLinePlan.fromJson, min: 1),
      requires: r.optStrings('requires', pattern: PlanIds.local, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'text': text, 'lines': [for (final l in lines) l.toJson()]};
    _putList(json, 'requires', requires);
    return json;
  }
}

/// Evidence asked for in an [InterviewPlan] (`TalkPresent`): one of
/// [accepted] (notebook evidence ids) plays [lines]; any other plays [miss]
/// (never counted wrong). [offered]: two pieces shown as cards to pick
/// from instead of the notebook, [tell] said after a second miss.
class InterviewPresentPlan {
  const InterviewPresentPlan({
    required this.id,
    required this.prompt,
    required this.accepted,
    required this.lines,
    required this.miss,
    this.offered = const [],
    this.tell,
    this.requires = const [],
  });

  final String id;
  final String prompt;
  final List<String> accepted;
  final List<TalkLinePlan> lines;
  final String miss;
  final List<String> offered;
  final String? tell;
  final List<String> requires;

  factory InterviewPresentPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = InterviewPresentPlan(
      id: r.str('id', pattern: PlanIds.local),
      prompt: r.str('prompt'),
      accepted: r.strings('accepted', min: 1, pattern: PlanIds.evidence, unique: true),
      lines: r.objs('lines', TalkLinePlan.fromJson, min: 1),
      miss: r.str('miss'),
      offered: r.optStrings('offered', pattern: PlanIds.evidence, unique: true),
      tell: r.optStr('tell'),
      requires: r.optStrings('requires', pattern: PlanIds.local, unique: true),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'prompt': prompt, 'accepted': accepted, 'lines': [for (final l in lines) l.toJson()], 'miss': miss};
    _putList(json, 'offered', offered);
    _putText(json, 'tell', tell);
    _putList(json, 'requires', requires);
    return json;
  }
}

/// A talk with one person of the case in which evidence is shown
/// (`TalkScene`, table `talks`, `evidence_talk`): questions asked, the
/// evidence that answers each prompt shown; finished once every step of
/// [finishWhen] is done, it gives the puzzle's answer.
class InterviewPlan {
  const InterviewPlan({
    required this.speaker,
    required this.goal,
    required this.opening,
    required this.presents,
    required this.finishWhen,
    this.portrait,
    this.questions = const [],
    this.finishLabel,
  });

  /// A charId of the case's characters.
  final String speaker;
  final String? portrait;
  final String goal;
  final List<TalkLinePlan> opening;
  final List<InterviewQuestionPlan> questions;
  final List<InterviewPresentPlan> presents;
  final List<String> finishWhen;
  final String? finishLabel;

  factory InterviewPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = InterviewPlan(
      speaker: r.str('speaker', pattern: PlanIds.local),
      portrait: r.optStr('portrait', pattern: PlanIds.assetFile),
      goal: r.str('goal'),
      opening: r.objs('opening', TalkLinePlan.fromJson, min: 1),
      questions: r.optObjs('questions', InterviewQuestionPlan.fromJson),
      presents: r.objs('presents', InterviewPresentPlan.fromJson, min: 1),
      finishWhen: r.strings('finishWhen', min: 1, pattern: PlanIds.local, unique: true),
      finishLabel: r.optStr('finishLabel'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'speaker': speaker};
    _putText(json, 'portrait', portrait);
    json['goal'] = goal;
    json['opening'] = [for (final l in opening) l.toJson()];
    _putList(json, 'questions', [for (final q in questions) q.toJson()]);
    json['presents'] = [for (final p in presents) p.toJson()];
    json['finishWhen'] = finishWhen;
    _putText(json, 'finishLabel', finishLabel);
    return json;
  }
}

class MissionPlayPlan {
  const MissionPlayPlan({
    this.title,
    this.location,
    this.story = const [],
    this.letterIntro,
    this.letter,
    this.question,
    this.prompt,
    this.hints = const [],
    this.successMessage,
    this.transition = const [],
    this.feedback = const {},
    this.orderFeedback,
    this.mapX,
    this.mapY,
    this.clue,
    this.evidence,
    this.recall,
    this.evidenceLinkLine,
    this.lockTitle,
    this.hideOptionNames,
    this.explore,
    this.search,
    this.dialogue,
    this.timeline,
    this.syllables,
    this.traces,
    this.inspect,
    this.records,
    this.interview,
    this.talk,
    this.discovery,
    this.ending = const [],
  });

  final String? title;
  final String? location;
  final List<String> story;
  final String? letterIntro;
  final String? letter;
  final String? question;
  final String? prompt;
  final List<String> hints;
  final String? successMessage;

  /// The scene after the answer (a final's: the scene after the case).
  final List<String> transition;

  /// A wrong typed answer → its line (typed and ordered puzzles; a choice's
  /// lines are its options').
  final Map<String, String> feedback;
  final String? orderFeedback;

  /// The map pin, as fractions of the map (0..1).
  final double? mapX;
  final double? mapY;
  final ClueText? clue;
  final EvidenceText? evidence;
  final RecallText? recall;

  /// How this mission's evidence matches the one its `evidenceLink` input names.
  final String? evidenceLinkLine;

  /// A letter lock's name on its plate (`Mission.lockTitle`); the game's
  /// plain "THE LOCK" when not given.
  final String? lockTitle;

  /// A picture choice told apart by its words only (`Mission.hideOptionNames`):
  /// the pictures are not named under them.
  final bool? hideOptionNames;

  /// The scene of a puzzle played on its engine's table (STEP 3-13), the
  /// one its `engineTable` reads: `explores`, `investigations`, `dialogues`.
  final ExplorePlan? explore;
  final SearchPlan? search;
  final DialoguePlan? dialogue;

  /// A timeline to put back together (Puzzle Engine 2.0, table `timelines`).
  final TimelinePlan? timeline;

  /// A note in the new letters to put back together (table `syllables`).
  final SyllablesPlan? syllables;

  /// Existing engines the generator makes (Puzzle Engine 2.0 STEP 1): a
  /// place read for its traces (`deductions`), exhibits under the glass
  /// (`inspections`), two records compared (`records`), a talk in which
  /// evidence is shown (`talks`).
  final TracesPlan? traces;
  final InspectPlan? inspect;
  final RecordsPlan? records;
  final InterviewPlan? interview;

  /// The story around the puzzle (STEP 3-13B), each optional: without it the
  /// mission plays as it always did. A mission's talks before and after its
  /// puzzle (`talkMissions`) and its own Discovery Moment (`discoveries`); a
  /// final's ending after its answer (`endings`).
  final MissionTalkPlan? talk;
  final DiscoveryPlan? discovery;
  final List<EndingLinePlan> ending;

  /// The scene given, by the table it is written into.
  Map<String, Object> get scenes => {
    'explores': ?explore,
    'investigations': ?search,
    'dialogues': ?dialogue,
    'timelines': ?timeline,
    'syllables': ?syllables,
    'deductions': ?traces,
    'inspections': ?inspect,
    'records': ?records,
    'talks': ?interview,
  };

  factory MissionPlayPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MissionPlayPlan(
      title: r.optStr('title'),
      location: r.optStr('location'),
      story: r.optStrings('story'),
      letterIntro: r.optStr('letterIntro'),
      letter: r.optStr('letter'),
      question: r.optStr('question'),
      prompt: r.optStr('prompt'),
      hints: r.optStrings('hints'),
      successMessage: r.optStr('successMessage'),
      transition: r.optStrings('transition'),
      feedback: r.optTextMap('feedback'),
      orderFeedback: r.optStr('orderFeedback'),
      mapX: r.optNum('mapX', min: 0, max: 1),
      mapY: r.optNum('mapY', min: 0, max: 1),
      clue: r.optObj('clue', ClueText.fromJson),
      evidence: r.optObj('evidence', EvidenceText.fromJson),
      recall: r.optObj('recall', RecallText.fromJson),
      evidenceLinkLine: r.optStr('evidenceLinkLine'),
      lockTitle: r.optStr('lockTitle'),
      hideOptionNames: r.optBool('hideOptionNames'),
      explore: r.optObj('explore', ExplorePlan.fromJson),
      search: r.optObj('search', SearchPlan.fromJson),
      dialogue: r.optObj('dialogue', DialoguePlan.fromJson),
      timeline: r.optObj('timeline', TimelinePlan.fromJson),
      syllables: r.optObj('syllables', SyllablesPlan.fromJson),
      traces: r.optObj('traces', TracesPlan.fromJson),
      inspect: r.optObj('inspect', InspectPlan.fromJson),
      records: r.optObj('records', RecordsPlan.fromJson),
      interview: r.optObj('interview', InterviewPlan.fromJson),
      talk: r.optObj('talk', MissionTalkPlan.fromJson),
      discovery: r.optObj('discovery', DiscoveryPlan.fromJson),
      ending: r._has('ending') ? r.objs('ending', EndingLinePlan.fromJson, min: 1) : const [],
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    _putText(json, 'title', title);
    _putText(json, 'location', location);
    _putList(json, 'story', story);
    _putText(json, 'letterIntro', letterIntro);
    _putText(json, 'letter', letter);
    _putText(json, 'question', question);
    _putText(json, 'prompt', prompt);
    _putList(json, 'hints', hints);
    _putText(json, 'successMessage', successMessage);
    _putList(json, 'transition', transition);
    _putMap(json, 'feedback', feedback);
    _putText(json, 'orderFeedback', orderFeedback);
    if (mapX != null) json['mapX'] = mapX;
    if (mapY != null) json['mapY'] = mapY;
    if (clue case final c?) json['clue'] = c.toJson();
    if (evidence case final e?) json['evidence'] = e.toJson();
    if (recall case final r?) json['recall'] = r.toJson();
    _putText(json, 'evidenceLinkLine', evidenceLinkLine);
    _putText(json, 'lockTitle', lockTitle);
    if (hideOptionNames != null) json['hideOptionNames'] = hideOptionNames;
    if (explore case final s?) json['explore'] = s.toJson();
    if (search case final s?) json['search'] = s.toJson();
    if (dialogue case final s?) json['dialogue'] = s.toJson();
    if (timeline case final s?) json['timeline'] = s.toJson();
    if (syllables case final s?) json['syllables'] = s.toJson();
    if (traces case final s?) json['traces'] = s.toJson();
    if (inspect case final s?) json['inspect'] = s.toJson();
    if (records case final s?) json['records'] = s.toJson();
    if (interview case final s?) json['interview'] = s.toJson();
    if (talk case final t?) json['talk'] = t.toJson();
    if (discovery case final d?) json['discovery'] = d.toJson();
    _putList(json, 'ending', [for (final l in ending) l.toJson()]);
    return json;
  }
}

/// One mission or final, planned.
class MissionPlan {
  const MissionPlan({
    required this.missionId,
    required this.slot,
    required this.placeId,
    required this.puzzle,
    required this.clueInputs,
    required this.clueOutputs,
    required this.learning,
    this.play,
    this.notes = const [],
  });

  /// `<case>_m<n>` or `<case>_final`.
  final String missionId;

  /// `m1`…, or `final`.
  final String slot;

  /// The season place it happens at (`ScenePlace`, by its id).
  final String placeId;
  final PuzzlePlan puzzle;
  final List<ClueInput> clueInputs;
  final ClueOutputs clueOutputs;
  final LearningPlan learning;

  /// Its words as the game shows them; null while only its structure is planned.
  final MissionPlayPlan? play;
  final List<String> notes;

  bool get isFinal => slot == 'final';

  factory MissionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = MissionPlan(
      missionId: r.str('missionId', pattern: PlanIds.mission),
      slot: r.str('slot', pattern: PlanIds.slot),
      placeId: r.str('placeId', pattern: PlanIds.place),
      puzzle: r.obj('puzzle', PuzzlePlan.fromJson),
      clueInputs: r.objs('clueInputs', ClueInput.fromJson),
      clueOutputs: r.obj('clueOutputs', ClueOutputs.fromJson),
      learning: r.obj('learning', LearningPlan.fromJson),
      play: r.optObj('play', MissionPlayPlan.fromJson),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'missionId': missionId,
      'slot': slot,
      'placeId': placeId,
      'puzzle': puzzle.toJson(),
      'clueInputs': [for (final c in clueInputs) c.toJson()],
      'clueOutputs': clueOutputs.toJson(),
      'learning': learning.toJson(),
    };
    if (play case final p?) json['play'] = p.toJson();
    _putList(json, 'notes', notes);
    return json;
  }
}

// ── PuzzlePlan ───────────────────────────────────────────────────────────

/// A choice of a puzzle (`ChoiceOption`, without its `Artwork`: a new
/// season's pictures are its own files, [picture]).
class OptionPlan {
  const OptionPlan({required this.id, required this.label, this.feedback, this.altText, this.picture});

  final String id;
  final String label;
  final String? feedback;
  final String? altText;

  /// A picture choice's picture (`ChoiceOption.picture`), from the
  /// repository's root.
  final String? picture;

  factory OptionPlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = OptionPlan(
      id: r.str('id'),
      label: r.str('label'),
      feedback: r.optStr('feedback'),
      altText: r.optStr('altText'),
      picture: r.optStr('picture', pattern: PlanIds.assetFile),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'id': id, 'label': label};
    _putText(json, 'feedback', feedback);
    _putText(json, 'altText', altText);
    _putText(json, 'picture', picture);
    return json;
  }
}

/// A puzzle's answer, in the `Mission` fields the palette's puzzles are
/// written with (`PuzzleDefinition.requiredData`). Only [answer] is common
/// to every puzzle; which others a puzzle needs is the palette's to say
/// (STEP 3-3).
class AnswerSpec {
  const AnswerSpec({
    required this.answer,
    this.acceptedAnswers = const [],
    this.options = const [],
    this.codeLength,
    this.codeFormat,
    this.dialSymbols = const [],
  });

  /// As `Mission.answer` holds it (an option id, a word, a code, ids joined
  /// by commas, `note:picture` pairs).
  final String answer;
  final List<String> acceptedAnswers;
  final List<OptionPlan> options;
  final int? codeLength;
  final String? codeFormat;
  final List<String> dialSymbols;

  factory AnswerSpec.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = AnswerSpec(
      answer: r.str('answer'),
      acceptedAnswers: r.optStrings('acceptedAnswers'),
      options: r.optObjs('options', OptionPlan.fromJson),
      codeLength: r.optInt('codeLength', min: 1),
      codeFormat: r.optStr('codeFormat', oneOf: PlanVocabulary.codeFormats),
      dialSymbols: r.optStrings('dialSymbols'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{'answer': answer};
    _putList(json, 'acceptedAnswers', acceptedAnswers);
    _putList(json, 'options', [for (final o in options) o.toJson()]);
    if (codeLength != null) json['codeLength'] = codeLength;
    _putText(json, 'codeFormat', codeFormat);
    _putList(json, 'dialSymbols', dialSymbols);
    return json;
  }
}

/// The puzzle a mission is played with, tied to the engine that plays it.
class PuzzlePlan {
  const PuzzlePlan({
    required this.paletteId,
    required this.surface,
    required this.engineTable,
    required this.missionType,
    required this.answerSpec,
    required this.assetNeeds,
    required this.status,
    this.devNote,
    this.notes = const [],
  });

  /// Its `PuzzlePalette` id; null only for a [PuzzleStatus.devRequest] (an
  /// engine the palette has not).
  final String? paletteId;
  final PlanSurface surface;

  /// The `SeasonContent` table its engine reads (a binding's `table`); null:
  /// played from its [missionType] alone.
  final String? engineTable;

  /// Its `MissionType`, by name.
  final String missionType;
  final AnswerSpec answerSpec;

  /// The pictures it needs beyond its place's (asset ids).
  final List<String> assetNeeds;
  final PuzzleStatus status;

  /// What is to be developed, for a [PuzzleStatus.devRequest].
  final String? devNote;
  final List<String> notes;

  factory PuzzlePlan.fromJson(Object? json, String path) {
    final r = _Reader(json, path);
    final out = PuzzlePlan(
      paletteId: r.nullableStr('paletteId', pattern: PlanIds.palette),
      surface: r.enumOf('surface', PlanSurface.values),
      engineTable: r.nullableStr('engineTable', pattern: PlanIds.table),
      missionType: r.str('missionType', oneOf: PlanVocabulary.missionTypes),
      answerSpec: r.obj('answerSpec', AnswerSpec.fromJson),
      assetNeeds: r.strings('assetNeeds', pattern: PlanIds.asset, unique: true),
      status: r.enumOf('status', PuzzleStatus.values),
      devNote: r.optStr('devNote'),
      notes: r.optStrings('notes'),
    );
    r.done();
    return out;
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'paletteId': paletteId,
      'surface': surface.name,
      'engineTable': engineTable,
      'missionType': missionType,
      'answerSpec': answerSpec.toJson(),
      'assetNeeds': assetNeeds,
      'status': status.name,
    };
    _putText(json, 'devNote', devNote);
    _putList(json, 'notes', notes);
    return json;
  }
}
