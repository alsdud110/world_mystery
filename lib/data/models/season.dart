import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Who stands behind the season's cases, as far as the detective knows.
///
/// A figure is revealed only once the case that names it in the story has
/// been solved ([afterCase]), so the season board never tells more than the
/// player has read.
@immutable
class SeasonFigure {
  const SeasonFigure({required this.afterCase, required this.figure, required this.label});

  /// The case whose solving reveals this figure (season record).
  final String afterCase;

  /// Which picture stands for it on the board (`ravens`, `ravenSociety`,
  /// `clockmaker`, `clockmakerWatch`; unknown keys show a question mark).
  final String figure;
  final String label;

  static SeasonFigure? fromJson(Object? json) {
    if (json is! Map) return null;
    final after = json['after'];
    final figure = json['figure'];
    final label = json['label'];
    if (after is! String || figure is! String || label is! String) return null;
    return SeasonFigure(afterCase: after, figure: figure, label: label);
  }
}

/// The season's opening sequence: short scenes, one message each, played
/// once before the first case.
///
/// London's pictures are its own (written in the screen); a season made from
/// its plans names its own: [hero], the four [pieces] and the first case's
/// picture as files.
@immutable
class SeasonPrologue {
  const SeasonPrologue({
    this.city = '',
    this.cases = const [],
    this.separate = const [],
    this.question = '',
    this.bigger = '',
    this.promise = const [],
    this.firstCasePicture = '',
    this.firstCaseLine = '',
    this.hero = '',
    this.heroPixels,
    this.pieces = const [],
  });

  /// The city at night.
  final String city;

  /// The kinds of trouble, laid on the desk one by one.
  final List<String> cases;

  /// Over the map: they look apart — but look closer.
  final List<String> separate;

  /// The thread appears: the question the season asks.
  final String question;
  final String bigger;

  /// Under 12 CASES · ONE MYSTERY.
  final List<String> promise;

  /// The first case's file: its picture (an `ArtAssets.objects` key, or a
  /// file) and a line.
  final String firstCasePicture;
  final String firstCaseLine;

  /// The first scene's picture, full screen (a file), and its pixel size
  /// (never decoded larger). Empty: London's own.
  final String hero;
  final Size? heroPixels;

  /// The pictures of the [cases], one each, in order (files). Empty:
  /// London's own.
  final List<String> pieces;

  /// Whether there is an opening to play: every scene has its words.
  bool get isPlayable =>
      city.isNotEmpty &&
      cases.length == 4 &&
      separate.isNotEmpty &&
      question.isNotEmpty &&
      bigger.isNotEmpty &&
      promise.isNotEmpty &&
      firstCasePicture.isNotEmpty &&
      firstCaseLine.isNotEmpty;

  /// Whether its pictures are its own ([hero], one of [pieces] per case)
  /// rather than London's.
  bool get hasOwnPictures => hero.isNotEmpty && pieces.length == cases.length;

  factory SeasonPrologue.fromJson(Object? json) {
    if (json is! Map) return const SeasonPrologue();
    List<String> lines(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    String text(Object? v) => v is String ? v : '';
    final first = json['firstCase'];
    final hero = json['hero'];
    final pixels = hero is Map ? hero['pixels'] : null;
    return SeasonPrologue(
      city: text(json['city']),
      cases: lines(json['cases']),
      separate: lines(json['separate']),
      question: text(json['question']),
      bigger: text(json['bigger']),
      promise: lines(json['promise']),
      firstCasePicture: first is Map ? text(first['picture']) : '',
      firstCaseLine: first is Map ? text(first['line']) : '',
      hero: hero is Map ? text(hero['file']) : '',
      heroPixels: pixels is Map && pixels['width'] is num && pixels['height'] is num
          ? Size((pixels['width'] as num).toDouble(), (pixels['height'] as num).toDouble())
          : null,
      pieces: lines(json['pieces']),
    );
  }

  /// Every line the opening JSON [json] says, in the order it shows them:
  /// `city`, `cases`, `separate`, `question`, `bigger`, `promise`, then
  /// `firstCase.line` — a level gives them all again, line for line
  /// (`SeasonContent.infoLevels['prologue']`).
  static List<String> linesOf(Object? json) {
    if (json is! Map) return const [];
    final first = json['firstCase'];
    return [
      for (final key in _spoken)
        if (json[key] is String)
          json[key] as String
        else if (json[key] is List)
          ...(json[key] as List).whereType<String>(),
      if (first is Map && first['line'] is String) first['line'] as String,
    ];
  }

  /// [json] with its spoken lines ([linesOf]) replaced by [lines], in the
  /// same order; null when [lines] are not as many. Its pictures stay.
  static Map<String, dynamic>? withLines(Map<dynamic, dynamic> json, List<String> lines) {
    if (linesOf(json).length != lines.length) return null;
    var i = 0;
    final out = <String, dynamic>{for (final e in json.entries) '${e.key}': e.value};
    for (final key in _spoken) {
      final v = json[key];
      if (v is String) {
        out[key] = lines[i++];
      } else if (v is List) {
        out[key] = [for (final s in v) s is String ? lines[i++] : s];
      }
    }
    final first = json['firstCase'];
    if (first is Map && first['line'] is String) out['firstCase'] = {...first, 'line': lines[i++]};
    return out;
  }

  static const _spoken = ['city', 'cases', 'separate', 'question', 'bigger', 'promise'];
}

/// The seasons' ids. Saved with a season's own records (Season 2 on), so they
/// never change once released.
abstract final class SeasonIds {
  /// Season 1. Its saves were made before seasons had ids: they keep their
  /// keys, and its content needs no id (it is the default).
  static const london = AppConstants.firstSeasonId;

