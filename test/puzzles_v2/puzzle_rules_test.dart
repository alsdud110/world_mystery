import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/timeline_rules.dart';

import '../helpers.dart';

/// Puzzle Engine 2.0 PART 3A: the rules' contract (no Flutter), the first
/// rules on it (the timeline's), saves in `puzzleStates`, levels and ids,
/// and the game's own answer check and rewards, unchanged.
void main() {
  const rules = TimelineRules();

  // Four cards that happened, two fixed by their years, one not part of it.
  TimelineSpec spec({String junior = '', List<String>? order, String? anchorB}) => TimelineSpec(
    cards: [
      const TimelineCard(id: 'gauge', title: 'THE GAUGE', text: 'A bronze cup for the rain.', anchor: '1441'),
      TimelineCard(id: 'letter', title: 'THE LETTER', text: 'The clerk writes to the palace.$junior'),
      const TimelineCard(id: 'bridge', title: 'THE BRIDGE', text: 'A stone marks the water.'),
      TimelineCard(id: 'book', title: 'THE BOOK', text: 'The new letters are shared.', anchor: anchorB ?? '1446'),
      const TimelineCard(id: 'list', title: 'A SHOPPING LIST', text: 'Rice and tea.', discard: true),
    ],
    order: order ?? const ['gauge', 'letter', 'bridge', 'book'],
    relations: const [
      TimelineRelation(earlier: 'letter', later: 'bridge', line: 'After the letter, a stone was set by the bridge.'),
    ],
  );

  group('the contract', () {
    test('no Flutter in the rules: the season tools run them as they are', () {
      final seen = <String>{};
      void walk(String path) {
        if (!seen.add(File(path).absolute.path)) return;
        for (final m in RegExp(r"^import '([^']+)';", multiLine: true).allMatches(File(path).readAsStringSync())) {
          final target = m[1]!;
          expect(target, isNot(startsWith('package:')), reason: '$path imports $target: the rules are plain Dart');
          if (!target.startsWith('dart:')) walk('${File(path).parent.path}/$target');
        }
      }

      for (final f in Directory('lib/puzzles_v2/core').listSync().whereType<File>()) {
        walk(f.path);
      }
      expect(seen.any((p) => p.endsWith('difficulty.dart')), isTrue);
    });

    test('a sound timeline: no issue', () {
      expect(rules.validate(spec()), isEmpty);
    });

    test('a spec read from JSON, and the reasons one does not read', () {
      final (ok, none) = TimelineSpec.parse({
        'cards': [
          {'id': 'a', 'title': 'A', 'text': 'a', 'anchor': '1'},
          {'id': 'b', 'title': 'B', 'text': 'b'},
          {'id': 'c', 'title': 'C', 'text': 'c', 'anchor': '3'},
        ],
        'order': ['a', 'b', 'c'],
      });
      expect([none, rules.validate(ok!)], [isEmpty, isEmpty]);
      final (bad, why) = TimelineSpec.parse({'cards': [{'id': 'a', 'title': 'A'}], 'relations': [{'before': 'a', 'after': 'b'}]});
      expect(bad, isNull);
      expect([for (final i in why) i.code], containsAll(['field_missing', 'field_unknown']),
          reason: '`before`/`after` are play.talk\'s words: a relation is `earlier`/`later`');
    });
  });

  group('a timeline that can be wrong', () {
    test('two orders the words allow: ambiguous', () {
      final s = TimelineSpec(cards: spec().cards, order: spec().order); // no relation: letter and bridge could swap
      expect(rules.validate(s).single.code, 'timeline_ambiguous');
      expect(rules.validate(s).single.message, contains('letter or bridge'));
    });

    test('an order that is not its cards', () {
      expect(rules.validate(spec(order: const ['gauge', 'letter', 'book'])).map((i) => i.code), contains('timeline_order_mismatch'));
      expect(rules.validate(spec(order: const ['gauge', 'letter', 'list', 'book'])).map((i) => i.code), contains('timeline_order_mismatch'));
    });

    test('years running back, a relation against the order or of a discard', () {
      expect(rules.validate(spec(anchorB: '1400')).map((i) => i.code), contains('timeline_anchor_order'));
      final s = TimelineSpec(cards: spec().cards, order: spec().order, relations: const [
        TimelineRelation(earlier: 'bridge', later: 'letter', line: 'x'),
        TimelineRelation(earlier: 'list', later: 'book', line: 'y'),
      ]);
      expect(rules.validate(s).map((i) => i.code), containsAll(['timeline_relation_contradicts', 'timeline_relation_unknown']));
    });

    test('too few cards, every card fixed, a fixed card set aside', () {
      final short = TimelineSpec(cards: spec().cards.take(2).toList(), order: const ['gauge', 'letter']);
      expect(rules.validate(short).map((i) => i.code), contains('timeline_too_short'));
      final fixed = TimelineSpec(cards: [
        for (final (i, c) in spec().cards.indexed)
          if (!c.discard) TimelineCard(id: c.id, title: c.title, text: c.text, anchor: '${1440 + i}'),
      ], order: spec().order);
      expect(rules.validate(fixed).map((i) => i.code), contains('timeline_nothing_to_do'));
      final aside = TimelineSpec(cards: [...spec().cards.take(4), const TimelineCard(id: 'list', title: 'L', text: 'l', anchor: '1450', discard: true)], order: spec().order, relations: spec().relations);
      expect(rules.validate(aside).map((i) => i.code), contains('timeline_anchor_discard'));
    });
  });

  group('ids', () {
    test('given twice, not an id, a plan\'s id, or one reserved', () {
      final issues = PuzzleSpecCheck.ids([
        ('a', 'gauge'), ('b', 'gauge'), ('c', 'The Gauge'), ('d', 's5_ep01_m2'), ('e', 's5_ep01_h1'), ('f', 'clock'),
      ], reserved: {'clock'});
      expect([for (final i in issues) '${i.path} ${i.code}'], [
        'b id_duplicate', 'c id_invalid', 'd id_reserved', 'e id_reserved', 'f id_reserved',
      ]);
    });

    test('a timeline whose cards share an id', () {
      final s = TimelineSpec(cards: [...spec().cards, const TimelineCard(id: 'letter', title: 'X', text: 'x', discard: true)], order: spec().order, relations: spec().relations);
      expect(rules.validate(s).map((i) => i.code), contains('id_duplicate'));
    });
  });

  group('moves', () {
    final s = spec();
    TimelineState play(List<TimelineAction> moves) {
      var state = rules.initial(s);
      for (final m in moves) {
        final r = rules.apply(s, state, m);
        expect(r.accepted, isTrue, reason: '${r.rejection}');
        state = r.state;
      }
      return state;
    }

    test('it opens with the anchors fixed in their slots', () {
      expect(rules.initial(s).slots, ['gauge', null, null, 'book']);
      expect(rules.isComplete(s, rules.initial(s)), isFalse);
    });

    test('place, swap, set aside, return, clear', () {
      var state = play(const [PlaceCard('bridge', 1), PlaceCard('letter', 2)]);
      expect(state.slots, ['gauge', 'bridge', 'letter', 'book']);
      state = rules.apply(s, state, const PlaceCard('letter', 1)).state; // swap
      expect(state.slots, ['gauge', 'letter', 'bridge', 'book']);
      state = rules.apply(s, state, const DiscardCard('bridge')).state;
      expect([state.slots, state.discarded], [['gauge', 'letter', null, 'book'], {'bridge'}]);
      state = rules.apply(s, state, const PlaceCard('bridge', 2)).state; // off the pile, into the slot
      expect([state.slots[2], state.discarded], ['bridge', <String>{}]);
      state = rules.apply(s, state, const PlaceCard('list', 2)).state; // over a card from the table: it goes back
      expect([state.slots[2], state.holds('bridge')], ['list', false]);
      state = rules.apply(s, state, const ReturnCard('list')).state;
      expect(state.slots[2], isNull);
      expect(rules.apply(s, play(const [PlaceCard('letter', 1), DiscardCard('list')]), const ClearTimeline()).state, rules.initial(s));
    });

    test('moves the puzzle does not allow: rejected, the state as it was', () {
      final state = play(const [PlaceCard('letter', 1)]);
      for (final (move, code) in const [
        (PlaceCard('ghost', 1), 'card_unknown'),
        (PlaceCard('bridge', 9), 'slot_unknown'),
        (PlaceCard('bridge', -1), 'slot_unknown'),
        (PlaceCard('gauge', 2), 'card_fixed'),
        (PlaceCard('bridge', 3), 'slot_fixed'),
        (PlaceCard('letter', 1), 'no_change'),
        (DiscardCard('book'), 'card_fixed'),
        (ReturnCard('bridge'), 'no_change'),
        (ReturnCard('gauge'), 'card_fixed'),
      ]) {
        final r = rules.apply(s, state, move);
        expect([r.accepted, r.rejection?.code, r.state], [false, code, state], reason: '$move');
      }
    });

    test('complete, its answer, and the first card out of place', () {
      final wrong = play(const [PlaceCard('bridge', 1), PlaceCard('letter', 2)]);
      expect(rules.isComplete(s, wrong), isTrue);
      expect(rules.answerOf(s, wrong), 'gauge,bridge,letter,book');
      final p = rules.firstProblem(s, wrong)!;
      expect([p.slot, p.card, p.line], [1, 'bridge', 'After the letter, a stone was set by the bridge.']);
      final right = play(const [PlaceCard('letter', 1), PlaceCard('bridge', 2), DiscardCard('list')]);
      expect([rules.answerOf(s, right), rules.firstProblem(s, right)], [rules.answer(s), null]);
      expect(rules.solved(s), right);
    });

    test('deterministic: the same moves, the same state and save', () {
      const moves = [PlaceCard('bridge', 1), DiscardCard('list'), PlaceCard('letter', 1)];
      expect(PuzzleStateCodec.encode(rules, play(moves)), PuzzleStateCodec.encode(rules, play(moves)));
    });
  });

  group('saved and opened again', () {
    final s = spec();

    test('as a save left it (the app closed, back, opened again)', () {
      var session = PuzzleSession.open(rules, s);
      expect(session.restored, isFalse);
      (session, _) = session.play(const PlaceCard('letter', 1));
      (session, _) = session.play(const DiscardCard('list'));
      expect(session.saved, startsWith('pv2:timeline:1:'));
      final again = PuzzleSession.open(rules, s, saved: session.saved);
      expect([again.restored, again.state], [true, session.state]);
    });

    test('anything else starts afresh: another engine\'s, another version, broken, tampered', () {
      for (final saved in [
        null,
        'step=2',
        '{"d":[1],"b":"x"}',
        'pv2:board:1:{}',
        'pv2:timeline:2:{"s":["gauge",null,null,"book"],"d":[]}',
        'pv2:timeline:1:not json',
        'pv2:timeline:1:{"s":["gauge",null,null],"d":[]}',
        'pv2:timeline:1:{"s":["letter",null,null,"book"],"d":[]}',
        'pv2:timeline:1:{"s":["gauge","ghost",null,"book"],"d":[]}',
        'pv2:timeline:1:{"s":["gauge","letter",null,"book"],"d":["letter"]}',
        'pv2:timeline:1:{"s":["gauge",null,null,"book"],"d":["book"]}',
      ]) {
        final session = PuzzleSession.open(rules, s, saved: saved);
        expect([session.restored, session.state], [false, rules.initial(s)], reason: saved);
      }
    });

    test('a solved mission opened again: laid out as solved, never played', () {
      final session = PuzzleSession.open(rules, s, saved: 'pv2:timeline:1:{"s":["gauge",null,null,"book"],"d":[]}', solved: true);
      expect([session.readOnly, session.state, session.answer], [true, rules.solved(s), rules.answer(s)]);
      final (after, why) = session.play(const ReturnCard('letter'));
      expect([identical(after, session), why?.code], [true, 'solved']);
    });
  });

  group('levels', () {
    Map<Difficulty, TimelineSpec> levels({TimelineSpec? junior, TimelineSpec? master}) => {
      Difficulty.rookie: spec(),
      Difficulty.junior: junior ?? spec(junior: ' He asks for help.'),
      Difficulty.master: master ?? spec(junior: ' He petitions the court.'),
    };

    test('the same game in other words: no issue', () {
      expect(PuzzleSpecCheck.levels(rules, levels()), isEmpty);
    });

    test('a level missing, another answer, another game, a word left out', () {
      expect(PuzzleSpecCheck.levels(rules, {Difficulty.rookie: spec()}).map((i) => i.code), ['level_missing', 'level_missing']);
      final swapped = TimelineSpec(cards: spec().cards, order: const ['gauge', 'bridge', 'letter', 'book'],
          relations: const [TimelineRelation(earlier: 'bridge', later: 'letter', line: 'x')]);
      expect(PuzzleSpecCheck.levels(rules, levels(master: swapped)).map((i) => i.code), containsAll(['level_changes_game', 'level_changes_answer']));
      expect(PuzzleSpecCheck.levels(rules, levels(junior: spec(anchorB: '1447'))).map((i) => i.code), contains('level_changes_game'),
          reason: 'an anchor is a time, the same at every level');
      final blank = TimelineSpec(cards: [const TimelineCard(id: 'gauge', title: '', text: 'x', anchor: '1441'), ...spec().cards.skip(1)], order: spec().order, relations: spec().relations);
      expect(PuzzleSpecCheck.levels(rules, levels(junior: blank)).map((i) => '${i.code} ${i.path}'), contains('text_missing junior.cards[0].title'));
    });

    test('the season\'s mission and fact ids are no card\'s', () {
      final clash = TimelineSpec(cards: [...spec().cards.take(4), const TimelineCard(id: 'bell', title: 'B', text: 'b', discard: true)], order: spec().order, relations: spec().relations);
      expect(PuzzleSpecCheck.levels(rules, {for (final d in Difficulty.values) d: clash}, reserved: {'bell'}).map((i) => i.code), contains('id_reserved'));
    });
  });

  group('the game as it is', () {
    final s = spec();
    final base = episode01.missions.first;
    final mission = Mission.fromJson({...base.toJson(), 'type': 'sequence', 'answer': rules.answer(s)});

    test('the mission is checked against what the puzzle answers', () {
      expect(PuzzleSpecCheck.mission(rules, s, missionId: mission.id, missionAnswer: mission.answer), isEmpty);
      expect(PuzzleSpecCheck.mission(rules, s, missionId: mission.id, missionAnswer: 'gauge,letter').single.code, 'answer_mismatch');
    });

    test('AnswerChecker takes a timeline\'s answer as a sequence\'s', () {
      expect(AnswerChecker.isCorrect(mission, rules.answerOf(s, rules.solved(s))), isTrue);
      expect(AnswerChecker.isCorrect(mission, 'gauge,bridge,letter,book'), isFalse);
    });

    test('the save is kept by the game, the reward paid once, the puzzle shown solved after', () async {
      final container = ProviderContainer(overrides: await testOverrides());
      addTearDown(container.dispose);
      final game = container.read(gameControllerProvider.notifier);
      var session = PuzzleSession.open(rules, s);
      (session, _) = session.play(const PlaceCard('letter', 1));
      game.recordPuzzleState(base.id, session.saved);
      expect(PuzzleSession.open(rules, s, saved: container.read(gameControllerProvider).puzzleStateOf(base.id)).state, session.state);

      final first = game.submitAnswer(base, base.answer);
      final again = game.submitAnswer(base, base.answer);
      expect([first.result, first.firstSolve, first.coins > 0], [SubmitResult.correct, true, true]);
      expect([again.result, again.coins], [SubmitResult.correct, 0], reason: 'a mission is paid once, whatever its engine');
      final progress = container.read(gameControllerProvider);
      expect(progress.isCompleted(base.id), isTrue);
      expect(PuzzleSession.open(rules, s, saved: progress.puzzleStateOf(base.id), solved: progress.isCompleted(base.id)).readOnly, isTrue);
    });
  });

  test('no plan of any season uses the timeline\'s own keys in its play (levels read play\'s words by key)', () {
    const keys = {'timeline', 'cards', 'order', 'relations', 'earlier', 'later', 'anchor', 'discard'};
    final found = <String>[];
    void walk(Object? v, String at) {
      if (v is Map) {
        for (final e in v.entries) {
          if (keys.contains(e.key)) found.add('$at.${e.key}');
          walk(e.value, '$at.${e.key}');
        }
      } else if (v is List) {
        for (final x in v) {
          walk(x, at);
        }
      }
    }

    final plans = [
      for (final f in Directory('content_pipeline/seasons').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('case.plan.json')) f,
    ];
    expect(plans, isNotEmpty);
    for (final f in plans) {
      final p = jsonDecode(f.readAsStringSync()) as Map;
      for (final m in [...p['missions'] as List, p['final']]) {
        walk((m as Map)['play'], f.path);
      }
    }
    expect(found, isEmpty);
  });
}
