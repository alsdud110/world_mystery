# Seoul Pilot Case 01 — 실행 준비 및 보완 보고서

작성일 2026-11-04

**결론**
- 역사 승인 없이는 sandbox에서도 시범 콘텐츠를 만들 수 없게 막았다.
- 단일 Case 실행 경로는 만들어 두었다. 역사 내용이 없는 기존 샌드박스 Case 2개로 처음부터 끝까지 플레이해 검증했다.
- 시범 Case 자체는 승인 전이라 생성되지 않았고, 플레이 테스트도 하지 않았다.
- 승인 명령 실행, 승인 상태 변경, 유료 API 호출, 정식 서울 시즌 생성, 커밋은 없다.

---

## 1. 변경 파일

| 파일 | 구분 | 내용 |
|---|---|---|
| `tool/season_gen/generate_case.dart` | 수정 | 역사 모드는 `sandbox` 대상도 `HistoryGate(game: true)` 검사. `staticOnly`(쓰기 없는 검사)와 `Generated.writable`, `makeAndWrite`의 쓰기 거부, sandbox용 `_history.g.dart` |
| `tool/season_gen/generate_season.dart` | 수정 | `--check`를 `staticOnly`로 전달 |
| `tool/season_planner/season_quality.dart` | 수정 | 계획 검사의 인메모리 생성기 실행에 `staticOnly: true` |
| `tool/season_gen/history_dossier.dart` | 수정 | `history_case_missing`을 **작성된 Case에만** 적용(§2.3) |
| `tool/season_gen/README.md` | 문서 | sandbox 게이트 한 줄 |
| `test/season_gen/history_dossier_test.dart` | 수정 | 테스트 3개 추가 |
| `test/sandbox/single_case.dart` | 신규 | 단일 Case 실행 경로 `SingleCase`, `CasePlayer` |
| `test/sandbox/single_case_test.dart` | 신규 | 실행 경로 검증(샌드박스 s8 Case 2개) |
| `test/sandbox/s7_pilot_gate_test.dart` | 신규 | 시범 Case 승인 전 차단 / 승인 후 생성 확인 |
| `test/sandbox/s7_pilot_records_layout_test.dart` | 수정 | M2 4줄, 터치 44 이상, 글자 11px 이상을 단언 |
| `test/sandbox/plans/s7_seoulpilot/…` | 수정 | 스토리, M2, M3, dossier, levels, 시즌 계획(임시 그림 표기) |
| `docs/SEOUL_PILOT_CASE01_READY_REPORT.md` | 신규 | 이 보고서 |

변경하지 않은 것:
- `lib/` 전체, 기존 시즌 콘텐츠·에셋, 저장·보상·해금 코드
- `approvals.json`(없음)
- `test/sandbox/generated/s7_seoulpilot/`(생성되지 않음)

---

## 2. Sandbox 게이트 보완 결과

### 2.1 동작
| 경로 | 일반 모드 | 역사 모드, 승인 전 | 역사 모드, 승인 후 |
|---|---|---|---|
| `generate_season --target sandbox` (쓰기) | 이전과 같음 | **거부**: `[history_blocked] …`, `nothing written`, exit 1 | 생성. `<seasonId>_history.g.dart`(REAL HISTORY / IN THIS MYSTERY) 포함 |
| `--target sandbox --check` | 이전과 같음 | 인메모리 생성·비교만 한다. `note history: N approvals missing …`, `blocked … checked only` 출력. 파일을 쓰지 않음 | 비교 |
| `--target game` (쓰기·check) | 이전과 같음 | 거부(기존 그대로) | 생성 |
| `plan_season check` 인메모리 생성기 | 이전과 같음 | `staticOnly`: 계획 검사는 계속 동작하고, 결과는 쓸 수 없음으로 표시 | 같음 |
| 코드에서 `CaseGenerator.sandbox(...)` | 이전과 같음 | 기본은 거부. `staticOnly: true`면 `writable: false`. 이 결과를 `makeAndWrite`에 넘겨도 쓰지 않음(exit 1) | 생성 |

### 2.2 검증
- 신규 테스트(Rome 사본을 역사 모드로 바꾼 픽스처):
  - 승인 전 sandbox 생성은 거부된다.
  - `staticOnly` 결과는 쓸 수 없고 reveal 파일이 없다. `makeAndWrite` → 1, 출력 폴더가 생기지 않는다.
  - 사실을 승인한 뒤에도 퍼즐 검토가 없으면 거부된다.
  - 모두 승인하면 생성되고 쓰기에 성공한다(`_history.g.dart` 포함, 게임용 `_content`·`_art`는 없음).
