import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../core/assets/season_pack_downloads.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/difficulty_content.dart';
import '../../data/mock/season_catalog.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/profile.dart';
import '../../data/season5/season5_art.dart' show season5Map;
import '../../data/season5/season5_content.dart';
import '../../data/repositories/episode_repository.dart';
import '../../data/repositories/memory_preferences.dart';
import '../../data/repositories/profile_store.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../mission_map/map_world.dart' show SeasonMap;
import '../result/case_solved_screen.dart' show historyRevealProvider;
import 'playtest_tools.dart' show playtestDetectiveName;

/// What the game knows of developer mode, from inside either session: the
/// player's own (to enter it) or a test session (to leave it). Null: no
/// developer mode in this game (no [DevSessionHost] above it).
@immutable
class DevSession {
  const DevSession({required this.active, required this.enter, required this.exit, this.enterPilot, this.pilot = false});

  /// This is a test session (TESTER, nothing saved on the device).
  final bool active;

  /// Starts a new test session (from the player's own; nothing is carried
  /// over from an earlier one).
  final VoidCallback enter;

  /// Ends the test session and returns to the player's own, as it was.
  final VoidCallback exit;

  /// Starts a new test session playing Seoul (Season 5) Case 01 alone at the
  /// level given ([season5Content]), from its case file. Null: no pilot in
  /// this game.
  final void Function(Difficulty level)? enterPilot;

  /// This test session plays Seoul Case 01 alone: its level is chosen by
  /// starting it again ([enterPilot]).
  final bool pilot;
}

final devSessionProvider = Provider<DevSession?>((ref) => null);

/// The test detective: TESTER, the boy's picture, Rookie. Its id names the
/// test session's namespace (in memory only).
const devDetectiveId = '7e57de7e7e57de7e7e57de7e7e57de7e';

DetectiveProfile devDetective({Difficulty level = Difficulty.standard}) => DetectiveProfile(
      id: devDetectiveId,
      detectiveName: playtestDetectiveName,
      avatar: DetectiveAvatar.boy,
      difficulty: level,
      createdAt: GameController.now(),
    );

/// Holds the player's own game and, while developer mode is on, a test
/// session in its place.
///
/// The player's own game lives in one provider container made here and kept
/// for the whole run: entering developer mode only takes it off the screen
/// (its play clock stopped), leaving puts it back exactly as it was — the
/// same saves, the same page (the Game Master page it was left on).
///
/// A test session is a container of its own, with no parent — nothing of it
/// can fall back on the player's providers — whose device storage is
/// [MemoryPreferences]: every save the game makes in it (detective, cases,
/// seasons and their levels, coins, tips, How to Play) stays in memory and
/// is thrown away when the session ends. Each entry makes a new one; within
/// a session the pages come and go and its saves stay. The system Back on a
/// test session's first page leaves developer mode rather than the app.
class DevSessionHost extends StatefulWidget {
  const DevSessionHost({super.key, required this.overrides, required this.child});

  /// The player's own game's overrides (device storage, content, session).
  final List<Override> overrides;

  /// The game ([WorldMysteryApp]), built in whichever session is on.
  final Widget child;

  @override
  State<DevSessionHost> createState() => _DevSessionHostState();
}

class _DevSessionHostState extends State<DevSessionHost> with WidgetsBindingObserver {
  late final ProviderContainer _own = ProviderContainer(
    overrides: [
      ...widget.overrides,
      devSessionProvider.overrideWithValue(_session(active: false)),
    ],
  );

  DevSession _session({required bool active, bool pilot = false}) => DevSession(
        active: active,
        enter: _enter,
        exit: _exit,
        enterPilot: operatorToolsInBuild ? _enterPilot : null,
        pilot: pilot,
      );

  ProviderContainer? _test;

