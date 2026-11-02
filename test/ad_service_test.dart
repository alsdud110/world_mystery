import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:world_mystery/core/constants/ad_config.dart';
import 'package:world_mystery/core/utils/ad_service.dart';

/// Records every call, in order; each step can fail or hang.
class _FakeSdk implements AdSdk {
  final List<String> calls = [];

  /// What the SDK reads back (null: what was set).
  RequestConfiguration? readBack;
  bool failConfigure = false;
  bool failInitialize = false;
  Completer<void>? hangInitialize;

  /// Loads answered in order: an ad, or an error.
  final List<Object> bannerResults = [];
  final List<Object> rewardedResults = [];
  Completer<BannerAd>? pendingBanner;

  RequestConfiguration? _set;

  @override
  Future<void> updateRequestConfiguration(RequestConfiguration configuration) async {
    calls.add('configure');
    if (failConfigure) throw Exception('channel');
    _set = configuration;
  }

  @override
  Future<RequestConfiguration> getRequestConfiguration() async {
    calls.add('read');
    return readBack ?? _set ?? RequestConfiguration();
  }

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (failInitialize) throw Exception('no network');
    if (hangInitialize != null) await hangInitialize!.future;
  }

  @override
  Future<BannerAd> loadBanner({required String adUnitId, required AdSize size, required AdRequest request}) async {
    calls.add('banner $adUnitId');
    expect(request.nonPersonalizedAds, isTrue);
    if (pendingBanner != null) return pendingBanner!.future;
    final r = bannerResults.removeAt(0);
    if (r is BannerAd) return r;
    throw r;
  }

  @override
  Future<RewardedAd> loadRewarded({required String adUnitId, required AdRequest request}) async {
    calls.add('rewarded $adUnitId');
    expect(request.nonPersonalizedAds, isTrue);
    final r = rewardedResults.removeAt(0);
    if (r is RewardedAd) return r;
    throw r;
  }

  List<String> get loads => [for (final c in calls) if (c.startsWith('banner') || c.startsWith('rewarded')) c];
}

class _FakeBanner extends Fake implements BannerAd {
  int disposed = 0;

  @override
  Future<void> dispose() async => disposed++;
}

class _FakeRewarded extends Fake implements RewardedAd {
  int disposed = 0;

  @override
  Future<void> dispose() async => disposed++;
}

