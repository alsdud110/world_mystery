/// Where a line of reading text is broken, so that it reads sentence by
/// sentence instead of as one block.
///
/// Only the line breaks change: no word, mark or space inside a sentence is
/// touched. Short sentences stay together on one line ("Yes! Thank you,
/// Mom!"); a sentence that would not fit beside the one before starts its
/// own line. Breaks already written ('\n') are kept, and each written line
/// is broken on its own.
library;

/// The longest two (or more) short sentences may be, together, to stay on
/// one line: about one line of body text on a small phone.
const readingLineLength = 36;

// The end of a sentence (with any closing quote, bracket or bold mark), the
// space after it, and what opens the next one.
final _boundary = RegExp(r'''[.!?…]+["”’')\]*]* +(?=["“‘'(\[*]*[A-Z0-9가-힣ㄱ-ㅎ])''');

// Words whose full stop does not end a sentence: titles and one initial
// ("Mr. Hale", "St. Paul's", "J. Smith", "4:00 P.M.").
final _abbreviation = RegExp(r'(?:\b(?:Mr|Mrs|Ms|Dr|St|Mt|Prof|Sr|Jr|vs|etc)|\b[A-Z])\.$');

// "No. 4", and the number of a list ("1. Open the box.").
final _numberSign = RegExp(r'\bNo\.$');
final _listNumber = RegExp(r'^\W*\d{1,2}\.$');
final _digit = RegExp(r'[0-9]');

/// [text] with a line break between its sentences, where they are too long
/// to share a line ([readingLineLength]).
String readingLines(String text) {
  if (text.length <= readingLineLength || !text.contains(' ')) return text;
  if (!text.contains('\n')) return _broken(text);
  return text.split('\n').map(_broken).join('\n');
}

String _broken(String line) {
  if (line.length <= readingLineLength) return line;
  final sentences = _sentences(line);
  if (sentences.length < 2) return line;
  final out = StringBuffer(sentences.first);
  var length = _shown(sentences.first);
  for (final s in sentences.skip(1)) {
    final shown = _shown(s);
    if (length + 1 + shown <= readingLineLength) {
      out.write(' ');
      length += 1 + shown;
    } else {
      out.write('\n');
      length = shown;
    }
    out.write(s);
  }
  return out.toString();
}

/// [line] cut at each sentence's end; the spaces between are dropped.
List<String> _sentences(String line) {
  final out = <String>[];
  var start = 0;
  for (final m in _boundary.allMatches(line)) {
    final end = m.group(0)!.trimRight();
    final sentence = line.substring(start, m.start + end.length);
    final stop = sentence.replaceFirst(RegExp(r'''["”’')\]*]+$'''), '');
    final single = !stop.endsWith('..') && !stop.endsWith('…');
    if (single && stop.endsWith('.')) {
      if (_abbreviation.hasMatch(stop) || _listNumber.hasMatch(stop)) continue;
      if (_numberSign.hasMatch(stop) && _digit.hasMatch(line[m.end])) continue;
    }
    out.add(sentence);
    start = m.end;
  }
  out.add(line.substring(start));
  return out;
}

/// How long [s] reads: without its bold marks, the detective's name about
/// as long as a name.
int _shown(String s) => s.replaceAll('**', '').replaceAll('{detectiveName}', 'Holmes').length;