  /// Counts the test sessions: each entry is a new one, never the last.
  int _sessions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _test?.dispose();
    _own.dispose();
    super.dispose();
  }

  void _enter() {
    if (_test != null || !_own.read(operatorToolsAvailableProvider)) return;
    // The player's case clock stops while they are away (nothing written).
    _own.read(gameControllerProvider.notifier).holdPlayClock();
    setState(() {
      _sessions++;
      _test = _newTestSession();
    });
  }

  /// A new test session in place of any other, playing Seoul Case 01 at
  /// [level] (see [DevSession.enterPilot]).
  void _enterPilot(Difficulty level) {
    if (!_own.read(operatorToolsAvailableProvider)) return;
    final old = _test;
    if (old == null) _own.read(gameControllerProvider.notifier).holdPlayClock();
    setState(() {
      _sessions++;
      _test = _newTestSession(pilotLevel: level);
    });
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _exit() {
    final test = _test;
    if (test == null) return;
    setState(() => _test = null);
    // Thrown away once its pages are gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => test.dispose());
    _own.read(gameControllerProvider.notifier).resumePlayClock();
  }

  ProviderContainer _newTestSession({Difficulty? pilotLevel}) {
    final tester = devDetective(level: pilotLevel ?? Difficulty.standard);
    final storage = MemoryPreferences({
      AppConstants.detectiveStorageKey: jsonEncode(DetectiveRecord(profile: tester).toJson()),
      // Its first case file already carries its name, as a new detective's.
      AppConstants.profileKey(devDetectiveId, AppConstants.progressStorageKey):
          jsonEncode(const GameProgress(detectiveName: playtestDetectiveName).toJson()),
      // Straight to the tools: How to Play is not in the way (it can still
      // be opened from the title page).
      AppConstants.onboardingSeenKey(devDetectiveId): true,
      // The device's sound setting, as the player has it.
      AppConstants.soundEnabledKey: ?_own.read(sharedPreferencesProvider).getBool(AppConstants.soundEnabledKey),
    });
    final test = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(storage),
        profileSessionProvider.overrideWithValue(ProfileSession(profile: tester)),
        // The same content, maps and build as the player's game.
        episodeRepositoryProvider.overrideWithValue(_own.read(episodeRepositoryProvider)),
        // The device's season packs: the ones downloaded, and where from.
        seasonPackSetupProvider.overrideWithValue(_own.read(seasonPackSetupProvider)),
        seasonPacksInAppProvider.overrideWithValue(_own.read(seasonPacksInAppProvider)),
        // Seoul Case 01's: the same (Seoul is a season of the game).
        if (pilotLevel != null)
          ...pilotOverrides(season5Content, seoulCase01Id, pilotLevel, own: _own)
        else ...[
          allEpisodesProvider.overrideWithValue(_own.read(allEpisodesProvider)),
          seasonMapsProvider.overrideWithValue(_own.read(seasonMapsProvider)),
          seasonReleasedProvider.overrideWithValue(_own.read(seasonReleasedProvider)),
        ],
        operatorToolsAvailableProvider.overrideWithValue(_own.read(operatorToolsAvailableProvider)),
        // One sound for the device: the player's (stopped with their game).
        audioServiceProvider.overrideWithValue(_own.read(audioServiceProvider)),
        // One ads SDK for the device too: the player's, started at most once.
        adServiceProvider.overrideWithValue(_own.read(adServiceProvider)),
        devSessionProvider.overrideWithValue(_session(active: true, pilot: pilotLevel != null)),
      ],
    );
    // The sound switch is the device's: switched here, it is the player's
    // too, which the one sound service listens to.
    test.listen<bool>(soundEnabledProvider, (_, on) {
      if (_own.read(soundEnabledProvider) == on) return;
      _own.read(soundEnabledProvider.notifier).toggle();
      _own.read(audioServiceProvider).refresh();
    });
    // It opens on the Game Master's tools; a pilot on its case file.
    test.read(gameMasterAccessProvider.notifier).grant();
    if (pilotLevel != null && openPilot(test, season5Content, seoulCase01Id)) {
      test.read(routerProvider).go(Routes.caseFile(seoulCase01Id));
    } else {
      test.read(routerProvider).go(Routes.gameMaster);
    }
    return test;
  }

  /// Back on a test session's first page: out of developer mode, not out
  /// of the app.
  @override
  Future<bool> didPopRoute() async {
    final test = _test;
    if (test == null || test.read(routerProvider).canPop()) return false;
    _exit();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final test = _test;
    if (test == null) {
      return UncontrolledProviderScope(key: const ValueKey('own-session'), container: _own, child: widget.child);
    }
    return UncontrolledProviderScope(
      key: ValueKey('test-session-$_sessions'),
      container: test,
      // A corner ribbon on every page: a test session never passes for the
      // player's game.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          key: const ValueKey('developer-mode-banner'),
          message: 'TESTER',
          location: BannerLocation.topEnd,
          color: AppColors.burgundy,
          child: KeyedSubtree(key: ValueKey('test-app-$_sessions'), child: widget.child),
        ),
      ),
    );
  }
}

/// What a session needs to play [caseId] of [season] alone at [level].
/// [own]: the player's session whose cases, maps and releases are kept
/// (null: the bundled ones).
///
/// A season of the game (Seoul, Season 5) is played as it is: the game's
/// own cases and maps, never a second copy beside them; the session's
/// detective gives the level, and the season preview opens it
/// ([openPilot]).
///
/// A season not in the game (a sandbox season, in the tests): the season
/// beside the game's own with that one case (in its level's words),
/// Seoul's map lent for its pins, and its REAL HISTORY reveal. Registers
/// the season's tables ([SeasonCatalog.testSeasons]) so its missions find
/// their puzzles.
List<Override> pilotOverrides(SeasonContent season, String caseId, Difficulty level, {ProviderContainer? own}) {
  final episodes = own?.read(allEpisodesProvider) ?? MockEpisodeRepository.bundled();
  final maps = own?.read(seasonMapsProvider) ?? SeasonMap.bySeason;
  final released = own?.read(seasonReleasedProvider) ?? seasonReleased;
  if (SeasonCatalog.byId(season.id) != null) {
    return [
      allEpisodesProvider.overrideWithValue(episodes),
      seasonMapsProvider.overrideWithValue(maps),
      seasonReleasedProvider.overrideWithValue(released),
    ];
  }
  if (!SeasonCatalog.testSeasons.any((s) => s.id == season.id)) {
    SeasonCatalog.testSeasons.add(season);
    SeasonCatalog.testPlaces.addAll(season.places);
  }
  final episode = DifficultyContent.episodeAt(
    Episode.fromJson({...season.episodes[caseId]!, 'seasonId': season.id}),
    level,
    patches: season.casePatches,
  );
  return [
    seasonsProvider.overrideWithValue([for (final s in SeasonCatalog.all) s.season, season.season]),
    allEpisodesProvider.overrideWithValue([...episodes, episode]),
    seasonMapsProvider.overrideWithValue({...maps, season.id: season5Map}),
    seasonReleasedProvider.overrideWithValue((id) => id == season.id || released(id)),
    // The game finds a reveal by its own seasons only.
    if (season.historyReveals[caseId] case final r?) historyRevealProvider(caseId).overrideWithValue(r),
  ];
}

/// [container]'s detective in [season] at [caseId]'s case file (the
/// season preview on, as for any unreleased season): false when it would
/// not open.
bool openPilot(ProviderContainer container, SeasonContent season, String caseId) {
  container.read(seasonPreviewSwitchProvider.notifier).set(true);
  final game = container.read(gameControllerProvider.notifier);
  return game.openSeason(season.id) && container.read(gameControllerProvider.notifier).openEpisode(caseId);
}
