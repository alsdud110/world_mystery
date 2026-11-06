import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';
import 'package:world_mystery/core/assets/season_pack_storage.dart';

/// The season packs downloaded from the real bucket, through the app's own
/// download code. Runs only when given the bucket's URL, so the usual test
/// runs never use the network:
///
///   SEASON_PACK_LIVE_URL=https://pub-….r2.dev/ flutter test test/season_pack_live_r2_test.dart
///
/// The widgets binding (test/flutter_test_config.dart) mocks HttpClient with
/// one that answers 400: the real one is put back.
void main() {
  final url = Platform.environment['SEASON_PACK_LIVE_URL'] ?? '';
  final skip = url.isEmpty ? 'SEASON_PACK_LIVE_URL not set' : null;
  final seoul = SeasonPack.seoul.manifest;
  late Directory device;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'progress.case': 'kept'});
    prefs = await SharedPreferences.getInstance();
    device = Directory.systemTemp.createTempSync('season_packs_live_');
  });
  tearDown(() => device.deleteSync(recursive: true));
  setUpAll(() => HttpOverrides.global = null);

  HttpSeasonPackSource live() => HttpSeasonPackSource(Uri.parse(url));

  for (final pack in [SeasonPack.paris, SeasonPack.rome, SeasonPack.newyork, SeasonPack.seoul]) {
    test('${pack.folder} downloads over HTTPS, every file checked, then loads offline; a restart downloads nothing', () async {
      final manifest = pack.manifest;
      final storage = SeasonPackStorage(device, prefs);
      var last = 0;
      await storage.install(manifest, live(), onProgress: (done, _) => last = done);
      expect(storage.isInstalled(manifest), isTrue);
      expect(last, manifest.totalBytes);

      // Offline: no source at all, no app copy; every picture comes from the
      // device, the bytes the manifest names.
      final bundle = SeasonPackBundle(app: _NoApp(), store: DownloadedSeasonPacks(storage));
      for (final f in manifest.files) {
        final bytes = await bundle.load(f.path);
        expect(PackFileVerifier.check(f, Uint8List.sublistView(bytes)), PackFileCheck.ok, reason: f.path);
      }

      // The app opened again (same storage): installed, nothing fetched.
      final again = _Counting(live());
      await SeasonPackStorage(device, prefs).install(manifest, again);
      expect(again.opened, isEmpty);
      expect(SeasonPackStorage(device, prefs).isInstalled(manifest), isTrue);
    }, skip: skip, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('a damaged download is not installed; the retry from R2 completes', () async {
    final storage = SeasonPackStorage(device, prefs);
    final damaged = _Damaging(live(), seoul.files[2].objectKey);
    await expectLater(storage.install(seoul, damaged), throwsA(isA<SeasonPackCorrupt>()));
    expect(storage.isInstalled(seoul), isFalse);

    final retry = _Counting(live());
    await storage.install(seoul, retry);
    expect(retry.opened, hasLength(seoul.files.length - 2), reason: 'the two files checked before are kept');
    expect(storage.isInstalled(seoul), isTrue);
    expect(prefs.getString('progress.case'), 'kept');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 5)));

  test('an object missing from the bucket (404) fails the install; nothing is recorded', () async {
    final storage = SeasonPackStorage(device, prefs);
    const ghost = SeasonPackFile('assets/seasons/season_05_seoul/ghost.webp', 1, '0000000000000000000000000000000000000000000000000000000000000000');
    final pack = SeasonPackManifest(folder: seoul.folder, version: 'ghost', files: [seoul.files.first, ghost]);
    await expectLater(
      storage.install(pack, live()),
      throwsA(isA<HttpException>().having((e) => e.message, 'message', 'HTTP 404')),
    );
    expect(storage.isInstalled(pack), isFalse);
  }, skip: skip);

  test('an unreachable host fails the install; nothing is recorded', () async {
    final storage = SeasonPackStorage(device, prefs);
    final nowhere = HttpSeasonPackSource(Uri.parse('https://season-packs.invalid/'));
    await expectLater(storage.install(seoul, nowhere), throwsA(isA<SocketException>()));
    expect(storage.isInstalled(seoul), isFalse);
  }, skip: skip);
}

class _NoApp extends AssetBundle {
  @override
  Future<ByteData> load(String key) => throw StateError('read from the app: $key');

  @override
  Future<String> loadString(String key, {bool cache = true}) => throw StateError('read from the app: $key');
}

class _Counting implements SeasonPackSource {
  _Counting(this.inner);
  final SeasonPackSource inner;
  final opened = <String>[];

  @override
  Stream<List<int>> open(String objectKey) {
    opened.add(objectKey);
    return inner.open(objectKey);
  }
}

/// [inner], with the first byte of [key] changed on the way.
class _Damaging implements SeasonPackSource {
  _Damaging(this.inner, this.key);
  final SeasonPackSource inner;
  final String key;

  @override
  Stream<List<int>> open(String objectKey) async* {
    var first = objectKey == key;
    await for (final chunk in inner.open(objectKey)) {
      if (first && chunk.isNotEmpty) {
        first = false;
        yield [chunk[0] ^ 0xff, ...chunk.skip(1)];
      } else {
        yield chunk;
      }
    }
  }
}
