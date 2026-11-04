import 'puzzle_rules.dart';

/// One card of a timeline: a thing that happened. An [anchor] (its time,
/// written on it: "1441") is fixed in its place from the start; a [discard]
/// card is not part of what happened and goes on the NOT PART OF IT pile.
class TimelineCard {
  const TimelineCard({required this.id, required this.title, required this.text, this.anchor, this.discard = false, this.evidence});

  final String id;
  final String title;
  final String text;
  final String? anchor;
  final bool discard;

  /// The evidence of the notebook the card is (a plan's evidence id), if any.
  final String? evidence;
}

/// What the game's words say of two cards: [earlier] came before [later].
/// [line] is those words (read in the case), what a wrong place points back to.
class TimelineRelation {
  const TimelineRelation({required this.earlier, required this.later, required this.line});

  final String earlier;
  final String later;
  final String line;
}

/// A timeline to put back together (`timeline_board`): its cards, the order
/// they happened in ([order]: every card but the discards), and the words
/// that tell it ([relations]).
class TimelineSpec {
  const TimelineSpec({required this.cards, required this.order, this.relations = const []});

  final List<TimelineCard> cards;
  final List<String> order;
  final List<TimelineRelation> relations;

  TimelineCard? card(String id) => cards.where((c) => c.id == id).firstOrNull;

  /// The anchored cards, by the slot they are fixed in.
  Map<int, String> get anchors => {
    for (final (i, id) in order.indexed)
      if (card(id)?.anchor != null) i: id,
  };

  static const _keys = {'cards', 'order', 'relations'};
  static const _cardKeys = {'id', 'title', 'text', 'anchor', 'discard', 'evidence'};
  static const _relationKeys = {'earlier', 'later', 'line'};

  /// [json] read as a spec (a plan's `play.timeline` with its order), or the
  /// reasons it does not read.
  static (TimelineSpec?, List<SpecIssue>) parse(Object? json) {
    final out = <SpecIssue>[];
    if (json is! Map) return (null, [const SpecIssue('spec_invalid', r'$', 'not an object')]);
    void unknown(Map<dynamic, dynamic> m, Set<String> known, String at) {
      for (final k in m.keys) {
        if (!known.contains(k)) out.add(SpecIssue('field_unknown', '$at.$k', 'not a field of a timeline'));
      }
    }

    String? str(Map<dynamic, dynamic> m, String key, String at, {bool optional = false}) {
      final v = m[key];
      if (v == null && optional) return null;
      if (v is String) return v;
      out.add(SpecIssue('field_missing', '$at.$key', 'a string'));
      return null;
    }

    unknown(json, _keys, r'$');
    final cards = <TimelineCard>[];
    for (final (i, c) in (json['cards'] is List ? json['cards'] as List : const []).indexed) {
      final at = '\$.cards[$i]';
      if (c is! Map) {
        out.add(SpecIssue('spec_invalid', at, 'not an object'));
        continue;
      }
      unknown(c, _cardKeys, at);
      final discard = c['discard'] ?? false;
      if (discard is! bool) out.add(SpecIssue('spec_invalid', '$at.discard', 'true or false'));
      final (id, title, text) = (str(c, 'id', at), str(c, 'title', at), str(c, 'text', at));
      if (id == null || title == null || text == null) continue;
      cards.add(TimelineCard(
        id: id,
        title: title,
        text: text,
        anchor: str(c, 'anchor', at, optional: true),
        discard: discard == true,
        evidence: str(c, 'evidence', at, optional: true),
      ));
    }
    if (json['cards'] is! List) out.add(const SpecIssue('field_missing', r'$.cards', 'a list of cards'));
    final order = json['order'];
    if (order is! List || order.any((x) => x is! String)) out.add(const SpecIssue('field_missing', r'$.order', 'the card ids in the order they happened'));
    final relations = <TimelineRelation>[];
    for (final (i, r) in (json['relations'] is List ? json['relations'] as List : const []).indexed) {
      final at = '\$.relations[$i]';
      if (r is! Map) {
        out.add(SpecIssue('spec_invalid', at, 'not an object'));
        continue;
      }
      unknown(r, _relationKeys, at);
      final (a, b, line) = (str(r, 'earlier', at), str(r, 'later', at), str(r, 'line', at));
      if (a != null && b != null && line != null) relations.add(TimelineRelation(earlier: a, later: b, line: line));
    }
    if (out.isNotEmpty) return (null, out);
    return (TimelineSpec(cards: cards, order: [for (final x in order as List) x as String], relations: relations), const []);
  }
}

