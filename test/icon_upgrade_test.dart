import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:world_mystery/data/content/difficulty_content.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/coin_balance.dart';
import 'package:world_mystery/widgets/evidence_card.dart';
import 'package:world_mystery/widgets/ink_icon.dart';
import 'package:world_mystery/widgets/symbol_icon.dart';

import 'helpers.dart';

/// The icon upgrade (docs/WORLD_MYSTERY_ICON_UPGRADE_PROGRESS.md): every
/// piece of evidence of the four seasons is shown as a picture — its own,
/// its case's drawing, or its paper with its words — never only an ink line;
/// the clue and lock stamps, the coin and the Archive's seal are pictures
/// with their ink glyph kept as the fallback.

final cases = MockEpisodeRepository.bundled();
final evidence = {for (final e in cases) for (final v in e.allEvidence) v.id: v};

/// What shows evidence [id]: its picture, its case's drawing or its paper.
String? shownBy(String id) => ArtAssets.evidencePictures.containsKey(id)
    ? 'picture'
    : SeasonCatalog.evidenceArt(id) != null
    ? 'drawn'
    : ArtAssets.evidenceDocs.containsKey(id)
    ? 'paper'
    : null;

(int, int) pngSize(String path) {
  final b = File(path).readAsBytesSync();
  int u32(int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  return (u32(16), u32(20));
}

void main() {
  group('every piece of evidence is a picture', () {
    test('the 194 of the four seasons, at every level: none left as an ink line', () {
      expect(evidence, hasLength(194));
      for (final s in ['ep', 's2_', 's3_', 's4_']) {
        expect(evidence.keys.where((id) => s == 'ep' ? !id.startsWith('s') : id.startsWith(s)), hasLength(s == 'ep' ? 50 : 48), reason: s);
      }
      for (final level in Difficulty.values) {
        for (final c in cases) {
          for (final e in DifficultyContent.episodeAt(c, level).allEvidence) {
            expect(shownBy(e.id), isNotNull, reason: '${e.id} ${e.name} at ${level.name}');
          }
        }
      }
      final by = <String, int>{};
      for (final id in evidence.keys) {
        by.update(shownBy(id)!, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(by, {'picture': 77, 'drawn': 33, 'paper': 84});
    });

    test('each is registered once, under a real evidence id', () {
      for (final id in [...ArtAssets.evidencePictures.keys, ...ArtAssets.evidenceDocs.keys]) {
        expect(evidence, contains(id), reason: id);
      }
      for (final id in ArtAssets.evidenceDocs.keys) {
        expect(ArtAssets.evidencePictures, isNot(contains(id)), reason: '$id: a picture and a paper');
        expect(SeasonCatalog.evidenceArt(id), isNull, reason: '$id: drawn by its case and a paper');
      }
    });

    test('a picture never tells what its words (or a later puzzle) ask', () {
      // The Star Print: Case 07 asks which sole made it, its answer the
      // picture of that sole: the print is the notebook's words.
      expect(ArtAssets.evidencePictures['s4_ep02_e1'], isNull);
      expect(ArtAssets.evidenceDocs['s4_ep02_e1'], EvidencePaper.statement);
      final sole = 'assets/seasons/season_04_newyork/objects/star_sole.png';
      expect(ArtAssets.evidencePictures.entries.where((e) => e.value == sole).map((e) => e.key), ['s4_ep07_e1']);
      // Words that are clues stay words: the map's swans, the map pieces'
      // ravens, the board's train, the mirror word, the chalk code, the stub.
      for (final id in ['e04', 'ep05_e4', 'ep07_e1', 'ep07_e2', 'ep07_e3', 'ep07_e4', 'ep12_e2', 's3_ep06_e3', 's3_ep07_e2', 's4_ep01_e4']) {
        expect(ArtAssets.evidenceDocs[id], isNotNull, reason: id);
      }
      // Paris's blank puzzle papers are never shown as the evidence.
      for (final id in ['s2_ep02_e4', 's2_ep03_e1', 's2_ep03_e2']) {
        expect(ArtAssets.evidencePictures[id], isNull, reason: id);
      }
      // The Wet Footprint: the search's own footprint, cut out of its black.
      expect(ArtAssets.evidencePictures['ep03_e3'], 'assets/seasons/season_01_london/objects/wet_footprint_cutout.png');
      final cut = img.decodePng(File(ArtAssets.evidencePictures['ep03_e3']!).readAsBytesSync())!;
      expect(cut.getPixel(0, 0).a, 0, reason: 'no black ground in the round frame');
      expect(cut.width, cut.height);
    });
  });

  group('the files', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    void bundled(String path) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(path, endsWith('.png'));
      expect(pubspec, contains('- ${path.substring(0, path.lastIndexOf('/') + 1)}'), reason: path);
    }

    test('every picture is on disk and bundled', () {
      for (final f in {
        ...ArtAssets.evidencePictures.values,
        for (final p in ArtAssets.evidencePapers.values) p.file,
        ...ArtAssets.symbols.values,
        ArtAssets.coin,
        ArtAssets.archiveSeal,
      }) {
        bundled(f);
      }
      expect(ArtAssets.evidencePapers.keys, containsAll(EvidencePaper.values));
    });

    test("a paper's shape is its file's, its words inside it", () {
      for (final MapEntry(key: kind, value: p) in ArtAssets.evidencePapers.entries) {
        final (w, h) = pngSize(p.file);
        expect(p.aspect, closeTo(w / h, 0.01), reason: kind.name);
        final r = p.writing;
        expect(r.left >= 0 && r.top >= 0 && r.right <= 1 && r.bottom <= 1 && r.width > 0.4 && r.height > 0.5, isTrue, reason: kind.name);
      }
    });

    test('every symbol the seasons use has its one-colour stamp, tinted by the game', () {
      final used = {
        for (final c in cases)
          for (final m in c.allMissions) ...[?m.clue?.symbol, ?m.evidence?.icon, ...m.dialSymbols, ...?m.evidence?.symbols],
      };
      expect(ArtAssets.symbols.keys, containsAll(used));
      for (final k in used) {
        expect(GameSymbol.of(k).asset, ArtAssets.symbols[k], reason: k);
      }
      for (final f in ArtAssets.symbols.values) {
        final p = img.decodePng(File(f).readAsBytesSync())!;
        expect((p.width, p.height), (256, 256), reason: f);
        expect(p.every((c) => c.a == 0 || (c.r == 0 && c.g == 0 && c.b == 0)), isTrue, reason: '$f: ink only');
      }
      // The Royal Box's four locks keep their full-colour pictures.
      expect(ArtAssets.symbols.values.toSet().intersection(ArtAssets.royalBoxLocks.values.toSet()), isEmpty);
    });
  });

  group('on screen', () {
    Future<void> zoom(WidgetTester t, Evidence e, {Size size = const Size(320, 568), double textScale = 1}) async {
      t.view.physicalSize = size * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(child: TextButton(onPressed: () => showEvidenceZoom(context, e), child: const Text('open'))),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('EVIDENCE'), findsOneWidget, reason: 'the close look is open');
    }

    for (final level in Difficulty.values) {
      testWidgets('a document at ${level.name}: its words on its paper, once, on a small phone at 1.3× text', (t) async {
        final base = cases.firstWhere((c) => c.id == 'ep02');
        final e = DifficultyContent.episodeAt(base, level).allEvidence.firstWhere((v) => v.id == 'ep02_e1');
        await zoom(t, e, textScale: 1.3);
        expect(t.takeException(), isNull, reason: 'no overflow');
        final paper = find.byKey(const ValueKey('evidence-paper-ep02_e1'));
        expect(paper, findsOneWidget);
        final words = e.inscription ?? e.description;
        // (Glossary words are set as rich text, a looked-up word marked for
        // screen readers: its words, in order.)
        final line = find.textContaining(
          RegExp(words.split(RegExp(r'\s+')).map(RegExp.escape).join(r'.*'), dotAll: true),
          findRichText: true,
        );
        expect(find.descendant(of: paper, matching: line), findsWidgets);
        expect(
          line.evaluate().where((e) => find.descendant(of: paper, matching: find.byWidget(e.widget)).evaluate().isEmpty),
          isEmpty,
          reason: 'not again under the paper',
        );
        expect(find.text(e.name), findsOneWidget);
      });
    }

    testWidgets('the longest words fit their paper', (t) async {
      final longest = (ArtAssets.evidenceDocs.keys.map((id) => evidence[id]!).toList()
            ..sort((a, b) => (b.inscription ?? '').length.compareTo((a.inscription ?? '').length)))
          .first;
      await zoom(t, longest, textScale: 1.3);
      expect(t.takeException(), isNull);
      expect(find.byKey(ValueKey('evidence-paper-${longest.id}')), findsOneWidget);
    });

    testWidgets('a tile shows the paper without its words, and a made picture as itself', (t) async {
      Future<void> tile(Evidence e) async {
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(home: Center(child: SizedBox(width: 160, height: 190, child: EvidenceTile(evidence: e)))),
        ));
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.pump();
      }

      await tile(evidence['ep02_e1']!);
      expect(find.byType(EvidencePaperView), findsOneWidget);
      expect(find.textContaining(evidence['ep02_e1']!.inscription!), findsNothing, reason: 'read in the close look');
      expect(find.bySemanticsLabel('${evidence['ep02_e1']!.name}. Tap to look closer.'), findsOneWidget);

      await tile(evidence['ep03_e2']!);
      final image = t.widget<Image>(find.byWidgetPredicate((w) => w is Image && w.image is ResizeImage));
      expect(((image.image as ResizeImage).imageProvider as AssetImage).assetName, 'assets/seasons/season_01_london/objects/blue_cloth.png');
      expect(find.byWidgetPredicate((w) => w is InkIcon && w.glyph == InkGlyph.cloth), findsNothing);
    });

    testWidgets('the coin and a clue stamp are pictures; a missing file keeps the ink', (t) async {
      await t.pumpWidget(const MaterialApp(home: Row(children: [GameCoin(size: 20), SymbolBadge('footprint', size: 32)])));
      final assets = find.byType(Image).evaluate().map((e) => ((e.widget as Image).image as dynamic)).map((p) => p is ResizeImage ? (p.imageProvider as AssetImage).assetName : (p as AssetImage).assetName);
      expect(assets, containsAll([ArtAssets.coin, ArtAssets.symbols['footprint']]));
      await t.pumpWidget(const MaterialApp(home: Center(child: InkMark(glyph: InkGlyph.cloth, monogram: 'C', size: 32, asset: 'assets/missing.png'))));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      expect(find.byType(InkIcon), findsOneWidget);
    });
  });

  test('the evidence board and the street book show the evidence, not its stamp', () {
    for (final f in ['lib/features/mission/widgets/evidence_board.dart', 'lib/features/mission/widgets/street_book.dart']) {
      final s = File(f).readAsStringSync();
      expect(s, contains('EvidenceThumb(evidence: evidence'), reason: f);
      expect(s, isNot(contains('SymbolBadge(evidence.icon')), reason: f);
    }
  });
}
