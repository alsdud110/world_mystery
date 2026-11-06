import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/assets/season_pack_bundle.dart';

/// The downloaded seasons' pictures (Paris, Rome, New York, Seoul) are no
/// longer in the app, so `flutter test` does not have them either. Tests
/// that show those seasons read exactly those files from `assets/` on disk,
/// as a downloaded pack would give them; every other asset is served as
/// flutter_test serves it (`UNIT_TEST_ASSETS`), and nothing else changes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final dir = Platform.environment['UNIT_TEST_ASSETS'];
  if (dir != null) {
    final packFiles = {
      for (final p in SeasonPack.all)
        if (p != SeasonPack.london)
          for (final f in p.manifest.files) f.path,
    };
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) {
      final key = utf8.decode(message!.buffer.asUint8List());
      var file = File('$dir/$key');
      if (!file.existsSync() && packFiles.contains(key)) file = File(key);
      if (!file.existsSync()) return null;
      return SynchronousFuture(Uint8List.fromList(file.readAsBytesSync()).buffer.asByteData());
    });
  }
  await testMain();
}
