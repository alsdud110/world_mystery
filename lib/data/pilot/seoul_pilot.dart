import 'dart:ui' show Offset, Size;

import '../../features/mission_map/map_world.dart' show SeasonLandmark, SeasonMap;
import '../mock/season_catalog.dart';
import 's7_seoulpilot/s7_seoulpilot_cases.g.dart';
import 's7_seoulpilot/s7_seoulpilot_history.g.dart';
import 's7_seoulpilot/s7_seoulpilot_levels.g.dart';
import 's7_seoulpilot/s7_seoulpilot_season.g.dart';

/// Seoul Pilot Case 01 (The Secret of the King's Letters, 1446), generated from
/// `test/sandbox/plans/s7_seoulpilot` with `--out lib/data/pilot/s7_seoulpilot`.
/// Never one of the game's seasons ([SeasonCatalog.all]): it is played in a
/// developer-mode session of its own (`DevSession.enterPilot`), and only an
/// operator build reaches it, so a release build leaves it out.
const seoulPilotCaseId = 's7_ep01';

final seoulPilotSeason = SeasonContent(
  info: s7SeoulpilotInfoJson,
  episodes: s7SeoulpilotEpisodes,
  places: s7SeoulpilotPlaces,
  released: false,
  storyGreeting: s7SeoulpilotStoryGreeting,
  learning: s7SeoulpilotLearning,
  languageTopics: s7SeoulpilotLanguageTopics,
  evidenceLinks: s7SeoulpilotEvidenceLinks,
  explores: s7SeoulpilotExplores,
  investigations: s7SeoulpilotInvestigations,
  dialogues: s7SeoulpilotDialogues,
  syllables: s7SeoulpilotSyllables,
  deductions: s7SeoulpilotDeductions,
  talks: s7SeoulpilotTalks,
  talkMissions: s7SeoulpilotTalkMissions,
  discoveries: s7SeoulpilotDiscoveries,
  endings: s7SeoulpilotEndings,
  historyReveals: s7SeoulpilotHistoryReveals,
  casePatches: s7SeoulpilotCasePatches,
  variants: s7SeoulpilotVariants,
  writtenLevels: s7SeoulpilotWrittenLevels,
  infoLevels: s7SeoulpilotInfoLevels,
  // The opening: King Sejong in his study, seen from behind.
  introBackdrops: const {seoulPilotCaseId: 'assets/seasons/season_07_seoulpilot/cover/kings_study.webp'},
);

// The pilot's three drawn places on its map, at the centre of each one's
// drawing (measured on assets/seasons/season_07_seoulpilot/locations/map/palace_map.webp):
// the gatehouse is the inner gate, the left hall the book hall, the right
// hall the servants' yard with Sora's writing room.
const _bookHall = SeasonLandmark('book_hall', 'The Book Hall', Offset(255 / 1536, 360 / 1024));
const _wellYard = SeasonLandmark('well_yard', 'The Well Yard', Offset(1320 / 1536, 330 / 1024));
const _innerGate = SeasonLandmark('inner_gate', 'The Inner Gate', Offset(760 / 1536, 725 / 1024));

/// The pilot's Mission Map: the palace grounds, every mission at its place.
const seoulPilotMap = SeasonMap(
  artwork: 'assets/seasons/season_07_seoulpilot/locations/map/palace_map.webp',
  pixels: Size(1536, 1024),
  aspect: 1536 / 1024,
  landmarks: [_bookHall, _wellYard, _innerGate],
  missionLandmarks: {
    's7_ep01_m1': _innerGate,
    's7_ep01_m2': _wellYard,
    's7_ep01_m3': _wellYard,
    's7_ep01_final': _bookHall,
  },
);
