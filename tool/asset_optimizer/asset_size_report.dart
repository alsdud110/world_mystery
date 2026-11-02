import 'dart:convert';
import 'dart:io';

import 'bundle_assets.dart';
import 'image_policy.dart';

/// What the app ships, measured (PART 5 of the asset optimization):
///
///     dart run tool/asset_optimizer/asset_size_report.dart
///         [--baseline tool/asset_optimizer/size_baseline.json] [--write-baseline]
///         [--json <out.json>] [--top 20]
///
/// The bundle as `pubspec.yaml` lists it (not the project folder): every
/// area (shared, each season, audio, fonts) by type and format, the largest
/// files, PNGs still to optimize, originals or work files that slipped into
/// the bundle, and each area's growth since the baseline (a new season shows
/// as a new area). The warnings (`image_policy.json` → `sizeWarnings`) are
/// diagnostics: the exit code is 0 unless the report cannot be made.
void main(List<String> args) {
  var baselinePath = 'tool/asset_optimizer/size_baseline.json';
  String? jsonOut;
  var writeBaseline = false;
  var top = 20;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--baseline' when i + 1 < args.length:
        baselinePath = args[++i];
      case '--json' when i + 1 < args.length:
        jsonOut = args[++i];
      case '--top' when i + 1 < args.length:
        top = int.parse(args[++i]);
      case '--write-baseline':
        writeBaseline = true;
      default:
        stderr.writeln('usage: dart run tool/asset_optimizer/asset_size_report.dart [--baseline <json>] [--write-baseline] [--json <out>] [--top 20]');
        exit(64);
    }
  }
  final policy = ImagePolicy.load();
  final baselineFile = File(baselinePath);
  final baseline = baselineFile.existsSync() ? jsonDecode(baselineFile.readAsStringSync()) as Map<String, Object?> : null;
  final report = SizeReport.of(BundleAssets.list(), policy: policy, baseline: baseline, top: top);
  stdout.write(report.text);
  if (jsonOut != null) File(jsonOut).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report.json)}\n');
  if (writeBaseline) {
    baselineFile.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(report.baseline)}\n');
    stdout.writeln('baseline written: $baselinePath');
  }
}

/// The measured bundle, as text and JSON.
class SizeReport {
  SizeReport._(this.text, this.json, this.baseline, this.warnings);

  final String text;
  final Map<String, Object?> json;

  /// What `--write-baseline` keeps: each area's bytes and files.
  final Map<String, Object?> baseline;
  final List<String> warnings;

