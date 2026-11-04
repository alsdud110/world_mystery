# Historical Fiction Mystery 모드 — PART 0 조사·설계 보고서

작성일 2026-11-04 · 범위: 조사와 설계만. 코드·에셋·시즌 데이터 변경 없음, 커밋 없음.

표기: **[확인]** = 이번 조사에서 소스 코드/파일을 직접 읽어 확인. **[추정]** = 구조상 그럴 것으로 보이나 실행·정독으로 확인하지 않음.

---

## 1. 현재 시즌팩토리 아키텍처

### 1.1 진입점과 흐름 [확인]

| 단계 | 진입점 | 산출물 |
|---|---|---|
| 기획 | `.claude/skills/plan-season/SKILL.md` → `tool/season_planner/PLAYBOOK.md`, `dart run tool/season_planner/plan_season.dart init/format/check/assets` | `content_pipeline/seasons/s<n>_<city>/` (brief, story_bible, season.plan, case.plan ×12, assets.manifest, quality_report) |
| 제작 | `.claude/skills/create-season/SKILL.md` → `dart run tool/season_factory/season_factory.dart status/run/reviewed/reject` | 이미지(WebP) → `assets/`, 생성 코드 → `lib/data/generated/<seasonId>/` |

`season_factory.dart run`의 단계(각 단계는 미완료일 때만 실행, 종료 코드로 정지):

1. 계획 검사 `SeasonQuality` → ERROR 시 **exit 10**
2. `asset_pipeline --doctor --fix` (기기 간 이미지 기록 정합)
3. 미검토 이미지 리뷰 시트 → **exit 20** (Claude가 시트를 직접 보고 `reviewed`/`reject`)
4. 게임에 쓰이는 이미지 `--batch`개 생성(OpenAI), 예산 초과 **exit 40**, API 오류 **exit 1**
5. `--apply`: WebP 변환(`tool/asset_optimizer`) → `assets/`, `pubspec.yaml`
6. 그리드 시트로 지도 랜드마크·탐색 영역 측정 → **exit 30**
6b. 케이스별 `levels.json`(Junior/Master) 작성·검사 → **exit 35**
7. `generate_season.dart --target game` → **exit 50**
8. `flutter analyze` + `test/generated_seasons_test.dart` (`--full-tests` 전체) → **exit 60**

### 1.2 Case/Mission 생성 [확인]

- 계획 형식: `tool/season_gen/plan_models.dart`(SeasonPlan/CasePlan/MissionPlan/PuzzlePlan) + `tool/season_gen/schema/*.schema.json`. 스키마는 `additionalProperties: false` — **모르는 필드는 거부**.
- 구조 검사: `plan_check.dart`, 퍼즐 선택 `puzzle_selection_check.dart`(팔레트·엔진·정답 형식), 단서 그래프 `clue_graph_check.dart`(단서가 발견 전에 쓰이지 않는지), 플레이 검사 `play_check.dart`.
- 코드 생성: `generate_case.dart`(1,344줄)가 케이스 JSON·학습 설계·퍼즐 테이블·엔딩을 `.g.dart`로 만들고, `generated_seasons.g.dart`에 등록 → `SeasonCatalog`가 읽음(`lib/data/mock/season_catalog.dart`의 `SeasonContent`).
- 생성 가능한 퍼즐: 텍스트형(`text_choice`, `word_entry`, `order_sequence`, `letter_tile_lock`, `combo_dial_lock`) + 그림형(`scene_explore_choose`, `dark_room_search`, `witness_compare`, `picture_choice`). 그 외 엔진은 `generate_unsupported`.

### 1.3 스토리·대화·퍼즐 규칙 [확인]

- 소스: `PLAYBOOK.md` §1–2, `CLAUDE.md` §20. 스토리 바이블(`planning/story_bible.json`, 검사기 `tool/season_planner/story_bible.dart`)이 "작가의 진실" — **게임은 읽지 않음**. 바이블도 모르는 필드를 거부(`bible_field_unknown`).
- 대화: 미션의 `play.talk.before/after`, `play.discovery`, 파이널의 `play.ending`. 대사 3–12단어, 8–12세 대상.
- 퍼즐 규칙: 정답은 게임 안 텍스트로 추론 가능해야 하며 **외부 지식 금지**("give the list, the definition, the guidebook line inside the letter") — 역사 모드의 요구 5와 그대로 맞물림.
- 영어 휴리스틱: `english_check.dart`(15단어 초과 문장, 110단어 초과 편지 등 WARNING).

