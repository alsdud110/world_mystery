# Seoul Pilot Case 01 — 최종 승인 준비 검토

작성일 2026-11-04

**결론:**
- 사실 7건은 모두 **PASS**다. 그중 3건은 이번에 레벨 문구를 고친 뒤 PASS가 되었다.
- 퍼즐 4건도 **PASS**다. 남은 판단 항목은 §2에 적었다.
- M3 흔적은 이제 그림 위에 그려지고, 터치 영역과 위치가 일치한다.
- 승인 기록 생성, 승인 명령 실행, 상태 변경은 하지 않았다. 사실은 모두 `draft` 그대로다.
- 유료 API 호출, 정식 서울 시즌 생성, 커밋은 없다.

---

## 1. 역사 사실 7건 개별 검토

**확인 방식:**
- **A** = 실록 국역·한문 원문을 직접 열어 대조
- **B** = 기관 페이지 본문을 열어 인용 문장이 있는지 확인(2026-11-04)

**자동 출처 규칙**(`HistoryDossier.sourceProblems`: 출처 2개 이상, 서로 다른 기관, 1차 또는 공공기관 1개 이상, 인용, 확인일, 미해결 충돌 없음): 7건 모두 문제 없음.

| 사실 | 판정 | 출처 (기관 수) | 게임 문구 ↔ 원문 | 이번 검토에서 확인·수정한 것 |
|---|---|---|---|---|
| **h1** 1443년 세종이 28자를 만들어 훈민정음이라 함 | **PASS** (수정 후) | 실록 1443(A, 국편) · UNESCO(B) · 국립한글박물관(B), 3기관 | 「上親制諺文二十八字…是謂訓民正音」 ↔ "King Sejong made 28 new letters in 1443." | Master reveal의 "an **entirely** new script"는 실록의 「其字倣古篆」(옛 전자를 본떴다)와 충돌한다 → "a new script"로 **수정**. 참고: 음력 세종 25년 12월은 양력으로 1444년 초에 걸치지만, 관례대로 1443을 쓴다(UNESCO, 박물관 모두 1443). |
| **h2** 1446년 9월 책 『훈민정음』 완성 | **PASS** | 실록 1446(A) · UNESCO(B) · kmowkc(B), 3기관 | 「是月, 訓民正音成。」 ↔ "A book about them was finished in 1446." / M1 "Autumn, 1446" | 29일 기사 vs 서문 "9월 상순" → 연도만 쓴다. 음력 9월은 가을이므로 "Autumn"은 맞다. |
| **h3** 기본 자음 = 발음 기관 모양 | **PASS** (수정 후) | 우리역사넷 제자해(B, 국편; 국역과 한문 원문) · 백과 28자모(B, 한중연), 2기관 | 「牙音ㄱ象舌根閉喉之形…喉音ㅇ象喉形」 ↔ "Five main consonant letters copy the shapes we make to speak. They show the tongue, the mouth, the teeth and the throat." | Junior "the shapes **our mouths** make"는 목구멍(ㅇ)을 빠뜨린다 → "the shapes we make when we speak"로 **수정**. 우리역사넷 국역은 ㅇ을 생략했지만 같은 페이지 한문 원문에 「喉音ㅇ」이 있다. 실록 1443의 "倣古篆"과 상형설은 서로 다른 서술이라, 게임은 "the book says"의 범위만 쓴다. |
| **h4** ㆍ하늘·ㅡ땅·ㅣ사람 | **PASS** | 우리역사넷(B) · 백과 초출자(B) · 박물관 웹진(B), 3기관 | 「形之圓象乎天…形之平象乎地…形之立象乎人」 ↔ "The dot is the round sky. The flat line is the flat earth. The standing line is a person." | Rookie "is", Junior "stands for", Master "represents"는 모두 '본뜸'의 쉬운 표현이고 뜻이 같다. |
| **h5** 서문: 쉽게 익혀 날마다 편히 쓰게 | **PASS** (검토 의견 1) | 실록 1446 한문(A) · 박물관 전시(B), 2기관 | 「新制二十八字, 欲使人(昜)〔易〕習, 便於日用耳。」 ↔ "so people can learn them easily and use them every day" / 종이 "EASY TO LEARN" | **이본**: 실록은 「欲使人易習」(人 하나, 昜→易 교감), 해례본은 흔히 「人人」으로 인용된다(해례본 원본은 이번에 직접 보지 않음). "people"은 양쪽에 맞는다. **검토 의견**: Master reveal "his **sole** aim"은 「耳」(~할 뿐)의 해석이다. 너무 강하다고 판단되면 "The King wrote that he made them only so…"로 바꿀 수 있다. |
| **h6** 정인지 서문: 아침나절 / 열흘 | **PASS** (수정 후) | 실록 1446 한문(A) · 박물관 전시(B), 2기관 | 「智者不崇朝而會, 愚者可浹旬而學。」 ↔ "The book says a slow person can learn them in ten days." | Master "can **master** them"은 「學」(배우다)보다 강하다 → "learn"으로 **수정**. **게임의 주장 범위**: "책이 그렇게 말한다"이지 실제 학습 기간이 아니다. 愚者 → "slow person"(아동용 순화). 실록은 不崇朝, 해례본 인용은 흔히 不終朝(이번에 원본 미확인, 게임 문구에 영향 없음). Sora "열흘", Bae "칠 일"은 창작 인물의 경험이다. |
| **h8** 승정원 = 왕명 출납 관청 | **PASS** | 백과 승정원(B, 한중연) · 승정원일기 소개(B, 국편), 2기관 | 「왕명의 출납을 관장하던 관청」 ↔ "The Royal Secretariat carries the King's orders." | 출납(명령이 나가고 보고가 들어옴)을 아동용으로 "carries/passes the King's orders"로 줄였다. 설치 연도 서술은 출처마다 다르지만 세종대에는 존재했다. |

