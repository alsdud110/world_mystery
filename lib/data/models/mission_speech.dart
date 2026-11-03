import 'package:flutter/foundation.dart';

import 'case_talk.dart';
import 'detective_name.dart';
import 'mission.dart';

/// A mission whose person talks to the detective (Season 1): played as a
/// talk before the puzzle on the `CaseTalk` page, never as a letter.
///
/// The words are the mission's own, at the mission's level (nothing is
/// written twice):
///  * [fromStory] false: the mission's letter is what the person says (the
///    taxi driver's description). The talk replaces the letter: it is not
///    shown again as a letter, and the puzzle's "reread" shows what was said.
///    A final's talk opens with its story (a final has no story page).
///  * [fromStory] true: the person's words are the quoted parts of the
///    mission's story (the stranger's greeting), and the letter stays a real
///    paper handed over after them ([Mission.letterIntro] closes the talk).
///  * [inLetter] true: the person's words are the quote that ends the
///    mission's letter (`Inspector Grey: "…"` under the arrivals board). They
///    are said in the talk and left off the paper, which stays a paper; the
///    puzzle's reread shows both, nothing twice ([paperOf], [wordsOf]).
///
/// Heard to its end, the talk is kept with the things looked at in the
/// mission ([TalkMission.beforeKey]), so it is never played again.
@immutable
class MissionSpeech {
  const MissionSpeech({
    required this.speaker,
    required this.goal,
    this.background,
    this.fromStory = false,
    this.inLetter = false,
  });

  final TalkSpeaker speaker;

  /// What the detective is finding out, one line over the talk.
  final String goal;

  /// The place behind the person (null: the night).
  final String? background;
  final bool fromStory;
  final bool inLetter;

  /// Whether the whole letter is what the person says (no paper is read).
  bool get saysLetter => !fromStory && !inLetter;

  /// The letter as its paper shows it: without the person's words when they
  /// end it ([inLetter]).
  String paperOf(Mission m) => inLetter ? _split(m.letter).$1 : m.letter;

  /// What the person says, as [spokenLines] reads it: the whole letter, or
  /// the quote that ends it ([inLetter]), one line.
  String wordsOf(Mission m) => inLetter ? _split(m.letter).$2 : m.letter;

  /// The talk of [m], the detective named [detectiveName] where the words
  /// address them.
  TalkMission talkOf(Mission m, String? detectiveName) {
    String named(String text) => DetectiveName.address(text, detectiveName);
    final opening = fromStory
        ? [
            for (final line in m.story) ...storyLines(named(line)),
            if (m.letterIntro.trim().isNotEmpty) TalkLine.narrator(named(m.letterIntro.trim())),
          ]
        : [
            // A final has no story page: its story opens the talk, told once.
            if (m.finale) for (final line in m.story) ...storyLines(named(line)),
            for (final line in spokenLines(named(wordsOf(m)))) TalkLine(line),
          ];
    return TalkMission(
      before: TalkScene(
        id: '${m.id}:speech',
        speaker: speaker,
        goal: goal,
        opening: opening,
        finishWhen: const {},
        place: m.location,
        background: background,
      ),
    );
  }

  /// What a person says, one line a beat: the letter's lines, empty ones
  /// left out, the quotation marks round them off (the talk adds its own).
  static List<String> spokenLines(String letter) => [
        for (final raw in letter.split('\n'))
          if (_unquote(raw).isNotEmpty) _unquote(raw),
      ];

  /// A story line as talk lines: its quoted parts said by the person (a
  /// comma that ends a quote before "he says" made a full stop), or, with no
  /// quote, the line told by the narrator.
  static List<TalkLine> storyLines(String line) {
    final quotes = _quoted.allMatches(line).map((q) => q.group(1)!.trim()).where((q) => q.isNotEmpty).toList();
    if (quotes.isEmpty) return [TalkLine.narrator(line.trim())];
    return [for (final q in quotes) TalkLine(q.endsWith(',') ? '${q.substring(0, q.length - 1)}.' : q)];
  }

  static final _quoted = RegExp(r'"([^"]+)"');

  /// A letter that ends with `Name: "words"` as (the paper before it, the
  /// words on one line); a letter without one stays whole.
  static (String, String) _split(String letter) {
    final q = _endQuote.firstMatch(letter);
    if (q == null) return (letter, '');
    return (letter.substring(0, q.start).trimRight(), q.group(1)!.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim());
  }

  static final _endQuote = RegExp(r'[^\n"]*:[ \t]*"([^"]+)"\s*$');

  static String _unquote(String s) {
    var t = s.trim();
    if (t.startsWith('"')) t = t.substring(1);
    if (t.endsWith('"')) t = t.substring(0, t.length - 1);
    return t.trim();
  }
}
