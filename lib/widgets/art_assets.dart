import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/painting.dart' show Alignment;

import '../data/generated/generated_season_art.g.dart';
import '../data/models/mission.dart';
import '../data/models/profile.dart';
import '../data/models/season.dart' show SeasonIds;
import '../features/game/scoring.dart';

/// The two pictures of the Royal Box: shut, and open with the Crown inside,
/// on canvases of the same size, in register. [dials] are the shut box's
/// four dial drums, left to right, where the game writes the numbers the
/// detective turns the locks to (fractions of the picture; empty: the shut
/// picture has its own). [shut] and [opened] are the parts of the canvas
/// the box fills, shut and open (fractions): the page looks closer at the
/// open box, so the Crown reads large.
typedef RoyalBoxArt = ({
  String closed,
  String open,
  List<Rect> dials,
  Rect shut,
  Rect opened,
});

/// A clock face picture with no hands, and the hands drawn over it: where
/// its pivot is and how long its hands are (fractions of the picture's
/// width / height), and the time it shows before and after its case is
/// solved (hours, minutes).
typedef ClockHandsArt = ({
  Offset pivot,
  double hourLength,
  double minuteLength,
  ({int hour, int minute}) before,
  ({int hour, int minute}) after,
});

/// The kinds of paper a document evidence is shown on
/// ([ArtAssets.evidencePapers]): its words are the evidence's own, set by
/// the app, never drawn into the picture.
enum EvidencePaper { note, card, letter, log, diary, ticket, tag, notice, map, music, statement }

/// A blank paper picture: its file, its width / height and where its words
/// go (fractions of the picture).
typedef PaperArt = ({String file, double aspect, Rect writing});

/// How the player's detective looks at a moment of play (see
/// [ArtAssets.detective]). The pictures are named after these: never rename
/// one without its files.
enum DetectiveExpression {
  /// Chin in hand: working out a puzzle, or looking again.
  thinking,

  /// Wide eyes, a letter in hand: something new has just turned up.
  surprised,

  /// Magnifying glass up: searching a place.
  investigating,

  /// Fists up, eyes shut with joy: a mission solved.
  happy,

  /// Pointing out, glass in hand: the whole case solved.
  confident,
}

/// Where a detective picture's medallion is cut: the centre of the circle
/// and its radius, in the picture's own pixels ([pixels]).
typedef DetectiveCrop = ({Size pixels, Offset centre, double radius});

/// The one place where finished artwork files are plugged in.
///
/// A picture without a file is drawn in code: scenes by `LandmarkArt`,
/// symbols and badges by the Ink Icon System (or a monogram while a drawing
/// is still a Custom Asset Required). When an illustrator delivers a file,
/// add it under `assets/art/`, list the folder in pubspec.yaml, and add one
/// line here. No screen changes. A missing or broken file falls back to the
/// drawing, so the game never shows an empty frame.
///
/// Files are PNG (or WebP/JPEG) loaded with `Image.asset`, with no extra
/// packages. SVG would need a new dependency and is not used.
abstract final class ArtAssets {
  /// The Mission Map artwork: a 3:2 landscape London map ([londonMapAspect]).
  /// Streets, river and landmarks only; pins and place names are drawn by
  /// the app (landmark positions: `Landmark` in `map_world.dart`). A missing
  /// or broken file falls back to the map drawn in code (`LondonMapPainter`).
  static const londonMap = 'assets/seasons/season_01_london/locations/map/london_mystery.webp';

  /// Width / height of [londonMap]: the map world keeps this ratio (never
  /// stretched); the map camera shows one part of it at a time.
  static const londonMapAspect = 3 / 2;

  /// Pixel size of [londonMap]: it is never decoded larger than this.
  static const londonMapPixels = Size(1536, 1024);

  /// Season 2's Mission Map: a 3:2 Paris map in the London map's style.
  /// Streets, the Seine and ten landmarks only (landmark positions:
  /// `ParisLandmark` in `map_world.dart`). A missing or broken file shows
  /// plain parchment, never London.
  static const parisMap = 'assets/seasons/season_02_paris/locations/map/paris_mystery.webp';

  /// Width / height of [parisMap] (the same ratio as London's).
  static const parisMapAspect = 3 / 2;

  /// Pixel size of [parisMap].
  static const parisMapPixels = Size(1536, 1024);

  /// The World Map: the whole world, navy sea and golden land with
  /// landmarks, no Antarctica, no markers: the cities' pins are the app's, by their
  /// landmarks (`WorldCity.mapAt`). A missing or broken file shows plain
  /// navy sea, never another map. The v4 artwork (1983 × 793) upscaled
  /// three times (5949 × 2379, Real-ESRGAN) so it stays sharp zoomed in.
  static const worldMap = 'assets/shared/world_map/world_map_v5.jpg';

  /// Width / height of [worldMap].
  static const worldMapAspect = 1983 / 793;

  /// The cities' pins on [worldMap] (96 × 120, the tip at the bottom
  /// middle, transparent): the season under way, a season complete, a city
  /// locked; and the gold ring round a chosen pin's head (144 × 144).
  static const worldMapPinInProgress = 'assets/shared/world_map/pin_in_progress.webp';
  static const worldMapPinCompleted = 'assets/shared/world_map/pin_completed.webp';
  static const worldMapPinLocked = 'assets/shared/world_map/pin_locked.webp';
  static const worldMapPinRing = 'assets/shared/world_map/pin_selected_ring.webp';

  /// The longitudes at [worldMap]'s west and east edges and the latitudes
  /// at its north and south edges (for a city with no painted marker, and
  /// the opening zoom), read off an earlier map's coastlines (a painting, so
  /// near enough: within about 2° around the game's cities). It reaches a
  /// little past one turn of the world, so the Bering Strait shows at both
  /// ends.
  static const worldMapWest = -163.6;
  static const worldMapEast = 211.2;
  static const worldMapNorth = 90.0;
  static const worldMapSouth = -66.0;

  /// The title screen: the detective's study on a London evening, in warm
  /// watercolour — bookshelves and the lamp on the left, the desk with a
  /// sealed letter, map and magnifying glass below, and a wide window over
  /// Westminster (Big Ben on the right, the moon above it). Portrait, no
  /// text: the window's sky is left for the title. The title screen (and,
  /// blurred, behind the registration form) only.
  static const titleDetectiveOffice = 'assets/shared/title/title_detective_office.webp';

  /// Pixel size of [titleDetectiveOffice] (never decoded larger).
  static const titleDetectiveOfficePixels = Size(942, 1670);

  /// [titleDetectiveOffice] with the desk lamp off: the room lit by the
  /// moon alone, everything else in place to the pixel (same size). Faded
  /// over it when the lamp falters on the title screen.
  static const titleDetectiveOfficeLampOff = 'assets/shared/title/title_detective_office_lamp_off.webp';

  /// The Season 1 cover: London from above at dusk — the Thames and its
  /// bridges, Westminster and Big Ben on the right, St Paul's far off, a
  /// stone balcony and a gas lamp in front (portrait, no text). The cover
  /// only (and the season's file in the archive, [seasonCovers]): the
  /// opening's first scene has its own picture ([season1LondonNight]),
  /// closer in.
  static const season1CoverLondonPanorama = 'assets/seasons/season_01_london/cover/season1_cover_london_panorama.webp';

  /// Pixel size of [season1CoverLondonPanorama] (never decoded larger).
  static const season1CoverLondonPanoramaPixels = Size(941, 1672);

  /// The Season 2 cover: Paris from a café balcony at dusk — the Seine and
  /// its bridges, the Eiffel Tower on the left, Notre-Dame on the right, a
  /// gas lamp and a pocket watch on the table in front (portrait, no text).
  /// It names the city: shown only once Season 2 is unsealed.
  static const season2CoverParisPanorama = 'assets/seasons/season_02_paris/cover/season2_cover_paris_panorama.webp';

  /// Pixel size of [season2CoverParisPanorama].
  static const season2CoverParisPanoramaPixels = Size(941, 1671);