- **확인 불가 → 승인 추천 안 함:** 없음. 승인 근거로 쓰지 않는 자료도 함께 적는다.
  - h7: 게임에서 사용 안 함, 승인 불필요
  - 왕비 상중(출처 1)
  - 경복궁 특정(출처 1)
  - 해례본 원본의 「人人」「不終朝」(직접 미확인, 게임 문구가 의존하지 않음)
- **실제 역사와 창작의 구분:** IN THIS MYSTERY 2줄과 dossier `fiction` 3줄에 창작 범위를 적었다: 인물 4명, 왕실 글, 가짜 종이, 그날 밤, 상자, 붓 보자기, 학자 쪽지, 궁중 의례 없음. 세종은 언급만 하고 대사·행동이 없다.
- **세 난이도:** 숫자(28, 1443, 1446, ten)와 고유명사가 같다(자동 검사). 뜻이 같은지는 위 표의 수정으로 맞췄다.
- **History Reveal:** REAL HISTORY 4줄은 h1 / h2+h4 / h5 / h8에 근거한다. 연도는 사실 문장과 일치한다(자동 검사 `history_reveal_unsupported` 없음).

---

## 2. 퍼즐 4건 검토

| 항목 | M1 `timeline_board` | M2 `record_mismatch` | M3 `trace_deduction` | Final `evidence_talk` |
|---|---|---|---|---|
| 필요한 단서가 게임 안에 있는가 | 장부 6줄 (then / later / after / nobody after) | 편지에 학자 쪽지 전문, 두 종이 4줄 | 메모 3줄 + 그림 위 흔적 3개(이번에 그려 넣음) | 수첩 3줄 + M1·M2·M3 증거, M1 끝 장면 "Bae는 베끼는 종이마다 잎을 그린다" |
| 정답이 하나인가 | 고정 카드 2장 + 관계 3개의 사슬 → 순서 하나(TimelineRules 검사). LUNCH는 낮의 일 | 다른 줄은 WHY 한 쌍뿐(`records_ambiguous` 검사) | 뚜껑이 있고 깔개 위에 있는 상자는 작은 상자뿐. 서랍은 뚜껑 없음, 궤짝은 열림 | 주장마다 받는 증거가 하나(시간 → 장부, 글씨 → 가짜 종이, 숨김 → 보자기). 틀린 카드는 오답이 아님 |
| 세 난이도에서 풀리는가 | 레벨별 PlayCheck 통과, 관계 문장이 레벨 편지에 그대로 있음 | 값은 레벨이 바꾸지 못함, 레벨 검사 통과 | 흔적 문장이 레벨 편지 줄과 글자 그대로 같음(PlayCheck) | 통과 |
| 오답·힌트가 공정한가 | 힌트 1: 순서 단어를 보라. 힌트 2: 점심 카드를 빼라. 오답 문구: "Sora 다음에 누가 왔나" | 힌트 2는 정답 줄을 직접 가리킨다(두 번째 힌트로는 의도된 수준). 오답은 엔진 기본 문구(경고 1건) | 오답 문구가 그 장소가 맞지 않는 이유를 말함(뚜껑, 잉크) | 놓쳐도 `miss` 문구만 나오고, 계속 시도할 수 있음 |
| 잘못된 역사 추론 유도 | 없음(창작 사건) | 가짜 종이의 "SCHOLARS ONLY"는 범인의 거짓으로 제시되고, 정답 직후 단서 노트와 Final, reveal에서 바로잡힌다 | 없음 | 범인의 동기(일감이 사라질 걱정)는 창작이다. 실존 반대 상소는 언급하지 않는다 |
| Final 세 증거가 독립적으로 의미가 있는가 | — | — | — | ① 장부 = **기회**(다만 Sora도 들어왔으므로 이것만으로는 부족) ② 잎 표시가 있는 새 글자 가짜 종이 = **가짜 종이를 쓴 사람 = 새 글자를 아는 Bae** ③ 이름이 수놓인 보자기에 싸인 원본 = **숨긴 원본과의 물증**. Sora도 새 글자를 알지만 범인이 아니므로 "새 글자를 배웠다"만으로는 결정되지 않는다. 세 단계가 모두 필요하다(`finishWhen`). |
| 판정 | **PASS** | **PASS** | **PASS** (이번 수정 후) | **PASS** |

