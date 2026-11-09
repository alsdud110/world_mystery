import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission/widgets/dialogue_investigation.dart' show WordsLink;

import 'helpers.dart';

/// "Words" beside Reread Letter, on the final's page and in a talk (2026-11-09):
/// the harder words of what was read, listed, each its meaning on a tap —
/// never shown before the tap, and no link when there is no hard word.
void main() {
  Future<ProviderContainer> pump(WidgetTester t, String text) async {
    final c = ProviderContainer(overrides: await testOverrides());
    addTearDown(c.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: Center(child: WordsLink(text: text)))),
    ));
    await t.pump();
    return c;
  }

  testWidgets('a text with words of the case: the link, its sheet, a meaning only on a tap', (t) async {
    final probe = ProviderContainer(overrides: await testOverrides());
    final glossary = probe.read(currentEpisodeProvider).glossary;
    probe.dispose();
    expect(glossary, isNotEmpty, reason: 'the open case has words to look up');
    final MapEntry(key: word, value: meaning) = glossary.entries.first;
    await pump(t, 'Look at the $word again.');
    expect(find.text('Words'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Words')), findsWidgets, reason: 'read out to a screen reader');
    await t.tap(find.text('Words'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('words-sheet')), findsOneWidget);
    expect(find.byKey(ValueKey('word-${word.toLowerCase()}')), findsOneWidget);
    expect(find.textContaining(meaning), findsNothing, reason: 'the meaning waits for a tap');
    await t.tap(find.byKey(ValueKey('word-${word.toLowerCase()}')));
    await t.pumpAndSettle();
    expect(find.textContaining(meaning), findsWidgets);
  });

  testWidgets('no hard word: no link at all', (t) async {
    await pump(t, 'Go.');
    expect(find.text('Words'), findsNothing);
  });
}