### 1.4 난이도 ROOKIE/JUNIOR/MASTER [확인]

- 계획은 Rookie 영어로 한 번만 작성. 케이스별 `cases/<caseId>/levels.json`, 시즌 줄은 `season.levels.json`에 Junior/Master 재작성.
- `tool/season_gen/case_levels.dart check`: 정답·이름·숫자·표현 유지, Rookie 복사 금지(6단어 이상 문장 절반 초과 시 거부). `review`로 R/J/M 대조.
- 생성 결과 `<caseId>_levels.g.dart`(`casePatches`, `variants`, `writtenLevels`), 검증 `test/difficulty_content_test.dart`.
- **난이도는 영어만 다르고 게임은 동일**이라는 규칙이 명시되어 있음.

### 1.5 이미지·사운드 [확인/추정]

- 이미지 [확인]: `assets.manifest.json` → `tool/asset_pipeline`(계획·예산·스케줄·상태) → `tool/ai_agents/openai_image.dart`. 예산은 `planning/factory.json`에 누적(Git 포함). 불량 이미지는 삭제하지 않고 `asset_work/<id>/superseded/`. 리뷰·측정은 사람이(Claude가 시트를 보고) 결정, 도구는 판정하지 않음. 이미지 속 글자 금지.
- 사운드 [확인]: 팩토리에는 사운드 생성 단계가 **없음**. `assets/sounds/processed/`의 공용 효과음(UI 탭, 타자기 등)을 씀. create-season 스킬은 "사운드 추가 금지". 공용 사운드가 시즌별로 어떻게 매핑되는지(`test/audio_context_mapping_test.dart` 등)는 [추정] — 이번에 정독하지 않음.

### 1.6 시즌 간 연결 [확인]

- `SeasonAvailability`(`lib/features/game/game_providers.dart:179`): 첫 시즌은 항상 열림, 이후 시즌은 앞 시즌 완료 후 열림.
- 생성 시즌은 `generatedSeasons` 리스트(London·Paris 뒤, 시즌 순서). 현재 s3_rome, s4_newyork.
- 월드맵: `lib/features/world_map/world_cities.dart` — **Seoul은 이미 그려진 도시**(`_drawn = [london, paris, rome, tokyo, seoul]`). `art.worldCity.mapAt` 사용 가능.
- 스토리상 시즌 간 연결은 없음(각 시즌 독립 미스터리). 다른 시즌 도시 이름 언급은 검사기가 잡음.

### 1.7 자동 테스트·품질 검증 [확인]

`plan_season.dart check`(스키마→구조→퍼즐→단서→PlayCheck→실제 생성기 인메모리→바이블→매니페스트→영어), `case_levels.dart check`, `test/season_planner/`, `test/season_gen/`, `test/generated_seasons_test.dart`(시즌 통째 플레이, 4개 화면 크기), `test/difficulty_content_test.dart`, `asset_optimizer` 테스트.

### 1.8 실패 복구 [확인]

- `run`은 멱등·재개형: 다시 실행하면 멈춘 곳부터.
- 한 번 만든 이미지는 다시 사지 않음(`generated` 기록), 예산 누적 기록, API 오류 시 즉시 중단(루프 금지).
- `init`은 `<folder>.part`에 쓰고 이름 변경(원자적).
- 두 기기: `--doctor --fix`가 `adopted`/`restored`/`CONFLICT` 처리. `asset_work/`는 Git 밖 → 수동 백업 `~/world_mystery_backups/`.
- 승인: `tool/season_gen/approve.dart` + `approvals.json`(해시 기반, 추가만 됨, `draft/approved/stale/missing` 판정).

### 1.9 설정·템플릿·프롬프트 위치 [확인]

