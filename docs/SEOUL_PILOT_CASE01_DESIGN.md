# Seoul Pilot Case 01 — "The Missing Royal Letter" 기획서

작성일 2026-11-04 · 범위: 역사 자료 조사, 스토리·미션 설계까지.
하지 않은 것: 코드 수정, 기존 시즌 변경, 서울 시즌 생성(`plan_season init` 포함), 이미지·사운드 생성, 유료 API 호출, 커밋·푸시, 역사 사실 승인.

표기:
- **[사실]** = 아래 §1 출처로 확인한 역사.
- **[창작]** = 이 게임을 위해 지어낸 것.
- **[미확인]** = 조사했지만 두 출처를 확보하지 못했거나 해석이 갈림. 게임에 쓰지 않는다.

이야기 틀: 사용자 지시에 따라 **안 B(시대 현장)** 로 기획했다. 1446년 가을 한양 궁궐이 무대다. PART 0~2에서 미결이던 "A 현재 전시 / B 시대 현장" 결정을 이 시범 Case에서는 B로 둔다. 시즌 전체에 적용할지는 §9의 결정 항목으로 남긴다.

---

## 0. 기존 시스템 확인 결과 (요약)

| 확인 대상 | 이 기획에 주는 제약 |
|---|---|
| Historical Fiction Mystery PART 1·2 | 사실 ID는 `s5_ep01_h<n>`. 사실마다 출처 2개 이상, **서로 다른 publisher**, 그중 1개 이상 `primary`/`public_institution`, `quote` 또는 `location`, `checkedAt` 필요. 파일에는 `source_checked`까지만 쓸 수 있고, `approved`는 사람이 터미널에서 직접 승인해야 한다. 게임 글에 나오는 4자리 연도는 승인 사실이나 `fiction`에 있어야 한다. 실존 인물은 등장인물(대사·행동)로 쓸 수 없다. reveal은 ROOKIE/JUNIOR/MASTER 3레벨로 쓴다. |
| Puzzle Engine V2 3A–3C | `timeline_board`: 카드 3–11장, 고정 카드 1–3장(anchor는 자유 텍스트이므로 "Sunset"을 쓸 수 있음), 제외 카드 ≤2장, 미션 화면 전용. |
| STEP 1 | 생성 가능한 퍼즐은 15종이다. Final 화면에서 쓸 수 있는 것은 `text_choice`, `word_entry`, `number_entry`, `order_sequence`, `letter_tile_lock`, `combo_dial_lock`, `picture_choice`, `evidence_talk`이다. 모든 미션은 dossier에 등록해야 하고(`factIds` 또는 `fiction: true`), Case마다 사실 기반 퍼즐이 1개 이상 있어야 한다. 선택기는 키워드 규칙으로 고르며 결과는 제안이다. |
| 기존 Case 분량 | 미션 1–5개 + Final. New York Case 01은 미션 3개 + Final(`witness_compare`, `text_choice`, `scene_explore_choose`, `order_sequence`)이다. 이 Case도 **미션 3개 + Final**로 맞춘다. |
| 폰트 | 번들 폰트에 한글이 없다(STEP 1 §10). 그림 속 글자도 금지다. → **이 Case는 한글 자모를 화면에 그리지 않는다.** 글자 모양은 영어 설명("a round dot", "a flat line", "a standing line")으로만 다룬다. |

---

## 1. 역사적 배경과 출처

조사일 2026-11-04. 출처는 모두 이번에 직접 열거나 본문을 추출해 읽었다.

출처 기관(publisher) 구분:
- 조선왕조실록·승정원일기·우리역사넷 = **국사편찬위원회**
- 한국민족문화대백과사전 = **한국학중앙연구원**
- UNESCO = **UNESCO**
- 한국의 세계기록유산 = **유네스코한국위원회/세계기록유산 한국위원회**
- 국립한글박물관 = **국립한글박물관**

같은 기관의 두 페이지는 "출처 2개"로 세지 않는다(PART 1 §5 규칙 2).

### 1.1 사실 후보 (`draft` → 사람 검토 후 `source_checked` → 승인)

