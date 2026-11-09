# Seoul Case 02~12 — 어린이 플레이 가능성 · 역사 · 스토리 · 난이도 전수조사

- 작성: 2026-11-09 · 기준: `main` 5c870fd + 작업 트리의 미커밋 변경(Case 01 V4, Case 08 일부 등)
- 범위: Seoul(시즌 5) Case 02~12, 11개 Case × (M1·M2·M3·Final) = **44개 퍼즐**, Intro·전환·Ending·Case Closed 포함
- 대상 플레이어: **8~12세 영어권 어린이, 한국사 처음, 한글 모름** (ROOKIE 8세 / JUNIOR 10세 / MASTER 12세)
- 조사만 했다. 게임 코드·스토리·퍼즐·이미지·저장 데이터 수정 없음, 커밋·푸시·R2 업로드 없음. 추가한 파일은 이 문서와 분석 스크립트 `tool/audit/seoul_text_stats.py`뿐.
- 표시: 직접 실행하지 않은 화면 동작은 **[코드 분석]**. 외부 자료로 확인하지 못한 역사 내용은 **미검증**.
- 진행 상태: PART 1~5 모두 완료. 맨 앞 A~G가 종합, 근거는 PART 1~5.

---

## 읽는 법

- **A~G**는 아래 PART 1~5의 종합본이다. 근거(인용·파일 경로·줄 번호)는 각 PART에 있다.
- PART 2~4는 Case별 정밀 조사, PART 5-A는 Case 간 연속성, PART 5-B는 역사 고증, PART 5-C는 엔진별 UX다.
- 모든 판단은 **[코드 분석]**이다. 앱 실행, 실기기 확인, 테스트 실행은 하지 않았다. 그림은 일부(C03 설계도, C04 목재 마당, C11 방)만 직접 열어 봤다.
- 정밀 조사는 Case별로 나눠 진행했다. 그래서 점수 기준이 조금씩 다를 수 있다. 종합하면서 역사 점수 3곳(C03·C08·C12)은 PART 5-B 결과에 맞춰 고쳤다.

---

# A. 전체 요약

| 항목 | 값 |
|---|---|
| 조사한 Case | 11 (Case 02~12) |
| 조사한 Mission/Final | 44 (Mission 33 + Final 11) |
| 조사한 퍼즐 | 44 (Final 대화형 3개는 질문 3~4개씩) |
| 난이도별 표시 텍스트 | 1,645줄 × 3레벨. 단어 수 ROOKIE 14,902 / JUNIOR 16,093 / MASTER 16,214 |
| 레벨 공통 문장 | 401/1,645 (24.4%). 대부분 라벨·선택지이고, 스토리 문장은 거의 모두 레벨별로 다르다 |
| **P0** (진행 불가) | **0** |
| **P1** (핵심 품질) | **3** — C12-1, C10-1, S-1 |
| **P2** (개선 필요) | **약 75** (출처별 합계는 아래, 중복 제외 추정) |
| **P3** (경미) | **약 55** |

출처별 원래 집계:

| 출처 | P1 | P2 | P3 |
|---|---|---|---|
| Case 02~05 | 0 | 22 | 9 |
| Case 06~09 | 0 | 20 | 13 |
| Case 10~12 | 2 | 12 | 13 |
| 연속성 | 1 (C12-1과 같은 건) | 7 | 7 |
| 역사 | 0 | 3 | 9 |
| UX 엔진 | 3 → 종합 때 1개만 P1로 유지 | 10 (+ P1에서 내린 2) | 5 |

**종합 때 바꾼 판정 (근거 확인 후):**
- UX의 "evidence_talk Final에 힌트 버튼 없음"은 P1에서 **P2**로 내렸다. `final_mission_screen.dart:868-879`의 `_talkFinal`이 `CaseTalk`만 그리고 힌트를 넘기지 않는 것은 직접 확인했다. 하지만 두 번 틀리면 정답 카드가 빛나서 진행은 막히지 않는다.
- "GYEONGSUN 철자 입력"도 P1에서 **P2**로 내렸다. 이름이 화면 문장에 있어서 보고 칠 수는 있다. 8세에게 부담이 큰 것은 맞다.
- 연속성 I-2("엄마, 고마워요" 대사에 `s5_ep01_e3` 카드가 붙음)는 C08 조사에서는 P3였지만 **P2**로 맞췄다. 같은 오참조가 C08과 C12 두 곳에 있다.

### 가장 심각한 문제 (시즌 전체)

1. **대상 불일치 (S-1, P1 — 대상이 영어권 어린이라면).** 단어 풀이의 뜻이 **전부 한국어**다(`gunpowder: 화약`, `envoy`, `treaty`, `provisional` 등. `lib/widgets/glossary_text.dart:251-290`). 영어 정의를 보여 주는 경로도, 언어 설정(l10n)도 없다. 보호자 리포트도 한국어 전용이다. 지금 코드는 **한국 어린이와 보호자**를 대상으로 만들어져 있다. 영어권 8세는 envoy, treaty, Provisional Government, Daewongun을 확인할 방법이 없다.
2. **Final 11개 중 7개가 사건 해결이 아니라 단어·연도 확인이다.** C02 DRAGON, C03 1796, C05 JAPAN, C06 FORCED, C10 1932, C11 KOREAN, C12 LIGHT가 그렇다. 앞에서 모은 증거가 정답 도출에 쓰이지 않는다. 글자 타일 자물쇠 4개(C02 F, C06 F, C10 M3, C12 F)는 **정답 글자만** 주는 애너그램이라 무작위로 눌러도 풀린다. 증거 제시 Final 3개(C04, C07, C09)는 질문마다 **선택지가 2개**이고 두 번 틀리면 정답이 드러난다.
3. **정답이 퍼즐 전에 화면에 나온다.** C02 M3의 12(M1 첫 대사), C03 F의 1796(Final 첫 줄 "Autumn, 1796."), C04 M2의 10(시놉시스·훅·대사), C10 F의 1932(여러 화면), C11 F의 KOREAN(편지 첫 줄), C05 F의 JAPAN(지문 문장 그대로)이다.
4. **순서 퍼즐의 지문이 이미 정답 순서다.** C03 M1, C04 M3, C05 M2(timeline), C06 M2(쪽지 순서 = 정답 순서)가 그렇다. 목표로 한 until/after/before 독해가 실제로 시험되지 않는다. 같은 형식이 Case 03~05에 연속으로 세 번 나온다.
5. **시즌 회수가 Case 01 V4와 어긋난다 (C12-1, P1).** C12 M2의 분이 카드는 아직 구판 문구 "The first note: the name of the letters."다(`s5_ep12.g.dart:504`). V4에서 분이의 첫 편지는 "엄마, 고마워요"다. C08과 C12는 편지 전체를 말하면서 증거로 `s5_ep01_e3`(첫 단어 "엄마"만)을 붙인다. 편지 전체 증거는 `e4`다. C12에서는 쪽지 수도 충돌한다("Six notes slide out" vs "under eleven more").
6. **역사 배경 한 줄이 비어 있다 (C08-3).** 1910년 일본의 한국 지배가 시즌 어디에도 서술되지 않는다. 그래서 C08~C12의 independence, 경찰, 임시정부, 광복이 영어권 아이에게 무엇에 대한 것인지 전달되지 않는다. 이토 히로부미가 누구인지(C07), 대원군 칭호(C04), March First Movement라는 이름(C09)도 설명이 없다.
7. **탐정의 역할이 수동적인 곳이 있다.** 경고문 작성자가 추리가 아니라 Ending 자백으로 밝혀진다(C03 옥분, C04 두리). C05는 쪽지·증언·밧줄·지도를 모두 한 상궁이 가져다준다. C04는 통나무 수레를 우연히 발견한다.

### 잘된 점

- **진행 불가(P0)는 없다.** 44개 퍼즐 모두 화면 단서로 정답이 나오고, 정답은 하나로 정해진다(C06 M3만 문장 해석이 둘로 갈릴 여지가 있다. P2).
- **한글을 읽거나 칠 필요가 있는 필수 조작은 없다.** C02 M2 거북선은 탭으로 조립한다. 영어 단어 입력은 대문자 TextField다.
- 오답 피드백이 흔한 실수를 짚는 미션이 많다. 예: C02 M2 거묵선·거북서, C11 M3의 219, C12 M3의 715/915/814.
- 역사 뼈대는 맞다. 고증 오류(P1)는 0건이다. 1592.4.12 대포 시험, 1909.10.26 하얼빈, 1919.4.1 아우내, 1932.4.29, 1945.8.15 등이 확인됐다(출처 URL은 PART 5-B). 사망·폭력 서술은 한 문장으로 담담해서 8세 기준으로 적절하다.
- plan과 생성 파일(`.g.dart`)의 정답·유형·자릿수가 44개 모두 일치한다.

### 가장 잘 설계된 Case / 우선 개선 대상

- **가장 잘 설계됨: Case 11** (4.3). 돋보기 탐색 → 두 기록 비교 → 피아노 상자 숫자 순으로 형식이 다르고, 단서가 모두 화면에 있으며, 오답 설명이 좋다. 그다음은 C07(흐름)과 C12 M1·M2, C08 M1·M2(증언 비교와 시간 표현 재배열)다.
- **우선 개선: Case 10** (3.3. P1 장면 모순, 시계를 바꾼 이유 없음, Final이 연도 확인), **Case 12** (P1 분이 카드, 쪽지 수, 시즌 피날레 회수), 그다음 **Final 구조가 약한 C02·C03·C05·C06**.

---

# B. Case별 평가표 (5점 만점)

| Case | 풀이 가능성 | 퍼즐 다양성 | 영어 난이도 | 역사 | 개연성 | UX·힌트 | 종합 |
|---|---|---|---|---|---|---|---|
| 02 거북선 | 4 | 4 | 3.5 | 4.5 | 3 | 4 | 3.8 |
| 03 거중기 | 4.5 | 3.5 | 3.5 | **4** ¹ | 3 | 4 | 3.8 |
| 04 경복궁 | 4.5 | 4 | 3 | 4.5 | 3 | 3.5 | 3.8 |
| 05 건청궁 | 5 | 3.5 | 3 | 4.5 | 3 | 4 | 3.8 |
| 06 헤이그 특사 | 4 | 3 | 4 | 5 | 3 | 4 | 3.8 |
| 07 하얼빈 | 4 | 4 | 3 | 5 | 4 | 4 | 4.0 |
| 08 아우내 | 4 | 4 | 3 | **4.5** ² | 3 | 4 | 3.8 |
| 09 상하이 | 4 | 4 | 3 | 5 | 3 | 4 | 3.8 |
| 10 두 시계 | 4 | 3 | 4 | 4 | **2** | 3 | **3.3** |
| 11 윤동주 | 5 | 4 | 4 | 5 | 4 | 4 | **4.3** |
| 12 광복 | 5 | 3 | 4 | 5 ³ | 3 | 4 | 4.0 |

¹ 정약용을 1795년 화성 현장 책임자처럼 그림(실제 현장 총괄은 조심태). PART 5-B P2-2.
² 유관순 "단독 주도" 서술. PART 5-B P2-1.
³ 사실 오류는 없지만, 김원봉의 등장은 사용자가 결정해야 한다. PART 5-B P2-3.

**공통 감점 (점수에 넣지 않음):** 단어 풀이가 한국어뿐이다(S-1). 대상이 영어권이라면 모든 Case의 "영어 난이도"와 "UX"가 0.5~1점씩 내려간다.

근거 요약:
- **풀이 가능성:** 모두 4 이상이다. 막히는 곳은 없고, 감점은 해석 여지(C02 M1 wet straw, C06 M3, C09 M1/M3)와 철자 입력(C08 M3) 때문이다.
- **퍼즐 다양성:** Case 안에서는 형식이 다양하다. 하지만 시즌 전체로 보면 숫자 입력 8개, 순서 9개, 단어/타일 입력 9개에 몰려 있고, Final이 약하다.
- **영어:** ROOKIE 문장은 짧다(평균 6.0어, 15어 초과 8문장). 대신 ROOKIE와 JUNIOR의 차이가 단어 바꾸기 수준이다. 설명 없는 역사 용어와 추상 개념(인플레이션, 조약, 망명정부)이 감점 요인이다.
- **개연성:** Case 안의 M1→M3 흐름은 대부분 탄탄하다. Final이 사건과 끊기거나 자백으로 끝나는 것이 공통 감점이다.
- **UX:** 오답 피드백은 좋다. 힌트 2가 정답을 그대로 말하는 경우가 많다. 2지선다와 애너그램은 너무 쉽다.

---

# C. 미션별 상세표 (44개)

정답 도출 과정, 실제 단서, 외부 지식, 복수 정답 검사의 상세 내용은 PART 2~4의 Case별 "미션별 상세표"에 있다. 여기서는 유형, 핵심 판단, 심각도만 모았다.

| Case | Mission | 주 / 보조 유형 | 핵심 판단 | 외부 지식 | 심각도 |
|---|---|---|---|---|---|
| 02 | M1 bucket | 관찰 / 단순 선택 | 위치어로 3물건을 찾는 좋은 수색. wet straw도 "망칠 수 있다"로 보일 여지가 있다 | 없음 | P2 |
| 02 | M2 거북선 | 조합 / 암호 해독 | 탭 조립이라 한글을 몰라도 된다. ㅂ 모양이 어디에도 없고, ㅁ = "mouth"(V4는 lips) | 없음 | P2 |
| 02 | M3 12 | 논리(곱셈) | 4×3. 정답 12가 M1 첫 대사에 나온다 | 없음 | P2 |
| 02 | F DRAGON | 영어 어휘 / 단순 선택 | 정답 글자 6개 애너그램. 단어가 지문에 그대로 있다. 사건과 무관하다 | 없음 | P2 |
| 03 | M1 timeline | 순서 / 관찰 | 일지가 이미 시간순이다 | 없음 | P2 |
| 03 | M2 gate_wheels | 증거 비교 / 관찰 | 그림 3장의 두 조건 대조. 좋음 | 없음 | OK |
| 03 | M3 tie→rise | 순서 / 영어 | 뒤섞인 before/after로 진짜 추리. 좋음 | 없음 | OK |
| 03 | F 1796 | 기타(계산) / 역사 | 정답이 Final 첫 줄에 있다. 사건과 무관하다. 다이얼 자물쇠는 시대착오 | 월 계산 | P2 |
| 04 | M1 GATES | 관찰 / 암호(가획) | 획 하나로 나→다. 좋은 2단계 추리 | 없음 | P3 |
| 04 | M2 10 | 증거 비교 / 계산 | 정답 10이 미션 전에 3번 나온다 | 없음 | P2 |
| 04 | M3 timeline | 순서 / 역사 | 지문이 이미 시간순이다. 통나무 수레를 우연히 발견한다 | 없음 | P2 |
| 04 | F 증거 제시 | 증거 비교 / 논리 | 2지선다 ×4 + 자동 공개. "who took the logs?"를 증명하지 않는다 | 없음 | P2 |
| 05 | M1 belt | 관찰 / 단순 선택 | 그림의 손자국으로 읽지 않고도 고를 수 있다 | 없음 | P3 |
| 05 | M2 timeline | 순서 / 영어 | 같은 형식이 세 번째 반복된다. 지문이 대부분 시간순이다 | 없음 | P2 |
| 05 | M3 37 | 패턴(자릿값) / 계산 | 매듭으로 자릿값 읽기. 좋음 | 없음 | OK |
| 05 | F JAPAN | 영어 어휘 / 역사 | 지문 문장 베끼기. 지도는 복선 없이 나온다 | 없음 | P2 |
| 06 | M1 old pine | 관찰 / 논리 | 흔적 3개로 장소 하나. 쪽지가 흔적을 미리 다 말해 준다 | 없음 | P3 |
| 06 | M2 길 순서 | 순서 / 단순 선택 | 정답 순서 = 쪽지 문장 순서 | 없음 | P2 |
| 06 | M3 6:50 | 논리(시간) | "has passed / do not wait"면 6:51~7:19도 맞는다. "as soon as"가 없다 | 없음 | P2 |
| 06 | F FORCED | 영어 어휘 / 조합 | 정답 글자만 있는 타일. 사건 증거를 쓰지 않는다 | 없음 | P2 |
| 07 | M1 다른 줄 | 증거 비교 / 관찰 | 두 신문 비교. 좋음 | 없음 | P3 |
| 07 | M2 박 씨의 하루 | 순서 / 논리 | 사건이 "아침"이었다는 정보가 없는데 결론을 선언한다 | 없음 | P2 |
| 07 | M3 KOREA | 영어(베끼기) | 따옴표 안 단어를 옮겨 적는다 | 없음 | P2 |
| 07 | F 설득 | 증거 비교 / 단순 선택 | 2지선다 ×3. 노트에 답 문장이 있다 | 없음 | P2 |
| 08 | M1 세 전령 | 증거 비교 / 논리 | 증언 비교로 진짜 날짜를 정한다. 시즌 우수작 | 없음 | OK |
| 08 | M2 계획 순서 | 순서 / 논리 | 시간 표현으로 진짜 재배열. 우수 | 없음 | OK |
| 08 | M3 GYEONGSUN | 관찰(텍스트) / 증거 비교 | 9글자 로마자 철자 입력. 사건 목표와 무관한 시즌 메타 미션 | 없음 | P2 |
| 08 | F 311 | 조합 / 논리 | "3월 마지막 밤 + 4월 1일"은 좋은 추리. 다이얼 기호(clock/watch/map)가 단서 그림과 맞지 않는다 | 3월 31일 | P2 |
| 09 | M1 1:00 | 논리(시간) | "saw a light at eleven"은 11시에 켰다는 뜻이 아니다 | 없음 | P2 |
| 09 | M2 paper | 공간·지도 / 관찰 | 위치어 탐색 + 장소별 오답 설명. 우수 | 없음 | P3 |
| 09 | M3 NAM GIHO | 논리 / 증거 비교 | 밤새 있던 경비가 용의자에서 빠지지 않는다 | 없음 | P2 |
| 09 | F 김구 | 증거 비교 / 역사 퀴즈 | 2지선다 ×4. 4번째는 역사 확인 | 없음 | P2 |
| 10 | M1 순서 | 순서 / 논리 | 하나로 정해진다. 좋음 | 없음 | OK |
| 10 | M2 new_watch | 증거 비교 / 단순 선택 | **해수가 윤봉길이 가져간 낡은 시계를 탁자에 놓는다**: 장면 모순 | 없음 | **P1** |
| 10 | M3 DROP | 영어 어휘 / 반복 탭 | 4글자 애너그램(24가지). 답이 같은 문장에 있다 | 없음 | P2 |
| 10 | F 1932 | 역사 퀴즈 | 연도가 화면 곳곳에 있고, 힌트 2가 답을 말한다 | 없음 | P2 |
| 11 | M1 WATER | 관찰 / 영어 | 윤동주가 아직 아무도 보지 않은 물건을 이미 안다 | 없음 | P2 |
| 11 | M2 string | 증거 비교 / 관찰 | 흑백 → 건반 → 피아노 추리를 게임이 대신 말한다 | 없음 | P2 |
| 11 | M3 319 | 암호 / 논리 | 219 함정과 피드백. 우수 | 없음 | OK |
| 11 | F KOREAN | 역사 / 영어 | 정답이 편지 첫 줄에 있다 | 없음 | P2 |
| 12 | M1 trunk | 관찰 / 증거 비교 | 오답이 조건을 하나씩만 맞춘다. 우수 | 없음 | OK |
| 12 | M2 쪽지 순서 | 순서 / 논리 | **분이 카드가 구판 문구다.** 쪽지 6장 vs 11장 | 없음 | **P1** |
| 12 | M3 815 | 암호(날짜 변환) / 영어 | 15 August → 815. 좋음 | 날짜 표기 | P3 |
| 12 | F LIGHT | 영어 어휘 / 조합 | 5글자 애너그램. 타일을 남긴 동기가 없다 | 없음 | P2 |

### 퍼즐 유형 분포 (주 유형 기준)

| 유형 | 수 | 비율 | 미션 |
|---|---|---|---|
| 순서 배열 | 9 | 20% | C03 M1·M3, C04 M3, C05 M2, C06 M2, C07 M2, C08 M2, C10 M1, C12 M2 |
| 증거 비교 | 9 | 20% | C03 M2, C04 M2·F, C07 M1·F, C08 M1, C09 F, C10 M2, C11 M2 |
| 관찰 및 단서 찾기 | 7 | 16% | C02 M1, C04 M1, C05 M1, C06 M1, C08 M3, C11 M1, C12 M1 |
| 영어 어휘 퀴즈 | 6 | 14% | C02 F, C05 F, C06 F, C07 M3, C10 M3, C12 F |
| 논리 추리 | 4 | 9% | C02 M3, C06 M3, C09 M1·M3 |
| 조합 및 구성 | 2 | 5% | C02 M2, C08 F |
| 암호 해독 | 2 | 5% | C11 M3, C12 M3 |
| 역사 지식 퀴즈 | 2 | 5% | C10 F, C11 F |
| 패턴 발견 / 공간·지도 / 기타(계산) | 각 1 | 2% | C05 M3 / C09 M2 / C03 F |

- **Final 11개의 주 유형:** 영어 어휘 4, 역사 퀴즈 2, 계산 1, 증거 제시(2지선다) 3, 조합 1. **사건을 실제로 해결하는 Final은 C08 정도뿐**이다.
- CLAUDE.md 목표(읽기·추리 60~70% / 관찰·조작 30~40%)와 비교하면, 읽기 계열(순서·증거·어휘·논리·역사)이 약 70%, 관찰·조작 계열(관찰·조합·패턴·공간)이 약 25%다. 비율은 대체로 맞다. 하지만 영어 어휘·역사 퀴즈 8개(18%)가 대부분 Final에 몰려 있다.
- 반복: timeline 형식이 C03→C04→C05에 연속으로 나오고, 지문이 모두 시간순이다. 숫자 입력은 Case 11·12에 연속으로 나온다.

---

# D. 난이도별 영어 통계

실측표는 **PART 1 §1.4**에 있다(Case × 레벨: 단어 수, 문장 수, 평균·최장 문장, 15/20어 초과, 고유어, 평균 단어 길이, 스토리만 수치, 동일 문장 비율, 최장 문장 원문, 희귀어, 단어 풀이 수).

판정:
- **ROOKIE:** 평균 6.0어, 15어 초과는 시즌 전체에 8문장(최장 26어는 C03 M2 그림 설명의 altText)이다. 길이로는 8세에 맞는다. 문제는 어휘와 개념이다. treaty, envoy, Provisional Government, Daewongun, surrendered, Allies가 설명 없이 나오고, "new coin buys less"(인플레이션)나 "Palace paths get counted"처럼 추상적인 문장이 있다.
- **JUNIOR:** ROOKIE보다 단어가 8% 많고 평균 문장이 0.7어 길다. 차이가 대부분 동의어 바꾸기 수준이다("is gone" → "has vanished"). "조금 더 풍부한 설명과 추론 표현"이라는 기준에는 약하다.
- **MASTER:** 20어 초과 14문장, 희귀어(brimming, smudged, laboured, sweltering)가 늘어난다. 12세에 무리한 성인 문장은 거의 없다. 다만 C02 MASTER처럼 퍼즐 지시문에 어려운 어휘가 들어간 곳은 풀이를 방해할 수 있다("Group 2: the mouth, one step stronger; a flat line with a dot beneath it…").
- **스토리·정답 동일 정책:** 정답, 순서, id는 엔진 수준에서 고정된다(`DifficultyContent.apply`). 위반은 1건이다. **C11 M3 편지에서 ROOKIE만 미리가 사본을 숨긴 이유 두 줄이 빠져**, 레벨마다 이야기가 다르다(C11-3).
- **동일 문장 24%** 는 라벨과 선택지가 대부분이다. 선택지·카드 문구는 ROOKIE에 맞춘 것이 MASTER에도 그대로 나온다.

---

# E. 역사 검증

주장별 표(주장 | 레벨 | 위치 | 판정 1~5 | 근거·URL)는 **PART 5-B**에 있다. 요약:

| 판정 | 내용 |
|---|---|
| 고증 오류 P1 | **0건** |
| P2 | ① C08 유관순 "단독 주도" 서술(R/J ending, caseSummary). 한국민족문화대백과는 조인원·유중권·유중무 등과 함께 주도했다고 쓴다. 같은 Case의 J/M reveal은 이미 정확하다. ② C03 정약용을 1795년 화성 현장 책임자처럼 그림. 우리역사넷 기준 현장 총괄은 조심태다. ③ C12 김원봉: 서술은 사실이지만 월북 경력과 서훈 논란이 있어 사용자 결정이 필요하다 |
| P3 | C03 "two years and eight months"(자료마다 다름), C03 숫자 다이얼 자물쇠 시대착오, C03 "Even the water girl is in it"(의궤 창작 주장), C09 "1940년 정부 수반"(1926년 국무령이 먼저), C11 1948 초간본 31편, C08 매봉산 봉화는 전승, C02 "navy of Jeolla"(전라좌수영), C10 "He died in Japan"(사형을 완곡하게 씀), C08 "students in Seoul" |
| 훈민정음 시점 | 창제 1443년 음력 12월, 해례본·반포 1446년 음력 9월. Case 01 V4의 "1446년 여름 = 아직 아는 사람이 적은 시기" 설정과 맞는다 |
| 사실·허구 구분 | 매 Case의 "IN THIS MYSTERY" reveal이 창작 인물·사건을 밝힌다. 사실과 허구를 섞는 대사는 따로 찾지 못했다 |
| 민감 내용 | 왕비 시해, 이토 처단, 유관순 부모 사망, 윤봉길·윤동주 사망 모두 한 문장으로 담담하게 서술되고 무기·고문 묘사가 없다. 8세 기준으로 적절하다 |
| 미검증 | 국가유산청 사이트, 거북선 원문 사료, 거중기 세부 구조, 윤봉길 사형 집행 장소, 충칭 방송 언어. 일부 항목은 검색 요약으로만 확인했다(PART 5-B에 [읽음]/[검색] 구분) |
| 배경 공백 (고증 오류는 아님, 대상 아이에게 중요) | 1910년 일본의 한국 지배, "King's letters" = Hangeul, March First Movement, 이토 히로부미, 대원군, 1897년 왕 → 황제(C05 King → C06 Emperor) |

---

# F. 미션 인과관계

Case별 사건 목표와 단계별 인과표(Intro→M1→M2→M3→Final→Ending: 필요 이유, 이전 정보, 행동, 상태 변화, 다음 이유)는 **PART 2~4의 각 Case 첫머리**에 있다. 공통 패턴:

| 패턴 | Case |
|---|---|
| M1→M3는 사건 목표를 유지한다 | 11개 모두 |
| **Final이 사건과 끊긴다**(목표는 M3에서 이미 끝남, Final은 확인 퀴즈) | C02, C03, C05, C06, C10, C11, C12 |
| 범인·작성자가 추리가 아니라 자백으로 밝혀진다 | C03(옥분), C04(두리) |
| 우연한 발견이나 NPC가 단서를 가져다준다 | C04 M3(수레), C05 전체(한 상궁), C05 M3(지도) |
| 미해결로 끝난다 | C08 돈 준 낯선 사람, C09 범인 도주와 사본 행방, C10 시계를 바꾼 이유 |
| 인물 모순 | C09 이미 손님인데 김구가 처음 만난 듯 자기소개, C11 M1 윤동주가 미리 안다 |
| 삭제해도 사건에 영향 없는 미션 | C02 F, C08 M3(시즌 메타), C10 F |

### Case 간 연속성 (PART 5-A)

- **Case별 완결성 4.5/5, 시즌 전체 이야기 3/5.**
- 바로 앞 Case 증거를 부르는 recall 사슬(C02→C03→…→C12)은 생성 코드에 실제로 있다. 역사 순서도 맞다. Case 01을 가리키는 `c1`(3건)과 `e2`(2건)는 V4와 맞는다. Taek은 게임 텍스트에 한 번도 나오지 않는다.
- 문제:
  - **C12-1 (P1)** 분이 카드가 구판 문구다.
  - **e3/e4 오참조 (P2)**: C08, C12 ending과 C12 EvidenceLink.
  - **쪽지 6 vs 11 (P2)**.
  - **탐정이 1446→1945를 어떻게 오가는지 설명이 없다 (P2)**. 모든 Intro가 "You are a guest of…"로 시작하는데, 지키미들은 탐정을 "Detective"라고 부르며 안다.
  - **C04 "But why?"(지키미들이 왜 계속 쪽지를 쓰나)에 게임이 답하지 않는다 (P2)**.
  - **쪽지 보관 경로가 끊긴다 (P2)**: C02 "Seok's note goes into your notebook"이라고 해 놓고 그 쪽지가 나중에 상자에 있고, C07에서는 상자가 하얼빈에 있다.
  - **C02 Ending에서 분이 가족임이 미리 드러나** C08 반전이 약해진다 (P2).
  - **상자를 준 사람이 문서마다 다르다 (P2, 문서)**: V4는 어머니의 나무 상자, story_bible은 소라, season.plan은 "promised Sora".
- C12 M2 순서 퍼즐은 상자 뚜껑 문구만으로 답이 정해진다. 그래서 건너뛰거나 다시 해도 풀 수 있지만, 이전 Case 기억이 보상받지 못한다(P3).

---

# G. 개선 우선순위

## P1

| ID | 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|
| **C12-1** | `s5_ep12/case.plan.json` missions[1].play.timeline.cards[0](plan:419), levels.json 496-498 → `s5_ep12.g.dart:504` | 분이 카드 "The first note: the name of the letters." V4의 첫 편지는 "엄마, 고마워요" | 시즌 첫 Case에서 직접 쓴 편지가 피날레에서 다른 내용으로 나온다. 감정적 회수가 깨진다 | 카드를 "The first note: a letter to her mother."로 바꾸고 R/J/M 맞추기. 피날레 ending에 "엄마, 고마워요" 회수 한 줄 | S | C08·C12 e3→e4, story_bible |
| **C10-1** | `s5_ep10/case.plan.json` missions[1].play.story[1] "Haesu lays two more next to it: his old case and her own watch." + 그림 `old_watch.webp` | 윤봉길이 김구의 낡은 시계를 가져갔다고 하면서 그 시계가 탁자에 있다 | 핵심 증거끼리 어긋난다. 추리가 흐려지고, 탁자 위 시계로 답이 드러난다 | 탁자에는 김구 손의 시계와 해수 시계만 두고, 낡은 시계는 편지 설명으로만 남기기. 또는 "his old case"가 빈 시계 상자임을 그림과 문구로 분명히 | S~M(그림 확인 필요) | 없음 |
| **S-1** | 모든 Case `play.glossary` 값(한국어), `lib/widgets/glossary_text.dart:203,251-290`; 보호자 화면 | 단어 풀이와 보호자 리포트가 한국어 전용. 언어 설정이 없다 | 영어권 아이는 envoy, treaty, provisional 등을 확인할 수 없다 | **대상 결정이 먼저다.** 영어권이 맞다면 glossary에 영어 쉬운 정의(예: envoy = "a person sent to speak for a country")를 넣고 locale에 따라 표시 | M(데이터 11 Case + 위젯) | 모든 시즌(런던~뉴욕 포함) |

## P2 — 높은 효과 순

1. **Final 재설계 (7개)**: C02 DRAGON, C03 1796, C05 JAPAN, C06 FORCED, C10 1932, C11 KOREAN, C12 LIGHT. 앞 미션 증거로 답을 끌어내게 바꾼다. 예: C02는 석이 무엇을 했는지 증거 3개로 확인하고, C06은 쪽지·길·시각 증거로 이준의 문을 연다. 최소안은 타일 자물쇠에 미끼 글자를 넣고, 정답 단어를 지문에서 직접 빼는 것이다. 범위 M~L. 정답을 바꾸면 테스트·증거 id·recall이 영향을 받는다.
2. **증거 제시 Final의 2지선다 (C04, C07, C09)**: 질문마다 선택지를 3~4개로 늘리고 노트 요약에서 답 문장을 뺀다. evidence_talk에 힌트 버튼을 연결한다(`_talkFinal`). 범위 S~M.
3. **답 미리 노출 제거**: C02 M3(M1 "Twelve barrels"), C03 F("Autumn, 1796."), C04 M2(synopsis·hook·대사의 10), C10 F, C11 F. 범위 S.
4. **순서 지문 섞기**: C03 M1, C04 M3, C05 M2, C06 M2. 관계 문장은 유지하고 등장 순서만 섞는다. 범위 S. 연속 세 번 나오는 timeline 중 하나는 다른 엔진으로 바꾸는 것도 검토한다(M).
5. **역사 배경 한 줄**: 1910년 일본의 지배(C07 또는 C08 Intro), 이토 히로부미(C07), 대원군(C04), "King's letters = Hangeul"(C08에서 연결), March First Movement(C08), King → Emperor(C06), 임시정부·망명(C09). 범위 S.
6. **논리 공백**: C06 M3 "Knock as soon as the 6:40 walk has passed", C09 M1 "lit at…" 명시, C09 M3 경비 배제 문장, C07 M2 사건이 아침이었다는 정보, C02 M1 "Which thing let the rain in over the powder?". 범위 S.
7. **시즌 연속성**: e3→e4(C08, C12), 쪽지 수(C12), 탐정의 시간 이동 틀(프롤로그 한 줄), "But why?" 답(C08 또는 C12 한 줄), 쪽지 보관 경로(C02, C06, C07), C02 Ending 분이 가족 노출 완화, story_bible·season.plan 상자 기원을 V4로 맞추기. 범위 S~M.
8. **자백으로 끝나는 작성자 → 추리로**: C03 옥분, C04 두리, 그리고 C05 탐정의 능동성. 범위 M.
9. **UX**: order_sequence 화면 안내("Tap in order"), number_entry 오답 뒤 입력 유지, 퍼즐 화면에 편지 고정 보기, 길게 누르는 단어 풀이에 표시, 6칸 타일의 320폭 터치 크기 실측, dark_room_search·witness_compare에서 쓰이지 않는 오답 피드백 연결 또는 삭제, 엔진 대부분의 퍼즐 중간 상태 미저장. 범위 M. 다른 시즌에도 영향이 있다.
10. **역사 P2**: C08 "Gwan-sun helped lead them", C03 IN THIS MYSTERY에 "Jo Sim-tae ran the building; Jeong planned it" 한 줄, C12 김원봉 유지 여부 결정. 범위 S.
11. **C08 Final 다이얼 기호**를 단서 그림에 맞추기, **C08 M3 GYEONGSUN**을 고르기 방식으로 바꾸거나 짧은 이름 허용. 범위 S.
12. **C11-3**: ROOKIE 편지에 빠진 두 줄 복원(스토리 동일 정책). 범위 S.
13. **JUNIOR 차별화**: 추론 표현과 문맥 단서를 늘리기. 범위 L. 우선순위는 가장 낮다.

P3 목록은 각 PART 이슈 표에 있다(표현, 동명이인 Mr. Pyo·Mr. Pak, HANGUL 철자 피드백, 날짜 표기 등).

---

# 수정 필요 여부

