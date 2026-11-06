import '../mock/season_catalog.dart' show SeasonContent;
import '../generated/s5_seoul/s5_seoul_content.g.dart';

/// Season 5, The King's Letters of Seoul: made whole from its plans by the
/// season factory (`content_pipeline/seasons/s5_seoul`,
/// `generate_season.dart --target game`, listed by `generated_seasons.g.dart`)
/// since 2026-11-06. Until then its Case 01 alone was made for the sandbox
/// and registered here by hand; this name stays for the developer's pilot
/// mode (`dev_session.dart`) and its tests, and is the generated content.
const seoulCase01Id = 's5_ep01';

final SeasonContent season5Content = s5SeoulContent;
