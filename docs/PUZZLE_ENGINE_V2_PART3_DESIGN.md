# Puzzle Engine 2.0 — PART 3 조사·설계

작성일 2026-11-04 · 범위: 조사와 설계만. 코드·에셋·시즌 데이터 변경 없음, 커밋 없음, 유료 API 호출 없음.

표기: **[확인]** = 이번 조사에서 소스를 직접 읽어 확인. **[추정]** = 구조상 그렇다고 보지만 실행해 보지 않음.

## 0. 선행 확인 — Historical Fiction Mystery PART 1·2 상태

- PART 1·2 코드가 작업 트리에 그대로 있다(커밋 전, 변경 25개 파일). 마지막 커밋은 `ba79290`.
- `flutter analyze`: No issues found **[확인, 이번 실행]**.
- `test/season_gen/history_dossier_test.dart` 42개 + `test/history_reveal_ui_test.dart` 7개 = **49개 통과 [확인, 이번 실행]**.
- 결론: PART 2는 보고서(`docs/HISTORICAL_FICTION_MYSTERY_PART2_REPORT.md`)대로 완료 상태다. 이 설계는 그 위에 얹는다.

---

## 1. 기존 퍼즐 유형 전체 목록

근거: `tool/season_gen/GAMEPLAY_CATALOG.md`(2026-10-29)를 현재 코드와 대조했다 **[확인]**.

- `PuzzleEngineDispatch`(`lib/data/content/puzzle_engine_collisions.dart`): 미션 화면 단계 40개, Final 화면 단계 13개
- `PuzzlePalette`(`lib/data/content/puzzle_palette.dart`): 등록 28개
- `PlayCheck.generatable`(`tool/season_gen/play_check.dart`): 생성기 지원 9개

카탈로그 이후 엔진 추가는 없었다. 단, 카탈로그 §3.6의 "난이도별 문구 ❌"는 이제 맞지 않는다. Rome·NY에서 `levels.json`으로 지원된다.

### 1.1 엔진 수

| 구분 | 수 | 비고 |
|---|---|---|
| 실제 쓰이는 엔진 | 46 | 기본 질문 위젯 6 + 테이블 엔진 40 |
| 팔레트 등록 | 28 | 다른 시즌이 재사용할 수 있게 정리된 것 |
| 팔레트 밖 Paris 전용 | 23 | 그 Case 전용 위젯 |
| **생성기 지원** | **9** | `text_choice`, `word_entry`, `order_sequence`, `letter_tile_lock`, `combo_dial_lock`, `picture_choice`, `scene_explore_choose`, `dark_room_search`, `witness_compare` |

### 1.2 실제 게임 방식으로 묶은 분류 (이름만 다른 것과 방식이 다른 것 구분)

| 실제 탐정 활동 | 실제 조작 | 해당 엔진 (팔레트 id / 테이블) | 비고 |
|---|---|---|---|
| 읽고 고르기 | 보기 탭 | `text_choice`, `picture_choice`, `clue_filter_choice`(`canvases`), `viewpoint_match`(`cornerChoices`) | 같은 방식(보기 id 판정). 그림·필터는 표현만 다름 |
| 읽고 입력 | 키보드/키패드/타일 | `word_entry`, `number_entry`, `letter_tile_lock` | 문자열 판정. 입력 수단만 다름 |
| 순서 | 순서대로 탭 | `order_sequence`, `trails`(그림 위 흔적 순서) | id 순서 판정 |
| 잠금 | 다이얼 회전 | `combo_dial_lock`, `symbol_dial_lock`(`dialLocks`), `clock_set`(`clocks`, `finalClocks`) | 상태 문자열 판정 |
| 장면 조사 | 그림 탭·확대·드래그 | `scene_explore_choose`(`explores`), `dark_room_search`(`investigations`), `lens_inspect_word`(`inspections`), `trace_deduction`(`deductions`), `object_decode`(`decodes`) | 조사 후 선택·입력 또는 오답 없음 |
| 차이 찾기 | 두 그림/문서 탭 | `spot_difference`(`compares`), `record_mismatch`(`records`), `layer_reveal`(`layers`) | 집합 판정(`answersASet`) |
| 짝짓기 | 두 항목 연결 | `room_find_match`(`studios`), `symbol_join`, 수첩 `evidenceLinks`(수동적) | `matchPairs` |
| 증언 | 질문 → 진술 노트 → 비교/제시 | `witness_compare`(`dialogues`), `evidence_talk`(`talks`), `talkMissions`(듣기만) | |
| 추론 보드 | 질문 → 증거 연결 → 결론 | `evidence_board`(`evidenceBoards`, P03-F·P08-F) | 상태 저장(`puzzleStates`). `requiresDevelopment`(Case 전용 무대) |
| 단계 안내 | 한 화면 한 동작 | `guided_steps`(`easySteps`, P 13개) | |
| Case 전용 장치 | 고유 조작 | Paris 전용 23개(`LiftRoute`, `GearBoardPuzzle`, `DrumTapePuzzle`…) | 재사용 불가 |