| 구분 | Case | 이유 |
|---|---|---|
| **반드시 수정** | **C12, C10** | P1이 있다. C12는 시즌 피날레다 |
| 수정 필요 (Final·구조) | C02, C03, C05, C06 | Final이 사건과 무관하다. 애너그램, 답 노출 |
| 수정 필요 (중간) | C04, C09 | 2지선다 Final, 답 노출(C04), 논리 공백·미해결(C09) |
| 소폭 수정 | C07, C08, C11 | 흐름이 좋다. 배경 한 줄, 문구, 다이얼 기호, ROOKIE 누락 줄 정도 |
| 수정하지 않아도 됨 (미션 단위) | C03 M2·M3, C05 M3, C08 M1·M2, C09 M2, C10 M1, C11 M3, C12 M1·M3 | 단서, 단일 정답, 오답 설명이 모두 좋다 |

# 예상 작업량과 PART 분할

시즌 공통 결정이 먼저 필요하다. 결정에 따라 S-1 범위가 크게 달라진다.
- **(결정 1) 대상**: 영어권 어린이(이 조사의 전제)인가, 한국 어린이인가.
- **(결정 2) C12 김원봉** 유지 여부.
- **(결정 3) Final 정답 변경 허용 여부**. 허용하지 않으면 미끼 글자와 지문 수정 수준으로 줄인다.

| PART | 내용 | 대상 | 범위 | 예상 |
|---|---|---|---|---|
| **S1 — P1 데이터 수정** | C12 분이 카드, C10 탁자 시계, e3→e4(C08·C12), C12 쪽지 수, story_bible·season.plan 상자 기원 | C08, C10, C12 + 문서 | plan·levels·생성, 테스트 C08·C10·C12 | 작음 |
| **S2 — 답 노출·논리 공백·순서 지문** | G-P2 3·4·6항 | C02~C07, C09 | 문구만. 정답 불변 | 작음~중간 |
| **S3 — 역사·배경 한 줄** | G-P2 5·10항, 역사 P3 | C03, C04, C06~C09, C12 | 문구 + IN THIS MYSTERY. dossier 단서 문구 검사(`history_clue_not_shown`) 확인 필요 | 작음 |
| **S4 — Final 재설계** | G-P2 1·2항 | C02, C03, C04, C05, C06, C07, C09, C10, C11, C12 | 퍼즐·증거 연결. 정답 변경 시 테스트·recall 영향. 그림이 필요하면 사양부터 요청 | 큼. 2~3개 PART로 나누기(Act별) |
| **S5 — 시즌 연속성 틀** | G-P2 7·8항 | 프롤로그, C02, C04, C06~C08, C12 | 대사 몇 줄 + C03·C04 작성자 추리화 | 중간 |
| **S6 — UX 엔진** | G-P2 9항, evidence_talk 힌트, 타일 미끼 옵션 | 공통 엔진 | 위젯·엔진. 다른 시즌 회귀 테스트 필요 | 중간 |
| **S7 — 단어 풀이 언어 (S-1)** | 결정 1에 따름 | 전 Case(+ 다른 시즌) | 데이터 모델 + 위젯 | 중간~큼 |
| S8 — JUNIOR 차별화 | G-P2 13항 | 전 Case | levels.json | 큼, 후순위 |

권장 순서: **결정 1~3 → S1 → S2 + S3(같이) → S4 → S5 → S6 → S7 → S8**. S1~S3는 정답을 바꾸지 않아서 위험이 낮다. S4부터는 Case 01처럼 설계 문서를 먼저 쓰고 사용자 확인 후 구현하는 것을 권한다.

---

# PART 1 — 구조와 전체 데이터

## 1.1 데이터 출처 (현재 사용 중인 것)

| 데이터 | 파일 | 비고 |
|---|---|---|
| 사건·미션·퍼즐 원본 (ROOKIE 문구 = 기본 문구) | `content_pipeline/seasons/s5_seoul/cases/s5_epNN/case.plan.json` | `missions[].puzzle`(엔진·정답), `missions[].play`(표시 문구) |
| JUNIOR/MASTER 문구 | `…/s5_epNN/levels.json` `lines[]{rookie,junior,master}` | ROOKIE 문장을 키로 레벨 문장을 붙인다(`tool/season_gen/case_levels.dart:19-34`) |
| 게임이 실제로 읽는 것 | `lib/data/generated/s5_seoul/s5_epNN.g.dart`, `s5_epNN_levels.g.dart`, `s5_seoul_*.g.dart` | 레벨 패치 적용: `DifficultyContent.apply` (`lib/data/content/difficulty_content.dart`) — 텍스트만 바뀌고 id·정답·순서·그림은 바뀌지 않는다 |
| 사용되지 않는 데이터 | `case.plan.json`의 `learning.*`, `clueInputs[].note`, `puzzle.notes`, `planning/*.json`(기획 문서) | 화면에 나오지 않음 → 통계에서 제외. `history_dossier.json`은 생성기 검사(`history_clue_not_shown`)에만 쓰임 |

## 1.2 Case·미션·엔진 목록

| Case | 제목 (연도) | M1 | M2 | M3 | Final |
|---|---|---|---|---|---|
| 02 | The Turtle Ship Before Dawn (1592) | dark_room_search → `bucket` | syllable_compose → `거북선` | number_entry → `12` | letter_tile_lock → `DRAGON` |
| 03 | The Crane That Lifts Stones (1794–96) | timeline_board → start,lift,copy,note,fail | picture_choice → `gate_wheels` | order_sequence → tie,hook,turn,rise | combo_dial_lock → `1796` |
| 04 | The Palace of a Thousand Logs (1865–68) | lens_inspect_word → `GATES` | number_entry → `10` | timeline_board → burn,ruins,begin,coin,logs | evidence_talk → `rebuilt` |
| 05 | The Lights of Geoncheonggung (1887~) | scene_explore_choose → `belt` | timeline_board → lit,lamphouse,dark,gate,hall,back | number_entry → `37` | word_entry → `JAPAN` |
| 06 | The Emperor's Secret Letter (1907) | trace_deduction → `b` | order_sequence → library,well,west_gate,lane | number_entry(time) → `0650` | letter_tile_lock → `FORCED` |
| 07 | Two Reports from Harbin (1909) | record_mismatch → `called` | timeline_board → open,platform,noon,tea,write,print | word_entry → `KOREA` | evidence_talk → `for_korea` |
| 08 | The Fire on the Hill (1919) | witness_compare → `april_first` | order_sequence → fire,walk,full,march | word_entry → `GYEONGSUN` | combo_dial_lock → `311` |
| 09 | The Spy in the Shanghai Office (1919~) | number_entry(time) → `0100` | dark_room_search → `paper` | word_entry → `NAM GIHO` | evidence_talk → `protect` |
| 10 | The Two Watches (1932) | order_sequence → eat,swap,goodbye,alone | picture_choice → `new_watch` | letter_tile_lock → `DROP` | number_entry → `1932` |
| 11 | The Poet's Three Copies (1941~48) | lens_inspect_word → `WATER` | record_mismatch → `string` | number_entry → `319` | word_entry → `KOREAN` |
| 12 | The Day the Light Returned (1945) | scene_explore_choose → `one_strap_lock` | timeline_board → bun_i,seok,okbun,duri,gyeongsun,miri | number_entry → `815` | letter_tile_lock → `LIGHT` |

### 엔진 분포 (44개)

| 엔진 | 수 | 미션 |
|---|---|---|
| number_entry (숫자/시각 입력) | **8** | C02 M3 · C04 M2 · C05 M3 · C06 M3 · C09 M1 · C10 F · C11 M3 · C12 M3 |
| timeline_board (카드 시간순) | 5 | C03 M1 · C04 M3 · C05 M2 · C07 M2 · C12 M2 |
| word_entry (영어 단어 입력) | 5 | C05 F · C07 M3 · C08 M3 · C09 M3 · C11 F |
| order_sequence (순서 탭) | 4 | C03 M3 · C06 M2 · C08 M2 · C10 M1 |
| letter_tile_lock (글자 타일 자물쇠) | 4 | C02 F · C06 F · C10 M3 · C12 F |
| evidence_talk (증거 제시 대화) | 3 | C04 F · C07 F · C09 F |
| combo_dial_lock · picture_choice · dark_room_search · lens_inspect_word · scene_explore_choose · record_mismatch | 각 2 | — |
| syllable_compose · trace_deduction · witness_compare | 각 1 | C02 M2 · C06 M1 · C08 M1 |

**관찰:** 정답을 "코드로 입력"하는 엔진(숫자·단어·타일·다이얼)이 **19/44(43%)**, 그중 숫자 입력이 8개로 최다다. 순서 맞추기(timeline + order) 9개(20%)까지 합치면 28/44(64%)가 "입력/배열" 계열이다. 엔진 이름만으로 단순 퀴즈라고 판정하지는 않는다 — 실제 풀이 경로는 PART 2~4에서 미션마다 본다.

## 1.3 영어 텍스트 추출 기준

- **대상 줄**: `levels.json`의 `lines[]` = 화면에 나오는 모든 ROOKIE 줄과 그 JUNIOR/MASTER 판(Case 02~12 합계 **1,645줄 × 3레벨**). 같은 문장이 여러 곳에 나와도 Case당 1번만 셌다.
- **범주**: 각 줄이 `case.plan.json`에서 처음 나오는 경로로 분류 — 스토리(story·intro·transition·synopsis·caseSummary·hook·ending·letter·대화 줄·증인 답·discovery), 지시문(question·task·prompt·goal·guide·objectives), 선택지/카드(options·cards·finds·spots·witness 이름), 힌트, 오답 피드백, 성공 메시지, 단서 문장(장면 속 단서 줄·증거 설명), 라벨(제목·장소·증거 이름).
- **단어**: 정규식 `[A-Za-z]+(['’-][A-Za-z]+)*` (숫자·한글 제외, 고유명사 포함).
- **문장**: `. ! ?` 뒤 공백/따옴표/끝, 그리고 줄바꿈에서 분리. 단어 없는 조각 제외. 선택지·라벨처럼 마침표 없는 짧은 줄도 1문장으로 센다 → 평균 문장 길이가 실제 읽기보다 짧게 나온다. 그래서 **스토리만** 수치를 따로 냈다.
- **희귀어**: `wordfreq` 영어 Zipf < 3.2(대략 백만 단어당 1.6회 미만), Case 안에서 대문자로만 나오는 단어(고유명사) 제외. 역사 용어처럼 흔하지만 어려운 단어(envoy, treaty, provisional…)는 이 지표로 잡히지 않으므로 PART 2~4에서 사람이 판정한다.
- 스크립트: `tool/audit/seoul_text_stats.py` (실행: `python -I tool/audit/seoul_text_stats.py <repo> <outdir>`, `wordfreq` 필요).

## 1.4 난이도별 영어 통계 (실측)

### 시즌 합계 (Case 02~12)

| Level | 단어 | 문장 | 평균 문장(단어) | 15어 초과 | 20어 초과 | 스토리만 단어 |
|---|---|---|---|---|---|---|
| ROOKIE | 14,902 | 2,474 | 6.0 | 8 | 1 | 7,994 |
| JUNIOR | 16,093 | 2,414 | 6.7 | 31 | 1 | 8,801 |
| MASTER | 16,214 | 2,308 | 7.0 | 59 | 14 | 8,945 |

- MASTER는 ROOKIE보다 단어가 **평균 8.8%만 많다**(Case별 1.05~1.14배). 세 레벨의 **분량은 거의 같고**, 차이는 어휘와 문장 결합에서 난다.
- 세 레벨이 **완전히 같은 줄 401/1,645(24.4%)**. 같은 줄은 거의 전부 라벨(제목·장소·증거 이름)과 선택지/카드 문구이고, **스토리·힌트·오답 피드백·성공 메시지는 0~4줄만 같다** → 스토리 문장은 실제로 레벨별로 다시 썼다.
- 선택지·카드가 레벨 공통인 것은 "정답·순서 불변" 정책(`difficulty_content.dart`: options의 label은 바꿀 수 있으나 대부분 그대로 둠)과 일치. 8세에게 맞춘 문구가 MASTER에도 그대로 나온다는 뜻이기도 하다.

### Case별 · 레벨별 (전체 = 대사+UI+선택지 합산 / 스토리 = 이야기 줄만)

| Case | Level | 표시 줄 | 단어 | 문장 | 평균 문장 | 최장 | >15 | >20 | 고유어 | 평균 단어길이 | 스토리 단어 | 스토리 평균 | 스토리 최장 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 02 | R | 147 | 1391 | 223 | 6.2 | 14 | 0 | 0 | 319 | 3.91 | 713 | 6.9 | 14 |
| 02 | J | 147 | 1568 | 216 | 7.3 | 18 | 4 | 0 | 369 | 3.98 | 845 | 8.4 | 18 |
| 02 | M | 147 | 1585 | 200 | 7.9 | 23 | 12 | 4 | 424 | 4.17 | 867 | 9.4 | 23 |
| 03 | R | 127 | 1240 | 179 | 6.9 | 26 | 3 | 1 | 280 | 4.18 | 666 | 7.3 | 14 |
| 03 | J | 127 | 1318 | 177 | 7.4 | 26 | 5 | 1 | 307 | 4.16 | 706 | 7.9 | 16 |
| 03 | M | 127 | 1319 | 166 | 7.9 | 23 | 7 | 1 | 356 | 4.36 | 720 | 9 | 19 |
| 04 | R | 163 | 1497 | 245 | 6.1 | 15 | 0 | 0 | 318 | 3.89 | 800 | 6.2 | 14 |
| 04 | J | 163 | 1598 | 235 | 6.8 | 20 | 5 | 0 | 354 | 3.97 | 863 | 7.1 | 20 |
| 04 | M | 163 | 1571 | 222 | 7.1 | 25 | 5 | 1 | 406 | 4.15 | 850 | 7.5 | 25 |
| 05 | R | 154 | 1478 | 227 | 6.5 | 17 | 1 | 0 | 317 | 4.0 | 742 | 7.2 | 15 |
| 05 | J | 154 | 1570 | 222 | 7.1 | 20 | 3 | 0 | 374 | 4.11 | 818 | 8.3 | 20 |
| 05 | M | 154 | 1597 | 212 | 7.5 | 23 | 4 | 1 | 431 | 4.22 | 834 | 8.6 | 23 |
| 06 | R | 129 | 1202 | 196 | 6.1 | 14 | 0 | 0 | 313 | 4.02 | 667 | 7.1 | 14 |
| 06 | J | 129 | 1264 | 193 | 6.5 | 15 | 0 | 0 | 349 | 4.08 | 718 | 7.8 | 15 |
| 06 | M | 129 | 1280 | 181 | 7.1 | 26 | 3 | 2 | 395 | 4.15 | 721 | 8.5 | 26 |
| 07 | R | 157 | 1346 | 257 | 5.2 | 14 | 0 | 0 | 281 | 3.98 | 715 | 5.6 | 14 |
| 07 | J | 157 | 1450 | 254 | 5.7 | 14 | 0 | 0 | 315 | 4.0 | 793 | 6.4 | 14 |
| 07 | M | 157 | 1411 | 242 | 5.8 | 19 | 2 | 0 | 351 | 4.1 | 770 | 6.8 | 16 |
| 08 | R | 163 | 1451 | 241 | 6.0 | 18 | 3 | 0 | 362 | 4.13 | 809 | 6.4 | 14 |
| 08 | J | 163 | 1565 | 231 | 6.8 | 18 | 6 | 0 | 402 | 4.18 | 878 | 7.3 | 16 |
| 08 | M | 163 | 1639 | 226 | 7.3 | 22 | 8 | 2 | 477 | 4.32 | 929 | 7.9 | 17 |
| 09 | R | 167 | 1512 | 250 | 6.0 | 15 | 0 | 0 | 319 | 4.02 | 840 | 6.4 | 15 |
| 09 | J | 167 | 1638 | 248 | 6.6 | 15 | 0 | 0 | 356 | 4.06 | 939 | 7.2 | 15 |
| 09 | M | 167 | 1668 | 242 | 6.9 | 25 | 4 | 1 | 396 | 4.12 | 964 | 7.6 | 25 |
| 10 | R | 119 | 1125 | 204 | 5.5 | 16 | 1 | 0 | 282 | 4.08 | 672 | 6.2 | 15 |
| 10 | J | 119 | 1210 | 202 | 6.0 | 16 | 2 | 0 | 301 | 4.05 | 715 | 6.7 | 16 |
| 10 | M | 119 | 1226 | 198 | 6.2 | 29 | 4 | 1 | 344 | 4.13 | 731 | 7.0 | 29 |
| 11 | R | 158 | 1362 | 224 | 6.1 | 14 | 0 | 0 | 317 | 4.01 | 685 | 7.1 | 14 |
| 11 | J | 158 | 1504 | 217 | 6.9 | 16 | 5 | 0 | 364 | 4.07 | 780 | 8.4 | 16 |
| 11 | M | 158 | 1513 | 207 | 7.3 | 21 | 9 | 1 | 424 | 4.25 | 807 | 9.0 | 21 |
| 12 | R | 161 | 1298 | 228 | 5.7 | 13 | 0 | 0 | 304 | 4.02 | 685 | 6.7 | 12 |
| 12 | J | 161 | 1408 | 219 | 6.4 | 18 | 1 | 0 | 354 | 4.07 | 746 | 7.6 | 18 |
| 12 | M | 161 | 1405 | 212 | 6.6 | 20 | 1 | 0 | 415 | 4.25 | 752 | 7.8 | 20 |

### 레벨 간 동일 문장 비율

| Case | 표시 줄 | R=J=M 동일 | R=J | J=M | 범주별 동일(동일/전체) |
|---|---|---|---|---|---|
| 02 | 147 | 34 (23%) | 37 (25%) | 34 (23%) | {'label': '20/20', 'story': '0/59', 'option': '13/13', 'feedback': '0/13', 'instruction': '1/13', 'hint': '0/8', 'success': '0/8', 'clue_text': '0/13'} |
| 03 | 127 | 28 (22%) | 30 (23%) | 28 (22%) | {'label': '13/13', 'story': '0/53', 'option': '15/24', 'instruction': '0/10', 'hint': '0/8', 'success': '0/4', 'feedback': '0/10', 'clue_text': '0/5'} |
| 04 | 163 | 26 (15%) | 29 (17%) | 26 (15%) | {'label': '14/15', 'story': '0/70', 'instruction': '2/23', 'hint': '0/8', 'success': '0/4', 'feedback': '0/13', 'clue_text': '0/10', 'option': '10/20'} |
| 05 | 154 | 42 (27%) | 45 (29%) | 44 (28%) | {'label': '15/16', 'story': '0/58', 'option': '24/28', 'feedback': '0/14', 'instruction': '1/15', 'hint': '0/8', 'success': '0/4', 'clue_text': '2/11'} |
| 06 | 129 | 37 (28%) | 40 (31%) | 37 (28%) | {'label': '14/15', 'story': '1/52', 'option': '19/19', 'feedback': '0/13', 'instruction': '0/11', 'hint': '0/8', 'success': '0/4', 'clue_text': '3/7'} |
| 07 | 157 | 46 (29%) | 52 (33%) | 48 (30%) | {'label': '13/13', 'story': '0/64', 'option': '26/30', 'instruction': '6/21', 'hint': '0/8', 'success': '0/4', 'feedback': '0/11', 'clue_text': '1/6'} |
| 08 | 163 | 34 (20%) | 35 (21%) | 34 (20%) | {'label': '15/15', 'story': '1/70', 'option': '14/17', 'feedback': '0/16', 'instruction': '2/24', 'hint': '0/8', 'success': '0/8', 'clue_text': '2/5'} |
| 09 | 167 | 39 (23%) | 41 (24%) | 40 (23%) | {'label': '22/22', 'story': '4/74', 'instruction': '2/20', 'hint': '0/8', 'success': '0/8', 'feedback': '0/15', 'clue_text': '3/12', 'option': '8/8'} |
| 10 | 119 | 32 (26%) | 33 (27%) | 32 (26%) | {'label': '15/15', 'story': '1/54', 'option': '15/15', 'instruction': '0/11', 'hint': '0/8', 'success': '0/4', 'feedback': '0/8', 'clue_text': '1/4'} |
| 11 | 158 | 35 (22%) | 41 (25%) | 40 (25%) | {'label': '15/17', 'story': '0/55', 'instruction': '3/20', 'hint': '0/8', 'success': '0/4', 'feedback': '0/17', 'clue_text': '0/9', 'option': '17/28'} |
| 12 | 161 | 48 (29%) | 48 (29%) | 49 (30%) | {'label': '16/17', 'story': '2/59', 'option': '24/35', 'feedback': '0/12', 'instruction': '1/16', 'hint': '0/8', 'success': '2/4', 'clue_text': '3/10'} |

### Case별 최장 문장 (전체 범주)


- C02 R (14어): "Knives and spikes stand on the roof, with a narrow path for my men.
- C02 J (18어): On the twelfth day of the fourth month of 1592, its cannons were tested, as his war diary records.
- C02 M (23어): Group 2: the mouth, one step stronger; a flat line with a dot beneath it, and the back of the tongue at the bottom.
- C03 R (26어): a drawing of a wooden frame like a gate, pulleys under the top beam and more pulleys below them, and a big wheel on each side
- C03 J (26어): a drawing of a wooden frame like a gate, with pulleys under the top beam, more pulleys below them, and a big wheel on each side
- C03 M (23어): a drawing of a gate-like wooden frame: pulleys under the top beam, further pulleys below them, and a big wheel on each side
- C04 R (15어): One new cut turned 나 into 다: a palace log now looks like a log to sell.
- C04 J (20어): Pyo, a timber dealer, had a new line cut on ten palace logs, so 나 became 다: logs that may be sold.
- C04 M (25어): The people paid dearly for it: they were made to give money, a new coin drove prices up, and many were summoned to hard work.
- C05 R (17어): a big iron wheel with a long leather belt and a muddy hand mark on the belt
- C05 J (20어): Strangers darkened the lamps and measured the path to the Queen's door, but Court Lady Han found their map first.
- C05 M (23어): Strangers plunged the lamps into darkness and measured the route to the Queen's door; Court Lady Han found their map before anyone else.
- C06 R (14어): Japan used the envoys as an excuse to force the Emperor off his throne.
- C06 J (15어): In 1907 three envoys went to The Hague to tell the world the 1905 treaty was forced.
- C06 M (26어): Bongsu's note pointed the way to the Emperor's letter in the old pine; it slipped out of the palace unseen and reached the envoy Yi Jun.
- C07 R (14어): Pak was on the platform: An Jung-geun called out, "Korea, hurrah!", not for money.
- C07 J (14어): That morning, before the noon train, I was on the platform with the bags.
- C07 M (19어): The Evening Sheet's writer came on the noon train and set down a traveller's tale, not what he witnessed.
- C08 R (18어): a girl of sixteen in a white jeogori and a black skirt, her hair in one long braid
- C08 J (18어): a sixteen-year-old girl in a white jeogori and a black skirt, with her hair in one long braid
- C08 M (22어): a boy of ten in a much-patched cotton jacket, with straw sandals on his feet and a cloth bag at his side
- C09 R (15어): The Provisional Government began in Shanghai in April 1919, and Kim Gu was its police chief.
- C09 J (15어): The note is in Hangeul, and there is a small water drop in its corner.
- C09 M (25어): The Provisional Government was founded in Shanghai in April 1919, with Kim Gu as its police chief; his police guarded it and kept watch for spies.
- C10 R (16어): a worn silver pocket watch with many small scratches on its case and a thin chain
- C10 J (16어): a worn silver pocket watch with many small scratches on its case and a thin chain
- C10 M (29어): On the morning of 29 April 1932, Yun Bong-gil and Kim Gu shared breakfast and then exchanged watches: Yun left his new watch with Kim Gu and took the old one.
- C11 R (14어): It is a folded card in the King's letters, with a small blue drop.
- C11 J (16어): It is a folded card written in the King's letters, marked with a small blue drop.
- C11 M (21어): His friend's family kept the copy hidden beneath their floor, and in 1948 it became a book: Sky, Wind, Stars and Poems.
- C12 R (13어): a travel trunk with one leather strap and a wooden peg, no lock
- C12 J (18어): The Allies won the war, and many Koreans, at home and far away, also worked for this day.
- C12 M (20어): The Allies won the war, yet many Koreans, both at home and far away, had also laboured for this day.

### 희귀어 (wordfreq 기준, 상위)


- C02 R: planks×2, drips×1
- C02 J: drips×1, planks×1
- C02 M: brimming×3, smudged×2, seeped×2, planks×2, hurries×1, breathlessly×1, reeks×1, trickles×1, ajar×1, legible×1, tucks×1, hasten×1, pales×1, paces×1, bristle×1, clangs×1, crowning×1
- C03 R: pulleys×13, dials×2, geojunggi×2, rebuilds×1, pulley×1
- C03 J: pulleys×13, dials×2, geojunggi×2, pulley×1
- C03 M: pulleys×12, pulley×3, dials×2, geojunggi×2, frowns×1, rebuilds×1, slung×1, hauls×1, shoves×1, precedes×1, taut×1, doffs×1, concedes×1, chuckles×1
- C04 R: 
- C04 J: 
- C04 M: darkened×2, fastened×1, disguising×1, rumbles×1
- C05 R: knotted×1
- C05 J: flicker×3, handprint×2, knotted×2, darkened×1
- C05 M: flicker×4, knotted×2, crept×1, handprint×1, tamper×1, murmurs×1, idly×1, glimpsed×1
- C06 R: envoys×5, knelt×2, errand×1
- C06 J: envoys×5, knelt×2, errand×1
- C06 M: envoys×5, knelt×2, errand×1, glimpsed×1, ushers×1, jumbled×1, fastened×1, tucks×1
- C07 R: hurrah×8, errand×1, envoys×1
- C07 J: hurrah×8, errand×1, envoys×1
- C07 M: hurrah×8, errand×1, mismatched×1, sips×1, composes×1, sprang×1, envoys×1, befell×1
- C08 R: messengers×7, dials×2, teacup×1, jeogori×1, patched×1, forties×1, blushes×1
- C08 J: messengers×8, faraway×2, dials×2, teacup×1, jeogori×1, patched×1, forties×1, scribbled×1
- C08 M: messengers×9, dials×2, bustling×1, teacup×1, jeogori×1, much-patched×1, forties×1, slung×1, jumbled×1, schoolmates×1, decorates×1, murmurs×1, hilltop×1
- C09 R: sill×5, hurries×1, inked×1, frowns×1, bookshelf×1, copier×1
- C09 J: sill×5, frowns×1, bookshelf×1
- C09 M: sill×5, hurries×2, reappears×1, lingered×1, unlocks×1, combed×1, frowns×1, hushed×1, bookshelf×1, broad-shouldered×1, secures×1
- C10 R: wristwatch×1
- C10 J: wristwatch×1
- C10 M: wristwatch×1, gazes×1
- C11 R: hand-sewn×2
- C11 J: hand-sewn×2, hurries×1
- C11 M: hand-sewn×2, inspecting×2, askew×1, peeks×1, murmurs×1, gleam×1, cradles×1, composes×1, entrusts×1, longed×1
- C12 R: gwangbok×4, gwang×3, hums×1, bookshelf×1
- C12 J: gwangbok×4, gwang×3, bookshelf×1
- C12 M: gwangbok×4, gwang×3, laboured×3, precedes×2, sweltering×1, conceals×1, hums×1, anxiously×1, bustling×1, bookshelf×1, inscribes×1, overflows×1
### 레벨별 단어 풀이(glossary) 수와 언어

| Case | 기본(ROOKIE, 모든 레벨 공유) | JUNIOR 추가 | MASTER 추가 |
|---|---|---|---|
| 02 | 12 (gunpowder, barrel, barrels, quartermaster, straw, planks…) | 5 | 10 |
| 03 | 10 (fortress, pulley, pulleys, beam, foreman, carpenter…) | 5 | 10 |
| 04 | 9 (timber, logs, apprentice, dealer, ruins, rebuilding…) | 5 | 10 |
| 05 | 10 (stranger, belt, coal, knot, measure, minister…) | 6 | 8 |
| 06 | 14 (envoy, treaty, watcher, forced, conference, hollow…) | 5 | 8 |
| 07 | 9 (report, platform, hurrah, traveller, printed, independence…) | 5 | 8 |
| 08 | 12 (independence, messenger, march, sign, elders, dusk…) | 4 | 7 |
| 09 | 11 (government, provisional, exile, spy, clerk, sill…) | 4 | 8 |
| 10 | 12 (swap, scratches, worn, smooth, strap, ceremony…) | 3 | 6 |
| 11 | 14 (copy, poem, dictionary, spine, string, subject…) | 5 | 7 |
| 12 | 11 (trunk, strap, brass, surrendered, allies, government…) | 5 | 7 |

**단어 풀이의 뜻은 모두 한국어다**(예: `gunpowder: 화약`, `envoy`류 포함). 한국어 화자를 전제로 만든 장치라 **영어권 어린이에게는 단어 풀이가 사실상 없다.** UI 동작과 영향은 PART 5(UX)에서 다룬다.

---

# PART 2 — Case 02~05 정밀 조사

## PART 2 — Seoul Case 02–05 플레이 가능성·인과·영어 감사

- 기준 플레이어: 한글을 못 읽는 8–12세 영어권 아이(ROOKIE 8 / JUNIOR 10 / MASTER 12).
- 방법: **전부 코드 분석**(앱·테스트 실행 안 함). case.plan.json, levels.json, generated `s5_ep0N.g.dart`, 엔진 코드(syllable_board.dart, syllable_rules.dart, letter_lock.dart, timeline_rules.dart, case_talk.dart, final_mission_screen.dart, question_widgets.dart)와 텍스트 덤프(seoul_text_dump.md)를 대조. 그림은 C03 설계도 3장·C04 목재 마당 1장만 직접 확인.
- plan ↔ generated 대조: 16개 퍼즐 모두 정답·유형·codeLength가 같음. C02 M2 syllables(sounds 6개, Group 1 given)와 C04 Final talk(`choices` 2개씩)는 generated에서 직접 확인. **차이 없음**(대사 전체를 글자 단위로 비교하지는 않음).
- 공통 엔진 사실(코드 분석):
  - `letterLock` 칸 수 = 타일 수(`List.filled(widget.mission.options.length…)`, letter_lock.dart:44). 그래서 타일에 **정답 글자만** 있으면 애너그램이 됨.
  - `wordInput`(영어)은 TextField 대문자 입력이라 한글을 칠 필요가 없음. C02 M2의 한글 정답 거북선은 SyllableBoard에서 **탭으로 조립**하므로 한글 키보드가 필요 없음.
  - evidence_talk 제시는 `choices`가 2개뿐이고, 두 번 틀리면 `tell`이 정답 카드를 밝힘(case_talk.dart:647). 무작위 탭으로도 반드시 통과함.
  - timeline: anchor 카드는 처음부터 고정되고, 나머지 카드만 배열함.

---

### Case 02 — The Turtle Ship Before Dawn (1592, 여수)

**사건 목표(한 문장):** 새벽 대포 시험 전에 사라진 화약 12통을 찾아, 젖지 않은 채로 시험에 쓰이게 한다.
**목표 유지 평가:** M1–M3까지는 목표가 잘 유지됨(사라짐 → 쪽지 → 거북선 → 12통 확인). Final은 "배 앞머리가 무엇인가"라는 **사건과 무관한 독해 문제**로 바뀜. 화약 문제는 M3에서 이미 끝남.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 시험 날·장소·인물 설정 | — | 읽기 | 새벽 종이 울림 | 창고에 문제가 생김 |
| M1 | 화약이 왜 위험한지, 무엇이 남았는지 확인 | 이순신 "Wet powder will not fire" | 보고서 3줄로 창고에서 3물건 찾기 → 위험물 고르기 | 비가 지붕으로 샘. 물방울 쪽지 확보 | 쪽지가 King's letters로 쓰여 있고 번짐 |
| M2 | 쪽지 해독 = 화약 행방 | 쪽지 + Case 01 Sora's board | 세 글자 조립(거북선) | 행방: 거북선 | 항구로 감 |
| M3 | 화약이 전부 무사한지 | 행방 | 석의 말로 4×3 계산 → 12 | 12통 모두 마름(해시 Ham의 12와 일치) | 이순신이 배에 탐 |
| Final | (약함) 배가 준비됐음을 보임 | M3 "준비 완료"뿐. 증거를 정답에 쓰지 않음 | 이순신 말에서 "dragon" 철자 맞추기 | 시험 진행 | — |
| Ending | 역사 연결(4.12 시험, 4.13 부산, 옥포) | — | 읽기 | 석의 물방울 = 분이의 물방울 | 다음 Case 떡밥 |

- 제거 가능한 미션: **Final**(사건 해결에 기여하지 않음).
- 동기 약점: 석은 화약을 옮기고 **함이 못 읽는 글자**로 쪽지를 남김. M2에서 함 본인이 "I cannot read the King's letters"라고 말함. 쪽지가 원래 독자에게 쓸모없는 셈임. 아이에게 "왜 그냥 말하지 않았지?"라는 의문이 남음.
- Ending은 원래 문제(화약·시험)를 해결함. 자연스러움.

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출(모르는 아이) | 외부 지식 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 수색+선택(bucket) | 관찰 및 단서 찾기 / 단순 선택 | Ham 보고서(under/next to/on), 이순신 "Wet powder will not fire", 그림 속 위치 | 전치사로 3물건을 찾고, "무엇이 화약을 망치나?"에서 비 = bucket | 없음 | **wet straw도 젖어 있어** "망칠 수 있다"고 볼 여지가 있음. 정답 근거는 "지붕으로 들어온 비"라는 해석임 | 오답 피드백이 이유를 설명함(straw는 출구 표시, paper는 지붕 아님). 힌트 2가 "What came through the roof?"로 정답을 짚어 줌 | 그림 탭. 명확함 | R 가능. J/M 문제없음 | P2 |
| M2 음절 조립(거북선) | 조합 및 구성 / 암호 해독 | Sora's board(ㄱㄴㅁㅅ 신체 부위, ㄴ+1=ㄷ, 모음 위치), 그룹 설명 3줄, Group 1(거) 예시 | G2: mouth+1 → 선택지 [ㄱㄴㅁㅂㅅㅈ]에서 ㅁ과 닮은 ㅂ, flat+dot under=ㅜ, 받침 ㄱ. G3: teeth=ㅅ, standing+dot left=ㅓ, 받침 ㄴ | 한글 지식은 필요 없음. 단 **ㅂ의 모양은 어디에도 나오지 않음**("ㅁ+1획"을 모양 유사로 추론해야 함) | 단일 정답. 조합 수가 적어(초성 6 × 모음 6 × 받침 3) 시행착오로도 풀 수 있음 | 거묵선·거북서·가북선·거북전 피드백이 정확함. 힌트 2개 유효 | 탭(초성 → 선 → 점 → 받침). 키보드 없음. 단계가 4개라 8세에게는 다소 많음 | R: "Flat vowels go under" 추상적. J/M 적정 | P2 |
| M3 숫자(12) | 논리 추리(간단 계산) / 영어 어휘 | 석의 4줄(4 barrels each time, three times) | 4×3=12 | 곱셈(8세 가능) | 단일. 단 **M1 첫 줄 "Twelve barrels… are gone!"으로 이미 12를 앎**(plan:90) → 계산 없이 기억으로 입력 가능 | 04/03/07 오답 피드백 좋음 | 2자리 숫자 입력 | 모두 적정 | P2 |
| Final 글자 타일(DRAGON) | 영어 어휘 퀴즈 / 단순 선택 | 이순신 4번째 줄 "At the front is a dragon's head" | 문장 속 단어를 그대로 철자함 | 없음 | 타일 6개 = D,R,A,G,O,N **정답 글자만**(plan:552). 애너그램이라 읽지 않고도 풀 수 있음 | 힌트 2가 사실상 정답("It is not a turtle. Spell the animal he names.") | 드래그/탭 | 모두 쉬움(학습 확인) | P2(구조) |

