import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:world_mystery/core/constants/ad_config.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/utils/ad_service.dart';
import 'package:world_mystery/data/models/wallet.dart';
import 'package:world_mystery/features/game/admob_rewarded_ad_gateway.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/rewarded_ad_service.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'mission_play.dart';

/// The ads SDK, recording what is asked of it; each rewarded load answers
/// with the next of [rewarded] (an ad, or an error; a new ad when empty).
class FakeAdSdk implements AdSdk {
  final List<String> calls = [];
  final List<Object> rewarded = [];
  final List<FakeRewardedAd> loaded = [];

  @override
  Future<void> updateRequestConfiguration(RequestConfiguration configuration) async => calls.add('configure');

  @override
  Future<RequestConfiguration> getRequestConfiguration() async => ChildSafeAds.configuration;

  @override
  Future<void> initialize() async => calls.add('initialize');

  @override
  Future<BannerAd> loadBanner({required String adUnitId, required AdSize size, required AdRequest request}) =>
      throw UnimplementedError('no banners here');

  @override
  Future<RewardedAd> loadRewarded({required String adUnitId, required AdRequest request}) async {
    calls.add('rewarded');
    expect(request.nonPersonalizedAds, isTrue);
    final r = rewarded.isEmpty ? FakeRewardedAd() : rewarded.removeAt(0);
    if (r is FakeRewardedAd) {
      loaded.add(r);
      return r;
    }
    throw r;
  }

  int get rewardedLoads => calls.where((c) => c == 'rewarded').length;
}

/// A rewarded ad the test plays: [earn] is the SDK's reward callback, [close]
/// the player closing it, [failToShow] the SDK failing to show it.
class FakeRewardedAd extends Fake implements RewardedAd {
  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  int disposed = 0;
  int shows = 0;
  OnUserEarnedRewardCallback? _earned;

  /// [show] throws (the plugin failing before the ad is up).
  bool throwOnShow = false;

  @override
  Future<void> show({required OnUserEarnedRewardCallback onUserEarnedReward}) async {
    shows++;
    if (throwOnShow) throw StateError('platform');
    _earned = onUserEarnedReward;
  }

  /// The SDK says the reward was earned (it names 10 coins; the game pays its own 30).
  void earn() => _earned!(this, RewardItem(10, 'coins'));

  void close() => fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);

  void failToShow() => fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(this, _ShowError());

  @override
  Future<void> dispose() async => disposed++;
}

class _ShowError extends Fake implements AdError {
  @override
  int get code => 1;
}

const _units = AdUnitIds(banner: 'banner-unit', rewarded: 'rewarded-unit');

AdService fakeAds(FakeAdSdk sdk, {bool allowed = true}) => AdService(sdk: sdk, units: _units, requestsAllowed: allowed);

/// GET COINS' ads on [sdk], paying into the app's own wallet.
Override rewardedAdsOn(FakeAdSdk sdk, {bool allowed = true}) => rewardedAdGatewayProvider.overrideWith((ref) {
  final service = fakeAds(sdk, allowed: allowed);
  final gateway = AdMobRewardedAdGateway(
    service,
    onEarned: (id) => ref.read(walletProvider.notifier).rewardCompletedAd(id),
  );
  ref.onDispose(() {
    gateway.dispose();
    service.dispose();
  });
  return gateway;
});

