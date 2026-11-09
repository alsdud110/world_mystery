import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/season5/season5_content.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import '../developer_session_test.dart' show openGameMaster, player, pumpGame;
import '../full_playthrough_test.dart' show tapText;

/// Seoul (Season 5) in developer mode: its pictures are its own, and the Game
/// Master has no Case 01 shortcut of its own (Seoul opens from its season in
/// the case shortcuts, as every season does).
void main() {
  tearDown(() {
    SeasonCatalog.testSeasons.clear();
    SeasonCatalog.testPlaces.clear();
  });

  test('the pilot\'s own pictures: no London or Paris picture; every one on disk, none with writing drawn by hand', () {
    String all(Object? o) => '$o';
    final made = [
      for (final p in season5Content.places.values) p.file,
      for (final d in season5Content.deductions.values) d.picture,
      for (final t in season5Content.talks.values) ...[all(t.background), ...t.speaker.portraits.values],
      for (final t in season5Content.talkMissions.values) for (final s in [?t.before, ?t.after]) ...s.speaker.portraits.values,
      for (final e in season5Content.endings.values) for (final l in e) ...[l.background, ?l.portrait],
      ...season5Content.introBackdrops.values,
    ];
    expect(made, isNotEmpty);
    for (final f in made) {
      expect(f, isNot(matches(RegExp('season_0[1-4]_'))), reason: f);
    }
    for (final f in made.where((f) => f.startsWith('assets/'))) {
      expect(File(f).existsSync(), isTrue, reason: f);
    }
    expect(season5Content.introBackdrops[seoulCase01Id], 'assets/seasons/season_05_seoul/cover/kings_study.webp');
    // Case 01's evidence is drawn with its words (no picture of the first
    // design is left wired); the later cases' evidence pictures are their own.
    expect(ArtAssets.evidencePictures.keys.where((id) => id.startsWith('s5_ep01_')), isEmpty);
  });

  testWidgets('the Game Master has no Seoul Case 01 shortcut, in developer mode or not: Seoul is opened from its season', (t) async {
    await pumpGame(t, player());
    await openGameMaster(t);
    expect(find.text('SEOUL — CASE 01'), findsNothing);
    await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsOneWidget);
    await t.scrollUntilVisible(find.text('SELECT SEASON'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('SEOUL — CASE 01'), findsNothing);
    expect(find.byKey(const ValueKey('seoul-pilot')), findsNothing);
  });
}
