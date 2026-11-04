import 'dart:convert';
import 'dart:io';

import '../../tool/season_gen/case_levels.dart';

/// The Rome mission made a timeline in a copy of the season (Puzzle Engine
/// 2.0, PART 3C tests): Case 08 Mission 3, Livia's diary pages, its days
/// put back in order — Tuesday fixed by its day, a closed-door card not
/// part of it. Its relations are rows of the diary (the letter) at every
/// level; every new line is written at Junior and Master in its own words.
const romeTimelineMission = 's3_ep08_m3';
const romeTimelineCase = 's3_ep08';

/// The cards, as the plan writes them ([card] changes one before it is written).
List<Map<String, Object?>> romeTimelineCards() => [
  {'id': 'tuesday', 'title': 'TUESDAY', 'text': 'Signor Valli takes the piece for photos.', 'anchor': 'TUESDAY'},
  {'id': 'thursday', 'title': 'THURSDAY NIGHT', 'text': 'Signor Valli comes to check the lights.'},
  {'id': 'friday_am', 'title': 'FRIDAY MORNING', 'text': 'Livia finds the piece is too light.'},
  {'id': 'midnight', 'title': 'FRIDAY, MIDNIGHT', 'text': 'Livia takes the copy out.'},
  {'id': 'monday', 'title': 'A CLOSED DOOR', 'text': 'The lab is closed for a holiday.', 'discard': true},
];

const _thursdayLine = 'THURSDAY NIGHT — Enzo says Signor Valli came at 11 PM to "check the lights".';
const _midnightLine = 'FRIDAY, MIDNIGHT — I turned off the lights and took the copy.';

/// Each new Rookie line → its Junior and Master words.
const _levels = {
  'Signor Valli takes the piece for photos.': ('Signor Valli takes the piece away for photos.', 'Signor Valli removes the piece for the poster photos.'),
  'Signor Valli comes to check the lights.': ('Signor Valli arrives to check the lights.', 'Signor Valli turns up, supposedly to check the lights.'),
  'Livia finds the piece is too light.': ('Livia notices the piece is too light.', 'Livia discovers the piece weighs far too little.'),
  'Livia takes the copy out.': ('Livia carries the copy out.', 'Livia slips out of the lab with the copy.'),
  'The lab is closed for a holiday.': ('The lab stays shut for a holiday.', 'The lab remains closed for a public holiday.'),
  _thursdayLine: (_thursdayLine, 'THURSDAY NIGHT — Enzo tells me Signor Valli came at 11 PM to "check the lights".'),
  _midnightLine: ('FRIDAY, MIDNIGHT — I switched off the lights and took the copy.', 'FRIDAY, MIDNIGHT — I switched off the lights and slipped out with the copy.'),
};

/// [seasonDir] (a copy of `s3_rome`) with Case 08 Mission 3 a timeline:
/// its plan, and its `levels.json` kept whole (new lines written, lines
/// no longer in the plan gone). [cards] / [relations]: other ones.
void makeRomeTimeline(String seasonDir, {List<Map<String, Object?>>? cards, List<Map<String, Object?>>? relations, void Function(Map<String, dynamic> mission)? change}) {
  final planFile = File('$seasonDir/cases/$romeTimelineCase/case.plan.json');
  final plan = jsonDecode(planFile.readAsStringSync()) as Map<String, dynamic>;
  final m = (plan['missions'] as List).cast<Map<String, dynamic>>().firstWhere((m) => m['missionId'] == romeTimelineMission);
  final theCards = cards ?? romeTimelineCards();
  final puzzle = m['puzzle'] as Map<String, dynamic>;
  puzzle
    ..['paletteId'] = 'timeline_board'
    ..['engineTable'] = 'timelines';
  (puzzle['answerSpec'] as Map<String, dynamic>)['options'] = [for (final c in theCards) {'id': c['id'], 'label': c['title']}];
  (m['play'] as Map<String, dynamic>)['timeline'] = {
    'cards': theCards,
    'relations': relations ??
        [
          {'earlier': 'thursday', 'later': 'friday_am', 'line': _thursdayLine},
          {'earlier': 'friday_am', 'later': 'midnight', 'line': _midnightLine},
        ],
  };
  change?.call(m);
  planFile.writeAsStringSync(jsonEncode(plan));

  final levelsFile = File('$seasonDir/cases/$romeTimelineCase/levels.json');
  final levels = jsonDecode(levelsFile.readAsStringSync()) as Map<String, dynamic>;
  final rookie = CaseLevels.rookieLines(plan);
  final kept = [for (final l in (levels['lines'] as List).cast<Map>()) if (rookie.contains(l['rookie'])) l];
  final written = {for (final l in kept) l['rookie']};
  levels['lines'] = [
    ...kept,
    for (final s in rookie)
      if (!written.contains(s))
        // A new card's title is a label: the same at every level.
        {'rookie': s, 'junior': _levels[s]?.$1 ?? s, 'master': _levels[s]?.$2 ?? s},
  ];
  levelsFile.writeAsStringSync(jsonEncode(levels));
}
