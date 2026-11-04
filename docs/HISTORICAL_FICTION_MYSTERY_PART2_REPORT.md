# Historical Fiction Mystery — PART 2 구현 보고서

작성일 2026-11-04 · 범위: History Reveal UI, 난이도별 역사 설명, 이미지·사운드 우회 차단, 퍼즐 추론 가능성 검토 체계. 서울 시즌 생성 없음, 유료 API 호출 없음, 커밋 없음.

## 1. 변경 파일 및 구현 내용

| 파일 | 구분 | 내용 |
|---|---|---|
| `lib/data/models/history_reveal.dart` | 수정 | `HistoryReveal`에 `HistoryLine`(rookie/junior/master, `at(Difficulty)`)과 `HistorySource` 추가 |
| `lib/data/mock/season_catalog.dart` | 수정 | `SeasonCatalog.historyReveal(episodeId)` |
| `lib/features/result/case_solved_screen.dart` | 수정 | `historyRevealProvider`, Case Closed 파일 안의 `_HistoryReveal` 섹션, SOURCES 다이얼로그 |
| `tool/season_gen/history_dossier.dart` | 수정 | 레벨별 reveal 검사, 유일 정답·연도·정답 노출 검사, reveal/퍼즐 승인 상태, 게임 단계 게이트(`game: true`), `HistoryGate.forOutput` |
| `tool/season_gen/content_approval.dart` | 수정 | 승인 종류 `historyReveal`, `historyPuzzle`. 승인 대상 JSON(`historyPayload`)을 해시 |
| `tool/season_gen/approve.dart` | 수정 | `reveal <caseId>`, `puzzle <missionId>` 대상. 승인 전 문제 검사와 체크리스트 출력 |
| `tool/season_gen/generate_case.dart` | 수정 | 게임 생성 때 `game: true` 게이트. 레벨별 문장과 출처를 생성 |
| `tool/season_factory/season_factory.dart` | 수정 | 7단계(게임 생성) 앞에 게임 게이트 → exit 15 |
| `tool/ai_agents/openai_image.dart` | 수정 | `ImageStudio.run`에서 API 호출 전 `HistoryGate.forOutput` 검사 |
| `tool/ai_agents/history_guard.dart` | 신규 | 사운드·수동 이미지 호출용 가드 CLI(`<path>...` / `--hook`) |
| `tool/ai_agents/history_guard_hook.sh` | 신규 | Claude Code PreToolUse 훅. 관련 명령만 Dart로 넘김 |
| `.claude/settings.json` | 수정 | `hooks.PreToolUse`(Bash)에 위 훅 등록. 기존 permissions는 바이트 그대로 |
| `test/season_gen/history_dossier_test.dart` | 수정 | 42개 테스트 |
| `test/history_reveal_ui_test.dart` | 신규 | 7개 위젯 테스트 |
| `tool/*/README.md`, `.claude/skills/create-season/SKILL.md` | 문서 | 새 대상과 exit 15 설명 |

## 2. History Reveal 실제 표시 흐름

```
history_dossier.json (reveal: 레벨별 문장 + 근거 factIds)
  → 사람 승인: fact / reveal / puzzle (approve.dart, 터미널)
  → generate_case.dart --target game (게이트 game:true 통과 시에만)
  → lib/data/generated/<id>/<id>_history.g.dart  (HistoryReveal: 레벨별 HistoryLine + HistorySource)
  → SeasonContent.historyReveals → SeasonCatalog.historyReveal(caseId)
  → historyRevealProvider(caseId) → CaseSolvedScreen._CaseFile
```

