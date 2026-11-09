import 'puzzle_rules.dart';

/// The line a vowel is built on: the flat earth (ㅡ) or a person standing (ㅣ).
enum VowelLine { flat, standing }

/// Where the sky's dot (ㆍ) sits on its line, if it has one.
enum VowelDot { none, above, below, left, right }

/// One written group of a note (`syllable_compose`): its first sound
/// ([initial]), the vowel to build ([vowel]), the sound under it
/// ([finalConsonant], if any), the words that tell how it looked ([line]),
/// and whether it comes already written, as the player's example ([given]).
class SyllableBlock {
  const SyllableBlock({required this.id, required this.initial, required this.vowel, this.finalConsonant, required this.line, this.given = false});

  final String id;
  final String initial;
  final String vowel;
  final String? finalConsonant;
  final String line;
  final bool given;
}

/// A note written in the new letters, put back together group by group
/// (Puzzle Engine 2.0, `syllable_compose`): each group's vowel is built from
/// the three first shapes — the sky's dot, the flat earth, the standing
/// person — and joined with its sounds into one written syllable.
///
/// With [sounds], the player also chooses each group's first sound among
/// them, and the sound under it (one of the groups' [SyllableBlock.finalConsonant]s,
/// or none): nothing of a group is given. With [columnHeight], the groups
/// sit on the paper as the book wrote them — down the page, [columnHeight]
/// to a column, the first column on the right — and each place on the
/// paper is named by where it is, never by its group's number.
class SyllableSpec {
  const SyllableSpec({required this.blocks, this.sounds = const [], this.columnHeight, this.row = false, this.lastSounds = const [], this.voice});

  final List<SyllableBlock> blocks;

  /// The first sounds the player chooses from (empty: each group's is given).
  final List<String> sounds;

  /// Groups in a column, written down the page from the right (null: one row of groups).
  final int? columnHeight;

  /// The groups side by side, left to right, as words are written today
  /// (Seoul Case 01 V4): each named BLOCK 1, BLOCK 2…, its parts FIRST
  /// SOUND, VOWEL and LAST SOUND, and its sound shown as it is built.
  final bool row;

  /// The last sounds to choose from (empty: the groups' own, [bottoms]).
  final List<String> lastSounds;

  /// The whole word said aloud (a voice file), heard before it is built; null: none.
  final String? voice;

  SyllableBlock? block(String id) => blocks.where((b) => b.id == id).firstOrNull;

  /// Whether the player chooses each group's sounds (else they are given).
  bool get choosesSounds => sounds.isNotEmpty;

  /// The sounds that may sit under a group, in the note's order.
  List<String> get bottoms => lastSounds.isNotEmpty ? lastSounds : {for (final b in blocks) ?b.finalConsonant}.toList();

  /// Columns on the paper ([columnHeight] set).
  int get columns => columnHeight == null ? 1 : (blocks.length + columnHeight! - 1) ~/ columnHeight!;

  /// Group [i]'s column counted from the right, and its row from the top.
  (int column, int row) placeOf(int i) => columnHeight == null ? (0, i) : (i ~/ columnHeight!, i % columnHeight!);

  /// Group [i]'s place on the paper in words ("TOP RIGHT"), never its number.
  String placeName(int i) {
    if (this.row) return 'BLOCK ${i + 1}';
    final (c, r) = placeOf(i);
    final h = columnHeight ?? blocks.length;
    final row = switch ((h, r)) {
      (2, 0) || (3, 0) => 'TOP',
      (2, 1) || (3, 2) => 'BOTTOM',
      (3, 1) => 'MIDDLE',
      _ => 'ROW ${r + 1}',
    };
    final column = switch ((columns, c)) {
      (1, _) => '',
      (_, 0) => ' RIGHT',
      (2, 1) || (3, 2) => ' LEFT',
      (3, 1) => ' MIDDLE',
      _ => ' · COLUMN ${c + 1} FROM THE RIGHT',
    };
    return '$row$column';
  }
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
  /// [syllable] in the Revised Romanization of Korean (the official one),
  /// as a lone word: 엄 eom, 마 ma, 언 eon. A lone vowel letter reads as its
  /// vowel; a lone first sound, or anything else, as ''.
  static String reading(String syllable) {
    if (syllable.isEmpty) return '';
    if (vowels.contains(syllable)) return _vowelReadings[vowels.indexOf(syllable)];
    final code = syllable.runes.first - 0xAC00;
    if (syllable.runes.length != 1 || code < 0 || code > 11171) return '';
    return '${_initialReadings[code ~/ 588]}${_vowelReadings[code ~/ 28 % 21]}${_finalReadings[code % 28]}';
  }

