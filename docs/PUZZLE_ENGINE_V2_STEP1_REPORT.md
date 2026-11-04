# Puzzle Engine 2.0 — STEP 1 시즌팩토리 퍼즐 다양화 통합 보고서

작성일 2026-11-04 · 범위: 기존 PART 3I(기존 엔진 자동 생성), 3J(역사 검증 연결), 3K(퍼즐 자동 선택)를 하나로 구현했다.

- 하지 않은 것: 서울 시즌 생성, Season 1–4 콘텐츠 변경, 기존 퍼즐 엔진의 플레이 방식 변경, 유료 API 호출, 커밋·푸시, 전체 `flutter test`, Release 빌드.
- 검증은 테스트 전용 샌드박스 시즌 `s8_timeline`의 새 Case 02(`s8_ep02`)와 Rome 임시 사본으로만 했다.

## 1. 자동 생성 지원이 추가된 퍼즐 유형 (5종)

| 유형 (`paletteId`) | 실제 조작 | 엔진 테이블 · 판정 | 역사 추리에 쓰는 법 |
|---|---|---|---|
| `record_mismatch` | 두 기록을 넘겨 읽고, 서로 다른 줄 한 쌍을 탭 | `records` · `matchPairs` (`time:time`) | 실록과 다른 기록, 공고문과 일지의 차이 |
| `trace_deduction` | 현장 그림에서 흔적을 모두 탭(메모) → 흔적이 모두 가리키는 곳을 탭 | `deductions` · `multipleChoice` | 유적·현장에 남은 흔적으로 장소 추리 |
| `lens_inspect_word` | 돋보기를 끌어 전시물 확인 → 쪽지가 묘사하는 전시물의 라벨에 빠진 단어 입력 | `inspections` · `wordInput` | 유물 설명문·비문 읽기 |
| `evidence_talk` | 인물과 대화, 질문하고 요구받은 증거를 수첩/카드 두 장에서 제시(오답 없음) | `talks` · `examine` | 증언의 모순을 증거로 반박 (Final 가능) |
| `number_entry` | 글로 읽은 숫자를 키패드로 입력 | (테이블 없음) · `numberCode` | 기록 속 숫자(횟수·번호)를 영어로 읽기 |

이로써 생성기가 만드는 유형은 10종 → **15종**(`timeline_board` 포함)이다.

**6종이 아니라 5종인 이유 — `spot_difference` 제외:**
- 같은 구도·크기로 픽셀이 정합된 그림 두 장과 "어디가 다른지"를 이미지 생성 도구가 보장할 수 없다. 차이 좌표를 측정해도 생성물마다 의도하지 않은 차이가 생기면 정답이 여럿이 된다(검증 불가).
- 정답에 영어가 거의 쓰이지 않는다(그림만 비교). CLAUDE.md §20의 "English is the tool"에 맞지 않는다.
- 나머지 후보도 검토했다: `object_decode`(오답이 없는 연출용, 추리 퍼즐이 아님), `room_find_match`·`layer_reveal`·`symbol_dial_lock`·`clue_filter_choice`(Paris 전용 그림 구성·Final 전용, 역사 단서와의 연결이 약함). 품질을 낮춰 개수를 채우지 않았다.

각 유형이 지원하는 것:

| 항목 | 내용 |
|---|---|
| 계획 스키마 | `missions[].play.records` / `traces` / `inspect` / `interview` (JSON Schema + Dart 모델 + 알 수 없는 필드 거부). `number_entry`는 기존 `answerSpec`(`codeLength`, `codeFormat`) |
| 콘텐츠 생성 | `<case>.g.dart`의 `<Case>Records/Deductions/Inspections/Talks`, 시즌 파일의 테이블. **그 테이블을 쓰는 시즌에만 출력**(`scenesOf`) |
| 정답·해결 가능성 검증 | `PlayCheck`(§5 표) |
| ROOKIE/JUNIOR/MASTER | 장면의 문구가 `levels.json`으로 레벨별 생성. 위치·정답·id·증거 id·기록 값은 레벨이 바꿀 수 없음 |
| Mission 화면 플레이 | 기존 위젯 그대로(`TowerRecords`, `SceneDeduction`, `LensInspect`, `CaseTalk`, `NumberCodeQuestion`) |
| 저장·복구·보상 | 기존 `submitAnswer` 경로. 새 저장 키 없음 |

## 2. 변경 파일

