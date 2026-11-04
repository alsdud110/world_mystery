# Historical Fiction Mystery — PART 1 구현 보고서

작성일 2026-11-04 · 범위: 역사 모드의 기반 시스템만. Season 5 Seoul 콘텐츠·이미지·사운드 생성 없음, API 호출 없음, 커밋 없음.

## 1. 변경·추가 파일

| 파일 | 구분 | 내용 |
|---|---|---|
| `tool/season_gen/history_dossier.dart` | 신규 | `SeasonMode`, `HistoryDossier`(스키마·출처·퍼즐 근거 검사, reveal 추출), `HistoryGate` |
| `lib/data/models/history_reveal.dart` | 신규 | `HistoryReveal`(REAL HISTORY / IN THIS MYSTERY) |
| `test/season_gen/history_dossier_test.dart` | 신규 | 29개 테스트 |
| `tool/season_gen/content_approval.dart` | 수정 | 승인 종류 `historyFact` (사실 단위 해시, `approved/` 스냅샷, `report()`에 사실 포함) |
| `tool/season_gen/approve.dart` | 수정 | `fact <factId>` 대상, 승인 전 출처 규칙 검사 |
| `tool/season_planner/season_quality.dart` | 수정 | 역사 모드일 때만 dossier 검사(6b). 알 수 없는 mode는 ERROR |
| `tool/season_planner/plan_season.dart` | 수정 | `init --mode historical_fiction_mystery` |
| `tool/season_planner/finding.dart` | 수정 | `Source.history` |
| `tool/season_factory/season_factory.dart` | 수정 | 1b 단계 게이트, exit 15 |
| `tool/asset_pipeline/asset_pipeline.dart` | 수정 | `run(generate: true)`에서 API 호출 전 게이트, 코드 3 |
| `tool/season_gen/generate_case.dart` | 수정 | 게임 타깃 + 역사 모드일 때만 게이트와 `<seasonId>_history.g.dart` |
| `lib/data/mock/season_catalog.dart` | 수정 | `SeasonContent.historyReveals` (기본값 `const {}`) |
| `tool/season_factory/README.md`, `tool/season_gen/README.md`, `.claude/skills/create-season/SKILL.md` | 문서 | exit 15와 새 모듈 한 줄씩 |

기존 파일 삭제 없음. `lib/data/generated/`, `content_pipeline/seasons/`, `assets/`는 변경 없음.

## 2. 신규 모드 설정 방식

- 위치: `content_pipeline/seasons/<seasonId>/planning/brief.json`의 `mode`.
- `SeasonMode.of(seasonDir)`:
  - brief 없음 또는 `mode` 없음 → `standard` (기존과 동일; 기존 brief 파일은 손대지 않음)
  - `"historical_fiction_mystery"` → 역사 모드
  - 그 밖의 값, JSON이 아닌 brief → `FormatException`. 검사에서는 `season_mode_unknown` ERROR, 게이트에서는 차단. 역사 시즌이 실수로 일반 시즌처럼 처리되어 게이트를 건너뛰지 않도록, 판단할 수 없으면 막는 쪽으로 동작함.
- 새 시즌: `dart run tool/season_planner/plan_season.dart init --season 5 --city Seoul --mode historical_fiction_mystery`. 다른 `--mode` 값은 거부.
- 일반 모드에서는 dossier를 읽지 않음. 깨진 dossier가 있어도 무시됨(테스트로 확인).

## 3. 역사 자료 스키마 (`planning/history_dossier.json`)

```json
{"schemaVersion": 1, "seasonId": "s5_seoul", "cases": [{
  "caseId": "s5_ep01",
  "subject": "Historical Subject", "period": "Year / Period", "location": "Historical Location",
  "facts": [{
    "factId": "s5_ep01_h1", "statement": "…",
    "status": "draft | source_checked | rejected",
    "sources": [{"kind": "primary | public_institution | academic | press | other",
                 "publisher": "…", "title": "…",
                 "url": "https://…"  또는  "citation": "문헌 식별 정보",
                 "quote": "인용문"  또는  "location": "쪽·조·행 등 위치",
                 "checkedAt": "YYYY-MM-DD"}],
    "conflict": {"status": "none | resolved | unresolved", "note": "…"}
  }],
  "fiction": ["Fictional Mystery: 창작 설정"],
  "puzzles": [{"puzzleId": "s5_ep01_m2", "factIds": ["s5_ep01_h1"], "answer": "…",
               "clues": [{"text": "1443", "missionId": "s5_ep01_m1"}], "derivation": "정답 도출 과정"}],
  "learningObjectives": ["…"],
  "reveal": {"realHistory": [{"text": "…", "factIds": ["s5_ep01_h1"]}], "inThisMystery": ["…"]}
}]}
```

