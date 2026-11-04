# Puzzle Engine 2.0 — PART 3C Timeline Board 자동 생성 보고서

작성일 2026-11-04 · 범위: `timeline_board`를 시즌팩토리 자동 생성 경로(팔레트 → 계획 스키마 → 검사 → 생성기 → 게임 콘텐츠)에 연결했다.

- 하지 않은 것: 서울 시즌 생성, 기존 시즌 콘텐츠 변경, 유료 API 호출, 커밋.
- 검증은 테스트 전용 샌드박스 시즌 `s8_timeline`과 Rome 임시 사본으로만 했다.

## 1. 변경 파일

| 파일 | 내용 |
|---|---|
| `lib/data/content/puzzle_palette.dart` | `timeline_board` 등록(팔레트 맨 끝, ready, textOnly, `TimelineBoard`/`timelines`/`sequence`, 미션 전용) |
| `tool/season_gen/palette_facts.dart` | 팔레트 사본을 기존 작성 테스트(`PALETTE_FACTS_WRITE=1`)로 재생성(+9줄) |
| `tool/season_gen/plan_models.dart` | `TimelinePlan`, `TimelineCardPlan`, `TimelineRelationPlan`, `MissionPlayPlan.timeline`, `scenes['timelines']` |
| `tool/season_gen/schema/mission_plan.schema.json` | `play.timeline`, `timelineCard`, `timelineRelation` |
| `tool/season_gen/case_levels.dart` | 레벨 문구에서 제외할 키에 `anchor`, `factIds`, `earlier`, `later` 추가(기존 계획에 이 키가 없음을 확인) |
| `tool/season_gen/play_check.dart` | `generatable['timeline_board']`, `sceneKeys['timelines']`, `_timeline()` 검사(§4) — 게임의 `TimelineRules`를 `package:` import로 그대로 사용 |
| `tool/season_gen/puzzle_selection_check.dart` | `planFields`에 `TimelineSpec.cards/order/relations` 추가(계획이 보유하는 데이터) |
| `tool/season_gen/generate_case.dart` | `v2SceneTables`와 `scenesOf(plans)`(**타임라인을 쓰는 시즌에만** `timelines` 테이블 출력), `_timeline()` 생성, import 목록 |
| `tool/season_gen/history_dossier.dart` | 역사 모드 타임라인 검사(§5) |
| `tool/season_planner/season_quality.dart` | 타임라인 미션마다 INFO `timeline_reasoning_review` |
| `tool/season_planner/PLAYBOOK.md`, `tool/season_gen/GAMEPLAY_CATALOG.md` | 생성 가능 유형 표에 `timeline_board` |
| `test/sandbox/plans/s8_timeline/` | 신규: 테스트 전용 계획(샌드박스 Case 01, Mission 2가 타임라인) |
| `test/sandbox/generated/s8_timeline/` | 신규: 생성기 출력 4개 파일 |
| `test/season_gen/timeline_fixture.dart` | 신규: Rome 사본의 Case 08 M3를 타임라인으로 바꾸는 픽스처(레벨 문장 포함) |
| `test/season_gen/timeline_generation_test.dart` | 신규 11개 |
| `test/sandbox/timeline_season_test.dart` | 신규 3개(실제 앱) |
| `test/season_gen/history_dossier_test.dart` | 역사 모드 타임라인 6개 추가 |
| `test/puzzle_palette_test.dart`, `test/season_gen/palette_facts_test.dart` | 고정된 목록과 개수(28→29)에 `timeline_board` 추가. 모델 클래스 스캔에 `lib/puzzles_v2/core` 포함. "게임의 어떤 미션이 쓰는지" 검사에서 `timeline_board`만 이유를 적어 예외 처리(아직 쓰는 시즌이 없음, 샌드박스 플레이로 검증) |

## 2. 팔레트 및 스키마 변경

- **팔레트**:
  - 맨 끝에 추가했다. 기존 28개의 순서·등급·모드는 그대로다.
  - 엔진 선택 순서는 3B에서 정한 대로 마지막 단계다.
  - 플래너가 `paletteId: timeline_board`를 써야만 선택되므로 기존 계획에는 영향이 없다.
