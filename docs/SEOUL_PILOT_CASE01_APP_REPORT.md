# Seoul Pilot Case 01 — 앱 연결 보고 (2026-11-04)

서울 시범 Case 01 *The Missing Royal Letter* (1446)를 개발자 모드에서 직접 플레이할 수 있게 연결했다.
**이미지는 만들지 못했다** (아래 1·2절). 앱은 지금도 London·Paris에서 빌린 임시 그림으로 플레이된다.

## 1. 제작한 이미지 목록

**만든 이미지: 없음.**

- 이 저장소에 연결된 이미지 생성 경로는 `tool/ai_agents/openai_image.dart`(OpenAI Image API, 유료) 하나뿐이다. 무료이거나 미리 승인된 경로는 없다.
- 지시대로 유료 호출은 하지 않았다. 비용 추정용 dry run(전송 없음)도 이 세션의 자동 모드 권한 검사가 "Real-World Transactions"로 막았다. 그래서 **추정 비용도 직접 계산하지 않았다.**
- 대신 아래에 제작 목록과 프롬프트를 준비했다. 사용자가 터미널에서 dry run으로 비용을 먼저 확인한 뒤 `--generate`로 만들면 된다.

### 공통 스타일 문장 (제안: `seoul_scene`)

`ImageStyles`에는 아직 서울 스타일이 없다. 그래서 각 프롬프트 끝에 아래 문장을 그대로 붙인다(`--style` 생략).

> Storybook illustration for a children's detective mystery game (ages 8-12): warm, inviting and gently mysterious, never scary. No text, letters, numbers, signatures, watermarks or logos anywhere in the image. Style: hand-drawn ink line drawing with soft watercolour washes on warm cream mulberry paper, lightly stylised rather than photographic; deep navy night tones with warm lantern-gold light, muted Joseon red and pine-green accents used sparingly; clear architectural perspective; full-bleed composition with no border. Setting: Hanyang, Joseon Korea, 1446 — Joseon-era clothing, wooden palace architecture, paper doors, low floor desks and floor cushions only; no modern objects, no Western furniture or decoration; King Sejong never appears.

인물(6·7번)은 `--style character`(1024×1536, 양피지 배경)에 아래 설정 문장을 붙인다. Setting: Joseon Korea 1446, Joseon-era palace clothing, no text.

### 제작 목록

| # | 파일 (제안: `qa/seoul_pilot/`) | 크기 | 들어갈 곳 (지금 빌린 그림) | 초점 / 주의 |
|---|---|---|---|---|
| 1 | `palace_night.png` | 1536×1024 | 장소 `s7_seoulpilot.palace_yard`. 마지막 대면 장면의 장소 (London `kings_cross_platform_night`) | 궁궐 문과 지붕선을 가운데 60% 안에 둔다. 좌우는 잘려도 되는 마당 |
| 2 | `royal_archive.png` | 1536×1024 | 장소 `s7_seoulpilot.secretariat`, M1 (Paris `annex_reading_room`) | 문서함과 선반을 가운데에 둔다 |
| 3 | `gate_ledger.png` | 1536×1024 | M2 출입 장부 `records.first` (Paris `inspection_log`) | **빈 장부 면.** 글은 앱이 그린다. 세로 칸만 있고 글자는 없다 |
| 4 | `scholar_papers.png` | 1536×1024 | M2 비교 자료 `records.second` (Paris `inspection_log`) | 두 종이를 나란히, 글자 없이 둔다. 거친 종이와 고운 종이의 질감 차이만 보이게 한다 |
| 5 | `copy_room.png` | 1536×1024 | M3 필사실 `deductions` (Paris `workshop_interior`) | 붓함(뚜껑)과 바닥 돗자리에 빈 공간을 남긴다. 먹물·붓털·종이 귀퉁이는 **그리지 않는다.** 앱의 `TraceSketch`가 그 위에 그린다 |
| 6 | `sora.png` | 1024×1536 | 궁녀 Sora 초상 (지금은 없음) | 젊은 궁녀, 친근한 표정 |
| 7 | `bae.png` | 1024×1536 | 필사관 Bae 초상 (지금은 없음, plan의 `bae_portrait`) | 중년 필사관, 붓을 든 모습. 악당처럼 무섭게 그리지 않는다 |
| 8 | `letter_found.png` | 1536×1024 | M3 발견 장면 (지금은 그림 없음) | 붓함 안의 접힌 왕실 문서와 붉은 인장. 글씨는 읽히지 않는 붓 자국만 |
| 9 | `bae_confrontation.png` | 1536×1024 | Final 대화 배경 (London `kings_cross_platform_night`) | 등롱 아래 마당. 아래쪽 40%에는 대화 UI가 올라오므로 비워 둔다 |
| 10 | `case_solved_dawn.png` | 1536×1024 | Case Solved / Case Closed 배경 | 새벽 궁궐 지붕, 밝아 오는 하늘 |