| 무엇 | 어디 |
|---|---|
| Claude 절차 | `.claude/skills/{plan,create}-season/SKILL.md`, `tool/season_planner/PLAYBOOK.md` |
| 퍼즐 카탈로그 | `tool/season_gen/GAMEPLAY_CATALOG.md` |
| 스키마 | `tool/season_gen/schema/` |
| 이미지 스타일·프롬프트 | `tool/ai_agents/image_styles.dart`, `STYLE_GUIDE.md`, 각 시즌 `assets.manifest.json`(`seasonStyles`, `prompt`) |
| WebP 정책 | `tool/asset_optimizer/image_policy.json` |
| 모범 예 | `content_pipeline/seasons/s3_rome/`, 샌드박스 `s9_sandbox/` |

---

## 2. 역사 모드 추가 가능 여부

**가능. 기본 모드 무변경으로 추가할 수 있다.** 근거:

1. 팩토리는 얇은 오케스트레이터라 검사 하나를 끼워 넣기 쉽다(`SeasonQuality` 단계 1).
2. 역사 검증 정보는 게임이 읽을 필요가 없는 작가용 정보 → 스토리 바이블처럼 **별도 파일**에 두면 기존 스키마·바이블을 건드리지 않는다.
3. "외부 지식 없이 게임 텍스트로 풀린다"는 규칙이 이미 있다.
4. 모드 표시는 `planning/brief.json`에 `"mode"` 한 필드. 없으면 기존 동작(현재 brief는 `init`만 쓰고 검사기는 읽지 않음 [확인]).

**새로 필요한 것은 한 가지뿐**: 해결 후 "실제 역사 vs 창작" 화면. 기존 `caseSummary`/`play.ending`은 아이용 짧은 대사라 사실·창작 구분 표시에 부족하다 → 선택 필드 + 사건 해결 화면(`case_solved_screen.dart`) 섹션 하나.

---

## 3. 필요한 최소 변경 파일 (PART 1 이후, 승인 시)

| # | 파일 | 변경 | 기존 시즌 영향 |
|---|---|---|---|
| 1 | `tool/season_planner/plan_season.dart` | `init --mode historical_fiction_mystery` → brief에 `mode` 기록 | 없음(옵션) |
| 2 | **신규** `tool/season_planner/history_dossier.dart` | `planning/history_dossier.json` 검사기 | 없음 |
| 3 | `tool/season_planner/season_quality.dart` | brief.mode가 역사 모드일 때만 2 실행 | 없음(분기) |
| 4 | `tool/season_gen/schema/case_plan.schema.json`, `plan_models.dart` | 선택 필드 `play.history`(reveal 문구) | 없음(선택 필드) |
| 5 | `tool/season_gen/generate_case.dart` | `play.history` 있을 때만 `historyNotes` 테이블 출력 | 기존 생성물 바이트 동일해야 함(검증 항목) |
| 6 | **신규** `lib/data/models/history_note.dart`, `lib/data/mock/season_catalog.dart` | `SeasonContent.historyNotes = const {}` | 기본값으로 무영향 |
| 7 | `lib/features/result/case_solved_screen.dart` | 노트가 있을 때만 "THE TRUE STORY" 섹션 | 노트 없는 시즌 화면 동일 |
| 8 | `tool/season_gen/case_levels.dart` | reveal 문구도 Junior/Master 대상에 포함 | 없음 |
| 9 | `tool/season_factory/season_factory.dart` | 역사 모드: 이미지 단계(4) 전에 dossier 승인 확인 | 없음(분기) |
| 10 | `tool/season_gen/content_approval.dart`, `approve.dart` | 승인 종류 `historyDossier` 추가 | 기존 기록 그대로 |
| 11 | `PLAYBOOK.md` 부록, create/plan-season 스킬에 모드 절 | 문서 | 없음 |
| 12 | 테스트 신규: dossier 검사, 생성기 history 테이블, 해결 화면 위젯 | | |

"기존 시즌 보호" 검증: 변경 후 s3_rome·s4_newyork를 재생성해 `git diff lib/data/generated` 가 비어야 하고, `test/season_planner/`, `test/generated_seasons_test.dart`, `test/difficulty_content_test.dart`, `case_solved` 관련 테스트가 통과해야 한다. Season 1·2(손으로 쓴 mock)는 1·4·5·7 변경과 무관.