### 1.3 공통 처리 [확인]

| 항목 | 실제 동작 |
|---|---|
| 데이터 | `Episode`(missions + finalMission), `Mission`(`MissionType` 17개, answer, options, hints, clue, evidence …), 엔진 데이터는 `SeasonContent`의 테이블(미션 id 키) |
| 정답 판정 | 모든 엔진이 `GameController.submitAnswer(mission, answer)` → `AnswerChecker` |
| 오답 | 선택형은 `ChoiceOption.feedback`, 입력·순서형은 `Mission.feedback`/`orderFeedback`. 오답 시 첫 시도 보너스만 잃고 바로 재시도 |
| 힌트 | 미션마다 2개(`AppConstants.maxHints`), 무료 힌트·팁 숍 공통 |
| 난이도 | 문구만 다름: `casePatches`(Case JSON 위에 덮어쓰기), `variants`(퍼즐 테이블의 레벨별 사본), `levels.json` → `*_levels.g.dart`. 게임·정답·보상은 동일(`Difficulty` 주석, `difficulty_content_test`) |
| 저장 | `GameProgress.completedMissionIds`(목록), attempts·wrongAnswers·hintsUsed·solveSeconds, **`puzzleStates`(미션별 문자열, 재시작 시 복원. 모르는 문자열이면 처음부터)**, `revealed` |
| 보상 중복 방지 | `_submitAnswer` 첫 줄: `if (state.isCompleted(mission.id)) return correct` — 순서와 무관하게 한 번만 지급 |
| 해금 | `GameProgress.isUnlocked` = 완료했거나 `currentMission`(앞에서부터 첫 미완료)과 같을 때. **엄격한 선형**. 사용처: `currentMission` 5곳(3개 파일), `isUnlocked` 9곳 |
| 이미지 | 장소 그림 + 엔진별 그림(`ScenePixels` 좌표, 0..1 비율) |
| 사운드 | 공용 효과음(`GameSound`), 엔진별 생성 없음 |
| 자동 생성 | Plan(`play.*`) → `PlayCheck` → `generate_case.dart`의 `sceneTables`(explores, investigations, dialogues)와 `storyTables`(talkMissions, discoveries, endings) |

---

## 2. 신규 퍼즐 유형 후보 — 요청 6종 판정

| 요청 유형 | 판정 | 근거 | 대신 할 일 |
|---|---|---|---|
| Evidence Comparison | **중복 — 제외** | 그림 차이는 `spot_difference`(P02-M1), 문서 차이는 `record_mismatch`(P03-M1) | 두 기존 엔진을 생성기에 추가(3I) |
| Timeline Reconstruction | **부분 신규 — 채택** | `order_sequence`는 "보기를 순서대로 탭"뿐. 새 요소: 고정 앵커 카드(연대 명시), 상대 시간 영어("two years later", "before the bell") 추론, 무관 카드 버리기, 칸별 피드백, 여러 Case의 증거 카드. 답 형식은 같은 id 순서 | `timeline_board` |
| Evidence Connection | **기존 엔진 일반화 — 채택** | `EvidenceBoard`(P03-F·P08-F)가 이미 질문→증거 연결→결론을 하고 상태를 저장한다. 다만 Case 전용 무대(`requiresDevelopment`). 새로 더할 것: 인물·장소·시간 노드, 관계 종류("was at", "wrote") | `deduction_board`(EvidenceBoard 데이터화) |
| Scene Investigation | **중복 — 제외** | `scene_explore_choose`·`dark_room_search`(생성 지원), `lens_inspect_word`·`trace_deduction`(엔진 있음) | `trace_deduction`, `lens_inspect_word`를 생성기에 추가(3I) |
| Testimony Analysis | **중복 — 제외** | 진술 비교는 `witness_compare`, 증거 제시로 반박은 `evidence_talk`(P11-F), 기록 대조는 `record_mismatch` | `evidence_talk`(질문·제시)을 생성기에 추가(3I) |
| Historical Mechanism | **신규 — 채택** | 장치 조작은 `clock_set`(`Artwork` enum에 묶임)과 Paris 전용 `GearBoard`·`TowerTest`뿐. 데이터로 정의되는 범용 장치 엔진은 없음 | `mechanism_sim`(+ 글자 조합 변형 `glyph_compose`) |

**실제 신규 엔진은 2개**: `timeline_board`, `mechanism_sim`. 여기에 기존 엔진을 일반화한 `deduction_board` 1개와, 기존 엔진 6개(`spot_difference`, `record_mismatch`, `trace_deduction`, `lens_inspect_word`, `evidence_talk`, `number_entry`)의 생성기 지원을 더한다. 시즌의 체감 다양성은 후자가 더 빨리, 더 싸게 늘린다.

