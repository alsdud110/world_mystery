---
name: create-season
description: Make a whole new World Mystery season and put it in the game — plan it, draw its pictures within an image budget, check and measure them, generate it into lib/, register it (catalog, map, cover, World Map, unlock after the season before), play it through in tests, and report. Use when the user says things like "시즌 4 뉴욕 제작해", "시즌 4 뉴욕 제작해. 이미지 예산 $10", "create season 5 in Tokyo", or asks to finish/continue a season already planned so it can be played in the app.
---

# Create a season (plan → pictures → game)

The user gives a season number, a city and maybe an image budget. Carry the
season all the way into the game yourself; do not stop to ask for approval
between steps.

**Pictures are made by default** (image policy, 2026-11-04), historical and
standard seasons alike, with the existing OpenAI pipeline: no question per
picture. The season's budget is its line in `content_pipeline/image_budgets.json`
(US dollars). A budget the user gives in the request is approved: write it
there (`usd`, `approvedOn`, a `note`) before the first run. A season with no
line is asked about **once**, before any paid call (exit 45 gives the amount
needed). Within the budget, a picture that fails its checks or is rejected
at review is made again without asking.

Stop and report only for: the budget would be passed, no budget set (asked
once), a user's save could be lost, an existing season would have to change,
a historical season's checks failing (exit 15: no picture before HistoryGate
passes), a core error you cannot fix, or a missing or refused credential
(`OPENAI_API_KEY` in `.env`). Report every picture made and what the API
cost (`planning/factory.json` `spentUsd`, the work folder's `image_manifest.json`).

Read first: `CLAUDE.md` (§20 gameplay, §21 testing), `tool/season_factory/README.md`.
Rome (`content_pipeline/seasons/s3_rome/`) is the worked example of every file.

## 1. Plan (no API call)

If `content_pipeline/seasons/s<n>_<city>/` does not exist yet, follow the
`plan-season` skill (`tool/season_planner/PLAYBOOK.md`) to write the story
bible, season plan, twelve case plans and `assets.manifest.json`; then
`plan_season.dart format` and `check` until there is no ERROR. Besides what
plan-season writes, the game target needs (Rome's `season.plan.json`):

- every `places[]` entry with its `locId` (one of `locations[].locId`);
- a `cover` and a `map` asset in the manifest (Rome's prompts: the map is
  an illustrated bird's-eye map, every location drawn apart and roughly
  where it really is, **no names, no pins, no writing**);
- `art.worldCity` (`cityId`, `latitude`, `longitude`; `mapAt` only when the
  World Map artwork draws that city: London, Paris, Rome, Tokyo and Seoul
  are drawn, see `lib/features/world_map/world_cities.dart`).
- its opening, `prologue` (PLAYBOOK §1 "The opening"), and one `prologue`
  picture in the manifest (PLAYBOOK §3) — `plan_season.dart check` refuses
  a season without them. The factory makes that picture like the others
  and names it in `prologue.hero` itself once it is in the game; its
  Junior and Master lines come with the levels (exit 35). Never write
  `hero` by hand.

Before any picture: read each prompt against its mission. A choice's right
picture must differ from the wrong ones only by what the clue says (Rome's
helmets lost a torn strip only the right one showed); a mission's place
picture must never be its right answer (Rome Case 08 M1); a word with two
meanings is named plainly ("construction tower crane", not "crane").

## 2. Run the factory, again and again

Every manifest `outputPath` (and every plan file naming it) ends in `.webp`:
the pipeline keeps the API's PNG out of the app and makes the game's WebP
by the picture's kind (`tool/asset_optimizer/README.md`). That needs Google's
`cwebp` on this machine (`CWEBP`, the PATH, or `~/.world_mystery/libwebp-*/bin/`;
macOS `brew install webp`). Without it a made picture waits `WAITING …`
(`generated`, never paid for again) and the run exits 1: install cwebp, run again.

```sh
dart run tool/season_factory/season_factory.dart status <seasonDir>
dart run tool/season_factory/season_factory.dart run <seasonDir>   # budget from image_budgets.json (--budget <usd> overrides)
```

The manifest (`assets.manifest.json`) is written in step 1 with the plans
(plan-season, PLAYBOOK §3, the city's look as `seasonStyles`): there is no
other manifest generator, and `run` refuses a season without one
(`asset_manifest_missing`, exit 10). A season of only a few cases (not whole,
e.g. Season 5 Seoul, `content_pipeline/seasons/s5_seoul`, its Case 01 only)
is drawn with `run <dir> --pictures-only`: the same history gate, budget,
review and apply, then it stops (measure, `generate_season.dart --target
sandbox --out lib/data/season5/s5_seoul`, and its registration by hand in
`lib/data/season5/`).

`run` goes on from where it stopped; act on its exit code and run it again:

| exit | what to do |
|---|---|
| 10 | fix the plans (`plan_season.dart check <seasonDir>`) |
| 15 | a historical season (`mode: historical_fiction_mystery`): fix what the dossier's automatic checks report (sources, facts `source_checked`, puzzles linked, levels) and run again; no person's approval is asked |
| 20 | **open the review sheet PNG with the Read tool and look at every picture**: style like the season's others, faces as the character's other portraits, every clue the plans name visible, no text, choices fair, nothing giving an answer away. Then `season_factory.dart reviewed <seasonDir> <assetId>...` for the good ones, and for a bad one fix its prompt in `assets.manifest.json` and `season_factory.dart reject <seasonDir> <assetId> --why "<what was wrong>"`. Never mark a picture reviewed without looking at it. |
| 30 | open each grid sheet it names (Read tool), read the pixel positions off the grid and write them into the plans: the map's `art.map.landmarks` (each drawing's centre) with `measuredOn` = the sha256 it printed; a look round's `areas`, `mark`, `guideAt`, `opening` (every place's centre inside it), `picture.measuredOn`, and replace its `UNMEASURED` note with how it was measured. No two areas may overlap. If you cannot see a thing on the picture, do not guess: fix the prompt and reject the picture. |
| 35 | not a stop for the user: write the Junior and Master English yourself right away (§ Levels below, its steps), then run again |
| 40 | the pictures left would pass the budget (checked before any call, at the conservative cost): stop and report the amount it printed |
| 41 | no API key: stop and report (nothing sent) |
| 45 | no budget set for the season: ask the user once to approve the amount it printed; once approved, write it into `content_pipeline/image_budgets.json` and run again |
| 50 | read the generator's errors, fix the plans, run again |
| 60 | read the failing test, fix the cause (never weaken the test), run again |
| 1 | an API error or a copy problem: read it; retry once only when the cause is clear and fixed (a prompt the safety system refused: rewrite the part it names). Never loop. |
| 0 | the season is in the game and played through |

### Levels (Rookie / Junior / Master)

The levels are the English, never the game: all three play the very same
cases, missions, puzzles, choices (as many, in the same order), answers,
clues, evidence, pictures and rewards. The plans are written once, without
any level, and their English is Rookie's. Then each case's
`cases/<caseId>/levels.json` (the factory writes its skeleton) gives every
Rookie line again at Junior and at Master — never a new or replaced puzzle,
never a choice more or less.

- **Junior**: natural intermediate English, more varied words and
  sentences, hints moderately direct.
- **Master**: rich vocabulary, complex sentences, indirect hints — but never
  an answer's information left out or a reasoning step added.
- The same at every level: every fact and action, names (people, evidence,
  places, titles, ALL-CAPS labels), numbers, times, codes, the words a
  puzzle reads or the player types, `{detectiveName}`, a mission's short
  learning expressions (and its level sentences still hold them), a search's
  `reportLine` word for word inside its letter. Master still tells clearly
  how to play.
- The season's own lines (its `prologue`'s lines, and its `outro` and
  `finale`, shown when its last case is solved and on its completed board)
  are written the same way in `season.levels.json` beside
  `season.plan.json`, line for line.