**남은 검토 의견** (승인 시 사람이 판단할 것):
1. M2 오답에 전용 문구가 없다. 엔진 기본값("Not quite!")이 나온다. matchPairs는 `orderFeedback`을 받지 않는다.
2. Final ②의 잎 표시는 Taek의 증언에 기대고 있다. 아동 대상 추리로는 충분하다고 판단했다.
3. M3의 "깔개 위의 상자"는 그림에서 상자가 깔개 가장자리에 놓인 모습에 의존한다. 정식 그림에서는 더 분명해야 한다.

---

## 3. M3 단서 시각화 결과

**문제:** 빌린 그림(파리 작업실)에는 잉크, 붓털, 종이 모서리가 없었다. 기존 엔진의 돋보기 원반은 위치만 알려 줄 뿐이었다.

**해결:**
- 기록 엔진에 **선택적 흔적 그리기**를 추가했다(유료 API 없음, 그림 파일 무변경).
- 모델: `TraceSketch { inkDrops, hair, paperCorner }`, `DeductionClue.sketch`(기본 `null`)
- 화면(`SceneDeduction`): `sketch`가 있으면 그 흔적의 **터치 영역 안에** 기존 디자인 토큰으로 그린다.
  - 잉크 = `AppColors.ink`, 종이 = `AppColors.paper`
  - 옅은 종이색 테두리를 둘러 어두운 나무·깔개 위에서도 보인다.
  - 잉크: 상자 쪽으로 점점 커지는 방울 4개
  - 붓털: 곡선 한 줄(두께 2.5 이상)
  - 종이: 찢긴 가장자리가 있는 삼각형
- 그려진 흔적은 그 자체가 표시이므로, 기록되기 전에는 돋보기 원반을 덮지 않는다. 기록되면 기존 체크 원반이 나타난다.
  - 처음에는 원반을 옆으로 옮겼는데, 원반이 흔적이 아닌 곳(바닥)을 가리켜 거기를 누르면 "Nothing here"가 나왔다. 그래서 이 방식으로 바꿨다.
- 계획·생성: 계획 `traces.clues[].sketch`(스키마 enum, Dart 모델, 레벨 비텍스트 키), 생성기가 `sketch: TraceSketch.x` 출력. 쓰는 시즌에만 import된다.
- **기존 콘텐츠 무영향:** London Case 01 등 `sketch`가 없는 장면은 이전과 같다. 원반이 그대로 보이고 아무것도 그리지 않는다(테스트). Rome·NY·샌드박스 생성물 불변.
- 시범 계획:
  - 세 흔적에 sketch를 지정했다.
  - 원반 위치는 흔적 중심이다(그려진 흔적과 탭 위치가 같다).
  - 처음 보이는 영역을 1000→800px로 좁혀 흔적을 더 크게 보이게 했다.
  - 안내점을 빈 바닥으로 옮겼다.

**측정** (320×568, 엔진 단독 렌더):

| 흔적 | 그려진 크기 | 화면 안 | 중앙 탭 → 기록 | 기록 전 원반 | 스크린리더 라벨 |
|---|---|---|---|---|---|
| ink | 52×22 | ✅ | ✅ | 없음 → 기록 후 체크 | "Drops of black ink across the rug" |
| hair | 28×20 | ✅ | ✅ | 없음 → 체크 | "A long brush hair under a lid" |
| corner | 24×24 (×1.6: 22.5) | ✅ | ✅ | 없음 → 체크 | "A torn paper corner" |