  static const paris = 's2_paris';

  /// Season 3, made from its plans (`content_pipeline/seasons/s3_rome`).
  static const rome = 's3_rome';

  /// Season 4, made from its plans (`content_pipeline/seasons/s4_newyork`).
  static const newyork = 's4_newyork';
}

/// A season: the bigger story the cases belong to. Its cases are the
/// episode catalog, in order; this holds what is told about the season as a
/// whole. Content, like an episode: plain JSON-shaped data.
@immutable
class Season {
  const Season({
    this.id = SeasonIds.london,
    required this.number,
    required this.title,
    required this.tagline,
    required this.prologue,
    required this.outro,
    this.finale = const [],
    required this.figures,
    this.city = 'London',
    this.plannedCases,
    this.upcomingTitles = const {},
  });

  /// [SeasonIds]: which season this is.
  final String id;

  /// The city the season's cases happen in ("London"), as the pages name it.
  final String city;

  /// How many cases the season will have once it is all in the game (12),
  /// or null: as many as are in the game. A season is complete only once
  /// all of them are solved.
  final int? plannedCases;

  /// The titles of cases not in the game yet, by case number, told where
  /// the season says what comes next ("CASE 05 · THE SILENT WORKSHOP"):
  /// a title only, never a case to open.
  final Map<int, String> upcomingTitles;

  final int number;

  /// "Shadows over London".
  final String title;

  /// Said after the number of cases ("ONE MYSTERY" → "12 CASES • ONE MYSTERY").
  final String tagline;

  /// The season's opening sequence (played once, before the first case).
  final SeasonPrologue prologue;

  /// The lines once every case is solved.
  final List<String> outro;

  /// The lines on the last case's report, pointing on to the next season
  /// ("London is safe." / "But the watch says PARIS."); empty: none.
  final List<String> finale;

  /// What the detective learns about who is behind it, in story order.
  final List<SeasonFigure> figures;

  /// "SEASON ONE".
  String get label => 'SEASON ${_words[number] ?? '$number'}';

  static const _words = {1: 'ONE', 2: 'TWO', 3: 'THREE', 4: 'FOUR'};

  /// The last figure revealed by the [solved] cases, or null (still a "?").
  SeasonFigure? figureFor(bool Function(String caseId) solved) {
    SeasonFigure? known;
    for (final f in figures) {
      if (solved(f.afterCase)) known = f;
    }
    return known;
  }

  /// Tolerant decoding, like the episodes: malformed lines are skipped.
  /// Whether the season opens with its [prologue]: all its words, and
  /// pictures of its own (London's are written in the screen).
  bool get playsPrologue => prologue.isPlayable && (id == SeasonIds.london || prologue.hasOwnPictures);

  factory Season.fromJson(Map<String, dynamic> json) {
    List<String> lines(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    final id = json['id'];
    final number = json['number'];
    final figures = json['figures'];
    final city = json['city'];
    final planned = json['cases'];
    final upcoming = json['upcoming'];
    return Season(
      // Season 1's content names no city: it is London.
      city: city is String && city.isNotEmpty ? city : 'London',
      plannedCases: planned is int && planned > 0 ? planned : null,
      upcomingTitles: upcoming is Map
          ? {
              for (final e in upcoming.entries)
                if (int.tryParse('${e.key}') case final n? when e.value is String) n: e.value as String,
            }
          : const {},
      // Season 1's content has no id: it is the default.
      id: id is String && id.isNotEmpty ? id : SeasonIds.london,
      number: number is int ? number : 1,
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      prologue: SeasonPrologue.fromJson(json['prologue']),
      outro: lines(json['outro']),
      finale: lines(json['finale']),
      figures: figures is List ? figures.map(SeasonFigure.fromJson).whereType<SeasonFigure>().toList() : const [],
    );
  }
}