  static const _initialReadings = ['g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp', 's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'];
  static const _vowelReadings = ['a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o', 'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu', 'eu', 'ui', 'i'];
  static const _finalReadings = ['', 'k', 'k', 'k', 'n', 'n', 'n', 't', 'l', 'k', 'm', 'l', 'l', 'l', 'p', 'l', 'm', 'p', 'p', 't', 't', 'ng', 't', 't', 'k', 't', 'p', 't'];

  static List<VowelDot> dotsFor(VowelLine line) =>
      line == VowelLine.flat ? const [VowelDot.above, VowelDot.below, VowelDot.none] : const [VowelDot.left, VowelDot.right, VowelDot.none];
}

/// One group as it is built: its line (null: none chosen yet) and its dot,
/// and — when the player chooses them ([SyllableSpec.sounds]) — its first
/// sound ([initial]) and the sound under it ([bottom]).
class SyllablePiece {
  const SyllablePiece([this.line, this.dot = VowelDot.none, this.initial, this.bottom]);

  final VowelLine? line;
  final VowelDot dot;
  final String? initial;
  final String? bottom;

  String? get vowel => line == null ? null : Hangul.vowelOf(line!, dot);

  SyllablePiece withVowel(VowelLine? line, [VowelDot dot = VowelDot.none]) => SyllablePiece(line, dot, initial, bottom);

  @override
  bool operator ==(Object other) => other is SyllablePiece && other.line == line && other.dot == dot && other.initial == initial && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(line, dot, initial, bottom);
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

/// Group [block]'s first sound chosen ([SyllableSpec.sounds] only).
class SetFirstSound extends SyllableAction {
  const SetFirstSound(this.block, this.sound);

  final int block;
  final String sound;
}

/// The sound under group [block] chosen, or taken away (null; [SyllableSpec.sounds] only).
class SetBottomSound extends SyllableAction {
  const SetBottomSound(this.block, this.sound);

  final int block;
  final String? sound;
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