- 일반 시즌: `staticOnly`와 관계없이 바이트가 같고, 쓸 수 있으며, history 파일이 없다.
- 시범 Case 실제 CLI:
  - `generate_season --target sandbox` → 에러 15줄, `nothing written`
  - `--check` → `blocked … checked only`
  - `test/sandbox/generated/s7_seoulpilot` 없음
- 유료 API 호출 없음(생성기는 API를 부르지 않는다).

### 2.3 함께 고친 규칙: `history_case_missing`
- 원래 규칙은 시즌에 계획된 12개 Case 모두에 dossier 항목을 요구했다. 작성되지 않은 Case도 포함이다.
- 그래서 1 Case 시범은 **승인을 모두 받아도 영원히 생성할 수 없었다.**
- 이제 "작성된 Case에는 반드시 항목이 있어야 한다"로 바꿨다.
- 생성기는 작성된 Case만 만든다. 게임 대상은 12 Case가 모두 작성되어야 한다(`game_cases_missing`, 변경 없음). 그래서 생성될 수 있는 Case에 대한 요구는 그대로다.
- 테스트: 작성된 Case의 항목을 지우면 오류가 난다. 그 Case 계획까지 지우면 요구하지 않는다.

---

## 3. 단일 Case 실행 경로

**설계:**
- `test/sandbox/single_case.dart`. 테스트 코드라 앱 빌드에 들어가지 않는다.
- `SingleCase(season, caseId)`:
  - 생성된 시즌에서 **그 Case 하나만** 앱에 넣는다(`allEpisodesProvider`에 그 Case만 추가). 그래서 시즌의 첫 Case가 되어 열린다.
  - 지도는 Paris 지도를 빌린다(기존 샌드박스와 같은 최소 진입).
  - 저장소는 테스트용 mock SharedPreferences다.
  - `SeasonCatalog.testSeasons/testPlaces`(기존 테스트 장치)로 장면 테이블, 학습, History Reveal을 게임과 같은 방식으로 찾는다.
- `CasePlayer`: 각 미션을 그 엔진의 실제 조작으로 푼다.
  - 엔진: 타임라인 카드·슬롯·제외 더미, 두 기록의 탭·줄·확인, 흔적 메모와 장소 선택, 돋보기 라벨, 대화의 증거 제시, 기본 질문(SandboxPlay)
  - 이동 흐름: 지도 → 장소 → 퍼즐 → Discovery → 장면 → 지도, 그리고 Final

**재사용한 것:** 실제 `WorldMysteryApp`, `GameController`, Mission·퍼즐 위젯, `SeasonContent`, 해금·저장 로직. 게임 코드는 바꾸지 않았다.

**기존 데이터에 영향 없음:** `SeasonCatalog.all`에 들어가지 않는다(테스트로 확인). 테스트가 끝나면 등록을 해제한다.

**승인 전 실행 불가:**
- 시범 콘텐츠는 생성기에서만 나오고, 생성기는 승인 전 생성을 거부한다(§2).
- 시범 Case를 플레이하는 테스트 파일은 생성된 파일을 import해야 하므로 **승인 후에 추가한다**(§8). 지금 추가하면 컴파일이 실패한다.

**검증:** 역사 내용이 없는 기존 샌드박스 s8의 Case 2개를 각각 **단독으로**, 실제 앱에서 Final 해결까지 플레이했다.
- s8_ep01: 객관식(오답 후 정답) → 타임라인 → 단어 입력 → 글자 타일 Final
- s8_ep02: 기록 대조(오답 쌍 후 정답) → 키패드 → 흔적 → 돋보기 → 증거 대화 Final
- 두 Case 모두에서 확인한 것: 첫 정답에 보상 지급 → 앱 재실행 후 진행 복구 → 같은 답 재제출 시 코인 0 → 예외 없음
- 시범 Case에 필요한 4개 엔진(타임라인, 기록, 흔적, 증거 대화)이 모두 이 경로로 동작함을 확인했다.

---

## 4. M2 UI 개선 결과

