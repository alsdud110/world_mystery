# season_factory — a planned season carried into the game

The Rome integration. One command for the whole way from a season's plans
(`content_pipeline/seasons/<seasonId>/`) to the season in the app, made of
the tools that already do each part. Nothing here plans, draws, measures
or generates by itself; it calls them in order and stops where a person's
(or Claude's) eyes are needed. The Claude Code skill that drives it:
`.claude/skills/create-season/SKILL.md` ("시즌 4 뉴욕 제작해. 이미지 예산 $10").

```
plan_season.dart (plans, check)
  → asset_pipeline.dart (--doctor --fix, --generate, review, --apply)
  → measured on the made pictures (grid sheets, written into the plans)
  → case_levels.dart (each case's English at Junior and Master, checked)
  → generate_season.dart --target game (lib/data/generated/, registered)
  → flutter analyze, test/generated_seasons_test.dart
  → season pack: manifest written again, checked, compared with R2, staged (nothing sent)
  → upload --approved (only once the user approves): pictures first, manifest last, read back
```

| File | What |
|---|---|
| `season_factory.dart` | `status`, `run`, `reviewed`, `reject`, `packs`, `upload` |
| `sheets.dart` | review sheets (a batch of pictures, numbered) and grid sheets (a line every 50 px) |

```sh
dart run tool/season_factory/season_factory.dart status   content_pipeline/seasons/s4_newyork
dart run tool/season_factory/season_factory.dart run      content_pipeline/seasons/s4_newyork [--budget 10] [--batch 4] [--full-tests]
dart run tool/season_factory/season_factory.dart reviewed content_pipeline/seasons/s4_newyork ev_owl_card cover   # or --all
dart run tool/season_factory/season_factory.dart reject   content_pipeline/seasons/s4_newyork ev_business_card --why "a bird, not a construction crane"
dart run tool/season_factory/season_factory.dart packs    content_pipeline/seasons/s4_newyork               # step 9 alone (after a pilot, or again)
dart run tool/season_factory/season_factory.dart upload   content_pipeline/seasons/s4_newyork [--approved]  # without it: what would be sent
```

A pilot case (one case, not a season: the Seoul pilot) is drawn with
`run <dir> --pictures-only`: its manifest's checks stand for step 1, every
picture its manifest plans is made (1b–4: the same history gate, budget and
review), only the ones a screen shows are applied (5), and the run ends.

## The steps of `run`

Each is done only when it is not done yet: run it again after any stop.

| # | Step | Stops with |
|---|---|---|
| 1 | Every plan check (`SeasonQuality`, the report written) | 10: an ERROR |
| 1b | A `historical_fiction_mystery` season only (`planning/brief.json` `mode`): its history dossier whole, every fact its puzzles and reveals rest on `source_checked`, its automatic checks passed (`HistoryGate`, `tool/season_gen/history_dossier.dart`). The asset pipeline holds the same gate before any API call | 15: fix the dossier until its checks pass |
| 2 | `--doctor --fix`: this machine's records against the game's files (below) | — |
| 3 | Pictures made here and not looked at: a review sheet | 20: look, then `reviewed` / `reject` |
| 4 | The next `--batch` pictures the game shows, within the budget | 20 (review); before any call 45 (no budget set), 41 (no API key), 40 (the pictures left pass the budget); 1 (API error) |
| 5 | `--apply`: validated pictures (the game's WebP, made by kind: `tool/asset_optimizer`) into `assets/`, manifest, `pubspec.yaml`; then the season's size in the app and the size report's warnings about it (diagnostics) | 1: a conflict |
| 6 | Anything not measured on the made pictures: a grid sheet | 30: measure, write into the plans |
| 6b | Every case's `levels.json` (Junior and Master English of each Rookie line; the same game) written and checked (`case_levels.dart check`, a level copied from Rookie refused); a skeleton written for missing lines, the lines written kept | 35: Claude writes the levels (create-season § Levels), reads `case_levels.dart review`, runs again |
| 7 | (a historical season: every reveal approved and every puzzle's reasoning reviewed by a person first, else 15) `generate_season.dart --target game` (content, art, the game's lists) | 50: generator errors |
| 8 | `flutter analyze`, `flutter test test/generated_seasons_test.dart` (`--full-tests`: all) | 60: a failure |
| 9 | The season pack (`tool/season_packs/deploy.dart`): `lib/core/assets/season_pack_manifests.g.dart` written again from the pictures on disk when they changed; this season's pack checked (each picture readable, at its size and SHA-256), compared with what the bucket holds (HEAD over HTTPS, read-only), its new objects staged in `build/season_packs/<folder>/<version>/` with `upload_list.tsv` (pictures, then the manifest). London ships in the app: nothing staged. Nothing is sent. The state is `planning/factory.json` `deploy` (`staged`, `deployed`, `blocked`, `upload_failed`, `verify_failed`, `in_app`), kept apart from the season itself | 70: not ready for the bucket (the season stays in the game) |

**The bucket.** `upload <dir>` shows what would be sent; `upload <dir>
--approved`, only once the user approves, sends the stage with wrangler (its
login on this machine: no key in the repo), pictures first and the manifest
last, stops at the first failure (`upload_failed`: run it again, what was
sent is not sent twice), then reads every object back over HTTPS (200, size,
SHA-256) before `deployed`. Nothing in the bucket is ever removed: older
manifests and pictures stay for apps not yet updated. The app downloads only
the manifest version it was built with, so a season (or a changed picture)
reaches players with the next app update carrying `lib/data/generated/<seasonId>`
and `season_pack_manifests.g.dart`. The bucket URL (`deploy.dart`
`packPublicUrl`, the app's `SeasonPackSetup.defaultUrl`) is the development
r2.dev one: replace both with the custom domain before release. The asset
pipeline never lists a downloaded season's pictures in `pubspec.yaml` (only
its `cover/`; London whole). Paris has no season folder here (made by hand):
its pack goes through `tool/season_packs/stage_packs.dart`.

**The budget** is the season's (US dollars at list prices; the bill is
OpenAI's): `--budget`, else its line in `content_pipeline/image_budgets.json`
(image policy, 2026-11-04: pictures are made by default within it, no
question per picture; a season with no line stops once, exit 45, for the
user to approve one). Before any call the pictures still to make are priced
at their conservative cost (the dry run's): more than is left, exit 40. What the factory spent before is kept in
`planning/factory.json` (in Git, so every machine sees it) and taken off.
Each call is checked at its conservative cost before it is sent; the
pipeline's rules hold (no call without a budget, an API error stops the run,
a picture made is never made again, never over a file).

**The pictures the game shows** (step 4): every one a case shows (places,
choices, faces), the cover, the map and each evidence picture. Not one no
screen shows (`not_supported` in the wiring), nor a story scene the
generator has no table for.

**Review** (step 3) is a look, never a verdict of the tool's: a picture is
`reviewed` only once someone has looked at it. `reject` sets the picture
aside (`asset_work/<id>/superseded/`, never deleted, with its record and
why) so the next run makes it again from its fixed prompt.

**Measuring** (step 6): the season map's landmarks (`art.map`, each
location's drawing centre, `measuredOn`) and every look round's areas
(`play.explore`, `picture.measuredOn`, no `UNMEASURED` note) are read off a
grid sheet of the very file and written into the plans. Nothing is guessed:
what cannot be seen on the picture means a new picture.

## Two machines

`content_pipeline/asset_work/` (the API's pictures and their records) is not
in Git; the game's copies in `assets/` are. On a machine that did not make a
picture (or whose work folder was lost or is older):

- a picture already in `assets/` is never made again here (`in game`);
- `--doctor --fix` records it as made, its picture a copy of the game's
  (`adopted`), and puts back a missing picture whose game copy has its
  recorded sha256 (`restored`);
- a picture here that differs from the game's is a `CONFLICT`, left as it
  is; a picture the manifest says is in the game but is not refuses every
  run (`asset_file_missing`): restore it from Git or a backup.

Nothing is synced to the cloud: back the work folder up yourself
(`~/world_mystery_backups/`).

## What stays a person's

- Approvals (`tool/season_gen/approve.dart`): a season in the game made
  from drafts says so in its manifest (`approved: false`).
- Looking at the pictures and measuring on them (Claude does both by
  reading the sheets; the tool never decides).
- A real device: the tests run in Flutter's test binding and on an emulator.