- **위치**: 기존 Case Closed 파일 안, CASE REPORT와 서명 아래, 점선(`_Rule`) 다음.
- **REAL HISTORY**: 파일 본문 서체(`bodyText`, navy 제목)로 표시. 아래에 **SOURCES** 버튼(48×48 이상)이 있고, 누르면 `GameDialog`가 발행 기관, 제목, URL 또는 문헌 정보를 보여준다. URL은 선택해 복사할 수 있고, 외부 링크로 열지는 않는다(아동용).
- **IN THIS MYSTERY**: 점선으로 분리. "Made up for this game." 문구 아래에 사건 메모 서체(`letter`)로 표시. 두 영역은 섞이지 않는다.
- **역사 모드에만 표시**: 데이터가 있는 Case만 섹션이 나온다. 현재 게임의 모든 시즌은 데이터가 없으므로 Case Closed 화면이 이전과 같다.
- **승인되지 않은 정보는 표시하지 않음**: 생성기가 게임 게이트를 통과해야만 데이터를 만든다(§4).
- **재진입**: 지도에서 해결된 Case를 열 때와 앱이 이 화면으로 다시 열릴 때(`/solved?settled=1`) 모두 같은 화면이 다시 표시된다.
- **저장 데이터**: 새 저장 키 없음. 읽기 전용 화면 데이터다.
- **접근성**: 두 제목은 `Semantics(header: true)`. 시스템 글자 크기를 따르고, 뒤로가기는 다이얼로그만 닫는다.

## 3. 난이도별 역사 설명

dossier의 reveal 문장마다 `text`(ROOKIE), `junior`, `master`를 모두 쓰고, 화면은 그 시즌의 난이도(`seasonDifficultyProvider`)에 맞는 문장을 고른다. 난이도를 정하는 방식은 바꾸지 않았다.

예시(테스트에 사용한 문장):

| 레벨 | REAL HISTORY | IN THIS MYSTERY |
|---|---|---|
| ROOKIE | King Sejong made new letters in 1443. | The lost page is made up. |
| JUNIOR | In 1443, King Sejong created a new set of letters. | The missing page was invented for this case. |
| MASTER | In 1443, King Sejong devised an entirely new alphabet. | The vanished page is an invention of this mystery. |

자동 검사(`history_reveal_level`, ERROR):

- 세 레벨 모두 작성됨
- 숫자(연도 등)의 집합이 같음
- ROOKIE에 나온 고유명사(문장 첫 단어가 아닌 대문자 단어)가 JUNIOR·MASTER에도 있음
- 6단어 이상 문장은 ROOKIE를 그대로 복사하지 않음
- REAL HISTORY 문장의 연도는 그 문장이 가리키는 사실(factIds)의 statement에 있어야 함(`history_reveal_unsupported`)

의미가 같은지는 사람이 reveal 승인 체크리스트로 확인한다.

## 4. 이미지·사운드 차단 검증 결과

| 경로 | 차단 위치 | 결과(테스트) |
|---|---|---|
| 팩토리 이미지 단계 | 1b `HistoryGate.blockers` → exit 15 | PART 1과 같음 |
| `asset_pipeline.dart --generate` | 예산·키 확인 전 → 코드 3 | API 0회 |
| **단독 `openai_image.dart`** | `ImageStudio.run`(generate)에서 `HistoryGate.forOutput` | 역사 시즌의 계획 폴더나 작업 폴더(`asset_work/<id>`)로 나가는 출력은 API 0회로 차단. `qa/...` 같은 범용 출력은 그대로 전송되고, 드라이런도 그대로. 사실 승인 후에는 전송됨 |
| **사운드(ElevenLabs Python/JS/CLI)**, curl 등 수동 이미지 API | PreToolUse 훅 → `history_guard.dart --hook` | 출력 경로가 역사 시즌의 asset root·계획 폴더·작업 폴더면 exit 2로 명령이 실행되기 전에 막힘. 시즌과 무관한 경로, 유료 호출이 아닌 명령, 일반 시즌은 통과. 실제 훅 셸 실행으로 확인 |
| 게임 생성 | 생성기·팩토리 7단계 `game: true` | fact·reveal·puzzle 승인과 레벨 작성 전에는 `[history_blocked]` |

승인 무효화:

- 사실의 문장이나 출처(인용문 포함)가 바뀌면 그 사실이 `stale`이 되고, 그 사실을 인용한 reveal과 퍼즐 승인도 `stale`이 된다. 각 해시에 인용한 사실 JSON이 포함되기 때문이다.
- 퍼즐 승인은 해당 미션들의 계획 JSON과 그 Case의 `levels.json`까지 해시한다. 힌트 한 줄이나 레벨 문장 하나만 바뀌어도 다시 검토해야 한다.

