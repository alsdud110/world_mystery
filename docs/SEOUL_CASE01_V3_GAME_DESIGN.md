# Seoul Case 01 V3 — The King's Secret Letters (게임 디자인)

작성 2026-11-07. 상태: **기획 + 이미지 완료, 게임 코드 미적용**(사용자 승인 후 별도 PART).
기존 Case 01(훈·음·정·민 네 묶음, `0fba989`·`5c870fd`)은 이 문서가 승인되면 대체된다. 그 전까지 게임은 기존 Case 01 그대로다.

목차: 1 사건 · 2 화면별 대본 · 3 퍼즐 문제지(M1·M2·M3·Final) · 4 난이도 · 5 역사 검증 · 6 이미지 · 7 Flutter 변경 · 8 다른 Case 연결 · 9 플레이 시뮬레이션 · 10 작업량 · 11 승인 필요 사항

---

## 1. 사건 전체

### 1.1 한 줄
글을 모르는 소녀 분이가 아픈 어머니를 위해 궁궐에 가져온 편지가 **잘못 쓰여 있다**. 탐정은 그 실수를 밝히고, 소라에게서 새 글자의 원리를 배워, 분이가 처음으로 자기 말을 직접 쓰게 돕는다. 마지막에 세종은 그 글자의 이름을 보여 주고, 탐정은 사건의 증거로 그 이름의 뜻을 풀어낸다: **훈민정음(訓民正音), 백성을 가르치는 바른 소리.**

### 1.2 사건의 줄기 (각 미션이 다음 미션을 부르는 이유)

| 순서 | 사건 | 다음으로 넘어가는 이유 |
|---|---|---|
| Intro | 저녁, 궁궐 옆문. 물 긷는 소녀 분이가 편지를 들고 "어머니가 아파요. 도와주세요"라고 한다. 소라(궁녀)가 편지를 받는다 | 분이는 편지에 무엇이 쓰였는지 모른다 |
| M1 | 편지는 한자 다섯 자. 장터 대서인(代書人)이 함께 접어 준 **그림 낱말표**로 글자를 풀면 편지는 "약"이 아니라 **"쌀"**을 청한다. 탐정이 잘못된 글자를 찾아 고친다 | 분이는 자기 편지를 읽지도, 고치지도 못했다. 직접 쓸 수 있다면 이런 일은 없었다 → 소라: "임금님이 만드신 새 글자가 있어요" |
| M2 | 소라의 소리판: 입술·혀·목구멍 그림과 새 글자 ㅁ·ㄴ·ㅇ의 모양을 견주어, 글자가 소리 내는 입의 모양을 본떴음을 알아낸다 | 분이: "그럼 제 말도 쓸 수 있어요? '엄마'를 쓰고 싶어요!" |
| M3 | 모음 ㅏ·ㅓ(점 + 선)를 배우고, 첫소리·모음·끝소리를 맞춰 **엄마**를 조립한다. 분이가 처음으로 자기 말을 쓴다 | 소식을 들은 임금이 분이와 탐정을 서재로 부른다 |
| Final | 세종의 세 질문에 세 증거로 답한다. 이어 세종이 보여 준 이름 訓民正音의 네 글자 뜻을 **사건의 증거와 임금의 그림 쪽지**로 풀고, 분이가 마지막 묶음 **음**을 직접 쓴다 | 사건 해결 |
| Ending | 새벽, 약을 받은 어머니 곁에서 분이가 자기 종이를 보여 준다: 엄마, 그리고 훈민정음 | CASE SOLVED — 훈민정음 |

### 1.3 인물

| 인물 | 실존/창작 | 역할 | 초상 |
|---|---|---|---|
| 세종 | 실존. 단, **이 사건에서 하는 말과 행동은 모두 창작** | Final 질문, 이름 공개 | 기존 `characters/sejong.webp` |
| 분이 | 창작. 궁궐 부엌에 물을 대는 소녀 (기존 시즌 설정 유지: C02·C08·C12가 그를 "물 긷던 분이"로 부른다) | 의뢰인, 처음 글을 쓰는 사람 | 기존 `bun_i.webp` |
| 소라 | 창작. 새 글자를 먼저 익힌 젊은 궁녀 | 선생님 | 기존 `sora.webp` |
| 장터 대서인 | 창작. 화면에 나오지 않음(그림 낱말표만) | 실수한 사람(악인이 아님) | 없음 |
| 분이 어머니 | 창작 | 엔딩 | 엔딩 그림 속에만 |

**연도(승인 필요, §11-1):** 요청은 1443년이다. 그러나 이미 구현된 C02·C08·C12가 분이의 쪽지를 "1446년"이라 부른다. 이 문서의 대사는 **연도를 한 줄(Intro 카드)에만** 둔다. 권장안은 **1446년 여름**(글자는 1443년 12월에 만들어졌고, 풀이한 책은 1446년 9월에 완성: 세종이 "책을 마무리하는" 시기)으로, 다른 Case를 고치지 않아도 된다.

---

## 2. 화면별 대본 (ROOKIE 기준 실제 영어)

표기: `[화면]` 구성, `NAR` 서술, `BUN-I`/`SORA`/`KING`/`YOU` 대사. 대괄호 속은 UI 동작.

### Intro — The King's Secret Letters
- `[화면]` 이미지 `intro_side_gate`(옆문, 분이와 소라). 카드: `HANYANG, JOSEON · SUMMER 1446`(§11-1이 1443이면 `WINTER 1443`).
- NAR: The King has made new letters. Very few people know them yet.
- NAR: At a side gate of the palace, a girl holds up a letter.
- BUN-I: My mother is sick. I need help.
- BUN-I: A scribe at the market wrote this for me. I gave him all my coins.
- SORA: What does it say?
- BUN-I: I don't know. I can't read it.
- SORA: Then let's find out together, Detective.
- `[버튼]` START THE CASE

---

## 3. 퍼즐 문제지

### 3.1 Mission 1 — The Letter Nobody Could Read

**목표:** 편지가 분이의 말과 다르다는 것을 증거로 밝히고, 왜 그런 일이 생겼는지 이해한다.

