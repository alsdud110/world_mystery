import '../../models/case_talk.dart';
import '../../models/mission_speech.dart';

const _london = 'assets/seasons/season_01_london';

/// Missions where a person talks to the detective (presentation only:
/// nothing here is saved but the talk heard). Mission id → who talks, over
/// which place. The words are the mission's own at its level (see
/// [MissionSpeech]): the case data, its answers and its tips stay as they
/// are, and so do its Junior and Master words.
///
/// Letters, notes, cards and signs stay papers; words on a thing are shown
/// on the thing (`ArtAssets.inscriptions`). Only what a person says to the
/// detective is a talk.
const Map<String, MissionSpeech> season1Speeches = {
  // ── Case 11 M3 — The Stage Door ──────────────────────────────────────
  // The driver's description is the puzzle (two big arches and a clock
  // tower; "I love trains"): said line by line, then read again from the
  // puzzle ("What the driver said"), never shown as a letter.
  'ep11_m3': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'taxiDriver',
      name: 'TAXI DRIVER',
      portraits: {'base': '$_london/characters/taxi_driver.webp'},
      description: 'an old London taxi driver in a flat cap and a thick dark coat, pointing the way',
    ),
    goal: 'Find out where the stranger ran.',
    background: '$_london/locations/covent_garden/theatre_door_dark.webp',
  ),

  // ── Case 11 Final — Behind the Mask ──────────────────────────────────
  // The stranger's greeting (the story's quoted words), then the card he
  // hands over — a real card, read as a letter after the talk. His name is
  // the puzzle: never on his name plate, never on his face (his picture
  // keeps the white mask on until the case is solved, and his face hidden
  // after).
  'ep11_final': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'stranger',
      name: 'THE STRANGER',
      portraits: {'base': '$_london/characters/stranger_masked.webp'},
      description: 'a stranger in a white mask and a long black hooded cloak, giving a small bow',
    ),
    goal: 'Find out who is behind the mask.',
    background: '$_london/locations/landmarks/kings_cross.webp',
    fromStory: true,
  ),
};
