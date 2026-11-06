import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/core/assets/season_pack_downloads.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';
import 'package:world_mystery/core/assets/season_pack_storage.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/season/season_pack_gate.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/data/models/game_progress.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// A pack file for [bytes] (its object named by their SHA-256).
SeasonPackFile _file(String name, List<int> bytes) =>
    SeasonPackFile('assets/seasons/season_99_test/$name', bytes.length, sha256.convert(bytes).toString());

SeasonPackManifest _pack(List<SeasonPackFile> files) =>
    SeasonPackManifest(folder: 'season_99_test', version: SeasonPackManifest.versionOf(files), files: files);

/// A source over a folder, noting each object opened; [failAfter] bytes of
/// object [failKey] are sent before the connection drops.
class _Counting implements SeasonPackSource {
  _Counting(this.root);
  final Directory root;
  final opened = <String>[];
  String? failKey;
  int failAfter = 0;

  /// When set, each object sends one byte, then waits for it.
  Future<void>? hold;

  @override
  Stream<List<int>> open(String objectKey) async* {
    opened.add(objectKey);
    if (hold != null) {
      yield [0];
      await hold;
    }
    final bytes = File('${root.path}/$objectKey').readAsBytesSync();
    if (objectKey == failKey) {
      yield bytes.sublist(0, failAfter);
      throw const SocketException('connection dropped');
    }
    // In two chunks, as a download arrives.
    yield bytes.sublist(0, bytes.length ~/ 2);
    yield bytes.sublist(bytes.length ~/ 2);
  }
}

/// [files] (with their bytes) put in [root] as the bucket holds them.
void _publish(Directory root, Map<SeasonPackFile, List<int>> files) {
  for (final e in files.entries) {
    File('${root.path}/${e.key.objectKey}')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(e.value);
  }
}

/// A season pack's real files published from the app's assets.
void _publishPack(Directory root, SeasonPack pack) =>
    _publish(root, {for (final f in pack.manifest.files) f: File(f.path).readAsBytesSync()});

/// The app bundle with no season pictures in it (a build without them).
class _NoSeasonFiles extends AssetBundle {
  final asked = <String>[];

