# Puzzle Engine 2.0 — PART 3A 공통 기반 구현 보고서

작성일 2026-11-04 · 범위: 퍼즐 규칙의 공통 기반(순수 Dart)과 첫 규칙 구현(타임라인)만 만들었다. 새 퍼즐 화면, 디스패치 등록, 시즌 콘텐츠, 시즌팩토리 변경은 없다. API 호출 없음, 커밋 없음.

## 0. 사전 확인 결과

| 확인 항목 | 결과 |
|---|---|
| PART 1·2 상태 | 작업 트리에 그대로 있음(커밋 전). 이번 회귀 실행에서 PART 1·2 테스트 49개 통과 |
| 엔진 선택·라우팅 | `PuzzleEngineDispatch`의 순서대로 테이블을 보고 고름. 이번 PART에서 **변경 없음** |
| 저장·복구 | 엔진마다 자기 문자열을 `GameProgress.puzzleStates[missionId]`에 저장(`GameController.recordPuzzleState`). 각 엔진의 `decode`는 모르는 문자열이면 처음부터 시작함. 해결 후에도 지워지지 않음 |
| 보상 | 두 겹으로 중복 방지: `_submitAnswer`의 `isCompleted` 선검사, 지갑의 미션별 키(`Wallet.missionKey`) |
| 정답 판정 | `AnswerChecker`. `sequence`는 쉼표로 이은 id 순서로 비교 |
| **설계와 실제 코드의 차이** | ① 설계의 관계 키 `before`/`after`는 이미 `play.talk`가 쓰는 키다(기존 계획에서 16·14회). 레벨 시스템(`CaseLevels._play`)이 이 키들을 **글로** 읽는다 → 관계 키를 `earlier`/`later`로 바꿈. ② 타임라인의 나머지 키(`timeline`, `cards`, `order`, `relations`, `anchor`, `discard`)는 기존 계획 어디에도 없음(테스트로 고정) |
| Paris 전용 엔진·EvidenceBoard 충돌 | EvidenceBoard(`BoardState.encode/decode`), 대화(`TalkProgress`), 단계(`step=n`) 등은 같은 `puzzleStates`를 자기 형식으로 쓴다. v2는 `pv2:<kind>:<version>:` 접두사가 있을 때만 읽으므로 다른 엔진의 문자열을 잘못 해석하지 않는다(테스트: `step=2`, 대화 JSON 등 → 처음부터). 디스패치를 건드리지 않았으므로 엔진 선택 충돌도 없다(`puzzle_engine_collisions_test` 통과) |

## 1. 변경 파일

| 파일 | 구분 |
|---|---|
| `lib/puzzles_v2/core/puzzle_rules.dart` | 신규: 공통 계약(`PuzzleRules`), `SpecIssue`, `Rejection`, `Applied`, `PuzzleStateCodec`, `PuzzleSession`, `PuzzleSpecCheck` |
| `lib/puzzles_v2/core/timeline_rules.dart` | 신규: 첫 규칙 구현 `TimelineRules`(+ `TimelineSpec.parse`) |
| `test/puzzles_v2/puzzle_rules_test.dart` | 신규: 24개 테스트 |
| `docs/PUZZLE_ENGINE_V2_PART3A_REPORT.md` | 이 보고서 |

**기존 파일 수정 없음.** `git status`의 수정 파일은 모두 PART 1·2의 것이다. 새 저장 키도 없다.

## 2. 공통 규칙 엔진 구조

```
PuzzleRules<Spec, State, Action>     (Flutter import 금지 — 테스트로 강제, import를 따라가며 확인)
  validate(spec)          → List<SpecIssue>       데이터 검증 (빈 목록 = 플레이 가능)
  initial(spec)           → State                  초기 상태
  apply(spec, s, a)       → Applied<State>         상태 전이. 허용되지 않는 조작은 예외 없이 Rejected(코드·이유), 상태 그대로
  isComplete(spec, s)     → bool                   제출 가능 여부
  answerOf(spec, s)       → String                 submitAnswer에 보낼 값 (Mission.answer 형식)
  answer(spec)            → String                 정답
  solved(spec)            → State                  해결 후 다시 열었을 때의 모습
  stateToJson / stateFromJson                       저장·복구 (맞지 않으면 null → 처음부터)
  structure(spec)         → 레벨과 무관한 구조(id·앵커·순서)    ← 레벨 비교용
  texts(spec)             → {경로: 문구}                        ← 레벨별로 쓰는 글
  elementIds(spec)        → [(경로, id)]
```

