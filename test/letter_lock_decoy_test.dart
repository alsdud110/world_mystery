import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/theme/app_theme.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/mission/widgets/letter_lock.dart';
import 'reading_finders.dart';

/// A letter lock with more tiles than letters (PART 1.5): a slot for each
/// letter of the answer, the extra tiles left on the desk. Every lock with
/// one tile a letter (London, Paris, Rome, New York, Seoul before) reads as
/// before.
void main() {
  final paris = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep01').finalMission;

  Mission lock(String answer, String tiles, {Map<String, String> feedback = const {}}) => Mission.fromJson({
    ...paris.toJson(),
    'id': 's9_test_final',
    'answer': answer,
    'options': [for (final (i, c) in tiles.split('').indexed) {'id': 't$i', 'label': c}],
    'feedback': feedback,
  });

  Future<List<String>> show(WidgetTester t, Mission m) async {
    final said = <String>[];
    t.view.physicalSize = const Size(320, 568) * t.view.devicePixelRatio;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: LetterLockQuestion(mission: m, onSubmit: said.add))),
    ));
    return said;
  }

  Future<void> tapLetter(WidgetTester t, String c) async {
    final tile = find.bySemanticsLabel('Letter $c').first;
    await t.ensureVisible(tile);
    await t.tap(tile);
    await t.pump();
  }

  test("every bundled lock's slots: one a tile unless it has extra tiles", () {
    for (final e in MockEpisodeRepository.bundled()) {
      for (final m in e.allMissions.where((m) => m.type == MissionType.letterLock)) {
        expect(LetterLockQuestion.slotCount(m), AnswerChecker.normalize(m.answer).length, reason: m.id);
      }
    }
    expect(LetterLockQuestion.slotCount(paris), paris.options.length, reason: 'Paris: one tile a letter, as before');
  });

  testWidgets('seven tiles, five slots: OPEN only when five are in, the two extra stay out', (t) async {
    final said = await show(t, lock('LIGHT', 'NHTIRGL'));
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('lock-slot-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('lock-slot-5')), findsNothing);
    for (final c in 'LIGH'.split('')) {
      await tapLetter(t, c);
    }
    await t.tap(find.text('OPEN THE LOCK'));
    expect(said, isEmpty, reason: 'four of five: not yet');
    await tapLetter(t, 'T');
    expect(findText('The lock is full. Tap a letter in it to take it out.'), findsOneWidget);
    await tapLetter(t, 'N');
    expect(find.bySemanticsLabel(RegExp('Letter N, in the lock')), findsNothing, reason: 'a full lock takes no more');
    await t.tap(find.text('OPEN THE LOCK'));
    expect(said, ['LIGHT']);
    expect(t.takeException(), isNull);
  });

  test('a decoy word is wrong, with its own line; the right word is right', () {
    final m = lock('LIGHT', 'NHTIRGL', feedback: {'NIGHT': 'Night is when it goes away.'});
    expect(AnswerChecker.isCorrect(m, 'LIGHT'), isTrue);
    expect(AnswerChecker.isCorrect(m, 'NIGHT'), isFalse);
    expect(AnswerChecker.feedbackFor(m, 'NIGHT'), 'Night is when it goes away.');
    expect(AnswerChecker.feedbackFor(m, 'GILHT'), m.orderFeedback, reason: 'its own letters in the wrong order');
  });

  test('the content check: extra tiles pass; a word the tiles cannot spell does not', () {
    expect(SeasonContentValidator.answerProblems(lock('LIGHT', 'NHTIRGL')).where((p) => p.contains('tiles')), isEmpty);
    expect(SeasonContentValidator.answerProblems(lock('LIGHT', 'NHTIRG')).where((p) => p.contains('tiles')), isNotEmpty);
  });
}