**화면 구성**
1. 대화(배경 `intro_side_gate`): 분이의 진술을 듣는다 → 노트에 **Bun-i's Story** 초안(1줄)이 적힌다.
2. 책상 화면: 위에 편지(`m1_letter`, 한자 5자는 Flutter가 종이 위에 그림), 아래에 대서인의 그림 낱말표(`m1_scribe_chart`, 8칸 그림, 각 칸 아래 빈 띠에 한자를 Flutter가 씀).
3. 세 단계: ① 글자 풀기 → ② 틀린 낱말 찾기 → ③ 바로잡기.

**화면에 보이는 단서(전부)**
- 분이의 말(노트에 고정): "My mother is sick. She needs **medicine**. Please help us."
- 편지 5자, 위에서 아래가 아니라 **왼쪽에서 오른쪽**으로 한 줄(게임 단순화, §5.4): `民 母 病 求 米` + 왼쪽 아래 물방울 자국(분이의 표시: 이름 대신 찍음).
- 낱말표 8칸(그림 → 띠의 한자): 어머니 → 母 · 아파 누운 사람 → 病 · 내민 두 손 → 求 · 쌀 한 그릇 → 米 / 약 한 사발과 약초 → 藥 · 물통 → 水 · 마을 사람들 → 民 · 소나무 → 松
- 소라의 안내(ROOKIE): "The scribe gave you a picture chart. The same marks are on the letter."

**조작**
- ① 편지의 한 글자를 탭 → 낱말표에서 **모양이 같은** 칸을 탭. 맞으면 그 글자 아래에 그림의 영어 낱말이 붙는다(PEOPLE, MOTHER, SICK, PLEASE, RICE). 다섯 자 모두.
- ② 풀린 편지 "PEOPLE · MOTHER · SICK · PLEASE · RICE"와 분이의 말을 비교해 **맞지 않는 낱말**을 탭.
- ③ 낱말표에서 그 자리에 들어가야 할 글자 칸을 탭 → 편지 위 米가 藥으로 바뀐다.

**정답과 근거**

| 단계 | 정답 | 근거(화면에 있는 것만) |
|---|---|---|
| ① | 民→사람들, 母→어머니, 病→아픈 사람, 求→내민 손, 米→쌀 | 글자 모양이 낱말표 띠의 글자와 같다. 한자를 읽을 필요 없음 |
| ② | RICE | 분이는 medicine이 필요하다고 했다. 나머지(people, mother, sick, please)는 분이의 말과 맞는다 |
| ③ | 藥(약 그림 칸) | 분이가 원한 것은 medicine. 낱말표에서 약 그림 아래 글자 |

**오답 반응**

| 상황 | 반응(ROOKIE) |
|---|---|
| ① 모양이 다른 칸 | SORA: Look again. Are the two marks the same shape? (흔들림, 감점 없음) |
| ① 米를 水에(가장 비슷한 쌍) | SORA: Close! Count the little lines. They are not the same. |
| ② MOTHER/SICK/PEOPLE/PLEASE | BUN-I: Yes, that part is right. (그 낱말에 ✓) |
| ③ 米·水·松 등 | SORA: Would that help Bun-i's mother? Read Bun-i's words again. |

**힌트**
- HINT 1: Find each mark on the chart. The picture tells you its word.
- HINT 2: Bun-i asked for medicine. Which word on the letter is not medicine?

**성공**
- 편지의 米가 지워지고 藥이 써지는 연출(먹이 번짐 0.6초). SORA: Now the letter says what Bun-i wanted.
- BUN-I: The scribe got it wrong… and I could not even check it.
- SORA: Because you could not read it. And you could not write it yourself.
- BUN-I: If I could write, I could say it in my own words!
- SORA: The King has made new letters for that. Come, I will show you.

**획득:** 증거 `e1` **Bun-i's Story** — "Bun-i asked for medicine, but the scribe wrote 'rice'. She could not read or write, so she could not check it." / 단서 `c1` **Bun-i's Mark**(물방울 표시, C02가 이 id를 쓴다).

**다음 미션 이유:** 문제는 대서인이 아니라 "직접 쓰지 못하는 것"이다.

### 3.2 Mission 2 — The Secret of Sounds

**목표:** 새 글자가 소리 낼 때 입의 모양을 본떴음을 관찰로 알아낸다(제자해, §5.2).

**화면 구성**
1. 소라의 소리판: 그림 세 장(`m2_mouth_lips`, `m2_mouth_tongue`, `m2_mouth_throat`, 이름표 없음) + 글자 타일 세 개 ㅁ · ㄴ · ㅇ.
2. 각 그림을 탭하면 소라가 그 소리를 내 보라고 한다(선택 음성 §7.4). 그림 위 빨간 윤곽선이 한 번 반짝인다.

**대사**
- SORA: The King's new letters are not just marks. Each one is a picture.
- SORA: A picture of what? Of your mouth, when you make a sound!
- SORA: Try it. Say "mmm". Now say "nnn". Now open wide: "ahh".
- (그림 탭) lips: Say "mmm". Your lips close. / tongue: Say "nnn". Where does the tip of your tongue go? / throat: Say "ahh". Look deep inside. What shape is there?

**조작:** 글자 타일을 탭 → 그림을 탭(끌어 놓기 가능). 세 쌍.

**정답과 근거**

| 글자 | 그림 | 근거(화면) | 맞힌 뒤 설명(SORA) |
|---|---|---|---|
| ㅁ | 입술(정면, 닫힌 입이 둥근 네모) | ㅁ은 네모. 입 전체가 네모 모양으로 칠해져 있다 | "ㅁ is a box, like your mouth. Say 'mmm': the sound comes from your closed lips." |
| ㄴ | 혀(옆모습, 혀끝이 윗잇몸에 닿아 꺾임) | 빨간 혀 윤곽이 └ 모양. ㄴ과 같은 꺾임 | "ㄴ copies your tongue: flat, then the tip goes up to touch behind your top teeth. 'nnn'!" |
| ㅇ | 목구멍(옆모습, 둥근 구멍) | 빨간 동그라미 | "ㅇ copies your throat: a round, open hole." |

맞히면 Flutter가 그림의 빨간 윤곽을 따라 선을 그린 뒤 그 선이 글자 모양으로 모이는 0.8초 애니메이션(예: 혀 윤곽 → ㄴ). **그림에는 글자가 없고, 글자는 모두 Flutter가 그린다.**

