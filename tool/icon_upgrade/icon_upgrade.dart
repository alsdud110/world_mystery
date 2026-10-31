// The icon upgrade's pictures, made with OpenAI's Image API through the
// game's own `ImageStudio` (tool/ai_agents), then readied for `assets/`.
// docs/WORLD_MYSTERY_ICON_UPGRADE_PROGRESS.md. Nothing here is imported by the game.
//
//   dart run tool/icon_upgrade/icon_upgrade.dart estimate
//   dart run tool/icon_upgrade/icon_upgrade.dart generate [--only a,b] [--limit N] [--jobs 3] [--budget-usd 10]
//   dart run tool/icon_upgrade/icon_upgrade.dart prep [--only a,b]
//   dart run tool/icon_upgrade/icon_upgrade.dart manifest
//
// * Each picture has its own API record (`qa/icon_upgrade/api/<id>.json`,
//   gitignored): a picture already made, its raw file unchanged, is never
//   asked for again, so a stopped run carries on where it was.
// * At most [maxCalls] calls a picture (one retry after a failure).
// * Before every call the money already spent (the responses' usage at list
//   prices; a failed call counted at its estimate) plus this call's estimate
//   must stay within --budget-usd.
// * The key comes from OPENAI_API_KEY or `.env` (tool/ai_agents/env_file.dart)
//   and is never printed or written.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import '../ai_agents/env_file.dart';
import '../ai_agents/image_manifest.dart';
import '../ai_agents/image_pricing.dart';
import '../ai_agents/openai_image.dart';
import 'icon_plan.dart';

const model = 'gpt-image-1.5';
const quality = 'medium';
const size = '1024x1024';
/// Calls a picture may take: its first, one retry, and a last one on
/// another GPT image model where both of the first drew something else.
const maxCalls = 3;
const trackedManifest = 'content_pipeline/icon_upgrade/icon_asset_manifest.json';

String apiRecord(IconArt a) => 'qa/icon_upgrade/api/${a.id}.json';

/// The visual check (2026-11-01): every picture on the contact sheets
/// (`sheet`) and in the game's own tiles, stamps and close look.
const qaPass = 'pass: contact sheet and in-game tile/stamp check (2026-11-01)';
const qaNotes = {
  'ev.raven_tower_painting': 'pass: the tower and its ravens read at tile size; drawn without its gilded frame',
  'ev.orange_cat_hair': 'pass on call 2: call 1 read as a feather in tweezers',
  'ev.stone_nest': 'pass on call 2: call 1 looked like a well',
  'ev.seagull_photo': 'pass on call 2: both calls drew the man and the seagull rather than a print; kept, its subject is right',
  'ev.karl_old_photo': 'pass on call 3 (gpt-image-2): calls 1 and 2 (gpt-image-1.5) drew a magnifying glass',
  'sym.letter': 'pass on call 3 (gpt-image-2): calls 1 and 2 drew a skull and crossbones (never used)',
  'sym.ticket': 'pass on call 3 (gpt-image-2): calls 1 and 2 drew other things (never used)',
  'sym.cloth': 'pass on call 3 (gpt-image-2): calls 1 and 2 drew a badge and a bear (never used)',
  'sym.seal': 'pass on call 2: call 1 drew a landscape badge',
  'sym.frame': 'pass on call 2: call 1 added a skull (never used)',
  'doc.ticket': 'pass: small prints at both ends; the words go between them',
};

ImageRequest requestOf(IconArt a) => ImageRequest(
      prompt: '${a.subject[0].toUpperCase()}${a.subject.substring(1)}.\n\n${a.style ?? styles[a.kind]}',
      output: a.raw,
      model: a.model ?? model,
      size: size,
      quality: quality,
      // gpt-image-2 is asked on white; prep clears it.
      background: a.kind == IconArtKind.symbol || a.model != null ? 'opaque' : 'transparent',
      styleId: 'icon_upgrade_${a.kind.name}',
      subjectId: a.id,
    );

double estimateOf(IconArt a) {
  final r = requestOf(a);
  return ImagePricing.estimate(model: r.model, size: r.size, quality: r.quality, prompt: r.prompt)!;
}

/// What the API records say of [a]: calls made, made or not, and its cost.
({int calls, bool made, double spent, double? fromUsage}) recordOf(IconArt a) {
  final f = File(apiRecord(a));
  if (!f.existsSync()) return (calls: 0, made: false, spent: 0, fromUsage: null);
  final m = ImageManifest.load(f.path);
  var spent = 0.0;
  double? usage;
  var made = false;
  for (final e in m.entries.where((e) => e['apiCalled'] == true)) {
    final cost = e['cost'] as Map?;
    final u = (cost?['fromUsageUsd'] as num?)?.toDouble();
    spent += u ?? (cost?['estimatedUsd'] as num?)?.toDouble() ?? 0;
    if (e['status'] == 'generated') {
      made = File(a.raw).existsSync();
      usage = (usage ?? 0) + (u ?? 0);
    }
  }
  // Every call for this picture, whatever its prompt (a remade picture's
  // first prompt counts too).
  final calls = m.entries.where((e) => e['apiCalled'] == true).length;
  return (calls: calls, made: made, spent: spent, fromUsage: usage);
}

