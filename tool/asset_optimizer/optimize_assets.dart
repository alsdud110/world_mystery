import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../season_gen/sha256.dart';
import 'bundle_assets.dart';
import 'image_file.dart';
import 'image_optimizer.dart';
import 'image_policy.dart';
import 'image_quality.dart';
import 'optimized_ledger.dart';
import 'webp_encoder.dart';

/// The game's PNGs made into the WebP it ships (README.md):
///
///     dart run tool/asset_optimizer/optimize_assets.dart [--apply] [--only <assets/…png>]... [--area season_02_paris]...
///         [--jobs 6] [--cwebp <exe>]
///     dart run tool/asset_optimizer/optimize_assets.dart --rewrite-refs [--apply]
///     dart run tool/asset_optimizer/optimize_assets.dart --verify
///     dart run tool/asset_optimizer/optimize_assets.dart --restore <assets/….webp>...
///
/// * Without `--apply` nothing is written: each picture's kind and why.
/// * `--apply`: each bundled PNG (not kept by `image_policy.json` → `keep`)
///   backed up to `originalsDir` (outside the app, not in Git), optimized
///   (`ImageOptimizer`), written beside itself as `.part`, read back, moved
///   to `<name>.webp`, the PNG removed, the record kept in
///   `optimized_assets.json`. A failure leaves that picture as it was.
///   Run again: what is done is skipped, what was cut short is finished.
/// * `--rewrite-refs [--apply]`: every path naming a PNG that became WebP,
///   in `lib/`, `test/`, `integration_test/`, the season plans and
///   `pubspec.yaml`, made to name the WebP (generated files are made again
///   by their generators instead).
/// * `--verify`: every record against its file.
/// * `--restore`: a WebP undone, its original PNG put back from
///   `originalsDir` (checked against its record), the record removed.
///
/// Exit codes: 0 done; 1 a picture failed or a check found a problem; 64 usage.
Future<void> main(List<String> args) async {
  var apply = false, rewrite = false, verify = false;
  var jobs = 6;
  String? cwebp;
  final only = <String>{}, areas = <String>{}, restore = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--apply':
        apply = true;
      case '--rewrite-refs':
        rewrite = true;
      case '--verify':
        verify = true;
      case '--jobs' when i + 1 < args.length:
        jobs = int.parse(args[++i]);
      case '--cwebp' when i + 1 < args.length:
        cwebp = args[++i];
      case '--only' when i + 1 < args.length:
        only.add(args[++i].replaceAll(r'\', '/'));
      case '--area' when i + 1 < args.length:
        areas.add(args[++i]);
      case '--restore' when i + 1 < args.length:
        restore.add(args[++i].replaceAll(r'\', '/'));
      default:
        stderr.writeln('usage: optimize_assets.dart [--apply] [--only <path>]... [--area <area>]... [--jobs 6] [--cwebp <exe>] '
            '| --rewrite-refs [--apply] | --verify | --restore <assets/….webp>...');
        exit(64);
    }
  }
  final policy = ImagePolicy.load();
  final ledger = OptimizedLedger.load();
  if (verify) exit(verifyLedger('.', ledger).isEmpty ? 0 : 1);
  if (restore.isNotEmpty) {
    final r = AssetOptimizerRun(root: '.', policy: policy, ledger: ledger, encoder: null);
    final lines = [for (final w in restore) r.restore(w)];
    lines.forEach(stdout.writeln);
    exit(lines.any((l) => l.startsWith('error')) ? 1 : 0);
  }
  if (rewrite) {
    final r = RefRewriter.of('.', ledger);
    final changed = r.run(apply: apply);
    for (final f in changed) {
      stdout.writeln('${apply ? 'rewrote ' : 'rewrite '} $f');
    }
    for (final a in r.ambiguous) {
      stdout.writeln('AMBIGUOUS $a');
    }
    stdout.writeln('refs     ${changed.length} file(s) ${apply ? 'rewritten' : 'to rewrite (--apply writes them)'}; ${r.replaced} path(s)');
    exit(r.ambiguous.isEmpty ? 0 : 1);
  }
  final files = [
    for (final f in BundleAssets.list())
      if (f.extension == '.png' && (only.isEmpty || only.contains(f.path)) && (areas.isEmpty || areas.contains(f.area))) f.path,
  ];
  final encoder = CwebpEncoder.find(path: cwebp);
  if (encoder == null && apply) {
    stderr.writeln(CwebpEncoder.missing);
    exit(1);
  }
  final run = AssetOptimizerRun(root: '.', policy: policy, ledger: ledger, encoder: encoder, jobs: jobs);
  final kinds = await run.classify(files);
  if (!apply) {
    for (final p in files) {
      stdout.writeln('${(kinds[p]?.kind ?? 'kept').padRight(9)} $p${kinds[p]?.why == null ? '' : '  (${kinds[p]!.why})'}');
    }
    stdout.writeln('dry run  ${files.length} PNG(s); ${encoder?.version ?? 'no cwebp'}; nothing written (--apply)');
    exit(0);
  }
  final s = await run.optimize(files, kinds);
  exit(s.failed == 0 ? 0 : 1);
}

/// Why a picture has the kind it has.
typedef KindChoice = ({String kind, String why});

/// One run of the optimizer over existing game files.
class AssetOptimizerRun {
  AssetOptimizerRun({required this.root, required this.policy, required this.ledger, required this.encoder, this.jobs = 6, void Function(String)? log})
    : log = log ?? stdout.writeln;

  final String root;
  final ImagePolicy policy;
  final OptimizedLedger ledger;
  final WebpEncoder? encoder;
  final int jobs;
  final void Function(String) log;

  /// Each PNG's kind (a kept one has none): the season manifest's type and
  /// use where a manifest names the file, else its place in `assets/`; then
  /// any picture with a twin in its folder (`twins`) is a puzzle's.
  Future<Map<String, KindChoice>> classify(List<String> files) async {
    final manifest = _manifestKinds();
    final out = <String, KindChoice>{};
    for (final p in files) {
      if (policy.keepReason(p) != null) continue;
      final m = manifest[p];
      out[p] = m != null
          ? (kind: policy.kindOfManifest(type: m.type, use: m.use), why: 'manifest: ${m.type}/${m.use}')
          : (kind: policy.kindOfPath(p), why: policy.exactFiles.contains(p) ? 'exactFiles' : policy.puzzleFiles.contains(p) ? 'puzzleFiles' : 'path');
    }
    // Twins are looked for among every picture of the folder (made WebP
    // already or not), so a run of a few files judges them as a whole run does.
    final byDir = <String, Set<String>>{};
    for (final p in out.keys.where((p) => policy.twinKinds.contains(out[p]!.kind))) {
      final dir = p.substring(0, p.lastIndexOf('/'));
      byDir[dir] ??= {
        for (final f in Directory('$root/$dir').listSync().whereType<File>())
          if (ImageFormat.ofPath(f.path) case ImageFormat.png || ImageFormat.webp) '$dir/${f.uri.pathSegments.last}',
      };
    }
    final minLikeness = policy.twinLikeness, base = root;
    final groups = [for (final g in byDir.values) if (g.length > 1) g.toList()..sort()];
    final twins = await _pool(groups, (List<String> g) => _twinsJob(base, g, minLikeness));
    for (final found in twins) {
      for (final MapEntry(:key, :value) in found.entries) {
        final k = out[key];
        if (k != null && k.kind != 'puzzle') out[key] = (kind: 'puzzle', why: 'twin of ${value.$1.split('/').last} (likeness ${value.$2.toStringAsFixed(3)})');
      }
    }
    return out;
  }

  /// The game file [webp] undone: its original PNG put back (checked
  /// against its record), the WebP and its record removed. For a picture
  /// to be made again by another kind or policy. The line of what was done.
  String restore(String webp) {
    final e = ledger.of(webp);
    if (e == null) return 'error    $webp: no record of it';
    final src = (e['source'] as Map)['path'] as String;
    if (src == webp) return 'error    $webp: kept as PNG, nothing to undo';
    final original = File('$root/${policy.originalsDir}/${src.substring('assets/'.length)}');
    if (!original.existsSync() || _sha(original.readAsBytesSync()) != (e['source'] as Map)['sha256']) {
      return 'error    $webp: its original is not at ${original.path} as recorded (restore it from Git or a backup)';
    }
    final png = File('$root/$src');
    if (png.existsSync()) return 'error    $src is there already: nothing done';
    final part = File('${png.path}.part');
    original.copySync(part.path);
    part.renameSync(png.path);
    final w = File('$root/$webp');
    if (w.existsSync()) w.deleteSync();
    ledger
      ..entries.remove(webp)
      ..save();
    return 'restored $src from ${original.path}; $webp removed';
  }

  /// The files of [group] (one folder) with another of the same size at
  /// least [minLikeness] alike: each with its likest twin and the likeness.
  static Map<String, (String, double)> findTwins(String root, List<String> group, double minLikeness) {
    final decoded = <String, img.Image>{};
    for (final p in group) {
      try {
        decoded[p] = ImageQuality.decode(File('$root/$p').readAsBytesSync());
      } on Object {
        continue;
      }
    }
    final out = <String, (String, double)>{};
    final keys = decoded.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        final a = decoded[keys[i]]!, b = decoded[keys[j]]!;
        if (a.width != b.width || a.height != b.height) continue;
        final l = ImageQuality.likeness(a, b);
        if (l < minLikeness) continue;
        for (final (x, y) in [(keys[i], keys[j]), (keys[j], keys[i])]) {
          if ((out[x]?.$2 ?? -1) < l) out[x] = (y, l);
        }
      }
    }
    return out;
  }

  /// `assets/…` → the manifest's type and use, for every season planned.
  Map<String, ({String type, String use})> _manifestKinds() {
    final out = <String, ({String type, String use})>{};
    final dir = Directory('$root/content_pipeline/seasons');
    if (!dir.existsSync()) return out;
    for (final d in dir.listSync().whereType<Directory>()) {
      final f = File('${d.path}/assets.manifest.json');
      if (!f.existsSync()) continue;
      for (final a in ((jsonDecode(f.readAsStringSync()) as Map)['assets'] as List).cast<Map>()) {
        final path = a['outputPath'] as String;
        final png = path.endsWith('.webp') ? '${path.substring(0, path.length - 5)}.png' : path;
        out[png] = (type: a['type'] as String, use: a['use'] as String);
      }
    }
    return out;
  }

  Future<({int done, int kept, int skipped, int failed})> optimize(List<String> files, Map<String, KindChoice> kinds) async {
    var done = 0, kept = 0, skipped = 0, failed = 0;
    var before = 0, after = 0;
    final todo = <String>[];
    for (final p in files) {
      final k = kinds[p];
      if (k == null) {
        log('kept     $p: ${policy.keepReason(p)}');
        kept++;
        continue;
      }
      switch (_resume(p)) {
        case final String note:
          log(note);
          skipped++;
        case null:
          todo.add(p);
      }
    }
    final enc = encoder!, pol = policy, base = root;
    await _pool(todo, (String p) => _optimizeJob(pol, enc, base, p, kinds[p]!.kind), onDone: (r) {
      final (:path, :result, :error) = r;
      if (result == null) {
        failed++;
        log('FAILED   $path: $error (left as it is)');
        return;
      }
      try {
        if (_commit(path, kinds[path]!, result)) {
          done++;
          before += result.sourceBytes;
          after += result.bytes.length;
          log('webp     $path → ${result.kind} ${result.setting} ${(result.sourceBytes / 1024).round()} KB → '
              '${(result.bytes.length / 1024).round()} KB (PSNR ${result.quality.psnr.toStringAsFixed(1)}, SSIM ${result.quality.ssim.toStringAsFixed(4)})');
        } else {
          kept++;
          log('kept     $path: ${result.keptBecause}');
        }
      } on Object catch (e) {
        failed++;
        log('FAILED   $path: $e (left as it is)');
      }
    });
    log('done    $done optimized (${(before / 1048576).toStringAsFixed(1)} MB → ${(after / 1048576).toStringAsFixed(1)} MB), '
        '$kept kept as PNG, $skipped already done, $failed failed; ${encoder!.version}, policy ${policy.version}');
    return (done: done, kept: kept, skipped: skipped, failed: failed);
  }

  // Static, so the isolate's closure carries only its arguments (never this run).
  static Future<Map<String, (String, double)>> _twinsJob(String root, List<String> group, double minLikeness) =>
      Isolate.run(() => findTwins(root, group, minLikeness));

  static Future<({String path, OptimizeResult? result, String? error})> _optimizeJob(
    ImagePolicy policy,
    WebpEncoder encoder,
    String root,
    String path,
    String kind,
  ) => Isolate.run(() {
    try {
      final r = ImageOptimizer(policy: policy, encoder: encoder).optimize(File('$root/$path').readAsBytesSync(), kind, keepPngWhenSmaller: true);
      return (path: path, result: r, error: null);
    } on Object catch (e) {
      return (path: path, result: null, error: '$e');
    }
  });

  /// A picture already handled: its line, after finishing what was cut
  /// short; or null when it is still to do.
  String? _resume(String png) {
    final webp = '${png.substring(0, png.length - 4)}.webp';
    final pngFile = File('$root/$png'), webpFile = File('$root/$webp');
    final kept = ledger.of(png);
    if (kept != null && pngFile.existsSync() && (kept['source'] as Map)['sha256'] == _sha(pngFile.readAsBytesSync()) && kept['policyVersion'] == policy.version) {
      return 'done     $png: kept as PNG before (${kept['keptBecause']})';
    }
    if (!webpFile.existsSync()) return null;
    final e = ledger.of(webp);
    if (e == null || (e['output'] as Map)['sha256'] != _sha(webpFile.readAsBytesSync())) {
      return 'CONFLICT $webp is there and is not recorded as made from $png: both left as they are';
    }
    if (pngFile.existsSync()) {
      if ((e['source'] as Map)['sha256'] != _sha(pngFile.readAsBytesSync())) {
        return 'CONFLICT $png changed since $webp was made from it: both left as they are (remove one)';
      }
      _backup(png, pngFile.readAsBytesSync());
      pngFile.deleteSync();
      return 'finished $png → $webp (its PNG removed; the original is in ${policy.originalsDir})';
    }
    return 'done     $webp';
  }

  /// [r] written as the game's file. Whether a WebP replaced the PNG.
  bool _commit(String png, KindChoice k, OptimizeResult r) {
    final source = File('$root/$png').readAsBytesSync();
    final record = <String, Object?>{
      'source': {'path': png, 'sha256': _sha(source), 'bytes': source.length},
      'why': k.why,
      ...r.toJson(),
      'encoder': encoder!.version,
      'policyVersion': policy.version,
    };
    if (r.keptSource) {
      ledger
        ..put(png, {...record, 'output': {'path': png, 'sha256': _sha(source), 'bytes': source.length}})
        ..save();
      return false;
    }
    _backup(png, source);
    final webp = '${png.substring(0, png.length - 4)}.webp';
    final part = File('$root/$webp.part')..writeAsBytesSync(r.bytes, flush: true);
    final info = ImageFileCheck.file(part.path);
    if (info.format != ImageFormat.webp || info.width != r.width || info.height != r.height || _sha(part.readAsBytesSync()) != _sha(r.bytes)) {
      part.deleteSync();
      throw StateError('the written WebP does not read back as made');
    }
    part.renameSync('$root/$webp');
    ledger
      ..put(webp, {...record, 'output': {'path': webp, 'sha256': _sha(r.bytes), 'bytes': r.bytes.length}})
      ..save();
    File('$root/$png').deleteSync();
    return true;
  }

  /// [bytes] kept at `originalsDir/<png>` (never over another file).
  void _backup(String png, Uint8List bytes) {
    final f = File('$root/${policy.originalsDir}/${png.substring('assets/'.length)}');
    if (f.existsSync()) {
      if (_sha(f.readAsBytesSync()) != _sha(bytes)) throw StateError('${f.path} is another picture: not written over');
      return;
    }
    f.parent.createSync(recursive: true);
    final part = File('${f.path}.part')..writeAsBytesSync(bytes, flush: true);
    if (_sha(part.readAsBytesSync()) != _sha(bytes)) {
      part.deleteSync();
      throw StateError('the original could not be kept at ${f.path}');
    }
    part.renameSync(f.path);
  }

  /// [items] through [work], [jobs] at a time, in order.
  Future<List<R>> _pool<T, R>(List<T> items, Future<R> Function(T) work, {void Function(R)? onDone}) async {
    final out = List<R?>.filled(items.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < items.length) {
        final i = next++;
        final r = await work(items[i]);
        out[i] = r;
        onDone?.call(r);
      }
    }

    await Future.wait([for (var i = 0; i < (jobs < 1 ? 1 : jobs); i++) worker()]);
    return out.cast<R>();
  }
}