**3단계(적용, 2지선다 아님):** BUN-I: Which letter starts "ma", like "mama"? 타일 ㅁ ㄴ ㅇ 중 선택 → ㅁ. 근거: "ma"를 말하면 입술이 먼저 닫힌다(그림 1).

**오답 반응**
- ㅁ→혀: SORA: ㅁ is a box with four sides. Is the tongue a box?
- ㄴ→목구멍: SORA: Look for the corner. Which picture bends like ㄴ?
- ㅇ→입술: SORA: ㅇ is round and open. Are your lips open when you say "mmm"?
- 3단계 ㄴ/ㅇ: BUN-I: "ma"… my lips close first! Which picture closes the lips?

**힌트**
- HINT 1: Look at the red line in each picture. Find the letter with the same shape.
- HINT 2: The tongue makes a corner, like ㄴ. The throat is round, like ㅇ.

**성공**
- SORA: You found it! The letters copy the mouth. That is why they are easy to learn.
- SORA: There are two more: ㄱ, the back of the tongue, and ㅅ, the teeth. And a stronger sound adds one line: ㄴ, then ㄷ. (소리판 전체가 한 장으로 보임 — C02·C04가 쓰는 규칙)
- BUN-I: Then can I write my own words? I want to write "Mom"!

**획득:** 증거 `e2` **Sora's Sound Board** — "The first letters copy the mouth: ㅁ the lips, ㄴ the tongue, ㅇ the throat, ㄱ the back of the tongue, ㅅ the teeth. A stronger sound adds a line. On top Sora wrote 音: sound." (이름 변경 §8: C02·C04는 id `e2`로 참조하므로 문구만 확인)

**다음 미션 이유:** 분이가 자기 말("엄마")을 쓰고 싶어 한다.

### 3.3 Mission 3 — Bun-i's First Word

**목표:** 모음 ㅏ·ㅓ와 묶음 규칙을 배우고 **엄마**를 직접 조립한다.

**배우기(퍼즐 전, 조작 포함)** — 배경 `m3_writing_desk`
- SORA: Letters for vowels are made from three shapes. A dot is the sky. A flat line is the earth. A standing line is a person.
- SORA: Put the sky dot on the RIGHT of the person. (플레이어가 점을 오른쪽에 탭 → ㅏ) That is ㅏ. It says "ah".
- SORA: Now put it on the LEFT. (왼쪽 탭 → ㅓ) That is ㅓ. It says "uh", like in "up".
- SORA: One written sound is a block. It has a FIRST SOUND, then a VOWEL beside it. Some blocks have a LAST SOUND. It sits under the other two, like a floor.
- SORA: If a block starts with a vowel sound, ㅇ goes first. It is the open throat: it holds the place.
- 화면 하단에 작은 "배운 것" 카드가 고정: ㅏ = ah · ㅓ = uh · ㅇ first = starts with a vowel · LAST SOUND = under the block.

**퍼즐 화면**
- BUN-I: I want to write my word for Mom: "UM-MA". (🔊 선택 음성 "엄마", 두 번 손뼉 그림 = 두 블록)
- 블록 두 개가 왼쪽→오른쪽. 각 블록 틀: 왼쪽 위 칸 **FIRST SOUND**, 오른쪽 칸 **VOWEL**, 아래 넓은 칸 **LAST SOUND**(선택). 칸 이름은 영어로 칸 안에 작게. **TOP/BOTTOM 표현 없음.**
- 타일: FIRST/LAST용 ㅇ ㅁ ㄴ · VOWEL용 ㅏ ㅓ · LAST SOUND용 "none".
- 조작: 칸 탭 → 타일 탭. 모두 채우면 READ IT. 정답이면 두 블록이 합쳐져 엄마가 된다.
- 블록이 채워지는 동안 블록 아래에 **지금 블록이 내는 소리**를 영어로 바로 보여 준다(예: ㅇ+ㅓ → "uh", +ㅁ → "um"). 정답을 따라 누르는 게임이 아니라, 자기 조합이 무슨 소리인지 들으며 고치게 한다.

**정답과 근거**

| 블록 | FIRST | VOWEL | LAST | 근거 |
|---|---|---|---|---|
| 1 "um" | ㅇ | ㅓ | ㅁ | 모음으로 시작 → ㅇ. "uh" → 점이 왼쪽 ㅓ. 끝에서 입술이 닫힘 → ㅁ(M2) 끝소리 칸 |
| 2 "ma" | ㅁ | ㅏ | none | 입술로 시작 → ㅁ. "ah" → 점이 오른쪽 ㅏ. 열린 채 끝남 → 끝소리 없음 |

정답 문자열 `엄마`. 실제 한글 조합 규칙(첫소리 + 오른쪽 모음 + 아래 끝소리)과 일치(§5.3).

**오답 반응(조합별, 자동 소리 표시와 함께)**

| 조합 | 화면 소리 | BUN-I / SORA |
|---|---|---|
| 1에 ㅁ 첫소리 | "mum" | BUN-I: That says "mum". My word starts open: "um". |
| 1에 ㅏ | "am" | SORA: That says "am". Bun-i says "um". Which side is the dot on? |
| 1에 끝소리 없음 | "uh" | BUN-I: Listen: "um". At the end, my lips close. |
| 1에 끝소리 ㄴ | "un" | SORA: That ends with the tongue. "um" ends with the lips. |
| 2에 ㅓ | "muh" | BUN-I: That says "muh". I say "ma". |
| 2에 끝소리 ㅁ | "mam" | BUN-I: "ma" ends open. Nothing goes under it. |
| 1·2 순서 바뀜 | "ma-um" | BUN-I: Say it with me: UM… MA. |

**힌트**
- HINT 1: "um" ends with closed lips. Which letter is the lips? Where does a last sound go?
- HINT 2: ㅓ has the dot on the left ("uh"). ㅏ has it on the right ("ah").

**성공**
- 연출: 두 블록이 미끄러져 붙고, 분이의 붓이 종이에 **엄마**를 쓴다(획 순 애니메이션, 텍스트는 Flutter).
- BUN-I: I wrote it! My own word!
- SORA: You learned it in one night.
- NAR: A palace servant comes running. The King wants to see the girl who wrote her own word.

