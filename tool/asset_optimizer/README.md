# asset_optimizer — the game's pictures as WebP, by kind

The game ships its pictures as WebP made from the PNGs the OpenAI Images API
draws. Plain Dart (`dart run`), `package:image` to decode and compare, and
Google's `cwebp` (libwebp) to encode: `package:image` reads WebP but cannot
write it. Nothing here calls an image API. The report of the first run:
`docs/WORLD_MYSTERY_ASSET_OPTIMIZATION.md`.

| File | What |
|---|---|
| `image_policy.json` | **The one policy**: each kind's cwebp ladder and quality gate, how a picture's kind is found, files kept as PNG, where originals go, the size warnings |
| `image_policy.dart` | `ImagePolicy`: the JSON read whole and checked |
| `image_file.dart` | `ImageFileCheck`: a PNG, WebP or JPEG read whole from its bytes (size, alpha, format) |
| `image_quality.dart` | `ImageQuality`: decode, PSNR (RGB premultiplied), SSIM (luma, 8×8), alpha difference, likeness |
| `webp_encoder.dart` | `CwebpEncoder`: finds and runs cwebp |
| `image_optimizer.dart` | `ImageOptimizer`: one PNG → the game's WebP (the ladder, every result read back and judged) |
| `optimize_assets.dart` | The game's existing PNGs → WebP; `--rewrite-refs`; `--verify`; `--restore` |
| `optimized_ledger.dart`, `optimized_assets.json` | Every picture made: its source PNG's sha256, its own, kind, setting, quality, encoder, policy version (in Git) |
| `asset_size_report.dart`, `size_baseline.json` | The bundle measured as `pubspec.yaml` lists it; growth over the baseline |
| `bundle_assets.dart` | What `pubspec.yaml` puts in the app (a folder entry: its own files only) |
| `compare_sheet.dart` | Original beside optimized, whole and its busiest part at 3×, for a person to look at |

Tests: `test/asset_optimizer/asset_optimizer_test.dart` (real cwebp where
installed, else those tests say so and skip; fake encoders for every failure
path), `test/asset_pipeline/asset_pipeline_test.dart` (the season pipeline),
`test/asset_bundle_decode_test.dart` (every bundled picture decoded by the
Flutter engine).

## cwebp

Found in order: `--cwebp <exe>`, `CWEBP`, the PATH, `~/.world_mystery/libwebp-*/bin/`
(the newest). Version 1.2 or later; the first run used **1.6.0**.

- Windows: unpack
  `https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.6.0-windows-x64.zip`
  into `%USERPROFILE%\.world_mystery\` (SHA-256 of that zip:
  `48886F506B21F62E4661F0F4CBFCA19800897C385128E8902542D29A950C93F1`).
- macOS: `brew install webp`.

The same input, settings and cwebp version give the same bytes; another
cwebp version may give other bytes (records keep the version).

## The policy (`image_policy.json`)

Each kind tries its **ladder** in order, then lossless WebP. A result is kept
when it reads back whole at the same size, its alpha equals the source's
exactly (`-alpha_q 100`), and it passes the kind's PSNR and SSIM. Lossless
must be exact. So a picture is never worse than its gate, and never fails:
at worst it is lossless.

| Kind | Ladder | Gate (PSNR / SSIM) | Found by |
|---|---|---|---|
| `scene` | q88, q92 (`-sharp_yuv`), near-lossless 60 | 30 / 0.975 | places, covers, maps, prologue, scenes |
| `character` | q90, q94, near-lossless 60 | 32 / 0.985 | portraits, the detective, How to Play |
| `ui` | q90, q94, near-lossless 60 | 32 / 0.985 | badges, pins, Royal Box symbols |
| `evidence` | q92, q95, near-lossless 60 | 35 / 0.99 | objects, a case's pictures |
| `document` | q94, near-lossless 60 | 37 / 0.993 | letters, papers, notices |
| `puzzle` | near-lossless 60 | 42 / 0.997 | `puzzleFiles`, twins, a manifest's `use: puzzle` object; **the default** for anything unknown |
| `glyph` | lossless only | exact | the one-colour stamps the game tints |
| `exact` | lossless only | exact | `exactFiles`: a picture cleared from another, equal to it pixel for pixel |

How a picture's kind is found: a season manifest's `type` and `use` first
(`manifestKinds`), else `exactFiles`, `puzzleFiles`, then the path rules
(`pathKinds`), else `defaultKind` (`puzzle`). Then **twins**: two pictures of
one folder, of one size and of a twin kind (`evidence`, `document`), alike at
0.8 or more (luma over grey, 128 px): variants a puzzle tells apart, both
`puzzle`. Near-lossless also moves alpha a little, so a transparent puzzle
picture ends lossless.

`maxEdge` (0 everywhere): the pictures keep their pixels. Coordinates are
measured on them (`measuredOn`, the scenes' areas); a smaller picture would
need them measured again.

Changing a ladder or a gate: raise `policyVersion`. A picture made before keeps
its record; to make one again, `--restore` it, then optimize it.

## Existing pictures

```sh
dart run tool/asset_optimizer/optimize_assets.dart                       # dry run: each PNG's kind and why
dart run tool/asset_optimizer/optimize_assets.dart --apply [--only <assets/…png>]... [--area season_05_tokyo]
dart run tool/asset_optimizer/optimize_assets.dart --rewrite-refs [--apply]   # paths in lib/, test/, plans, pubspec
dart run tool/asset_optimizer/optimize_assets.dart --verify
dart run tool/asset_optimizer/optimize_assets.dart --restore <assets/….webp>...
```

`--apply`, each PNG: the original copied to `content_pipeline/asset_originals/<path>`
(out of Git and of the app: back it up) and checked; optimized; written as
`<name>.webp.part`, read back, moved; the PNG removed; the record saved.
A failure leaves that PNG as it was. Run again: a picture done is skipped
(its record matches its file), one cut short (WebP written, PNG still there)
is finished without encoding, a WebP with no record is a `CONFLICT`, left.
A lossy file (WebP, JPEG) is never encoded again.

`--rewrite-refs`: a path is rewritten only when every PNG it can name became
WebP (`RefRewriter`); generated code is made again by its generator
(`generate_season.dart`), never edited. A line that names a source PNG on
purpose carries the words `source PNG` (in a comment) and is left. Read the
diff: a test's made-up path whose end looks like an asset's is the thing to
check.

Kept as PNG: `assets/branding/` (the native splash and icon tools read PNG);
the World Map is already a JPEG and is not encoded again.

## New seasons

The season pipeline does it (`tool/asset_pipeline/README.md`, "The game's
WebP"): the manifest's `outputPath` is a `.webp`; the API's PNG stays in
`asset_work/raw/`; `_validate` makes the WebP in `asset_work/game/` by the
manifest's kind; `--apply` copies it to `assets/`. No cwebp or no good
picture: the picture waits `generated` (never paid for again), nothing goes
to the game. `test/asset_optimizer` fails the suite if a bundled picture is a
PNG the optimizer has no record of.

## Size

```sh
dart run tool/asset_optimizer/asset_size_report.dart [--json out.json] [--write-baseline]
```

The bundle by area (shared, each season, audio, fonts), by format, the
largest files, PNGs left, originals or work files in the bundle, each area's
growth over `size_baseline.json` (a new season shows as a new area). The
warnings (`sizeWarnings`: bundle 200 MB, a season 60 MB, a season's growth
50 MB, a file 1200 KB) are diagnostics: the exit code is 0. Google Play's
limit is on the compressed download of the AAB: measure a release build.
