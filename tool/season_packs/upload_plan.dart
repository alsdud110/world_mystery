import 'dart:convert';

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
    final body = const JsonEncoder.withIndent('  ').convert(pack.toJson());
    uploads.add(UploadItem(key: pack.objectKey, contentType: 'application/json', bytes: utf8.encode(body).length, body: body));
  }
  return UploadPlan(uploads: uploads, skippedObjects: skippedObjects, skippedBytes: skippedBytes);
}
