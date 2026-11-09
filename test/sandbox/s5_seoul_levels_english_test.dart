import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// PART 6: the three levels of Seoul Cases 01–12 are really three Englishes
/// (Rookie shortest, Junior and Master reworded), with one game under them:
/// the same answers, options and steps, line for line.
void main() {
  Episode at(String id, Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes[id]!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  final words = RegExp(r"[A-Za-z][A-Za-z'\-]*");

  /// Every text the child reads in a case, in order (a letter whole: its
  /// lines may be cut differently at each level).
  List<String> lines(Episode e) => [
    for (final m in e.allMissions) ...[...m.story, m.letter, m.question, ...m.hints, ...m.transition, m.successMessage],
  ];

  for (var n = 1; n <= 12; n++) {
    final id = 's5_ep${n.toString().padLeft(2, '0')}';
    test('$id: the same game at every level, its English reworded and Rookie the shortest', () {
      final r = at(id, Difficulty.rookie), j = at(id, Difficulty.junior), m = at(id, Difficulty.master);
      for (final e in [j, m]) {
        String game(Episode e) => [for (final x in e.allMissions) '${x.id} ${x.type.name} ${x.answer} ${x.options.map((o) => o.id).join(',')}'].join('\n');
        expect(game(e), game(r));
      }
      final (lr, lj, lm) = (lines(r), lines(j), lines(m));
      expect([lj.length, lm.length], [lr.length, lr.length], reason: 'one text for one text');
      // Lines of five words or more (names and labels are the same at every level).
      var prose = 0, jDiff = 0, mDiff = 0;
      for (var i = 0; i < lr.length; i++) {
        if (words.allMatches(lr[i]).length < 5) continue;
        prose++;
        if (lj[i] != lr[i]) jDiff++;
        if (lm[i] != lr[i] && lm[i] != lj[i]) mDiff++;
      }
      // The rest are clue sentences every level must show word for word.
      expect(jDiff / prose, greaterThan(0.6), reason: '$id Junior reworded $jDiff of $prose');
      expect(mDiff / prose, greaterThan(0.6), reason: '$id Master reworded $mDiff of $prose');
      int count(List<String> ls) => ls.fold(0, (a, l) => a + words.allMatches(l).length);
      expect(count(lr), lessThan(count(lj)), reason: '$id Rookie reads less than Junior');
      expect(count(lr), lessThan(count(lm)), reason: '$id Rookie reads less than Master');
    });
  }
}