| 항목 | 이전 | 지금 |
|---|---|---|
| 자음 설명 | 종이 값 "MOUTH, THROAT" | **편지(설명 영역, 일반 글 크기)**: "Five main consonant letters copy the shapes we make to speak. / They show the tongue, the mouth, the teeth and the throat." 모음 셋, 왕의 뜻, 열흘(h6)도 편지에 쓴다 |
| 종이(정답 선택 영역) | 6줄 | **4줄**: LETTERS 28 / DOT THE SKY / FLAT THE EARTH / WHY EASY TO LEARN ↔ SCHOLARS ONLY |
| 줄 터치 영역 (320×568) | 35.6–38.2 | **50.1–53.7** (44 이상 단언, 48도 넘음) |
| 값 글자 높이 (×1.0) | 8.8–10.9 px | **12.1–12.4 px** (11 이상 단언) |
| 큰 글자 ×1.6 | — | 12.2–13.8 px, 겹침·예외 없음 |
| 방법 | — | 줄 간격 확대(5칸), 터치 여유 48, 크롭을 종이에 맞춤(820→720px, 그림 약 14% 확대), 값 열 548→600 |

- 세 난이도는 같은 사실을 쓴다. 숫자(28, ten)와 고유명사가 같고(레벨 검사 통과), 종이 값은 레벨이 바꿀 수 없다.
- 측정은 기록 엔진의 `RecordPaper`를 단독으로 그려서 했다. 실제 미션 화면의 여백·확대는 시범 플레이(승인 후)에서 확인한다.

---

## 5. 스토리 수정 내용

| 이전 | 지금 |
|---|---|
| 해가 뜨면 Mun-su가 궁궐 일꾼들에게 왕실 글을 **읽어 준다**(공개 낭독) | 해가 뜨면 Mun-su가 왕실 글을 **궁궐 학자들에게 전달**해야 한다. 전달 전에 글이 사라진다 |
| 끝 장면: 일꾼들 앞 낭독 | 끝 장면: "Before Mun-su delivers the royal letter, Sora reads its first line with him." |
| M1 "The palace scholars have finished their book" (h7 주장) | "The book of the new letters is finished." (h2. 누가 썼는지 말하지 않음 → h7 미사용) |

- 왕비 상중: 1446년 봄 왕비 승하는 출처가 1개(실록 기사 목록)뿐이어서 **게임에서 언급하지 않는다.**
- 상중과 어긋날 수 있는 축하·공개 행사는 없앴다. 궁중 의례를 새로 만들어 사실처럼 설명하지 않는다.
- dossier `fiction`에 "No palace ceremony is shown or claimed."를 적었다.
- 왕실 글의 존재, 전달 일정, 수신인은 모두 창작으로 선언되어 있다.

**M3 임시 그림:**
- 런던 탑 그림을 파리 Case 05의 작업실(`workshop_interior.webp`)로 바꿨다.
- 장소 선택지를 **그림에 실제로 그려진 물건**으로 바꿨다: (a) 작업대 서랍, (b) 책상 밑 작은 상자 = 정답, (c) 열린 나무 궤짝. 흔적 문장도 맞췄다: 깔개 위 잉크, 뚜껑에 낀 붓털, 같은 상자에서 삐져나온 종이 모서리.
- 좌표는 이 파일에 직접 측정했다(`measuredOn` = 이 파일의 sha256). 영역을 그림 위에 그려 눈으로 확인했다. 선택 영역 3곳은 각 물건 위에 있고, 흔적 3곳은 상자 주변이며, 안내점은 빈 바닥이다.
- 흔적 자체(잉크, 붓털, 종이)는 그림에 **그려져 있지 않다.** 영역만 있다(계획 노트에 명시).
- 모든 그림은 테스트용이다. 시즌 계획, Case 계획, 각 퍼즐 노트, 화면 라벨("… (test picture)")에 표시했다. 정식 서울 그림은 만들지 않았다.
- 증거와 Final도 "brush box"에서 "chest"로 통일했다.

---

## 6. 역사 자료별 승인 준비 상태

**확인 방식:**
- **A** = 원문 사료 본문을 직접 열어 대조. 조선왕조실록 국역과 한문 인쇄본.
- **B** = 기관 페이지 본문을 도구로 열어, 인용 문장이 본문에 있는지 확인. 2026-11-04, 이번에 모두 다시 열었다.
- **C** = 검색 결과의 발췌만 봄. dossier 출처로 쓰지 않는다.