String _sha(List<int> bytes) => 'sha256:${Sha256.hex(bytes)}';

/// Every record against its file: the problems found (none: all as recorded).
List<String> verifyLedger(String root, OptimizedLedger ledger, {void Function(String)? log}) {
  final say = log ?? stdout.writeln;
  final problems = <String>[];
  for (final MapEntry(:key, :value) in ledger.entries.entries) {
    final f = File('$root/$key');
    if (!f.existsSync()) {
      problems.add('$key: missing');
    } else if (_sha(f.readAsBytesSync()) != (value['output'] as Map)['sha256']) {
      problems.add('$key: changed since it was made');
    } else {
      try {
        final info = ImageFileCheck.file(f.path);
        if (info.width != value['width'] || info.height != value['height']) problems.add('$key: ${info.width}x${info.height}, recorded ${value['width']}x${value['height']}');
      } on ImageFileProblem catch (e) {
        problems.add('$key: $e');
      }
    }
    final src = (value['source'] as Map)['path'] as String;
    if (src != key && File('$root/$src').existsSync()) problems.add('$src: still there beside $key');
  }
  for (final p in problems) {
    say('PROBLEM  $p');
  }
  say('verify   ${ledger.entries.length} record(s), ${problems.isEmpty ? 'all as recorded' : '${problems.length} problem(s)'}');
  return problems;
}

