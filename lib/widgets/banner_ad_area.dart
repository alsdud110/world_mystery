import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/ad_service.dart';
import '../features/game/game_providers.dart';

/// The anchored adaptive banner's size for a [width] in an [orientation]
/// (null: none fits).
typedef BannerSizeLookup = Future<AdSize?> Function(Orientation orientation, int width);

/// The SDK's anchored adaptive size in the app; a fixed size in tests.
final bannerSizeLookupProvider = Provider<BannerSizeLookup>(
  (ref) => AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation,
);

/// How a loaded banner is drawn: the plugin's [AdWidget] in the app.
final bannerAdViewProvider = Provider<Widget Function(BannerAd ad)>((ref) => (ad) => AdWidget(ad: ad));

/// A page with a banner ad under it, only on the pages allowed one (the
/// archives, the investigation board, the case files): never a story,
/// a scene, a puzzle or a mission. Each page that shows one wraps its own
/// body; there is no app-wide banner.
///
/// The page is [child], as it was. Only once an ad has loaded does a strip
/// for it open below the page (which then gives up its bottom inset to the
/// strip); while loading, when ads are off ([AdService]) or the ad does not
/// load, nothing is shown and nothing waits. Ads start here, the first time
/// a page needs one ([AdService.start]).
///
/// Each area owns its own [BannerSlot]: its ad is drawn in one place only,
/// released when the page goes, and asked for afresh when the page comes
/// back, or when the width changes (rotation, a resized window).
class BannerAdArea extends ConsumerStatefulWidget {
  const BannerAdArea({super.key, required this.child});

  final Widget child;

  /// How long the size lookup may take before the banner is given up.
  static const sizeTimeout = Duration(seconds: 5);

  @override
  ConsumerState<BannerAdArea> createState() => _BannerAdAreaState();
}

class _BannerAdAreaState extends ConsumerState<BannerAdArea> {
  BannerSlot? _slot;

  /// The orientation and width the banner was asked for.
  (Orientation, int)? _fit;

  /// Counts the asks: an answer to an earlier one is dropped.
  int _asked = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final fit = (MediaQuery.orientationOf(context), (size.width - pad.left - pad.right).truncate());
    if (fit == _fit) return;
    _fit = fit;
    _load(fit);
  }

  Future<void> _load((Orientation, int) fit) async {
    _drop();
    final asked = ++_asked;
    final service = ref.read(adServiceProvider);
    if (!await service.start() || !_current(asked)) return;
    final AdSize? size;
    try {
      size = await ref.read(bannerSizeLookupProvider)(fit.$1, fit.$2).timeout(BannerAdArea.sizeTimeout);
    } catch (e) {
      debugPrint('Banner not shown: no size (${e.runtimeType})');
      return;
    }
    if (size == null || size.width <= 0 || size.height <= 0 || !_current(asked)) return;
    final slot = _slot = service.banner(size)..addListener(_changed);
    unawaited(slot.load());
  }

  bool _current(int asked) => mounted && asked == _asked;

  void _changed() {
    if (mounted) setState(() {});
  }

  /// Releases the banner (its ad, a load still under way).
  void _drop() {
    final slot = _slot;
    _slot = null;
    slot
      ?..removeListener(_changed)
      ..dispose();
  }

  @override
  void dispose() {
    _asked++;
    _drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slot;
    final ad = slot?.ad;
    return Column(
      children: [
        Expanded(
          // The page keeps its place in the tree whether or not a banner is under it.
          child: MediaQuery.removePadding(context: context, removeBottom: ad != null, child: widget.child),
        ),
        if (slot != null && ad != null)
          DecoratedBox(
            key: const ValueKey('banner-ad'),
            // Set apart from the page's buttons above it.
            decoration: BoxDecoration(
              color: AppColors.nightBottom,
              border: Border(
                top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.2), width: AppLine.hairline),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpace.sm),
                child: Center(
                  heightFactor: 1,
                  child: SizedBox(
                    width: slot.size.width.toDouble(),
                    height: slot.size.height.toDouble(),
                    child: KeyedSubtree(key: ObjectKey(ad), child: ref.watch(bannerAdViewProvider)(ad)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
