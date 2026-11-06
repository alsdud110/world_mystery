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
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/season_packs');
    return SeasonPackSetup(SeasonPackStorage(dir, prefs), HttpSeasonPackSource(base));
  }

  /// The R2 bucket's public URL. shortcut: an r2.dev URL is for development
  /// and tests; replace it with the custom domain before release.
  static const defaultUrl = 'https://pub-935cdbceccfe457a850a5a7e685faf42.r2.dev/';
}

final seasonPackSetupProvider = Provider<SeasonPackSetup?>((ref) => null);

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
  /// The folders of the packs installed at the app's manifest version.
  @override
  Set<String> build() {
    final setup = ref.watch(seasonPackSetupProvider);
    if (setup == null) return const {};
    return {for (final p in SeasonPack.all) if (setup.storage.isInstalled(p.manifest)) p.folder};
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
