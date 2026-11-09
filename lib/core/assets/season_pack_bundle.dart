import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/season.dart';
import 'season_pack_downloads.dart';
import 'season_pack_local.dart';
import 'season_pack_manifest.dart';
import 'season_pack_storage.dart';
import 'season_pack_manifests.g.dart';

/// A season's pictures as one pack: everything under its folder of
/// `assets/seasons/`. Today every pack ships inside the app (pubspec.yaml);
/// later a pack may also be installed on the device, read through
/// [SeasonPackStore].
@immutable
class SeasonPack {
  const SeasonPack({required this.seasonId, required this.folder});

  final String seasonId;

  /// Its folder under `assets/seasons/` (`season_01_london`).
  final String folder;

  /// The asset path every one of its files starts with.
  String get root => 'assets/seasons/$folder/';

  /// Its files as the app was built with them (size, SHA-256): what a
  /// downloaded copy is checked against ([PackFileVerifier]).
  SeasonPackManifest get manifest => seasonPackManifests[folder]!;

  static const london = SeasonPack(seasonId: SeasonIds.london, folder: 'season_01_london');
  static const paris = SeasonPack(seasonId: SeasonIds.paris, folder: 'season_02_paris');
  static const rome = SeasonPack(seasonId: SeasonIds.rome, folder: 'season_03_rome');
  static const newyork = SeasonPack(seasonId: SeasonIds.newyork, folder: 'season_04_newyork');
  static const seoul = SeasonPack(seasonId: SeasonIds.seoul, folder: 'season_05_seoul');

  static const all = [london, paris, rome, newyork, seoul];

  /// The pack [key] belongs to, or null: an app file (logo, UI, sounds,
  /// World Map), or a path a pack must never answer for (`..`, `\`, an
  /// unknown folder).
  static SeasonPack? ofAsset(String key) {
    if (key.contains('..') || key.contains(r'\')) return null;
    for (final p in all) {
      if (key.startsWith(p.root) && key.length > p.root.length) return p;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is SeasonPack && other.folder == folder && other.seasonId == seasonId;

  @override
  int get hashCode => Object.hash(seasonId, folder);

  @override
  String toString() => 'SeasonPack($seasonId, $folder)';
}

/// Where installed (downloaded) season packs are read from.
abstract interface class SeasonPackStore {
  /// The bytes of [key] from [pack] as installed on the device, or null when
  /// the pack (or that file) is not installed: the app's own copy is read.
  Future<ByteData?> load(SeasonPack pack, String key);
}

/// No pack is installed apart from the app: every season reads the copy in
/// the app bundle, as before season packs.
class BundledSeasonPacks implements SeasonPackStore {
  const BundledSeasonPacks();

  @override
  Future<ByteData?> load(SeasonPack pack, String key) async => null;
}

/// The game's asset bundle (`DefaultAssetBundle` at the app's root, so every
/// `Image.asset`, `AssetImage` and `precacheImage` reads through it without
/// a change to their paths): a season's file comes from its installed pack
/// ([store]) when there is one, everything else, and every season file no
/// pack holds, from the app bundle ([app]) exactly as before.
class SeasonPackBundle extends AssetBundle {
  SeasonPackBundle({AssetBundle? app, this.store = const BundledSeasonPacks()}) : app = app ?? rootBundle;

  final AssetBundle app;
  final SeasonPackStore store;

  /// [key]'s bytes from its installed pack, or null: read [app].
  Future<ByteData?> _installed(String key) async {
    final pack = SeasonPack.ofAsset(key);
    return pack == null ? null : store.load(pack, key);
  }

  @override
  Future<ByteData> load(String key) async => await _installed(key) ?? await app.load(key);

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async {
    final bytes = await _installed(key);
    if (bytes == null) return app.loadBuffer(key);
    return ui.ImmutableBuffer.fromUint8List(Uint8List.sublistView(bytes));
  }

  // Text and structured files (the asset manifest `AssetImage` reads, kept
  // synchronous by the app bundle's cache) come from the app unless a pack
  // holds them.
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (SeasonPack.ofAsset(key) == null) return app.loadString(key, cache: cache);
    return load(key).then((d) => utf8.decode(Uint8List.sublistView(d)));
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> Function(String value) parser) {
    if (SeasonPack.ofAsset(key) == null) return app.loadStructuredData(key, parser);
    return loadString(key, cache: false).then(parser);
  }

  @override
  Future<T> loadStructuredBinaryData<T>(String key, FutureOr<T> Function(ByteData data) parser) {
    if (SeasonPack.ofAsset(key) == null) return app.loadStructuredBinaryData(key, parser);
    return load(key).then(parser);
  }

  @override
  void evict(String key) => app.evict(key);

  @override
  void clear() => app.clear();
}

/// The bundle the game reads its pictures through (see [SeasonPackBundle]).
final seasonPackBundleProvider = Provider<SeasonPackBundle>((ref) {
  final local = ref.watch(localSeasonPacksProvider);
  if (local != null) return SeasonPackBundle(store: local);
  final setup = ref.watch(seasonPackSetupProvider);
  return SeasonPackBundle(store: setup == null ? const BundledSeasonPacks() : DownloadedSeasonPacks(setup.storage));
});
