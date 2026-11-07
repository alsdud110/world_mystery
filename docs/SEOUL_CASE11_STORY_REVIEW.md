# Seoul Case 11 — 스토리·퍼즐 전면 조사

- 작성: 2026-11-07, 조사·설계안만 (콘텐츠·코드·테스트 수정 없음)
- 기준: 작업 트리의 `content_pipeline/seasons/s5_seoul/cases/s5_ep11/case.plan.json`·`levels.json` (**R1~R3 미커밋 변경 포함** 상태), `planning/story_bible.json`, `planning/history_dossier.json`, `planning/puzzle_selection.json`, `docs/SEOUL_ROOKIE_AUDIT.md`, `tool/season_gen/GAMEPLAY_CATALOG.md`
- 핵심 질문: 윤동주의 이야기에서 왜 한글 창제 원리(가획) 퍼즐이 나오는가?
- **결론 요약: 원본 스토리 안에 근거가 없다.** 퍼즐 선정 도구도 M2에 맞는 방식을 찾지 못했고(`selected: null`), 사람이 손으로 `syllable_compose`를 골랐다. 그 퍼즐을 정당화하는 대사는 사건 자체의 논리와도 어긋난다. 설계 문제로 기록하고, M2 교체를 권한다.

---

## 1. Case 11 전체 스토리 요약

| 항목 | 내용 |
|---|---|
| 시대·장소 | 1941년 늦가을, 서울 연희전문학교 (윤동주의 방 → 대강당 → 교문). 방·강당·피아노는 창작 |
| 등장인물 | **윤동주**(실존, 대사·행동은 창작) — 시집을 손으로 세 부 베낀 시인 / **미리**(창작) — 1941년의 '지키는 사람(keeper)', 해수의 사촌 / 탐정(플레이어) / 언급만: 소라·분이(C01), 해수(C09~10), 정병욱(실존, 엔딩) |
| 사건의 시작 | 윤동주는 졸업 기념 시집을 인쇄하지 못해 손으로 세 부 베꼈다. 오늘 밤 친구에게 줄 사본(흰 끈)이 책상에서 사라졌다. 사무실 사람이 오늘 밤 방을 검사한다(hook). |
| 최종 목표 | 친구용 사본을 찾고, 그의 시가 왜 중요한지 알기 |
| 진상(창작) | 미리가 한국어 원고가 위험해지자 사본을 하룻밤 숨겼다 — 강당 피아노 속 지키는 사람들의 편지 상자 |
| 역사적 결말(사실) | 윤동주는 학교에서 한국어가 밀려나던 때 한국어로 시를 썼다(h4·h5). 사본 세 부 중 정병욱의 사본을 그 가족이 마루 밑에 숨겼고(h6), 1948년 『하늘과 바람과 별과 시』로 나왔다(h7). |
| 시즌 연결 | 앞: C10 해수의 물방울 쪽지(s5_ep10_e1), C01 분이의 물동이(s5_ep01_c1). 뒤: 미리가 상자를 충칭으로 보냄(s5_ep11_e4 → C12 M1) |

### 미션 흐름