**영어 난이도 메모**
- 레벨 차이: 스토리는 59줄 전부 다름. 그러나 R↔J 차이는 대부분 단어 하나 추가 수준임. 예: "Find the two numbers in Seok's words." / "Look for the two numbers in Seok's words." 실제 구조 차이는 J/M의 M2 letter(그룹 설명 포함 여부)와 M 어휘("brimming", "reeks of damp timber", "hasten", "Tally")에서만 뚜렷함.
- R 어려운 어휘·설명 없는 용어: "gums", "Flat vowels go under. Standing vowels go on the right."(무엇의 아래/오른쪽인지 설명 없음), "Jeolla", "Okpo", "war diary"(설명 없이 1회), "moon calendar"는 설명이 있어 OK. J의 "Quartermaster"는 설명 없음.
- M "Whose head stands at the front" 문제 없음.

**이슈 목록**

| ID | 심각도 | 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C02-1 | P2(구조) | s5_ep02 final.puzzle(plan:552), final.play.letter(plan:621) | Final이 사건 해결이 아님. 정답 단어가 지문에 그대로 있고 타일은 정답 글자 6개뿐 | 탐정 결말 없이 받아쓰기로 끝남. 무작위로 맞춰도 됨 | Final을 "시험 직전 화약통 배치/석의 쪽지 확인" 같은 사건 마무리로 바꾸거나, 최소한 미끼 타일(T,U,R,L,E 등)을 넣어 turtle과 구별하게 함 | M | C03·C05 Final도 같은 패턴 |
| C02-2 | P2 | m3 answerSpec 12 / m1 play.story(plan:90) | 정답 12가 M1 첫 장면에 이미 나옴 | 계산 없이 기억만으로 통과 | M1 대사에서 숫자를 빼거나("All the barrels are gone"), M3를 "12와 일치하는지 대조" 판단 문제로 바꿈 | S | — |
| C02-3 | P2 | m2 play.letter(plan:369) vs Case 01 V4 e2 "ㅁ the lips" | Case 01 V4는 ㅁ = **lips**, 모든 글자 = "copy the mouth"로 가르침. Case 02는 ㅁ = **the mouth**로 부름. recall miss는 "lesson board"인데 실제 증거 이름은 "The Sound Board" | Case 01 용어를 기억한 아이가 "the mouth"가 무엇인지 헷갈리고, 노트에서 "lesson board"를 찾지 못할 수 있음 | Case 02 board를 "ㅁ = the lips"로 통일. miss를 "Look for the Sound Board."로 | S | C04 recall miss "Sora's board"도 이름 통일 필요 |
| C02-4 | P2 | m2 syllables.sounds [ㄱㄴㅁㅂㅅㅈ] | ㅂ의 모양이 어디에도 제시되지 않음. "mouth + 1 line"을 ㅂ 모양에서 추론해야 함. ㅂ은 ㅁ에 "한 줄 더"로 보이지 않음 | 8세는 ㅁ을 그대로 고르기 쉬움(피드백은 있음) | board에 "ㅁ + 1 line = ㅂ" 예시를 넣거나(ㄴ→ㄷ처럼), 초성 버튼에 그림 힌트를 붙임 | S | C04도 같은 가획 규칙 사용 |
| C02-5 | P2 | m1 answerSpec options / play.question | "Which thing can ruin the powder?"에 wet straw도 젖은 물건이라 그럴듯함 | 첫 시도 오답 가능(피드백 있음) | 질문을 "Which thing shows rain came in over the powder?"로 | S | — |
| C02-6 | P2 | m3 play.letter·talk / m2 story "I cannot read the King's letters" | 석의 동기: 함이 못 읽는 글자로 쪽지를 남김. 소리 내 알리지 않은 이유가 없음 | 개연성에 의문 | 석 대사 1줄 추가: "Ham was asleep… my grandmother said: write it, so it is not lost" 등 | S | 시즌 물방울 가문 설정 전반 |
| C02-7 | P3 | m1 discovery.detail "Bun-i, the girl who carried water, wrote the first note" | Case 01 V4에서 분이는 "물 긷는 아이"로 소개되지 않음(우물가·양동이 그림만). 분이가 쓴 것은 엄마에게 보낸 **편지**이지 "note"가 아님 | 작은 불일치 | "Bun-i wrote her first letter in 1446, signed with a water drop." | S | C03·C04 discovery |
| C02-8 | P3 | final clueInputs s5_ep01_c1 use: answerDerivation | 실제로는 정답 도출에 쓰이지 않음(엔딩 언급뿐) | 없음(메타 데이터) | use를 textMention으로 | S | — |

**clueInputs 타 Case 참조:** s5_ep01_c1(물방울 표식)은 V4 c1 "Bun-i's Mark: a water drop"과 **일치**함. s5_ep01_e2(recall)는 V4 e2 "The Sound Board"로 존재하지만 **용어가 불일치**함(C02-3).

**점수(5점 만점)**
- 풀이 가능성 4: 모든 미션이 화면 단서로 풀림. M2는 ㅂ 추론이 약간 막힐 수 있으나 피드백이 받쳐 줌.
- 퍼즐 다양성 4: 수색 / 음절 조립 / 계산 / 타일로 서로 다름. 다만 Final이 약함.
- 영어 난이도 3.5: R 문장은 짧음(평균 6.2어). R↔J 차이가 얕음.
- 역사 4.5: 1592.4.12 지자·현자포 시험(난중일기), 4.13 부산, 5월 옥포, 용머리 포구 모두 맞음. 명백한 오류 없음.
- 개연성 3: M1→M3 흐름은 좋음. 석의 쪽지 동기가 약하고 Final이 사건과 단절됨.
- UX·힌트 4: 오답 피드백이 구체적임. Final 힌트는 정답을 그대로 줌.
- **종합 3.8**

---

### Case 03 — The Crane That Lifts Stones (1795–96, 수원 화성)

**사건 목표(plan.goal):** "Find out if the lifting machine is broken, and who wrote the warning."
**목표 유지 평가:** "고장인가 변경인가"는 M1–M3에서 잘 풀림. **"누가 경고문을 썼나"는 아이가 추리하지 않음.** 엔딩에서 옥분이 "I wrote the note"라고 자백함(plan:527). Final(기록함 연도)은 사건과 무관함.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 거중기·곽 반장의 "고장" 주장 | — | 읽기 | 갈등 제시 | 일지를 확인 |
| M1 | 고장 vs 변경 판단 | 쪽지 "The drawing is different" | 일지를 시간순 배열(+recall: 1592 물방울) | "변경되었음" | 정약용: 어느 도면이 내 것인가 |
| M2 | 올바른 도면 찾기 | 복사 도면 단서 | 설명과 그림 3장 대조 | 정 본인의 도면 확인. 현장 기계는 틀린 복사본 | 재조립 |
| M3 | 돌 들어 올리기(사건 해결) | 올바른 도면 | 4단계 순서 탭 | 돌이 올라감. 곽이 "never broken" 인정 | (1796로 시간 점프) |
| Final | (약함) 완공 연도 | M1 "1794" | 4자리 다이얼 1796 | 기록함이 열림 | 물 긷는 소녀 언급 |
| Ending | 역사(1796.9 완공, 의궤 임금 기록) + 옥분 자백 | — | 읽기 | 쪽지 작성자 = 옥분(자백) | 다음 Case |

- 제거 가능: **Final**(사건은 M3에서 끝남). 갑작스러운 1년 점프와 새 목표("record chest")가 나옴.
- 자기 해결 엔딩: 작성자 문제는 아이 행동 없이 대사로 풀림. M3 transition의 "a girl with a water bucket watches and smiles"가 유일한 복선임.

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서 | 정답 도출 | 외부 지식 | 복수 정답 | 힌트/오답 | 조작 | R/J/M | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 타임라인(start,lift,copy,note,fail) | 순서 배열 / 관찰 | 곽의 일지 5줄이 **이미 시간순**임(plan:98). 앞뒤 카드 고정(1794, THIS MORNING). RICE는 버림 | 일지 순서 그대로 가운데 3장 배치 | 없음 | 단일(until/after) | orderFeedback 1개("what came after the carpenter's work?"). 힌트 2개 | 드래그 카드 | until/after를 몰라도 줄 순서만 따라 하면 됨. 문법 학습 목표가 실질적으로 시험되지 않음 | P2 |
| M2 그림 선택(gate_wheels) | 증거 비교 / 관찰 | 정약용 말 4줄(gate 모양, 위아래 도르래, 양쪽 바퀴). 그림 3장(이름 숨김) | 기둥 1개 그림은 탈락, 바퀴 없는 그림은 탈락 → 바퀴 2개 그림 | 없음 | 단일. 그림을 직접 확인함: 바퀴 유무, 아래 도르래 유무가 분명함 | 오답 피드백 2개 모두 이유를 설명함 | 탭 | 적정 | OK |
| M3 순서(tie,hook,turn,rise) | 순서 배열 / 영어(before/after) | 4줄 규칙. 미끼 2개는 "Nobody pulls/pushes"로 명시적 배제 | before·after를 풀어 tie→hook→turn→rise | 없음 | 단일 | 오답 2종 피드백 + order 피드백 | 탭 순서 | M3는 문장 순서와 실행 순서가 달라 실제 독해가 필요함(좋음) | OK |
| Final 다이얼(1796) | 단순 계산 / 역사 지식 | 서기 말: 1794년 1월 + 2년 8개월. **그러나 Final story 첫 줄이 "Autumn, 1796."**(plan:476) | 첫 줄을 보고 1796 입력 | 없음 | 단일 | 1794/1795/1797 피드백 좋음 | 4개 다이얼 ±1 | 계산 퍼즐로 의도했으나 지문에 정답이 노출됨 | P2 |

**영어 난이도 메모**
- R 최장 26어는 그림 altText("a drawing of a wooden frame like a gate, pulleys under…")임. 스크린리더/설명용이라 화면 노출 여부는 코드 분석으로 미확인(hideOptionNames=true라서 이름은 숨김).
- 어휘: pulley, beam, foreman, carpenter, clerk, "work log"(C04의 timber "logs"와 동음이의라 시즌 내 혼동 가능), "Count on two years"(수학 관용 표현)는 8세에게 낯섦.
- 설명 없는 역사 용어: geojunggi(intro에서 1회 설명 OK), Hwaseong Fortress(OK), Suwon.
- 레벨 차이: R/J/M 구조가 거의 같고 어휘만 바뀜("began/started/commenced", "pushes/shoves"). J가 R보다 실질적으로 어렵지 않음.

**이슈 목록**

| ID | 심각도 | 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C03-1 | P2 | final.play.story[0] "Autumn, 1796."(plan:476) vs answer 1796(plan:432) | 정답이 계산 전에 지문에 나옴 | 퍼즐이 무의미함 | 첫 줄을 "Autumn. The last stone is on the wall." 등으로 바꿔 연도를 뺌 | S | — |
| C03-2 | P2(구조) | final 전체 | Final이 사건(기계·경고문 작성자)과 무관한 연도 자물쇠임 | 탐정 결말 없음 | Final에서 "경고문 작성자 찾기"를 추리로 만듦(물방울 recall + 물동이 + 현장에 있던 사람). 연도는 엔딩 사실로 이동 | M | C02·C05와 같은 패턴 |
| C03-3 | P2 | ending "I carry water here. I wrote the note."(plan:527), goal "who wrote the warning" | 목표 절반이 자백으로 자기 해결됨 | 추리 성취감 없음 | 위 C03-2와 함께 해결 | M | C04도 엔딩 자백(Duri) |
| C03-4 | P2 | m1 play.letter(plan:98) | 일지가 이미 시간순이라 until/after 독해가 시험되지 않음 | 쉬움(학습 목표 미달) | 일지 문장 순서를 섞음(M3처럼). 예: "This morning… / The note was on the rope after… / … until the new carpenter came." | S | C04 M3·C05 M2도 동일 |
| C03-5 | P3 | intro "a guest of Jeong Yak-yong at Hwaseong"(1795 봄) | 역사적으로 정약용은 1795년 화성 공사 현장 책임자가 아니었음(거중기 설계는 1792). 허구 범위로 볼 수 있음 | 없음 | notes에 허구임을 명시. 정밀 검증은 역사 에이전트 몫 | S | — |
| C03-6 | P3 | final transition "Even the water girl is in it" | 의궤에 물 긷는 소녀가 실렸다는 것은 근거 불명확(추정) | 없음 | "Even water carriers are paid in it"처럼 일반화 | S | — |

**clueInputs 타 Case 참조:** s5_ep02_e1(1592 물방울 쪽지) recall은 C02 m1 evidence와 **일치**함. Case 01 직접 참조 없음.

**점수**
- 풀이 가능성 4.5: 모두 풀림. 막힐 곳이 거의 없음.
- 퍼즐 다양성 3.5: 타임라인 / 그림 비교 / 순서 / 다이얼. 순서 배열 2개가 겹침.
- 영어 난이도 3.5: R 짧음. 레벨 차이 얕음.
- 역사 4.5: 1794.1 착공, 1796.9 완공, 거중기, 의궤 임금 기록 모두 맞음.
- 개연성 3: M1→M3는 깔끔함. 작성자는 자백, Final은 시간 점프 epilogue.
- UX·힌트 4: 피드백 충실. Final 정답 노출.
- **종합 3.8**

---
### Case 04 — The Palace of a Thousand Logs (1866 겨울, 경복궁 중건)

**사건 목표(plan.goal):** "Find out where the palace logs went, and what the new palace costs."
**목표 유지 평가:** 앞부분(로그 행방)은 M1–M2에서 잘 이어짐. **뒷부분("what the palace costs")은 역사 학습을 위해 붙인 목표**라서 M3가 사건 추적에서 벗어남. 통나무는 M3 끝에서 우연히 발견됨("Duri points to a cart", plan:410). Final interview는 이 시즌 2–5 중 유일하게 증거를 제시해 사건을 닫는 Final이라 구조가 가장 좋음. 다만 "who took the logs"는 질문으로만 남고, 실제로 표를 고발하는 단계가 없음.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 통나무 10개 실종 | — | 읽기 | 문제 제시 | 마당 조사 |
| M1 | 표식 조작 발견 | Sora's board 가획 규칙(Case 01 V4), 마당 표(가/나/다) | 돋보기로 새 획이 있는 다 통나무 → 꼬리표 → "GATES" 입력 | 나 → 다 조작 확인 | "몇 개나?" |
| M2 | 조작 규모 + 구매자 | 나 → 다 규칙 | 장부 16−6 = 10 | 10개 모두 표가 구매 | "왜?" |
| M3 | (역사) 궁궐의 비용·당백전 | — (사건 정보 추가 없음) | 역사 카드 배열 | 비용 이해 → 우연히 표의 수레 발견 | 대원군 등장 |
| Final | 대원군에게 증명 | e1, e2, e3, C02/C03 물방울 쪽지 | 4개 질문에 증거 제시 | 통나무 반환 | 엔딩 |
| Ending | 1865.4 착공, 1868 완공·이어, 백성 부담 + 두리 자백 | — | 읽기 | "가문이 쓴다" | Act 1 전환점 |

- 우연한 발견: 통나무 위치를 추리하지 않음(M3 transition에서 두리가 가리킴).
- 동기: 표가 "새 돈은 가치가 떨어지니 통나무를 원함"(M3 story). 아이가 인플레이션 개념을 이해해야 동기가 성립함. 8세에게는 추상적임.
- 범인 증명 부재: Final 질문은 "Who wrote the note, and who took the logs?"(plan:588)인데, 4개 제시 중 표에 대한 것이 없음. caseSummary는 "Mr. Pyo… had a new line cut"이라고 하지만 게임 안 근거는 "그가 다 통나무를 전부 샀다"뿐임(서기가 판매함).

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서 | 정답 도출 | 외부 지식 | 복수 정답 | 힌트/오답 | 조작 | R/J/M | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 돋보기+단어(GATES) | 관찰 및 단서 찾기 / 암호 해독(가획) | 마당 표: 가 = halls, 나 = gates, 다 = sale. "ㄴ, then ㄷ". 통나무 3개 표식(앱 텍스트). 새 획은 **설명문**("One cut is pale and new!")으로 알려 줌 | 새 획이 있는 다에서 획을 빼면 나 → 표에서 "for the palace gates" → GATES 입력 | 한글 읽기는 불필요(모양 대응). 두리가 미리 "Ten great logs were 나"라고 말해 줌 | GATE/GATES 허용. HALLS는 오답이지만 이유를 설명하지 않음(orderFeedback 1종) | 힌트 2 유효 | 드래그 돋보기 또는 탭 + 영어 타이핑 | 적정. 새 획이 그림이 아니라 텍스트로만 제시되면 관찰 요소가 약함(코드 분석: 표식은 앱 텍스트 오버레이, plan notes) | P3 |
| M2 숫자(10) | 증거 비교 / 계산 | 장부: 어젯밤 나10·다6, 오늘 나0·다16 | 16−6 = 10 | 없음 | 단일. **정답 10이 synopsis·hook·두리 대사에 이미 있음**(plan:9, 229, 785) | 16/06 피드백 좋음 | 2자리 | 적정 | P2 |
| M3 타임라인(burn,ruins,begin,coin,logs) | 순서 배열 / 역사 지식 | 두리 말 5줄이 **시간순 그대로**. 1592·LAST NIGHT 고정, 이어(move)는 버림 | 줄 순서 그대로 | 없음(지문에 다 있음) | 단일 | 힌트 2(미래 사건 제외) 좋음 | 드래그 | 사건과 무관한 역사 정리. 학습용 | P2 |
| Final 증거 제시(4문항) | 증거 비교 / 논리 추리 | 질문마다 증거 2개 중 택1. 2번 틀리면 정답을 알려 줌 | e1 / e2 / C03e1(또는 C02e1) / e3 | 없음 | 단일. **2지선다 + 자동 정답 공개라 무작위로 통과 가능** | miss 대사 + tell | 탭 | 구조 좋음. 난이도는 매우 낮음 | P2 |

**영어 난이도 메모**
- R은 짧음(평균 6.1어, 최장 15). 그러나 개념 어휘가 추상적임: "forced gifts", "cost the people dearly", "the new coin buys less every week", "Prices went up". 8세는 '물가 상승'을 영어 설명 없이 이해하기 어려움.
- 설명 없는 용어: **Daewongun**(왕의 아버지라는 설명 없음, 칭호인지 이름인지 모름), Hanyang, Gyeongbokgung(intro에서 "the great palace"로 OK), apprentice, timber dealer, clerk.
- 레벨 차이: M에는 "destined", "passes for", "disguising", "summoned"가 있어 차이가 있음. R↔J는 "has gone missing / are missing" 수준.

**이슈 목록**

| ID | 심각도 | 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C04-1 | P2 | final.play.question(plan:588), interview.presents | "who took the logs?"를 묻지만 표를 지목·증명하는 제시가 없음. 범인 판정이 암시(빨개진 얼굴)뿐임 | 사건 해결감이 약함. "표가 했는지 서기가 했는지"가 남음 | 5번째 제시 추가: "Who asked for the new line?"에 표의 쪽지(e2의 "I bought every 다 log") + 새 단서(예: 표의 칼·끌, 수레의 나무 부스러기) | M | — |
| C04-2 | P2 | m3 transition "Duri points to a cart"(plan:410) | 통나무 위치를 우연히 발견함. M3는 사건 정보를 주지 않음 | 미션이 이야기와 겉돌게 느껴짐 | M3 정보로 수레를 찾게 함(예: 두리 이야기 속 "logs go out by the east gate at dawn" → 위치 추론) | M | — |
| C04-3 | P2 | interview presents `offered` 2개씩(plan:655–735), case_talk.dart:647 | 2지선다 + 2회 오답 시 자동 공개 | 무작위 탭으로 통과 | 노트 전체(5–7장)에서 고르게 하거나, 최소 3–4개 제시 | S | C07·C09 talk도 같은 엔진(범위 밖) |
| C04-4 | P2 | m2 answer 10 vs synopsis/hook/talk(plan:9, 229, 785) | 정답 10이 미션 전에 3번 노출됨 | 계산 없이 통과 | synopsis·hook을 "Some great logs…"로. 두리 대사의 "Ten" 삭제 | S | — |
| C04-5 | P2 | m3 play.letter | 지문이 이미 시간순이라 after/until/then 독해가 시험되지 않음 | 쉬움 | 문장 순서 섞기 | S | C03 M1·C05 M2 |
| C04-6 | P2 | intro/final 전반 "Daewongun" | 칭호 설명 없음 | 누구인지 모름 | intro 1줄: "the King's father, who rules for the young King" | S | — |
| C04-7 | P2 | m3 story·ending "new coin buys less", "forced gifts" | 인플레이션·강제 기부 개념이 R8에게 추상적임 | 동기·결말 이해 실패 | R: "With the new coin, rice cost more and more." 같은 구체적 예 | S | — |
| C04-8 | P3 | m1 recall.miss "Look for Sora's board" | 노트 증거 이름은 "The Sound Board"(Case 01 V4 e2) | 찾기 혼동 | "Look for the Sound Board." | S | C02-3 |
| C04-9 | P3 | ending "I wrote the note. My father taught me the mark." | 작성자 자백(자기 해결). 단, interview "note" 질문이 "한 사람이 아니다"까지는 추리하게 해 줌 | 경미 | 유지 가능 | — | — |

**clueInputs 타 Case 참조:** s5_ep01_e2(가획 규칙)는 V4 m2 transition "A stronger sound adds one line: ㄴ, then ㄷ."와 e2 설명으로 **일치**함. s5_ep02_e1·s5_ep03_e1(물방울 쪽지)도 각각 존재하며 **일치**함. 단, Final `offered`에는 s5_ep03_e1만 있고 s5_ep02_e1은 accepted에만 있음(문제 없음).

**점수**
- 풀이 가능성 4.5: 모두 풀림.
- 퍼즐 다양성 4: 돋보기 / 계산 / 타임라인 / 심문으로 다양함.
- 영어 난이도 3: 문장은 짧으나 경제 개념이 추상적이고 칭호 설명이 없음.
- 역사 4.5: 1865.4 착공, 1866 당백전·물가, 원납전, 1868 완공·이어 모두 맞음.
- 개연성 3: 표식 조작 → 수량은 좋음. 수레는 우연히 발견, 범인 증명 없음.
- UX·힌트 3.5: 피드백은 좋으나 Final 2지선다 + 자동 공개.
- **종합 3.8**

---

### Case 05 — The Lights of Geoncheonggung (1895 가을, 건청궁)

**사건 목표(plan.goal):** "Find out what the strangers were doing in the dark, and why the Queen is in danger."
**목표 유지 평가:** 전반부("어둠 속에서 무엇을 했나")는 M1–M3에서 단계적으로 밝혀짐(일부러 만든 어둠 → 동선 → 37걸음 측량). **"왜 위험한가"는 Final에서 한 궁녀가 문장으로 말해 줌.** 앞의 증거(37걸음 등)는 Final 정답 도출에 쓰이지 않음. 엔딩은 원래 문제를 해결하지 못하고 역사 비극(을미사변)으로 끝남. 역사적으로 정확하며 의도된 결말임.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 1887 전등, 1시간 정전, 낯선 이 2명 | — | 읽기 | 문제 제시 | 전기실 조사 |
| M1 | 정전이 사고인가 고의인가 | — | 탐색: 쪽지 찾기 → 기계에서 부위 고르기 | 고의(벨트 분리) 확인 | 쪽지 서명 "Han" → 한 상궁을 찾아감 |
| M2 | 낯선 이의 동선 | 고의 정전 | 한 상궁 증언 순서 배열(+recall: Duri 물방울) | 동문 → 왕비 처소 | "They counted" → 밧줄 |
| M3 | 무엇을 셌나 | 동선 | 매듭 규칙으로 37 | 측량했음 | 한 상궁이 숨긴 판(지도) 등장 |
| Final | 왜 왕비가 표적인가 | (형식상) c1–c3 | 한 상궁 말에서 JAPAN 입력 | "감시당한다" 인식 | 엔딩 |
| Ending | 1895 인아거일, 10.8 을미사변 | — | 읽기 | 비극 서술 | Case 06 (지도 e4) |

- 수동적 수사: 쪽지·증언·밧줄·지도를 전부 한 상궁이 가져다줌. 탐정이 직접 발견하는 것은 M1의 쪽지 위치뿐임.
- 갑작스러운 요소: M3 transition에서 "they dropped a board too. I hid it"으로 지도가 새로 나옴(복선 없음).
- 쪽지 수 불일치(경미): M1 "A stranger"(단수) ↔ intro·M2 "two strangers / the strangers"(복수).

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서 | 정답 도출 | 외부 지식 | 복수 정답 | 힌트/오답 | 조작 | R/J/M | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 탐색+그림 선택(belt) | 관찰 및 단서 찾기 / 단순 선택 | 쪽지: "He did not touch the fire… the coal. He took off the long leather belt… His muddy hand is still on it."(plan:88). 선택 그림 중 벨트에만 진흙 손자국 | 쪽지를 그대로 읽고 벨트 선택 | 없음 | 단일. 그림에 손자국이 있어 읽지 않고도 고를 수 있음 | fire/coal 피드백 좋음 | 그림 탭 | R 적정. 매우 쉬움 | P3 |
| M2 타임라인(6장, 2장 고정) | 순서 배열 / 영어(after/before/first) | 한 상궁 말 7줄. "dark after the strangers came into the lamp house"는 한 번 뒤집힘. 나머지는 시간순 | 첫 관계문만 해석하면 나머지는 줄 순서 | 없음 | 단일. MAIN GATE 버림 | 힌트 2 좋음 | 드래그 | 적정 | P2(반복 패턴) |
| M3 숫자(37) | 패턴 발견(자릿값) / 계산 | 큰 매듭 = 10, 작은 매듭 = 1, 3개 + 7개 | 30 + 7 = 37 | 없음 | 단일 | 10/30/73 피드백 우수 | 2자리 | R8에 적합. 매듭을 그림으로 세게 하지 않고 숫자가 문장에 있음 | OK |
| Final 영어 단어(JAPAN) | 영어 어휘 퀴즈 / 역사 지식 | "The Queen works with Russia to hold back Japan's power."(plan:659). prompt "The Queen holds back ____'s power." | 문장에서 Japan을 그대로 옮김 | 없음(지문 제공) | 단일(RUSSIA·CHINA·KOREA 피드백) | 힌트 2 사실상 정답 | 영어 타이핑 | 독해 확인 문제. 탐정 추리 아님. R에만 "(To hold back = …)" 해설 있음 | P2(구조) |

**영어 난이도 메모**
- 설명 없는 고유명사가 intro 2줄에 몰림: Geoncheonggung, Gyeongbokgung, Jangandang, Gonnyeonhap. R8에게 과부하. 퍼즐에는 불필요함.
- 관용 표현: "good-for-nothing lights"(R intro), "hold back"(R만 해설), J/M "Some men want her out of the way"(완곡어법 → 10세에게 의미 전달이 불확실), M "no accident of the lamps", "crept".
- 레벨 차이: 동일 줄 27%(대부분 라벨·옵션). 스토리는 다름. R↔J는 문장 하나 추가 수준. M은 어휘 수준이 올라감("deliberate", "grows by the day").
- 연령: 엔딩 "The Queen was killed in that attack."은 담백하게 서술됨. 8세 대상이므로 보호자 안내 수준의 고려 필요(P3).

**이슈 목록**

| ID | 심각도 | 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C05-1 | P2(구조) | final.puzzle answer JAPAN(plan:606), letter(plan:659) | Final이 지문 문장을 베껴 쓰는 독해 문제임. c1–c3 증거가 정답에 쓰이지 않음(clueInputs가 answerDerivation으로 표기됐지만 실제로는 아님) | 사건 결말을 아이가 추리하지 않음 | Final을 "지도(37걸음)와 밧줄(37) 대조 → 표적은 왕비 처소" 추리로. 일본·러시아 사실은 엔딩으로 이동하거나, 다른 증거(외국 장화 자국 등)와 결합 | M | C02·C03 Final |
| C05-2 | P2 | 전 미션(쪽지·증언·밧줄·지도 모두 한 상궁 제공) | 탐정 행동이 수동적임 | "내가 찾았다"는 느낌이 약함 | M2를 현장 흔적(발자국·문)으로 순서를 잡게 하거나, M3 밧줄을 탐정이 직접 발견하게 함 | M | — |
| C05-3 | P2 | m3 transition "they dropped a board too. I hid it" | Final 핵심 소품(지도)이 복선 없이 등장함 | 개연성 약함 | M1 탐색에 "something was dragged/dropped" 흔적을 추가 | S | Case 06 recall e4 |
| C05-4 | P2 | m2 play.letter(plan:383) | 지문이 대부분 시간순이라 타임라인이 반복적이고 쉬움(C03 M1·C04 M3와 같은 엔진·같은 쉬움) | 지루함 | 문장 순서 섞기, 또는 엔진 교체 | S | C03·C04 |
| C05-5 | P2 | intro 2–3줄 | 궁궐 이름 4개가 연속으로 나옴 | 읽기 부담 | R은 "the King's hall / the Queen's hall"로만 | S | — |
| C05-6 | P3 | m1 letter "A stranger" vs synopsis·m2 "two strangers" | 단수·복수 혼재 | 경미한 혼동 | "One of the strangers came into the lamp house." | S | — |
| C05-7 | P3 | J/M final letter "want her out of the way" | 완곡어법. R에만 hold back 해설 | 의미 오해 | J도 "(hold back = stop it from growing)" 유지 | S | — |
| C05-8 | P3 | ending 을미사변 | 왕비 피살 서술(정확함) | 정서적 부담 | 현 수준 유지 가능. 보호자 노트 검토 | — | — |

**clueInputs 타 Case 참조:** s5_ep04_e1(두리 쪽지) recall은 C04 m1 evidence "The Water-Drop Note (1866)"와 **일치**함. Final transition "Lady Han puts her note in a small wooden box"는 Case 01 V4의 "엄마가 작은 나무 상자에 보관"과 **호응함**(의도된 연결로 보이나 plan에 근거 표기 없음, 추정).

**점수**
- 풀이 가능성 5: 막힐 곳 없음.
- 퍼즐 다양성 3.5: 탐색 / 타임라인 / 숫자 / 단어. 단어·숫자 입력이 C02–C04와 반복됨.
- 영어 난이도 3: 고유명사 과다, 완곡어법·관용 표현.
- 역사 4.5: 1887 건청궁 전등, 건달불, 인아거일, 1895.10.8 을미사변(미우라 공사) 모두 맞음.
- 개연성 3: 동선 → 측량은 좋음. 증인 의존, 지도 돌출, Final 추리 없음.
- UX·힌트 4: 피드백 우수. Final 힌트가 정답에 가까움.
- **종합 3.8**

---

## Case 02–05 종합

- 심각도 집계: **P0 0 / P1 0 / P2 22 / P3 9**
  - Case별 P2: C02 6 · C03 4 · C04 7 · C05 5
  - Case별 P3: C02 2 · C03 2 · C04 2 · C05 3
  - "구조" 표시: C02-1, C03-2, C05-1(세 Case 공통 패턴).
- 진행 불가나 단서 없는 정답은 **발견하지 못함**. 모든 퍼즐의 단서가 화면에 있고 정답은 하나임. 한글 입력이 필요한 조작도 없음(C02 거북선은 탭으로 조립).
- 반복 패턴(우선 수정 권장):
  1. **Final이 사건 해결이 아님**: C02(DRAGON 철자), C03(연도 다이얼), C05(JAPAN 받아쓰기). 세 Final 모두 정답이 지문에 노출되어 있고 앞 증거를 쓰지 않음. C04 interview만 증거 제시형인데, 그마저 2지선다 + 자동 공개라 무작위 탭으로 통과됨.
  2. **정답 사전 노출**: C02 M3 12(M1에서 나옴), C03 Final 1796(첫 줄), C04 M2 10(synopsis·hook·대사).
  3. **타임라인 3회(C03 M1, C04 M3, C05 M2)**: 모두 지문이 이미 시간순이라 until/after 학습 목표가 시험되지 않음.
  4. **작성자 자백 엔딩**: C03 옥분, C04 두리. 물방울 가문 미스터리가 추리 없이 대사로 풀림.
- Case 01 V4 정합성: C02의 Sora's board가 ㅁ을 "the mouth"로 부르지만 V4는 "the lips"로 가르침. 노트 증거 이름("The Sound Board")과 recall miss 문구("lesson board", "Sora's board")도 다름(C02-3, C04-8). 가획 규칙(ㄴ→ㄷ)과 ㅓ(dot left)는 V4에서 가르쳐져 일치함. 다만 flat 모음(ㅜ)과 ㅂ 모양은 V4에서 배우지 않은 새 개념임.
- 미실행: 앱 실행·테스트·스크린샷 없음. 그림은 C03 설계도 2장·C04 마당만 확인함. 영어 판단은 텍스트 덤프 기준.

---

# PART 3 — Case 06~09 정밀 조사

## PART 3 — Seoul Case 06–09 플레이 가능성 감사 (영어권 8–12세, 한글 못 읽음 기준)

감사 방법: 전부 **코드 분석**(앱 실행·실기기·이미지 판독 없음). 출처 = `content_pipeline/seasons/s5_seoul/cases/s5_epNN/case.plan.json`, `levels.json`, `lib/data/generated/s5_seoul/s5_epNN.g.dart`(실제 로드), 텍스트 덤프 `scratchpad/seoul_text_dump.md`.
엔진 확인: `lib/core/utils/answer_checker.dart`(오답 피드백 규칙), `lib/features/mission/widgets/question_widgets.dart`(NumberCode·Sequence), `scene_deduction.dart`, `letter_lock.dart`, `lib/widgets/glossary_text.dart`.

## 공통 엔진 사실 (4개 Case 모두에 적용)
- **오답 횟수 제한 없음**: `game_controller.dart:322` `_submitAnswer`는 잠김(locked) 외에 시도 횟수를 세지 않음 → 모든 퍼즐이 무제한 재시도. 선택지 3개·타일 6개 같은 퍼즐은 무작위 탭으로 통과 가능.
- **오답 피드백 규칙** (`answer_checker.dart:19-55`): 선택형은 옵션별 feedback, 순서형은 등록된 조합 일치 → 아니면 "같은 항목·다른 순서"일 때만 orderFeedback, 그 외는 null → 일반 문구 `'Good detectives look again.\nRead the clue one more time!'` (`answer_feedback.dart:459`). 즉 등록되지 않은 오답 대부분은 이유 설명이 없다.
- **시간 입력** (`question_widgets.dart:443-461`): `codeFormat: time`이면 4칸 사이에 ':'가 항상 표시됨(“_ _ : _ _”). 아이는 6:50을 **0,6,5,0** 으로 입력해야 함. "6,5,0"까지 치면 `65:0_`로 보여 첫 칸 0의 필요를 화면에서 스스로 깨달아야 함. 안내 문구 없음.
- **글로서리(길게 누르기) 뜻 = 한국어** (`glossary_text.dart:199-215`, plan `play.glossary` 값이 전부 한국어). 영어권 아이에게 envoy/treaty/protectorate 등 어려운 단어의 유일한 설명 장치가 무용지물. → 시즌 전체 이슈(아래 C06-G로 1회 기재, 다른 Case에도 동일).
- **글자 타일 자물쇠** (`letter_lock.dart`): 타일 = 정답 글자 정확히 그 개수. 미끼 글자 없음 → 철자 퍼즐이 아니라 애너그램. 오답은 항상 "같은 글자·다른 순서"이므로 orderFeedback만 반복.

