import '../mock/season_catalog.dart';
import 's5_seoul/s5_seoul_cases.g.dart';
import 's5_seoul/s5_seoul_history.g.dart';
import 's5_seoul/s5_seoul_levels.g.dart';
import 's5_seoul/s5_seoul_season.g.dart';

/// Season 5, The King's Letters of Seoul: Case 01 (The Secret of the King's
/// Letters, 1446) only, Cases 02–12 not written yet (`plannedCases` 12).
/// Generated from `content_pipeline/seasons/s5_seoul` with
/// `generate_season.dart --target sandbox --out lib/data/season5/s5_seoul`,
/// and registered here by hand ([SeasonCatalog.all], its map and cover in
/// `season5_art.dart`): the game target takes a season only whole, with its
/// opening. It was the Seoul pilot (`s7_seoulpilot`) until 2026-11-05; no
/// player ever saved under that id (the pilot was played in memory only).
const seoulCase01Id = 's5_ep01';

final season5Content = SeasonContent(
  info: s5SeoulInfoJson,
  episodes: s5SeoulEpisodes,
  places: s5SeoulPlaces,
  storyGreeting: s5SeoulStoryGreeting,
  learning: s5SeoulLearning,
  languageTopics: s5SeoulLanguageTopics,
  evidenceLinks: s5SeoulEvidenceLinks,
  explores: s5SeoulExplores,
  investigations: s5SeoulInvestigations,
  dialogues: s5SeoulDialogues,
  syllables: s5SeoulSyllables,
  deductions: s5SeoulDeductions,
  talks: s5SeoulTalks,
  talkMissions: s5SeoulTalkMissions,
  discoveries: s5SeoulDiscoveries,
  endings: s5SeoulEndings,
  historyReveals: s5SeoulHistoryReveals,
  casePatches: s5SeoulCasePatches,
  variants: s5SeoulVariants,
  writtenLevels: s5SeoulWrittenLevels,
  infoLevels: s5SeoulInfoLevels,
  // The opening: King Sejong in his study, seen from behind.
  introBackdrops: const {seoulCase01Id: 'assets/seasons/season_05_seoul/cover/kings_study.webp'},
);
