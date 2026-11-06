import 'dart:convert';

import 'package:crypto/crypto.dart';

// Plain Dart (no Flutter): the app reads it, and so do the tools in
// tool/season_packs/ that make the manifests and stage the packs for R2.

/// One file of a season pack as the app was built with it.
class SeasonPackFile {
  const SeasonPackFile(this.path, this.bytes, this.sha256);

  /// Its asset key (`assets/seasons/season_01_london/cover/…webp`), the key
  /// [SeasonPackBundle] is asked for.
  final String path;

  /// Its size in bytes.
  final int bytes;

  /// Its SHA-256, lowercase hex.
  final String sha256;

  /// Where it lives in the bucket: named by its content, so a file that did
  /// not change keeps its object (never uploaded twice, shared by every
  /// version and every pack that holds the same bytes), and a changed file is
  /// a new object.
  String get objectKey {
    final slash = path.lastIndexOf('/'), dot = path.lastIndexOf('.');
    final ext = dot > slash ? path.substring(dot).toLowerCase() : '';
    return 'objects/$sha256$ext';
  }

  Map<String, Object> toJson() => {'path': path, 'bytes': bytes, 'sha256': sha256};

  static SeasonPackFile fromJson(Map<String, Object?> json) =>
      SeasonPackFile(json['path']! as String, json['bytes']! as int, json['sha256']! as String);

  @override
  bool operator ==(Object other) => other is SeasonPackFile && other.path == path && other.bytes == bytes && other.sha256 == sha256;

  @override
  int get hashCode => Object.hash(path, bytes, sha256);

  @override
  String toString() => 'SeasonPackFile($path, $bytes, $sha256)';
}

/// A season pack's files at one version (`SeasonPack.folder` names it).
class SeasonPackManifest {
  const SeasonPackManifest({required this.folder, required this.version, required this.files});

  /// Its folder under `assets/seasons/` (`season_01_london`).
  final String folder;

  /// [versionOf] its files: changes exactly when a file is added, removed or
  /// changed.
  final String version;

  /// Sorted by path.
  final List<SeasonPackFile> files;

  int get totalBytes => files.fold(0, (sum, f) => sum + f.bytes);

  /// The manifest's own place in the bucket (one object per version).
  String get objectKey => 'manifests/$folder/$version.json';

  /// The first 16 hex of the SHA-256 of one line per file (`path`, `bytes`,
  /// `sha256`, tab-separated), sorted by path.
  static String versionOf(Iterable<SeasonPackFile> files) {
    final lines = [for (final f in files) '${f.path}\t${f.bytes}\t${f.sha256}\n']..sort();
    return sha256.convert(utf8.encode(lines.join())).toString().substring(0, 16);
  }

  Map<String, Object> toJson() => {
        'folder': folder,
        'version': version,
        'fileCount': files.length,
        'totalBytes': totalBytes,
        'files': [for (final f in files) f.toJson()],
      };

  static SeasonPackManifest fromJson(Map<String, Object?> json) => SeasonPackManifest(
        folder: json['folder']! as String,
        version: json['version']! as String,
        files: [for (final f in json['files']! as List) SeasonPackFile.fromJson((f as Map).cast<String, Object?>())],
      );
}

/// What a check of downloaded bytes against their [SeasonPackFile] found.
enum PackFileCheck {
  ok,

  /// Not the size the manifest gives (cut short, or another file).
  wrongSize,

  /// The right size, other bytes.
  wrongHash,
}

/// Downloaded files checked against the manifest the app was built with.
abstract final class PackFileVerifier {
  /// [data] held whole.
  static PackFileCheck check(SeasonPackFile file, List<int> data) {
    if (data.length != file.bytes) return PackFileCheck.wrongSize;
    return sha256.convert(data).toString() == file.sha256 ? PackFileCheck.ok : PackFileCheck.wrongHash;
  }

  /// [data] read in chunks (a file on disk, a download), never held whole.
  static Future<PackFileCheck> checkStream(SeasonPackFile file, Stream<List<int>> data) async {
    var length = 0;
    final digest = await sha256.bind(data.map((chunk) {
      length += chunk.length;
      return chunk;
    })).single;
    if (length != file.bytes) return PackFileCheck.wrongSize;
    return digest.toString() == file.sha256 ? PackFileCheck.ok : PackFileCheck.wrongHash;
  }
}