  @override
  Future<ByteData> load(String key) async {
    asked.add(key);
    if (SeasonPack.ofAsset(key) != null) throw FlutterError('not in the app: $key');
    return ByteData(1);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

/// An app bundle whose asset list (`AssetManifest.bin`) is [assets].
class _Listing extends AssetBundle {
  _Listing(this.assets);
  final Set<String> assets;

  @override
  Future<ByteData> load(String key) async => const StandardMessageCodec().encodeMessage({for (final a in assets) a: <Object>[]})!;

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

class _Playing extends SelectedSeasonNotifier {
  _Playing(this.seasonId);
  final String seasonId;

  @override
  String build() => seasonId;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp, bucket, device;
  late SharedPreferences prefs;
  late SeasonPackStorage storage;

  final a = [1, 2, 3, 4, 5], b = [9, 8, 7, 6], c = [42];
  final fa = _file('a.webp', a), fb = _file('b.webp', b), fc = _file('c.webp', c);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'progress.case': 'kept'});
    prefs = await SharedPreferences.getInstance();
    tmp = Directory.systemTemp.createTempSync('season_packs_');
    bucket = Directory('${tmp.path}/bucket')..createSync();
    device = Directory('${tmp.path}/device');
    storage = SeasonPackStorage(device, prefs);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> onDevice() => device.existsSync()
      ? ([for (final f in device.listSync(recursive: true).whereType<File>()) f.uri.pathSegments.last]..sort())
      : [];

  group('SeasonPackStorage', () {
    test('installs a pack: every file checked, kept under its SHA-256, recorded last', () async {
      _publish(bucket, {fa: a, fb: b});
      final pack = _pack([fa, fb]);
      final progress = <int>[];
      expect(storage.isInstalled(pack), isFalse);
      await storage.install(pack, _Counting(bucket), onProgress: (done, total) {
        expect(total, 9);
        progress.add(done);
      });
      expect(storage.isInstalled(pack), isTrue);
      expect(progress.last, 9);
      expect(onDevice(), ['${fa.sha256}.webp', '${fb.sha256}.webp']..sort());
      expect(storage.fileOf(pack, fb).readAsBytesSync(), b);
    });

    test('a file with other bytes is thrown away; the retry fetches only it', () async {
      _publish(bucket, {fa: a, fb: [9, 9, 9, 9]}); // b's size, other bytes
      final pack = _pack([fa, fb]);
      final source = _Counting(bucket);
      await expectLater(
        storage.install(pack, source),
        throwsA(isA<SeasonPackCorrupt>().having((e) => e.check, 'check', PackFileCheck.wrongHash)),
      );
      expect(storage.isInstalled(pack), isFalse);
      expect(onDevice(), ['${fa.sha256}.webp'], reason: 'the bad file is not kept, not even as .part');

      _publish(bucket, {fb: b});
      source.opened.clear();
      await storage.install(pack, source);
      expect(source.opened, [fb.objectKey]);
      expect(storage.isInstalled(pack), isTrue);
    });

    test('a file cut short is the wrong size', () async {
      _publish(bucket, {fa: [1, 2]});
      await expectLater(
        storage.install(_pack([fa]), _Counting(bucket)),
        throwsA(isA<SeasonPackCorrupt>().having((e) => e.check, 'check', PackFileCheck.wrongSize)),
      );
      expect(onDevice(), isEmpty);
    });

    test('a dropped connection: not installed; downloaded again from the files missing', () async {
      _publish(bucket, {fa: a, fb: b, fc: c});
      final pack = _pack([fa, fb, fc]);
      final source = _Counting(bucket)
        ..failKey = fb.objectKey
        ..failAfter = 2;
      await expectLater(storage.install(pack, source), throwsA(isA<SocketException>()));
      expect(storage.isInstalled(pack), isFalse);

      source
        ..failKey = null
        ..opened.clear();
      await storage.install(pack, source);
      expect(source.opened, [fb.objectKey, fc.objectKey]);
      expect(storage.isInstalled(pack), isTrue);
      expect(onDevice().where((n) => n.endsWith('.part')), isEmpty);
    });

    test('stopped by the player: not installed, resumed later', () async {
      _publish(bucket, {fa: a, fb: b});
      final pack = _pack([fa, fb]);
      final cancel = SeasonPackCancel();
      await expectLater(
        storage.install(pack, _Counting(bucket), cancel: cancel, onProgress: (done, _) => done >= 5 ? cancel.cancel() : null),
        throwsA(isA<SeasonPackCancelled>()),
      );
      expect(storage.isInstalled(pack), isFalse);
      await storage.install(pack, _Counting(bucket));
      expect(storage.isInstalled(pack), isTrue);
    });

    test('a new version fetches only changed files and drops the old ones', () async {
      _publish(bucket, {fa: a, fb: b, fc: c});
      final v1 = _pack([fa, fb]), v2 = _pack([fa, fc]);
      await storage.install(v1, _Counting(bucket));
      final source = _Counting(bucket);
      expect(storage.isInstalled(v2), isFalse);
      await storage.install(v2, source);
      expect(source.opened, [fc.objectKey]);
      expect(onDevice(), ['${fa.sha256}.webp', '${fc.sha256}.webp']..sort());
      expect(storage.isInstalled(v1), isFalse);
    });

    test('deleting a pack removes its files and record, never the progress', () async {
      _publish(bucket, {fa: a});
      final pack = _pack([fa]);
      await storage.install(pack, _Counting(bucket));
      await storage.delete(pack);
      expect(storage.isInstalled(pack), isFalse);
      expect(onDevice(), isEmpty);
      expect(prefs.getString('progress.case'), 'kept');
    });

    test('a file gone from the device (its record kept): not intact; the next install fetches only it', () async {
      _publish(bucket, {fa: a, fb: b});
      final pack = _pack([fa, fb]);
      await storage.install(pack, _Counting(bucket));
      expect(storage.isIntact(pack), isTrue);

      storage.fileOf(pack, fb).deleteSync();
      expect(storage.isInstalled(pack), isTrue, reason: 'the record alone');
      expect(storage.isIntact(pack), isFalse);
      storage.fileOf(pack, fa).writeAsBytesSync([1]); // a's file cut short
      expect(storage.isIntact(pack), isFalse);

      final source = _Counting(bucket);
      await storage.install(pack, source);
      expect(source.opened, [fa.objectKey, fb.objectKey]);
      expect(storage.isIntact(pack), isTrue);
      expect(prefs.getString('progress.case'), 'kept');
    });

    test('not enough free space: nothing is downloaded; with room, it is', () async {
      _publish(bucket, {fa: a, fb: b});
      final pack = _pack([fa, fb]);
      var free = SeasonPackStorage.spare; // 9 bytes short of the pack and its spare room
      final tight = SeasonPackStorage(device, prefs, freeSpace: () async => free);
      final source = _Counting(bucket);
      await expectLater(tight.install(pack, source), throwsA(isA<SeasonPackNoSpace>().having((e) => e.needed, 'needed', 9)));
      expect(source.opened, isEmpty);
      expect(tight.isInstalled(pack), isFalse);

      free = SeasonPackStorage.spare + 9;
      await tight.install(pack, source);
      expect(tight.isIntact(pack), isTrue);
      // Installed: nothing to download, the free space is not asked again.
      free = 0;
      await tight.install(pack, source);
    });

    test('a write refused because the device is full is told apart from other file errors', () {
      final full = Platform.isWindows ? 112 : 28;
      expect(isNoSpace(FileSystemException('write', 'x', OSError('full', full))), isTrue);
      expect(isNoSpace(const FileSystemException('write', 'x', OSError('denied', 13))), isFalse);
      expect(isNoSpace(const FileSystemException('write', 'x')), isFalse);
    });
  });

  group('the device', () {
    test('iOS: the packs\' folder is excluded from backup; the free space is asked for the same folder', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(seasonPackChannel, (call) async {
        calls.add(call);
        return call.method == 'freeBytes' ? 123456789 : null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(seasonPackChannel, null));
      await excludeFromBackup(device);
      expect(await freeBytes(device), 123456789);
      expect([for (final c in calls) (c.method, c.arguments)], [('excludeFromBackup', device.path), ('freeBytes', device.path)]);
    });

    test('a device that cannot say: no exclusion, free space unknown, no error', () async {
      // No handler: MissingPluginException, as on a platform without it.
      await excludeFromBackup(device);
      expect(await freeBytes(device), isNull);
    });
  });

  group('reading the pictures', () {
    test('a downloaded pack is read from the device, offline; before it, the app copy', () async {
      final app = _NoSeasonFiles();
      final bundle = SeasonPackBundle(app: app, store: DownloadedSeasonPacks(storage));
      final picture = SeasonPack.seoul.manifest.files.first;
      await expectLater(bundle.load(picture.path), throwsA(isA<FlutterError>()), reason: 'not installed: the app copy is read');

      _publishPack(bucket, SeasonPack.seoul);
      await storage.install(SeasonPack.seoul.manifest, DirectorySeasonPackSource(bucket));
      bucket.deleteSync(recursive: true); // no source any more: offline
      app.asked.clear();
      final bytes = await bundle.load(picture.path);
      expect(Uint8List.sublistView(bytes), File(picture.path).readAsBytesSync());
      expect(app.asked, isEmpty);
      final buffer = await bundle.loadBuffer(picture.path);
      expect(buffer.length, picture.bytes);

      // London and app files still come from the app.
      await bundle.load('assets/shared/x.webp');
      expect(app.asked, ['assets/shared/x.webp']);
    });

    test('a downloaded file gone from the device falls back to the app copy', () async {
      _publishPack(bucket, SeasonPack.seoul);
      await storage.install(SeasonPack.seoul.manifest, DirectorySeasonPackSource(bucket));
      final picture = SeasonPack.seoul.manifest.files.first;
      storage.fileOf(SeasonPack.seoul.manifest, picture).deleteSync();
      expect(await DownloadedSeasonPacks(storage).load(SeasonPack.seoul, picture.path), isNull);
    });
  });

  group('which seasons are downloaded', () {
    ProviderContainer containerWith(SeasonPackSetup? setup, {String playing = SeasonIds.london, bool inApp = true}) =>
        ProviderContainer(
          overrides: [
            seasonPackSetupProvider.overrideWithValue(setup),
            selectedSeasonIdProvider.overrideWith(() => _Playing(playing)),
            seasonPacksInAppProvider.overrideWithValue(inApp),
          ],
        );

    test('without a download URL nothing is downloaded: every season plays from the app', () {
      final container = containerWith(null, playing: SeasonIds.seoul);
      addTearDown(container.dispose);
      for (final p in SeasonPack.all) {
        expect(container.read(seasonPacksProvider.notifier).needsDownload(p.seasonId), isFalse);
      }
      expect(container.read(seasonPackBundleProvider).store, isA<BundledSeasonPacks>());
      expect(container.read(Provider((ref) => seasonPackRedirect(ref, Routes.map))), isNull);
    });

    test('no download URL and the pictures not in the app: only London plays; the others are never read', () {
      final container = containerWith(null, playing: SeasonIds.paris, inApp: false);
      addTearDown(container.dispose);
      final packs = container.read(seasonPacksProvider.notifier);
      expect(packs.isMissing(SeasonIds.london), isFalse);
      expect(packs.needsDownload(SeasonIds.london), isFalse);
      for (final id in [SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork, SeasonIds.seoul]) {
        expect(packs.isMissing(id), isTrue, reason: id);
        expect(packs.needsDownload(id), isTrue, reason: id);
        expect(packs.downloadOf(id), isNull, reason: id);
      }
      String? redirect(String path) => container.read(Provider((ref) => seasonPackRedirect(ref, path)));
      expect(redirect(Routes.map), Routes.worldMap);
      expect(redirect(Routes.worldMap), isNull);
    });

    test('the app lists its packs: all of them, or none once they are downloaded instead', () async {
      expect(await seasonPacksInApp(_Listing({for (final p in SeasonPack.all) for (final f in p.manifest.files) f.path})), isTrue);
      final bundled = {...SeasonPack.london.manifest.files.map((f) => f.path), for (final p in SeasonPack.all) for (final f in p.manifest.files) if (f.path.contains('/cover/')) f.path};
      expect(await seasonPacksInApp(_Listing(bundled)), isFalse);
    });

    test('London is in the app; the others until downloaded; deleting keeps the progress', () async {
      final container = containerWith(SeasonPackSetup(storage, DirectorySeasonPackSource(bucket)), playing: SeasonIds.seoul);
      addTearDown(container.dispose);
      final packs = container.read(seasonPacksProvider.notifier);
      expect(packs.needsDownload(SeasonIds.london), isFalse);
      for (final id in [SeasonIds.paris, SeasonIds.rome, SeasonIds.newyork, SeasonIds.seoul]) {
        expect(packs.needsDownload(id), isTrue, reason: id);
      }
      expect(container.read(seasonPackBundleProvider).store, isA<DownloadedSeasonPacks>());

      // Playing Seoul without its pack: its pages go back to the World Map.
      String? redirect(String path) => container.read(Provider((ref) => seasonPackRedirect(ref, path)));
      for (final path in [Routes.season, Routes.map, Routes.mission('s5m1'), Routes.solved, Routes.episodes]) {
        expect(redirect(path), Routes.worldMap, reason: path);
      }
      for (final path in [Routes.worldMap, Routes.seasons, Routes.start, Routes.howToPlay]) {
        expect(redirect(path), isNull, reason: path);
      }

      _publishPack(bucket, SeasonPack.seoul);
      await packs.download(SeasonIds.seoul);
      expect(packs.needsDownload(SeasonIds.seoul), isFalse);
      expect(container.read(seasonPacksProvider), {SeasonPack.seoul.folder});
      expect(redirect(Routes.map), isNull);

      await packs.delete(SeasonIds.seoul);
      expect(packs.needsDownload(SeasonIds.seoul), isTrue);
      expect(redirect(Routes.map), Routes.worldMap);
      expect(prefs.getString('progress.case'), 'kept');
    });

    test('a pack whose files are gone: not installed at start, or once looked at again; its progress kept', () async {
      _publishPack(bucket, SeasonPack.seoul);
      await storage.install(SeasonPack.seoul.manifest, DirectorySeasonPackSource(bucket));
      final setup = SeasonPackSetup(storage, DirectorySeasonPackSource(bucket));

      // Gone while the app was running: seen when the season is entered.
      final running = containerWith(setup);
      addTearDown(running.dispose);
      final packs = running.read(seasonPacksProvider.notifier);
      expect(packs.needsDownload(SeasonIds.seoul), isFalse);
      storage.fileOf(SeasonPack.seoul.manifest, SeasonPack.seoul.manifest.files[5]).deleteSync();
      packs.recheck(SeasonIds.seoul);
      expect(packs.needsDownload(SeasonIds.seoul), isTrue);

      // Gone before the app started.
      final again = containerWith(setup);
      addTearDown(again.dispose);
      expect(again.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isTrue);

      final source = _Counting(bucket);
      await again.read(seasonPacksProvider.notifier).download(SeasonIds.seoul);
      expect(again.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isFalse);
      await storage.install(SeasonPack.seoul.manifest, source);
      expect(source.opened, isEmpty, reason: 'whole again');
      expect(prefs.getString('progress.case'), 'kept');
    });

    test('a pack installed earlier is ready when the app starts again', () async {
      _publishPack(bucket, SeasonPack.seoul);
      await storage.install(SeasonPack.seoul.manifest, DirectorySeasonPackSource(bucket));
      final container = containerWith(SeasonPackSetup(SeasonPackStorage(device, prefs), DirectorySeasonPackSource(bucket)));
      addTearDown(container.dispose);
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isFalse);
    });
  });