### 프롬프트 (각각 끝에 공통 스타일 문장)

1. A royal palace gate of Joseon Korea at night: a wooden gatehouse with a curved tiled roof, painted beams in muted red and green, stone steps, two paper lanterns glowing gold, a wide empty stone courtyard in front, a starry navy sky.
2. Inside a royal records room of a Joseon palace at night: low wooden shelves holding stacked folded documents and wrapped bundles, a lacquered document box with a small brass lock on a low desk, paper sliding doors with lattice, one candle lamp.
3. Top-down view of an open palace gate ledger on a low wooden desk: a stitched Korean book with thick cream paper, faint vertical ruled columns, all columns completely blank, an ink stone and a brush resting beside it.
4. Top-down view of two sheets of paper side by side on a low desk: on the left a rough, fibrous cream sheet, on the right a smooth, fine palace sheet; both blank; a small brass paperweight; soft lamp light.
5. A palace copyists' room of Joseon Korea at night: low writing desks, floor cushions, rolled paper, ink stones, a long wooden brush box with a lifted lid at the centre, a plain woven straw mat floor with open space in front of the box, lattice paper doors, warm lamp light.
6. A young palace maid of Joseon Korea, about seventeen, in a simple palace maid's hanbok with a plain jacket and long skirt, hair braided and tied, holding a small wooden tray with tea cups, a kind and slightly nervous expression.
7. A palace copyist of Joseon Korea, about forty, in a plain grey-blue scholar's robe and a black horsehair hat, holding a writing brush, a thoughtful, worried expression.
8. Close view of an open wooden brush box: under the brushes lies a folded royal document of fine cream paper tied with a red cord and stamped with a round red seal, lamp light falling on it; the writing is only soft, unreadable brush marks.
9. A palace courtyard of Joseon Korea at night under hanging paper lanterns: a copyist in a grey-blue robe stands by a stone step facing the viewer, his hands lowered; the lower part of the picture is plain stone paving with open space.
10. The curved tiled roofs of a Joseon palace at dawn: a soft gold and rose sky, mist over the courtyard, a single lantern still glowing, peaceful and hopeful.

### 실행 순서 (사용자 터미널)

```sh
# 1) dry run: 비용만 확인. 전송 없음
dart run tool/ai_agents/openai_image.dart --size 1536x1024 --prompt "<프롬프트> <공통 스타일 문장>" --output qa/seoul_pilot/palace_night.png
# 2) 만들기: 1회 호출
dart run tool/ai_agents/openai_image.dart ... --generate
```

`ImageStudio.run`과 `history_guard_hook.sh`는 역사 시즌 그림을 HistoryGate로 막는다. 현재 시범 Case의 HistoryGate는 통과 상태다(`s7_pilot_gate_test`의 "once its checks pass" 그룹 통과).

## 2. 실제 이미지와 임시 이미지 구분