/// Where the cards are: each slot of the timeline (null: empty), and the
/// NOT PART OF IT pile. A card in neither is still on the table.
class TimelineState {
  const TimelineState(this.slots, this.discarded);

  final List<String?> slots;
  final Set<String> discarded;

  bool holds(String id) => slots.contains(id) || discarded.contains(id);

  @override
  bool operator ==(Object other) =>
      other is TimelineState && _same(slots, other.slots) && discarded.length == other.discarded.length && discarded.containsAll(other.discarded);

  @override
  int get hashCode => Object.hash(Object.hashAll(slots), Object.hashAllUnordered(discarded));

  static bool _same(List<String?> a, List<String?> b) => a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
}

/// What the detective does with a card.
sealed class TimelineAction {
  const TimelineAction();
}

/// [card] into [slot] (0 first). The card in it goes where [card] was (a
/// swap), or back on the table.
class PlaceCard extends TimelineAction {
  const PlaceCard(this.card, this.slot);

  final String card;
  final int slot;
}

/// [card] onto the NOT PART OF IT pile.
class DiscardCard extends TimelineAction {
  const DiscardCard(this.card);

  final String card;
}

/// [card] back on the table.
class ReturnCard extends TimelineAction {
  const ReturnCard(this.card);

  final String card;
}

/// Every card back on the table but the anchors.
class ClearTimeline extends TimelineAction {
  const ClearTimeline();
}

/// The first card out of place, and the words that put it right.
class TimelineProblem {
  const TimelineProblem(this.slot, this.card, this.line);

  final int slot;

  /// The card there (null: the slot is empty).
  final String? card;

  /// A line of the case about that card (null: none).
  final String? line;
}

/// The rules of `timeline_board` (PART 3A: the rules only; its page comes in 3B).
class TimelineRules extends PuzzleRules<TimelineSpec, TimelineState, TimelineAction> {
  const TimelineRules();

  @override
  String get kind => 'timeline';

  @override
  int get stateVersion => 1;

  @override
  List<SpecIssue> validate(TimelineSpec spec) {
    final out = <SpecIssue>[...PuzzleSpecCheck.ids(elementIds(spec))];
    final kept = [for (final c in spec.cards) if (!c.discard) c.id];
    if (kept.length < 3) out.add(SpecIssue('timeline_too_short', r'$.cards', '${kept.length} card(s) to put in order: three at least'));
    if (spec.order.length != kept.length || !spec.order.toSet().containsAll(kept) || spec.order.toSet().length != spec.order.length) {
      out.add(SpecIssue('timeline_order_mismatch', r'$.order', '${spec.order.join(',')}: every card but the discards, each once (${kept.join(',')})'));
      return out;
    }
    for (final (i, c) in spec.cards.indexed) {
      if (c.discard && c.anchor != null) out.add(SpecIssue('timeline_anchor_discard', '\$.cards[$i].anchor', '${c.id} is not part of it: it has no place to be fixed in'));
      if (c.anchor != null && c.anchor!.trim().isEmpty) out.add(SpecIssue('field_missing', '\$.cards[$i].anchor', 'an anchor is the time written on the card'));
    }
    if (spec.anchors.length == kept.length) out.add(const SpecIssue('timeline_nothing_to_do', r'$.cards', 'every card is fixed: nothing is left to place'));

    // Anchors with numbers (years, hours) run forward.
    final numbered = [for (final MapEntry(key: i, value: id) in spec.anchors.entries) if (int.tryParse(spec.card(id)!.anchor!.trim()) case final n?) (i, id, n)];
    for (var k = 1; k < numbered.length; k++) {
      if (numbered[k].$3 < numbered[k - 1].$3) {
        out.add(SpecIssue('timeline_anchor_order', r'$.order', '${numbered[k].$2} (${numbered[k].$3}) comes after ${numbered[k - 1].$2} (${numbered[k - 1].$3})'));
      }
    }

    final at = {for (final (i, id) in spec.order.indexed) id: i};
    for (final (i, r) in spec.relations.indexed) {
      final p = '\$.relations[$i]';
      if (r.line.trim().isEmpty) out.add(SpecIssue('field_missing', '$p.line', 'the words that tell it'));
      if (!at.containsKey(r.earlier) || !at.containsKey(r.later)) {
        out.add(SpecIssue('timeline_relation_unknown', p, '${r.earlier} → ${r.later}: both are cards of the timeline (no discard)'));
      } else if (r.earlier == r.later || at[r.earlier]! > at[r.later]!) {
        out.add(SpecIssue('timeline_relation_contradicts', p, '${r.earlier} before ${r.later}, but the order says otherwise'));
      }
    }
    if (out.isEmpty) {
      final why = _ambiguity(spec);
      if (why != null) out.add(SpecIssue('timeline_ambiguous', r'$.relations', why));
    }
    return out;
  }