| 미션 | 스토리 | 플레이어 행동 | 정답 | 다음 미션과 연결 |
|---|---|---|---|---|
| **M1** The Desk by the Window (`lens_inspect_word`) | 윤동주가 사본 셋(선생님·친구·자신)을 설명. 사전이 옮겨져 있다. | 돋보기로 책상을 훑어 "빨간 책등의 두꺼운 책"을 찾고, 그 밑 쪽지의 지워진 단어 입력. 파란 잉크병은 "not ink"로 배제 | **WATER** (분이의 물동이 → 물방울 표식) | 쪽지 = 지키는 사람의 물방울 쪽지 → M2에서 펼침 |
| **M2** A Riddle in the King's Letters (`syllable_compose`) | 쪽지가 "옛 방식"(C01 소라의 수업)으로 쓴 수수께끼 | 편지 속 '소라의 판'(ㄱ·ㄴ·ㅁ·ㅅ·ㅇ = 신체 부위, 한 획 = 더 센 소리)을 보고 초성·모음·받침을 골라 네 글자를 세로쓰기 칸에 조립(~18탭). ㅁ+2획=ㅍ | **피아노안** (피아노 안) | 강당의 피아노 → M3 |
| **M3** The Box in the Piano (`number_entry`) | 피아노 속 번호 자물쇠 상자. 미리가 나타나 자백("Papers in Korean can get a student in trouble now.") | "사본 수, 그다음 사본당 시 수를 나란히" 규칙을 읽고 3 + (18+1) → 입력 | **319** | 친구의 사본(흰 끈, King's letters로 쓰임) → Final |
| **Final** In His Own Language (`word_entry`) | 새벽, 교문에서 친구를 기다림 | 노트 문장(1938년 조선어 선택과목화, 학교는 일본어로 가르침, 사본은 세종의 글자로 쓰임)을 읽고 언어 이름 입력 | **KOREAN** | 엔딩: 정병욱에게 사본 전달, 마루 밑 보관, 1948 출간 → C12 |

---

## 2. M1~Final 실제 퍼즐과 정답

| 미션 | 엔진 | 정답 | 풀이 근거 | 사실/창작 |
|---|---|---|---|---|
| M1 | lens_inspect_word | WATER (오답 피드백: INK, RAIN) | "the thick book with a red spine", "not ink", 분이의 물동이 | 전부 창작(책상·사전·쪽지). 사본 3부와 받는 사람은 사실(h3) |
| M2 | syllable_compose (`columnHeight 2`) | 피아노안 (오답: 비아노안·미아노안·노안피아·피어노안) | 소라의 판 + "+ 2 lines" + 모음 위치 문장 + 오른쪽 열부터 | 창작. **dossier 팩트 연결 0개**(`factIds: []`) |
| M3 | number_entry | 319 (오답: 119·219·318, 순서 오류) | 사본 3(h3), 18편+서시 1편 = 19(h2), "side by side" 규칙(창작) | 숫자는 사실, 자물쇠 규칙은 창작 |
| Final | word_entry | KOREAN (허용: THE KOREAN LANGUAGE 등; 오답: JAPANESE·HANGEUL·CHINESE·ENGLISH) | 1938 선택과목화(h4), 한국어로 쓴 시(h5) | 사실 |

---

## 3. 역사적 연관성 평가

### 3.1 퍼즐별 평가

| 질문 | M1 WATER | M2 피아노안 | M3 319 | Final KOREAN |
|---|---|---|---|---|
| ① 윤동주의 생애·작품과 직접 관련 | 약함 (사본 3부 소개만) | **없음** | 강함 (사본 3부·19편) | 강함 (한국어로 쓴 시) |
| ② 1941년 시대 배경과 연결 | 약함 | **없음** (1446년 원리) | 보통 | 강함 (1938 교육령) |
| ③ 사실·창작 구분 | 됨 (notes) | 됨 (창작 명시) | 됨 | 됨 |
| ④ 윤동주에 대해 배우는 것 | 사본이 셋 | **없음** (배우는 건 훈민정음 원리) | 시 19편, 손으로 세 부 | 왜 한국어로 쓴 것이 의미 있는가 |
| ⑤ 다른 인물 Case에 넣어도 성립하는 범용 퍼즐? | 반쯤 (시즌 공통 물방울 회수) | **예.** 답 글자만 바꾸면 어느 Case에도 들어감 (실제로 C01 M3 서고지붕, C02 M2 거북선과 같은 틀) | 아니오 | 아니오 |
| ⑥ 앞뒤 미션과 논리 연결 | 좋음 | 형식상 연결(쪽지 → 장소)만 있음 | 좋음 | 좋음 |

### 3.2 M2 한글 가획 퍼즐의 근거 조사

원본에서 찾은 근거와 그 한계:

1. **story_bible C11 `fromPrevious`**: "The letters themselves (s5_ep01_e2): Hangeul is taught less and less in the schools."
   → 바이블이 의도한 연결은 **"세종의 글자 → 1941년 그 글자로 쓴 언어가 학교에서 밀려남"**이다. 이것은 Final(KOREAN)이 이미 정확히 전달한다. 바이블은 "글자를 만드는 원리"를 퍼즐로 쓰라고 하지 않는다.
2. **story_bible clueThread** `s5_ep01_e2 → s5_ep11_m2`: "Sora's Lesson Board reads Miri's riddle". 이것은 퍼즐을 정한 **뒤에** 적힌 연결 기록이지 이유가 아니다.
3. **puzzle_selection.json M2**: `traits: []`, `candidates: []`, `selected: null`, 사유 "no trait its words show: write the clue into the case, or choose by hand and say why". `planned: syllable_compose`, `plannedIsSelected: false`.
   → **선정 도구가 이 미션의 이야기에서 어떤 퍼즐 특성도 찾지 못했고, 사람이 고른 이유("say why")는 어디에도 기록되지 않았다.**
4. **history_dossier M2**: `fiction: true`, 사실 연결 없음. 도출 설명은 "Sora's board (Case 01, built on Hunminjeongeum's facts there)"로 C01의 사실에 기댄다.
5. **게임 속 정당화 대사**: "The keeper made it the old way, like Sora's lesson." / "Only a person who knows how the letters are made can read it," Yun smiles.

**판정: 근거 없음 — 설계 문제.** 게임 속 정당화도 사건 논리와 충돌한다.

- **내부 모순**: M3에서 미리는 "Papers in Korean can get a student in trouble now."라고 말한다. 위험한 것이 '한국어 문서'라면, 숨긴 장소를 **한글로 된 수수께끼**로 남기는 건 위험을 줄이지 못하고 오히려 늘린다.
- **비밀 유지 논리 없음**: 1941년 조선의 검사자는 한글을 읽을 수 있다. 가획 원리로 "피아노"를 쓴다고 감춰지지 않는다. "글자가 만들어진 원리를 아는 사람만 읽는다"는 대사는 사실이 아니라 게임 장치일 뿐이다.
- **인물 논리 없음**: 윤동주는 소라(1446, 창작 인물)를 모른다. 미리가 1446년 소라의 수업 방식으로 쓸 이유는 '지키는 사람 집안의 전통'뿐인데, 그 전통은 시즌 어디에도 "수수께끼는 가획으로 쓴다"는 규칙으로 정해져 있지 않다(C02~C10의 물방울 쪽지는 이 방식을 쓰지 않음).
- **학습 초점 이탈**: C11에서 한국어 단어가 가장 많은 미션이 1446년 문자 원리 설명이다(편지 15줄, ROOKIE 첫 조작 전 143어로 P0 판정 — `SEOUL_ROOKIE_AUDIT.md`). 윤동주·시·1941년에 대해서는 한 문장도 배우지 않는다.
- **반복**: 같은 조립 퍼즐이 C01 M3·C02 M2·C11 M2 세 번 나오고, C11은 시즌 막바지라 C01의 규칙을 10개 Case 뒤에 다시 꺼내야 한다(R1에서 편지에 판을 넣어 P0는 땜질했지만 근본 원인은 남음).

### 3.3 C11 안의 세종·글자 원리 반복 정도

현재 C11 `case.plan.json`(R1 반영본)에서 등장 횟수(notes 포함): `Sora` 8, `stronger` 9, `the mouth` 8, `tongue` 6, `throat` 5, `old way` 4, `King's letters` 9, `Sejong` 3.
가획·신체 부위 어휘는 **전부 M2**에서 나온다. M2를 바꾸면 C11의 세종 관련 표현은 "King's letters"(시즌 공통 표현)와 Final의 Sejong 한 줄 + 힌트·피드백 정도만 남는다. 이 정도면 **시즌을 잇는 실**로서 적절하며 과도하지 않다.

---

## 4. M2 대체 퍼즐 3개

공통 전제

- M2의 역할은 그대로: **물방울 쪽지 → "강당 피아노 안"을 알아내 M3로 보낸다.** 출력 단서 `s5_ep11_c2`(피아노 안)와 M3 장소는 바뀌지 않는다.
- 시즌 관례상 쪽지는 "King's letters로 쓰였다"고 말하고 **화면에는 영어로** 보여 준다(C10 M3, C12 Final과 같음). 한글을 직접 해독할 필요가 없다.
- 시의 본문은 인용·번역하지 않는다는 기존 규칙(notes)을 지킨다.

### 제안 A — "Yun's Copy List" (두 목록 비교, `record_mismatch`)

| 항목 | 내용 |
|---|---|
| 스토리 연결 | 윤동주는 꼼꼼해서(바이블: "careful with every word") 세 사본을 적은 목록을 책상에 둔다(창작). 미리의 쪽지는 **그 목록과 똑같은 꼴로 쓴 한 줄짜리 카드**다. 윤동주만 자기 목록을 알기에, 바뀐 한 줄을 알아챌 수 있다. 검사자가 보면 그냥 사본 목록이다. |
| 화면 단서 | 종이 A — **YUN'S LIST** (친구의 사본 칸): FOR: Jeong Byeong-uk / STRING: white / POEMS: 18 and 1 opening poem / KEPT: on my desk  · 종이 B — **THE WATER-DROP CARD**: FOR: your friend / STRING: white / POEMS: 18 and 1 opening poem / KEPT: under the black and white keys |
| 조작 순서 | ① 종이 A를 탭해 읽음 ② 종이 B를 탭해 읽음 ③ 서로 다른 줄 한 쌍을 고름 ④ (전환 대사) 바뀐 말 "the black and white keys"가 무엇인지 윤동주와 추리 → 피아노 |
| 정답 | `kept:kept` (다른 줄 쌍). 이후 전환: "Black and white keys... the piano in the college hall!" |
| 힌트 1 | "Read the two papers line by line. Three lines are the same." |
| 힌트 2 | "Look at KEPT. What has black and white keys?" |
| 오답 피드백 | FOR 쌍: "Jeong Byeong-uk is Yun's friend. These lines say the same thing." / STRING 쌍: "Both say white." / POEMS 쌍: "18 poems and 1 opening poem: the same." |
| ROOKIE 영어 | story: "You open the note. It looks like Yun's list." / "One line is not the same." · question: "Which line is different?" · transition: "\"Black and white keys?\" Yun says. \"The piano in the hall!\"" |
| 역사 사실 | 사본 3부와 받는 사람 — 선생님 이양하, 후배 정병욱, 자신(h3) / 18편 + 서시 = 19편(h2) |
| 창작 | 사본 목록, 물방울 카드, "KEPT" 칸, 피아노 |
| 앞뒤 연결 | M1의 흰 끈·사본 셋을 그대로 씀. **M3의 "18 and 1 opening poem"을 M2에서 먼저 증거로 얻으므로 M3가 '앞에서 찾은 증거를 다시 쓰는' 구조가 된다**(CLAUDE.md §20). 정병욱 이름이 일찍 나와 엔딩의 사본 전달이 미리 깔린다. |
| 반복 여부 | `record_mismatch`는 시즌에서 C07 M1 한 번만 사용. C11 안에서 겹치는 조작 없음 |
| 약점 | 다른 줄이 하나라 추리 난도는 낮다(ROOKIE엔 적당, Master는 줄을 늘리거나 함정 줄 1개 추가 필요 — 엔진의 정답 쌍 유일성 검사 `scene_ambiguous`에 걸리지 않게 설계) |
| 작업량 | **중간.** 엔진·생성기 기존 지원. 필요한 것: 빈 종이 그림 2장(사본 목록용 원고지풍 종이, 카드) 생성·측정(`records.first/second`의 crop·sheet 좌표), case.plan M2 재작성, levels 3단계 문구, dossier·selection·bible 갱신, 재생성, 관련 테스트 교체 |

### 제안 B — "Who Saw the White String?" (증언 비교, `witness_compare`)

| 항목 | 내용 |
|---|---|
| 스토리 연결 | 쪽지에는 "The copy is safe. Ask who was awake."만 있다. 그날 밤 기숙사에 깨어 있던 두 사람의 말을 비교한다: **송몽규**(실존, 윤동주와 함께 연희전문에 다닌 사람 — dossier h1·h8 출처 인용문에 등장. 대사는 창작)와 **야간 경비원**(창작). |
| 화면 단서 | 질문: "What did you see tonight?" / "Where did it go?" · 송몽규: "A young woman ran past. She had a thin book with a white string." / "She went into the college hall." / "The office man starts on the first floor." · 경비원: "Nobody went out of the gate tonight." / "In the hall, someone closed the piano lid. There was no music." |
| 조작 순서 | ① 증인 선택 ② 질문 ③ 답이 노트에 기록 ④ 두 진술을 골라 비교(같은 곳을 가리키는 쌍) ⑤ 결론 대사 |
| 정답 | 송몽규 "went into the college hall" + 경비원 "closed the piano lid" 쌍 → 강당 피아노 |
| 힌트 1 | "Which two people talk about the same place?" |
| 힌트 2 | "She went into the hall. What did the guard hear in the hall?" |
| 오답 피드백 | "first floor"+"gate": "These talk about different places." / "white string"+"gate": "The book did not go out of the gate. Where did it go?" |
| ROOKIE 영어 | "Two people were awake tonight. Ask them." / "Find two answers about the same place." |
| 역사 사실 | 윤동주는 1938년 연희전문에 진학해 송몽규 등과 함께 공부했다(h1 출처 인용). 1943년 둘은 함께 체포되었다(h8, 엔딩에서만 한 줄). |
| 창작 | 그날 밤, 송몽규의 대사, 경비원, 피아노 뚜껑 |
| 앞뒤 연결 | M1 흰 끈 → 증언의 흰 끈. M3에서 미리 등장 시 "the young woman"의 정체가 밝혀져 반전이 생긴다. |
| 반복 여부 | `witness_compare`는 C08 M1 한 번만 사용 |
| 약점 | 윤동주의 시 자체와는 간접 연결. **송몽규가 윤동주의 사촌이라는 사실 등은 dossier에 독립 팩트로 없음 → 출처 확인 필요.** 실존 인물을 한 명 더 등장시키는 부담 |
| 작업량 | **중간~큼.** 엔진·생성기 지원. 초상화 2장(송몽규, 경비원) + 대화 배경(dorm 재사용 가능) 생성, dossier에 송몽규 팩트 추가·출처 확인, `play.dialogue` 작성(질문 2 × 증인 2, deduction 대사 10+4줄) |

### 제안 C — "Water, Not Ink" (원고지 칸 읽기, 새 격자 조작)

| 항목 | 내용 |
|---|---|
| 스토리 연결 | 윤동주는 시를 **원고지**에 옮겨 적고 손으로 제본했다(h2 광양시 출처: "18편의 시를 원고지에 옮겨 적고"). 미리는 윤동주의 연습용 원고지 한 장의 몇 칸에 **물방울**을 찍어 장소를 남겼다. 잉크 얼룩도 섞여 있다. |
| 화면 단서 | 원고지 한 장(앱이 그리는 격자 + 윤동주 필체 대신 앱 텍스트 한글). 일부 칸에 물방울, 일부 칸에 잉크 얼룩. 쪽지: "Tap only the squares with a water drop. Not ink. Start at the top right. Go down." |
| 조작 순서 | ① 원고지 확대 ② 물방울 칸과 잉크 칸 구별 ③ 지시 순서대로 물방울 칸 탭 ④ 칸이 모이면 윤동주가 소리 내어 읽음: "피아노 — piano!" |
| 정답 | 물방울 칸 3개를 정해진 순서로 탭 (피·아·노) |
| 힌트 1 | "Water drops are light and round. Ink is dark." (M1 연결) |
| 힌트 2 | "Start at the top right square, then go down." |
| 오답 피드백 | 잉크 칸: "That is ink, not water." / 순서 오류: "Start at the top right." |
| ROOKIE 영어 | "Yun copies his poems on paper with little squares." / "Find the squares with water drops." |
| 역사 사실 | 원고지에 옮겨 적고 손으로 세 부 제본(h2·h3) |
| 창작 | 연습 원고지, 물방울 표식 위치 |
| 앞뒤 연결 | M1의 "not ink, water" 구별을 그대로 조작으로 확장. 원고지는 엔딩의 "사본"과 연결 |
| 약점 | ① **새 엔진 필요**(격자 탭 퍼즐 없음 — 퍼즐 엔진 변경 금지 조건에 걸림) ② 물방울·잉크 아이콘은 실제 에셋 필요(임시 도형 금지) ③ 세로쓰기·오른쪽 열 순서를 다시 써서 ROOKIE 부담이 이전 M2와 비슷 ④ 결국 한글 읽기 결과로 끝나 '세종 퍼즐' 인상이 남을 수 있음 ⑤ 윤동주 원고의 실제 쓰기 방향(가로/세로)은 dossier에 없음 → 확인 필요 |
| 작업량 | **큼.** 새 위젯·모델·생성기 지원·PlayCheck 규칙·테스트, 에셋 2종 |

### 비교

| 기준 | A Copy List | B Witnesses | C Manuscript |
|---|---|---|---|
| 윤동주·시와 직접 연결 | **강함** (사본·받는 사람·19편) | 보통 (동료·그날 밤) | 강함 (원고지) |
| 1941 배경 | 보통 | 보통 | 보통 |
| 사실 근거 (dossier) | h2·h3 그대로 | h1·h8 인용 + 추가 확인 필요 | h2 + 쓰기 방향 확인 필요 |
| ROOKIE 영어 부담 | 낮음 (표 4줄 × 2) | 중간 (질문·진술 6~8줄) | 중간 (위치 지시 + 세로 순서) |
| 실제 조작 | 읽기·비교·선택 + 수수께끼 추리 | 질문·기록·비교 | 관찰·구별·순서 탭 |
| M3·Final 연결 | **M3 숫자의 출처가 됨**, 엔딩 정병욱 예고 | M3 반전 강화 | M1 확장 |
| 시즌 내 반복 | C07 1회 | C08 1회 | 없음 (새 조작) |
| 엔진 변경 | 없음 | 없음 | **필요** |
| 새 에셋 | 종이 그림 2 | 초상화 2 | 아이콘·원고지 |
| 작업량 | 중간 | 중간~큼 | 큼 |

---

## 5. 가장 적합한 대체안: **A "Yun's Copy List"**

1. **윤동주에 대한 사실을 퍼즐 자체가 가르친다** — 누구에게 사본을 주었는지(h3), 시가 몇 편인지(h2). 지금 M2는 아무것도 가르치지 않는다.
2. **M2 → M3 → Final이 한 줄로 이어진다.** M2에서 얻은 "18 and 1 opening poem"을 M3 자물쇠에서 다시 쓰고, M2의 "Jeong Byeong-uk"가 엔딩에서 사본을 받는다. "앞에서 얻은 증거가 뒤에서 중요해야 한다"(CLAUDE.md §20)를 이 Case 안에서 처음으로 만족시킨다.
3. **사건 논리와 맞는다.** 위험한 건 '눈에 띄는 한국어 문서'다. 미리는 새 문서를 만들지 않고 윤동주의 목록과 똑같은 꼴의 카드에 한 줄만 바꿔 남겼다 — 주인만 알아챈다. M3의 미리 대사와 모순이 사라진다.
4. **엔진·저장 구조 변경 없음**, ROOKIE 영어 부담이 가장 낮고, 시즌 내 1회만 쓴 방식이라 반복도 적다.
5. 약점(추리 난도 낮음)은 수수께끼 한 단계("black and white keys" → piano)와 Master용 문구로 보완한다.

B는 이야기 긴장감이 더 크지만 실존 인물 추가와 출처 확인 비용이 있다. A 승인 후 시간이 남으면 B의 "the young woman" 목격담을 M3 도입 한 줄로 빌려 쓸 수 있다(선택).

---

## 6. M1·M3·Final 수정 필요 여부

**판단: M2 교체만으로 '왜 세종 퍼즐인가' 문제는 해결된다. 다만 M2의 출력이 바뀌므로 M1·M3·Final에 작은 문구 조정이 필요하다.** 퍼즐 방식·정답(WATER·319·KOREAN)은 모두 유지.

| 대상 | 필요 여부 | 내용 |
|---|---|---|
| M1 | 작음 | transition 마지막 줄을 M2로 이어지게("The note looks like Yun's list of copies."). 정답·돋보기 장면·에셋 그대로. (ROOKIE 감사 P2의 story 3번째 줄 중복 삭제도 이때 처리 가능) |
| M3 (319) | **작음~중간** | ① clueInputs에 M2 증거 recall 추가, ② 편지에서 "Each has eighteen poems, and one more poem to open the book."을 M2 증거 참조로 바꿔 단어 수 감소(ROOKIE P1 140어 해소에 도움), ③ 힌트 2 → "Look at Yun's list: 18 poems and 1 opening poem." 자물쇠 규칙(사본 수 → 시 수, 나란히)과 오답 피드백 119·219·318은 그대로 유효 |
| Final (KOREAN) | 거의 없음 | 이미 C11의 핵심(한국어로 쓴 시, 1938 교육령)을 정확히 전달. "King Sejong made his letters for the people's own language." 1줄과 CHINESE 피드백 1줄은 C01 → C11 시즌 실로서 적당하며 과하지 않다. 유지 권장(ROOKIE 감사 P2의 "choice subject" 쉬운 말 교체는 별건) |
| Case 메타 | 작음 | `keyWords`에서 `stronger` 제거·`list` 추가, glossary에서 `tongue`·`gums`·`throat`·`riddle` 제거(M2 전용), `learningGoal` "숫자·위치·언어" → "목록·숫자·언어", objectives 2번 "Read the keeper's riddle." → "Compare the note with Yun's list." |
| 세종 반복 | 해소 | M2 제거로 Sora·가획·신체 부위 표현이 C11에서 모두 빠짐 |

### 다른 Case·시즌 구조 영향

- **C11 M2의 출력(`s5_ep11_c2`, `s5_ep11_e2`)은 C11 M3에서만 쓰인다.** C12는 `s5_ep11_e4`(Final 증거)만 참조 → 영향 없음.
- **C01 소라의 판(`s5_ep01_e2`)**: C11에서의 회수가 사라져도 C02(M2)·C04가 여전히 회수하므로 "앞 증거가 뒤에서 쓰인다" 규칙은 유지된다. story_bible의 clueThread `s5_ep01_e2 → s5_ep11_m2` 1개 삭제, C11 `fromPrevious` 문구 정리 필요.
- `syllable_compose` 사용은 3회 → 2회(C01 M3, C02 M2). 한글 조립 퍼즐은 세종 Case(C01)에 남으므로 시즌 정체성은 유지.
- C02 M2(거북선 음절 조립)에도 "왜 이 Case에서 가획인가" 같은 질문이 성립할 수 있으나 **이번 조사 범위 밖이며 확인하지 않았다.**
- 지도 좌표(`seoul_case_maps_test.dart`의 C11 M2 "Yun's Room")는 장소가 같으므로 변경 없음.

---

## 7. 구현 예상 작업량과 영향 범위 (A안 기준)

| 작업 | 파일 | 규모 |
|---|---|---|
| M2 재작성 (`record_mismatch`, `play.records`) + M1/M3 문구 조정 + 메타 | `cases/s5_ep11/case.plan.json` | 중간 |
| ROOKIE·JUNIOR·MASTER 문구 | `cases/s5_ep11/levels.json` | 중간 (M2 신규 ~25줄, M1·M3 ~6줄) |
| 퍼즐 사실 연결 (M2에 h2·h3, M3 derivation) | `planning/history_dossier.json` (**현재 미커밋 변경 있음 → 그 위에 이어서 수정**) | 작음 |
| clueThread·fromPrevious | `planning/story_bible.json` | 작음 |
| 퍼즐 선정 기록 재생성 | `planning/puzzle_selection.json`, `quality_report.json` | 도구 실행 |
| 에셋: 빈 종이 그림 2장 (사본 목록 종이, 물방울 카드) 생성·측정 | `assets/seasons/season_05_seoul/cases/case_11/` | 이미지 예산 내 2장 + 측정 (승인 필요, R2 업로드 여부 결정 필요) |
| 생성 코드 재생성 | `lib/data/generated/s5_seoul/s5_ep11*.g.dart`, manifest | 도구 실행 |
| 테스트 교체 | `test/sandbox/s5_seoul_syllables_test.dart`의 C11 블록(215~237행, **R1 미커밋 변경 있음**)을 제거하고 record 검사로 이전, `test/sandbox/s5_seoul_rookie_test.dart`의 M3 단언 확인 | 작음 |
| 검증 | `flutter analyze`, Seoul sandbox 테스트, C11 플레이스루(season_playthrough), PlayCheck | 집중 테스트만 |

- 퍼즐 엔진·저장 데이터 형식 변경: **없음** (기존 `record_mismatch` 사용, 미션 id 유지 → 저장 진행도 호환. 단 M2 정답 형식이 문자열 `피아노안` → `kept:kept`로 바뀌므로, M2 진행 중 저장된 오답 기록이 있다면 의미가 없어질 뿐 깨지지는 않는지 구현 시 확인 필요).
- 다른 시즌·다른 Case 코드 수정: 없음 (story_bible의 C11 관련 항목만).

### 승인이 필요한 결정

1. 대체안 선택 (권장 A)
2. A안의 종이 그림 2장 이미지 생성 (시즌 이미지 예산 사용)
3. M3 편지 축약(M2 증거 참조) 동시 진행 여부
4. C02 M2도 같은 관점으로 조사할지 여부

---

### 이번 조사에서 하지 않은 것

- 콘텐츠·코드·테스트 수정, 이미지 생성, R2 업로드, 커밋 — 하지 않음
- 앱 실행·실기기 확인 — 하지 않음
- 송몽규 관련 사실, 윤동주 원고의 쓰기 방향 — 외부 출처 확인하지 않음 (B·C안 채택 시 필요)