double spentSoFar() => plan.fold(0.0, (s, a) => s + recordOf(a).spent);

Future<void> main(List<String> args) async {
  if (args.isEmpty) _usage();
  final opts = _options(args.skip(1).toList());
  final only = opts['only']?.split(',').toSet();
  final items = [for (final a in plan) if (only == null || only.contains(a.id)) a];
  switch (args.first) {
    case 'estimate':
      final todo = items.where((a) => !recordOf(a).made).toList();
      final each = todo.isEmpty ? 0.0 : estimateOf(todo.first);
      final total = todo.fold(0.0, (s, a) => s + estimateOf(a));
      stdout.writeln('${items.length} planned, ${todo.length} still to make; ~${ImagePricing.usd(each)} each, '
          '${ImagePricing.usd(total)} estimated ($model, $size, $quality; list prices of ${ImagePricing.checkedOn})');
      stdout.writeln('spent so far: ${ImagePricing.usd(spentSoFar())}');
    case 'generate':
      // --redo a,b: pictures that failed the visual check, made again with
      // their corrected prompt (the first kept in qa/icon_upgrade/superseded/).
      for (final id in opts['redo']?.split(',') ?? const <String>[]) {
        final a = plan.firstWhere((a) => a.id == id);
        final raw = File(a.raw);
        if (!raw.existsSync()) continue;
        final keep = File('qa/icon_upgrade/superseded/${a.id}.${recordOf(a).calls}.png')..parent.createSync(recursive: true);
        raw.renameSync(keep.path);
        stdout.writeln('redo     ${a.id} (first kept: ${keep.path})');
      }
      await _generate(items, budget: double.parse(opts['budget-usd'] ?? '10'), jobs: int.parse(opts['jobs'] ?? '3'),
          limit: int.tryParse(opts['limit'] ?? ''));
    case 'prep':
      for (final a in items) {
        if (!File(a.raw).existsSync()) {
          stdout.writeln('skip     ${a.id}: not made yet');
          continue;
        }
        final out = prepare(img.decodePng(File(a.raw).readAsBytesSync())!, a.kind);
        File(a.asset)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(img.encodePng(out, level: 9));
        stdout.writeln('wrote    ${a.asset} ${out.width}x${out.height}');
      }
    case 'manifest':
      writeManifest();
    case 'sheet':
      // Contact sheets for the visual check, on the notebook's paper colour
      // (qa/icon_upgrade/sheet_<kind>.png): each picture large, and the
      // stamps also at their real size, tinted as the game tints them.
      for (final kind in IconArtKind.values) {
        final arts = items.where((a) => a.kind == kind && File(a.asset).existsSync()).toList();
        if (arts.isEmpty) continue;
        const tile = 200, cols = 6;
        final rows = (arts.length / cols).ceil();
        final sheet = img.Image(width: cols * tile, height: rows * (tile + 24), numChannels: 4);
        img.fill(sheet, color: img.ColorRgba8(0xF6, 0xEE, 0xDC, 255));
        for (final (i, a) in arts.indexed) {
          final x = (i % cols) * tile, y = (i ~/ cols) * (tile + 24);
          var p = img.decodePng(File(a.asset).readAsBytesSync())!;
          if (kind == IconArtKind.symbol) p = _tint(p, 0x2B, 0x3A, 0x67);
          final s = p.width > p.height ? 180 / p.width : 180 / p.height;
          final r = img.copyResize(p, width: (p.width * s).round(), height: (p.height * s).round(), interpolation: img.Interpolation.average);
          img.compositeImage(sheet, r, dstX: x + (tile - r.width) ~/ 2, dstY: y + (tile - r.height) ~/ 2);
          if (kind == IconArtKind.symbol) {
            final small = img.copyResize(p, width: 32, height: 32, interpolation: img.Interpolation.average);
            img.compositeImage(sheet, small, dstX: x + 4, dstY: y + 4);
          }
          img.drawString(sheet, a.id.split('.').last, font: img.arial14, x: x + 4, y: y + tile + 4, color: img.ColorRgba8(40, 30, 20, 255));
        }
        final out = 'qa/icon_upgrade/sheet_${kind.name}.png';
        File(out).writeAsBytesSync(img.encodePng(sheet));
        stdout.writeln('wrote    $out');
      }
    case 'footprint':
      // P0: the wet footprint's own picture (black, 2:3, shown in Case 03's
      // search) cut out for the evidence's round frame: no API call.
      const from = 'assets/seasons/season_01_london/objects/wet_footprint.png';
      const to = 'assets/seasons/season_01_london/objects/wet_footprint_cutout.png';
      final cut = _square(_trim(clearEdge(img.decodePng(File(from).readAsBytesSync())!, int.parse(opts['tolerance'] ?? '34'))), 512, margin: 0.05);
      File(to).writeAsBytesSync(img.encodePng(cut, level: 9));
      stdout.writeln('wrote    $to ${cut.width}x${cut.height}');
    default:
      _usage();
  }
}