void main() {
  const units = AdUnitIds(banner: 'banner-unit', rewarded: 'rewarded-unit');
  const failure = AdLoadFailure(3, 'No fill');

  late _FakeSdk sdk;
  setUp(() => sdk = _FakeSdk());

  AdService service({AdUnitIds? ids = units, bool allowed = true, Duration? timeout}) => AdService(
    sdk: sdk,
    units: ids,
    requestsAllowed: allowed,
    timeout: timeout ?? const Duration(seconds: 10),
  );

  group('start', () {
    test('protects the requests, reads them back, then starts the SDK', () async {
      final ads = service();
      expect(await ads.start(), isTrue);
      expect(sdk.calls, ['configure', 'read', 'initialize']);
      expect(ads.state, AdServiceState.ready);
      expect(ads.canRequestAds, isTrue);
      expect(ads.units, units);
    });

    test('the protection is the child treatment, G rating, non-personalized', () {
      expect(ChildSafeAds.configuration.ageRestrictedTreatment, AgeRestrictedTreatment.child);
      expect(ChildSafeAds.configuration.maxAdContentRating, MaxAdContentRating.g);
      expect(ChildSafeAds.request.nonPersonalizedAds, isTrue);
      expect(ChildSafeAds.isApplied(ChildSafeAds.configuration), isTrue);
    });

    test('protection that fails to set: the SDK is never started, nothing loads', () async {
      sdk.failConfigure = true;
      final ads = service();
      final slot = ads.banner(AdSize.banner);
      expect(await slot.load(), isFalse);
      expect(sdk.calls, ['configure']);
      expect(ads.offReason, AdOffReason.childSafetyNotApplied);
      expect(ads.canRequestAds, isFalse);
      expect(ads.units, isNull);
    });

    test('protection that does not read back: the SDK is never started', () async {
      for (final readBack in [
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg, ageRestrictedTreatment: AgeRestrictedTreatment.child),
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g, ageRestrictedTreatment: AgeRestrictedTreatment.teen),
      ]) {
        sdk = _FakeSdk()..readBack = readBack;
        final ads = service();
        expect(await ads.start(), isFalse);
        expect(sdk.calls, ['configure', 'read']);
        expect(ads.offReason, AdOffReason.childSafetyNotApplied);
      }
    });

    test('starts the SDK once, however often it is asked', () async {
      final ads = service();
      final all = await Future.wait([ads.start(), ads.start(), ads.start()]);
      await ads.start();
      expect(all, everyElement(isTrue));
      expect(sdk.calls.where((c) => c == 'initialize'), hasLength(1));
      expect(sdk.calls.where((c) => c == 'configure'), hasLength(1));
    });

    test('an SDK that fails to start turns ads off and throws nothing', () async {
      sdk.failInitialize = true;
      final ads = service();
      expect(await ads.start(), isFalse);
      expect(ads.offReason, AdOffReason.sdkNotStarted);
      expect(await ads.rewarded().load(), isFalse);
      expect(sdk.loads, isEmpty);
    });

    test('an SDK that never answers is given up on, not waited for', () async {
      sdk.hangInitialize = Completer<void>();
      final ads = service(timeout: const Duration(milliseconds: 20));
      expect(await ads.start(), isFalse);
      expect(ads.offReason, AdOffReason.sdkNotStarted);
      sdk.hangInitialize!.complete(); // late: still off
      await Future<void>.delayed(Duration.zero);
      expect(ads.canRequestAds, isFalse);
    });

    test('no ad units (another platform, a release without IDs): the SDK is not touched', () async {
      final ads = service(ids: null);
      expect(await ads.start(), isFalse);
      expect(await ads.banner(AdSize.banner).load(), isFalse);
      expect(sdk.calls, isEmpty);
      expect(ads.offReason, AdOffReason.noAdUnits);
    });

    test('a build not cleared for ads: the SDK is not touched', () async {
      final ads = service(allowed: false);
      expect(await ads.start(), isFalse);
      expect(sdk.calls, isEmpty);
      expect(ads.offReason, AdOffReason.notCleared);
    });
  });

  group('build policy', () {
    test('debug and profile may request ads (sample units), a release only when cleared', () {
      for (final platform in AdPlatform.values) {
        expect(AdConfig.requestsAllowed(platform: platform, release: false), isTrue);
        expect(AdConfig.requestsAllowed(platform: platform, release: true), isFalse);
        expect(AdConfig.requestsAllowed(platform: platform, release: true, cleared: {platform}), isTrue);
      }
    });

    test('no release is cleared yet', () {
      expect(AdConfig.releaseCleared, isEmpty);
    });

    test('tests are not a release: the sample units, ads allowed', () {
      final current = AdConfig.current;
      expect(current == null || !AdConfig.isRealAdUnitId(current.banner), isTrue);
      expect(AdConfig.requestsAllowedNow, AdConfig.platform != null);
    });
  });

  group('banner slot', () {
    test('loads once: a second load while loading or loaded asks nothing', () async {
      final banner = _FakeBanner();
      sdk.pendingBanner = Completer<BannerAd>();
      final slot = service().banner(AdSize.banner);
      final first = slot.load();
      await Future<void>.delayed(Duration.zero);
      expect(slot.isLoading, isTrue);
      expect(await slot.load(), isFalse);
      sdk.pendingBanner!.complete(banner);
      expect(await first, isTrue);
      expect(await slot.load(), isTrue);
      expect(sdk.loads, ['banner banner-unit']);
      expect(slot.ad, same(banner));
    });

    test('a failed load leaves no ad and throws nothing', () async {
      sdk.bannerResults.add(failure);
      final slot = service().banner(AdSize.banner);
      expect(await slot.load(), isFalse);
      expect(slot.ad, isNull);
      expect(slot.failures, 1);
      expect(slot.isLoading, isFalse);
    });

    test('release and dispose dispose the ad', () async {
      final a = _FakeBanner(), b = _FakeBanner();
      sdk.bannerResults.addAll([a, b]);
      final slot = service().banner(AdSize.banner);
      await slot.load();
      slot.release();
      expect(a.disposed, 1);
      expect(slot.ad, isNull);
      await slot.load();
      slot.dispose();
      expect(b.disposed, 1);
      expect(await slot.load(), isFalse);
      expect(sdk.loads, hasLength(2));
    });

    test('an ad arriving after its slot is gone is disposed, not kept', () async {
      final banner = _FakeBanner();
      sdk.pendingBanner = Completer<BannerAd>();
      final slot = service().banner(AdSize.banner);
      final loading = slot.load();
      await Future<void>.delayed(Duration.zero);
      slot.dispose();
      sdk.pendingBanner!.complete(banner);
      expect(await loading, isFalse);
      expect(banner.disposed, 1);
    });

    test('disposing the service disposes every slot\'s ad and stops ads', () async {
      final banner = _FakeBanner();
      final reward = _FakeRewarded();
      sdk.bannerResults.add(banner);
      sdk.rewardedResults.add(reward);
      final ads = service();
      final b = ads.banner(AdSize.banner);
      final r = ads.rewarded();
      await b.load();
      await r.load();
      ads.dispose();
      expect(banner.disposed, 1);
      expect(reward.disposed, 1);
      expect(b.isDisposed && r.isDisposed, isTrue);
      expect(ads.offReason, AdOffReason.disposed);
    });
  });

  group('rewarded slot', () {
    test('preloads, and hands the ad over once', () async {
      final reward = _FakeRewarded();
      sdk.rewardedResults.add(reward);
      final slot = service().rewarded();
      expect(await slot.load(), isTrue);
      expect(sdk.loads, ['rewarded rewarded-unit']);
      expect(slot.take(), same(reward));
      expect(slot.take(), isNull);
      slot.dispose();
      expect(reward.disposed, 0, reason: 'the taker disposes it');
    });

    test('failed loads wait longer and longer before asking again', () async {
      var now = DateTime(2026, 11, 2, 12);
      final backoff = AdBackoff(first: const Duration(seconds: 30), max: const Duration(minutes: 2), now: () => now);
      sdk.rewardedResults.addAll([failure, failure, failure, _FakeRewarded()]);
      final slot = service().rewarded(backoff: backoff);

      expect(await slot.load(), isFalse); // 1st failure: wait 30 s
      expect(await slot.load(), isFalse);
      now = now.add(const Duration(seconds: 29));
      expect(await slot.load(), isFalse);
      expect(sdk.loads, hasLength(1));

      now = now.add(const Duration(seconds: 1));
      expect(await slot.load(), isFalse); // 2nd failure: wait 60 s
      now = now.add(const Duration(seconds: 59));
      expect(await slot.load(), isFalse);
      expect(sdk.loads, hasLength(2));

      now = now.add(const Duration(seconds: 1));
      expect(await slot.load(), isFalse); // 3rd failure: 120 s (the max)
      expect(backoff.after(10), const Duration(minutes: 2));
      now = now.add(const Duration(minutes: 2));
      expect(await slot.load(), isTrue);
      expect(slot.failures, 0);
      expect(sdk.loads, hasLength(4));
    });
  });
}
