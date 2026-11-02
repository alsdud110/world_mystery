import 'dart:io';
import 'dart:typed_data';

/// Makes WebP bytes from PNG bytes with the given encoder settings.
abstract interface class WebpEncoder {
  /// Which encoder and version, kept in the records of what it made.
  String get version;

  /// [png] encoded with [args] (cwebp's options). A [WebpEncodeError] when
  /// the encoder fails; never a partial result.
  Uint8List encode(Uint8List png, List<String> args);
}

class WebpEncodeError implements Exception {
  const WebpEncodeError(this.message);

  final String message;

  @override
  String toString() => 'WebP encoding failed: $message';
}

/// Google's `cwebp` (libwebp), run as a process. Not a Dart package: the
/// pure-Dart `package:image` decodes WebP but cannot write it.
///
/// Found, in order: the path given, the `CWEBP` environment variable,
/// `cwebp` on the PATH, then `~/.world_mystery/libwebp-*/bin/` (the newest).
/// Windows: the release zip from
/// https://storage.googleapis.com/downloads.webmproject.org/releases/webp/
/// unpacked there; macOS: `brew install webp`.
class CwebpEncoder implements WebpEncoder {
  CwebpEncoder._(this.executable, this.version);

  /// An encoder already found (passed to another isolate by its two fields).
  CwebpEncoder.at(this.executable, this.version);

  final String executable;

  @override
  final String version;

  static const minVersion = (1, 2);

  /// The encoder found (see the class), or null.
  static CwebpEncoder? find({String? path, Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final exe = Platform.isWindows ? 'cwebp.exe' : 'cwebp';
    final candidates = <String>[
      ?path,
      ?env['CWEBP'],
      for (final dir in (env['PATH'] ?? '').split(Platform.isWindows ? ';' : ':')) if (dir.isNotEmpty) '$dir${Platform.pathSeparator}$exe',
      ..._userInstalls(env, exe),
    ];
    for (final c in candidates) {
      if (!File(c).existsSync()) continue;
      try {
        final r = Process.runSync(c, ['-version']);
        final v = '${r.stdout}'.trim().split(RegExp(r'\s+')).first;
        final parts = v.split('.').map(int.tryParse).toList();
        if (r.exitCode != 0 || parts.length < 2 || parts[0] == null || parts[1] == null) continue;
        final (major, minor) = (parts[0]!, parts[1]!);
        if (major < minVersion.$1 || (major == minVersion.$1 && minor < minVersion.$2)) continue;
        return CwebpEncoder._(c, 'cwebp $v');
      } on ProcessException {
        continue;
      }
    }
    return null;
  }

  static List<String> _userInstalls(Map<String, String> env, String exe) {
    final home = env['USERPROFILE'] ?? env['HOME'];
    if (home == null) return const [];
    final dir = Directory('$home/.world_mystery');
    if (!dir.existsSync()) return const [];
    final found = [
      for (final d in dir.listSync().whereType<Directory>())
        if (d.uri.pathSegments.where((s) => s.isNotEmpty).last.startsWith('libwebp-')) '${d.path}/bin/$exe',
    ]..sort();
    return found.reversed.toList();
  }

  /// What to tell a person when no encoder is found.
  static const missing = 'no cwebp (libwebp 1.2+) found: set CWEBP, put it on the PATH, or unpack '
      'https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.6.0-windows-x64.zip '
      'into ~/.world_mystery/ (macOS: brew install webp). Nothing was written.';

  @override
  Uint8List encode(Uint8List png, List<String> args) {
    final tmp = Directory.systemTemp.createTempSync('wm_webp_');
    try {
      final input = File('${tmp.path}/in.png')..writeAsBytesSync(png, flush: true);
      final output = File('${tmp.path}/out.webp');
      final r = Process.runSync(executable, ['-quiet', ...args, input.path, '-o', output.path]);
      if (r.exitCode != 0 || !output.existsSync()) {
        throw WebpEncodeError('cwebp ${args.join(' ')}: exit ${r.exitCode} ${'${r.stderr}'.trim()}');
      }
      return output.readAsBytesSync();
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }
}