  /// Season 2's opening, at Gare du Nord: the iron-and-glass hall in the
  /// morning light, a train on the left, great station clocks on the right
  /// (portrait, no text). Shown full screen once, in the opening's third
  /// scene. Missing → only the night.
  static const season2GareDuNord = 'assets/seasons/season_02_paris/cover/season2_gare_du_nord.webp';

  /// Pixel size of [season2GareDuNord] (never decoded larger).
  static const season2GareDuNordPixels = Size(941, 1671);

  /// Each season's cover by season id (see [SeasonCover]): the one place a
  /// season's cover is registered. A season without one shows its file
  /// without a picture, and its board the night only (never another
  /// season's).
  static const seasonCovers = <String, SeasonCover>{
    SeasonIds.london: SeasonCover(
      file: season1CoverLondonPanorama,
      pixels: season1CoverLondonPanoramaPixels,
      // The city under the evening sky, not the balcony.
      archiveLook: Alignment(0, 0.1),
      // Big Ben stands near the right edge; the gas lamp on the left gives
      // up a little of its edge instead.
      crop: Alignment(0.6, 0),
      push: Alignment(0.7, -0.15),
    ),
    SeasonIds.paris: SeasonCover(
      file: season2CoverParisPanorama,
      pixels: season2CoverParisPanoramaPixels,
      // The Eiffel Tower and Notre-Dame over the Seine, not the café table.
      archiveLook: Alignment(0.1, -0.25),
      // The Eiffel Tower on the left, Notre-Dame on the right, the push
      // towards the river between them.
      crop: Alignment(0.3, 0),
      push: Alignment(0.2, -0.2),
    ),
    // The seasons made from plans (Rome on): their own (season plan `art.cover`).
    ...generatedSeasonCovers,
  };

  /// The first scene of the Season 1 opening: a warm London night on the
  /// embankment — Big Ben, Westminster, the bridge and the Thames, a gas
  /// lamp and wet paving in front (portrait, no text). Shown full screen
  /// once, as that scene's hero picture; used nowhere else, so the opening
  /// keeps its moment. Missing → the London drawn in code.
  static const season1LondonNight = 'assets/seasons/season_01_london/cover/season1_london_night.webp';

  /// Pixel size of [season1LondonNight] (never decoded larger).
  static const season1LondonNightPixels = Size(941, 1671);

  /// The player's detective, chosen at CREATE YOUR DETECTIVE (see
  /// `DetectiveAvatar`): a boy and a girl in the storybook's style, head and
  /// shoulders on transparency, 4:5. Custom Asset Required: the folder is
  /// already in pubspec.yaml, so dropping the two files in is enough; until
  /// then the choice shows the cap icon and its word.
  static const avatarBoy = 'assets/shared/detectives/avatars/detective_boy.webp';
  static const avatarGirl = 'assets/shared/detectives/avatars/detective_girl.webp';

  /// The player's detective through the cases, one picture per
  /// [DetectiveExpression]: `detectives/<boy|girl>/<expression>.webp`. The
  /// avatar is the one chosen at CREATE YOUR DETECTIVE; a detective made
  /// before avatars existed is shown as the boy (as in How to Play).
  ///
  /// Cut-outs on transparency (RGBA), waist up. They were delivered with a
  /// checkered backdrop painted in, which was taken out once (the delivered
  /// files are no longer kept). Shown whole (an illustration) or in a
  /// medallion ([detectiveCrops]).
  static String detective(DetectiveAvatar? avatar, DetectiveExpression expression) =>
      'assets/shared/detectives/expressions/${(avatar ?? DetectiveAvatar.boy).name}/${expression.name}.webp';

  /// The medallion of each detective picture (its pixel size, and the
  /// circle round the face with the hands and what they hold).
  static DetectiveCrop detectiveCrop(DetectiveAvatar? avatar, DetectiveExpression expression) =>
      detectiveCrops[avatar ?? DetectiveAvatar.boy]![expression]!;

  static const _square = Size(1254, 1254);
  static const _wide = Size(1312, 1199);

  static const detectiveCrops = <DetectiveAvatar, Map<DetectiveExpression, DetectiveCrop>>{
    DetectiveAvatar.boy: {
      // The chin in the hand.
      DetectiveExpression.thinking: (pixels: _square, centre: Offset(720, 600), radius: 400),
      // The face over the letter.
      DetectiveExpression.surprised: (pixels: _square, centre: Offset(730, 620), radius: 420),
      // The face and the magnifying glass.
      DetectiveExpression.investigating: (pixels: _square, centre: Offset(850, 700), radius: 400),
      DetectiveExpression.happy: (pixels: _square, centre: Offset(720, 480), radius: 420),
      // The pointing hand and the glass either side of the face.
      DetectiveExpression.confident: (pixels: _wide, centre: Offset(780, 540), radius: 470),
    },
    DetectiveAvatar.girl: {
      DetectiveExpression.thinking: (pixels: _square, centre: Offset(740, 620), radius: 420),
      DetectiveExpression.surprised: (pixels: _square, centre: Offset(760, 640), radius: 430),
      DetectiveExpression.investigating: (pixels: _square, centre: Offset(830, 700), radius: 420),
      DetectiveExpression.happy: (pixels: _wide, centre: Offset(790, 520), radius: 450),
      DetectiveExpression.confident: (pixels: _wide, centre: Offset(820, 560), radius: 470),
    },
  };

  /// How to Play (the first-play guide): its own pictures, never a case's
  /// character or evidence. A missing file leaves its place empty.
  ///
  /// The detective in the guide, as the player chose them (boy or girl; a
  /// detective made before avatars existed: the boy), waving hello: full
  /// figure on transparency, 2:3. One rule for every page: see
  /// [onboardingReady].
  static String onboardingWelcome(DetectiveAvatar? avatar) => switch (avatar) {
        DetectiveAvatar.girl => 'assets/shared/onboarding/detective_welcome_girl.webp',
        DetectiveAvatar.boy || null => 'assets/shared/onboarding/detective_welcome_boy.webp',
      };

  /// The same detective setting off, letter and magnifying glass in hand
  /// (the guide's last page). Same size as [onboardingWelcome].
  static String onboardingReady(DetectiveAvatar? avatar) => switch (avatar) {
        DetectiveAvatar.girl => 'assets/shared/onboarding/detective_ready_girl.webp',
        DetectiveAvatar.boy || null => 'assets/shared/onboarding/detective_ready_boy.webp',
      };

  /// Pixel size of the [onboardingWelcome] and [onboardingReady] pictures
  /// (all four alike, so the boy and the girl show at the same size).
  static const onboardingDetectivePixels = Size(1024, 1536);

  /// Mrs Moss, the tea seller: the practice witness (no case's), printed
  /// like the witnesses of the cases (4:5 on parchment, [witnessPortraitAspect]).
  static const onboardingWitness = 'assets/shared/onboarding/witness_tea_seller.webp';

  /// Pip, the practice puzzle's lost kitten (red collar): square, on
  /// transparency.
  static const onboardingCat = 'assets/shared/onboarding/lost_cat.webp';

  /// A pointing hand with a gold touch ring (the guide's word page shows
  /// how to press and hold a word): square, on transparency. Its fingertip
  /// is at [onboardingHandTip], as fractions of the picture.
  static const onboardingHand = 'assets/shared/onboarding/long_press_hand.webp';
  static const onboardingHandTip = Offset(0.42, 0.15);

  /// Scene pictures (mission, final, image choices, the arrival at a place,
  /// Case Solved photo), full colour: the nine London landmarks in
  /// `locations/landmarks/`, and the places inside a landmark in a folder named
  /// after it. A place inside a landmark (the Boathouse in Hyde Park) never
  /// borrows its landmark's picture: without its own it is drawn in code.
  static const Map<Artwork, String> scenes = {
    ...landmarkScenes,
    ...insideScenes,
    ...objectScenes,
    ...parisScenes,
  };

