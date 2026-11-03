import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/ad_config.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/ad_service.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/widgets/banner_ad_area.dart';

import 'fake_consent_sdk.dart';
import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The ads SDK, recording what is asked of it; each banner load answers
/// with the next of [banners] (an ad, or an error), or waits on [pending].
class _FakeSdk implements AdSdk {
  final List<String> calls = [];
  bool failInitialize = false;
  final List<Object> banners = [];
  Completer<BannerAd>? pending;
  final List<AdSize> sizes = [];

  @override
  Future<void> updateRequestConfiguration(RequestConfiguration configuration) async => calls.add('configure');

  @override
  Future<RequestConfiguration> getRequestConfiguration() async {
    calls.add('read');
    return ChildSafeAds.configuration;
  }

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    if (failInitialize) throw Exception('no network');
  }

  @override
  Future<BannerAd> loadBanner({required String adUnitId, required AdSize size, required AdRequest request}) async {
    calls.add('banner');
    sizes.add(size);
    expect(request.nonPersonalizedAds, isTrue);
    if (pending != null) return pending!.future;
    final r = banners.isEmpty ? _FakeBanner() : banners.removeAt(0);
    if (r is BannerAd) return r;
    throw r;
  }

  @override
  Future<RewardedAd> loadRewarded({required String adUnitId, required AdRequest request}) =>
      throw UnimplementedError('no rewarded ads in PART 3');

  int get bannerLoads => calls.where((c) => c == 'banner').length;
}

class _FakeBanner extends Fake implements BannerAd {
  int disposed = 0;

  @override
  Future<void> dispose() async => disposed++;
}

const _units = AdUnitIds(banner: 'banner-unit', rewarded: 'rewarded-unit');

