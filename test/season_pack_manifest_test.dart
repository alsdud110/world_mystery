import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';
import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';

import '../tool/asset_optimizer/bundle_assets.dart';
import '../tool/season_packs/season_manifests.dart';
import '../tool/season_packs/upload_plan.dart';

// SHA-256 of "abc" (FIPS 180-2) and of no bytes.
const _abcSha = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
const _emptySha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

SeasonPackManifest _pack(String folder, List<SeasonPackFile> files) =>
    SeasonPackManifest(folder: folder, version: SeasonPackManifest.versionOf(files), files: files);

void main() {
  group('PackFileVerifier', () {
    const abc = SeasonPackFile('assets/seasons/season_01_london/a.webp', 3, _abcSha);

    test('the right bytes pass, whole or in chunks', () async {
      expect(PackFileVerifier.check(abc, utf8.encode('abc')), PackFileCheck.ok);
      expect(await PackFileVerifier.checkStream(abc, Stream.fromIterable([[0x61], [0x62, 0x63]])), PackFileCheck.ok);
      const empty = SeasonPackFile('assets/seasons/season_01_london/e.webp', 0, _emptySha);
      expect(PackFileVerifier.check(empty, const []), PackFileCheck.ok);
      expect(await PackFileVerifier.checkStream(empty, const Stream.empty()), PackFileCheck.ok);
    });

    test('a file cut short or too long is the wrong size', () async {
      expect(PackFileVerifier.check(abc, utf8.encode('ab')), PackFileCheck.wrongSize);
      expect(PackFileVerifier.check(abc, utf8.encode('abcd')), PackFileCheck.wrongSize);
      expect(await PackFileVerifier.checkStream(abc, Stream.value(utf8.encode('ab'))), PackFileCheck.wrongSize);
    });

    test('the right size with other bytes is the wrong hash', () async {
      expect(PackFileVerifier.check(abc, utf8.encode('abd')), PackFileCheck.wrongHash);
      expect(await PackFileVerifier.checkStream(abc, Stream.fromIterable([[0x61, 0x62], [0x64]])), PackFileCheck.wrongHash);
    });

    test('a stream that fails is not passed', () {
      expect(PackFileVerifier.checkStream(abc, Stream.error(const FileSystemException('gone'))), throwsA(isA<FileSystemException>()));
    });
  });

  group('SeasonPackManifest', () {
    test('a file\'s object is named by its content and keeps its extension', () {
      expect(const SeasonPackFile('assets/seasons/season_01_london/x/A.WEBP', 3, _abcSha).objectKey, 'objects/$_abcSha.webp');
      expect(const SeasonPackFile('assets/seasons/season_01_london/x.y/noext', 3, _abcSha).objectKey, 'objects/$_abcSha');
    });

    test('the version follows the files, not their order', () {
      const a = SeasonPackFile('assets/seasons/s/a.webp', 3, _abcSha), b = SeasonPackFile('assets/seasons/s/b.webp', 0, _emptySha);
      final v = SeasonPackManifest.versionOf([a, b]);
      expect(v, hasLength(16));
      expect(SeasonPackManifest.versionOf([b, a]), v);
      expect(SeasonPackManifest.versionOf([a]), isNot(v));
      expect(SeasonPackManifest.versionOf([a, const SeasonPackFile('assets/seasons/s/b.webp', 0, _abcSha)]), isNot(v));
      expect(_pack('s', [a, b]).objectKey, 'manifests/s/$v.json');
    });

    test('JSON round trip', () {
      final p = _pack('season_05_seoul', const [SeasonPackFile('assets/seasons/season_05_seoul/a.webp', 3, _abcSha)]);
      final back = SeasonPackManifest.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, Object?>);
      expect((back.folder, back.version), (p.folder, p.version));
      expect(back.files, p.files);
      expect(p.toJson()['totalBytes'], 3);
    });
  });

  group('planUpload', () {
    const a = SeasonPackFile('assets/seasons/s1/a.webp', 3, _abcSha);
    const sameAsA = SeasonPackFile('assets/seasons/s2/copy.webp', 3, _abcSha);
    const b = SeasonPackFile('assets/seasons/s2/b.webp', 0, _emptySha);

    test('the same content is uploaded once, manifests after every file', () {
      final plan = planUpload([_pack('s1', [a]), _pack('s2', [b, sameAsA])], {});
      expect([for (final u in plan.uploads) u.key], ['objects/$_abcSha.webp', 'objects/$_emptySha.webp', _pack('s1', [a]).objectKey, _pack('s2', [b, sameAsA]).objectKey]);
      expect((plan.skippedObjects, plan.skippedBytes), (1, 3));
      expect(plan.uploads.first.contentType, 'image/webp');
      expect(plan.uploads.first.source, a.path);
      expect(SeasonPackManifest.fromJson(jsonDecode(plan.uploads.last.body!) as Map<String, Object?>).files, [b, sameAsA]);
    });

    test('only a changed file and the new version go up', () {
      final v1 = _pack('s1', [a, b]);
      final known = {for (final u in planUpload([v1], {}).uploads) u.key};
      expect(planUpload([v1], known).uploads, isEmpty);

      final changed = SeasonPackFile('assets/seasons/s1/a.webp', 4, 'ab' * 32);
      final v2 = _pack('s1', [changed, b]);
      expect(v2.version, isNot(v1.version));
      final plan = planUpload([v2], known);
      expect([for (final u in plan.uploads) u.key], [changed.objectKey, v2.objectKey]);
      expect((plan.skippedObjects, plan.skippedBytes), (1, 0));
    });
  });

  group('the manifests the app is built with', () {
    test('the app ships London and every season cover; the downloaded seasons\' other files only from the bucket', () {
      final shipped = {for (final f in BundleAssets.list()) f.path};
      for (final pack in SeasonPack.all) {
        for (final f in pack.manifest.files) {
          final inApp = pack == SeasonPack.london || f.path.startsWith('${pack.root}cover/');
          expect(shipped.contains(f.path), inApp, reason: f.path);
        }
      }
    });

    test('match every season file on disk: path, size, SHA-256, version', () {
      final measured = measureSeasonPacks();
      expect(measured.map((p) => p.folder), seasonPackManifests.keys);
      for (final p in measured) {
        final built = seasonPackManifests[p.folder]!;
        expect(built.files, p.files, reason: '${p.folder}: run dart run tool/season_packs/build_manifest.dart');
        expect(built.version, p.version);
        expect(built.version, SeasonPackManifest.versionOf(built.files));
      }
    });

    test('each SeasonPack has its manifest, and each file belongs to that pack', () {
      expect([for (final p in SeasonPack.all) p.folder]..sort(), seasonPackManifests.keys.toList()..sort());
      for (final pack in SeasonPack.all) {
        expect(pack.manifest.files, isNotEmpty);
        for (final f in pack.manifest.files) {
          expect(SeasonPack.ofAsset(f.path), pack, reason: f.path);
          expect(f.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
        }
      }
    });

    test('the generated file is what the generator writes', () {
      expect(File(generatedPath).readAsStringSync().replaceAll('\r\n', '\n'), renderManifests(measureSeasonPacks()));
    });
  });
}
