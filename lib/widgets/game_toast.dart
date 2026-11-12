import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'ink_icon.dart';
import '../core/utils/reading_lines.dart';

OverlayEntry? _current;

/// A short message at the top of the screen that never blocks taps
/// (unlike a SnackBar, which would cover the big bottom buttons). It fades
/// in and out where it stands; it never slides (see [AppMotion]).
void showGameToast(BuildContext context, String message, {InkGlyph glyph = InkGlyph.lock}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      glyph: glyph,
      onDone: () {
        if (_current == entry) _current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.glyph, required this.onDone});

  final String message;
  final InkGlyph glyph;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.toastIn,
    reverseDuration: AppMotion.toastOut,
  );
  late final CurvedAnimation _fade = CurvedAnimation(
    parent: _c,
    curve: AppMotion.toastInCurve,
    reverseCurve: AppMotion.toastOutCurve,
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(AppMotion.toastHold);
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _fade.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Material(
                color: AppColors.navy,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.4), width: AppLine.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      InkIcon(widget.glyph, color: AppColors.goldLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(readingLines(widget.message), style: AppText.bodyText(size: 16, color: AppColors.paperLight)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