- Harder words a level brings: `glossary.junior` / `glossary.master` (one
  lower-case word → Korean).
At exit 35 do this yourself, without asking (writing is not approving:
`approve.dart` and every other approval stay the user's):

1. The run printed each levels file still to write; the factory wrote its
   skeleton (every Rookie line; the lines already written kept). Write only
   the empty `junior` / `master` fields; never rewrite a line already
   written, a `rookie` line, or the plans. Read the case plan beside it for
   what each line is (a question, a choice, a hint, a clue, a letter).
2. Write each sentence again at its level — never copy Rookie's into it.
   Only a name, title, label, a short choice or the in-world writing a
   puzzle reads stays as it is. The check refuses a level that gives back
   more than half its sentences (six words or more) as Rookie's.
3. Twelve cases are a lot of English: a subagent for a few cases each, with
   these rules and the file paths; each writes and checks its own cases.
4. Check every case until it prints `ok` (the plan's own checks run on each
   level, every line written, answers and expressions kept, nothing but the
   words changed, not copied):
   `dart run tool/season_gen/case_levels.dart check --season <seasonDir>/season.plan.json`
   (no case given: every case of the season, found by the tool — no
   `cases/*` pattern, which PowerShell does not spread; one case: add its
   `case.plan.json` after it)
5. The checks hold an answer's words, not its meaning. Read
   `dart run tool/season_gen/case_levels.dart review <seasonDir>/season.plan.json`
   (every case; or one `case.plan.json`)
   (each mission's question, choices with the answer ✓, hints, clue,
   evidence, a line holding a typed answer — R / J / M one under another)
   for every case, and fix any line where Junior or Master would lead to
   another answer, leaves out what the answer needs, makes a wrong choice
   right, or gives the answer away more than Rookie does.
6. Run the factory again: it goes on from the levels step to generate.
   Stopped half way (a session ended)? `season_factory.dart status` lists
   the files still to write; the lines written are kept.

The generator makes `<caseId>_levels.g.dart` and `<seasonId>_levels.g.dart`
from them (`SeasonContent.casePatches`, `variants`, `writtenLevels`), and
`test/difficulty_content_test.dart` checks every level of every season is
the same game, every word written.

Cover framing (`art.cover.archiveLook`, `crop`, `push`): look at the cover
and set them so the city's landmarks, not the foreground, are framed
(Rome's: archiveLook `[0, 0.15]`, crop `[0.1, 0]`, push `[0, -0.1]`).

## 3. Finish

- The season pack (the factory's step 9, exit 0 or 70): report per season
  the pack's version, new pictures and bytes, and whether its manifest is
  new (`status` shows it). **Never upload without the user's approval**: ask,
  then `season_factory.dart upload <dir> --approved` (pictures first, the
  manifest last, read back over HTTPS). Exit 70 leaves the season in the
  game: report why and stop the deploy. Say in the report that the next app
  update must carry `lib/data/generated/<seasonId>` and
  `lib/core/assets/season_pack_manifests.g.dart`.

- `flutter analyze`, `flutter test test/generated_seasons_test.dart` (the
  factory runs both), then the whole `flutter test` (a new season is a
  release milestone, CLAUDE.md §21).
- `asset_pipeline.dart --manifest <manifest> --doctor`: everything as recorded.
- `dart run tool/asset_optimizer/asset_size_report.dart`: the new season's
  area and its growth over `size_baseline.json`, no unoptimized PNG, no work
  file in the bundle (the factory prints the season's lines after `--apply`);
  `flutter test test/asset_optimizer test/asset_bundle_decode_test.dart`.
  Once the season is accepted, `--write-baseline` (the next season is measured
  against it).
- Back up `content_pipeline/asset_work/<seasonId>/` (not in Git) to
  `~/world_mystery_backups/<seasonId>_asset_work_<date>/` and compare sha256.
- Write `planning/FACTORY_REPORT.md` (Korean) and report in Korean: pictures
  made, reused, rejected and why, their WebP settings and sizes (the state's
  `optimized` records), the season's MB in the app, calls and cost (usage and conservative),
  budget left, what was measured, tests run and their results, what was not
  checked (a real device), what is left.

Never: change London's or Paris's stories, reset or rename saves, add a game
engine or sound, overwrite a file in `assets/`, delete a picture (rejected
ones go to `superseded/`), approve plans on the user's behalf
(`approve.dart` is theirs), commit or push unless asked.
