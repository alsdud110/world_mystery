import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/history_dossier.dart' show SeasonMode;
import '../../tool/season_gen/palette_facts.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';
import '../../tool/season_planner/puzzle_selection.dart';
import '../../tool/season_planner/season_quality.dart';

/// Puzzle Engine 2.0 STEP 1: the puzzle of each mission of a historical
/// season chosen by rules — from what its words show, among the puzzles the
/// generator makes, with the season's variety — the same every time, and
/// reported beside the plan's own choice.
void main() {
  const casePath = 'test/sandbox/plans/s8_timeline/cases/s8_ep02/case.plan.json';
  Map<String, dynamic> raw() => jsonDecode(File(casePath).readAsStringSync()) as Map<String, dynamic>;

  /// The sandbox's Case 02 as case [n] of a season, each mission's letter
  /// [letters] (by index, 4 the final) when given.
  CasePlan caseOf(int n, {Map<int, String> letters = const {}}) {
    final plan = raw();
    final id = 's8_ep${n.toString().padLeft(2, '0')}';
    final text = jsonEncode(plan).replaceAll('s8_ep02', id);
    final json = jsonDecode(text) as Map<String, dynamic>;
    json['number'] = n;
    for (final MapEntry(key: i, value: letter) in letters.entries) {
      final m = (i < 4 ? (json['missions'] as List)[i] : json['final']) as Map;
      (m['play'] as Map)
        ..['letter'] = letter
        ..['story'] = ['You look.']
        ..['question'] = 'What now?';
    }
    return CasePlan.fromJson(json);
  }

  group('traits', () {
    test('read in the words; the facts alone never choose', () {
      final t = PuzzleSelector.traitsOf('First the bell rang. Then the gate closed, two years later.', 'The gate closed in 1443 and opened in 1446.');
      expect([for (final x in t) (x.trait, x.shown)], [(PuzzleTrait.chronology, true)]);
      final facts = PuzzleSelector.traitsOf('Find the gate.', 'The gate closed in 1443 and opened in 1446.');
      expect([for (final x in facts) (x.trait, x.shown)], [(PuzzleTrait.chronology, false)]);
      final records = PuzzleSelector.traitsOf('The log says 3:00 PM. The notice says 4:00 PM.', '').map((x) => x.trait);
      expect(records, contains(PuzzleTrait.documents));
      expect(records, isNot(contains(PuzzleTrait.number)), reason: 'a time said is not a number to put in');
      expect(PuzzleSelector.traitsOf('The locker is four hundred and seventeen. Put in the number.', '').map((x) => x.trait), contains(PuzzleTrait.number));
    });

    test('the sandbox case: each mission\'s words call for its engine', () {
      final picks = PuzzleSelector.select([caseOf(2)]);
      expect([for (final x in picks) x.planned], ['record_mismatch', 'number_entry', 'trace_deduction', 'lens_inspect_word', 'evidence_talk']);
      expect([for (final x in picks) x.selected], ['record_mismatch', 'number_entry', 'trace_deduction', 'lens_inspect_word', 'evidence_talk']);
    });
  });

  group('rules', () {
    test('the same plans, the same choice and the same words, every time', () {
      final plans = [for (var n = 2; n <= 7; n++) caseOf(n)];
      String run() => jsonEncode([for (final x in PuzzleSelector.select(plans)) x.toJson()]);
      expect(run(), run());
    });

    test('only puzzles the generator makes, on the page they are played on', () {
      for (final x in PuzzleSelector.select([for (var n = 2; n <= 7; n++) caseOf(n)])) {
        for (final c in x.candidates) {
          expect(PlayCheck.generatable.containsKey(c.paletteId), isTrue, reason: '${x.missionId} ${c.paletteId}');
          expect(PaletteFacts.lookup(c.paletteId)!.supports(x.surface), isTrue, reason: '${x.missionId} ${c.paletteId} on ${x.surface.name}');
        }
      }
      // A final full of traces: the traces are played on a mission page only.
      final fin = PuzzleSelector.select([caseOf(2, letters: {4: 'Footprints and scratches by the wall. A mark on the stone.'})]).last;
      expect(fin.candidates.map((c) => c.paletteId), isNot(contains('trace_deduction')));
    });

    test('variety: one kind once a case while another fits; a third of the season at most', () {
      const marks = 'Footprints by the wall. Scratches on the stone. A hidden mark behind it.';
      final picks = PuzzleSelector.select([caseOf(2, letters: {0: marks, 1: marks, 2: marks, 3: marks})]);
      final scene = [for (final x in picks.take(4)) x.selected];
      expect(scene.take(3), ['trace_deduction', 'dark_room_search', 'scene_explore_choose'], reason: 'each scene puzzle once while one is left');
      expect(picks[3].candidates.every((c) => c.why.contains('already in this case')), isTrue, reason: 'the fourth: every kind used, said so');

      final season = PuzzleSelector.select([for (var n = 2; n <= 10; n++) caseOf(n)]);
      final cap = (season.length / 3).ceil();
      final counts = <String, int>{};
      for (final x in season) {
        if (x.selected case final id?) counts[id] = (counts[id] ?? 0) + 1;
      }
      expect(counts.values.every((n) => n <= cap), isTrue, reason: '$counts, a third is $cap');
    });

    test('nothing fits: said, never picked at random', () {
      final x = PuzzleSelector.select([caseOf(2, letters: {0: 'Go on.'})]).first;
      expect(x.selected, isNull);
      expect(x.reason, contains('no trait its words show'));
    });
  });

  group('in the planner', () {
    late Directory tmp;
    late String dir;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('puzzle_selection_');
      dir = '${tmp.path.replaceAll(r'\', '/')}/content_pipeline/seasons/s3_rome';
      for (final f in Directory('content_pipeline/seasons/s3_rome').listSync(recursive: true).whereType<File>()) {
        File('${tmp.path}/${f.path.replaceAll(r'\', '/')}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(f.readAsBytesSync());
      }
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('a standard season: no selection, no finding of it (Rome as it was)', () {
      final r = SeasonQuality.run(dir);
      expect(r.selection, isNull);
      expect(r.findings.where((f) => f.code.startsWith('puzzle_selection') || f.code == 'puzzle_case_no_hands_on'), isEmpty);
      SeasonQuality.write(dir, r);
      expect(File('$dir/${PuzzleSelector.fileName}').existsSync(), isFalse);
    });

    test('a historical season: puzzle_selection.json written, the same twice, every mission reported', () {
      final brief = File('$dir/planning/brief.json');
      brief.writeAsStringSync(jsonEncode({...jsonDecode(brief.readAsStringSync()) as Map, 'mode': SeasonMode.historicalName}));
      final r = SeasonQuality.run(dir);
      SeasonQuality.write(dir, r);
      final file = File('$dir/${PuzzleSelector.fileName}');
      final first = file.readAsStringSync();
      SeasonQuality.write(dir, SeasonQuality.run(dir));
      expect(file.readAsStringSync(), first);
      final json = jsonDecode(first) as Map;
      final missions = (json['missions'] as List).cast<Map>();
      expect(missions, hasLength((r.summary['missions'] as int) + (r.summary['finals'] as int)));
      for (final m in missions) {
        expect(m.keys, containsAll(['caseId', 'missionId', 'selected', 'reason', 'factIds', 'planned', 'checks', 'personReview']), reason: '${m['missionId']}');
        expect((m['checks'] as Map).keys, ['answerAndPlay', 'levels']);
        expect(m['personReview'], isNotEmpty);
      }
      // Rome's plans were made before the selector: where they differ is said, never changed.
      expect(r.findings.where((f) => f.code.startsWith('puzzle_selection')), isNotEmpty);
      expect(r.findings.where((f) => f.code.startsWith('puzzle_selection') && f.isError), isEmpty);
    });
  });
}