---

### Case 06 — The Emperor's Secret Letter (1907, 헤이그 특사)

**사건 목표(한 문장)**: 궁 안에 숨겨진 황제의 비밀 편지를 찾아 감시를 피해 궁 밖으로 빼내 특사 이준에게 전한다 (`goal`).
**목표 유지 평가**: M1(찾기)→M2(빼내기)→M3(이준 집 도착)까지 목표가 한 줄로 유지됨. 단, 목표는 **M3 끝(이준이 문을 엶)에서 사실상 달성**되고 Final(이준의 여행 상자 자물쇠)은 목표와 무관한 덧붙임.

**인과관계 표**
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 1905 조약·헤이그 회의·특사 소개 | — | 읽기, 고종과 대화(talk.before) | 목표 제시 | 편지가 숨겨져 있음 |
| M1 | 편지 위치를 모름 | (C05 e1 물방울 쪽지 recall) | 그림에서 흔적 3개 탭 → 장소 3곳 중 선택 | 편지 확보(old pine) | "Past the watchers" |
| M2 | 문마다 감시 | 편지 확보, C05 "strangers' map" 언급 | 봉수의 길 6개 중 4개 순서 탭 | 궁 밖(서문) 탈출 | 골목에도 감시 |
| M3 | 이준 집 앞 순찰 | 서쪽 골목 도착 | 순찰 시각+10분 계산, 시각 입력 | 이준과 만남 | 이준이 "편지 가져왔나?" |
| Final | (약함) 이준이 상자를 열어야 함 | 편지 소지 — **답 도출에는 미사용** | 6글자 타일 FORCED | 편지 상자에 보관 | — |
| Ending | 역사 결과 | — | 대화 | 특사 출발·입장 거부·이준 사망·고종 퇴위 | hook → C07 |

**미션별 상세표**
| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정(모르는 아이) | 외부 지식 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 흔적 → old pine | 관찰 및 단서 찾기 / 논리 추리 | 쪽지(letter)에 흔적 3줄이 **먼저** 다 적혀 있음; 그림에서 흔적 3개를 다 찾아야 장소 선택이 열림(`scene_deduction.dart:85 _choosing => allNoted`) | "to the trees, not to the steps"+"rough bark"+"by a root" → 나무인 곳은 pine 하나 | 없음 | lantern(돌)·pots(계단 옆)은 각 1개 흔적으로 배제, 옵션별 feedback 있음. 단일 정답 | 힌트 1=탭 위치 안내, 힌트 2=bark/roots 질문 — 유효 | 탭·핀치. 명확 | R 적정. 단, 쪽지가 흔적을 미리 알려줘서 그림 탐색은 "확인" 수준 | P3 |
| M2 길 순서 | 순서 배열 / 단순 선택 | 봉수의 말 6줄: First library / Do not throne / After library, well / Then west gate / Last lane / front gate 감시 | 쪽지에 나온 순서대로 4개 탭하면 됨(정답 순서 = 쪽지 등장 순서) | 없음 | 6개 중 4개 순서, 미끼 2개 모두 문장으로 배제. 단일 | feedback 2조합 + orderFeedback, 나머지 오답은 일반 문구 | 탭 순서, Undo 있음 | 읽고 옮겨 적기 수준. 추리 약함 | P2 |
| M3 노크 시각 0650 | 논리 추리(시간 계산) / 영어 어휘 | 6:00·6:40·7:20, "Each walk takes ten minutes", "Knock when the 6:40 walk has passed", "Do not wait for the next walk" | 6:40+10분=6:50 | 없음 | **6:51~7:19도 문장상 맞음**("has passed"+"do not wait for next"), 그러나 0650만 정답. 0700 등은 일반 문구만 | 힌트 2개 유효; 0640/0720/0610 feedback 좋음 | 시간 4칸 '0650' 입력(앞자리 0) | R: has passed 이해 필요하나 hint로 보완 | P2 |
| Final FORCED | 영어 어휘 퀴즈 / 조합 및 구성 | 뚜껑: "Japan made Korea sign it. Korea did not choose it. Japan ______ Korea to sign it."(R); J/M "It was ______ on Korea." | made ~ do = forced. intro 2줄째 "Japan forced a treaty on Korea"에서 이미 본 단어 | forced 어휘 | 타일 C,O,E,F,D,R = 정답 글자뿐 → FORCED 외 영어 단어 없음, 그러나 **애너그램 추측으로 통과 가능** | R 힌트2 "It starts with F"; J/M 힌트2는 정의만. orderFeedback이 매 오답마다 같은 문장 | 타일 탭/드래그 | 사건 해결이 아니라 어휘 시험 | P2 |

**영어 난이도 메모**
- R은 짧고 구체적(평균 6.1어, 최장 14어). 좋음: "They go to the trees, not to the steps."
- 추상/어려운 어휘가 설명 없이 등장: intro "**treaty**", "**envoys**", "**peace conference**", "Korea lost the right to deal with other countries"(외교권 개념 — 8세에게 추상적). 글로서리는 한국어라 도움 안 됨.
- 어색한 문장: M2 story R "You remember the strangers' map of 1895. **Palace paths get counted.**" — 무엇을 누가 센다는지 불명. C05 회상을 억지로 넣은 문장.
- "A note in the **King's letters**" — 1907엔 'Emperor'인데 'King's letters'(=한글)라 혼동 가능. intro에서 왕→황제 변화 설명 없음.
- 레벨 차이: J는 R과 거의 같음(J 평균 6.5 vs R 6.1, 동일 줄 31%). M은 conceal/usher/linger/seized upon 등 어휘 상승 — M다운 차이 있음.
- 민감 내용: "Yi Jun died in The Hague that July." — 사인 언급 없이 담담. 8세 적정.

**이슈 목록**
| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C06-1 | P2 | `final.play.letter`, `final.puzzle.answerSpec.options` | Final이 사건 해결이 아니라 어휘 빈칸. 이준이 자기 상자 암호를 뚜껑에 쓰인 정의로 플레이어에게 묻는 구조 — 동기 약함. clueInputs c1이 `answerDerivation`이라 적혔지만 편지는 답 도출에 쓰이지 않음 | "왜 내가 이준 상자를 열어야 하지?" + 6타일 애너그램은 추측으로 풀림 | Final을 M1~M3 증거(편지의 봉인, 6:50, 봉수 쪽지)로 "이 사람이 진짜 이준인지 / 편지가 진짜인지" 확인하는 해결 장면으로; 또는 미끼 타일 2~3개 추가 | M | 시즌 letter_tile_lock 사용 Case 전부 |
| C06-2 | P2 | `missions[2].play.letter` "Knock when the 6:40 walk has passed. Do not wait for the next walk." | 6:51~7:19도 조건 충족 | 7:00 입력 시 일반 오답 문구만 → 왜 틀렸는지 모름 | "Knock **as soon as** the 6:40 walk has passed" 또는 "The door opens only for ten minutes" | S | 없음 |
| C06-3 | P2 | `missions[1]` M2 | 정답 순서 = 쪽지 문장 순서, 추리 없음(옮겨 적기) | 쉬우나 '탐정' 느낌 약함 | 쪽지 순서를 섞어(After the well… / Before the gate…) 실제 재배열 필요하게 | S | 없음 |
| C06-4 | P2 | `missions[1].play.story[1]` "Palace paths get counted." | 의미 불명, C05 회상 억지 연결 | 문장 해석 불가 | "Strangers once mapped this palace. Someone may be watching the paths." | S | 없음 |
| C06-5 | P3 | `missions[0].play.letter` vs traces | 쪽지가 흔적 3개를 미리 다 알려줌 → 그림 탐색은 확인용 | 긴장감 약함 | 쪽지는 "I saw him go into the garden" 정도로, 흔적 문장은 그림 탭 때만 공개 | S | 없음 |
| C06-6 | P3 | `play.intro`, M1 `letterIntro` | 1895엔 King, 1907엔 Emperor — 변화 설명 없음 + "King's letters" | 같은 사람인지 혼동 | intro에 "Gojong is now Emperor" 한 줄 | S | C05, C07 |
| C06-7 | P3 | M3 시간 입력 | '0650' 앞자리 0 입력 안내 없음 | 65:0_ 로 막힘 | question에 "(06:50)" 또는 첫 칸 0 예시 | S | C09 M1(0100) 등 time 코드 전부 |
| C06-G | P2 | `play.glossary` 전 Case, `glossary_text.dart:203` | 단어 길게 누르기 뜻이 **한국어** | envoy·treaty 뜻을 확인할 방법 없음 | 글로서리를 쉬운 영어 정의로 교체(아이용) | M | 시즌 5 전체 |

**6항목 점수**
- 풀이 가능성 4/5 — 모든 답이 화면 문장에서 도출됨. M3 복수 해석, 시간 입력 0 문제만 감점.
- 퍼즐 다양성 3/5 — 흔적 탐색·순서·시간 계산·애너그램으로 형식은 다르나 M2·Final이 얕음.
- 영어 난이도 4/5 — R 짧고 구체적. treaty/envoy/conference 설명 부재, "Palace paths get counted" 어색.
- 역사 5/5 — 1907 헤이그, 세 특사, 입장 거부, 이준 사망(7월), 고종 강제 퇴위 모두 명백한 오류 없음.
- 개연성 3/5 — M1→M3 연결 좋음. Final(남의 상자 열기)은 동기 약하고 이전 증거 미사용.
- UX·힌트 4/5 — 힌트 실효성 좋음, 등록되지 않은 오답은 일반 문구.
- **종합 3.8/5**

---
### Case 07 — Two Reports from Harbin (1909, 하얼빈)

**사건 목표(한 문장)**: 하얼빈의 두 신문 중 어느 기사가 사실인지, 안중근이 실제로 무엇을 외쳤는지 밝힌다 (`goal`).
**목표 유지 평가**: M1(불일치 줄)→M2(A 기자의 행적)→M3(목격자 증언)→Final(기자 설득)로 목표가 끝까지 유지됨. 4개 Case 중 인과 흐름이 가장 좋다. 단 M2의 핵심 결론이 그 시점 화면 정보로는 도출 불가.

**인과관계 표**
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 사건 배경 | (C06 hook: 누가 한국 말을 들어줄까) | 읽기, 강 부인 대화 | 두 신문 제시 | 하나가 거짓 |
| M1 | 어느 줄이 다른지 | C06 e1 물방울 recall | 두 신문 4줄씩 비교, 다른 줄 탭 | "HE CALLED" 줄만 다름 | 강 부인 "박 씨에게 물어봐" |
| M2 | A 기자가 현장에 있었나 | "Only one writer was on the platform" | 박 씨 하루 카드 3장 배치(고정 3장, 버림 1장) | A 기자는 정오 기차로 옴 → 현장 없었음(**게임이 선언**) | 박 씨는 현장에 있었다 |
| M3 | 실제 외친 말 | 박 씨 = 목격자 | KOREA 입력 | "Korea, hurrah!" 확정 | 강 부인이 B를 A 신문사로 |
| Final | 기자가 반박 | e2, e3, C06 e4 | 질문 3개에 증거 제시(각 2지선다) | 기자 인정 | 진실 기사 보관 |
| Ending | 결과 | e4 | 대화·역사 | 동양평화론 집필 | hook → 1919 |

**미션별 상세표**
| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정 | 외부 지식 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 다른 줄 | 증거 비교 / 관찰 | 두 신문: DATE·PLACE·NAME 동일, HE CALLED: NOTHING vs KOREA, HURRAH! | 줄별 비교 → 마지막 줄 | 없음 | 4줄 중 1줄만 다름, 단일 | date/place/name 오답 각각 feedback 있음, 좋음 | 각 신문의 줄 탭 | R 적정. 매우 쉬움 | P3 |
| M2 박 씨의 하루 | 순서 배열 / 논리 추리 | 7:00·12:00·5:00 PM 카드 고정, before/after 문장 3개, goods train 버림 | 고정 슬롯 사이에 3장 넣기: platform(정오 전)→tea→write. 엔진(`timeline_rules.dart:42` anchors 고정) 덕에 단일 | 없음 | 단일 | orderFeedback "When did the writer come?" 유효 | 카드 배치 | 배치 자체는 쉬움. 그러나 **사건이 아침에 일어났다는 정보가 M2 이전에 없음** → "He was never on the platform!" 결론은 아이가 도출 못 하고 게임이 말해줌 | P2 |
| M3 KOREA | 영어 어휘(베끼기) / 단순 선택 | "He called out, 'Korea, hurrah!' He called out for his country" | 따옴표 안 단어 그대로 입력 | 없음 | KOREA/COREA/HIS COUNTRY 허용. "Korea, hurrah"를 통째로 치면 `KOREAHURRAH`로 정규화돼 오답(`answer_checker.dart:14`) → 일반 문구 | MONEY/HIMSELF/HARBIN feedback 좋음 | 시스템 키보드 타이핑 | 추리 없음, 베끼기 | P2 |
| Final 소린 설득 | 증거 비교 / 단순 선택 | 노트 요약 3줄이 답을 그대로 적어 둠; 질문마다 증거 **2개 중 1개** (`s5_ep07.g.dart:627-689` choices) | 질문-증거 매칭 | 1905 조약(C06에서 배움) | 각 단계 단일. 그러나 2지선다 ×3 = 무작위로도 통과 | tell 문구로 오답 설명 | 탭 | 사건 해결형 Final로 좋음, 난도는 낮음 | P2 |

**영어 난이도 메모**
- 4개 Case 중 가장 짧음(R 평균 5.2어, 최장 14). R은 8세에게 적정.
- **레벨 차이 약함**: J 5.7, M 5.8, M 최장 19어. M에 "befell", "recounts", "pay it no mind" 정도. J≈R(동일 33%). M은 12세 기준 오히려 쉬움.
- 설명 없는 고유/역사어: "**Itō Hirobumi of Japan**"(누구인지 설명 없음), "On Peace in East Asia", "independence"(C07에서 처음, 글로서리는 한국어). Harbin이 중국 땅이라는 설명 없음.
- 문법 어색: M3 question R "**Who** did An Jung-geun call out for? Type the name of his country." — 나라에 who.
- **민감 내용**: intro R "On 26 October, at Harbin Station, An Jung-geun killed Itō Hirobumi of Japan." — 묘사 없이 한 번만, 아이가 행위를 하거나 보지 않음(`notes`), 엔딩은 감옥에서 평화론 집필로 마무리. 수위 자체는 적정. 다만 **이토가 누구이며 왜 그런 일이 있었는지(한국 지배의 책임자)**가 Final의 "why" 이전엔 전혀 없고, Final도 "Japan forced a treaty"로만 답함 → 8세는 "나라를 위해 외쳤으니 사람을 죽여도 된다"는 단순 메시지로 받아들일 여지. "Itō Hirobumi, the Japanese leader who took control of Korea" 정도의 맥락 1줄 필요.

**이슈 목록**
| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C07-1 | P2 | `missions[1].play.successMessage` "The writer came at noon. He was never on the platform!" | 사건이 **아침**이었다는 정보가 M2 전에 없음(덤프 검색: 사건 시각 언급 0회, 'that morning'은 M2/M3 박 씨 말뿐) | 카드는 맞췄는데 왜 '현장에 없었다'인지 이해 못 함 | M1 신문 B 또는 intro에 "in the morning, at 9:30" 한 줄; 또는 M2 letter에 "It happened that morning, on the platform" | S | 없음 |
| C07-2 | P2 | `play.intro[1]`, history reveal(`s5_seoul_history.g.dart` s5_ep07) | 이토의 정체·사건 이유 설명 없음, "killed"만 단독 | 8세: 누가 왜? 폭력의 의미를 맥락 없이 받음 | 이토 = 한국을 지배한 일본의 최고 책임자 1줄 + "People still talk about what he did and why" 같은 중립적 맥락 | S | C08–C12 (일제 지배 배경) |
| C07-3 | P2 | `final.play.interview.presents[*].offered` (각 2개) + `final.play.letter`가 답 요약 | 2지선다 3회, 노트가 답 문장을 미리 제공 | 생각 없이 통과 가능 | 노트북 전체 증거(5~6개)에서 고르게, letter 요약 제거 | S | C09 Final 동일 구조 |
| C07-4 | P2 | `missions[2]` M3 | 따옴표 안 단어 베끼기. 'Korea, hurrah' 전체 입력은 오답 | 추리 없음 / 맞는 말 쳤는데 틀림 | acceptedAnswers에 "KOREAHURRAH" 추가, 또는 "not for money / not for himself" 대조로 고르게 | S | 없음 |
| C07-5 | P2 | levels.json 전체(stats: R5.2/J5.7/M5.8) | 레벨 차이 약함 | M12에게 단조 | M 문장에 종속절·추론 표현 추가 | M | — |
| C07-6 | P3 | `records.second` "THE MORNING NEWS", DATE "26 OCTOBER" | 아침 신문이 같은 날 아침 사건을 보도 | 꼼꼼한 아이 혼동 | 신문 B DATE 27 OCTOBER 또는 이름 변경 | S | 없음 |
| C07-7 | P3 | `play.intro[0]` | Harbin이 중국 도시라는 설명 없음, "Korean inn in Harbin" | 어디인지 모름 | "Harbin, a city in China" | S | 없음 |
| C07-8 | P3 | `missions[2].play.question` "Who did … call out for?" | 나라에 who | 경미 | "What did he call out for?" | S | 없음 |

**6항목 점수**
- 풀이 가능성 4/5 — 모든 퍼즐 답은 화면에서 나옴. M2 결론만 근거 부족.
- 퍼즐 다양성 4/5 — 기록 비교·타임라인·입력·증거 제시로 다양. M3가 얕음.
- 영어 난이도 3/5 — R 적정, J/M 차이 약함, 이토·독립 설명 없음.
- 역사 5/5 — 1909.10.26 하얼빈역, "코레아 우라", 동양평화론 1910.3 미완 모두 명백한 오류 없음.
- 개연성 4/5 — 두 기사 → 기자 행적 → 목격자 → 설득의 흐름이 탄탄. M2 결론의 정보 공백.
- UX·힌트 4/5 — 오답 피드백 충실. Final 2지선다는 너무 쉬움.
- **종합 4.0/5**

---

### Case 08 — The Fire on the Hill (1919, 아우내 장터)

**사건 목표(한 문장)**: 마을들에 퍼진 가짜 날짜 속에서 만세 행진의 진짜 날짜와 마을에 알릴 신호를 찾는다 (`goal`).
**목표 유지 평가**: M1(진짜 날짜)·M2(신호)는 목표에 직결. **M3(물방울 쪽지를 쓴 사람)는 목표와 무관한 시즌 메타 서사**(keepers)로, 빼도 사건 해결에 지장 없음. Final은 M1·M2 결과(4월 1일, 전날 밤)를 정확히 사용해 좋음. 가짜 날짜를 퍼뜨린 '낯선 사람(stranger)'은 끝까지 해소되지 않음.

**인과관계 표**
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 1919 배경, 가짜 날짜 | (C07 hook: 10년 뒤) | 읽기 | 문제 제시 | 장터 쪽지 |
| M1 | 어느 날이 진짜인가 | 물방울 쪽지(우연히 찻잔 밑) | 전령 3명에게 질문 → 두 답 비교 → Pyo에게 "who" → 날짜 선택 | 4월 1일 확정, 매수된 Pyo | 먼 마을엔 어떻게 알리나 |
| M2 | 신호 방법 | 4월 1일 | 뒤섞인 계획 4단계 정렬(종 배제) | 매봉산 횃불, 전날 밤 | (약함) "But the stranger is still asking" |
| M3 | (사건 목표와 무관) 쪽지 작성자 | C07 e1 recall | 공책 3개 설명 읽고 이름 입력 | 경순 = keeper | "오늘 밤 언덕에서 보여줄게" |
| Final | 낯선 사람이 계획을 못 읽게 상자 잠금 | c1(4/1), c2(전날 밤) | 다이얼 3-1-1 | 상자 열림, 분이 편지 발견 | — |
| Ending | 역사 | e4 | 서술 | 횃불, 4월 1일 행진 | hook → 상자 행방 |

**미션별 상세표**
| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정 | 외부 지식 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 세 전령 | 증거 비교 / 논리 추리 | 쪽지: "Two of them say the same day. One man says another day. Someone paid him." + 3인의 day/place/who 답 | 경순·동일 = April 1, Pyo = April 2 + 동전 받음 → April 1 | 없음 | march_tenth는 아무도 말 안 함, april_second는 1명. 단일 | 옵션별 feedback 좋음, 대화 엔진의 off-topic/different 문구도 설명적 | 인물 탭→질문 탭→답 2개 비교 탭 | 탐정 게임다운 좋은 퍼즐. R 적정 | — |
| M2 계획 순서 | 순서 배열 / 논리 추리 | 뒤섞인 5문장: When…full / In the morning / the night before / fire / No bell | 시간 표현으로 재배열: fire(전날 밤)→walk(아침)→full→march | 없음 | bell은 "No bell"로 배제. walk/full 순서도 문장으로 결정. 단일 | 힌트 2개가 시간 표현을 정확히 가리킴 | 탭 순서 | 진짜 재배열이 필요한 좋은 퍼즐(C06 M2와 대비) | — |
| M3 쪽지 작성자 | 관찰(텍스트) / 증거 비교 | 공책 설명 3줄 + "Your note: … with a small water drop" | 물방울 = 경순 공책 | "Chinese characters" 개념(문장 안에서 대조로 해결) | 단일. 단, 그림 관찰이 아니라 문장 매칭 | SUNJA/OKHUI/GWANSUN feedback 좋음 | **GYEONGSUN 9글자 타이핑**(eo, ng 철자) | R8에게 철자 부담. 오탈자(GYEONSUN 등)는 일반 문구 | P2 |
| Final 다이얼 311 | 조합 및 구성 / 논리 추리 | "First two dials: the night of the sign… a night in March. Last dial: the day of the march… March has thirty-one days." | M1(4월 1일)+M2(전날 밤)→3월 31일 → 31, 1 | 3월 31일(문장에 제공) | 131/301/302/012 각 feedback 있음. 단일 | 힌트 2 직접적 | ± 다이얼 3개 | 이전 증거 사용 좋음. 단 다이얼 그림 기호 혼란(아래 C08-1) | P2 |

**영어 난이도 메모**
- R 평균 6.0어, 최장 18어(>15어 3문장). 대체로 적정.
- 레벨 차이: J 6.8, M 7.3, M 최장 22어. 어휘 상승(stroll, as though, genuine, hastily) — 보통 수준의 차이.
- **"Hangeul"이 C08에서 처음 등장**(`missions[0].play.story[2]` "It is written in Hangeul.") — C01–C07은 계속 "the King's letters"라고 불렀고(생성 파일 기준 Hangeul 0회), 같은 것이라는 연결 문장 없음.
- **"independence"의 대상이 설명되지 않음**: 시즌 전체 텍스트·history reveal 어디에도 1910년 일본의 국권 강탈/지배가 없음(덤프·`s5_seoul_history.g.dart` 검색, "1910"은 동양평화론 날짜뿐). "the police watch the roads"의 police가 누구 편인지도 모름. 영어권 8세는 "누구로부터 독립?"을 이해 못 함.
- 민감 내용(유관순): 스토리 본문은 횃불·행진까지로 밝게 끝남. history reveal R "Gwan-sun's father and mother died at the market that day." / "Gwan-sun was arrested. She died in Seodaemun Prison in 1920." — 잔혹 묘사 없음, 사실 위주로 8세 수용 가능. 다만 부모의 죽음 이유(일본 헌병의 발포)가 빠져 '왜 죽었지?'가 남음 — 짧은 원인 1줄 권장.

**이슈 목록**
| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C08-1 | P2 | `final.puzzle.answerSpec.dialSymbols` ["clock","watch","map"] vs `missions[0].play.clue.symbol` "clock"(=4월 1일, 실제로는 **3번째** 다이얼); M2/M3 clue엔 symbol 없음. 노트북 문구 `notebook_screen.dart:222` "All clues found! Match each picture to its number." | 다이얼 그림 기호가 단서 그림과 대응한다는 기존(런던식) 규칙이 이 Case에선 틀림 | 시계 그림 단서(4월 1일)를 1번 다이얼에 넣어 "1??"로 시도 → 혼란 | dialSymbols 제거 또는 (fire, fire, clock) 식으로 실제 대응, 노트북 문구 조정 | S | dialSymbols 쓰는 다른 Seoul Final 확인 필요(코드 분석) |
| C08-2 | P2 | `missions[2].puzzle.answerSpec.answer` "GYEONGSUN" (wordInput) | 한국 로마자 이름 9글자 철자 입력, 퍼즐은 텍스트 매칭뿐 | 8세가 eo/ng 철자 틀리면 일반 문구만 | 공책 3개(그림)를 탭해 고르게, 또는 철자 유사 허용 | S | C09 M3(NAM GIHO)도 타이핑(허용 폭은 넓음) |
| C08-3 | P2(시즌 최우선) | C08 intro 전체 / 시즌 텍스트 | 일제의 한국 지배(1910)가 시즌 어디에도 서술되지 않음 | independence, police, Provisional Government, 망명 정부의 의미를 이해 못 함 | C07 엔딩 또는 C08 intro에 "In 1910, Japan took over Korea. Koreans wanted their country back." 1~2줄 | S | C07, C09–C12 |
| C08-4 | P2 | `missions[0].play.story[2]`, `missions[2].play.letter` | "Hangeul" 신규 용어, "King's letters"와 연결 없음 | 다른 문자로 오해 | "Hangeul, the King's letters" 첫 등장 시 병기 | S | C09 |
| C08-5 | P3 | `final.play.ending[2]` evidence "s5_ep01_e3" | 대사는 편지 전체 "엄마, 고마워요"인데 연결 증거는 C01 e3 "Bun-i's First Word(엄마)". 전체 편지는 e4 "Bun-i's Letter". 또 한글이 번역 없이 표시 | 증거 카드와 대사 불일치, 한글 못 읽음 | evidence를 s5_ep01_e4로, 대사에 "(Mom, thank you)" 병기 | S | C01 V4 기준 정합 |
| C08-6 | P3 | M1 `deduction.then` pyo.who → 이후 미해소 | 돈 준 '낯선 사람'이 결말까지 등장·해결 없음 | "그 사람은?" | 엔딩 1줄(낯선 사람이 4월 2일에 장터에 왔다가 허탕 등) | S | 없음 |
| C08-7 | P3 | `final.play.letter` | 경순이 자기가 잠근 상자를 플레이어에게 풀게 함(C06 Final과 같은 억지 구조) | 동기 약함 | "당신이 기억하는 두 날로 잠갔다, 확인해 달라" 식 | S | C06 |
| C08-8 | P3 | M3 전체 | 사건 목표(진짜 날짜·신호)와 무관한 시즌 메타 미션 | 이야기가 잠시 옆으로 샘 | 경순 쪽지 확인이 '가짜 날짜를 누가 퍼뜨렸나' 배제에 쓰이게 연결 | M | C09(Haesu) |

**6항목 점수**
- 풀이 가능성 4/5 — 모든 답이 화면 정보로 단일 도출. M3 철자, Final 다이얼 기호 혼란 감점.
- 퍼즐 다양성 4/5 — 증언 비교·진짜 재배열·이름 입력·다이얼. M1·M2는 시즌 내 수작.
- 영어 난이도 3/5 — 문장은 적정, 그러나 independence의 배경·Hangeul 용어 공백.
- 역사 5/5 — 이화학당 휴교·매봉산 횃불(전날 밤)·4월 1일 아우내 장터·부모 사망·1920 서대문형무소 사망, 명백한 오류 없음.
- 개연성 3/5 — M1→M2→Final 연결 좋음. M3 이탈, 낯선 사람 미해소.
- UX·힌트 4/5 — 오답 피드백 충실, 다이얼 기호가 오해 유발.
- **종합 3.8/5**

---

### Case 09 — The Spy in the Shanghai Office (1920, 상하이 임시정부)

**사건 목표(한 문장)**: 비밀 명단을 베낀 사람을 찾아 경무국장 김구에게 증거를 보인다 (`goal`).
**목표 유지 평가**: M1(언제)→M2(어떻게)→M3(누가)→Final(증명)으로 탐정극 구조가 가장 정석적. 단, 결말에서 범인은 도망가고 "The real list is safe"로 끝나 **베낀 명단이 유출됐는지**가 해소되지 않음. Final 4번째 질문은 사건과 무관한 역사 확인.

**인과관계 표**
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 임시정부·김구 소개 | (C08 hook: 상자는 어디로) | 읽기 | 명단 사건 제시 | 골목 쪽지 |
| M1 | 누군가 언제까지 책상에 있었나 | 물방울 쪽지(점원이 우연히 떨어뜨림), C08 e4 recall | 11시 + 4시간 초의 절반 → 01:00 입력 | 11~1시 사용 | 해수 등장, 무엇을 남겼나 |
| M2 | 베꼈다는 증거 | 11~1시 | 보고서 위치어로 3물건 찾기 → 어느 것이 복사 증거인지 선택 | 얇은 종이(눌린 이름) | "밤엔 점원만 들어올 수 있다" |
| M3 | 누가 | 불 꺼진 시각 1시 | 퇴근부에서 1시 이후 퇴근자 → 이름 입력 | 남기호 | 김구에게 보고 |
| Final | 김구 설득 | e1, e2, e3 | 질문 4개 × 2지선다 증거 | 김구 납득 | — |
| Ending | 결과·역사 | e4 | 서술 | 남기호 도주, 명단 안전 | hook → 김구의 다음 부탁 |

**미션별 상세표**
| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정 | 외부 지식 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 반 토막 초 0100 | 논리 추리(시간 계산) | "The guard saw a light … at eleven. I left a new candle there. A new candle burns for four hours. This morning, half of it was gone." | 4시간의 절반=2시간, 11+2=1시 → 01:00 | 24시간 표기(01:00 vs 13:00) | **"saw a light at eleven"은 '11시에 켜졌다'가 아님** — 10시 반에 켜졌다면 12시 반. 힌트 1 "Find when the light went **on**"이 텍스트에 없는 전제 | 1300/2300/0300 feedback 좋음. 1100(12시간제 아이)·0130 등은 일반 문구 | 시간 4칸 0,1,0,0 입력 | R8: 반·4시간·자정 넘김·24시간제가 한 번에 — 부담 큼 | P2 |
| M2 경찰 보고서 | 공간·지도 추리 / 관찰 | 보고서 3줄: next to the stove / on the window sill / under the list desk + "Names are pressed into it" | 위치어로 3개 찾기 → 질문 답은 보고서 문장에 그대로 | 없음 | key/ink 각각 feedback으로 배제. 단일 | 힌트 2 "Copying presses names…" 유효. 잘못된 장소 탭도 "The report says UNDER it" 식 설명 — 좋음 | 그림 탭 | 위치 전치사 학습과 탐색이 자연스럽게 결합 | P3 |
| M3 퇴근부 | 논리 추리 / 증거 비교 | 9시·10시·11시 반·1시 15분 퇴근, 경비 "here all night, at the front door" | 1시 이후 퇴근자 = 남기호 | half past / a quarter past 이해 | 점원 중 단일. 그러나 **경비가 밤새 있었음**이 배제되지 않음(Haesu: "Nobody gets in at night. The guard sits at the front door.") | SEO/PAK/HAESU feedback 좋음 | 이름 타이핑(NAM, GIHO, MR NAM 허용 — 관대) | R8: a quarter past one 이해 필요, 힌트가 보완 | P2 |
| Final 김구의 질문 | 증거 비교 / 역사 지식 퀴즈 | 노트 요약 4줄이 답을 그대로 적음, 질문마다 증거 2개 중 택1 | when→e1, how→e2, who→e3, why police→e2 | 4번째는 "police guard the government" 역사 확인 | 단일, 그러나 2지선다 ×4 무작위 통과 | 힌트 "One of them is used twice" 좋음 | 탭 | 앞 3질문은 사건 해결, 4번째는 학습 확인 | P2 |

**영어 난이도 메모**
- R 평균 6.0어, 최장 15어. 문장 길이는 적정. J 6.6 / M 6.9, M 최장 25어 1개 — 레벨 차이 약~보통.
- 설명 없는 추상·역사어: synopsis "Korea's **government in exile**", intro "the **Provisional Government of the Republic of Korea**", "the **March First Movement**" — C08은 이 이름을 한 번도 쓰지 않았고(C08 텍스트에 "March First" 0회), 'provisional'·'exile' 뜻은 한국어 글로서리뿐. 왜 정부가 '외국 도시'에 있는지(일제 지배)도 없음 → C08-3과 같은 뿌리.
- 시간 표현 "half past eleven", "a quarter past one", 24시간 "01:00"이 한 Case에 몰림. 학습목표와 일치하나 R8에겐 무거움.
- 이름 혼동: 퇴근부의 "Mr. Pak"은 C07 짐꾼 Mr. Pak과 같은 이름.

**이슈 목록**
| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C09-1 | P2 | `missions[0].play.letter` "The guard saw a light in the office window at eleven." + hints[0] "Find when the light went on" | 켜진 시각이 명시되지 않음(11시에 '보였다') | 논리적인 아이는 "11시 전에 켜졌을 수도"; 정답은 전제를 받아들여야만 나옴 | "At eleven, the guard saw the light **go on**." 또는 "I lit a new candle at eleven" | S | 없음 |
| C09-2 | P2 | `missions[2].play.letter` "The night guard: here all night, at the front door." / talk "Nobody gets in at night." | 밤새 있던 경비가 용의선상에서 배제되지 않음 | "경비도 있었잖아?" — 답이 하나라는 확신 불가 | "The guard never goes upstairs: the stairs door is locked from the office side" 등 1줄 | S | 없음 |
| C09-3 | P2 | `missions[1].play.transition` "laid thin paper on the list and wrote over it. The names are pressed into the paper, but not inked." / `final.play.ending[0]` "Mr. Nam Giho has left Shanghai. The real list is safe." | 복사 방식이 물리적으로 모호(위에 써서 눌렸는데 잉크가 없다?) + 베낀 사본의 행방·범인 도주가 해소되지 않음 | "그럼 명단 이름들은 위험한 거야?" — 사건이 해결된 느낌 약함 | "This is the sheet under his copy: the pen pressed through" + 엔딩에 "Kim Gu warns everyone on the list" 1줄 | S | C10 연결 확인 |
| C09-4 | P2 | `play.intro[0]` "You are a guest of Kim Gu", intro[4] 김구가 이미 걱정을 말함 ↔ `final.play.story[1]` "\"I am Kim Gu,\" he says. \"I am the police chief here.\"" | 이미 손님으로 함께 있는 사람이 처음 만난 듯 자기소개 | 이야기 모순 | Final story를 "Kim Gu comes up the stairs. 'Show me your proof.'"로 | S | 없음 |
| C09-5 | P2 | `final.play.interview.presents` (각 offered 2개), presents[3] "Why does our government need police, so far from home?" | 2지선다 4회 + 노트 요약이 답을 적어 둠, 4번째는 역사 확인 | 생각 없이 통과, Final이 학습 테스트화 | 증거 전체에서 선택, 4번째는 대사로 처리 | S | C07 Final 동일 |
| C09-6 | P2 | `play.intro[1-2]`, `synopsis[0]` | March First Movement·Provisional Government·government in exile 설명 없음, C08은 이 명칭을 안 씀 | 정부가 왜 상하이에? 임시가 뭐지? | C08 엔딩에 "This was the March First Movement." 1줄, C09 intro에 "a Korean government outside Korea, because Japan ruled Korea" | S | C08, C10–C12 |
| C09-7 | P3 | `missions[1].play.successMessage` "You found all three things!" | 질문은 '어느 것이 복사 증거인가'인데 성공 문구는 찾기 완료 | 경미한 어긋남 | "The thin paper shows the list was copied!" | S | 없음 |
| C09-8 | P3 | `missions[2].play.letter` "Mr. Pak: left at ten." | C07 박 씨와 동명 | 같은 사람인지 혼동 | 다른 성(Mr. Choi 등) | S | C07 |
| C09-9 | P3 | M1 시간 입력 0100 | 앞자리 0 입력, 24시간제 | 1:00을 '0100'으로 칠 생각을 못 함 | C06-7과 동일 해결 | S | C06 |