- **계획 스키마**(`missions[].play.timeline`, 선택 필드):

```jsonc
"timeline": {
  "cards": [                                   // 3–11장 (스키마), 세부 제한은 PlayCheck
    {"id": "key", "title": "THE KEY", "text": "…", "anchor": "9:00"},       // 고정 기준 카드
    {"id": "tom", "title": "TOM", "text": "…"},                              // 배치 카드
    {"id": "cat", "title": "THE CAT", "text": "…", "discard": true},         // 제외 카드
    // 역사 모드: "factIds": ["s5_ep02_h1"]  또는  "fiction": true
  ],
  "relations": [ {"earlier": "tom", "later": "bell", "line": "Mr. Bell came after Tom."} ]   // 3A의 earlier/later 유지
}
// puzzle: paletteId timeline_board, engineTable timelines, missionType sequence
// answerSpec.answer = 정답 순서(제외 카드 빼고), options = 카드(label = title), codeLength
// play.orderFeedback(오답), play.hints(힌트), 레벨 문구 = 기존 levels.json
```

- **카드 수 제한**:
  - 배치 2–6장, 고정 1–3장, 제외 0–2장
  - 최소값의 근거: 배치가 1장이면 고민할 것이 없다. 규칙 엔진은 정답 카드 3장 이상을 요구하므로 고정 1장 + 배치 2장이 최소다.
- 게임 쪽 모델(`TimelineSpec`)은 3A 그대로다. 출처(`factIds`, `fiction`)는 게임에 싣지 않고 계획과 역사 자료에만 둔다.

## 3. 자동 생성 과정

```
plan (play.timeline)
  → validate_plan: JSON Schema + Dart 모델 + PuzzleSelectionCheck(팔레트·엔진·타입)
  → PlayCheck._timeline: 게임과 같은 TimelineRules + 생성 규칙(§4)
  → (역사 모드) HistoryDossier: 카드 출처·사실 승인(§5)
  → generate_case.dart: <case>.g.dart의 <Case>Timelines,
       <season>_cases.g.dart의 <Season>Timelines,
       레벨이 있으면 <case>_levels.g.dart와 variants에 레벨별 TimelineSpec
  → 게임: SeasonContent.timelines → TimelineBoard (3B)
```

- **기존 결과 불변 장치**:
  - 생성기는 `timelines` 테이블을 그 시즌의 미션이 타임라인을 쓸 때만 쓴다(`scenesOf`). 따라서 Rome·NY·s9 샌드박스 출력은 바이트 단위로 같다.
  - 새 import(`timeline_rules.dart`)도 실제로 쓸 때만 들어간다.

## 4. 정답 유일성 검증 방식

| 확인 항목 | 방법 | 자동/사람 |
|---|---|---|
| 정답이 정확히 하나 | `TimelineRules.validate`: 앵커를 고정한 채 칸마다 관계가 허용하는 후보가 1장인지 시뮬레이션 (`timeline_ambiguous`) | 자동 |
| 앵커 연도와 관계의 모순 | 숫자 앵커가 앞으로만 흐름(`timeline_anchor_order`), 관계가 순서와 일치(`timeline_relation_contradicts`), 고정 칸 충돌 | 자동 |
| 배치 카드가 모두 정답에 필요 | 정답 = 제외 카드를 뺀 전 카드의 순열(`timeline_order_mismatch`). 각 배치 카드가 관계로 순서가 정해짐(소거법만으로 정해지면 `timeline_card_unrelated`) | 자동 |
| 제외 카드가 정답에 없음 | `timeline_order_mismatch` | 자동 |
| 실제 조작으로 완료 가능 | 페이지의 조작(`PlaceCard`, `DiscardCard`)으로 끝까지 두어 완료와 정답을 확인(`timeline_unplayable`) | 자동 |
| 게임 속 단서만으로 추론 | 각 관계의 `line`이 그 미션의 편지·이야기에 글자 그대로 있는지(`timeline_line_unread`). **레벨마다**: `CaseLevels.checkCase`가 레벨 계획에 `PlayCheck`를 다시 돌리므로, MASTER 편지 줄에서 관계 문장이 빠지면 거부됨(테스트로 확인) | 자동(문장 존재) |
| 그 문장들로 실제로 추론되는가 | 사람이 읽고 판단. 플래너가 미션마다 INFO `timeline_reasoning_review`를 남기고, 역사 모드에서는 퍼즐 승인(`approve.dart … puzzle`, 7개 체크리스트) | **사람** |
| 세 레벨의 정답 동일 | 정답·순서·앵커·id는 레벨 문구가 아니라서 레벨이 바꿀 수 없음(`_playNotText`). 게임 검증기(`_timelines`, `DifficultyContent.structureOf`)가 레벨별 구조와 정답을 비교 | 자동 |
| 기타 | 옵션 = 카드(`timeline_options_mismatch`), `orderFeedback` 필수, `codeLength` 일치, 카드 id에 계획 id 금지(`id_reserved`), 엔진 테이블과 장면 일치 | 자동 |

