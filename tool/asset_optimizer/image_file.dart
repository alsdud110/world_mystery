import 'dart:io';
import 'dart:typed_data';

import '../ai_agents/png_check.dart';

/// The formats a picture of the game may be in.
enum ImageFormat {
  png('.png'),
  webp('.webp'),
  jpeg('.jpg');

  const ImageFormat(this.extension);

  /// The file name ending the game uses for it.
  final String extension;

  /// The format a file name says ([path]'s ending), or null.
  static ImageFormat? ofPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return png;
    if (p.endsWith('.webp')) return webp;
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return jpeg;
    return null;
  }
}

/// What a picture file is, read from its own bytes (never its name).
class ImageFileInfo {
  const ImageFileInfo({required this.format, required this.width, required this.height, required this.hasAlpha});

  final ImageFormat format;
  final int width;
  final int height;

  /// Whether the file can hold transparency (an alpha channel or plane).
  final bool hasAlpha;

  Map<String, Object?> toJson() => {'format': format.name, 'width': width, 'height': height, 'hasAlpha': hasAlpha};
}

/// Why bytes are not a picture the game can open.
class ImageFileProblem implements Exception {
  const ImageFileProblem(this.message);

  final String message;

  @override
  String toString() => 'not a valid picture: $message';
}

/// Reads a picture's container whole, whatever its format: a PNG as
/// [PngCheck] does (every chunk's CRC, the pixel data inflated); a WebP's
/// RIFF size, every chunk inside it, and the size and alpha its bitstream
/// header gives; a JPEG's markers up to its frame header. Decoding the pixels
/// is the caller's (`ImageQuality`, or the engine's codec in the tests).
abstract final class ImageFileCheck {
  static ImageFileInfo file(String path) => bytes(File(path).readAsBytesSync());

  static ImageFileInfo bytes(Uint8List b) {
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      try {
        final p = PngCheck.bytes(b);
        return ImageFileInfo(format: ImageFormat.png, width: p.width, height: p.height, hasAlpha: p.hasAlpha);
      } on PngProblem catch (e) {
        throw ImageFileProblem(e.message);
      }
    }
    if (b.length >= 12 && _ascii(b, 0, 4) == 'RIFF' && _ascii(b, 8, 4) == 'WEBP') return _webp(b);
    if (b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8) return _jpeg(b);
    throw const ImageFileProblem('neither PNG, WebP nor JPEG');
  }

  static String _ascii(Uint8List b, int at, int n) => String.fromCharCodes(b.sublist(at, at + n));

  static ImageFileInfo _webp(Uint8List b) {
    final d = ByteData.sublistView(b);
    final riff = d.getUint32(4, Endian.little);
    if (riff + 8 != b.length) throw ImageFileProblem('RIFF says ${riff + 8} bytes, the file has ${b.length}');
    int? width, height;
    var alpha = false, image = false;
    var at = 12;
    while (at < b.length) {
      if (at + 8 > b.length) throw ImageFileProblem('a chunk cut short at byte $at');
      final type = _ascii(b, at, 4);
      final size = d.getUint32(at + 4, Endian.little);
      final body = at + 8;
      if (body + size > b.length) throw ImageFileProblem('chunk $type runs past the end');
      switch (type) {
        case 'VP8X':
          if (size < 10) throw const ImageFileProblem('VP8X too short');
          alpha = (b[body] & 0x10) != 0;
          width = 1 + (b[body + 4] | b[body + 5] << 8 | b[body + 6] << 16);
          height = 1 + (b[body + 7] | b[body + 8] << 8 | b[body + 9] << 16);
        case 'VP8 ':
          if (size < 10 || b[body + 3] != 0x9D || b[body + 4] != 0x01 || b[body + 5] != 0x2A) {
            throw const ImageFileProblem('VP8 without its start code');
          }
          image = true;
          width ??= d.getUint16(body + 6, Endian.little) & 0x3FFF;
          height ??= d.getUint16(body + 8, Endian.little) & 0x3FFF;
        case 'VP8L':
          if (size < 5 || b[body] != 0x2F) throw const ImageFileProblem('VP8L without its signature');
          image = true;
          final bits = d.getUint32(body + 1, Endian.little);
          width ??= 1 + (bits & 0x3FFF);
          height ??= 1 + ((bits >> 14) & 0x3FFF);
          alpha = alpha || ((bits >> 28) & 1) == 1;
        case 'ALPH':
          alpha = true;
      }
      at = body + size + (size & 1);
    }
    if (at != b.length) throw const ImageFileProblem('the last chunk runs past the end');
    if (!image || width == null || height == null || width == 0 || height == 0) throw const ImageFileProblem('no image in the WebP');
    return ImageFileInfo(format: ImageFormat.webp, width: width, height: height, hasAlpha: alpha);
  }

  static ImageFileInfo _jpeg(Uint8List b) {
    var at = 2;
    while (at + 4 <= b.length) {
      if (b[at] != 0xFF) throw ImageFileProblem('no marker at byte $at');
      final marker = b[at + 1];
      if (marker == 0xD8 || (marker >= 0xD0 && marker <= 0xD7) || marker == 0x01 || marker == 0xFF) {
        at += marker == 0xFF ? 1 : 2;
        continue;
      }
      final length = (b[at + 2] << 8) | b[at + 3];
      if (at + 2 + length > b.length) throw const ImageFileProblem('a JPEG segment runs past the end');
      // SOF0–SOF15, less DHT (C4), JPG (C8) and DAC (CC).
      if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
        final h = (b[at + 5] << 8) | b[at + 6], w = (b[at + 7] << 8) | b[at + 8];
        if (w == 0 || h == 0) throw const ImageFileProblem('no pixels');
        if (b[b.length - 2] != 0xFF || b[b.length - 1] != 0xD9) throw const ImageFileProblem('no end of image');
        return ImageFileInfo(format: ImageFormat.jpeg, width: w, height: h, hasAlpha: false);
      }
      at += 2 + length;
    }
    throw const ImageFileProblem('no JPEG frame header');
  }
}
