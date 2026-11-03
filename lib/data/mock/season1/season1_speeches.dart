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
///
/// One person, one portrait, wherever they talk (Mrs Bell in Cases 02 and
/// 12, Grey in Cases 07 and 12, the Ravenmaster twice in Case 10). No picture
/// shows an answer before it is found: the butler holds no key (Case 09 M1),
/// Carl wears no hat (Case 09's final), Mrs Robin's scarf and arms hide her
/// coat's buttons (Case 08's final).
const _mrsBell = TalkSpeaker(
  id: 'mrsBell',
  name: 'MRS BELL',
  portraits: {'base': '$_london/characters/mrs_bell.webp'},
  description: "Mrs Bell, Big Ben's old clockkeeper, with her ring of old keys, whispering",
);
const _grey = TalkSpeaker(
  id: 'inspectorGrey',
  name: 'INSPECTOR GREY',
  portraits: {'base': '$_london/characters/inspector_grey.webp'},
  description: 'Inspector Grey, a tall man in a grey hat and a dark coat, pointing the way',
);
// The man, not his bird: `characters/raven_master.webp` is a raven.
const _ravenmaster = TalkSpeaker(
  id: 'ravenmaster',
  name: 'RAVENMASTER',
  portraits: {'base': '$_london/characters/ravenmaster.webp'},
  description: 'the Ravenmaster of the Tower, white-bearded, a raven on his glove',
);

const Map<String, MissionSpeech> season1Speeches = {
  // ── Case 02 Final — The Great Clock ──────────────────────────────────
  // Mrs Bell whispers what to do; the clock is set on its face after.
  'ep02_final': MissionSpeech(
    speaker: _mrsBell,
    goal: 'Find the time the thief will take the picture.',
    background: '$_london/locations/big_ben/clock_mechanism.webp',
  ),

  // ── Case 03 M3 — The Wet Footprints ──────────────────────────────────
  // The cleaner says how wet each footprint was; the steps are put in order
  // on the floor after.
  'ep03_m3': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'cleaner',
      name: 'CLEANER',
      portraits: {'base': '$_london/characters/cleaner.webp'},
      description: 'a museum cleaner with a mop, pointing at the floor',
    ),
    goal: 'Find out which way the wet footprints went.',
    background: '$_london/locations/british_museum/british_museum_great_court.webp',
  ),

  // ── Case 07 Final — The Last Piece ───────────────────────────────────
  'ep07_final': MissionSpeech(
    speaker: _grey,
    goal: 'Find where to stop in the park.',
    background: '$_london/locations/landmarks/hyde_park.webp',
  ),

  // ── Case 08 Final — The Last Train ───────────────────────────────────
  // Her lie, said to the detective's face; the evidence answers it.
  'ep08_final': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'mrsRobin',
      name: 'MRS ROBIN',
      portraits: {'base': '$_london/characters/mrs_robin.webp'},
      description: 'Mrs Robin in a long red coat and a blue scarf, arms folded, chin up',
    ),
    goal: 'Find what proves where she has been.',
    background: '$_london/locations/landmarks/kings_cross.webp',
  ),

  // ── Case 09 M1 — The Empty Box ───────────────────────────────────────
  'ep09_m1': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'headButler',
      name: 'HEAD BUTLER',
      portraits: {'base': '$_london/characters/head_butler.webp'},
      description: 'the head butler of the palace in a black tailcoat and white gloves, one finger raised',
    ),
    goal: 'Find out whose key opened the jewel case.',
    background: '$_london/locations/landmarks/buckingham_palace.webp',
  ),

  // ── Case 09 M2 — The New Helper ──────────────────────────────────────
  'ep09_m2': MissionSpeech(
    speaker: TalkSpeaker(
      id: 'guardCarl',
      name: 'GUARD CARL',
      portraits: {'base': '$_london/characters/guard_carl.webp'},
      description: 'a young palace guard in a red tunic, scratching his head as he tries to remember',
    ),
    goal: "Find out the new helper's name.",
    background: '$_london/locations/buckingham_palace/buckingham_palace_palace_staff_room.webp',
  ),

  // ── Case 10 M1 — Which Raven? / Final — The Raven's Message ──────────
  'ep10_m1': MissionSpeech(
    speaker: _ravenmaster,
    goal: 'Find out which raven brings the words.',
    background: '$_london/locations/landmarks/tower_of_london.webp',
  ),
  'ep10_final': MissionSpeech(
    speaker: _ravenmaster,
    goal: "Read the raven's message.",
    background: '$_london/locations/landmarks/tower_bridge.webp',
  ),

  // ── Case 12 M1 — The Real Gear ───────────────────────────────────────
  'ep12_m1': MissionSpeech(
    speaker: _mrsBell,
    goal: 'Find the real gear.',
    background: '$_london/locations/big_ben/clock_mechanism.webp',
  ),

  // ── Case 12 M2 — The Last Train In ───────────────────────────────────
  // The arrivals board stays a paper; only Grey's words under it are said
  // (the letter keeps both, word for word at every level: see
  // MissionSpeech.inLetter). The puzzle's reread shows his words and the
  // board, each once.
  'ep12_m2': MissionSpeech(
    speaker: _grey,
    goal: "Find out when the Clockmaker's train comes in.",
    background: '$_london/locations/kings_cross/kings_cross_waiting_hall.webp',
    inLetter: true,
  ),

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