### 2.1 `timeline_board` — 사건 재구성

| 항목 | 설계 |
|---|---|
| 터치 조작 | 카드 더미에서 카드를 끌어 타임라인 칸에 놓기. 대안: 카드 탭 → 칸 탭(드래그 없이). 칸의 카드를 탭하면 더미로 되돌림. "NOT PART OF IT" 칸으로 무관 카드 버리기 |
| 화면 | 위쪽에 문서·단서 접힘 패널(읽은 편지 다시 보기), 가운데 세로 타임라인(앵커 카드는 고정·잉크 날짜), 아래쪽 카드 더미. 작은 화면에서도 세로 목록이라 가로 스크롤 없음 |
| 정답 판정 | 비-버림 카드의 id 순서 문자열 `c1,c3,c2,c4`. 버림 카드는 정답에 포함하지 않고, 버림 칸에 있어야 함 → 기존 `sequence` 판정과 같은 형식(`AnswerChecker` 재사용). CHECK 버튼으로 제출 |
| 오답·힌트 | 오답 시 "처음으로 틀린 칸"만 흔들고 그 카드의 `because`를 가리키는 문장 표시(정답은 말하지 않음). 힌트 1은 어느 문서를 볼지, 힌트 2는 앵커 하나 기준으로 생각하는 법 |
| 레벨 | 카드 제목·본문·이유 문장이 레벨별 문구(levels.json). 카드 수·앵커·정답은 동일 |
| 접근성 | 카드마다 `Semantics(customActions: move up/down, place, discard)`. 드래그 필수 아님. 48dp. 큰 글자에서 카드 높이 자동 |
| 상태 저장 | `puzzleStates[missionId] = "tl1:{slots:[…],discard:[…]}"` |
| 자동 테스트 | 순수 Dart reducer 단위 테스트 + 탭만으로 푸는 위젯 테스트 |
| 생성기 | 텍스트 카드만이면 `textOnly`, 증거 그림 카드면 기존 증거 그림 재사용(새 그림 불필요) → 자동 생성 가능 |
| **자동 유일성 검사** | 계획의 `relations`(A before B, 근거 문장) + 앵커 연대로 위상 정렬했을 때 순서가 **정확히 하나**인지(각 단계에서 후보가 1개). 근거 문장이 게임 글에 실제로 있는지도 검사(`reportLine` 방식) |

### 2.2 `deduction_board` — 증거 연결 (EvidenceBoard 일반화)

| 항목 | 설계 |
|---|---|
| 터치 조작 | 질문 카드 탭 → 노드(증거·인물·장소·시간) 탭으로 연결 → 관계 종류가 둘 이상이면 시트에서 선택. 다시 탭하면 해제. 모든 질문이 채워지면 결론 고르기 → SOLVE THE CASE |
| 화면 | 기존 EvidenceBoard의 종이 보드 시각 언어 재사용. 좁은 화면(360dp 미만)에서는 공간 그래프 대신 "질문 → 연결 칩" 목록 레이아웃 |
| 정답 판정 | 정렬된 연결 집합 + 결론 id를 정규 문자열로(`q1:n3/wrote;q2:n5|k2`). `AnswerChecker`에 집합 비교 경로(이미 `answersASet` 개념 있음) |
| 오답·힌트 | 틀린 연결이 있는 질문만 표시하고(어느 노드인지는 말하지 않음) 결론은 유지. 힌트는 질문별 |
| 레벨 | 질문·노드 이름·결론 문장이 레벨 문구 |
| 상태 저장 | 기존 EvidenceBoard처럼 변경 즉시 `puzzleStates` |
| 생성기 | 노드가 수첩 증거(`evidence` id)와 시즌 인물·장소를 재사용 → 새 그림 거의 불필요 |
| 자동 검사 | 각 정답 연결의 `because` 문장이 게임 글에 있는지. 결론이 정답 연결들로만 도출되는지는 사람 검토(퍼즐 체크리스트) |

### 2.3 `mechanism_sim` — 역사적 장치의 원리 조작 (신규)

데이터로 정의하는 작은 상태 기계: 조작부(controls), 상태 변수, 표시 규칙, 목표.

| 변형 | 예(서울 후보) | 조작 |
|---|---|---|
| `measure` | 측우기 눈금 읽기·수표 수위 | 물 높이 슬라이더/스테퍼 → 표시되는 눈금 |
| `count` | 보신각 인정 28·파루 33 → 문 닫힘·열림 | 종 치기 횟수 → 문 상태 |
| `sequence` | 자격루 구슬→인형→종/북 연쇄 | 부품 순서대로 작동시키기 |
| `compose`(`glyph_compose`) | 훈민정음: 기본자 + 획 더하기(가획) → 글자, 초·중·종성 → 음절 | 획/자모 조각을 칸에 놓기 |

