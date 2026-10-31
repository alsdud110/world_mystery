# World Mystery — 아이콘 이미지 에셋화 진행 기록

- 기준 문서: [WORLD_MYSTERY_ICON_AUDIT.md](WORLD_MYSTERY_ICON_AUDIT.md)
- 시작: 2026-11-01, 기준 커밋 `3d0f852`
- 이미지 비용 상한(사전 승인): **USD 10**
- 생성 매니페스트(추적): [content_pipeline/icon_upgrade/icon_asset_manifest.json](../content_pipeline/icon_upgrade/icon_asset_manifest.json), 재사용·기각 목록: [reused.json](../content_pipeline/icon_upgrade/reused.json)
- 생성 원본·호출 기록(git 제외): `qa/icon_upgrade/raw/`, `qa/icon_upgrade/api/<id>.json`, 버린 시도 `qa/icon_upgrade/superseded/`

## 결과 요약

| 항목 | 결과 |
|---|---|
| 증거 194건 중 선 아이콘으로만 보이던 것 | 119건 → **0건** |
| 증거 표시 방식 | 그림 77 (기존 42 + 재사용 13 + 신규 22) · 사건별 코드 그림 33 · 문서 종이+영어 문장 84 |
| OpenAI로 만든 게임용 이미지 | **59장** (사물 22, 문서 종이 11, 단서·자물쇠 스탬프 24, UI 2) |
| API 호출 | 72회 (59장 + 품질 불합격 재시도 13회; 실패 응답 0) |
| 비용 | **$3.2685** — 응답 `usage`를 공식 목록가(2026-10-29 확인, 2026-11-01 재확인)로 환산한 값. 실제 청구액은 OpenAI 기준 |
| 기존 이미지 재사용 | 그림 6장 → 증거 13건 (감사 문서 후보 19건 중 5건은 기각, 아래) |
| 이미지로 바뀐 아이콘 종류 | 58종 중 **25종** (A 23종 전부 + B 2종: 코인, 아카이브 도장) |

## 모델·설정

- 모델: `gpt-image-1.5`, `1024x1024`, `quality: medium`, 사물·문서·UI는 `background: transparent`, 스탬프는 흰 배경(불투명)으로 받아 명도→알파 변환.
  - 근거: 프로젝트의 기존 런던 업그레이드가 같은 설정으로 투명 사물을 만든 선례, 공식 가격표(이미지 출력 $32/1M 토큰) 확인.
  - 두 번 연속 다른 것을 그린 4장만 세 번째 시도에 `gpt-image-2`(같은 OpenAI Images API, 흰 배경 → 배경 제거)를 사용.
- 키: `.env`의 `OPENAI_API_KEY`(git 제외)를 기존 `tool/ai_agents/env_file.dart`로 읽음. 코드·매니페스트·로그 어디에도 기록하지 않음.
- 도구: [tool/icon_upgrade/](../tool/icon_upgrade/) — 기존 `ImageStudio`(비용 추정·같은 요청 재전송 방지·PNG 검증·호출 기록) 재사용.
  - `generate`: 호출 전 누적 비용 + 이번 추정이 상한을 넘으면 중단, 이미 만든 그림은 다시 요청하지 않음, 그림당 최대 3회.
  - `prep`: 잘라내기·정사각 여백·리사이즈(사물 512, 스탬프·UI 256, 종이 최대 1024).
  - `sheet`: 검수용 대조표. `manifest`: 추적 매니페스트 작성.
  - 중단돼도 `generate`를 다시 실행하면 남은 것만 만든다.

## P0 — 기존 이미지 재사용 + 표시 구조

| 증거 | 사용 그림 | 판단 |
|---|---|---|
| ep02_e2 Small Brass Gear, ep12_e1 The Real Gear | `season_01_london/objects/brass_gear.png` | 같은 톱니(까마귀 각인)가 Case 02 탐색에서 이미 쓰임 |
| ep03_e2 Blue Cloth | `objects/blue_cloth.png` | 탐색 장면의 그 천 |
| ep03_e3 Wet Footprint | `objects/wet_footprint_cutout.png` (신규 파생) | 원본의 검은 배경 제거 + 정사각 패딩. 원본은 탐색 장면용으로 그대로 둠 |
| ep04_e3 Postmark | `shared/objects/letter.png` | "두 번째 봉투에서" — 봉투 그림. 탑 그림은 문구로만 |
| 로마 부엉이 카드 7건 | `season_03_rome/objects/owl_card.png` | 같은 범인의 같은 카드. 각자의 문구는 확대 보기에 |
| s4_ep11_e2 The Brass Bird, Found | `objects/brass_bird.png` | Case 04의 같은 새 |

**기각 5건 (정답 노출·의미 왜곡 검증)**

