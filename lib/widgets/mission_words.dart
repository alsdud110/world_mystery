import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/mock/season_catalog.dart';
import '../data/models/case_talk.dart';
import '../data/models/mission.dart';
import '../data/models/mission_speech.dart';
import 'display_sized_image.dart';
import 'art_assets.dart';
import 'glossary_text.dart';
import 'letter_card.dart';

/// A mission's letter as it is held (the solved page, the puzzle's reread):
/// words written on a thing on the thing ([ArtAssets.inscriptions]), what a
/// person said in the talk's own card ([SeasonCatalog.speech]), else the
/// letter itself.
class MissionWords extends StatelessWidget {
  const MissionWords({super.key, required this.mission});

  final Mission mission;

  /// The puzzle's way back to the words: the thing looked at again, the
  /// person heard again, else the letter read again.
  static String rereadLabel(Mission m) {
    if (ArtAssets.inscriptions.containsKey(m.id)) return 'Look Again';
    if (SeasonCatalog.speech(m)?.saysLetter ?? false) return 'Hear It Again';
    return 'Reread Letter';
  }

  /// The letter as its paper shows it: a person's words that end it are
  /// said in the talk, not written again (see [MissionSpeech.inLetter]).
  static String paperOf(Mission m) => SeasonCatalog.speech(m)?.paperOf(m) ?? m.letter;

  @override
  Widget build(BuildContext context) {
    final m = mission;
    final inscribed = ArtAssets.inscriptions[m.id];
    if (inscribed != null) {
      return InscribedObject(
        file: inscribed.file,
        aspect: inscribed.aspect,
        text: inscribed.text,
        words: m.letter,
        thing: inscribed.thing,
      );
    }
    final speech = SeasonCatalog.speech(m);
    if (speech != null && speech.saysLetter) return SpokenWordsCard(speaker: speech.speaker, words: m.letter);
    final paper = LetterCard(text: paperOf(m), sealPicture: ArtAssets.letterSeals[m.id]);
    if (speech == null || !speech.inLetter) return paper;
    // What was said, then the paper read with it (Case 12: Grey, the board).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpokenWordsCard(speaker: speech.speaker, words: speech.wordsOf(m)),
        const SizedBox(height: AppSpace.lg),
        paper,
      ],
    );
  }
}

/// Words written on a thing, on the thing itself (Season 1: Case 11's white
/// mask): its picture, and the words set by the game over the place they are
/// written ([text], fractions of the picture), so they are spelt exactly
/// and read out — letter by letter, as written — with what the thing is.
class InscribedObject extends StatelessWidget {
  const InscribedObject({
    super.key,
    required this.file,
    required this.aspect,
    required this.text,
    required this.words,
    required this.thing,
    this.maxWidth = 360,
  });

  final String file;
  final double aspect;
  final Rect text;
  final String words;
  final String thing;
  final double maxWidth;

  /// What a screen reader says: the thing, then the words letter by letter
  /// (a word written backwards is not a word to pronounce).
  String get label => '$thing. Written on it: ${words.split('').where((c) => c.trim().isNotEmpty).join(' ')}';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Semantics(
          image: true,
          label: label,
          excludeSemantics: true,
          child: AspectRatio(
            aspectRatio: aspect,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(boxShadow: AppShadow.paperLift),
                    child: DisplaySizedImage(file, fit: BoxFit.cover, width: box.maxWidth, excludeFromSemantics: true),
                  ),
                  Positioned(
                    left: text.left * box.maxWidth,
                    top: text.top * box.maxHeight,
                    width: text.width * box.maxWidth,
                    height: text.height * box.maxHeight,
                    child: FittedBox(
                      key: const ValueKey('inscribed-words'),
                      // The words are the thing's: never larger with the
                      // text size, always the width written on.
                      child: Text(
                        words,
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: AppText.placeTitle(size: 40, color: AppColors.inkBrown).copyWith(letterSpacing: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a person said, read again (a talk's words, after it is over): their
/// portrait small, their name plate, and the words in quotes — the talk's own
/// card, not a letter.
class SpokenWordsCard extends StatelessWidget {
  const SpokenWordsCard({super.key, required this.speaker, required this.words});

  final TalkSpeaker speaker;

  /// The words, as the letter holds them (see [MissionSpeech.spokenLines]).
  final String words;

  @override
  Widget build(BuildContext context) {
    final portrait = speaker.portrait(speaker.baseMood);
    final lines = MissionSpeech.spokenLines(words);
    return Container(
      key: const ValueKey('spoken-words'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppLine.faint(), width: AppLine.hairline),
        boxShadow: AppShadow.paperLift,
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (portrait != null) ...[
            Semantics(
              image: true,
              label: speaker.description,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.paper),
                child: SizedBox(
                  width: 64,
                  height: 96,
                  child: DisplaySizedImage(portrait, fit: BoxFit.cover, alignment: Alignment.topCenter, width: 64, excludeFromSemantics: true),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speaker.name, style: AppText.mark(color: AppColors.burgundy, size: 15)),
                const SizedBox(height: AppSpace.sm),
                // Its words keep their meanings (press and hold), as the letter's.
                GlossaryText('"${lines.join('\n')}"', style: AppText.letter(size: 18, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
