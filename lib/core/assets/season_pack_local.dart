import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'season_pack_bundle.dart';
import 'season_pack_manifest.dart';

/// Where the downloaded seasons' pictures come from in this build.
enum AssetSource {
  /// Downloaded from the bucket (SEASON_PACK_URL), kept and checked on the device.
  r2,

  /// Read from the project folder on the computer the app runs on (an iOS
  /// simulator, macOS): no download, no network ([LocalSeasonPacks]).
  local;

  /// `--dart-define=ASSET_SOURCE=local|r2`; unset: local in a debug build,
  /// r2 otherwise. A release build is always r2, whatever it was given.
  static AssetSource of(String value, {required bool debug, required bool release}) {
    if (release) return r2;
    return switch (value) {
      'local' => local,
      'r2' => r2,
      '' => debug ? local : r2,
      _ => throw ArgumentError.value(value, 'ASSET_SOURCE', 'local or r2'),
    };
  }

  static AssetSource fromEnvironment() =>
      of(const String.fromEnvironment('ASSET_SOURCE'), debug: kDebugMode, release: kReleaseMode);
}

/// The downloaded seasons' packs read straight from the project's
/// `assets/seasons/` on this computer ([root], `--dart-define=SEASON_PACK_DIR=`
/// the project folder): each file checked once against the manifest the app
/// is built with (size, SHA-256), as a download is. A file missing or
/// different is an error naming it, never a quiet download. London (in the
/// app) and files no pack lists (Seoul's voices) are read from the app.
class LocalSeasonPacks implements SeasonPackStore {
  LocalSeasonPacks(this.root);

  /// The project folder; empty: not given.
  final String root;
  final _checked = <String>{};
  final _byPath = <String, Map<String, SeasonPackFile>>{};

  static LocalSeasonPacks fromEnvironment() => LocalSeasonPacks(const String.fromEnvironment('SEASON_PACK_DIR'));

  SeasonPackFile? _fileOf(SeasonPack pack, String key) =>
      _byPath.putIfAbsent(pack.folder, () => {for (final f in pack.manifest.files) f.path: f})[key];

  /// Every downloaded season's file not on disk under [root].
  List<String> missing() => [
    for (final p in SeasonPack.all)
      if (p != SeasonPack.london)
        for (final f in p.manifest.files)
          if (root.isEmpty || !File('$root/${f.path}').existsSync()) f.path,
  ];

  /// What the developer must fix, or null: every file is there.
  String? problem() {
    if (root.isEmpty) {
      return 'ASSET_SOURCE=local needs the project folder: --dart-define=SEASON_PACK_DIR=<project folder> '
          '(or --dart-define=ASSET_SOURCE=r2 to download)';
    }
    final gone = missing();
    if (gone.isEmpty) return null;
    return '${gone.length} season pack files are missing under $root: ${gone.take(10).join(', ')}${gone.length > 10 ? ', …' : ''}';
  }

  @override
  Future<ByteData?> load(SeasonPack pack, String key) async {
    if (pack == SeasonPack.london) return null;
    final file = _fileOf(pack, key);
    if (file == null) return null;
    if (root.isEmpty) throw FlutterError('Local season pack: ${problem()}');
    final Uint8List bytes;
    try {
      bytes = await File('$root/$key').readAsBytes();
    } on FileSystemException {
      throw FlutterError('Local season pack: $key is missing under $root');
    }
    if (_checked.add(key) && (bytes.length != file.bytes || sha256.convert(bytes).toString() != file.sha256)) {
      _checked.remove(key);
      throw FlutterError('Local season pack: $key differs from the app\'s manifest '
          '(run dart run tool/season_packs/build_manifest.dart)');
    }
    return ByteData.sublistView(bytes);
  }
}

/// The local packs this build reads, or null: none (packs are downloaded,
/// or in the app).
final localSeasonPacksProvider = Provider<LocalSeasonPacks?>((ref) => null);
