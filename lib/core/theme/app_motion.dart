import 'package:flutter/widgets.dart';

/// How things move in the game, in one place. Each kind of overlay has its
/// own motion so the player learns what it is by how it arrives:
///
/// * snackbar — slides up from the bottom: ease-out in, ease-in out.
/// * toast — fades in and out where it stands; it never travels.
/// * popup — grows slightly into place (scale in, ease-out).
/// * bottom sheet — slides up from the bottom while the page behind fades
///   darker (the route's barrier fades with it).
/// * like — a quick spring "pop" on scale.
/// * loading — turns at one steady speed (linear), forever.
/// * titles and steps — one line after another ([staggerDelay]).
///
/// Every helper honours the system's reduce-motion setting.
abstract final class AppMotion {
  // Snackbar ---------------------------------------------------------------
  static const snackBarIn = Duration(milliseconds: 280);
  static const snackBarOut = Duration(milliseconds: 200);
  static const snackBarInCurve = Curves.easeOut;
  static const snackBarOutCurve = Curves.easeIn;

  // Toast ------------------------------------------------------------------
  static const toastIn = Duration(milliseconds: 220);
  static const toastOut = Duration(milliseconds: 260);
  static const toastHold = Duration(milliseconds: 2400);
  static const toastInCurve = Curves.easeOut;
  static const toastOutCurve = Curves.easeIn;

  // Popup ------------------------------------------------------------------
  static const popupIn = Duration(milliseconds: 240);
  static const popupOut = Duration(milliseconds: 160);
  static const popupCurve = Curves.easeOut;
  static const popupReverseCurve = Curves.easeIn;

  /// The size a popup starts from: just a little smaller, so it settles
  /// rather than pops.
  static const popupScaleFrom = 0.94;

  // Bottom sheet -----------------------------------------------------------
  static const sheetIn = Duration(milliseconds: 300);
  static const sheetOut = Duration(milliseconds: 220);
  static const sheetCurve = Curves.easeOut;
  static const sheetReverseCurve = Curves.easeIn;

  // Like -------------------------------------------------------------------
  /// A light, slightly under-damped spring: one small overshoot, then rest.
  static const likeSpring = SpringDescription(mass: 1, stiffness: 420, damping: 16);

  /// The size a like starts its spring from (a quick squeeze before the pop).
  static const likeScaleFrom = 0.7;

  // Loading ----------------------------------------------------------------
  /// One full turn of a loading mark, at a steady (linear) speed.
  static const loadingTurn = Duration(milliseconds: 1100);
  static const loadingCurve = Curves.linear;

  // Titles and steps, one line at a time -----------------------------------
  static const lineIn = Duration(milliseconds: 360);
  static const staggerDelay = Duration(milliseconds: 90);
  static const lineCurve = Curves.easeOut;

  /// How far (logical px) a line rises as it appears.
  static const lineRise = 8.0;

  /// True when the player asked the system for less motion.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [motion], or nothing at all when the player asked for less motion.
  static Duration of(BuildContext context, Duration motion) => reduced(context) ? Duration.zero : motion;

  /// For `showDialog(animationStyle:)`: the popup's timing and its fade.
  static AnimationStyle popup(BuildContext context) => AnimationStyle(
    duration: of(context, popupIn),
    reverseDuration: of(context, popupOut),
    curve: popupCurve,
    reverseCurve: popupReverseCurve,
  );

  /// For `showModalBottomSheet(sheetAnimationStyle:)`.
  static AnimationStyle sheet(BuildContext context) => AnimationStyle(
    duration: of(context, sheetIn),
    reverseDuration: of(context, sheetOut),
    curve: sheetCurve,
    reverseCurve: sheetReverseCurve,
  );
}
