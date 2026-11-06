import 'dart:math' as math;

import 'plan_ids.dart';
import 'plan_models.dart';

/// One thing wrong in how a plan's parts relate: where, and why.
class PlanIssue {
  const PlanIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// The structure of plans that keep the format (STEP 3-2): ids against
/// their season and case, the acts' cases, the missions' order. What a JSON
/// Schema cannot say; the format itself is the models' and the schemas'.
///
/// Not checked here: the palette fit and engines (STEP 3-3,
/// `PuzzleSelectionCheck`), the clue graph — whether a clue exists, is found
/// before it is used, and is left once (STEP 3-4, `ClueGraphCheck`) —, the
/// levels' words, the assets, the Dart content.
abstract final class PlanCheck {
  /// What is wrong in [plan]'s structure, or nothing.
  static List<PlanIssue> season(SeasonPlan plan) {
    final out = <PlanIssue>[];
    void bad(String path, String message) => out.add(PlanIssue(path, message));

    final n = PlanIds.seasonNumber(plan.seasonId);
    if (n != plan.number) bad(r'$.number', 'season ${plan.number}, but its id ${plan.seasonId} says $n');

    // Three acts, in order, each with its four cases: Case 01–04, 05–08, 09–12.
    final seen = <String>{};
    for (final (i, act) in plan.acts.indexed) {
      final at = '\$.acts[$i]';
      if (act.actId != 'act${i + 1}') bad('$at.actId', '${act.actId} is act ${i + 1}');
      for (final (j, id) in act.caseIds.indexed) {
        final want = PlanIds.caseOf(plan.number, i * casesPerAct + j + 1);
        if (!seen.add(id)) {
          bad('$at.caseIds[$j]', '$id is in two acts');
        } else if (id != want) {
          bad('$at.caseIds[$j]', '$id, but case ${i * casesPerAct + j + 1} of ${plan.seasonId} is $want');
        }
      }
    }

    final cases = plan.caseIds;
    int? order(String caseId) => cases.contains(caseId) ? cases.indexOf(caseId) : null;
    void inSeason(String path, String caseId) {
      if (order(caseId) == null) bad(path, '$caseId is not a case of the season');
    }

    inSeason(r'$.mainMystery.revealCase', plan.mainMystery.revealCase);

    final charIds = <String>{};
    for (final (i, c) in plan.characters.indexed) {
      final at = '\$.characters[$i]';
      if (!charIds.add(c.charId)) bad('$at.charId', '${c.charId} given twice');
      inSeason('$at.firstCase', c.firstCase);
      for (final (key, id) in [('revealCase', c.revealCase), ('secretUntil', c.secretUntil)]) {
        if (id == null) continue;
        inSeason('$at.$key', id);
        final (first, then) = (order(c.firstCase), order(id));
        if (first != null && then != null && then < first) bad('$at.$key', '$id comes before their first case ${c.firstCase}');
      }
    }

    final locIds = <String>{};
    for (final (i, l) in plan.locations.indexed) {
      if (!locIds.add(l.locId)) bad('\$.locations[$i].locId', '${l.locId} given twice');
    }

    for (final (i, f) in plan.figures.indexed) {
      inSeason('\$.figures[$i].after', f.after);
    }

    // The season map (the Rome integration): a place's location and a
    // landmark's are the season's own; every landmark on its artwork, one a
    // location; every place on the map once the map is planned.
    for (final (i, p) in plan.places.indexed) {
      if (p.locId case final l? when !locIds.contains(l)) bad('\$.places[$i].locId', '$l is not a location of the season plan');
    }
    if (plan.art?.map case final map?) {
      final drawn = <String>{};
      for (final (i, l) in map.landmarks.indexed) {
        final at = '\$.art.map.landmarks[$i]';
        if (!locIds.contains(l.locId)) bad('$at.locId', '${l.locId} is not a location of the season plan');
        if (!drawn.add(l.locId)) bad('$at.locId', '${l.locId} given twice');
        if (l.at.x < 0 || l.at.y < 0 || l.at.x > map.width || l.at.y > map.height) {
          bad('$at.at', '${l.at.toJson()} is off the ${map.width}x${map.height} map');
        }
      }
      for (final (i, p) in plan.places.indexed) {
        if (p.locId == null) {
          bad('\$.places[$i].locId', 'missing: ${p.placeId} must be on the season map (art.map)');
        } else if (!drawn.contains(p.locId)) {
          bad('\$.places[$i].locId', '${p.locId} has no landmark on the season map (art.map.landmarks)');
        }
      }
    }
    // A case's own map: its marks stay inside the part of the map the pins
    // and their notes fit in, its missions' spots apart from each other.
    for (final MapEntry(key: caseId, value: map) in plan.art?.caseMaps.entries ?? const <MapEntry<String, CaseMapPlan>>[]) {
      final at = '\$.art.caseMaps.$caseId';
      inSeason(at, caseId);
      void inside(String path, ScenePoint p) {
        final (x, y) = (p.x / map.width, p.y / map.height);
        if (x < _caseMapSide || x > 1 - _caseMapSide || y < _caseMapTop || y > 1 - _caseMapBottom) {
          bad(path, '${p.toJson()} is outside the part of the ${map.width}x${map.height} map a pin fits in');
        }
      }

      final spotIds = <String>{};
      final spots = <String, ScenePoint>{};
      for (final (i, l) in map.landmarks.indexed) {
        final path = '$at.landmarks[$i]';
        if (!spotIds.add(l.spotId)) bad('$path.spotId', '${l.spotId} given twice');
        inside('$path.at', l.at);
        for (final MapEntry(key: id, value: p) in l.missions.entries) {
          inside('$path.missions.$id', p);
          if (spots.containsKey(id)) bad('$path.missions.$id', '$id given twice');
          for (final MapEntry(key: other, value: q) in spots.entries) {
            final apart = math.sqrt(math.pow(p.x - q.x, 2) + math.pow(p.y - q.y, 2)) / map.width;
            if (apart < _caseMapApart) bad('$path.missions.$id', 'too close to $other');
          }
          spots[id] = p;
        }
      }
    }
    return out;
  }

