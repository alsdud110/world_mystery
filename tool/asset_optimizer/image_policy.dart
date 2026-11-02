import 'dart:convert';
import 'dart:io';

/// One kind of picture's settings (`image_policy.json` → `kinds`).
class KindPolicy {
  const KindPolicy({required this.name, required this.ladder, required this.minPsnr, required this.minSsim, required this.maxEdge});

  final String name;

  /// cwebp settings tried in order; lossless WebP always comes after them.
  final List<List<String>> ladder;
  final double minPsnr;
  final double minSsim;

  /// The long edge a picture is shrunk to when larger; 0 keeps every pixel.
  final int maxEdge;

  bool passes(double psnr, double ssim) => psnr >= minPsnr && ssim >= minSsim;
}

/// Where the size report says the bundle has grown too much (diagnostics).
class SizeWarnings {
  const SizeWarnings({required this.bundleMb, required this.seasonMb, required this.seasonGrowthMb, required this.fileKb});

  final double bundleMb, seasonMb, seasonGrowthMb, fileKb;
}

/// The one place the game's picture policy is written:
/// `tool/asset_optimizer/image_policy.json`, read whole and checked.
class ImagePolicy {
  ImagePolicy._(this.json);

  static const defaultPath = 'tool/asset_optimizer/image_policy.json';

  final Map<String, Object?> json;

  static ImagePolicy load([String path = defaultPath]) => ImagePolicy.fromJson(jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>);

  factory ImagePolicy.fromJson(Map<String, Object?> json) {
    final p = ImagePolicy._(json);
    // Read every part once now: a policy that cannot be read fails before any picture.
    p.kinds;
    if (!p.kinds.containsKey(p.defaultKind)) throw FormatException('defaultKind ${p.defaultKind} is not a kind');
    for (final r in [...p._manifestKinds, ...p._pathKinds]) {
      if (!p.kinds.containsKey(r['kind'])) throw FormatException('a rule names the kind ${r['kind']}, not in kinds');
    }
    p.sizeWarnings;
    return p;
  }

  int get version => json['policyVersion'] as int;

  List<String> get commonArgs => [for (final a in ((json['encoder'] as Map)['common'] as List)) a as String];
  List<String> get losslessArgs => [for (final a in ((json['encoder'] as Map)['lossless'] as List)) a as String];

  late final Map<String, KindPolicy> kinds = {
    for (final MapEntry(:key, :value) in (json['kinds'] as Map).entries)
      key as String: KindPolicy(
        name: key,
        ladder: [for (final step in (value as Map)['ladder'] as List) [for (final a in step as List) a as String]],
        minPsnr: (value['minPsnr'] as num).toDouble(),
        minSsim: (value['minSsim'] as num).toDouble(),
        maxEdge: value['maxEdge'] as int? ?? 0,
      ),
  };

  String get defaultKind => json['defaultKind'] as String;

  KindPolicy kind(String name) => kinds[name] ?? (throw ArgumentError.value(name, 'kind', 'not a kind of $defaultPath'));

  List<Map<String, Object?>> get _manifestKinds => [for (final r in json['manifestKinds'] as List) (r as Map).cast<String, Object?>()];
  List<Map<String, Object?>> get _pathKinds => [for (final r in json['pathKinds'] as List) (r as Map).cast<String, Object?>()];

  Set<String> get puzzleFiles => {for (final f in json['puzzleFiles'] as List? ?? const []) f as String};

  /// Pictures whose pixels must match another's exactly (kind `exact`).
  Set<String> get exactFiles => {for (final f in json['exactFiles'] as List? ?? const []) f as String};

  double get twinLikeness => ((json['twins'] as Map?)?['minLikeness'] as num?)?.toDouble() ?? 1.01;

  /// The kinds whose twins are puzzles' (none: no twin rule).
  Set<String> get twinKinds => {for (final k in (json['twins'] as Map?)?['kinds'] as List? ?? const []) k as String};

  String get originalsDir => json['originalsDir'] as String;

  SizeWarnings get sizeWarnings {
    final w = json['sizeWarnings'] as Map;
    double n(String k) => (w[k] as num).toDouble();
    return SizeWarnings(bundleMb: n('bundleMb'), seasonMb: n('seasonMb'), seasonGrowthMb: n('seasonGrowthMb'), fileKb: n('fileKb'));
  }

  /// Why [path] stays as it is (a tool reads it as PNG), or null.
  String? keepReason(String path) {
    for (final r in json['keep'] as List? ?? const []) {
      final m = r as Map;
      if (path.startsWith(m['prefix'] as String)) return m['why'] as String;
    }
    return null;
  }

  /// The kind of a season pipeline's picture, from its manifest's `type`
  /// and `use` (the generator's own record of what it is), else the default.
  String kindOfManifest({required String type, required String use}) {
    for (final r in _manifestKinds) {
      if (r['type'] != null && r['type'] != type) continue;
      if (r['use'] != null && r['use'] != use) continue;
      return r['kind'] as String;
    }
    return defaultKind;
  }

  /// The kind of a picture known only by its place in `assets/`: an
  /// explicit puzzle file first, then the first path rule, else the default
  /// (the most careful kind).
  String kindOfPath(String path) {
    // Listed as the PNGs they were made from; the same picture as a WebP is the same puzzle's.
    String stem(String p) => p.replaceFirst(RegExp(r'\.(png|webp)$'), '');
    if (exactFiles.map(stem).contains(stem(path))) return 'exact';
    if (puzzleFiles.map(stem).contains(stem(path))) return 'puzzle';
    for (final r in _pathKinds) {
      final prefix = r['prefix'] as String?, contains = r['contains'] as String?;
      if (prefix != null && !path.startsWith(prefix)) continue;
      if (contains != null && !path.contains(contains)) continue;
      return r['kind'] as String;
    }
    return defaultKind;
  }
}
