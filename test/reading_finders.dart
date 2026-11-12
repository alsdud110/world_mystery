import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading text is set sentence by sentence (`readingLines`): a line break
/// stands where a space was written, and no word changes. These finders
/// find text by its words as written, whichever way its lines are broken.

String _written(String shown) => shown.replaceAll('\n', ' ');

// As `find.text` reads them: the [RichText] alone when rich text is asked
// for (the [Text] over it is the same words, not counted twice).
String? _shown(Widget w, bool rich) => switch (w) {
  RichText() when rich => w.text.toPlainText(),
  Text() when !rich => w.data ?? w.textSpan?.toPlainText(),
  EditableText() when !rich => w.controller.text,
  _ => null,
};

/// Like `find.text`, a line break read as the space it stands for.
Finder findText(String text, {bool findRichText = false, bool skipOffstage = true}) => find.byWidgetPredicate(
  (w) {
    final shown = _shown(w, findRichText);
    return shown != null && (shown == text || _written(shown) == _written(text));
  },
  description: 'text "$text"',
  skipOffstage: skipOffstage,
);

/// Like `find.textContaining`, a line break read as the space it stands for.
Finder findTextContaining(Pattern pattern, {bool findRichText = false, bool skipOffstage = true}) => find.byWidgetPredicate(
  (w) {
    final shown = _shown(w, findRichText);
    if (shown == null) return false;
    if (shown.contains(pattern)) return true;
    return _written(shown).contains(pattern is String ? _written(pattern) : pattern);
  },
  description: 'text containing "$pattern"',
  skipOffstage: skipOffstage,
);