| 화면 | 지금 쓰는 그림 | 구분 |
|---|---|---|
| M1 장소 (Royal Secretariat) | Paris Case 11 `annex_reading_room.webp` | 임시 (빌림) |
| M2 출입 장부 두 장 | Paris Case 03 `inspection_log.webp` | 임시 (빌림) |
| M3 필사실 | Paris Case 05 `workshop_interior.webp` + 앱이 그린 먹물·붓털·종이 귀퉁이 (`TraceSketch`) | 그림은 임시, 흔적은 앱이 실제로 그림 |
| Final / Palace Yard | London Case 01 `kings_cross_platform_night.webp` | 임시 (빌림) |
| Sora / Bae 초상 | 없음 | 미제작 |

서울 전용 이미지: **0장.** 기존 시즌 에셋은 하나도 바꾸지 않았다(빌려 쓰기만 함).

M3: 세 흔적은 그림 위에 앱이 그린다. 그린 자리가 곧 터치 영역이다. `s7_pilot_traces_test`가 320×568 화면, 글자 크기 ×1 / ×1.6에서 이를 확인한다. 각 흔적이 화면 안에 있는지, 짧은 변이 12dp 이상인지, 가운데를 탭하면 기록되는지, 스크린리더 이름이 있는지 본다. 새 `copy_room.png`가 오면 세 흔적의 좌표(`case.plan.json`의 `traces.clues[].areas/mark`)를 새 그림에 맞춰 다시 재야 한다.

## 3. 개발자 모드 진입 방법

1. 디버그 빌드나 `--dart-define=LM_PLAYTEST=true` 빌드에서 앱을 연다.
2. Game Master로 들어간다(부모 확인) → **START DEVELOPER MODE**.
3. 개발자 모드 페이지의 **SEOUL PILOT — CASE 01** 섹션에서 **ROOKIE / JUNIOR / MASTER** 중 하나를 누른다.
4. 그 난이도의 새 테스트 세션이 시작되고 Case 01 파일이 열린다 → **BEGIN INVESTIGATION**.
5. 시범 세션 안에서 Game Master의 TEST LEVEL을 바꾸면 그 난이도로 새 시범 세션이 다시 시작된다(처음부터). EXIT DEVELOPER MODE를 누르면 플레이어 본인의 게임으로 돌아간다.

구현:
- `lib/data/pilot/s7_seoulpilot/`: 생성기 출력이다(`generate_case.dart --target sandbox --out lib/data/pilot/s7_seoulpilot`). 이전 `test/sandbox/generated/s7_seoulpilot`와 바이트 단위로 같아서 그 폴더는 지웠다.
- `lib/data/pilot/seoul_pilot.dart`: 시범의 `SeasonContent`. `SeasonCatalog.all`에는 넣지 않았다.
- `lib/features/game_master/dev_session.dart`: `DevSession.enterPilot` / `pilot`, `pilotOverrides`, `openPilot`. 테스트 세션은 기존 개발자 모드와 같은 `MemoryPreferences` 독립 세션이다. 테스트의 `SingleCase`도 같은 `pilotOverrides`를 쓴다.
- `game_master_screen.dart`: `_SeoulPilot` 섹션. 개발자 모드 안(`testing`)이면서 `playtestToolsEnabled`일 때만 보인다.
- `SeasonCatalog.testSeasons/testPlaces`: 앱의 시범 세션도 쓰도록 `@visibleForTesting`을 뗐다. 동작은 그대로다.

보호:
- 플레이어 본인의 프로필과 진행 기록은 건드리지 않는다. 테스트가 시범 전체 플레이 후 EXIT했을 때 저장소 전체가 바이트 단위로 같음을 확인한다.
- 플레이어의 시즌 목록과 사건 목록에는 시범이 없다(같은 테스트에서 확인).
- 정식 배포 빌드: `enterPilot`은 `operatorToolsInBuild`(const)가 false면 null이고, 섹션은 `playtestToolsEnabled`로도 가려진다. 서울 전용 에셋은 없어서 번들에 추가된 파일도 없다. **release 빌드 바이너리에서 시범 코드가 실제로 tree-shake되는지는 빌드해서 확인하지 않았다.**

