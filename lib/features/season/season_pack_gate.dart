import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assets/season_pack_downloads.dart';
import '../../core/assets/season_pack_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/mock/season_catalog.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_providers.dart';

/// Before a season is entered: its pictures are on the device, or the
/// detective agrees to download them first (its name and size asked, the
/// download shown, stopped or tried again). The season's unlock and progress
/// are not touched here.
abstract final class SeasonPackGate {
  /// True once season [seasonId] can be played (at once when nothing must be
  /// downloaded); false when the detective said not now or stopped. A pack
  /// whose files are gone from the device is asked for again.
  static Future<bool> ensure(BuildContext context, WidgetRef ref, String seasonId) async {
    // A season that cannot be entered (locked, not ready) is refused by
    // `GameController.openSeason` with its own reason, never downloaded.
    final enterable = ref.read(seasonAvailabilityProvider(seasonId))?.canEnter ?? false;
    final packs = ref.read(seasonPacksProvider.notifier)..recheck(seasonId);
    if (!enterable || !packs.needsDownload(seasonId)) return true;
    if (packs.isMissing(seasonId)) {
      showGameToast(context, 'This file is not in this version of the game.', glyph: InkGlyph.seal);
      return false;
    }
    final ok = await showGamePopup<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.55),
      builder: (_) => SeasonDownloadDialog(seasonId: seasonId),
    );
    return ok ?? false;
  }
}

/// "150.8 MB".
String megabytes(int bytes) => '${(bytes / 1000000).toStringAsFixed(1)} MB';

enum _Phase { ask, downloading, failed, noSpace }

class SeasonDownloadDialog extends ConsumerStatefulWidget {
  const SeasonDownloadDialog({super.key, required this.seasonId});

  final String seasonId;

  @override
  ConsumerState<SeasonDownloadDialog> createState() => _SeasonDownloadDialogState();
}

class _SeasonDownloadDialogState extends ConsumerState<SeasonDownloadDialog> {
  var _phase = _Phase.ask;
  var _done = 0;
  SeasonPackCancel? _cancel;

  late final _total = ref.read(seasonPacksProvider.notifier).downloadOf(widget.seasonId)!.manifest.totalBytes;

  Future<void> _download() async {
    final cancel = _cancel = SeasonPackCancel();
    setState(() => _phase = _Phase.downloading);
    try {
      await ref.read(seasonPacksProvider.notifier).download(
        widget.seasonId,
        cancel: cancel,
        onProgress: (done, _) {
          if (mounted && !cancel.isCancelled) setState(() => _done = done);
        },
      );
      if (mounted && !cancel.isCancelled) Navigator.of(context).pop(true);
    } on SeasonPackCancelled {
      // Closed already by STOP.
    } on SeasonPackNoSpace catch (e) {
      debugPrint('Season pack download failed: $e');
      if (mounted && !cancel.isCancelled) setState(() => _phase = _Phase.noSpace);
    } catch (e) {
      debugPrint('Season pack download failed: $e');
      if (mounted && !cancel.isCancelled) setState(() => _phase = _Phase.failed);
    }
  }

  void _stop() {
    _cancel?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final season = SeasonCatalog.byId(widget.seasonId)?.season;
    final name = season?.city ?? 'this season';
    final size = megabytes(_total);
    final (String title, String message) = switch (_phase) {
      _Phase.ask => (
        'Download $name?',
        '${season == null ? '' : '${season.label} · ${season.title}\n'}'
            'The case pictures for $name: $size.\nOnce they are here, the season plays without the internet.\n'
            'On mobile data, this download uses your data plan.',
      ),
      _Phase.downloading => ('Downloading $name', '${megabytes(_done)} of $size'),
      _Phase.failed => (
        'The download stopped',
        'Check the connection and try again. What was already downloaded is kept, and your cases and rewards are safe.',
      ),
      _Phase.noSpace => (
        'Not enough space',
        '$name needs about $size of free space on this device. Free up some space and try again. '
            'What was already downloaded is kept, and your cases and rewards are safe.',
      ),
    };
    return PopScope(
      canPop: false,
      child: GameDialog(
        key: const ValueKey('season-download-dialog'),
        title: title,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppText.bodyText(size: 16)),
            if (_phase == _Phase.downloading) ...[
              const SizedBox(height: AppSpace.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const ValueKey('season-download-progress'),
                  value: _total == 0 ? null : _done / _total,
                  minHeight: 4,
                  color: AppColors.gold,
                  backgroundColor: AppColors.parchmentDark.withValues(alpha: 0.6),
                  semanticsLabel: 'Downloading $name',
                  semanticsValue: '${(_total == 0 ? 0 : _done * 100 ~/ _total)}%',
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_phase != _Phase.downloading) ...[
            GameButton(
              key: const ValueKey('season-download-go'),
              label: _phase == _Phase.ask ? 'DOWNLOAD · $size' : 'TRY AGAIN',
              onPressed: _download,
            ),
            const SizedBox(height: AppSpace.xs),
            InkTextButton(label: 'Not now', color: AppColors.inkBrown, onPressed: () => Navigator.of(context).pop(false)),
          ] else
            InkTextButton(key: const ValueKey('season-download-stop'), label: 'Stop', color: AppColors.inkBrown, onPressed: _stop),
        ],
      ),
    );
  }
}
