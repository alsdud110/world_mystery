# World Mystery — 코드 글리프 → 에셋 교체 조사 (2026-11-18)

플레이어가 보는 화면에서 게임 그림 대신 코드로 그린 것(InkGlyph/InkIcon, CustomPainter, 글자 '?')이
나오는 곳의 목록. 버튼·내비게이션 아이콘(back, close, check, notebook 등)은 제외.
줄 번호는 2026-11-18 작업 트리 기준.

## 런던 — 2026-11-18 처리 완료

| 항목 | 교체 내용 | 에셋 |
|---|---|---|
| 보드 "THE RAVEN SOCIETY" 검은 새 | Case 02 깃털 증거 그림 | `cases/case_02` 깃털 (`evidencePictures['ep02_e4']`) |
| 보드 "THE CLOCKMAKER" 톱니+? | 얼굴 가린 실루엣 | `season_01_london/characters/clockmaker_shadow.webp` |
| Case 07 M1·Final 공원 지도 4장 (LandmarkArt painter) | 지도 한 장 + 선택지별 X 위치 (`ArtAssets.parkMapMarks`) | `season_01_london/cases/case_07/park_map.webp` |
| 파리 클락메이커 톱니·열쇠 마크 (Case 09 M3, Case 10 드럼 명판·재판 기록, Case 12 도장, 증거 카드) | 색 입힌 투명 마크 | `shared/symbols/mark_gear.webp`, `mark_key.webp` |
| 파리 Case 10 M3 해 토큰 | 그림 | `shared/symbols/sun_token.webp` |

남겨둔 소소한 것: Case 01 M2 열쇠 FOUND 카드 글리프, Case 06 M2 발자국 링, 사냥모자 엠블럼·레벨 카드, 잠금 배지 자물쇠.

## 공통 (파리·로마·뉴욕·서울 전부)

| # | 어디 | 코드 | 보이는 것 | 비고 |
|---|---|---|---|---|
| A | 시즌 보드 가운데 인물 | `lib/features/season/widgets/investigation_board.dart:606` | 큰 '?' 글자. 파리는 Case 12 전까지, 로마·뉴욕·서울은 시즌 내내 | `s3_rome_season.g.dart:23`, `s4_newyork_season.g.dart:23`, `s5_seoul_season.g.dart:23` 이 `figures: []`. 쓸 그림: 파리 `characters/emile_back.webp`, 로마 `objects/owl_card.webp`, 뉴욕 `objects/silver_lark.webp`, 서울 `characters/sejong.webp` 등 |
| B | 모든 편지 미션의 봉투·편지지 | `lib/widgets/letter_card.dart:446~629` (`_PocketPainter`, `_FlapPainter`, `_WaxBlobPainter`, `_LetterPaperPainter`) | 코드로 그린 봉투. 소인 **"LONDON"**(:499), 밀랍 도장 **"LM"**(:629). 네 시즌 전부 같은 봉투 | 서울 조선 편지에도 런던 소인. 파이널 편지(`final_mission_screen.dart:877, :1413`), 탐색 서류(`scene_explore.dart:739`), Case Closed 도장(`case_solved_screen.dart:695`)도 같은 LM. `ArtAssets.letterSeals`(art_assets.dart:629)는 런던 ep04만 있음 |
| C | 레터락 자물쇠판 | `lib/features/mission/widgets/letter_lock.dart:142`, `_LockPlate :374` | 톱니 글리프 박힌 호두색 상자 (클락메이커 모티프). 서울 C12 "어머니의 자물쇠", 로마 C02 M3·C05 M2·C10 M2 및 C04·06·08·11·12 파이널, 뉴욕 C02 M3·C09 M3 및 C04·06·08·10·11·12 파이널 | 서울 `case_12/trunk_one_strap_lock.webp`, 뉴욕 `objects/brass_egg.webp`, `wheel_box.webp` 등 실제 자물쇠 그림 있음 |
| D | 파이널 그림 다이얼 | `lib/widgets/royal_box_picture.dart:33` (`RoyalBoxPicture.of`) | 시즌 검사가 없어 다이얼 심볼이 clock/train/park/museum이면 **런던 Royal Box 그림**이 나옴 | 로마 C03·C07 파이널 "CLOCK" = 런던 회중시계, 로마 C09 "museum" = 로제타석에 **"STONE"** 표기(스크린리더도 "Stone"), 뉴욕 C03 파이널 clock = 회중시계. 로마 C03 M1 단서 "Pia's Morning" 카드까지 전염(`clue_card.dart:44`, `forClue`). 고치는 곳은 한 곳: `RoyalBoxPicture.of`에 시즌(런던 Case 01) 검사 |

## 파리 (위 공통 + 2026-11-18 처리분 제외)