| 항목 | 설계 |
|---|---|
| 화면 | 장치 일러스트(기존 장면 그림 규칙: 글자 없음) 위에 조작부 오버레이. 게임 속 "장치 설명서" 카드(원리를 영어로, 역사 근거 factIds)를 언제든 펼침 → 사전 지식 불필요 |
| 정답 판정 | 목표 상태의 정규 문자열(`level=6;gate=open`) → 문자열 판정 |
| 오답·힌트 | CHECK 시 목표와 다른 변수 하나에 대해 설명서의 해당 문장을 가리킴. 힌트 1은 설명서의 어느 줄, 힌트 2는 그 줄을 현재 상태에 적용하는 법 |
| 레벨 | 설명서·라벨 문구만 다름. 상태 공간·목표 동일 |
| 접근성 | 스테퍼(＋/－ 버튼), 토글, 슬롯 선택. 연속 드래그 없이도 조작 가능. 상태 변화는 `SemanticsService.announce` |
| 상태 저장 | `puzzleStates`에 `ms1:{vars}` |
| 자동 검사 | 목표 상태에 도달 가능(BFS, 상태 수 상한), 목표가 단 하나, 설명서가 규칙의 키 토큰(숫자·부품 이름)을 담는지 |
| 한글 표시 | 폰트 대신 **획 벡터 데이터**(`CustomPainter`)로 그린다. 번들 폰트(Sentient, IMFellEnglishSC, LibreBaskerville)에 한글이 없고 **[확인]**, 가획 원리를 보이려면 획 단위가 필요하다. 그림 속 글자 금지 규칙과도 충돌하지 않음 |

---

## 3. 권장 엔진 아키텍처

### 3.1 원칙
- **기존 디스패치는 그대로 둔다.** 새 테이블 3개(`timelines`, `boards`, `mechanisms`)를 `SeasonContent`에 기본값 `const {}`로 추가하고, `PuzzleEngineDispatch.mission`/`finalMission` 끝에 단계를 덧붙인다. 기존 미션은 새 테이블에 키가 없으므로 고르는 엔진이 같다(`PuzzleEngineCollisionCheck`가 충돌을 잡음).
- **규칙과 화면 분리**: 엔진마다 Flutter를 import하지 않는 순수 Dart 코어를 둔다. 게임 위젯과 시즌팩토리(plain `dart run`)가 같은 규칙 코드를 쓴다. 생성기의 유일성·도달성 검사가 게임과 같은 규칙으로 돌아간다(현재 `palette_facts.dart`의 복사 방식보다 안전함).

```
lib/puzzles_v2/
  core/                      ← Flutter import 금지(테스트로 강제)
    engine_contract.dart     PuzzleCoreV2<S>: initial, reduce(S, Action), answerOf(S), encode/decode(S), firstProblem(S)
    timeline_core.dart       TimelineSpec, TimelineState, solveUnique(spec)
    board_core.dart          BoardSpec, BoardState
    mechanism_core.dart      MechanismSpec(작은 규칙 언어), MechanismState, reachable(spec)
    glyph_strokes.dart       한글 기본자 획 데이터(가획 단계)
  widgets/
    timeline_board.dart  deduction_board.dart  mechanism_stage.dart  glyph_canvas.dart
```

- 위젯은 상태를 `reduce`로만 바꾸고, 바뀔 때마다 `encode`로 `puzzleStates`에 저장하고, CHECK 시 `answerOf`를 `submitAnswer`에 보낸다. 판정·보상·저장 경로는 기존 그대로다.
- `MissionType`: 타임라인은 기존 `sequence`, 보드와 장치는 기존 문자열 비교 경로를 쓴다. 보드의 집합 비교가 필요하면 `matchPairs` 판정을 재사용하는지 3D에서 확인한다(enum 추가는 최후 수단. 저장은 미션 id만 쓰므로 추가해도 저장 호환에는 문제없음 [확인]).

### 3.2 팔레트·생성기 등록
- `PuzzlePalette`에 `timeline_board`, `deduction_board`, `mechanism_sim` 등록 → `palette_facts.dart` 자동 갱신 테스트(`palette_facts_test`)를 함께 수정.
- `PlayCheck.generatable`에 추가하고 `generate_case.dart`의 `sceneTables`에 `timelines`/`boards`/`mechanisms` 모델을 추가.

---

## 4. 신규 퍼즐 데이터 스키마 (CasePlan `missions[].play.*`, 모두 선택 필드)