| 파일 | 내용 |
|---|---|
| `tool/season_gen/plan_models.dart` | `TracesPlan`, `InspectPlan`, `RecordsPlan`(+`RecordDocPlan`, `RecordSheetPlan`, `RecordLinePlan`), `InterviewPlan`(+질문·제시), `MissionPlayPlan`의 4개 필드, 리더 보조(`rect`, `number`, `numbers`, `optInts`) |
| `tool/season_gen/schema/mission_plan.schema.json` | `play.traces`, `inspect`, `records`(+`recordDoc`), `interview` |
| `tool/season_gen/case_levels.dart` | 레벨 문구에서 제외할 키 `accepted`, `offered`, `finishWhen`(기존 Rome·NY·s9 계획에 없음을 확인) |
| `tool/season_gen/play_check.dart` | `generatable` 5종, `pictured`, `sceneKeys`, 엔진별 검사 `_numberCode`·`_traces`·`_inspect`·`_records`·`_interview`, 그림 목록 |
| `tool/season_gen/generate_case.dart` | `v2SceneTables`에 4개 테이블, `talks`는 `final`(`TalkScene`이 상수가 아님), 빌더 4개, import 목록 |
| `tool/season_gen/history_dossier.dart` | 모든 미션의 dossier 등록(`history_puzzle_unlisted`), 창작 퍼즐(`fiction: true`, `history_puzzle_source`), 기록 값의 연도 검사 |
| `tool/season_planner/puzzle_selection.dart` | **신규** `PuzzleSelector`(규칙 기반 선택기) |
| `tool/season_planner/season_quality.dart` | 역사 모드에서 선택 실행, 찾은 것, `planning/puzzle_selection.json` 기록 |
| `tool/season_factory/season_factory.dart` | 1단계 후 선택 요약 한 줄 |
| `tool/season_planner/PLAYBOOK.md`, `tool/season_gen/GAMEPLAY_CATALOG.md` | 생성 가능 유형 표, 역사 모드 선택 절차 |
| `test/sandbox/plans/s8_timeline/cases/s8_ep02/case.plan.json` | **신규** 샌드박스 Case 02(5종 엔진 한 Case). 그림·측정 좌표는 London Case 01·Paris Case 03 재사용 |
| `test/sandbox/generated/s8_timeline/*` | 재생성(`s8_ep02.g.dart` 추가, 시즌 파일에 4개 테이블) |
| `test/sandbox/engines_season_test.dart` | **신규** 실제 앱 플레이 |
| `test/season_gen/engines_generation_test.dart` | **신규** 잘못된 계획 차단, 레벨 |
| `test/season_planner/puzzle_selection_test.dart` | **신규** 선택기 |
| `test/season_gen/history_dossier_test.dart` | 픽스처가 모든 미션을 dossier에 등록(첫 미션은 사실, 나머지는 창작), STEP 1 테스트 4개 |
| `test/sandbox/sandbox_play.dart` | 키패드 입력(`numberCode`) |
| `test/sandbox/timeline_season_test.dart` | s8에 Case가 둘이 되어 `.single` → `.first` |

## 3. 역사 검증 연동 (Historical Fiction Mystery 모드에서만)

PART 1·2의 dossier·승인·게이트를 그대로 쓰고 범위만 넓혔다. 우회 경로는 없다.

| 요구 | 구현 |
|---|---|
| 승인된 역사 사실 ID 연결 | 퍼즐 항목의 `factIds`(기존). 미승인 사실은 이미지·게임 게이트 차단(기존 `history_fact_unapproved`) |
| 창작 정보 명시 | **신규:** 퍼즐 항목은 `factIds` 또는 `fiction: true` 중 하나(`history_puzzle_source`). 창작 퍼즐도 사람 검토 대상. Case에 사실 기반 퍼즐이 하나도 없으면 `history_case_unlinked` |
| **모든 퍼즐이 승인 시스템 통과** | **신규:** dossier에 없는 미션은 `history_puzzle_unlisted` → 게임 생성 게이트에서 차단(그림 단계는 사실만 요구하므로 통과) |
| 정답과 역사 근거 연결 | `answer`, `derivation`, `whyNot`/`whyOnly`(기존) |
| 단서가 게임 안에 존재 | `clues[].text`가 플레이 전 글에 있음(기존). **신규:** 기록(`records`)의 값도 플레이어가 읽는 글로 취급해 연도 검사 대상 |
| 세 난이도에서 정답 일치 | 정답·id·위치·기록 값은 레벨 문구가 아님(`_playNotText`) → 레벨이 바꿀 수 없음. 레벨 계획마다 `PlayCheck`를 다시 실행하므로 흔적 문장·쪽지 줄이 레벨 편지에서 빠지면 그 레벨에서 거부(테스트) |
| 사실 변경 시 승인 무효화 | 퍼즐 승인 해시 = 퍼즐 항목 + 미션 JSON(장면 포함) + 인용 사실(기존). 창작 퍼즐도 힌트 한 줄 변경으로 `stale`(테스트) |
| 미승인 정보로 콘텐츠·유료 에셋 생성 차단 | 기존 `HistoryGate`(이미지·사운드·게임). 새 코드 `history_puzzle_unlisted`는 게임 단계 차단 목록에 추가 |