| ID | 사실 (dossier statement 초안) | 출처 (kind · publisher · 위치/인용) | 자료 간 차이와 처리 |
|---|---|---|---|
| **h1** | 세종은 1443년(세종 25년) 12월에 새 글자 28자를 만들고 이를 훈민정음이라 불렀다. | ① primary · 국사편찬위원회 · 『세종실록』 102권, 세종 25년 12월 30일 2번째 기사 https://sillok.history.go.kr/id/kda_12512030_002 — "是月, 上親制諺文二十八字 … 是謂訓民正音" ② public_institution · UNESCO · Memory of the World "Hunminjeongum Manuscript" https://www.unesco.org/en/memory-world/hunminjeongum-manuscript — "the development of which he completed in 1443" ③ public_institution · 국립한글박물관 상설전시 https://www.hangeul.go.kr/exhi/dailyExhibition.do?curr_menu_cd=0102010000 — "1443년 세종은 우리의 문자 '훈민정음'을 만들었습니다" | 연도는 일치한다. 날짜는 실록이 "이달에"라고만 해서 게임에 쓰지 않는다. → `conflict: none` |
| **h2** | 책 『훈민정음』(해례본)은 1446년(세종 28년) 음력 9월에 완성되었다. | ① primary · 국사편찬위원회 · 『세종실록』 113권, 세종 28년 9월 29일 4번째 기사 https://sillok.history.go.kr/id/kda_12809029_004 — "이달에 《훈민정음(訓民正音)》이 이루어졌다" ② public_institution · UNESCO · 위 페이지 — "published in the ninth lunar month of 1446" ③ public_institution · 한국의 세계기록유산 https://www.kmowkc.org/front/heritage/detail.do?heritageId=U001&type=intro — "1446년 음력 9월 상순에" | 날짜가 다르다(실록 9월 29일 기사 vs 정인지 서문 "9월 상순"). → `resolved`: 게임에는 **연도 1446만** 쓴다. PART 0 §4.5에서 예견한 불일치와 같다. |
| **h3** | 『훈민정음』 해례 제자해에 따르면 기본 자음 다섯 글자는 소리 낼 때의 발음 기관(혀·입·이·목구멍) 모양을 본떴다. | ① public_institution · 국사편찬위원회 · 우리역사넷 「한글의 구성 원리」(제자해 번역) https://contents.history.go.kr/id/hm_091_0030 — "'ㄱ'은 혀뿌리가 목구멍을 닫는 꼴 … 'ㅅ'은 이의 꼴을 본뜬 것" ② academic · 한국학중앙연구원 · 한국민족문화대백과 「훈민정음28자모」 https://encykorea.aks.ac.kr/Article/E0074518 — "ㄱ, ㄴ, ㅁ, ㅅ, ㅇ의 다섯 문자는 … 발음 기관의 모양을 본떠 만들고" ③ public_institution · 국립한글박물관 웹진 2020-10 https://www.hangeul.go.kr/webzine/202010/sub1_3.html | ㄱ의 설명이 출처마다 다르다. 해례 번역은 "혀뿌리가 목구멍을 막는", 국립국어원(korean.go.kr)의 현대 음성학 풀이는 "혓등이 연구개에 닿는"이다. 또 실록 1443년 기사는 "옛 전자(篆字)를 모방"이라고 적었다. → `resolved`: 게임은 **"the book says"의 요약("copy the tongue, mouth, teeth and throat")만** 쓰고, 글자별 세부와 기원 논쟁은 쓰지 않는다. ③ 웹진은 기본자를 "ㄱ, ㄴ, ㄷ, ㅅ, ㅇ"로 잘못 적어 출처로 쓰지 않는다(참고만). |
| **h4** | 해례에 따르면 기본 모음 세 글자 중 둥근 점(ㆍ)은 하늘, 평평한 선(ㅡ)은 땅, 서 있는 선(ㅣ)은 사람을 본떴다. | ① public_institution · 국사편찬위원회 · 우리역사넷 「한글의 구성 원리」 — "꼴이 둥긂은 하늘을 본뜬 것 … 꼴이 평평함은 땅을 … 꼴이 섬은 사람을 본뜬 것" ② academic · 한국학중앙연구원 · 「초출자」 https://encykorea.aks.ac.kr/Article/E0078696 — "'ㆍ'는 하늘의 둥근 모양, 'ㅡ'는 '땅의 평평한 모양', 'ㅣ'는 '사람의 서 있는 모양'" ③ public_institution · 국립한글박물관 웹진 2020-10 — "'ㆍ'의 둥근 모양은 하늘이 둥근 것을 본떴고 …" | 세 기관이 일치한다. → `none` |
| **h5** | 세종의 서문(어제)은 새로 28자를 만든 까닭을 "사람들로 하여금 쉬 익히어 날마다 쓰는 데 편하게" 하려는 것이라고 밝혔다. | ① primary · 국사편찬위원회 · 『세종실록』 세종 28년 9월 29일 — "새로 28자(字)를 만들었으니, 사람들로 하여금 쉬 익히어 날마다 쓰는 데 편하게 할 뿐이다" ② public_institution · 국립한글박물관 상설전시 — "그 어떤 백성이라도 누구나 쉽게 배워서 편히 쓸 수 있도록 만든 한글" | 일치한다. → `none`. 원문 "欲使人人易習便於日用耳" |
| **h6** | 정인지 서문은 "지혜로운 사람은 아침나절이 되기 전에 이해하고, 어리석은 사람도 열흘 만에 배울 수 있다"고 적었다. | ① primary · 국사편찬위원회 · 『세종실록』 세종 28년 9월 29일 (정인지 서문) — "지혜로운 사람은 아침나절이 되기 전에 이를 이해하고, 어리석은 사람도 열흘 만에 배울 수 있게 된다" ② public_institution · 국립한글박물관 상설전시 3부 — "'슬기로운 사람은 아침나절에 깨우치고, 어리석은 사람이라도 열흘이면 배울 수 있는'" ③ public_institution · 국사편찬위원회 · 우리역사넷 영상 책 이야기 https://contents.history.go.kr/front/ts/view.do?levelId=ts_b32 (①과 같은 기관이므로 보조) | 번역 표현만 다르다. → `none`. 게임 영어: "a wise person … one morning; a slow person … ten days". 아동용이라 "어리석은(foolish)"을 "slow"로 순화했다. 승인 시 확인할 것. |
| **h7** | 해례(풀이와 보기)는 집현전 학자들이 썼다. 정인지 서문은 정인지·최항·박팽년·신숙주·성삼문·강희안·이개·이선로 8명을 적었다. | ① primary · 국사편찬위원회 · 『세종실록』 세종 28년 9월 29일 — "집현전 응교 최항, 부교리 박팽년과 신숙주, 수찬 성삼문, 돈녕부 주부 강희안, 행 집현전 부수찬 이개·이선로 등과 더불어 … 해석과 범례를 지어" ② public_institution · UNESCO — "explanations and examples by scholars of the Hall of Worthies" | 실록에서 강희안은 집현전이 아니라 돈녕부 주부다. → `resolved`: 게임에서는 **"palace scholars"** 라고만 쓰고 인원수·이름은 쓰지 않는다. |
| **h8** | 승정원은 조선시대 왕명의 출납(왕의 명령과 신하의 보고가 오가는 일)을 맡은 관청이었다. | ① academic · 한국학중앙연구원 · 「승정원」 https://encykorea.aks.ac.kr/Article/E0032242 — "조선시대 왕명의 출납을 관장하던 관청" ② primary/public_institution · 국사편찬위원회 · 승정원일기 소개 https://sjw.history.go.kr/intro/intro.do — "승정원은 조선시대 왕명의 출납을 관장하던 관청으로" | 정식 명칭이 확정된 시점(1400/1405)은 자료마다 다르게 서술된다. 세종대에는 이미 존재했으므로 영향이 없다. → `resolved`. 게임 영어: "the Royal Secretariat, the office that carried the King's orders". |
| h9 (선택) | 1444년(세종 26년) 2월, 집현전 부제학 최만리 등이 언문 제작에 반대하는 상소를 올렸다. | ① primary · 국사편찬위원회 · 『세종실록』 103권, 세종 26년 2월 20일 https://sillok.history.go.kr/id/kda_12602020_001 — "집현전 부제학 최만리 등이 언문 제작의 부당함을 아뢰다" ② academic · 한국학중앙연구원 · 「최만리」 https://encykorea.aks.ac.kr/Article/E0057279 | 상소의 **진의에 대한 해석이 갈린다**. 백과는 "그 진의는 세종의 한자음 개혁에 반대한 것"으로 본다. 상소 원문에는 "二十七字諺文"이라는 표현도 있다. → **게임 퍼즐에는 쓰지 않는다.** reveal에 넣을지는 사용자 결정(§8). 넣는다면 "Some scholars wrote to the King against the new letters in 1444"까지만 쓴다. |

