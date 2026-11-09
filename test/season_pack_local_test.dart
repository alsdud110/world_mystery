import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/core/assets/season_pack_downloads.dart';
import 'package:world_mystery/core/assets/season_pack_local.dart';
import 'package:world_mystery/core/assets/season_pack_storage.dart';

/// Any HTTP request at all fails the test that makes it.
class _NoNetwork extends HttpOverrides {
  int requests = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    requests++;
    throw StateError('network used');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ASSET_SOURCE', () {
    test('unset: local in debug, r2 in profile; a release is always r2', () {
      expect(AssetSource.of('', debug: true, release: false), AssetSource.local);
      expect(AssetSource.of('', debug: false, release: false), AssetSource.r2);
      expect(AssetSource.of('r2', debug: true, release: false), AssetSource.r2);
      expect(AssetSource.of('local', debug: false, release: false), AssetSource.local);
      expect(AssetSource.of('local', debug: false, release: true), AssetSource.r2, reason: 'never shipped');
      expect(AssetSource.of('', debug: false, release: true), AssetSource.r2);
      expect(() => AssetSource.of('cdn', debug: true, release: false), throwsArgumentError);
    });

    test('unset: the project folder when this device has it, else R2; ASSET_SOURCE=local: the folder, or a named error', () {
      expect(LocalSeasonPacks.choose(Directory.current.path, explicit: false)?.root, Directory.current.path, reason: 'a simulator');
      expect(LocalSeasonPacks.choose('', explicit: false), isNull, reason: 'no folder known: R2');
      expect(LocalSeasonPacks.choose('/Users/someone/world_mystery_not_here', explicit: false), isNull, reason: 'a phone: R2');
      expect(LocalSeasonPacks.choose('', explicit: true)?.problem(), contains('SEASON_PACK_DIR'), reason: 'never a quiet download');
    });

    test('this test run (debug, no ASSET_SOURCE): local', () {
      expect(AssetSource.fromEnvironment(), AssetSource.local);
    });
  });

  group('the project folder', () {
    test('every Seoul picture (Cases 01–12) read and drawn with no network', () async {
      final net = _NoNetwork();
      final local = LocalSeasonPacks(Directory.current.path);
      expect(local.problem(), isNull);
      final bundle = SeasonPackBundle(app: _NoApp(), store: local);
      final files = SeasonPack.seoul.manifest.files;
      for (var c = 1; c <= 12; c++) {
        expect(files.where((f) => f.path.contains('/cases/case_${'$c'.padLeft(2, '0')}/')), isNotEmpty, reason: 'case $c');
      }
      await HttpOverrides.runZoned(() async {
        for (final f in files) {
          final buffer = await bundle.loadBuffer(f.path);
          expect(buffer.length, f.bytes, reason: f.path);
          final codec = await ui.instantiateImageCodecFromBuffer(buffer);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, greaterThan(0), reason: f.path);
          frame.image.dispose();
          codec.dispose();
        }
      }, createHttpClient: net.createHttpClient);
      expect(net.requests, 0);
    }, timeout: const Timeout(Duration(minutes: 3))); // 115 pictures decoded

    test('London and files no pack lists come from the app', () async {
      final local = LocalSeasonPacks(Directory.current.path);
      expect(await local.load(SeasonPack.london, '${SeasonPack.london.root}cover/x.webp'), isNull);
      expect(await local.load(SeasonPack.seoul, 'assets/seasons/season_05_seoul/cases/case_01/audio/eomma.m4a'), isNull);
    });

    test('in the app: the local packs, not the bundled or downloaded ones', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        localSeasonPacksProvider.overrideWithValue(LocalSeasonPacks(Directory.current.path)),
        seasonPackSetupProvider.overrideWithValue(SeasonPackSetup(SeasonPackStorage(Directory.systemTemp, prefs), DirectorySeasonPackSource(Directory.systemTemp))),
      ]);
      addTearDown(c.dispose);
      expect(c.read(seasonPackBundleProvider).store, isA<LocalSeasonPacks>());
    });
  });

  group('a clear error, never a quiet download', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('local_packs'));
    tearDown(() => tmp.deleteSync(recursive: true));
    final first = SeasonPack.seoul.manifest.files.first;

    test('no folder given', () async {
      final local = LocalSeasonPacks('');
      expect(local.problem(), contains('SEASON_PACK_DIR'));
      expect(() => local.load(SeasonPack.seoul, first.path), throwsA(isA<FlutterError>()));
    });

    test('a file missing: named', () async {
      final local = LocalSeasonPacks(tmp.path);
      expect(local.missing(), contains(first.path));
      expect(local.problem(), contains('missing'));
      await expectLater(
        local.load(SeasonPack.seoul, first.path),
        throwsA(isA<FlutterError>().having((e) => e.message, 'message', contains(first.path))),
      );
    });

    test('a file other than the manifest names: refused', () async {
      File('${tmp.path}/${first.path}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List.filled(first.bytes, 0));
      await expectLater(
        LocalSeasonPacks(tmp.path).load(SeasonPack.seoul, first.path),
        throwsA(isA<FlutterError>().having((e) => e.message, 'message', contains('differs'))),
      );
    });
  });
}

/// The app bundle must not be read for a pack file.
class _NoApp extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw StateError('app bundle read: $key');
}