Future<void> _generate(List<IconArt> items, {required double budget, required int jobs, int? limit}) async {
  final key = ApiKey.find();
  if (key == null) {
    stderr.writeln('no API key: OPENAI_API_KEY is in neither the environment nor .env');
    exit(2);
  }
  final todo = [
    for (final a in items)
      if (!recordOf(a).made && recordOf(a).calls < maxCalls) a,
  ].take(limit ?? items.length).toList();
  final skipped = items.where((a) => !recordOf(a).made && recordOf(a).calls >= maxCalls).map((a) => a.id).toList();
  if (skipped.isNotEmpty) stdout.writeln('not retried again (already $maxCalls calls): ${skipped.join(', ')}');
  stdout.writeln('${todo.length} to make, $jobs at a time; spent so far ${ImagePricing.usd(spentSoFar())} of ${ImagePricing.usd(budget)}');
  var reserved = 0.0;
  final queue = [...todo];
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final a = queue.removeAt(0);
      final est = estimateOf(a);
      // Reserved before the call, so parallel calls never pass the cap together.
      if (spentSoFar() + reserved + est > budget) {
        stdout.writeln('STOP     ${a.id}: ${ImagePricing.usd(spentSoFar() + reserved + est)} would pass ${ImagePricing.usd(budget)}');
        queue.clear();
        return;
      }
      reserved += est;
      final log = <String>[];
      final code = await ImageStudio(api: OpenAiImageApi(), findKey: () => key, log: log.add)
          .run(requestOf(a), generate: true, budgetUsd: 0.2, manifestPath: apiRecord(a));
      reserved -= est;
      stdout.writeln('${code == 0 ? 'ok      ' : 'FAILED  '} ${a.id}  ${log.where((l) => l.startsWith('cost') || l.startsWith('FAILED') || l.startsWith('error')).join(' | ')}');
    }
  }

  await Future.wait([for (var i = 0; i < jobs; i++) worker()]);
  stdout.writeln('spent so far ${ImagePricing.usd(spentSoFar())}');
}

/// The picture readied for the game.
img.Image prepare(img.Image src, IconArtKind kind) {
  var p = src.convert(numChannels: 4);
  switch (kind) {
    case IconArtKind.symbol:
      // Ink only: the darker, the more opaque; the app tints it.
      for (final c in p) {
        final l = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b).round();
        final a = ((255 - l) * 1.25).clamp(0, 255).round();
        c
          ..r = 0
          ..g = 0
          ..b = 0
          ..a = a < 24 ? 0 : a;
      }
      return _square(_trim(p), 256, margin: 0.04);
    case IconArtKind.object:
      if (_clearShare(p) < 0.05) p = clearEdge(p, 40);
      return _square(_trim(p), 512, margin: 0.06);
    case IconArtKind.ui:
      if (_clearShare(p) < 0.05) p = clearEdge(p, 40);
      return _square(_trim(p), 256, margin: 0.03);
    case IconArtKind.doc:
      if (_clearShare(p) < 0.05) p = clearEdge(p, 40);
      final t = _trim(p);
      final long = t.width > t.height ? t.width : t.height;
      return long <= 1024 ? t : img.copyResize(t, width: t.width * 1024 ~/ long, interpolation: img.Interpolation.average);
  }
}

img.Image _tint(img.Image p, int r, int g, int b) {
  final out = img.Image.from(p);
  for (final c in out) {
    c
      ..r = r
      ..g = g
      ..b = b;
  }
  return out;
}

double _clearShare(img.Image p) {
  var clear = 0;
  for (final c in p) {
    if (c.a < 8) clear++;
  }
  return clear / (p.width * p.height);
}

/// The picture cut to what is not (nearly) clear.
img.Image _trim(img.Image p) {
  var l = p.width, t = p.height, r = -1, b = -1;
  for (final c in p) {
    if (c.a > 16) {
      if (c.x < l) l = c.x;
      if (c.x > r) r = c.x;
      if (c.y < t) t = c.y;
      if (c.y > b) b = c.y;
    }
  }
  if (r < 0) return p;
  return img.copyCrop(p, x: l, y: t, width: r - l + 1, height: b - t + 1);
}