### 1.2 조사했지만 쓰지 않는 것 [미확인]

| 항목 | 이유 |
|---|---|
| 집현전 터 = 경복궁 수정전 자리 | 우리역사넷 1곳뿐이다. 무대를 "the palace in Hanyang"으로 일반화하고 경복궁 이름은 쓰지 않는다. |
| 1446년 세종이 머문 궁궐, 승정원 건물의 위치·구조 | 확인하지 않았다. 그림 프롬프트는 "조선 초기 궁궐 관청 내부" 수준으로 두고 특정 전각을 그리지 않는다. |
| 해례본 1940년 안동 발견, 국보 지정, 1997 유네스코 등재 | 출처(kmowkc, UNESCO)는 있지만 이 Case의 1446년 이야기와 무관하다. 시즌 후반 Case 후보로 남긴다. |
| "한글"이라는 이름이 20세기에 생겼다는 점 | 신뢰할 만한 출처를 1곳도 확보하지 못했다. 이야기 안에서는 "the new letters"라고만 부른다(1446년 사람의 말로 자연스러움). |
| 인정·파루 시각, 궁궐 문 여닫는 시각 | PART 0 §4.5의 자료 불일치. 시각 대신 "Sunset / Dawn"을 쓴다. |

---

## 2. 실제 역사와 창작 설정 구분

| 실제 역사 [사실] | 창작 [창작] |
|---|---|
| 1443년 28자 창제(h1), 1446년 책 완성(h2) | 1446년 가을의 **그 하룻밤**과 사건 전체 |
| 자음·모음 기본자의 모양 원리(h3, h4) | **"royal letter"**: 새 글자로 쓴 짧은 왕실 글을 아침에 궁궐 일꾼들에게 읽어 준다는 설정. 그런 행사가 있었다는 기록은 확인하지 않았고, 있었다고 주장하지도 않는다. |
| 서문의 창제 목적(h5), "아침나절 / 열흘"(h6) | 글의 **내용**은 h5 서문 문장을 쉬운 영어로 옮긴 것이다. 실제 왕의 말이므로 바꾸지 않는다. 인물이 그것을 읽는 장면은 창작이다. |
| 해례를 궁궐 학자들이 씀(h7) | "the scholars' sheet"(학자들의 설명 쪽지): 해례 내용을 요약한 가상의 쪽지 |
| 승정원이 왕명을 출납함(h8) | 승정원 서리 **Mun-su**, 문지기 **Taek**, 궁녀 **Sora**, 필사관 **Bae**, 출입 장부, 상자, 붓함 |
| (선택) 1444년 반대 상소(h9) | Bae의 동기(남의 글을 대신 써 주는 일감이 사라질까 두려움). 실제 상소자들의 동기와 **다르다**는 것을 reveal에서 분명히 한다(넣을 경우). |

**실존 인물 규칙:**
- 세종은 "the King"으로만 언급한다. 대사·행동·등장이 없다.
- 정인지 등 8학자, 최만리는 등장하지 않는다.
- 창작 인물의 이름은 실존 학자들의 성(정·최·박·신·성·강·이)을 피했다.

---

## 3. 전체 스토리

### 3.1 사건 발생 배경
1446년 가을, 새 글자를 풀이한 책이 막 완성되었다[사실 h2]. 궁궐에서는 내일 아침 새 글자로 쓴 왕실 글 한 장을 일꾼들에게 읽어 주기로 한다[창작]. 글에는 "누구나 쉽게 익혀 날마다 쓰라"는 왕의 뜻이 담겨 있다[사실 h5]. 글은 밤새 승정원의 상자에 보관된다. 승정원은 왕의 명령이 오가는 관청이다[사실 h8].