**획득:** 증거 `e3` **Bun-i's First Word** — "Bun-i's paper. She wrote 엄마 (Mom) by herself, with the new letters." (엔딩에서 같은 종이에 훈민정음이 더해진다 → C08의 "It says 훈민정음"과 맞음)

**다음 미션 이유:** 임금이 부른다.

### 3.4 Final — The King's Secret

배경 `final_kings_study`. 세 단계.

**1단계 — 세 질문 (증거 제시, 기존 `evidence_talk`)**

- NAR: The King's study. Books everywhere. The King holds a long scroll.
- KING: So you are the girl who wrote her own word.
- KING: Tell me, Detective. Show me what you found.

| 질문 (KING) | 제시 카드(3장 모두 제시 가능) | 정답 | 맞혔을 때 |
|---|---|---|---|
| A letter asked for rice, when she needed medicine. How did that happen? | e1 · e2 · e3 | **Bun-i's Story** | YOU: She could not read the letter. She could not check it. / KING: So my people cannot say what they mean in writing. |
| My scholars say ordinary people cannot learn letters. Are they right? | e1 · e2 · e3 | **Sora's Sound Board** | YOU: Your letters copy the mouth. They are easy to learn. / KING: Easy enough for anyone. |
| Then who are these letters for? | e1 · e2 · e3 | **Bun-i's First Word** | YOU: For people like Bun-i. She wrote her own word in one night. / KING: Yes. These letters are for people like Bun-i. |

오답 카드: KING: That is a good clue, but it does not answer my question. (2회 오답 후 `tell`: 정답 카드가 빛남, 감점 없음)

**2단계 — 이름의 뜻 (새 UI: M1과 같은 "모양 찾기")**

- KING: I have a name for my letters. Four characters. (두루마리에 訓 民 正 音, Flutter 글자)
- KING: You already know some of them. The rest, my pictures will tell you. (두루마리 옆에 임금의 그림 쪽지 두 장: **스승이 아이에게 글을 보여 주는 그림**, **곧게 늘어진 먹줄(목수의 다림줄)과 곧은 기둥 그림** — §6.3 추가 이미지 후보, 없으면 아래 대안)
- 조작: 두루마리 글자를 탭 → 증거 카드(e1의 낱말표, e2의 소리판) 또는 임금의 그림 쪽지에서 **같은 모양**을 찾아 탭 → 그 글자의 뜻을 영어 낱말 타일에서 고른다.
- 낱말 타일(6): TEACH · PEOPLE · RIGHT · SOUND · RICE · MOTHER

| 글자 | 찾는 곳 | 뜻 | 근거 |
|---|---|---|---|
| 民 | e1 대서인 낱말표의 "마을 사람들" 칸 | PEOPLE | M1에서 이미 풀었다 |
| 音 | e2 소리판 위 글자("On top Sora wrote 音: sound") | SOUND | M2 증거 |
| 訓 | 임금 쪽지 1: 스승이 아이를 가르치는 그림 | TEACH | 그림이 보여 주는 행동. 소라가 분이에게 한 일과 같다 |
| 正 | 임금 쪽지 2: 곧은 먹줄 그림 | RIGHT | 그림: 곧고 바른 것. M1에서 "편지를 바르게 고친" 일과 이어짐(대사로만) |

- 다 채우면 문장이 완성된다: "Letters to **TEACH** the **PEOPLE** the **RIGHT SOUNDS**." (한자 순서 그대로)
- 오답: RICE/MOTHER → KING: That is on Bun-i's letter, but not in my name. Look at the picture again. / 모양 불일치 → SORA: Are the two marks the same shape?
- 힌트: HINT 1: Two of the marks are in your notebook. Find the same shapes. / HINT 2: The picture of a teacher shows 訓. The straight line shows 正.

**3단계 — 분이가 쓰는 마지막 묶음 "음"**
- KING: In my new letters, the name is read: Hun-min-jeong-eum. (🔊 선택)
- BUN-I: The last one is "eum"… Sound! Can I write it?
- SORA: The flat line is the earth. A flat vowel sits UNDER the first sound, not beside it.
- 블록 하나(M3와 같은 판, VOWEL 칸이 아래로 옮겨짐): FIRST ㅇ · VOWEL ㅡ · LAST ㅁ. 타일 ㅇ ㅁ ㄴ / ㅡ ㅏ ㅓ / none.
- 정답 `음`. 근거: 모음 시작 → ㅇ, "eu"는 납작한 선 ㅡ, 입술로 끝남 → ㅁ. 오답: ㅓ → "um": "That says 'um', like Mom. The King says 'eum'." 끝소리 없음 → "eu": "Close your lips at the end."
- 힌트: HINT 1: "eum" starts open and ends with closed lips. / HINT 2: The vowel is the flat line ㅡ. It goes under ㅇ.

**클라이맥스 연출:** 음이 완성되면 두루마리의 訓民正音 아래로 한글 **훈민정음**이 한 글자씩 나타난다. KING: Hunminjeongeum. The right sounds to teach the people.

**획득:** 증거 `e4` **The Name of the Letters** — "訓民正音, Hunminjeongeum: the right sounds to teach the people."

### 3.5 Ending
- 이미지 `ending_dawn_home`(새벽, 약사발, 분이와 어머니).
- NAR: At dawn, Bun-i runs home with real medicine.
- NAR: She shows her mother a paper. On it, in the new letters: 엄마. Under it: 훈민정음.
- BUN-I: Dear Mother, I can write now!
- NAR: (KING, 회상 한 줄) "These letters are for people like Bun-i."
- 화면: **CASE SOLVED — 훈민정음**
- REAL HISTORY / IN THIS MYSTERY 카드(§5.6).
- 주의: 엔딩의 영어 편지는 오늘날 어린이를 위한 의역 연출이며, 15세기 편지의 재현이 아니다(IN THIS MYSTERY에 명시).

---

## 4. 난이도 (구조·정답 동일, 영어만 차등)

ROOKIE: 짧은 문장, 기본 어휘, 무료 힌트 2개, 오답 감점 없음(시즌 규칙과 같음). JUNIOR·MASTER: 문장·어휘만 길어지고 힌트 표현이 덜 직접적.