  /// Season 2's scenes: Gare du Nord's hall (Case 01), the old clock's face
  /// (no hands: [clockHands]), the painting of Montmartre from the brass
  /// box, where Case 02 begins, and Case 02's street (as it really is) and
  /// the painter's studio.
  static const parisScenes = <Artwork, String>{
    Artwork.gareDuNord: season2GareDuNord,
    Artwork.oldClockFace: '$_paris01/old_clock_face.webp',
    Artwork.montmartrePainting: '$_paris01/montmartre_painting.webp',
    Artwork.montmartreStreet: '$_paris02/montmartre_street_real.webp',
    Artwork.paintersStudio: '$_paris02/painters_studio.webp',
    Artwork.paintersMessage: '$_paris02/canvas_back.webp',
    Artwork.eiffelTower: '$_paris03/eiffel_tower_exterior.webp',
    Artwork.towerEntrance: '$_paris03/tower_notice_board.webp',
    Artwork.towerLift: '$_paris03/tower_lift.webp',
    Artwork.serviceDoor: '$_paris03/service_door.webp',
    Artwork.serviceRoom: '$_paris03/service_room.webp',
    Artwork.timeMachine: '$_paris03/time_recording_machine.webp',
    Artwork.seineQuays: '$_paris04/seine_quays_dusk.webp',
    Artwork.quayWall: '$_paris04/quay_wall_marks.webp',
    Artwork.keeperHut: '$_paris04/keeper_hut.webp',
    Artwork.keeperHutInside: '$_paris04/keeper_hut_interior.webp',
    Artwork.quayBoxes: '$_paris04/quay_boxes.webp',
    Artwork.passageGate: '$_paris04/passage_gate.webp',
    Artwork.workshopInterior: '$_paris05/workshop_interior.webp',
    Artwork.workbenchMarks: '$_paris05/workbench_marks.webp',
    Artwork.wallOfClocks: '$_paris05/wall_of_clocks.webp',
    Artwork.writingDesk: '$_paris05/writing_desk_blotter.webp',
    Artwork.louvrePostRoom: '$_paris06/louvre_post_room_exterior.webp',
    Artwork.holdRack: '$_paris06/post_room_hold_rack.webp',
    Artwork.archiveFloorPlan: '$_paris06/archive_floor_plan.webp',
    Artwork.archiveRoom: '$_paris06/archive_room.webp',
    Artwork.palaisGarnierNight: '$_paris07/palais_garnier_night.webp',
    Artwork.operaArchive: '$_paris07/opera_archive_room.webp',
    Artwork.operaStage: '$_paris07/stage_base.webp',
    Artwork.flyRail: '$_paris07/fly_rail.webp',
    Artwork.lightTable: '$_paris07/light_table_off.webp',
    Artwork.abbessesSquare: '$_paris08/abbesses_square.webp',
    Artwork.paintersCorner: '$_paris08/corner_2.webp',
    Artwork.drawingBundle: '$_paris08/drawing_bundle.webp',
    // Case 09: the garden (its own clock covered where its hands would
    // tell the wrong time: `season2_case09_scenes.dart`), and the board.
    Artwork.luxembourgGarden: '$_paris09/garden_model_view.webp',
    Artwork.gearBoard: '$_paris09/gear_board.webp',
    // Case 10: the arch, and the room under its roof.
    Artwork.arcStarView: '$_paris10/arc_star_view.webp',
    Artwork.starRoom: '$_paris10/star_room.webp',
    // Case 11: the street and the Archive Annex's reading room.
    Artwork.annexStreet: '$_paris11/annex_street.webp',
    Artwork.annexReadingRoom: '$_paris11/annex_reading_room.webp',
    // Case 12: the museum hall and the room of old machines.
    Artwork.artsMetiersHall: '$_paris12/arts_metiers_hall.webp',
    Artwork.oldMachineRoom: '$_paris12/old_machine_room.webp',
  };

  static const _paris01 = 'assets/seasons/season_02_paris/cases/case_01';
  static const _paris02 = 'assets/seasons/season_02_paris/cases/case_02';
  static const _paris03 = 'assets/seasons/season_02_paris/cases/case_03';
  static const _paris04 = 'assets/seasons/season_02_paris/cases/case_04';
  static const _paris05 = 'assets/seasons/season_02_paris/cases/case_05';
  static const _paris06 = 'assets/seasons/season_02_paris/cases/case_06';
  static const _paris07 = 'assets/seasons/season_02_paris/cases/case_07';
  static const _paris08 = 'assets/seasons/season_02_paris/cases/case_08';
  static const _paris11 = 'assets/seasons/season_02_paris/cases/case_11';
  static const _paris12 = 'assets/seasons/season_02_paris/cases/case_12';
  static const _paris09 = 'assets/seasons/season_02_paris/cases/case_09';
  static const _paris10 = 'assets/seasons/season_02_paris/cases/case_10';

  /// Clock faces cut out on transparency (a frame of their own): shown
  /// without a paper card behind them.
  static const cutOutClockFaces = {Artwork.oldClockFace};

  /// Scenes shown by a character or object picture: the Tower raven (Poppy)
  /// for the raven scenes, the old brown suitcase where the story finds one,
  /// and the Royal Box as it is once found: open, the Crown inside (the case
  /// photo; the final case itself animates [royalBox]). Never `special/
  /// royal_box.webp`: that is a theatre's royal box. Mrs Robin's black
  /// suitcase (Case 08, its name tag washed blank). Case 09's open glass
  /// case, its cushion empty and a card left on it. The two doors, each for
  /// its own case: the White Tower's, a dial and the four gears the final
  /// lock asks about (Case 05), and the small iron door under Big Ben
  /// (Case 12).
  ///
  /// Not here, on purpose: `objects/jewel_case.webp` (a full red box with a
  /// tiara: Case 09's glass case is empty, the Blue Star is a blue jewel) and
  /// `objects/locked_door.webp` (a plain arched wooden door, neither case's).
  /// That door is the Season opening's "doors found locked" print only.
  static const objectScenes = <Artwork, String>{
    Artwork.raven: '${_london}characters/raven_master.webp',
    Artwork.oldSuitcase: 'assets/shared/objects/suitcase.webp',
    Artwork.royalBox: '${_london}special/royal_box_open.webp',
    Artwork.blackSuitcase: 'assets/seasons/season_01_london/objects/suitcase_black.webp',
    Artwork.jewelCase: 'assets/seasons/season_01_london/objects/empty_glass_jewel_case.webp',
    Artwork.gearDoor: 'assets/seasons/season_01_london/objects/locked_door_gears.webp',
    Artwork.ironDoor: 'assets/seasons/season_01_london/objects/small_iron_door.webp',
    // The iron chest behind the White Tower's door (Case 05's final).
    Artwork.ironChest: 'assets/seasons/season_01_london/objects/iron_chest.webp',
    // Big Ben's clock (Case 02): its face with no hands (the hands are drawn
    // over it: [clockHands]), and the wheels behind it, no time to read.
    Artwork.clockFace: '$_scenes/big_ben/clock_face.webp',
    Artwork.clockMechanism: '$_scenes/big_ben/clock_mechanism.webp',
    // The masked stranger on Platform 9 (Case 11's final), a portrait on
    // parchment: his face is never shown (see [solvedScenes]).
    Artwork.maskedStranger: '${_london}characters/stranger_masked.webp',
  };

