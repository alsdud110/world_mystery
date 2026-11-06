import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'season_pack_bundle.dart';
import 'season_pack_manifest.dart';

/// Where a pack's objects are downloaded from (the bucket's layout of
/// tool/season_packs/stage_packs.dart: `objects/<sha256>.<ext>`).
abstract interface class SeasonPackSource {
  /// The bytes of [objectKey]; the stream fails when it cannot be read.
  Stream<List<int>> open(String objectKey);
}

/// The packs over HTTPS (the R2 bucket's public URL or a CDN in front of it).
class HttpSeasonPackSource implements SeasonPackSource {
  HttpSeasonPackSource(this.base, {HttpClient? client})
    : assert(base.scheme == 'https' && base.path.endsWith('/')),
      _client = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 20));

  final Uri base;
  final HttpClient _client;

  /// A download that stops sending for this long fails (it can be retried).
  static const idle = Duration(seconds: 30);

  @override
  Stream<List<int>> open(String objectKey) async* {
    final uri = base.resolve(objectKey);
    final response = await (await _client.getUrl(uri)).close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    yield* response.timeout(idle);
  }
}

/// The packs from a folder laid out as the bucket (a staged folder, tests).
class DirectorySeasonPackSource implements SeasonPackSource {
  DirectorySeasonPackSource(this.root);

  final Directory root;

  @override
  Stream<List<int>> open(String objectKey) => File('${root.path}/$objectKey').openRead();
}

/// The player stopped a download.
class SeasonPackCancelled implements Exception {
  const SeasonPackCancelled();
}

/// A downloaded file was not the one the manifest names (cut short, or other
/// bytes): it was thrown away and can be downloaded again.
class SeasonPackCorrupt implements Exception {
  const SeasonPackCorrupt(this.path, this.check);
  final String path;
  final PackFileCheck check;

  @override
  String toString() => 'SeasonPackCorrupt(${check.name}: $path)';
}

/// Asks a running [SeasonPackStorage.install] to stop.
class SeasonPackCancel {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Season packs downloaded into the app's own storage, one folder each:
/// every file under its SHA-256 (`<root>/<folder>/<sha256>.<ext>`), written
/// as `.part` and renamed only once its size and SHA-256 were checked. A pack
/// counts as installed only when the version of the manifest the app was
/// built with is recorded (after all its files were checked), so a stopped,
/// failed or outdated download is never read; a retry keeps the files
/// already checked. Nothing here touches the game's progress or rewards.
class SeasonPackStorage {
  SeasonPackStorage(this.root, this.prefs);

  final Directory root;
  final SharedPreferences prefs;

  static String _key(String folder) => 'season_pack.installed.$folder';

  bool isInstalled(SeasonPackManifest pack) => prefs.getString(_key(pack.folder)) == pack.version;

  Directory _dirOf(SeasonPackManifest pack) => Directory('${root.path}/${pack.folder}');

  File fileOf(SeasonPackManifest pack, SeasonPackFile file) =>
      File('${_dirOf(pack).path}/${file.objectKey.substring('objects/'.length)}');

  /// Downloads what [pack] still lacks from [source], checks every file, then
  /// records it installed. [onProgress]: bytes in place so far of the
  /// pack's total. Throws [SeasonPackCancelled], [SeasonPackCorrupt] or the
  /// source's error; the files checked so far stay for the next try.
  Future<void> install(
    SeasonPackManifest pack,
    SeasonPackSource source, {
    void Function(int done, int total)? onProgress,
    SeasonPackCancel? cancel,
  }) async {
    final dir = _dirOf(pack)..createSync(recursive: true);
    final total = pack.totalBytes;
    var done = 0;
    for (final f in pack.files) {
      final target = fileOf(pack, f);
      // Renamed into place only after its check: the right size is enough.
      if (target.existsSync() && target.lengthSync() == f.bytes) {
        done += f.bytes;
        onProgress?.call(done, total);
        continue;
      }
      if (cancel?.isCancelled ?? false) throw const SeasonPackCancelled();
      final part = File('${target.path}.part');
      final sink = part.openWrite();
      var got = 0;
      try {
        await for (final chunk in source.open(f.objectKey)) {
          if (cancel?.isCancelled ?? false) throw const SeasonPackCancelled();
          sink.add(chunk);
          got += chunk.length;
          onProgress?.call(done + got, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      final check = await PackFileVerifier.checkStream(f, part.openRead());
      if (check != PackFileCheck.ok) {
        part.deleteSync();
        onProgress?.call(done, total);
        throw SeasonPackCorrupt(f.path, check);
      }
      part.renameSync(target.path);
      done += f.bytes;
    }
    // Files of an older version, and parts left by a stopped download.
    final keep = {for (final f in pack.files) fileOf(pack, f).path.replaceAll(r'\', '/')};
    for (final e in dir.listSync().whereType<File>()) {
      if (!keep.contains(e.path.replaceAll(r'\', '/'))) e.deleteSync();
    }
    await prefs.setString(_key(pack.folder), pack.version);
  }

  /// [pack]'s downloaded files and its record removed (the season's progress
  /// and rewards are kept elsewhere and stay).
  Future<void> delete(SeasonPackManifest pack) async {
    await prefs.remove(_key(pack.folder));
    final dir = _dirOf(pack);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// [SeasonPackStore] over [SeasonPackStorage]: an installed pack's files are
/// read from the device; a pack not installed (or a file gone) reads null,
/// so [SeasonPackBundle] reads the app's own copy.
class DownloadedSeasonPacks implements SeasonPackStore {
  DownloadedSeasonPacks(this.storage);

  final SeasonPackStorage storage;
  final _byPath = <String, Map<String, SeasonPackFile>>{};

  @override
  Future<ByteData?> load(SeasonPack pack, String key) async {
    final manifest = pack.manifest;
    if (!storage.isInstalled(manifest)) return null;
    final files = _byPath.putIfAbsent(pack.folder, () => {for (final f in manifest.files) f.path: f});
    final file = files[key];
    if (file == null) return null;
    try {
      final bytes = await storage.fileOf(manifest, file).readAsBytes();
      return ByteData.sublistView(bytes);
    } on FileSystemException catch (e) {
      debugPrint('Season pack file unreadable, using the app copy: ${e.path}');
      return null;
    }
  }
}
