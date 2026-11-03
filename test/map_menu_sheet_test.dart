import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/theme/app_colors.dart';
import 'package:world_mystery/data/models/detective_name.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/mission_map/mission_map_screen.dart';
import 'package:world_mystery/features/game/scoring.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/coin_balance.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// The map's menu: a page of the casebook over the map — same content,
/// order and actions; closes by swipe, a tap outside or back.
void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('map menu $tag: paper page, same items, closes three ways, items still go where they went', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: WorldMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final router = ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first).read(routerProvider);
      router.go(Routes.map);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 1200));

      Future<void> open() async {
        await t.tap(find.byTooltip('Menu'));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('Detective MINYOUNG'), findsOneWidget);
      }

      await open();
      expect(t.takeException(), isNull);
      // The paper of the case files, nearly square corners, no grey handle.
      final sheet = t.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, AppColors.paper);
      expect((sheet.shape! as RoundedRectangleBorder).borderRadius, const BorderRadius.vertical(top: Radius.circular(4)));
      expect(sheet.showDragHandle, isFalse);
      // Same content, same order.
      final labels = ['The Missing Crown', 'Detective MINYOUNG', 'Detective Notebook', 'Case Files', 'World Map', 'My Detective Profile', 'Sound Effects', 'How to Play'];
      final tops = [for (final l in labels) t.getRect(find.descendant(of: find.byType(BottomSheet), matching: find.text(l))).top];
      expect(tops, [...tops]..sort(), reason: 'in the same order');
      // The sound switch still switches.
      final before = t.widget<Switch>(find.byType(Switch)).value;
      await t.tap(find.text('Sound Effects'));
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<Switch>(find.byType(Switch)).value, !before);
      await capture(t, 'map_menu_$tag');

      // Closes: a tap outside, back, and a swipe down.
      await t.tapAt(const Offset(20, 20));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'tap outside');
      await open();
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'back');
      await open();
      await t.drag(find.text('Detective MINYOUNG'), const Offset(0, 500));
      await wait(t, const Duration(milliseconds: 600));
      expect(find.byType(BottomSheet), findsNothing, reason: 'swipe down');

      // The notebook opens over the map (pushed, as before).
      await open();
      await t.tap(find.text('Detective Notebook'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('DETECTIVE NOTEBOOK'), findsOneWidget);

      // Where each other item goes, as before.
      for (final (label, path) in const [
        ('Case Files', Routes.episodes),
        ('My Detective Profile', Routes.detective),
        ('World Map', Routes.worldMap),
      ]) {
        router.go(Routes.map);
        await wait(t, const Duration(milliseconds: 1200));
        await open();
        await t.tap(find.text(label));
        await wait(t, const Duration(milliseconds: 1200));
        expect(router.routerDelegate.currentConfiguration.last.matchedLocation, path, reason: label);
      }
      await wait(t, const Duration(seconds: 3));
    });
  }

  group('the menu', () {
    late ProviderContainer app;
    /// The page on top (a page pushed over the map included).
    String path() => app.read(routerProvider).routerDelegate.currentConfiguration.last.matchedLocation;
    final sheet = find.byType(BottomSheet);
    Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);

    Future<void> pumpMap(WidgetTester t, {DetectiveAvatar? avatar}) async {
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
        }),
        child: const WorldMysteryApp(),
      ));
      await wait(t, const Duration(milliseconds: 300));
      app = ProviderScope.containerOf(find.byType(WorldMysteryApp).evaluate().first);
      if (avatar != null) await t.runAsync(() => app.read(detectiveProfileProvider.notifier).setAvatar(avatar));
      app.read(routerProvider).go(Routes.map);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await wait(t, const Duration(milliseconds: 1200));
    }

    Future<void> open(WidgetTester t) async {
      await t.tap(find.byTooltip('Menu'));
      await wait(t, const Duration(milliseconds: 600));
      expect(sheet, findsOneWidget);
    }

    String? portraitAsset(WidgetTester t) {
      final image = inSheet(find.descendant(of: find.byKey(const ValueKey('menu-portrait')), matching: find.byType(Image)));
      if (image.evaluate().isEmpty) return null;
      return (t.widget<Image>(image).image as AssetImage).assetName;
    }

    testWidgets('six items, the profile renamed, the season board and archive gone', (t) async {
      await pumpMap(t);
      await open(t);
      expect(inSheet(find.byType(ListTile)), findsNWidgets(6));
      for (final gone in ['Season board', 'World Archive', 'My detective', 'Case results']) {
        expect(inSheet(find.text(gone)), findsNothing, reason: gone);
      }
      expect(inSheet(find.text('My Detective Profile')), findsOneWidget);
      // The settings under their own rule, below the four places.
      expect(t.getRect(inSheet(find.text('Sound Effects'))).top, greaterThan(t.getRect(inSheet(find.text('My Detective Profile'))).top));
      expect(t.getRect(inSheet(find.text('How to Play'))).top, greaterThan(t.getRect(inSheet(find.text('Sound Effects'))).top));
      for (final tile in inSheet(find.byType(ListTile)).evaluate()) {
        expect(t.getSize(find.byWidget(tile.widget)).height, greaterThanOrEqualTo(48));
      }
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the saved picture in the corner, never over the name; a tap opens the profile', (t) async {
      await pumpMap(t, avatar: DetectiveAvatar.boy);
      await open(t);
      expect(portraitAsset(t), ArtAssets.avatarBoy);
      final portrait = t.getRect(find.byKey(const ValueKey('menu-portrait')));
      expect(portrait.size, const Size(80, 80));
      // The picture alone on the paper: no frame, card or shadow around it.
      final frame = find.descendant(of: find.byKey(const ValueKey('menu-portrait')), matching: find.byWidgetPredicate((w) => w is Container || w is DecoratedBox || w is Material));
      expect(frame, findsNothing);
      // Whole, at its own shape (contain), as tall as the space.
      final img = t.widget<Image>(inSheet(find.descendant(of: find.byKey(const ValueKey('menu-portrait')), matching: find.byType(Image))));
      expect(img.fit, BoxFit.contain);
      expect(t.getRect(inSheet(find.text('Detective MINYOUNG'))).right, lessThanOrEqualTo(portrait.left));
      final semantics = t.ensureSemantics();
      expect(find.bySemanticsLabel('My Detective Profile'), findsWidgets);
      semantics.dispose();

      await t.tap(find.byKey(const ValueKey('menu-portrait')));
      await wait(t, const Duration(milliseconds: 1200));
      expect(path(), Routes.detective);
      expect(sheet, findsNothing);
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 1200));
      expect(path(), Routes.map);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('XP and the wallet\'s coins on one line, no play time; a new balance the next time it opens', (t) async {
      await pumpMap(t);
      final xp = XpBreakdown.totalFor(app.read(currentEpisodeProvider), app.read(gameControllerProvider));
      final coins = app.read(walletProvider).balance;
      await open(t);
      expect(inSheet(find.text('$xp XP')), findsOneWidget);
      expect(inSheet(find.text('$coins Coins')), findsOneWidget);
      expect(inSheet(find.byType(GameCoin)), findsOneWidget);
      expect(inSheet(find.textContaining(RegExp(r'\d+:\d\d'))), findsNothing, reason: 'no play time');
      expect(t.getRect(inSheet(find.text('$xp XP'))).center.dy, closeTo(t.getRect(inSheet(find.text('$coins Coins'))).center.dy, 2));
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 600));

      app.read(walletProvider.notifier).rewardCompletedAd('menu-test');
      await open(t);
      expect(inSheet(find.text('${coins + 30} Coins')), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('the rule under the status is the settings\' rule: same ink, same margins', (t) async {
      await pumpMap(t);
      await open(t);
      final rules = t.widgetList<Divider>(inSheet(find.byType(Divider))).toList();
      expect(rules, hasLength(2));
      for (final r in rules) {
        expect((r.color, r.indent, r.endIndent, r.thickness, r.height), (rules.last.color, rules.last.indent, rules.last.endIndent, rules.last.thickness, rules.last.height));
      }
      expect(rules.first.indent, greaterThan(0));
      final sheetRect = t.getRect(sheet);
      final top = t.getRect(inSheet(find.byType(Divider)).first);
      expect(top.width, sheetRect.width, reason: 'the box spans the sheet; the line is inset by indent');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a small phone, a long name, large text: nothing overflows or overlaps', (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpMap(t, avatar: DetectiveAvatar.girl);
      t.view.physicalSize = const Size(320, 568) * 3;
      // The longest name the form takes, in wide letters.
      final longest = 'W' * DetectiveName.maxLength;
      expect(app.read(gameControllerProvider.notifier).renameDetective(longest), isNull);
      await wait(t, const Duration(milliseconds: 600));
      await open(t);
      expect(t.takeException(), isNull);
      final name = t.getRect(inSheet(find.textContaining('WWW')));
      final portrait = t.getRect(find.byKey(const ValueKey('menu-portrait')));
      expect(name.right, lessThanOrEqualTo(portrait.left));
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('no picture chosen: the cap in ink, still a way to the profile', (t) async {
      await pumpMap(t);
      await open(t);
      expect(portraitAsset(t), isNull);
      expect(inSheet(find.byKey(const ValueKey('menu-portrait'))), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a new picture saved in the profile is the one in the menu next time', (t) async {
      await pumpMap(t, avatar: DetectiveAvatar.boy);
      await open(t);
      await t.tap(inSheet(find.text('My Detective Profile')));
      await wait(t, const Duration(milliseconds: 1200));
      final semantics = t.ensureSemantics();
      await t.tap(find.bySemanticsLabel('girl detective'));
      semantics.dispose();
      await wait(t, const Duration(milliseconds: 400));
      await t.ensureVisible(find.text('SAVE CHANGES'));
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(find.text('SAVE CHANGES'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(path(), Routes.map);
      await open(t);
      expect(portraitAsset(t), ArtAssets.avatarGirl);
      await wait(t, const Duration(seconds: 3));
    });

    for (final (label, page, title, backTip) in const [
      ('Case Files', Routes.episodes, 'CASE FILES', 'Back'),
      ('My Detective Profile', Routes.detective, null, 'Back'),
      ('Detective Notebook', Routes.notebook, 'DETECTIVE NOTEBOOK', 'Close'),
    ]) {
      for (final viaButton in [true, false]) {
        testWidgets('Map → menu → $label → ${viaButton ? 'its back arrow' : 'system back'} → the map, as it was', (t) async {
          await pumpMap(t);
          final progress = app.read(gameControllerProvider);
          await open(t);
          await t.tap(inSheet(find.text(label)));
          await wait(t, const Duration(milliseconds: 1500));
          expect(path(), page);
          expect(sheet, findsNothing);
          if (title != null) expect(find.text(title), findsOneWidget);
          if (viaButton) {
            await t.tap(find.byTooltip(backTip).hitTestable().first);
          } else {
            await t.binding.handlePopRoute();
          }
          await wait(t, const Duration(milliseconds: 1500));
          expect(path(), Routes.map, reason: 'not the season board, not the World Map');
          expect(find.byType(MissionMapScreen), findsOneWidget);
          expect(app.read(gameControllerProvider), progress, reason: 'the case as it was');
          expect(app.read(routerProvider).canPop(), isFalse, reason: 'nothing left stacked under the map');
          await wait(t, const Duration(seconds: 3));
        });
      }
    }

    testWidgets('a double tap opens one page, not two', (t) async {
      await pumpMap(t);
      await open(t);
      await t.tap(inSheet(find.text('Case Files')));
      await t.tap(inSheet(find.text('Case Files')), warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 1500));
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 1500));
      expect(path(), Routes.map);
      expect(app.read(routerProvider).canPop(), isFalse);
      await wait(t, const Duration(seconds: 3));
    });
  });
}
