import 'dart:typed_data';

/// A real, decodable lossless WebP (VP8L) of [w]×[h] pixels of one colour,
/// made in plain Dart for the tests (no cwebp): no transform, no colour
/// cache, five prefix codes of one symbol each, so every pixel takes no
/// bits (WebP Lossless Bitstream, §3 and §6.2.1, "simple code").
Uint8List solidWebp(int w, int h, {int r = 90, int g = 120, int b = 150, int a = 255}) {
  final bits = <int>[];
  void put(int value, int n) {
    for (var i = 0; i < n; i++) {
      bits.add((value >> i) & 1);
    }
  }

  void simpleCode(int symbol) {
    put(1, 1); // simple code
    put(0, 1); // one symbol
    put(1, 1); // the symbol in 8 bits
    put(symbol, 8);
  }

  put(0x2F, 8); // signature
  put(w - 1, 14);
  put(h - 1, 14);
  put(a == 255 ? 0 : 1, 1); // alpha is used
  put(0, 3); // version
  put(0, 1); // no transform
  put(0, 1); // no colour cache
  put(0, 1); // no meta prefix codes
  simpleCode(g);
  simpleCode(r);
  simpleCode(b);
  simpleCode(a);
  simpleCode(0); // distance
  final data = Uint8List((bits.length + 7) ~/ 8);
  for (var i = 0; i < bits.length; i++) {
    data[i >> 3] |= bits[i] << (i & 7);
  }
  final padded = data.length.isOdd ? 1 : 0;
  final out = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_u32(4 + 8 + data.length + padded))
    ..add('WEBP'.codeUnits)
    ..add('VP8L'.codeUnits)
    ..add(_u32(data.length))
    ..add(data);
  if (padded == 1) out.addByte(0);
  return out.toBytes();
}

List<int> _u32(int v) => [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
