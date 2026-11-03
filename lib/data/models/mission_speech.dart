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
///  * [fromStory] true: the person's words are the quoted parts of the
///    mission's story (the stranger's greeting), and the letter stays a real
///    paper handed over after them ([Mission.letterIntro] closes the talk).
///
/// Heard to its end, the talk is kept with the things looked at in the
/// mission ([TalkMission.beforeKey]), so it is never played again.
@immutable
class MissionSpeech {
  const MissionSpeech({required this.speaker, required this.goal, this.background, this.fromStory = false});

  final TalkSpeaker speaker;

  /// What the detective is finding out, one line over the talk.
  final String goal;

  /// The place behind the person (null: the night).
  final String? background;
  final bool fromStory;

  /// The talk of [m], the detective named [detectiveName] where the words
  /// address them.
  TalkMission talkOf(Mission m, String? detectiveName) {
    String named(String text) => DetectiveName.address(text, detectiveName);
    final opening = fromStory
        ? [
            for (final line in m.story) ...storyLines(named(line)),
            if (m.letterIntro.trim().isNotEmpty) TalkLine.narrator(named(m.letterIntro.trim())),
          ]
        : [for (final line in spokenLines(named(m.letter))) TalkLine(line)];
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

  static String _unquote(String s) {
    var t = s.trim();
    if (t.startsWith('"')) t = t.substring(1);
    if (t.endsWith('"')) t = t.substring(0, t.length - 1);
    return t.trim();
  }
}
