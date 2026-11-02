import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/widgets/edge_swipe_back.dart';

/// The iOS back swipe: from the left edge only, far enough only, and never
/// over a drag of the page's own (the puzzles' drags, sliders, pictures
/// that pan and pinch, pages that turn, lists that scroll).
void main() {
  late int backs;

  Future<void> pump(WidgetTester t, Widget page) async {
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    backs = 0;
    await t.pumpWidget(MaterialApp(
      builder: (context, child) => EdgeSwipeBack(onBack: () => backs++, child: child!),
      home: Scaffold(body: page),
    ));
  }

  Future<void> swipe(WidgetTester t, {Offset from = const Offset(4, 400), Offset by = const Offset(160, 0)}) async {
    await t.timedDragFrom(from, by, const Duration(milliseconds: 250));
    await t.pumpAndSettle();
  }

  group('on a plain page', () {
    testWidgets('a swipe from the edge goes back, once', (t) async {
      await pump(t, const SizedBox.expand());
      await swipe(t);
      expect(backs, 1);
    });

    testWidgets('a swipe begun past the 20 points does nothing', (t) async {
      await pump(t, const SizedBox.expand());
      await swipe(t, from: const Offset(EdgeSwipeBack.edgeWidth + 6, 400));
      expect(backs, 0);
    });

    testWidgets('short of the commit distance, or mostly up and down, does nothing', (t) async {
      await pump(t, const SizedBox.expand());
      await swipe(t, by: const Offset(EdgeSwipeBack.commitDistance - 8, 0));
      await swipe(t, by: const Offset(60, 120));
      expect(backs, 0);
    });

    testWidgets('dragged back to the left before letting go: cancelled', (t) async {
      await pump(t, const SizedBox.expand());
      final g = await t.startGesture(const Offset(4, 400));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(12, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      for (var i = 0; i < 9; i++) {
        await g.moveBy(const Offset(-12, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pumpAndSettle();
      expect(backs, 0);
    });

    testWidgets('a button at the edge still taps', (t) async {
      var taps = 0;
      await pump(t, Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => taps++, icon: const Icon(Icons.arrow_back))));
      await t.tapAt(const Offset(6, 422));
      await t.pumpAndSettle();
      expect(taps, 1);
      expect(backs, 0);
    });
  });

  group("the page's own drags keep the finger at the edge", () {
    Future<void> expectKept(WidgetTester t, Widget inner, bool Function() moved, {String? reason}) async {
      await pump(t, inner);
      await swipe(t);
      expect(moved(), isTrue, reason: '${reason ?? 'the drag'} got the finger');
      expect(backs, 0, reason: 'no back over ${reason ?? 'the drag'}');
    }

    testWidgets('a sideways drag (star records, the strip)', (t) async {
      var dx = 0.0;
      await expectKept(t, GestureDetector(behavior: HitTestBehavior.opaque, onHorizontalDragUpdate: (d) => dx += d.delta.dx, child: const SizedBox.expand()), () => dx > 0);
    });

    testWidgets('a pan (lens, mark compare)', (t) async {
      var moved = Offset.zero;
      await expectKept(t, GestureDetector(behavior: HitTestBehavior.opaque, onPanUpdate: (d) => moved += d.delta, child: const SizedBox.expand()), () => moved.dx > 0);
    });

    testWidgets('a draggable piece (letters, gears, labels)', (t) async {
      var started = false;
      await expectKept(
        t,
        Align(
          alignment: Alignment.centerLeft,
          child: Draggable<String>(
            data: 'A',
            onDragStarted: () => started = true,
            feedback: const SizedBox(width: 40, height: 40),
            child: const SizedBox(width: 80, height: 80, child: ColoredBox(color: Colors.brown)),
          ),
        ),
        () => started,
      );
    });

    testWidgets('a picture that pans and pinches (look round, World Map)', (t) async {
      final view = TransformationController();
      await expectKept(
        t,
        InteractiveViewer(
          transformationController: view,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          child: const SizedBox(width: 1200, height: 1200),
        ),
        () => view.value.getTranslation().x != 0,
      );
    });

    testWidgets('a slider (the paint slider, morning sketches)', (t) async {
      var value = 0.5;
      await expectKept(
        t,
        StatefulBuilder(
          builder: (context, setState) => Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 390, child: Slider(value: value, onChanged: (v) => setState(() => value = v))),
          ),
        ),
        () => value != 0.5,
      );
    });

    testWidgets('pages that turn (How to Play)', (t) async {
      final pages = PageController(initialPage: 1);
      await expectKept(
        t,
        PageView(controller: pages, children: const [SizedBox.expand(), SizedBox.expand(), SizedBox.expand()]),
        () => pages.page != 1,
      );
    });
  });

  testWidgets('a list that scrolls: a vertical scroll stays a scroll, a sideways swipe goes back', (t) async {
    final list = ScrollController();
    await pump(t, ListView(controller: list, children: [for (var i = 0; i < 40; i++) SizedBox(height: 80, child: Text('$i'))]));
    await swipe(t, by: const Offset(4, -300));
    expect(list.offset, greaterThan(0));
    expect(backs, 0);
    await swipe(t);
    expect(backs, 1);
  });
}
