import 'dart:io';

import 'package:world_mystery/core/assets/season_pack_manifest.dart';
import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';

import 'upload_plan.dart';

/// Prepares the season packs for Cloudflare R2. It never connects to R2: it
/// plans the upload and, with `--stage`, lays the objects out in a folder the
/// way the bucket holds them, for an uploader to send as listed.
///
///   dart run tool/season_packs/stage_packs.dart
///       [--season season_02_paris]...   only these packs (default: all)
///       [--known keys.txt]              keys the bucket holds, one per line
///       [--stage build/season_packs]    write the objects and upload_list.tsv
///
/// Bucket layout:
///   `objects/<sha256>.<ext>`              one per distinct file content
///   `manifests/<folder>/<version>.json`   one per pack version
///
/// Every file is checked against the manifest the app is built with
/// (lib/core/assets/season_pack_manifests.g.dart) first: a pack whose
/// pictures changed since is refused until the manifest is rebuilt.
Future<void> main(List<String> args) async {
  String? valueOf(String flag) {
    final i = args.indexOf(flag);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final seasons = [for (var i = 0; i < args.length - 1; i++) if (args[i] == '--season') args[i + 1]];
  final knownPath = valueOf('--known'), stagePath = valueOf('--stage');

  final unknown = seasons.where((s) => !seasonPackManifests.containsKey(s)).toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('No such pack: ${unknown.join(', ')} (have: ${seasonPackManifests.keys.join(', ')})');
    exitCode = 2;
    return;
  }
  final packs = [for (final e in seasonPackManifests.entries) if (seasons.isEmpty || seasons.contains(e.key)) e.value];

  final bad = <String>[];
  for (final pack in packs) {
    for (final f in pack.files) {
      final file = File(f.path);
      final check = file.existsSync() ? await PackFileVerifier.checkStream(f, file.openRead()) : PackFileCheck.wrongSize;
      if (check != PackFileCheck.ok) bad.add('${check.name}: ${f.path}');
    }
  }
  if (bad.isNotEmpty) {
    stderr
      ..writeln('The manifest does not match the files on disk (run dart run tool/season_packs/build_manifest.dart):')
      ..writeln(bad.map((b) => '  $b').join('\n'));
    exitCode = 1;
    return;
  }

  final known = knownPath == null
      ? <String>{}
      : {for (final l in File(knownPath).readAsLinesSync()) if (l.trim().isNotEmpty) l.trim()};
  final plan = planUpload(packs, known);

  for (final p in packs) {
    stdout.writeln('${p.folder.padRight(18)} ${p.files.length.toString().padLeft(4)} files '
        '${p.totalBytes.toString().padLeft(11)} bytes  v${p.version}');
  }
  stdout.writeln('To upload: ${plan.uploads.length} objects, ${plan.uploadBytes} bytes; '
      'already held or duplicate: ${plan.skippedObjects} files, ${plan.skippedBytes} bytes.');

  if (stagePath == null) return stdout.writeln('Plan only (no --stage): nothing written.');
  final list = StringBuffer('key\tcontent_type\tbytes\n');
  for (final u in plan.uploads) {
    final out = File('$stagePath/${u.key}')..parent.createSync(recursive: true);
    if (u.source != null) {
      File(u.source!).copySync(out.path);
    } else {
      out.writeAsStringSync(u.body!);
    }
    list.writeln('${u.key}\t${u.contentType}\t${u.bytes}');
  }
  File('$stagePath/upload_list.tsv').writeAsStringSync(list.toString());
  stdout.writeln('Staged in $stagePath (upload_list.tsv lists the objects in upload order).');
}