  /// First sounds a player may choose from.
  static const soundChoices = (2, 9);

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
      if (b.line.trim().isEmpty) out.add(SpecIssue('field_missing', '$at.line', 'the words that tell how it looked'));
      if (spec.choosesSounds && !spec.sounds.contains(b.initial)) {
        out.add(SpecIssue('syllables_sound_missing', '$at.initial', '"${b.initial}" is not among the sounds to choose from'));
      }
    }
    if (spec.choosesSounds) {
      if (spec.sounds.length < soundChoices.$1 || spec.sounds.length > soundChoices.$2) {
        out.add(SpecIssue('syllables_sounds_size', r'$.sounds', '${spec.sounds.length} sound(s): ${soundChoices.$1} to ${soundChoices.$2}'));
      }
      for (final (i, s) in spec.sounds.indexed) {
        if (!Hangul.initials.contains(s)) out.add(SpecIssue('syllables_initial', '\$.sounds[$i]', '"$s" is no first sound of a syllable'));
      }
      if (spec.sounds.toSet().length != spec.sounds.length) out.add(const SpecIssue('syllables_sounds_duplicate', r'$.sounds', 'a sound is given twice'));
    }
    for (final (i, s) in spec.lastSounds.indexed) {
      if (!Hangul.finals.contains(s) || s.isEmpty) out.add(SpecIssue('syllables_final', '\$.lastSounds[$i]', '"$s" is no sound under a syllable'));
    }
    if (spec.lastSounds.isNotEmpty) {
      if (!spec.choosesSounds) out.add(const SpecIssue('syllables_last_sounds', r'$.lastSounds', 'last sounds are chosen only when first sounds are'));
      for (final (i, b) in spec.blocks.indexed) {
        if (b.finalConsonant case final f? when !spec.lastSounds.contains(f)) {
          out.add(SpecIssue('syllables_sound_missing', '\$.blocks[$i].final', '"$f" is not among the last sounds to choose from'));
        }
      }
    }
    if (spec.row && spec.columnHeight != null) out.add(const SpecIssue('syllables_columns', r'$.row', 'a row of blocks has no columns'));
    if (spec.columnHeight case final h? when h < 1 || h >= spec.blocks.length) {
      out.add(SpecIssue('syllables_columns', r'$.columnHeight', '$h group(s) to a column: 1 to ${spec.blocks.length - 1}, so the paper has two columns at least'));
    }
    return out;
  }

  @override
  SyllableState initial(SyllableSpec spec) => SyllableState([for (final b in spec.blocks) b.given ? _built(spec, b) : const SyllablePiece()]);

  /// [b] as it was written.
  SyllablePiece _built(SyllableSpec spec, SyllableBlock b) {
    final parts = Hangul.partsOf(b.vowel);
    if (parts == null) return const SyllablePiece();
    return SyllablePiece(parts.$1, parts.$2, spec.choosesSounds ? b.initial : null, spec.choosesSounds ? b.finalConsonant : null);
  }

  @override
  Applied<SyllableState> apply(SyllableSpec spec, SyllableState s, SyllableAction action) {
    Applied<SyllableState> no(String code, String why) => Applied.rejected(s, Rejection(code, why));
    Applied<SyllableState> put(int i, SyllablePiece p) => Applied.accepted(SyllableState([...s.pieces]..[i] = p));
    final i = switch (action) {
      SetVowelLine(:final block) || SetVowelDot(:final block) || SetFirstSound(:final block) || SetBottomSound(:final block) || ClearVowel(:final block) => block,
    };
    if (i < 0 || i >= s.pieces.length) return no('block_unknown', 'there is no group ${i + 1}');
    if (spec.blocks[i].given) return no('block_given', 'this group comes written');
    final now = s.pieces[i];
    switch (action) {
      case SetVowelLine(:final line):
        if (now.line == line) return no('no_change', 'the line is there already');
        return put(i, now.withVowel(line));
      case SetVowelDot(:final dot):
        if (now.line == null) return no('dot_without_line', 'a dot sits on a line: lay the line first');
        if (Hangul.vowelOf(now.line!, dot) == null) return no('dot_misplaced', 'a dot never sits there on that line');
        if (now.dot == dot) return no('no_change', 'the dot is there already');
        return put(i, now.withVowel(now.line, dot));
      case SetFirstSound(:final sound):
        if (!spec.choosesSounds || !spec.sounds.contains(sound)) return no('sound_unknown', 'that sound is not one to choose');
        if (now.initial == sound) return no('no_change', 'the sound is there already');
        return put(i, SyllablePiece(now.line, now.dot, sound, now.bottom));
      case SetBottomSound(:final sound):
        if (!spec.choosesSounds || (sound != null && !spec.bottoms.contains(sound))) return no('sound_unknown', 'that sound is not one to choose');
        if (now.bottom == sound) return no('no_change', 'the sound is there already');
        return put(i, SyllablePiece(now.line, now.dot, now.initial, sound));
      case ClearVowel():
        if (now == const SyllablePiece()) return no('no_change', 'the group is empty already');
        return put(i, const SyllablePiece());
    }
  }

  /// Group [i]'s first sound now: chosen, or given.
  String? firstSound(SyllableSpec spec, SyllableState s, int i) => spec.choosesSounds ? s.pieces[i].initial : spec.blocks[i].initial;

  /// The sound under group [i] now: chosen, or given.
  String? bottomSound(SyllableSpec spec, SyllableState s, int i) => spec.choosesSounds ? s.pieces[i].bottom : spec.blocks[i].finalConsonant;

  /// Group [i] as it is written now: its syllable once its sound and vowel
  /// are there, else what of it is (its first sound or its vowel alone; '' for nothing).
  String written(SyllableSpec spec, SyllableState s, int i) {
    final first = firstSound(spec, s, i);
    final v = s.pieces[i].vowel;
    if (first == null) return v ?? '';
    return v == null ? first : Hangul.compose(first, v, bottomSound(spec, s, i)) ?? first;
  }

  @override
  bool isComplete(SyllableSpec spec, SyllableState s) =>
      [for (var i = 0; i < s.pieces.length; i++) s.pieces[i].vowel != null && firstSound(spec, s, i) != null].every((x) => x);

  @override
  String answerOf(SyllableSpec spec, SyllableState s) => [for (var i = 0; i < spec.blocks.length; i++) written(spec, s, i)].join();

  @override
  String answer(SyllableSpec spec) => [for (final b in spec.blocks) Hangul.compose(b.initial, b.vowel, b.finalConsonant) ?? ''].join();

  /// The first group (in the note's order) not written as it was (null: none).
  int? firstProblem(SyllableSpec spec, SyllableState s) {
    for (var i = 0; i < spec.blocks.length; i++) {
      final b = spec.blocks[i];
      if (s.pieces[i].vowel != b.vowel || firstSound(spec, s, i) != b.initial || bottomSound(spec, s, i) != b.finalConsonant) return i;
    }
    return null;
  }

  @override
  SyllableState solved(SyllableSpec spec) => SyllableState([for (final b in spec.blocks) _built(spec, b)]);

  @override
  Object? stateToJson(SyllableState s) => [
    for (final p in s.pieces) [p.line?.name, p.dot.name, if (p.initial != null || p.bottom != null) ...[p.initial, p.bottom]],
  ];

  @override
  SyllableState? stateFromJson(SyllableSpec spec, Object? json) {
    if (json is! List || json.length != spec.blocks.length) return null;
    final pieces = <SyllablePiece>[];
    for (final x in json) {
      if (x is! List || (x.length != 2 && x.length != 4)) return null;
      final line = x[0] == null ? null : VowelLine.values.where((v) => v.name == x[0]).firstOrNull;
      final dot = VowelDot.values.where((v) => v.name == x[1]).firstOrNull;
      if ((x[0] != null && line == null) || dot == null) return null;
      if (line == null ? dot != VowelDot.none : Hangul.vowelOf(line, dot) == null) return null;
      String? initial, bottom;
      if (x.length == 4) {
        if (!spec.choosesSounds || x[2] is! String? || x[3] is! String?) return null;
        initial = x[2] as String?;
        bottom = x[3] as String?;
        if (initial != null && !spec.sounds.contains(initial)) return null;
        if (bottom != null && !spec.bottoms.contains(bottom)) return null;
      }
      // A save from before a group was given still shows it written.
      final b = spec.blocks[pieces.length];
      pieces.add(b.given ? _built(spec, b) : SyllablePiece(line, dot, initial, bottom));
    }
    return SyllableState(pieces);
  }

  /// [SyllableBlock.given] is left out: a level may give less, the game is the same.
  @override
  Object? structure(SyllableSpec spec) => {
    'blocks': [
      for (final b in spec.blocks) {'id': b.id, 'initial': b.initial, 'vowel': b.vowel, 'final': b.finalConsonant},
    ],
    'sounds': spec.sounds,
    'columnHeight': spec.columnHeight,
    if (spec.row) 'row': true,
    if (spec.lastSounds.isNotEmpty) 'lastSounds': spec.lastSounds,
  };

  @override
  Map<String, String> texts(SyllableSpec spec) => {for (final (i, b) in spec.blocks.indexed) 'blocks[$i].line': b.line};

  @override
  List<(String, String)> elementIds(SyllableSpec spec) => [for (final (i, b) in spec.blocks.indexed) ('\$.blocks[$i].id', b.id)];
}
