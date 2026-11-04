# Puzzle Engine 2.0 — PART 3B Timeline Board 게임 UI 보고서

작성일 2026-11-04 · 범위: PART 3A의 `TimelineRules`를 실제 미션 화면에 연결했다.

- 하지 않은 것: 서울 시즌 생성, 기존 시즌 콘텐츠 변경, API 호출, 커밋.
- 팔레트 등록과 시즌팩토리 자동 생성은 3C 범위로 남겼다.

## 1. 변경 파일

| 파일 | 구분 | 내용 |
|---|---|---|
| `lib/features/mission/widgets/timeline_board.dart` | 신규 | `TimelineBoard` 위젯(탭 전용, 포커스·시맨틱 포함) |
| `lib/data/mock/season_catalog.dart` | 수정 | `SeasonContent.timelines`(기본 `const {}`), `missionTables['timelines']`, `SeasonCatalog.timeline(m)`(레벨별 `variants` 자동 선택) |
| `lib/data/content/puzzle_engine_collisions.dart` | 수정 | `PuzzleEngineDispatch.mission` **맨 끝**에 `EngineStep('timelines', 'TimelineBoard')` |
| `lib/features/mission/mission_screen.dart` | 수정 | `final timeline = SeasonCatalog.timeline(m);`, `_PuzzleStage`의 child 연결(clock → trail → **timeline** → 기본 질문), `_timelineFor`, `_SolvedStage`에 해결된 타임라인(타임라인이 있을 때만) |
| `lib/data/content/season_content_validator.dart` | 수정 | `_timelines()`: `sequence` 미션인지, 정답이 미션과 같은지, 세 레벨이 같은 게임인지, 카드 id가 미션 id와 겹치지 않는지 |
| `lib/data/content/difficulty_content.dart` | 수정 | `structureOf`에 `TimelineSpec` 추가(규칙의 `structure()` 재사용) |
| `lib/features/mission/widgets/question_widgets.dart` | 수정 | 기존 답 카드 스타일의 공개 별칭 `answerPaper` 한 줄(동작 변경 없음) |
| `test/puzzle_engine_collisions_test.dart` | 수정 | 디스패치 목록과 child 연결 문자열의 기대값에 `timelines`를 추가(검사는 약화하지 않음) |
| `test/timeline_board_test.dart` | 신규 | 위젯 단위 9개 |
| `test/sandbox/timeline_mission_test.dart` | 신규 | 실제 앱 통합 5개 |

설계 문서와 다르게 한 점: 위젯을 `lib/puzzles_v2/widgets/`가 아니라 **`lib/features/mission/widgets/`**에 두었다. 모든 엔진 위젯이 이 폴더에 있고, 기존 테스트("every engine is a widget of the game")가 이 폴더만 확인한다. 순수 규칙은 그대로 `lib/puzzles_v2/core/`에 있다.

## 2. 실제 타임라인 게임 플레이 흐름

```
지도 → GO TO 장소 → INVESTIGATE → 편지 TAP TO OPEN → SOLVE THE PUZZLE
  → [MISSION 0N · THE PUZZLE] 질문 + THE TIMELINE 보드
      · 연도가 적힌 고정 카드(금색 연도 표시 + "FIXED")가 제자리에 있음
      · 카드 탭 → "PICKED" 표시(글자 + 진한 테두리 + 남색 바탕) → 놓을 칸 탭
      · 놓인 카드를 다른 칸에 놓으면 맞바꿈, 테이블 카드가 오면 원래 카드는 테이블로
      · NOT PART OF IT 칸을 탭해 무관한 카드 제외, "Back to the table"로 되돌림
      · Undo로 이전 조작 하나씩 되돌림
      · 고정 카드를 건드리면 "That card is fixed: its time is written on it."
      · 모든 칸이 차면 CHECK THE ORDER 활성화
  → 오답: 기존 try-again 시트(미션의 orderFeedback 문장, 힌트 제안)
         + 보드에 처음 틀린 칸 "CHECK THIS ONE"과 그 카드에 관한 게임 속 문장(정답은 말하지 않음)
  → 힌트: 기존 "Get a Free Hint"/팁 숍 그대로
  → 정답: 기존 Discovery Moment → 이야기 → TO THE MAP (보상은 기존 정책)
  → 해결 후 다시 열기: SOLVED 화면 + "WHAT HAPPENED" 타임라인(정답 배치, 제외 카드 표시, 조작 없음)
```