### 3.2 도입 장면
새벽. 서리 Mun-su가 상자를 연다. 왕실 글이 없고 낯선 종이 한 장이 들어 있다. 해가 뜨면 이 글을 읽어야 한다. Mun-su는 의심받을까 떨고, 플레이어(궁궐에 불려 온 젊은 조사관)가 사건을 맡는다.

### 3.3 등장인물 (모두 창작)
| 이름 | 역할 | 사건에서의 위치 |
|---|---|---|
| Mun-su | 승정원 젊은 서리. 글을 맡은 사람 | 의뢰인. 처음 의심받는 사람 |
| Taek | 밤 문지기. 출입 장부를 쓴다 | 증언(장부) 제공 |
| Sora | 궁녀. 밤에 찻잔을 치우러 들어왔다. 소매에 종이가 있었다 | **붉은 청어(가짜 용의자)** |
| Bae | 필사관. 사람들 대신 한자로 글을 써 주는 일을 한다 | **범인** |

### 3.4 핵심 미스터리
누가, 언제, 왜 진짜 왕실 글을 가짜 종이로 바꿨나? 진짜 글은 어디 있나?

### 3.5 단서와 증거 (수첩)
| 증거 ID(가칭) | 얻는 곳 | 내용 |
|---|---|---|
| `gate_book` | M1 | Taek의 장부: 상자를 잠근 뒤 들어온 사람은 Sora, 그다음 Bae. Bae 뒤로는 아무도 없음 |
| `scholars_sheet` | M2 | 학자들의 설명 쪽지: 28자, 기본 글자 모양, **"모든 사람이 쉽게 익혀 날마다 쓰도록"**, 아침나절/열흘 |
| `false_page` | M2 | 상자 속 가짜 종이: 다른 줄은 같고 **"Only for scholars. Not for common people."** 한 줄만 다름 |
| `torn_corner` | M3 | 두꺼운 종이의 찢긴 모서리 |
| `royal_letter` | M3 | 붓함 속에서 찾은 진짜 글 |
| `sora_practice` | M3 발견 장면 | Sora의 소매 속 종이 = 새 글자 연습지. "Day 10: I can read the dot, the flat line and the standing line!" |

### 3.6 범인과 진상
필사관 Bae가 범인이다.
- Mun-su가 상자를 잠그고 퇴근한 뒤, Bae는 붓을 가지러 왔다며 들어왔다.
- 진짜 글을 꺼내 자기 붓함에 숨기고, 목적 한 줄만 바꾼 가짜 종이를 넣었다.
- 동기: 누구나 글을 쓰게 되면 남의 글을 대신 써 주는 자기 일이 사라질까 두려웠다. 가짜 종이가 읽히면 "이 글자는 학자만 쓴다"는 말이 퍼질 것이라 생각했다.

### 3.7 반전
1. **Sora는 도둑이 아니다** (M3 끝). 소매 속 종이는 그녀가 열흘 동안 몰래 익힌 새 글자 연습지다. 의심의 증거가 오히려 왕의 뜻이 이루어지고 있다는 증거로 바뀐다.
2. **Bae도 새 글자를 이미 익혔다** (Final 끝). 가짜 종이를 새 글자로 썼다는 것 자체가 그가 배웠다는 뜻이다. "배울 수 없다"던 그의 말을 그의 손이 반박한다. Bae: "…Seven days."

### 3.8 사건 해결 장면
해가 뜬다. Mun-su가 진짜 글을 읽고, Sora가 옆에서 따라 읽는다. Bae는 고개를 숙인다. Mun-su가 말한다. "Then teach the others. You learned fastest of all." Case Closed 파일에 REAL HISTORY / IN THIS MYSTERY가 표시된다(§6.4).

---

## 4. 미션별 플레이 흐름

공통 흐름은 기존 그대로다: Story → Map 핀 → 장소 → (퍼즐 전 대화) → 엔진 → (퍼즐 후 대화) → Discovery.

| # | 제목 | 장소 [창작 공간] | 퍼즐 (`paletteId`) | 플레이어가 손으로 하는 것 | 근거 |
|---|---|---|---|---|---|
| M1 | The Night Book | 승정원 방, 새벽 | `timeline_board` | 장부와 증언 카드를 탭해 밤의 순서를 맞춘다. 무관한 카드 1장은 뺀다. | `fiction: true` |
| M2 | Two Papers | 같은 방, 등불 아래 | `record_mismatch` | 학자들의 쪽지와 가짜 종이를 넘겨 읽고, 서로 다른 줄 한 쌍을 탭한다. | h1, h3, h4, h5, h6 |
| M3 | Ink in the Copy Room | 필사실 | `trace_deduction` | 그림 속 흔적 3개를 모두 탭해 메모한 뒤, 세 흔적이 모두 가리키는 곳을 탭한다. | `fiction: true` |
| Final | The Copyist Answers | 승정원 마당, 해 뜨기 직전 | `evidence_talk` | Bae에게 질문하고, 그의 주장마다 수첩에서 맞는 증거를 제시한다. | h5, h6 (+ M1·M2·M3 증거) |

- 경험이 미션마다 다르다: 재구성(시간) → 문서 대조(읽기) → 현장 관찰(눈) → 대면(말과 증거).
- 비율: 읽기·추론 2(M2, Final) / 관찰·조작 2(M1, M3). 시즌 목표(60–70 : 30–40)는 시즌 전체에서 맞춘다.
- **이전 증거가 뒤에서 쓰인다**: Final은 M1·M2·M3의 증거 없이는 끝나지 않는다. `sora_practice`와 `scholars_sheet`는 시즌 Final의 "글자 모으기" 후보로 남긴다(§9).

