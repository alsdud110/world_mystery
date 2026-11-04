import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import 'question_widgets.dart' show AnswerState, answerPaper;
import '../../../widgets/game_button.dart';
import '../../../puzzles_v2/core/puzzle_rules.dart';
import '../../../puzzles_v2/core/syllable_rules.dart';

/// A note in the new letters put back together (Puzzle Engine 2.0,
/// `syllable_compose`): each group's first sound is known, its vowel is
/// built from the book's first shapes — a flat line (the earth) or a
/// standing line (a person), and the sky's dot on it — and the group is
/// written as one syllable as soon as it is built. Taps only. Every move is
/// the rules' ([SyllableRules] through a [PuzzleSession]) and is saved
/// ([onSaved]); READ THE NOTE sends the note ([onSubmit]). A solved mission
/// ([solved]) shows the note as it was written.
class SyllableBoard extends StatefulWidget {
  const SyllableBoard({super.key, required this.spec, this.saved, this.solved = false, this.onSaved, this.onSubmit});

  final SyllableSpec spec;

  /// The mission's saved puzzle state (`GameProgress.puzzleStates`).
  final String? saved;
  final bool solved;
  final ValueChanged<String>? onSaved;
  final ValueChanged<String>? onSubmit;

  @override
  State<SyllableBoard> createState() => _SyllableBoardState();
}

class _SyllableBoardState extends State<SyllableBoard> {
  static const _rules = SyllableRules();

  late PuzzleSession<SyllableSpec, SyllableState, SyllableAction> _session =
      PuzzleSession.open(_rules, widget.spec, saved: widget.saved, solved: widget.solved);

  /// The first group read wrong after READ THE NOTE.
  int? _problem;

  /// Why the last tap did nothing.
  String? _note;

  SyllableSpec get _spec => widget.spec;

  void _play(SyllableAction action) {
    final (next, why) = _session.play(action);
    if (why?.code == 'no_change') return;
    setState(() {
      if (why != null) {
        _note = why.code == 'dot_without_line' ? 'Lay a line first: the dot sits on it.' : 'The dot cannot sit there on that line.';
        return;
      }
      _note = null;
      _problem = null;
      _session = next;
    });
    if (why == null) widget.onSaved?.call(_session.saved);
  }

  void _read() {
    setState(() => _problem = _rules.firstProblem(_spec, _session.state));
    widget.onSubmit?.call(_session.answer);
  }

  static String _lineName(VowelLine l) => l == VowelLine.flat ? 'FLAT' : 'STANDING';
  static String _lineMeaning(VowelLine l) => l == VowelLine.flat ? 'the earth' : 'a person';
  static String _lineGlyph(VowelLine l) => l == VowelLine.flat ? 'ㅡ' : 'ㅣ';
  static String _dotName(VowelDot d) => d == VowelDot.none ? 'NO DOT' : d.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    if (_session.readOnly) return _solvedNote();
    return Column(
      key: const ValueKey('syllable-board'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('THE NOTE, GROUP BY GROUP', style: AppText.eyebrow())),
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.sm),
          child: Text('Lay each vowel\'s line, then put the sky\'s dot on it.', style: AppText.aside(size: 15)),
        ),
        for (var i = 0; i < _spec.blocks.length; i++) _group(i),
        if (_note != null)
          Semantics(
            liveRegion: true,
            child: Text(_note!, key: const ValueKey('syllable-note'), style: AppText.aside(size: 15, color: AppColors.inkBrown)),
          ),
        const SizedBox(height: AppSpace.md),
        GameButton(key: const ValueKey('syllable-check'), label: 'READ THE NOTE', onPressed: _session.complete ? _read : null),
      ],
    );
  }

  /// Group [i]: what is written so far, the words that tell its vowel, and its pieces.
  Widget _group(int i) {
    final b = _spec.blocks[i];
    final piece = _session.state.pieces[i];
    final wrong = _problem == i;
    final written = _rules.written(_spec, _session.state, i);
    return Container(
      key: ValueKey('syllable-group-${b.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: answerPaper(wrong ? AnswerState.wrong : AnswerState.idle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Group ${i + 1}: ${piece.vowel == null ? 'only its first sound, ${b.initial}, is known' : 'written $written'}',
                excludeSemantics: true,
                child: Container(
                  key: ValueKey('syllable-written-${b.id}'),
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.paperLight,
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
                  ),
                  child: Text(written, style: AppText.title(size: 40, color: piece.vowel == null ? AppColors.inkBrown : AppColors.navy)),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wrong ? 'GROUP ${i + 1} · CHECK THIS ONE' : 'GROUP ${i + 1}', style: AppText.eyebrow(color: wrong ? AppColors.tryAgain : AppColors.goldDeep)),
                    Text(b.line, style: AppText.bodyText(size: 15, color: AppColors.inkBrown)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final l in VowelLine.values)
                _Piece(
                  key: ValueKey('syllable-line-${b.id}-${l.name}'),
                  glyph: _lineGlyph(l),
                  label: _lineName(l),
                  semanticsLabel: 'Group ${i + 1}: a ${_lineName(l).toLowerCase()} line, ${_lineMeaning(l)}',
                  selected: piece.line == l,
                  onTap: () => _play(SetVowelLine(i, l)),
                ),
            ],
          ),
          if (piece.line case final line?) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final d in Hangul.dotsFor(line))
                  _Piece(
                    key: ValueKey('syllable-dot-${b.id}-${d.name}'),
                    glyph: d == VowelDot.none ? '' : Hangul.dot,
                    label: _dotName(d),
                    semanticsLabel: d == VowelDot.none ? 'Group ${i + 1}: no dot' : 'Group ${i + 1}: the sky\'s dot ${d.name} the line',
                    selected: piece.dot == d,
                    onTap: () => _play(SetVowelDot(i, d)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// The note as it was written: its groups in a row.
  Widget _solvedNote() => Column(
    key: const ValueKey('syllable-solved'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(header: true, child: Text('THE NOTE', style: AppText.eyebrow())),
      const SizedBox(height: AppSpace.sm),
      Semantics(
        label: 'The note: ${_session.answer}',
        excludeSemantics: true,
        child: Text(_session.answer, textAlign: TextAlign.center, style: AppText.title(size: 40, color: AppColors.navy)),
      ),
    ],
  );
}

/// One piece to lay: its shape and its name. 48 dp at least; selected is
/// told by its fill, its border and its tick, never by colour alone.
class _Piece extends StatefulWidget {
  const _Piece({super.key, required this.glyph, required this.label, required this.semanticsLabel, required this.selected, required this.onTap});

  final String glyph;
  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Piece> createState() => _PieceState();
}

class _PieceState extends State<_Piece> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return Semantics(
      button: true,
      selected: on,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: FocusableActionDetector(
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
            decoration: answerPaper(on ? AnswerState.selected : AnswerState.idle).copyWith(
              border: _focused ? Border.all(color: AppColors.gold, width: AppLine.ink) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.glyph.isNotEmpty) ...[
                  Text(widget.glyph, style: AppText.title(size: 22, color: on ? AppColors.goldLight : AppColors.navy)),
                  const SizedBox(width: AppSpace.xs),
                ],
                // Wraps under large text rather than running off the piece.
                Flexible(child: Text(on ? '✓ ${widget.label}' : widget.label, style: AppText.eyebrow(color: on ? AppColors.paperLight : AppColors.ink))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
