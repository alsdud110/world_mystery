import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'season_pack_bundle.dart';
import 'season_pack_storage.dart';

/// Season packs downloaded on demand: where they are kept and where they come
/// from. Null (the default): no season is downloaded; seasons play the copy
/// inside the app, when it has one ([seasonPacksInAppProvider]).
@immutable
class SeasonPackSetup {
  const SeasonPackSetup(this.storage, this.source);

  final SeasonPackStorage storage;
  final SeasonPackSource source;

  /// The packs come from [defaultUrl], or the build's
  /// `--dart-define=SEASON_PACK_URL=https://…/` (HTTPS, ending in `/`). An
  /// empty or non-HTTPS URL, or the web: null, nothing is downloaded.
  static Future<SeasonPackSetup?> fromEnvironment(SharedPreferences prefs) async {
    const url = String.fromEnvironment('SEASON_PACK_URL', defaultValue: defaultUrl);
    final base = Uri.tryParse(url);
    if (kIsWeb || base == null || base.scheme != 'https' || !base.path.endsWith('/')) return null;
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/season_packs')..createSync(recursive: true);
    // Downloaded again whenever needed: kept out of iCloud backups (the
    // game's progress and profile, elsewhere, are still backed up).
    if (Platform.isIOS) await excludeFromBackup(dir);
    return SeasonPackSetup(
      SeasonPackStorage(dir, prefs, freeSpace: () => freeBytes(dir)),
      HttpSeasonPackSource(base),
    );
  }

  /// The R2 bucket's public URL. shortcut: an r2.dev URL is for development
  /// and tests; replace it with the custom domain before release.
  static const defaultUrl = 'https://pub-935cdbceccfe457a850a5a7e685faf42.r2.dev/';
}

final seasonPackSetupProvider = Provider<SeasonPackSetup?>((ref) => null);

/// The app's own code for the packs' folder (MainActivity.kt, AppDelegate.swift).
const seasonPackChannel = MethodChannel('world_mystery/season_packs');

/// [dir] (and everything in it) left out of the device's backups (iOS).
Future<void> excludeFromBackup(Directory dir) async {
  try {
    await seasonPackChannel.invokeMethod<void>('excludeFromBackup', dir.path);
  } on Object catch (e) {
    debugPrint('Season packs not excluded from backup: $e');
  }
}

/// The bytes free on [dir]'s volume, or null when the device does not say.
Future<int?> freeBytes(Directory dir) async {
  try {
    return await seasonPackChannel.invokeMethod<int>('freeBytes', dir.path);
  } on Object catch (e) {
    debugPrint('Free space unknown: $e');
    return null;
  }
}

/// Whether every season's pictures are inside the app (the default: tests,
/// builds from before season packs). The app sets it from its asset list
/// ([seasonPacksInApp]); without them and without a download URL, the
/// downloaded seasons cannot be played.
final seasonPacksInAppProvider = Provider<bool>((ref) => true);

/// Whether [bundle] lists every file of every downloaded season's pack.
Future<bool> seasonPacksInApp(AssetBundle bundle) async {
  final listed = (await AssetManifest.loadFromAssetBundle(bundle)).listAssets().toSet();
  return SeasonPack.all.where((p) => p != SeasonPack.london).every((p) => p.manifest.files.every((f) => listed.contains(f.path)));
}

/// Which seasons must be downloaded before they are played, and the
/// downloads. London is always in the app; a season's unlock and its
/// download are separate (nothing here reads or writes progress).
class SeasonPacksNotifier extends Notifier<Set<String>> {
  /// The folders of the packs installed at the app's manifest version, with
  /// all their files still on the device.
  @override
  Set<String> build() {
    final setup = ref.watch(seasonPackSetupProvider);
    if (setup == null) return const {};
    return {for (final p in SeasonPack.all) if (setup.storage.isIntact(p.manifest)) p.folder};
  }

  /// Season [seasonId]'s pack looked at again (before it is entered): a pack
  /// whose files are gone from the device is downloaded again (only those
  /// files; its progress and rewards are not touched).
  void recheck(String seasonId) {
    final pack = downloadOf(seasonId);
    if (pack == null || !state.contains(pack.folder)) return;
    if (!ref.read(seasonPackSetupProvider)!.storage.isIntact(pack.manifest)) state = {...state}..remove(pack.folder);
  }

  /// The pack season [seasonId] downloads, or null: it plays from the app.
  SeasonPack? downloadOf(String seasonId) {
    if (ref.read(seasonPackSetupProvider) == null || seasonId == SeasonPack.london.seasonId) return null;
    for (final p in SeasonPack.all) {
      if (p.seasonId == seasonId) return p;
    }
    return null;
  }

  /// Whether season [seasonId] cannot be played at all: its pictures are
  /// neither in the app nor downloadable (a build without a download URL).
  bool isMissing(String seasonId) =>
      ref.read(seasonPackSetupProvider) == null &&
      !ref.read(seasonPacksInAppProvider) &&
      seasonId != SeasonPack.london.seasonId &&
      SeasonPack.all.any((p) => p.seasonId == seasonId);

  /// Whether season [seasonId] cannot be played until it is downloaded (or
  /// at all, when [isMissing]).
  bool needsDownload(String seasonId) {
    final pack = downloadOf(seasonId);
    return (pack != null && !state.contains(pack.folder)) || isMissing(seasonId);
  }

  /// Downloads season [seasonId]'s pack (see [SeasonPackStorage.install]).
  Future<void> download(String seasonId, {void Function(int done, int total)? onProgress, SeasonPackCancel? cancel}) async {
    final pack = downloadOf(seasonId);
    if (pack == null) return;
    await ref.read(seasonPackSetupProvider)!.storage.install(pack.manifest, ref.read(seasonPackSetupProvider)!.source, onProgress: onProgress, cancel: cancel);
    _changed({...state, pack.folder});
  }

  /// Removes season [seasonId]'s downloaded pack. Its progress and rewards
  /// stay; it is downloaded again before it is next played.
  Future<void> delete(String seasonId) async {
    final pack = downloadOf(seasonId);
    if (pack == null) return;
    await ref.read(seasonPackSetupProvider)!.storage.delete(pack.manifest);
    _changed({...state}..remove(pack.folder));
  }

  void _changed(Set<String> installed) {
    // Pictures decoded from the other copy are not shown again.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    state = installed;
  }
}

final seasonPacksProvider = NotifierProvider<SeasonPacksNotifier, Set<String>>(SeasonPacksNotifier.new);