**6항목 점수**
- 풀이 가능성 4/5 — 답은 모두 화면 정보에서 나오나 M1 전제·M3 경비 배제가 약함.
- 퍼즐 다양성 4/5 — 시간 계산·위치어 탐색·기록 대조·증거 제시. 형식은 다양.
- 영어 난이도 3/5 — 문장 길이 적정, 임시정부·망명·3·1운동 무설명, 시간 표현이 R8에 몰림.
- 역사 5/5 — 1919.4 상하이 임시정부, 김구 1919.8 경무국장('문지기' 일화), 1940 주석, 명백한 오류 없음.
- 개연성 3/5 — 언제·어떻게·누가 구조는 탄탄. 김구 자기소개 모순, 범인 도주·사본 행방 미해소.
- UX·힌트 4/5 — M2 위치 오답 피드백 우수, Final 2지선다는 너무 쉬움.
- **종합 3.8/5**

---

## 종합 (Case 06–09)
- 심각도 집계: **P0 0 / P1 0 / P2 20 / P3 13** (C06 P2×5·P3×3, C07 P2×5·P3×3, C08 P2×4·P3×4, C09 P2×6·P3×3). P0/P1로 올릴 만한 '진행 불가·단서 없는 정답·명백한 역사 오류'는 확인되지 않음(코드 분석 기준).
- 가장 큰 공통 문제:
  1. **일제의 한국 지배(1910) 배경이 시즌 어디에도 없음**(C08-3) → independence, police, 임시정부, 상하이 망명 정부의 의미가 영어권 아이에게 성립하지 않음. 1~2줄로 해결 가능, 효과 최대.
  2. **글로서리 뜻이 한국어**(C06-G) → envoy/treaty/provisional 등의 유일한 설명 장치가 대상 아이에게 무용.
  3. **Final의 증거 제시가 2지선다 + 노트 요약이 답을 미리 적음**(C07-3, C09-5), C06 Final은 6타일 애너그램 어휘 시험(C06-1).
  4. 사건 결론이 그 시점 정보로 도출 불가하거나 전제가 숨어 있음: C07-1(사건 시각), C09-1(초 켠 시각), C09-2(경비), C06-2(노크 시각 범위).
  5. C08 Final 다이얼 기호(clock/watch/map)가 단서 그림과 대응하지 않는데 노트북은 "Match each picture to its number"라 안내(C08-1).
- 잘 된 점: C08 M1(증언 비교)·M2(시간 표현 재배열), C07 전체 흐름, C09 M2(위치어 탐색 + 장소별 오답 설명)는 "영어로 추리하는 탐정 게임" 목표에 잘 맞음. 민감 역사(이토 사살, 유관순)는 묘사 없이 사실 위주로 8세 수용 가능 — 단 이토의 정체·부모 사망 원인 등 맥락 1줄 보강 권장.
- 미확인: 앱 실행·이미지 판독(C06 정원 그림의 소나무 구멍, C09 사무실 물건 위치) 안 함. 테스트 미실행. C01 V4 정합은 C08 엔딩 문구와 증거 ID만 확인.

---

# PART 4 — Case 10~12 정밀 조사

## PART 4 — Seoul Case 10·11·12 + 시즌 피날레 감사 (읽기 전용)

- 기준: 8–12세 **영어권** 아이, 한글을 읽지 못함, 한국사 처음. R=8 / J=10 / M=12.
- 출처: `content_pipeline/seasons/s5_seoul/cases/s5_ep1{0,1,2}/case.plan.json`, `levels.json`, `season.plan.json`, `season.levels.json`, 생성본 `lib/data/generated/s5_seoul/s5_ep1{0,1,2}.g.dart`, 엔진 `lib/puzzles_v2/core/timeline_rules.dart`, `lib/features/mission/widgets/letter_lock.dart`.
- 생성본 대조: C10–12의 정답·유형·codeLength·옵션은 plan과 생성본이 **일치**(`s5_ep10.g.dart:78,154,218,266`, `s5_ep11.g.dart:59,129,180,241`, `s5_ep12.g.dart:73,148,202,277`). 문제 문장(“Six notes…”, “name of the letters” 등)도 생성본에 그대로 있음(`s5_ep12.g.dart:106,111,293,504`).
- 에셋: C10 시계 3장, C11 dorm_room/c11_copy_list/c11_drop_card, C12 office/트렁크 3장 모두 파일 존재(plan status는 `awaitingAssets`로 남아 있으나 실제 파일은 있음). dorm_room.webp·old_watch.webp는 직접 열어 확인.
- 모든 판단은 **코드 분석**(앱 실행·기기 플레이 안 함). 테스트도 실행하지 않음.

---

### Case 10 — The Two Watches (1932 상하이, 윤봉길·김구)

**사건 목표(한 문장):** 1932년 4월 29일 아침, 김구와 윤봉길이 바꾼 시계 중 김구가 쥔 것이 누구의 시계인지 밝히고 그날의 의미를 기록한다.

**목표 유지 평가:** 시작 질문 “Which watch is which?”는 M2에서 끝난다. M3(상자 자물쇠 DROP)와 Final(연도 1932)은 시계와 무관하다. 사건 질문이 중반에 끝나고, 후반은 ‘기록 보관’과 ‘역사 학습’으로 바뀐다. 시계를 바꾼 **이유**(윤봉길이 돌아오지 못할 것을 알았다)는 끝까지 나오지 않아서, 아이에게 시계 교환은 이유 없는 행동으로 남는다.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 김구가 아침 식사에 초대 | C09의 해수·김구 | 읽기 | 작은 집 도착, 문에서 회색 양복 청년과 스침 | 집 안에서 아침에 있었던 일을 알아야 함 |
| M1 | 아침 순서를 알아야 누가 어떤 시계를 가졌는지 알 수 있음 | 그릇 밑 물방울 쪽지(순서 단어가 섞인 문장) | 카드 5장 중 4장을 순서대로 배열(‘buy’는 함정) | “The Swap” 단서 | 김구가 쥔 시계가 누구 것인지 질문 생김 |
| M2 | 교환 뒤 김구의 시계 판별 | M1 단서(식사 후 교환) + 해수 설명(낡음/새것/줄) | 그림 3장 중 선택(이름 숨김) | 김구=윤봉길의 새 시계 | 해수가 이 아침을 상자에 남기려 함 |
| M3 | 해수가 상자에 기록을 넣으려면 자물쇠를 열어야 함 | 시즌 내내 본 물방울 표식 | P·O·D·R 타일로 DROP | 쪽지 보관 | “이날이 정부에 무슨 의미?” — 연결이 약함 |
| Final | 몇 주 뒤 해수의 기록 | 해수 페이지(1919/1932를 영어 단어로) | 연도 4자리 입력 1932 | 그날 이후 중국의 지원 | 상자가 서울로 감(C11 연결) |
| Ending | 김구의 회고 | 새 시계 | 읽기 | “I will not forget him” | — 원래 질문(어느 시계)은 M2에서 이미 끝남. Final은 사건 해결이 아니라 연도 확인 |

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정(모르는 아이 기준) | 외부 지식 필요 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 판단 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 Breakfast for Two | 순서 배열 / 논리 추리 | 쪽지 5줄: “At the end…alone / Before that…goodbye / …breakfast first / After breakfast…swapped / …did not buy it this morning” | first→eat, after breakfast→swap, at the end→alone, before that→goodbye. ‘buy’는 “did not buy it this morning”으로 제외 | 없음 | eat,swap,goodbye,alone 하나뿐. ‘buy’를 넣는 4장 조합은 모두 오답 | 힌트 2개가 ‘at the end/before that’을 설명해 좋음. orderFeedback은 R/J에서 “Those are the right steps”라고만 해서 순서가 틀렸다는 말이 약함(M만 “but not their order”) | 카드 탭 배열, 쉬움 | R에 적합. 순서 단어를 영어로 실제 쓰게 하는 좋은 퍼즐 | OK(P3: R/J orderFeedback 문구) |
| M2 Which Watch? | 증거 비교 / 단순 선택 | 해수 설명(낡고 긁힌 케이스=김구 것, 매끈=윤 것, 가죽 줄=해수 것, 서로 바꿈) + 그림 3장 | 교환 → 김구는 윤의 시계 → 윤의 것은 새것 → 매끈한 시계 | 없음 | 정답 하나. 다만 줄 시계는 “her own watch”로 바로 빠져서 사실상 2지선다 | 힌트2 “After the swap, Mr. Kim has Mr. Yun's watch. Is it old or new?”가 사실상 정답 공개. 오답 피드백은 이유를 설명함 | 그림 탭(이름 숨김), 쉬움 | R 적합, M에게는 너무 쉬움 | **P1**(장면 모순, C10-1) |
| M3 The Box's New Lock | 영어 어휘 / 반복 탭 | “Every note…the same small mark: a small water drop. The lock wants the last word.” 타일 P,O,D,R | 같은 문장 안의 마지막 단어 drop을 타일로 입력 | 없음 | 정답 하나지만 타일 4개가 정답 글자뿐이라 24가지를 무작위로 눌러도 풀림 | 힌트2 “A small water ...”가 답을 거의 알려 줌. orderFeedback은 R/J에서 “right letters”라고만 함 | 타일 4개, 쉬움 | 모든 레벨에 추리 없음 | P2(C10-3) |
| Final After That Day | 역사 지식 퀴즈 / 암호 해독(숫자 단어→숫자) | 해수 페이지: “nineteen nineteen” “nineteen thirty-two”, “After that day…Chinese leaders began to help” | 질문 “In which year did Chinese leaders begin to help strongly?” → after Mr. Yun's day → 1932 | 없음(텍스트 안에 있음) | 1932만 정답. 1919·0429만 오답 피드백이 있고, 1933 등은 일반 피드백 | 힌트2 “Find the year of Mr. Yun's day. Write it with four numbers.”가 답 공개. 1932는 intro·synopsis·M1 위치 등 거의 모든 화면에 숫자로 보여서 **외워서 입력 가능** | 숫자 4자리 입력 | 영어 숫자 단어 읽기는 R에 좋은 연습. 하지만 사건 해결이 아닌 학습 확인 | P2(C10-2) |

**영어 난이도 메모**
- R 평균 문장 5.5단어(통계), 짧고 명확함. M1의 순서 단어 학습이 잘 짜여 있음.
- 레벨 차이는 대부분 동의어 바꾸기 수준: R “passes you” / J “you pass” / M “brushes past you”, R “eat breakfast” / M “share my breakfast”. J와 M 차이가 작음.
- R에서 설명 없는 단어: “Provisional Government”(ending, R), “attacked a Japanese army event”(event가 모호), “the keepers' mark”(시즌 용어라 이해 가능).
- 민감 내용: 폭탄·사상자·사형은 말하지 않음. “he attacked… He was caught at once.”만 있음 → 8세에게 적절한 수위. 다만 plan notes는 “Yun's arrest and death are told once in the reveal”이라고 하는데 실제 텍스트에 죽음은 없음(ending의 “I will not forget him”으로 암시만). 의도와 텍스트가 어긋남(P3).

**이슈 목록**

| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C10-1 | **P1** | `s5_ep10/case.plan.json` missions[1].play.story[1] “Haesu lays two more next to it: his old case and her own watch.” + answerSpec.options[old_watch] (그림 `case_10/old_watch.webp` = 줄 달린 온전한 시계) ↔ 같은 미션 transition “Mr. Yun took Mr. Kim's old, scratched watch.” 및 오답 피드백 “After the swap, who has it?” | 윤봉길이 김구의 낡은 시계를 가져갔다고 하는데, 그 시계가 지금 탁자 위에 있음. 퍼즐의 핵심 증거끼리 모순 | 꼼꼼한 아이일수록 “윤이 가져갔다는 시계가 왜 여기 있지?”라며 교환 자체를 의심하게 됨 | 낡은 시계 대신 해수의 **스케치/메모 카드**를 놓거나, 해수가 “I drew his old watch” 같은 그림을 보여 주는 식으로 바꿈. 또는 선택지를 ‘김구 손의 시계 + 시계점 영수증의 설명’ 같은 실물로 교체 | S | 없음 |
| C10-2 | P2 | final.puzzle answerSpec “1932”, final.play.question, hints[1] | Final이 사건 해결(시계)이 아니라 연도 확인. 1932는 intro·synopsis·ending 등 화면 곳곳에 숫자로 나오고 힌트2가 답을 알려 줌 | 읽지 않고 1932를 입력해도 통과. 사건의 결론(시계/교환의 의미)을 쓰지 않음 | Final에서 앞의 증거(새 시계, 해수의 아침 기록)를 쓰게 함. 예: 김구가 간직한 시계가 무엇을 뜻하는지 증거로 고르기. 연도는 ending 문장으로 옮김 | M | C11 Final도 같은 패턴 |
| C10-3 | P2 | missions[2] answerSpec options P,O,D,R; play.letter 마지막 줄 | 타일이 정답 글자뿐이고 정답 단어가 같은 문장에 나옴. 시즌 내내 본 ‘water drop’이라 추리가 없음 | 4장을 아무렇게나 눌러도 금방 풀림 | 방해 타일 추가(W,A,T,E 등)나, 앞 증거에서 단어를 끌어오는 방식으로 변경. 또는 M3를 다른 메커니즘으로 교체 | S | C12 Final도 같은 ‘정답 글자만 타일’ |
| C10-4 | P2 | intro/M1–M3 전체, final.play.ending.text | 시계를 바꾼 이유가 끝까지 설명되지 않음. 사건의 감정적 핵심이 아이에게 전달되지 않음 | “왜 바꿨지?”에 답이 없어 사건이 사소하게 느껴짐 | 아이 수준의 한 줄 추가. 예: Kim: “He said, ‘I will need a watch only for a little while. You will need one for a long time.’” (죽음은 직접 말하지 않음) | S | 없음 |
| C10-5 | P3 | missions[1] hints[1] | 힌트2가 답을 그대로 줌, 줄 시계 때문에 사실상 2지선다 | M(12세)에게 너무 쉬움 | 힌트2를 “What did Haesu say about Mr. Yun's watch?”처럼 단서를 가리키게 수정 | S | — |
| C10-6 | P3 | missions[0]/[2] orderFeedback(R/J) | “Those are the right steps/letters.”만 있고 순서가 틀렸다는 말이 R/J에 없음(M만 “but not their order”) | 8세가 “맞다는데 왜 안 열려?”라고 헷갈림 | R/J에도 “…but in the wrong order” 추가 | S | 다른 Case 문구도 점검 필요 |
| C10-7 | P3 | missions[2].play.letter “The lock wants the last word.” | 편지의 마지막 단어는 ‘word’라 문장이 모호함(타일 덕분에 실제 오답은 안 나옴) | 잠깐 헷갈림 | “The lock wants the last word of our mark.” | S | — |
| C10-8 | P3 | notes[1] vs final.play.ending.text | plan은 ‘죽음을 한 번 말한다’고 하지만 텍스트는 암시만 함 | (아이에게 문제 없음. 기획 기록과 실제가 다름) | 의도를 정해 notes나 텍스트 중 하나를 맞춤 | S | — |

**6항목 점수**
- 풀이 가능성 4/5 — 모든 퍼즐이 화면 단서만으로 풀림. 다만 M2 장면 모순이 논리를 흐림.
- 퍼즐 다양성 3/5 — 순서·그림 선택·타일·숫자로 형식은 다양. M3와 Final은 추리가 거의 없음.
- 영어 난이도 4/5 — R이 짧고 순서 단어 학습이 좋음. J/M 차이는 약함.
- 역사(명백한 오류만) 4/5 — 날짜·교환·체포·중국 지원 모두 통설과 맞음. 명백한 오류는 찾지 못함.
- 개연성 2/5 — 교환 이유 없음, 낡은 시계 모순, Final이 사건과 무관.
- UX·힌트 3/5 — 힌트가 답을 공개하는 경우가 많고, R/J 순서 피드백이 약함.
- **종합 3.3/5**

---

### Case 11 — The Poet's Three Copies (1941 연희전문, 윤동주)

**사건 목표(한 문장):** 윤동주가 친구를 위해 손으로 베낀 시집 한 부가 책상에서 사라졌으니, 그것을 찾아 친구에게 전한다.

**목표 유지 평가:** M1(쪽지 발견) → M2(카드의 거짓 줄 → 흑백 건반) → M3(피아노 속 상자 열기 → 사본 회수)까지 목표가 잘 이어진다. 사건은 **M3에서 해결**되고, Final(“어떤 언어로 썼나” → KOREAN)은 사건 해결이 아니라 의미 확인이다. 원래 문제(친구에게 전달)는 ending 문장 “Yun gives the copy to his young friend”로 마무리된다. 이번 감사 범위에서 인과가 가장 탄탄한 Case.

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 사본이 사라짐 | C10 끝: “Miri will take the box home to Seoul” | 읽기 | 윤동주의 방 | 단서를 찾으려면 책상을 봐야 함 |
| M1 | 누가 가져갔는지 단서 | 윤의 말(빨간 책등의 두꺼운 책, 파란 점은 잉크가 아님) | 돋보기로 책상 탐색 → 사전 밑 쪽지 → 빈칸 WATER 입력 | 키퍼의 물방울 쪽지 발견 | 쪽지(카드)가 위치를 알려 줄 것 |
| M2 | 카드가 왜 목록과 같은 모양인지 | 윤의 목록 + M1에서 들은 “white string” | 두 문서를 비교해 다른 줄 탭(STRING) | 거짓 줄 = BLACK AND WHITE, 끝말 “keys of these colours” | 흑백 건반 → 강당 피아노(게임이 대신 말해 줌) |
| M3 | 피아노 속 상자가 숫자 자물쇠로 잠겨 있음 | 목록의 “2 OF 3”, “18 + 1” | 3 + 19 → 319 입력 | 사본 회수, 미리 등장, 숨긴 이유 설명 | 사본을 친구에게 전해야 함 |
| Final | 사본의 의미 | 노트의 1938 사실, 왕의 글자 | KOREAN 타이핑 | 의미 확인 | 상자가 충칭으로(C12 연결) |
| Ending | 친구에게 전달 | 사본 | 읽기 | 1948 출판 | 상자의 다음 행선지 |

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정(모르는 아이 기준) | 외부 지식 필요 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 판단 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 The Desk by the Window | 관찰 및 단서 찾기 / 영어 어휘 | 윤의 편지 “thick book with a red spine… It is a drop of ____.”, 탐색 지점 6곳(잉크병·사본 2권·사전·쪽지·램프). 쪽지는 사전을 본 뒤에만 열림(`requires: dictionary`) | 빨간 책등 책 → 그 밑 쪽지 → 빈칸. 시즌 내내 ‘water drop’을 봤고 힌트2(분이의 물동이)도 있음 → WATER | **한글 읽기 필요 없음**(그림 확인: 쪽지에는 파란 점만 있음). 힌트2는 C01 기억을 쓰지만 ‘water drop’ 표식만으로도 충분 | WATER 하나. INK·RAIN에는 맞춤 피드백 있음 | 힌트 좋음. 오답 피드백이 이유를 설명함 | 돋보기 드래그 또는 탭 + 타이핑. 8세도 가능 | R 적합. 추리는 가벼움 | P2(C11-4 인과) |
| M2 Yun's List | 증거 비교 / 관찰 | 목록: COPY 2 OF 3 / FOR JEONG BYEONG-UK / POEMS 18 + 1 OPENING / STRING WHITE. 카드: 같은 내용에 STRING만 BLACK AND WHITE, 끝말 “It is safe under keys of these colours.” | 두 문서를 한 줄씩 비교 → STRING만 다름 → 양쪽 STRING 탭(string:string) | 없음 | 하나. 다른 줄 조합(copy:copy 등)은 “둘 다 같다”는 피드백. 제목 “MY FRIEND'S COPY” vs “YOUR FRIEND'S COPY”도 서로 달라 눈에 띔(줄이 아니라 탭은 안 됨) | 힌트2가 M1의 흰 끈을 떠올리게 함. 오답 피드백이 이유를 설명함 | 문서 탭 → 줄 탭, 명확 | R 적합. 핵심 추리(흑백 건반 → 피아노)는 transition이 대신 말해 줌 | P2(C11-1) |
| M3 The Box in the Piano | 암호 해독 / 논리 추리(+ 덧셈) | 미리: “First: the number of copies. Then: the number of poems in each copy. Like this: 2 copies and 15 poems is 215.” 윤: “copy 2 of 3, and 18 + 1 opening poem.” | 3부, 18+1=19 → 319 | 없음 | 319 하나. 219(복사본 번호를 넣은 함정)·119·193에 피드백 있음 | 힌트 2개가 단계별로 좋음. 예시(215)가 형식을 알려 줌 | 숫자 3자리 | 모든 레벨에 적합. 이 Case에서 가장 좋은 퍼즐 | OK |
| Final In His Own Language | 역사 지식 퀴즈 / 영어 어휘 | 노트: “In 1938, Korean became only a choice subject… Yun's pages are written in the King's letters. King Sejong made his letters for the people's own language.” | 왕의 글자 = 한국말을 쓰는 글자(C01에서 배움) → KOREAN. 단어 ‘Korean’이 첫 줄에 이미 나옴 | 아주 약간(왕의 글자=한국어 표기). C01에서 배운 내용 | KOREAN(+KOREAN LANGUAGE). JAPANESE/HANGEUL/CHINESE/ENGLISH는 맞춤 피드백 | 힌트2 “King Sejong's letters write the language of Korea.”가 답 공개. 가장 흔한 영어 철자 “HANGUL”은 맞춤 피드백이 없어 “Check your spelling”으로 빠짐 | 타이핑(6글자) | R 가능. 사건 해결 아님 | P2(C11-2) |

**영어 난이도 메모**
- R 평균 6.1단어, 최장 14단어로 적절함. J/M은 “bound with”, “askew”, “bears no writing”, “closing words” 등으로 실제 어휘 차이가 있음(C10보다 레벨 차이가 뚜렷함).
- 어려운 개념: “a choice subject”(R·J·M 모두. 영어권 아이에게 ‘elective’ 개념이 낯설고 표현도 어색함), “opening poem”(서시), “A man from the office checks the rooms”(누가 왜 위험한지 모호함).
- **정책 위반:** M3 편지에서 R은 “I hid the copy in our family's letter box.”와 “Tonight a man from the office is checking the rooms.”가 **빠짐**(levels.json m3 letter, R 6줄 vs J/M 7줄). 이야기는 레벨마다 같아야 한다는 정책에 어긋남. R은 talk 줄(“Papers in Korean can get a student in trouble now.”)로만 이유를 들음.
- 민감 내용: 윤동주의 옥사는 **전혀 언급하지 않음**. “Papers in Korean can get a student in trouble now.”는 8세에게 적절한 수위. 다만 1948년 책이 된 이유(본인은 볼 수 없었음)가 빠져서, 아이는 윤이 직접 출판했다고 생각할 수 있음. 넣을지는 기획 결정(P3).

**이슈 목록**

| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C11-1 | P2 | missions[1].play.transition[1–2] “Black and white keys!” / “Something in the college hall has keys like that,” Yun says. | 가장 재미있는 추리(흑백 → 건반 → 피아노)를 게임이 대신 말해 줌. 아이는 다른 글자 찾기만 함 | 탐정 역할이 ‘다른 그림 찾기’로 줄어듦 | M2 뒤에 짧은 선택 단계(강당 그림에서 흑백 ‘건반’이 있는 물건 탭: piano / chessboard / typewriter)를 추가하거나 M3 첫 동작을 피아노 찾기로 만듦 | M | 없음 |
| C11-2 | P2 | final.puzzle answerSpec “KOREAN”, final.play.letter, hints[1] | Final은 사건 해결 뒤의 의미 확인 퀴즈. 정답 단어가 편지 첫 줄에 있고 힌트2가 답을 공개함 | 퍼즐이 아니라 확인 문제로 느껴짐 | 사본을 친구에게 건네는 행동과 묶기. 예: 문 앞 세 사람 중 목록의 FOR(정병욱)에 맞는 사람 찾기. 언어 사실은 ending으로 옮김 | M | C10 Final과 같은 패턴 |
| C11-3 | P2 | `s5_ep11/levels.json` missions[2].play.letter rookie | R에서 미리가 숨긴 이유 두 줄이 빠짐(레벨마다 이야기가 달라짐) | R 아이는 ‘왜 미리가 숨겼나’를 talk 한 줄로만 앎 | R에도 짧게 추가: “I hid the copy here. A man is checking the rooms tonight.” | S | 다른 Case R 텍스트도 점검 필요 |
| C11-4 | P2 | missions[0].play.letter “Something small is under the dictionary now. The blue spot on it is not ink.” | 윤이 아직 아무도 보지 않은 물건의 위치와 파란 점이 잉크가 아니라는 것까지 알고 있음. 그러면서 직접 들추지 않음. 또 M1은 쪽지가 “in the King's letters”라는데 M2 카드는 영어 대문자로 보임 | 인과가 어색함(“윤은 어떻게 알아?”) | 윤은 “Someone moved my dictionary.”까지만 말하고, 파란 점은 아이가 찾은 뒤 윤이 “That is not ink…”라고 반응하게 순서를 바꿈. 카드는 ‘번역해 읽어 준다’는 한 줄을 넣음 | S | — |
| C11-5 | P3 | final.play.feedback 키 HANGEUL | 영어권에서 흔한 철자 “HANGUL”을 입력하면 맞춤 피드백 대신 “Check your spelling. It is the language of Korea.”가 나옴(철자 문제가 아닌데 철자 탓을 함) | 혼란 | HANGUL도 같은 피드백 키에 추가 | S | — |
| C11-6 | P3 | final.play.letter “a choice subject” | 어색하고 추상적인 표현 | 의미 파악이 어려움 | R: “In 1938, schools stopped needing to teach Korean.” | S | — |
| C11-7 | P3 | missions[1].play.records 제목 MY/YOUR FRIEND'S COPY | 제목도 달라서 ‘다른 점 찾기’에서 방해가 됨 | 제목을 탭하려다 반응이 없음 | 제목을 같게 하거나 카드 제목을 “FRIEND'S COPY”로 | S | — |
| C11-8 | P3 | final.play.ending.text | 1948 출판의 맥락(윤은 그 전에 세상을 떠남)이 없음 | 아이가 오해할 수 있음 | 넣는다면 아주 부드럽게: “Yun did not live to see it.” — 기획 결정 | S | — |

**6항목 점수**
- 풀이 가능성 5/5 — 모든 단서가 화면에 있고, 복수 정답 없음, 한글 읽기 필요 없음.
- 퍼즐 다양성 4/5 — 돋보기 탐색·문서 비교·숫자 자물쇠·단어 입력. Final만 약함.
- 영어 난이도 4/5 — R이 짧고 레벨 차이가 실제로 있음. “choice subject”, R 누락 줄이 감점 요인.
- 역사(명백한 오류만) 5/5 — 사본 3부(스승·정병욱·본인), 18+1편, 1938 선택과목화, 1948 출판, 정병욱 가족이 마루 밑에 숨김 모두 통설과 맞음.
- 개연성 4/5 — 흐름이 탄탄함. M1에서 윤의 ‘미리 앎’과 M2 추리 대행이 감점 요인.
- UX·힌트 4/5 — 오답 피드백이 이유를 잘 설명함. Final 힌트2는 답 공개.
- **종합 4.3/5**

---

### Case 12 — The Day the Light Returned (1945 충칭, 광복)

**사건 목표(한 문장):** 서울에서 온 키퍼들의 상자를 찾아 쪽지를 순서대로 되돌리고, 광복의 날 마지막 물방울 쪽지를 읽는다.

**목표 유지 평가:** M1(트렁크) → M2(쪽지 순서) → M3(날짜) → Final(LIGHT)로 상자와 ‘마지막 쪽지’라는 목표가 유지된다. 다만 타일 H/T/I/G/L은 빛나가 남겼다는 것 말고 **왜 남겼는지** 동기가 없다(무작위 글자 수집). 시즌 결말(분이의 첫 쪽지)은 **C01 V4와 내용이 어긋난다**(C12-1).

**인과관계 표**

| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 상자가 충칭에 도착 | C11 끝: 미리가 상자를 충칭으로 보냄 | 읽기 | 사무실, 의자 위 물방울 쪽지 | 상자의 위치를 찾아야 함 |
| M1 | 상자가 트렁크 안에 있음 | 책상 쪽지(끈 1개 + 둥근 놋쇠 자물쇠) | 사무실 탐색 → 쪽지를 읽어야 트렁크가 열림 → 3개 중 선택 | 상자 + 타일 H | “누가 남겼지?” |
| M2 | 상자를 열자 쪽지가 쏟아짐 | 해수가 뚜껑 안에 쓴 순서 규칙 | 타임라인 보드(양 끝 고정, 그림은 버리기) | 순서 복원 + 타일 T, I | 사무실에서 고함 |
| M3 | 라디오 뉴스 | 라디오 “fifteenth of August”, 빛나의 월 카드 | 815 입력 | 날짜를 적음 + 타일 G, L | 강가 계단으로 |
| Final | 마지막 쪽지 ‘광복’ | 타일 5개, 빛나의 설명(gwang = opposite of dark) | 타일로 LIGHT | 마지막 쪽지가 위에 놓임 | 시즌 종료 |
| Ending | 광복의 의미 | — | 읽기 | 연합국 승리 + 많은 한국인의 노력. “Bun-i's first note started it all.” | 원래 문제(마지막 쪽지)는 해결됨. 분이 쪽지의 내용은 보여 주지 않음 |

**미션별 상세표**

| Mission | 주/보조 유형 | 실제 단서(화면) | 정답 도출 과정(모르는 아이 기준) | 외부 지식 필요 | 복수 정답 검사 | 힌트/오답 | 조작 | R8/J10/M12 판단 | 심각도 |
|---|---|---|---|---|---|---|---|---|---|
| M1 The Trunk by the Wall | 관찰 및 단서 찾기 / 증거 비교 | 쪽지: “ONE leather strap… a round brass lock”. 트렁크 3개(끈2+놋쇠, 끈1+나무못, 끈1+놋쇠). 쪽지를 읽기 전에는 트렁크가 잠김(unreadLine) | 두 조건을 모두 만족하는 것은 하나뿐 | 없음 | 하나. 오답 둘은 각각 조건 하나만 맞음(좋은 설계) | 힌트 좋음. 오답 피드백이 빠진 조건을 정확히 말함 | 탐색 탭 + 선택 | 모든 레벨에 적합 | OK |
| M2 Eleven Notes and One Box | 순서 배열 / 논리 추리 | 뚜껑 글: 분이(1446) 맨 아래, 미리(1941) 맨 위, Seok<Okbun<Duri<Gyeongsun, 물방울 없는 쪽지는 제외. 카드에 이름 + 한 줄 설명. 분이·미리 카드는 엔진에서 위치 고정(`timeline_rules.dart` anchors) | 고정 두 장 사이에 이어진 관계 사슬을 그대로 배치하고, 그림은 버림 | 없음(이전 Case 기억이 있으면 확인 가능. 1592/1795/1866/1919) | bun_i,seok,okbun,duri,gyeongsun,miri 하나뿐(관계가 하나의 사슬) | 힌트 좋음. orderFeedback은 고정 문구 “Who wrote after Okbun?”이지만 엔진이 틀린 칸의 관계 줄을 짚어 줌(코드 분석) | 드래그/탭 배치 | R 적합. 시즌 회수로도 좋은 퍼즐 | **P1**(C12-1 내용), P2(C12-2 개수) |
| M3 News on the Radio | 암호 해독(날짜 변환) / 영어 어휘 | 라디오 “fifteenth of August”, 카드 “August is month eight”, “month before the day” | 8 + 15 → 815 | 없음 | 하나. 715/915/814에 피드백 있음 | 힌트2가 거의 답 공개. 피드백은 이유를 설명함 | 숫자 3자리 | R 적합. 탐정 요소는 약함 | P3 |
| Final The Last Water-Drop Note | 영어 어휘 퀴즈 / 조합 및 구성 | “Gwang (광) is the opposite of dark… Spell what gwang means, in English.” 타일 H,T,I,G,L | opposite of dark → LIGHT | 없음(한글은 로마자와 함께 표시되고 읽을 필요 없음) | 하나. 타일 5개가 정답 글자뿐이라 120가지 순열을 무작위로 해도 결국 풀림 | 힌트2 “Day is full of it…”가 사실상 답 공개 | 타일 5개 | 모든 레벨이 쉬움. 시즌 피날레로는 가벼움 | P2(C12-3) |

**영어 난이도 메모**
- R 평균 5.7단어, 최장 13단어로 매우 짧음. R 편지는 “Japan has given up”처럼 쉽게 풀어 씀(좋음). 하지만 discovery와 ending R은 “Japan has surrendered”, “surrendered to the Allies”를 그대로 씀 → **Allies, surrendered, government in exile, minister**가 R에 설명 없이 나옴.
- 레벨 차이: 표시 줄의 29%가 R=J=M 동일(통계). J/M 차이도 작음(“The sun sets / sinks”).
- “Write today's number on my note.” — 날짜를 ‘number’라고 부르는 것이 어색함.
- 민감 내용: 전쟁 종료를 기쁨과 울음(“some of them cry”)으로 표현해 8세에게 적절함. “No one person brought this day… The Allies won the war, and many Koreans worked for it.”는 균형 잡힌 서술. “worked for it”에서 it이 전쟁인지 그날인지 모호함(P3).

**이슈 목록**

