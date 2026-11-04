import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/case_levels.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/json_schema_lite.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';
import '../../tool/season_gen/season_cases.dart';

/// Puzzle Engine 2.0 STEP 1: five engines the game already played, now made
/// by the generator from a plan (`number_entry`, `trace_deduction`,
/// `lens_inspect_word`, `record_mismatch`, `evidence_talk`) — on the
/// sandbox's Case 02 (`test/sandbox/plans/s8_timeline/cases/s8_ep02`,
/// played in the app by `test/sandbox/engines_season_test.dart`): every
/// broken plan refused before anything is written, and the case made at
/// Rookie, Junior and Master with the same answers.
void main() {
  const plans = 'test/sandbox/plans/s8_timeline';
  const casePath = '$plans/cases/s8_ep02/case.plan.json';
  final season = PlanFiles.loadSeasonPlan('$plans/season.plan.json');
  Map<String, dynamic> raw() => jsonDecode(File(casePath).readAsStringSync()) as Map<String, dynamic>;
  Map<String, dynamic> missionOf(Map<String, dynamic> plan, int i) =>
      (i < 4 ? (plan['missions'] as List)[i] : plan['final']) as Map<String, dynamic>;

  /// The codes [PlayCheck] finds in the plan once [change] is made to mission [i] (4: the final).
  Set<String> codesAfter(int i, void Function(Map<String, dynamic> m) change) {
    final plan = raw();
    change(missionOf(plan, i));
    return {for (final x in PlayCheck.casePlan(CasePlan.fromJson(plan), season)) if (x.blocking) x.code};
  }

  test('the plan as written: nothing to refuse', () {
    expect([for (final x in PlayCheck.casePlan(CasePlan.fromJson(raw()), season)) if (x.blocking) '$x'], isEmpty);
  });

  group('a broken plan is refused', () {
    test('records: no line, or two, that disagree; options not the shared lines; the answer not the pair', () {
      Map lines(Map m, String doc) => {for (final l in (m['play']['records'][doc]['lines'] as List).cast<Map>()) l['id']: l};
      expect(codesAfter(0, (m) => lines(m, 'second')['time']['value'] = '4:00 PM'), contains('records_ambiguous'));
      expect(codesAfter(0, (m) => lines(m, 'second')['date']['value'] = '13 MAY'), contains('records_ambiguous'));
      expect(codesAfter(0, (m) => (m['puzzle']['answerSpec']['options'] as List).removeLast()), contains('scene_answer_mismatch'));
      expect(codesAfter(0, (m) => m['puzzle']['answerSpec']['answer'] = 'date:date'), contains('scene_answer_mismatch'));
      expect(codesAfter(0, (m) => m['play']['records']['second']['id'] = 'notice'), contains('scene_invalid'));
      expect(codesAfter(0, (m) => (m['play']['records']['first']['sheet']['rows'] as List).removeLast()), contains('scene_invalid'));
    });

    test('keypad: digits only, as many as its length; a time is HHMM', () {
      expect(codesAfter(1, (m) => m['puzzle']['answerSpec']['answer'] = 'four'), contains('number_answer_invalid'));
      expect(codesAfter(1, (m) => m['puzzle']['answerSpec']['codeLength'] = 4), contains('number_answer_invalid'));
      expect(codesAfter(1, (m) => m['puzzle']['answerSpec'].remove('codeLength')), contains('play_field_missing'));
      expect(
        codesAfter(1, (m) => m['puzzle']['answerSpec']
          ..['answer'] = '2575'
          ..['codeLength'] = 4
          ..['codeFormat'] = 'time'),
        contains('number_answer_invalid'),
      );
    });

    test('traces: a note not in the letter, places not the options, the guide on a trace, a picture changed', () {
      expect(codesAfter(2, (m) => m['play']['traces']['clues'][0]['line'] = 'The footprints go away.'), contains('scene_text_mismatch'));
      expect(codesAfter(2, (m) => (m['play']['traces']['places'] as List).removeLast()), contains('scene_answer_mismatch'));
      expect(codesAfter(2, (m) => m['play']['traces']['guideAt'] = [560, 900]), contains('scene_invalid'));
      expect(codesAfter(2, (m) => m['play']['traces']['clues'][0]['areas'] = [[0, 0, 2000, 10]]), contains('scene_area_invalid'));
      expect(codesAfter(2, (m) => m['play']['traces']['picture']['measuredOn'] = 'sha256:${'0' * 64}'), contains('coordinates_stale'));
      expect(codesAfter(2, (m) => m['puzzle']['engineTable'] = 'investigations'), contains('generate_unsupported'));
    });

    test('glass: two exhibits described, a line nothing confirms, the line to answer confirmed, the label opened by nothing', () {
      expect(codesAfter(3, (m) => m['play']['inspect']['spots'][0]['kind'] = 'match'), contains('scene_invalid'));
      expect(codesAfter(3, (m) => m['play']['inspect']['spots'][2]['checks'] = []), contains('scene_invalid'));
      expect(codesAfter(3, (m) => m['play']['inspect']['spots'][3]['checks'] = [1, 2, 3]), contains('scene_invalid'));
      expect(codesAfter(3, (m) => (m['play']['inspect']['spots'][3] as Map).remove('requires')), contains('scene_invalid'));
      expect(codesAfter(3, (m) => m['play']['inspect']['taskLine'] = 9), contains('scene_invalid'));
    });

    test('talk: evidence not in the notebook yet, a step that is not there, cards without the answer', () {
      expect(codesAfter(4, (m) => m['play']['interview']['presents'][0]['accepted'] = ['s8_ep02_e5']), contains('talk_evidence_unheld'));
      expect(codesAfter(4, (m) => m['play']['interview']['finishWhen'] = ['time', 'tools', 'ghost']), contains('scene_invalid'));
      expect(codesAfter(4, (m) => m['play']['interview']['finishWhen'] = ['time']), contains('scene_invalid'));
      expect(codesAfter(4, (m) => m['play']['interview']['presents'][0]['offered'] = ['s8_ep02_e2', 's8_ep02_e4']), contains('scene_answer_mismatch'));
      expect(codesAfter(4, (m) => m['play']['interview']['speaker'] = 'nobody'), contains('play_story_person'));
    });

    test('a field no engine reads: refused when read', () {
      final plan = raw();
      (missionOf(plan, 2)['play']['traces'] as Map)['answer'] = 'b';
      expect(() => CasePlan.fromJson(plan), throwsA(isA<PlanFormatException>()));
      final schemas = SchemaSet.load('tool/season_gen/schema');
      expect(schemas.validate(plan, 'case_plan.schema.json'), isNotEmpty);
    });
  });

  group('at each level', () {
    late Directory tmp;
    late String dir;
    // A few lines in other words (the rest kept): enough to tell the levels apart.
    const words = {
      'The footprints stop at the tower wall.': ('The footprints end at the tower wall.', 'The trail of footprints ends at the tower wall.'),
      'Strange writing… big and grey.': ('Strange writing, big and grey.', 'Strange script on a large grey slab.'),
      'Tap each record to read it.': ('Tap each record to read it.', 'Tap each record and read it through.'),
      'I came at 4:00 PM, like the notice says.': ('I came at 4:00 PM, as the notice says.', 'I arrived at 4:00 PM, just as the notice states.'),
    };

    // A line in its level's words, wherever it is said (a note and the letter that holds it alike).
    String reword(String s, String Function((String, String)) pick) {
      for (final MapEntry(:key, :value) in words.entries) {
        s = s.replaceAll(key, pick(value));
      }
      return s;
    }

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('engines_generation_');
      dir = '${tmp.path.replaceAll(r'\', '/')}/$plans';
      for (final f in Directory(plans).listSync(recursive: true).whereType<File>()) {
        File('${tmp.path}/${f.path.replaceAll(r'\', '/')}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(f.readAsBytesSync());
      }
      for (final id in ['s8_ep01', 's8_ep02']) {
        final plan = jsonDecode(File('$dir/cases/$id/case.plan.json').readAsStringSync());
        File('$dir/cases/$id/levels.json').writeAsStringSync(jsonEncode({
          'schemaVersion': 1,
          'caseId': id,
          'lines': [
            for (final s in CaseLevels.rookieLines(plan)) {'rookie': s, 'junior': reword(s, (w) => w.$1), 'master': reword(s, (w) => w.$2)},
          ],
          'glossary': {'junior': {}, 'master': {}},
        }));
      }
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('the same game at Junior and Master: every engine\'s check holds, the answers never change', () {
      final s = PlanFiles.loadSeasonPlan('$dir/season.plan.json');
      final path = '$dir/cases/s8_ep02/case.plan.json';
      expect(CaseLevels.checkCase(path, s, SchemaSet.load('tool/season_gen/schema')), isEmpty);
      final levels = CaseLevels.load(path)!;
      final rookie = CasePlan.fromJson(raw());
      for (final level in PlanLevel.values) {
        final plan = CasePlan.fromJson(levels.apply(raw(), level));
        expect([for (final x in PlayCheck.casePlan(plan, s)) if (x.blocking) '$x'], isEmpty, reason: level.name);
        expect([for (final m in plan.allMissions) m.puzzle.answerSpec.answer], [for (final m in rookie.allMissions) m.puzzle.answerSpec.answer], reason: level.name);
      }
    });

    test('a level that drops a trace\'s note from its letter is refused at that level', () {
      final file = File('$dir/cases/s8_ep02/levels.json');
      final json = jsonDecode(file.readAsStringSync()) as Map;
      final letter = (json['lines'] as List).cast<Map>().firstWhere((l) => (l['rookie'] as String).startsWith('The footprints stop at the tower wall.\n'));
      // The note keeps its Master words; the letter no longer says them.
      letter['master'] = 'The footprints go round the tower.\nThe lamp shines on one stone in the wall.\nThat stone has fresh scratches around it.';
      file.writeAsStringSync(jsonEncode(json));
      final s = PlanFiles.loadSeasonPlan('$dir/season.plan.json');
      expect(CaseLevels.checkCase('$dir/cases/s8_ep02/case.plan.json', s, SchemaSet.load('tool/season_gen/schema')).join('\n'), contains('scene_text_mismatch'));
    });

    test('generated: each engine\'s scene at Junior and Master in its own words, the same bytes twice', () {
      Generated make() => CaseGenerator.sandbox(seasonPath: '$dir/season.plan.json', casePaths: SeasonCases.of('$dir/season.plan.json'));
      final made = make();
      final levels = made.files['s8_ep02_levels.g.dart']!;
      expect(levels, allOf(contains("line: 'The footprints end at the tower wall.'"), contains("line: 'The trail of footprints ends at the tower wall.'")));
      expect(levels, allOf(contains("line: 'Strange script on a large grey slab.'"), contains("readTask: 'Tap each record and read it through.'")));
      expect(levels, contains("'I arrived at 4:00 PM, just as the notice states.'"));
      expect(RegExp(r"answer: 'bell'").allMatches(levels), hasLength(2), reason: 'the talk gives the same answer at Junior and Master');
      expect(RegExp(r"optionId: 'b'").allMatches(levels), hasLength(2), reason: 'the stone is a place at both levels');
      expect(made.files['s8_timeline_levels.g.dart'], allOf(contains('deductions: {'), contains('inspections: {'), contains('records: {'), contains('talks: {')));
      expect(make().files, made.files);
    });
  });
}