  /// Width / height of each scene picture that is not printed like the
  /// landmark set ([scenePrint]): frames take the picture's own ratio.
  static const sceneAspects = <Artwork, double>{
    Artwork.raven: 1,
    Artwork.oldSuitcase: 1,
    Artwork.royalBox: 1659 / 948,
    Artwork.greatCourt: 1264 / 848,
    Artwork.egyptRoom: 1264 / 848,
    Artwork.boathouse: 1288 / 816,
    Artwork.roseGarden: 1288 / 816,
    Artwork.staffRoom: 1288 / 816,
    Artwork.courtyard: 1288 / 816,
    Artwork.dressingRoom: 1290 / 816,
    Artwork.waitingRoom: 1273 / 832,
    Artwork.gallery: 1536 / 1024,
    Artwork.auditorium: 1536 / 1024,
    Artwork.blackSuitcase: 1377 / 1142,
    Artwork.jewelCase: 1536 / 1024,
    Artwork.gearDoor: 1536 / 1024,
    Artwork.ironDoor: 1536 / 1024,
    Artwork.theatreDoor: 1536 / 1024,
    Artwork.ironChest: 1536 / 1024,
    Artwork.royalArchive: 1536 / 1024,
    Artwork.clockFace: 1,
    Artwork.clockMechanism: 1536 / 1024,
    Artwork.maskedStranger: 1024 / 1536,
    // Season 2: Gare du Nord's hall, a portrait picture.
    Artwork.gareDuNord: 941 / 1671,
    Artwork.oldClockFace: 1,
    Artwork.montmartrePainting: 1774 / 887,
    Artwork.montmartreStreet: 1536 / 1024,
    // The studio: a portrait picture.
    Artwork.paintersStudio: 1024 / 1536,
    Artwork.paintersMessage: 1536 / 1024,
    // Case 03: the tower at dusk is a portrait picture; the rest are wide.
    Artwork.eiffelTower: 1024 / 1536,
    Artwork.towerEntrance: 1536 / 1024,
    Artwork.towerLift: 1536 / 1024,
    Artwork.serviceDoor: 1536 / 1024,
    Artwork.serviceRoom: 1536 / 1024,
    Artwork.timeMachine: 1536 / 1024,
    // Case 04: the gate is a portrait picture; the rest are wide.
    Artwork.seineQuays: 1536 / 1024,
    Artwork.quayWall: 1536 / 1024,
    Artwork.keeperHut: 1536 / 1024,
    Artwork.keeperHutInside: 1536 / 1024,
    Artwork.quayBoxes: 1536 / 1024,
    Artwork.passageGate: 1024 / 1536,
    // Case 05: all wide; the desk a little less tall than the rest.
    Artwork.workshopInterior: 1536 / 1024,
    Artwork.workbenchMarks: 1536 / 1024,
    Artwork.wallOfClocks: 1536 / 1024,
    Artwork.writingDesk: 1264 / 848,
    // Case 06: the plan of the building is a portrait picture; the rest
    // are wide.
    Artwork.louvrePostRoom: 1536 / 1024,
    Artwork.holdRack: 1536 / 1024,
    Artwork.archiveFloorPlan: 1024 / 1536,
    Artwork.archiveRoom: 1536 / 1024,
    // Case 07: all wide.
    Artwork.palaisGarnierNight: 1536 / 1024,
    Artwork.operaArchive: 1536 / 1024,
    Artwork.operaStage: 1536 / 1024,
    Artwork.flyRail: 1536 / 1024,
    Artwork.lightTable: 1536 / 1024,
    // Case 08: all wide.
    Artwork.abbessesSquare: 1536 / 1024,
    Artwork.paintersCorner: 1536 / 1024,
    Artwork.drawingBundle: 1536 / 1024,
    // Case 09: both wide.
    Artwork.luxembourgGarden: 1536 / 1024,
    Artwork.gearBoard: 1536 / 1024,
    // Case 10: both wide.
    Artwork.arcStarView: 1536 / 1024,
    Artwork.starRoom: 1536 / 1024,
    Artwork.annexStreet: 1536 / 1024,
    Artwork.annexReadingRoom: 1536 / 1024,
    Artwork.artsMetiersHall: 1536 / 1024,
    Artwork.oldMachineRoom: 1536 / 1024,
  };

  /// Width / height of the picture of [a] ([scenePrint] unless listed).
  static double sceneAspect(Artwork a) => sceneAspects[a] ?? scenePrint.size.aspectRatio;

  /// Recurring characters (full colour, on parchment, square), and the
  /// witnesses a mission talks to (Case 06's market hall: printed on
  /// parchment, 4:5 portraits, see `season1_dialogues.dart`).
  static const characters = <String, String>{
    'raven': '${_london}characters/raven_master.webp',
    'clockmaker': '${_london}characters/clockmaker_master.webp',
    'flowerSeller': '${_london}characters/flower_seller.webp',
    'juggler': '${_london}characters/juggler.webp',
    'baker': '${_london}characters/baker.webp',
  };

  /// Width / height of a witness portrait ([characters]: flower seller,
  /// juggler, baker).
  static const witnessPortraitAspect = 1122 / 1402;

  /// The Covent Garden market hall at closing time, inside (portrait 2:3):
  /// the room Case 06's witnesses are talked to in.
  static const marketHall = '$_scenes/covent_garden/covent_garden_market_hall.webp';

  /// Story objects (full colour, on parchment, square except the map).
  static const objects = <String, String>{
    'crown': 'assets/seasons/season_01_london/objects/crown.webp',
    'key': 'assets/shared/objects/key.webp',
    'letter': 'assets/shared/objects/letter.webp',
    'map': 'assets/shared/objects/map.webp',
    'pocketWatch': 'assets/shared/objects/pocket_watch.webp',
    'suitcase': 'assets/shared/objects/suitcase.webp',
  };

  /// The Season opening's prints of trouble, cut out on transparency: a
  /// stranger hiding his face (no one in particular: never the Clockmaker
  /// or the Ravenmaster) and a locked old door (mood only, no case's door).
  static const mysteriousStranger = '${_london}characters/mysterious_stranger.webp';
  static const lockedDoor = 'assets/shared/objects/locked_door.webp';

  /// Words written on a thing, shown on the thing itself instead of a
  /// letter (Season 1), by mission: the picture ([file], width / height
  /// [aspect]), where on it the words are written ([text], fractions of the
  /// picture: the game sets the mission's own letter there, so its spelling
  /// is exact and a screen reader can read it) and what the thing is
  /// ([thing], read out with the words). Case 11's white mask, turned over:
  /// its blank inner brow.
  static const Map<String, ({String file, double aspect, Rect text, String thing})> inscriptions = {
    'ep11_m2': (
      file: '${_london}objects/white_mask_inside.webp',
      aspect: 1,
      text: Rect.fromLTRB(0.31, 0.305, 0.69, 0.385),
      thing: 'The inside of the white mask',
    ),
  };

  /// The Raven Society mark (full colour, not a tinted [symbols] glyph).
  static const ravenMark = '${_london}symbols/raven_mark.webp';

  /// Case 04's black wax seal, a raven pressed into it (on transparency):
  /// the seal of R.'s letters and the Black Wax Seal in the notebook.
  static const blackWaxSeal = '${_london}objects/black_wax_seal_raven.webp';

  /// The seal pressed on a mission's letter, where it is not the game's own
  /// wax seal: Case 04's letters from R. ("the same black seal as the first
  /// letter"; the final's "pressed into every seal we send"). Only these.
  static const letterSeals = <String, String>{
    'ep04_m1': blackWaxSeal,
    'ep04_m3': blackWaxSeal,
    'ep04_final': blackWaxSeal,
  };

  /// Case 01's Royal Box (the final mission's golden box with the Crown
  /// inside), as two pictures on transparency (1659 × 948, in register):
  /// shut, its four dial drums blank — `royal_box_closed_blank.webp`, made
  /// from the delivered `royal_box_closed.webp` (kept, its drums painted
  /// 0000) by `tool/royal_box_blank/blank_test.dart` — so the game writes
  /// on them the numbers the detective turns the locks to; and open with the
  /// Crown in it, its drums showing the code (7924), shown only once the box
  /// is opened. The opening animation crossfades the two; a missing picture
  /// falls back to the box drawn in code (`RoyalBoxAnimation`).
  static const RoyalBoxArt royalBox = (
    closed: '${_london}special/royal_box_closed_blank.webp',
    open: '${_london}special/royal_box_open.webp',
    // The drums' digit faces, measured on the picture (pixels 521–552,
    // 709–740, 909–940, 1104–1135 across; 644–688 down).
    dials: [
      Rect.fromLTRB(521 / 1659, 644 / 948, 552 / 1659, 688 / 948),
      Rect.fromLTRB(709 / 1659, 644 / 948, 740 / 1659, 688 / 948),
      Rect.fromLTRB(909 / 1659, 644 / 948, 940 / 1659, 688 / 948),
      Rect.fromLTRB(1104 / 1659, 644 / 948, 1135 / 1659, 688 / 948),
    ],
    // Shut: the whole box, its wide brass corners included. Open: the box
    // from its lid to its feet, a little closer (the Crown larger).
    shut: Rect.fromLTRB(30 / 1659, 80 / 948, 1630 / 1659, 905 / 948),
    opened: Rect.fromLTRB(100 / 1659, 5 / 948, 1560 / 1659, 905 / 948),
  );