| ID | 심각도 | 정확한 위치 | 실제 문제 | 아이가 겪는 어려움 | 개선 방향 | 수정 범위 | 다른 Case 영향 |
|---|---|---|---|---|---|---|---|
| C12-1 | **P1** | `s5_ep12/case.plan.json` missions[1].play.timeline.cards[0].text “The first note: the name of the letters.” (생성본 `s5_ep12.g.dart:504`, levels J/M `s5_ep12_levels.g.dart:392,1001`) | C01 V4에서 분이의 첫 쪽지는 엄마에게 쓴 편지 “엄마, 고마워요”(C01 caseSummary)이고, C08도 “It says 엄마, 고마워요. This is Bun-i's letter from 1446!”라고 함. C12는 그것을 ‘글자 이름 쪽지’로 바꿔 시즌 회수가 모순됨 | C01·C08을 기억하는 아이는 “분이가 쓴 건 엄마한테 고맙다는 편지였는데?”라며 혼란. 시즌의 감정적 회수를 잃음 | “The first note: Bun-i's letter to her mom. 'Mom, thank you.'”로 수정(R/J/M 모두) | S | 시즌 outro와 함께 맞춰야 함 |
| C12-2 | P2 | missions[1].play.title “Eleven Notes and One Box” / story “Six notes slide out onto the floor.” / final.play.transition “Bun-i's first note lies under eleven more.” | 상자의 쪽지 수가 맞지 않음. 6장만 순서에 나오고, 해수(C09–C10에서 직접 상자에 넣은 쪽지)·레이디 한(C05/06)·봉수(C07) 등의 쪽지는 사라짐. C10 M3 transition은 해수의 쪽지가 “on top of the others”라고 함 | “해수 아줌마 쪽지는 어디 갔지?” 제목은 11장, 화면은 6장 | “Eleven notes are inside. Six slide out onto the floor.”처럼 이유를 주거나, 해수 카드를 넣어 7장 순서로 만듦(관계 줄 하나 추가) | S–M | C05–C10 키퍼 설정 |
| C12-3 | P2 | final.puzzle answerSpec options H,T,I,G,L; missions[0..2] transition의 타일 발견 | 타일이 정답 글자뿐이고 빛나가 왜 타일을 남겼는지 동기가 없음(“The tiles were mine”뿐). 정답은 영어 어휘(opposite of dark)이고 힌트2가 답을 공개함 | 탐정 결말이 ‘반대말 퀴즈’가 됨. 무작위 배열로도 통과 가능 | 각 타일을 앞의 증거와 연결(예: 각 키퍼 쪽지 구석의 글자)하고 방해 타일 1–2개 추가. 또는 빛나의 이유 한 줄 추가(“I wanted the guest to find the word himself.”) | M | C10 M3와 같은 패턴 |
| C12-4 | P2 | final.play.ending.text “Bun-i's first note started it all.” / season outro | 분이 쪽지의 **내용**이 피날레에서 다시 나오지 않아 회수가 추상적임 | 8세는 ‘first note’가 무엇인지 연결하지 못함 | 결말에서 쪽지를 보여 줌: “At the bottom: 엄마, 고마워요. Mom, thank you. Signed with a water drop.” | S | season.levels.json |
| C12-5 | P3 | play.intro “On your chair lies a small note with a water drop.” vs missions[0].play.story “On the desk lies a small note…” | 쪽지 위치가 다름 | 사소한 혼란 | 하나로 통일(desk) | S | — |
| C12-6 | P3 | missions[0].play.talk.before “A box came for you from Seoul. A girl knows where.” | 소녀가 위치를 안다고 해 놓고 실제로는 쪽지가 알려 줌. 빛나는 M2에서야 등장 | 약한 엇갈림 | “A note on the desk knows where.” 또는 빛나가 쪽지를 남겼다고 명시 | S | — |
| C12-7 | P3 | final.play.ending.text “Kim Won-bong had worked for independence since 1919.” | 이 Case에서 인사만 한 인물이 결말에서 갑자기 강조됨. 아이가 아는 김구(C09–C10)는 나오지 않음. 해방 후 행적 때문에 한국 보호자에게 민감할 수 있음(역사 담당이 검토) | 왜 이 사람인지 모름 | 결말은 ‘많은 사람’ 줄로 충분. 김원봉 줄을 빼거나 김구/해수와 함께 언급 | S | — |
| C12-8 | P3 | missions[2] play.letter “Write today's number on my note.” | 날짜를 ‘number’로 부름. 815는 한국 아이에게는 상식이지만 영어권 아이에게는 카드로 배우는 구조라 괜찮음 | 약간 어색함 | “Write today's date in numbers.” | S | — |
| C12-9 | P3 | missions[2].play.discovery, final ending(R) | R에 surrendered/Allies가 설명 없이 나옴 | 단어 이해 부족 | R: “Japan gave up. The war was over.” + ending에서 “the Allies (the countries fighting Japan)” | S | — |

**6항목 점수**
- 풀이 가능성 5/5 — 모든 퍼즐이 화면 단서만으로 풀리고 복수 정답 없음.
- 퍼즐 다양성 3/5 — M1·M2는 좋음. M3(날짜 변환)와 Final(반대말 타일)은 가벼움.
- 영어 난이도 4/5 — R이 매우 짧음. surrendered/Allies 같은 미설명 어휘와 약한 레벨 차이가 감점 요인.
- 역사(명백한 오류만) 5/5 — 1945.8.15 항복, 광(光)/복(復) 뜻, 김원봉 1944년 군무부장, 충칭 임시정부 모두 맞음.
- 개연성 3/5 — 상자 흐름은 좋지만 C01 쪽지 내용 모순, 쪽지 수 불일치, 타일 동기 없음.
- UX·힌트 4/5 — 잠금 단계(쪽지를 읽어야 트렁크가 열림)와 오답 피드백이 좋음. Final·M3 힌트2는 답 공개.
- **종합 4.0/5**

---

### 시즌 피날레 / 아웃트로 (`season.plan.json` outro·finale, `season.levels.json`)

- 아웃트로: “Bun-i's first note lies under all the others.” / “The letters she learned in 1446 are read freely again.”
- 피날레: “Seoul keeps its story in its letters.” / “This time, you read it note by note.”

판단
1. **회수의 일관성:** 아웃트로 자체는 C01 V4(분이가 1446년에 글자를 배워 쓴 쪽지)와 모순되지 않음. 그러나 C12 M2 카드가 그 쪽지를 “the name of the letters”라고 해서 **같은 화면 흐름 안에서 두 설명이 갈림**(C12-1). 카드를 고치면 아웃트로는 그대로 써도 됨.
2. **추상성(P2):** “read freely again”은 C11의 ‘학교에서 밀려난 한국어’를 기억해야 이해되는 표현이라 8세에게 추상적임. R 제안: “Now people can read and write Bun-i's letters again, at school and at home.”
3. **감정 회수 부족(P2, C12-4와 같은 이슈):** 시즌을 시작한 장면(엄마에게 쓴 “Mom, thank you”)이 마지막에 다시 나오지 않음. 한 줄만 넣어도 회수가 완성됨: “At the bottom of the box: 'Mom, thank you.' — and a small water drop.”
4. **기획 문서 내부 충돌(보고만 함, 수정하지 않음):** `planning/story_bible.json` truth는 “was given a small wooden letter box by Sora”(line 10, 65)라고 하고, 같은 파일 line 868과 C01 V4는 “her mother's wooden box” / “Her mother keeps the letter in a little wooden box.”라고 함. 상자를 준 사람(소라 vs 엄마)이 문서끼리 다름. C12 텍스트에는 드러나지 않지만 이후 수정 때 기준을 정해야 함.
5. 프롤로그의 “Find the keepers / Who keeps writing the notes?”는 C08에서 답이 나오고 C12에서 마지막 키퍼(빛나)로 닫혀서 시즌 질문은 해결됨.

---

### 심각도 집계(C10–12 + 피날레)
- P0: 0
- P1: 2 (C10-1 낡은 시계 장면 모순, C12-1 분이 첫 쪽지 내용이 C01 V4/C08과 모순)
- P2: 12 (C10-2, C10-3, C10-4, C11-1, C11-2, C11-3, C11-4, C12-2, C12-3, C12-4[피날레 감정 회수 포함], 피날레 “read freely again” 추상성, 스토리 바이블 상자 출처 충돌[문서])
- P3: 13 (C10-5~8, C11-5~8, C12-5~9)

실행하지 않은 것: 앱 실행·기기 플레이, 테스트 실행, 엔진의 오답 피드백 화면 표시 확인(코드 분석만), 역사 정밀 검증(다른 에이전트 담당).

---

# PART 5-A — Case 간 연속성

## Season 5 Seoul — 스토리 연속성 감사 (READ-ONLY)

작성 2026-11-09. 저장소 파일은 수정하지 않음. 경로 약칭: `CP/NN` = `content_pipeline/seasons/s5_seoul/cases/s5_epNN/case.plan.json`, `LV/NN` = 같은 폴더 `levels.json`, `G/NN` = `lib/data/generated/s5_seoul/s5_epNN.g.dart`, `SB` = `planning/story_bible.json`, `SP` = `season.plan.json`, `DUMP` = scratchpad `seoul_text_dump.md`.

## 0. 요약

