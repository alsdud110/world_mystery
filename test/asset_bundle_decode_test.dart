import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_manifests.g.dart';

import '../tool/asset_optimizer/bundle_assets.dart';
import '../tool/asset_optimizer/image_file.dart';

/// Every picture the app ships (pubspec.yaml, as Flutter reads it) and every
/// downloaded season's (its season pack's manifest), decoded
/// by the engine's own codec, the one `Image.asset` uses: whole, at the size
/// its file says. The game's pictures are WebP since the asset optimization
/// (tool/asset_optimizer); a file the engine cannot open would be a blank
/// place, a missing clue, in the game.
void main() {
  // The app's own pictures, and the downloaded seasons' (season packs).
  final pictures = {
    for (final f in BundleAssets.list()) if (f.type == 'image') f.path,
    for (final p in seasonPackManifests.values) for (final f in p.files) f.path,
  }.toList();

  test('the bundle lists its pictures, and every entry of pubspec.yaml is on disk', () {
    expect(pictures.length, greaterThan(400));
    expect(BundleAssets.missing(), isEmpty);
  });

  testWidgets('every bundled picture decodes in the engine, at its own size', (t) async {
    final problems = <String>[];
    await t.runAsync(() async {
      for (final p in pictures) {
        final bytes = File(p).readAsBytesSync();
        try {
          final info = ImageFileCheck.bytes(bytes);
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          if ((frame.image.width, frame.image.height) != (info.width, info.height)) {
            problems.add('$p: decoded at ${frame.image.width}x${frame.image.height}, the file says ${info.width}x${info.height}');
          }
          frame.image.dispose();
          codec.dispose();
        } on Object catch (e) {
          problems.add('$p: $e');
        }
      }
    });
    expect(problems, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
