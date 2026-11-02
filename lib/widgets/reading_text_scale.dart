import 'package:flutter/widgets.dart';

import '../core/theme/app_tokens.dart';

/// Long reading may grow past the page's text size cap, following the
/// system's text size up to [AppTextScale.reading] (never smaller than the
/// page around it). Only for words that wrap inside a scroll: a clue's
/// words, an evidence's words — not tabs, tiles or buttons.
class ReadingTextScale extends StatelessWidget {
  const ReadingTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The system's own text size (the app caps it for every page).
    final system = MediaQueryData.fromView(View.of(context)).textScaler;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: system.clamp(maxScaleFactor: AppTextScale.reading)),
      child: child,
    );
  }
}
