import 'puzzle_rules.dart';

/// The line a vowel is built on: the flat earth (ㅡ) or a person standing (ㅣ).
enum VowelLine { flat, standing }

/// Where the sky's dot (ㆍ) sits on its line, if it has one.
enum VowelDot { none, above, below, left, right }

/// One written group of a note (`syllable_compose`): its first sound
/// ([initial], already known), the vowel to build ([vowel]), the sound
/// under it ([finalConsonant], if any), and the words that tell how its
/// vowel looked ([line]).
class SyllableBlock {
  const SyllableBlock({required this.id, required this.initial, required this.vowel, this.finalConsonant, required this.line});

  final String id;
  final String initial;
  final String vowel;
  final String? finalConsonant;
  final String line;
}

/// A note written in the new letters, put back together group by group
/// (Puzzle Engine 2.0, `syllable_compose`): each group's vowel is built from
/// the three first shapes — the sky's dot, the flat earth, the standing
/// person — and joined with its sounds into one written syllable.
class SyllableSpec {
  const SyllableSpec({required this.blocks});

  final List<SyllableBlock> blocks;

  SyllableBlock? block(String id) => blocks.where((b) => b.id == id).firstOrNull;
}

/// Hangul as Unicode writes it: the jamo a syllable is joined from.
abstract final class Hangul {
  static const initials = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];
  static const vowels = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ'];
  static const finals = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'];

  /// The sky's dot, as the 1446 book drew it (아래아).
  static const dot = 'ㆍ';

  /// [initial] + [vowel] (+ [finalConsonant]) as one syllable, or null
  /// when Unicode joins no such syllable.
  static String? compose(String initial, String vowel, [String? finalConsonant]) {
    final (i, v, f) = (initials.indexOf(initial), vowels.indexOf(vowel), finals.indexOf(finalConsonant ?? ''));
    if (i < 0 || v < 0 || f < 0) return null;
    return String.fromCharCode(0xAC00 + (i * 21 + v) * 28 + f);
  }

  /// The vowel a line and a dot make (the book's first letters: ㅣ ㅏ ㅓ ㅡ ㅗ ㅜ),
  /// or null when the dot cannot sit there (beside a flat line, over a standing one).
  static String? vowelOf(VowelLine line, VowelDot dot) => switch ((line, dot)) {
    (VowelLine.standing, VowelDot.none) => 'ㅣ',
    (VowelLine.standing, VowelDot.right) => 'ㅏ',
    (VowelLine.standing, VowelDot.left) => 'ㅓ',
    (VowelLine.flat, VowelDot.none) => 'ㅡ',
    (VowelLine.flat, VowelDot.above) => 'ㅗ',
    (VowelLine.flat, VowelDot.below) => 'ㅜ',
    _ => null,
  };

  /// How [vowel] is built (its line and dot), or null when it is not one of [vowelOf]'s.
  static (VowelLine, VowelDot)? partsOf(String vowel) {
    for (final line in VowelLine.values) {
      for (final dot in VowelDot.values) {
        if (vowelOf(line, dot) == vowel) return (line, dot);
      }
    }
    return null;
  }

  /// The places a dot can take on [line].
  static List<VowelDot> dotsFor(VowelLine line) =>
      line == VowelLine.flat ? const [VowelDot.above, VowelDot.below, VowelDot.none] : const [VowelDot.left, VowelDot.right, VowelDot.none];
}

/// One group as it is built: its line (null: none chosen yet) and its dot.
class SyllablePiece {
  const SyllablePiece([this.line, this.dot = VowelDot.none]);

  final VowelLine? line;
  final VowelDot dot;

  String? get vowel => line == null ? null : Hangul.vowelOf(line!, dot);

  @override
  bool operator ==(Object other) => other is SyllablePiece && other.line == line && other.dot == dot;

  @override
  int get hashCode => Object.hash(line, dot);
}

/// Every group of the note as it is built, in the note's order.
class SyllableState {
  const SyllableState(this.pieces);

  final List<SyllablePiece> pieces;

  @override
  bool operator ==(Object other) =>
      other is SyllableState && other.pieces.length == pieces.length && [for (var i = 0; i < pieces.length; i++) other.pieces[i] == pieces[i]].every((x) => x);

  @override
  int get hashCode => Object.hashAll(pieces);
}

sealed class SyllableAction {
  const SyllableAction();
}

/// Group [block]'s vowel built on [line] (its dot taken off: it sits elsewhere on another line).
class SetVowelLine extends SyllableAction {
  const SetVowelLine(this.block, this.line);

  final int block;
  final VowelLine line;
}

/// The dot of group [block] put at [dot] ([VowelDot.none]: taken off).
class SetVowelDot extends SyllableAction {
  const SetVowelDot(this.block, this.dot);

  final int block;
  final VowelDot dot;
}

/// Group [block] emptied again.
class ClearVowel extends SyllableAction {
  const ClearVowel(this.block);

  final int block;
}

/// The rules of `syllable_compose`.
class SyllableRules extends PuzzleRules<SyllableSpec, SyllableState, SyllableAction> {
  const SyllableRules();

  @override
  String get kind => 'syllables';

  @override
  int get stateVersion => 1;

  /// Groups a note may have.
  static const sizes = (2, 6);

