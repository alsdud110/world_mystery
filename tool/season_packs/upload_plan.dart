import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';

/// One object to put in the bucket.
class UploadItem {
  const UploadItem({required this.key, required this.contentType, required this.bytes, this.source, this.body});

  final String key;
  final String contentType;
  final int bytes;

  /// The file it is copied from (a pack file), or null: [body] is the object.
  final String? source;
  final String? body;
}

/// What a deploy puts in the bucket: only objects it does not hold yet.
class UploadPlan {
  UploadPlan({required this.uploads, required this.skippedObjects, required this.skippedBytes});

  final List<UploadItem> uploads;

  /// Pack files whose object the bucket already holds (unchanged, or the same
  /// bytes under another path or pack), and the bytes not sent again.
  final int skippedObjects;
  final int skippedBytes;

  int get uploadBytes => uploads.fold(0, (sum, u) => sum + u.bytes);
}

String contentTypeOf(String key) => switch (key.substring(key.lastIndexOf('.') + 1).toLowerCase()) {
      'webp' => 'image/webp',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'json' => 'application/json',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };

/// [packs] against the keys the bucket already holds ([known]): each file
/// object at most once, then each pack's manifest for its version.
UploadPlan planUpload(Iterable<SeasonPackManifest> packs, Set<String> known) {
  final uploads = <UploadItem>[];
  final planned = <String>{};
  var skippedObjects = 0, skippedBytes = 0;
  for (final pack in packs) {
    for (final f in pack.files) {
      final key = f.objectKey;
      if (known.contains(key) || planned.contains(key)) {
        skippedObjects++;
        skippedBytes += f.bytes;
        continue;
      }
      planned.add(key);
      uploads.add(UploadItem(key: key, contentType: contentTypeOf(key), bytes: f.bytes, source: f.path));
    }
  }
  // Manifests last: a version is listed only once every file it names is up.
  for (final pack in packs) {
    if (known.contains(pack.objectKey)) continue;
    final body = manifestBody(pack);
    uploads.add(UploadItem(key: pack.objectKey, contentType: 'application/json', bytes: utf8.encode(body).length, body: body));
  }
  return UploadPlan(uploads: uploads, skippedObjects: skippedObjects, skippedBytes: skippedBytes);
}

/// [pack]'s manifest object, as the bucket holds it.
String manifestBody(SeasonPackManifest pack) => const JsonEncoder.withIndent('  ').convert(pack.toJson());

/// The file listing a staged folder's objects in upload order.
const uploadListName = 'upload_list.tsv';

/// [plan]'s objects laid out in [stageDir] as the bucket holds them, and
/// [uploadListName] listing them in upload order (key, content type, bytes).
void writeStage(UploadPlan plan, String stageDir) {
  final list = StringBuffer('key\tcontent_type\tbytes\n');
  for (final u in plan.uploads) {
    final out = File('$stageDir/${u.key}')..parent.createSync(recursive: true);
    if (u.source != null) {
      File(u.source!).copySync(out.path);
    } else {
      out.writeAsStringSync(u.body!);
    }
    list.writeln('${u.key}\t${u.contentType}\t${u.bytes}');
  }
  File('$stageDir/$uploadListName').writeAsStringSync(list.toString());
}

/// A staged object, as [uploadListName] lists it.
typedef StagedObject = ({String key, String contentType, int bytes});

/// The objects [uploadListName] in [stageDir] lists, in upload order.
List<StagedObject> readStage(String stageDir) => [
  for (final line in File('$stageDir/$uploadListName').readAsLinesSync().skip(1))
    if (line.split('\t') case [final key, final contentType, final bytes]) (key: key, contentType: contentType, bytes: int.parse(bytes)),
];

/// What is wrong with the objects staged in [stageDir] (empty: nothing):
/// each listed, at its size; a file object's SHA-256 the one its key names.
List<String> checkStage(String stageDir) {
  final problems = <String>[];
  for (final o in readStage(stageDir)) {
    final f = File('$stageDir/${o.key}');
    if (!f.existsSync()) {
      problems.add('missing: ${o.key}');
      continue;
    }
    final bytes = f.readAsBytesSync();
    if (bytes.length != o.bytes) problems.add('wrong size: ${o.key} (${bytes.length}, listed ${o.bytes})');
    if (objectSha256(o.key) case final want? when sha256.convert(bytes).toString() != want) problems.add('wrong SHA-256: ${o.key}');
  }
  return problems;
}

/// The SHA-256 a file object's key names (`objects/<sha256>.<ext>`), or
/// null for a manifest.
String? objectSha256(String key) =>
    RegExp(r'^objects/([0-9a-f]{64})\.[a-z0-9]+$').firstMatch(key)?.group(1);
