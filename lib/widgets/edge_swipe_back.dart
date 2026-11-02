import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The iOS back swipe: a drag to the right that begins at the left edge of
/// the screen goes back, exactly as Android's back does ([onBack]: the
/// router's popRoute, so each page's own back still decides where to — a
/// step of the mission, the page it came from, a question first).
///
/// Flutter's own swipe (the Cupertino page route) cannot be used here: it
/// is off on the first page of a stack (every page reached with `go`) and on
/// a page that handles back itself (every [BackTo] page, the case map), and
/// it would slide the pages instead of the game's fade.
///
/// Inside the page, every drag is the page's own: a swipe counts only after
/// [commitDistance], beyond the distance at which a puzzle's drag, a
/// slider, a scroll or the map's pan and pinch take the finger, so a drag
/// that begins at the edge on one of those stays with it.
class EdgeSwipeBack extends StatelessWidget {
  const EdgeSwipeBack({super.key, required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  /// Where a back swipe may begin: the left 20 points, as on iOS.
  static const edgeWidth = 20.0;

  /// How far to the right the finger must go (and stay) to go back: past
  /// the pan slop (36) at which pans, pinches and drags win the finger.
  static const commitDistance = 48.0;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        _EdgeSwipeRecognizer: GestureRecognizerFactoryWithHandlers<_EdgeSwipeRecognizer>(
          () => _EdgeSwipeRecognizer(debugOwner: this),
          (recognizer) => recognizer.onSwipe = onBack,
        ),
      },
      child: child,
    );
  }
}

class _EdgeSwipeRecognizer extends OneSequenceGestureRecognizer {
  _EdgeSwipeRecognizer({super.debugOwner});

  VoidCallback? onSwipe;

  /// Where the finger came down (null: no swipe under way).
  Offset? _start;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _start == null && event.position.dx <= EdgeSwipeBack.edgeWidth && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _start = event.position;
  }

  /// Gone far enough to the right, and more sideways than up or down.
  bool _farEnough(Offset delta) => delta.dx >= EdgeSwipeBack.commitDistance && delta.dy.abs() < delta.dx;

  @override
  void handleEvent(PointerEvent event) {
    final start = _start;
    if (start == null) return;
    final delta = event.position - start;
    if (event is PointerMoveEvent) {
      if (_farEnough(delta)) {
        resolve(GestureDisposition.accepted);
      } else if (delta.dx < -kTouchSlop || (delta.dy.abs() > kTouchSlop && delta.dy.abs() > delta.dx)) {
        // Back to the left, or up or down: not a back swipe.
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
      }
    } else if (event is PointerUpEvent) {
      // Let go far enough to the right: back (else nothing).
      final swiped = _farEnough(delta);
      resolve(swiped ? GestureDisposition.accepted : GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
      if (swiped) invokeCallback<void>('onSwipe', () => onSwipe?.call());
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) => stopTrackingPointer(pointer);

  @override
  void didStopTrackingLastPointer(int pointer) => _start = null;

  @override
  String get debugDescription => 'edge swipe back';
}
