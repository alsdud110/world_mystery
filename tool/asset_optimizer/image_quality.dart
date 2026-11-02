import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// How far an encoded picture is from its source, measured on decoded pixels.
class QualityReport {
  const QualityReport({required this.psnr, required this.ssim, required this.alphaMaxDiff, required this.sameSize});

  /// Peak signal-to-noise ratio of R, G, B (dB), each premultiplied by its
  /// alpha: what the picture looks like over any background. 99 for identical.
  final double psnr;

  /// Mean structural similarity of the luma in 8×8 blocks (1 for identical).
  final double ssim;

  /// The largest difference of one pixel's alpha (0–255); 0 when both are opaque.
  final int alphaMaxDiff;

  final bool sameSize;

  Map<String, Object?> toJson() => {
    'psnr': double.parse(psnr.toStringAsFixed(2)),
    'ssim': double.parse(ssim.toStringAsFixed(5)),
    'alphaMaxDiff': alphaMaxDiff,
  };
}

/// Decodes pictures (PNG, WebP, JPEG) in plain Dart (`package:image`) and
/// compares them. The numbers are a gate, not a verdict: the pictures that
/// matter most are also looked at (comparison sheets).
abstract final class ImageQuality {
  /// [bytes] decoded as 8-bit RGBA, or a [FormatException].
  static img.Image decode(Uint8List bytes) {
    final im = img.decodeImage(bytes);
    if (im == null) throw const FormatException('the picture does not decode');
    return _rgba8(im);
  }

  /// [im] as 8-bit RGBA. `convert(alpha:)` sets the alpha of every pixel,
  /// so it is given only to a picture without alpha (opaque, then).
  static img.Image _rgba8(img.Image im) {
    if (im.format == img.Format.uint8 && im.numChannels == 4 && !im.hasPalette) return im;
    return im.hasAlpha ? im.convert(format: img.Format.uint8, numChannels: 4) : im.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
  }

  static QualityReport compare(img.Image source, img.Image encoded) {
    if (source.width != encoded.width || source.height != encoded.height) {
      return const QualityReport(psnr: 0, ssim: 0, alphaMaxDiff: 255, sameSize: false);
    }
    final a = _rgba(source), b = _rgba(encoded);
    final w = source.width, h = source.height, n = w * h;
    final la = Float64List(n), lb = Float64List(n);
    var se = 0.0;
    var alphaMax = 0;
    for (var i = 0, p = 0; i < n; i++, p += 4) {
      final aa = a[p + 3], ab = b[p + 3];
      alphaMax = math.max(alphaMax, (aa - ab).abs());
      final fa = aa / 255, fb = ab / 255;
      final ra = a[p] * fa, ga = a[p + 1] * fa, ba = a[p + 2] * fa;
      final rb = b[p] * fb, gb = b[p + 1] * fb, bb = b[p + 2] * fb;
      se += (ra - rb) * (ra - rb) + (ga - gb) * (ga - gb) + (ba - bb) * (ba - bb);
      la[i] = 0.299 * ra + 0.587 * ga + 0.114 * ba;
      lb[i] = 0.299 * rb + 0.587 * gb + 0.114 * bb;
    }
    final mse = se / (3 * n);
    final psnr = mse == 0 ? 99.0 : math.min(99.0, 10 * math.log(255 * 255 / mse) / math.ln10);
    return QualityReport(psnr: psnr, ssim: _ssim(la, lb, w, h), alphaMaxDiff: alphaMax, sameSize: true);
  }

  static Uint8List _rgba(img.Image im) => _rgba8(im).getBytes(order: img.ChannelOrder.rgba);

  static double _ssim(Float64List a, Float64List b, int w, int h) {
    const k = 8, c1 = 6.5025, c2 = 58.5225, n = k * k;
    var sum = 0.0;
    var blocks = 0;
    for (var by = 0; by + k <= h; by += k) {
      for (var bx = 0; bx + k <= w; bx += k) {
        var sa = 0.0, sb = 0.0, saa = 0.0, sbb = 0.0, sab = 0.0;
        for (var y = by; y < by + k; y++) {
          for (var x = bx, i = y * w + bx; x < bx + k; x++, i++) {
            final va = a[i], vb = b[i];
            sa += va;
            sb += vb;
            saa += va * va;
            sbb += vb * vb;
            sab += va * vb;
          }
        }
        final ma = sa / n, mb = sb / n;
        final varA = (saa - n * ma * ma) / (n - 1), varB = (sbb - n * mb * mb) / (n - 1), cov = (sab - n * ma * mb) / (n - 1);
        sum += ((2 * ma * mb + c1) * (2 * cov + c2)) / ((ma * ma + mb * mb + c1) * (varA + varB + c2));
        blocks++;
      }
    }
    return blocks == 0 ? 1 : sum / blocks;
  }

  /// Whether any pixel of [im] is not fully opaque.
  static bool usesAlpha(img.Image im) {
    if (!im.hasAlpha) return false;
    final px = _rgba(im);
    for (var p = 3; p < px.length; p += 4) {
      if (px[p] != 255) return true;
    }
    return false;
  }

  /// The structural similarity of two pictures' luma over mid grey, both
  /// shrunk to [side] on their long edge: how alike two pictures look
  /// (variants of one scene). Over grey, two shapes of one colour differ.
  static double likeness(img.Image a, img.Image b, {int side = 128}) {
    if (a.width != b.width || a.height != b.height) return 0;
    img.Image small(img.Image im) => img.copyResize(im, width: a.width >= a.height ? side : null, height: a.width >= a.height ? null : side, interpolation: img.Interpolation.average);
    final sa = small(a), sb = small(b);
    Float64List luma(img.Image im) {
      final px = _rgba(im);
      final out = Float64List(im.width * im.height);
      for (var i = 0, p = 0; i < out.length; i++, p += 4) {
        final f = px[p + 3] / 255;
        out[i] = (0.299 * px[p] + 0.587 * px[p + 1] + 0.114 * px[p + 2]) * f + 128 * (1 - f);
      }
      return out;
    }

    return _ssim(luma(sa), luma(sb), sa.width, sa.height);
  }
}