---

## 4. 역사 검증 프로세스

### 4.1 Case별 기록 — `planning/history_dossier.json` (게임에 들어가지 않음)

```json
{
  "schemaVersion": 1,
  "seasonId": "s5_seoul",
  "mode": "historical_fiction_mystery",
  "cases": [{
    "caseId": "s5_ep01",
    "subject": "훈민정음 창제와 반포",
    "period": {"label": "1443–1446", "from": 1443, "to": 1446},
    "location": {"name": "경복궁", "today": "서울 종로구", "inCity": true},
    "facts": [{
      "factId": "f1",
      "statement": "세종은 1443년 겨울(음력 12월) 훈민정음을 만들었다.",
      "status": "verified",
      "sources": [
        {"tier": "A", "title": "조선왕조실록 세종 25년 12월 30일", "url": "https://sillok.history.go.kr/…",
         "quote": "<원문에서 그대로 옮긴 문장>", "accessed": "2026-11-xx"}
      ],
      "variance": "반포 날짜: 실록 9월 29일 기사 vs 해례본 9월 상순 → 게임에는 '1446년'까지만 쓴다"
    }],
    "fiction": ["사라진 해례 한 장", "가상 인물 전원", "도난 사건"],
    "realPeople": ["세종"],
    "historicalClues": [{"factId": "f1", "missionId": "s5_ep01_m2", "shownAs": "1443"}],
    "learningObjectives": {"english": ["…"], "history": ["훈민정음은 1443년에 만들어졌다"]},
    "reveal": "→ case.plan.json play.history (게임이 보여주는 문구)",
    "verificationStatus": "verified"
  }]
}
```

### 4.2 상태와 규칙

`status`: `unverified` → `sourced`(Claude가 출처 페이지를 **실제로 열어** 인용문을 옮김) → `verified`(사용자 승인) / `disputed`(자료 간 불일치) / `rejected`.

검사기(`history_dossier.dart`)가 자동으로 막는 것:

1. 퍼즐 정답·단서(`historicalClues`)에 쓰인 사실은 `verified`만. `disputed`·`unverified`는 ERROR.
2. `verified`/`sourced` 사실은 출처 2개 이상, 그중 1개 이상 Tier A, 각 출처에 `url`·`quote`·`accessed` 필수.
3. **게임 안에 근거가 있어야 함**: `shownAs` 문구가 해당 미션의 편지/이야기 텍스트에 실제로 있는지 문자열 검사 → 요구 5(사전 지식 불필요) 자동 보장.
4. `realPeople`의 이름이 시즌 캐릭터(`characters[].name`)이면 ERROR — 실존 인물에게 지어낸 대사·행동을 주지 않는다.
5. 모든 Case에 `fiction` 목록과 `play.history`(해결 후 사실/창작 구분 문구) 필수.
6. `play.history`의 "사실" 줄은 `verified` 사실에서만 나와야 함(factId 연결).

### 4.3 출처 등급

- **Tier A**: 1차 사료 원문(조선왕조실록 sillok.history.go.kr, 승정원일기), 국가유산청 국가유산포털, 국립중앙박물관·국립고궁박물관·서울역사박물관, 한국민족문화대백과사전(encykorea.aks.ac.kr), 우리역사넷(국사편찬위원회), 학술 논문.
- **Tier B**: 서울시 공식 자료(news.seoul.go.kr, mediahub.seoul.go.kr), 주요 언론의 역사 기획.
- **불가**: 나무위키 등 위키류, 블로그·카페, AI 요약 — 단서 찾기용으로만.

### 4.4 사람이 할 일

AI는 `sourced`까지만 올린다. `verified`는 사용자가 `approve.dart approve historyDossier <caseId>`로 승인(해시 기반이라 이후 수정되면 `stale`). 팩토리는 역사 모드에서 **승인 전에는 이미지에 돈을 쓰지 않는다**.

### 4.5 이번 조사에서 실제로 본 것 (검증 아님, 예비 확인)

이 단계의 웹 조사로 **자료 간 불일치가 흔하다**는 것이 확인되었다 — 검증 단계가 꼭 필요한 이유:

