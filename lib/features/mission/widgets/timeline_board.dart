import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import 'question_widgets.dart' show AnswerState, answerPaper;
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../puzzles_v2/core/puzzle_rules.dart';
import '../../../puzzles_v2/core/timeline_rules.dart';
import '../../../core/utils/reading_lines.dart';

/// A timeline to put back together (Puzzle Engine 2.0, `timeline_board`):
/// the cards' places, the cards still on the table, and the NOT PART OF IT
/// pile. Played by taps only: a card is picked, then where it goes is
/// tapped. Every move is the rules' ([TimelineRules] through a
/// [PuzzleSession]); this page only shows them. Each move is saved
/// ([onSaved]: `GameController.recordPuzzleState`), CHECK THE ORDER sends
/// the order ([onSubmit]: `GameController.submitAnswer`). A solved mission
/// ([solved]) shows its timeline as it happened, nothing to play.
class TimelineBoard extends StatefulWidget {
  const TimelineBoard({super.key, required this.spec, this.saved, this.solved = false, this.onSaved, this.onSubmit});

  final TimelineSpec spec;

  /// The mission's saved puzzle state (`GameProgress.puzzleStates`).
  final String? saved;
  final bool solved;
  final ValueChanged<String>? onSaved;
  final ValueChanged<String>? onSubmit;

  @override
  State<TimelineBoard> createState() => _TimelineBoardState();
}

class _TimelineBoardState extends State<TimelineBoard> with SingleTickerProviderStateMixin {
  static const _rules = TimelineRules();

  late PuzzleSession<TimelineSpec, TimelineState, TimelineAction> _session =
      PuzzleSession.open(_rules, widget.spec, saved: widget.saved, solved: widget.solved);

  /// The sessions before each move, for UNDO (kept while the page is open).
  final _history = <PuzzleSession<TimelineSpec, TimelineState, TimelineAction>>[];

  /// The card picked, waiting for where it goes.
  String? _picked;

  /// The first card out of place after a wrong CHECK THE ORDER.
  TimelineProblem? _problem;

  /// Why the last tap did nothing (said under the board, and read out).
  String? _note;

