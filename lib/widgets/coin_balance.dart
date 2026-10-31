import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/wallet_controller.dart';
import 'art_assets.dart';
import 'ink_icon.dart';

/// The detective's coin, everywhere coins are shown: its gold picture
/// ([ArtAssets.coin], full colour, a little larger than an ink icon so its
/// star reads), or the ink coin in [color] while the file is missing.
class GameCoin extends StatelessWidget {
  const GameCoin({super.key, this.size = AppIconSize.small, this.color});

  final double size;

  /// The ink coin's colour (the picture keeps its own gold).
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Image.asset(
          ArtAssets.coin,
          width: size,
          height: size,
          cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          errorBuilder: (context, error, stack) => InkIcon(InkGlyph.coin, size: size, color: color),
        ),
      );
}

/// The detective's coins, quietly in the app bar beside the notebook: the
/// gold coin and the number, nothing to tap. The wallet is read from the
/// saves when the game starts, so the number is there from the first frame
/// (never a 0 that flickers). A change fades in briefly (not with Reduce
/// Motion).
class CoinBalance extends ConsumerWidget {
  const CoinBalance({super.key, this.dark = false});

  /// On the night bar (search, talk): lighter ink.
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletProvider.select((w) => w.balance));
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Coins: $balance',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameCoin(size: AppIconSize.small, color: dark ? AppColors.goldLight : AppColors.goldDeep),
            const SizedBox(width: AppSpace.xs + 2),
            AnimatedSwitcher(
              duration: still ? Duration.zero : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                '$balance',
                key: ValueKey(balance),
                style: AppText.bodyText(
                  size: 15,
                  weight: FontWeight.w700,
                  color: dark ? AppColors.paperLight : AppColors.navy,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()], height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
