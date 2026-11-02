import 'dart:io';

import 'package:image/image.dart' as img;

import 'image_policy.dart';
import 'image_quality.dart';
import 'optimized_ledger.dart';

/// Sheets to look at, the original beside the game's copy:
///
///     dart run tool/asset_optimizer/compare_sheet.dart [--out qa/asset_compare] <assets/….webp>...
///
/// One sheet a picture: both whole (shrunk to 480 px wide) over the most
/// detailed 160×160 of the picture at 3× (nearest pixels, so every artefact
/// shows), over grey so transparency shows too. Written outside the app
/// (`qa/` is not in Git); the original comes from `originalsDir`. The numbers
/// are on the sheet's file name; the look is a person's.
void main(List<String> args) {
  var out = 'qa/asset_compare';
  final paths = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) {
      out = args[++i];
    } else {
      paths.add(args[i].replaceAll(r'\', '/'));
    }
  }
  if (paths.isEmpty) {
    stderr.writeln('usage: dart run tool/asset_optimizer/compare_sheet.dart [--out <dir>] <assets/….webp>...');
    exit(64);
  }
  final policy = ImagePolicy.load();
  final ledger = OptimizedLedger.load();
  Directory(out).createSync(recursive: true);
  var failed = 0;
  for (final p in paths) {
    final e = ledger.of(p);
    if (e == null) {
      stderr.writeln('no record of $p in ${ledger.path}');
      failed++;
      continue;
    }
    final src = (e['source'] as Map)['path'] as String;
    final original = File('${policy.originalsDir}/${src.substring('assets/'.length)}');
    if (!original.existsSync()) {
      stderr.writeln('$p: its original is not at ${original.path}');
      failed++;
      continue;
    }
    final sheet = CompareSheet.of(ImageQuality.decode(original.readAsBytesSync()), ImageQuality.decode(File(p).readAsBytesSync()));
    final q = (e['quality'] as Map?) ?? const {};
    final name = '${p.substring('assets/'.length).replaceAll('/', '__').replaceAll('.webp', '')}'
        '__${e['setting'].toString().replaceAll(' ', '')}__psnr${q['psnr']}_ssim${q['ssim']}.png';
    File('$out/$name').writeAsBytesSync(img.encodePng(sheet));
    stdout.writeln('sheet    $out/$name');
  }
  exit(failed == 0 ? 0 : 1);
}

abstract final class CompareSheet {
  static const width = 480, crop = 160, zoom = 3, gap = 8;

  /// [a] (the original) beside [b] (the game's copy).
  static img.Image of(img.Image a, img.Image b) {
    final (x, y) = _busiest(a);
    img.Image whole(img.Image i) => _overGrey(img.copyResize(i, width: width, interpolation: img.Interpolation.average));
    img.Image zoomed(img.Image i) =>
        img.copyResize(_overGrey(img.copyCrop(i, x: x, y: y, width: crop, height: crop)), width: crop * zoom, interpolation: img.Interpolation.nearest);
    final wa = whole(a), wb = whole(b), za = zoomed(a), zb = zoomed(b);
    final colW = width > crop * zoom ? width : crop * zoom;
    final out = img.Image(width: colW * 2 + gap, height: wa.height + gap + za.height, numChannels: 3)..clear(img.ColorRgb8(255, 0, 255));
    img.compositeImage(out, wa);
    img.compositeImage(out, wb, dstX: colW + gap);
    img.compositeImage(out, za, dstY: wa.height + gap);
    img.compositeImage(out, zb, dstX: colW + gap, dstY: wa.height + gap);
    return out;
  }

  static img.Image _overGrey(img.Image i) {
    final bg = img.Image(width: i.width, height: i.height, numChannels: 3)..clear(img.ColorRgb8(128, 128, 128));
    return img.compositeImage(bg, i);
  }

  /// The top-left of the [crop]-square with the most luma variance.
  static (int, int) _busiest(img.Image a) {
    if (a.width <= crop || a.height <= crop) return (0, 0);
    final px = a.getBytes(order: img.ChannelOrder.rgba);
    double luma(int x, int y) {
      final p = (y * a.width + x) * 4;
      return (0.299 * px[p] + 0.587 * px[p + 1] + 0.114 * px[p + 2]) * px[p + 3] / 255;
    }

    var best = (0, 0);
    var bestVar = -1.0;
    final step = crop ~/ 2;
    for (var y = 0; y + crop <= a.height; y += step) {
      for (var x = 0; x + crop <= a.width; x += step) {
        var s = 0.0, ss = 0.0;
        var n = 0;
        for (var yy = y; yy < y + crop; yy += 4) {
          for (var xx = x; xx < x + crop; xx += 4) {
            final v = luma(xx, yy);
            s += v;
            ss += v * v;
            n++;
          }
        }
        final variance = ss / n - (s / n) * (s / n);
        if (variance > bestVar) {
          bestVar = variance;
          best = (x, y);
        }
      }
    }
    return best;
  }
}
