import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/utils/ad_service.dart';
import 'rewarded_ad_gateway.dart';

/// What the coins dialog can offer of a rewarded ad.
enum RewardedOffer {
  /// Being loaded: GET COINS waits, without a spinner.
  loading,

  /// Loaded: GET COINS shows it.
  ready,

  /// On screen now: GET COINS does nothing more.
  showing,

  /// Did not load (its wait before asking again is not over).
  unavailable,
}

/// The rewarded ad of GET COINS, on the game's [AdService]: one ad kept
/// loaded ahead ([RewardedSlot]), shown only when the player asks, then
/// disposed and the next one loaded.
///
/// Coins come only from the SDK's `onUserEarnedReward`, and at most once per
/// ad: each shown ad has its own reward id, and [onEarned] (the wallet,
/// which writes each id once) is called with it the moment the reward is
/// earned, so closing the ad or leaving the page afterwards cannot lose it.
/// Opening, closing, a failed load or a failed show pays nothing. Nothing
/// here throws into the game.
class AdMobRewardedAdGateway extends ChangeNotifier implements RewardedAdGateway {
  AdMobRewardedAdGateway(this._service, {required this._onEarned, DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _service.addListener(_changed);
    _slot.addListener(_changed);
  }

  final AdService _service;
  final void Function(String rewardId) _onEarned;
  final DateTime Function() _now;
  late final RewardedSlot _slot = _service.rewarded();

  bool _showing = false;
  int _shown = 0;
  bool _disposed = false;

  /// What GET COINS can do now; null when this build or session shows no
  /// ads at all (a release not cleared for them, the SDK off): no offer.
  RewardedOffer? get offer {
    if (!_service.mayStart) return null;
    if (_showing) return RewardedOffer.showing;
    if (_slot.ad != null) return RewardedOffer.ready;
    if (_slot.isLoading || _slot.failures == 0) return RewardedOffer.loading;
    return RewardedOffer.unavailable;
  }

  @override
  bool get isAvailable => offer == RewardedOffer.ready;

  /// Loads an ad ahead of its moment (starting ads first); asks nothing while
  /// one is loaded or loading, or the last failure's wait is not over.
  Future<void> preload() async {
    if (_disposed || _showing) return;
    await _slot.load();
  }

  /// Shows the loaded ad. The reward id once its reward was earned (the coins
  /// are already paid then); null when there was no ad, it failed to show,
  /// or it was closed before its reward.
  @override
  Future<String?> showAndEarnReward() async {
    if (_disposed || _showing) return null;
    final ad = _slot.take();
    if (ad == null) {
      unawaited(preload());
      return null;
    }
    _showing = true;
    _changed();
    final rewardId = 'admob:${_now().microsecondsSinceEpoch}:${++_shown}';
    var earned = false;
    final closed = Completer<void>();
    void close(RewardedAd ad) {
      try {
        ad.dispose().catchError((Object _) {});
      } catch (_) {}
      if (!closed.isCompleted) closed.complete();
    }

    try {
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: close,
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad not shown: ${error.code}');
          close(ad);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, _) {
          if (earned) return; // one reward per ad, however often it is said
          earned = true;
          try {
            _onEarned(rewardId);
          } catch (error, stack) {
            FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'rewarded ad'));
          }
        },
      );
    } catch (e) {
      debugPrint('Rewarded ad not shown (${e.runtimeType})');
      close(ad);
    }
    await closed.future;
    _showing = false;
    _changed();
    unawaited(preload()); // the next one, ready for another time
    return earned ? rewardId : null;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  /// The ad kept loaded is released; an ad on screen disposes itself when
  /// it closes, and a reward it earns is still paid.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _service.removeListener(_changed);
    _slot.removeListener(_changed);
    _slot.dispose();
    super.dispose();
  }
}