| 후보 | 이유 | 대체 |
|---|---|---|
| s4_ep02_e1 Star Print ← `star_sole.png` | **정답 노출.** 뉴욕 Case 07이 "어느 밑창이 별 발자국을 만들었나"를 묻고 정답 선택지가 바로 이 그림 | 수첩 진술 종이 + 영어 문장 |
| s2_ep03_e2 Lift Log ← `lift_log.png` | 빈 장부(글자는 퍼즐이 그림). 이전에 "빈 종이라 증거로 쓰지 않음"으로 결정됨 | 기록부 종이 + 영어 문장 |
| s2_ep03_e1 Conflicting Notices ← `tower_notice_board.png` | 게시문이 아니라 입구 전체 장면 | 안내문 종이 + 영어 문장 |
| ep07_e3/e4 Joined Map, Old London Map ← `map.png` | 문구의 까마귀가 그림에 없음(의미 왜곡) | 지도 종이 + 영어 문장 |
| s3_ep09_e2 Old Street ← `city_plan.png` | 다른 문서(e4의 건축 계획) | 지도 종이 + 영어 문장 |

`Wet Footprint`: 런던에는 밑창 맞추기 퍼즐이 없고 Case 03 탐색에서 이미 이 그림을 보여 주므로 노출 위험 없음. Painter's Message(`canvas_back.png`)도 같은 이전 결정에 따라 종이+문장으로 처리.

**구조 변경**

- [evidence_board.dart](../lib/features/mission/widgets/evidence_board.dart), [street_book.dart](../lib/features/mission/widgets/street_book.dart):
  - 변경 전: `SymbolBadge(evidence.icon)`이라 그림이 있어도 선 아이콘이 표시됨
  - 변경 후: `EvidenceThumb`로 바꿔, 수첩·발견 화면과 같은 공통 증거 그림을 표시
- 테스트 갱신(조건 약화 없음):
  - `art_assets_test`, `rome_integration_test`: 증거 그림 목록 고정값에 새 항목을 추가하고 이유를 명시. Paris의 빈 퍼즐 종이가 증거 그림이 되지 않는다는 기존 의도는 단언으로 유지.
  - `case01_lock_pictures_test`:
    - 그림 로딩 중 잠깐 보이는 대체 스탬프도 이제 이미지라, `Image` 탐색을 "증거 그림(ResizeImage)"으로 좁힘.
    - London Map은 "그림 없음" 대신 "빈 지도 종이, 타일에 swans 문구 없음, 그림 등록 없음"으로 의도를 그대로 검증.
    - 다른 사건 스탬프는 "Case 01 컬러 자물쇠 그림이 아님"을 단언.
- 관련 테스트: 66 통과.

## P1 — 신규 증거 이미지

- **개별 사물 22장** — 문구가 정답이거나 단서인 내용(글자, 숫자, 각인 문자, 무늬)은 그리지 않음.
  - 런던 8: raven_feather, silver_whistle, raven_tower_painting, empty_jewel_box, blue_star_jewel, poppys_ring(글자 없음), white_mask(글자 없음), toy_train_whistle
  - 파리 1: clockmaker_mark(톱니만, M은 문구로)
  - 로마 5: white_dust, light_box, bag_of_white_dust, orange_cat_hair, cat_collar_tag(빈 태그)
  - 뉴욕 8: tiny_screws, karl_old_photo, seagull_photo, karl_pocket_book(닫힌 수첩: 음표는 문구), wheel_box(빈 고리), dexter_safe, stone_nest, open_stone(글자 없음)
- **문서 종이 11종 + 공통 렌더링** — note 27, card 11, map 8, statement 8, log 7, notice 6, letter 5, diary 5, tag 3, ticket 2, music 2 (합 84건)
  - 종이는 모두 글자 없이 생성했습니다.
  - [EvidencePaperView](../lib/widgets/evidence_card.dart)가 확대 보기에서 종이의 글자 영역에 증거의 영어 문장(`inscription`, 없으면 `description`)을 렌더링합니다. 용어 설명(GlossaryText)도 그대로 동작합니다.
  - 큰 글씨 설정에서는 잘리지 않고 축소되며, 종이 아래의 중복 문구 상자는 숨깁니다.
  - 타일·회상 카드 같은 작은 원형 프레임에는 빈 종이만 표시합니다. 영어 문구는 전처럼 눌러서 확대해야 보이므로, 퍼즐 흐름이 바뀌지 않습니다.
- **글자가 단서라 일부러 종이+문장으로 둔 증거**: 런던 지도와 지도 조각(백조·까마귀), Arrivals Board, 로마 Mirror Sketch·Chalk Code, 뉴욕 Page Stub(톱니 모양은 Case 11 맞추기), Wet Paint Sign, Family Tree.

## P2 — 단서·자물쇠 스탬프

- `ArtAssets.symbols`에 `GameSymbol`의 24개 키를 모두 등록했습니다(watch를 clock과 분리, palace 포함).
  - 단색(검정) 실루엣이고, 게임이 심볼 색으로 칠합니다(`InkMark`, `BlendMode.srcIn`).
  - 파일이 없으면 기존 잉크 글리프로 돌아갑니다.
- 적용 범위(4개 시즌):
  - 단서 카드 146건(런던 Case 01의 4건은 기존 컬러 자물쇠 그림 유지)
  - 다이얼 자물쇠 7개 사건(로마 5, 뉴욕 2)
  - 그림 없는 증거의 대체 표시와 `scene_decode`