모든 조작은 탭만으로 된다(드래그·길게 누르기 없음).

## 3. 신규 엔진 연결 방식

- **엔진 선택**:
  - `PuzzleEngineDispatch.mission`의 마지막 단계로 추가했고, 기존 단계의 순서는 바꾸지 않았다.
  - 화면에서는 기본 질문 단계(`_PuzzleStage`)의 child로 들어간다(clock, trail과 같은 자리). 그래서 질문 표시, 편지 다시 읽기, 힌트, 오답 흔들림을 그대로 쓴다.
  - 테이블에 항목이 없는 미션(모든 기존 시즌)은 고르는 엔진이 이전과 같다(`puzzle_engine_collisions_test` 통과).
- **규칙 중복 없음**: 위젯의 모든 상태 변경은 `PuzzleSession.play`(3A 규칙)를 거치고, 위젯은 결과를 그리기만 한다. Undo는 이전 세션(불변 값)을 되돌려 놓는 것이다.
- **판정·보상**: CHECK THE ORDER → `_submit(m, answer)` → 기존 `GameController.submitAnswer` → `AnswerChecker`(`sequence`). 오답 기록(`wrongAnswers`), 첫 시도 보너스, 코인 1회 지급이 모두 기존 그대로다.
- **저장**: 조작할 때마다 `GameController.recordPuzzleState(m.id, session.saved)`.
- **레벨**: `SeasonCatalog.timeline(m)`이 기존 `_pick`으로 미션 난이도의 `variants[level].timelines`를 먼저 찾는다. 질문·힌트·오답 문장은 기존 `casePatches`가 맡는다.
- **검증**: `SeasonContentValidator`(`_timelines`)와 `DifficultyContent`(구조 비교)가 게임 콘텐츠 검사에 포함된다.

## 4. 저장·복구 검증 (실제 위젯 + `GameController`, `timeline_mission_test`)

| 상황 | 결과 |
|---|---|
| 카드 배치 후 화면 이탈(Back → 편지 → SOLVE THE PUZZLE) | 배치 그대로 |
| 앱 종료 후 재실행(같은 저장소로 새 `ProviderContainer`와 앱) | GO TO 하면 미션 화면이 **퍼즐 단계에서 바로** 이어지고, 배치·제외 카드 그대로 |
| 미션 재진입 | 위와 같음 |
| 중간 저장 | 조작마다 `puzzleStates[m1] = "pv2:timeline:1:…"` |
| 완료 후 재열람 | SOLVED 화면에 `WHAT HAPPENED`(정답 배치), CHECK 없음 |
| 중복 보상 | 두 번째 `submitAnswer` → `coins 0`, 지갑 잔액 변화 없음 |
| 손상된 저장 | `pv2:timeline:1:{"s":["gauge"`(잘림) → 앵커만 있는 처음 상태로 열림, 막히지 않음 |
| 기존 저장 구조 | `puzzleStates` 그대로, 새 키 없음 |

참고: 이미 해결한 미션을 다시 제출하면 기존 controller가 `firstSolve` 기본값 `true`를 그대로 돌려준다. 코인은 0이라 보상 정책에는 영향이 없다. 기존 동작이므로 바꾸지 않았다.

## 5. 접근성 검증

| 항목 | 방법 | 결과 |
|---|---|---|
| 최소 48dp | 모든 칸·카드·제외 칸의 높이 ≥ 48 (실제 56/52) | ✅ |
| 작은 화면·큰 글자 | 320×568, 글자 1.6배: 예외·오버플로 없음, 모든 요소가 화면 폭 안, 끝까지 풀 수 있음 | ✅ |
| 스크롤 | 보드는 기존 `CenteredScroll` 안의 Column. 테스트는 `ensureVisible`로 모든 요소에 도달 | ✅ |
| 색 외 선택 표시 | "PICKED" 글자 + 진한 금색 테두리, 시맨틱 `selected` | ✅ |
| 스크린리더 | 카드: "제목. 본문. on the table / not part of it, picked". 칸: "Place 2 of 4, fixed, 1441, THE GAUGE …, out of place". 힌트 문장("Tap to put THE LETTER here.") 제공. 시맨틱 탭 동작만으로 배치 성공. 섹션 제목은 `header` | ✅ |
| 키보드 | 각 요소가 `FocusableActionDetector`: Tab/Shift+Tab으로 이동, Enter/Space로 선택·배치, 포커스 시 금색 테두리 | ✅ |
| 애니메이션 비의존 | 조작에 애니메이션이 필요 없음. 오답 흔들림은 기존 연출일 뿐 | ✅ |
| 거부 안내 | 거부 이유를 `liveRegion` 텍스트로 표시 | ✅ |

