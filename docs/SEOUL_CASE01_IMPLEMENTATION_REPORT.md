# Seoul Case 01 — The Secret of the King's Letters 구현 보고 (2026-11-05)

설계: `docs/SEOUL_CASE01_REDESIGN.md` (D1–D5 승인). 기존 Bae 도난 사건을 새 이야기로 교체했다. 개발자 모드 **SEOUL PILOT — CASE 01**에서 ROOKIE / JUNIOR / MASTER 모두 끝까지 플레이된다. 커밋·푸시는 하지 않았다.

## 1. 플레이 흐름

| 단계 | 장소(그림) | 엔진 | 정답 |
|---|---|---|---|
| Story Intro | 왕의 처소, 세종의 뒷모습 (`cover/kings_study.webp`) | — | — |
| M1 The Paper Under the Gate | 안문 (`gate_courtyard`), 택 초상 대화 | `trace_deduction` — 앱이 그리는 흔적 3개(門 종이쪽, 물동이 자국, 물방울) | `c` 부엌 우물 길 |
| M2 Sora's Lesson Box | 우물가 (`well_yard`), 소라 초상 대화 | `letter_tile_lock` — 한글 타일 5개 | `ㅅㄱㅈㅂㅇ` |
| M3 Four Little Groups | 글방 (`copy_room` 재사용), 택 초상 대화 | **`syllable_compose` (신규)** | `서고지붕` |
| Final The King's Letters | 비 오는 서고 (`book_hall_rain`) | `evidence_talk` — 세종 초상, 질문 셋 | 세 증거 제시 |
| Ending | — | 분이·소라 초상 (`bun_i`, `sora`) | — |
| Case Closed | — | REAL HISTORY 7줄 / IN THIS MYSTERY 3줄 / SOURCES | — |

## 2. letter_tile_lock 한글 지원 확인 결과

- **결함을 발견해 고쳤다.** `AnswerChecker.normalize`가 `[^A-Z0-9]`를 지워서 한글 정답이 빈 문자열이 되었다. 그래서 **무엇을 넣어도 정답**으로 처리됐다. 한글 범위(U+3131–318E, U+AC00–D7A3)는 지우지 않도록 바꿨다. 라틴 문자 정답의 동작은 그대로다. 도구 쪽 같은 정규화 두 곳(`puzzle_selection_check`, `season_quality`)도 맞췄다.
- 엔진의 제약: 타일 수 = 칸 수다. 방해 타일을 넣을 수 없다. 그래서 M2는 다섯 글자를 택의 순서대로 놓는 퍼즐이 되었다. 순서가 틀리면 `orderFeedback`이 나온다.

## 3. 신규 엔진 syllable_compose

- 규칙 `lib/puzzles_v2/core/syllable_rules.dart`: 순수 Dart. 유니코드 조합, 선(ㅡ/ㅣ)+점 위치 → ㅣㅏㅓㅡㅗㅜ, 검증, 저장(`pv2:syllables:1:`), 레벨 구조.
- 위젯 `lib/features/mission/widgets/syllable_board.dart`: 탭만 사용, 48dp, 선택 표시(✓·채움·테두리), 스크린리더 이름, 키보드 포커스, 오답 묶음 "CHECK THIS ONE", 해결 후 읽기 전용.
- 기존 시스템 재사용: `_submit` → `GameController.submitAnswer`(오답 기록, 보상 1회), `recordPuzzleState`, 기존 힌트·try-again 시트·`feedback`.
- 연결: `SeasonContent.syllables`, 디스패치 마지막 단계, `SeasonContentValidator._syllables`, `DifficultyContent.structureOf`, 팔레트 `syllable_compose`, 생성기(`play.syllables`, 스키마, PlayCheck, palette_facts, 레벨 비텍스트 키 `initial/vowel/final`).
- `TraceSketch`에 `waterRing`, `waterDrops`, `copiedScrap`(門을 앱 텍스트로 세 번)을 추가했다. 그림에는 글자가 없다.

## 4. 역사 검증 (history_dossier.json)

| id | 내용 | 출처 (2026-11-04 원문 확인) |
|---|---|---|
| h1, h2, h4, h5, h6 | 기존(1443 창제, 1446 책 완성, 천지인, 서문 목적, 열흘) | 기존 확인 유지 |
| h3 (개정) | 제자해: ㄱ 혀뿌리가 목구멍을 막음, ㄴ 혀가 윗잇몸에 닿음, ㅁ 입, ㅅ 이, ㅇ 목구멍 | 우리역사넷(국사편찬위) 원문, 한국민족문화대백과, 국립한글박물관 |
| h9 | 서문: 나랏말이 중국과 달라 백성이 뜻을 펴지 못함 | 세종실록 28년 9월 29일(원문), 국립한글박물관 |
| h10 | 가획: 소리가 세지면 획을 더함 | 우리역사넷(제자해 원문), 한국민족문화대백과「한글」 |
| h11 | ㅗㅏㅜㅓ = ㆍ와 ㅡ/ㅣ의 결합 | 한국민족문화대백과「훈민정음28자모」, 우리역사넷 |
| h12 | 合字: ㆍㅡㅗㅜ는 초성 아래, ㅣㅏㅓ는 오른쪽, 종성은 초성을 다시 씀 | 세종실록(원문), 한국민족문화대백과「한글」 |
| h13 | ㆍ·ㆆ·ㅿ·ㆁ은 오늘날 쓰이지 않음 | 국립한글박물관 기획전시, 한국민족문화대백과「한글」 |