- **판정·보상·저장은 하지 않는다.** 위젯은 `answerOf`를 기존 `GameController.submitAnswer`로 보내고(→ `AnswerChecker`, 보상 1회), `PuzzleSession.saved`를 기존 `recordPuzzleState`로 저장한다. 기존 엔진과 같은 경로다.
- **`PuzzleSession`**(불변 값): `open(rules, spec, saved:, solved:)` → `play(action)` → `(새 세션, Rejection?)`. 해결된 미션의 세션은 `readOnly`라 모든 조작이 `solved`로 거부된다.
- **결정성**: 상태는 불변 값이고 `==`가 정의되어 있다. 저장할 때 버림 더미를 정렬하므로 같은 조작이면 같은 저장 문자열이 나온다(테스트).

### 2.1 첫 구현: `TimelineRules`(`timeline_board`의 규칙)

| 항목 | 동작 |
|---|---|
| 데이터 | 카드(`id`, `title`, `text`, `anchor`, `discard`, `evidence`), 정답 순서 `order`, 관계(`earlier`, `later`, `line`). `TimelineSpec.parse`가 JSON을 읽고 모르는 필드를 거부 |
| 검증 | 놓을 카드 3장 이상, `order`가 버림 카드를 뺀 전체의 순열, 연도 앵커가 앞으로만 흐름, 버림 카드에 앵커 없음, 관계가 순서와 모순되지 않음, 모두 고정이면 할 일 없음, **순서가 정확히 하나인지**(앵커를 칸에 고정한 채 관계로 칸마다 후보가 하나인지 시뮬레이션 → 아니면 `timeline_ambiguous`, 바꿔 놓아도 되는 카드 이름을 알려 줌) |
| 초기 상태 | 앵커 카드는 자기 칸에 고정, 나머지는 테이블에 |
| 조작 | `PlaceCard`(이미 놓인 카드끼리는 맞바꿈, 테이블에서 온 카드면 원래 있던 카드는 테이블로), `DiscardCard`, `ReturnCard`, `ClearTimeline` |
| 거부 | `card_unknown`, `slot_unknown`, `card_fixed`, `slot_fixed`, `no_change`, (세션) `solved` |
| 완료·답 | 모든 칸이 차면 완료, 답은 `a,b,c`(= 기존 `sequence` 형식. `AnswerChecker` 그대로 사용 — 테스트) |
| 오답 안내 | `firstProblem`: 처음 틀린 칸과, 그 카드에 관한 게임 속 문장(`relations[].line`). 정답은 말하지 않음 |

## 3. 상태 저장·복구 방식

- **저장 위치**: 기존 `GameProgress.puzzleStates[missionId]`. **새 저장 키 없음.**
- **형식**: `pv2:<kind>:<version>:<json>` (예: `pv2:timeline:1:{"s":["gauge","letter",null,"book"],"d":["list"]}`)

복구 규칙(`PuzzleStateCodec.decode` → 맞지 않으면 처음부터):

| 상황 | 동작 | 테스트 |
|---|---|---|
| 앱 종료 후, 뒤로가기 후, 미션 재진입 | 저장 문자열에서 같은 상태로 복원(`restored = true`) | ✅ |
| 다른 엔진의 문자열(`step=2`, 대화 JSON), 다른 종류(`pv2:board`), 다른 버전, JSON 깨짐 | 처음부터 | ✅ |
| 조작된 저장(칸 수 다름, 앵커가 옮겨짐, 모르는 카드, 같은 카드 두 번, 고정 카드를 버림) | 처음부터 | ✅ |
| 정답 완료 후 다시 보기 | `solved` 모습, 읽기 전용, 조작 거부 | ✅ |
| 보상 중복 방지 | 기존 controller 그대로: 두 번째 제출은 `coins 0`. 저장된 퍼즐 상태는 해결 후에도 남지만 해결된 세션은 읽기 전용 | ✅(실제 `GameController`로) |
| 기존 저장 데이터 호환 | 새 키 없음. 기존 엔진 문자열을 v2가 해석하지 않음 | ✅ |

## 4. 난이도 및 ID 검증 방식

`PuzzleSpecCheck`:

- **`ids(ids, reserved:)`**:
  - 형식: 소문자 id, 32자 이하(`id_invalid`)
  - 중복(`id_duplicate`)
  - **시즌 접두사 `s<n>_`로 시작하는 id 금지**(`id_reserved`): 미션·단서·증거·장소 id와 역사 사실 id(`s5_ep01_h1`)는 모두 시즌 접두사로 시작하므로 형식만으로 충돌을 막는다
  - 시즌이 넘겨주는 `reserved` 집합(그 시즌의 미션·사실 id 등)과의 충돌
- **`levels(rules, {Difficulty: spec}, reserved:)`**:
  - 세 레벨 모두 있음(`level_missing`)
  - 각 레벨이 `validate`와 ids 검사를 통과
  - 빈 문구 없음(`text_missing`)
  - **`structure`가 Rookie와 같음**(id·앵커·순서·관계가 같아야 함 → `level_changes_game`)
  - **답이 같음**(`level_changes_answer`)
  - 문구 위치가 같음
  - 기존 난이도 정책(영어만 다르고 게임은 같다)을 v2 규칙에 그대로 옮긴 것이다