void main() {
  late FakeAdSdk sdk;
  setUp(() => sdk = FakeAdSdk());

  group('the gateway', () {
    late List<String> paid;
    late AdService service;
    late AdMobRewardedAdGateway gateway;

    setUp(() {
      paid = [];
      service = fakeAds(sdk);
      gateway = AdMobRewardedAdGateway(service, onEarned: paid.add);
    });
    tearDown(() {
      gateway.dispose();
      service.dispose();
    });

    /// Loads an ad and shows it; [play] runs while it is on screen.
    Future<String?> watch(void Function(FakeRewardedAd ad) play) async {
      await gateway.preload();
      await pumpEventQueue(); // or the one loading since the last ad closed
      expect(gateway.offer, RewardedOffer.ready);
      final ad = sdk.loaded.last;
      final shown = gateway.showAndEarnReward();
      await Future<void>.delayed(Duration.zero);
      expect(gateway.offer, RewardedOffer.showing);
      play(ad);
      return shown;
    }

    test('nothing is asked for before a preload', () {
      expect(sdk.calls, isEmpty);
      expect(gateway.offer, RewardedOffer.loading);
    });

    test('a reward earned once: paid once, then the ad is disposed and the next one loaded', () async {
      final id = await watch((ad) {
        ad.earn();
        expect(paid, hasLength(1), reason: 'paid as soon as it is earned, before the ad closes');
        ad.close();
      });
      expect(id, isNotNull);
      expect(paid, [id]);
      expect(sdk.loaded.first.disposed, 1);
      await Future<void>.delayed(Duration.zero);
      expect(sdk.rewardedLoads, 2, reason: 'the next ad, loaded ahead');
      expect(gateway.offer, RewardedOffer.ready);
    });

    test('the reward said twice: paid once', () async {
      await watch((ad) {
        ad
          ..earn()
          ..earn()
          ..close();
      });
      expect(paid, hasLength(1));
    });

    test('closed without its reward (cancelled): nothing paid', () async {
      final id = await watch((ad) => ad.close());
      expect(id, isNull);
      expect(paid, isEmpty);
      expect(sdk.loaded.first.disposed, 1);
    });

    test('failed to show: nothing paid, the ad disposed', () async {
      final id = await watch((ad) => ad.failToShow());
      expect(id, isNull);
      expect(paid, isEmpty);
      expect(sdk.loaded.first.disposed, 1);
      expect(gateway.offer, isNot(RewardedOffer.showing));
    });

    test('the plugin throwing on show: nothing paid, nothing thrown', () async {
      await gateway.preload();
      sdk.loaded.single.throwOnShow = true;
      expect(await gateway.showAndEarnReward(), isNull);
      expect(paid, isEmpty);
      expect(sdk.loaded.single.disposed, 1);
    });

    test('a failed load: no ad to show, nothing paid, its wait kept', () async {
      sdk.rewarded.add(const AdLoadFailure(3, 'No fill'));
      await gateway.preload();
      expect(gateway.offer, RewardedOffer.unavailable);
      expect(await gateway.showAndEarnReward(), isNull);
      expect(paid, isEmpty);
      await gateway.preload();
      expect(sdk.rewardedLoads, 1, reason: 'not asked again before the backoff is over');
    });

    test('a second show while one is on screen does nothing', () async {
      await gateway.preload();
      final first = gateway.showAndEarnReward();
      await Future<void>.delayed(Duration.zero);
      expect(await gateway.showAndEarnReward(), isNull);
      expect(sdk.loaded.single.shows, 1);
      sdk.loaded.single
        ..earn()
        ..close();
      expect(await first, isNotNull);
      expect(paid, hasLength(1));
    });

    test('the gateway gone while the ad is up: a reward earned is still paid, once', () async {
      await gateway.preload();
      final shown = gateway.showAndEarnReward();
      await Future<void>.delayed(Duration.zero);
      gateway.dispose();
      sdk.loaded.single
        ..earn()
        ..earn()
        ..close();
      expect(await shown, isNotNull);
      expect(paid, hasLength(1));
      expect(sdk.loaded.single.disposed, 1);
    });

    test('each ad has its own reward id', () async {
      final a = await watch((ad) => ad..earn()..close());
      final b = await watch((ad) => ad..earn()..close());
      expect(a, isNot(b));
      expect(paid, [a, b]);
    });

    test('disposing the gateway releases the ad kept loaded', () async {
      await gateway.preload();
      gateway.dispose();
      expect(sdk.loaded.single.disposed, 1);
    });

    test('a release not cleared for ads: no offer, the SDK asked nothing', () async {
      final off = AdMobRewardedAdGateway(fakeAds(sdk, allowed: false), onEarned: paid.add);
      addTearDown(off.dispose);
      expect(off.offer, isNull);
      await off.preload();
      expect(await off.showAndEarnReward(), isNull);
      expect(sdk.calls, isEmpty);
      expect(AdConfig.releaseCleared, isEmpty);
      for (final p in AdPlatform.values) {
        expect(AdConfig.requestsAllowed(platform: p, release: true), isFalse);
      }
    });
  });

  group('GET COINS in the coins dialog', () {
    /// m02's puzzle, its free hint taken, with fewer coins than hint 2 costs.
    Future<(MissionPlay, int)> shortOfCoins(WidgetTester t, {bool allowed = true}) async {
      final play = MissionPlay(overrides: [rewardedAdsOn(sdk, allowed: allowed)]);
      await play.openPuzzle(t, const Size(360, 640), 'm02');
      for (final other in play.season.skip(1).expand((e) => e.allMissions)) {
        if (play.ref.read(walletProvider).balance < WalletController.priceOf(2)) break;
        play.ref.read(walletProvider.notifier).unlockTip(other, 2);
      }
      await wait(t, const Duration(milliseconds: 300));
      await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
      await tapText(t, 'Get More Hints', after: const Duration(milliseconds: 600));
      return (play, play.ref.read(walletProvider).balance);
    }

    final getCoins = find.text('GET COINS');
    final note = find.byKey(const ValueKey('get-coins-note'));

    bool enabled(WidgetTester t) {
      final button = find.ancestor(of: getCoins, matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true)).first;
      return t.widget<Semantics>(button).properties.enabled ?? false;
    }

    Future<void> tapGetCoins(WidgetTester t) async {
      await t.tap(getCoins);
      await t.pump();
      await t.pump();
    }

    testWidgets('a reward earned: 30 coins on top of the balance, saved and shown at once', (t) async {
      final (play, before) = await shortOfCoins(t);
      final entriesBefore = play.ref.read(walletProvider).entries.toList();
      expect(sdk.rewardedLoads, 1, reason: 'loaded while the question is read');
      expect(find.text('Watch an ad to earn 30 Coins'), findsOneWidget);
      expect(enabled(t), isTrue);
      await tapGetCoins(t);
      final ad = sdk.loaded.single;
      expect(ad.shows, 1);
      ad.earn();
      await t.pump();
      expect(play.ref.read(walletProvider).balance, before + AppConstants.rewardedAdCoins);
      ad.close();
      await wait(t, const Duration(milliseconds: 300));
      expect(AppConstants.rewardedAdCoins, 30);
      expect(find.text('You earned 30 coins!'), findsOneWidget);
      expect(play.ref.read(walletProvider).balance, before + 30);
      // Saved, every earlier entry kept as it was.
      final saved = play.ref.read(progressRepositoryProvider).loadWallet()!;
      expect(saved.balance, before + 30);
      expect(saved.entries.take(entriesBefore.length).map((e) => e.key), entriesBefore.map((e) => e.key));
      expect(saved.entries.last.source, CoinSource.rewardedAd);
      expect(saved.entries.last.amount, 30);
      // Enough now: the hint can be bought; nothing else of the game moved.
      expect(find.text('GET MORE HINTS'), findsOneWidget);
      expect(play.ref.read(gameControllerProvider).hintsFor('m02'), 1);
      expect(play.ref.read(walletProvider).ownsTip('m02', 2), isFalse);
      expect(sdk.rewardedLoads, 2, reason: 'the next ad loaded after this one closed');
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('closed before its reward: no coins', (t) async {
      final (play, before) = await shortOfCoins(t);
      await tapGetCoins(t);
      sdk.loaded.single.close();
      await wait(t, const Duration(milliseconds: 300));
      expect(find.text('No coins this time.'), findsOneWidget);
      expect(play.ref.read(walletProvider).balance, before);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('a quick double tap shows one ad; GET COINS waits while it is up', (t) async {
      final (play, before) = await shortOfCoins(t);
      await t.tap(getCoins);
      await t.tap(getCoins, warnIfMissed: false);
      await t.pump();
      await t.pump();
      expect(sdk.loaded.single.shows, 1);
      expect(enabled(t), isFalse);
      await t.tap(getCoins, warnIfMissed: false);
      await t.pump();
      expect(sdk.loaded.single.shows, 1);
      sdk.loaded.single
        ..earn()
        ..earn()
        ..close();
      await wait(t, const Duration(milliseconds: 300));
      expect(play.ref.read(walletProvider).balance, before + 30);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('the ad did not load: GET COINS is off and says so, the dialog works as before', (t) async {
      sdk.rewarded.add(const AdLoadFailure(3, 'No fill'));
      final (play, before) = await shortOfCoins(t);
      await t.pump();
      expect(find.text('No ad right now. Try again later.'), findsOneWidget);
      expect(enabled(t), isFalse);
      await tapText(t, 'CANCEL', after: const Duration(milliseconds: 400));
      expect(play.ref.read(walletProvider).balance, before);
      expect(play.ref.read(gameControllerProvider).hintsFor('m02'), 1);
      await wait(t, const Duration(seconds: 2));
    });

    testWidgets('a release not cleared for ads: no GET COINS, no word of ads, nothing asked', (t) async {
      final (play, before) = await shortOfCoins(t, allowed: false);
      expect(getCoins, findsNothing);
      expect(note, findsNothing);
      expect(find.textContaining(RegExp(r'\b[Aa]ds?\b')), findsNothing);
      expect(sdk.calls, isEmpty);
      expect(play.ref.read(walletProvider).balance, before);
      await wait(t, const Duration(seconds: 2));
    });
  });
}
