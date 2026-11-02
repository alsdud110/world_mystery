import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'image_file.dart';
import 'image_policy.dart';
import 'image_quality.dart';
import 'webp_encoder.dart';

/// One picture as the game will store it, and how it was judged.
class OptimizeResult {
  const OptimizeResult({
    required this.bytes,
    required this.format,
    required this.kind,
    required this.setting,
    required this.quality,
    required this.sourceBytes,
    required this.width,
    required this.height,
    required this.hasAlpha,
    required this.tried,
    this.keptBecause,
  });

  final Uint8List bytes;
  final ImageFormat format;
  final String kind;

  /// The cwebp settings kept (`lossless` for exact pixels, `source` when the PNG stays).
  final String setting;
  final QualityReport quality;
  final int sourceBytes;
  final int width, height;
  final bool hasAlpha;

  /// The settings tried before it, each with why it was not kept.
  final List<String> tried;

  /// Why the source PNG stays as it is (only when the caller allows it).
  final String? keptBecause;

  bool get keptSource => keptBecause != null;

  Map<String, Object?> toJson() => {
    'kind': kind,
    'format': format.name,
    'setting': setting,
    'quality': quality.toJson(),
    'width': width,
    'height': height,
    'hasAlpha': hasAlpha,
    'tried': ?(tried.isEmpty ? null : tried),
    'keptBecause': ?keptBecause,
  };
}

/// Why a picture could not be optimized. Nothing was written for it.
class OptimizeFailure implements Exception {
  const OptimizeFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What makes the game's WebP of a PNG (the season pipeline takes any: the
/// tests give it one that needs no cwebp).
abstract interface class PictureOptimizer {
  /// The policy the kinds are named in.
  ImagePolicy get policy;

  /// [source] (a PNG) as the game will store it, by [kindName]'s policy;
  /// an [OptimizeFailure] when no setting makes a good picture.
  OptimizeResult optimize(Uint8List source, String kindName, {bool keepPngWhenSmaller = false});

  /// Which encoder, for the records.
  String get encoderVersion;
}

/// A PNG made into the WebP the game ships, by its kind's policy
/// (`image_policy.json`):
///
/// 1. The source must be a whole PNG that decodes (the API's format; a
///    lossy picture is never encoded again, so quality is never lost twice).
/// 2. Shrunk only when its kind has a `maxEdge` and it is larger.
/// 3. Each setting of the kind's ladder in turn, then lossless WebP: encoded,
///    read back whole (container, size, alpha), decoded and compared with
///    the source. The first that keeps the size, keeps alpha exactly and
///    passes the kind's PSNR and SSIM is the result.
/// 4. With [keepPngWhenSmaller], a result no smaller than its PNG leaves the
///    PNG as it is.
class ImageOptimizer implements PictureOptimizer {
  ImageOptimizer({required this.policy, required this.encoder});

  @override
  final ImagePolicy policy;
  final WebpEncoder encoder;

  @override
  String get encoderVersion => encoder.version;

  @override
  OptimizeResult optimize(Uint8List source, String kindName, {bool keepPngWhenSmaller = false}) {
    final kind = policy.kind(kindName);
    final ImageFileInfo info;
    try {
      info = ImageFileCheck.bytes(source);
    } on ImageFileProblem catch (e) {
      throw OptimizeFailure('the source is damaged: $e');
    }
    if (info.format != ImageFormat.png) {
      throw OptimizeFailure('the source is ${info.format.name}, not PNG: a lossy picture is never encoded again');
    }
    img.Image reference;
    try {
      reference = ImageQuality.decode(source);
    } on Object catch (e) {
      throw OptimizeFailure('the source does not decode: $e');
    }
    var input = source;
    final longEdge = math.max(reference.width, reference.height);
    if (kind.maxEdge > 0 && longEdge > kind.maxEdge) {
      final scale = kind.maxEdge / longEdge;
      reference = img.copyResize(
        reference,
        width: (reference.width * scale).round(),
        height: (reference.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
      input = img.encodePng(reference, level: 6);
    }
    final hasAlpha = ImageQuality.usesAlpha(reference);
    final tried = <String>[];
    final steps = [...kind.ladder, policy.losslessArgs];
    for (final (i, step) in steps.indexed) {
      final lossless = i == steps.length - 1;
      final name = lossless ? 'lossless' : step.join(' ');
      final Uint8List out;
      try {
        out = encoder.encode(input, [...policy.commonArgs, ...step]);
      } on WebpEncodeError catch (e) {
        tried.add('$name: $e');
        continue;
      }
      final String? problem;
      QualityReport? q;
      try {
        final got = ImageFileCheck.bytes(out);
        if (got.format != ImageFormat.webp) {
          problem = 'not WebP';
        } else if (got.width != reference.width || got.height != reference.height) {
          problem = '${got.width}x${got.height}, not ${reference.width}x${reference.height}';
        } else {
          q = ImageQuality.compare(reference, ImageQuality.decode(out));
          problem = !q.sameSize
              ? 'decoded at another size'
              : q.alphaMaxDiff != 0
              ? 'alpha changed (by up to ${q.alphaMaxDiff})'
              : lossless && q.psnr < 99
              ? 'lossless but not exact (PSNR ${q.psnr.toStringAsFixed(2)})'
              : !lossless && !kind.passes(q.psnr, q.ssim)
              ? 'PSNR ${q.psnr.toStringAsFixed(2)} / SSIM ${q.ssim.toStringAsFixed(4)} under ${kind.minPsnr} / ${kind.minSsim}'
              : null;
        }
      } on Object catch (e) {
        tried.add('$name: does not read back ($e)');
        continue;
      }
      if (problem != null) {
        tried.add('$name: $problem');
        continue;
      }
      final keep = keepPngWhenSmaller && out.length >= source.length && kind.maxEdge == 0;
      return OptimizeResult(
        bytes: keep ? source : out,
        format: keep ? ImageFormat.png : ImageFormat.webp,
        kind: kindName,
        setting: keep ? 'source' : name,
        quality: keep ? const QualityReport(psnr: 99, ssim: 1, alphaMaxDiff: 0, sameSize: true) : q!,
        sourceBytes: source.length,
        width: reference.width,
        height: reference.height,
        hasAlpha: hasAlpha,
        tried: tried,
        keptBecause: keep ? 'the WebP ($name, ${out.length} bytes) is not smaller than the PNG (${source.length} bytes)' : null,
      );
    }
    throw OptimizeFailure('no setting made a good picture: ${tried.join('; ')}');
  }
}