`forOutput`이 시즌을 찾는 범위: `content_pipeline/seasons/<id>/`, `content_pipeline/asset_work/<id>/`, brief나 매니페스트의 `assetRoot`. mode를 판단할 수 없는 시즌의 폴더는 차단한다.

## 5. 퍼즐 추론 가능성 검토 체계

| 항목 | 자동 검사 | 사람 검토 |
|---|---|---|
| 정답에 필요한 정보가 게임 안에 있음 | 단서 문구가 해당 미션의 글에 있음(PART 1). **연도가 정답이면 그 연도가 퍼즐까지의 글에 나와야 함**(`history_answer_unshown`) | 체크리스트 1 |
| 단서가 퍼즐보다 먼저 또는 같은 단계 | `history_clue_late` | 2 |
| 세 레벨 모두 추론 가능 | 단서가 레벨마다 있음. 레벨 파일이 없으면 게임 게이트에서 차단 | 3 |
| 사전 역사 지식 불필요 | (위 두 검사가 일부 대신함) | 4 |
| 역사와 창작 단서가 모순되지 않음 | **Case의 모든 글(힌트·오답 피드백 포함, 모든 레벨)에 나오는 연도는 승인 대상 사실이나 `fiction`에 선언되어 있어야 함**(`history_year_unsupported`) | 5 |
| 정답이 하나로 수렴 | **선택형은 모든 오답에 `whyNot`, 그 외에는 `whyOnly` 필수**(`history_uniqueness_missing`) | 6 |
| 오답·힌트가 역사를 왜곡하지 않음 | 연도 검사(위) | 7 |

- 사람의 검토는 `approve.dart <seasonDir> puzzle <missionId>`로 기록한다.
  - 자동 검사에 오류가 있거나, 인용한 사실이 미승인이거나, 레벨 파일이 없으면 거부된다.
  - 통과하면 "the automatic checks hold; they are not this review" 문구와 7개 체크리스트를 보여주고, 터미널에서 ID를 입력받는다.
- 보고서 요약(`summary.history`)은 `puzzlesReviewedByPerson`만 센다. 자동 검사를 통과했다는 표시는 없다. 미검토 퍼즐은 `history_puzzle_unreviewed`로 계속 표시된다.
- PART 1의 INFO 항목 `history_reasoning_review`는 이 승인 체계로 대체되었다.

## 6. 신규 테스트 및 회귀 테스트 결과

- `flutter analyze`: **No issues found**.
- `test/season_gen/history_dossier_test.dart`: **42개 통과**. 다룬 항목:
  - 모드, 출처, 승인, 퍼즐 근거(PART 1)
  - 유일 정답(`whyNot`/`whyOnly`), 연도 왜곡 검사, 연도 정답 미노출
  - 퍼즐 승인 거부 조건과 체크리스트 출력, 힌트 변경 시 재검토
  - reveal 레벨 검사(누락, 숫자 변경, 고유명사 누락, 복사)와 연도 근거 검사, reveal 승인 조건, 변경 시 재승인
  - 사실 변경 시 reveal·퍼즐 승인 무효화
  - 파이프라인 API 0회, 단독 이미지 도구 API 0회와 범용·드라이런 비차단
  - 사운드·curl 명령 차단, 일반 시즌·무관 경로 통과, 가드 CLI와 셸 훅 실제 실행
  - 게임 생성 단계별 차단과 레벨·출처 출력, 일반 시즌 무출력
- `test/history_reveal_ui_test.dart`: **7개 통과**. 다룬 항목:
  - 일반 시즌 무표시
  - 영역 순서와 분리, 제목 시맨틱
  - JUNIOR/MASTER 문장 선택
  - SOURCES 다이얼로그(시스템 뒤로가기와 CLOSE)
  - 320×568 화면, 글자 크기 1.6배에서 오버플로 없음
  - 재진입(settled) 표시, 저장 키 추가 없음