## 4. 세 난이도 플레이 테스트 결과

| 테스트 | 내용 | 결과 |
|---|---|---|
| `test/sandbox/s7_pilot_dev_mode_test.dart` (신규) | 개발자 모드 → SEOUL PILOT 버튼 → Case File → BEGIN INVESTIGATION → Story Intro → M1 → M2 → M3 → Final → Case Solved → Case Closed와 REAL HISTORY / IN THIS MYSTERY 문장. ROOKIE 320×568, JUNIOR 390×844, MASTER 320×568. EXIT 후 플레이어 저장소 바이트 동일. 시범 안에서 난이도를 바꾸면 새 세션 | 4/4 통과 |
| `test/sandbox/s7_pilot_play_test.dart` | R/J/M 각각: M1 오답 → TRY AGAIN → 무료 힌트 → 정답, 앱 재실행 후 진행 유지, M1 보상 재지급 0 (중복 방지), M2 오답 → 정답, M3, Final, Case Closed, History Reveal 순서, SOURCES | 통과 |
| `s7_pilot_gate_test`, `s7_pilot_traces_test`, `s7_pilot_records_layout_test` | HistoryGate와 생성물 최신 여부(새 경로), M3 흔적·터치 영역(320, ×1/×1.6), M2 기록 줄 44dp(320) | 통과 |
| 회귀: `single_case_test`, `developer_session_test`, `puzzle_engine_collisions_test`, `typography_test`, `generated_seasons_test`, `single_detective_test`, `onboarding_personal_test`, `story_backdrop_test`, `puzzle_palette_test` | 공유 코드(개발자 세션, SeasonCatalog, Game Master) 회귀 | 통과 |

위 묶음 실행: **+266, 실패 0 (약 3분 17초).** `single_case.dart` 정리 뒤 play / single_case / dev_mode를 다시 돌린 결과: +11, 실패 0. `flutter analyze`: 문제 없음.

**전체 `flutter test`는 돌리지 않았다.**

## 5. 기존 시즌 영향

- Season 1–4 콘텐츠, 에셋, 생성기, `lib/data/generated`: 변경 없음.
- 변경한 공유 코드는 세 곳이다. `SeasonCatalog`(주석과 `@visibleForTesting` 제거), 개발자 세션(시범 세션 추가, 기존 세션의 override 내용은 같음), Game Master(개발자 모드 안에 섹션 하나 추가). 기존 개발자 모드 테스트 15개가 통과했다.
- 정식 서울 시즌(s5_seoul)은 만들지 않았다. 커밋·푸시도 하지 않았다.

## 6. 실제 기기에서 확인할 사항 (수행하지 않음)

- iPhone에서 개발자 모드 → SEOUL PILOT 세 버튼 → 끝까지 플레이.
- 임시 그림이 iPhone SE(320)부터 Pro Max까지 어떻게 잘리는지. 특히 M3 필사실의 흔적 위치와 Final 배경.
- VoiceOver로 시범 버튼, M1 타임라인 카드, M2 기록 줄, M3 흔적 읽기.
- 시범 세션에서 나갈 때 소리와 광고 상태가 플레이어 세션으로 돌아오는지.

## 7. 남은 작업

