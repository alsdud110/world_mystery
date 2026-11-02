import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import 'admob_rewarded_ad_gateway.dart';
import 'game_providers.dart';
import 'wallet_controller.dart';

/// GET COINS' rewarded ad, on the game's ads ([adServiceProvider]): Google's
/// sample ads in debug and profile builds; none in a release until it is
/// cleared for ads (`AdConfig.releaseCleared`). A reward is paid into the
/// wallet the moment the SDK says it was earned.
final rewardedAdGatewayProvider = Provider<AdMobRewardedAdGateway>((ref) {
  final gateway = AdMobRewardedAdGateway(
    ref.watch(adServiceProvider),
    onEarned: (rewardId) => ref.read(walletProvider.notifier).rewardCompletedAd(rewardId),
  );
  ref.onDispose(gateway.dispose);
  return gateway;
});

enum RewardedAdStatus { unavailable, notEarned, earned }

class RewardedAdOutcome {
  const RewardedAdOutcome(this.status, {this.coins = 0});

  final RewardedAdStatus status;
  final int coins;
}

/// Single entry point for the UI. Only an earned callback can credit coins.
/// Production adapters must supply a stable, unique reward event ID.
/// Client-only IDs are not fraud-proof; server-side verification is recommended.
final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref),
);

class RewardedAdService {
  const RewardedAdService(this.ref);

  final Ref ref;

  Future<RewardedAdOutcome> showAndReward() async {
    final gateway = ref.read(rewardedAdGatewayProvider);
    if (!gateway.isAvailable) {
      return const RewardedAdOutcome(RewardedAdStatus.unavailable);
    }
    final rewardId = await gateway.showAndEarnReward();
    if (rewardId == null || rewardId.trim().isEmpty) {
      return const RewardedAdOutcome(RewardedAdStatus.notEarned);
    }
    final wallet = ref.read(walletProvider.notifier);
    // Paid once: usually already, when the reward was earned (see the gateway).
    wallet.rewardCompletedAd(rewardId);
    if (!wallet.hasRewardedAd(rewardId)) {
      return const RewardedAdOutcome(RewardedAdStatus.notEarned);
    }
    return const RewardedAdOutcome(RewardedAdStatus.earned, coins: AppConstants.rewardedAdCoins);
  }
}