```jsonc
// timeline_board — puzzle: { paletteId: "timeline_board", engineTable: "timelines", missionType: "sequence" }
"timeline": {
  "axis": "years",                        // years | hours | steps (화면 표기만)
  "cards": [
    {"id": "c1", "title": "THE RAIN GAUGE", "text": "Rain is measured in a bronze cup.", "anchor": "1441", "factIds": ["s5_ep02_h1"]},
    {"id": "c2", "title": "THE LETTER", "text": "…", "evidence": "s5_ep01_e2"},
    {"id": "c9", "title": "A SHOPPING LIST", "text": "…", "discard": true}
  ],
  "relations": [ {"before": "c1", "after": "c2", "line": "Two years after the bronze cup, …"} ],
  "wrongLine": {"c2": "Read the letter again: what came first?"}
}
// answerSpec.answer = "c1,c2,…" (버림 카드 제외), answerSpec.options = 카드(라벨)

// deduction_board — engineTable: "boards", 결론 선택은 options
"board": {
  "nodes": [ {"id": "n1", "kind": "person", "charId": "…"}, {"id": "n2", "kind": "evidence", "evidence": "s5_ep02_e1"},
             {"id": "n3", "kind": "place", "placeId": "s5_seoul.bosingak"}, {"id": "n4", "kind": "time", "label": "AT DAWN"} ],
  "relations": ["was at", "wrote", "took"],
  "questions": [ {"id": "q1", "text": "Who wrote the false note?", "links": [{"node": "n1", "relation": "wrote", "line": "…"}]} ],
  "conclusion": "k2"
}

// mechanism_sim — engineTable: "mechanisms"
"mechanism": {
  "kind": "count",                                  // measure | count | sequence | compose
  "picture": "assets/seasons/season_05_seoul/puzzles/bell.webp", "pixels": [1536, 1024],
  "controls": [ {"id": "strikes", "type": "stepper", "min": 0, "max": 40, "label": "STRIKES"} ],
  "vars": {"gate": ["closed", "open"]},
  "rules": [ {"when": {"strikes": 28}, "set": {"gate": "closed"}, "show": "The gates close."},
             {"when": {"strikes": 33}, "set": {"gate": "open"},   "show": "The gates open."} ],
  "manual": [ {"text": "At dawn the bell rings 33 times …", "factIds": ["s5_ep04_h1"]} ],
  "target": {"strikes": 33, "gate": "open"}
}
// compose 변형: "parts": [{"id": "g_base", "glyph": "ㄱ"}, {"id": "stroke", "glyph": "+stroke"}], "slots": […], target = 조합 결과 id

// Case 단위 진행 흐름 (§5) — CasePlan 최상위, 선택
"flow": {"kind": "open", "requires": {"m3": ["evidence:s5_ep01_e1", "evidence:s5_ep01_e2"], "final": ["m1", "m2", "m3"]}}
```

- 레벨 문구: `play` 아래 문자열은 `CaseLevels._visit`가 자동으로 레벨 대상으로 삼는다. 새 비텍스트 키(`id`, `axis`, `anchor`, `relation`, `kind`, `node`, `type`, `when`, `set`, `target`, `vars`, `glyph` …)는 `_playNotText`에 추가해야 한다. **이 키들이 기존 Rome·NY·sandbox 계획의 `play` 안에 이미 있는지 먼저 확인한다.** 있으면 기존 레벨 추출이 바뀌므로 이름을 바꾼다(3A 검증 항목).
- 스키마 3계층(JSON Schema + Dart 모델 + `season_gen_schema_test`)을 함께 갱신한다. 기존 규칙과 같다.

---

## 5. 동적 미션 진행 구조

### 5.1 흐름 종류 (Case별 선택, 강제 아님)

| 흐름 | 의미 | 데이터 |
|---|---|---|
| `linear`(기본, `flow` 없음) | 현재와 100% 동일 | — |
| `open` 자유 조사 | 지정한 미션들을 아무 순서로 | `requires` 없는 미션들 |
| 증거 기반 해금 | 특정 증거·단서를 모으면 다음 미션 | `requires: ["evidence:<id>", "clue:<id>"]` |
| 다중 증언 조사 | 인물별 대화 미션(open) → 기록 비교 미션(모든 대화가 requires) | open + requires |
| 사건 재구성 | 모은 증거로 `timeline_board`(여러 Case 증거 가능) | requires + recall 입력 |
| 최종 추론 | Final을 `deduction_board`로 | `final` requires |