  /// The breath of the empty places while a card is picked: where it can go.
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Breathes only while a card waits for its place (and motion is allowed).
  void _syncPulse() {
    if (_picked != null && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  TimelineSpec get _spec => widget.spec;
  TimelineState get _state => _session.state;
  bool get _readOnly => _session.readOnly;

  void _play(TimelineAction action) {
    final (next, why) = _session.play(action);
    setState(() {
      _picked = null;
      if (why != null) {
        _note = _say(why);
        return;
      }
      _note = null;
      _problem = null;
      _history.add(_session);
      _session = next;
    });
    if (why == null) widget.onSaved?.call(_session.saved);
  }

  /// A rejection in the player's words.
  String _say(Rejection why) => switch (why.code) {
    'card_fixed' || 'slot_fixed' => 'That card is fixed: its time is written on it.',
    'no_change' => 'It is there already.',
    _ => 'That cannot go there.',
  };

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _session = _history.removeLast();
      _picked = null;
      _problem = null;
      _note = null;
    });
    widget.onSaved?.call(_session.saved);
  }

  void _tapCard(String id) {
    if (_readOnly) return;
    if (_spec.anchors.containsValue(id)) {
      setState(() => _note = _say(const Rejection('card_fixed', '')));
      return;
    }
    setState(() {
      _picked = _picked == id ? null : id;
      _note = null;
    });
  }

  void _tapSlot(int slot) {
    if (_readOnly) return;
    final there = _state.slots[slot];
    if (_picked case final card?) {
      _play(PlaceCard(card, slot));
    } else if (there != null) {
      _tapCard(there);
    }
  }

  void _check() {
    final answer = _session.answer;
    setState(() => _problem = _rules.firstProblem(_spec, _state));
    widget.onSubmit?.call(answer);
  }

  TimelineCard _card(String id) => _spec.card(id)!;

  @override
  Widget build(BuildContext context) {
    final slots = _state.slots;
    final table = [for (final c in _spec.cards) if (!_state.holds(c.id)) c];
    final picked = _picked == null ? null : _card(_picked!);
    _syncPulse();
    return Column(
      key: const ValueKey('timeline-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(_readOnly ? 'WHAT HAPPENED' : 'THE TIMELINE', style: AppText.eyebrow())),
        if (!_readOnly)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              readingLines(picked == null ? 'Tap a card, then tap where it goes.' : 'Now tap where "${picked.title}" goes.'),
              style: AppText.aside(size: 15),
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        for (var i = 0; i < slots.length; i++) _slot(i, slots[i], picked),
        if (!_readOnly) ...[
          const SizedBox(height: AppSpace.md),
          Semantics(header: true, child: Text('ON THE TABLE', style: AppText.eyebrow())),
          const SizedBox(height: AppSpace.sm),
          if (table.isEmpty) Text('Every card is placed.', style: AppText.aside(size: 15)),
          for (final c in table) _cardTile(c, where: 'on the table'),
        ],
        const SizedBox(height: AppSpace.md),
        _pile(picked),
        if (_note != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Text(readingLines(_note!), key: const ValueKey('timeline-note'), style: AppText.aside(size: 15, color: AppColors.inkBrown)),
            ),
          ),
        if (!_readOnly) ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              InkTextButton(label: 'Undo', glyph: InkGlyph.backspace, onPressed: _history.isEmpty ? null : _undo),
              if (picked != null && _state.holds(picked.id))
                InkTextButton(label: 'Back to the table', glyph: InkGlyph.clear, onPressed: () => _play(ReturnCard(picked.id))),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          GameButton(label: 'CHECK THE ORDER', onPressed: _session.complete ? _check : null),
        ],
      ],
    );
  }

  /// Place [i] of the timeline: its fixed card, the card put there, or empty.
  Widget _slot(int i, String? id, TimelineCard? picked) {
    final card = id == null ? null : _card(id);
    final fixed = _spec.anchors[i] != null;
    final wrong = _problem?.slot == i;
    final chosen = id != null && id == _picked;
    final target = picked != null && !fixed && !_readOnly;
    final where = 'Place ${i + 1} of ${_state.slots.length}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: _Tap(
        key: ValueKey('timeline-slot-$i'),
        enabled: !_readOnly,
        semanticsLabel: [
          where,
          if (fixed) 'fixed, ${card!.anchor}',
          card == null ? 'empty' : '${card.title}. ${card.text}',
          if (chosen) 'picked',
          if (wrong) 'out of place',
        ].join(', '),
        semanticsHint: _readOnly
            ? null
            : target
            ? 'Tap to put ${picked.title} here.'
            : fixed
            ? null
            : card != null
            ? 'Tap to pick this card.'
            : 'Pick a card first.',
        selected: chosen,
        onTap: () => _tapSlot(i),
        child: (focused) => AnimatedBuilder(
          animation: _pulse,
          // An empty place breathes gold while a card waits for it.
          builder: (context, child) {
            final glow = target && card == null ? _pulse.value : 0.0;
            return Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              decoration: answerPaper(chosen ? AnswerState.selected : wrong ? AnswerState.wrong : card == null ? AnswerState.disabled : AnswerState.idle).copyWith(
                color: target && card == null ? Color.lerp(AppColors.paperLight, AppColors.goldLight, 0.15 + 0.35 * glow) : null,
                border: Border.all(
                  color: focused || target ? Color.lerp(AppColors.goldDeep, AppColors.gold, glow)! : fixed ? AppColors.goldDeep : AppLine.faint(0.22),
                  width: focused || target || fixed ? AppLine.ink : AppLine.hairline,
                ),
                boxShadow: glow > 0 ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.45 * glow), blurRadius: 4 + 10 * glow)] : null,
              ),
              child: child,
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Mark(fixed ? card!.anchor! : '${i + 1}', year: fixed, light: chosen),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: card == null
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpace.xs),
                        child: target
                            ? Row(
                                children: [
                                  InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.goldDeep),
                                  const SizedBox(width: AppSpace.xs),
                                  Flexible(child: Text('Put it here', style: AppText.subtitle(color: AppColors.goldDeep))),
                                ],
                              )
                            : Text('Empty', style: AppText.aside(size: 15)),
                      )
                    : _words(card, chosen: chosen, tag: fixed ? 'FIXED' : chosen ? 'PICKED' : wrong ? 'CHECK THIS ONE' : null,
                        line: wrong ? _problem!.line : null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A card on the table or the pile.
  Widget _cardTile(TimelineCard c, {required String where}) {
    final chosen = c.id == _picked;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: _Tap(
        key: ValueKey('timeline-card-${c.id}'),
        enabled: !_readOnly,
        semanticsLabel: '${c.title}. ${c.text}. $where${chosen ? ', picked' : ''}',
        semanticsHint: _readOnly ? null : chosen ? 'Now tap a place on the timeline, or Not part of it.' : 'Tap to pick this card.',
        selected: chosen,
        onTap: () => _tapCard(c.id),
        child: (focused) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          decoration: answerPaper(chosen ? AnswerState.selected : AnswerState.idle).copyWith(
            border: focused ? Border.all(color: AppColors.gold, width: AppLine.ink) : null,
          ),
          child: _words(c, chosen: chosen, tag: chosen ? 'PICKED' : null),
        ),
      ),
    );
  }

  /// The NOT PART OF IT pile: where a picked card is set aside, and what is there.
  Widget _pile(TimelineCard? picked) {
    final aside = [for (final c in _spec.cards) if (_state.discarded.contains(c.id)) c];
    if (_readOnly && aside.isEmpty) return const SizedBox.shrink();
    final target = picked != null && !_readOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('NOT PART OF IT', style: AppText.eyebrow(color: AppColors.inkBrown))),
        const SizedBox(height: AppSpace.sm),
        if (!_readOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _Tap(
              key: const ValueKey('timeline-pile'),
              enabled: true,
              semanticsLabel: 'Not part of it: ${aside.length} card${aside.length == 1 ? '' : 's'}',
              semanticsHint: target ? 'Tap to set ${picked.title} aside.' : 'Pick a card first.',
              selected: false,
              onTap: () {
                if (_picked case final card?) _play(DiscardCard(card));
              },
              child: (focused) => Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                decoration: answerPaper(AnswerState.disabled).copyWith(
                  border: Border.all(color: focused || target ? AppColors.gold : AppLine.faint(0.22), width: focused || target ? AppLine.ink : AppLine.hairline),
                ),
                child: Text(
                  readingLines(target ? 'Set it aside: it did not happen in this story' : 'Cards that are not part of what happened'),
                  style: AppText.aside(size: 15),
                ),
              ),
            ),
          ),
        for (final c in aside) _cardTile(c, where: 'not part of it'),
      ],
    );
  }

  Widget _words(TimelineCard c, {required bool chosen, String? tag, String? line}) {
    final ink = chosen ? AppColors.paperLight : AppColors.ink;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null) Text(tag, style: AppText.eyebrow(color: chosen ? AppColors.goldLight : AppColors.goldDeep)),
          Text(c.title, style: AppText.subtitle(color: ink)),
          Text(readingLines(c.text), style: AppText.bodyText(size: 15, color: chosen ? AppColors.paperLight : AppColors.inkBrown)),
          if (line != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(readingLines(line), key: const ValueKey('timeline-problem-line'), style: AppText.aside(size: 15, color: AppColors.tryAgain)),
          ],
        ],
      ),
    );
  }
}

