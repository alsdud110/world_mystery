# Seoul Pilot Case 01 — 구현 보고서

작성일 2026-11-04

**결론:** Case 01 "The Missing Royal Letter"의 계획 데이터는 정적 검증을 모두 통과했다. 그러나 **역사 승인 게이트에서 의도대로 멈췄다.**
- 역사 사실 8개는 모두 `draft`다. 퍼즐 4개와 reveal은 사람의 검토를 받지 않았다.
- 그래서 게임 콘텐츠를 생성하지 않았고, **실제 앱 플레이 테스트도 하지 않았다.**
- 게이트를 우회하지 않았고, 승인 기록을 만들지 않았다.
- 유료 API 호출, 커밋은 없다.

---

## 0. 설계 문서와 현재 구현의 차이 (작업 전에 확인)

| # | 차이 | 처리 |
|---|---|---|
| D1 | **생성기의 `sandbox` 대상은 HistoryGate를 거치지 않는다.** [generate_case.dart:401](../tool/season_gen/generate_case.dart#L401)에서 게이트는 `target == 'game'`일 때만 실행된다. 역사 모드 시즌도 `--target sandbox`로는 승인 없이 `.g.dart`가 생성된다(`--check`로 확인함: "sandbox content only" 안내만 나오고 차단되지 않음). | 이 경로로 플레이 가능한 콘텐츠를 만들면 승인 우회가 된다고 판단해 **쓰지 않았다.** 막을지는 사용자 결정 항목이다(§10). |
| D2 | 게임 대상 생성은 시즌 단위다. 12 Case 전부, 지도, 프롤로그가 필요하다(`game_cases_missing`, `game_map_missing`, `game_prologue_missing`). | 1 Case 시범은 역사 승인과 무관하게 앱 생성이 불가능하다. 정식 서울 시즌 없이 앱에서 플레이하려면 시범용 생성 경로가 따로 필요하다(§9). |
| D3 | 시즌 계획의 막은 3개, 막마다 Case 4개로 고정이다(`casesPerAct`, `plannedCases` 12). Dossier에는 시즌의 모든 Case 항목이 필요하다. | 시범 시즌은 12 Case를 선언하고 Case 01만 작성했다. 그래서 `case_missing` ×11, `history_case_missing` ×11이 **구조적으로** 나온다. 아래 결과에서는 따로 셌다. |
| D4 | 미션 하나는 증거를 **하나만** 준다(`clueOutputs.evidence`). | Final의 세 증거를 M1·M2·M3에 하나씩 배치했다(§4). |
| D5 | 기획서의 Final 증거(장부, 학자 쪽지, Sora 연습지)는 사용자 요구(기회, 지식, 물증)와 맞지 않았다. | 기회 = 출입 장부, 지식 = 새 글자로 쓰고 Bae의 잎 표시가 있는 가짜 종이, 물증 = Bae의 이름이 수놓인 붓 보자기에 싸인 진짜 글. Sora 연습지는 M3 반전 장면으로 옮겼다. |
| D6 | 기획서의 M2 값이 길었다(예: "TONGUE, MOUTH, TEETH, THROAT"). | 320 폭에서 3.5px로 그려지는 것을 측정하고 13자 이하로 줄였다(§7). |
| D7 | 사실 ID | 기획서의 `s5_ep01_h*` 대신 시범 시즌 ID를 따라 `s7_ep01_h*`로 했다. 정식 시즌 `s5_seoul`은 만들지 않았다. |

---

## 1. 변경 파일

모두 **새 파일**이다. 기존 파일은 수정하지 않았다.

| 파일 | 내용 |
|---|---|
| `test/sandbox/plans/s7_seoulpilot/season.plan.json` | 테스트 전용 시범 시즌. 12 Case를 선언하고 Case 01만 작성했다. 장소 그림 3장은 **임시**(Paris·London). |
| `test/sandbox/plans/s7_seoulpilot/planning/brief.json` | `mode: historical_fiction_mystery` |
| `test/sandbox/plans/s7_seoulpilot/planning/history_dossier.json` | 사실 h1–h8(모두 `draft`), fiction 3줄, 퍼즐 4개(근거·유일성), reveal 3레벨 |
| `test/sandbox/plans/s7_seoulpilot/cases/s7_ep01/case.plan.json` | M1 `timeline_board`, M2 `record_mismatch`, M3 `trace_deduction`, Final `evidence_talk` |
| `test/sandbox/plans/s7_seoulpilot/cases/s7_ep01/levels.json` | 161줄 전체의 JUNIOR·MASTER |
| `test/sandbox/plans/s7_seoulpilot/planning/{quality_report,puzzle_selection}.json` | `plan_season check`가 쓴 보고서 |
| `test/sandbox/s7_pilot_records_layout_test.dart` | M2의 두 종이를 기록 엔진의 `RecordPaper`로 320×568, 글자 ×1.0/×1.6에서 측정하는 테스트(4개) |
| `docs/SEOUL_PILOT_CASE01_IMPLEMENTATION_REPORT.md` | 이 보고서 |

만들지 않은 것:
- `lib/`, `assets/`, `content_pipeline/`, `pubspec.yaml`, 생성 코드(`*.g.dart`)
- `approvals.json`

---

## 2. 역사 자료 검증 결과

2026-11-04에 원문을 다시 대조했다.
- **직접 연 페이지:** 조선왕조실록 원문(국역·한문 인쇄본 2건, 1444년 기사), 『세종실록』 1446년 9월 29일 한문 원문
- **검색 도구가 본문을 추출해 읽은 페이지:** 백과사전, 우리역사넷, 국립한글박물관, UNESCO, kmowkc. 사람이 원문 페이지에서 다시 확인해야 한다(§3 체크 항목).

### 2.1 세종 서문 원문과 영어

| 항목 | 원문 (『세종실록』 113권 세종 28년 9월 29일, 한문) | 게임 영어 | 판단 |
|---|---|---|---|
| 창제 목적 | 「予爲此憫然, 新制二十八字, 欲使人(昜)〔易〕習, 便於日用耳。」 | "EASY TO LEARN" (M2 기록), "so people could learn them easily and use them every day" (reveal) | 뜻이 맞다. **이본 차이**: 실록은 `欲使人易習`(人 하나, 昜→易 교감), 해례본은 흔히 `人人`(사람마다)으로 인용된다. 영어 "people"은 양쪽에 맞는다. "everyone"이나 "all people"은 해례본 쪽 표현이라 쓰지 않았다. |
| 아침나절·열흘 (정인지 서문) | 「故智者不崇朝而會, 愚者可浹旬而學。」 | "A wise person: one morning. A slow person: ten days." | 뜻이 맞다. 실록은 `不崇朝`, 해례본 인용은 흔히 `不終朝`(뜻 같음). `愚者`(어리석은 사람)는 아동용으로 "a slow person"으로 순화했다. |
| 완성 | 「是月, 訓民正音成。」 | "The book … was finished in 1446." | 맞다. 날짜(29일 기사 vs 서문 "9월 상순")가 달라 연도만 쓴다. |
| 해례 작성자 | 「集賢殿應敎崔恒、副校理朴彭年ㆍ申叔舟、修撰成三問、敦寧注簿姜希顔、行集賢殿副修撰李塏ㆍ李善老等謹作諸解及例」 | "the palace scholars" | 강희안은 돈녕부 주부라 "집현전 학자 8명"은 부정확하다. → 이름·인원수를 쓰지 않는다. |

### 2.2 궁궐 위치를 특정할 근거
- 국사편찬위원회 『한국사』 총설 DB는 조선 전기 승정원이 "경복궁 근정전의 서남쪽 月華門 밖"에 있었다고 적는다. **출처 1곳**이고, 1446년 당시를 특정한 서술이 아니다.
- 1446년 가을 세종이 어느 궁에 머물렀는지는 **확인하지 못했다.** 『세종실록』 세종 28년 4월 3일 기사 목록에는 빈전 진향과 왕비 장사 논의가 있다. 그해 봄 왕비가 세상을 떠났음을 보여 준다(출처 1곳, 승하 날짜는 확인하지 않음).
- 결론: "경복궁"으로 특정할 근거가 부족하다. 게임은 **"the palace"**, 장소 표시는 "THE PALACE, HANYANG"으로 둔다.
- 추가로 확인할 것: 1446년 가을이 왕비 상중이었다는 점이 "궁궐 일꾼에게 글을 읽어 주는" 창작 장면과 어울리는지 사람이 판단할 것.

### 2.3 출처 간 충돌 요약
| 사실 | 충돌 | 처리 |
|---|---|---|
| h2 | 9월 29일 기사 vs 9월 상순 | 연도만 사용 (`resolved`) |
| h3 | 실록 1443 "옛 전자를 모방(倣古篆)" vs 해례 "발음 기관을 본뜸", ㄱ의 현대 설명 차이 | "the book says"의 요약만 사용. M2 종이 칸이 좁아 "MOUTH, THROAT"로 줄였다. 혀·이는 입에 속하므로 줄였는데, **이 단순화가 공정한지 사람이 판단할 것** (`resolved`, 메모 있음) |
| h5 | 人 vs 人人 | "people" (`resolved`) |
| h6 | 崇朝 vs 終朝, 愚者 순화 | (`resolved`) |
| h7 | 강희안 소속 | 이름·인원수 미사용 (`resolved`) |
| h8 | 설치 연도 서술 차이 | 세종대에는 존재 (`resolved`) |
| (선택) 1444 상소 | 진의 해석이 갈림 | dossier에 넣지 않았다 |

---

## 3. 사실별 승인 대기 목록

모두 `status: draft`다. 승인 기록은 0건이다. 사람이 할 일은 다음 순서다.
1. 출처를 연다.
2. dossier의 `status`를 `source_checked`로 바꾼다.
3. 터미널에서 직접 `dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact <id>`를 실행한다.

| ID | 사실 (요약) | 쓰이는 곳 | 출처 (서로 다른 기관) | 사람이 확인할 것 |
|---|---|---|---|---|
| s7_ep01_h1 | 1443년 세종이 28자를 만들어 훈민정음이라 함 | M2 퍼즐, reveal 1 | 실록(국편), UNESCO, 국립한글박물관 | UNESCO·박물관 원문 |
| s7_ep01_h2 | 1446년 9월 책 완성 | reveal 2 | 실록, UNESCO, kmowkc | 날짜 처리 |
| s7_ep01_h3 | 기본 자음은 발음 기관 모양 | M2 퍼즐 | 우리역사넷(국편), 백과(한중연) | "MOUTH, THROAT" 단순화가 공정한가 |
| s7_ep01_h4 | ㆍ하늘·ㅡ땅·ㅣ사람 | M2 퍼즐, reveal 2 | 우리역사넷, 백과, 국립한글박물관 | — |
| s7_ep01_h5 | 서문: 쉽게 익혀 날마다 편히 쓰게 | M2 퍼즐(정답 줄), reveal 3 | 실록, 국립한글박물관 | 人/人人 이본 처리 |
| s7_ep01_h6 | 아침나절/열흘 | (M2 쪽지 메모·M3 대사, 퍼즐 근거 아님) | 실록, 국립한글박물관 | "slow person" 순화 |
| s7_ep01_h7 | 해례는 궁궐 학자들이 씀 | (배경만, 퍼즐·reveal 미사용) | 실록, UNESCO | 승인 생략 가능 |
| s7_ep01_h8 | 승정원은 왕명 출납 관청 | reveal 4 (M1 이야기에도 등장) | 백과(한중연), 승정원일기(국편) | — |

게이트가 승인을 요구하는 사실: **h1, h2, h3, h4, h5, h8** (퍼즐이나 REAL HISTORY에 쓰임). h6·h7은 근거로 쓰이지 않아 게이트에 걸리지 않는다.

그다음 승인할 것:
- 퍼즐 검토 4건: `approve … puzzle s7_ep01_m1 | s7_ep01_m2 | s7_ep01_m3 | s7_ep01_final`
- reveal 1건: `approve … reveal s7_ep01`

---

## 4. Case 01 스토리와 퍼즐 구현 상태

배경: 1446년 가을, 한양의 궁궐. 등장인물은 모두 창작이다(Mun-su, Taek, Sora, Bae). 세종은 "the King"으로만 언급하고, 대사·행동이 없다. 고정 주인공은 없다: 대화의 화자는 기존 플레이어인 `detective`다.

| 단계 | 퍼즐 | 플레이 | 얻는 증거 | 근거 |
|---|---|---|---|---|
| M1 The Gate Book | `timeline_board` | 출입 장부의 then/later/after로 SUNSET–DAWN 사이 3장을 놓고 LUNCH를 뺀다. 정답 `lock,home,cups,brush,dawn`. 끝 장면에서 Taek가 "Bae는 베끼는 종이마다 작은 잎을 그린다"고 말한다. | e1 **The Gate Book** (기회) | fiction |
| M2 Two Papers | `record_mismatch` | 학자 쪽지와 상자 속 종이 6행을 비교한다. WHY만 다르다: EASY TO LEARN vs SCHOLARS ONLY. 정답 `why:why`. 종이 하단에 작은 잎이 있다. | e2 **The False Page** (지식: 새 글자로 썼고 Bae의 잎이 있음) | h1, h3, h4, h5 |
| M3 Ink in the Copy Room | `trace_deduction` | 잉크·붓털·찢긴 종이 모서리가 가리키는 곳 = Bae의 붓함(b). 오답은 찻쟁반(a), 종이 궤(c). 끝 장면은 반전 1: Sora의 종이는 열흘 동안 익힌 연습지다. | e3 **The Wrapped Letter** (물증: BAE가 수놓인 붓 보자기) | fiction |
| Final The Copyist Answers | `evidence_talk` | Bae의 세 주장에 증거를 하나씩 보여 준다. "해 지기 전에 갔다" → e1, "새 글자를 못 쓴다" → e2, "누구나 내 상자에 넣을 수 있다" → e3. 순서대로 열린다(`requires`). | — | fiction |

- **새 글자를 배웠다는 것만으로 범인을 정하지 않는다.** Sora도 새 글자를 배웠지만 범인이 아니다. 세 증거가 모두 있어야 Final이 끝난다(`finishWhen`).
- 반전 2(끝 장면): Bae도 새 글자를 배웠다. "Seven days."
- 각 증거를 제시할 때 다른 카드 1장이 함께 나온다(`offered`). 틀린 카드는 오답으로 처리되지 않는다(엔진 규칙).

---

## 5. 실제 플레이 가능 여부

**불가능하다. 실제 앱 플레이 테스트는 하지 않았다.**

| 원인 | 내용 |
|---|---|
| 역사 승인 | `HistoryGate.blockers(game: true)` = 14건(§6) |
| 시즌 구조 | 게임 생성은 12 Case, 지도, 프롤로그를 요구한다(D2). 승인 후에도 1 Case 시범은 지금 경로로는 앱에 들어갈 수 없다. |
| 그림 | 모든 그림이 임시다(Paris·London). 정식 서울 그림은 승인 후에만 만들 수 있다. |

생성기 코드 자체는 `--target sandbox --check`(비교만, 쓰기 없음)로 실행했다. 오류 없이 6개 파일을 만들 수 있는 상태다. **파일은 쓰지 않았다.**

---

## 6. 승인 때문에 차단된 단계

| 단계 | 상태 | 근거 |
|---|---|---|
| 계획 작성 (시즌, Case, dossier, levels) | ✅ 완료 | — |
| 정적 검증 (스키마, 구조, 단서, PlayCheck, 레벨, dossier, 선택기) | ✅ 통과 | §7 |
| 유료 에셋 단계 (이미지, 사운드) | ⛔ 차단 | `blockers(game: false)` 9건: 퍼즐 M2와 REAL HISTORY가 쓰는 h1·h2·h3·h4·h5·h8 미승인 |
| 게임 콘텐츠 생성 | ⛔ 차단 | `blockers(game: true)` 14건 = 위 9건 + 퍼즐 검토 4건(`history_puzzle_unreviewed`) + reveal 미승인 1건. 실제 명령 `generate_season --target game --check`도 거부(D2 사유, nothing written) |
| 앱 플레이 테스트 | ⛔ 미실행 | 생성 차단 |

(별도: 미작성 Case 11개의 `history_case_missing` 11건은 시범 시즌 구조에서 생기는 것으로, 위 숫자에서 뺐다.)

---

## 7. 테스트 결과

### 7.1 정적 검증 (실행함)
| 검사 | 결과 |
|---|---|
| `validate_plan.dart` (스키마·구조·단서 그래프) | 0 errors, 0 warnings |
| `case_levels.dart check` (3레벨, PlayCheck 레벨별 재실행) | "every level written, the same game" |
| `plan_season check --all` | Case 오류 0건. 남은 오류는 시즌 구조뿐이다: `prologue_missing`, `bible_missing`, `asset_manifest_missing`, `case_missing` ×11, `history_case_missing` ×11. 경고 1건: M2 `feedback_missing`(matchPairs는 `orderFeedback`을 허용하지 않아 엔진 기본 문구 사용). Dossier 오류 0건(연도, 단서 노출 3레벨, 유일성, 레벨 문장 모두 통과). |
| 퍼즐 자동 선택기 (`planning/puzzle_selection.json`) | 아래 표 |

| 미션 | 감지 성격 (단서) | 선택기 | 기획 | 일치 | 정답·플레이 | 레벨 |
|---|---|---|---|---|---|---|
| M1 | chronology (1446, after, later, then) | timeline_board 10 > order_sequence 7 | timeline_board | ✅ | pass | pass |
| M2 | documents (copy, does not match) | record_mismatch 10 > text_choice 5 | record_mismatch | ✅ | pass | pass |
| M3 | scene (hidden, marks) | trace_deduction 10 > dark_room_search 7 > scene_explore 4 | trace_deduction | ✅ | pass | pass |
| Final | testimony (claim, claims, says) | evidence_talk 10 | evidence_talk | ✅ | pass | pass |

선택기는 Rookie 글만 본다. 미션 유형은 사용자가 확정한 대로 두었다.

### 7.2 신규 테스트: M2 6줄 문서, 320×568
`test/sandbox/s7_pilot_records_layout_test.dart`: 4개 통과.
- 앱 플레이가 아니라 **엔진 `RecordPaper` 단독 측정**이다.
- 실제 미션 화면의 여백·확대 동작은 반영되지 않았다.

| 항목 | 결과 |
|---|---|
| 6줄 모두 화면 안, 겹침 없음, 예외 없음 (×1.0, ×1.6) | ✅ |
| 종이 크기 | 288×319.6 |
| 줄 터치 영역 높이 | **35.6–38.2 px** — 권장 44–48 미만 |
| 값 글자 높이 (수정 전) | "TONGUE, MOUTH, TEETH, THROAT" **3.5 px**, "EASY TO LEARN, FOR DAILY USE" 3.8 px → 읽을 수 없음 |
| 값 글자 높이 (수정 후, ×1.0) | 8.8–10.9 px. 이 종이에서 짧은 값의 상한("28" = 10.9)과 같다. 기존 콘텐츠와 같은 수준이다. |
| 큰 글자 ×1.6 | 짧은 값만 10.9→12.2 px로 조금 커진다. 종이 속 글은 시스템 글자 크기를 거의 따르지 않는다(엔진 방식, 기존 Paris도 같음). |

### 7.3 회귀 (실행함)
- `flutter analyze`: **No issues found**
- STEP 1 회귀 묶음 전체: `test/season_gen`, `test/season_planner`, `test/season_factory`, `test/sandbox` 전체, `test/puzzles_v2` + 개별 파일 14개(`timeline_board`, `puzzle_palette`, `puzzle_engine_collisions`, `difficulty_content`, `generated_seasons`, `full_playthrough`, `season_playthrough`, `back_navigation`, `history_reveal_ui`, `answer_checker`, `case01_deduction`, `case01_inspect`, `paris_case03`, `case_talk`)
  - 결과: **+888, 모두 통과**, 3분 32초
  - 888 = STEP 1의 884 + 신규 4
  - STEP 1 때 마지막에 묶음 전체를 다시 돌리지 못했던 것을 이번에 전체 실행으로 마쳤다.
- 전체 `flutter test`, Release 빌드: **실행하지 않음**(요청대로).

### 7.4 실행하지 않은 UI 검증 (생성 차단으로 불가)
Story Intro → M1–M3 → Final → Case Closed, 기존 프로필 적용, 뒤로가기·재진입, 앱 재실행 복구, 힌트·오답·정답 처리, 보상 중복 방지, History Reveal 구분 표시, 접근성 라벨(종이 줄의 `label: value` 시맨틱은 엔진 코드로 확인), 큰 글자의 미션 전체 화면.

---

## 8. 기존 시즌 영향
- 기존 파일 수정 없음(§1). `lib/`, `assets/`, `content_pipeline/`의 git 변경은 이번 작업 전부터 있던 것이다.
- Rome·New York: `generate_season --target game --check` → 각 30 files + registry 3 files **up to date**.
- 샌드박스 s8·s9: `--check` up to date.
- Season 1·2(손으로 쓴 콘텐츠): 관련 파일 미변경. `full_playthrough`(London), `paris_case03`이 회귀 묶음에서 통과했다.
- 저장·보상·난이도 정책 코드 미변경.

---

## 9. 남은 문제
1. **D1 샌드박스 경로의 게이트 공백.** 역사 모드 시즌을 `--target sandbox`로 생성하면 승인 없이 테스트용 콘텐츠가 만들어진다. 앱에는 들어가지 않지만, "승인 전에는 역사 콘텐츠를 만들지 않는다"는 원칙에 구멍이 있다.
2. **1 Case 시범을 앱에 넣는 경로가 없다**(D2). 승인 후에도 앱에서 플레이하려면 둘 중 하나가 필요하다.
   - (a) 시범을 정식 시즌 구조(12 Case, 지도, 프롤로그)로 확장
   - (b) 역사 게이트를 거치는 시범 전용 생성·실행 경로(코드 변경 필요)
3. **기록 엔진의 작은 화면 가독성.** 320 폭에서 값이 최대 약 11 px로 그려지고, 줄 터치 영역이 36–38 px다. 6줄이라 줄 간격을 넓힐 여유도 없다. 실제 미션 화면에 확대 기능이 있는지는 확인하지 않았다.
4. **임시 그림.** M3 흔적 장면은 London Case 01의 탑 아래 그림과 측정 좌표를 빌렸다. 라벨("brush box" 등)이 그림 내용과 다르다. 시범 검증용일 뿐이며, 정식 그림이 생기면 다시 측정해야 한다.
5. **h3 단순화**("MOUTH, THROAT") — 사람 판단 필요.
6. **1446년 왕비 상중**과 창작 장면(아침 낭독)의 어울림 — 사람 판단 필요(§2.2).
7. 선택기는 단어에 민감하다. JUNIOR/MASTER 문장을 바꿔도 Rookie 기준 결과는 그대로지만, Rookie 문장을 고치면 다시 확인해야 한다.

---

## 10. 다음 작업 및 사용자 승인 필요 항목

**사용자 결정:**
1. **D1 처리:** 역사 모드 시즌은 `sandbox` 대상에서도 게이트로 막을지(권장: 막음. 생성기 한 곳 수정 + 테스트)
2. **앱 플레이 경로:** §9-2의 (a) 또는 (b)
3. §2.2 / §9-5 / §9-6의 내용 판단

**사용자 승인** (모두 터미널에서 직접. Claude는 실행할 수 없음):
1. h1·h2·h3·h4·h5·h8 출처를 확인하고 `source_checked`로 바꾼 뒤 `approve … fact s7_ep01_h<n>` (h6·h7은 선택)
2. `approve … puzzle s7_ep01_m1`, `…_m2`, `…_m3`, `…_final` (7개 체크리스트)
3. `approve … reveal s7_ep01`

승인과 위 결정 이후의 작업:
- 게이트를 다시 확인하고 생성 경로를 정한다.
- 앱 플레이 테스트(§7.4 항목 전체)를 한다.
- 정식 서울 그림의 사양을 정리한다(예산 지정 전에는 생성하지 않음).