| 위치 | ROOKIE | JUNIOR | MASTER |
|---|---|---|---|
| Intro | My mother is sick. I need help. | My mother is ill, and I need help. | My mother has fallen ill. Please, I need help. |
| M1 지시 | Tap a mark on the letter. Then find the same mark on the chart. | Match each mark on the letter to the same mark on the scribe's chart. | Decode the letter: find each mark on the scribe's picture chart. |
| M1 ② | Which word is not what Bun-i asked for? | Which word does not match Bun-i's story? | One word contradicts Bun-i's account. Which one? |
| M1 HINT 2 | Bun-i asked for medicine. Which word is not medicine? | Compare the letter with what Bun-i needs. | Bun-i's mother needs a cure, not food. |
| M2 지시 | Match each letter to the mouth picture it copies. | Each letter copies a part of the mouth. Match them. | Each letter is drawn from the shape the mouth makes. Pair them. |
| M2 HINT 1 | Look at the red line. Find the same shape. | Compare the red outline with each letter. | Trace the red outline: which letter shares its shape? |
| M3 지시 | Build Bun-i's word: UM-MA. | Build the two blocks of Bun-i's word, UM-MA. | Assemble Bun-i's word, UM-MA, block by block. |
| M3 HINT 1 | "um" ends with closed lips. Where does a last sound go? | The block "um" ends with the lips. Last sounds sit under the block. | "um" closes on the lips; a closing sound is written beneath its block. |
| Final Q2 | My scholars say ordinary people cannot learn letters. Are they right? | My scholars claim ordinary people could never learn to write. Are they right? | My scholars insist that common people are incapable of learning letters. Do you agree? |
| Final ② HINT 1 | Two of the marks are in your notebook. | Two characters already appear in your evidence. | You have seen two of these characters before. Search your evidence. |
| Ending | Dear Mother, I can write now! | Dear Mother, I can write now! (같음: 상징 문장) | 같음 |

ROOKIE 문장 규칙(이번 프로젝트 원칙, 메모리 `feedback_rookie_easy`): 퍼즐·추리 단계는 같고 영어만 짧게. 한 문장 12단어 이내, 과거·현재 단순시제.

---

## 5. 역사·교육 정확성 검증

### 5.1 근거로 쓰는 사실 (시즌 history dossier, 2026-11-07 원문 확인분)

