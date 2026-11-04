import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_theme.dart';
import 'package:world_mystery/features/mission/widgets/timeline_board.dart';
import 'package:world_mystery/puzzles_v2/core/puzzle_rules.dart';
import 'package:world_mystery/puzzles_v2/core/timeline_rules.dart';

/// Puzzle Engine 2.0 PART 3B: the timeline's page on its own — taps only,
/// every move the rules', saved as it goes; read by a screen reader, worked
/// by a keyboard, on a small phone with large text. Played in a mission of
/// the real app in `timeline_mission_test.dart`.
void main() {
  const rules = TimelineRules();
  const spec = TimelineSpec(
    cards: [
      TimelineCard(id: 'gauge', title: 'THE GAUGE', text: 'A bronze cup for the rain.', anchor: '1441'),
      TimelineCard(id: 'letter', title: 'THE LETTER', text: 'The clerk writes to the palace.'),
      TimelineCard(id: 'bridge', title: 'THE BRIDGE', text: 'A stone marks the water.'),
      TimelineCard(id: 'book', title: 'THE BOOK', text: 'The new letters are shared.', anchor: '1446'),
      TimelineCard(id: 'list', title: 'A SHOPPING LIST', text: 'Rice and tea.', discard: true),
    ],
    order: ['gauge', 'letter', 'bridge', 'book'],
    relations: [TimelineRelation(earlier: 'letter', later: 'bridge', line: 'After the letter, a stone was set by the bridge.')],
  );

  late List<String> saves;
  late List<String> answers;

  Future<void> pump(WidgetTester t, {TimelineSpec s = spec, String? saved, bool solved = false, Size size = const Size(390, 844), double textScale = 1}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    saves = [];
    answers = [];
    await t.pumpWidget(const SizedBox()); // a page opened anew: its board too
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [TimelineBoard(spec: s, saved: saved, solved: solved, onSaved: saves.add, onSubmit: answers.add)],
        ),
      ),
    ));
  }

  Finder card(String id) => find.byKey(ValueKey('timeline-card-$id'));
  Finder slot(int i) => find.byKey(ValueKey('timeline-slot-$i'));
  final pile = find.byKey(const ValueKey('timeline-pile'));

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await t.pump();
  }

  Future<void> put(WidgetTester t, String id, int i) async {
    await tap(t, card(id));
    await tap(t, slot(i));
  }

  String labelOf(WidgetTester t, Finder f) => t.getSemantics(f).label;
  TimelineState? lastSaved() => PuzzleStateCodec.decode(rules, spec, saves.last);

  testWidgets('it opens with the years fixed, every other card on the table', (t) async {
    await pump(t);
    expect(labelOf(t, slot(0)), contains('Place 1 of 4, fixed, 1441, THE GAUGE'));
    expect(labelOf(t, slot(1)), 'Place 2 of 4, empty');
    expect(labelOf(t, slot(3)), contains('fixed, 1446, THE BOOK'));
    for (final id in ['letter', 'bridge', 'list']) {
      expect(card(id), findsOneWidget, reason: id);
    }
    await t.tap(find.text('CHECK THE ORDER'), warnIfMissed: false);
    await t.pump();
    expect(answers, isEmpty, reason: 'nothing to check until every place is filled');
  });

  testWidgets('pick, place, swap, set aside, back to the table, undo — every move saved', (t) async {
    await pump(t);
    await put(t, 'bridge', 1);
    expect(labelOf(t, slot(1)), contains('THE BRIDGE'));
    expect(card('bridge'), findsNothing, reason: 'off the table');
    expect(lastSaved()!.slots, ['gauge', 'bridge', null, 'book']);

    await put(t, 'letter', 2);
    // A card in place, picked, then another place: they swap.
    await tap(t, slot(2));
    expect(t.getSemantics(slot(2)), isSemantics(isSelected: true), reason: 'picked, said by the screen reader');
    expect(find.text('PICKED'), findsOneWidget, reason: 'picked shown in words, not in colour only');
    await tap(t, slot(1));
    expect(lastSaved()!.slots, ['gauge', 'letter', 'bridge', 'book']);

    // The shopping list set aside, then brought back to the table.
    await tap(t, card('list'));
    await tap(t, pile);
    expect(lastSaved()!.discarded, {'list'});
    expect(labelOf(t, card('list')), contains('not part of it'));
    await tap(t, card('list'));
    await tap(t, find.text('Back to the table'));
    expect(lastSaved()!.discarded, isEmpty);
    expect(labelOf(t, card('list')), contains('on the table'));

    // Undo: the moves taken back one by one, each saved.
    await tap(t, find.text('Undo'));
    expect(lastSaved()!.discarded, {'list'});
    await tap(t, find.text('Undo'));
    expect(lastSaved()!.discarded, isEmpty);
    await tap(t, find.text('Undo'));
    expect(lastSaved()!.slots, ['gauge', 'bridge', 'letter', 'book'], reason: 'the swap undone');
  });

  testWidgets('a fixed card cannot be moved: said, nothing changes', (t) async {
    await pump(t);
    await tap(t, slot(0));
    expect(find.text('That card is fixed: its time is written on it.'), findsOneWidget);
    await tap(t, card('letter'));
    await tap(t, slot(3));
    expect(find.text('That card is fixed: its time is written on it.'), findsOneWidget);
    expect(saves, isEmpty, reason: 'a move not allowed is never saved');
    expect(labelOf(t, slot(3)), contains('THE BOOK'));
  });

  testWidgets('a wrong order: sent, and the first card out of place shown with the words about it', (t) async {
    await pump(t);
    await put(t, 'bridge', 1);
    await put(t, 'letter', 2);
    await tap(t, find.text('CHECK THE ORDER'));
    expect(answers, ['gauge,bridge,letter,book']);
    expect(find.text('CHECK THIS ONE'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-problem-line')), findsOneWidget);
    expect(labelOf(t, slot(1)), contains('out of place'));
    expect(find.textContaining('letter, bridge'), findsNothing, reason: 'the answer is never said');
    // The next move clears the mark (the letter, picked in its place, swapped up).
    await tap(t, slot(2));
    await tap(t, slot(1));
    expect(find.text('CHECK THIS ONE'), findsNothing);
    await tap(t, find.text('CHECK THE ORDER'));
    expect(answers.last, rules.answer(spec));
  });

  testWidgets('opened again as it was left; a broken save opens afresh', (t) async {
    await pump(t, saved: 'pv2:timeline:1:{"s":["gauge","letter",null,"book"],"d":["list"]}');
    expect(labelOf(t, slot(1)), contains('THE LETTER'));
    expect(labelOf(t, card('list')), contains('not part of it'));
    await pump(t, saved: 'pv2:timeline:1:{"s":["letter"');
    expect(labelOf(t, slot(1)), 'Place 2 of 4, empty');
    await pump(t, saved: 'step=2');
    expect(labelOf(t, slot(1)), 'Place 2 of 4, empty');
  });

  testWidgets('solved: laid out as it happened, nothing to play', (t) async {
    await pump(t, solved: true, saved: 'pv2:timeline:1:{"s":["gauge",null,null,"book"],"d":[]}');
    expect(find.text('WHAT HAPPENED'), findsOneWidget);
    expect([for (var i = 0; i < 4; i++) labelOf(t, slot(i)).split(', ').firstWhere((p) => p.startsWith('THE '))],
        ['THE GAUGE. A bronze cup for the rain.', 'THE LETTER. The clerk writes to the palace.', 'THE BRIDGE. A stone marks the water.', 'THE BOOK. The new letters are shared.']);
    expect(labelOf(t, card('list')), contains('not part of it'));
    expect(find.text('CHECK THE ORDER'), findsNothing);
    expect(find.text('Undo'), findsNothing);
    await tap(t, slot(1));
    expect(saves, isEmpty);
  });

  testWidgets('every tap target is 48 or more; a small phone with large text: nothing overflows', (t) async {
    await pump(t, size: const Size(320, 568), textScale: 1.6);
    expect(t.takeException(), isNull);
    for (final f in [slot(0), slot(1), slot(2), slot(3), card('letter'), card('bridge'), card('list'), pile]) {
      await t.ensureVisible(f);
      await t.pump();
      expect(t.getSize(f).height, greaterThanOrEqualTo(48), reason: '$f');
      expect(t.getRect(f).right, lessThanOrEqualTo(320));
    }
    await put(t, 'letter', 1);
    await put(t, 'bridge', 2);
    await tap(t, find.text('CHECK THE ORDER'));
    expect(t.takeException(), isNull);
    expect(answers.single, rules.answer(spec));
  });

  testWidgets('a keyboard: Tab moves between cards and places, Enter picks and puts', (t) async {
    await pump(t);
    Focus.of(t.element(find.descendant(of: card('letter'), matching: find.byType(GestureDetector)).first)).requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(t.getSemantics(card('letter')), isSemantics(isSelected: true));
    // Back up to place 2 (Shift+Tab from the first card on the table: place 4, 3, 2).
    for (var i = 0; i < 3; i++) {
      await t.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await t.pump();
    }
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pump();
    expect(lastSaved()!.slots, ['gauge', 'letter', null, 'book']);
  });

  testWidgets('a screen reader hears what to do, and taps through its own actions', (t) async {
    final handle = t.ensureSemantics();
    await pump(t);
    expect(t.getSemantics(card('letter')), isSemantics(label: 'THE LETTER. The clerk writes to the palace.. on the table', hint: 'Tap to pick this card.', isButton: true, hasTapAction: true));
    t.semantics.tap(find.semantics.byLabel(RegExp('^THE LETTER')));
    await t.pump();
    expect(t.getSemantics(slot(1)).hint, 'Tap to put THE LETTER here.');
    t.semantics.tap(find.semantics.byLabel('Place 2 of 4, empty'));
    await t.pump();
    expect(lastSaved()!.slots[1], 'letter');
    expect(t.getSemantics(find.text('THE TIMELINE')), isSemantics(isHeader: true));
    handle.dispose();
  });
}
