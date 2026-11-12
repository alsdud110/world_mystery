import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/game_dialog.dart';
import '../../../widgets/paper.dart';

/// Above a puzzle shown with its answer entered (the answer's picture, see
/// [showAnswerPicture]): the puzzle's widgets start with [answer] set in
/// them, as the detective would have set it, in place of an empty puzzle.
class ShownAnswer extends InheritedWidget {
  const ShownAnswer({super.key, required this.answer, required super.child});

  /// The mission's answer, as it is checked ([Mission.answer]).
  final String answer;

  /// The answer a puzzle under a [ShownAnswer] starts with; null on a
  /// puzzle that is played. Read once, as the puzzle's state is made.
  static String? of(BuildContext context) => context.getInheritedWidgetOfExactType<ShownAnswer>()?.answer;

  @override
  bool updateShouldNotify(ShownAnswer old) => old.answer != answer;
}

/// A puzzle with its answer entered, as [showAnswerPicture] shows it.
@immutable
class AnswerPicture {
  const AnswerPicture(this.child, {this.page = false, this.dark = false, this.question, this.sends = true});

  /// Whether the puzzle shown has a way to send the answer set in it (its
  /// own button, or by itself once complete); false for one that only shows
  /// what is chosen (a poster, two statements).
  final bool sends;

  /// The puzzle itself, its answer set in it.
  final Widget child;

  /// True: [child] is a whole page (a place searched, a talk), laid out at
  /// the size of the screen under the bar; false: a puzzle laid on the page,
  /// as wide as the page's column and as tall as it needs.
  final bool page;

  /// The puzzle is one of a night page (a final case's dials): its picture
  /// keeps the night behind it.
  final bool dark;

  /// The heading over the picture, in place of the mission's question.
  final String? question;
}

/// The answer of [mission], shown as a picture of its puzzle with the answer
/// entered: the puzzle itself ([picture]), laid out as on its page and made
/// smaller to fit, like a photo of the page. Nothing on it can be touched.
Future<void> showAnswerPicture(
  BuildContext context, {
  required Mission mission,
  required AnswerPicture picture,
}) {
  final screen = MediaQuery.sizeOf(context);
  final pageWidth = picture.page ? screen.width : screen.width - 2 * AppSpace.screen;
  final pageHeight = picture.page ? screen.height - MediaQuery.paddingOf(context).top - kToolbarHeight : null;
  final dark = picture.dark;
  final question = picture.question;
  return showGamePopup<void>(
    context: context,
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.55),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperSheet(
          ruled: true,
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('THE ANSWER', textAlign: TextAlign.center, style: AppText.eyebrow()),
                const SizedBox(height: AppSpace.sm),
                // A whole page says its own task.
                if (!picture.page) ...[
                  Text(
                    Formatters.sentenceLines(question ?? mission.question),
                    textAlign: TextAlign.center,
                    style: AppText.title(size: 18),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                const SizedBox(height: AppSpace.xs),
                // The page's photo: the puzzle as it stands with the answer
                // in it, whole, never scrolled.
                Semantics(
                  label: 'The answer: ${mission.answerLabel}',
                  image: true,
                  container: true,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey('answer-picture'),
                        constraints: BoxConstraints(maxHeight: screen.height * 0.52),
                        padding: EdgeInsets.all(picture.page ? 0 : AppSpace.md),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: dark ? AppColors.navyDeep : AppColors.paper,
                          border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.45), width: AppLine.hairline),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: pageWidth,
                            height: pageHeight,
                            child: ShownAnswer(answer: mission.answer, child: picture.child),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                GameButton(
                  label: 'BACK TO THE PUZZLE',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
