import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:world_mystery/core/assets/season_pack_manifest.dart';

import '../asset_optimizer/image_file.dart';
import 'upload_plan.dart';

/// The R2 bucket the season packs are deployed to, and its public URL (the
/// app's `SeasonPackSetup.defaultUrl`; a test keeps the two the same).
/// shortcut: the r2.dev URL is for development; replace both with the custom
/// domain before release.
const packBucket = 'world-mystery-assets';
const packPublicUrl = 'https://pub-935cdbceccfe457a850a5a7e685faf42.r2.dev/';

/// What is wrong with [pack]'s files before they are deployed (empty:
/// nothing): each on disk, a picture the game reads (PNG or WebP), at the
/// size and SHA-256 its manifest names.
List<String> checkPackFiles(SeasonPackManifest pack) {
  final problems = <String>[];
  for (final f in pack.files) {
    final file = File(f.path);
    if (!file.existsSync()) {
      problems.add('missing: ${f.path}');
      continue;
    }
    final bytes = file.readAsBytesSync();
    if (bytes.length != f.bytes) problems.add('wrong size: ${f.path} (${bytes.length}, the manifest says ${f.bytes})');
    if (sha256.convert(bytes).toString() != f.sha256) problems.add('wrong SHA-256: ${f.path}');
    try {
      ImageFileCheck.bytes(bytes);
    } on ImageFileProblem catch (e) {
      problems.add('not a picture the game reads: ${f.path} (${e.message})');
    }
  }
  return problems;
}

/// Which of [keys] (key → its bytes) the bucket at [base] holds already: a
/// HEAD answered 200 at that size. 404 (or another size): not held. Anything
/// else throws: nothing is decided on a guess. Read-only, no credentials.
Future<Set<String>> heldKeys(Uri base, Map<String, int> keys, {HttpClient? client}) async {
  final http = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 20));
  try {
    final held = <String>{};
    for (final MapEntry(key: key, value: bytes) in keys.entries) {
      final response = await (await http.headUrl(base.resolve(key))).close();
      await response.drain<void>();
      if (response.statusCode == HttpStatus.ok) {
        if (response.contentLength == bytes) held.add(key);
      } else if (response.statusCode != HttpStatus.notFound) {
        throw HttpException('HEAD $key: HTTP ${response.statusCode}', uri: base.resolve(key));
      }
    }
    return held;
  } finally {
    if (client == null) http.close();
  }
}

/// How an upload of a staged folder ended: [sent] objects put, and the one
/// that failed (null: all of them).
typedef UploadResult = ({int sent, String? failed});

/// One object put in the bucket from [file]; true when it was.
typedef PutObject = Future<bool> Function(StagedObject object, String file);

/// The objects staged in [stageDir] put in the bucket one by one, in their
/// listed order (pictures first, the manifest last), stopping at the first
/// that fails: a manifest is never put before every file it names. [skip]: the
/// first objects, sent by an earlier try that stopped (not sent again).
Future<UploadResult> uploadStage(String stageDir, {PutObject put = wranglerPut, int skip = 0}) async {
  var sent = skip;
  for (final o in readStage(stageDir).skip(skip)) {
    if (!await put(o, '$stageDir/${o.key}')) return (sent: sent, failed: o.key);
    sent++;
  }
  return (sent: sent, failed: null);
}

/// [object] put in [packBucket] by wrangler (its login on this machine: no
/// key or token passes through here, none is printed).
Future<bool> wranglerPut(StagedObject object, String file) async {
  final r = await Process.run(
    'npx',
    ['--yes', 'wrangler', 'r2', 'object', 'put', '$packBucket/${object.key}', '--file', file, '--content-type', object.contentType, '--remote'],
    runInShell: true,
  );
  if (r.exitCode != 0) stderr.writeln('wrangler exit ${r.exitCode} for ${object.key}');
  return r.exitCode == 0;
}

/// What is wrong with the objects staged in [stageDir] as the bucket serves
/// them over HTTPS (empty: nothing): each 200, at its size, with the SHA-256
/// of the staged copy.
Future<List<String>> verifyLive(Uri base, String stageDir, {HttpClient? client}) async {
  final http = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 20));
  final problems = <String>[];
  try {
    for (final o in readStage(stageDir)) {
      final response = await (await http.getUrl(base.resolve(o.key))).close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        problems.add('HTTP ${response.statusCode}: ${o.key}');
        continue;
      }
      final body = <int>[];
      await response.forEach(body.addAll);
      if (body.length != o.bytes) problems.add('wrong size: ${o.key} (${body.length}, staged ${o.bytes})');
      final want = sha256.convert(File('$stageDir/${o.key}').readAsBytesSync()).toString();
      if (sha256.convert(body).toString() != want) problems.add('wrong SHA-256: ${o.key}');
    }
    return problems;
  } finally {
    if (client == null) http.close();
  }
}

/// A season's pack made ready to deploy (nothing sent): what is new to the
/// bucket, staged in [stageDir] in upload order; or why it is not
/// ([problems] not empty: nothing staged).
class PackStage {
  const PackStage({required this.pack, required this.problems, this.stageDir, this.newPictures = 0, this.newBytes = 0, this.newManifest = false, this.held = 0});

  final SeasonPackManifest pack;
  final List<String> problems;
  final String? stageDir;

  /// Pictures the bucket does not hold yet, their bytes, and whether this
  /// version's manifest is new to it; [held]: pictures it holds already.
  final int newPictures, newBytes, held;
  final bool newManifest;

  bool get ok => problems.isEmpty;
  bool get nothingToSend => ok && newPictures == 0 && !newManifest;
}

/// [pack] checked ([checkPackFiles]), compared with what the bucket holds
/// ([held]: [heldKeys] on [packPublicUrl] unless given) and staged under
/// [stageRoot]`/<folder>/<version>` (its objects new to the bucket only,
/// the manifest last, each staged copy checked). Nothing is sent, nothing
/// in the bucket is changed or removed.
Future<PackStage> stagePack(
  SeasonPackManifest pack, {
  required String stageRoot,
  Future<Set<String>> Function(Map<String, int> keys)? held,
}) async {
  final problems = checkPackFiles(pack);
  if (problems.isNotEmpty) return PackStage(pack: pack, problems: problems);
  final keys = {for (final f in pack.files) f.objectKey: f.bytes, pack.objectKey: utf8.encode(manifestBody(pack)).length};
  final Set<String> known;
  try {
    known = await (held ?? (k) => heldKeys(Uri.parse(packPublicUrl), k))(keys);
  } on Object catch (e) {
    return PackStage(pack: pack, problems: ['the bucket could not be asked what it holds: $e']);
  }
  final plan = planUpload([pack], known);
  final stageDir = '$stageRoot/${pack.folder}/${pack.version}';
  final out = Directory(stageDir);
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);
  writeStage(plan, stageDir);
  final staged = checkStage(stageDir);
  final pictures = plan.uploads.where((u) => u.key != pack.objectKey);
  return PackStage(
    pack: pack,
    problems: staged,
    stageDir: stageDir,
    newPictures: pictures.length,
    newBytes: pictures.fold(0, (sum, u) => sum + u.bytes),
    newManifest: plan.uploads.any((u) => u.key == pack.objectKey),
    held: plan.skippedObjects,
  );
}
