import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';

import '../full_playthrough_test.dart' show tapText, wait;
import 'generated/s8_timeline/s8_timeline_cases.g.dart';
import 'generated/s8_timeline/s8_timeline_season.g.dart';
import 'single_case.dart';

/// The single-case path (Seoul Pilot): a case of a sandbox season played
/// alone in the real app with [SingleCase] and [CasePlayer], proved here on
/// the timeline sandbox's two cases (standard, no history) — every engine
/// the pilot uses (timeline, records, traces, a talk with evidence) and the
/// rest its cases hold. The pilot itself is played this way only once its
/// history is approved and its content made (s7_pilot_gate_test).
void main() {
  final season = SeasonContent(
    info: s8TimelineInfoJson,
    episodes: s8TimelineEpisodes,
    places: s8TimelinePlaces,
    released: false,
    storyGreeting: s8TimelineStoryGreeting,
    learning: s8TimelineLearning,
    languageTopics: s8TimelineLanguageTopics,
    evidenceLinks: s8TimelineEvidenceLinks,
    explores: s8TimelineExplores,
    investigations: s8TimelineInvestigations,
    dialogues: s8TimelineDialogues,
    timelines: s8TimelineTimelines,
    deductions: s8TimelineDeductions,
    inspections: s8TimelineInspections,
    records: s8TimelineRecords,
    talks: s8TimelineTalks,
    talkMissions: s8TimelineTalkMissions,
    discoveries: s8TimelineDiscoveries,
    endings: s8TimelineEndings,
  );

  test('one case alone: the game\'s validator takes it, the game\'s own seasons untouched', () {
    expect(SeasonContentValidator.validate(season), isEmpty);
    final one = SingleCase(season, 's8_ep02');
    expect(one.episode.id, 's8_ep02');
    expect(SeasonCatalog.all.any((s) => s.id == one.seasonId), isFalse);
  });

  for (final caseId in ['s8_ep01', 's8_ep02']) {
    testWidgets('$caseId alone, from the map to its final solved: a miss, closed and opened again, paid once', (t) async {
      final one = SingleCase(season, caseId)..register();
      addTearDown(one.unregister);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var c = await one.open(t, prefs, fresh: true);
      final p = CasePlayer(t, season);
      final ep = one.episode;
      bool done(String id) => c.read(gameControllerProvider).isCompleted(id);
      expect(c.read(currentEpisodeProvider).id, caseId);

      // The first mission: a miss first where it has wrong options, then its answer.
      final first = ep.missions.first;
      await p.toPuzzle(first);
      final miss = first.options.where((o) => o.id != first.answer && first.type.name != 'sequence').firstOrNull;
      if (season.records[first.id] case final r?) {
        final other = r.first.lines.firstWhere((l) => '${l.id}:${l.id}' != first.answer).id;
        await p.answer(first, '$other:$other');
      } else if (miss != null) {
        await p.answer(first, miss.id);
      }
      if (find.text('Not quite!').evaluate().isNotEmpty) {
        expect(done(first.id), isFalse);
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      }
      final before = c.read(walletProvider).balance;
      await p.answer(first);
      expect(done(first.id), isTrue, reason: p.play.texts());
      final paid = c.read(walletProvider).balance - before;
      expect(paid, greaterThan(0));
      await p.onToMap();

      // Closed and opened again: the first solved, the rest as they were.
      c = await one.open(t, prefs, fresh: false);
      expect([done(first.id), done(ep.missions[1].id)], [true, false]);
      expect(c.read(gameControllerProvider.notifier).submitAnswer(first, first.answer).coins, 0, reason: 'paid once');

      for (final m in ep.missions.skip(1)) {
        await p.toPuzzle(m);
        await p.answer(m);
        expect(done(m.id), isTrue, reason: '${m.id}: ${p.play.texts()}');
        await p.onToMap();
      }
      await p.solveFinal(ep.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      expect(done(ep.finalMission.id), isTrue, reason: p.play.texts());
      expect(t.takeException(), isNull);
    });
  }
}