## 4. 자동 선택 규칙 (`PuzzleSelector`)

입력: 각 미션의 플레이어가 퍼즐 전에 읽는 글(story, letterIntro, letter, question)과, dossier에서 그 퍼즐이 인용한 사실의 문장.

1. **성격 판정(키워드 규칙, 대소문자 무시, 같은 단어는 1번):**

| 성격 | 단서 단어(예) | 최소 개수 | 우선 퍼즐(순서대로) |
|---|---|---|---|
| chronology 연대·순서 | before, after, then, later, finally, 4자리 연도 | 2 | `timeline_board`, `order_sequence` |
| documents 기록 차이 | record, log, notice, register, copy, does not match | 2 | `record_mismatch`, `text_choice` |
| testimony 증언 | said, says, told, claims, witness, saw | 2 | `witness_compare`, `evidence_talk` |
| scene 현장 흔적 | footprints, marks, scratches, hidden, behind | 2 | `trace_deduction`, `dark_room_search`, `scene_explore_choose` |
| inscription 새긴 글 | label, inscription, carved, plaque, sign | 1 | `lens_inspect_word`, `word_entry` |
| relations 관계 | wrote, owner, belongs, gave, took, whose, who | 2 | `evidence_talk`, `witness_compare` |
| number 숫자 입력 | how many, number, count, hundred | 1 | `number_entry`, `combo_dial_lock` |

   - "Evidence Connection 계열"(`deduction_board`)은 아직 생성기가 없으므로 후보에 없다. 관계는 증거 제시 대화와 증인 비교로 대신한다.
   - 시각(3:00 PM)·연도만으로는 `number`가 되지 않는다(대부분의 Case에 나오므로).
2. **암기 문제 방지:** 사실 문장에만 있고 플레이어가 읽는 글에 없는 성격은 기록만 하고 선택에 쓰지 않는다(`"from": "factsOnly"`). 필요한 단서는 플레이 전 글에 있어야 선택된다.
3. **후보 제한:** `PlayCheck.generatable`(실제 생성·검증 가능)이고 그 화면(미션/Final)에서 플레이되는 유형만. 화면이 못 하는 1순위가 빠지면 다음 순위가 올라간다.
4. **점수:** 성격별 순위 10, 7, 4점을 더한다. 감점: 같은 Case에 이미 있음 −8, 시즌의 1/3 초과 −8, 앞 Case의 같은 자리와 같음 −4, 일반 객관식(`text_choice`) −2(CLAUDE.md §20). 동점은 팔레트 순서. **랜덤 없음.**
5. **적합한 유형 없음:** `selected: null`과 이유를 기록하고 WARNING `puzzle_selection_none`으로 보고한다. 임의로 고르지 않는다.
6. **계획과 비교(바꾸지 않음):** 계획 유형이 후보에 없으면 WARNING `puzzle_selection_unmatched`, 후보지만 1순위가 아니면 INFO `puzzle_selection_alternative`. 계획 기준으로 한 유형이 시즌의 1/3을 넘으면 `puzzle_type_overused`, 손으로 조작하는 퍼즐이 없는 Case는 `puzzle_case_no_hands_on`.
7. 선택 결과는 계획에 반영된 뒤 기존 절차(스키마 → `PlayCheck` → 레벨 → 역사 dossier 승인 → 게이트)를 그대로 통과해야 생성된다.

## 5. 제작 보고서 — `planning/puzzle_selection.json`

`plan_season.dart check`와 시즌팩토리 1단계가 **역사 모드 시즌에만** 쓴다. 같은 계획이면 같은 바이트(테스트). 미션마다:

| 필드 | 내용 |
|---|---|
| `caseId`, `missionId`, `surface` | |
| `traits` | 성격, 단서 단어, 출처(`words`/`factsOnly`) |
| `factIds` | dossier 퍼즐 항목의 사실 ID |
| `candidates` | 후보별 점수와 이유(감점 포함) |
| `selected`, `reason` | 규칙의 선택과 이유 |
| `planned`, `plannedIsSelected` | 계획의 실제 유형 |
| `checks.answerAndPlay` | 정답 유일성·해결 가능성 자동 검사(`PlayCheck`) 결과: `pass` 또는 문제 목록 |
| `checks.levels` | 난이도별 검사(`CaseLevels.checkCase`): `pass` / 문제 목록 / `not written` |
| `personReview` | 사람이 읽을 것(유형별 1줄 + 미검토·미등록 역사 항목) |

