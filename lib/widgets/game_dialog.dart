import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'game_button.dart';
import 'paper.dart';
import '../core/utils/reading_lines.dart';

/// The game's popup: [showDialog] with the popup motion — the paper grows
/// slightly into place (scale in, ease-out) as the page behind dims.
/// Use it wherever a dialog is shown, so every popup arrives the same way.
Future<T?> showGamePopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierColor: barrierColor,
  animationStyle: AppMotion.popup(context),
  builder: (context) => PopupScale(child: builder(context)),
);

/// Grows its popup from [AppMotion.popupScaleFrom] to full size with the
/// route that shows it (ease-out in, ease-in out). The route itself fades.
class PopupScale extends StatefulWidget {
  const PopupScale({super.key, required this.child});

  final Widget child;

  @override
  State<PopupScale> createState() => _PopupScaleState();
}

class _PopupScaleState extends State<PopupScale> {
  CurvedAnimation? _curve;
  Animation<double>? _scale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route == _curve?.parent) return;
    _curve?.dispose();
    _curve = CurvedAnimation(parent: route, curve: AppMotion.popupCurve, reverseCurve: AppMotion.popupReverseCurve);
    _scale = Tween(begin: AppMotion.popupScaleFrom, end: 1.0).animate(_curve!);
  }

  @override
  void dispose() {
    _curve?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    if (scale == null) return widget.child;
    return ScaleTransition(scale: scale, child: widget.child);
  }
}

/// The game's own dialog: a ruled paper document laid over the page,
/// instead of a Material alert.
///
/// [GameDialog.plain] is the grown-ups' version (parent gate, operator
/// tools): the same paper, no ornament, compact themed actions, so it reads
/// as a tool and works outside the game's provider scope.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.plain = false,
    this.scrollable = false,
  });

  /// A child-facing yes/no question. Primary action on top, full width;
  /// "keep going" below as a quiet ink link. Returns true for [confirmLabel].
  ///
  /// [onScene]: asked over a painted scene (the title page's office). The
  /// scene stays in view under a translucent night shade instead of the
  /// plain dim. Either way the paper arrives as every popup does
  /// ([showGamePopup]).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool onScene = false,
  }) async {
    Widget dialog(BuildContext context) => GameDialog(
      title: title,
      content: Text(readingLines(message), textAlign: TextAlign.center, style: AppText.bodyText(size: 16)),
      actions: [
        GameButton(label: confirmLabel, onPressed: () => Navigator.of(context).pop(true)),
        const SizedBox(height: AppSpace.xs),
        InkTextButton(label: cancelLabel, color: AppColors.inkBrown, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
    final ok = await showGamePopup<bool>(
      context: context,
      barrierColor: onScene ? AppColors.navyDeep.withValues(alpha: 0.55) : null,
      builder: dialog,
    );
    return ok ?? false;
  }

  /// A grown-ups' confirmation. [destructive] paints the action in the
  /// try-again ink so a reset never looks like an ordinary button.
  static Future<bool> confirmPlain(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final ok = await showGamePopup<bool>(
      context: context,
      builder: (context) => GameDialog(
        plain: true,
        title: title,
        content: Text(readingLines(message), style: AppText.bodyText(size: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.tryAgain) : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool plain;

  /// Scroll inside the paper (e.g. a field above the keyboard on a small phone).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: plain ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: [
        Text(readingLines(title), textAlign: plain ? TextAlign.start : TextAlign.center, style: AppText.title(size: 22)),
        if (!plain) ...[const SizedBox(height: AppSpace.sm), const Center(child: OrnamentRule(width: 96))],
        const SizedBox(height: AppSpace.lg),
        content,
        const SizedBox(height: AppSpace.xl),
        if (plain)
          Wrap(alignment: WrapAlignment.end, spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: actions)
        else
          ...actions,
      ],
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperSheet(
          ruled: !plain,
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
          child: scrollable ? SingleChildScrollView(child: body) : body,
        ),
      ),
    );
  }
}
