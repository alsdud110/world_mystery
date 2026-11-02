import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_config.dart';

/// What every ad request of the game carries. The players are 8 to 12, so
/// the SDK is told so before it starts:
///
/// - [configuration]: the child age treatment (`ageRestrictedTreatment`,
///   which replaces the deprecated child-directed and under-age-of-consent
///   tags in google_mobile_ads 9.x; they are not set as well) and a G
///   maximum ad content rating. It applies to every later request.
/// - [request]: each request also asks for non-personalized ads.
///
/// [AdService.start] reads the configuration back and asks for nothing
/// unless both are in place.
abstract final class ChildSafeAds {
  static final configuration = RequestConfiguration(
    maxAdContentRating: MaxAdContentRating.g,
    ageRestrictedTreatment: AgeRestrictedTreatment.child,
  );

  static const request = AdRequest(nonPersonalizedAds: true);

  /// Whether the SDK's configuration [applied] protects the players.
  static bool isApplied(RequestConfiguration applied) =>
      applied.maxAdContentRating == MaxAdContentRating.g &&
      applied.ageRestrictedTreatment == AgeRestrictedTreatment.child;
}

/// The Google Mobile Ads SDK, as the game uses it (the plugin in the app, a
/// stand-in in tests). Loads complete when the ad is loaded and fail with an
/// [AdLoadFailure] otherwise.
abstract interface class AdSdk {
  Future<void> updateRequestConfiguration(RequestConfiguration configuration);

  Future<RequestConfiguration> getRequestConfiguration();

  Future<void> initialize();

  Future<BannerAd> loadBanner({required String adUnitId, required AdSize size, required AdRequest request});

  Future<RewardedAd> loadRewarded({required String adUnitId, required AdRequest request});
}

/// An ad that did not load. Never names the ad unit.
class AdLoadFailure implements Exception {
  const AdLoadFailure(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'AdLoadFailure($code: $message)';
}

class GoogleMobileAdsSdk implements AdSdk {
  const GoogleMobileAdsSdk();

  @override
  Future<void> updateRequestConfiguration(RequestConfiguration configuration) =>
      MobileAds.instance.updateRequestConfiguration(configuration);

  @override
  Future<RequestConfiguration> getRequestConfiguration() => MobileAds.instance.getRequestConfiguration();

  @override
  Future<void> initialize() => MobileAds.instance.initialize();

  @override
  Future<BannerAd> loadBanner({required String adUnitId, required AdSize size, required AdRequest request}) {
    final done = Completer<BannerAd>();
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: request,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!done.isCompleted) done.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!done.isCompleted) done.completeError(AdLoadFailure(error.code, error.message));
        },
      ),
    );
    banner.load().catchError((Object e) {
      banner.dispose();
      if (!done.isCompleted) done.completeError(e);
    });
    return done.future;
  }

  @override
  Future<RewardedAd> loadRewarded({required String adUnitId, required AdRequest request}) {
    final done = Completer<RewardedAd>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!done.isCompleted) done.complete(ad);
        },
        onAdFailedToLoad: (error) {
          if (!done.isCompleted) done.completeError(AdLoadFailure(error.code, error.message));
        },
      ),
    ).catchError((Object e) {
      if (!done.isCompleted) done.completeError(e);
    });
    return done.future;
  }
}

enum AdServiceState {
  /// Nothing asked of the SDK yet.
  idle,

  /// Protecting the requests, then starting the SDK.
  starting,

  /// Ads may be requested.
  ready,

  /// No ads this session (see [AdService.offReason]); the game plays on.
  off,
}

enum AdOffReason {
  /// Another platform, or a release without its real ad unit IDs.
  noAdUnits,

  /// A release on a platform not cleared for ads ([AdConfig.releaseCleared]).
  notCleared,

  /// The children's protection could not be set, or did not read back.
  childSafetyNotApplied,

  /// The SDK failed to start, or did not within [AdService.timeout].
  sdkNotStarted,

  /// The service was disposed.
  disposed,
}