| 항목 | 일치하는 부분 | 불일치 |
|---|---|---|
| 훈민정음 | 1443년 창제, 1446년 해례본, 1940 안동 발견, 1997 유네스코 | 반포 날짜(음 9/29 vs 9월 상순) |
| 측우기 | 1441–1442 세종대, 수표 1441 수표교 | 연도(1441/1442), **발명자(장영실 통념 vs 세자 문종)** |
| 보신각 | 인정 28회 / 파루 33회로 도성 문 여닫음 | 인정 시각(밤 10시 vs 오후 7시) |
| 경복궁 전등 | 1887년 건청궁, 에디슨 회사 설비 | 세부 날짜·"아시아 최초" 주장(위키 출처) |
| 서울 전차 | 1899년 5월, 한성전기회사, 서대문–청량리(동대문 경유) | 개통일(5/4·5/17·5/20), 기점(서대문/남대문) |
| 덕수궁 전화 | 1890년대 후반 궁궐 전화 | **1896 vs 1898** — 단정 불가 |

→ 설계 원칙: 불일치하는 세부(날짜, 발명자)는 **게임에 쓰지 않거나** reveal에서 "자료마다 다르다"고 말한다. 퍼즐 정답은 모든 자료가 일치하는 사실(예: 28과 33, 1443)만 쓴다.

---

## 5. 서울 시범 시즌 12 Case 후보

시즌 번호: **Season 5 (`s5_seoul`)** — London 1, Paris 2, Rome 3, New York 4 다음 [확인: catalog, content_pipeline].

### 5.1 핵심 결정 필요: 이야기 틀

| 안 | 내용 | 장점 | 위험 |
|---|---|---|---|
| **A (권장)** 현재 서울 틀 | 가상의 전시 "서울 600년"에서 누군가 기록을 몰래 바꾸고 유물 복제품을 훔친다. 탐정은 게임 속 사료로 **진짜 기록을 되찾는다** | "사실 vs 창작" 자체가 주제가 됨, 실존 인물에게 대사를 줄 필요 없음, 시대 순서를 자유롭게 배치, "시간여행 금지" 규칙과 충돌 없음 | 시대 현장감이 약함 → 장소 그림(궁궐·다리·종각)으로 보완 |
| B 시대별 현장 | 각 Case가 그 시대에 벌어짐(1446 경복궁 등), 가상 인물만 등장 | 몰입감 | 실존 인물 주변 창작 → 왜곡 위험 큼, 시대마다 의상·건물 고증 이미지 비용↑ |

### 5.2 후보 (안 A 기준, 3막)

검증 상태는 모두 **unverified 후보**. 4.5에서 예비로 본 항목만 표시.