- 상태: 새 사실과 개정한 사실은 내가 출처를 직접 열어 인용을 확인한 뒤 `source_checked`로 두었다(수동 승인 절차 없음, HistoryGate 자동 검사 통과). h7은 draft, h8은 쓰지 않음.
- 15세기 표기: 음절 단위 모아쓰기는 1446년 규칙(h12)과 같다. 쪽지의 단어(서고·지붕)는 현대 맞춤법으로 썼다고 IN THIS MYSTERY와 dossier fiction에 밝혔다. 옛 점 ㆍ는 M3 조각에서 "dot"으로 보이고, 완성 모음은 현대 글자로 그린다. "점이 짧은 획이 되었다"는 출처를 찾지 못해 쓰지 않았다.
- 실존 인물(D1): 세종의 모든 대사는 창작이다. 두 줄은 서문을 풀어 썼다(h9, h5). Reveal과 dossier fiction에 명시했다.

## 5. 글꼴

- macOS/iOS 대체 글꼴 Apple SD Gothic Neo가 ㆍ(U+318D), 쓰인 자모 전부, 서·고·지·붕, 門을 모두 가진다(CoreText 확인). Flutter는 번들 글꼴에 없는 글자를 시스템 글꼴로 그린다.
- Android(Noto Sans CJK)와 실기기 화면은 확인하지 않았다.

## 6. 이미지 (7장, 누적 $0.9018 / $1.00)

- 신규: `sejong`, `taek`, `bun_i`, `gate_courtyard`, `well_yard`, `book_hall_rain`, `cover/kings_study`. 7회 호출에 $0.2971를 썼고 재생성은 없었다. 7장 모두 직접 보고 확인했다. 글자는 없다.
- 팩토리의 사전 점검(보수 추정치 ×1.5)은 7장 합계 $0.6085로, 남은 $0.3953을 넘었다. 그래서 4장 + 3장 두 번으로 나눠 실행했다. 호출마다 하는 예산 검사는 그대로 적용됐다. 나누려고 계획 파일의 초상 경로를 잠시 뺐다가 다시 넣었다.
- `kings_study`는 참조 이미지 방식이면 추정 $0.11이 들어 $1.00을 넘는다. 그래서 참조 없이 세종의 뒷모습으로 그렸다(얼굴 불일치도 없음).
- 쓰지 않게 된 기존 파일(`royal_archive`, `scholar_papers`, `gate_ledger`, `letter_found`, `bae`, `palace_night` 등)은 지우지 않았다. 매니페스트에서만 뺐다. `ArtAssets.evidencePictures`의 옛 증거 그림 2개 연결은 뺐다.
- M1 흔적과 장소의 좌표는 새 그림의 격자 위에서 측정했다(`measuredOn` sha256).

## 7. 테스트

- 새로 만든 테스트: `test/puzzles_v2/syllable_rules_test.dart`(규칙 6개), `test/sandbox/s7_pilot_syllables_test.dart`(R/J/M × 320폭 글자 ×1·×1.6, 거부·복원·스크린리더, 해결 화면). 이 테스트가 ×1.6에서 조각 라벨이 넘치는 문제를 찾아내서 고쳤다.
- 고친 테스트: `s7_pilot_play_test`(R/J/M에서 M1 오답·힌트, 재실행, 보상 1회, M2 순서 오답, M3 모음 오답과 "CHECK THIS ONE", 세종 대화, 엔딩, Reveal, SOURCES), `s7_pilot_dev_mode_test`, `s7_pilot_traces_test`(M1 흔적), 팔레트·디스패치의 기대값(새 엔진 등록).
- 삭제한 테스트: `s7_pilot_records_layout_test`. M2가 더 이상 record_mismatch가 아니다. 같은 역할은 syllables 레이아웃 테스트가 맡는다.
- 회귀 묶음: puzzles_v2, 시범 5개, single_case, timeline, engines, s9_ep01(글자 자물쇠), season_gen 전체, season_planner 전체, season_factory, answer_checker, developer_session, difficulty_content, generated_seasons, history_reveal_ui, letter_lock_title, story_backdrop, story_intro, timeline_board, typography, puzzle_engine_collisions, puzzle_palette, art_assets → **+870, 실패 0 (5분 40초)**.
- `flutter analyze`: 문제 없음. Rome·New York `generate_season --target game --check`: up to date.
- **전체 `flutter test`는 실행하지 않았다.**

## 8. 남은 위험

- 실기기 미확인: iPhone과 Android에서 한글·ㆍ 렌더링, 320폭 화면의 실제 그림 잘림, VoiceOver.
- `CaseTalk`(공유 컴포넌트)는 320×568에서 긴 대사와 증거 패널이 겹치면 넘친다. 이번에는 Final 대사를 짧게 써서 피했다. 컴포넌트는 그대로 두었다.
- 시범 계획 검사의 ERROR 13개(12개 Case 없음, story bible 없음, prologue 없음)는 단일 Case 시범이라 생기는 것으로, 이전과 같다.