  /// The delivered shut Royal Box, its drums painted 0000: the source of
  /// [royalBox]'s shut picture, never shown (the 0000 would not follow the
  /// locks).
  static const royalBoxClosedPainted = '${_london}special/royal_box_closed.webp';

  /// Special pictures. The theatre royal box: listed, not shown yet — the
  /// game's Royal Box (Case 01) is a golden box with the Crown inside.
  static const special = <String, String>{
    'theatreRoyalBox': '${_london}special/royal_box.webp',
  };

  /// Evidence shown by its real picture (notebook, zoom, celebrations),
  /// by evidence id. Case 01's map (two swans) keeps its drawn mark, as do
  /// the maps whose drawn ravens the pictures lack. Case 01's Pocket Watch
  /// is the Royal Box's own watch, the same picture everywhere it appears
  /// (2026-10-19, requested), though that picture reads about ten past ten,
  /// not the 7 o'clock its words give.
  static const evidencePictures = <String, String>{
    'e01': 'assets/shared/objects/letter.webp', // Old Letter
    'e02': 'assets/shared/objects/key.webp', // Golden Key
    'e03': _case01PocketWatch, // Pocket Watch: the Royal Box's clock lock
    // Crown Symbol: the card with a crown on it (the crown it shows).
    'e05': 'assets/seasons/season_01_london/objects/crown.webp',
    'e06': 'assets/seasons/season_01_london/objects/crown.webp', // The Missing Crown
    'ep03_e1': 'assets/seasons/season_01_london/objects/red_button.webp', // Red Button (Case 03, again in Case 08)
    'ep04_e1': blackWaxSeal, // Black Wax Seal: a raven pressed into the black wax
    'ep05_e3': 'assets/shared/objects/key.webp', // Brass Key
    'ep10_e3': 'assets/shared/objects/letter.webp', // Ravenmaster's Letter
    'ep12_e4': 'assets/shared/objects/pocket_watch.webp', // The Clockmaker's Watch
    // Paris Case 01: the lost ticket and the Montmartre painting (wide
    // pictures: their middle in the round frame, whole in the close look,
    // [evidencePrints]).
    's2_ep01_e2': '$_paris01/lost_ticket.webp',
    's2_ep01_e4': '$_paris01/montmartre_painting.webp',
    // Paris Case 02: the painting of the street, its clock above the door.
    's2_ep02_e1': '$_paris02/montmartre_street_painted.webp',
    // Paris Case 03: the hidden room, and the plaque from the machine
    // (its message is in its words: the picture is the blank brass).
    's2_ep03_e3': '$_paris03/service_room.webp',
    's2_ep03_e4': '$_paris03/brass_plaque.webp',
    // Paris Case 04: its stone, ledger and label are blank pictures, drawn
    // with their words where they are shown (`season2Case04EvidenceArt`);
    // these are what stands under them.
    's2_ep04_e1': '$_paris04/river_mark_d.webp',
    's2_ep04_e2': '$_paris04/keeper_ledger.webp',
    's2_ep04_e3': '$_paris04/delivery_label_blank.webp',
    's2_ep04_e4': '$_paris04/delivery_label_blank.webp',
    // The icon upgrade (docs/WORLD_MYSTERY_ICON_UPGRADE_PROGRESS.md): each
    // object shown as itself, never its words or what it answers. Pictures
    // the game already had, where they agree with the evidence:
    'ep02_e2': _londonGear, // Small Brass Gear: the gear of Case 02's belfry search
    'ep12_e1': _londonGear, // The Real Gear: the same gear, back where it belongs
    'ep03_e2': '$_londonObjects/blue_cloth.webp', // Blue Cloth, as found on the frame
    // Wet Footprint: the search's footprint, its black ground cut away.
    'ep03_e3': '$_londonObjects/wet_footprint_cutout.webp',
    'ep04_e3': 'assets/shared/objects/letter.webp', // Postmark: on the second envelope
    // Rome's Owl leaves the same card each time (its words differ).
    's3_ep02_e1': _owlCard,
    's3_ep02_e4': _owlCard,
    's3_ep04_e1': _owlCard,
    's3_ep04_e3': _owlCard,
    's3_ep07_e1': _owlCard,
    's3_ep08_e1': _owlCard,
    's3_ep12_e4': _owlCard,
    's4_ep11_e2': '$_newYorkObjects/brass_bird.webp', // The Brass Bird, Found: Case 04's bird
    // Made for it (gpt-image-1.5, content_pipeline/icon_upgrade/).
    'ep02_e4': '$_londonObjects/raven_feather.webp',
    'ep06_e4': '$_londonObjects/silver_whistle.webp',
    'ep08_e3': '$_londonObjects/raven_tower_painting.webp',
    'ep08_e4': '$_londonObjects/empty_jewel_box.webp',
    'ep09_e4': '$_londonObjects/blue_star_jewel.webp',
    'ep10_e1': '$_londonObjects/poppys_ring.webp', // no letters: they are its words
    // The lost map of London, piece by piece (2026-11-03): the Tower's piece
    // (Case 05's chest), the river's and the station's, joined (its arrow),
    // and whole (nine ravens round the station). Their words under them.
    'ep05_e4': '$_london07/map_piece_park.webp',
    'ep07_e1': '$_london07/map_piece_river.webp',
    'ep07_e2': '$_london07/map_piece_station.webp',
    'ep07_e3': '$_london07/map_joined.webp',
    'ep07_e4': '$_london07/old_london_map.webp',
    'ep11_e2': '$_londonObjects/white_mask.webp', // nothing written: its words say what
    'ep11_e3': '$_londonObjects/toy_train_whistle.webp',
    's2_ep01_e3': '$_paris01/clockmaker_mark.webp', // the carved gear (the M is in its words)
    's3_ep01_e2': '$_romeObjects/white_dust.webp',
    's3_ep01_e4': '$_romeObjects/light_box.webp',
    's3_ep03_e2': '$_romeObjects/bag_of_white_dust.webp',
    's3_ep05_e1': '$_romeObjects/orange_cat_hair.webp',
    's3_ep05_e2': '$_romeObjects/cat_collar_tag.webp', // blank: its letters are its words
    's4_ep05_e3': '$_newYorkObjects/tiny_screws.webp',
    's4_ep05_e4': '$_newYorkObjects/karl_old_photo.webp',
    's4_ep06_e2': '$_newYorkObjects/seagull_photo.webp',
    's4_ep06_e4': '$_newYorkObjects/karl_pocket_book.webp', // shut: the notes on its page are words
    's4_ep09_e2': '$_newYorkObjects/wheel_box.webp', // blank rings
    's4_ep11_e4': '$_newYorkObjects/dexter_safe.webp',
    's4_ep12_e1': '$_newYorkObjects/stone_nest.webp', // no letters
    's4_ep12_e2': '$_newYorkObjects/open_stone.webp', // no letters
    // The seasons made from plans (Rome on): each picture made for an
    // evidence of their cases (their asset manifests).
    ...generatedEvidencePictures,
  };

  static const _londonObjects = 'assets/seasons/season_01_london/objects';
  static const _london07 = 'assets/seasons/season_01_london/cases/case_07';
  static const _londonGear = '$_londonObjects/brass_gear.webp';
  static const _romeObjects = 'assets/seasons/season_03_rome/objects';
  static const _owlCard = '$_romeObjects/owl_card.webp';
  static const _newYorkObjects = 'assets/seasons/season_04_newyork/objects';