### 5.2 구현
- `CaseFlow`(순수 Dart, `Episode.flow`, JSON 선택 필드) — `isUnlocked(progress, missionId)`와 `suggestedNext(progress)`.
- `GameProgress.isUnlocked`: `episode.flow == null`이면 기존 코드 그대로. 있으면 `CaseFlow`에 위임.
- `currentMission`의 의미를 "다음 추천 미션"(계획 순서상 해금된 첫 미완료)으로 유지한다. 지도·라우터·Case 해결 판정이 그대로 동작하고, flow가 없으면 결과가 같다.
- 지도: 해금된 핀이 여러 개 동시에 켜진다. 잠긴 핀은 "필요한 증거" 문구(레벨 문구 포함).
- **저장**: 새 필드 없음. `completedMissionIds`는 순서와 무관한 집합으로 쓰이고, 수첩 단서 순서는 완료 순서라 자유 순서도 자연스럽다 **[확인: `collectedClues`]**. 미션 안 진행은 `puzzleStates`.
- **중복 보상**: `_submitAnswer`의 `isCompleted` 선검사로 이미 보장된다 **[확인]**. 자유 조사에서도 재진입하면 해결 상태 화면만 보인다.
- **뒤로가기·복귀**: 지도가 허브. 미션 화면의 Back 규칙은 그대로이고, 앱을 다시 열면 `activeEpisodeId` → 지도.
- **단서 그래프 검사 변경(중요)**: `ClueGraphCheck`는 "단일 플레이 순서"를 가정한다 **[확인: README]**. flow가 있는 Case에서는 "입력 단서를 만드는 미션이 그 미션의 **필수 선행**(requires의 전이 폐포)인가"로 판정해야 한다. 그래야 어떤 순서로 플레이해도 단서가 먼저 나온다. 역사 dossier의 `history_clue_late`도 같은 기준으로 바꾼다.

---

## 6. 역사 검증 시스템 연동

PART 1·2의 `history_dossier.json`, `HistoryGate`, 승인 3종을 그대로 쓰고, 검사 대상을 새 스키마로 넓힌다.

| 규칙 | 새 엔진에서 |
|---|---|
| 역사 사실은 승인된 dossier 근거 | 타임라인 카드·앵커, 보드 연결, 장치 설명서 줄의 `factIds`가 모두 승인(게이트). 카드 앵커 연도는 그 사실 statement에 있어야 함(`history_reveal_unsupported`와 같은 연도 검사) |
| 창작과 사실 구분 | 버림 카드는 "사실이지만 무관"(factIds 필수) 또는 "창작"(dossier `fiction`에 선언) 중 하나여야 함. **거짓 역사 문장인 버림 카드 금지** |
| 지식은 게임 안에서 | 장치는 `manual`, 타임라인은 `relations[].line`, 보드는 `links[].line`이 게임 글에 실제로 있는지 자동 검사(레벨별). 기존 `clues` 검사를 엔진 데이터에서 자동 도출 |
| 정답이 명확·검증 가능 | 타임라인 위상 정렬 유일성, 장치 BFS 목표 유일성은 자동. 보드는 사람 체크리스트 |
| 오답·힌트가 역사 왜곡 금지 | 기존 연도 검사(`history_year_unsupported`)가 카드·설명서·피드백 문구까지 적용(play 문자열 전체). 서술 왜곡은 퍼즐 승인 체크리스트 7번 |
| 진행을 끊지 않음 | 퍼즐 안에서는 설명서·카드 같은 게임 속 사물로만 역사를 주고, 긴 설명은 Case Closed의 REAL HISTORY(PART 2)로 미룸. 해결 직후 Discovery Moment에 한 줄만 허용 |
| 퍼즐 승인 해시 | PART 2의 `historyPuzzle` 해시는 미션 JSON 전체를 포함하므로 `play.timeline`/`board`/`mechanism` 변경 시 자동 재검토 **[확인: historyPayload]** |

---

## 7. 저장·복귀·난이도 호환 전략

| 항목 | 전략 | 기존 영향 |
|---|---|---|
| 저장 스키마 | 새 키 없음. 미션 안 상태만 `puzzleStates`에 버전 접두사(`tl1:`, `bd1:`, `ms1:`) | 없음. 모르는 문자열이면 처음부터(기존 계약) |
| 저장 버전 변경 | 디코드 실패 시 초기 상태. 해결한 미션은 `completedMissionIds`로 이미 고정 | — |
| 보상 | 기존 `submitAnswer` 경로만. 엔진은 지급하지 않음 | 정책 불변 |
| 난이도 | 문구만 레벨별(levels.json). 카드 수·앵커·노드·장치 상태 공간·정답은 동일. `CaseLevels.sameGame`이 이를 강제하도록 새 비텍스트 키 등록 | 난이도 고정 정책 불변 |
| 진행 흐름 | `flow` 없음 = 선형 그대로 | Season 1–4는 `flow`가 없음 |
| 기존 시즌 | 새 테이블 기본 `const {}`. 디스패치 끝에 추가. 생성기는 새 키가 있을 때만 출력 | 완료 조건: Rome·NY `generate_season --check` 차이 0, `plan_season check` 출력 동일(PART 1·2와 같은 방법) |

