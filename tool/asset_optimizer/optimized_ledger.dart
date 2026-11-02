import 'dart:convert';
import 'dart:io';

/// Every picture the optimizer made, in Git (`optimized_assets.json`): the
/// game file, the PNG it was made from (its sha256: the original itself is
/// kept outside the app, `image_policy.json` → `originalsDir`), the kind,
/// setting, quality and policy version. A picture whose record matches its
/// file is never encoded again; a PNG kept as it is has a record too.
class OptimizedLedger {
  OptimizedLedger._(this.path, this.entries);

  static const defaultPath = 'tool/asset_optimizer/optimized_assets.json';
  static const schemaVersion = 1;

  final String path;

  /// By the game file's path (`assets/…`).
  final Map<String, Map<String, Object?>> entries;

  static OptimizedLedger load([String path = defaultPath]) {
    final f = File(path);
    if (!f.existsSync()) return OptimizedLedger._(path, {});
    final json = jsonDecode(f.readAsStringSync());
    if (json is! Map || json['schemaVersion'] != schemaVersion || json['entries'] is! Map) {
      throw FormatException('$path: not an optimized-assets ledger (schemaVersion $schemaVersion)');
    }
    return OptimizedLedger._(path, {
      for (final MapEntry(:key, :value) in (json['entries'] as Map).entries) key as String: (value as Map).cast<String, Object?>(),
    });
  }

  Map<String, Object?>? of(String gamePath) => entries[gamePath];

  /// The record whose source was [pngPath], or null.
  MapEntry<String, Map<String, Object?>>? bySource(String pngPath) {
    for (final e in entries.entries) {
      if ((e.value['source'] as Map?)?['path'] == pngPath) return e;
    }
    return null;
  }

  /// Every source PNG path and the game file made from it (WebP ones only).
  Map<String, String> get renamed => {
    for (final e in entries.entries)
      if ((e.value['source'] as Map?)?['path'] case final String src when src != e.key) src: e.key,
  };

  void put(String gamePath, Map<String, Object?> entry) => entries[gamePath] = entry;

  /// Written whole beside itself, then moved over the old one.
  void save() {
    final keys = entries.keys.toList()..sort();
    final part = File('$path.part')..parent.createSync(recursive: true);
    part.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': schemaVersion,
        'note': 'Written by tool/asset_optimizer (README.md). Do not edit by hand: a record that does not match its file makes the optimizer leave that file alone.',
        'entries': {for (final k in keys) k: entries[k]},
      })}\n',
      flush: true,
    );
    part.renameSync(path);
  }
}