  /// The papers documents are shown on: blank, the evidence's own words set
  /// on them by the app (`EvidencePaperView`) in the close look, so its
  /// English stays the game's (and follows the detective's level). [writing]
  /// is where the words go, as fractions of the picture.
  static const evidencePapers = <EvidencePaper, PaperArt>{
    // Clear of the torn top and the margin line.
    EvidencePaper.note: (file: '$_docs/doc_note.webp', aspect: 731 / 777, writing: Rect.fromLTRB(0.2, 0.15, 0.94, 0.92)),
    // Inside the printed border.
    EvidencePaper.card: (file: '$_docs/doc_card.webp', aspect: 961 / 639, writing: Rect.fromLTRB(0.12, 0.15, 0.88, 0.85)),
    EvidencePaper.letter: (file: '$_docs/doc_letter.webp', aspect: 790 / 942, writing: Rect.fromLTRB(0.12, 0.1, 0.88, 0.9)),
    EvidencePaper.log: (file: '$_docs/doc_log.webp', aspect: 846 / 982, writing: Rect.fromLTRB(0.14, 0.1, 0.9, 0.9)),
    // Below the ribbon.
    EvidencePaper.diary: (file: '$_docs/doc_diary.webp', aspect: 775 / 978, writing: Rect.fromLTRB(0.12, 0.14, 0.88, 0.9)),
    // Between the printed ends, before the stub.
    EvidencePaper.ticket: (file: '$_docs/doc_ticket.webp', aspect: 967 / 377, writing: Rect.fromLTRB(0.24, 0.16, 0.74, 0.84)),
    // Right of the eyelet.
    EvidencePaper.tag: (file: '$_docs/doc_tag.webp', aspect: 977 / 478, writing: Rect.fromLTRB(0.2, 0.16, 0.92, 0.84)),
    // Inside the pins and the border.
    EvidencePaper.notice: (file: '$_docs/doc_notice.webp', aspect: 848 / 903, writing: Rect.fromLTRB(0.12, 0.1, 0.88, 0.9)),
    // The clear middle of the old map.
    EvidencePaper.map: (file: '$_docs/doc_map.webp', aspect: 1024 / 893, writing: Rect.fromLTRB(0.2, 0.2, 0.8, 0.8)),
    EvidencePaper.music: (file: '$_docs/doc_music.webp', aspect: 953 / 731, writing: Rect.fromLTRB(0.08, 0.1, 0.92, 0.9)),
    // Right of the red margin, below the leather corner.
    EvidencePaper.statement: (file: '$_docs/doc_statement.webp', aspect: 736 / 935, writing: Rect.fromLTRB(0.14, 0.1, 0.9, 0.92)),
  };

  static const _docs = 'assets/shared/evidence_docs';

  /// The paper of document evidence [evidenceId], or null.
  static PaperArt? paperOf(String evidenceId) => evidencePapers[evidenceDocs[evidenceId]];

  /// Document evidence by id: the paper it is shown on. One place for every
  /// season; an evidence with its own picture ([evidencePictures]) or drawn
  /// by its case ([SeasonCatalog.evidenceArt]) is never listed here.
  static const evidenceDocs = <String, EvidencePaper>{
    // London.
    'e04': EvidencePaper.map, // its swans are its words (the Royal Box's number)
    'ep02_e1': EvidencePaper.note,
    'ep02_e3': EvidencePaper.card,
    'ep03_e4': EvidencePaper.tag,
    'ep04_e2': EvidencePaper.card,
    'ep04_e4': EvidencePaper.letter,
    'ep05_e1': EvidencePaper.card,
    'ep05_e2': EvidencePaper.note,
    'ep06_e1': EvidencePaper.statement,
    'ep06_e2': EvidencePaper.card,
    'ep06_e3': EvidencePaper.ticket,
    'ep08_e1': EvidencePaper.tag,
    'ep08_e2': EvidencePaper.note,
    'ep09_e1': EvidencePaper.card,
    'ep09_e2': EvidencePaper.tag,
    'ep09_e3': EvidencePaper.log,
    'ep10_e2': EvidencePaper.note,
    'ep10_e4': EvidencePaper.note,
    'ep11_e1': EvidencePaper.note,
    'ep11_e4': EvidencePaper.card,
    'ep12_e2': EvidencePaper.notice, // the arrivals board's line
    'ep12_e3': EvidencePaper.note,
    // Paris (Cases 01–03; 04–12 are drawn by their cases).
    's2_ep01_e1': EvidencePaper.notice,
    's2_ep02_e2': EvidencePaper.note,
    's2_ep02_e4': EvidencePaper.note, // the canvas says it in French: its words in English
    's2_ep03_e1': EvidencePaper.notice,
    's2_ep03_e2': EvidencePaper.log, // the puzzle's ledger is blank paper
    // Rome.
    's3_ep02_e2': EvidencePaper.note,
    's3_ep03_e1': EvidencePaper.log,
    's3_ep03_e3': EvidencePaper.statement,
    's3_ep04_e2': EvidencePaper.note,
    's3_ep05_e3': EvidencePaper.note,
    's3_ep06_e1': EvidencePaper.statement,
    's3_ep06_e2': EvidencePaper.log,
    's3_ep06_e3': EvidencePaper.note, // the mirror word: words, never drawn
    's3_ep07_e2': EvidencePaper.notice, // the chalk code: words, never drawn
    's3_ep08_e2': EvidencePaper.statement,
    's3_ep08_e3': EvidencePaper.diary,
    's3_ep09_e1': EvidencePaper.card,
    's3_ep09_e2': EvidencePaper.map,
    's3_ep09_e3': EvidencePaper.note,
    's3_ep10_e1': EvidencePaper.notice,
    's3_ep10_e3': EvidencePaper.log,
    's3_ep10_e4': EvidencePaper.letter,
    's3_ep11_e2': EvidencePaper.statement,
    's3_ep11_e3': EvidencePaper.note,
    's3_ep11_e4': EvidencePaper.statement,
    's3_ep12_e1': EvidencePaper.card,
    's3_ep12_e2': EvidencePaper.card,
    // New York.
    's4_ep01_e1': EvidencePaper.log,
    's4_ep01_e4': EvidencePaper.diary, // the stub's zigzag is its words (Case 11 matches it)
    // The Star Print: the notebook's words, never the sole (Case 07 asks
    // which sole made it, its answer a picture of that sole).
    's4_ep02_e1': EvidencePaper.statement,
    's4_ep02_e3': EvidencePaper.note,
    's4_ep02_e4': EvidencePaper.note,
    's4_ep03_e2': EvidencePaper.note,
    's4_ep03_e3': EvidencePaper.diary,
    's4_ep03_e4': EvidencePaper.note,
    's4_ep04_e1': EvidencePaper.notice,
    's4_ep04_e3': EvidencePaper.note,
    's4_ep04_e4': EvidencePaper.note,
    's4_ep05_e1': EvidencePaper.letter,
    's4_ep05_e2': EvidencePaper.diary,
    's4_ep06_e1': EvidencePaper.ticket,
    's4_ep06_e3': EvidencePaper.note,
    's4_ep07_e2': EvidencePaper.statement,
    's4_ep07_e3': EvidencePaper.log,
    's4_ep07_e4': EvidencePaper.note,
    's4_ep08_e1': EvidencePaper.music, // blank staves: the tune is its words
    's4_ep08_e2': EvidencePaper.note,
    's4_ep08_e3': EvidencePaper.diary,
    's4_ep09_e1': EvidencePaper.card,
    's4_ep09_e3': EvidencePaper.letter,
    's4_ep09_e4': EvidencePaper.map,
    's4_ep10_e1': EvidencePaper.note,
    's4_ep10_e2': EvidencePaper.note,
    's4_ep10_e3': EvidencePaper.note,
    's4_ep10_e4': EvidencePaper.music,
    's4_ep11_e1': EvidencePaper.card,
    's4_ep12_e3': EvidencePaper.letter,
  };