| 사실 | 게임 속 사용 위치 | 출처 (확인 방식) | 충돌·이본 | 게이트가 승인을 요구? |
|---|---|---|---|---|
| h1 28자 창제 1443 | M2 편지·종이 "28", reveal 1 | 실록 1443(A), UNESCO(B), 국립한글박물관 전시(B) | 날짜 없음 → 연도만 | 예 |
| h2 책 완성 1446 | M1 첫 줄 "Autumn, 1446 … finished", reveal 2 | 실록 1446(A), UNESCO(B), kmowkc(B) | 29일 vs 상순 → 연도만. kmowkc는 강희안을 "집현전 학사"로 적음(실록과 다름, h7 참조) | 예 |
| h3 자음 기본자 = 발음 기관 | M2 편지 2줄 | 우리역사넷 제자해(B: 국역과 한문 원문 모두 본문에 있음), 백과 28자모(B) | 실록 1443 "倣古篆" vs 해례 상형. ㄱ의 현대 설명 차이. 우리역사넷 국역은 ㅇ을 생략했고 한문 원문 「喉音ㅇ象喉形」에는 있음. 박물관 웹진은 기본자를 "ㄱㄴㄷㅅㅇ"로 잘못 적어 h3 출처에서 뺌 | 예 |
| h4 ㆍ하늘·ㅡ땅·ㅣ사람 | M2 편지·종이(DOT/FLAT), M3 장면(Sora 연습지), reveal 2 | 우리역사넷(B), 백과 초출자(B), 박물관 웹진(B) | 없음 | 예 |
| h5 서문: 쉽게 익혀 날마다 | M2 편지·종이 "EASY TO LEARN", reveal 3 | 실록 1446 한문(A) 「欲使人(昜)〔易〕習, 便於日用耳」, 박물관 전시(B) | 실록 `人` 하나 vs 해례본 인용 `人人` → "people" | 예 |
| h6 아침나절 / 열흘 | **M2 편지** "The book says a slow person can learn them in ten days." (이번에 M2 퍼즐 factIds에 추가해 게이트 대상으로 만듦). M3 Sora 대사 "ten days"(창작 인물의 경험) | 실록 1446 한문(A) 「智者不崇朝而會, 愚者可浹旬而學」, 박물관 전시(B) | 실록 不崇朝 vs 해례본 인용 不終朝(뜻 같음). 愚者 → "a slow person"(순화). **게임 주장의 범위: "책이 그렇게 말한다"이지 "실제로 열흘이면 배운다"가 아님** | 예 |
| h7 해례는 궁궐 학자들이 씀 | **사용 안 함**(M1에서 문구 삭제) | 실록(A), UNESCO(B) | 강희안 소속 | 아니오(승인 선택) |
| h8 승정원 = 왕명 출납 | M1 둘째 줄, reveal 4 | 백과 승정원(B), 승정원일기 소개(B) | 설치 연도 서술 차이 | 예 |

**C(검색 발췌만)로 남은 자료:** 우리역사넷 영상 책 이야기(h6의 세 번째 출처, 보조), 국편 한국사 DB(승정원 위치 = 월화문 밖), 1446년 4월 실록 기사 목록(왕비 상중). 모두 승인 근거로 쓰지 않는다.

**승인 해시와 수정 문구의 관계:**
- `approve.dart status` 결과 승인 기록은 **0건**이고 모두 `draft`다. 이번 수정으로 무효가 된 승인은 없다.
- 앞으로의 규칙(기존 구현):
  - 사실 승인은 사실 객체(문장, 출처, 충돌)를 해시한다.
  - 퍼즐 승인은 퍼즐 항목 + 미션 JSON + 그 Case의 `levels.json` + 인용 사실을 해시한다.
  - reveal 승인은 reveal과 인용 사실을 해시한다.
  - 따라서 승인 뒤 M2 편지 한 줄, 레벨 문장 하나만 바뀌어도 해당 퍼즐 승인은 `stale`이 된다.

**승인 대상 목록** (사람이 터미널에서 직접 실행. Claude는 실행하지 않았다)
1. 사실 7건: h1, h2, h3, h4, h5, h6, h8
   - 출처를 확인한다.
   - dossier의 `status`를 `source_checked`로 바꾼다.
   - `dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h<n>`
   - h7은 선택이다.
