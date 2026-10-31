// The icon upgrade's pictures (docs/WORLD_MYSTERY_ICON_UPGRADE_PROGRESS.md):
// what each one shows, where it goes in the game and which evidence, symbol
// or screen uses it. Plain Dart; nothing here is imported by the game.

/// What a picture is, which decides its prompt's style and its last steps.
enum IconArtKind {
  /// One evidence object, full colour on transparency (512 × 512).
  object,

  /// A blank paper for documents: the app writes the evidence's words on it.
  doc,

  /// A one-colour stamp for clue and lock symbols, tinted by the app (256 × 256).
  symbol,

  /// A game-world UI picture, full colour on transparency (256 × 256).
  ui,
}

class IconArt {
  const IconArt(this.id, this.kind, this.asset, this.subject, {this.usedBy = const [], this.qa, this.model, this.style});

  /// Another GPT image model for a picture the first one kept getting wrong
  /// (null: the run's model). gpt-image-2 is asked on white (opaque), the
  /// white cleared after.
  final String? model;

  /// Its own style line instead of its kind's.
  final String? style;

  /// Its name in the manifest (`ev.raven_feather`, `doc.note`, `sym.key`, `ui.coin`).
  final String id;
  final IconArtKind kind;

  /// The file the game loads.
  final String asset;

  /// What to draw (the style is added by the kind).
  final String subject;

  /// Evidence ids, symbol keys or screens that show it.
  final List<String> usedBy;

  /// The visual check once it is made (null: not checked yet).
  final String? qa;

  /// The API's picture, before its last steps (gitignored).
  String get raw => 'qa/icon_upgrade/raw/$id.png';
}

const _common = "Storybook illustration for a children's detective mystery game (ages 8-12): warm, inviting and gently "
    'mysterious, never scary. No text, letters, numbers, signatures, watermarks or logos anywhere in the image.';

const styles = <IconArtKind, String>{
  IconArtKind.object: '$_common Style: one single object, hand-inked linework with soft watercolour washes and gentle shading, '
      "like a vintage detective storybook; warm palette of parchment, brass, polished wood, leather and ink, the object's own "
      'colours kept clear; a bold, simple silhouette that is easy to recognise even when shown very small; the object centred '
      'and filling about three quarters of the square, seen from a slightly raised three-quarter view; isolated on a fully '
      'transparent background with no ground shadow, no table, no frame and no other objects.',
  IconArtKind.doc: '$_common Style: hand-inked linework with soft watercolour washes, like a vintage detective storybook; warm '
      'aged paper colours; the paper seen straight on from directly above, lying flat and square to the frame, filling about '
      '85 percent of the image; its writing area completely blank and empty (no handwriting, no scribbles, no printed words, '
      'no numbers), because the game writes on it later; isolated on a fully transparent background, no table, no other objects.',
  IconArtKind.symbol: 'A bold vintage rubber-stamp or woodcut emblem: solid black ink shapes with a few clean white cut-out '
      'details, thick simple forms that stay readable at 20 pixels, no thin lines, no shading, no grey tones; centred, filling '
      'about 80 percent of the square; on a plain pure white background; no circle or border around it. No text, letters, '
      'numbers or logos.',
  IconArtKind.ui: '$_common Style: one single object, hand-inked linework with soft watercolour washes and gentle shading, like '
      'a vintage detective storybook; warm brass, gold, wax and leather colours; a bold, simple shape that reads clearly at '
      '20 pixels; seen face on, centred, filling about 85 percent of the square; isolated on a fully transparent background '
      'with no shadow and no other objects.',
};

/// Added to a subject made again after its first picture showed something else.
const _only = ' — only this one thing, nothing else at all: no other objects, no people beyond the ones named, no animals beyond the ones named, no skulls, no weapons, no tools, no landscapes, no badges';

/// The third (last) try of a picture gpt-image-1.5 drew as something else twice.
const _retryModel = 'gpt-image-2';

/// The object style on plain white (gpt-image-2 is asked opaque; the white is cleared).
const _objectOnWhite = '$_common Style: hand-inked linework with soft watercolour washes and gentle shading, like a vintage '
    'detective storybook; warm sepia and parchment colours; centred, filling about three quarters of the square; on a plain '
    'pure white background with no shadow and nothing else.';

