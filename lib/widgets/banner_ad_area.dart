import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/ad_service.dart';
import '../features/game/game_providers.dart';

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
/// The ad is the standard banner ([size], 320×50), centred at the bottom
/// and drawn at its own size: never stretched, shrunk or cut. A page too
/// narrow for it gets none.
///
/// Each area owns its own [BannerSlot]: its ad is drawn in one place only,
/// released when the page goes, and asked for afresh when the page comes
/// back, or when the page grows wide enough for it again.
class BannerAdArea extends ConsumerStatefulWidget {
  const BannerAdArea({super.key, required this.child});

  final Widget child;

  /// The banner's size: AdMob's standard banner.
  static const size = AdSize.banner;

  @override
  ConsumerState<BannerAdArea> createState() => _BannerAdAreaState();
}

class _BannerAdAreaState extends ConsumerState<BannerAdArea> {
  BannerSlot? _slot;

  /// Whether the page was wide enough for the banner, when last measured.
  bool? _fits;

  /// Counts the asks: an answer to an earlier one is dropped.
  int _asked = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final fits = size.width - pad.left - pad.right >= BannerAdArea.size.width;
    if (fits == _fits) return;
    _fits = fits;
    _asked++;
    _drop();
    if (fits) _load();
  }

  Future<void> _load() async {
    final asked = _asked;
    final service = ref.read(adServiceProvider);
    if (!await service.start() || !_current(asked)) return;
    final slot = _slot = service.banner(BannerAdArea.size)..addListener(_changed);
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
            // A dark strip exactly the ad's height; the system inset below it apart.
            decoration: const BoxDecoration(color: AppColors.nightBottom),
            child: SafeArea(
              top: false,
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
      ],
    );
  }
}