- 큰 글자 ×1.6에서도 같다.
- 눈으로 확인: 실제 그림과 함께 렌더한 화면을 캡처했다. 세 흔적이 깔개 위 잉크 자국, 상자 뚜껑의 털, 상자 옆 종이로 가려지지 않고 보인다. 캡처용 임시 테스트는 삭제했다.
- 한계: 종이 모서리 그림이 작은 화면에서 화살표처럼 보일 수 있다. 그림은 여전히 파리 작업실(테스트용)이다.

---

## 4. 수정 파일

| 파일 | 내용 |
|---|---|
| `lib/data/models/scene_deduction.dart` | `TraceSketch`, `DeductionClue.sketch` (선택) |
| `lib/features/mission/widgets/scene_deduction.dart` | 흔적 그리기(`_TraceSketchPainter`), 그린 흔적의 원반은 기록 후에만 표시. 커밋 기준 +97/−9 |
| `tool/season_gen/plan_models.dart`, `schema/mission_plan.schema.json` | `traces.clues[].sketch` (enum) |
| `tool/season_gen/generate_case.dart` | `sketch` 출력, `TraceSketch` import |
| `tool/season_gen/case_levels.dart` | `sketch`를 레벨 문구가 아닌 키로 지정 |
| `test/sandbox/plans/s7_seoulpilot/cases/s7_ep01/case.plan.json` | M3 sketch, 원반 위치, 처음 보이는 영역, 안내점, 노트 |
| `test/sandbox/plans/s7_seoulpilot/cases/s7_ep01/levels.json`, `planning/history_dossier.json` | 레벨 문구 3곳 수정(h1 Master, h3 Junior, h6 Master) |
| `test/sandbox/s7_pilot_traces_test.dart` | 신규 5개 테스트 |
| `docs/SEOUL_PILOT_CASE01_APPROVAL_REVIEW.md` | 이 보고서 |

**작업 중 사고와 복구 (알림):**
- `mission_plan.schema.json`을 고치는 중에 제 스크립트 실수(쓰기 모드로 먼저 연 뒤 읽음)로 파일이 **빈 파일**이 되었다. 이 파일에는 이전 PART들의 커밋 안 된 변경이 있었다.
- 복구: git에 남아 있던 같은 날 10:29의 객체(`fdaa786`, 편집 직전 작업 사본)로 되돌렸다. 직전 상태임은 내용(`flat.minimum: 1`)과 시각(10:29, 편집 10:30)으로 확인했다.
- 그 뒤 `sketch` 한 줄만 다시 넣었다. 현재 파일과 그 객체의 차이는 이 한 줄뿐이다.
- 스키마↔모델 대조 테스트(181개)와 회귀 묶음이 통과했다.
- 따로 `scene_deduction.dart`가 `dart format`으로 전체 재정렬된 것도, 커밋 버전 + 제 변경만으로 되돌렸다.

---

## 5. 테스트 결과

| 검사 | 결과 |
|---|---|
| `flutter analyze` | No issues found |
| 시범 `validate_plan` / `case_levels check` | 0 errors / every level written, the same game |
| 시범 `plan_season check --all` | Case 오류 0건. 남은 것은 시범 시즌 구조 오류(prologue, bible, manifest, case_missing ×11)와 M2 오답 문구 경고 1건 |
| 자동 선택기 | 4/4가 기획과 일치, 정답·플레이·레벨 pass |
| 사실 출처 규칙(`sourceProblems`) | 7건 모두 문제 없음 |
| M3 흔적 테스트 `s7_pilot_traces_test` | 5/5: 계획의 sketch, 생성기 출력(인메모리·쓸 수 없음), 320×568 ×1.0/×1.6 표시·탭·라벨·원반, sketch 없는 장면 무변경 |
| 역사 게이트 | 시범 차단: 유료 단계 10건, 생성 15건. 모두 승인 항목. `s7_pilot_gate_test` 통과 |
| 회귀 묶음 (STEP 1 묶음 + 시범·경로·게이트·레이아웃·흔적 테스트) | **+903, 모두 통과**, 3분 41초. London Case 01 흔적 장면 테스트(`case01_deduction_test`, `full_playthrough_test`) 포함 |
| Rome·New York `--target game --check` | 각 30 + 3 files up to date |
| 샌드박스 s8·s9 `--check` | up to date. 시범 생성물 없음 |
| 전체 `flutter test`, Release 빌드 | 실행하지 않음 |

---

## 6. 사용자가 직접 실행할 승인 명령