  /// Why the cards' words and anchors leave more than one order (null: they
  /// leave exactly [TimelineSpec.order]). Played as the page plays it: the
  /// anchors fixed in their slots, the rest placed slot by slot from what
  /// the relations allow.
  String? _ambiguity(TimelineSpec spec) {
    final anchors = spec.anchors;
    final anchored = anchors.values.toSet();
    final edges = <String, Set<String>>{for (final id in spec.order) id: {}};
    for (final r in spec.relations) {
      edges[r.earlier]!.add(r.later);
    }
    // Numbered anchors are in their time's order; each anchor before the cards a relation puts after it.
    final numbered = [for (final id in anchors.values) if (int.tryParse(spec.card(id)!.anchor!.trim()) != null) id];
    for (var k = 1; k < numbered.length; k++) {
      edges[numbered[k - 1]]!.add(numbered[k]);
    }
    final into = {for (final id in spec.order) id: 0};
    for (final next in edges.values) {
      for (final id in next) {
        into[id] = into[id]! + 1;
      }
    }
    final placed = <String>{};
    for (var slot = 0; slot < spec.order.length; slot++) {
      final ready = [for (final id in spec.order) if (!placed.contains(id) && into[id] == 0) id];
      final String next;
      if (anchors[slot] case final a?) {
        if (!ready.contains(a)) return 'slot ${slot + 1} is fixed to $a, but the words put ${ready.join(' or ')} before it';
        next = a;
      } else {
        final free = [for (final id in ready) if (!anchored.contains(id)) id];
        if (free.length != 1) {
          return free.isEmpty
              ? 'nothing the words allow fits slot ${slot + 1}'
              : 'slot ${slot + 1} could hold ${free.join(' or ')}: no words of the case tell them apart';
        }
        next = free.single;
      }
      placed.add(next);
      for (final id in edges[next]!) {
        into[id] = into[id]! - 1;
      }
    }
    return null;
  }

  @override
  TimelineState initial(TimelineSpec spec) =>
      TimelineState([for (var i = 0; i < spec.order.length; i++) spec.anchors[i]], const {});