  /// The detective's coin (wallet, tip shop, How to Play), full colour on
  /// transparency. Missing: the ink coin.
  static const coin = 'assets/shared/ui/coin.webp';

  /// The World Archive's wax seal, full colour. Missing: the ink seal.
  static const archiveSeal = 'assets/shared/ui/archive_seal.webp';

  /// Evidence pictures too wide for the round frame's close look: shown
  /// whole there, at their width / height.
  static const evidencePrints = <String, double>{
    // London's map, whole in the close look (its pieces are wide, joined tall).
    'ep05_e4': 768 / 512,
    'ep07_e1': 768 / 559,
    'ep07_e2': 768 / 600,
    'ep07_e3': 768 / 1115,
    'ep07_e4': 768 / 1091,
    's2_ep01_e2': 1774 / 887,
    's2_ep01_e4': 1774 / 887,
    's2_ep02_e1': 1536 / 1024,
    // The Hidden Sketch on its easel (drawn: `season2Case02EvidenceArt`).
    's2_ep02_e3': 640 / 690,
    's2_ep03_e3': 1536 / 1024,
    's2_ep03_e4': 1536 / 1024,
    // Case 04: the mark up close, the ledger's page, the label whole, and
    // the label's lower part with its last piece.
    's2_ep04_e1': 1.0,
    's2_ep04_e2': 620 / 755,
    's2_ep04_e3': 1377 / 1142,
    's2_ep04_e4': 1377 / 514,
  };

  /// What a case's Case Closed file shows under its title in place of the
  /// small tilted case photo, by case id: the thing the case was about,
  /// alone on the file's paper. Case 01: the Missing Crown, cut out of
  /// `objects/crown.webp` (kept, on its parchment) by
  /// `tool/crown_cutout/cutout_test.dart`. Other cases keep their photo.
  static const caseClosedEmblems = <String, String>{
    'ep01': 'assets/seasons/season_01_london/objects/crown_cutout.webp',
    // Paris Case 01: the painting found in the brass box.
    's2_ep01': '$_paris01/montmartre_painting.webp',
  };

  /// Width / height of a [caseClosedEmblems] picture that is not square.
  static const caseClosedEmblemAspects = <String, double>{'s2_ep01': 1774 / 887};

  /// How much closer an [evidencePictures] picture is shown in its round
  /// frame, where its object sits small in a wide parchment margin: only
  /// the margin goes, never the object. The crown (crown.webp) fills about
  /// the middle half of its square; at 1.5× its cross, jewels and band
  /// still lie inside the circle.
  /// Below 1, farther: the Pocket Watch's bow and open lid reach just past
  /// its square's inscribed circle, so it is shown a little smaller, whole.
  static const evidencePictureZoom = <String, double>{'e05': 1.5, 'e03': 0.95};

  static const _london = 'assets/seasons/season_01_london/';
  static const _case01 = 'assets/images/case01';
  static const _case01PocketWatch = '$_case01/symbols/symbol_pocket_watch.webp';

  /// The nine London landmarks.
  static const landmarkScenes = <Artwork, String>{
    Artwork.kingsCross: '$_scenes/landmarks/kings_cross.webp',
    Artwork.britishMuseum: '$_scenes/landmarks/british_museum.webp',
    Artwork.coventGarden: '$_scenes/landmarks/covent_garden.webp',
    Artwork.bigBen: '$_scenes/landmarks/big_ben.webp',
    Artwork.hydePark: '$_scenes/landmarks/hyde_park.webp',
    Artwork.buckinghamPalace: '$_scenes/landmarks/buckingham_palace.webp',
    Artwork.towerBridge: '$_scenes/landmarks/tower_bridge.webp',
    Artwork.towerOfLondon: '$_scenes/landmarks/tower_of_london.webp',
    Artwork.londonEye: '$_scenes/landmarks/london_eye.webp',
  };

  /// Places inside a landmark, each in its landmark's folder.
  static const insideScenes = <Artwork, String>{
    Artwork.greatCourt: '$_scenes/british_museum/british_museum_great_court.webp',
    Artwork.egyptRoom: '$_scenes/british_museum/british_museum_egypt_room.webp',
    Artwork.boathouse: '$_scenes/hyde_park/hyde_park_boathouse.webp',
    Artwork.roseGarden: '$_scenes/hyde_park/hyde_park_rose_garden.webp',
    Artwork.staffRoom: '$_scenes/buckingham_palace/buckingham_palace_palace_staff_room.webp',
    Artwork.courtyard: '$_scenes/buckingham_palace/buckingham_palace_palace_courtyard.webp',
    Artwork.dressingRoom: '$_scenes/covent_garden/covent_garden_dressing_room.webp',
    Artwork.waitingRoom: '$_scenes/kings_cross/kings_cross_waiting_hall.webp',
    // Gallery 8 (Case 03): the room as the theft left it — the empty gold
    // frame, the bench, the door (its M1 is searched in this picture: see
    // `season1_investigations.dart`). And the theatre's auditorium (Case 11).
    Artwork.gallery: '$_scenes/british_museum/british_museum_gallery_8.webp',
    Artwork.auditorium: '$_scenes/covent_garden/covent_garden_theatre.webp',
    // The theatre's door at night (Case 06; the file keeps its delivered name).
    Artwork.theatreDoor: '$_scenes/covent_garden/theatre_door_dark.webp',
    // The Royal Archive, down the secret stairs of Buckingham Palace (its own
    // folder: it is no landmark of the map).
    Artwork.royalArchive: '$_scenes/royal_archive/royal_archive.webp',
  };

  static const _scenes = 'assets/seasons/season_01_london/locations';

  /// How the scene pictures are printed (about 400×256, a thin paper frame;
  /// the landmark set also has the place's name plate along the bottom).
  /// They show whole, in frames of this ratio. Only where a name must not
  /// show (an image-choice answer, always a landmark) is the part above
  /// [nameTop] shown, inside the [frame].
  /// Fractions of the picture's width / height.
  static const scenePrint = (size: Size(400, 256), frame: 0.045, nameTop: 0.68);

  /// A scene after its case is solved, when it is another picture of the
  /// same view (Case 02's clock keeps its face and turns its drawn hands):
  /// Case 05's iron chest open, the map fragment inside; Case 10's raven
  /// cawing once, the warning delivered; Case 11's stranger, his white mask
  /// off and in his hand, his face still hidden in his hood (never shown);
  /// Case 12's small iron door standing open on the Clockmaker's empty room.
  static const Map<Artwork, String> solvedScenes = {
    Artwork.ironChest: 'assets/seasons/season_01_london/objects/iron_chest_open.webp',
    Artwork.raven: '${_london}characters/raven_master_caw.webp',
    Artwork.maskedStranger: '${_london}characters/stranger_unmasked.webp',
    Artwork.ironDoor: 'assets/seasons/season_01_london/objects/small_iron_door_open.webp',
  };

  /// Clock faces whose hands are drawn over the picture. Case 02: Big Ben
  /// stopped at 8:17, set to 9:17 when the case is solved. The pivot and the
  /// hands are measured on `big_ben/clock_face.webp` (1254 × 1254: the pivot
  /// at 627, 548; the numerals' ring about 337 px out).
  static const Map<Artwork, ClockHandsArt> clockHands = {
    Artwork.clockFace: (
      pivot: Offset(0.5, 0.437),
      hourLength: 0.185,
      minuteLength: 0.30,
      before: (hour: 8, minute: 17),
      after: (hour: 9, minute: 17),
    ),
    // Gare du Nord's old clock (Paris Case 01 M3): the pivot is the brass
    // ring in the middle of its face; the minute hand reaches the minute
    // track, the hour hand the inner circle under the numerals.
    Artwork.oldClockFace: (
      pivot: Offset(0.498, 0.492),
      hourLength: 0.18,
      minuteLength: 0.30,
      before: (hour: 9, minute: 0),
      after: (hour: 10, minute: 0),
    ),
  };

