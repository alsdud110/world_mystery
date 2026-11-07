import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season1/season1_explores.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import 'full_playthrough_test.dart' show goToTime, reveal, tapText, wait;
import 'helpers.dart';

/// How a player goes back.
enum BackVia {
  /// The system back as older Android versions deliver it (popRoute).
  systemBack,

  /// Android 16 (target SDK 36, predictive back): the back gesture channel.
  backGesture,

  /// The arrow in the app bar.
  appBar,

  /// iOS: a swipe from the left edge of the screen (EdgeSwipeBack).
  iosEdgeSwipe,
}

/// Where an iOS back swipe begins: the left edge, low on the page (clear of
/// a mission's pictures, which take a drag themselves).
const _swipeFrom = Offset(4, 600);

/// Android back (the system back button / gesture) never closes the app in
/// the middle of a case: it walks back a step, or asks first. It does exactly
/// what the app bar arrow does.
void main() {
  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation;

  /// What the framework last told Android: whether it handles back itself.
  /// False would let Android send the app away on the next back.
  late List<bool> handlesBack;

  Future<void> start(WidgetTester t, {bool introSeen = true, String at = Routes.map, List<String> completed = const []}) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    handlesBack = [];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') handlesBack.add(call.arguments as bool);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final progress = GameProgress(detectiveName: 'KIM', introSeen: introSeen, completedMissionIds: completed, startedAt: DateTime(2026, 10, 1, 10), playMillis: 0);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(progress.toJson())}),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
    appRef.read(routerProvider).go(at);
    await wait(t, const Duration(milliseconds: 1500));
  }

  Future<void> back(WidgetTester t, BackVia via) async {
    if (via != BackVia.iosEdgeSwipe) expect(handlesBack.last, isTrue, reason: 'Android must hand this back to the game');
    switch (via) {
      case BackVia.iosEdgeSwipe:
        await t.timedDragFrom(_swipeFrom, const Offset(160, 0), const Duration(milliseconds: 250));
      case BackVia.systemBack:
        await t.binding.handlePopRoute();
      case BackVia.backGesture:
        const codec = StandardMethodCodec();
        for (final call in const [
          MethodCall('startBackGesture', <String, Object?>{'touchOffset': <double>[0, 300], 'progress': 0.0, 'swipeEdge': 0}),
          MethodCall('commitBackGesture'),
        ]) {
          await t.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/backgesture', codec.encodeMethodCall(call), (_) {});
          await t.pump();
        }
      case BackVia.appBar:
        await t.tap(find.byWidgetPredicate((w) => w is IconButton && (w.tooltip == 'Back' || w.tooltip == 'Back to map')));
    }
    await wait(t, const Duration(milliseconds: 800));
  }

  /// The map is on screen and ready: not faded out, GO can be tapped.
  void expectMapBack(WidgetTester t) {
    expect(path(), Routes.map);
    expect(t.widget<FadeTransition>(find.byKey(const ValueKey('map-page'))).opacity.value, 1, reason: 'the map is visible again');
    expect(find.bySemanticsLabel("GO TO KING'S CROSS"), findsOneWidget);
    expect(find.text('Leave the case?'), findsNothing);
  }

  Future<void> goToMission(WidgetTester t) async {
    await t.tap(find.bySemanticsLabel("GO TO KING'S CROSS"));
    await wait(t, goToTime);
    expect(path(), Routes.mission('m01'));
  }

  Finder lookRound() => find.byKey(const ValueKey('explore-picture'));

  /// Case 01's first mission is played by looking round King's Cross: no
  /// letter step (the letter is in the suitcase there).
  Future<void> investigate(WidgetTester t) async {
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
    expect(lookRound(), findsOneWidget, reason: 'the look round');
    expect(find.text('TAP TO OPEN'), findsNothing, reason: 'no letter step');
  }

  Future<void> tapSpot(WidgetTester t, String id) async {
    final picture = t.getRect(lookRound());
    final at = exploreOf(MockEpisodeRepository.bundled().first.missions.first)!.spot(id).areas.first.center;
    await t.tapAt(Offset(picture.left + at.dx * picture.width, picture.top + at.dy * picture.height));
    await wait(t, const Duration(milliseconds: 600));
  }

  /// The letter found and read in the suitcase, then the poster board open
  /// (where the museum is chosen: the mission's puzzle).
  Future<void> openLetterAndSolve(WidgetTester t) async {
    await tapSpot(t, 'suitcase');
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    await tapText(t, 'BACK TO INVESTIGATION', after: const Duration(milliseconds: 500));
    await tapSpot(t, 'posters');
    expect(find.text('CHECK ANSWER'), findsOneWidget, reason: 'the puzzle step');
  }

  for (final via in BackVia.values) {
    // The iOS swipe is there on iOS only.
    final TestVariant<Object?> platform =
        via == BackVia.iosEdgeSwipe ? TargetPlatformVariant.only(TargetPlatform.iOS) : const DefaultTestVariant();
    group(via.name, () {
      testWidgets('Map → GO → the mission → back → the map', variant: platform, (t) async {
        await start(t);
        await goToMission(t);
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('the look round → back → the mission (the place) → back → the map', variant: platform, (t) async {
        await start(t);
        await goToMission(t);
        await investigate(t);
        await back(t, via);
        expect(path(), Routes.mission('m01'));
        await reveal(t, find.text('INVESTIGATE'));
        expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'look round → the place');
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });

      testWidgets('the posters → back → the look round, the letter still read → the place → the map', variant: platform, (t) async {
        await start(t);
        await goToMission(t);
        await investigate(t);
        await openLetterAndSolve(t);
        await back(t, via);
        expect(find.text('CHECK ANSWER'), findsNothing, reason: 'the posters closed first');
        expect(lookRound(), findsOneWidget, reason: 'posters → the look round');
        expect(find.text('Letter'), findsOneWidget, reason: 'the letter is still read');
        await back(t, via);
        await reveal(t, find.text('INVESTIGATE'));
        expect(find.text('INVESTIGATE'), findsOneWidget, reason: 'look round → the place');
        await back(t, via);
        expectMapBack(t);
        await wait(t, const Duration(seconds: 3));
      });
    });
  }

  // The map pushes the final: back pops it, so OPEN THE FINAL CASE opens it
  // again at once (going to the map instead left that button dead).
  for (final via in [BackVia.appBar, BackVia.systemBack, BackVia.backGesture]) {
    testWidgets('${via.name}: map → the final → back → the map → the final again', (t) async {
      await start(t, completed: [for (final m in MockEpisodeRepository.bundled().first.missions) m.id]);
      for (var i = 0; i < 2; i++) {
        await tapText(t, 'OPEN THE FINAL CASE', after: goToTime);
        expect(path(), Routes.finalMission, reason: 'entry ${i + 1}');
        await back(t, via);
        expect(path(), Routes.map);
        expect(t.widget<FadeTransition>(find.byKey(const ValueKey('map-page'))).opacity.value, 1, reason: 'the map is visible again');
      }
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('a returning detective (straight to the puzzle) also walks back to the map', (t) async {
    await start(t);
    await goToMission(t);
    await investigate(t);
    await openLetterAndSolve(t); // the puzzle is now started: next time it opens on the look round
    for (var i = 0; i < 3; i++) {
      await back(t, BackVia.backGesture); // posters → look round → place → map
    }
    expectMapBack(t);
    await goToMission(t);
    expect(lookRound(), findsOneWidget, reason: 'reopens on the look round');
    for (var i = 0; i < 2; i++) {
      await back(t, BackVia.backGesture); // look round → place → map
    }
    expectMapBack(t);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a mission with nothing under it still goes back to its map', (t) async {
    await start(t, at: Routes.mission('m01'));
    expect(path(), Routes.mission('m01'));
    expect(appRef.read(routerProvider).canPop(), isFalse, reason: 'the mission is the only page');
    await back(t, BackVia.backGesture);
    expect(path(), Routes.map);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('pressing back many times never closes the app: the map asks first', (t) async {
    await start(t);
    await goToMission(t);
    await investigate(t);
    await openLetterAndSolve(t);
    for (var i = 0; i < 3; i++) {
      await back(t, BackVia.backGesture); // posters → look round → place → map
    }
    expectMapBack(t);
    await back(t, BackVia.backGesture);
    expect(find.text('Leave the case?'), findsOneWidget, reason: 'on the map, back asks');
    await back(t, BackVia.backGesture); // closes the question
    expect(find.text('Leave the case?'), findsNothing);
    expect(path(), Routes.map);
    expect(handlesBack.last, isTrue, reason: 'the game still owns back');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('back on the map asks before leaving the case', (t) async {
    await start(t);
    await back(t, BackVia.systemBack);
    expect(find.text('Leave the case?'), findsOneWidget);
    await tapText(t, 'Keep investigating', after: const Duration(milliseconds: 600));
    expect(path(), Routes.map, reason: 'stay on the case');

    await back(t, BackVia.systemBack);
    await tapText(t, 'TITLE SCREEN', after: const Duration(milliseconds: 800));
    expect(path(), Routes.start);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('back on the story intro returns to the case files', (t) async {
    await start(t, introSeen: false, at: Routes.intro);
    expect(path(), Routes.intro);
    await back(t, BackVia.systemBack);
    expect(path(), Routes.episodes);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets("the story intro's own back arrow returns to the case files", (t) async {
    await start(t, introSeen: false, at: Routes.intro);
    final arrow = find.byKey(const ValueKey('intro-back'));
    final size = t.getSize(arrow);
    expect(size.width >= 44 && size.height >= 44, isTrue, reason: 'a comfortable touch target ($size)');
    expect(find.byTooltip('Back to case files'), findsOneWidget, reason: 'named for VoiceOver');
    expect(t.getRect(arrow).top, greaterThanOrEqualTo(0));
    await t.tap(arrow);
    await wait(t, const Duration(milliseconds: 800));
    expect(path(), Routes.episodes);
    expect(appRef.read(gameControllerProvider).introSeen, isFalse, reason: 'the case has not begun');
    await wait(t, const Duration(seconds: 3));
  });

  group('iOS edge swipe', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    testWidgets('on the story intro: back to the case files', variant: ios, (t) async {
      await start(t, introSeen: false, at: Routes.intro);
      await back(t, BackVia.iosEdgeSwipe);
      expect(path(), Routes.episodes);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('on the map: asks before leaving the case, as Android back does', variant: ios, (t) async {
      await start(t);
      await back(t, BackVia.iosEdgeSwipe);
      expect(find.text('Leave the case?'), findsOneWidget);
      await tapText(t, 'Keep investigating', after: const Duration(milliseconds: 600));
      expect(path(), Routes.map, reason: 'stay on the case');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('only from the edge, only far enough: a short or inner swipe does nothing', variant: ios, (t) async {
      await start(t, introSeen: false, at: Routes.intro);
      // Begun 30 points in: a drag on the page, not the back swipe.
      await t.timedDragFrom(const Offset(30, 600), const Offset(160, 0), const Duration(milliseconds: 250));
      await wait(t, const Duration(milliseconds: 800));
      expect(path(), Routes.intro);
      // From the edge, but let go short of the commit distance.
      await t.timedDragFrom(_swipeFrom, const Offset(30, 0), const Duration(milliseconds: 250));
      await wait(t, const Duration(milliseconds: 800));
      expect(path(), Routes.intro);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the World Map: swiping from the edge drags the map, never leaves it', variant: ios, (t) async {
      await start(t, at: Routes.worldMap);
      expect(path(), Routes.worldMap);
      final viewer = find.byKey(const ValueKey('world-map-viewer'));
      final before = t.widget<InteractiveViewer>(viewer).transformationController!.value.clone();
      await t.timedDragFrom(const Offset(4, 300), const Offset(160, 0), const Duration(milliseconds: 250));
      await wait(t, const Duration(milliseconds: 800));
      expect(path(), Routes.worldMap, reason: 'the map keeps its drag');
      expect(t.widget<InteractiveViewer>(viewer).transformationController!.value, isNot(before), reason: 'the map moved');
      await wait(t, const Duration(seconds: 3));
    });
  });

  testWidgets('Android: an edge swipe is only a drag (back stays the system back)', (t) async {
    await start(t, introSeen: false, at: Routes.intro);
    await t.timedDragFrom(_swipeFrom, const Offset(160, 0), const Duration(milliseconds: 250));
    await wait(t, const Duration(milliseconds: 800));
    expect(path(), Routes.intro);
    await back(t, BackVia.systemBack);
    expect(path(), Routes.episodes);
    await wait(t, const Duration(seconds: 3));
  });
}
