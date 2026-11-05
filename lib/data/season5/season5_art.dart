import 'dart:ui' show Offset, Size;

import 'package:flutter/painting.dart' show Alignment;

import '../../features/mission_map/map_world.dart' show SeasonLandmark, SeasonMap;
import '../../widgets/art_assets.dart' show SeasonCover;

// Season 5's art, registered by hand as a generated season's `*_art.g.dart`
// is: its map (`SeasonMap.bySeason`) and its cover (`ArtAssets.seasonCovers`).
// Its city on the World Map is `WorldCities.seoul`.

// The three drawn places on its map, at the centre of each one's drawing
// (measured on assets/seasons/season_05_seoul/locations/map/palace_map.webp):
// the gatehouse is the inner gate, the left hall the book hall, the right
// hall the servants' yard with Sora's writing room.
const _bookHall = SeasonLandmark('book_hall', 'The Book Hall', Offset(255 / 1536, 360 / 1024));
const _wellYard = SeasonLandmark('well_yard', 'The Well Yard', Offset(1320 / 1536, 330 / 1024));
const _innerGate = SeasonLandmark('inner_gate', 'The Inner Gate', Offset(760 / 1536, 725 / 1024));

/// Its Mission Map: the palace grounds, every mission at its place.
const season5Map = SeasonMap(
  artwork: 'assets/seasons/season_05_seoul/locations/map/palace_map.webp',
  pixels: Size(1536, 1024),
  aspect: 1536 / 1024,
  landmarks: [_bookHall, _wellYard, _innerGate],
  missionLandmarks: {
    's5_ep01_m1': _innerGate,
    's5_ep01_m2': _wellYard,
    's5_ep01_m3': _wellYard,
    's5_ep01_final': _bookHall,
  },
);

/// Its cover: the palace at night under the moon, Bugaksan behind (the
/// season's city at night, made with its pictures and kept until now).
const season5Cover = SeasonCover(
  file: 'assets/seasons/season_05_seoul/cover/season5_prologue_night.webp',
  pixels: Size(1024, 1536),
  // The lit hall (drawn between 15% and 55% of its height), not the empty
  // paving below it, kept for words.
  archiveLook: Alignment(0, -0.1),
  crop: Alignment(0, 0),
  push: Alignment(0, -0.2),
);