1. 이미지 10장 제작. 비용을 승인한 뒤 위 프롬프트로 만든다.
2. 이미지 적용. `test/sandbox/plans/s7_seoulpilot`의 `season.plan.json` places와 `case.plan.json`의 records / traces / 배경 경로·픽셀 크기를 바꾸고, M3 흔적 좌표와 M2 기록 줄 위치를 새 그림에서 다시 잰 뒤, `generate_case.dart … --out lib/data/pilot/s7_seoulpilot`로 재생성한다. 그다음 `pubspec.yaml`에 서울 시범 폴더를 추가하고, 전체 화면 배경으로 쓰면 `BackdropArt.pictures`에 항목을 추가한다(`story_backdrop_test`가 확인).
3. 초상(Sora, Bae)을 보여 줄 자리가 생성기 출력에 아직 없다(`bae_portrait`는 assetNeeds에만 있음). 초상을 대화에 넣으려면 생성기가 대화 초상을 쓰도록 이어야 한다. 기존 시즌의 대화 초상 경로를 재사용한다.
4. 서울 그림을 release 번들에서 뺄지 결정해야 한다. 지금 Flutter 에셋은 빌드 종류와 관계없이 번들에 들어간다.
5. 실기기 확인(6절)과 release 빌드 tree-shake 확인.

---

# 이미지 제작·적용 (2026-11-04 추가)

- 생성: `season_factory.dart run test/sandbox/plans/s7_seoulpilot --pictures-only`. 매니페스트 `assets.manifest.json`(10장, `seasonStyles` seoul_scene/character/object, 기존 공통 스타일 변경 없음). gpt-image-2 medium. 예산은 `content_pipeline/image_budgets.json`의 $1.00. HistoryGate를 통과한 뒤 생성했다.
- API 호출 12회(10장 + 탈락 2장 재생성). 실제 비용 **$0.5194**(응답 usage 기준 list price, `planning/factory.json`).
- 탈락: letter_found(서양식 밀랍 봉인 → 붉은 인장), bae_confrontation(Bae 얼굴 불일치 → 초상을 참조해 다시 그림).
- 앱 적용(`assets/seasons/season_07_seoulpilot/`): royal_archive(M1·M2 장소), copy_room(M3 장소·흔적), palace_night(Final 장소·배경), scholar_papers(M2 두 기록지), bae(Final 초상), sora(M3 대화 초상), gate_ledger·letter_found(증거 e1·e3 그림, `ArtAssets.evidencePictures`).
- 앱 화면 자리가 없어 앱에 넣지 않은 그림: bae_confrontation, case_solved_dawn. `content_pipeline/asset_work/s7_seoulpilot`에만 있다.
- London·Paris 임시 그림 참조: 0개.
- M2: 왼쪽·오른쪽 종이의 모서리를 격자 시트와 밝기 스캔으로 측정했다. 320폭에서 기록 줄 터치 영역 45~53dp, ×1·×1.6 렌더링을 직접 보고 확인했다.
- M3: 흔적 좌표를 새로 정했다. 돗자리 위 먹물, 함 뚜껑 이음새의 붓털, 함 오른쪽 모서리의 종이 귀퉁이. `inside` 위쪽은 330이다. 320폭에서 ×1·×1.6 탭 위치가 그린 위치와 일치한다.
- Sora: M3 전환 문장 중 Sora 부분을 기존 talk-after 구조로 옮겼다(새 이야기 없음, J/M 문장 작성).
- 도구 변경: `--pictures-only`(시범 Case용 그림 단계만 실행), `HistoryGate.forOutput`이 `test/sandbox/plans`도 검사, 매니페스트 prologue는 `season.plan.json`에 prologue가 있을 때만 요구.
- 테스트(순차 실행): 시범 5개 파일, season_factory·asset_pipeline·season_planner·history_dossier·ai_agents·art_assets, developer_session·generated_seasons·story_backdrop·puzzle_engine_collisions 모두 통과. `flutter analyze` 문제 없음. Rome·NY `--check` 바이트 동일. 전체 `flutter test`는 돌리지 않았다.
- 남은 일: 실기기 확인. 고아 `flutter_tester` 프로세스 4개(이번 작업에서 생김)는 권한 문제로 정리하지 못했다.