요구 항목과 대응:

| 요구 항목 | 필드 |
|---|---|
| Verified Facts | `facts[]` |
| Sources | `sources[]` |
| Fictional Mystery | `fiction` |
| Historical Clues | `puzzles[].clues` |
| Historical Reveal / Fact vs Fiction | `reveal` |
| Verification Status | 필드로 쓰지 않음 — `status` + 승인 기록에서 계산 (`HistoryReport.summary`) |

- 사실 ID는 `<caseId>_h<n>`. 계획 파일의 `_f<n>`(게임 속 fact)과 겹치지 않음.
- 모르는 필드는 ERROR. 계획 파일·바이블과 같은 규칙.
- 시즌의 모든 Case에 항목이 있어야 하고, Case마다 퍼즐 1개 이상이 역사 사실에 근거해야 함.

## 4. 승인 및 재승인 정책

- 파일에 쓸 수 있는 상태는 `draft`, `source_checked`, `rejected`뿐이다. `approved`라고 쓰면 ERROR(`history_status_reserved`).
- `approved`는 기존 `approvals.json`에 기록된다:
  - 형식: `{"kind": "historyFact", "id": "s5_ep01_h1", "hash": "sha256:…", "approvedAt": UTC, "approvedBy": "이름 <메일>"}`
  - 승인 당시의 사실 JSON은 `approved/<hash>.json`에 남는다.
  - Case ID는 사실 ID 안에 들어 있다.
- 해시 대상은 사실 객체 하나(statement·sources·conflict·status)다.
  - 문장이나 출처(인용문 포함)가 바뀌면 `stale` → 재승인이 필요하다(`history_fact_changed`).
  - 같은 dossier의 다른 부분(subject 등)이 바뀌는 것은 영향 없음.
- `approve.dart approve <seasonDir> fact <factId>`가 승인 전에 확인하는 것:
  - 상태가 `source_checked`일 것
  - 출처 규칙(§5)을 모두 충족할 것
  - 위 조건을 통과하면 터미널에서 사람이 factId를 직접 입력해야 승인된다(기존 `_askAtTerminal`).
  - 파이프 입력이나 TTY가 없는 실행(자동 제작 명령, Claude의 Bash)은 거부된다.
- 팩토리·파이프라인·생성기에는 승인을 쓰는 코드가 없다.
- `rejected` 사실을 퍼즐이나 REAL HISTORY에 쓰면 ERROR.
- 승인 후 상태를 `draft`/`rejected`로 바꾸면 승인 효력이 없다(`history_fact_unchecked`).
- `approve.dart status`는 사실도 함께 나열하고, `impact`는 바뀐 사실에 대해 재승인이 필요하다고 안내한다.

## 5. 출처 검증 (자동으로 보는 것 / 사람이 보는 것)

자동 검사(`HistoryDossier.sourceProblems`). `source_checked`인 사실에서 위반하면 ERROR, `draft`이면 참고 정보:

1. 출처 2개 이상
2. 서로 다른 `publisher` 2곳 이상 — URL이 2개라도 같은 기관이면 실패
3. 1개 이상이 `primary` 또는 `public_institution`
4. 각 출처에 `url`(http/https) 또는 `citation`
5. 각 출처에 `quote` 또는 `location`
6. 각 출처에 `checkedAt`(실제로 열어 본 날짜). 없으면 "열어 보지 않은 출처"로 처리
7. `conflict` 기록 필수. `unresolved`면 승인 불가·게이트 차단, `resolved`면 `note` 필수

사람의 판단으로 남는 것(승인 시 화면에 안내 문구 출력):