- **`mission(rules, spec, missionId:, missionAnswer:)`**: 퍼즐의 정답이 미션의 `answer`와 같은지(`answer_mismatch`)
- 앵커(연도)는 구조에 속한다. 레벨마다 연도를 다르게 쓰면 `level_changes_game`이 된다(테스트).

## 5. 신규 테스트 결과

`flutter test test/puzzles_v2` — **24개 모두 통과**.

| 그룹 | 내용 |
|---|---|
| 계약 | 규칙 코드에 Flutter·패키지 import 없음(import를 따라가며 확인), 정상 스펙, JSON 읽기와 거부(`before`/`after` 키 거부 포함) |
| 잘못된 타임라인 | 순서 모호, 순서 불일치(누락·버림 포함), 연도 역행, 관계 모순·버림 카드 관계, 너무 짧음, 모두 고정, 고정 카드를 버림 |
| ID | 중복, 형식, 미션 id·사실 id·예약어 충돌, 카드 id 중복 |
| 조작 | 초기 앵커, 놓기·맞바꾸기·버리기·되돌리기·비우기, 거부 9종(상태 그대로), 완료·답·첫 오류 안내, 결정성 |
| 저장·복구 | 복원, 처음부터 시작하는 11가지 경우, 해결 후 읽기 전용 |
| 레벨 | 같은 게임 통과, 레벨 누락, 다른 답·다른 구조, 앵커 변경, 빈 문구, 예약 id |
| 기존 게임 | 미션 정답 일치 검사, `AnswerChecker`가 타임라인 답을 `sequence`로 판정, 실제 `GameController`로 저장·보상 1회·해결 후 읽기 전용 |
| 계획 키 | 모든 시즌 계획의 `play`에 타임라인 전용 키가 없음 |

## 6. 기존 시즌 회귀 결과

- `flutter analyze`: **No issues found**.
- Rome·New York: `generate_season.dart --target game --check` 결과 둘 다 `up to date`(30개 + registry 3개). `plan_season.dart check --all` 출력이 PART 1 이전 기준선과 **동일**.
- 관련 테스트를 한 번에 실행해 **283개 모두 통과**(166초):
  - 신규 24개
  - `answer_checker_test`, `puzzle_engine_collisions_test`, `puzzle_palette_test`, `season_gen/palette_facts_test`, `difficulty_content_test`, `generated_seasons_test`
  - PART 1·2의 `history_dossier_test`, `history_reveal_ui_test`
- 전체 `flutter test`와 Release 빌드는 **실행하지 않음**(요청대로).

## 7. 남은 위험

1. **아직 게임에 연결되지 않음**: 디스패치·`SeasonContent` 테이블·위젯이 없다(3B 범위). 그래서 실제 화면에서 저장·복구가 되는지는 3B 위젯 테스트로 확인해야 한다.
2. **해결 후 저장 문자열이 남음**: 기존 엔진과 같은 방식이다. 해결된 세션은 `solved` 모습으로 열리므로 영향은 없다. 미션을 다시 할 때 저장을 지우는 것은 기존 "시즌 다시 하기" 경로가 맡으며, v2 문자열도 같이 지워지는지는 3B에서 확인한다.
3. **레벨 문구 추출**: 계획의 `anchor`(연도 문자열)는 글이 아니므로 3C에서 `CaseLevels._playNotText`에 넣어야 한다. 넣지 않으면 레벨마다 연도를 "다시 쓰라"고 요구하게 된다. 기존 계획에 이 키가 없음은 테스트로 고정했다.
4. **유일성 검사의 범위**: 관계와 연도 앵커만 본다. 카드 본문에 숨은 시간 단서(예: "two years later"를 관계로 적지 않은 경우)는 보지 못한다. 그런 단서는 관계로 적도록 PLAYBOOK에 규칙을 두어야 한다(3C/3K).
5. **역사 연동은 아직 없음**: 카드의 `factIds`, 버림 카드 규칙은 3J 범위.

## 8. PART 3B 진행 가능 여부

**진행 가능.** 3B에서 할 일:

- `timelines` 테이블을 `SeasonContent`에 기본 `const {}`로 추가
- `PuzzleEngineDispatch` 끝에 `timelines` 단계 추가
- `TimelineBoard` 위젯
  - 탭 전용 조작, 시맨틱 커스텀 액션, 48dp
  - 세로 타임라인과 작은 화면 대응
  - 기존 종이·잉크 컴포넌트 재사용
  - `recordPuzzleState`와 `submitAnswer` 연결
- 위젯 테스트: 저장·복구, 뒤로가기, 해결 후 다시 보기, 작은 화면·큰 글자, 스크린리더

완료 조건은 기존과 같다: 디스패치 충돌 검사 통과, Rome·NY 차이 0, 기존 엔진 테스트 통과.