  /// The part of a case's own map a pin fits in, as shares of the artwork:
  /// the top is `MapWorld.topMargin`, where the YOU'RE HERE note still fits.
  static const _caseMapTop = 0.15;
  static const _caseMapSide = 0.08;
  static const _caseMapBottom = 0.08;

  /// How far apart two missions' spots stay, as a share of the map's width.
  static const _caseMapApart = 0.06;

  /// What is wrong in [plan]'s structure, or nothing. With its [season]:
  /// also its place in the season's acts and the people and places it names.
  static List<PlanIssue> casePlan(CasePlan plan, {SeasonPlan? season}) {
    final out = <PlanIssue>[];
    void bad(String path, String message) => out.add(PlanIssue(path, message));

    final seasonNumber = PlanIds.seasonNumber(plan.seasonId);
    if (PlanIds.caseNumbers(plan.caseId) case (final s, final c)) {
      if (s != seasonNumber) bad(r'$.caseId', '${plan.caseId} is not a case of ${plan.seasonId}');
      if (c != plan.number) bad(r'$.number', 'case ${plan.number}, but its id ${plan.caseId} says $c');
    }
    final act = 'act${(plan.number - 1) ~/ casesPerAct + 1}';
    if (plan.actId != act) bad(r'$.actId', '${plan.actId}, but case ${plan.number} is in $act');

    if (season != null) {
      if (season.seasonId != plan.seasonId) bad(r'$.seasonId', '${plan.seasonId}, not the season planned (${season.seasonId})');
      final inAct = season.acts.where((a) => a.caseIds.contains(plan.caseId)).map((a) => a.actId).firstOrNull;
      if (inAct == null) {
        bad(r'$.caseId', '${plan.caseId} is in no act of ${season.seasonId}');
      } else if (inAct != plan.actId) {
        bad(r'$.actId', '${plan.actId}, but the season plan has ${plan.caseId} in $inAct');
      }
      // Its own map, if it has one: every mission on it once, at the place
      // the mission names.
      if (season.art?.caseMaps[plan.caseId] case final map?) {
        final at = '(season plan) \$.art.caseMaps.${plan.caseId}';
        final placeOf = {for (final l in map.landmarks) for (final id in l.missions.keys) id: l};
        for (final m in plan.allMissions) {
          final place = placeOf.remove(m.missionId);
          if (place == null) {
            bad(at, '${m.missionId} has no spot on the case\'s map');
          } else if (place.name.toLowerCase() != m.play?.location?.toLowerCase()) {
            bad(at, '${m.missionId} happens at ${m.play?.location}, not at ${place.name}');
          }
        }
        for (final id in placeOf.keys) {
          bad(at, '$id is not a mission of ${plan.caseId}');
        }
      }
      final people = {for (final c in season.characters) c.charId};
      final places = {for (final l in season.locations) l.locId};
      for (final (i, id) in plan.characters.indexed) {
        if (!people.contains(id)) bad('\$.characters[$i]', '$id is not a character of the season plan');
      }
      for (final (i, id) in plan.locations.indexed) {
        if (!places.contains(id)) bad('\$.locations[$i]', '$id is not a location of the season plan');
      }
    }

    // Missions m1, m2… in order, then the final; every id the case's own.
    final ids = <String>{};
    for (final (i, m) in plan.allMissions.indexed) {
      final isFinalSlot = i == plan.missions.length;
      final at = isFinalSlot ? r'$.final' : '\$.missions[$i]';
      final slot = isFinalSlot ? 'final' : 'm${i + 1}';
      if (m.slot != slot) bad('$at.slot', '${m.slot}, but it is ${isFinalSlot ? 'the final' : 'mission ${i + 1}'} ($slot)');
      final id = '${plan.caseId}_${m.slot}';
      if (m.missionId != id) bad('$at.missionId', '${m.missionId}, but ${m.slot} of ${plan.caseId} is $id');
      if (!ids.add(m.missionId)) bad('$at.missionId', '${m.missionId} given twice');
      out.addAll(_mission(m, plan, at));
    }
    return out;
  }