| Case | 주제 / 연대 | 서울 연관 | 창작 미스터리 예 | 퍼즐 방향 (영어 사용) | 예비 확인 | 위험 |
|---|---|---|---|---|---|---|
| **Act 1 — 세종의 서울** |
| 01 | 훈민정음 창제·반포 1443/1446 | 경복궁 | 사라진 해례 한 장, 바뀐 글자 설명판 | 자음은 발음 기관 모양, 모음은 하늘·땅·사람 — 게임 속 해설 문서를 읽고 글자 조각 맞추기(letter tile / picture choice) | 일부 | 한글 글리프를 게임 폰트로 그려야 함(그림 속 글자 금지 규칙) |
| 02 | 측우기·수표 1441 | 청계천 수표교 | 비 기록이 조작됨 | 눈금 읽기·전후 비교(order / word entry) | 일부 | 발명자 논쟁 → 이름 안 씀 |
| 03 | 자격루 1434 | 경복궁 보루각 | 멈춘 물시계 복제품 | 시간 순서·원인과 결과 문장(sequence) | 미확인 | 기계 원리 단순화 필요 |
| 04 | 보신각 종 인정·파루 | 종로 | 종 치는 기록이 바뀜 | 28·33 숫자, 문 열고 닫기(combo dial) | 일부 | 시각은 자료 불일치 → 숫자만 사용 |
| **Act 2 — 도성과 궁궐** |
| 05 | 한양 천도·경복궁 창건 1394–95 | 경복궁 | 전시 연표가 뒤섞임 | 연표 정렬(sequence) | 미확인 | |
| 06 | 한양도성·숭례문 1396 / 2008 화재·2013 복구 | 도성 성곽 | 성문 지도 조각 | 방향·위치 영어(search) | 미확인 | 화재는 담담히 |
| 07 | 종묘 1395, 유네스코 1995 | 종로 | 제례 순서 문서 | 순서·예절 표현(talk) | 미확인 | 종교·제례 묘사 신중 |
| 08 | 수선전도·대동여지도 김정호 1861 | 서울 지도 | 접힌 지도 첩 하나가 없음 | 지도 읽기(look round) | 미확인 | **"전국을 걸어 다녔다/옥사" 설은 검증 안 됨 → 사실로 쓰지 않음** (좋은 교육 예) |
| **Act 3 — 근대의 서울** |
| 09 | 규장각 1776 (정조) | 창덕궁 | 도서 목록 위조 | 목록·분류 읽기(text choice) | 미확인 | 시대 순서상 Act 2가 자연스러움 → 05–08과 교체 가능 |
| 10 | 우정총국 1884, 첫 우표 | 종로 | 우표 도안 바꿔치기 | 액면·색 설명 비교(picture choice) | 미확인 | 개국 축하연의 갑신정변 → 언급 회피 |
| 11 | 건청궁 전등 1887 / 전차 1899 | 경복궁·종로 | 전시장 정전, 노선도 조작 | 노선 따라가기(sequence/search) | 일부 | 건청궁=명성황후 시해 장소 → 언급 안 함 |
| 12 | 해례본 1940 안동 발견·간송 소장, 한글날 | 성북동(간송미술관) | Case 01의 사라진 장이 돌아옴, 범인 동기 공개 | Case 01 이후 모은 글자로 단어 완성(Final Mission) | 일부 | 일제강점기 배경 — 보존 이야기로만 |

Case 01과 12가 훈민정음으로 처음과 끝을 이루어 시즌의 단서가 이어진다(CLAUDE.md §20 "앞 증거가 뒤에 쓰임", "글자 모아 단어 만들기").

### 5.3 연대기

- 사용자 요청대로 Case 01을 훈민정음으로 두면 엄밀한 연대순(1394→1940)은 깨진다. 안 A(전시 틀)에서는 "전시실 순서"로 정당화되며, Act 2–3은 연대순을 지킨다(09 규장각은 Act 2로 옮기면 Act 3가 1884–1940 연대순).
- 엄격한 연대순을 원하면: 05→06→07→03→02→01→04→09→08→10→11→12. 대신 훈민정음이 6번째가 된다.

### 5.4 제외 권장

임진왜란·한국전쟁(폭력), 갑신정변·을미사변(정치 폭력), 3·1운동(중요하지만 창작 미스터리와 섞으면 왜곡 위험이 가장 큼 — 사용자가 원할 때만 별도 검토), 수원 화성(서울이 아님).

---

## 6. 자동 제작 과정의 변경 지점

| 팩토리 단계 | 역사 모드에서 달라지는 것 |
|---|---|
| plan `init` | `--mode historical_fiction_mystery`, `history_dossier.json` 골격 |
| 기획 (PLAYBOOK) | 바이블보다 **dossier 먼저**: 주제 → 사실 수집(WebFetch로 출처 열기, 인용 복사) → 사실 위에 창작 |
| 1 계획 검사 | `history_dossier.dart` 추가 실행 (exit 10 재사용) |
| 3–4 이미지 | 역사 모드: dossier `verified` 승인 전엔 생성 안 함(새 exit 15 "history approval"). 프롬프트에 시대 고증 줄(건물·복식), 글자 금지 유지 |
| 6b 레벨 | `play.history` 문구도 Junior/Master. 연도·숫자·고유명사는 모든 레벨 동일(기존 규칙 그대로) |
| 7 생성 | `historyNotes` 테이블 |
| 8 테스트 | 해결 화면에 reveal 표시 확인 |
| 보고 | `FACTORY_REPORT.md`에 Case별 출처 목록(dossier에서 자동 정리) |

---

## 7. 예상 작업량과 위험