2. 퍼즐 검토 4건: `… approve test/sandbox/plans/s7_seoulpilot puzzle s7_ep01_m1` / `_m2` / `_m3` / `_final`
3. reveal 1건: `… approve test/sandbox/plans/s7_seoulpilot reveal s7_ep01`

현재 게이트 차단: 유료 단계 **10건**, 게임·sandbox 생성 **15건**. 모두 위 승인 항목이며, 계획 오류는 0건이다.

---

## 7. 테스트 결과

| 검사 | 결과 |
|---|---|
| `flutter analyze` | No issues found |
| `validate_plan` (시범) | 0 errors, 0 warnings |
| `case_levels check` (시범, 3레벨) | every level written, the same game |
| `plan_season check --all` (시범) | Case 오류 0건. 남은 오류는 시범 시즌 구조뿐: prologue, bible, manifest, case_missing ×11. `history_case_missing`은 사라졌다(§2.3). 경고 1건: M2 matchPairs의 오답 문구는 엔진 기본값 |
| 자동 선택기 | 4/4가 기획과 일치. M1 timeline_board, M2 record_mismatch, M3 trace_deduction, Final evidence_talk. 정답·플레이, 레벨 모두 pass. M2에 "chronology"(1443, before)가 함께 잡히지만 사실 문장에서만 나온 것(`factsOnly`)이라 선택에 쓰이지 않는다 |
| sandbox 게이트 테스트 (`history_dossier_test`) | 신규 3개 포함 해당 파일 전부 통과 |
| 단일 Case 경로 (`single_case_test`) | 3/3 통과 |
| 시범 게이트 (`s7_pilot_gate_test`) | 4/4 통과: 승인 전 차단, 쓸 수 없음, 생성물 없음 |
| M2 작은 화면·큰 글자·터치 (`s7_pilot_records_layout_test`) | 4/4 통과 |
| 회귀 묶음 (STEP 1 묶음 전체 + 신규) | **+898, 모두 통과**, 3분 42초. 898 = 이전 888 + 신규 10 |
| Rome·New York `--target game --check` | 각 30 files + registry 3 up to date |
| 샌드박스 s8·s9 `--check` | up to date |
| 전체 `flutter test`, Release 빌드 | 실행하지 않음(요청대로) |
| 시범 Case 실제 플레이 | **실행하지 않음**: 승인 전이라 생성 차단 |

---

## 8. 승인 후 실제 플레이까지 남은 작업

1. 사람의 승인(§6 목록): 사실 7건 → 퍼즐 4건 → reveal 1건. 순서는 approve.dart가 강제한다. 퍼즐 승인은 사실 승인 후에만 가능하다.
2. 생성: `dart run tool/season_gen/generate_season.dart --season test/sandbox/plans/s7_seoulpilot/season.plan.json --target sandbox`
   - `test/sandbox/generated/s7_seoulpilot/`에 생성된다. 게이트 테스트는 자동으로 "승인 후" 분기로 바뀌어 생성물이 최신인지 검사한다.
3. 시범 플레이 테스트 추가(`test/sandbox/s7_pilot_play_test.dart`, 약 40줄):
   - 생성된 테이블로 `SeasonContent`를 만든다(`historyReveals` 포함).
   - `SingleCase(season, 's7_ep01')`와 `CasePlayer`로 M1 → M2 → M3 → Final을 플레이한다.
   - 확인할 것:
     - Case Closed의 REAL HISTORY / IN THIS MYSTERY 구분과 SOURCES
     - 오답·힌트
     - 재실행 복구, 보상 1회
     - 320×568, 큰 글자, 접근성 라벨
4. 실기기 확인은 선택이다. 테스트 전용 경로라 앱 빌드에는 들어가지 않는다. 실기기에서 보려면 별도의 개발 전용 진입이 필요하고, 그건 이번 범위 밖이다.

**남은 위험:**
- 임시 그림:
  - 기록 종이가 클립보드라 시대에 맞지 않는다.
  - 승정원·궁궐 마당 장소 그림은 대역이라 그 장면을 보여 주지 않는다.
  - M3 흔적은 그림에 그려져 있지 않다.
  - 정식 그림이 생기면 좌표를 다시 측정해야 한다.
- 단일 Case 경로의 Paris 지도 대여: 지도 핀 위치는 계획의 mapX/Y를 따르고, 지도 그림은 파리다(테스트 전용).