  @override
  List<SpecIssue> validate(SyllableSpec spec) {
    final out = <SpecIssue>[...PuzzleSpecCheck.ids(elementIds(spec))];
    if (spec.blocks.length < sizes.$1 || spec.blocks.length > sizes.$2) {
      out.add(SpecIssue('syllables_size', r'$.blocks', '${spec.blocks.length} group(s): ${sizes.$1} to ${sizes.$2}'));
    }
    for (final (i, b) in spec.blocks.indexed) {
      final at = '\$.blocks[$i]';
      if (!Hangul.initials.contains(b.initial)) out.add(SpecIssue('syllables_initial', '$at.initial', '"${b.initial}" is no first sound of a syllable'));
      if (Hangul.partsOf(b.vowel) == null) {
        out.add(SpecIssue('syllables_vowel', '$at.vowel', '"${b.vowel}" is not built from a line and a dot (ㅣ ㅏ ㅓ ㅡ ㅗ ㅜ)'));
      }
      if (b.finalConsonant case final f? when f.isEmpty || !Hangul.finals.contains(f)) {
        out.add(SpecIssue('syllables_final', '$at.finalConsonant', '"$f" is no sound under a syllable'));
      }
      if (b.line.trim().isEmpty) out.add(SpecIssue('field_missing', '$at.line', 'the words that tell how its vowel looked'));
    }
    return out;
  }

  @override
  SyllableState initial(SyllableSpec spec) => SyllableState([for (final _ in spec.blocks) const SyllablePiece()]);

  @override
  Applied<SyllableState> apply(SyllableSpec spec, SyllableState s, SyllableAction action) {
    Applied<SyllableState> no(String code, String why) => Applied.rejected(s, Rejection(code, why));
    Applied<SyllableState> put(int i, SyllablePiece p) => Applied.accepted(SyllableState([...s.pieces]..[i] = p));
    final i = switch (action) {
      SetVowelLine(:final block) || SetVowelDot(:final block) || ClearVowel(:final block) => block,
    };
    if (i < 0 || i >= s.pieces.length) return no('block_unknown', 'there is no group ${i + 1}');
    final now = s.pieces[i];
    switch (action) {
      case SetVowelLine(:final line):
        if (now.line == line) return no('no_change', 'the line is there already');
        return put(i, SyllablePiece(line));
      case SetVowelDot(:final dot):
        if (now.line == null) return no('dot_without_line', 'a dot sits on a line: lay the line first');
        if (Hangul.vowelOf(now.line!, dot) == null) return no('dot_misplaced', 'a dot never sits there on that line');
        if (now.dot == dot) return no('no_change', 'the dot is there already');
        return put(i, SyllablePiece(now.line, dot));
      case ClearVowel():
        if (now.line == null) return no('no_change', 'the group is empty already');
        return put(i, const SyllablePiece());
    }
  }

  /// Group [i] as it is written now: its syllable once its vowel is built,
  /// else its first sound alone.
  String written(SyllableSpec spec, SyllableState s, int i) {
    final b = spec.blocks[i];
    final v = s.pieces[i].vowel;
    return v == null ? b.initial : Hangul.compose(b.initial, v, b.finalConsonant) ?? b.initial;
  }

  @override
  bool isComplete(SyllableSpec spec, SyllableState s) => s.pieces.every((p) => p.vowel != null);

  @override
  String answerOf(SyllableSpec spec, SyllableState s) => [for (var i = 0; i < spec.blocks.length; i++) written(spec, s, i)].join();

  @override
  String answer(SyllableSpec spec) => [for (final b in spec.blocks) Hangul.compose(b.initial, b.vowel, b.finalConsonant) ?? ''].join();

  /// The first group whose vowel is not the one written (null: none).
  int? firstProblem(SyllableSpec spec, SyllableState s) {
    for (var i = 0; i < spec.blocks.length; i++) {
      if (s.pieces[i].vowel != spec.blocks[i].vowel) return i;
    }
    return null;
  }

  @override
  SyllableState solved(SyllableSpec spec) => SyllableState([
    for (final b in spec.blocks)
      if (Hangul.partsOf(b.vowel) case (final line, final dot)) SyllablePiece(line, dot) else const SyllablePiece(),
  ]);

  @override
  Object? stateToJson(SyllableState s) => [
    for (final p in s.pieces) [p.line?.name, p.dot.name],
  ];

  @override
  SyllableState? stateFromJson(SyllableSpec spec, Object? json) {
    if (json is! List || json.length != spec.blocks.length) return null;
    final pieces = <SyllablePiece>[];
    for (final x in json) {
      if (x is! List || x.length != 2) return null;
      final line = x[0] == null ? null : VowelLine.values.where((v) => v.name == x[0]).firstOrNull;
      final dot = VowelDot.values.where((v) => v.name == x[1]).firstOrNull;
      if ((x[0] != null && line == null) || dot == null) return null;
      if (line == null ? dot != VowelDot.none : Hangul.vowelOf(line, dot) == null) return null;
      pieces.add(SyllablePiece(line, dot));
    }
    return SyllableState(pieces);
  }

  @override
  Object? structure(SyllableSpec spec) => [
    for (final b in spec.blocks) {'id': b.id, 'initial': b.initial, 'vowel': b.vowel, 'final': b.finalConsonant},
  ];

  @override
  Map<String, String> texts(SyllableSpec spec) => {for (final (i, b) in spec.blocks.indexed) 'blocks[$i].line': b.line};

  @override
  List<(String, String)> elementIds(SyllableSpec spec) => [for (final (i, b) in spec.blocks.indexed) ('\$.blocks[$i].id', b.id)];
}
