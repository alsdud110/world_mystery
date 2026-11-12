import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/wallet.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/features/mission/widgets/question_widgets.dart';
import 'package:world_mystery/features/mission/widgets/shown_answer.dart';
import 'package:world_mystery/widgets/detective_tips.dart';
import 'package:world_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'reading_finders.dart';

/// See the Answer: offered once every hint is read, paid for once with coins
/// (the price of hint 2), shown as a picture of the puzzle with the answer
/// entered.
void main() {
  final london = MockEpisodeRepository.bundled().first;
  final m = {for (final x in london.allMissions) x.id: x};

  group('the coins', () {
    late ProviderContainer c;
    WalletController wallet() => c.read(walletProvider.notifier);
    Wallet coins() => c.read(walletProvider);

    setUp(() async => c = ProviderContainer(overrides: await testOverrides()));
    tearDown(() => c.dispose());

    test('the answer costs what hint 2 costs', () {
      expect(AppConstants.answerPrice, 20);
      expect(AppConstants.answerPrice, AppConstants.tipPrices[1]);
    });

    test('paid once, then kept: seen again for free', () {
      expect(coins().ownsAnswer('m02'), isFalse);
      expect(wallet().unlockAnswer(m['m02']!), isTrue);
      expect(coins().balance, 0);
      expect(coins().ownsAnswer('m02'), isTrue);
      expect(wallet().unlockAnswer(m['m02']!), isTrue, reason: 'already paid for');
      expect(coins().balance, 0, reason: 'never charged twice');
      expect(coins().entries.where((e) => e.key == Wallet.answerKey('m02')).single.source, CoinSource.answer);
    });

    test('short of coins: not shown, nothing charged', () {
      wallet().unlockAnswer(m['m02']!); // 20 → 0
      expect(wallet().unlockAnswer(m['m03']!), isFalse);
      expect(coins().balance, 0);
      expect(coins().ownsAnswer('m03'), isFalse);
    });

    test('a saved wallet keeps the answers paid for', () {
      wallet().unlockAnswer(m['m02']!);
      final back = Wallet.fromJson(coins().toJson());
      expect(back.ownsAnswer('m02'), isTrue);
      expect(back.balance, 0);
    });
  });

  test('the link: hints first, then the answer where the puzzle can show it', () {
    const hints = ['one', 'two'];
    expect(nextTipLabel(hints, 0, answer: true), 'Get a Free Hint');
    expect(nextTipLabel(hints, 1, answer: true), 'Get More Hints');
    expect(nextTipLabel(hints, 2, answer: true), answerLinkLabel);
    expect(nextTipLabel(hints, 2), isNull, reason: 'a puzzle with no answer picture offers nothing more');
  });

  // Every puzzle played on its page, in every season: with the answer
  // entered as its picture shows it, what the puzzle would send is right.
  group('the answer entered is the right answer', () {
    final plain = <Mission>[
      for (final s in SeasonCatalog.all)
        for (final json in s.episodes.values)
          for (final x in Episode.fromJson({...json, 'seasonId': s.id}).allMissions)
            if (const {
              MissionType.multipleChoice,
              MissionType.wordInput,
              MissionType.numberCode,
              MissionType.imageChoice,
              MissionType.sequence,
              MissionType.letterLock,
            }.contains(x.type))
              x,
    ];

    testWidgets('${plain.length} puzzles', (t) async {
      t.view.physicalSize = const Size(390, 2400) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      expect(plain.length, greaterThan(100));
      final overrides = await testOverrides();
      for (final x in plain) {
        String? sent;
        await t.pumpWidget(ProviderScope(
          key: ValueKey(x.id),
          overrides: overrides,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ShownAnswer(answer: x.answer, child: questionFor(x, (a) => sent = a)),
              ),
            ),
          ),
        ));
        await t.pump();
        final send = find.byType(GameButton).last;
        expect(t.widget<GameButton>(send).onPressed, isNotNull, reason: '${x.id}: the answer is entered whole');
        t.widget<GameButton>(send).onPressed!();
        await t.pump();
        expect(sent, isNotNull, reason: x.id);
        expect(AnswerChecker.isCorrect(x, sent!), isTrue, reason: '${x.id} (${x.type.name}): "$sent" for "${x.answer}"');
      }
    });
  });

  group('on a puzzle', () {
    Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);
    final picture = find.byKey(const ValueKey('answer-picture'));
    final seeButton = find.byWidgetPredicate((w) => w is CompactButton && w.label == answerButtonLabel);
    final cancel = find.byWidgetPredicate((w) => w is CompactButton && w.label == 'CANCEL');
    final link = find.text(answerLinkLabel);

    testWidgets('after hint 2: asked for coins, shown as a picture of the puzzle, free from then on', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm04');
      Wallet coins() => play.ref.read(walletProvider);
      expect(link, findsNothing, reason: 'the hints come first');
      // Short of the answer's price once hint 2 is paid for.
      final atStart = coins().balance;
      final left = atStart - AppConstants.tipPrices[1];
      expect(left, lessThan(AppConstants.answerPrice));

      // Hint 1 (free), hint 2 (20 coins): then the answer is offered.
      await reveal(t, hintAction());
      await t.tap(hintAction());
      await takeTipFromSheet(t);
      expect(link, findsNothing);
      await reveal(t, hintAction());
      await t.tap(hintAction());
      await takeTipFromSheet(t);
      expect(play.ref.read(gameControllerProvider).hintsFor('m04'), 2);
      expect(coins().balance, left);
      expect(hintAction(), findsNothing);
      expect(link, findsOneWidget);

      // Short of coins: asked, nothing shown, nothing charged.
      await reveal(t, link);
      await t.tap(link);
      await wait(t, const Duration(milliseconds: 500));
      expect(inDialog(findText('See the Answer?')), findsOneWidget);
      expect(inDialog(findTextContaining('Not enough coins')), findsOneWidget);
      expect(seeButton, findsNothing);
      await t.tap(cancel);
      await wait(t, const Duration(milliseconds: 500));
      expect(picture, findsNothing);
      expect(coins().ownsAnswer('m04'), isFalse);

      // With coins (an ad's reward): paid, and the picture is shown.
      play.ref.read(walletProvider.notifier).rewardCompletedAd('answer-test');
      await t.pump();
      await t.tap(link);
      await wait(t, const Duration(milliseconds: 500));
      expect(inDialog(findText('Spend coins to see the answer.')), findsOneWidget);
      await t.tap(seeButton);
      await wait(t, const Duration(milliseconds: 700));
      expect(coins().balance, left + AppConstants.rewardedAdCoins - AppConstants.answerPrice);
      expect(coins().ownsAnswer('m04'), isTrue);
      expect(picture, findsOneWidget);
      expect(find.descendant(of: picture, matching: find.byType(ImageChoiceQuestion)), findsOneWidget,
          reason: 'the puzzle itself, its answer chosen');
      expect(t.takeException(), isNull);
      // Nothing is entered for the detective: the puzzle is still to solve.
      expect(play.ref.read(gameControllerProvider).isCompleted('m04'), isFalse);

      await t.tap(find.text('BACK TO THE PUZZLE'));
      await wait(t, const Duration(milliseconds: 500));
      expect(picture, findsNothing);

      // Again: no coins asked.
      await t.tap(link);
      await wait(t, const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('tip-price')), findsNothing);
      expect(picture, findsOneWidget);
      expect(coins().balance, left + AppConstants.rewardedAdCoins - AppConstants.answerPrice);
    });

    for (final size in const [Size(320, 568), Size(390, 844)]) {
      testWidgets('the picture fits ${size.width.toInt()}x${size.height.toInt()}: a picture choice, whole', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm04');
        final game = play.ref.read(gameControllerProvider.notifier);
        game.useHint(m['m04']!);
        game.useHint(m['m04']!);
        play.ref.read(walletProvider.notifier).unlockAnswer(m['m04']!);
        await t.pump();
        await reveal(t, link);
        await t.tap(link);
        await wait(t, const Duration(milliseconds: 700));
        expect(picture, findsOneWidget);
        expect(t.takeException(), isNull, reason: 'nothing overflows');
        final shown = t.getRect(picture);
        expect(shown.top, greaterThanOrEqualTo(0));
        expect(shown.bottom, lessThanOrEqualTo(size.height));
        expect(shown.left, greaterThanOrEqualTo(0));
        expect(shown.right, lessThanOrEqualTo(size.width));
      });
    }
  });
}