/// Starts the ads SDK for the game, once, and says whether ads may be
/// requested. Nothing of it reaches the game: a failure, a timeout or no
/// network only turns ads off for the session.
///
/// Fail-closed: the SDK is never started (and so never requests an ad)
/// unless this build has ad units, may request ads, and the children's
/// protection ([ChildSafeAds]) is set and read back first.
///
/// Nothing calls [start] at launch; the first [AdSlot] that loads does.
class AdService extends ChangeNotifier {
  AdService({
    required this._sdk,
    required this._units,
    required this._requestsAllowed,
    this.timeout = const Duration(seconds: 10),
  });

  /// This build's: the plugin, its ad units, its policy.
  factory AdService.forThisBuild() => AdService(
    sdk: const GoogleMobileAdsSdk(),
    units: AdConfig.current,
    requestsAllowed: AdConfig.requestsAllowedNow,
  );

  final AdSdk _sdk;
  final AdUnitIds? _units;
  final bool _requestsAllowed;

  /// How long each step of [start] may take before ads are given up.
  final Duration timeout;

  AdServiceState _state = AdServiceState.idle;
  AdOffReason? _offReason;
  Future<bool>? _start;
  final Set<AdSlot<Ad>> _slots = {};

  AdServiceState get state => _state;
  AdOffReason? get offReason => _offReason;

  /// Whether an ad may be requested now.
  bool get canRequestAds => _state == AdServiceState.ready;

  /// The ad units, only while ads may be requested.
  AdUnitIds? get units => canRequestAds ? _units : null;

  /// Protects the requests, then starts the SDK. Called again, it gives the
  /// first call's answer: the SDK is started at most once.
  Future<bool> start() => _start ??= _run();

  Future<bool> _run() async {
    if (_state == AdServiceState.off) return false; // disposed before
    if (_units == null) return _off(AdOffReason.noAdUnits);
    if (!_requestsAllowed) return _off(AdOffReason.notCleared);
    _set(AdServiceState.starting);
    try {
      await _sdk.updateRequestConfiguration(ChildSafeAds.configuration).timeout(timeout);
      final applied = await _sdk.getRequestConfiguration().timeout(timeout);
      if (!ChildSafeAds.isApplied(applied)) return _off(AdOffReason.childSafetyNotApplied);
    } catch (e) {
      debugPrint('Ads off: the children\'s protection could not be set (${e.runtimeType})');
      return _off(AdOffReason.childSafetyNotApplied);
    }
    if (_state != AdServiceState.starting) return false; // disposed meanwhile
    try {
      await _sdk.initialize().timeout(timeout);
    } catch (e) {
      debugPrint('Ads off: the SDK did not start (${e.runtimeType})');
      return _off(AdOffReason.sdkNotStarted);
    }
    if (_state != AdServiceState.starting) return false;
    _set(AdServiceState.ready);
    return true;
  }

  bool _off(AdOffReason reason) {
    if (_state != AdServiceState.off) {
      _offReason = reason;
      _set(AdServiceState.off);
    }
    return false;
  }

  void _set(AdServiceState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  /// A banner of [size], loaded on [AdSlot.load].
  BannerSlot banner(AdSize size, {AdBackoff backoff = AdBackoff.standard}) =>
      _track(BannerSlot._(this, size, backoff));

  /// A rewarded ad kept loaded ahead of its moment.
  RewardedSlot rewarded({AdBackoff backoff = AdBackoff.standard}) => _track(RewardedSlot._(this, backoff));

  S _track<S extends AdSlot<Ad>>(S slot) {
    if (_disposed) {
      slot.dispose();
    } else {
      _slots.add(slot);
    }
    return slot;
  }

  bool _disposed = false;

  /// The app is closing: every slot's ad is released and no ad is asked for
  /// again.
  @override
  void dispose() {
    if (_disposed) return;
    _off(AdOffReason.disposed);
    _disposed = true;
    for (final slot in [..._slots]) {
      slot.dispose();
    }
    super.dispose();
  }
}

/// How long a slot waits after failed loads before it asks again: [first],
/// doubled with each failure in a row, up to [max]. A load succeeding starts
/// over.
@immutable
class AdBackoff {
  const AdBackoff({required this.first, required this.max, this.now = DateTime.now});