## 5. 역사 사실 승인 연동 (Historical Fiction Mystery 모드에서만)

- 모든 카드(제외 카드 포함)는 `factIds`(승인 대상 사실) 또는 `fiction: true` 중 **정확히 하나**를 가진다(`history_timeline_card_source`). 그래서 거짓 역사 문장이 제외 카드로 들어갈 수 없다.
- 카드의 사실은 기존 `uses()` 규칙을 그대로 따른다:
  - 없는 사실 → 오류
  - `rejected` → 오류(`history_fact_rejected`)
  - 미승인 → 이미지·게임 게이트 차단(`history_fact_unapproved`)
- 타임라인 미션은 역사 자료의 퍼즐이어야 한다(`history_timeline_unreviewed`). 카드의 사실은 그 퍼즐의 `factIds`에 모두 있어야 한다(`history_timeline_fact_unlisted`). 그래서 PART 2 퍼즐 승인 해시가 카드와 그 사실을 함께 덮는다:
  - 카드 문장이 바뀌면 퍼즐 승인이 `stale`
  - 카드 사실이 바뀌면 퍼즐 승인이 `stale`
  - (둘 다 테스트로 확인)
- 고정 카드의 연도:
  - 사실 카드면 그 사실의 문장에 있어야 함
  - 창작 카드면 Case의 fiction 줄에 선언되어 있어야 함
  - (`history_timeline_anchor_unsupported`)
- 카드 본문 속 연도는 PART 2의 `history_year_unsupported`가 그대로 검사한다(카드 문장도 미션의 글이므로).
- 기존 승인 절차를 우회하는 경로는 없다. 생성기와 팩토리의 역사 게이트(PART 1·2)를 그대로 쓴다.

## 6. 난이도별 생성 결과 (Rome 사본, Case 08 M3 "Livia의 일기")

| | ROOKIE | JUNIOR | MASTER |
|---|---|---|---|
| 카드 friday_am | Livia finds the piece is too light. | Livia notices the piece is too light. | Livia discovers the piece weighs far too little. |
| 카드 midnight | Livia takes the copy out. | Livia carries the copy out. | Livia slips out of the lab with the copy. |
| 관계 문장(편지 줄) | FRIDAY, MIDNIGHT — I turned off the lights and took the copy. | … I switched off the lights and took the copy. | … I switched off the lights and slipped out with the copy. |
| 고정 앵커 / 순서 | `TUESDAY` / tuesday, thursday, friday_am, midnight | 같음 | 같음 |

- `<case>_levels.g.dart`에 Junior·Master `TimelineSpec`이 각각 생성된다. 앵커와 순서는 두 레벨에서 같다(테스트).
- 시즌 레벨 파일의 `variants`에 `timelines:`가 들어간다.
- 같은 계획으로 두 번 생성하면 같은 바이트가 나온다.
- 카드 제목(ALL-CAPS 라벨)은 기존 규칙대로 세 레벨이 같다.

## 7. 샌드박스 실제 플레이 결과 (`test/sandbox/timeline_season_test.dart`)

테스트 전용 시즌 `s8_timeline`(계획 → 실제 생성기 → 커밋 전 생성 파일 → 실제 앱):