/// Rewrites the paths naming a PNG that became a WebP.
///
/// A path is read as the run of path characters before `.png`; it names
/// the PNGs whose path ends with it (an interpolated path keeps only its
/// literal end, so the first segment may be dropped until it names any).
/// It is rewritten only when every PNG it can name became a WebP; one that
/// could name a PNG still there (a kept one, an original outside the app)
/// is listed as ambiguous and left.
class RefRewriter {
  RefRewriter._(this.root, this.renamed, this.universe);

  final String root;

  /// Source PNG → its WebP.
  final Map<String, String> renamed;

  /// Every PNG path there is or was under `assets/`.
  final Set<String> universe;
  final ambiguous = <String>[];
  var replaced = 0;

  /// Folders and files scanned; generated code is made again by its generator.
  static const scanned = ['lib', 'test', 'integration_test', 'content_pipeline/seasons'];
  static const skipped = ['lib/data/generated/', 'test/sandbox/generated/'];

  static RefRewriter of(String root, OptimizedLedger ledger) {
    final renamed = ledger.renamed;
    final universe = {...renamed.keys};
    final assets = Directory('$root/assets');
    if (assets.existsSync()) {
      for (final f in assets.listSync(recursive: true).whereType<File>()) {
        final rel = f.path.substring(root.length + 1).replaceAll(r'\', '/');
        if (rel.toLowerCase().endsWith('.png')) universe.add(rel);
      }
    }
    return RefRewriter._(root, renamed, universe);
  }

  static final _token = RegExp(r'[A-Za-z0-9_./-]*\.png(?![A-Za-z0-9_])');

  /// A line that names a picture's source PNG on purpose says so with this
  /// text (in a comment): it is never rewritten.
  static const keepMarker = 'source PNG';

  /// [text] with its paths rewritten; [where] names it in the ambiguous list.
  /// The first segment is dropped only after `$` or `}` (the end of a
  /// variable's name): `raw/cover/x.png` (a work file) is never read as
  /// `cover/x.png`.
  String rewrite(String text, String where) => text.replaceAllMapped(_token, (m) {
    final lineStart = text.lastIndexOf('\n', m.start) + 1;
    final lineEnd = text.indexOf('\n', m.end);
    if (text.substring(lineStart, lineEnd < 0 ? text.length : lineEnd).contains(keepMarker)) return m[0]!;
    var t = m[0]!;
    if (t.startsWith('./')) t = t.substring(2);
    final interpolated = m.start > 0 && (text[m.start - 1] == r'$' || text[m.start - 1] == '}');
    var segments = t.split('/');
    for (var drop = 0; drop <= (interpolated ? 1 : 0) && segments.isNotEmpty; drop++) {
      final suffix = segments.join('/');
      final names = [for (final u in universe) if (u == suffix || u.endsWith(suffix.startsWith('/') ? suffix : '/$suffix')) u];
      if (names.isNotEmpty) {
        if (names.every(renamed.containsKey)) {
          replaced++;
          return '${m[0]!.substring(0, m[0]!.length - 4)}.webp';
        }
        if (names.any(renamed.containsKey)) ambiguous.add('$where: ${m[0]} could name ${names.join(', ')}');
        return m[0]!;
      }
      segments = segments.sublist(1);
    }
    return m[0]!;
  });

  /// The files changed (written with [apply]).
  List<String> run({bool apply = false}) {
    final changed = <String>[];
    final files = <File>[
      for (final d in scanned)
        if (Directory('$root/$d').existsSync())
          for (final f in Directory('$root/$d').listSync(recursive: true).whereType<File>())
            if (f.path.endsWith('.dart') || f.path.endsWith('.json')) f,
      File('$root/pubspec.yaml'),
    ];
    for (final f in files) {
      final rel = f.path.substring(root.length + 1).replaceAll(r'\', '/');
      if (skipped.any(rel.startsWith) || rel.startsWith('content_pipeline/asset_work/')) continue;
      final text = f.readAsStringSync();
      final out = rewrite(text, rel);
      if (out == text) continue;
      changed.add(rel);
      if (apply) f.writeAsStringSync(out);
    }
    return changed;
  }
}