---

## 8. 예상 변경 파일과 작업량

| 영역 | 파일 | 규모 감 |
|---|---|---|
| 순수 코어 | `lib/puzzles_v2/core/*` (신규 5) + 테스트 | 중 |
| 위젯 | `lib/puzzles_v2/widgets/*` (신규 4) | 대 (디자인 품질 요구) |
| 디스패치·콘텐츠 | `puzzle_engine_collisions.dart`(단계 추가), `season_catalog.dart`(테이블 3), `mission_page`/`final_mission_screen`(분기 연결) | 소–중 |
| 팔레트 | `puzzle_palette.dart`, `palette_facts.dart`, `palette_facts_test` | 소 |
| 흐름 | `episode.dart`(`flow`), `game_progress.dart`(`isUnlocked` 위임), `mission_map_screen.dart`(다중 핀·잠김 문구), 신규 `case_flow.dart` | 중 (회귀 위험 가장 큼) |
| 계획·검사 | `schema/mission_plan.schema.json`, `case_plan.schema.json`, `plan_models.dart`, `play_check.dart`, `clue_graph_check.dart`(부분 순서), `case_levels.dart`(`_playNotText`) | 중 |
| 생성기 | `generate_case.dart`(`sceneTables` 3, flow 출력), 기존 엔진 6종 생성 지원 | 중–대 |
| 역사 연동 | `history_dossier.dart`(새 스키마 factIds·버림 카드·설명서 검사, 부분 순서) | 소–중 |
| 퍼즐 선택 | 신규 `tool/season_planner/puzzle_selection.dart`, `planning/puzzle_selection.json`, PLAYBOOK·스킬 | 중 |
| 샌드박스 | `content_pipeline/seasons/s9_sandbox/` 새 Case(새 엔진·흐름 예제) + playthrough 테스트 | 중 |

### 8.1 시즌팩토리 자동 선택 (“Season 5 Seoul을 Historical Fiction Mystery 모드로 제작해 줘”)

- **결정론적 점수표**로 고르고, 랜덤은 쓰지 않는다. Claude가 계획을 쓰고 도구가 근거를 검사하는 기존 분업(PLAYBOOK)을 유지한다.
- 입력:
  - dossier의 사실 성격 태그: `device`, `chronology`, `relationship`, `document`, `place`
  - Case 단서의 성격(PLAYBOOK §2 "Choosing how each mission is played")
  - 사용 가능한 엔진(생성기 지원 + 그림 예산)
- 규칙 예:
  - 장치·발명 사실 → `mechanism_sim`
  - 연대·순서 사실 → `timeline_board`
  - 인물·장소 관계 → `deduction_board`(Final 우선)
  - 두 기록 대조 → `record_mismatch`
  - 장소 단서 → `scene_explore_choose`/`trace_deduction`
  - 증인 → `witness_compare`/`evidence_talk`
- 제약(검사기):
  - 한 유형이 시즌의 1/3 이하
  - 막마다 신규 엔진 1개 이상
  - 연속 두 Case가 같은 유형 조합이 아님
  - Case마다 손으로 조작하는 퍼즐 1개 이상(CLAUDE.md §20)
- 산출: `planning/puzzle_selection.json` — 미션별 후보, 점수, 선택, 이유 문장, 근거 factIds. 검사기가 계획과 일치하는지 확인한다. 동점이면 고정 순서로 정한다. `FACTORY_REPORT.md`에 "Case별 퍼즐 유형과 선택 이유" 표를 자동으로 넣는다.

---

## 9. PART 3A–3N 단계별 구현 계획