void main() {
  late _FakeSdk sdk;
  setUp(() => sdk = _FakeSdk());

  /// The ads of a build that may request them (debug, sample units), on [sdk];
  /// [allowed] false: a release not cleared for ads.
  List<Override> adOverrides({bool allowed = true}) => [
    adServiceProvider.overrideWith((ref) {
      final service = AdService(sdk: sdk, units: _units, requestsAllowed: allowed, consent: allowingConsent());
      ref.onDispose(service.dispose);
      return service;
    }),
    // A plain box for the native ad view (AdWidget needs the plugin).
    bannerAdViewProvider.overrideWithValue((ad) => const SizedBox.expand(key: ValueKey('ad-view'))),
  ];

  final strip = find.byKey(const ValueKey('banner-ad'));
  final view = find.byKey(const ValueKey('ad-view'));
  const page = ValueKey('page');

  /// A page wrapped in a [BannerAdArea], over a 24 px system navigation bar.
  Widget area({Key? key}) => MediaQuery(
    data: const MediaQueryData(size: Size(360, 640), padding: EdgeInsets.only(bottom: 24)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: BannerAdArea(key: key, child: const SizedBox.expand(key: page)),
    ),
  );

  Future<void> pumpArea(WidgetTester t, {List<Override>? overrides, Widget? child}) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(overrides: overrides ?? adOverrides(), child: child ?? area()));
    await t.pump();
    await t.pump();
  }

  double pageBottomPadding(WidgetTester t) => MediaQuery.paddingOf(t.element(find.byKey(page))).bottom;

  group('the banner', () {
    testWidgets('is shown under the page once its ad has loaded, the page giving up its bottom inset', (t) async {
      final ad = _FakeBanner();
      sdk.banners.add(ad);
      await pumpArea(t);
      expect(sdk.calls, ['configure', 'read', 'initialize', 'banner'], reason: 'protected, started, then asked');
      expect(sdk.sizes.single, AdSize.banner, reason: 'the standard banner, not an adaptive one');
      expect(strip, findsOneWidget);
      expect(view, findsOneWidget);
      expect(t.getSize(view), const Size(320, 50), reason: 'drawn at its own size');
      expect(t.getSize(strip).height, 50 + 24, reason: '50 for the ad, the navigation bar apart');
      expect(t.getRect(view).center.dx, 180, reason: 'centred');
      expect(pageBottomPadding(t), 0, reason: 'the strip keeps the navigation bar clear itself');
      // The page above, never under it.
      expect(t.getRect(find.byKey(page)).bottom, lessThanOrEqualTo(t.getRect(strip).top));
      expect(t.getRect(strip).bottom, 640);
      expect(t.getRect(view).bottom, 640 - 24, reason: 'above the system navigation bar');
      expect(find.byType(Text), findsNothing, reason: 'no words of ours around the ad');
    });

    testWidgets('is not there while the ad loads, and nothing waits for it', (t) async {
      sdk.pending = Completer();
      await pumpArea(t);
      expect(sdk.bannerLoads, 1);
      expect(strip, findsNothing);
      expect(find.byKey(page), findsOneWidget);
      expect(pageBottomPadding(t), 24);
      await t.pump(const Duration(minutes: 1));
      expect(strip, findsNothing);
    });

    testWidgets('a failed load leaves no room for it', (t) async {
      sdk.banners.add(const AdLoadFailure(3, 'No fill'));
      await pumpArea(t);
      expect(sdk.bannerLoads, 1);
      expect(strip, findsNothing);
      expect(t.getRect(find.byKey(page)), const Rect.fromLTWH(0, 0, 360, 640));
      expect(pageBottomPadding(t), 24);
    });

    testWidgets('when the SDK does not start, no banner is asked for and the page plays on', (t) async {
      sdk.failInitialize = true;
      await pumpArea(t);
      expect(sdk.calls, ['configure', 'read', 'initialize']);
      expect(strip, findsNothing);
      expect(find.byKey(page), findsOneWidget);
    });

    testWidgets('a page too narrow for it asks for none', (t) async {
      await pumpArea(
        t,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(340, 640), padding: EdgeInsets.symmetric(horizontal: 12)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: BannerAdArea(child: const SizedBox.expand(key: page)),
          ),
        ),
      );
      expect(sdk.bannerLoads, 0);
      expect(strip, findsNothing);
    });

    testWidgets('a release not cleared for ads asks the SDK nothing at all', (t) async {
      await pumpArea(t, overrides: adOverrides(allowed: false));
      expect(sdk.calls, isEmpty);
      expect(strip, findsNothing);
      // And no platform is cleared yet: every release build is one.
      expect(AdConfig.releaseCleared, isEmpty);
      for (final p in AdPlatform.values) {
        expect(AdConfig.requestsAllowed(platform: p, release: true), isFalse);
      }
    });

    testWidgets('leaving the page releases its ad', (t) async {
      final ad = _FakeBanner();
      sdk.banners.add(ad);
      await pumpArea(t);
      expect(strip, findsOneWidget);
      await t.pumpWidget(const SizedBox());
      expect(ad.disposed, 1);
    });

    testWidgets('an ad arriving after the page has gone is released, not shown', (t) async {
      sdk.pending = Completer();
      await pumpArea(t);
      await t.pumpWidget(ProviderScope(overrides: adOverrides(), child: const SizedBox()));
      final late = _FakeBanner();
      sdk.pending!.complete(late);
      await t.pump();
      expect(late.disposed, 1);
    });

    testWidgets('coming back asks for a new ad: one ad, one view, never shared', (t) async {
      final first = _FakeBanner(), second = _FakeBanner();
      sdk.banners.addAll([first, second]);
      final container = ProviderContainer(overrides: adOverrides());
      addTearDown(container.dispose);
      Future<void> show(Widget child) async {
        await t.pumpWidget(UncontrolledProviderScope(container: container, child: child));
        await t.pump();
        await t.pump();
      }

      await show(area(key: const ValueKey('visit-1')));
      final firstView = t.widget<KeyedSubtree>(find.ancestor(of: view, matching: find.byType(KeyedSubtree)).first);
      expect(firstView.key, ObjectKey(first));
      await show(const SizedBox());
      expect(first.disposed, 1);
      await show(area(key: const ValueKey('visit-2')));
      expect(sdk.bannerLoads, 2);
      expect(sdk.calls.where((c) => c == 'initialize'), hasLength(1), reason: 'the SDK starts once');
      expect(view, findsOneWidget);
      final secondView = t.widget<KeyedSubtree>(find.ancestor(of: view, matching: find.byType(KeyedSubtree)).first);
      expect(secondView.key, ObjectKey(second));
      expect(second.disposed, 0);
    });

    testWidgets('turning the phone keeps the same banner', (t) async {
      final first = _FakeBanner();
      sdk.banners.add(first);
      Widget sized(Size size, EdgeInsets pad) => MediaQuery(
        data: MediaQueryData(size: size, padding: pad),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BannerAdArea(child: const SizedBox.expand(key: page)),
        ),
      );
      await pumpArea(t, child: sized(const Size(360, 640), EdgeInsets.zero));
      await pumpArea(t, child: sized(const Size(640, 360), const EdgeInsets.symmetric(horizontal: 30)));
      expect(sdk.bannerLoads, 1);
      expect(first.disposed, 0);
      expect(strip, findsOneWidget);
    });
  });

  group('the pages', () {
    /// Season 1 with Case 01 solved and Case 02 under way.
    Map<String, Object> saves() {
      final catalog = MockEpisodeRepository.bundled();
      final ep01 = catalog.firstWhere((e) => e.id == 'ep01');
      return {
        AppConstants.progressStorageKey: jsonEncode(
          GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in ep01.allMissions) m.id],
            startedAt: DateTime(2026, 9, 29, 10),
            completedAt: DateTime(2026, 9, 29, 10, 30),
            playMillis: 0,
          ).toJson(),
        ),
        AppConstants.progressKeyFor('ep02'): jsonEncode(
          GameProgress(detectiveName: 'MINYOUNG', introSeen: true, startedAt: DateTime(2026, 9, 29, 11), playMillis: 0)
              .toJson(),
        ),
        AppConstants.seasonStorageKey: jsonEncode(
          const SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01'], prologueSeen: true).toJson(),
        ),
      };
    }

    late WidgetRef appRef;

    Future<void> pumpApp(WidgetTester t) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: [...await testOverrides(prefs: saves(), adsOff: false), ...adOverrides()],
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
    }

    Future<void> go(WidgetTester t, String route) async {
      appRef.read(routerProvider).go(route);
      await wait(t, const Duration(milliseconds: 1600));
    }

    for (final (name, route) in [
      ('the Detective Archives', Routes.seasons),
      ('the investigation board', Routes.season),
      ('the case files', Routes.episodes),
    ]) {
      testWidgets('$name has a banner under it', (t) async {
        await pumpApp(t);
        expect(sdk.bannerLoads, 0, reason: 'nothing is asked for at launch');
        await go(t, route);
        expect(find.byType(BannerAdArea), findsOneWidget);
        expect(sdk.bannerLoads, 1);
        expect(strip, findsOneWidget);
        await wait(t, const Duration(seconds: 3));
      });
    }

    for (final (name, route) in [
      ('the title', Routes.start),
      ('the World Map', Routes.worldMap),
      ('the case map', Routes.map),
      ('the story intro', Routes.intro),
    ]) {
      testWidgets('$name has none, and asks for none', (t) async {
        await pumpApp(t);
        await go(t, route);
        expect(find.byType(BannerAdArea), findsNothing);
        expect(sdk.calls, isEmpty, reason: 'the SDK is not even started');
        await wait(t, const Duration(seconds: 3));
      });
    }

    test('only the pages allowed a banner have one', () {
      // Never a common Scaffold, a story, a scene, a puzzle or a mission.
      final using = [
        for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart') &&
              !f.path.replaceAll(r'\', '/').endsWith('widgets/banner_ad_area.dart') &&
              f.readAsStringSync().contains('BannerAdArea('))
            f.path.replaceAll(r'\', '/'),
      ]..sort();
      expect(using, [
        'lib/features/onboarding/episode_select_screen.dart',
        'lib/features/season/season_screen.dart',
        'lib/features/season/world_archive_screen.dart',
      ]);
    });
  });
}