| 영역 | 규모 감 |
|---|---|
| 도구(모드·dossier 검사·승인 종류·팩토리 분기) | 중 — 기존 패턴(story_bible, approvals) 복제 |
| 게임 측(모델·생성기·해결 화면·레벨) | 소–중 |
| 서울 사실 조사·dossier 12 Case | **대** — 사람 검토 시간이 병목 |
| 서울 기획·이미지·레벨 | 뉴욕 시즌과 같은 규모 + 고증 리젝트 증가 예상 |

위험:

1. **사실 오류가 아이에게 전달됨** — 가장 큰 위험. 완화: Tier A 인용 필수, 사람 승인, 불일치 세부는 미사용.
2. **이미지 고증 오류**(궁궐 구조·한복·시대 소품) — AI 이미지는 고증이 약함. 리뷰 기준에 "시대 착오" 항목 추가, 리젝트 비용 반영해 예산 여유 필요.
3. **한글 표시** — 그림 속 글자 금지라 한글 자모는 게임 폰트로 렌더링해야 함. 현재 앱 폰트의 한글 지원 여부 [미확인] — PART 2에서 확인.
4. **민감 주제** — 5.4 제외 목록으로 회피, reveal 문구 톤 검토.
5. **영어 학습과 역사 용어 충돌** — "Hunminjeongeum" 같은 긴 고유명사는 영어 휴리스틱 WARNING 유발 → glossary, 첫 등장에 짧은 설명("the book of new letters").
6. **기존 시즌 회귀** — 생성기 변경이 s3/s4 출력을 바꿀 위험 → 재생성 diff 0을 완료 조건으로.

---

## 8. PART 1~N 구현 계획

| PART | 내용 | 완료 조건 |
|---|---|---|
| **1** | 도구: `init --mode`, `history_dossier.dart`, `SeasonQuality` 분기, 승인 종류 `historyDossier`, 테스트 | 기존 `test/season_planner`·`test/season_gen` 통과, s3/s4 `check` 결과 동일 |
| **2** | 게임: `play.history` 스키마·모델, 생성기 `historyNotes`, `SeasonContent`, 해결 화면 섹션, `case_levels` 포함, 한글 폰트 확인 | s3/s4 재생성 diff 0, 위젯 테스트, `flutter analyze` |
| **3** | 팩토리 분기(승인 전 이미지 차단), PLAYBOOK·스킬 문서 | 샌드박스 시즌으로 exit 흐름 확인 |
| **4** | 서울 dossier: 12 Case 사실 조사·인용 → **사용자 검토·승인** | 모든 사용 사실 `verified` |
| **5** | 서울 기획: 바이블·시즌·12 케이스·매니페스트 (`plan_season check` ERROR 0) | dossier 검사 통과 |
| **6** | 팩토리 실행: 이미지(예산 지정), 측정, 레벨, 생성 | exit 0 |
| **7** | 전체 회귀(`flutter test` 전체 — 새 시즌은 릴리스 마일스톤), 실기기 확인, 보고서 | |

PART 4는 사람의 검토 시간이 필요하므로, PART 1–3 과 병행해 1·12번 Case(훈민정음)부터 먼저 검증하는 것을 권장한다.

---

## 부록: 이번 조사의 출처 (예비 확인용, 검증 완료 아님)

- 훈민정음: https://sgsg.hankyung.com/article/2019101176191 , https://www.khan.co.kr/article/202510092042005/amp
- 보신각: https://news.seoul.go.kr/culture/archives/24692 , https://m.seoul.co.kr/news/culture/20240118500068
- 전차: https://mediahub.seoul.go.kr/archives/1262485 , https://khan.co.kr/article/201005161759235
- 전등: https://mediahub.seoul.go.kr/archives/2008140 , https://www.korea.kr/news/reporterView.do?newsId=148942310
- 측우기·수표: https://sisul.or.kr/open_content/cheonggye/intro/assets3.jsp , https://weekly.khan.co.kr/article/202303031128481
- 덕수궁 전화: https://www.koreatimes.co.kr/www/opinion/2024/02/721_288091.html , https://www.etnews.com/200801180030

모두 Tier B(언론·지자체) 이하. PART 4에서 실록 원문·국가유산포털·한국민족문화대백과사전으로 다시 확인해야 한다.
