import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/season5/season5_content.dart';

/// Seoul Case 07 "Two Reports from Harbin" (PART 3, docs/SEOUL_CASE02_12_REDESIGN_PLAN.md
/// Case 07): the cry heard as "Koreya! Ura!" and read off Mr. Pak's word
/// card, the writer's noon train set against the 9:30 cry, and Mr. Sorin's
/// three claims answered by three cards of this case only, at every level.
void main() {
  Episode episode(Difficulty level) => DifficultyContent.episodeAt(
    Episode.fromJson({...season5Content.episodes['s5_ep07']!, 'seasonId': season5Content.id}),
    level,
    patches: season5Content.casePatches,
  );
  Mission mission(String id, [Difficulty level = Difficulty.rookie]) => episode(level).allMissions.firstWhere((m) => m.id == id);

  test('M1: Paper B says KOREYA! URA!; the note no longer gives away who was on the platform', () {
    final records = season5Content.records['s5_ep07_m1']!;
    expect(records.second.lines.last.value, 'KOREYA! URA!');
    expect(records.second.title, 'THE HARBIN DAILY');
    for (final level in Difficulty.values) {
      final m = mission('s5_ep07_m1', level);
      expect(m.letter, isNot(contains('Only one writer')), reason: level.label);
      expect(m.letter, contains('Itō forced the 1905 treaty on Korea'), reason: level.label);
    }
  });

  test('M2: the cry is fixed at 9:30, before the noon train; one order at every level', () {
    final spec = season5Content.timelines['s5_ep07_m2']!;
    expect(spec.order.join(','), 'pak_start,shout,noon,tea,write,print');
    expect(spec.card('shout')!.anchor, '9:30');
    for (final level in Difficulty.values) {
      final m = mission('s5_ep07_m2', level);
      expect(m.answer, 'pak_start,shout,noon,tea,write,print', reason: level.label);
      expect(m.letter, contains('9:30'), reason: level.label);
      expect(m.options.map((o) => o.id).join(','), isNot(m.answer), reason: 'the board never shows the answer order');
    }
  });

  test('M3: KOREA from the word card; every other word on it has its own line', () {
    for (final level in Difficulty.values) {
      final m = mission('s5_ep07_m3', level);
      expect(m.letter, contains('Koreya! Ura!'), reason: level.label);
      expect(m.letter, contains('Koreya = Korea'), reason: level.label);
      expect(AnswerChecker.isCorrect(m, 'KOREA'), isTrue, reason: level.label);
      for (final w in ['RUSSIA', 'MONEY', 'HURRAH', 'KOREYA', 'HARBIN']) {
        expect(AnswerChecker.isCorrect(m, w), isFalse, reason: '${level.label} $w');
        expect(AnswerChecker.feedbackFor(m, w), isNotNull, reason: '${level.label} $w');
      }
      // Before M3, the cry's meaning in English is never given away.
      for (final id in ['s5_ep07_m1', 's5_ep07_m2']) {
        expect(mission(id, level).letter, isNot(contains('Korea, hurrah')), reason: '${level.label} $id');
      }
    }
  });

  test("Final: three cards each, this case's only; each claim answered by one card; lit from the third miss", () {
    final talk = season5Content.talks['s5_ep07_final']!;
    final want = {'where': 's5_ep07_e2', 'what': 's5_ep07_e3', 'why': 's5_ep07_e1'};
    for (final p in talk.presents) {
      expect(p.choices, hasLength(3), reason: p.id);
      expect(p.choices.every((e) => e.startsWith('s5_ep07_')), isTrue, reason: p.id);
      expect(p.accepted, {want[p.id]}, reason: p.id);
      expect(p.litAfter, 3, reason: p.id);
      expect(p.choices.first, isNot(want[p.id]), reason: '${p.id}: the right card is never first');
    }
    final fin = mission('s5_ep07_final');
    expect(fin.hints, hasLength(2));
    expect(fin.letter, allOf(contains('called out nothing.'), contains('He wanted money.')));
  });

  test('stands alone: no other case, no water drop, no letter box, at every level', () {
    for (final level in Difficulty.values) {
      final ep = episode(level);
      final text = [
        ...ep.intro,
        for (final m in ep.allMissions) ...[...m.story, m.letterIntro, m.letter, m.question, ...m.hints, ...m.transition],
      ].join('\n');
      for (final w in ['water drop', 'letter box', 'keeper', 'Bongsu', 'Emperor', 'Morning News', RegExp(r's5_ep(0[1-689]|1\d)_')]) {
        expect(text, isNot(contains(w)), reason: '${level.label}: $w');
      }
      expect(ep.intro.join(' '), contains('morning'), reason: '${level.label}: the cry was in the morning');
    }
  });
}