- 케이스 연대는 1446 → 1592 → 1795/96 → 1866 → 1895 → 1907 → 1909 → 1919 → 1920 → 1932 → 1941 → 1945로 단조 증가하고, 역사 순서 오류는 없다.
- 시즌 실(물방울 쪽지 → 가족 → 편지 상자 → 광복)은 C02→C04(한 사람 아님)→C08(분이 가족·상자)→C12(마지막 쪽지)로 이어진다. 바로 앞 케이스의 증거를 recall로 받는 사슬(C02←C01, C03←C02, C04←C01/C02/C03, C05←C04, C06←C05, C07←C06/C05, C08←C07, C09←C08, C10←C09, C11←C10/C01, C12←C08/C01)이 G/*.g.dart에 실제로 들어 있다.
- **V4로 바뀐 Case 01과 맞지 않는 곳이 남아 있다.** 가장 큰 것은 C12 M2 카드 "The first note: the name of the letters."(P1)와 C08·C12가 분이의 편지를 `s5_ep01_e3`(현재는 "Bun-i's First Word", 엄마만)로 가리키는 것(P2)이다.
- 탐정이 500년을 건너는 방식은 게임 어디에서도 설명되지 않는다. "You are a guest of …"로만 반복되고, 지키미들은 "Detective,"라고 부르며 탐정을 알고 있다(P2).

---

## 1. 케이스 간 영향 / 시즌 실 / 시간 이동

| 연결 | 근거 (인용) | 판정 |
|---|---|---|
| C01→C02 | C02 m1 discovery "Bun-i, the girl who carried water, wrote the first note in 1446. Who draws her water drop now?" (CP/02); final ending "Seok's water drop is just like Bun-i's." | 연결됨 |
| C02→C03 | C03 m1 recall s5_ep02_e1 "The Same Mark?" (G/03:113); ending Okbun "Seok? My mother told me that name." | 연결됨 |
| C03→C04 | C04 final clueInputs s5_ep03_e1, s5_ep02_e1; ending "1592, 1795, 1866: the same water drop." / "Not one person. A family keeps writing them. But why?" | 연결됨. 단, **"But why?"에 대한 답이 게임에 없음** (아래 I-7) |
| C04→C05 | C05 m2 recall s5_ep04_e1 "A Drop Like Duri's" (G/05:181) | 연결됨. m1 clueInputs는 [] |
| C05→C06 | C06 m1 recall s5_ep05_e1; m2 story "You remember the strangers' map of 1895." | 연결됨 |
| C06→C07 | C07 m1 recall s5_ep06_e1; final clueInputs s5_ep06_e4 (1905 treaty forced) | 연결됨 |
| C07→C08 | C08 m3 recall s5_ep07_e1; Gyeongsun "Mrs. Kang in Harbin is my family too." | 연결됨 |
| C08→C09 | C09 m1 recall s5_ep08_e4; Haesu "Gyeongsun of Aunae is my cousin. She gave me the old box." | 연결됨 |
| C09→C10 | C10 m1 recall s5_ep09_e4 "Who is Haesu?" | 연결됨 |
| C10→C11 | C10 final transition "My cousin Miri will take the box home to Seoul."; C11 m1 "Haesu's notes had the same drop." | 연결됨 |
| C11→C12 | C11 final transition "Miri sends the old letter box far away. It goes to Haesu's family, in Chongqing."; C12 intro "Miri sent the old letter box here from Seoul." | 연결됨 |

**시간 이동:** 모든 intro가 같은 틀이다. "Summer, 1446. You visit King Sejong"(CP/01), "You are a guest of Admiral Yi Sun-sin"(CP/02), … "You are a guest of the Provisional Government in Chongqing"(CP/12). 프롤로그(SP.prologue / `s5_seoul_season.g.dart:24-45`)는 "They look like different cases. But a good detective puts the pieces together."라고만 말한다. **탐정이 어떻게 1446→1945를 오가는지, 왜 늙지 않는지는 게임 텍스트 어디에도 없다** (grep "travel / centuries / five hundred": 기획 문서에만 있음). 그런데도 탐정은 개인 기억으로 시대를 잇는다. "You remember the strangers' map of 1895."(C06 m2), "This is Bun-i's letter from 1446!"(C08), 그리고 지키미 쪽지는 탐정을 이름으로 부른다("Detective," C05 m1, C07 m1, C09 m1; C12 "A box came for you from Seoul."). 규칙 자체는 일관된다(항상 손님이고 역사를 바꾸지 않음, SB.themes). 다만 **규칙이 플레이어에게 설명되지 않고, 지키미들이 탐정을 아는 이유도 풀리지 않는다** → I-6.

## 2. 인물 일관성

| 인물 | 등장 | 이름/역할/행동 | 판정 |
|---|---|---|---|
| Bun-i | C01 (언급: C02, C08, C11, C12) | 물 긷는 소녀, 이름 대신 물방울로 서명(c1 "Bun-i cannot write her name. She signs with a water drop."). C11 "What did Bun-i carry in her bucket?" | 일치. 단, C12 M2 카드는 구판 설명(I-1) |
| Sora | C01 (언급: C02/C04 "Sora's board") | 궁녀, 글자를 가르침. 이후 "Sora's board" 내용 = C01 e2 "The Sound Board" | 대체로 일치. C02 보드는 "ㅁ = the mouth"와 "Flat vowels go under"를 담는데, C01 V4는 ㅁ=lips로 가르치고 세운 모음(점 좌/우)만 가르침(I-11, P3). SB는 "Sora gives Bun-i the little letter box"라고 하나 V4에 없음(I-4) |
| Taek | 없음 | V4에서 빠짐. C02–C12 표시 텍스트에 언급 0건(DUMP grep). SB/SP 캐스트에만 남음(SB characters taek "kept for the season's cast", SP.characters[1]) | 게임상 모순 없음. 문서 정리 대상(P3) |
| Seok | C02 | 16세 수병, "My grandmother taught me that mark." / "Who taught my grandmother? I never asked." | 일치 |
| Okbun | C03 | 물 긷는 12세, "Seok? My mother told me that name." | 일치 |
| Duri | C04 | 목수 견습, "My father taught me the mark."; "Duri lays three notes side by side." | 일치. 단, 쪽지 소재 모순(I-5) |
| Ham | C02 | 창고지기, 보고서 작성 | 단발, 문제없음 |
| Lady Han | C05 | 쪽지 "— Han", "Lady Han puts her note in a small wooden box.", "I will keep our letters, and the truth of these days." | 일치. 가족이라는 말은 C07 이후 간접적으로만 나옴 |
| Bongsu | C06 | "Bongsu folds his note and keeps it." / "I will keep my note." | 상자에 넣는다는 말 없음(I-5) |
| Mrs. Kang | C07 | "This one goes in my letter box."(하얼빈) | 상자 위치 모순(I-5) |
| Gyeongsun | C08 | 16세, 공책에 물방울, 상자 공개, "Bun-i was our first keeper." | 일치 |
| Haesu | C09, C10 (C12 언급) | Gyeongsun의 사촌, 쪽지 서명 "— a small water drop", 상자에 DROP 자물쇠 | 일치. C10 "Bitna … My daughter."는 SB의 Bitna 11세(1945)와 시점이 어긋남(I-12) |
| Miri | C11 | "I am Miri, Haesu's cousin."; 상자를 충칭으로 보냄 | 일치 |
| Bitna | C12 | "My mother Haesu keeps this box"; 타일·마지막 쪽지 | 일치 |
| Kim Gu | C09, C10 | 경무국장, Haesu를 신뢰 | 일치 |
| Mr. Pyo ×2 | C04 목재상, C08 소금장수 | 다른 악역인데 이름이 같음 | 혼동 우려(I-10, P3) |
| Mr. Pak ×2 | C07 짐꾼, C09 서기(sign-out book) | 다른 인물인데 이름이 같음 | P3 |

## 3. 교차 참조 원장 (ref → 사용처 → 묘사 → 현재 의미 → 일치?)

Case 01 현재 의미(CP/01): **c1** "Bun-i's Mark" = 물방울 서명 · **c2** "Letters from the Mouth" ㅁㄴㅇ · **c3** "The First Word" 엄마 · **e1** "Bun-i's Message"(그림 편지, 고맙다) · **e2** "The Sound Board"(ㅁ lips, ㄴ tongue, ㅇ throat, ㄱ, ㅅ, stronger sound adds a line) · **e3** "Bun-i's First Word"(편지 맨 위 엄마) · **e4** "Bun-i's Letter"(엄마, 고마워요 + 물방울).

| ref | 사용처 | 그곳의 묘사 | 현재 의미 | 일치? |
|---|---|---|---|---|
| s5_ep01_c1 | C02 m1 clueInputs (textMention) | "Bun-i, the water-carrier of 1446, left water drops by her note." | 물방울 **서명** | △ 내부 note가 구판 서술("left water drops by"). 표시되는 discovery("wrote the first note in 1446")는 무리 없음. P3 |
| s5_ep01_c1 | C02 final clueInputs (answerDerivation) | "Seok's water drop is Bun-i's mark" | 물방울 서명 | ✅ |
| s5_ep01_c1 | C11 m1 clueInputs + 힌트 | "what her bucket held" / "What did Bun-i carry in her bucket?" | 물 긷는 소녀의 물방울 | ✅ (V4 m1 "Bun-i sets down her bucket") |
| s5_ep01_e2 | C02 m2 recall (G/02:154 "Which page of your notebook shows how the letters are made?") | note "Sora's Lesson Board: … tongue, mouth, teeth, throat; stronger sound adds a line" | "The Sound Board" | ✅ 내용 일치. 이름 "Lesson Board"는 내부 note만(P3). C02 보드 글의 "ㅁ = the mouth"·평모음 규칙은 V4가 안 가르침(P3, I-11) |
| s5_ep01_e2 | C04 m1 recall (G/04:93 "how a stronger sound is written") | "a stronger sound adds one line (ㄴ, then ㄷ)" | e2 + V4 m2 transition "ㄴ, then ㄷ" | ✅ |
| s5_ep01_e3 | C08 final clueInputs + ending evidence (G/08:681, LV/08 → `s5_ep08_levels.g.dart:563,1137`) | "It says 엄마, 고마워요. This is Bun-i's letter from 1446!" | e3 = "Bun-i's First Word"(**엄마만**) | ❌ **불일치**. 편지 전체는 **e4**. 대사와 함께 뜨는 증거 카드가 "The top of Bun-i's letter … 엄마". P2 (I-2) |
| s5_ep01_e3 | C12 final clueInputs (evidenceLink), EvidenceLink `s5_ep12_e4 → s5_ep01_e3` "Bun-i's first note, from 1446, at the bottom of the box." (G/12:381-383) | 상자 맨 아래의 첫 쪽지 | e3 = 첫 낱말 | ❌ 상자 속 물건은 어머니가 간직한 **편지(e4)**. P2 (I-2) |
| s5_ep01_e3 | C12 final ending "Bun-i's first note started it all." (G/12:731; levels :613,1222) | 첫 쪽지 | 첫 낱말 | ❌ 같은 이유 (I-2) |
| s5_ep01_e3 | SB clueThreads from e3 → s5_ep08_final | "Bun-i's letter of 1446 (엄마, 고마워요, her water drop)" | 첫 낱말 | ❌ 문서도 e4여야 함 |
| (텍스트) Bun-i 첫 쪽지 | C12 m2 timeline card bun_i (G/12:504, LV/12:496-498, CP/12:419) | "The first note: the name of the letters." | 엄마, 고마워요 편지 | ❌ **P1** 구판(분이의 종이에 '훈민정음' 이름) 잔존 (I-1) |
| (텍스트) | SB characters bun_i.purpose | "her paper holds the name of the letters" | 같음 | ❌ 문서 잔존 |
| (텍스트) | C08 ending, C08 summary "Bun-i's note at the bottom", SP.outro "Bun-i's first note lies under all the others.", C12 final "under eleven more" | 상자 맨 아래 | V4 "Her mother keeps the letter in a little wooden box." | ✅ 상자·맨 아래는 일치 |
| s5_ep02_e1 | C03 m1 recall, C04 final | "Seok's note of 1592" | "The Water-Drop Note (1592)" | ✅ |
| s5_ep03_e1 | C04 final | "Okbun's water drop of 1795" | "The Water-Drop Note (1795)" | ✅ |
| s5_ep04_e1 | C05 m2 recall | "Duri's water-drop note" | "(1866)" | ✅ |
| s5_ep05_e1 | C06 m1 recall, C07 m1 | Lady Han 1895 | ✅ | ✅ |
| s5_ep05_e4 | C06 m2 | "strangers drew a map … palace is watched" | "The Strangers' Map" | ✅ |
| s5_ep06_e1 | C07 m1 recall | Bongsu 1907 | ✅ | ✅ |
| s5_ep06_e4 | C07 final | "1905 treaty was forced" | "The Emperor's Letter, with Yi Jun" | ✅ |
| s5_ep07_e1 | C08 m3 recall | Mrs. Kang 1909 | ✅ | ✅ |
| s5_ep08_e4 | C09 m1 recall, C12 m2 recall | "The keepers' letter box" | "The Keepers' Letter Box … Bun-i's note of 1446 is at the bottom" | ✅ |
| s5_ep09_e4 | C10 m1 recall | Kim Gu trusts Haesu | "Kim Gu's Case Note" | ✅ |
| s5_ep10_e1 | C11 m1 | "the same small blue drop" | Haesu 1932 note | ✅ (파란 물방울은 C01 assets "A blue water drop" LV/01:306에서 이미 나옴) |
| s5_ep11_e4 | C12 m1 | Miri가 상자를 보냄 | "Poems in Korean" | △ 증거 내용은 시집. 상자 발송은 C11 transition에만 있음. P3 |

Case 01 참조 소계: c1 ×3 일치(1건은 내부 note만 구판), e2 ×2 일치, **e3 ×4 불일치(e4여야 함)**, 텍스트 1건 P1 불일치.

## 4. 모순 점검

- **이미 푼 것의 재발견:** C04 ending에서 탐정이 이미 "Not one person. A family keeps writing them."이라고 결론 낸다. C02 ending에서는 "Seok's water drop is just like Bun-i's." + "My grandmother taught me that mark."가 나온다. 그래서 C08의 '분이 가족' 공개는 C02부터 강하게 예고된 셈이고, 반전 강도가 약하다(P2, I-8). 정면 모순은 아님.
- **배운 것을 모르는 인물:** 정면 사례는 없음. C08 m3 "Who wrote the water-drop note?"는 새 지키미를 찾는 퍼즐이라 정당.
- **장소·순서:** 상자 경로 Seoul(1446, 어머니) → … → Seoul 1895(Lady Han "puts her note in a small wooden box") → **Harbin 1909**(Mrs. Kang "This one goes in my letter box") → Cheonan 1919(Gyeongsun) → Shanghai 1920/1932 → Seoul 1941 → Chongqing 1945. 서울과 아우내 사이에 하얼빈이 끼는데 설명이 없다(I-5).
- **쪽지 소재:** C02 final transition "Seok's note goes into your notebook."(DUMP:451)에서 탐정이 석의 쪽지를 가져간다. 그런데 C04에서는 Duri가 "lays three notes side by side"하고, C12 상자에도 석의 쪽지("A note from the navy base by the sea")가 들어 있다. Bongsu는 "folds his note and keeps it"한다(I-5).
- **수량:** C12 m2 title "Eleven Notes and One Box", story "Six notes slide out", lid 순서는 6명(Lady Han, Bongsu, Mrs. Kang, Haesu 누락). final은 "Bun-i's first note lies under eleven more." 같은 케이스 안에서 6과 11이 충돌한다(I-3).
- **자물쇠:** C08 dial lock(31·1) → C10 "I put a letter lock on our box"(DROP) → C11 "a letter box with a number lock"(319) → C10 final "small water-drop lock". 바뀌는 이유가 없다(P3).
- **역사 순서:** 12케이스 모두 연대순. C12 Kim Won-bong 1944 군무부장, C09 Kim Gu 1919-08 경무국장 등은 노트상 확인된 사실로 처리됨.

## 5. Case 01 편지와 나무 상자의 반영

| 후속 표현 | 위치 | V4와 일치? |
|---|---|---|
| "It says 엄마, 고마워요. This is Bun-i's letter from 1446!" (R/J/M 모두) | C08 final ending (DUMP:3756-3758) | ✅ 텍스트 일치 / ❌ 연결 증거 e3 (I-2) |
| "The oldest is at the bottom. Its paper is yellow with age." | C08 | ✅ |
| "An old wooden letter box … Bun-i's note of 1446 is at the bottom." | C08 e4 | ✅ (V4 "little wooden box") |
| "Bun-i's note of 1446 lies at the bottom. It is the oldest." | C12 m2 lid | ✅ |
| **"The first note: the name of the letters."** / J "The very first note: the name of the letters." / M "…bearing the name of the letters." | C12 m2 card (G/12:504, `s5_ep12_levels.g.dart:392,1001`) | ❌ **P1** |
| "Bun-i's first note lies under eleven more." / "Bun-i's first note started it all." | C12 final | ✅ 텍스트 / ❌ evidence e3 |
| "Bun-i … wrote the first note in 1446." | C02 m1 discovery | △ V4에서는 어머니께 쓴 '편지'. 'note'라는 호칭만 느슨함(P3) |
| 경고 쪽지 / 탄 모서리 / 다른 문구 | 전체 DUMP grep "burn/warning/corner" | 해당 없음. "corner"는 C08/C09/C11의 물방울 위치, "warning"은 C02 제독 대사 |
| 상자의 기원 | V4 "Her mother keeps the letter in a little wooden box." vs SB.coreMystery.truth "was given a small wooden letter box by Sora" vs SP.mainMystery.truth "Bun-i … kept a small letter box", motive "as Bun-i promised Sora: 'Anyone can learn them. I will teach them.'" | ❌ 문서 3종이 서로 다름. 게임 텍스트는 V4 하나뿐이라 플레이어 쪽 모순은 없음. 다만 '약속' 동기는 게임에 없음(I-4, I-7) |

## 6. C12 피날레

- **이전 케이스와의 연결:** recall s5_ep08_e4(상자), 카드 6장(Bun-i/C01, Seok/C02, Okbun/C03, Duri/C04, Gyeongsun/C08, Miri/C11), Haesu 언급(C09–10), Miri의 상자(C11). **C05 Lady Han, C06 Bongsu, C07 Mrs. Kang, C09–C10 Haesu의 쪽지는 피날레 퍼즐에 없다.** 11명 모두를 모으는 대목도 없고 "eleven more"라는 숫자로만 처리된다(I-3).
- **M2 순서 bun_i, seok, okbun, duri, gyeongsun, miri를 풀 수 있는가:** 카드 제목이 이름이고(G/12:501-532), lid가 "Bun-i … bottom / Seok before Okbun / Duri after Okbun / Gyeongsun after Duri / Miri … top"으로 관계를 전부 준다. 그래서 **이전 케이스 기억 없이도 유일해** 건너뛰거나 다시 해도 풀 수 있다. 반대로 말하면 이전 케이스 지식(1592<1795<1866<1919)은 필요 없고, 시즌 보상감이 약하다(P3, I-9). 카드 설명("navy base by the sea", "palace timber yard" 등)은 각 케이스와 일치하지만, 분이 카드만 구판이다(I-1).
- **재플레이/건너뛰기:** C08·C12의 e3 표시와 recall 대상(e2, e8_e4)은 공책에 있어야 한다. 시즌이 순차 해금이면 문제없음(추정: 해금 로직은 확인 안 함).

## 7. 시즌 수준 판정

SB.mysteryQuestions 5개:
1. "Can Bun-i write her own letter?" → C01에서 해결 ✅
2. "Who leaves the water-drop notes?" → C08 "Bun-i was our first keeper. We are all her family." ✅
3. "Is it one person…?" → C04 ending ✅ (질문은 C04 m1 discovery에 나옴. SB는 C03 raised로 적음, 사소함)
4. "What do the keepers keep?" → C08 상자 ✅
5. "What does the last note say?" → C12 LIGHT ✅

coreMystery의 "who / what they keep"은 닫힌다. 그러나 **"why"(C04 "But why?", SB motive "keep the letters alive")는 게임에서 명시적으로 답해지지 않는다.** 가장 가까운 대사는 C05 Lady Han "I will keep our letters, and the truth of these days."와 C06 Bongsu "One day people will read the truth."다. 탐정이 왜 매번 그 자리에 있는지도 열려 있다.

| 평가 | 점수 | 이유 |
|---|---|---|
| 케이스별 독립 완결성 | **4.5/5** | 12케이스 모두 자체 사건 → 증거 → 역사적 사실 엔딩 구조가 닫힌다. 각 케이스 summary가 사건과 역사를 함께 정리한다. 감점: C12 m2 6 vs 11 내부 불일치. |
| 시즌 전체 이야기 완결성 | **3/5** | 물방울 사슬과 상자 이동이 매 케이스 recall로 실제로 이어지고 C04/C08/C12 반전 구조도 있다. 감점: V4와 어긋난 C12 카드(P1), e3/e4 오참조, 상자 경로(하얼빈)와 쪽지 소재 모순, 동기 "why" 미해결, 탐정 시간 이동 무설명, 피날레에서 지키미 5명 누락, C08 반전 약함. |

## 8. 이슈 목록

| ID | 심각도 | 위치 | 내용 | 수정 방향 | 범위 |
|---|---|---|---|---|---|
| I-1 | **P1** | CP/12:419, LV/12:496-498 → G/12:504, `s5_ep12_levels.g.dart:392,1001` | 분이 카드 "The first note: the name of the letters." V4에서 분이의 첫 편지는 "엄마, 고마워요" | 카드 text를 예: "The first note: 엄마, 고마워요." (R/J/M) 로 바꾸고 재생성. SB bun_i.purpose도 함께 수정 | C12 m2 텍스트 3줄 + generator + SB 1줄 |
| I-2 | P2 | CP/08 final clueInputs + ending `evidence: s5_ep01_e3`; CP/12 final clueInputs + ending + evidenceLink (G/12:381-383, 731); SB clueThreads e3→ep08 | 상자 속 편지를 e3(첫 낱말 엄마)로 가리킴. 대사 "엄마, 고마워요"와 뜨는 카드가 어긋남 | 모두 **s5_ep01_e4 "Bun-i's Letter"**로 교체 후 재생성. 관련 테스트 기대값 확인 | C08·C12 plan/levels, SB, 테스트 |
| I-3 | P2 | CP/12 m2 title "Eleven Notes and One Box", story "Six notes slide out", final "under eleven more" | 같은 케이스 안에서 쪽지 수 6과 11이 충돌. Lady Han·Bongsu·Mrs. Kang·Haesu 누락 | (a) story를 "Eleven notes slide out. Haesu marked six on the lid."처럼 바꿔 나머지가 있음을 밝히거나, (b) 카드를 10~11장으로 늘림(난이도 상승 주의). 적어도 Haesu 자신의 쪽지가 빠진 이유 한 줄 | C12 m2 텍스트, 필요 시 timeline spec |
| I-4 | P2 (문서) | SB.coreMystery.truth "given … by Sora", SB sora.purpose, SP.mainMystery.truth/motive "promised Sora" | V4 = 어머니의 나무 상자. 문서 3종 불일치 | SB/SP를 V4로 정렬: "Her mother kept Bun-i's letter in a little wooden box; Bun-i taught her children…" | 기획 문서만 (게임 텍스트 영향 없음) |
| I-5 | P2 | C02 final transition "Seok's note goes into your notebook."; C06 "Bongsu folds his note and keeps it."; C07 "This one goes in my letter box."(Harbin) | 쪽지 소재와 상자 위치(서울→하얼빈→아우내)가 끊김 | C02 줄을 "Seok keeps his note. You copy it into your notebook."로. C07 "I will send it to my family's box at home." 정도로 상자 경로 보강 | C02/C06/C07 각 1줄 |
| I-6 | P2 | 모든 intro "You are a guest of…", SP.prologue | 탐정의 500년 이동·불로가 설명되지 않음. 지키미들이 "Detective,"로 부르는 이유도 없음 | 프롤로그나 C02 intro에 틀 한 줄 추가(예: 케이스북·초대장 장치). 또는 지키미 대사 한 줄("Bun-i wrote of a guest who helped her…")로 가족 전승에 탐정을 넣음. 사용자 결정 필요 | 프롤로그/C02/C08 소량 |
| I-7 | P2 | C04 ending "A family keeps writing them. But why?" | 동기가 게임에서 명시적으로 답해지지 않음 | C08 ending의 Gyeongsun이나 C12 Bitna에 한 줄: "Bun-i taught her mother. We teach, and we keep the truth." | C08 또는 C12 1~2줄 |
| I-8 | P2 | C02 ending Seok "My grandmother taught me that mark." + 탐정 "just like Bun-i's" | C08의 '분이 가족' 공개가 C02부터 사실상 드러남 | C02 탐정 대사를 "Seok's water drop … where have I seen it?" 수준으로 약화하거나 그대로 두고 C08 반전을 '상자·첫 편지 실물'에 집중(현재도 그러함) | 선택 |
| I-9 | P3 | C12 m2 | 퍼즐이 lid만으로 풀리고 이전 케이스 지식이 필요 없음 | 관계 한 줄을 연도 기반으로 대체(예: "Seok wrote in the year the war began")해 기억 보상을 줌. 단, Rookie 난이도 고려 | C12 m2 |
| I-10 | P3 | C04 Mr. Pyo(목재상) / C08 Mr. Pyo(소금장수); C07 Mr. Pak / C09 Mr. Pak | 다른 인물인데 같은 이름 | C08 악역 또는 C09 서기 이름 변경 | 이름 치환 |
| I-11 | P3 | C02 m2 Sora's board "ㅁ = the mouth", "Flat vowels go under"; clueInputs note "Sora's Lesson Board" | V4는 ㅁ=lips, 세운 모음(점 좌/우)만 가르침 | "ㅁ = the lips"로 맞추고, 평모음은 C02 보드의 '새 줄'로 두거나 Sora의 다른 규칙이라고 표기 | C02 보드 텍스트 |
| I-12 | P3 | C10 final "Bitna will read this one day … My daughter." (1932) vs SB bitna "Eleven" (1945) | 1932년에는 Bitna가 아직 태어나지 않았을 나이. 게임에 나이 표시는 없음 | SB 나이를 13~14로 바꾸거나 C10 대사를 "my child, one day"로 | SB 또는 C10 1줄 |
| I-13 | P3 | C08 dial / C10 DROP letter lock / C11 number lock | 같은 상자의 자물쇠가 매번 바뀌는데 이유가 없음 | C11에 "Miri put a new lock on it" 한 줄 | C11 1줄 |
| I-14 | P3 | SB/SP characters `taek` | V4에서 빠졌는데 캐스트에 남음 | SB/SP에서 제거하거나 "unused" 표기 | 문서 |
| I-15 | P3 | CP/02 m1 clueInputs note "left water drops by her note" | 구판 서술(내부 note만, 화면 표시 안 됨으로 추정) | "signed her letter with a water drop" | 내부 note |

확인하지 않은 것: 시즌 해금/재플레이 로직(공책에 C01 증거가 남는지), 실제 기기 화면 표시, `season_content_validator`가 e4 참조를 허용하는지(추정: final 출력도 recall 대상 허용).

---

# PART 5-B — 한국 역사·문화 고증 (E. 역사 검증)

## Season 5 Seoul — 역사 고증 점검 (Case 02–12 + Case 01 반복 사실)

범위: `content_pipeline/seasons/s5_seoul/cases/s5_epNN/case.plan.json`·`levels.json`(R/J/M), `lib/data/generated/s5_seoul/s5_seoul_history.g.dart`(REAL HISTORY / IN THIS MYSTERY), `season.plan.json`·`season.levels.json`(프롤로그·아웃트로). 플레이어에게 보이는 대사는 `scratchpad/seoul_text_dump.md`를 케이스별로 나눠(`scratchpad/hist/cNN.txt`) 읽었다. 저장소 파일은 수정하지 않았다.

판정: 1 역사적 사실(확인) · 2 교육적 단순화 · 3 창작 인물·사건 · 4 고증 오류 · 5 추가 확인 필요
심각도: P1 아이에게 틀린 역사를 가르침 · P2 오해 소지가 있는 단순화 또는 사실과 창작의 경계 흐림 · P3 경미

출처 표기 원칙: 아래 URL은 이번 점검에서 직접 열었거나(WebFetch) 검색 결과 요약으로 내용을 확인한 것이다. **[읽음]**은 페이지를 직접 열어 확인했다는 뜻이고, **[검색]**은 검색 결과 요약으로만 확인했다는 뜻이다. 이 두 표시가 없는 항목은 이번에 검증하지 않았다는 뜻이며 "미검증"으로 적었다.

총평: 날짜·인물·사건의 뼈대는 거의 모두 정확하다. 각 케이스의 history reveal(IN THIS MYSTERY)도 창작 인물과 창작 사건을 꼼꼼하게 밝히고 있다. **P1(명백한 고증 오류)은 찾지 못했다.** 고칠 만한 것은 주로 P2/P3이다. 주인공 역할을 과장한 부분(유관순, 정약용), 시대에 맞지 않는 소품(1796년의 숫자 다이얼 자물쇠), 기간 계산(화성 "2년 8개월"), 그리고 정치적으로 민감한 인물 선택(김원봉)이 그 예이다.

---

## Case 01 사실 가운데 이후 케이스가 반복하는 것

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1443년 세종이 28자를 만듦 | R/J/M | history.g.dart s5_ep01 realHistory[0] | 1 | 세종실록 25년 12월 30일 "上親制諺文二十八字…是謂訓民正音" [읽음] https://sillok.history.go.kr/id/kda_12512030_002 | 음력 12월이라는 점은 표기하지 않음(문제 없음) |
| 1446년 『훈민정음』(해례본) 완성 | R/J/M | 같은 곳 [1] | 1 | 출처 목록의 세종실록 28년 9월 기사(미검증, 통설과 일치) | "finished"는 반포·해례본 완성(9월 상순)과 맞음 |
| 느린 사람도 열흘이면 배운다 | R/J/M | 같은 곳 [7] | 1 | 정인지 서문 "愚者可浹旬而學"(통설, 미검증) | |
| Bun-i가 1446년에 첫 쪽지를 씀 / "The letters she learned in 1446" | R/J/M | c02 m1 discovery.detail, season.levels.json outro | 3 | — | IN THIS MYSTERY에 창작이라고 밝혀져 있음 |
| Sora's board: ㄱ=혀뿌리, ㄴ=혀가 잇몸에 닿음, ㅁ=입, ㅅ=이, 가획 / 아래아·가로·세로 모음 위치 | R/J/M | c02 m2 letter, c04 m1 letter | 2 | 우리역사넷 제자해(출처 목록, 미검증. 통설과 일치) | ㅅ "teeth", ㄴ "gums"는 제자해와 일치 |
| 1919·1920년 쪽지를 "Hangeul"로 부름 | R/J/M | c08 m1 story, c09 m1 story | 1 | 주시경이 1910년대에 '한글'이라는 이름을 쓰기 시작(통설) | 시대에 맞음. 1941년 케이스는 "King's letters"로 부르는데 이것도 문제 없음 |

---

## Case 02 — The Turtle Ship Before Dawn (1592, 여수)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1592년 음력 4월 12일 거북선 포 시험, 난중일기에 기록 | R/J/M | final.play.ending.text, play.caseSummary, history[2] | 1 | 난중일기 4/12 "식후에 배를 타고 거북선의 지자포·현자포를 쏘았다" [검색] https://www.kyeonggi.com/article/202101051151835 , https://mediahub.seoul.go.kr/archives/2016775 | 일기에는 "식후"라고 되어 있음. 게임의 "At dawn our cannons must fire"(m1 talk)는 창작 시각(P3, 수정 불필요) |
| 다음 날(13일) 일본 배가 부산 앞바다를 덮음, 전쟁 시작 | R/J/M | final.play.transition, ending, history[3] | 1 | 일본 선단의 부산 앞바다 도착은 4/13, 부산진성 공격은 4/14 새벽 [검색] https://www.dailian.co.kr/news/view/1671578/ , encykorea 부산포성 E0024275 | "ships covered the sea"는 13일 도착과 맞음. 통설 범위 안 |
| 5월 옥포에서 첫 해전 승리 | R/J/M | ending, history[4] | 1 | 선조수정실록 25년 5월 1일 기사(출처 목록, 미검증. 통설) | |
| 판옥 지붕, 칼·송곳, 좁은 길, 거북 꼬리, 용머리 입이 포구 | R/J/M | final.play.letter, history[1] | 1 | 이순신 장계 "前設龍頭 口放大砲"·이분 행록(통설). 출처 목록 encykorea 거북선 E0001833(미검증) | |
| "He commands the navy of Jeolla" | R/J/M | play.intro[2], history[0] | 2 | 실제 직함은 전라좌도수군절도사(전라좌수사) | P3. "the Left Navy of Jeolla" 정도로 바꿀 수 있지만 아이에게는 단순화로 허용 가능 |
| "Before the war, he built a turtle ship" | R/J/M | play.intro[3] | 1 | 4/11 돛 달기, 4/12 포 시험 [검색] 위 kyeonggi | |
| Seok, Ham, 비, 화약 12통 | 전체 | m1–m3 | 3 | history inThisMystery[0]에 밝혀 둠 | |
| 화약을 "barrels(통)"에 보관 | R/J/M | m1 story | 5 | 미검증 | P3. 조선 수군의 화약 보관 용기(궤·독 등)는 확인하지 못함. 게임 소품 수준 |

## Case 03 — The Crane That Lifts Stones (1795–1796, 수원)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 화성은 1794년 1월~1796년 9월에 쌓음 | R/J/M | final.letter, ending, history[0] | 1 | 우리역사넷 "축성이 시작된 때는 1794년 1월", "9월 10일 성역이 종료" [읽음] https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_r300890&code=kc_age_30 | 같은 페이지의 개요에는 "2월에 시작"이라고도 적혀 있음. 1월이 통설 |
| "two years and eight months later" (기간) | R/J/M | final.play.letter (clerk) | 5 | 우리역사넷은 "약 2년 반", 다른 자료는 "2년 9개월"·"33개월" [검색] https://www.seoul.co.kr/news/1997/12/05/19971205017001 등 | **P3.** 1795년에 윤2월이 있으므로 음력으로 세면 약 33개월(2년 9개월)이다. 1794년에는 흉년으로 공사가 중단된 기간도 있었다. 퍼즐 답(1796)에는 영향이 없으므로 "nearly three years later"나 "in the ninth month of 1796"으로 바꾸는 것을 권장 |
| 정약용이 거중기(도르래)를 설계하고 글로 남김 | R/J/M | play.intro, history[1] | 1 | 정약용이 「기중도설」을 써서 거중기를 고안 [읽음] 위 우리역사넷. encykorea 거중기 [읽음] https://encykorea.aks.ac.kr/Article/E0001891 | |
| 거중기 = 문 모양 틀, 위·아래 도르래, 양쪽의 "big wheel"을 일꾼이 돌림 | R/J/M | m2 letter | 2 | 의궤 그림의 감는 장치는 물레·녹로(손잡이로 돌리는 굴대)임. 도르래 개수는 이번에 확인하지 못함 | P3. "wheel"은 굴대(winch)를 단순화한 표현으로 허용 가능 |
| **정약용이 1795년 봄 화성 현장에서 손님을 맞고 공사를 지휘하며, 1796년 가을 수원으로 다시 초대함** | R/J/M | play.intro[0], m1–final, final.play.story[0] | 3 (경계 흐림) | 정약용은 1792년 「성설」로 계획을 세웠다. 현장 총괄은 감동당상 조심태, 실무는 도청 이유경이 맡음 [읽음] 위 우리역사넷. 정약용은 1795년 7월 금정찰방으로 좌천됨(통설, 미검증) | **P2.** history reveal은 "his words and steps … invented"라고만 쓴다. 이 문장만으로는 아이가 "정약용이 화성 공사 현장의 책임자였다"고 믿을 수 있음. IN THIS MYSTERY에 한 줄 추가를 권장: "Jeong Yak-yong planned the fortress and the machine, but others ran the building site." |
| 1801년 간행된 기록책에 일꾼 이름과 품삯 | R/J/M | final.ending, history[3] | 1 | "간행은 1801년(순조 1)" [읽음] 위 우리역사넷 | 『화성성역의궤』 |
| "Even the water girl is in it" (의궤에 물 긷는 소녀가 실려 있음) | R/J/M | final.play.transition[2] | 5 | 미검증. 의궤의 명단은 주로 장인(匠人)이다 | **P3.** 실제 기록에 대한 창작 주장이다. "the water carriers"처럼 직종으로 쓰거나 IN THIS MYSTERY에서 창작임을 밝히는 것을 권장 |
| 1796년 기록함의 "four number dials" 자물쇠가 서기 연도 '1796'으로 열림 | R/J/M | final.play.story[2], letter | 4 (시대착오) | 조선 1796년은 정조 20년(병진년). 아라비아 숫자 다이얼 자물쇠는 시대에 맞지 않음 | **P3.** 퍼즐 장치이므로 고치지 않을 수도 있다. 고친다면 IN THIS MYSTERY에 "The number lock is the game's own" 한 줄을 넣거나 열쇠 자물쇠로 바꾸는 방법이 있음 |
| Okbun, Gwak, 목수, 잘못된 도면 | 전체 | m1–m3 | 3 | inThisMystery 명시 | |

## Case 04 — The Palace of a Thousand Logs (1866, 한양)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 경복궁이 1592년 전쟁 때 불타 오래 폐허로 남음 | R/J/M | play.intro, m3 letter, history[0] | 1 | encykorea 경복궁 [읽음] https://encykorea.aks.ac.kr/Article/E0002434 | 누가 불태웠는지는 말하지 않음(논쟁이 있는 사안이라 적절) |
| 1865년 4월 중건 시작, 흥선대원군 지휘 | R/J/M | ending, history[1] | 1 | 신편 한국사 37 "고종 2년(1865) 4월에 營建都監을 설치" [읽음] https://db.history.go.kr/id/nh_037_0040_0020_0020 | |
| 1866년 (11월) 새 동전(당백전), 물가 급등 | R/J/M | m3 letter, history[3] | 1 | "고종 3년(1866) 11월부터 … 주조", 실질가치는 명목의 1/20 [읽음] 위 신편 한국사 | |
| "Every house gave money for it. Most had no choice." (원납전) | R/J/M | m3 talk, history[2] | 1 | "빈부의 구분없이 매호마다 강징" [읽음] 위 신편 한국사 | |
| 농민 부역이 고됨 | R/J/M | m3 talk, history[4] | 1 | "민간인 工匠도 강제 동원", 경기 농민 부역 부담 [읽음] 위 신편 한국사 | |
| 1868년 완공, 왕이 옮겨 옴 | R/J/M | ending, history[4] | 2 | 신편 한국사: 1868년 완공, 같은 해 7월 이어 [읽음]. encykorea는 "중건공사 완료: 1867년 말" [읽음] | P3. 자료 사이에 차이가 있으나 통설 범위 안. 부속 공사는 이후에도 계속됨 |
| Duri, 표씨, 통나무 표식 가/나/다 | 전체 | m1–final | 3 | inThisMystery 명시 | |
| 1866년 서울을 "Hanyang"이라 부름 | R/J/M | play.intro | 2 | 공식 명칭은 한성부. '한양'은 통용되던 이름 | 허용 |

## Case 05 — The Lights of Geoncheonggung (1895)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1887년 경복궁 건청궁에서 한국 최초의 전등 점등 | R/J/M | play.intro, history[0] | 1 | 1887년 3월 초 건청궁 점등 [검색] https://mediahub.seoul.go.kr/archives/2008140 , https://www.korea.kr/news/reporterView.do?newsId=148942310 | |
| "South of the pond stands the lamp house", 석탄, 바퀴 | R/J/M | m1 story, search | 1 | 2015년 발굴에서 전기등소를 향원지 남쪽·영훈당 북쪽 사이로 확인, 석탄과 탄소봉 출토, 향원지 물을 냉각수로 씀 [검색] 위 mediahub, YTN https://www.ytn.co.kr/_ln/0106_201505280018551806 | 가죽 벨트로 바퀴를 돌린다는 구조는 미검증(P3, 게임 소품) |
| 자주 깜빡여 '건달불'이라 불림 | R/J/M | intro, history[1] | 1 | 출처 목록 mediahub 2008140(제목 확인). 통설 | |
| 장안당=왕, 곤녕합=왕비 | R/J/M | play.intro[1] | 1 | 통설. encykorea 을미사변(곤녕합 시해) [읽음] https://encykorea.aks.ac.kr/Article/E0042948 | |
| 1895년 왕비가 러시아와 손잡아 일본 세력을 견제 | R/J/M | final letter, ending, history[2] | 1 | encykorea 을미사변: 일본은 왕비를 조선과 러시아를 잇는 중심 인물로 보았다 [읽음] | |
| 1895년 10월 8일 미우라 공사가 보낸 무리가 궁을 습격해 왕비 시해 | R/J/M | ending, caseSummary, history[3] | 1 | encykorea "1895년 10월 8일(음력 8월 20일) … 미우라 고로" [읽음] | 양력 표기. 다른 케이스는 음력이라 혼동될 수 있으나 연도가 다르므로 문제 없음 |
| 왕비의 대사 "Korea must choose its own way" | R/J/M | final ending | 3 | inThisMystery "their words … invented" | |
| 한 상궁, 등 켜는 사람, 낯선 자들, 37걸음 지도 | 전체 | m1–final | 3 | inThisMystery 명시 | 창작이지만 "시해를 위한 사전 답사"라는 설정이 실제 사건과 바로 연결된다. 사실처럼 읽힐 수 있으나 reveal이 명확하게 밝히고 있어 P3 |
| 8:00/9:00 시각 표기 | R/J/M | m2 letter | 2 | 1890년대 궁중에 서양 시계가 있었음(통설) | 허용 |

민감도: "The Queen was killed in that attack."은 담담하게 서술되고 시신 소각 같은 세부는 빠져 있다. 8세 아이에게 적절한 수위이다. 얼굴을 그리지 않는다는 원칙(inThisMystery[2])도 좋다.

## Case 06 — The Emperor's Secret Letter (1907)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1905년 조약을 강제당해 외교권 상실 | R/J/M | play.intro, history[0] | 1 | 우리역사넷 헤이그특사: "강압적으로 … 외교권을 박탈한 을사늑약" [검색] https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_i403600&code=kc_age_40 | |
| 1907년 이상설·이준·이위종 밀사를 헤이그 평화회의에 보냄 | R/J/M | ending, history[1] | 1 | 같은 곳 [검색] | 우리역사넷은 헐버트도 특사로 든다(P3, 세 명은 통설) |
| 회의장에 들어가지 못함 | R/J/M | ending, history[3] | 1 | 같은 곳 [검색] | |
| 이준이 1907년 7월 헤이그에서 사망 | R/J/M | ending, history[4] | 1 | "7월 14일 헤이그에서 순국" [검색] 같은 곳 | 사인을 말하지 않음(분사설 등 논쟁을 피함, 적절) |
| 일본이 이를 구실로 고종을 강제 퇴위시킴 | R/J/M | ending, history[5] | 1 | "헤이그 특사 파견을 구실로 고종을 폐위" [검색] 같은 곳 | |
| 1907년 봄 경운궁(Gyeongun Palace) | R/J/M | play.intro, place | 1 | 덕수궁으로 이름이 바뀐 것은 1907년 퇴위 후(통설) | 시대에 맞는 명칭 |
| 비단에 싸인 황제의 밀서를 소나무 구멍에 숨김, 이준 집으로 전달 | 전체 | m1–final | 3 | inThisMystery 명시 | |

## Case 07 — Two Reports from Harbin (1909)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1909년 10월 26일 하얼빈역에서 안중근이 이토 히로부미를 처단 | R/J/M | play.intro, history[0] | 1 | 우리역사넷 안중근(오전 9시 30분경) [검색] https://contents.history.go.kr/mobile/eh/view.do?levelId=eh_n0770_0010&code=eh_age_40 | "that morning"(m2)과도 맞음 |
| "Korea, hurrah!"를 외침 | R/J/M | m3 letter, history[1] | 1 | "꼬레아 우라" [검색] 같은 곳 | 실제로는 러시아어 "Корея ура"였음. 이 점을 reveal에 넣어도 좋음(선택) |
| 달아나지 않음 | R/J/M | m3 letter | 1 | 현장에서 체포(통설) | |
| 1910년 3월 옥중에서 『동양평화론』을 쓰기 시작했으나 끝내지 못함 | R/J/M | ending, history[3] | 1 | encykorea 동양평화론: 사형 집행(1910.3.26)으로 미완 [검색] https://encykorea.aks.ac.kr/Article/E0016677 | |
| 두 신문, 한 신문의 "돈 때문" 보도, Kang·Pak·Sorin, 정오 열차 | 전체 | m1–final | 3 | inThisMystery 명시 | |
| "Ten years later, people all over Korea will stand up" | R/J/M | final ending | 3 | 1919년 3·1운동을 예고하는 창작 대사 | 허용 |

민감도: "killed Itō Hirobumi"는 담담하게 서술되고 총기 묘사가 없다. 안중근의 사형은 언급하지 않는다.

## Case 08 — The Fire on the Hill (1919, 아우내)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1919년 4월 1일 장날, 아우내장터에서 수천 명이 만세 시위 | R/J/M | ending, history[2] | 1 | encykorea 유관순 "1919년 4월 1일 … 병천 시장에서 수천 명이 참여한 만세시위" [읽음] https://encykorea.aks.ac.kr/Article/E0041268 | 음력 3월 1일 장날(통설) |
| **"Gwan-sun leads them" / "Gwan-sun led thousands of people"** | R/J (M "With Gwan-sun at their head") | final ending[1], play.caseSummary | 2 | encykorea: "조인원·유중권·유중무 등과 함께 … 주도" [읽음]. 김구응 등을 실제 주역으로 보는 연구도 있음 [검색] https://www.seoul.co.kr/news/2019/02/12/20190212027002 | **P2.** history reveal(J/M)은 "one of the leaders"·"helped lead"라고 정확하게 쓰는데, 본편과 요약은 혼자 이끈 것처럼 서술한다. "Gwan-sun and the village elders lead them" 또는 "helps lead"로 통일을 권장 |
| 전날 밤 매봉산 봉화가 신호, 유관순이 불을 붙임 | R/J/M | m2 letter, final ending[0], history[1] | 5 | 천안시 봉화제 등 전승으로 널리 알려짐. 유관순이 봉화를 맡았다는 서술이 일반적 [검색] 위 seoul.co.kr, https://www.newsis.com/view/NISX20190228_0000573036 . encykorea 유관순 항목에는 봉화 언급이 없음 [읽음] | P3. 전승을 사실로 단정하고 있음. reveal의 "a signal fire … gave the sign"은 무난하다. 본편의 "Gwan-sun lights the fire"는 통설 수준이라 허용 가능 |
| 이화학당 학생, 3월 휴교로 귀향 | R/J/M | m2 story, intro, history[0] | 1 | 통설(3.10 휴교령). encykorea 유관순 [읽음]에서 이화학당 재학 확인 | |
| "In March, students in Seoul called for independence" | R/J/M | play.intro[1] | 2 | 3·1운동은 민족대표 선언과 탑골공원의 학생·시민이 함께 시작함(통설) | P3. "people in Seoul, many of them students"가 더 정확 |
| 부모가 그날 장터에서 숨짐 | R/J/M | history[3] | 1 | "이날 유관순의 부모를 포함하여 19명이 시위 현장에서 순국" [읽음] | 민감: R은 "died", J/M은 "were killed"(총격 묘사 없음). 적절 |
| 1920년 서대문형무소에서 사망 | R/J/M | history[4] | 1 | "1920년 9월 28일 … 순국" [읽음](장소는 본문에 수감 기록으로만 나옴) | 고문 묘사 없음. 적절 |
| 흰 저고리·검정 치마·외가닥 땋은 머리(Gyeongsun 16세) | R/J/M | m1 talk 인물 설명 | 2 | 1910년대 여학생 차림으로 일반적(미검증) | 허용 |
| Gyeongsun, Dong-il, 표씨, 거짓 날짜, 낯선 남자 | 전체 | m1–final | 3 | inThisMystery 명시 | |

## Case 09 — The Spy in the Shanghai Office (1920)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 3·1운동 후 1919년 4월 상하이에서 대한민국 임시정부 수립 | R/J/M | play.intro, ending, history[0] | 1 | 우리역사넷 대한민국 임시정부 1919(출처 목록, 통설) | |
| 1919년 8월 김구가 문지기를 자청했으나 경무국장에 임명됨 | R/J/M | final talk, history[1] | 1 | "8월에는 내무총장 안창호에게 … 문지기를 자청하였으나 경무국장에 임명" [읽음] https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_n400245&code=kc_age_40 | |
| 경무국이 정부를 지키고 일본 밀정을 감시함 | R/J/M | final letter, history[2] | 1 | 출처 목록 korea.kr·edaily(미검증). 통설 | |
| "Later, in 1940, Kim Gu became the head of that government" | R/J/M | final ending[2], caseSummary | 2 | 1926년 12월 국무령, 1940년 10월 주석 [읽음] 위 우리역사넷 | **P3.** 김구는 1926년에 이미 정부 수반(국무령)이 되었다. history reveal은 "led … In 1940 he became its chairman"이라고 정확하게 쓰므로 본편도 "chairman"으로 통일을 권장 |
| Haesu, 남기호, 비밀 명단, 양초, 퇴근부 | 전체 | m1–final | 3 | inThisMystery 명시 | 1920년 사무실의 양초·퇴근부는 시대에 맞음 |

## Case 10 — The Two Watches (1932)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1932년 4월 29일 아침 윤봉길과 김구가 아침을 함께 먹고 시계를 바꿈. 윤이 새 시계를 두고 김구의 낡은 시계를 가져감 | R/J/M | 전체, history[0] | 1 | 금색 시계는 윤봉길이 1932년 4월 구입해 거사 당일 아침 백범의 은색 시계와 맞바꿈. 장소는 김해산 거주지 [검색] https://www.segye.com/newsView/20140314004194 | "He did not buy it this morning"(m1)은 전날 샀다는 백범일지 내용과 모순되지 않음 |
| "I gave him money for a good watch" (김구) | R/J/M | m2 talk | 2 | 백범일지 "선생님 말씀에 따라 … 산 시계"(통설, 금액은 이번 검색에서 확인 못함) | P3. 김구가 돈을 주었다는 해석은 허용 범위 |
| 훙커우공원 일본군 기념식 공격, 즉시 체포 | R/J/M | m3/final letter, history[1–2] | 1 | encykorea 훙커우공원 의거: 상하이사변 전승·천장절 기념식 [읽음] https://encykorea.aks.ac.kr/Article/E0065823 | 폭탄과 사상자는 언급하지 않음(아이 수위로 적절) |
| "He died in Japan in December 1932" | R/J/M | history[2] | 2 | 1932년 12월 일본에서 사형(총살) 집행. 집행 장소(가나자와/오사카)는 이번 요약에서 엇갈림 [읽음, 장소 미확정] | P3. "died"는 사형을 완곡하게 표현한 것. MASTER는 "was put to death"도 고려할 수 있음 |
| 이후 중국인의 인식이 바뀌고 중국 지도자들이 임시정부를 강하게 지원 | R/J/M | final letter, history[3] | 1 | encykorea [읽음] | |
| Haesu의 손목시계(가죽 끈) | R/J/M | m2 letter | 2 | 1930년대 손목시계는 실재함 | 허용 |

## Case 11 — The Poet's Three Copies (1941)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1938년 연희전문 입학, 1941년 졸업 | R/J/M | intro, history[0] | 1 | encykorea "1941년 연희전문학교 문과를 졸업" [읽음] https://encykorea.aks.ac.kr/Article/E0042294 . 1938년 4월 입학은 독립기념관 자료 [검색] | 1941년 12월 단축 졸업이므로 "late autumn 1941 … graduates this year"는 맞음 |
| 1941년 시 19편을 골랐으나 출판하지 못해 손으로 세 부를 베낌(스승·친구·본인) | R/J/M | m1 talk, intro, history[2] | 1 | encykorea 하늘과 바람과 별과 시: 19편, 이양하·정병욱에게 한 부씩, 한 부는 본인 [읽음] https://encykorea.aks.ac.kr/Article/E0060561 | |
| 18편 + 서시 = 19편 (자물쇠 퍼즐) | R/J/M | m3 letter | 1 | 우리역사넷 "서시를 포함한 19편", 공훈전자사료관 "18편에 서시를 더해" [검색] https://contents.history.go.kr/mobile/eh/view.do?levelId=eh_n0910_0010&code=eh_age_40 | |
| 정병욱 집안이 마루 밑에 숨김 | R/J/M | final ending, history[3] | 1 | 출처 목록 서울신문 2025-02-14 정병욱 가옥(미검증. 통설) | |
| "In 1948 it became a book: Sky, Wind, Stars and Poems" | R/J/M | final ending, caseSummary | 2 | 1948년 정음사 초간본은 서시를 포함해 31편. 강처중이 보관한 원고가 합쳐짐 [검색] 위 우리역사넷, 국립한글박물관 | P3. "그 한 권(19편)이 그대로 책이 되었다"로 읽힐 수 있음. "became the heart of a book"이 더 정확(선택) |
| 1938년 조선어가 선택과목(수의과목)이 됨, 학교는 일본어로 가르침 | R/J/M | final letter, history[1] | 1 | 제3차 조선교육령(출처 목록 우리역사넷, 미검증. 통설) | |
| 1943년 체포, 1945년 일본 감옥에서 사망 | R/J/M | history[4] | 1 | encykorea "1943년 7월 … 검거", "1945년 2월 … 후쿠오카형무소" [읽음] | |
| 연희전문 강당의 피아노, 전기 스탠드 | R/J/M | m3, m1 | 2 | 1941년 전문학교에 있을 법함(미검증) | 피아노는 inThisMystery에 창작이라고 밝힘 |
| Miri, 카드, 윤동주의 목록, 흰 끈 | 전체 | m1–final | 3 | inThisMystery 명시 | |

## Case 12 — The Day the Light Returned (1945, 충칭)

| 주장 | 레벨 | 위치 | 판정 | 근거·출처 | 비고 |
|---|---|---|---|---|---|
| 1940년 임시정부가 충칭으로 옮기고 한국광복군 창설 | R/J/M | history[0] | 1 | encykorea 한국광복군: 1940년 9월 17일 충칭에서 총사령부 성립 [읽음] https://encykorea.aks.ac.kr/Article/E0005134 | |
| 김원봉 1919년부터 독립운동, 1938년 조선의용대 | R/J/M | ending, history[1] | 1 | encykorea 김원봉 [읽음] https://encykorea.aks.ac.kr/Article/E0010036 (의열단 1919년 11월 또는 12월) | |
| 1942년 광복군 부사령관, 1944년 군무부장 | J/M (R "joined") | history[2] | 1 | 1942년 조선의용대를 이끌고 광복군에 합류해 제1지대장 겸 부사령관, 1944년 군무부장 [검색] https://www.newsis.com/view/NISX20190606_0000673747 | encykorea 요약은 부사령관을 1944년과 함께 적어 혼선이 있음. 다수 자료는 1942년 |
| 1945년 8월 15일 일본이 연합국에 항복, 광복 | R/J/M | ending, history[3] | 1 | 출처 목록 encykorea 8·15광복(미검증. 통설) | |
| 광복 = 빛을 되찾음(光 빛, 復 돌아옴) | R/J/M | final letter, history[4] | 1 | 光復. 통설 | |
| 연합국의 승리와 국내외 한국인의 독립운동, 광복군의 작전은 일본의 항복으로 취소됨 | R/J/M | ending, history[5] | 1 | 임정·OSS 국내 진공 작전 합의(8월 7일), 일본 항복으로 취소 [검색] https://m.seoul.co.kr/news/2019/02/21/20190221008002 | 균형 잡힌 서술 |
| 충칭 사무실의 라디오에서 영어로 "Japan has surrendered … Today is the fifteenth of August" | R/J/M | m3 letter | 5 | 일본 항복 의사는 8월 10일 전후에 전해졌고, 일왕의 방송은 8월 15일 정오(일본어). 충칭의 영어 방송 여부는 확인하지 못함 [검색] | P3. 창작 장면으로 허용 가능 |
| **김원봉을 시즌 마지막 실존 인물(임정 각료로 주인공을 맞음)로 선택** | R/J/M | play.intro[2], ending | 2 (민감) | 김원봉은 1948년 월북해 북한에서 국가검열상·노동상을 지냈고 1958년 숙청됨. 독립유공자 서훈을 두고 논란이 있음 [읽음] encykorea, [검색] https://www.newsis.com/view/NISX20190327_0000600733 | **P2(민감도, 오류 아님).** 서술 자체는 사실이다. 다만 한국 학부모·교사 사이에서 논쟁이 될 수 있는 인물 선택이다. 기획 단계에서 의도적으로 고른 것인지 사용자의 확인을 권장. 대안으로 김구(당시 시안 체류)나 이름 없는 임정 직원이 있음 |
| Bitna, 타일, 트렁크, 편지함 | 전체 | m1–final | 3 | inThisMystery 명시 | 영어 글자 타일은 게임 장치 |

## 프롤로그·아웃트로 (season.levels.json / season.plan.json)

| 주장 | 레벨 | 위치 | 판정 | 비고 |
|---|---|---|---|---|
| "Your first case starts in old Hanyang" | R/J/M | season.levels.json lines[12] | 2 | 허용 |
| "The letters she learned in 1446 are read freely again" | R/J/M | lines[14], season.plan outro[1] | 2 | 1945년 이후 한글 교육이 회복되었다는 뜻이며 사실 범위 안 |
| mainMystery.truth "For five hundred years her family kept it … They never changed history" | (기획 문서) | season.plan.json | 3 | 1446→1945는 499년. "never changed history"라는 원칙이 좋다 |
| character role: Yu Gwan-sun "An Ewha student who led the Aunae Market march" | (화면 노출 여부 미확인) | season.plan.json characters[22] | 2 | Case 08과 같은 P2. 화면에 나온다면 "helped lead"로 |

---

## 오류·수정 권고 목록 (심각도 순)

**P1: 없음.** 아이에게 틀린 날짜·인물·사건을 가르치는 문장은 찾지 못했다.

**P2**
1. **Case 08 유관순 단독 주도 서술.** R/J `final.play.ending.text` "Gwan-sun leads them. They call for Korea's independence."와 `play.caseSummary` "Gwan-sun led thousands of people at Aunae Market."가 해당된다(M "With Gwan-sun at their head"도 같은 결). encykorea는 조인원·유중권·유중무 등과 "함께 주도"했다고 쓴다(https://encykorea.aks.ac.kr/Article/E0041268). 수정안: "Gwan-sun and the village elders lead them." / "Gwan-sun helped lead thousands of people…". 같은 케이스의 history reveal J/M은 이미 정확하므로 본편을 그에 맞추면 된다. season.plan characters[22] role도 같다.
2. **Case 03 정약용의 현장 지휘 설정.** 해당 위치는 `play.intro` "You are a guest of Jeong Yak-yong at Hwaseong Fortress", `final.play.story` "Autumn, 1796. Jeong invites you back to Suwon." 및 m1–m3 전반이다. 정약용은 계획(「성설」·「기중도설」)을 세운 사람이고 현장 총괄은 조심태였다(우리역사넷 https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_r300890&code=kc_age_30). 그는 1795년 7월 금정찰방으로 좌천되기도 했다(통설, 미검증). 수정안: 본편은 그대로 두고 history inThisMystery에 한 줄을 추가한다. "Jeong Yak-yong planned the fortress and designed the machine, but other officials ran the building site."
3. **Case 12 김원봉 등장(민감도).** 서술은 사실이지만 월북·북한 각료 경력과 서훈 논란이 있는 인물이다. 의도된 선택인지 사용자의 결정이 필요하다(https://www.newsis.com/view/NISX20190327_0000600733).

**P3**
4. Case 03 `final.play.letter` "two years and eight months later": 자료마다 "약 2년 반"·"2년 9개월"·"33개월"로 다르고, 1795년 윤2월도 있다. 수정안: "nearly three years later"로 바꾸거나 기간을 빼기.
5. Case 03 `final.play.story` 숫자 다이얼 4개 자물쇠가 서기 '1796'으로 열림: 시대착오이다. 퍼즐을 유지한다면 inThisMystery에 "The number lock is the game's own."을 추가.
6. Case 03 `final.play.transition` "Even the water girl is in it": 실제 『화성성역의궤』에 대한 창작 주장이다. "Even the water carriers are in it"으로 바꾸거나 창작임을 명시.
7. Case 09 `final.play.ending.text`/`caseSummary` "in 1940, Kim Gu became the head": 1926년 국무령이 먼저였다. "became its chairman"으로(reveal과 통일).
8. Case 11 "In 1948, it became a book": 초간본은 31편이었다. "its poems became the heart of a book"(선택).
9. Case 08 `play.intro` "students in Seoul called for independence": "people in Seoul, many of them students"(선택).
10. Case 02 "navy of Jeolla": 실제는 전라좌수영(선택).
11. Case 10 history "He died in Japan": 사형을 완곡하게 쓴 것. MASTER만 "was put to death"(선택).
12. Case 08 매봉산 봉화를 유관순이 올렸다는 서술: 널리 퍼진 전승이나 encykorea 본문에는 없다. 그대로 둬도 무방하다(5, 추가 확인).

## 민감·폭력성 점검 (8세 기준)
- 사망을 언급하는 문장: 왕비 시해(C05), 이토 처단(C07), 유관순 부모 사망·옥사(C08), 이준 사망(C06), 윤봉길 사망(C10), 윤동주 옥사(C11). 모두 한 문장으로 담담하게 서술되고 무기·고문·시신·폭탄 묘사가 없다. **수위는 적절하다.**
- 왕비의 얼굴을 그리지 않는다(C05)와 안중근은 말하지 않는다(C07)는 원칙도 신중하다.
- 일본을 서술하는 방식은 "Japan forced…", "men sent by Japan's minister"처럼 국가·기관 단위이고 일본인 전체를 적대하는 표현은 없다. 적절하다.

## 이번에 검증하지 못한 것
- 거북선 구조 원문(이분 행록·장계), 옥포 해전 날짜, 1446년 9월 실록 기사, 제3차 조선교육령, 정병욱 가옥 마루 밑 보관, 8·15 광복 백과 항목: 통설과 일치하지만 이번에 원문을 열지 않았다.
- 거중기의 도르래 개수와 물레 구조, 조선 수군의 화약 보관 용기, 윤봉길 사형 집행 장소(가나자와 통설, 확인한 요약에는 오사카로 나와 혼선), 충칭의 라디오 방송 언어.
- 국가유산청 사이트는 이번에 열지 않았다.

---

# PART 5-C — 엔진별 UX · 힌트 (코드 분석)

## 서울(S5) Case 02–12 퍼즐 엔진 UX 감사 — 영어권 8–12세 (한글 읽기/입력 불가) 관점

모든 판정은 **코드 분석**(정적 읽기)이다. 앱 실행·기기 확인·테스트 실행은 하지 않았다. 경로는 저장소 루트 기준.

## 0. 공통 사항 (모든 엔진에 적용)

- **미션 흐름**: 장소(story) → 봉인 편지(letter) → 퍼즐. `lib/features/mission/mission_screen.dart:111`. 편지 단계를 건너뛰는 표(`skipsLetter`: dialogues, talks, records, explores, inspections, deductions, …)는 `lib/data/content/puzzle_engine_collisions.dart:145-178`에 있다. 검색(investigations)은 도착 화면에서 보고서를 보여준다.
- **퍼즐 화면 지시문**: `_PuzzleStage`가 맨 위에 `mission.question`(plan `play.question`, 난이도별 patch)을 GlossaryText로 보여준다(`mission_screen.dart:2196-2201`). `CenteredScroll` 안에 있어서 퍼즐이 길면 같이 스크롤되어 사라진다. 고정 헤더는 없다. 편지 본문은 퍼즐 화면에 나오지 않고 "Reread Letter" 바텀시트로만 다시 볼 수 있다(`:2209-2214`, `:1310-1344`).
- **힌트**: 미션당 최대 2개(`lib/core/constants/app_constants.dart:90`). 가격은 `tipPrices = [0, 20]`(`:126`)이다. 1번은 무료로 즉시 열리고, 2번은 20코인이다. 시작 코인 20(`:119`), 미션 보상 5(`:115`). 링크("Get a Free Hint"/"Get More Hints", `lib/widgets/detective_tips.dart:306-312`)는 퍼즐 화면에 **처음부터** 보인다(오답 전에도). 오답 시트에서도 힌트를 고를 수 있다(`mission_screen.dart:1358-1366`). 코인이 모자라면 `TipState.help`가 되어 "Not enough coins!" 문구와 보상형 광고 GET COINS가 나온다(`lib/features/mission/widgets/tip_shop.dart:48-53,267-269,203-224`). 힌트 문구는 난이도별 patch에 들어 있어 화면 텍스트와 같은 레벨이다(예: `lib/data/generated/s5_seoul/s5_ep07_levels.g.dart:58,111,166,200`). 열린 힌트는 `DetectiveTipNotes`로 페이지에 남는다(`mission_screen.dart:2206`).
- **오답**: `GameController._submitAnswer`는 attempts/wrongAnswers만 늘린다(`lib/features/game/game_controller.dart:327-335`). 목숨·코인·시간 페널티는 없다. 처음/두 번째 시도에 맞히면 받는 careful 보너스 XP만 줄어든다(`lib/features/game/scoring.dart:54-57`, `app_constants.dart:102-103`). 화면에서는 흔들림, 오답 소리, 그리고 "Not quite!" 시트(TRY AGAIN / 힌트)가 나온다(`lib/features/mission/widgets/answer_feedback.dart:407-466`). 문구는 `AnswerChecker.feedbackFor`가 고른다. 선택형은 option.feedback, 텍스트형은 feedback 맵이나 같은 글자를 순서만 틀리게 쓴 경우의 orderFeedback, 그 밖에는 일반 문구 "Good detectives look again. Read the clue one more time!"다(`lib/core/utils/answer_checker.dart:18-54`, `answer_feedback.dart:459`). 재시도 횟수 제한은 없다.
- **정답 비교**: 대문자로 바꾸고 A–Z, 0–9, 한글 외의 문자를 지운 뒤 answer와 acceptedAnswers를 비교한다(`answer_checker.dart:12-14,82-84`). 그래서 공백, 하이픈, 마침표, 대소문자는 무시된다.
- **뒤로 가기**: AppBar 화살표와 Android back은 같은 경로를 쓴다. 퍼즐 → 편지 → 장소 → 지도 순으로 한 단계씩 돌아가고, 장면형 엔진은 열린 카드부터 닫는다(`mission_screen.dart:276-391`, `:1807-1814`). 파이널은 `_backToMap` 한 번에 지도로 간다(`final_mission_screen.dart:659`).
- **저장·재개**: 진행 상태는 `_update`가 바뀔 때마다 저장한다(`game_controller.dart:73-83`). 미션 완료는 정답을 맞힐 때만 저장된다. 한 번 퍼즐에 들어간 미션은(`markMissionStarted`) 다시 열면 퍼즐 단계부터 시작한다(`mission_screen.dart:257-262,265-268`). 퍼즐 내부 상태는 **timeline / syllable / case_talk만** `recordPuzzleState`로 저장된다(`:1442-1458`, `:1193-1200`). 검색 결과(`_found`), 둘러보기, 흔적, 돋보기, 기록, 증언, 숫자패드, 순서, 문자자물쇠, 다이얼은 메모리에만 있어서 앱을 다시 켜면 처음부터다(`mission_screen.dart:128-149`, `investigation_search.dart:209-213`). 힌트 사용 수, 오답 수, 회상 증거는 저장된다.
- **용어집(Glossary)**: `GlossaryText`의 대상 단어는 **아무 표시도 없다**. **길게 눌러야** 단어 카드가 열린다("A tap is never a look-up", `lib/widgets/glossary_text.dart:16-21`). 카드는 `word` / `= meaning` 두 줄이다(`:253-290`, 예 "Queen = 여왕"). 뜻은 **모두 한국어**다. 예: Rookie 기본 `gunpowder: 화약`(`lib/data/generated/s5_seoul/s5_ep02.g.dart:278-282`), Junior/Master는 `content_pipeline/seasons/s5_seoul/cases/s5_ep{02..12}/levels.json`의 glossary. 영어 정의를 보여주는 경로나 언어 전환은 **없다**. 안내 문구 "Press and hold a word to see what it means."는 편지 단계(`mission_screen.dart:2130`), 둘러보기 문서(`scene_explore.dart:745`), How to Play(`lib/features/onboarding/how_to_play_screen.dart:333`)에만 있다. 증언 화면의 Words 시트만 "Tap a word"로 조작이 다르다(`dialogue_investigation.dart:1561`).
- **로케일/대상 사용자**: `MaterialApp.router`에 locale, localizationsDelegates, supportedLocales가 없다(`lib/app.dart:106-110`). l10n, Intl, flutter_localizations도 쓰지 않는다(lib·pubspec 검색 결과 0건). 게임 UI 문자열은 영어 하드코딩이고, 보호자용 화면은 한국어다. 예: 부모 리포트(`lib/features/result/parent_report_screen.dart:56,75,81,100`), 보호자 게이트 "보호자/운영자 확인"(`lib/features/game_master/parent_gate.dart:63`). 코드가 상정하는 사용자는 **영어를 배우는 한국 아동과 그 보호자**다.
- **글자 크기 상한**: 앱 전체 textScaler를 `AppTextScale.page`로 제한한다(`lib/app.dart:123`).
- **증거 회상 독(EvidenceRecallDock)**: plan `play.recall`이 있는 미션에서 편지를 연 뒤부터 풀 때까지 화면 아래에 카드가 붙는다(`mission_screen.dart:1772-1790`). 가져오기 전에는 recall.title/prompt를 보여주고(min 56dp), 탭하면 수첩 증거 선택 시트가 열린다. 맞는 증거를 고르면 이름과 사진이 접혔다 펼쳐진다(min 48dp). 틀린 증거는 miss 문구로 이유만 알려주고 페널티가 없으며, 가져온 사실은 저장된다(`evidence_recall.dart:19-21,91-97,164-237`). 회상이 붙은 미션: C02M2, C03M1, C04M1, C05M2, C06M1, C07M1, C08M3, C09M1, C10M1, C11M3, C12M2. (`talkBefore`가 있으면 독을 숨긴다: `mission_screen.dart:1780`)
- **오디오/듣기**: `SyllableBoard`의 LISTEN 버튼은 `SyllableSpec.voice`가 있을 때만 보인다(`syllable_board.dart:33,244`). voice 파일은 Case 01에만 있다(`lib/data/generated/s5_seoul/s5_ep01.g.dart:428`, `assets/seasons/season_05_seoul/cases/case_01/audio/*.m4a`). **Case 02–12에는 한글 발음 버튼이나 오디오가 하나도 없다**(generated 파일에서 `.m4a`/`.mp3`를 검색해도 ep01 말고는 없다). TTS도 없다.
- **텍스트 분량(퍼즐 전)**: Rookie 기본 plan 기준으로 story 90–194자, letter 143–332자다(대략 영어 2–3문장과 편지 3–8줄). 가장 긴 편지는 C05M2 332자, C07M2 327자, C08M3 317자, C10F 307자. Junior/Master patch는 더 길 수 있다.

## 1. 미션별 엔진 배치 (plan `missions[].puzzle` / `final.puzzle`)

| Case | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 02 | dark_room_search | syllable_compose (거북선) | number_entry (12) | letter_tile_lock (DRAGON) |
| 03 | timeline_board | picture_choice | order_sequence | combo_dial_lock (1796, 4) |
| 04 | lens_inspect_word (GATES) | number_entry (10) | timeline_board | evidence_talk |
| 05 | scene_explore_choose | timeline_board | number_entry (37) | word_entry (JAPAN) |
| 06 | trace_deduction | order_sequence | number_entry (06:50 time) | letter_tile_lock (FORCED) |
| 07 | record_mismatch | timeline_board | word_entry (KOREA) | evidence_talk |
| 08 | witness_compare | order_sequence | word_entry (GYEONGSUN) | combo_dial_lock (311, 3) |
| 09 | number_entry (01:00 time) | dark_room_search | word_entry (NAM GIHO) | evidence_talk |
| 10 | order_sequence | picture_choice | letter_tile_lock (DROP) | number_entry (1932) |
| 11 | lens_inspect_word (WATER) | record_mismatch | number_entry (319) | word_entry (KOREAN) |
| 12 | scene_explore_choose | timeline_board | number_entry (815) | letter_tile_lock (LIGHT) |

Hangul 정답은 C02M2 `거북선` 하나뿐이다(SyllableBoard로 탭 조합하며, 키보드는 쓰지 않는다).

## 2. 엔진별 요약 표 (코드 분석)

열 번호: ①조작/터치 크기 ②지시문 출처·상시 표시 ③텍스트 입력 ④자물쇠·브루트포스 ⑤힌트 ⑥오답 ⑦뒤로/되돌리기 ⑧저장·재개 ⑨작은 화면·사전 텍스트 ⑩용어집 ⑪회상 독 ⑫오디오. 힌트, 용어집, 회상 독, 오디오는 §0의 공통 규칙을 따르며, 표에는 엔진별로 다른 점만 적었다.

| 엔진 (미션) | ① 조작 / 터치 | ② 지시문 | ③ 입력 | ④ 잠금·추측 | ⑥ 오답 | ⑦ 뒤로·되돌리기 | ⑧ 저장 | ⑨ 화면·텍스트 |
|---|---|---|---|---|---|---|---|---|
| **dark_room_search** (C02M1, C09M2) `investigation_search.dart` | 그림을 탭한다. 핀치/드래그/더블탭 줌은 선택이다(`:200-203`). 히트 영역은 그림 비율 rect에 slack 12dp를 더한 값이다(`:300,345`). 320폭에서 C02 짚 약 59×55, 쪽지 약 86×49dp(추정) | `scene.task`("Find the three things in Ham's report", `:982`)와 보고서 문서가 패널에 고정된다. 3번 헛탭하면 "Stuck? Read the report again, or get a hint."(`:296,554`) | 없음 | 해당 없음 | **오답 제출 자체가 없다.** 헛탭하면 spot.line이나 missLine을 보여준다(`:361-375`). 목록을 다 찾으면 자동으로 정답이 된다(`:388-396`). plan의 options/feedback(straw, key, ink…)은 런타임에 **쓰이지 않는다** | 찾은 카드를 닫는다. 뒤로 가면 장소로 가고, 찾은 것은 페이지가 살아 있는 동안 유지된다 | **저장 안 됨**. 재시작하면 검색을 처음부터 다시 한다(`:209-213`) | 다크 풀스크린. 도착 문장과 보고서가 약 1.4초에 걸쳐 나온다(`:1-5`) |
| **syllable_compose** (C02M2 거북선) `syllable_board.dart` | **탭만** 쓴다(`:18`). 조각 최소 48×48(`:483-484,517`). 칸 72×72(`:339`). 320×568, 글자 1.6배 테스트가 있다(`test/sandbox/s5_seoul_syllables_test.dart:15,53`) | question 위에 "Tap a place on the paper, then build what was written there."(`:260`)와 각 그룹의 `line`(영어 설명, `:254`)이 보드에 항상 보인다. Sora 판(편지)은 Reread에서만 보인다 | 키보드를 쓰지 않는다. 첫소리(ㄱㄴㅁㅂㅅㅈ 글리프), FLAT/STANDING 선, 점 위치, 받침을 탭해서 고른다. 칸 아래에 로마자 "says 'geo'"가 나온다(`:369`) | 첫소리 6 × 모음 조합 × 받침 = 조합 수가 커서 추측하기 어렵다 | feedback 맵 4개(거묵선 등)로 그룹별 문구를 보여준다. 처음 틀린 그룹에 "CHECK THIS ONE" 표시(`:46,182`). 보드는 **유지된다** | 조각을 다시 탭하면 덮어쓴다. UNDO 버튼은 없다. 예시 칸은 잠겨 있다(`:314`) | **저장됨**(`recordPuzzleState`, `mission_screen.dart:1452-1458`) | 편지 223자 + story 177자. Hangul 글리프는 모양 대조용이라 읽을 필요는 없다 |
| **number_entry** (C02M3, C04M2, C05M3, C06M3 time, C09M1 time, C10F, C11M3, C12M3) `question_widgets.dart:410-534` | 숫자 키패드 3×4. maxWidth 330, 비율 1.45라서 320폭에서 키 약 85×59dp(`:491-499`). 휠 60×74를 FittedBox로 줄인다(`:458-469`). Delete와 Clear에 캡션이 있다(`:503-517`) | `_PuzzleStage`의 question(스크롤 시 사라짐) | 키패드만 쓰고 OS 키보드는 쓰지 않는다 | **자릿수가 휠 개수로 보인다**(`:427`). time 형식은 콜론이 고정 표시된다(`:462-467`). 2–4자리라 이론상 브루트포스가 가능하지만 페널티가 없어 막는 장치도 없다 | feedback 맵/orderFeedback(같은 숫자, 다른 순서). 제출하면 입력이 **초기화된다**(`:526-528`) | Delete(마지막 한 자리), Clear | 저장 안 됨(입력값) | 문제 없음 |
| **letter_tile_lock** (C02F DRAGON, C06F FORCED, C10M3 DROP, C12F LIGHT) `letter_lock.dart` | **탭 또는 드래그**(`:13-18`). 화면에 "Drag a letter into the lock, or tap it."(`:152`). 타일 56dp(`:247`), 슬롯 64dp. 다만 6칸은 `Flexible` 안에 있어 320폭에서 약 33–40dp로 **줄어든다**(추정, `:128-141,219-220`) | question, 그리고 자물쇠 제목(`titleOf`) | 키보드 없음 | **타일이 정답 글자뿐인 애너그램이고 미끼가 없다**(plan options = 정답 글자). 경우의 수: DROP 24, LIGHT 120, DRAGON/FORCED 720. 같은 글자를 순서만 틀리면 orderFeedback | orderFeedback이나 일반 문구. 타일은 **제자리에 남는다**(`:20-21`) | 슬롯 타일을 탭하면 빠진다. 드래그로 슬롯끼리 바꿀 수 있다 | 저장 안 됨 | 6칸이면 작은 폰에서 슬롯이 좁아진다(검증 안 함) |
| **timeline_board** (C03M1, C04M3, C05M2, C07M2, C12M2) `timeline_board.dart` | **탭만**: 카드를 고르고 놓을 칸을 탭한다. 드래그와 롱프레스는 없다(`:14,378-380`). 칸과 카드 minHeight 56, 버림 더미 52(`:233,288,322`). 320×568, 1.6배 테스트가 있다(`test/timeline_board_test.dart:168`) | "Tap a card, then tap where it goes." / "Now tap where … goes."(`:156`)가 보드 위에 붙어 있다. 거부 이유도 알려준다(`:93-97`) | 없음 | 카드 5–6장과 미끼 카드("NOT PART OF IT"), 고정(FIXED) 카드가 있다 | 처음 틀린 카드에 "CHECK THIS ONE"과 problem line(`:47,265,351`). 배치는 유지된다 | **Undo**(이동 기록 스택), "Back to the table"(`:184-186`) | **저장됨**(`mission_screen.dart:1442-1448`) | 카드 제목이 대문자 영어 구(THE WALL BEGINS)라 읽기 부담이 크다 |
| **picture_choice** (C03M2, C10M2) `ImageChoiceQuestion` `question_widgets.dart:600-797` | 그림 2열 그리드를 탭하고 CHECK ANSWER를 누른다. 작은 폰용 MORE BELOW 표시가 있다(`mission_screen.dart:2163`) | question | 없음 | 3–4지선다 | option.feedback(예: "This has one pole…"). 선택 상태 유지 | 다른 그림을 탭하면 바뀐다 | 저장 안 됨 | 그림 이름을 숨긴 경우 altText는 스크린리더 전용이다 |
| **order_sequence** (C03M3, C06M2, C08M2, C10M1) `SequenceQuestion` `question_widgets.dart:801-940` | 보기 타일을 순서대로 탭한다. 타일 minH 52, minW 96(`:998`). Step 줄 minH 52(`:861`) | question뿐이다. "순서대로 탭하라"는 전용 안내가 **없다**. 빈 줄 "Step n: empty"는 스크린리더 라벨에만 있다(`:887-888`) | 없음 | 보기 4–5개 중 미끼 1개(예: "Pull the rope by hand"). 경우의 수 24–120 | feedback 맵 또는 orderFeedback(같은 항목, 다른 순서). 선택은 **유지된다** | **Undo / Start again**(`:917-925`) | 저장 안 됨 | 문제 없음 |
| **combo_dial_lock** (C03F 1796, C08F 311) `final_mission_screen.dart:1325-1350,1879-` | 자리마다 ▲▼ IconButton(기본 48dp)과 기호 배지 46, 숫자칸 58×66. `Flexible`로 4개가 320폭에 들어간다 | 파이널 편지와 질문. dialSymbols(seal/gear/key/watch)로 어느 단서의 숫자인지 이어 준다 | 없음 | 자릿수는 다이얼 개수로 보인다. 10^4 / 10^3 조합이고 페널티가 없다. 다만 한 번에 한 칸씩 돌려야 해서 시간이 많이 든다 | 오답이면 흔들리고 시트가 뜬다. 다이얼 값은 **유지된다**(`_submit`이 `_digits`를 건드리지 않음, `:663-688`) | ▼는 +9로 한 칸 뒤로(`:1339`). 뒤로 가면 바로 지도로 간다 | 다이얼 값은 저장 안 됨(재진입 시 0000, `:485-486`) | 파이널 desk |
| **lens_inspect_word** (C04M1 GATES, C11M1 WATER) `lens_inspect.dart` | 돋보기 **드래그 또는 탭**. 탭하면 렌즈가 그 지점으로 옮겨가 바로 검사한다(`:136-141,567-576`). 화면 안내 `dragGuide`/`tapGuide`("Drag the glass… / Or tap a log…", `s5_ep04.g.dart`). 머무름 450ms, slack 10(`:75,84`) | note 패널(task → nextTask)에 체크 표시가 붙는다(`:360,411`) | 라벨 카드 안의 `WordInputQuestion`(`:929`). **OS 키보드**를 쓰고 A–Z와 공백만 받는다 | acceptedAnswers: gates/gate, water | feedback 맵/일반 문구. 라벨이 흔들린다 | 열린 카드는 뒤로 가기로 닫힌다(`mission_screen.dart:351-354`) | 저장 안 됨 | C04: 통나무 표식 가/다를 모양으로 대조한다(읽을 필요 없음) |
| **evidence_talk** (C04F, C07F, C09F) `case_talk.dart` | NEXT/READ ALL/SKIP으로 한 줄씩 넘기고, 질문 버튼과 SHOW EVIDENCE로 수첩 선택 시트를 연다(`:447-493`). 버튼 minH 48–72 | 대사 카드와 present.prompt(`:640-660`) | 없음 | 증거 제시. **2번 틀리면** `tell` 문구와 정답 카드에 불이 들어온다(`:632,647,670`) | 오답은 **제출되지 않는다**(miss 카운트만, 저장 안 됨 `:132`) | Talk log 시트. 뒤로 가면 지도로 간다 | **저장됨**(TalkProgress, `final_mission_screen.dart:868-879`) | 힌트 2개가 plan에 있지만 **힌트 버튼이 없다**(`_talkFinal`, `:868-879`) |
| **scene_explore_choose** (C05M1, C12M1) `scene_explore.dart` | 그림 탭과 핀치/드래그(선택). 표식 30dp 아이콘이고 히트 영역은 그림 rect(`:326,360-390`). 다 본 뒤 선택 페이지에서 그림을 탭하고 CHECK ANSWER | 문서는 장소에서 읽는다. 선택 페이지에 question(`:921`) | 없음 | 2–4지선다(긴 영어 라벨: "The trunk with two leather straps…") | option.feedback. 그림이 흔들린다 | 열린 카드 닫기, BACK TO INVESTIGATION, Reread Letter(`:707,979`) | 저장 안 됨(`:10-11`) | 문서 안에 "Press and hold a word…" 안내(`:745`) |
| **word_entry** (C05F JAPAN, C07M3 KOREA, C08M3 GYEONGSUN, C09M3 NAM GIHO, C11F KOREAN) `WordInputQuestion` `question_widgets.dart:302-405` | **OS 키보드**. `TextCapitalization.characters`, 자동완성 끔, 최대 20자(`:369-394`). CHECK ANSWER | question. prompt가 있으면 빈칸 라벨에 입력이 들어간다(`:341-365`) | `FilteringTextInputFormatter.allow([A-Za-z ])`(`:384-386`)라서 **한글은 입력할 수 없다**(영어 아동은 필요 없음). 하이픈과 마침표는 입력 단계에서 막히지만 비교 때 무시되므로 문제 없다. accepted: GYEONG-SUN/GYEONG SUN, NAM/GIHO/MR NAM, COREA/HIS COUNTRY, JAPANS, korean/KOREAN LANGUAGE | 자유 입력이라 브루트포스는 해당 없다 | feedback 맵. 입력값은 **유지된다** | 키보드 백스페이스 | 저장 안 됨 | 키보드가 올라오면 scrollPadding으로 버튼을 보이게 한다(`:376-383`) |
| **trace_deduction** (C06M1) `scene_deduction.dart` | 흔적 표식(30dp)을 탭해 노트에 적고, 다 적은 뒤 장소 표식(40dp, IgnorePointer라 실제로는 그림 히트 영역)을 탭한다(`:287-288,580`). 320×568 테스트(`test/sandbox/s5_seoul_traces_test.dart:105-117`) | 노트 패널 "CLUES n / m" → "YOUR NOTES"(`:649`) | 없음 | 장소 3–4개 | option.feedback. 그림이 흔들린다 | 열린 카드 닫기. 뒤로 가면 장소 | 저장 안 됨 | 문제 없음 |
| **record_mismatch** (C07M1, C11M2) `tower_records.dart` | 두 기록 탭(min 48, `:231`)을 각각 읽은 뒤 기록마다 한 줄을 탭하고 THESE DO NOT MATCH(`checkLabel`) | `readTask` → `compareTask`(`:104-109`) | 없음 | 4줄 × 2 기록 | `answer_checker.dart:31-37`의 matchPairs 규칙: 첫 번째 틀린 부분의 feedback 문구 | 다시 탭하면 바꿀 수 있다. 읽은 기록은 저장된다(`onRead`) | 고른 줄은 저장 안 됨 | 기록 글씨가 **그림 비율로 그려져서**(`SheetWriting`, `:257-260,353-385`) 작은 폰에서 글씨와 행 높이가 작아질 수 있다(측정 안 함). "Look closer" 줌이 있다 |
| **witness_compare** (C08M1) `dialogue_investigation.dart` | TALK, 질문 버튼, COMPARE TWO STATEMENTS를 누르고 진술 2개를 탭한다(minH 48–72) | "YOUR MISSION" 카드(`:435`) | 없음 | 진술 짝 맞추기 | 틀린 짝은 "THE STORIES ARE DIFFERENT"를 띄우고 **제출되지 않는다**(`:2013`). plan options feedback(april_second)은 쓰이지 않는다 | CHOOSE ANOTHER PAIR, BACK TO WITNESSES(`:1937-1946`) | **저장 안 됨**(`:7-9`) | Words 시트는 "Tap a word"로 다른 엔진(길게 누르기)과 조작이 다르다 |

공통 ⑤⑩⑪⑫: 힌트는 처음부터 무료 1개, 2번째는 20코인이다. 예외로 dark_room_search, witness_compare, scene_*, lens는 엔진 자체 패널에서 hint 링크를 보여주고(`mission_screen.dart:1155-1186,1469-1483`), evidence_talk에는 링크가 없다. 용어집은 표시 없음, 길게 누르기, 한국어 뜻(영어 정의나 로케일 없음). 회상 독은 §0 목록의 미션에만 붙는다. 오디오는 Case 02–12에 없다.

## 3. 구체적 UX 이슈 (심각도순, 모두 코드 분석)

P0(진행 불가) 항목은 찾지 못했다. 영어 아동이 한글을 입력해야 하는 곳이 없고, 모든 엔진이 탭으로 끝까지 진행되며, 오답 페널티나 횟수 제한도 없다.

### P1 — 연령에 맞지 않거나 막히는 요소
1. **용어집 뜻이 한국어뿐이다.** 단어 카드는 `word = meaning`이고 meaning은 한국어다(`lib/widgets/glossary_text.dart:251-290`, `s5_ep02.g.dart:278-282`, `levels.json` glossary). 영어 정의를 보여주는 경로나 locale/l10n은 없다(`lib/app.dart:106-110`). 영어권 아동에게 Junior/Master의 어려운 어휘(decipher, smuggle, concealed…)는 사실상 설명이 없는 셈이다. 영향: **Case 02–12 모든 미션**(특히 Junior·Master 레벨).
2. **GYEONGSUN을 정확한 로마자로 타이핑해야 한다.** 8세에게 낯선 한국어 로마자 철자를 OS 키보드로 정확히 입력하라는 요구다. accepted 변형은 하이픈과 공백뿐이고 부분 정답도 없다(`content_pipeline/.../s5_ep08/case.plan.json` answerSpec, `question_widgets.dart:384-386`). NAM GIHO는 NAM이나 GIHO만 쳐도 정답이라 완화되어 있다. 영향: C08M3. (힌트 2개가 철자를 알려주는지는 확인하지 않았다.)
3. **evidence_talk 파이널에는 힌트 버튼이 없다.** plan에 힌트 2개가 있는데 `_talkFinal`이 CaseTalk만 그린다(`final_mission_screen.dart:868-879`, `case_talk.dart`에 hints 매개변수 없음). 대신 2번 틀리면 정답 카드에 불이 들어오므로(`case_talk.dart:632-670`) 진행은 된다. 막히지는 않지만 힌트 UX가 다른 엔진과 다르다. 영향: C04F, C07F, C09F.

### P2 — 개선 필요
4. **퍼즐 화면에 편지가 없다.** 단서 문서를 보려면 "Reread Letter" 시트를 오가야 한다(`mission_screen.dart:2209-2214,1310-1344`). 지시문(question)도 `CenteredScroll`과 함께 스크롤되어 사라진다(`:2186-2201`). 편지 300자 이상을 기억하며 풀어야 하는 미션: C05M2(332), C07M2(327), C08M3(317), C10F(307), C06M2(294). 영향: 편지 단계를 쓰는 엔진 전부(number/word/sequence/timeline/picture/letterLock/syllable).
5. **용어집 단어에 표시가 없고 길게 눌러야 한다.** 어떤 단어를 눌러 볼 수 있는지 알 수 없다(`glossary_text.dart:16-21`). 안내는 편지 단계와 둘러보기 문서에만 있다(`mission_screen.dart:2130`, `scene_explore.dart:745`). 증언 Words 시트는 "Tap"이라 조작이 서로 다르다(`dialogue_investigation.dart:1561`). 영향: 전 미션, 특히 C08M1.
6. **퍼즐 진행이 저장되지 않는 엔진이 많다.** 앱을 닫으면 검색, 둘러보기, 흔적, 돋보기, 기록, 증언, 문자자물쇠, 다이얼, 순서, 키패드가 모두 처음으로 돌아간다(`investigation_search.dart:209-213`, `scene_explore.dart:10-11`, `scene_deduction.dart:9-10`, `lens_inspect.dart:10-11`, `dialogue_investigation.dart:7-9`, `final_mission_screen.dart:485-486`). 저장되는 것은 timeline, syllable, case_talk뿐이다. 영향: C02M1, C09M2, C04M1, C11M1, C05M1, C12M1, C06M1, C07M1, C11M2, C08M1, 모든 letterLock/dial 파이널.
7. **문자자물쇠가 미끼 없는 애너그램이다.** 정답 글자 타일만 있어서 4–5글자는 몇 번 바꿔 보면 풀린다(DROP 24, LIGHT 120가지). 오답 페널티도 없다(`answer_checker.dart:47-53`, plan options). 추리 대신 찍기가 가능하다. 영향: C10M3, C12F(그리고 C02F, C06F는 720가지).
8. **작은 폰에서 6칸 문자자물쇠의 슬롯이 좁아질 수 있다.** 슬롯은 64dp 고정이지만 `Flexible` 안에 6개가 들어가서 320폭 파이널 판에서는 칸당 약 33–40dp로 줄어든다(추정). 탭과 드래그 목표가 44dp보다 작을 수 있다. 엔진 전용 320폭 테스트는 찾지 못했다(`letter_lock.dart:128-141,219-220`; `test/letter_lock_title_test.dart`는 제목 테스트). 영향: C02F DRAGON, C06F FORCED.
9. **dark_room_search와 witness_compare의 plan 오답 피드백은 죽은 데이터다.** 런타임은 목록을 다 찾거나 맞는 짝을 고르면 정답만 보낸다(`investigation_search.dart:388-396`, `dialogue_investigation.dart:7-11`). 그래서 plan options의 feedback("The straw was next to the door…", "Only Mr. Pyo says the second…")은 아이에게 보이지 않는다. 기획 의도와 실제 동작이 다르다. 영향: C02M1, C09M2, C08M1.
10. **2번째 힌트가 20코인이고, 부족하면 보상형 광고로 이어진다.** 시작 20코인에 미션당 5코인이라 몇 번 쓰면 바로 부족해지고, 그때 GET COINS(광고)를 권한다(`app_constants.dart:115,119,126`, `tip_shop.dart:203-224,267-269`). 아동용으로는 정책 검토가 필요하다. 영향: 전 미션.
11. **order_sequence에 "순서대로 탭하세요" 안내가 화면에 없다.** question만 있고 빈 Step 줄의 뜻은 스크린리더 라벨에만 있다(`question_widgets.dart:861-895`). timeline_board에는 안내가 있다(`timeline_board.dart:156`). 영향: C03M3, C06M2, C08M2, C10M1.
12. **Case 02–12에 한글 발음 듣기가 없다.** C02M2 거북선과 C04M1 가/다 같은 한글 요소가 나오지만 voice가 없어 LISTEN 버튼이 숨는다(`syllable_board.dart:33,244`; voice는 ep01뿐). 로마자 표기("says geo", `:369`)만 있다. 영향: C02M2(그리고 한글 표식이 나오는 장면).
13. **record_mismatch 글씨가 그림 비율로 그려진다.** 작은 폰에서 행 높이와 글씨가 작아질 수 있다(`tower_records.dart:257-260,335-385`). "Look closer"가 있지만 측정하지 않았다. 영향: C07M1, C11M2.

### P3 — 경미
14. **number_entry**: 오답 제출 뒤 입력이 전부 지워진다(`question_widgets.dart:526-528`). 같은 숫자에서 한 자리만 고치고 싶을 때 불편하다. 다이얼은 반대로 값이 유지되어 엔진끼리 일관성이 없다. 영향: number_entry 8개 미션.
15. **combo_dial_lock**: 재진입하면 0으로 초기화되고, ▲▼로만 돌릴 수 있다(숫자를 직접 탭할 수 없음). 1796이면 탭이 많이 필요하다(`final_mission_screen.dart:640-642,1325-1350`). 영향: C03F, C08F.
16. **scene_explore와 trace_deduction 표식**은 아이콘이 30/40dp로 작아 보인다. 실제 히트는 그림 영역에 slack을 더한 크기라 문제는 작다(`scene_explore.dart:326`, `scene_deduction.dart:287-288`). 영향: C05M1, C12M1, C06M1.
17. **정답에 어퍼스트로피나 하이픈이 들어간 accepted(JAPAN'S, GYEONG-SUN)**는 입력 필터가 막지만 비교에서 무시되므로 동작에는 문제가 없다. 다만 화면에 하이픈을 칠 수 없다는 안내는 없다(`question_widgets.dart:384-386`, `answer_checker.dart:12-14`).
18. **보호자 화면과 리포트가 한국어 전용이다**(`parent_report_screen.dart`, `parent_gate.dart:63`). 영어권 보호자는 읽을 수 없다. 영향: 앱 전체(퍼즐 밖).

## 4. 확인하지 않은 것
- 실제 기기와 위젯 렌더링. 6칸 자물쇠 폭, 기록 글씨 크기, 키보드가 올라온 상태의 레이아웃은 모두 추정이다.
- 난이도별(Rookie/Junior/Master) 힌트 문구 하나하나의 내용, 그리고 GYEONGSUN 철자를 힌트로 알려주는지.
- 테스트는 실행하지 않았다. 인용한 320×568 테스트는 존재 여부만 확인했다.