### 4.1 M1 — The Night Book (`timeline_board`)
- 이야기(ROOKIE): "Autumn, 1446. The book of the new letters is finished. / At dawn, Clerk Mun-su opens the letter box. / The royal letter is gone. A strange page is in its place. / Guard Taek kept the gate book last night."
- 카드:

| id | 카드 | 고정(anchor) |
|---|---|---|
| `lock` | Mun-su locks the letter box. | **Sunset** |
| `home` | Mun-su goes home. | |
| `cups` | Sora comes in for the tea cups. | |
| `brush` | Bae comes back for his brush. | |
| `dawn` | Mun-su opens the box. The letter is gone. | **Dawn** |
| `lunch` | Mun-su eats lunch with the clerks. | (제외: 밤의 일이 아님) |

- 관계(장부 문장 = relation `line`):
  - lock → home: "Then he went home."
  - home → cups: "Later, Sora came in for the tea cups."
  - cups → brush: "After Sora left, Bae came back for his brush."
- 정답 순서: `lock, home, cups, brush, dawn`
- Discovery: "Two people came in after the box was locked: Sora and Bae." → 증거 `gate_book`

### 4.2 M2 — Two Papers (`record_mismatch`)
- 이야기: "Mun-su shows you the strange page. He also has the scholars' sheet about the new letters. The strange page is a copy of the King's words. Compare the two papers. Which line does not match?"
- 두 기록(같은 6행, label : value):

| 행 | 학자들의 쪽지 (`first`) | 가짜 종이 (`second`) |
|---|---|---|
| `count` | Letters : 28 | Letters : 28 |
| `sounds` | Five main sound letters : copy the tongue, mouth, teeth and throat | (같음) |
| `dot` | The dot : the round sky | (같음) |
| `flat` | The flat line : the flat earth | (같음) |
| `stand` | The standing line : a person standing | (같음) |
| `why` | **Why : so all people can learn them easily and use them every day** | **Why : only for scholars, not for common people** |

- 선택하지 않은 "How long" 줄(아침나절/열흘)은 쪽지 하단 메모(`noteRow`)로 둔다. 비교 대상이 아니므로 다른 줄이 2쌍이 되는 일을 막는다.
- 정답: `why:why`
- Discovery: "Someone changed the King's words. Who wanted common people to stop learning?" → 증거 `scholars_sheet`, `false_page`

### 4.3 M3 — Ink in the Copy Room (`trace_deduction`)
- 이야기: "Two people came in after the box was locked: Sora and Bae. Sora had a paper in her sleeve. Bae says he only took his brush."
- Mun-su의 메모(흔적 line은 이 편지의 줄과 글자 그대로 같아야 함):
  - "There is fresh black ink on the floor."
  - "A long brush hair lies by the wall."
  - "A torn corner of thick paper is under the table."
- 장소(옵션):
  - `brush_box`(Bae의 붓함) = **정답**
  - `tea_tray`(Sora의 찻쟁반)
  - `paper_chest`(종이 궤)
- Discovery(반전 1): 붓함에서 진짜 글이 나온다. 모서리가 찢겨 있다. Sora가 자기 종이를 보여 준다. 그것은 연습지다 → 증거 `royal_letter`, `torn_corner`, `sora_practice`

### 4.4 Final — The Copyist Answers (`evidence_talk`)
- 시작 대사(Bae): "I am a copyist. I only came back for my brush."
- 질문(먼저 듣기): "What do you do all day?" → "I write letters for people who cannot write. They pay me."
- 제시 단계:

| id | Bae의 주장 (prompt) | 받는 증거 (`accepted`) | 성공 대사 |
|---|---|---|---|
| `after_dark` | "I never touched the box after sunset." | `gate_book` | "…Nobody came in after me. Yes." |
| `kings_words` | "The page in the box shows the King's own words." | `scholars_sheet` | "All people… easily… every day. I changed that line." |
| `cannot_learn` | "Common people can never learn letters. Look at the maid!" | `sora_practice` | Sora: "Ten days. Just like the book says." |

- `finishWhen`: 세 단계 모두
- 끝 대사(반전 2): "You wrote the false page in the new letters, Bae. So you learned them too." / Bae: "…Seven days."
- 정답: 대화 완료(`examine`). 오답은 실패로 처리하지 않고 `miss` 대사만 나온다(엔진 규칙).

---

## 5. 퍼즐 및 정답 근거 (dossier `puzzles[]` 초안)