모두 **터미널에서 직접** 실행한다. 승인 도구는 대상 ID를 직접 타이핑해 확인받고, TTY가 아니면 거부한다. Claude는 실행하지 않았다.

### 6.1 사실 7건

**사전 조건:** 사실마다 `status`가 `source_checked`여야 한다. 현재는 모두 `draft`다.

1. §1의 출처를 직접 열어 확인한다.
2. `test/sandbox/plans/s7_seoulpilot/planning/history_dossier.json`에서 h1, h2, h3, h4, h5, h6, h8 항목의 `"status": "draft"`를 **사람이 직접** `"status": "source_checked"`로 바꾼다. h7은 쓰지 않으므로 그대로 둔다.
3. 상태가 바뀌는지 확인한다: `dart run tool/season_gen/approve.dart status test/sandbox/plans/s7_seoulpilot fact s7_ep01_h1`
4. 승인한다(각 명령마다 ID 입력):

```
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h1
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h2
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h3
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h4
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h5
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h6
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot fact s7_ep01_h8
```

### 6.2 퍼즐 4건

**사전 조건:** 인용한 사실이 승인되어 있고, 레벨 파일이 있으며, 자동 검사 오류가 없어야 한다. 실행하면 7개 체크리스트가 나온다.

```
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot puzzle s7_ep01_m1
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot puzzle s7_ep01_m2
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot puzzle s7_ep01_m3
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot puzzle s7_ep01_final
```

### 6.3 History Reveal 1건

```
dart run tool/season_gen/approve.dart approve test/sandbox/plans/s7_seoulpilot reveal s7_ep01
```

### 6.4 확인

```
dart run tool/season_gen/approve.dart status test/sandbox/plans/s7_seoulpilot
flutter test test/sandbox/s7_pilot_gate_test.dart
```

게이트 테스트가 "after its approvals" 분기로 바뀌어야 한다. 그 시점에 생성물이 없으면 이 테스트는 실패하며, 이것은 정상이다(다음 생성 단계를 요구하는 것).

**주의 — 승인이 무효화되는 경우:** 승인은 내용의 해시다. 승인 뒤 다음을 바꾸면 해당 승인이 `stale`이 되어 다시 승인해야 한다.
- 사실 문장, 출처, 충돌 기록
- 미션 JSON(그림 좌표·sketch 포함)
- `levels.json`의 문장 하나
- reveal 문장

그러니 §1의 h5 Master 검토 의견("sole aim")처럼 고칠 것이 있으면 **승인 전에** 고친다.

---

## 7. 승인 후 실제 플레이 테스트 절차

1. **생성** (승인 후에만 가능):
   `dart run tool/season_gen/generate_season.dart --season test/sandbox/plans/s7_seoulpilot/season.plan.json --target sandbox`
   - `test/sandbox/generated/s7_seoulpilot/`에 생성된다(`s7_seoulpilot_history.g.dart` 포함).
   - 이어서 `flutter test test/sandbox/s7_pilot_gate_test.dart`가 통과해야 한다(생성물 최신 확인).
2. **플레이 테스트 추가** `test/sandbox/s7_pilot_play_test.dart`:
   - 생성된 테이블로 `SeasonContent`를 만든다: `timelines`, `records`, `deductions`, `talks`, `historyReveals` 등.
   - `SingleCase(season, 's7_ep01')`와 `CasePlayer`(`test/sandbox/single_case.dart`, s8로 검증 완료)를 쓴다.
3. **시나리오:**
   1. Story Intro → 지도
   2. M1: 틀린 순서 → 오답 문구 → 힌트 → 정답
   3. M2: 틀린 줄 쌍 → TRY AGAIN → WHY 쌍
   4. M3: 그려진 흔적 3개 기록(원반 체크) → 궤짝(오답 문구) → 작은 상자
   5. **앱 재실행** → 진행이 복구되는지
   6. Final: 틀린 카드(오답 아님) → 세 증거 → CLOSE THE CASE
   7. 보상 1회(같은 답 재제출 시 코인 0)
   8. Case Closed: REAL HISTORY 4줄 / IN THIS MYSTERY 2줄 구분, SOURCES 다이얼로그
4. **화면:** 위 시나리오를 390×844와 320×568에서 실행하고, 큰 글자 ×1.6, 스크린리더 라벨(흔적, 기록 줄, 장소)을 확인한다.
5. **레벨:** JUNIOR, MASTER로 각각 한 번 더 플레이한다(정답 동일, 문장만 다름).
6. 결과를 보고한다. 실기기 확인은 별도 개발 진입이 필요해 이 경로 밖이다.