| # | Case / Mission | 코드 | 보이는 것 | 있는 에셋 |
|---|---|---|---|---|
| 1 | C01 파이널 그림 뒷면 | `lock_box.dart:389~420` (`_Back`, 글리프 :412) | 코드로 그린 양피지 + 편지 글리프 "FIND THE PAINTER." | `case_02/canvas_back.webp` |
| 2 | C06 M2 설계도 경로 | `plan_route.dart:249~262` (`_LetterToken`), `:211~226` (`_ring`) | 편지 글리프 원판 토큰, 발자국 글리프 링 | `shared/symbols/symbol_letter.webp`, `symbol_footprint.webp` |
| 3 | C10 M1 드럼 테이프 (증거 e1/e4 포함) | `star_records.dart:271 → _TapePaper :352` | 코드로 그린 구멍 뚫린 종이띠 | 없음 (`case_10/record_drum.webp`만) |
| 4 | C10 M1 헤더 "T1 · DRUM TAPE" | `star_records.dart:504` | 톱니 글리프 (11-18 작업에서 놓친 1곳) | `shared/symbols/mark_gear.webp` |
| 5 | C10 파이널 재판 기록 | `star_records.dart:2013 → _FadedWords :2088` | 코드로 그린 바랜 글씨 선 | 없음 (`case_10/trial_log_open.webp` 위) |
| 6 | C05 M3 "THE MIRROR SAYS", C05 파이널, C11 M1 3쪽·M2·증거 e1, C12 M1 이름표·증거 e1·e4 | `easy_steps.dart:1127~1210` (`_PaperView`) | 코드로 그린 종이(그라데이션 박스 + 줄) | `case_05/post_slip_blank.webp`, `repair_card_blank.webp`, `case_10/trial_log_open.webp`, `case_11/big_book_torn.webp` |
| 7 | 프롤로그 역 시계 3장 | `paris_prologue.dart:530~575` (`_StationClocks`, 글리프 :561) | 시계 글리프 카드 10:00/10:00/9:00 | `case_01/station_hall_clocks.webp`, `old_clock_face.webp` |
| 8 | 프롤로그 기차표, 시즌 종료 다음 도시 표 | `train_ticket.dart:41` (`paris_prologue.dart:402`, `case_solved_screen.dart:372`) | 코드로 그린 표 + 기차 글리프 | 없음 |
| 9 | 보드 Case 12 에밀 얼굴 (파일 실패 시) | `investigation_board.dart:603` | 톱니 글리프 errorBuilder | `characters/emile_base.webp` 가 본 그림 |

소소한 것: C02 M2 노트 카드 액자 글리프(`studio_match.dart:1128`), C07 수정 전표·C08 찢긴 서식의 화살표 글리프(`opera_papers.dart:508`, `abbesses_papers.dart:108`), C11 M1 탁본 연필 애니메이션(`easy_steps.dart:1497, :1512`).

깨끗함: 파리 장면 31개 전부 파일 있음(`art_assets.dart:364~410`), 증거 48개 전부 그림/종이, 심볼 키 전부 `shared/symbols` 파일 있음. 시계 바늘·리프트 선·붉은 실·찢김은 그림 위에 올리는 코드라 유지.

## 로마

위 A·B·C·D 외 깨끗함. 자산 74개 전부 디스크 + 팩 매니페스트. 장면 18곳, 증거 48개, 이미지 선택지(C08 M1, C09 M1, C11 M1) 전부 그림.
봉투(B) 뒤 편지가 실제 물건인 경우: 올빼미 카드(C03 M2, C04 M3, C07 M1, C08 M1 → `objects/owl_card.webp`), 깡통 뚜껑(C02 M3), 헬멧 이름띠(C10 M2 → `yellow_helmet.webp`), 리비아 일기(C08 M3), 알도 스케치(C06 M3).

## 뉴욕

위 A·B·C·D 외 깨끗함. 자산 전부 디스크 + 매니페스트(`season_pack_manifests.g.dart:384~460`), 증거 48개 그림/종이, 장면 14곳, 이미지 선택지 6개 전부 그림.
봉투(B) 뒤 편지가 실제 물건인 경우: C01 M2 신문(`objects/newspaper.webp`), C02 M3 달걀 태그(`brass_egg.webp`), C04·C11 M2 놋쇠 태그(`brass_bird.webp`), C09 M3 상자 뚜껑(`wheel_box.webp`), C06 M1 페리 표. 런던 ep11_m2만 쓰는 `ArtAssets.inscriptions`(art_assets.dart:590, 물건 위에 글 올리기)을 재사용할 수 있음.
C03 파이널 다이얼 clock/map/gem, C05 파이널 gear/watch/feather는 공용 도장 그림(코드 아님)이나 안내문 "Each picture is a place"와 맞지 않음.

## 서울

위 A·B·C 외 깨끗함(Royal Box 다이얼은 안 써서 D 해당 없음). 자산 전부 디스크 + 매니페스트, 증거 48개 그림/종이, 장면·선택지·초상 전부 있음. 심볼 키 14개 전부 파일 있음.
C04 M1 "THE YARD TAG" 확대(`lens_inspect.dart:905~929`)는 글자판만 있고 그림이 없음 (`s5_ep04.g.dart:656~722`에 `labelPicture` 없음, C11은 있음). `case_04/timber_yard.webp` 안에 태그가 보임.

## 우선순위 제안

1. D — 런던 그림이 다른 시즌 파이널에 노출(로제타석 "STONE"). `RoyalBoxPicture.of` 한 곳.
2. B — 서울·로마·뉴욕 편지에 LONDON 소인 + LM 도장. 시즌별 소인/도장 또는 소인 제거.
3. A — 보드 '?'. 생성 시즌 `figures`에 그림 한 장씩.
4. 파리 1~8, C 레터락 판.

확인하지 않은 것: 캡처 없음(코드 조사만). 로마·뉴욕·서울은 앱 실행 없이 코드·데이터 읽기. 주니어·마스터 변형은 공통 키만 확인.