| 미션 | factIds / fiction | 단서(게임 안 위치) | 도출 과정 (`derivation`) | 유일성 (`whyOnly` / `whyNot`) |
|---|---|---|---|---|
| M1 | `fiction: true` | 장부 3문장(M1 편지) | 고정 카드 Sunset·Dawn 사이에서 "Then" → "Later" → "After Sora left"를 따라가면 home → cups → brush 순서가 된다. lunch는 밤의 일이 아니다. | 관계 3개가 사슬을 이루어 순서가 하나뿐이다(`TimelineRules`가 모호성을 검사함). |
| M2 | h1, h3, h4, h5, h6 | 쪽지 6행(M2 편지 = 화면 기록) | 두 종이의 같은 label 행을 비교하면 `why` 행만 값이 다르다. 쪽지의 목적 문장은 왕의 서문(h5)이다. | `whyOnly`: 나머지 5행은 글자까지 같다(`records_ambiguous` 자동 검사). 외부 지식이 필요 없다: 틀린 쪽을 고르는 것이 아니라 **다른 줄을 찾는** 퍼즐이다. 어느 쪽이 진짜인지는 이야기(쪽지 = 학자들의 것)가 알려 준다. |
| M3 | `fiction: true` | 메모 3줄 + 그림 속 흔적 | 잉크·붓털·찢긴 두꺼운 종이가 함께 있는 곳은 붓함뿐이다. | `whyNot`: 찻쟁반에는 잉크가 없고 차 얼룩뿐이다. 종이 궤에는 종이가 있지만 붓털과 생 잉크가 없다. |
| Final | h5, h6 | `scholars_sheet`(M2), `sora_practice`(M3), `gate_book`(M1) | 각 주장을 반박하는 증거가 하나씩 있다. | `whyOnly`(단계별): `after_dark`는 시간 증거인 장부만, `kings_words`는 원문이 적힌 쪽지만, `cannot_learn`은 실제로 배운 사람의 연습지만 답이 된다. `false_page`는 어느 단계의 답도 아니다(Bae의 주장을 되풀이할 뿐). |

**자동 검사가 보는 연도:** 게임 글에 나오는 4자리 연도는 1446(M1 이야기)과 1443(reveal)뿐이다. 둘 다 h1/h2에 있다. → `history_year_unsupported` 없음(예상).

**역사 지식 없이 풀리는가:**
- M2의 정답은 "다른 줄 찾기"이고, 진짜 문장은 화면에 있다.
- Final의 "ten days"도 쪽지 하단 메모와 Sora의 연습지 양쪽에 있다.
- 연도·인물을 외워야 하는 퍼즐은 없다.

**오답이 역사를 왜곡하지 않는가:**
- 가짜 종이의 "only for scholars" 줄은 **범인이 꾸민 거짓으로 명시**되고, 정답 처리 후 바로 바로잡힌다(Discovery 대사).
- 다른 오답 카드(lunch, 찻쟁반, 종이 궤)는 역사 내용이 아니다.
- 승인 체크리스트 7번 항목으로 사람이 확인한다.

---

## 6. 난이도별 영어 예시

규칙: 정답·이름·숫자·연도는 세 레벨이 같다. 영어 표현만 다르다(`case_levels.dart`). 6단어 이상 문장은 ROOKIE를 그대로 복사하지 않는다.

### 6.1 도입 (M1 이야기 첫 줄)
| ROOKIE | JUNIOR | MASTER |
|---|---|---|
| Autumn, 1446. The book of the new letters is finished. | It is autumn in 1446, and the book explaining the new letters is complete. | Autumn, 1446: the palace scholars have just completed their book on the new letters. |

### 6.2 M1 장부 문장 (관계)
| ROOKIE | JUNIOR | MASTER |
|---|---|---|
| Later, Sora came in for the tea cups. | Some time later, Sora entered to collect the tea cups. | Some while afterwards, Sora slipped in to clear away the tea cups. |
| After Sora left, Bae came back for his brush. | Once Sora had gone, Bae returned for his brush. | No sooner had Sora left than Bae reappeared, claiming he needed his brush. |

M1 주의: 관계를 표현하는 말(later / after / once)이 레벨마다 달라진다. 순서는 문장 의미로 정해지고, `TimelineRules`는 relation 데이터로 검사하므로 정답은 그대로다.

### 6.3 M2 다른 줄
| | ROOKIE | JUNIOR | MASTER |
|---|---|---|---|
| 쪽지 | so all people can learn them easily and use them every day | so that everyone can learn them with ease and use them daily | so that every person may master them easily and use them each day |
| 가짜 | only for scholars, not for common people | meant only for scholars, never for ordinary people | reserved for scholars alone, not for the common folk |
| 같은 줄 예 | The flat line : the flat earth | The flat line : the level ground of the earth | The flat line : modelled on the flat earth |

### 6.4 History Reveal (Case Closed)
| | ROOKIE | JUNIOR | MASTER |
|---|---|---|---|
| REAL HISTORY (h1) | King Sejong made 28 new letters in 1443. | In 1443, King Sejong created a set of 28 new letters. | In 1443, King Sejong devised an entirely new script of 28 letters. |
| REAL HISTORY (h2, h4) | A book about them was finished in 1446. It says the dot is the sky, the flat line is the earth, and the standing line is a person. | The book explaining them was completed in 1446. It describes the dot as the sky, the flat line as the earth and the standing line as a person. | Completed in 1446, the book explaining them likens the dot to the round sky, the flat line to the earth and the standing line to a person. |
| REAL HISTORY (h5) | The King wanted all people to learn them easily. | The King wanted everyone to be able to learn them easily. | The King's stated aim was that everyone could learn them with ease. |
| IN THIS MYSTERY | Mun-su, Sora, Bae and Taek are made up. The royal letter and the stolen night are made up too. | Mun-su, Sora, Bae and Taek were invented for this case, as were the royal letter and that night. | Mun-su, Sora, Bae and Taek are fictional, and so are the royal letter and the night it vanished. |

(h9를 넣을 경우 ROOKIE: "In 1444, some scholars wrote to the King against the new letters. Their reasons were not Bae's reasons.")

---

## 7. 자동 선택기 검토 결과