- 회귀: `test/season_gen`, `test/season_planner`, `test/asset_pipeline`, `test/season_factory`, `test/ai_agents`, `test/generated_seasons_test.dart`, `test/case01_case_closed_test.dart`, `test/case_solved_desk_test.dart`, `test/difficulty_content_test.dart`, `test/detective_report_test.dart` + 신규 2개 파일 = **702개 모두 통과**(175초).
- Rome·New York:
  - `generate_season.dart --target game --check` 결과 둘 다 `up to date`(차이 0)
  - `plan_season.dart check --all` 출력이 PART 1 이전 기준선과 동일
- 전체 `flutter test`, Release 빌드: **실행하지 않음**(요청대로 제외).

## 7. PART 1 대비 개선점

- 사람이 승인하는 단위가 사실 하나에서 **사실 + reveal + 퍼즐 추론**으로 늘었다. 각각 검토한 내용 전체를 해시하므로 연쇄적으로 무효화된다.
- 게이트가 두 단계로 나뉘었다. 이미지 이전에는 사실만, 게임 이전에는 reveal·퍼즐 검토·레벨까지 요구한다. 그림이 텍스트 검토를 기다리지 않는다.
- PART 1에서 남았던 우회로 두 개를 막았다:
  - 단독 이미지 CLI
  - 레포 밖 사운드·이미지 API 명령(훅)
- 추론 가능성: "문자열이 있음"에서 나아가 유일 정답 근거, 연도 정합성, 연도 정답 노출 검사를 추가했고, 검토는 사람의 승인으로만 기록된다.
- 데이터 모델만 있던 reveal이 실제 화면, 레벨별 문장, 출처까지 연결되었다.

## 8. 남은 위험 및 PART 3 제안

남은 위험:

1. **훅의 한계**: Claude Code의 Bash 명령만 본다.
   - 사람이 직접 터미널에서 실행하는 경우, 스크립트 파일 안에서 API를 부르는 경우(`python gen.py`), 경로를 변수로 만드는 경우는 잡지 못한다.
   - 결과 파일을 `assets/`에 넣는 단계는 기존 파이프라인 경로가 아니면 막히지 않는다.
   - 사운드 생성을 레포 도구로 들여오면(이미지처럼 `ImageStudio` 같은 한 지점) 확실히 막을 수 있다.
2. **훅 비용**: 관련 명령마다 `dart run` 시작에 몇 초가 걸린다. 관련 없는 명령은 셸 grep으로 바로 통과한다. 훅 설정은 새 세션부터 확실히 적용된다.
3. **레벨 검사는 표면 검사**: 숫자와 고유명사만 비교한다. 의미가 같은지는 reveal 승인 체크리스트에 의존한다.
4. **연도 검사**: 4자리 연도(1000–2099)만 본다. "the fifteenth century" 같은 서술형 시대 표현이나 인물 이름의 왜곡은 사람 검토에 맡긴다.
5. **SOURCES**: URL을 열지 않고 보여주기만 한다. 실제 링크 열기는 보호자 게이트가 필요하므로 이번에 넣지 않았다.
6. **실기기 미확인**: 위젯 테스트로만 확인했다(iOS/Android 실기기, VoiceOver/TalkBack 미확인).

PART 3 제안:

1. 서울 dossier 작성 시작(Case 01 훈민정음): 출처를 실제로 열고 인용 → `source_checked` → 사용자가 fact 승인
2. 서울 이야기 틀(A: 현재 전시회 / B: 시대별 현장) 결정 후 Case 01 계획과 reveal 문장 작성
3. 사운드 생성을 레포 도구로 들여올지 결정 — 필요하면 `ImageStudio`처럼 게이트를 둔 단일 진입점을 만든다
4. 실기기에서 Case Closed reveal 섹션의 표시와 스크린리더 확인
5. PLAYBOOK과 plan/create-season 스킬에 역사 모드 절차 반영(dossier 먼저 → 승인 3단계)