  testWidgets('downloads on, nothing installed: the World Map and the archives read no picture of those seasons but their covers', (t) async {
    // Every asset the app asks for, served as flutter_test_config.dart does.
    final asked = <String>[];
    final assets = Platform.environment['UNIT_TEST_ASSETS']!;
    t.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      asked.add(key);
      final file = [File('$assets/$key'), File(key)].where((f) => f.existsSync()).firstOrNull;
      return file == null ? null : ByteData.sublistView(file.readAsBytesSync());
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null));
    t.view.physicalSize = const Size(360, 640) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    late WidgetRef app;
    final saves = {AppConstants.progressStorageKey: jsonEncode(GameProgress(detectiveName: 'MINYOUNG', introSeen: true).toJson())};
    await t.pumpWidget(ProviderScope(
      overrides: [
        ...await testOverrides(prefs: saves),
        seasonPackSetupProvider.overrideWithValue(SeasonPackSetup(storage, DirectorySeasonPackSource(bucket))),
      ],
      child: Consumer(builder: (context, ref, _) {
        app = ref;
        return const WorldMysteryApp();
      }),
    ));
    String path() => app.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
    for (final to in [Routes.worldMap, Routes.seasons, Routes.worldMap]) {
      app.read(routerProvider).go(to);
      await wait(t, const Duration(milliseconds: 800));
    }
    expect(path(), Routes.worldMap);