  static const standard = AdBackoff(first: Duration(seconds: 30), max: Duration(minutes: 10));

  final Duration first;
  final Duration max;
  final DateTime Function() now;

  Duration after(int failures) {
    final ms = first.inMilliseconds * math.pow(2, math.min(failures - 1, 20));
    return Duration(milliseconds: math.min(ms.toInt(), max.inMilliseconds));
  }
}

/// One ad for one place in the game: loaded once (a second load while one
/// is loading or loaded asks nothing), retried no sooner than its
/// [AdBackoff] allows, and released when its place no longer needs it.
/// Never throws: an ad that does not load leaves [ad] null.
abstract class AdSlot<T extends Ad> extends ChangeNotifier {
  AdSlot._(this._service, this._backoff);

  final AdService _service;
  final AdBackoff _backoff;

  T? _ad;
  bool _loading = false;
  int _failures = 0;
  DateTime? _retryAt;
  bool _disposed = false;

  /// The loaded ad, or null.
  T? get ad => _ad;
  bool get isLoading => _loading;

  /// Failed loads in a row.
  int get failures => _failures;

  bool get isDisposed => _disposed;

  @protected
  Future<T> request(AdSdk sdk, AdUnitIds units);

  /// Loads the ad if there is none: starts the service first, and asks
  /// nothing while ads are off or the last failure's wait is not over.
  /// True when an ad is loaded.
  Future<bool> load() async {
    if (_disposed) return false;
    if (_ad != null) return true;
    if (_loading) return false;
    final retryAt = _retryAt;
    if (retryAt != null && _backoff.now().isBefore(retryAt)) return false;
    _loading = true;
    notifyListeners();
    try {
      if (!await _service.start()) return false;
      final units = _service.units;
      if (_disposed || units == null) return false;
      final T ad;
      try {
        ad = await request(_service._sdk, units);
      } catch (e) {
        _failures++;
        _retryAt = _backoff.now().add(_backoff.after(_failures));
        debugPrint('Ad not loaded: ${e is AdLoadFailure ? e : e.runtimeType}');
        return false;
      }
      if (_disposed) {
        _disposeAd(ad); // its place went away while it loaded
        return false;
      }
      _ad = ad;
      _failures = 0;
      _retryAt = null;
      return true;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Disposes the loaded ad (its place is gone, or it was shown); the slot
  /// may load another.
  void release() {
    final ad = _ad;
    if (ad == null) return;
    _ad = null;
    _disposeAd(ad);
    if (!_disposed) notifyListeners();
  }

  /// Gives the loaded ad to the caller, who disposes it from then on (a
  /// full-screen ad disposes itself once dismissed).
  @protected
  T? handOver() {
    final ad = _ad;
    _ad = null;
    if (ad != null && !_disposed) notifyListeners();
    return ad;
  }

  static void _disposeAd(Ad ad) {
    try {
      ad.dispose().catchError((Object _) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_disposed) return;
    release();
    _disposed = true;
    _service._slots.remove(this);
    super.dispose();
  }
}

class BannerSlot extends AdSlot<BannerAd> {
  BannerSlot._(super.service, this.size, super.backoff) : super._();

  final AdSize size;

  @override
  Future<BannerAd> request(AdSdk sdk, AdUnitIds units) =>
      sdk.loadBanner(adUnitId: units.banner, size: size, request: ChildSafeAds.request);
}

class RewardedSlot extends AdSlot<RewardedAd> {
  RewardedSlot._(super.service, super.backoff) : super._();

  @override
  Future<RewardedAd> request(AdSdk sdk, AdUnitIds units) =>
      sdk.loadRewarded(adUnitId: units.rewarded, request: ChildSafeAds.request);

  /// The loaded ad, taken out to be shown: the caller disposes it from now
  /// on, and the slot may preload the next.
  RewardedAd? take() => handOver();
}
