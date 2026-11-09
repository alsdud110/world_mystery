import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of `integration_test/seoul_final_qa_test.dart`: every
/// screenshot the device takes is written under `qa/screenshots/seoul_final/`
/// (its name holds the screen size's folder: `375x667/c04_m3_opening`).
///
///   flutter drive --driver=test_driver/seoul_final_qa_driver.dart \
///     --target=integration_test/seoul_final_qa_test.dart -d DEVICE
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('qa/screenshots/seoul_final/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return true;
  },
);
