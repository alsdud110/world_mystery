import 'dart:io';

/// One file the app ships (`pubspec.yaml`'s `flutter: assets:` and `fonts:`).
class BundledFile {
  const BundledFile(this.path, this.bytes);

  /// From the repository's root, with `/`.
  final String path;
  final int bytes;

  /// `season_01_london`…, else `shared` (every other picture), `audio`, `fonts`.
  String get area {
    final m = RegExp(r'^assets/seasons/([^/]+)/').firstMatch(path);
    if (m != null) return m[1]!;
    if (path.startsWith('assets/fonts/')) return 'fonts';
    if (path.startsWith('assets/sounds/')) return 'audio';
    return 'shared';
  }

  /// `image`, `audio`, `font` or `other`.
  String get type {
    final ext = extension;
    if (const {'.png', '.webp', '.jpg', '.jpeg', '.gif'}.contains(ext)) return 'image';
    if (const {'.wav', '.mp3', '.ogg', '.m4a', '.aac'}.contains(ext)) return 'audio';
    if (const {'.ttf', '.otf'}.contains(ext)) return 'font';
    return 'other';
  }

  String get extension {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot).toLowerCase();
  }
}

/// What `pubspec.yaml` puts in the app, read as Flutter reads it: a file
/// entry is that file; a folder entry (`…/`) is the files directly in it,
/// never its subfolders; `fonts:` add their `asset:` files.
abstract final class BundleAssets {
  /// The `flutter: assets:` entries and font files, as written.
  static ({List<String> entries, List<String> fonts}) entriesOf(String pubspec) {
    final lines = pubspec.replaceAll('\r\n', '\n').split('\n');
    final entries = <String>[], fonts = <String>[];
    var inFlutter = false, inAssets = false, inFonts = false;
    for (final line in lines) {
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
      final indent = line.length - line.trimLeft().length;
      if (indent == 0) {
        inFlutter = line.startsWith('flutter:');
        inAssets = inFonts = false;
        continue;
      }
      if (!inFlutter) continue;
      if (indent == 2) {
        inAssets = line.trim() == 'assets:';
        inFonts = line.trim() == 'fonts:';
        continue;
      }
      if (inAssets) {
        final m = RegExp(r'''^\s*-\s*(?:path:\s*)?["']?([^"'\s#]+)["']?\s*(#.*)?$''').firstMatch(line);
        if (m != null) entries.add(m[1]!);
      } else if (inFonts) {
        final m = RegExp(r'^\s*-?\s*asset:\s*(\S+)\s*$').firstMatch(line);
        if (m != null) fonts.add(m[1]!);
      }
    }
    return (entries: entries, fonts: fonts);
  }

  /// Every file the app ships, each once, sorted.
  static List<BundledFile> list({String root = '.', String pubspecPath = 'pubspec.yaml'}) {
    final (:entries, :fonts) = entriesOf(File('$root/$pubspecPath').readAsStringSync());
    final out = <String, BundledFile>{};
    void add(File f, String rel) => out[rel] = BundledFile(rel, f.lengthSync());
    for (final e in entries) {
      if (e.endsWith('/')) {
        final dir = Directory('$root/$e');
        if (!dir.existsSync()) continue;
        for (final f in dir.listSync().whereType<File>()) {
          final name = f.uri.pathSegments.last;
          if (name.startsWith('.')) continue;
          add(f, '$e$name');
        }
      } else {
        final f = File('$root/$e');
        if (f.existsSync()) add(f, e);
      }
    }
    for (final font in fonts) {
      final f = File('$root/$font');
      if (f.existsSync()) add(f, font);
    }
    return out.values.toList()..sort((a, b) => a.path.compareTo(b.path));
  }

  /// The entries naming a file or folder that is not there.
  static List<String> missing({String root = '.', String pubspecPath = 'pubspec.yaml'}) {
    final (:entries, :fonts) = entriesOf(File('$root/$pubspecPath').readAsStringSync());
    return [
      for (final e in [...entries, ...fonts])
        if (e.endsWith('/') ? !Directory('$root/$e').existsSync() : !File('$root/$e').existsSync()) e,
    ];
  }
}