1. 생성 파일이 계획과 바이트 단위로 같고, 두 번 생성해도 같음
2. 게임 검증기 `SeasonContentValidator.validate` 이상 없음, 미션 타입 `sequence`, 정답 `key,tom,bell,lee`
3. 실제 앱:
   - Story Intro
   - Mission 1(기존 텍스트 선택) 풀이
   - Mission 2 타임라인 진입: `9:00 THE KEY` 고정, 카드 4장
   - 오답 배치 → 계획의 오답 문장("Who came after Tom?") → TRY AGAIN → "CHECK THIS ONE"
   - 무료 힌트(계획의 힌트 문장)
   - **앱 재실행** → 배치·제외 그대로 복원
   - 정답 → 코인 지급 → 재제출 코인 0
   - 재열람 → `WHAT HAPPENED`에 정답 순서

## 8. 신규·회귀 테스트 결과

- `flutter analyze`: **No issues found**.
- 신규:
  - `timeline_generation_test` **11개**
    - Rome 사본 플래너 전체 검사 ERROR 0 + 리뷰 INFO
    - 레벨 검사 통과
    - MASTER에서 관계 문장이 사라지면 거부
    - 레벨별 생성
    - 원본 Rome 출력에 타임라인 없음
    - 잘못된 계획 거부 6묶음: 크기, 모호, 모순, 옵션, 읽히지 않는 문장, id
  - `timeline_season_test` **3개**
  - `history_dossier_test`에 역사 모드 타임라인 **6개**(전체 48개)
- 생성 결과 불변:
  - Rome·NY: `generate_season --target game --check` → `up to date`
  - s9 샌드박스·s8: `--check` → `up to date`
  - Rome·NY `plan_season check --all` 출력이 PART 1 이전 기준선과 **동일**
- 회귀 묶음 **774개 모두 통과**(200초):
  - `test/season_gen`, `test/season_planner`, `test/season_factory`, `test/sandbox` 전체, `test/puzzles_v2`
  - `timeline_board_test`, `puzzle_palette_test`, `puzzle_engine_collisions_test`, `difficulty_content_test`, `generated_seasons_test`
  - `full_playthrough_test`(London), `season_playthrough_test`, `back_navigation_test`, `history_reveal_ui_test`, `answer_checker_test`
- 전체 `flutter test`, Release 빌드: **실행하지 않음**(요청대로).

## 9. 남은 위험

1. **추론 가능성은 사람 판단**: 관계 문장이 편지에 있는지까지만 자동으로 본다. 그 문장이 아이에게 명확한 순서 단서인지는 리뷰(`timeline_reasoning_review`, 역사 모드는 퍼즐 승인)에 의존한다.
2. **관계 문장과 편지의 글자 일치 규칙**: 편지를 고쳐 쓰면 관계 문장도 같이 고쳐야 한다. 레벨별로 편지 줄이 바뀌면 관계 문장도 같은 레벨 문장으로 써야 한다(검사가 잡아 줌).
3. **비숫자 앵커**(`TUESDAY`, `9:00`)는 순서 비교를 하지 않는다. 고정 위치로만 쓰이므로 모순 검사는 관계와 정답 순서에 의존한다.
4. **팔레트 예외**: `timeline_board`는 게임 시즌이 쓰기 전까지 "게임 미션 사용" 검사에서 예외다. 첫 실제 시즌이 쓰면 예외를 지워야 한다(테스트 주석에 적어 둠).
5. **자동 선택기 미구현**: 어떤 미션에 타임라인을 쓸지는 아직 기획자(Claude)가 고른다. 사실 성격에 따른 결정론적 선택과 선택 이유 보고는 3K 범위다.
6. 실기기 확인 없음.

## 10. 다음 PART 진행 가능 여부

**진행 가능.** 설계 문서의 권장 순서대로 다음은 **3I(기존 엔진 6종 자동 생성 지원)**이다. 이번 PART의 구조를 그대로 쓰면 된다: 팔레트 `generatable`, 계획 `play.*`, `PlayCheck`, 생성기의 테이블 출력. 그다음 3J(역사 연동 정리)와 3K(자동 선택기)로 가면 서울 시즌 제작에 필요한 생성 경로가 갖춰진다.