  static String mb(num bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  /// A path that is an original or a work file, never the game's copy.
  static bool isWorkFile(String path) =>
      path.contains('/original/') ||
      path.contains('/originals/') ||
      path.contains('asset_work/') ||
      path.contains('asset_originals/') ||
      path.endsWith('.part') ||
      RegExp(r'_(raw|orig|original|source)\.[a-z]+$').hasMatch(path);

  static SizeReport of(List<BundledFile> files, {required ImagePolicy policy, Map<String, Object?>? baseline, int top = 20}) {
    final out = StringBuffer();
    final warnings = <String>[];
    final w = policy.sizeWarnings;
    final total = files.fold<int>(0, (s, f) => s + f.bytes);
    final areas = <String, List<BundledFile>>{};
    for (final f in files) {
      (areas[f.area] ??= []).add(f);
    }
    final areaNames = areas.keys.toList()..sort();
    final byFormat = <String, (int, int)>{};
    for (final f in files) {
      final (n, b) = byFormat[f.extension] ?? (0, 0);
      byFormat[f.extension] = (n + 1, b + f.bytes);
    }
    final pngs = [for (final f in files) if (f.extension == '.png' && policy.keepReason(f.path) == null) f]..sort((a, b) => b.bytes.compareTo(a.bytes));
    final kept = [for (final f in files) if (f.extension == '.png' && policy.keepReason(f.path) != null) f];
    final work = [for (final f in files) if (isWorkFile(f.path)) f];
    final largest = [...files]..sort((a, b) => b.bytes.compareTo(a.bytes));
    final baseAreas = (baseline?['areas'] as Map?)?.cast<String, Object?>() ?? const {};

    out.writeln('bundle   ${files.length} files, ${mb(total)} MB (pubspec.yaml: what the app ships, before store compression)');
    out.writeln('area                      files      MB   images   audio   fonts   other   since baseline');
    final areaJson = <String, Object?>{};
    for (final a in areaNames) {
      final fs = areas[a]!;
      int sum(String type) => fs.where((f) => f.type == type).fold(0, (s, f) => s + f.bytes);
      final bytes = fs.fold<int>(0, (s, f) => s + f.bytes);
      final before = (baseAreas[a] as Map?)?['bytes'] as int?;
      final growth = before == null ? null : bytes - before;
      out.writeln('${a.padRight(24)} ${fs.length.toString().padLeft(6)} ${mb(bytes).padLeft(7)} ${mb(sum('image')).padLeft(8)} '
          '${mb(sum('audio')).padLeft(7)} ${mb(sum('font')).padLeft(7)} ${mb(sum('other')).padLeft(7)}   '
          '${before == null ? (baseline == null ? '-' : 'new area') : '${growth! >= 0 ? '+' : ''}${mb(growth)} MB'}');
      areaJson[a] = {'files': fs.length, 'bytes': bytes, 'imageBytes': sum('image'), 'audioBytes': sum('audio'), 'growthBytes': ?growth};
      if (a.startsWith('season_') && bytes / (1024 * 1024) > w.seasonMb) {
        final big = [...fs]..sort((x, y) => y.bytes.compareTo(x.bytes));
        warnings.add('$a is ${mb(bytes)} MB (over ${w.seasonMb} MB); largest: ${big.take(3).map((f) => '${f.path} ${mb(f.bytes)} MB').join(', ')}');
      }
      if (growth != null && growth / (1024 * 1024) > w.seasonGrowthMb) {
        warnings.add('$a grew ${mb(growth)} MB since the baseline (over ${w.seasonGrowthMb} MB)');
      } else if (before == null && baseline != null && a.startsWith('season_')) {
        out.writeln('           ↳ a new season since the baseline: +${mb(bytes)} MB');
      }
    }
    for (final gone in baseAreas.keys.where((k) => !areas.containsKey(k))) {
      out.writeln('${gone.padRight(24)}      0     0.0   (in the baseline, not in the bundle now)');
    }
    out.writeln('format   ${[for (final e in (byFormat.keys.toList()..sort())) '${e.isEmpty ? '(none)' : e} ${byFormat[e]!.$1} files ${mb(byFormat[e]!.$2)} MB'].join(' · ')}');
    out.writeln('largest  (top $top)');
    for (final f in largest.take(top)) {
      out.writeln('  ${mb(f.bytes).padLeft(6)} MB  ${f.path}');
    }
    out.writeln('png      ${pngs.length} PNG(s) not optimized (${mb(pngs.fold<int>(0, (s, f) => s + f.bytes))} MB); ${kept.length} kept as PNG on purpose');
    for (final f in pngs.take(top)) {
      out.writeln('  ${mb(f.bytes).padLeft(6)} MB  ${f.path}  (dart run tool/asset_optimizer/optimize_assets.dart --only ${f.path})');
    }
    for (final f in kept) {
      out.writeln('  kept   ${f.path}: ${policy.keepReason(f.path)}');
    }
    if (pngs.isNotEmpty) warnings.add('${pngs.length} PNG(s) in the bundle are not optimized (${mb(pngs.fold<int>(0, (s, f) => s + f.bytes))} MB)');
    for (final f in work) {
      warnings.add('${f.path} looks like an original or a work file, not the game\'s copy: keep it out of pubspec.yaml');
    }
    final bigFiles = [for (final f in files) if (f.bytes / 1024 > w.fileKb) f];
    if (bigFiles.isNotEmpty) {
      warnings.add('${bigFiles.length} file(s) over ${w.fileKb.round()} KB: ${bigFiles.take(5).map((f) => '${f.path} (${(f.bytes / 1024).round()} KB)').join(', ')}');
    }
    if (total / (1024 * 1024) > w.bundleMb) {
      warnings.add('the bundle is ${mb(total)} MB, over ${w.bundleMb} MB (Google Play\'s base module download limit is checked on the compressed AAB: measure it there)');
    }
    out.writeln(warnings.isEmpty ? 'warnings none' : 'warnings ${warnings.length} (diagnostics; nothing blocked)');
    for (final x in warnings) {
      out.writeln('  ! $x');
    }

    final json = <String, Object?>{
      'files': files.length,
      'bytes': total,
      'areas': areaJson,
      'formats': {for (final MapEntry(:key, :value) in byFormat.entries) key: {'files': value.$1, 'bytes': value.$2}},
      'largest': [for (final f in largest.take(top)) {'path': f.path, 'bytes': f.bytes}],
      'unoptimizedPng': [for (final f in pngs) f.path],
      'workFiles': [for (final f in work) f.path],
      'warnings': warnings,
    };
    final base = <String, Object?>{
      'note': 'The bundle as measured by asset_size_report.dart --write-baseline: compare a later bundle (a new season) with it.',
      'files': files.length,
      'bytes': total,
      'areas': {for (final a in areaNames) a: {'files': areas[a]!.length, 'bytes': areas[a]!.fold<int>(0, (s, f) => s + f.bytes)}},
    };
    return SizeReport._(out.toString(), json, base, warnings);
  }
}