### 7.1 실행 방법
- 서울 시즌 폴더를 만들지 않았다. 대신 위 ROOKIE 글(story + letter + question)을 스크래치 스크립트에 넣었다.
- 스크립트는 실제 `PuzzleSelector.traitsOf`, `byTrait`, `PlayCheck.generatable`, `PaletteFacts`(화면 지원)를 import하고, `select()`와 같은 점수식을 적용했다(순위 10/7/4, `text_choice` −2, Case 내 중복 −8).
- 시즌 1/3 상한과 앞 Case 같은 자리 감점은 Case가 하나뿐이라 적용되지 않는다.
- 저장소 파일은 바꾸지 않았다.

### 7.2 결과

| 미션 | 감지된 성격 (단서 단어) | 후보 (점수) | 선택기 | 기획 | 일치 |
|---|---|---|---|---|---|
| M1 | chronology (1446, after, later, then) | timeline_board 10, order_sequence 7 | `timeline_board` | `timeline_board` | ✅ |
| M2 | documents (copy, does not match) | record_mismatch 10, text_choice 5 | `record_mismatch` | `record_mismatch` | ✅ |
| M3 | scene (hidden, marks) | trace_deduction 10, dark_room_search 7, scene_explore_choose 4 | `trace_deduction` | `trace_deduction` | ✅ |
| Final | testimony (claim, claims, said, says) | evidence_talk 10 (`witness_compare`는 Final 불가로 제외) | `evidence_talk` | `evidence_talk` | ✅ |

사실 문장(dossier)만으로 생긴 성격(`factsOnly`)은 없었다. 즉 플레이어가 읽지 않은 역사로 퍼즐을 고르지 않았다.

### 7.3 기획자 판단과 차이 · 주의점
1. **결과가 단어에 민감하다.**
   - M3 메모를 처음에 "I **saw** fresh ink"로 쓰면 says + saw로 testimony가 함께 잡힌다. 그러면 `witness_compare` 10점이 `trace_deduction`과 동점이 되어, 결과가 팔레트 순서로 정해진다.
   - 최종 글에서는 "There is …"로 썼다. 레벨 작성 때도 이 단어를 피하도록 메모한다.
2. **M2의 "copy"는 우연한 단서다.** "The strange page is a copy of the King's words"가 없으면 documents 단서가 1개("does not match")뿐이라 선택이 `null`이 된다. 문장은 이야기상 필요하므로 유지하지만, 선택기가 의미를 이해한다고 보지는 않는다.
3. **선택기가 고르지 않는 좋은 대안(기획자 메모):**
   - `number_entry`로 "28"을 묻는 미션은 고려했지만 넣지 않았다. 28은 쪽지에 그대로 적혀 있어 **읽고 옮겨 적기**가 되고, 추론이 아니다. 단순 암기·옮기기 금지 원칙에 해당한다.
   - `lens_inspect_word`: M3 대안으로 고려했다. 하지만 라벨 단어 입력에 역사가 들어가지 않고, 흔적 추리가 Sora/Bae 의심 구도에 더 맞아 `trace_deduction`을 택했다.
4. **엔진 다양성:** 4개 미션이 모두 다른 엔진이다. 기존 London·Paris·Rome·NY Case 01과 겹치는 엔진 구성은 없다(NY 01: witness/text/explore/order).

---

## 8. 역사 승인에 필요한 항목

### 8.1 사람이 할 일 (순서대로, 모두 터미널에서 직접)
1. 시즌 폴더를 만들지 결정한다. 만든다면 `plan_season.dart init --season 5 --city Seoul --mode historical_fiction_mystery`. **이번 작업에서는 실행하지 않았다.**
2. §1.1의 h1–h8을 dossier에 `draft`로 옮긴 뒤 각 출처 URL을 **직접 열어** 인용문을 확인하고 `source_checked`로 바꾼다.
   - 이번 조사의 인용 일부(국립한글박물관, 우리역사넷, 백과)는 검색 도구의 본문 추출로 읽었다.
   - 사람이 원문 페이지에서 한 번 더 확인할 것.
3. `dart run tool/season_gen/approve.dart approve content_pipeline/seasons/s5_seoul fact s5_ep01_h<n>` × 8
4. 퍼즐 4개 검토: `… approve … puzzle s5_ep01_m1|m2|m3|final` (레벨 파일 작성 후, 7개 체크리스트)
5. reveal 승인: `… approve … reveal s5_ep01`

### 8.2 승인 시 특히 판단할 것
| # | 질문 | 기획자 권장 |
|---|---|---|
| A1 | "royal letter"를 일꾼들에게 읽어 준다는 **창작 행사**에 실제 왕의 서문 문장(h5)을 넣어도 되는가? | 된다. 문장은 사실 그대로 쓰고, 행사는 IN THIS MYSTERY에 명시한다. 거북하면 "a notice from the Royal Secretariat"로 바꿀 수 있다. |
| A2 | h6의 "어리석은 사람"을 "a slow person"으로 순화해도 되는가? | 된다(아동 대상). reveal에서 직접 인용하지 않는다. |
| A3 | h9(1444년 반대 상소)를 reveal에 넣을까? | **넣지 않기를 권장한다.** 상소의 진의에 대한 해석이 갈리고, Bae의 동기와 겹쳐 보여 실존 인물을 악역처럼 읽히게 할 위험이 있다. |
| A4 | 무대를 "경복궁"으로 특정할까? | 하지 않기를 권장한다(§1.2, 출처 1개). |
| A5 | 승정원에서 글을 밤새 보관하는 설정 | 창작으로 명시. 실제 문서 보관 절차는 확인하지 않았다. |