- 출처의 실제 독립성(예: 한 기관 자료를 그대로 옮긴 기사)
- 인용문이 주장을 실제로 뒷받침하는지
- 해석이 타당한지

도구는 URL을 열어 보지 않는다.

## 6. 제작 차단 위치

`HistoryGate.blockers(seasonDir)` 하나를 세 곳에서 호출한다. 일반 모드에서는 항상 빈 목록이다.

| 위치 | 시점 | 결과 |
|---|---|---|
| `season_factory.dart run` 1b | 계획 검사 직후, doctor·이미지 단계 이전 | exit 15, 누락 항목 출력 |
| `AssetPipeline.run(generate: true)` | 예산·키 확인과 **모든 API 호출 이전** | 코드 3, `history …` 로그 |
| `generate_case.dart` (target game) | 게임 코드 생성 이전 | `[history_blocked]` 생성 실패 |

차단 조건:

- dossier 없음, 또는 JSON·스키마 오류
- 퍼즐이나 REAL HISTORY가 쓰는 사실 중 하나라도 "지금 내용 그대로 승인됨"이 아님 (미승인, 변경됨, draft)
- 출처 규칙 위반
- 충돌 `unresolved`
- 존재하지 않는 사실 ID, rejected 사실
- 퍼즐 근거 오류(§7)

차단하지 않는 것:

- 레벨 파일이 아직 없는 것 — 이미지 다음 단계에서 작성되므로
- 수동 검토 항목
- 어디에도 쓰이지 않는 draft 사실

## 7. 퍼즐 근거 검증 방식

dossier `puzzles[]`로 다음을 추적한다: 퍼즐 ID(미션 ID), 사실 ID, 단서(`clues`), 도출 과정(`derivation`), 정답(`answer`).

자동 검사:

- 사실 ID가 존재하는가, 승인되었는가, rejected가 아닌가
- 퍼즐 ID가 해당 Case의 미션인가
- `answer`가 계획 파일의 정답(옵션 id 또는 정답 옵션 문구)과 같은가
- 단서가 나오는 미션이 퍼즐보다 앞이거나 같은 미션인가 (시즌 플레이 순서 기준)
- 단서 문구가 그 미션에서 플레이어가 읽는 글(레벨 시스템이 "글"로 보는 문자열. id나 매칭 키는 제외)에 단어 단위로 있는가 — ROOKIE는 계획 파일, JUNIOR/MASTER는 `levels.json`을 적용한 결과로 각각 확인

추리 타당성:

- 문자열이 있다고 해서 추론 가능하다고 판정하지 않는다.
- 모든 퍼즐에 `history_reasoning_review`(수동 검토, INFO)를 붙여 "각 레벨에서 게임 안 단서만으로 정답에 도달하는지 읽어 볼 것"을 남긴다.

## 8. 기존 모드 호환성 검증 결과

| 확인 | 방법 | 결과 |
|---|---|---|
| Rome·New York 게임 코드 | `generate_season.dart --target game --check` (파일을 쓰지 않고 비교만 함), 변경 전후 | 둘 다 `up to date` (각 30개 파일 + registry 3개), 차이 0 |
| Rome·New York 계획 검사 | `plan_season.dart check --no-report --all` 출력, 변경 전후 diff | 동일 (Rome 0 ERROR/28 WARNING/14 INFO, NY 0/55/13) |
| mode 없는 시즌 | 테스트: 검사에 history 항목 없음, 게이트 비어 있음, brief 없음도 standard | 통과 |
| 일반 모드가 dossier를 읽지 않음 | 테스트: 깨진 dossier가 있어도 무영향 | 통과 |
| 일반 시즌 게임 생성 | 테스트: `_history.g.dart` 없음, content에 `historyReveals` 없음 | 통과 |
| 기존 저장·진행·난이도·사건 해결 UI | 해당 코드 미변경 (`SeasonContent`에 기본값이 있는 필드만 추가) | — |

유료 API 호출이나 기존 파일 덮어쓰기는 없었다. `quality_report.json`도 다시 쓰지 않았다(`--no-report`).

## 9. 테스트 결과