/// The stamp style said plainly (no list of what not to draw: it drew those).
const _pictogram = 'Style: a flat, bold black silhouette pictogram, like a simple museum sign symbol: solid black shapes '
    'with a few thin white inner lines, centred, filling about 80 percent of the square, on a plain pure white background. '
    'No text, letters or numbers.';

const _l = 'assets/seasons/season_01_london/objects';
const _r = 'assets/seasons/season_03_rome/objects';
const _n = 'assets/seasons/season_04_newyork/objects';
const _docs = 'assets/shared/evidence_docs';
const _sym = 'assets/shared/symbols';

const plan = <IconArt>[
  // ── Evidence objects (one each; never their words or the answer) ──────
  IconArt('ev.raven_feather', IconArtKind.object, '$_l/raven_feather.png',
      'a single glossy black raven feather, gently curved, with a blue-black sheen', usedBy: ['ep02_e4']),
  IconArt('ev.silver_whistle', IconArtKind.object, '$_l/silver_whistle.png',
      'a small polished silver police whistle on a short silver chain, old-fashioned British design', usedBy: ['ep06_e4']),
  IconArt('ev.raven_tower_painting', IconArtKind.object, '$_l/raven_tower_painting.png',
      'a small oil painting in an ornate gilded frame, showing a dark stone tower at dusk with a few black ravens flying around it',
      usedBy: ['ep08_e3']),
  IconArt('ev.empty_jewel_box', IconArtKind.object, '$_l/empty_jewel_box.png',
      'an open, empty jewellery box lined with red velvet, a small brass clasp, its velvet cushion empty', usedBy: ['ep08_e4']),
  IconArt('ev.blue_star_jewel', IconArtKind.object, '$_l/blue_star_jewel.png',
      'a large sparkling deep-blue royal gemstone cut in the shape of a star, in a simple gold setting', usedBy: ['ep09_e4']),
  IconArt('ev.poppys_ring', IconArtKind.object, '$_l/poppys_ring.png',
      'a tiny plain gold leg ring of the kind a bird keeper puts on a bird, shown large and close up, smooth with no engraving',
      usedBy: ['ep10_e1']),
  IconArt('ev.white_mask', IconArtKind.object, '$_l/white_mask.png',
      'a plain white theatre half-mask with two eye holes and a thin black ribbon tie, nothing written on it', usedBy: ['ep11_e2']),
  IconArt('ev.toy_train_whistle', IconArtKind.object, '$_l/toy_train_whistle.png',
      "a small wooden child's toy train whistle, painted red and green, shaped like a little steam locomotive's chimney",
      usedBy: ['ep11_e3']),
  IconArt('ev.clockmaker_mark', IconArtKind.object, 'assets/seasons/season_02_paris/cases/case_01/clockmaker_mark.png',
      'a small round piece of old dark polished wood from a clock case with one tiny gear carved into it, seen close up',
      usedBy: ['s2_ep01_e3']),
  IconArt('ev.white_dust', IconArtKind.object, '$_r/white_dust.png',
      'a small soft heap of fine white chalk-like dust on a square piece of dark grey stone floor tile', usedBy: ['s3_ep01_e2']),
  IconArt('ev.light_box', IconArtKind.object, '$_r/light_box.png',
      'an old metal electric switch box on a small wooden board, with one big black lever switch', usedBy: ['s3_ep01_e4']),
  IconArt('ev.bag_of_white_dust', IconArtKind.object, '$_r/bag_of_white_dust.png',
      'a small tied cloth drawstring bag, a little fine white dust on it', usedBy: ['s3_ep03_e2']),
  IconArt('ev.orange_cat_hair', IconArtKind.object, '$_r/orange_cat_hair.png',
      'a small clear glass evidence slide with one short, thin, wavy orange cat hair lying on it, the hair shown large$_only', usedBy: ['s3_ep05_e1']),
  IconArt('ev.cat_collar_tag', IconArtKind.object, '$_r/cat_collar_tag.png',
      "a small round brass pet tag hanging from a thin red leather cat collar, the tag's face smooth and blank",
      usedBy: ['s3_ep05_e2']),
  IconArt('ev.tiny_screws', IconArtKind.object, '$_n/tiny_screws.png',
      'a little heap of tiny brass clock screws, each as small as a grain of rice, on a folded square of white paper',
      usedBy: ['s4_ep05_e3']),
  IconArt('ev.karl_old_photo', IconArtKind.object, '$_n/karl_old_photo.png',
      'a small old sepia photograph print with a white scalloped border, lying flat, seen straight on from above; the photograph '
          'shows a young mother holding her baby, with a violin on the table beside them',
      usedBy: ['s4_ep05_e4'], model: _retryModel, style: _objectOnWhite),
  IconArt('ev.seagull_photo', IconArtKind.object, '$_n/seagull_photo.png',
      'an old faded photograph print with a wide white border, lying flat and seen straight on; in the photo a smiling man in a flat cap has a seagull standing on his hat$_only',
      usedBy: ['s4_ep06_e2']),
  IconArt('ev.karl_pocket_book', IconArtKind.object, '$_n/karl_pocket_book.png',
      'a small closed brown leather pocket notebook held shut with an elastic band, a pencil tucked beside it', usedBy: ['s4_ep06_e4']),
  IconArt('ev.wheel_box', IconArtKind.object, '$_n/wheel_box.png',
      'a small old iron box locked by four brass rotating rings set side by side on its front, the rings plain and smooth',
      usedBy: ['s4_ep09_e2']),
  IconArt('ev.dexter_safe', IconArtKind.object, '$_n/dexter_safe.png',
      'a small shiny theatre prop safe painted green with gold trim and a round dial, its door a little open, empty inside',
      usedBy: ['s4_ep11_e4']),
  IconArt('ev.stone_nest', IconArtKind.object, '$_n/stone_nest.png',
      "a small bird's nest of woven twigs, but carved entirely out of grey stone, sitting on a stone ledge, empty, clearly shaped like a bird's nest$_only", usedBy: ['s4_ep12_e1']),
  IconArt('ev.open_stone', IconArtKind.object, '$_n/open_stone.png',
      'a square grey stone block pulled half out of an old castle wall, a small dark empty hollow behind it', usedBy: ['s4_ep12_e2']),

  // ── Document papers (blank: the evidence's own words are set on them) ──
  IconArt('doc.note', IconArtKind.doc, '$_docs/doc_note.png',
      'a single small sheet of torn notebook paper, slightly crumpled, with a torn top edge'),
  IconArt('doc.card', IconArtKind.doc, '$_docs/doc_card.png',
      'a plain cream index card in landscape orientation with rounded corners and a thin printed border line'),
  IconArt('doc.letter', IconArtKind.doc, '$_docs/doc_letter.png',
      'a single unfolded letter sheet of cream writing paper in portrait orientation with soft fold creases'),
  IconArt('doc.log', IconArtKind.doc, '$_docs/doc_log.png',
      'a single page from an old ledger log book in portrait orientation, faint ruled lines and a narrow left column'),
  IconArt('doc.diary', IconArtKind.doc, '$_docs/doc_diary.png',
      'a single page from a small diary in portrait orientation, faint ruled lines, a red ribbon bookmark across its top corner'),
  IconArt('doc.ticket', IconArtKind.doc, '$_docs/doc_ticket.png',
      'an old paper admission ticket, a wide rectangle with a perforated tear-off stub at its right end'),
  IconArt('doc.tag', IconArtKind.doc, '$_docs/doc_tag.png',
      'a brown manila luggage tag in landscape orientation with a metal eyelet at its left end and a short piece of string tied through it'),
  IconArt('doc.notice', IconArtKind.doc, '$_docs/doc_notice.png',
      'a printed notice sheet in portrait orientation held by four brass pins at its corners, a thin decorative border line'),
  IconArt('doc.map', IconArtKind.doc, '$_docs/doc_map.png',
      'an old torn piece of map paper in landscape orientation, the map very faint and simple (a few pale streets, a river and '
          'park shapes in soft colour) leaving a large clear space in the middle'),
  IconArt('doc.music', IconArtKind.doc, '$_docs/doc_music.png',
      'a single sheet of old music paper in landscape orientation with empty five-line staves and no musical notes at all'),
  IconArt('doc.statement', IconArtKind.doc, '$_docs/doc_statement.png',
      "a single open page of a detective's notebook in portrait orientation, lined paper with a red margin line and a small leather corner"),

  // ── Clue and lock stamps (one per GameSymbol key) ─────────────────────
  IconArt('sym.train', IconArtKind.symbol, '$_sym/symbol_train.png', 'a steam locomotive seen from the side', usedBy: ['train']),
  IconArt('sym.museum', IconArtKind.symbol, '$_sym/symbol_museum.png',
      'a classical museum front with columns and a triangular roof', usedBy: ['museum']),
  IconArt('sym.clock', IconArtKind.symbol, '$_sym/symbol_clock.png', 'a round wall clock face with two hands', usedBy: ['clock']),
  IconArt('sym.watch', IconArtKind.symbol, '$_sym/symbol_watch.png', 'a pocket watch with its ring and a short chain', usedBy: ['watch']),
  IconArt('sym.park', IconArtKind.symbol, '$_sym/symbol_park.png', 'a leafy round park tree', usedBy: ['park']),
  IconArt('sym.palace', IconArtKind.symbol, '$_sym/symbol_palace.png',
      'a palace front with a central dome and a flag on top', usedBy: ['palace']),
  IconArt('sym.crown', IconArtKind.symbol, '$_sym/symbol_crown.png', 'a royal crown', usedBy: ['crown']),
  IconArt('sym.raven', IconArtKind.symbol, '$_sym/symbol_raven.png', 'a raven standing in profile', usedBy: ['raven']),
  IconArt('sym.gear', IconArtKind.symbol, '$_sym/symbol_gear.png', 'a cog gear with a round hole in the middle', usedBy: ['gear']),
  IconArt('sym.letter', IconArtKind.symbol, '$_sym/symbol_letter.png', 'a simple pictogram of a closed paper envelope, seen flat from the front, with its V-shaped flap',
      usedBy: ['letter'], model: _retryModel, style: _pictogram),
  IconArt('sym.key', IconArtKind.symbol, '$_sym/symbol_key.png', 'an old-fashioned key', usedBy: ['key']),
  IconArt('sym.map', IconArtKind.symbol, '$_sym/symbol_map.png', 'a folded paper map', usedBy: ['map']),
  IconArt('sym.ticket', IconArtKind.symbol, '$_sym/symbol_ticket.png', 'a simple pictogram of one paper ticket: a plain rectangle with a dotted tear line near its right end',
      usedBy: ['ticket'], model: _retryModel, style: _pictogram),
  IconArt('sym.feather', IconArtKind.symbol, '$_sym/symbol_feather.png', 'a feather', usedBy: ['feather']),
  IconArt('sym.footprint', IconArtKind.symbol, '$_sym/symbol_footprint.png',
      'one boot print: the sole and the separate heel', usedBy: ['footprint']),
  IconArt('sym.button', IconArtKind.symbol, '$_sym/symbol_button.png', 'a round coat button with four holes', usedBy: ['button']),
  IconArt('sym.cloth', IconArtKind.symbol, '$_sym/symbol_cloth.png', 'a simple pictogram of one torn piece of cloth: a plain rectangle of fabric with ragged, frayed edges',
      usedBy: ['cloth'], model: _retryModel, style: _pictogram),
  IconArt('sym.seal', IconArtKind.symbol, '$_sym/symbol_seal.png', 'a single round wax seal blob with wavy melted edges and a plain smooth centre$_only', usedBy: ['seal']),
  IconArt('sym.frame', IconArtKind.symbol, '$_sym/symbol_frame.png', 'a single ornate empty rectangular picture frame with decorative corners$_only', usedBy: ['frame']),
  IconArt('sym.mask', IconArtKind.symbol, '$_sym/symbol_mask.png', 'a theatre half-mask with two eye holes', usedBy: ['mask']),
  IconArt('sym.gem', IconArtKind.symbol, '$_sym/symbol_gem.png', 'a cut gemstone', usedBy: ['gem']),
  IconArt('sym.bag', IconArtKind.symbol, '$_sym/symbol_bag.png', 'a small handbag with a clasp and a handle', usedBy: ['bag']),
  IconArt('sym.umbrella', IconArtKind.symbol, '$_sym/symbol_umbrella.png', 'an open umbrella', usedBy: ['umbrella']),
  IconArt('sym.whistle', IconArtKind.symbol, '$_sym/symbol_whistle.png', 'a police whistle', usedBy: ['whistle']),

  // ── Game-world UI (only where a picture is better than the ink line) ──
  IconArt('ui.coin', IconArtKind.ui, 'assets/shared/ui/coin.png',
      "a thick gold detective's coin seen face on, a raised rim and a raised five-pointed star in its middle",
      usedBy: ['CoinBalance', 'tip shop', 'How to Play']),
  IconArt('ui.archive_seal', IconArtKind.ui, 'assets/shared/ui/archive_seal.png',
      'a round deep-red wax seal with irregular edges, a simple magnifying glass pressed into its middle',
      usedBy: ['World Archive']),
];