엔진별 자동 검사(`PlayCheck`):

| 유형 | 자동으로 막는 것 |
|---|---|
| `record_mismatch` | 다른 줄이 0개 또는 2개 이상(`records_ambiguous`), 옵션 ≠ 두 기록 공통 줄, 정답 ≠ 그 쌍, 줄보다 적은 행, 종이 밖 레이아웃, 같은 id |
| `trace_deduction` | 흔적 2–5개, 흔적 문장이 편지 줄과 글자 그대로 같지 않음, 장소 ≠ 옵션, 안내 위치가 흔적·장소 위, 그림 밖 영역 |
| `lens_inspect_word` | 일치 전시물·라벨이 각각 1개가 아님, 라벨이 일치 전시물로 열리지 않음, 확인되지 않는 편지 줄, 답할 줄을 다른 것이 확인, 돋보기 시작점이 전시물 위, 정답이 단어가 아님 |
| `evidence_talk` | 사건 인물이 아닌 화자, 단계 id 중복·`opening`, 없는 단계, 끝 조건에 빠진 제시, **그때 수첩에 없는 증거**(`talk_evidence_unheld`), 정답 증거가 없는 카드 두 장 |
| `number_entry` | 숫자가 아님, 자릿수 ≠ `codeLength`, 시각이 HHMM이 아님, 보기 있음 |
| 그림 공통 | 파일 없음·크기 불일치, 좌표 미측정·그림 변경 후(`coordinates_unmeasured/stale`) |

**사람 검토가 남는 것**: 흔적이 정말 한 곳만 가리키는지, 쪽지가 전시물 하나만 묘사하는지, 다른 줄이 의미 있는 모순인지, 각 프롬프트에 맞는 증거가 하나뿐인지, 숫자를 글에서 읽는지. 역사 모드에서는 `approve.dart … puzzle <id>`(7개 체크리스트)로 기록한다.

## 6. 실제 플레이 검증 (`test/sandbox/engines_season_test.dart`)

계획 → 실제 생성기 → 생성 파일 → 실제 앱. 세로 1170×2532 화면.

1. 게임 검증기 `SeasonContentValidator.validate` 이상 없음, 미션 타입·테이블이 계획대로.
2. 정답이 하나: 기록 9쌍 중 `time:time`만, 장소 3개 중 돌만, `stone`/`STONE`만.
3. 실제 앱(Case 01 해결 후 Case 02):
   - **M1 기록**: 두 기록을 탭으로 읽음 → 날짜 쌍(오답, Not quite!) → TRY AGAIN → 시각 쌍 → 해결
   - **M2 키패드**: 숫자 순서가 틀린 `714` → 계획의 오답 문장 → `417` → 해결
   - **M3 흔적**: 세 흔적 탭 → 벤치(오답) → 돌 → 해결
   - **M4 돋보기**: 석판 → 라벨 → `stone` 입력 → 해결
   - **앱 재실행** → 네 미션 해결 상태 유지, Final 미해결
   - **Final 대화**: 틀린 카드(오답 처리 안 됨, 미해결 유지) → 기록 카드 → 공구함 카드 → CLOSE THE CASE → 해결
   - 보상 지급 1회, 같은 답 재제출 시 코인 0

## 7. 신규·회귀 테스트 결과

- `flutter analyze`: **No issues found** (프로젝트 전체).
- 신규:
  - `test/season_gen/engines_generation_test.dart` **10개**: 계획 그대로 통과, 유형별 잘못된 계획 거부 6묶음(기록·키패드·흔적·돋보기·대화·알 수 없는 필드), 레벨 3개(세 레벨 정답 동일·각 엔진 검사 통과, 레벨에서 흔적 문장이 편지에서 빠지면 거부, 레벨별 생성·같은 바이트)
  - `test/season_planner/puzzle_selection_test.dart` **8개**: 성격 판정(사실만으로는 선택 안 함), 샌드박스 5개 미션의 선택 = 계획, 결정성, 후보 제한(생성 가능·화면), 다양성(Case 내 중복·시즌 1/3), 적합 유형 없음 보고, 일반 시즌 무출력, 역사 시즌 파일 기록·동일 바이트
  - `test/sandbox/engines_season_test.dart` **3개**(실제 앱 플레이 포함, §6)
  - `test/season_gen/history_dossier_test.dart` STEP 1 **4개**(전체 52개)