| id | 사실 | 출처 |
|---|---|---|
| h1 | 1443년(세종 25) 12월, 세종이 친히 28자를 만들고 훈민정음이라 함 | 세종실록 102권 세종 25년 12월 30일 [sillok](https://sillok.history.go.kr/id/kda_12512030_002) |
| h2 | 풀이한 책 『훈민정음』 1446년(세종 28) 9월 완성 | 세종실록 113권 세종 28년 9월 29일 [sillok](https://sillok.history.go.kr/id/kda_12809029_004), [UNESCO](https://www.unesco.org/en/memory-world/hunminjeongum-manuscript) |
| h3 | 기본 자음 다섯은 발음 기관을 본뜸: ㄱ 혀뿌리가 목구멍을 막는 모양, ㄴ 혀가 윗잇몸에 닿는 모양, ㅁ 입 모양, ㅅ 이 모양, ㅇ 목구멍 모양 | [우리역사넷 제자해](https://contents.history.go.kr/id/hm_091_0030), [한국민족문화대백과 훈민정음28자모](https://encykorea.aks.ac.kr/Article/E0074518) |
| h4 | 기본 모음 셋은 하늘(점)·땅(납작한 선)·사람(선 선) | 같음 |
| h5·h9 | 어제 서문: 나랏말이 중국과 달라 한자와 맞지 않아 어리석은 백성이 하고 싶은 말이 있어도 제 뜻을 펴지 못함 → 28자를 만들어 쉽게 익혀 날로 쓰기 편하게 함 | 세종실록 113권, [세종어제훈민정음](https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_r300900) |
| h6 | 정인지 서문: 슬기로운 이는 아침이 끝나기 전에, 어리석은 이도 열흘이면 배운다 | 세종실록 113권 |
| h10 | 센 소리는 획을 더함(ㄴ→ㄷ→ㅌ, ㅁ→ㅂ→ㅍ 등) | 우리역사넷 제자해 |
| h11 | ㅏ·ㅓ·ㅗ·ㅜ는 점(ㆍ)과 ㅡ·ㅣ를 합쳐 만듦 | 같음 |
| h12 | 글자를 합쳐 한 소리를 씀: ㅡ·ㅗ·ㅜ는 첫소리 아래, ㅣ·ㅏ·ㅓ는 오른쪽, 끝소리는 첫소리 글자를 다시 씀 | 같음, [한국민족문화대백과 한글](https://encykorea.aks.ac.kr/Article/E0061508) |
| h13 | ㆍ·ㆆ·ㅿ·ㆁ 등은 오늘날 쓰지 않음 | 같음 |
| h14 | 訓民正音 = 백성을 가르치는 바른 소리 | 같음 |

### 5.2 퍼즐별 점검
- **M2 자음:** ㅁ=입, ㄴ=혀끝이 윗잇몸에 닿음, ㅇ=목구멍 — h3 그대로. 그림의 얼굴은 모두 **왼쪽을 향함**(교과서식): 혀 그림의 빨간 윤곽이 └(ㄴ) 모양. 이미지 확인 완료(§6).
- **"ㅇ은 소리가 없다":** 15세기 ㅇ(이응)은 목구멍소리로, 첫소리에서 사실상 소리값이 없었다. 받침 "ng"는 옛이응 ㆁ이 하던 일이다(h13). 게임은 **첫소리 ㅇ만** 쓰고 "holds the place"라고만 말한다. 받침 ㅇ은 나오지 않는다 → 오해 없음.
- **M3 모음:** ㅏ=ㅣ 오른쪽 점, ㅓ=ㅣ 왼쪽 점(h11). 15세기에는 점이 실제 둥근 점, 오늘날은 짧은 획 — IN THIS MYSTERY에 "today the dot is drawn as a short line".
- **엄마:** 오늘날의 말·맞춤법. 15세기 문헌의 어머니 낱말 표기를 게임이 주장하지 않는다(기존 Case 01의 원칙과 같음: "written in today's spelling").
- **끝소리 규칙:** "끝소리는 첫소리 글자를 다시 쓴다"(h12) — M3의 LAST SOUND 타일이 FIRST SOUND 타일과 같은 글자(ㅇ ㅁ ㄴ)인 이유. 소라 대사에 반영 가능(MASTER): "A last sound uses the same letters as first sounds."
- **음 블록:** ㅡ는 첫소리 아래(h12). Final 3단계에서 VOWEL 칸이 아래로 옮겨지는 것은 규칙 그대로.
- **訓民正音 뜻:** h14. 正을 RIGHT로 옮기는 것은 "바르다"의 영어 번역(기존 Case 01과 같음).

### 5.3 창작과 역사의 구분 (IN THIS MYSTERY 카드 문안)
- Bun-i, Sora, the market scribe and Bun-i's mother are made up.
- The wrong letter, the picture chart and Sora's sound board are made up.
- King Sejong is real, but everything he says and does in this case is made up. He never met Bun-i.
- The letter in Chinese characters is very short and simple for the game; a real letter would be longer.
- Bun-i's words are written in today's spelling. Her English letter is a retelling for you, not a real letter.

REAL HISTORY 카드: h1, h2, h3, h4, h9(서문 뜻), h6(열흘), h14.

### 5.4 의도한 단순화 (역사 오류 아님, 문서에 명시)
- 편지를 가로로 다섯 자만 씀: 당시 글은 세로쓰기·문어체. 어린이 탐정용 단순화.
- 장터 대서인: 글을 대신 써 주는 일은 있었으나, 이 인물과 "그림 낱말표"는 창작.
- 임금의 두 그림 쪽지는 창작 장치(실제로 세종이 그림으로 이름을 설명했다는 기록 없음).

### 5.5 어린이에게 잘못 전할 위험과 대책
| 위험 | 대책 |
|---|---|
| 세종이 실제로 분이를 만났다고 믿음 | IN THIS MYSTERY 첫 줄 + 엔딩 "In this story" |
| 1443(창제)과 1446(반포·책) 혼동 | REAL HISTORY에 두 해를 각각 한 줄로 |
| 오늘날 24자 = 1443년 28자로 착각 | REAL HISTORY: "He made 28 letters. Today Korean uses 24." |
| ㆍ(아래아)가 지금도 쓰인다고 착각 | 모음 수업에 "today the dot is a short line" |

---

## 6. 신규 이미지

### 6.1 조사한 기존 규칙
- 시즌 스타일 `seoul_scene`/`seoul_character`(`assets.manifest.json` `seasonStyles`): 먹선 + 수채, 한지 크림 바탕, 남색 밤과 등불 금색, 조선 의복·건축, 글자 없음. 장면 1536×1024, 인물 1024×1536, 모델 gpt-image-2 medium.
- 저장 정책(`tool/asset_optimizer/image_policy.json` scene): WebP `-q 88 -sharp_yuv -m 6`. 기존 장면 50~60만 바이트.
- 인물은 **기존 초상을 그대로 재사용**(sejong, bun_i, sora) — 새로 만들지 않음. 장면 생성 때 이 초상을 참조 그림으로 보내 얼굴·옷을 맞춤.
- 세로 화면: 장면은 `SceneBackdrop`이 양옆을 잘라 씀 → 프롬프트에 "중요한 인물은 가로 가운데 절반 안".

### 6.2 생성 결과 (2026-11-07, 실제 파일)
원본 PNG: `content_pipeline/asset_work/s5_seoul/v3_case01/raw/`, 게임용 WebP: `…/v3_case01/game/`, 생성 기록: `…/raw/image_manifest.json`. **`content_pipeline/asset_work/`는 git에서 제외되는 폴더**라 커밋 대상이 아니다(적용 PART에서 `assets/seasons/season_05_seoul/cases/case_01_v3/`로 옮기고 시즌 팩·R2 갱신).

| 파일(game/) | 크기 | 용량 | 참조 초상 | 쓰는 곳 | 표시 방식 |
|---|---|---|---|---|---|
| `intro_side_gate.webp` | 1536×1024 | 469,694 B | bun_i, sora | Intro, M1 대화 배경 | 배경(가운데 기준 자르기) |
| `m1_letter.webp` | 1536×1024 | 363,706 B | — | M1 편지 | 빈 종이 위에 한자 5자를 Flutter가 씀. 물방울 표시는 그림에 있음(왼쪽 아래) |
| `m1_scribe_chart.webp` | 1536×1024 | 462,322 B | — | M1 낱말표, Final 2단계(民) | 8칸 그림. 칸 아래 빈 띠에 한자를 Flutter가 씀 |
| `m2_mouth_lips.webp` | 1024×1024 | 132,530 B | — | M2 ㅁ | 그림 + Flutter 윤곽 애니메이션 |
| `m2_mouth_tongue.webp` | 1024×1024 | 104,310 B | — | M2 ㄴ | 같음(빨간 혀 윤곽이 └) |
| `m2_mouth_throat.webp` | 1024×1024 | 220,008 B | — | M2 ㅇ | 같음(빨간 원) |
| `m3_writing_desk.webp` | 1536×1024 | 443,290 B | bun_i, sora | M3 배경 | 배경. 종이는 비어 있고 블록·글자는 Flutter |
| `final_kings_study.webp` | 1536×1024 | 437,788 B | sejong, bun_i, sora | Final 배경 | 배경. 두루마리는 비어 있고 訓民正音·훈민정음은 Flutter |
| `ending_dawn_home.webp` | 1536×1024 | 426,598 B | bun_i | Ending | 배경. 종이는 뒷면만 보임 |

오버레이 좌표(원본 픽셀, 미리보기에서 잰 근사값 — 적용 때 `measuredOn`으로 다시 잼):
- `m1_letter` 빈 영역 ≈ x 280–1250, y 130–940. 물방울 중심 ≈ (375, 853).
- `m1_scribe_chart` 띠(라벨 자리): 윗줄 y ≈ 423–473, 아랫줄 y ≈ 828–883. 칸 x ≈ 205–470, 495–748, 776–1033, 1058–1357(윗줄), 184–457, 483–748, 778–1044, 1075–1379(아랫줄).
- `m2_mouth_tongue` 혀 윤곽: 선 부분 x ≈ 350–400, y ≈ 410–670; 누운 부분 y ≈ 620–670, x ≈ 350–770.

### 6.3 버리거나 만들지 않은 것
- 버림(raw/rejected/): `m2_sound_board.png`(얼굴이 오른쪽을 향해 ㄴ이 뒤집힘, 세 그림이 비슷함), `m2_sound_board_v2.png`(빨간 옷의 선생과 남자아이 교실이 끼어 들어 세종과 혼동 위험), `m2_mouth_throat.png`(서양 아이 외모). 세 그림을 하나씩 따로 다시 만들어 해결.
- **만들지 않음(승인 필요 §11-4):** Final 2단계 임금의 그림 쪽지 두 장(가르치는 스승, 곧은 먹줄). 이번 PART에서는 Final 배경까지만 만들었다. 각 1024×1024 object, 약 $0.05씩. 대안: 그림 대신 KING 대사 단서("訓 is what Sora did for Bun-i every night." / "正 is what you did to the wrong letter.")로 풀게 함 — 이미지 0장.
- 소리판 전체(5자) 그림: 만들지 않음. 증거 카드 e2는 글(+ M2 그림 세 장 축소)로 충분.

### 6.4 비용
gpt-image-2 medium 12회, 사용량 기준 **$0.6571**(호출별 실제 사용량: 참조 1~3장 장면 $0.055~0.080, 참조 없는 그림 $0.043~0.054). 시즌 예산 $12.00 중 누적 $5.7235(`planning/factory.json` `spentUsd` 갱신). 청구액은 OpenAI 기준.

---

## 7. Flutter 변경 (승인 후 구현)

### 7.1 엔진 매핑

| 미션 | 필요한 상호작용 | 기존 엔진 | 판단 |
|---|---|---|---|
| M1 | 문서 글자 ↔ 그림표 짝짓기 → 틀린 낱말 탭 → 대체 글자 선택 | `record_mismatch`(두 기록 비교), `room_find_match`(Paris 전용) | **신규 `symbol_decode`** — 세 단계를 한 화면에서. 순수 Dart 규칙(`lib/puzzles_v2/core`) + 위젯 + 계획 스키마 + 생성기 지원 |
| M2 | 글자 타일 ↔ 그림 짝짓기 + 윤곽→글자 애니메이션 + 적용 1문 | 없음 | **신규 `shape_match`**(짝 3~5, 그림마다 윤곽 경로 데이터) |
| M3 | 배우기(점 좌/우) + 블록 2개 가로 조립 + 실시간 소리 표시 | `syllable_compose`(`SyllableBoard`, 세로 칸 TOP/BOTTOM) | **확장**: 가로 단어 배치, 칸 이름 FIRST SOUND/VOWEL/LAST SOUND, 조합→로마자 소리 표시, 조합별 오답 반응, 배우기 단계 |
| Final 1 | 증거 제시 3문 | `evidence_talk`(`CaseTalk`, 카드 2장 제시) | **재사용**, 제시 카드 3장 허용(현재 2장 고정인지 확인 필요) |
| Final 2 | 한자 ↔ 증거/쪽지 모양 찾기 → 영어 뜻 타일 | M1의 `symbol_decode` | **재사용**(출처를 증거 카드로 지정하는 옵션) |
| Final 3 | 블록 1개(모음 아래) | `syllable_compose` 확장분 | 재사용 |

### 7.2 데이터
- `case.plan.json`·`levels.json` 전면 재작성(미션 3 + Final, R/J/M).
- 증거 id 유지: `e1` Bun-i's Story(새 내용), `e2` Sora's Sound Board(이름 변경, 규칙 문구 유지), `e3` Bun-i's First Word(새 내용, 엔딩에 훈민정음 추가), `e4` The Name of the Letters. 단서 `c1` 유지(물방울 표시).
- `history_dossier.json`의 s5_ep01 fiction 목록을 새 사건으로 교체(사실 h1–h15는 그대로).
- `assets.manifest.json`에 신규 9장 등록, 쓰지 않게 되는 Case 01 전용 그림(`gate_courtyard`, `copy_room`, `well_yard` 등)은 다른 Case가 쓰는지 확인 후 정리.
- 시즌 팩 R2 업로드(새 그림 9장).

### 7.3 공통 UI 영향
- `SyllableBoard` 변경은 C02(`거북선`, 세로 3묶음)도 쓰므로 **기존 세로 배치는 그대로 두고 가로 배치를 옵션으로** 추가.
- `CaseTalk` 카드 3장: 다른 시즌 대화는 2장 그대로.
- 신규 엔진 두 개는 Seoul Case 01만 사용.

### 7.4 소리 에셋(선택)
"mmm", "nnn", "ahh", "UM-MA", "Hun-min-jeong-eum" 짧은 음성 5개. 퍼즐은 소리 없이도 풀린다(화면 글로 안내). 만들려면 한국어 발음이 정확한 녹음이 필요해 이번 PART에서는 만들지 않음(§11-5).

---

## 8. 다른 Case와의 연결·영향

| Case | 지금 참조하는 것 | V3에서 |
|---|---|---|
| C02 | 단서 `s5_ep01_c1` 물방울(분이의 표시), 증거 `e2` 소라의 판(다섯 모양 + 획 더하기), "Bun-i, the water-carrier of 1446" | 물방울 = 편지의 서명으로 유지. e2 내용 유지(이름만 Sora's Sound Board). 연도는 §11-1 |
| C04 | `e2`의 "a stronger sound adds one line" | M2 성공 대사·e2 설명에 유지 |
| C08 | `e3` "Bun-i's note of 1446… It says 훈민정음" | e3 종이에 엔딩에서 훈민정음이 더해져 맞음. 연도는 §11-1 |
| C12 | "Bun-i's note of 1446 lies at the bottom. It is the oldest." | 같음 |

연도를 1443년으로 하면 C02·C08·C12의 "1446" 문구 4곳 이상을 고쳐야 한다(다른 Case 수정 → 별도 승인).

**테스트 변경 예상:** `test/sandbox/s5_seoul_case01_test.dart` 전면 교체, `s5_seoul_play_test`·`s5_seoul_dev_mode_test`·`s5_seoul_syllables_test`의 Case 01 부분, `test/season_gen/play_check_test.dart`(신규 엔진 규칙), `puzzle_engine_collisions_test`, 신규 엔진 위젯 테스트 2개.

---

## 9. 플레이 시뮬레이션 (정답을 모르는 아이가 화면만 보고)

### 9.1 8세(ROOKIE, 한자·한글 모름, 영어 기초)
- **M1①**: 편지의 첫 글자 民을 탭 → 낱말표에서 같은 모양을 찾는다. 8칸 띠를 훑어 같은 모양을 찾는 것은 "같은 그림 찾기"라 8세가 할 수 있다. 米를 水와 헷갈릴 수 있음 → "Count the little lines" 반응. 다섯 자 모두 풀면 영어 낱말이 붙는다(PEOPLE, MOTHER, SICK, PLEASE, RICE: 모두 초급 낱말).
- **M1②**: 노트에 고정된 분이의 말 "She needs medicine." vs "RICE". medicine이 어려운 낱말일 수 있음 → 분이 대사에 그림 아이콘(약사발)을 함께 보여 준다(구현 메모). RICE를 탭. ✔
- **M1③**: "Which picture is medicine?" 낱말표에 약사발 그림 → 藥 칸. ✔ 막히면 HINT 2.
- **M2**: 빨간 선의 모양을 글자와 비교. ㄴ↔혀 꺾임, ㅇ↔동그라미가 매우 뚜렷해 ㅁ은 소거법으로도 풀림. 적용 문제는 "mama"를 직접 말해 보면 입술이 닫힌다. ✔
- **M3**: 가장 어려운 단계. 배우기에서 직접 점을 놓아 ㅏ/ㅓ 소리를 확인했고, 하단 카드가 남아 있다. 블록 1에서 아이가 ㅁ을 먼저 넣기 쉬움 → 화면 소리 "mum"과 분이 반응으로 스스로 고침. 끝소리 칸이 "아래"에 있는 것은 칸 모양 자체가 보여 줌. 예상 시도 2~4회, 힌트 1개. ✔
- **Final**: 질문 3개는 카드가 3장뿐이고 각 카드의 한 줄 설명이 질문과 직접 대응. 2단계는 M1과 같은 조작이라 익숙함. 3단계 음은 ㅡ 한 가지만 새로움(소라가 바로 앞에서 설명). ✔
- **검증 결과:** 화면 정보만으로 모든 단계 해결 가능. 운에 맡길 단계 없음(각 단계 오답마다 원인 반응). 막히는 지점은 M3 블록 1이며, 실시간 소리 표시가 핵심 안전장치다.

### 9.2 12세(MASTER)
- 문장이 길고 힌트가 간접적("a cure, not food")이어도 퍼즐 구조가 같아 무리 없음.
- 지루할 위험: M1①의 다섯 자 짝짓기는 반복 → 3자 맞히면 나머지 2자는 자동으로 풀리게(구현 옵션) 고려.
- 성취감: Final 2단계에서 앞 증거가 실제로 답이 되고, 3단계에서 분이가 이름의 마지막 묶음을 쓰는 장면이 절정.

### 9.3 논리 결함 점검(설계 중 고친 것)
- 초안의 "Final 2단계: 뜻을 그냥 순서대로" → 뜻을 증거·그림에서 찾게 바꿈.
- 초안 M3 "TOP/BOTTOM" → FIRST SOUND/VOWEL/LAST SOUND 칸 모양으로.
- 正의 뜻 단서: "교정 도장 正"은 역사적 관행처럼 보일 위험이 있어 쓰지 않고, 임금의 그림 쪽지(창작 장치로 명시)로 바꿈.
- M2 소리판 그림 방향: 오른쪽을 보는 얼굴이면 혀 모양이 ┘가 되어 ㄴ과 반대 → 왼쪽 방향으로 다시 생성.

---

## 10. 구현 단계별 예상 작업량

| 단계 | 내용 | 규모 |
|---|---|---|
| P1 | 계획 데이터(case.plan·levels R/J/M), history fiction, 증거·단서 id 정리 | 중 |
| P2 | `symbol_decode` 엔진(규칙·위젯·스키마·생성기·play_check·테스트) | 대 |
| P3 | `shape_match` 엔진(윤곽 경로 데이터·애니메이션 포함) | 중~대 |
| P4 | `SyllableBoard` 확장(가로 배치·칸 이름·소리 표시·조합별 오답·배우기 단계) | 중 |
| P5 | `CaseTalk` 카드 3장, Final 3단계 연결, 엔딩 | 소~중 |
| P6 | 이미지 9장을 assets로 옮기고 매니페스트·시즌 팩·R2 업로드 | 소 |
| P7 | 테스트 교체·추가, 6가지 화면 조건 검증, 다른 Case(C02·C04·C08·C12) 회귀 | 중 |

순서 제안: P1 → P4(기존 엔진 확장, 위험 낮음) → P2 → P3 → P5 → P6 → P7. P2·P3은 각각 한 PART로 나누는 것이 안전.

---

## 11. 사용자 승인 필요 사항

1. **연도:** 1446년 여름(권장, 다른 Case 수정 없음) / 1443년 겨울(요청안, C02·C08·C12의 "1446" 문구 수정 필요).
2. **신규 엔진 두 개**(`symbol_decode`, `shape_match`)와 `SyllableBoard`·`CaseTalk` 확장 개발.
3. **증거 이름 변경:** "Sora's Lesson Board" → "Sora's Sound Board"(id `e2` 유지, C02·C04 영향은 문구 확인만).
4. **Final 2단계 임금의 그림 쪽지 두 장**을 새로 그릴지(약 $0.10), 대사 단서로 대신할지.
5. **음성 5개**(mmm, nnn, ahh, UM-MA, Hun-min-jeong-eum)를 만들지(선택, 이번 PART 미생성).
6. 기존 Case 01 전용 그림(gate_courtyard, copy_room, well_yard 등)을 V3 적용 후 팩에서 뺄지.
7. 편지의 한자를 가로 5자로 단순화하는 것(§5.4).

## 진행 상태
- 완료: 조사, 상세 기획, 이미지 9장 생성·검수·WebP 변환, 비용 기록.
- 미완료(승인 후): 게임 코드·데이터 적용, 이미지의 assets 이동과 R2 업로드, 음성, 임금의 그림 쪽지 2장.
