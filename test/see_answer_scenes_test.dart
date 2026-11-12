import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/answer_pictures.dart';
import 'package:world_mystery/features/mission/widgets/shown_answer.dart';
import 'package:world_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The answer's picture of a puzzle played in a scene of its own: the scene
/// with its answer set. What it would send, were its button pressed (or
/// what it sends by itself, its board complete), is the right answer.
void main() {
  final scenes = <Mission>[
    for (final e in [...MockEpisodeRepository.bundled(), ...MockEpisodeRepository.awaitingArt()])
      for (final m in e.allMissions)
        if (!playedOnThePage(m) && answerPictureOf(m) != null) m,
  ];

  // The game's own fonts: the test font is wider and would not fit.
  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  test('the scenes that show their answer', () {
    // London's and the made seasons' looked-round places and traces, and
    // Paris's scenes: more are added as their pictures are made.
    expect(scenes.length, greaterThanOrEqualTo(60));
  });

  for (final m in scenes) {
    testWidgets('${m.id}: the answer set is the right answer', (t) async {
      const size = Size(390, 844);
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      String? sent;
      final picture = answerPictureOf(m, onSent: (a) => sent ??= a)!;
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: ShownAnswer(
              answer: m.answer,
              child: picture.page
                  ? SizedBox(width: size.width, height: size.height - 56, child: picture.child)
                  : SingleChildScrollView(padding: const EdgeInsets.all(24), child: picture.child),
            ),
          ),
        ),
      ));
      // A board that is complete sends its answer by itself, a moment later.
      await wait(t, const Duration(milliseconds: 3200));
      // A poster chosen, two statements chosen: shown, nothing to send.
      if (!picture.sends) {
        expect(t.takeException(), isNull);
        return;
      }
      // Else its own button, the last one that can be pressed and is not a
      // way back (and, when a card says why the answer is right first, that
      // card's button).
      for (var round = 0; round < 3 && sent == null; round++) {
        final buttons = [
          for (final e in find.byType(GameButton).evaluate())
            if ((e.widget as GameButton).onPressed != null && !(e.widget as GameButton).label.startsWith('BACK'))
              e.widget as GameButton,
        ];
        if (buttons.isEmpty) break;
        buttons.last.onPressed!();
        await wait(t, const Duration(milliseconds: 900));
      }
      expect(sent, isNotNull, reason: '${m.id}: its answer can be sent');
      expect(AnswerChecker.isCorrect(m, sent!), isTrue, reason: '${m.id}: "$sent" for "${m.answer}"');
      await t.pumpWidget(const SizedBox());
      await wait(t, const Duration(milliseconds: 3200));
    });
  }
}
