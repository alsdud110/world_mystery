abstract final class Formatters {
  /// 42:18 or 1:02:05
  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  /// "42 min" — rounded, at least 1 minute.
  static String minutes(Duration d) {
    final m = (d.inSeconds / 60).round();
    return '${m < 1 ? 1 : m} min';
  }

  static String clueNumber(int index) => 'CLUE #${(index + 1).toString().padLeft(2, '0')}';

  /// A puzzle's question as its title: each sentence on a line of its own
  /// ("What did they touch?" / "Tap a picture."), never after Mr. or Mrs.
  static String sentenceLines(String text) => text.replaceAllMapped(_sentenceEnd, (m) => '${m[1]}\n');
  static final _sentenceEnd = RegExp(r'''(?<!\b(?:Mrs?|Ms|Dr|St))([.?!]) +(?=[A-Z"'])''');
}