    final read = [
      for (final key in asked)
        if (SeasonPack.ofAsset(key) case final p? when p != SeasonPack.london && !key.startsWith('${p.root}cover/')) key,
    ];
    expect(read, isEmpty);
    expect(asked.where((k) => k.contains('/cover/')), isNotEmpty, reason: 'the covers are shown, from the app');
  });

  group('the download dialog', () {
    late _Counting source;
    late ProviderContainer container;
    bool? answer;

    Future<void> openDialog(WidgetTester tester) async {
      source = _Counting(bucket);
      container = ProviderContainer(overrides: [seasonPackSetupProvider.overrideWithValue(SeasonPackSetup(storage, source))]);
      addTearDown(container.dispose);
      answer = null;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => answer = await showDialog<bool>(
                  context: context,
                  builder: (_) => const SeasonDownloadDialog(seasonId: SeasonIds.seoul),
                ),
                child: const Text('ENTER SEOUL'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ENTER SEOUL'));
      await tester.pumpAndSettle();
    }

    /// Lets the file reads run until [done] (or a few seconds).
    Future<void> settleIo(WidgetTester tester, bool Function() done, {int tries = 300}) async {
      for (var i = 0; i < tries && !done(); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    final size = megabytes(SeasonPack.seoul.manifest.totalBytes);

    testWidgets('asks first with the season and its size; Not now downloads nothing', (tester) async {
      await openDialog(tester);
      expect(find.text('Download Seoul?'), findsOneWidget);
      expect(find.textContaining(size), findsWidgets);
      expect(find.textContaining('On mobile data, this download uses your data plan.'), findsOneWidget);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
      expect(source.opened, isEmpty);
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isTrue);
    });

    testWidgets('a failed download offers TRY AGAIN; the retry finishes and the season opens', (tester) async {
      await tester.runAsync(() async => _publishPack(bucket, SeasonPack.seoul));
      final broken = SeasonPack.seoul.manifest.files[3];
      await openDialog(tester);
      source
        ..failKey = broken.objectKey
        ..failAfter = 100;
      await tester.tap(find.byKey(const ValueKey('season-download-go')));
      await settleIo(tester, () => find.text('TRY AGAIN').evaluate().isNotEmpty);
      expect(find.text('The download stopped'), findsOneWidget);
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isTrue);

      source
        ..failKey = null
        ..opened.clear();
      await tester.tap(find.text('TRY AGAIN'));
      await settleIo(tester, () => answer != null);
      expect(answer, isTrue);
      expect(source.opened.first, broken.objectKey, reason: 'the files already checked are kept');
      expect(source.opened, hasLength(SeasonPack.seoul.manifest.files.length - 3));
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isFalse);
    });

    testWidgets('a full device: "Not enough space", not the connection; with room, TRY AGAIN finishes', (tester) async {
      await tester.runAsync(() async => _publishPack(bucket, SeasonPack.seoul));
      var free = 0;
      storage = SeasonPackStorage(device, prefs, freeSpace: () async => free);
      await openDialog(tester);
      await tester.tap(find.byKey(const ValueKey('season-download-go')));
      await settleIo(tester, () => find.text('TRY AGAIN').evaluate().isNotEmpty);
      expect(find.text('Not enough space'), findsOneWidget);
      expect(find.textContaining('free space'), findsOneWidget);
      expect(find.text('The download stopped'), findsNothing);
      expect(source.opened, isEmpty);

      free = 1 << 40;
      await tester.tap(find.text('TRY AGAIN'));
      await settleIo(tester, () => answer != null, tries: 1500); // the whole pack this time
      expect(answer, isTrue);
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isFalse);
    });

    testWidgets('Stop closes it during the download and nothing is installed', (tester) async {
      final hold = Completer<void>();
      await tester.runAsync(() async => _publishPack(bucket, SeasonPack.seoul));
      await openDialog(tester);
      // The first file never finishes until the test lets it.
      source.hold = hold.future;
      await tester.tap(find.byKey(const ValueKey('season-download-go')));
      await tester.pump();
      expect(find.byKey(const ValueKey('season-download-progress')), findsOneWidget);
      expect(find.text('Downloading Seoul'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('season-download-stop')));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
      hold.complete();
      // The stopped download ends at its next chunk and closes its file.
      var waited = 0;
      await settleIo(tester, () => ++waited > 10);
      expect(container.read(seasonPacksProvider.notifier).needsDownload(SeasonIds.seoul), isTrue);
      expect(storage.isInstalled(SeasonPack.seoul.manifest), isFalse);
    });
  });
}