## 6. 테스트 결과

- `flutter analyze`: **No issues found**.
- 신규 `test/timeline_board_test.dart` **9개 통과**:
  - 초기 상태(앵커 고정, CHECK 비활성)
  - 선택·배치·교환·제외·되돌리기·Undo와 조작마다 저장
  - 고정 카드 거부(저장 없음)
  - 오답 표시와 정답 문구 비노출
  - 저장 복원·손상 저장·다른 엔진 문자열
  - 해결 화면 읽기 전용
  - 48dp와 작은 화면·큰 글자
  - 키보드
  - 스크린리더
- 신규 `test/sandbox/timeline_mission_test.dart` **5개 통과**:
  - 검증기 통과와 레벨이 게임을 바꾸면 거부
  - 레벨별 문구 선택(정답은 하나)
  - 실제 앱 전체 흐름(배치 → 이탈 → 재진입 → 재실행 → 오답 → 힌트 → 정답 → 보상 1회 → 해결 화면)
  - 손상 저장
  - MASTER 문구 표시
- 회귀 묶음 **358개 모두 통과**(186초):
  - 위 신규 14개, 3A 24개, `test/sandbox` 전체(s9·Rome 포함)
  - `puzzle_engine_collisions_test`, `puzzle_palette_test`, `difficulty_content_test`, `generated_seasons_test`
  - `full_playthrough_test`, `back_navigation_test`, `season_playthrough_test`, `answer_checker_test`
  - PART 1·2의 `history_dossier_test`, `history_reveal_ui_test`
- 전체 `flutter test`, Release 빌드: **실행하지 않음**(요청대로).

## 7. 기존 시즌 영향

- Season 1–4 콘텐츠·이미지·사운드: 변경 없음. 네 시즌 모두 `timelines` 항목이 없으므로 엔진 선택, 해결 화면, 검증 결과가 이전과 같다(관련 플레이스루 테스트 통과).
- Rome·New York: `generate_season.dart --target game --check` 결과 `up to date`(차이 0), `plan_season.dart check --all` 출력이 기준선과 동일.
- 저장·보상·난이도 정책: 변경 없음(기존 경로만 사용).
- 기존 테스트 수정은 `puzzle_engine_collisions_test`의 기대값 두 곳뿐이다. 이 테스트는 디스패치 목록과 화면 코드 문자열을 고정해 두는 테스트이므로, 새 단계를 넣은 사실을 그대로 기록한 것이다. `vars['timeline'] == 'timelines'` 검사도 추가했다.

## 8. PART 3C 진행 가능 여부

**진행 가능.** 3C에서 할 일:

1. `PuzzlePalette`에 `timeline_board` 등록(`palette_facts.dart`와 테스트 동기화)
2. 계획 스키마 `play.timeline`(JSON Schema, `plan_models.dart`, `season_gen_schema_test`)
3. `CaseLevels._playNotText`에 `anchor`, `earlier`, `later`(그리고 `discard`, `id`는 이미 있거나 문자열이 아님) 추가 — 3A에서 기존 계획에 이 키들이 없음을 확인함
4. `PlayCheck.generatable`과 `generate_case.dart`에서 `timelines` 테이블을 생성하고, 레벨별 `variants`에 timelines 포함
5. 생성 단계의 유일성·근거 문장 검사(`TimelineRules.validate` + 관계 `line`이 게임 글에 있는지)
6. 샌드박스 Case로 생성 → 플레이스루

남은 위험:

- 실기기와 실제 VoiceOver/TalkBack 확인 안 함(위젯 테스트의 시맨틱 트리로만 확인)
- 카드가 많아지면(8장 이상) 세로 스크롤이 길어진다 — 3C 생성 규칙에서 카드 수 상한(예: 놓을 카드 6장 + 제외 2장)을 두는 것을 권장
