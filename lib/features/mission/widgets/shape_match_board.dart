import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/shape_match.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'question_widgets.dart' show AnswerState, answerPaper;
import '../../../core/utils/reading_lines.dart';

/// Letters laid on the pictures they copy ([ShapeMatchSpec], `shape_match`):
/// a letter tile is tapped, then the picture it goes on; a laid letter is
/// tapped again to pick it back up. CHECK sends the `letter:picture` pairs
/// ([onSubmit]) once every picture has one. With [solvedAnswer] the letters
/// lie where they belong, nothing to play.
class ShapeMatchBoard extends StatefulWidget {
  const ShapeMatchBoard({super.key, required this.spec, this.onSubmit, this.solvedAnswer});

  final ShapeMatchSpec spec;
  final ValueChanged<String>? onSubmit;
  final String? solvedAnswer;

  @override
  State<ShapeMatchBoard> createState() => _ShapeMatchBoardState();
}

class _ShapeMatchBoardState extends State<ShapeMatchBoard> {
  /// The letter on each picture, by picture id.
  late final Map<String, String> _on = {
    for (final p in (widget.solvedAnswer ?? '').split(',').map((s) => s.split(':')))
      if (p.length == 2) p[1]: p[0],
  };

  /// The letter tile in hand, waiting for its picture.
  String? _held;

  bool get _solved => widget.solvedAnswer != null;
  bool get _full => widget.spec.pictures.every((p) => _on.containsKey(p.id));

  void _tapLetter(String id) => setState(() => _held = _held == id ? null : id);

  void _tapPicture(String id) => setState(() {
    if (_held case final l?) {
      _on.removeWhere((_, v) => v == l);
      _on[id] = l;
      _held = null;
    } else {
      _held = _on.remove(id);
    }
  });

  void _check() => widget.onSubmit?.call([for (final p in widget.spec.pictures) '${_on[p.id]}:${p.id}'].join(','));

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final held = _held == null ? null : spec.letter(_held!).glyph;
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(140.0, box.maxWidth * 0.4);
        return Column(
          key: const ValueKey('shape-board'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_solved) ...[
              Semantics(header: true, child: Text('THE LETTERS', style: AppText.eyebrow())),
              const SizedBox(height: AppSpace.xs),
              Semantics(
                liveRegion: true,
                child: Text(
                  readingLines(held == null ? spec.task : 'Now tap the picture $held copies.'),
                  key: const ValueKey('shape-say'),
                  style: AppText.aside(size: 15, color: AppColors.inkBrown),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final l in spec.letters)
                    _LetterTile(
                      key: ValueKey('shape-letter-${l.id}'),
                      glyph: l.glyph,
                      held: _held == l.id,
                      laid: _on.containsValue(l.id),
                      onTap: () => _tapLetter(l.id),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
            ],
            Semantics(header: true, child: Text('THE PICTURES', style: AppText.eyebrow())),
            const SizedBox(height: AppSpace.sm),
            for (final p in spec.pictures)
              _PictureRow(
                key: ValueKey('shape-picture-${p.id}'),
                picture: p,
                side: side,
                glyph: _on[p.id] == null ? null : spec.letter(_on[p.id]!).glyph,
                waiting: _held != null,
                onTap: _solved ? null : () => _tapPicture(p.id),
              ),
            if (!_solved) ...[
              Center(
                child: InkTextButton(
                  label: 'Start again',
                  glyph: InkGlyph.clear,
                  onPressed: _on.isEmpty && _held == null ? null : () => setState(() => _on.clear()),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              GameButton(key: const ValueKey('shape-check'), label: 'CHECK', onPressed: _full ? _check : null),
            ],
          ],
        );
      },
    );
  }
}

/// A letter tile: large, its stroke told apart at a glance. In hand: navy;
/// already laid on a picture: faded, still tappable to move it.
class _LetterTile extends StatelessWidget {
  const _LetterTile({super.key, required this.glyph, required this.held, required this.laid, required this.onTap});

  final String glyph;
  final bool held;
  final bool laid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: held,
    label: 'Letter $glyph${laid ? ', on a picture' : ''}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: laid && !held ? 0.45 : 1,
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: answerPaper(held ? AnswerState.selected : AnswerState.idle),
          child: Text(readingLines(glyph), style: AppText.title(size: 32, color: held ? AppColors.goldLight : AppColors.navy)),
        ),
      ),
    ),
  );
}

/// A picture with the place for its letter beside it. Gold-edged while a
/// letter is in hand: it can go here.
class _PictureRow extends StatelessWidget {
  const _PictureRow({super.key, required this.picture, required this.side, required this.glyph, required this.waiting, required this.onTap});

  final ShapePicture picture;
  final double side;
  final String? glyph;
  final bool waiting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '${picture.name}: ${picture.label} ${glyph == null ? 'No letter yet.' : 'Letter $glyph on it.'}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: answerPaper(AnswerState.idle).copyWith(
          border: waiting ? Border.all(color: AppColors.gold, width: AppLine.ink) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.paper),
              child: Image.asset(picture.file, width: side, height: side, fit: BoxFit.cover, excludeFromSemantics: true),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(picture.name, textAlign: TextAlign.center, style: AppText.eyebrow()),
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paperLight,
                      borderRadius: BorderRadius.circular(AppRadius.paper),
                      border: Border.all(color: glyph == null ? AppColors.goldDeep : AppColors.navy, width: AppLine.rule),
                    ),
                    child: Text(readingLines(glyph ?? '?'), style: AppText.title(size: glyph == null ? 24 : 36, color: glyph == null ? AppColors.muted : AppColors.navy)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