- `flutter analyze`: No issues found.
- `flutter test test/season_gen/history_dossier_test.dart`: **29개 모두 통과**. 다룬 항목:
  - 모드 기본값, 잘못된 mode 거부, `init --mode`
  - dossier 누락 차단
  - 미승인·draft 사실 사용 차단
  - 출처 부족(1개, 같은 기관, 공신력 출처 없음, 열어 보지 않은 출처)
  - 충돌 `unresolved` 차단
  - 승인 후 문장·인용문 변경 시 재승인 요구
  - 존재하지 않는 사실 ID, rejected 사실, 없는 미션, 정답 불일치
  - 단서 미노출, JUNIOR에서 단서 누락, 퍼즐보다 뒤에 나오는 단서
  - 승인 CLI(승인·확인 거부·규칙 위반 거부·status)
  - **파이프라인이 API 호출 0회로 차단**, 승인 후에는 게이트 통과
  - 게임 생성기의 reveal 출력, 일반 시즌 무출력
- 회귀: `test/season_gen`, `test/season_planner`, `test/asset_pipeline`, `test/season_factory`, `test/generated_seasons_test.dart` — **615개 통과**(새 29개 포함), 177초.
- 생성된 `_history.g.dart`를 lib 안에 임시로 넣고 `dart analyze`로 컴파일 확인 → 문제 없음(임시 파일은 삭제).
- 전체 `flutter test`, Release 빌드: **실행하지 않음** (요청에 따라 제외).

## 10. 미구현 항목과 위험 요소

미구현(의도적으로 PART 2 이후):

- 사건 해결 화면에 REAL HISTORY / IN THIS MYSTERY 표시 (데이터는 `SeasonContent.historyReveals`까지만 연결됨)
- reveal 문구의 JUNIOR/MASTER 버전 — 현재 Rookie 문장 하나만 있음. `levels.json` 대상에 포함되지 않음
- 서울 dossier와 콘텐츠

위험:

1. **사운드**: 현재 팩토리·파이프라인에는 사운드 생성 단계가 없다. 별도의 `sound-effects` 스킬(ElevenLabs)은 게이트 밖이다. 사운드를 팩토리에 넣을 때 같은 게이트를 호출해야 한다.
2. **이미지 단독 CLI**: `tool/ai_agents/openai_image.dart`를 직접 실행하면 시즌 폴더를 모르기 때문에 게이트를 거치지 않는다. 팩토리와 `asset_pipeline.dart` 경로만 막힌다.
3. **승인 API**: `SeasonApprovals.approve()`는 코드에서 직접 호출하면 출처 규칙을 다시 보지 않는다(기존 승인과 같은 구조). 다만 그렇게 승인된 사실도 규칙 위반이 남아 있으면 게이트가 ERROR로 막는다.
4. **출처 독립성**은 publisher 이름 비교뿐이다. 이름을 다르게 적으면 통과하므로 사람의 승인이 최종 판단이다.
5. **단서 검사의 한계**: 단어 일치만 본다. 의미 전달과 추리 가능성은 수동 검토 항목이며 기록·차단되지 않는다.
6. 팩토리 exit 15 경로는 같은 `HistoryGate`를 쓰지만, 팩토리 자체를 실행하는 테스트는 추가하지 않았다(게이트 함수와 파이프라인 차단은 테스트함).

## 11. PART 2 권장 작업

1. 사건 해결 화면(`case_solved_screen.dart`)에 REAL HISTORY / IN THIS MYSTERY 섹션 추가 — `historyReveals`가 있는 시즌만, 위젯 테스트 포함
2. reveal 문구를 `levels.json` 대상에 넣어 JUNIOR/MASTER 작성·검사
3. 수동 검토(추리 타당성) 결과를 기록하는 방법 — 퍼즐 단위 승인(`historyPuzzle`)을 둘지 결정
4. 앱 폰트의 한글 자모 표시 확인 (PART 0 위험 3)
5. PLAYBOOK과 plan/create-season 스킬에 역사 모드 절차(dossier 먼저 → 출처 열기 → `source_checked` → 사용자 승인) 정리
6. 그다음 PART: 서울 dossier 작성(Case 01 훈민정음부터) → 사용자 승인
