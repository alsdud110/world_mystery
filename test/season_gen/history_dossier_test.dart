import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ai_agents/env_file.dart';
import '../../tool/ai_agents/history_guard.dart';
import '../../tool/ai_agents/image_manifest.dart';
import '../../tool/ai_agents/openai_image.dart';
import '../../tool/asset_pipeline/asset_pipeline.dart';
import '../../tool/asset_pipeline/asset_plan.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/history_dossier.dart';
import '../../tool/season_gen/season_cases.dart';
import '../../tool/season_planner/finding.dart';
import '../../tool/season_planner/plan_season.dart';
import '../../tool/season_planner/season_quality.dart';
import 'timeline_fixture.dart';

/// Historical Fiction Mystery (PART 1–2): the mode, the dossier's checks
/// (no person's approval: the checks are the gate), and the gates before
/// anything is paid for and before the game — on a copy of the Rome season
/// made historical (its first mission of each case "rests" on a made-up
/// fact; the facts are fixtures, not history).
void main() {
  const trial = 'content_pipeline/seasons/s3_rome';
  late Directory tmp;
  late String dir;

  Map<String, dynamic> read(String file) => (jsonDecode(File('$dir/$file').readAsStringSync()) as Map).cast<String, dynamic>();
  void write(String file, Object? json) => File('$dir/$file').writeAsStringSync(jsonEncode(json));
  void edit(String file, void Function(Map<String, dynamic> json) change) {
    final json = read(file);
    change(json);
    write(file, json);
  }

  List<String> caseIds() => [for (var i = 1; i <= 12; i++) 's3_ep${i.toString().padLeft(2, '0')}'];

  Map<String, Object?> source(String publisher, String kind) => {
    'kind': kind,
    'publisher': publisher,
    'title': 'A record',
    'url': 'https://example.org/$publisher',
    'quote': 'the words that bear it out',
    'checkedAt': '2026-11-04',
  };

  /// The years a case's words hold (its numbers as words, never pixels): the fixture declares them made up.
  Set<String> yearsIn(Object? v) => switch (v) {
    final String s => {for (final m in RegExp(r'(?<![0-9])(1[0-9]{3}|20[0-9]{2})(?![0-9])').allMatches(s)) m[1]!},
    final List<dynamic> l => {for (final x in l) ...yearsIn(x)},
    final Map<dynamic, dynamic> m => {for (final x in m.values) ...yearsIn(x)},
    _ => const {},
  };

  Map<String, Object?> dossier() => {
    'schemaVersion': 1,
    'seasonId': 's3_rome',
    'cases': [
      for (final id in caseIds())
        () {
          final plan = read('cases/$id/case.plan.json');
          final all = [...(plan['missions'] as List).cast<Map>(), plan['final'] as Map];
          // Every puzzle listed (STEP 1): the first on the case's fact, the rest made up.
          Map<String, Object?> puzzle(Map m, {required bool fact}) {
            final spec = m['puzzle']['answerSpec'] as Map;
            final options = [for (final o in (spec['options'] as List? ?? const [])) (o as Map)['id'] as String];
            return {
              'puzzleId': m['missionId'],
              if (fact) 'factIds': ['${id}_h1'] else 'fiction': true,
              'answer': spec['answer'],
              'clues': [
                {'text': m['play']['location']},
              ],
              'derivation': 'The place named leads to the answer.',
              if (options.contains(spec['answer']))
                'whyNot': {for (final o in options) if (o != spec['answer']) o: 'The letter rules it out.'}
              else
                'whyOnly': 'Only this order fits the letter.',
            };
          }

          final years = {for (final x in [...plan['missions'] as List, plan['final']]) ...yearsIn((x as Map)['play'])};
          return {
            'caseId': id,
            'subject': 'Subject of $id',
            'period': '1446',
            'location': 'A place',
            'facts': [
              {
                'factId': '${id}_h1',
                'statement': 'A fact of $id, in 1446.',
                'status': 'source_checked',
                'sources': [source('archive', 'primary'), source('museum', 'academic')],
                'conflict': {'status': 'none'},
              },
            ],
            'fiction': ['The theft is made up.', if (years.isNotEmpty) 'Its times and numbers are made up: ${years.join(', ')}.'],
            'puzzles': [for (final (i, m) in all.indexed) puzzle(m, fact: i == 0)],
            'learningObjectives': ['Read a place name.'],
            'reveal': {
              'realHistory': [
                {
                  'text': 'This happened in Seoul in 1446.',
                  'junior': 'This really took place in Seoul in 1446.',
                  'master': 'In 1446, this genuinely unfolded in Seoul.',
                  'factIds': ['${id}_h1'],
                },
              ],
              'inThisMystery': [
                {'text': 'The thief is made up.', 'junior': 'The thief was invented for the game.', 'master': 'The thief is an invention of this story.'},
              ],
            },
          };
        }(),
    ],
  };

  void historical() => edit('planning/brief.json', (b) => b['mode'] = SeasonMode.historicalName);
  Map<String, dynamic> caseOf(Map<String, dynamic> d, String caseId) => ((d['cases'] as List).firstWhere((c) => c['caseId'] == caseId) as Map).cast<String, dynamic>();
  void editCase(String caseId, void Function(Map<String, dynamic> c) change) => edit(HistoryDossier.path, (d) => change(caseOf(d, caseId)));
  void editFact(String caseId, void Function(Map<String, dynamic> fact) change) =>
      editCase(caseId, (c) => change(((c['facts'] as List).first as Map).cast<String, dynamic>()));
  void editPuzzle(String caseId, void Function(Map<String, dynamic> puzzle) change) =>
      editCase(caseId, (c) => change(((c['puzzles'] as List).first as Map).cast<String, dynamic>()));
  void editRealLine(String caseId, void Function(Map<String, dynamic> line) change) =>
      editCase(caseId, (c) => change((((c['reveal'] as Map)['realHistory'] as List).first as Map).cast<String, dynamic>()));
  /// Every case's fact [status]: `draft` (its sources not checked yet) or `source_checked`.
  void factsAre(String status) => edit(HistoryDossier.path, (d) {
    for (final c in d['cases'] as List) {
      ((c['facts'] as List).first as Map)['status'] = status;
    }
  });
  void draftFacts() => factsAre('draft');
  void checkFacts() => factsAre('source_checked');
  List<String> missionsOf(String caseId) {
    final plan = read('cases/$caseId/case.plan.json');
    return [for (final m in [...plan['missions'] as List, plan['final']]) (m as Map)['missionId'] as String];
  }

  QualityReport check() => SeasonQuality.run(dir);
  List<String> historyErrors(QualityReport r) => [for (final f in r.findings) if (f.isError && f.source == Source.history) f.code];
  List<String> historyCodes(QualityReport r) => [for (final f in r.findings) if (f.source == Source.history) f.code];
  String messagesOf(QualityReport r, String code) => [for (final f in r.findings) if (f.code == code) f.message].join('\n');
  String gate({bool game = false}) => HistoryGate.blockers(dir, game: game).join('\n');

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('history_dossier_');
    dir = '${tmp.path.replaceAll(r'\', '/')}/$trial';
    for (final f in Directory(trial).listSync(recursive: true).whereType<File>()) {
      File('${tmp.path}/${f.path.replaceAll(r'\', '/')}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(f.readAsBytesSync());
    }
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  group('the mode', () {
    test('no mode: the standard mode, no history check, no gate', () {
      expect(SeasonMode.of(dir), SeasonMode.standard);
      expect(historyCodes(check()), isEmpty);
      expect(HistoryGate.blockers(dir), isEmpty);
      expect(HistoryGate.blockers(dir, game: true), isEmpty);
      File('$dir/planning/brief.json').deleteSync();
      expect(SeasonMode.of(dir), SeasonMode.standard, reason: 'no brief at all is the standard mode too');
    });

    test('the standard mode never reads a dossier, even a broken one', () {
      File('$dir/${HistoryDossier.path}').writeAsStringSync('not json');
      expect(historyCodes(check()), isEmpty);
      expect(HistoryGate.blockers(dir), isEmpty);
    });

    test('an unknown mode is an error, and blocks', () {
      edit('planning/brief.json', (b) => b['mode'] = 'historical');
      expect(() => SeasonMode.of(dir), throwsFormatException);
      expect(historyErrors(check()), ['season_mode_unknown']);
      expect(gate(), contains('mode'));
    });

    test('init --mode writes it; without, no mode; another value refused', () {
      final root = '${tmp.path}/seasons';
      SeasonBrief.parse(['--season', '7', '--city', 'Seoul', '--root', root, '--mode', SeasonMode.historicalName]).write();
      expect(jsonDecode(File('$root/s7_seoul/planning/brief.json').readAsStringSync())['mode'], SeasonMode.historicalName);
      expect(SeasonMode.of('$root/s7_seoul'), SeasonMode.historicalFictionMystery);
      SeasonBrief.parse(['--season', '8', '--city', 'Busan', '--root', root]).write();
      expect((jsonDecode(File('$root/s8_busan/planning/brief.json').readAsStringSync()) as Map).containsKey('mode'), isFalse);
      expect(() => SeasonBrief.parse(['--season', '9', '--city', 'Jeju', '--root', root, '--mode', 'history']), throwsFormatException);
    });
  });

  group('the dossier', () {
    setUp(() {
      historical();
      write(HistoryDossier.path, dossier());
    });

    test('a written case without its entry: an error; a case not written yet asks for none (Seoul Pilot)', () {
      edit(HistoryDossier.path, (d) => (d['cases'] as List).removeWhere((c) => (c as Map)['caseId'] == 's3_ep12'));
      expect(historyErrors(check()), contains('history_case_missing'));
      expect(gate(game: true), contains('s3_ep12 has no entry'));
      File('$dir/cases/s3_ep12/case.plan.json').deleteSync();
      expect(gate(game: true), isNot(contains('history_case_missing')));
    });

    test('missing: an error, and the gate is shut', () {
      File('$dir/${HistoryDossier.path}').deleteSync();
      expect(historyErrors(check()), ['history_dossier_missing']);
      expect(gate(), contains('history_dossier_missing'));
    });

    test('whole, sourced and checked: no error, nothing pending, both gates open with no one\'s approval', () {
      final r = check();
      expect(historyErrors(r), isEmpty, reason: r.findings.where((f) => f.isError).join('\n'));
      // Every mission is a puzzle of the dossier (STEP 1): a case's first on its fact, the rest made up.
      final puzzles = caseIds().expand(missionsOf).length;
      final summary = r.summary['history'] as Map;
      expect([summary['source_checked'], summary['puzzles'], summary['reveals'], summary['pending']], [12, puzzles, 12, 0]);
      expect(HistoryGate.blockers(dir), isEmpty);
      expect(HistoryGate.blockers(dir, game: true), isEmpty);
    });

    test('a status other than draft, source_checked or rejected is an error', () {
      editFact('s3_ep01', (f) => f['status'] = 'approved');
      expect(historyErrors(check()), contains('history_status_unknown'));
    });

    test('one source is not enough', () {
      editFact('s3_ep01', (f) => (f['sources'] as List).removeLast());
      expect(messagesOf(check(), 'history_source_rule'), contains('two independent sources'));
      expect(gate(), contains('history_source_rule'));
    });

    test('two links of one publisher are not two independent sources', () {
      editFact('s3_ep01', (f) => f['sources'] = [source('archive', 'primary'), {...source('Archive', 'press'), 'url': 'https://other.example.org/x'}]);
      expect(messagesOf(check(), 'history_source_rule'), contains('one publisher'));
    });

    test('no primary or public source', () {
      editFact('s3_ep01', (f) => f['sources'] = [source('paper', 'press'), source('blog', 'other')]);
      expect(messagesOf(check(), 'history_source_rule'), contains('primary or public_institution'));
    });

    test('a source never opened (no checkedAt, no quote) is not checked', () {
      editFact('s3_ep01', (f) => ((f['sources'] as List).first as Map)..remove('checkedAt')..remove('quote'));
      expect(messagesOf(check(), 'history_source_rule'), allOf(contains('checkedAt'), contains('quote')));
    });

    test('sources in conflict, unresolved: an error, the gate shut', () {
      editFact('s3_ep01', (f) => f['conflict'] = {'status': 'unresolved', 'note': '1896 or 1898'});
      expect(messagesOf(check(), 'history_source_rule'), contains('unresolved'));
      expect(gate(), contains('history_source_rule'));
    });

    test('a draft fact a puzzle rests on keeps the gate shut', () {
      editFact('s3_ep02', (f) => f['status'] = 'draft');
      expect(historyErrors(check()), isEmpty);
      expect(gate(), allOf(contains('history_fact_unchecked'), contains('s3_ep02_h1')));
    });

    test('a rejected fact is never a ground for a puzzle', () {
      editFact('s3_ep01', (f) => f['status'] = 'rejected');
      expect(historyErrors(check()), contains('history_fact_rejected'));
    });

    test('another part of the dossier changed: the gates stay open', () {
      editCase('s3_ep01', (c) => c['subject'] = 'Renamed');
      expect(HistoryGate.blockers(dir, game: true), isEmpty);
    });

    test('a puzzle naming a fact that is not there', () {
      editPuzzle('s3_ep02', (p) => p['factIds'] = ['s3_ep02_h9']);
      expect(historyErrors(check()), contains('history_fact_unknown'));
      expect(gate(), contains('s3_ep02_h9'));
    });

    test('a puzzle that is no mission, an answer that is not the plan\'s', () {
      editPuzzle('s3_ep01', (p) => p['puzzleId'] = 's3_ep01_m9');
      editPuzzle('s3_ep02', (p) => p['answer'] = 'wrong');
      expect(historyErrors(check()), containsAll(['history_puzzle_unknown', 'history_answer_mismatch']));
    });

    test('a clue the player never reads', () {
      editPuzzle('s3_ep01', (p) => p['clues'] = [{'text': 'BRONZE OWL OF 1446'}]);
      expect(historyErrors(check()), contains('history_clue_not_shown'));
    });

    test('a clue a level leaves out', () {
      edit('cases/s3_ep01/levels.json', (l) {
        for (final line in (l['lines'] as List).cast<Map>()) {
          line['junior'] = (line['junior'] as String).replaceAll(RegExp('guard room', caseSensitive: false), 'WATCH HALL');
        }
      });
      expect(messagesOf(check(), 'history_clue_not_shown_at_level'), contains('junior'));
    });

    test('a clue read only after the puzzle', () {
      editPuzzle('s3_ep01', (p) => p['clues'] = [{'text': 'THE GUARD ROOM', 'missionId': 's3_ep01_m2'}]);
      expect(historyErrors(check()), contains('history_clue_late'));
    });

    test('a case with no puzzle on its history', () {
      editCase('s3_ep01', (c) => c['puzzles'] = []);
      expect(historyErrors(check()), containsAll(['history_field_missing', 'history_case_unlinked']));
    });
  });

  group('reasoning a player can follow', () {
    setUp(() {
      historical();
      write(HistoryDossier.path, dossier());
    });

    test('one answer: every wrong option ruled out, or why nothing else fits', () {
      editPuzzle('s3_ep01', (p) => (p['whyNot'] as Map).remove('alarm'));
      editPuzzle('s3_ep02', (p) => p.remove('whyOnly'));
      final r = check();
      expect(messagesOf(r, 'history_uniqueness_missing'), allOf(contains('"alarm"'), contains('no other')));
    });

    test('a year in a hint the dossier does not hold up: a possible distortion', () {
      edit('cases/s3_ep01/case.plan.json', (p) {
        final play = ((p['missions'] as List).first as Map)['play'] as Map;
        play['hints'] = [...play['hints'] as List, 'It happened in 1999.'];
      });
      expect(messagesOf(check(), 'history_year_unsupported'), contains('1999'));
      editCase('s3_ep01', (c) => (c['fiction'] as List).add('The 1999 story is made up.'));
      expect(historyErrors(check()), isNot(contains('history_year_unsupported')), reason: 'declared made up');
    });

    test('a year answer the game never says needs history the player was never told', () {
      edit('cases/s3_ep02/case.plan.json', (p) => (((p['missions'] as List).first as Map)['puzzle']['answerSpec'] as Map)['answer'] = '1446');
      editPuzzle('s3_ep02', (p) => p['answer'] = '1446');
      expect(historyErrors(check()), contains('history_answer_unshown'));
    });

    test('a case whose levels are not written: the game waits, the pictures do not', () {
      File('$dir/cases/s3_ep01/levels.json').renameSync('$dir/cases/s3_ep01/levels.off');
      expect(HistoryGate.blockers(dir), isEmpty);
      expect(gate(game: true), contains('history_levels_pending'));
    });
  });

  group('the reveal at each level', () {
    setUp(() {
      historical();
      write(HistoryDossier.path, dossier());
    });

    test('every level written, the same numbers and names, its own English', () {
      editRealLine('s3_ep01', (l) => l.remove('master'));
      editRealLine('s3_ep02', (l) => l['junior'] = 'This really took place in Seoul in 1447.');
      editRealLine('s3_ep03', (l) => l['master'] = 'In 1446, this genuinely unfolded in the capital.');
      editRealLine('s3_ep04', (l) => l['junior'] = 'This happened in Seoul in 1446.');
      editRealLine('s3_ep04', (l) => l['text'] = l['junior'] = 'This all happened in old Seoul in 1446.');
      final r = check();
      expect(historyErrors(r), contains('history_field_missing'));
      expect(messagesOf(r, 'history_reveal_level'), allOf(contains('1447'), contains('leaves out Seoul'), contains("Rookie's line again")));
    });

    test('REAL HISTORY says no year its facts do not say', () {
      editRealLine('s3_ep01', (l) {
        l['text'] = 'This happened in Seoul in 1450.';
        l['junior'] = 'This really took place in Seoul in 1450.';
        l['master'] = 'In 1450, this genuinely unfolded in Seoul.';
      });
      expect(historyErrors(check()), contains('history_reveal_unsupported'));
    });
  });

  group('the paid steps', () {
    setUp(() {
      historical();
      write(HistoryDossier.path, dossier());
    });

    ImageStudio studio(_CountingApi api, List<String> log) => ImageStudio(
      api: api,
      editApi: api,
      findKey: () => ApiKey.find(envPath: 'none', environment: {'OPENAI_API_KEY': 'sk-test-0123456789abcdef'}),
      root: tmp.path,
      log: log.add,
    );

    test('the asset pipeline sends nothing while a fact is a draft', () async {
      draftFacts();
      edit('assets.manifest.json', (m) {
        for (final a in (m['assets'] as List).cast<Map>()) {
          a['status'] = 'planned';
        }
      });
      final plan = AssetPlan.load('$trial/assets.manifest.json', root: tmp.path);
      expect(plan.ok, isTrue, reason: plan.errors.join('\n'));
      final api = _CountingApi();
      final log = <String>[];
      AssetPipeline pipeline() => AssetPipeline(plan: plan, studio: studio(api, log), log: log.add);
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 3);
      expect(api.calls, 0);
      expect(log.join('\n'), contains('history_fact_unchecked'));

      checkFacts();
      log.clear();
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), isNot(3));
      expect(log.where((l) => l.startsWith('history')), isEmpty, reason: 'past the gate once every fact is checked');
    });

    test('the image tool alone: a historical season\'s picture is never sent while its checks fail; any other is', () async {
      draftFacts();
      final api = _CountingApi();
      final log = <String>[];
      const raw = 'content_pipeline/asset_work/s3_rome/raw/places/x.png';
      for (final out in ['$trial/scratch/x.png', raw]) {
        log.clear();
        expect(await studio(api, log).run(ImageRequest(prompt: 'A quiet square.', output: out), generate: true), 2, reason: out);
        expect(log.join('\n'), contains('belongs to a historical season'), reason: 'stopped by the history gate, not another rule');
      }
      expect(api.calls, 0);
      // Not a historical season's: as before (sent, and here the fake API fails).
      expect(await studio(api, log).run(ImageRequest(prompt: 'A quiet square.', output: 'qa/ai_image_tests/x.png'), generate: true), 1);
      expect(api.calls, 1);
      // A dry run sends nothing and is never stopped.
      expect(await studio(api, log).run(ImageRequest(prompt: 'A quiet square.', output: raw)), 0);
      checkFacts();
      log.clear();
      expect(await studio(api, log).run(ImageRequest(prompt: 'A quiet square.', output: raw), generate: true), 1);
      expect(api.calls, 2, reason: 'sent once its facts are checked');
      expect(HistoryGate.forOutput(tmp.path, 'assets/seasons/season_03_rome/places/x.png'), isEmpty, reason: 'checked: its asset root open too');
    });

    test('sound and hand-made image calls: stopped for a historical season only', () {
      draftFacts();
      const sfx = 'elevenlabs text-to-sound-effects convert --text "bell" --output assets/seasons/season_03_rome/sounds/bell.mp3';
      expect(HistoryGuard.command(sfx, tmp.path), isNotEmpty);
      expect(HistoryGuard.command('python3 -c "client.text_to_sound_effects.convert(text=\'x\'); open(\'./assets/seasons/season_03_rome/a.wav\',\'wb\')"', tmp.path), isNotEmpty);
      expect(HistoryGuard.command('curl https://api.openai.com/v1/images/generations -o content_pipeline/seasons/s3_rome/x.png', tmp.path), isNotEmpty);
      expect(HistoryGuard.command(sfx.replaceAll('assets/seasons/season_03_rome/sounds', 'qa/sounds'), tmp.path), isEmpty, reason: 'no season\'s file');
      expect(HistoryGuard.command('cp a.mp3 assets/seasons/season_03_rome/sounds/bell.mp3', tmp.path), isEmpty, reason: 'no paid call');
      checkFacts();
      expect(HistoryGuard.command(sfx, tmp.path), isEmpty);
    });

    test('the standard season\'s files are never stopped', () {
      edit('planning/brief.json', (b) => b.remove('mode'));
      expect(HistoryGate.forOutput(tmp.path, 'assets/seasons/season_03_rome/places/x.png'), isEmpty);
      expect(HistoryGuard.command('elevenlabs text-to-sound-effects convert --output assets/seasons/season_03_rome/a.mp3', tmp.path), isEmpty);
    });

    test('the guard command and its hook: exit 2 before the call, 0 for anything else', () async {
      Future<ProcessResult> hook(String command, {String? project, bool shell = false}) async {
        final p = await Process.start(
          shell ? 'sh' : 'dart',
          shell ? ['tool/ai_agents/history_guard_hook.sh'] : ['run', 'tool/ai_agents/history_guard.dart', '--hook'],
          environment: {'CLAUDE_PROJECT_DIR': project ?? Directory.current.path},
        );
        p.stdin.write(jsonEncode({'tool_name': 'Bash', 'tool_input': {'command': command}}));
        await p.stdin.close();
        final err = await p.stderr.transform(utf8.decoder).join();
        await p.stdout.drain<void>();
        return ProcessResult(p.pid, await p.exitCode, '', err);
      }

      draftFacts();
      const sfx = 'elevenlabs text-to-sound-effects convert --text "bell" --output assets/seasons/season_03_rome/a.mp3';
      final stopped = await hook(sfx, project: tmp.path);
      expect(stopped.exitCode, 2);
      expect(stopped.stderr, contains('history_fact_unchecked'));
      expect((await hook(sfx)).exitCode, 0, reason: 'the real Rome is a standard season');
      expect((await hook('ls -la', shell: true)).exitCode, 0, reason: 'any other command passes the hook without Dart');
    });

    test('the game is made with its reveals once the checks pass, with no one\'s approval', () {
      Generated make() => CaseGenerator.sandbox(seasonPath: '$dir/season.plan.json', casePaths: SeasonCases.of('$dir/season.plan.json'), target: 'game');
      draftFacts();
      expect(make, throwsA(isA<GenerateFailure>().having((e) => e.lines.join('\n'), 'lines', contains('history_blocked'))));
      checkFacts();
      final made = make();
      expect(made.files['s3_rome_content.g.dart'], contains('historyReveals: s3RomeHistoryReveals,'));
      final history = made.files['s3_rome_history.g.dart']!;
      expect(history, allOf(contains("'s3_ep01': HistoryReveal("), contains("rookie: 'This happened in Seoul in 1446.'"), contains("master: 'The thief is an invention of this story.'")));
      expect(history, allOf(contains('HistorySource('), contains("publisher: 'archive'"), contains("url: 'https://example.org/museum'")));
      expect(made.files['generated.manifest.json'], contains(HistoryDossier.path));
    });

    test('the sandbox too: blocked while the checks fail, a check made unwritable, made with its reveals after', () {
      Generated make({bool staticOnly = false}) =>
          CaseGenerator.sandbox(seasonPath: '$dir/season.plan.json', casePaths: SeasonCases.of('$dir/season.plan.json'), staticOnly: staticOnly);
      draftFacts();
      expect(make, throwsA(isA<GenerateFailure>().having((e) => e.lines.join('\n'), 'lines', contains('history_fact_unchecked'))));
      final checked = make(staticOnly: true);
      expect(checked.writable, isFalse);
      expect(checked.notes.join('\n'), contains('blockers'));
      expect(checked.files.keys.where((k) => k.contains('history')), isEmpty, reason: 'no reveal while its checks fail');
      final out = '${tmp.path}/out';
      expect(makeAndWrite(() => checked, out: out), 1);
      expect(Directory(out).existsSync(), isFalse, reason: 'nothing written');
      checkFacts();
      final made = make();
      expect(made.writable, isTrue);
      expect(made.files['s3_rome_history.g.dart'], contains("rookie: 'This happened in Seoul in 1446.'"));
      expect(made.files.keys.where((k) => k.contains('_content') || k.contains('_art')), isEmpty, reason: 'the sandbox, not the game');
      expect(makeAndWrite(() => made, out: out), 0);
      expect(File('$out/s3_rome_history.g.dart').existsSync(), isTrue);
    });

    test('a standard sandbox season is made and written as before, check or not', () {
      final made = CaseGenerator.sandbox(seasonPath: '$trial/season.plan.json', casePaths: SeasonCases.of('$trial/season.plan.json'));
      final checked = CaseGenerator.sandbox(seasonPath: '$trial/season.plan.json', casePaths: SeasonCases.of('$trial/season.plan.json'), staticOnly: true);
      expect([made.writable, checked.writable], [true, true]);
      expect(checked.files, made.files);
      expect(made.files.keys.where((k) => k.contains('history')), isEmpty);
    });

    test('the standard season is made as before: no reveals', () {
      final made = CaseGenerator.sandbox(seasonPath: '$trial/season.plan.json', casePaths: SeasonCases.of('$trial/season.plan.json'), target: 'game');
      expect(made.files.keys.where((k) => k.contains('history')), isEmpty);
      expect(made.files['s3_rome_content.g.dart'], isNot(contains('historyReveals')));
    });
  });

  group('a timeline of a historical season (Puzzle Engine 2.0)', () {
    // Tuesday is real history (its fact); the other days and the closed door are made up.
    List<Map<String, Object?>> sourced() => [
      for (final c in romeTimelineCards())
        c['id'] == 'tuesday' ? {...c, 'factIds': ['s3_ep08_h1']} : {...c, 'fiction': true},
    ];
    Map<String, Object?> puzzle({List<String> facts = const ['s3_ep08_h1']}) => {
      'puzzleId': romeTimelineMission,
      'factIds': facts,
      'answer': 'tuesday,thursday,friday_am,midnight',
      'clues': [
        {'text': 'TUESDAY'},
      ],
      'derivation': 'The diary rows put the days in the week\'s order.',
      'whyOnly': 'Each day comes once, in the week\'s order.',
    };
    void plan({List<Map<String, Object?>>? cards}) {
      makeRomeTimeline(dir, cards: cards ?? sourced());
      historical();
      write(HistoryDossier.path, dossier());
      // In place of the fixture's made-up entry for the mission.
      editCase(romeTimelineCase, (c) => (c['puzzles'] as List)
        ..removeWhere((p) => (p as Map)['puzzleId'] == romeTimelineMission)
        ..add(puzzle()));
    }

    void editCard(String id, void Function(Map<String, dynamic> c) change) => edit('cases/$romeTimelineCase/case.plan.json', (p) {
      final m = (p['missions'] as List).cast<Map>().firstWhere((m) => m['missionId'] == romeTimelineMission);
      change(((m['play']['timeline']['cards'] as List).cast<Map>().firstWhere((c) => c['id'] == id)).cast<String, dynamic>());
    });

    test('every card sourced, the mission a puzzle of the dossier: no error; a draft fact under a card shuts the gate', () {
      plan();
      expect(historyErrors(check()), isEmpty, reason: check().findings.where((f) => f.isError).join('\n'));
      expect(HistoryGate.blockers(dir, game: true), isEmpty);
      draftFacts();
      expect(gate(), contains('the card tuesday rests on s3_ep08_h1'));
    });

    test('a card that says nowhere where it comes from, or says both', () {
      plan(cards: [for (final c in sourced()) c['id'] == 'monday' ? ({...c}..remove('fiction')) : c]);
      expect(messagesOf(check(), 'history_timeline_card_source'), contains('monday: a card of real history names its checked facts'));
      editCard('tuesday', (c) => c['fiction'] = true);
      expect(messagesOf(check(), 'history_timeline_card_source'), contains('tuesday: facts and fiction both'));
    });

    test('a timeline that is no puzzle of the dossier; a card fact its puzzle does not list', () {
      plan();
      editCase(romeTimelineCase, (c) => (c['puzzles'] as List).removeLast());
      expect(historyErrors(check()), contains('history_timeline_unreviewed'));
      plan();
      editCard('midnight', (c) => c..remove('fiction')..['factIds'] = ['s3_ep07_h1']);
      expect(messagesOf(check(), 'history_timeline_fact_unlisted'), contains('s3_ep07_h1'));
    });

    test('no false history set aside: a card resting on a rejected fact', () {
      plan();
      editCard('monday', (c) => c..remove('fiction')..['factIds'] = ['s3_ep07_h1']);
      editCase(romeTimelineCase, (c) => ((c['puzzles'] as List).last as Map)['factIds'] = ['s3_ep08_h1', 's3_ep07_h1']);
      editFact('s3_ep07', (f) => f['status'] = 'rejected');
      expect(historyErrors(check()), contains('history_fact_rejected'));
    });

    test('a fixed card\'s year its facts do not say; a made-up one no fiction line declares', () {
      plan();
      editCard('tuesday', (c) => c['anchor'] = '1450');
      expect(messagesOf(check(), 'history_timeline_anchor_unsupported'), contains('1450, which none of its facts'));
      plan();
      editCard('thursday', (c) => c['anchor'] = '1499');
      expect(messagesOf(check(), 'history_timeline_anchor_unsupported'), contains('1499 on a made-up card'));
    });
  });

  group('every puzzle in the dossier (Puzzle Engine 2.0 STEP 1)', () {
    setUp(() {
      historical();
      write(HistoryDossier.path, dossier());
    });

    test('a mission the dossier does not list: pictures may wait, the game may not', () {
      final mid = missionsOf('s3_ep02')[1];
      editCase('s3_ep02', (c) => (c['puzzles'] as List).removeWhere((p) => (p as Map)['puzzleId'] == mid));
      expect(historyErrors(check()), isEmpty);
      expect(messagesOf(check(), 'history_puzzle_unlisted'), contains('$mid (text_choice) is no puzzle of the dossier'));
      expect(HistoryGate.blockers(dir), isEmpty, reason: 'its pictures rest on no fact');
      expect(HistoryGate.blockers(dir, game: true), [contains('history_puzzle_unlisted')], reason: 'that mission alone');
    });

    test('a made-up puzzle names no fact; a case of made-up puzzles only rests on no history', () {
      final mid = missionsOf('s3_ep03')[1];
      editCase('s3_ep03', (c) => ((c['puzzles'] as List).cast<Map>().firstWhere((p) => p['puzzleId'] == mid))['factIds'] = ['s3_ep03_h1']);
      expect(messagesOf(check(), 'history_puzzle_source'), contains('$mid: facts and fiction both'));
      write(HistoryDossier.path, dossier());
      editCase('s3_ep03', (c) => (((c['puzzles'] as List).first as Map)..remove('factIds'))['fiction'] = true);
      expect(historyErrors(check()), contains('history_case_unlinked'));
    });

    test("a record's value is read: a year it says is one the dossier holds up", () {
      final records = (jsonDecode(File('test/sandbox/plans/s8_timeline/cases/s8_ep02/case.plan.json').readAsStringSync())['missions'] as List).first['play']['records'] as Map;
      ((records['second'] as Map)['lines'] as List).cast<Map>().last['value'] = 'IN 1450';
      edit('cases/s3_ep05/case.plan.json', (p) => (((p['missions'] as List).first as Map)['play'] as Map)['records'] = records);
      expect(messagesOf(check(), 'history_year_unsupported'), contains('s3_ep05_m1 says 1450'));
    });
  });
}

class _CountingApi implements ImageApi, ImageEditApi {
  int calls = 0;

  @override
  Future<ApiImage> generate(Map<String, Object?> body, ApiKey key) async {
    calls++;
    throw const ApiFailure('no call is answered in this test', status: 500);
  }

  @override
  Future<ApiImage> edit(Map<String, Object?> body, ApiKey key) => generate(body, key);
}
