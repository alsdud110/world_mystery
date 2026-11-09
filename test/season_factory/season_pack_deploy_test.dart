import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/core/assets/season_pack_downloads.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';
import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';

import '../../tool/asset_pipeline/asset_pipeline.dart' show PubspecAssets;
import '../../tool/season_factory/season_factory.dart';
import '../../tool/season_packs/deploy.dart';
import '../../tool/season_packs/season_manifests.dart';
import '../../tool/season_packs/upload_plan.dart';

/// The season factory's way to the bucket (step 9, `packs`, `upload`): what
/// ships in the app, what is staged (only what the bucket lacks, the
/// manifest last), the checks before and after, and that nothing is sent
/// without approval. No real bucket: a local HTTPS-like server, fake puts.
void main() {
  late Directory tmp;
  setUpAll(() => HttpOverrides.global = null); // a real client for the local server
  setUp(() => tmp = Directory.systemTemp.createTempSync('season_deploy_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  final seoul = seasonPackManifests['season_05_seoul']!;
  SeasonPackManifest packOf(List<SeasonPackFile> files) =>
      SeasonPackManifest(folder: seoul.folder, version: SeasonPackManifest.versionOf(files), files: files);
  Map<String, int> allKeys(SeasonPackManifest p) =>
      {for (final f in p.files) f.objectKey: f.bytes, p.objectKey: utf8.encode(manifestBody(p)).length};

  group('what ships in the app', () {
    test('London whole, every season\'s cover; the downloaded seasons\' other pictures never', () {
      expect(bundledSeasonFolder, SeasonPack.london.folder);
      expect(packPublicUrl, SeasonPackSetup.defaultUrl, reason: 'the tools deploy where the app downloads from');
      expect(shipsInApp('assets/seasons/season_01_london/cases/case_01/'), isTrue);
      expect(shipsInApp('assets/seasons/season_02_paris/cover/'), isTrue);
      expect(shipsInApp('assets/seasons/season_06_tokyo/cover/a.webp'), isTrue, reason: 'a new season too');
      expect(shipsInApp('assets/seasons/season_02_paris/cases/case_01/'), isFalse);
      expect(shipsInApp('assets/seasons/season_05_seoul/locations/map/'), isFalse);
      expect(shipsInApp('assets/seasons/season_05_seoul/cases/case_11/c11_copy_list.webp'), isFalse, reason: 'in the Seoul pack since its upload');
      expect(shipsInApp('assets/seasons/season_05_seoul/cases/case_01/audio/eomma.m4a'), isTrue, reason: 'a voice: the pack holds pictures only');
      expect(shipsInApp('assets/shared/ui/'), isTrue);
    });

    test('the asset pipeline never lists a downloaded season\'s pictures in pubspec.yaml; its cover and London, yes', () {
      final pubspec = File('${tmp.path}/pubspec.yaml')
        ..writeAsStringSync('name: x\nflutter:\n  assets:\n    - assets/shared/ui/\n');
      final added = PubspecAssets.add(pubspec.path, {
        'assets/seasons/season_05_seoul/locations/',
        'assets/seasons/season_05_seoul/cover/',
        'assets/seasons/season_01_london/objects/',
      });
      expect(added, ['assets/seasons/season_01_london/objects/', 'assets/seasons/season_05_seoul/cover/']);
      expect(pubspec.readAsStringSync(), isNot(contains('season_05_seoul/locations/')));
    });
  });

  group('staging a pack', () {
    test('first time: every picture, then the manifest last; each staged copy checked', () async {
      final pack = packOf(seoul.files.take(3).toList());
      final stage = await stagePack(pack, stageRoot: tmp.path, held: (_) async => {});
      expect(stage.ok, isTrue, reason: stage.problems.join('\n'));
      expect((stage.newPictures, stage.newManifest, stage.held), (3, true, 0));
      expect(stage.newBytes, pack.totalBytes);
      final listed = readStage(stage.stageDir!);
      expect([for (final o in listed) o.key], [...pack.files.map((f) => f.objectKey), pack.objectKey]);
      expect(checkStage(stage.stageDir!), isEmpty);
    });

    test('made again with one picture changed: only that picture and the new manifest; the rest is held', () async {
      final before = packOf(seoul.files.take(3).toList());
      final held = allKeys(before).keys.toSet();
      final after = packOf([seoul.files[0], seoul.files[1], seoul.files[5]]); // the third picture is another one now
      final stage = await stagePack(after, stageRoot: tmp.path, held: (keys) async => held.intersection(keys.keys.toSet()));
      expect((stage.newPictures, stage.newManifest, stage.held), (1, true, 2));
      expect([for (final o in readStage(stage.stageDir!)) o.key], [seoul.files[5].objectKey, after.objectKey]);
      expect(after.version, isNot(before.version));
    });

    test('everything held already: nothing to send', () async {
      final pack = packOf(seoul.files.take(2).toList());
      final stage = await stagePack(pack, stageRoot: tmp.path, held: (keys) async => keys.keys.toSet());
      expect(stage.nothingToSend, isTrue);
      expect(readStage(stage.stageDir!), isEmpty);
    });

    test('a picture not as its manifest says, or not a picture: nothing is staged', () async {
      final f = seoul.files.first;
      final wrong = packOf([SeasonPackFile(f.path, f.bytes, 'ab' * 32)]);
      final asked = <Map<String, int>>[];
      final stage = await stagePack(wrong, stageRoot: tmp.path, held: (k) async {
        asked.add(k);
        return {};
      });
      expect(stage.ok, isFalse);
      expect(stage.problems.single, startsWith('wrong SHA-256'));
      expect(stage.stageDir, isNull);
      expect(asked, isEmpty, reason: 'the bucket is not even asked');

      final text = File('${tmp.path}/notes.webp')..writeAsStringSync('not a picture');
      final bytes = text.readAsBytesSync();
      final notPicture = packOf([SeasonPackFile(text.path, bytes.length, sha256Hex(bytes))]);
      expect((await stagePack(notPicture, stageRoot: tmp.path, held: (_) async => {})).problems.single, startsWith('not a picture'));
    });

    test('the bucket cannot be asked: stopped, nothing staged', () async {
      final stage = await stagePack(packOf(seoul.files.take(1).toList()), stageRoot: tmp.path, held: (_) => throw const SocketException('offline'));
      expect(stage.ok, isFalse);
      expect(stage.problems.single, contains('could not be asked'));
    });
  });

  group('the bucket over HTTPS (a local server)', () {
    late HttpServer server;
    late Uri base;
    final served = <String, List<int>>{};
    var failWith = 0;
    setUp(() async {
      served.clear();
      failWith = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://${server.address.address}:${server.port}/');
      server.listen((r) {
        final key = r.uri.path.substring(1);
        final body = served[key];
        r.response.statusCode = failWith != 0 ? failWith : body == null ? 404 : 200;
        if (body != null && failWith == 0) {
          r.response.contentLength = body.length;
          if (r.method != 'HEAD') r.response.add(body);
        }
        r.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    test('held: 200 at its size; 404 or another size: not held; any other answer stops', () async {
      served['objects/a.webp'] = [1, 2, 3];
      served['objects/b.webp'] = [1, 2];
      expect(await heldKeys(base, {'objects/a.webp': 3, 'objects/b.webp': 3, 'objects/c.webp': 1}), {'objects/a.webp'});
      failWith = 500;
      await expectLater(heldKeys(base, {'objects/a.webp': 3}), throwsA(isA<HttpException>()));
    });

    test('read back after the upload: every object 200, its size, its SHA-256', () async {
      final pack = packOf(seoul.files.take(2).toList());
      final stage = await stagePack(pack, stageRoot: tmp.path, held: (_) async => {});
      for (final o in readStage(stage.stageDir!)) {
        served[o.key] = File('${stage.stageDir}/${o.key}').readAsBytesSync();
      }
      expect(await verifyLive(base, stage.stageDir!), isEmpty);
      served[pack.files.first.objectKey] = [...served[pack.files.first.objectKey]!]..[100] ^= 0xff;
      served.remove(pack.objectKey);
      expect(await verifyLive(base, stage.stageDir!), [
        'wrong SHA-256: ${pack.files.first.objectKey}',
        'HTTP 404: ${pack.objectKey}',
      ]);
    });
  });

  group('the factory (Seoul\'s plans in a copy)', () {
    late String dir;
    setUp(() {
      dir = '${tmp.path.replaceAll(r'\', '/')}/s5_seoul';
      for (final f in ['season.plan.json', 'assets.manifest.json']) {
        File('content_pipeline/seasons/s5_seoul/$f').copySync((File('$dir/$f')..createSync(recursive: true)).path);
      }
    });

    test('packs: staged, nothing sent; upload without approval sends nothing; approved: pictures first, manifest last, read back, deployed', () async {
      final stageRoot = '${tmp.path}/stage';
      expect(await SeasonFactory.preparePack(dir, stageRoot: stageRoot, held: (_) async => {}), 0);
      final staged = SeasonFactory.deployOf(dir)!;
      expect(staged['status'], 'staged');
      expect((staged['folder'], staged['version'], staged['newPictures'], staged['newBytes'], staged['newManifest']),
          (seoul.folder, seoul.version, seoul.files.length, seoul.totalBytes, true));

      final put = <String>[];
      Future<bool> fake(StagedObject o, String file) async {
        put.add(o.key);
        return true;
      }

      expect(await SeasonFactory.upload(dir, approved: false, put: fake, verify: (_) async => []), 0);
      expect(put, isEmpty, reason: 'nothing sent without approval');
      expect(SeasonFactory.deployOf(dir)!['status'], 'staged');

      expect(await SeasonFactory.upload(dir, approved: true, put: fake, verify: (_) async => []), 0);
      expect(put.last, seoul.objectKey, reason: 'the manifest last');
      expect(put, hasLength(seoul.files.length + 1));
      expect(SeasonFactory.deployOf(dir)!['status'], 'deployed');
    });

    test('an upload that fails: the season untouched, upload_failed; the retry sends only what was not sent', () async {
      await SeasonFactory.preparePack(dir, stageRoot: '${tmp.path}/stage', held: (_) async => {});
      final put = <String>[];
      var failAt = 3;
      Future<bool> flaky(StagedObject o, String file) async {
        if (put.length == failAt) return false;
        put.add(o.key);
        return true;
      }

      expect(await SeasonFactory.upload(dir, approved: true, put: flaky, verify: (_) async => []), SeasonFactory.exitPacks);
      expect(SeasonFactory.deployOf(dir)!['status'], 'upload_failed');
      expect(put, hasLength(3));
      expect(put, isNot(contains(seoul.objectKey)), reason: 'no manifest before its pictures');

      failAt = -1;
      expect(await SeasonFactory.upload(dir, approved: true, put: flaky, verify: (_) async => []), 0);
      expect(put.toSet(), hasLength(seoul.files.length + 1), reason: 'each object sent once');
      expect(SeasonFactory.deployOf(dir)!['status'], 'deployed');
    });

    test('read back wrong: verify_failed, not deployed', () async {
      await SeasonFactory.preparePack(dir, stageRoot: '${tmp.path}/stage', held: (_) async => {});
      expect(await SeasonFactory.upload(dir, approved: true, put: (o, file) async => true, verify: (_) async => ['wrong size: x']), SeasonFactory.exitPacks);
      expect(SeasonFactory.deployOf(dir)!['status'], 'verify_failed');
    });

    test('the bucket holds all of it already: deployed without sending; the manifest the app ships is unchanged', () async {
      final before = File(generatedPath).readAsStringSync();
      expect(await SeasonFactory.preparePack(dir, stageRoot: '${tmp.path}/stage', held: (keys) async => keys.keys.toSet()), 0);
      expect(SeasonFactory.deployOf(dir)!['status'], 'deployed');
      expect(File(generatedPath).readAsStringSync(), before);
    });

    test('the bucket cannot be asked: blocked (exit 70), the season untouched', () async {
      expect(await SeasonFactory.preparePack(dir, stageRoot: '${tmp.path}/stage', held: (_) => throw const SocketException('offline')),
          SeasonFactory.exitPacks);
      expect(SeasonFactory.deployOf(dir)!['status'], 'blocked');
    });
  });
}

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();