  /// A mission's own parts against its case: its outputs and place are its
  /// case's and season's, its puzzle's page is its slot's.
  static List<PlanIssue> _mission(MissionPlan m, CasePlan plan, String at) {
    final out = <PlanIssue>[];
    void bad(String path, String message) => out.add(PlanIssue(path, message));

    if (PlanIds.seasonOfScoped(m.placeId) != plan.seasonId) bad('$at.placeId', '${m.placeId} is not a place of ${plan.seasonId}');

    final outputs = m.clueOutputs;
    if (!m.isFinal && outputs.clue == null) bad('$at.clueOutputs.clue', 'missing: every mission before the final leaves a clue');
    for (final (key, id) in [
      ('clue', outputs.clue),
      ('evidence', outputs.evidence),
      for (final (i, f) in outputs.facts.indexed) ('facts[$i]', f),
    ]) {
      if (id != null && PlanIds.caseOfChild(id) != plan.caseId) bad('$at.clueOutputs.$key', '$id is not an id of ${plan.caseId}');
    }

    final p = m.puzzle;
    final surface = m.isFinal ? PlanSurface.finalMission : PlanSurface.mission;
    if (p.surface != surface) bad('$at.puzzle.surface', '${p.surface.name}, but a ${m.isFinal ? 'final' : 'mission'} is played on ${surface.name}');
    if (p.paletteId == null && p.status != PuzzleStatus.devRequest) {
      bad('$at.puzzle.paletteId', 'missing: only a development request has no palette puzzle');
    }
    if (p.status == PuzzleStatus.devRequest && p.devNote == null) bad('$at.puzzle.devNote', 'missing: a development request says what to develop');
    for (final (i, id) in p.assetNeeds.indexed) {
      if (PlanIds.seasonOfScoped(id) != plan.seasonId) bad('$at.puzzle.assetNeeds[$i]', '$id is not an asset of ${plan.seasonId}');
    }
    return out;
  }
}