  /// Symbol pictures (clue stamps, evidence, lock dials), keyed like
  /// `GameSymbol`, e.g. `'park': 'assets/shared/symbols/symbol_park.webp'`.
  /// One-colour artwork on transparency: the game tints it with the symbol's
  /// colour, as it does the ink glyphs.
  ///
  /// Every key of `GameSymbol` has its stamp (the icon upgrade): clue cards,
  /// lock dials and a fallen-back evidence mark, in all four seasons. The
  /// Royal Box's four locks keep their own full-colour pictures
  /// ([royalBoxLocks]); a missing stamp falls back to its ink glyph.
  static const Map<String, String> symbols = {
    'train': '$_symbols/symbol_train.webp',
    'museum': '$_symbols/symbol_museum.webp',
    'clock': '$_symbols/symbol_clock.webp',
    'watch': '$_symbols/symbol_watch.webp',
    'park': '$_symbols/symbol_park.webp',
    'palace': '$_symbols/symbol_palace.webp',
    'crown': '$_symbols/symbol_crown.webp',
    'raven': '$_symbols/symbol_raven.webp',
    'gear': '$_symbols/symbol_gear.webp',
    'letter': '$_symbols/symbol_letter.webp',
    'key': '$_symbols/symbol_key.webp',
    'map': '$_symbols/symbol_map.webp',
    'ticket': '$_symbols/symbol_ticket.webp',
    'feather': '$_symbols/symbol_feather.webp',
    'footprint': '$_symbols/symbol_footprint.webp',
    'button': '$_symbols/symbol_button.webp',
    'cloth': '$_symbols/symbol_cloth.webp',
    'seal': '$_symbols/symbol_seal.webp',
    'frame': '$_symbols/symbol_frame.webp',
    'mask': '$_symbols/symbol_mask.webp',
    'gem': '$_symbols/symbol_gem.webp',
    'bag': '$_symbols/symbol_bag.webp',
    'umbrella': '$_symbols/symbol_umbrella.webp',
    'whistle': '$_symbols/symbol_whistle.webp',
  };

  static const _symbols = 'assets/shared/symbols';

  /// Case 01's Royal Box: the four pictures of its locks, in full colour on
  /// transparency (cut out of the delivered files kept in
  /// `assets/images/case01/symbols/original/`, by
  /// `tool/symbol_cutout/cutout_test.dart`), keyed like the locks'
  /// `dialSymbols`. Shown where the lock order is read — the crown card's
  /// hidden message, the Crown Symbol evidence and the locks themselves —
  /// never tinted. Other cases keep their [symbols] glyphs.
  static const royalBoxLocks = <String, String>{
    'clock': _case01PocketWatch,
    'train': '$_case01/symbols/symbol_steam_train.webp',
    'park': '$_case01/symbols/symbol_swan.webp',
    'museum': '$_case01/symbols/symbol_rosetta_stone.webp',
  };

  /// The Royal Box lock pictures are square (512 × 512), each drawing
  /// centred with the same margin, so they look the same size side by side.
  static const royalBoxLockPixels = Size(512, 512);

  static const _badges = 'assets/shared/badges';

  /// Badge medals, one per [GameBadge] (retired ones too: old saves still
  /// show them). Each is a finished medal — the gold rosette, its enamel
  /// face and the badge's own emblem — in full colour on transparency,
  /// shown by `BadgeMedal` as it is: never tinted, never framed again.
  static const Map<GameBadge, String> badges = {
    GameBadge.firstClue: '$_badges/badge_first_clue.webp',
    GameBadge.sharpEyes: '$_badges/badge_sharp_eyes.webp',
    GameBadge.quickThinker: '$_badges/badge_quick_thinker.webp',
    GameBadge.puzzleSolver: '$_badges/badge_puzzle_solver.webp',
    GameBadge.londonExplorer: '$_badges/badge_london_explorer.webp',
    GameBadge.masterDetective: '$_badges/badge_master_detective.webp',
    GameBadge.clockWatcher: '$_badges/badge_clock_watcher.webp',
    GameBadge.evidenceHunter: '$_badges/badge_evidence_hunter.webp',
    GameBadge.letterReader: '$_badges/badge_letter_reader.webp',
    GameBadge.codeBreaker: '$_badges/badge_code_breaker.webp',
    GameBadge.mapMaster: '$_badges/badge_map_master.webp',
    GameBadge.londonLegend: '$_badges/badge_london_legend.webp',
    GameBadge.secondLook: '$_badges/badge_second_look.webp',
    GameBadge.notebookExplorer: '$_badges/badge_notebook_explorer.webp',
    GameBadge.wordCollector: '$_badges/badge_word_collector.webp',
  };

  /// The same rosette with an empty face: a badge still to win. Every locked
  /// badge shows it (greyed, with a lock), so its emblem stays a surprise.
  static const badgeFrame = '$_badges/badge_frame.webp';

  /// The badge pictures and [badgeFrame] are square, all the same size, so
  /// medals line up whatever their emblem.
  static const badgePixels = Size(1254, 1254);

  /// The file for [artwork], or null to keep the drawing. Once a scene that
  /// changes when solved is being solved (or after), its solved picture if
  /// it has one, else its own picture (its change is drawn over it).
  static String? scene(Artwork artwork, {double solved = 0}) =>
      solved > 0 && changesWhenSolved.contains(artwork) ? solvedScenes[artwork] ?? scenes[artwork] : scenes[artwork];

  /// Choice pictures drawn on transparency (Case 09's keys, Case 10's
  /// ravens): shown on parchment, as drawn, not in the dark mount of a
  /// photograph (a dark iron key on it was hard to see).
  static bool onParchment(String file) =>
      file.startsWith('${_london}cases/case_09/key_') || file.startsWith('${_london}cases/case_10/raven_');

  /// Final scenes printed with their own aged-paper border: laid on the desk
  /// as they are, never inside the light paper sheet (a second, white frame
  /// round the dark chest read as a white background on the device). Only
  /// Case 05's chest so far.
  static const ownPaperEdge = {Artwork.ironChest};

  /// What a scene that changes with its solve shows, read out before and
  /// after (the picture itself is decoration): null for any other scene.
  static String? sceneLabel(Artwork artwork, {double solved = 0}) => switch (artwork) {
        Artwork.ironChest => solved > 0
            ? 'The iron chest is open. An old map fragment lies inside.'
            : 'The heavy iron chest, shut with three number locks.',
        Artwork.raven => solved > 0 ? 'Poppy the raven caws loudly, her beak wide open.' : 'A black raven, standing quietly.',
        Artwork.maskedStranger => solved > 0
            ? 'The stranger holds his white mask in his hand. His face is hidden in his hood.'
            : 'A stranger in a white mask and a long black cloak, the hood up.',
        Artwork.ironDoor => solved > 0
            ? "The small iron door stands open. Inside, lamplight falls on an empty desk."
            : 'A small iron door under the tower, shut tight.',
        _ => null,
      };

  /// Scenes that show differently once their case is solved (the clock's
  /// drawn hands, drawn in code, its hands turn too; the [solvedScenes]).
  static const changesWhenSolved = {
    Artwork.clockFace,
    Artwork.ironChest,
    Artwork.raven,
    Artwork.maskedStranger,
    Artwork.ironDoor,
  };
}

/// A season's cover painting (portrait, no text) and how it is framed.
class SeasonCover {
  const SeasonCover({
    required this.file,
    required this.pixels,
    this.archiveLook = Alignment.center,
    this.crop = Alignment.center,
    this.push = Alignment.center,
  });

  /// The picture's asset.
  final String file;

  /// Its pixel size (never decoded larger).
  final Size pixels;

  /// Where the season's file strip in the Detective Archives looks.
  final Alignment archiveLook;

  /// The season board's crop when the phone is narrower than the painting
  /// (9:16).
  final Alignment crop;

  /// Where the season board's camera pushes in.
  final Alignment push;
}
