import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/asset_optimizer/asset_size_report.dart';
import '../../tool/asset_optimizer/bundle_assets.dart';
import '../../tool/asset_optimizer/image_file.dart';
import '../../tool/asset_optimizer/image_optimizer.dart';
import '../../tool/asset_optimizer/image_policy.dart';
import '../../tool/asset_optimizer/image_quality.dart';
import '../../tool/asset_optimizer/optimize_assets.dart';
import '../../tool/asset_optimizer/optimized_ledger.dart';
import '../../tool/asset_optimizer/webp_encoder.dart';
import 'webp_fixture.dart';

/// The asset optimizer (tool/asset_optimizer): the game's PNGs made into
/// WebP by kind, checked, recorded, and never encoded twice. No call to any
/// image API. The tests that encode for real need Google's cwebp (libwebp,
/// tool/asset_optimizer/README.md); without it they say so and are skipped,
/// and the fake encoders below still check every failure path.
void main() {
  final cwebp = CwebpEncoder.find();
  final noCwebp = cwebp == null ? 'cwebp is not installed on this machine (${CwebpEncoder.missing})' : null;
  final policy = ImagePolicy.load();

  group('reading picture files (ImageFileCheck)', () {
    test('PNG, WebP and JPEG read from their own bytes; a damaged one refused', () {
      final png = _scenePng(40, 30);
      expect(ImageFileCheck.bytes(png).toJson(), {'format': 'png', 'width': 40, 'height': 30, 'hasAlpha': false});
      expect(ImageFileCheck.bytes(solidWebp(1024, 1536)).toJson(), {'format': 'webp', 'width': 1024, 'height': 1536, 'hasAlpha': false});
      expect(ImageFileCheck.bytes(solidWebp(7, 3, a: 100)).hasAlpha, isTrue);
      final jpg = img.encodeJpg(img.decodePng(png)!);
      expect(ImageFileCheck.bytes(jpg).toJson(), {'format': 'jpeg', 'width': 40, 'height': 30, 'hasAlpha': false});
      expect(() => ImageFileCheck.bytes(Uint8List.sublistView(png, 0, png.length - 20)), throwsA(isA<ImageFileProblem>()));
      expect(() => ImageFileCheck.bytes(Uint8List.sublistView(solidWebp(9, 9), 0, 30)), throwsA(isA<ImageFileProblem>()));
      expect(() => ImageFileCheck.bytes(Uint8List.fromList(utf8.encode('not a picture'))), throwsA(isA<ImageFileProblem>()));
      expect(ImageFormat.ofPath('assets/x/y.webp'), ImageFormat.webp);
    });
  });

  group('the policy (image_policy.json)', () {
    test('read whole: every kind has a ladder and a gate, or is lossless only; the default is the most careful kind', () {
      expect(policy.kinds.keys, containsAll(['scene', 'character', 'ui', 'evidence', 'document', 'glyph', 'puzzle']));
      expect(policy.defaultKind, 'puzzle');
      for (final k in policy.kinds.values) {
        expect(k.ladder.isNotEmpty || k.minPsnr >= 99, isTrue, reason: '${k.name}: a ladder, or lossless only');
        expect(k.minSsim, inInclusiveRange(0.9, 1.0), reason: k.name);
      }
      expect(policy.kind('glyph').ladder, isEmpty, reason: 'the stamps the game tints: exact pixels');
      expect(policy.kindOfPath('assets/shared/symbols/symbol_key.png'), 'glyph'); // a source PNG, classified
      expect(policy.kind('puzzle').ladder.expand((s) => s), isNot(contains('-q')), reason: 'a puzzle picture: near-lossless at most');
      expect(policy.losslessArgs, contains('-lossless'));
      expect(policy.commonArgs, containsAll(['-alpha_q', '100']), reason: 'alpha always kept exactly');
    });

    test('a kind from the season manifest first (its type and use), else from the path; unknown: the careful default', () {
      expect(policy.kindOfManifest(type: 'object', use: 'puzzle'), 'puzzle');
      expect(policy.kindOfManifest(type: 'document', use: 'puzzle'), 'document');
      expect(policy.kindOfManifest(type: 'place', use: 'seasonPlace'), 'scene');
      expect(policy.kindOfManifest(type: 'character', use: 'notWired'), 'character');
      expect(policy.kindOfManifest(type: 'something new', use: 'x'), 'puzzle');
      expect(policy.kindOfPath('assets/shared/badges/badge_first_clue.webp'), 'ui');
      expect(policy.kindOfPath('assets/seasons/season_02_paris/cases/case_04/hands_sign.webp'), 'puzzle', reason: 'listed in puzzleFiles');
      expect(policy.kindOfPath('assets/seasons/season_09_x/somewhere/new.png'), 'puzzle');
      expect(policy.keepReason('assets/branding/splash_logo.png'), isNotNull);
    });
  });

  group('optimizing one picture (cwebp)', () {
    late ImageOptimizer optimizer;
    setUp(() => optimizer = ImageOptimizer(policy: policy, encoder: cwebp!));

    test('a background PNG becomes a smaller WebP of the same size, within its kind\'s gate', () {
      final png = _scenePng(320, 200);
      final r = optimizer.optimize(png, 'scene');
      expect(r.format, ImageFormat.webp);
      expect(r.bytes.length, lessThan(png.length));
      final info = ImageFileCheck.bytes(r.bytes);
      expect((info.format, info.width, info.height), (ImageFormat.webp, 320, 200));
      final q = ImageQuality.compare(ImageQuality.decode(png), ImageQuality.decode(r.bytes));
      expect(q.psnr, greaterThanOrEqualTo(policy.kind('scene').minPsnr));
      expect(q.ssim, greaterThanOrEqualTo(policy.kind('scene').minSsim));
      expect([for (final s in policy.kind('scene').ladder) s.join(' ')], contains(r.setting), reason: 'one of the scene\'s own settings');
    }, skip: noCwebp);

    test('a transparent PNG keeps its alpha, every pixel of it', () {
      final png = _cutoutPng(160, 160);
      final r = optimizer.optimize(png, 'ui');
      expect(r.hasAlpha, isTrue);
      expect(ImageFileCheck.bytes(r.bytes).hasAlpha, isTrue);
      final a = ImageQuality.decode(png), b = ImageQuality.decode(r.bytes);
      for (var y = 0; y < 160; y += 3) {
        for (var x = 0; x < 160; x += 3) {
          expect(b.getPixel(x, y).a, a.getPixel(x, y).a, reason: 'alpha at $x,$y');
        }
      }
      expect(ImageQuality.compare(a, b).alphaMaxDiff, 0);
    }, skip: noCwebp);

    test('a puzzle picture: near-lossless at most, no pixel moved more than a few levels', () {
      final png = _scenePng(200, 120, marks: true);
      final r = optimizer.optimize(png, 'puzzle');
      expect(r.setting, anyOf(startsWith('-near_lossless'), 'lossless'));
      final a = ImageQuality.decode(png), b = ImageQuality.decode(r.bytes);
      var worst = 0;
      for (final p in a) {
        final q = b.getPixel(p.x, p.y);
        worst = math.max(worst, math.max((p.r - q.r).abs().toInt(), math.max((p.g - q.g).abs().toInt(), (p.b - q.b).abs().toInt())));
      }
      expect(worst, lessThanOrEqualTo(8), reason: 'near-lossless bounds each pixel\'s change');
      expect(ImageQuality.compare(a, b).psnr, greaterThanOrEqualTo(policy.kind('puzzle').minPsnr));
    }, skip: noCwebp);

    test('a kind with a maxEdge: shrunk to it, proportions kept, judged against the shrunk picture', () {
      final json = jsonDecode(File(ImagePolicy.defaultPath).readAsStringSync()) as Map<String, Object?>;
      ((json['kinds'] as Map)['scene'] as Map)['maxEdge'] = 80;
      final small = ImageOptimizer(policy: ImagePolicy.fromJson(json), encoder: cwebp!).optimize(_scenePng(320, 200), 'scene');
      expect((small.width, small.height), (80, 50));
      expect(ImageFileCheck.bytes(small.bytes).width, 80);
    }, skip: noCwebp);

    test('the same picture made twice: the same bytes (a rerun writes nothing new)', () {
      final png = _cutoutPng(96, 96);
      expect(optimizer.optimize(png, 'ui').bytes, optimizer.optimize(png, 'ui').bytes);
    }, skip: noCwebp);
  });

  group('optimizing one picture: what is refused', () {
    test('a damaged PNG: refused before any encoding', () {
      final enc = _CountingEncoder();
      final png = _scenePng(40, 30);
      expect(
        () => ImageOptimizer(policy: policy, encoder: enc).optimize(Uint8List.sublistView(png, 0, png.length ~/ 2), 'scene'),
        throwsA(isA<OptimizeFailure>().having((e) => e.message, 'message', contains('damaged'))),
      );
      expect(enc.calls, 0);
    });

    test('a picture already lossy (WebP, JPEG) is never encoded again', () {
      final enc = _CountingEncoder();
      final o = ImageOptimizer(policy: policy, encoder: enc);
      expect(() => o.optimize(solidWebp(20, 20), 'scene'), throwsA(isA<OptimizeFailure>().having((e) => e.message, 'message', contains('never encoded again'))));
      expect(() => o.optimize(img.encodeJpg(img.decodePng(_scenePng(20, 20))!), 'scene'), throwsA(isA<OptimizeFailure>()));
      expect(enc.calls, 0);
    });

    test('an encoder that fails, or answers another picture: each setting tried, then a failure naming them', () {
      final failing = _CountingEncoder(fail: true);
      expect(() => ImageOptimizer(policy: policy, encoder: failing).optimize(_scenePng(40, 30), 'scene'),
          throwsA(isA<OptimizeFailure>().having((e) => e.message, 'message', contains('lossless'))));
      expect(failing.calls, policy.kind('scene').ladder.length + 1);
      final wrongSize = _CountingEncoder(answer: solidWebp(39, 30));
      expect(() => ImageOptimizer(policy: policy, encoder: wrongSize).optimize(_scenePng(40, 30), 'scene'),
          throwsA(isA<OptimizeFailure>().having((e) => e.message, 'message', contains('39x30'))));
    });

    test('a result that loses detail fails the gate; lossless must be exact', () {
      // The encoder answers one flat colour, of the right size, for every setting.
      final flat = _CountingEncoder(answer: solidWebp(40, 30));
      expect(() => ImageOptimizer(policy: policy, encoder: flat).optimize(_scenePng(40, 30), 'scene'),
          throwsA(isA<OptimizeFailure>().having((e) => e.message, 'message', allOf(contains('PSNR'), contains('lossless but not exact')))));
    });
  });

  group('the existing pictures (optimize_assets) on a temporary project', () {
    late Directory tmp;
    late List<String> log;
    const folder = 'assets/seasons/season_09_test/cases/case_01';
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('asset_optimizer');
      log = [];
      File('${tmp.path}/pubspec.yaml').writeAsStringSync('name: x\nflutter:\n  assets:\n    - $folder/\n');
      File('${tmp.path}/$folder/scene.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(_scenePng(240, 160));
      File('${tmp.path}/$folder/cutout.png').writeAsBytesSync(_cutoutPng(120, 120));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    String root() => tmp.path.replaceAll(r'\', '/');
    OptimizedLedger ledger() => OptimizedLedger.load('${tmp.path}/ledger.json');
    AssetOptimizerRun run(WebpEncoder encoder) =>
        AssetOptimizerRun(root: root(), policy: policy, ledger: ledger(), encoder: encoder, jobs: 2, log: log.add);
    List<String> files() => [for (final f in Directory(tmp.path).listSync(recursive: true).whereType<File>()) f.path.replaceAll(r'\', '/').substring(root().length + 1)]..sort();
    Future<void> optimize(WebpEncoder encoder) async {
      final r = run(encoder);
      final pngs = [for (final f in BundleAssets.list(root: root())) if (f.extension == '.png') f.path];
      await r.optimize(pngs, await r.classify(pngs));
    }

    test('--apply: WebP beside, the PNG kept outside the app then removed, recorded; again: nothing new, nothing encoded', () async {
      final scene = File('${tmp.path}/$folder/scene.png').readAsBytesSync();
      final counting = _CountingEncoder(through: cwebp);
      await optimize(counting);
      expect(log.join('\n'), contains('2 optimized'));
      expect(files(), [
        '$folder/cutout.webp',
        '$folder/scene.webp',
        'content_pipeline/asset_originals/seasons/season_09_test/cases/case_01/cutout.png',
        'content_pipeline/asset_originals/seasons/season_09_test/cases/case_01/scene.png',
        'ledger.json',
        'pubspec.yaml',
      ]);
      expect(File('${tmp.path}/content_pipeline/asset_originals/seasons/season_09_test/cases/case_01/scene.png').readAsBytesSync(), scene);
      final e = ledger().of('$folder/scene.webp')!;
      expect((e['source'] as Map)['path'], '$folder/scene.png');
      expect(e['policyVersion'], policy.version);
      expect(e['kind'], 'evidence', reason: 'a case\'s picture by its path');
      expect(verifyLedger(root(), ledger(), log: log.add), isEmpty);

      final before = {for (final f in files()) f: File('${tmp.path}/$f').readAsBytesSync()};
      final calls = counting.calls;
      log.clear();
      await optimize(counting);
      expect(counting.calls, calls, reason: 'nothing encoded again');
      expect({for (final f in files()) f: File('${tmp.path}/$f').readAsBytesSync()}, before, reason: 'no file added or changed');
    }, skip: noCwebp);

    test('an encoder that fails: the PNG left as it was, nothing recorded, nothing backed up', () async {
      final before = files();
      await optimize(_CountingEncoder(fail: true));
      expect(log.join('\n'), contains('FAILED'));
      expect(files(), before);
      expect(File('${tmp.path}/ledger.json').existsSync(), isFalse);
    });

    test('a run cut short after its WebP was written: the next run finishes it without encoding', () async {
      await optimize(_CountingEncoder(through: cwebp));
      // As if the process stopped before removing the PNG.
      File('${tmp.path}/content_pipeline/asset_originals/seasons/season_09_test/cases/case_01/scene.png').copySync('${tmp.path}/$folder/scene.png');
      final counting = _CountingEncoder(through: cwebp);
      log.clear();
      await optimize(counting);
      expect(counting.calls, 0);
      expect(log.join('\n'), contains('finished $folder/scene.png'));
      expect(File('${tmp.path}/$folder/scene.png').existsSync(), isFalse);
    }, skip: noCwebp);

    test('a WebP there that the ledger does not know: a CONFLICT, both left as they are', () async {
      File('${tmp.path}/$folder/scene.webp').writeAsBytesSync(solidWebp(240, 160));
      await optimize(_CountingEncoder(fail: true));
      expect(log.join('\n'), contains('CONFLICT $folder/scene.webp'));
      expect(File('${tmp.path}/$folder/scene.png').existsSync(), isTrue);
      expect(File('${tmp.path}/$folder/scene.webp').readAsBytesSync(), solidWebp(240, 160));
    });

    test('two variants of one picture in a case folder: both kept as a puzzle\'s', () async {
      final a = _scenePng(160, 120, marks: true);
      final b = img.decodePng(a)!;
      img.fillRect(b, x1: 10, y1: 10, x2: 14, y2: 14, color: img.ColorRgb8(255, 0, 0));
      File('${tmp.path}/$folder/variant_a.png').writeAsBytesSync(a);
      File('${tmp.path}/$folder/variant_b.png').writeAsBytesSync(img.encodePng(b));
      final r = run(_CountingEncoder(fail: true));
      final kinds = await r.classify(['$folder/variant_a.png', '$folder/variant_b.png', '$folder/scene.png']);
      expect(kinds['$folder/variant_a.png']!.kind, 'puzzle');
      expect(kinds['$folder/variant_b.png']!.why, contains('twin of variant_a.png'));
      expect(kinds['$folder/scene.png']!.kind, 'evidence');
    });
  });

  group('paths rewritten (RefRewriter)', () {
    late Directory tmp;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('ref_rewrite');
      for (final f in ['assets/s/case/a.webp', 'assets/s/case/b.png', 'assets/images/sym/original/c.png']) {
        File('${tmp.path}/$f')
          ..createSync(recursive: true)
          ..writeAsBytesSync([0]);
      }
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('only a path every PNG of which became WebP; an interpolated path by its literal end; an ambiguous one listed', () {
      final ledger = OptimizedLedger.load('${tmp.path}/ledger.json')
        ..put('assets/s/case/a.webp', {'source': {'path': 'assets/s/case/a.png'}, 'output': {'path': 'assets/s/case/a.webp'}})
        ..put('assets/images/sym/c.webp', {'source': {'path': 'assets/images/sym/c.png'}, 'output': {'path': 'assets/images/sym/c.webp'}});
      final r = RefRewriter.of(tmp.path.replaceAll(r'\', '/'), ledger);
      const text = """
const a = 'assets/s/case/a.png';
final b = '\$_case/a.png'; // and `a.png` in a comment
const keep = 'assets/s/case/b.png';
const original = 'assets/images/sym/original/c.png';
const either = 'c.png';
const other = 'qa/out.png';
const work = '\$root/raw/case/a.png'; // the pipeline's work file, a PNG
final dir = '\${d}/a.png';
const named = 'assets/s/case/a.png'; // its source PNG, on purpose
""";
      final out = r.rewrite(text, 'lib/x.dart');
      expect(out, contains("'assets/s/case/a.webp'"));
      expect(out, contains("'\$_case/a.webp'"));
      expect(out, contains('`a.webp`'));
      expect(out, contains("'assets/s/case/b.png'"), reason: 'still a PNG');
      expect(out, contains("'assets/images/sym/original/c.png'"), reason: 'the original outside the app is still a PNG');
      expect(out, contains("'c.png'"), reason: 'could name either: left');
      expect(out, contains("'qa/out.png'"), reason: 'no picture of the game');
      expect(out, contains("'\$root/raw/case/a.png'"), reason: 'a work file whose end looks like an asset\'s: not a game path');
      expect(out, contains("'\${d}/a.webp'"));
      expect(out, contains("const named = 'assets/s/case/a.png'"), reason: 'a line marked "source PNG" is left');
      expect(r.ambiguous, [contains("lib/x.dart: c.png could name")]);
      expect(r.replaced, 4);
    });
  });

  group('the size report', () {
    test('a new season shows as a new area, with its size; warnings are diagnostics, not failures', () {
      final files = [
        const BundledFile('assets/shared/ui/coin.webp', 40 * 1024),
        const BundledFile('assets/seasons/season_01_london/cover/cover.webp', 300 * 1024),
        const BundledFile('assets/seasons/season_05_tokyo/cover/cover.webp', 2 * 1024 * 1024),
        const BundledFile('assets/seasons/season_05_tokyo/cases/case_01/scene.png', 3 * 1024 * 1024),
        const BundledFile('assets/images/case01/symbols/original/x.png', 1024),
        const BundledFile('assets/sounds/processed/tap.wav', 10 * 1024),
      ];
      final baseline = {
        'areas': {
          'shared': {'files': 1, 'bytes': 40 * 1024},
          'season_01_london': {'files': 1, 'bytes': 300 * 1024},
          'audio': {'files': 1, 'bytes': 10 * 1024},
        },
      };
      final r = SizeReport.of(files, policy: policy, baseline: baseline);
      expect(r.text, contains('a new season since the baseline: +5.0 MB'));
      expect(r.text, contains('season_05_tokyo'));
      expect((r.json['areas'] as Map)['season_05_tokyo'], containsPair('bytes', 5 * 1024 * 1024));
      expect(r.json['unoptimizedPng'], ['assets/seasons/season_05_tokyo/cases/case_01/scene.png', 'assets/images/case01/symbols/original/x.png']);
      expect(r.warnings, contains(contains('original/x.png looks like an original')));
      expect(r.warnings, contains(contains('not optimized')));
      expect(r.baseline['areas'], containsPair('season_05_tokyo', {'files': 2, 'bytes': 5 * 1024 * 1024}));
    });

    test('the bundle is read as Flutter reads pubspec.yaml: a folder\'s own files only, fonts, quoted entries', () {
      final tmp = Directory.systemTemp.createTempSync('bundle');
      addTearDown(() => tmp.deleteSync(recursive: true));
      for (final f in ['assets/a/x.webp', 'assets/a/sub/y.webp', 'assets/b.wav', 'assets/fonts/f.ttf', 'assets/q/z.png']) {
        File('${tmp.path}/$f')
          ..createSync(recursive: true)
          ..writeAsBytesSync([1, 2, 3]);
      }
      File('${tmp.path}/pubspec.yaml').writeAsStringSync('name: x\nflutter:\n  assets:\n    - assets/a/\n    - assets/b.wav  # a note\n    - "assets/q/"\n'
          '  fonts:\n    - family: F\n      fonts:\n        - asset: assets/fonts/f.ttf\n');
      expect([for (final f in BundleAssets.list(root: tmp.path)) f.path], ['assets/a/x.webp', 'assets/b.wav', 'assets/fonts/f.ttf', 'assets/q/z.png']);
    });
  });

  group('the game\'s own bundle', () {
    test('every bundled picture is recorded by the optimizer, or kept on purpose, or a lossy original never re-encoded', () {
      final ledger = OptimizedLedger.load();
      final problems = <String>[];
      for (final f in BundleAssets.list()) {
        if (f.type != 'image') continue;
        final format = ImageFormat.ofPath(f.path);
        if (format == ImageFormat.png && policy.keepReason(f.path) == null) {
          final e = ledger.of(f.path);
          if (e == null || e['keptBecause'] == null) problems.add('${f.path}: a PNG not optimized (optimize_assets.dart --only ${f.path})');
        } else if (format == ImageFormat.webp && ledger.of(f.path) == null) {
          problems.add('${f.path}: a WebP the optimizer has no record of');
        }
      }
      expect(problems, isEmpty);
      expect(SizeReport.of(BundleAssets.list(), policy: policy).json['workFiles'], isEmpty, reason: 'no original or work file in the app');
    });
  });
}

/// A painting-like picture: smooth light, a few shapes, a little grain;
/// [marks]: thin dark lines and dots (the details a puzzle reads).
Uint8List _scenePng(int w, int h, {bool marks = false}) {
  final im = img.Image(width: w, height: h);
  final rnd = math.Random(7);
  for (final p in im) {
    final fx = p.x / w, fy = p.y / h;
    final grain = rnd.nextInt(9) - 4;
    p
      ..r = (60 + 120 * fx + 30 * math.sin(fy * 9) + grain).clamp(0, 255)
      ..g = (80 + 90 * fy + 20 * math.cos(fx * 7) + grain).clamp(0, 255)
      ..b = (120 + 60 * (1 - fx) * fy + grain).clamp(0, 255);
  }
  img.fillCircle(im, x: w ~/ 3, y: h ~/ 2, radius: h ~/ 5, color: img.ColorRgb8(200, 170, 90));
  if (marks) {
    for (var i = 0; i < 6; i++) {
      img.drawLine(im, x1: 5 + i * 12, y1: 4, x2: 9 + i * 12, y2: h - 6, color: img.ColorRgb8(20, 20, 30));
      img.fillCircle(im, x: w - 20, y: 8 + i * 14, radius: 2, color: img.ColorRgb8(240, 240, 240));
    }
  }
  return img.encodePng(im);
}

/// A cut-out: a disc with a soft edge on transparency, a pattern inside.
Uint8List _cutoutPng(int w, int h) {
  final im = img.Image(width: w, height: h, numChannels: 4);
  final cx = w / 2, cy = h / 2, r = math.min(w, h) * 0.4;
  for (final p in im) {
    final d = math.sqrt((p.x - cx) * (p.x - cx) + (p.y - cy) * (p.y - cy));
    final a = (255 * (r + 3 - d) / 6).clamp(0, 255).round();
    p
      ..r = 140 + ((p.x * 5) % 80)
      ..g = 90 + ((p.y * 3) % 60)
      ..b = 40
      ..a = a;
  }
  return img.encodePng(im);
}

/// Counts its calls (in a file: the optimizer encodes in other isolates, each
/// with its own copy of this object); fails, answers fixed bytes, or passes
/// through to a real encoder.
class _CountingEncoder implements WebpEncoder {
  _CountingEncoder({this.fail = false, this.answer, this.through})
    : _calls = '${Directory.systemTemp.createTempSync('encoder_calls').path}/calls';

  final bool fail;
  final Uint8List? answer;
  final WebpEncoder? through;
  final String _calls;

  int get calls => File(_calls).existsSync() ? File(_calls).readAsStringSync().length : 0;

  @override
  String get version => through?.version ?? 'fake';

  @override
  Uint8List encode(Uint8List png, List<String> args) {
    File(_calls).writeAsStringSync('x', mode: FileMode.append, flush: true);
    if (fail) throw const WebpEncodeError('fake failure');
    return answer ?? through!.encode(png, args);
  }
}
