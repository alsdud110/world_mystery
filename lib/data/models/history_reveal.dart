import 'difficulty.dart';

/// What a case of a historical season (Historical Fiction Mystery) tells
/// once it is solved: the real history its puzzles rest on, apart from what
/// the mystery made up. Generated from the season's history dossier, only
/// once a person approved each fact (with its sources) and the reveal
/// itself (its words at every level). Shown on the Case Closed file.
class HistoryReveal {
  const HistoryReveal({required this.realHistory, required this.inThisMystery, this.sources = const []});

  /// REAL HISTORY: what really happened.
  final List<HistoryLine> realHistory;

  /// IN THIS MYSTERY: what the game made up for the case.
  final List<HistoryLine> inThisMystery;

  /// Where [realHistory] comes from: the sources of the facts it names.
  final List<HistorySource> sources;
}

/// One line, in the words of each level. The facts, years, people and
/// meaning are the same at every level; only the English changes.
class HistoryLine {
  const HistoryLine({required this.rookie, required this.junior, required this.master});

  final String rookie;
  final String junior;
  final String master;

  String at(Difficulty level) => switch (level) {
    Difficulty.rookie => rookie,
    Difficulty.junior => junior,
    Difficulty.master => master,
  };
}

/// A source of an approved fact: who published it, what, and where to find it.
class HistorySource {
  const HistorySource({required this.publisher, required this.title, this.url, this.citation});

  final String publisher;
  final String title;
  final String? url;
  final String? citation;
}