  @override
  Applied<TimelineState> apply(TimelineSpec spec, TimelineState s, TimelineAction action) {
    Applied<TimelineState> no(String code, String why) => Applied.rejected(s, Rejection(code, why));
    final anchors = spec.anchors;
    switch (action) {
      case ClearTimeline():
        return Applied.accepted(initial(spec));
      case PlaceCard(:final card, :final slot):
        if (spec.card(card) == null) return no('card_unknown', '$card is no card of this timeline');
        if (slot < 0 || slot >= s.slots.length) return no('slot_unknown', 'there is no slot ${slot + 1}');
        if (anchors.containsValue(card)) return no('card_fixed', '$card is fixed in its place');
        if (anchors.containsKey(slot)) return no('slot_fixed', 'slot ${slot + 1} holds a fixed card');
        if (s.slots[slot] == card) return no('no_change', '$card is there already');
        final slots = [...s.slots];
        final from = slots.indexOf(card);
        final there = slots[slot];
        if (from >= 0) slots[from] = there; // a swap: what was there goes where the card was
        slots[slot] = card;
        return Applied.accepted(TimelineState(slots, {...s.discarded}..remove(card)));
      case DiscardCard(:final card):
        if (spec.card(card) == null) return no('card_unknown', '$card is no card of this timeline');
        if (anchors.containsValue(card)) return no('card_fixed', '$card is fixed in its place');
        if (s.discarded.contains(card)) return no('no_change', '$card is on the pile already');
        return Applied.accepted(TimelineState([for (final x in s.slots) x == card ? null : x], {...s.discarded, card}));
      case ReturnCard(:final card):
        if (spec.card(card) == null) return no('card_unknown', '$card is no card of this timeline');
        if (anchors.containsValue(card)) return no('card_fixed', '$card is fixed in its place');
        if (!s.holds(card)) return no('no_change', '$card is on the table already');
        return Applied.accepted(TimelineState([for (final x in s.slots) x == card ? null : x], {...s.discarded}..remove(card)));
    }
  }

  @override
  bool isComplete(TimelineSpec spec, TimelineState s) => !s.slots.contains(null);

  @override
  String answerOf(TimelineSpec spec, TimelineState s) => [for (final x in s.slots) x ?? ''].join(',');

  @override
  String answer(TimelineSpec spec) => spec.order.join(',');

  /// The first slot whose card is not the one that happened there, and a
  /// line of the case about it — for a wrong answer to point back to the
  /// words, never to say the answer.
  TimelineProblem? firstProblem(TimelineSpec spec, TimelineState s) {
    for (var i = 0; i < spec.order.length; i++) {
      final card = s.slots[i];
      if (card == spec.order[i]) continue;
      final line = card == null ? null : spec.relations.where((r) => r.earlier == card || r.later == card).firstOrNull?.line;
      return TimelineProblem(i, card, line);
    }
    return null;
  }

  @override
  TimelineState solved(TimelineSpec spec) => TimelineState([...spec.order], {for (final c in spec.cards) if (c.discard) c.id});

  @override
  Object? stateToJson(TimelineState s) => {
    's': s.slots,
    'd': s.discarded.toList()..sort(),
  };

  @override
  TimelineState? stateFromJson(TimelineSpec spec, Object? json) {
    if (json is! Map || json['s'] is! List || json['d'] is! List) return null;
    final slots = [for (final x in json['s'] as List) x is String ? x : null];
    final discarded = {for (final x in json['d'] as List) if (x is String) x};
    if (slots.length != spec.order.length || (json['s'] as List).any((x) => x != null && x is! String)) return null;
    final known = {for (final c in spec.cards) c.id};
    final seen = [...slots.whereType<String>(), ...discarded];
    if (!known.containsAll(seen) || seen.toSet().length != seen.length) return null;
    for (final MapEntry(key: i, value: id) in spec.anchors.entries) {
      if (slots[i] != id) return null;
    }
    if (discarded.any(spec.anchors.containsValue)) return null;
    return TimelineState(slots, discarded);
  }

  @override
  Object? structure(TimelineSpec spec) => {
    'cards': [
      for (final c in spec.cards) {'id': c.id, 'anchor': c.anchor, 'discard': c.discard, 'evidence': c.evidence},
    ],
    'order': spec.order,
    'relations': [for (final r in spec.relations) [r.earlier, r.later]],
  };

  @override
  Map<String, String> texts(TimelineSpec spec) => {
    for (final (i, c) in spec.cards.indexed) ...{'cards[$i].title': c.title, 'cards[$i].text': c.text},
    for (final (i, r) in spec.relations.indexed) 'relations[$i].line': r.line,
  };

  @override
  List<(String, String)> elementIds(TimelineSpec spec) => [for (final (i, c) in spec.cards.indexed) ('\$.cards[$i].id', c.id)];
}
