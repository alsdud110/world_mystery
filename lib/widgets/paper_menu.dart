import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/game_providers.dart';
import 'ink_icon.dart';
import 'paper.dart';

/// A press on the menu paper: a faint ink mark, not a Material ripple.
Color get _press => AppColors.inkBrown.withValues(alpha: 0.08);

/// The game's menu: a page of the casebook slid over the page (the case
/// map's menu, the World Map's). The case files' paper, nearly square
/// corners, a thin ink-brown tab printed on it (the theme's grey handle is
/// off; the whole sheet still drags to close). [items] are built in the
/// sheet, so they follow the game as it changes (the sound switch).
Future<void> showPaperMenu(
  BuildContext context, {
  required List<Widget> Function(BuildContext sheetContext, WidgetRef ref) items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaperSheetTab(),
              ...items(sheetContext, ref),
              const SizedBox(height: AppSpace.sm),
            ],
          ),
        ),
      ),
    ),
  );
}

/// One line of a [showPaperMenu] page: its ink mark and what it does.
class PaperMenuItem extends StatelessWidget {
  const PaperMenuItem(this.glyph, this.label, {super.key, required this.onTap});

  final InkGlyph glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final press = _press;
    return ListTile(
      leading: InkIcon(glyph, color: AppColors.ink),
      title: Text(label, style: AppText.subtitle()),
      splashColor: press,
      hoverColor: press,
      focusColor: press,
      onTap: onTap,
    );
  }
}

/// The game's one sound switch, on a [showPaperMenu] page.
class SoundSwitchTile extends ConsumerWidget {
  const SoundSwitchTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundOn = ref.watch(soundEnabledProvider);
    final press = _press;
    // Its press and focus marks in the same faint ink (this row only).
    return Theme(
      data: Theme.of(context).copyWith(focusColor: press, hoverColor: press, splashColor: press, highlightColor: press),
      child: SwitchListTile(
        secondary: InkIcon(soundOn ? InkGlyph.speaker : InkGlyph.speakerOff, color: AppColors.ink),
        title: Text('Sound effects', style: AppText.subtitle()),
        hoverColor: press,
        activeThumbColor: AppColors.goldLight,
        activeTrackColor: AppColors.navy,
        inactiveThumbColor: AppColors.paperLight,
        inactiveTrackColor: AppColors.parchmentDark,
        value: soundOn,
        onChanged: (_) => ref.read(soundEnabledProvider.notifier).toggle(),
      ),
    );
  }
}