| PART | 내용 | 완료 조건 |
|---|---|---|
| **3A** | 순수 코어 계약(`PuzzleCoreV2`), `puzzleStates` 버전 접두사 규약, "core에 Flutter import 금지" 테스트, 새 비텍스트 키가 기존 계획에 없는지 검증 | 단위 테스트. 기존 앱 무변경 |
| **3B** | `timeline_board` 코어 + 위젯 + 디스패치 등록(테이블 기본 빈 값) | 위젯 테스트(탭 전용·작은 화면·큰 글자·스크린리더 동작), 기존 엔진 충돌 검사 통과 |
| **3C** | 타임라인 계획 스키마·PlayCheck·생성기·유일성 검사·샌드박스 Case | 샌드박스 플레이스루, Rome·NY 차이 0 |
| **3D** | `deduction_board`: EvidenceBoard를 데이터화(Paris 동작 불변) + 생성기 | Paris P03-F·P08-F 회귀 테스트 그대로 통과 |
| **3E** | `mechanism_sim` 코어(규칙 언어·BFS) + 조작부 위젯(스테퍼·토글·슬롯) | 단위·위젯 테스트 |
| **3F** | `glyph_compose`: 한글 획 벡터 데이터와 렌더러. 획 데이터의 역사 근거는 dossier 사실로 승인 | 렌더 테스트, 사람의 시각 확인 |
| **3G** | 장치 계획 스키마·생성기·샌드박스 Case | 플레이스루 |
| **3H** | `CaseFlow`(open·증거 해금) + `isUnlocked` 위임 + 지도 다중 핀 + 부분 순서 단서 그래프 | flow 없는 전 시즌 회귀(전체 `flutter test` 1회 — 공유 진행 로직 변경이므로 CLAUDE.md §21 기준 해당), 자유 순서 플레이스루, 중복 보상 0 |
| **3I** | 기존 엔진 6종 생성 지원(`trace_deduction`, `lens_inspect_word`, `record_mismatch`, `spot_difference`, `evidence_talk`, `number_entry`) | 각 샌드박스 미션 플레이스루 |
| **3J** | 역사 연동: 새 스키마 factIds·버림 카드 규칙·설명서·부분 순서 `clue_late` | dossier 테스트 확장 |
| **3K** | 퍼즐 자동 선택기 + `puzzle_selection.json` + FACTORY_REPORT 표 + PLAYBOOK·plan/create-season 스킬 | 샌드박스에서 결정론 재현(같은 입력이면 같은 출력) |
| **3L** | 샌드박스 시즌 전체(새 엔진·흐름 혼합) 플레이스루, 전체 회귀 | 전체 `flutter test` |
| **3M** | 실기기·접근성(VoiceOver/TalkBack)·작은 화면 확인, impeccable 리뷰 | 기기 캡처, 사람 확인 |
| **3N** | (사용자 승인 후) Seoul Case 01 시범 — dossier 승인 → 계획 → 팩토리 | 역사 게이트 통과, 실기기 |

권장 순서: 3A → 3B → 3C → 3I → 3J → 3K → 3D → 3E → 3F → 3G → 3H → 3L → 3M → 3N.

- 이유 1: 위험이 낮고 가치가 빠른 것부터. 타임라인과 기존 엔진 생성 지원만으로도 Season 5의 퍼즐 다양성이 Rome·NY보다 크게 늘어난다.
- 이유 2: 진행 흐름(3H)은 공유 진행 로직을 건드리므로 엔진이 안정된 뒤에 한다.
- 이유 3: 장치·한글(3E–3G)은 서울 dossier 사실 승인과 맞물리므로 dossier 작업과 병행한다.

---

## 10. 위험 요소 및 우선순위

| # | 위험 | 영향 | 완화 | 우선 |
|---|---|---|---|---|
| 1 | 진행 흐름 변경이 지도·라우터·Case 해결 판정에 회귀를 일으킴 | 높음(전 시즌) | `flow` 없음 = 기존 코드 경로 그대로. 3H에서 전체 테스트, 마지막에 배치 | 상 |
| 2 | 범용 엔진이 "앱 같은" 화면이 됨(CLAUDE.md §5·§19) | 높음(정체성) | 기존 종이·잉크 컴포넌트 재사용, 3M에 impeccable 리뷰, 엔진마다 장면 일러스트 | 상 |
| 3 | 레벨 추출 키 충돌(`_playNotText`) | 중(기존 레벨 변경) | 3A에서 기존 계획의 키 전수 검사, 차이 0 확인 | 상 |
| 4 | 장치 규칙 언어가 복잡해짐 | 중 | 정수·열거형 변수와 조건→설정만. 상태 수 상한, 자동 BFS | 중 |
| 5 | 한글 획 데이터의 역사 정확성 | 중(역사 왜곡) | 획·가획 단계 자체를 dossier 사실로 승인받고 사람이 시각 확인 | 중 |
| 6 | 드래그 중심 조작의 접근성 | 중 | 모든 드래그에 탭·커스텀 액션 대안. 48dp | 중 |
| 7 | 자동 선택기가 기계적으로 고름 | 중(재미) | 점수는 후보 제시용이고, 최종 선택과 이유는 Claude가 쓰며 검사기는 제약만 확인 | 중 |
| 8 | `palette_facts` 복사본 불일치 | 낮음 | 기존 자동 갱신 테스트 | 하 |
| 9 | 새 엔진의 그림 비용 | 낮음 | 타임라인·보드는 텍스트와 기존 증거 그림 재사용. 장치만 새 그림 1장 | 하 |
| 10 | 위젯 테스트로 시각 정확도를 보장하지 못함 | 중 | 실기기 캡처(3M) | 중 |

이번 PART에서 하지 않은 것: 코드 변경·실행 검증(설계만), Paris 전용 엔진 23개의 상세 정독(카탈로그 분류를 신뢰), EvidenceBoard 내부 판정 형식의 정독(3D에서 확인), 사운드 연동 상세.
