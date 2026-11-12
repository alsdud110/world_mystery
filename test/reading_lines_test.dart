import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/utils/reading_lines.dart';

void main() {
  test('short sentences share a line', () {
    expect(readingLines('"Yes! Thank you, Mom!" says Bun-i.'), '"Yes! Thank you, Mom!" says Bun-i.');
    expect(readingLines('It fits! Well done.'), 'It fits! Well done.');
  });

  test('long sentences each start a line', () {
    expect(
      readingLines("Hello once more! You don't object to a little filming, do you? It's for the children!"),
      "Hello once more!\nYou don't object to a little filming, do you?\nIt's for the children!",
    );
    expect(
      readingLines('No. Bun-i is not leaving. She goes home tomorrow.'),
      'No. Bun-i is not leaving.\nShe goes home tomorrow.',
    );
  });

  test('only spaces between sentences change', () {
    const text =
        "Something glints in the shadow. A small golden key! ROOM 4 is cut into it. A tag on the key says: 'My next stop is where London's biggest bell rings.'";
    expect(readingLines(text).replaceAll('\n', ' '), text);
  });

  test('written breaks are kept and each line is broken on its own', () {
    expect(
      readingLines('Dear Detective {detectiveName},\n\nI took the Crown! Ha ha!\nThe sailors read the board every day. The King made it for them.'),
      'Dear Detective {detectiveName},\n\nI took the Crown! Ha ha!\nThe sailors read the board every day.\nThe King made it for them.',
    );
  });

  test('titles, initials, numbers and bold marks do not end a line', () {
    expect(readingLines('Mr. Hale is waiting at St. Paul\'s with Dr. Reed today.'), contains('Mr. Hale'));
    expect(readingLines('Mr. Hale is waiting at St. Paul\'s with Dr. Reed today.'), isNot(contains('\n')));
    expect(readingLines('The train left from platform No. 4 at a quarter past nine.'), isNot(contains('\n')));
    expect(readingLines('1. Open the box with the small golden key from Room 4.'), isNot(contains('\n')));
    expect(
      readingLines('There are **3 copies in the library.** Count the poems in each book again.'),
      'There are **3 copies in the library.**\nCount the poems in each book again.',
    );
    expect(readingLines('the letter said "a famous stone" and nothing else at all, detective'), isNot(contains('\n')));
  });
}