- 회귀 묶음 **884개**(3분 45초): `test/season_gen`, `test/season_planner`, `test/season_factory`, `test/sandbox` 전체, `test/puzzles_v2`, `timeline_board_test`, `puzzle_palette_test`, `puzzle_engine_collisions_test`, `difficulty_content_test`, `generated_seasons_test`, `full_playthrough_test`(London), `season_playthrough_test`(Rome·NY 포함), `back_navigation_test`, `history_reveal_ui_test`, `answer_checker_test`, `case01_deduction_test`, `case01_inspect_test`, `paris_case03_test`, `case_talk_test`
  - 첫 실행 883 통과 / 1 실패: `timeline_season_test`의 시즌 구성에 새 테이블 4개가 빠져 Case 02의 기록 미션이 "엔진 없음"으로 검증됨(테스트 쪽 누락). 테이블을 추가한 뒤 그 파일과 `engines_season_test`를 다시 실행해 **6개 통과**. 묶음 전체는 다시 돌리지 않았다.
- 전체 `flutter test`, Release 빌드: **실행하지 않음**(요청대로).

## 8. 기존 시즌 영향

- Season 1–4 콘텐츠·에셋 변경 없음. 기존 엔진 위젯·판정·저장 코드 변경 없음.
- Rome·NY: `generate_season --target game --check` → `up to date`(차이 0). s9 샌드박스 `--check` → `up to date`.
- Rome·NY `plan_season check`: `quality_report.json`이 커밋된 기준선과 **바이트 동일**(재작성 후 `git diff` 없음). 일반 시즌에는 `puzzle_selection.json`이 생기지 않는다(테스트).
- 생성기의 새 테이블과 import(`Size`, `TalkQuestion` 등)는 그 시즌이 쓸 때만 출력된다.

## 9. 남은 위험

1. **선택기는 키워드 규칙이다.** 문장의 의미를 이해하지 않는다. 단어 선택에 따라 성격이 달라질 수 있으므로 결과는 "제안 + 이유"로 쓰고, 다르게 계획하면 보고만 한다. 실제 서울 Case에서 규칙표를 한 번 조정해야 할 수 있다.
2. **추론의 공정성은 사람 판단**: 흔적·쪽지·증거 제시가 "하나로만" 수렴하는지는 자동으로 증명하지 못한다(구조와 문장 존재만 검사).
3. **기록 퍼즐의 그림 측정 부담**: 빈 종이의 네 모서리와 행 위치를 그림마다 측정해야 한다. 시즌마다 기록 용지 그림 1–2장을 재사용하는 것을 권장한다.
4. **`evidence_talk` 초상화**: 없으면 얼굴 없이 진행한다(대체 그림 금지 규칙). 기분별 초상화는 아직 생성하지 않는다(`base` 하나).
5. **샌드박스는 London·Paris 그림 재사용**: 새 그림에서의 좌표 정확도는 실기기·사람 확인이 필요하다.
6. **역사 모드 dossier 작업량 증가**: 모든 미션을 dossier에 등록해야 한다(창작 퍼즐 포함).
7. 실기기 확인 없음.

## 10. 서울 역사 사건 1개 시범 제작 가능 여부

**가능하다 — 단, 아래 조건에서.**

- 생성 경로: 15종 생성, 역사 dossier → 승인 3종 → 게이트, 규칙 기반 선택과 보고서까지 갖춰졌다.
- 잘 맞는 사건: 기록·연대·새긴 글·증언으로 풀리는 사건(예: 훈민정음 반포 과정의 기록 대조, 수표 수위 기록, 비문 읽기).
- 아직 못 하는 것: **장치 조작(측우기 눈금, 자격루 연쇄, 보신각 타종 횟수의 상태 변화)**은 `mechanism_sim`이 없어 선택기가 `puzzle_selection_none`으로 보고한다. **한글 자모 조합**(`glyph_compose`)도 없다. 이런 사건을 고르면 Case가 기존 유형으로만 구성된다.
- 시작 전 결정·준비가 필요한 것:
  1. 이야기 틀(A 현재 전시회 / B 시대 현장) 결정 — PART 2부터 미결
  2. Case 01 dossier: 출처를 실제로 열어 인용 → `source_checked` → 사용자의 fact 승인
  3. 그림 예산과 기록 용지 그림 측정
  4. 실기기 확인(한글 표기 필요 여부 포함: 번들 폰트에 한글 없음)