### 8.3 이미지 고증 검토 항목 (생성 전, 리뷰 시)
- 조선 초기(15세기) 관복·궁녀 복식, 관청 실내, 붓·벼루·종이 궤
- 후기(18–19세기) 양식이 섞이지 않을 것
- 그림 속 글자 금지: 종이·장부·쪽지는 **빈 종이**로 그리고, 글은 앱이 쓴다

---

## 9. 구현 가능 여부와 남은 위험

### 9.1 구현 가능 여부: **가능** (조건부)
- 4개 엔진 모두 STEP 1 기준 생성·검증·플레이가 가능하다(샌드박스 `s8_ep02`에서 `record_mismatch`·`trace_deduction`·`evidence_talk`, `s8_ep01`에서 `timeline_board` 검증됨).
- 역사 dossier → fact/puzzle/reveal 승인 → 게이트 경로가 갖춰져 있다.
- 한글 자모를 그리지 않으므로 폰트 작업이 필요 없다.

### 9.2 필요한 그림 (예산 판단용, 생성하지 않음)
| 그림 | 쓰임 | 측정 |
|---|---|---|
| 승정원 방, 새벽 (장소) | M1/M2 배경 | — |
| 빈 쪽지 종이 2장 (학자 쪽지, 가짜 종이) — 같은 종이 1장을 두 번 써도 됨 | M2 `records` | 네 모서리·행 위치 |
| 필사실 (붓함·찻쟁반·종이 궤, 흔적 3곳) | M3 `traces` | 흔적·장소 영역 |
| 승정원 마당, 새벽 | Final 배경 | — |
| 초상화: Bae (필수), Mun-su·Sora·Taek (대화용, 선택) | Final·대화 | — |
| 시즌 공통: 표지·지도·월드시티(서울은 이미 그려진 도시) | 시즌 | — |

### 9.3 남은 위험
1. **이야기 틀 결정이 시즌 전체로 번진다.**
   - PART 0의 12 Case 후보는 안 A(현재 전시) 기준이다. Case 12(1940 해례본 발견), 근대 Case(1884–1899) 등은 안 B에서 시대가 크게 바뀐다(일제강점기 등 민감도 상승).
   - 시즌 전체를 B로 갈지, Case마다 시대를 옮길지 결정이 필요하다.
2. **주인공 미정.** Rome·NY에는 시즌 주인공이 있다. 1446년 궁궐 조사관을 어떤 인물로 둘지(가상 인물, 그림 필요) 정해야 한다.
3. **선택기 단어 민감도**(§7.3). 레벨 문장(JUNIOR/MASTER)을 쓴 뒤 선택 결과가 바뀔 수 있다. 바뀌면 보고만 되고 계획은 그대로다.
4. **`record_mismatch`의 6행이 작은 화면에 들어가는가.** 320×568에서 레이아웃 검사(`PlayCheck` "종이 밖 레이아웃")와 실기기 확인이 필요하다. 넘치면 `sounds` 행을 빼고 5행으로 줄인다(사실 h3은 reveal로만 남김).
5. **고증 이미지 리젝트 비용.** AI 이미지는 15세기 복식·건축 고증이 약하다. 리젝트를 예산에 반영해야 한다.
6. **역사 내용을 아이에게 잘못 전할 위험.**
   - 가짜 종이의 "only for scholars"가 사실처럼 기억될 수 있다. Discovery와 Final에서 두 번 바로잡도록 설계했다.
   - 그래도 리뷰에서 문장 강도를 확인할 것.
7. **사용하지 않은 확인 사항:** 승정원·궁궐의 실제 공간 배치, 15세기 궁녀의 업무, 필사관이라는 직업의 실제 존재 형태. 모두 창작으로 처리했다. 사실처럼 묘사하는 문장이 생기지 않게 레벨 작성 때 확인해야 한다.

### 9.4 다음 단계 (사용자 승인 후에만)
1. §8.2 A1–A5와 §9.3-1·2(이야기 틀, 주인공) 결정
2. 시즌 폴더 생성(`init --mode`) → dossier h1–h8 기입 → 사용자 fact 승인
3. Case 01 `case.plan.json` 작성 → `plan_season check`로 실제 `puzzle_selection.json` 생성(이번 §7 결과와 대조)
4. 이미지 예산 지정 후 팩토리 실행

---

## 부록: 이번 조사에서 연 출처
- 『세종실록』 세종 25년 12월 30일 https://sillok.history.go.kr/id/kda_12512030_002
- 『세종실록』 세종 28년 9월 29일 https://sillok.history.go.kr/id/kda_12809029_004
- 『세종실록』 세종 26년 2월 20일 https://sillok.history.go.kr/id/kda_12602020_001
- 한국민족문화대백과: 훈민정음 E0065805, 훈민정음28자모 E0074518, 제자해 E0078676, 초출자 E0078696, 한글 E0061508, 승정원 E0032242, 집현전 E0055081, 세종 E0029857, 최만리 E0057279
- 우리역사넷: 한글의 구성 원리 hm_091_0030, 훈민정음 해례본 ts_b32, 집현전 kc_o301300
- 승정원일기 소개 https://sjw.history.go.kr/intro/intro.do
- UNESCO Memory of the World — Hunminjeongum Manuscript
- 한국의 세계기록유산(kmowkc) 훈민정음 해례본
- 국립한글박물관 상설전시, 웹진 2020-10
- 참고만(출처로 쓰지 않음): 국립국어원 korean.go.kr 「알고 싶은 한글」, atlas.mkhz.kr, 충북교육문화원, 한국문화신문 기사
