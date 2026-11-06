import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';

/// The app bundle as the game has it, noting each file read.
class _Recording extends AssetBundle {
  _Recording(this.inner);
  final AssetBundle inner;
  final loaded = <String>[];

  @override
  Future<ByteData> load(String key) {
    loaded.add(key);
    return inner.load(key);
  }

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) {
    loaded.add(key);
    return inner.loadBuffer(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) => inner.loadString(key, cache: cache);

  @override
  Future<T> loadStructuredBinaryData<T>(String key, FutureOr<T> Function(ByteData data) parser) =>
      inner.loadStructuredBinaryData(key, parser);
}

/// A pack installed on the device holding exactly [files].
class _Installed implements SeasonPackStore {
  _Installed(this.files);
  final Map<String, ByteData> files;
  final asked = <(SeasonPack, String)>[];

  @override
  Future<ByteData?> load(SeasonPack pack, String key) async {
    asked.add((pack, key));
    return files[key];
  }
}

/// A season's first picture on disk (as an asset path).
String _pictureOf(SeasonPack pack) {
  final files = Directory(pack.root).listSync(recursive: true).whereType<File>().map((f) => f.path.replaceAll(r'\', '/')).where((p) => p.endsWith('.webp')).toList()..sort();
  return files.first;
}

void main() {
  test('every season folder is one pack, for every season the game lists', () {
    final folders = [for (final d in Directory('assets/seasons').listSync().whereType<Directory>()) d.path.replaceAll(r'\', '/').split('/').last]..sort();
    expect([for (final p in SeasonPack.all) p.folder]..sort(), folders);
    expect({for (final p in SeasonPack.all) p.seasonId}, {for (final s in SeasonCatalog.all) s.season.id});
  });

  test('a path belongs to its season pack; app files and odd paths to none', () {
    expect(SeasonPack.ofAsset('assets/seasons/season_01_london/cover/x.webp'), SeasonPack.london);
    expect(SeasonPack.ofAsset('assets/seasons/season_02_paris/cases/case_01/a.webp'), SeasonPack.paris);
    expect(SeasonPack.ofAsset('assets/seasons/season_03_rome/locations/map/m.webp'), SeasonPack.rome);
    expect(SeasonPack.ofAsset('assets/seasons/season_04_newyork/characters/c.webp'), SeasonPack.newyork);
    expect(SeasonPack.ofAsset('assets/seasons/season_05_seoul/cover/kings_study.webp'), SeasonPack.seoul);
    for (final key in [
      'assets/branding/app_icon.png',
      'AssetManifest.bin',
      'assets/seasons/season_05_seoul/',
      'assets/seasons/season_09_tokyo/a.webp',
      'assets/seasons/season_05_seoul/../../branding/app_icon.png',
      r'assets/seasons/season_05_seoul\a.webp',
    ]) {
      expect(SeasonPack.ofAsset(key), isNull, reason: key);
    }
  });

  test('with no pack installed, every file is the app bundle\'s own', () async {
    final app = _Recording(rootBundle);
    final bundle = SeasonPackBundle(app: app);
    final cover = _pictureOf(SeasonPack.seoul);
    final mine = await bundle.load(cover);
    final theirs = await rootBundle.load(cover);
    expect(mine.buffer.asUint8List(mine.offsetInBytes, mine.lengthInBytes), theirs.buffer.asUint8List(theirs.offsetInBytes, theirs.lengthInBytes));
    (await bundle.loadBuffer(cover)).dispose();
    expect(app.loaded, [cover, cover]);
    expect(SeasonPackBundle().store, isA<BundledSeasonPacks>());
    expect(SeasonPackBundle().app, same(rootBundle));
  });

  test('an installed pack answers for its own files only; the rest stay the app\'s', () async {
    final seoul = _pictureOf(SeasonPack.seoul);
    final london = _pictureOf(SeasonPack.london);
    final missing = '${SeasonPack.seoul.root}not_installed.webp';
    final installed = _Installed({seoul: ByteData.sublistView(Uint8List.fromList([1, 2, 3]))});
    final app = _Recording(rootBundle);
    final bundle = SeasonPackBundle(app: app, store: installed);

    expect((await bundle.load(seoul)).buffer.asUint8List(), [1, 2, 3]);
    await bundle.load(london);
    await expectLater(bundle.load(missing), throwsA(anything)); // not installed, not in the app: as before
    await bundle.loadString('AssetManifest.json').then((_) {}, onError: (_) {});

    expect(installed.asked, [(SeasonPack.seoul, seoul), (SeasonPack.london, london), (SeasonPack.seoul, missing)]);
    expect(app.loaded, [london, missing]);
  });

  testWidgets('Image.asset shows each season\'s pictures through the bundle', (t) async {
    final app = _Recording(rootBundle);
    final pictures = [for (final p in SeasonPack.all) _pictureOf(p)];
    final errors = <String>[];
    await t.runAsync(() async {
      await t.pumpWidget(DefaultAssetBundle(
        bundle: SeasonPackBundle(app: app),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [
            for (final p in pictures)
              SizedBox(width: 8, height: 8, child: Image.asset(p, errorBuilder: (_, e, _) {
                errors.add('$p: $e');
                return const SizedBox();
              })),
          ]),
        ),
      ));
      final context = t.element(find.byType(Column));
      await Future.wait([for (final p in pictures) precacheImage(AssetImage(p), context)]);
    });
    await t.pump();
    expect(errors, isEmpty);
    expect(app.loaded.toSet(), containsAll(pictures));
    for (final p in pictures) {
      final image = t.widget<Image>(find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName == p));
      expect(image, isNotNull);
    }
  });
}
