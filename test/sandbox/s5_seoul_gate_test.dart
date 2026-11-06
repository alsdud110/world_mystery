import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/history_dossier.dart';
import '../../tool/season_gen/season_cases.dart';

/// Seoul (Season 5) Case 01 (`content_pipeline/seasons/s5_seoul`) while its
/// history's automatic checks fail and once they pass (no person approves
/// it). While they fail: its content is never made to be played —
/// the generator refuses it for the sandbox as for the game, a check makes it
/// in memory only (unwritable), and nothing of it is on disk to play. Once
/// they pass: it must be made (`generate_season.dart --season … --target sandbox`) and
/// stay as its plans make it, to be played with `SingleCase`.
void main() {
  const plans = 'content_pipeline/seasons/s5_seoul';
  const out = 'lib/data/generated/s5_seoul'; // Season 5 in the game (generate_season.dart --target game)
  final cases = SeasonCases.of('$plans/season.plan.json');
  List<String> blockers() => HistoryGate.blockers(plans, game: true);

  test('a historical season, its twelve cases written', () {
    expect(SeasonMode.of(plans), SeasonMode.historicalFictionMystery);
    expect(cases.map((c) => File(c).parent.uri.pathSegments.reversed.elementAt(1)),
        [for (var i = 1; i <= 12; i++) 's5_ep${i.toString().padLeft(2, '0')}']);
  });

  if (blockers().isNotEmpty) {
    group('while its checks fail', () {
      test('every blocker a fact still a draft or a level unwritten, none a broken plan; no case unwritten asked for', () {
        final b = blockers();
        expect(b, isNotEmpty);
        for (final line in b) {
          expect(line, matches(RegExp(r'history_(fact_unchecked|levels_pending)')), reason: line);
        }
      });

      test('never made to be played: the sandbox refuses it, a check makes it unwritable', () {
        expect(
          () => CaseGenerator.sandbox(seasonPath: '$plans/season.plan.json', casePaths: cases),
          throwsA(isA<GenerateFailure>().having((e) => e.lines.join('\n'), 'lines', contains('history_blocked'))),
        );
        final checked = CaseGenerator.sandbox(seasonPath: '$plans/season.plan.json', casePaths: cases, staticOnly: true);
        expect(checked.writable, isFalse, reason: 'its plans hold together (every check but history), yet nothing may be written');
        expect(checked.files.keys.where((k) => k.contains('history')), isEmpty);
        expect(makeAndWrite(() => checked, out: '${Directory.systemTemp.createTempSync('s5_seoul_').path}/out'), 1);
      });

      test('nothing of it on disk to play', () {
        expect(Directory(out).existsSync(), isFalse, reason: '$out: no pilot content while its checks fail');
      });
    });
  } else {
    group('once its checks pass', () {
      test('made, and as its plans make it now', () {
        final made = CaseGenerator.sandbox(seasonPath: '$plans/season.plan.json', casePaths: cases);
        expect(made.writable, isTrue);
        expect(made.files.keys, contains('s5_seoul_history.g.dart'));
        // In the game whole, made fresh (test/generated_seasons_test.dart);
        // no hand-registered sandbox copy of it is left.
        expect(File('$out/s5_seoul_history.g.dart').existsSync(), isTrue,
            reason: 'run: dart run tool/season_factory/season_factory.dart run $plans');
        expect(Directory('lib/data/season5/s5_seoul').existsSync(), isFalse);
      });
    });
  }
}