- 퍼즐 조작·정답·선택지 수·힌트는 변경하지 않았습니다. 스탬프는 기존 글리프와 같은 의미의 사물만 그립니다.
- 새 시즌은 같은 키를 쓰면 스탬프가 자동으로 적용됩니다. 새 키는 `GameSymbol._symbols`와 `ArtAssets.symbols`에 한 줄씩 추가하면 됩니다.

## P3 — 게임 전용 UI (B 그룹 14종 검토)

| 항목 | 결정 |
|---|---|
| 코인 | **교체.** `GameCoin` 하나로 지갑·팁 상점·How to Play 3곳 통일, 파일 없으면 잉크 코인 |
| World Archive 도장 | **교체.** 헤더 엠블럼을 밀랍 도장 그림으로(없으면 잉크 도장) |
| 별점(InkStar) | 유지 — 코드로 그린 별이 선명하고 크기·색 대응이 이미 좋음 |
| 수첩·사건 파일·핀·힌트 전구 | 유지 — 메뉴·버튼 아이콘이라 선화가 UI 언어와 맞음. 힌트 전구는 불빛 애니메이션이 글리프 격자에 묶여 있음 |
| deerstalker, eye, puzzle, sun | 유지 — 대체 표시이거나 퍼즐 보조 버튼 |
| 지도 핀, 밀랍 봉인 모노그램, `?` 표시, 번호 스탬프 | 유지 — 코드 그림 품질이 충분하거나 번호 자체가 퍼즐 정보 |
| 배지 메달 | 이미 15종 PNG |

## P4 — 검증

| 검사 | 결과 |
|---|---|
| `flutter analyze` | No issues |
| [test/icon_upgrade_test.dart](../test/icon_upgrade_test.dart) (신규 13) | 통과 — 194건 전부 그림 표시(3개 난이도 모두), 중복 등록 없음, 파일 존재·번들, 종이 비율=파일 비율, 스탬프 단색, Star Print 정답 노출 방지, 문서 문장 난이도별 표시(320×568, 글씨 1.3배, 넘침 없음), 가장 긴 문장, 타일 접근성 라벨, 코인·스탬프·대체 표시 |
| 관련 기존 테스트 | 66 + 324 통과 |
| 위젯 렌더링 스크린샷(테스트 내 캡처) | 원형 프레임 잘림 없음, 밝은 종이·어두운 남색 배경 모두 식별, 32px 스탬프 구분 가능 |
| 전체 `flutter test` (최종 1회, 571초) | **3402 통과, 4 실패.** 4건 모두 작업 전 HEAD `3d0f852`(별도 worktree)에서 똑같이 실패 — 이번 작업과 무관: `audit_fix_d4_d5_test` D5와 `final_small_pass_test` 17(사건 데이터 지문: 직전 커밋 `3d0f852`의 런던 Case 03 선택지 메모가 바꿈), `season_planner_test` 2건(이전 기록에도 있던 기존 실패). 손대지 않음 |
| 실제 아이폰 | **확인하지 않음** |

### 실제 아이폰에서 확인할 것

- 수첩 증거 타일과 확대 보기: 새 사물 그림, 종이 위 영어 문장 크기(특히 티켓·꼬리표처럼 가로로 긴 종이)
- 단서 카드 하단 스탬프, 로마·뉴욕 자물쇠 스탬프의 크기와 대비
- 증거 보드(파리 Case 03·04·08), Street Book의 34px 그림
- 코인(앱 바, 팁 상점), World Archive 도장
- 시스템 글씨 크게 설정 시 확대 보기

## 난이도·데이터 영향

- Rookie / Junior / Master: 난이도 패치는 증거의 이름·설명만 바꾸고 `inscription`·아이콘은 고정이므로, 종이 위 문장은 세 난이도 모두 같은 영어 단서다. 이름·설명은 그대로 난이도별로 표시된다.
- 퍼즐 정답·힌트·코인·XP·미션 ID·저장 데이터 형식: 변경 없음(모델·저장 코드 미변경).
- 사운드: 추가 없음.
- Season Factory: 생성 코드(`*.g.dart`)와 파이프라인은 건드리지 않음. 생성 시즌의 추가 그림은 `ArtAssets.evidencePictures`/`evidenceDocs`(손으로 관리)에 등록, 같은 ID가 생성 쪽에 생기면 const map 중복 키로 컴파일 오류가 나 이중 등록을 막는다.

## 남은 일

- 직접 `InkIcon`으로 그리는 퍼즐 안 사물 표시(파리 시계공 각인 톱니 비교, plan_route 발자국·편지 토큰 등)는 퍼즐 메커니즘이라 유지.
- 파리 시계공 각인을 퍼즐 전체에 같은 그림으로 통일하는 작업(감사 문서 A-4)은 퍼즐 위젯 수정이 필요해 이번 범위에서 제외.
- 로마·뉴욕 시즌 조사 보드 인물 `?`, 런던 전용 배지는 이번 범위 밖.