/// [p] centred on a clear square of [side], [margin] of it left round it.
img.Image _square(img.Image p, int side, {required double margin}) {
  final inner = (side * (1 - 2 * margin)).round();
  final scale = inner / (p.width > p.height ? p.width : p.height);
  final s = img.copyResize(p, width: (p.width * scale).round(), height: (p.height * scale).round(), interpolation: img.Interpolation.average);
  final out = img.Image(width: side, height: side, numChannels: 4);
  img.compositeImage(out, s, dstX: (side - s.width) ~/ 2, dstY: (side - s.height) ~/ 2);
  return out;
}

/// The background joined to the edge cleared (its colour within
/// [tolerance] of the corners' mean); the object keeps every pixel.
img.Image clearEdge(img.Image src, int tolerance) {
  final p = src.convert(numChannels: 4);
  final w = p.width, h = p.height;
  final corners = [p.getPixel(0, 0), p.getPixel(w - 1, 0), p.getPixel(0, h - 1), p.getPixel(w - 1, h - 1)];
  final br = corners.fold<num>(0, (s, c) => s + c.r) / 4, bg = corners.fold<num>(0, (s, c) => s + c.g) / 4;
  final bb = corners.fold<num>(0, (s, c) => s + c.b) / 4;
  bool near(img.Pixel c) => (c.r - br).abs() + (c.g - bg).abs() + (c.b - bb).abs() <= tolerance * 1.7;
  final seen = List<bool>.filled(w * h, false);
  final todo = <int>[];
  void push(int x, int y) {
    final i = y * w + x;
    if (seen[i]) return;
    seen[i] = true;
    if (near(p.getPixel(x, y))) todo.add(i);
  }

  for (var x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (todo.isNotEmpty) {
    final i = todo.removeLast();
    final x = i % w, y = i ~/ w;
    p.getPixel(x, y).a = 0;
    if (x > 0) push(x - 1, y);
    if (x < w - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < h - 1) push(x, y + 1);
  }
  return p;
}

/// The tracked record: every picture of the plan, made or reused.
void writeManifest() {
  final reused = jsonDecode(File('content_pipeline/icon_upgrade/reused.json').readAsStringSync()) as List;
  var total = 0.0;
  final entries = <Map<String, Object?>>[];
  for (final a in plan) {
    final r = recordOf(a);
    total += r.spent;
    final file = File(a.asset);
    final decoded = file.existsSync() ? img.decodePng(file.readAsBytesSync()) : null;
    entries.add({
      'id': a.id,
      'kind': a.kind.name,
      'file': a.asset,
      'usedBy': a.usedBy,
      'reused': false,
      'model': model,
      'size': size,
      'quality': quality,
      'background': requestOf(a).background,
      'apiCalls': r.calls,
      'generated': r.made,
      'inGame': file.existsSync(),
      if (decoded != null) 'pixels': '${decoded.width}x${decoded.height}',
      'estimatedUsd': ImagePricing.round(estimateOf(a)),
      'fromUsageUsd': r.fromUsage == null ? null : ImagePricing.round(r.fromUsage),
      'qa': a.qa ?? qaNotes[a.id] ?? qaPass,
    });
  }
  for (final e in reused) {
    entries.add({...(e as Map).cast<String, Object?>(), 'reused': true, 'apiCalls': 0, 'inGame': File(e['file'] as String).existsSync()});
  }
  final out = {
    'note': 'Icon upgrade pictures (docs/WORLD_MYSTERY_ICON_UPGRADE_PROGRESS.md). fromUsageUsd: the responses\' usage at '
        'OpenAI list prices of ${ImagePricing.checkedOn} (a failed call counted at its estimate in the total); the bill is OpenAI\'s.',
    'totals': {
      'planned': plan.length,
      'generated': plan.where((a) => recordOf(a).made).length,
      'apiCalls': plan.fold(0, (s, a) => s + recordOf(a).calls),
      'reusedPictures': reused.where((e) => (e as Map)['kind'] != 'rejected').length,
      'reusedEvidence': reused.fold(0, (s, e) => s + ((e as Map)['kind'] == 'rejected' ? 0 : (e['usedBy'] as List).length)),
      'rejectedReuse': reused.where((e) => (e as Map)['kind'] == 'rejected').length,
      'spentUsd': ImagePricing.round(total),
    },
    'entries': entries,
  };
  File(trackedManifest)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  stdout.writeln('wrote $trackedManifest: ${(out['totals'] as Map)}');
}

Map<String, String> _options(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--') || i + 1 >= args.length) _usage();
    out[args[i].substring(2)] = args[++i];
  }
  return out;
}

Never _usage() {
  stderr.writeln('usage: icon_upgrade.dart estimate|generate|prep|manifest [--only a,b] [--limit N] [--jobs 3] [--budget-usd 10]');
  exit(64);
}
