# Season play order vs. season ids

Since 2026-11-11 the seasons play in this order:

| Plays | Season id | Asset / R2 folder | City |
|---|---|---|---|
| 1 | `s1_london` | `season_01_london` | London |
| 2 | `s2_paris` | `season_02_paris` | Paris |
| 3 | `s5_seoul` | `season_05_seoul` | Seoul |
| 4 | `s3_rome` | `season_03_rome` | Rome |
| 5 | `s4_newyork` | `season_04_newyork` | New York |

## What decides the order

Only `number` in `content_pipeline/seasons/<id>/season.plan.json` (and its
`planning/brief.json`). `SeasonCatalog.all` sorts by it; everything the
player sees follows: the World Map label `SEASON 3 · SEOUL`, the archive
files, which season unlocks when the one before it is solved, the "next
season" hand-off at the end of a season, the level question asked between
seasons.

## What the id's digit means

Nothing but a name, from when the season was planned. The season id
(`s5_seoul`), its case ids (`s5_ep01` … `s5_ep12`), its asset folder, its
pack folder on R2 and its generated code (`lib/data/generated/s5_seoul/`)
all keep that digit for good. `plan_check.dart` derives case ids from the
id's digit, `AssetManifest.rootFor` the asset root; neither reads `number`.
Players never see these names.

## Why not rename

Renaming the three seasons to match their play order would have meant:
three seasons of plans, planning files and asset work, every generated file,
the hand-written references (`season_pack_bundle`, `art_assets`,
`season.dart`, `season5_*`, `world_cities`), `pubspec.yaml`, 67 test
files, moving the asset folders, and re-uploading about 214 MB to R2
(Rome 52, New York 55, Seoul 106; the bucket never deletes, so the old
copies would stay). The ids 3 and 5 swap, so it needs temporary names too.
The player would see exactly what they see now.

## Rules

- Never "fix" an id's digit to match `number`, and never read a season's
  place in play from its id.
- A new season takes the next free id digit (`s6_…`) and its own
  `number`; the two need not agree.
- Changing the order again is one `number` per season, a regenerate, and
  the tests that spell the order out (`multi_season_test`,
  `rome_integration_test`, `world_archive_test`, `paris_case12_test`,
  `difficulty_season_policy_test`, the catalog-order lists).
