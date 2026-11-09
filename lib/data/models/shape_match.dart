// Plain Dart (no Flutter): the season generator's play check reads it too.

/// A picture a letter is laid on (`shape_match`): what part of the body it
/// shows, by its [name] (LIPS), and for screen readers ([label]).
class ShapePicture {
  const ShapePicture({required this.id, required this.file, required this.name, required this.label});

  final String id;
  final String file;
  final String name;
  final String label;
}

/// A letter tile of a [ShapeMatchSpec]: drawn by the app, never in a picture.
class ShapeLetter {
  const ShapeLetter({required this.id, required this.glyph});

  final String id;
  final String glyph;
}

/// Letters laid on the pictures they copy (Seoul Case 01 M2: ㅁ on the lips,
/// ㄴ on the tongue, ㅇ on the throat). The mission is a `matchPairs` whose
/// answer is `letter:picture` pairs; more letters than pictures, so a
/// guess rarely holds.
class ShapeMatchSpec {
  const ShapeMatchSpec({required this.pictures, required this.letters, required this.task});

  final List<ShapePicture> pictures;
  final List<ShapeLetter> letters;

  /// What to do, over the tiles.
  final String task;

  ShapeLetter letter(String id) => letters.firstWhere((l) => l.id == id);

  /// What is wrong with this spec for [answer] (`letter:picture` pairs);
  /// empty when it plays.
  List<String> problems(String answer) {
    final pictureIds = {for (final p in pictures) p.id};
    final letterIds = {for (final l in letters) l.id};
    final out = <String>[
      if (pictureIds.length != pictures.length) 'a picture id is given twice',
      if (letterIds.length != letters.length) 'a letter id is given twice',
      if (pictures.length < 2) 'two pictures at least',
      if (letters.length <= pictures.length) 'more letters than pictures, so a guess rarely holds',
    ];
    final pairs = [for (final p in answer.split(',')) p.trim().split(':')];
    final placed = <String>{};
    for (final p in pairs) {
      if (p.length != 2 || !letterIds.contains(p[0]) || !pictureIds.contains(p[1])) {
        out.add('"${p.join(':')}" is no letter:picture pair of the board');
      } else if (!placed.add(p[1])) {
        out.add('picture "${p[1]}" has two letters');
      }
    }
    if (placed.length != pictures.length) out.add('every picture has one letter in the answer');
    return out;
  }
}
