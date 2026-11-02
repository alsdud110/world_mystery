import 'package:flutter/foundation.dart';

/// The platforms that show AdMob ads.
enum AdPlatform { android, ios }

/// One platform's ad unit IDs.
@immutable
class AdUnitIds {
  const AdUnitIds({required this.banner, required this.rewarded});

  final String banner;
  final String rewarded;

  @override
  bool operator ==(Object other) =>
      other is AdUnitIds && other.banner == banner && other.rewarded == rewarded;

  @override
  int get hashCode => Object.hash(banner, rewarded);
}

/// The AdMob ad unit IDs this build uses.
///
/// Release builds take the real IDs passed with
/// `--dart-define-from-file=config/ads.local.json` (git-ignored; keys in
/// `config/ads.example.json`). Debug and profile builds always use Google's
/// sample IDs, so they never request real ads. The App IDs are not read here:
/// the native builds put them into AndroidManifest.xml
/// (android/app/build.gradle.kts) and Info.plist (ios/scripts/admob_app_id.sh),
/// and a release build stops there when an ID is missing.
///
/// Nothing here starts the SDK or requests an ad.
abstract final class AdConfig {
  static const _androidBannerId = String.fromEnvironment('ADMOB_ANDROID_BANNER_ID');
  static const _androidRewardedId = String.fromEnvironment('ADMOB_ANDROID_REWARDED_ID');
  static const _iosBannerId = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
  static const _iosRewardedId = String.fromEnvironment('ADMOB_IOS_REWARDED_ID');

  /// Google's sample publisher: every test App ID and ad unit ID starts with it.
  static const samplePublisher = 'ca-app-pub-3940256099942544';

  /// Google's sample ad units (adaptive banner, rewarded).
  static const testAndroid = AdUnitIds(
    banner: '$samplePublisher/9214589741',
    rewarded: '$samplePublisher/5224354917',
  );
  static const testIos = AdUnitIds(
    banner: '$samplePublisher/2435281174',
    rewarded: '$samplePublisher/1712485313',
  );

  /// The platform this build runs on, or null when it shows no ads.
  static AdPlatform? get platform => switch (defaultTargetPlatform) {
    _ when kIsWeb => null,
    TargetPlatform.android => AdPlatform.android,
    TargetPlatform.iOS => AdPlatform.ios,
    _ => null,
  };

  /// The platforms whose release builds may request ads: none until that
  /// store's checks in docs/ADMOB_POLICY_CHECKLIST.md are done (children's
  /// ads policy, consent where the law asks for it). Adding a platform here
  /// is that sign-off.
  static const releaseCleared = <AdPlatform>{};

  /// Whether this build may ask the SDK for ads at all.
  static bool get requestsAllowedNow {
    final p = platform;
    return p != null && requestsAllowed(platform: p, release: kReleaseMode);
  }

  /// Debug and profile builds may (sample ads only); a release only on a
  /// platform [cleared] for it.
  @visibleForTesting
  static bool requestsAllowed({
    required AdPlatform platform,
    required bool release,
    Set<AdPlatform> cleared = releaseCleared,
  }) => !release || cleared.contains(platform);

  /// This build's ad units, or null when it shows no ads (another platform,
  /// or a release without valid IDs).
  static AdUnitIds? get current => resolve(
    platform: platform,
    release: kReleaseMode,
    configured: const {
      AdPlatform.android: AdUnitIds(banner: _androidBannerId, rewarded: _androidRewardedId),
      AdPlatform.ios: AdUnitIds(banner: _iosBannerId, rewarded: _iosRewardedId),
    },
  );

  /// The ad units for [platform]: the sample ones outside a [release]; in a
  /// release, the [configured] ones when both are real IDs, else null (never
  /// the sample ones).
  @visibleForTesting
  static AdUnitIds? resolve({
    required AdPlatform? platform,
    required bool release,
    required Map<AdPlatform, AdUnitIds> configured,
  }) {
    if (platform == null) return null;
    if (!release) {
      return switch (platform) {
        AdPlatform.android => testAndroid,
        AdPlatform.ios => testIos,
      };
    }
    final ids = configured[platform];
    if (ids == null || !isRealAdUnitId(ids.banner) || !isRealAdUnitId(ids.rewarded)) {
      return null;
    }
    return ids;
  }

  static final _adUnitId = RegExp(r'^ca-app-pub-\d+/\d+$');

  /// Whether [id] is an ad unit ID that is not one of Google's samples.
  static bool isRealAdUnitId(String id) =>
      _adUnitId.hasMatch(id) && !id.startsWith(samplePublisher);
}