/// A place's number, or the fixed card's time.
class _Mark extends StatelessWidget {
  const _Mark(this.text, {required this.year, required this.light});

  final String text;
  final bool year;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 32),
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 2),
    decoration: year ? BoxDecoration(border: Border.all(color: AppColors.goldDeep, width: AppLine.rule), borderRadius: BorderRadius.circular(AppRadius.paper)) : null,
    child: ExcludeSemantics(
      child: Text(readingLines(text), textAlign: TextAlign.center, style: AppText.title(size: year ? 16 : 20, color: light ? AppColors.goldLight : year ? AppColors.goldDeep : AppColors.navy)),
    ),
  );
}

/// A tappable part of the board: a tap, or Enter / Space once it has the
/// keyboard's focus (its ring drawn by [child]), and one label for a screen
/// reader. No drag, no long press.
class _Tap extends StatefulWidget {
  const _Tap({super.key, required this.enabled, required this.semanticsLabel, this.semanticsHint, required this.selected, required this.onTap, required this.child});

  final bool enabled;
  final String semanticsLabel;
  final String? semanticsHint;
  final bool selected;
  final VoidCallback onTap;
  final Widget Function(bool focused) child;

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.enabled,
    selected: widget.selected,
    label: widget.semanticsLabel,
    hint: widget.semanticsHint,
    onTap: widget.enabled ? widget.onTap : null,
    excludeSemantics: true,
    child: FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.enabled ? widget.onTap : null, child: widget.child(_focused)),
    ),
  );
}
