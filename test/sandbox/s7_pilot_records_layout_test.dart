import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/tower_puzzles.dart';
import 'package:world_mystery/features/mission/widgets/tower_records.dart' show RecordPaper;

/// Seoul Pilot Case 01, Mission 2 (`test/sandbox/plans/s7_seoulpilot`): its
/// two four-line papers on the records engine's own paper, at the smallest
/// phone width: every line a 44 dp target at least, every value readable. Only the layout: the pilot is never generated or played
/// while its history waits for approval (HistoryGate).
void main() {
  const plan = 'test/sandbox/plans/s7_seoulpilot/cases/s7_ep01/case.plan.json';
  final records = (((jsonDecode(File(plan).readAsStringSync()) as Map)['missions'] as List)[1] as Map)['play']['records'] as Map;

  RecordDoc doc(Map d) {
    final pic = d['picture'] as Map;
    final px = ScenePixels((pic['pixels']['width'] as num).toDouble(), (pic['pixels']['height'] as num).toDouble());
    final c = [for (final v in d['crop'] as List) (v as num).toDouble()];
    final s = d['sheet'] as Map;
    Offset at(int i) => Offset(((s['corners'] as List)[i][0] as num).toDouble(), ((s['corners'] as List)[i][1] as num).toDouble());
    final t = [for (final v in s['title'] as List) (v as num).toDouble()];
    double n(String k) => (s[k] as num).toDouble();
    return RecordDoc(
      id: d['id'] as String,
      name: d['name'] as String,
      file: pic['file'] as String,
      pixels: px,
      crop: Rect.fromLTRB(c[0] / px.width, c[1] / px.height, c[2] / px.width, c[3] / px.height),
      sheet: PaperQuad(
        topLeft: at(0),
        topRight: at(1),
        bottomRight: at(2),
        bottomLeft: at(3),
        flat: Size(((s['flat'] as List)[0] as num).toDouble(), ((s['flat'] as List)[1] as num).toDouble()),
      ),
      layout: RecordLayout(
        title: Rect.fromLTRB(t[0], t[1], t[2], t[3]),
        rows: [for (final r in s['rows'] as List) (r as num).toDouble()],
        rowHeight: n('rowHeight'),
        labelLeft: n('labelLeft'),
        labelRight: n('labelRight'),
        valueLeft: n('valueLeft'),
        valueRight: n('valueRight'),
        noteRow: n('noteRow'),
        reach: n('reach'),
      ),
      title: d['title'] as String,
      lines: [for (final l in d['lines'] as List) RecordLine(id: l['id'] as String, label: l['label'] as String, value: l['value'] as String)],
      note: d['note'] as String?,
      label: d['label'] as String,
    );
  }

  for (final scale in [1.0, 1.6]) {
    for (final side in ['first', 'second']) {
      testWidgets('$side paper: four lines on a 320×568 phone, text ×$scale', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final d = doc(records[side] as Map);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: const Size(320, 568), textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: RecordPaper(doc: d, onPick: (_) {})),
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rows = [for (final l in d.lines) tester.getRect(find.byKey(ValueKey('line-${d.id}-${l.id}')))];
        expect(rows, hasLength(4));
        for (final r in rows) {
          expect(r.left >= 0 && r.right <= 320 && r.top >= 0 && r.bottom <= 568, isTrue, reason: '$r is on the screen');
        }
        // Rows read top to bottom, no target over the next; each one a finger's (44 dp).
        for (var i = 1; i < rows.length; i++) {
          expect(rows[i].top, greaterThanOrEqualTo(rows[i - 1].bottom));
        }
        for (final r in rows) {
          expect(r.height, greaterThanOrEqualTo(44));
        }
        // Each value as drawn (the paper scales it down to its column): 11 px at least.
        double drawn(String v) => tester.getRect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == v).first).height;
        // ignore: avoid_print
        print('$side ×$scale: paper ${tester.getRect(find.byType(RecordPaper)).size}, row targets ${[for (final r in rows) r.height.toStringAsFixed(1)]}, '
            'values drawn ${[for (final l in d.lines) '${l.value}=${drawn(l.value).toStringAsFixed(1)}']}');
        for (final l in d.lines) {
          expect(drawn(l.value), greaterThanOrEqualTo(11), reason: l.value);
        }
      });
    }
  }
}
