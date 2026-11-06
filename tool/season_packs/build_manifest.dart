import 'dart:io';

import 'season_manifests.dart';

/// Writes lib/core/assets/season_pack_manifests.g.dart from the season
/// pictures under assets/seasons/ on disk. `--check`: writes nothing, exits 1 when the
/// file is not what the assets on disk give (run it before a release).
///
///   dart run tool/season_packs/build_manifest.dart [--check]
void main(List<String> args) {
  final packs = measureSeasonPacks();
  final source = renderManifests(packs);
  final file = File(generatedPath);
  final current = file.existsSync() ? file.readAsStringSync().replaceAll('\r\n', '\n') : null;

  for (final p in packs) {
    stdout.writeln('${p.folder.padRight(18)} ${p.files.length.toString().padLeft(4)} files '
        '${p.totalBytes.toString().padLeft(11)} bytes  v${p.version}');
  }
  if (args.contains('--check')) {
    if (current == source) return stdout.writeln('$generatedPath is up to date.');
    stderr.writeln('$generatedPath is stale: run dart run tool/season_packs/build_manifest.dart');
    exitCode = 1;
    return;
  }
  if (current == source) return stdout.writeln('$generatedPath unchanged.');
  file.writeAsStringSync(source);
  stdout.writeln('Wrote $generatedPath.');
}
