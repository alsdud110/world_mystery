import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/data/models/investigation.dart' show InvestigationSpot;
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/scene_deduction.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;
import 'package:world_mystery/features/mission/widgets/scene_deduction.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_models.dart';

/// Seoul (Season 5) Case 01, Mission 1 (`content_pipeline/seasons/s5_seoul`): the
/// inner gate's picture holds no writing, so the app draws the three traces
/// (`TraceSketch`: the scrap with 門 copied on it, the bucket's wet ring, the
/// drops of water) over their measured areas: each where a tap notes it,
/// seen on the smallest phone, named for screen readers.
void main() {
  const plan = 'content_pipeline/seasons/s5_seoul/cases/s5_ep01/case.plan.json';
  final raw = jsonDecode(File(plan).readAsStringSync()) as Map<String, dynamic>;
  final casePlan = CasePlan.fromJson(raw);
  final traces = casePlan.missions[0].play!.traces!;
  final (w, h) = (traces.picture.width.toDouble(), traces.picture.height.toDouble());
  Rect rect(SceneRect r) => Rect.fromLTRB(r.left / w, r.top / h, r.right / w, r.bottom / h);
  Offset point(ScenePoint p) => Offset(p.x / w, p.y / h);

  DeductionScene scene({bool sketched = true}) => DeductionScene(
    picture: traces.picture.file,
    pixels: ScenePixels(w, h),
    place: traces.place,
    task: traces.task,
    chooseTask: traces.chooseTask,
    missLine: traces.missLine,
    notPlaceLine: traces.notPlaceLine,
    clues: [
      for (final c in traces.clues)
        DeductionClue(
          id: c.id,
          label: c.label,
          areas: [for (final a in c.areas) rect(a)],
          mark: point(c.mark),
          line: c.line,
          sketch: sketched ? TraceSketch.values.byName(c.sketch!) : null,
        ),
    ],
    others: [for (final o in traces.others) InvestigationSpot(label: o.label, areas: [for (final a in o.areas) rect(a)], line: o.line)],
    places: [for (final p in traces.places) DeductionPlace(optionId: p.optionId, areas: [for (final a in p.areas) rect(a)], mark: point(p.mark))],
    guideAt: point(traces.guideAt),
    inside: rect(traces.inside!),
    opening: rect(traces.opening!),
  );
  final mission = Mission.fromJson((CaseGenerator.episodeJson(casePlan)['missions'] as List)[0] as Map<String, dynamic>);

  Future<DeductionProgress> open(WidgetTester t, DeductionScene s, {double text = 1}) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final progress = DeductionProgress()..guideShown = true;
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(320, 568), textScaler: TextScaler.linear(text)),
          child: Scaffold(
            body: SceneDeduction(
              scene: s,
              mission: mission,
              progress: progress,
              onChanged: () {},
              onChoose: (_) {},
              hintsShown: 0,
              onHint: () {},
              wrongPulse: 0,
            ),
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    return progress;
  }

  test('the plan names a sketch for each of its three traces, the picture lacking them', () {
    expect({for (final c in traces.clues) c.id: c.sketch}, {'scrap': 'copiedScrap', 'ring': 'waterRing', 'drops': 'waterDrops'});
  });

  test('the generator writes the sketches (made in memory only)', () {
    const seasonPath = 'content_pipeline/seasons/s5_seoul/season.plan.json';
    final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: const ['content_pipeline/seasons/s5_seoul/cases/s5_ep01/case.plan.json'], staticOnly: true);
    final code = made.files['s5_ep01.g.dart']!;
    expect(code, allOf(contains('sketch: TraceSketch.copiedScrap'), contains('sketch: TraceSketch.waterRing'), contains('sketch: TraceSketch.waterDrops')));
    expect(code, contains('show DeductionClue, DeductionPlace, DeductionScene, TraceSketch'));
  });

  for (final text in [1.0, 1.6]) {
    testWidgets('320×568, text ×$text: each trace drawn on screen, where a tap notes it, named for screen readers', (t) async {
      final s = scene();
      final progress = await open(t, s, text: text);
      expect(t.takeException(), isNull);
      final semantics = t.ensureSemantics();
      for (final c in s.clues) {
        final drawn = find.byKey(ValueKey('sketch-${c.id}'));
        expect(drawn, findsOneWidget, reason: c.id);
        final r = t.getRect(drawn);
        expect(r.left >= 0 && r.right <= 320 && r.top >= 0 && r.bottom <= 568, isTrue, reason: '${c.id} $r on screen');
        // ignore: avoid_print
        print('×$text ${c.id}: drawn ${r.size.width.toStringAsFixed(1)}×${r.size.height.toStringAsFixed(1)} at ${r.topLeft}');
        expect(r.shortestSide, greaterThanOrEqualTo(12), reason: '${c.id}: seen on a small phone');
        expect(find.bySemanticsLabel(c.label), findsOneWidget, reason: '${c.id}: named for screen readers');
        // Its own sign: no glass over it until it is noted.
        expect(find.byKey(ValueKey('mark-${c.id}')), findsNothing, reason: '${c.id}: nothing covers it');
        // The drawing is the trace's tap area: its middle notes it, and the glass ticks it.
        await t.tapAt(r.center);
        await t.pump(const Duration(milliseconds: 400));
        expect(progress.hasNoted(c.id), isTrue, reason: '${c.id}: tapped where it is drawn');
        expect(find.byKey(ValueKey('mark-${c.id}')), findsOneWidget, reason: '${c.id}: noted, ticked');
      }
      semantics.dispose();
      await t.pumpAndSettle();
    });
  }

  testWidgets('without a sketch (London\'s pictures show their traces): nothing drawn', (t) async {
    final s = scene(sketched: false);
    await open(t, s);
    for (final c in s.clues) {
      expect(find.byKey(ValueKey('mark-${c.id}')), findsOneWidget, reason: 'its glass shows where to look, as before');
    }
    expect(find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key! as ValueKey).value}'.startsWith('sketch-')), findsNothing);
  });
}
