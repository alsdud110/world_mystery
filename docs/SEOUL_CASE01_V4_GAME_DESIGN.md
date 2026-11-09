# Seoul Case 01 V4 — The King's Secret Letters (최종 설계 + 구현 기록)

작성 2026-11-07. 이 문서는 V3(`SEOUL_CASE01_V3_GAME_DESIGN.md`, 미적용)와 현재 게임의 Case 01(네 묶음, `0fba989`·`5c870fd`)을 대체한다. V3는 참고만 했다.

목차: 1 확정 스토리 · 2 Intro~Ending 대사 · 3 퍼즐 상세 · 4 인과관계 검증 · 5 이미지·오디오 · 6 구현 범위 · 7 역사 검증 · 8 테스트 결과 · 9 남은 문제 · 10 PART별 진행

---

## 1. 확정된 전체 스토리

### 1.1 한 줄
분이는 어머니에게 "고마워요"라는 말을 **직접 쓴 편지**로 주고 싶다. 탐정은 분이의 그림 메모에서 그 말을 찾아내고(M1), 새 글자가 입 모양을 본떴다는 원리를 배우고(M2), 분이가 첫 단어 **엄마**를 쓰도록 돕고(M3), 소라가 써 준 본보기와 분이가 쓴 첫 단어로 편지를 완성한다(Final). 세종이 그 글자의 이름을 알려 준다: **훈민정음, 백성을 가르치는 바른 소리.** 새벽에 분이는 글을 모르는 어머니에게 편지를 읽는 법을 가르친다.

### 1.2 핵심 질문
**"Can Bun-i write her own letter?"** — Intro에서 세종이 묻고, Ending에서 어머니가 그 편지를 읽는 것으로 답한다.

### 1.3 왜 분이는 직접 써야 하는가 (개연성의 중심)
| 질문 | 답 (화면에서 말해짐) |
|---|---|
| 왜 편지인가 | 내일 새벽은 분이가 한 달 만에 집에 가는 날. 선물을 사고 싶지만 동전이 없다. 편지는 어머니가 간직할 수 있는 선물이다 (Intro·M1 대화) |
| 왜 대서인(글 대신 써 주는 사람)에게 맡기지 않는가 | 대서인은 한자로 쓴다. 분이도 어머니도 한자를 읽지 못한다. 그리고 그것은 분이의 말이 아니다 (M1 대화) |
| 왜 새 글자인가 | 새 글자는 입 모양을 본떠 쉽게 배운다. 하룻밤에 배운 분이가 어머니에게도 가르칠 수 있다 (M2, Ending) |
| 왜 세종이 나오는가 | 우물가에서 빈 종이를 든 분이를 본 세종(창작)이 탐정에게 도움을 청한다. 마지막에 편지를 보러 서재로 부른다 (Intro, M3 끝) |
| 편지는 어떻게 전해지는가 | 분이가 새벽에 직접 집으로 가져간다. 어머니는 글을 못 읽지만 분이가 소리를 가르쳐, 어머니가 스스로 "엄마"를 읽는다 (Ending) |

### 1.4 시간·장소
1446년 여름, 한양 궁궐. 저녁(우물가) → 밤(소라의 방) → 밤(글방 책상) → 깊은 밤(임금의 서재) → 새벽(분이의 집). 글자는 1443년에 만들어졌고 풀이한 책은 1446년 9월에 완성되었다: 여름 1446은 "아직 아는 사람이 적은" 시기다. C02·C08·C12가 분이의 쪽지를 "1446"이라 부르는 것과 맞는다.

### 1.5 인물
| 인물 | 실존/창작 | 역할 | 초상 |
|---|---|---|---|
| 세종 | 실존. 이 사건의 말과 행동은 모두 창작 | 의뢰, Final 질문, 이름 공개 | 기존 `sejong.webp` |
| 분이 | 창작. 궁궐 부엌에 물을 대는 소녀(시즌 설정 유지) | 편지를 쓰는 사람 | 기존 `bun_i.webp` |
| 소라 | 창작. 새 글자를 먼저 익힌 궁녀 | 선생님 | 기존 `sora.webp` |
| 분이 어머니 | 창작 | 편지를 받는 사람 (Ending 그림·서술에만) | 없음 (서술) |
| 탐정(플레이어) | — | 분이를 돕는 사람 | — |

택(Taek)은 V4에 나오지 않는다(다른 Case가 Case 01의 택을 참조하지 않음, §6.4).

### 1.6 시즌과의 연결
- 분이는 이름을 못 써서 편지에 **물방울**을 찍는다 → 단서 `c1` Bun-i's Mark. C02·C11·시즌 프롤로그("Every note has the same small water drop")와 이어진다.
- 어머니가 편지를 **작은 나무 상자**에 간직한다 → C08 "The Keepers' Letter Box", C12 "Bun-i's first note lies at the bottom"의 출발점.

---

## 2. Intro ~ Ending 실제 대사 (ROOKIE)

표기: NAR 서술, KING/BUN-I/SORA 대사, YOU 탐정. J/M 문장은 `levels.json`에 있다(§3.6에 대표 문장).

### Intro (사건 시작 화면)
- Summer, 1446. You visit King Sejong in Hanyang.
- He has made new letters. Very few people know them yet.
- By the kitchen well, a girl holds an empty paper.
- KING: "Bun-i has something to say. But she cannot write it."
- KING: "Can you help her?"

목표 4줄(`objectives`): Find out what Bun-i wants to say. / Learn how sounds become letters. / Help Bun-i write her first word. / Finish Bun-i's letter.

### Mission 1 — The Unwritten Letter (우물가, 저녁)
대화(분이):
- BUN-I: Tomorrow I go home to Mom. I want to give her a present.
- BUN-I: But I have no coins. So I want to give her a letter!
- BUN-I: A scribe writes in Chinese characters. Mom can't read them. I can't either.
- BUN-I: And they would be his words, not mine.
- YOU: Then what do you want to say?
- BUN-I: I drew it. Look!

퍼즐: §3.1. 성공 후:
- BUN-I: Yes! Thank you, Mom. That is my letter.
- BUN-I: I know what I want to say. But how can I write it?
- NAR: Sora, the palace maid, comes with a lamp.
- SORA: With the King's new letters. Come, I will show you.

### Mission 2 — The Secret of Sounds (소라의 방, 밤)
대화(소라):
- SORA: The King's letters are not just marks.
- SORA: Each one is a picture of your mouth!
- SORA: Say a sound. Feel your mouth. Then look.

퍼즐: §3.2. 성공 후:
- BUN-I: So sounds can become letters!
- SORA: Yes! ㄱ is the back of the tongue. ㅅ is the teeth.
- SORA: A stronger sound adds one line: ㄴ, then ㄷ.
- SORA: Now let's write your first word.

### Mission 3 — Bun-i's First Word (글방 책상, 밤)
대화(분이):
- BUN-I: I want to write MOM. We say eom-ma.
- SORA: Then build it, block by block.

퍼즐: §3.3. 성공 후:
- BUN-I: I wrote it! My own word!
- SORA: Your first word, at the top of your letter.
- NAR: A servant comes to the door. The King wants to see the letter.

### Final — The Letter for Mother (임금의 서재, 깊은 밤)
이야기 3줄:
- The King's study. Books everywhere.
- The King holds a long, empty scroll.
- "So this is Bun-i's letter," he says.

대화(세종, 증거 제시 2회): §3.4 1단계. 퍼즐: §3.4 2단계. 성공 후 이름 공개와 Ending:
- NAR: Bun-i copies Sora's word slowly. Then she presses her water drop at the end.
- KING: These letters have a name.
- NAR: On the scroll: 훈민정음 · 訓民正音 · Hunminjeongeum.
- KING: 훈 is to teach. 민 is the people.
- KING: 정 is right. 음 is sound.
- KING: The right sounds, to teach the people. Like you taught Bun-i.
- NAR: At dawn, Bun-i runs home with her letter.
- NAR: Her mother cannot read. So Bun-i shows her: "ㅁ is your lips. Say mmm."
- NAR: Her mother reads slowly: "엄… 마. Mom. That is me!"
- BUN-I: And 고마워요. Thank you, Mom!
- NAR: Her mother keeps the letter in a little wooden box.

CASE SOLVED. 사건 요약(`caseSummary`): Bun-i wanted to thank her mother in her own words. You found her message, learned how the King's letters copy the mouth, and helped her write 엄마, 고마워요. The King named his letters 훈민정음: the right sounds, to teach the people.

---

## 3. 퍼즐 상세

### 3.1 Mission 1 — The Unwritten Letter (`trace_deduction`, 기존 엔진)

**플레이어가 해결하는 것:** 분이가 어머니에게 하고 싶은 말.
**영어 사용:** 분이의 설명 문장(그림마다 한 줄)을 읽고, "주기만 하는 어머니"와 "한 번도 그 말을 못 했다"는 말에서 "고맙다"를 추리한다.
**조작:** 분이의 그림 메모(새 그림 `m1_picture_memo`)를 둘러보며 어머니 그림 세 개를 탭(낙서는 탭하면 "어머니 그림이 아님") → 아래 줄 분이 그림 셋 중 하나를 탭.

화면 단서
- 편지(letter, 다시 읽기 링크 있음):
  - Bun-i drew Mom three times. Tap each picture.
  - Then she drew herself three times, at the bottom.
  - Bun-i: "Mom gives me so much. I never said one word back."
- 흔적(그림 탭 → 노트에 적힘):
  - sew — "Mom sews at night, by a lamp. She makes my clothes."
  - rice — "Mom gives me her rice. She says, 'I am not hungry.'"
  - rain — "I was sick. Mom carried me to the doctor in the rain."
- 낙서(others): 고양이 "The palace cat. It is not about Mom." / 물통 "Bun-i's water bucket. It is not about Mom." / 물방울 "Bun-i's mark: a water drop. She cannot write her name."
- 선택할 곳(places, 칩): 절하는 분이 `THANK YOU` · 깨진 그릇 앞에서 우는 분이 `SORRY` · 보따리를 메고 손 흔드는 분이 `GOODBYE`

질문: What does Bun-i want to tell Mom? Tap the right Bun-i.
정답: 절하는 분이(THANK YOU). 근거: 세 그림 모두 어머니가 무언가를 **준다**(옷, 밥, 업어 줌). 분이는 "한 번도 그 말을 못 했다". 받은 사람이 하는 말 = thank you.
오답 반응
- SORRY: Did Bun-i break or spoil something? Look at what Mom does in each picture.
- GOODBYE: Bun-i is going home to Mom, not away from her.
HINT 1: Tap the 3 pictures of Mom. What does Mom do each time?
HINT 2: Mom gives and gives. What do you say when someone gives you something?
성공: Bun-i wants to say THANK YOU!
획득: 단서 `c1` Bun-i's Mark(값: a water drop) · 증거 `e1` **Bun-i's Message** — "Bun-i's picture note. Mom sews for her, gives her rice, and carried her in the rain. Bun-i wants to say: thank you, Mom."
다음 미션과의 인과: 무엇을 쓸지 알았지만 쓸 줄 모른다 → "How can I write it?" → 소라가 새 글자를 보여 준다. e1은 Final 1단계의 답이자 Final 2단계에서 고를 낱말(THANK YOU)을 정한다.

### 3.2 Mission 2 — The Secret of Sounds (신규 엔진 `shape_match`)

**해결하는 것:** 분이의 말을 어떻게 글자로 적는가 — 글자가 소리 낼 때의 입 모양을 본떴다.
**영어 사용:** 소라의 설명(ㅁ says "m", ㄴ says "n", ㅇ is the open throat…)과 그림 이름(LIPS, TONGUE, THROAT)을 읽고 직접 소리 내 본다.
**조작:** 글자 타일(ㅁ ㄴ ㅇ ㄱ ㅅ 다섯 개, 큰 글자)을 탭 → 입 그림(입술·혀·목구멍, V3 그림 3장 재사용)을 탭해 올린다. 세 그림 모두 채우면 CHECK.

화면 단서 (소라의 수업, letter)
- The King's letters copy your mouth.
- ㅁ says "m". Say "mmm".
- ㄴ says "n". Say "nnn".
- ㅇ is the open throat. Say "ah".
- ㄱ says "g". ㅅ says "s".
- Look at the red line in each picture.

질문: Put each letter on the picture it copies.
정답: `mieum:lips,nieun:tongue,ieung:throat`.
근거: "mmm"은 입술이 닫힌다(입 그림, 네모난 입 모양). "nnn"은 혀끝이 윗잇몸에 닿는다 — 빨간 혀 윤곽이 └ 모양으로 ㄴ과 같다. 목구멍 그림은 빨간 동그라미 — ㅇ. ㄱ은 꺾임이 반대(┐), ㅅ은 이(teeth)인데 이 그림이 없다.
오답 반응 (첫 번째 틀린 짝 기준)
- ㄱ → 혀: ㄱ bends the other way. Find the letter with the same corner as the red line.
- ㅅ → 아무 그림: ㅅ is the teeth. No picture here shows the teeth.
- ㄱ → 입술/목구멍: ㄱ says "g". Say it: the back of your tongue goes up.
- ㅁ → 혀/목구멍: Say "mmm". Your lips close. Which picture shows closed lips?
- ㄴ → 입술/목구멍: Say "nnn". Where does the tip of your tongue go?
- ㅇ → 입술/혀: ㅇ is round and open. Find the round red line.
HINT 1: Say each sound. Feel your mouth. Then look at the red line.
HINT 2: The tongue's red line makes a corner, like ㄴ. The throat's red line is round, like ㅇ.
성공: The letters copy the mouth!
획득: 단서 `c2` Letters from the Mouth(값 ㅁ ㄴ ㅇ) · 증거 `e2` **The Sound Board** — "Sora's board: the first letters copy the mouth. ㅁ the lips, ㄴ the tongue, ㅇ the throat, ㄱ the back of the tongue, ㅅ the teeth. A stronger sound adds a line." (C02·C04가 이 문구의 다섯 모양과 획 더하기를 쓴다.)
다음 미션과의 인과: 엄마의 ㅁ·ㅇ이 여기서 나온다. "Now let's write your first word."
무작위 방지: 다섯 글자 중 셋을 세 그림에 놓는 경우의 수 60, 틀리면 짝마다 이유를 말한다.

### 3.3 Mission 3 — Bun-i's First Word (`syllable_compose`, 확장: 가로 블록·칸 이름·소리 표시)

**해결하는 것:** 편지의 첫 단어 엄마를 분이가 직접 쓴다.
**영어 사용:** 소라의 규칙 문장(오른쪽/왼쪽 점, FIRST SOUND / VOWEL / LAST SOUND)과 분이의 소리 "eom-ma"를 읽는다.
**조작:** 종이 위 두 블록(BLOCK 1, BLOCK 2, 왼쪽→오른쪽)을 탭 → FIRST SOUND(ㅇ ㅁ ㄴ) · VOWEL: LINE(ㅡ ㅣ) · VOWEL: DOT(왼쪽/오른쪽/없음) · LAST SOUND(NONE, ㅁ, ㄴ)를 고른다. 블록 아래에 지금 블록의 소리(로마자 표기, 국어의 로마자 표기법)가 바로 보인다. READ THE WORD.

화면 단서 (소라의 수업, letter)
- A vowel is a line and a dot.
- A standing line with the dot on the RIGHT is ㅏ. It says "a".
- With the dot on the LEFT, it is ㅓ. It says "eo".
- Each block has a FIRST SOUND, then a VOWEL beside it.
- A LAST SOUND sits under them, at the bottom.
- Does a block start with a vowel sound? Then ㅇ goes first. It holds the place.
- 블록 줄: BLOCK 1 says "eom". / BLOCK 2 says "ma".

질문: Build Bun-i's word, eom-ma: tap a block, then choose its parts.
정답: `엄마` (BLOCK 1 = ㅇ + ㅓ + 아래 ㅁ, BLOCK 2 = ㅁ + ㅏ).
근거: eom은 모음으로 시작 → ㅇ, "eo" → 점 왼쪽 ㅓ, 끝에서 입술이 닫힘 → LAST SOUND ㅁ(M2). ma는 입술로 시작 → ㅁ, "a" → 점 오른쪽 ㅏ, 열린 채 끝 → 없음.
오답 반응 (만들어진 낱말 기준, 실시간 소리 표시와 함께)
- 어마: That says eo-ma. Listen: eom. At the end, the lips close.
- 언마: That says eon-ma. Eom ends with the lips, not the tongue.
- 암마: That says am-ma. Eo has its dot on the left.
- 멈마: That says meom-ma. Eom starts with a vowel sound: ㅇ goes first.
- 엄머: That says eom-meo. Ma has its dot on the right.
- 엄맘: That says eom-mam. Ma ends open: no last sound.
- 마엄: Say it with Bun-i: eom first, then ma.
- 그 밖: 보드가 첫 번째 틀린 블록에 CHECK 표시.
HINT 1: Eom ends with closed lips. Which letter is the lips? Put it at the bottom.
HINT 2: ㅓ has its dot on the left. ㅏ has its dot on the right.
성공: Bun-i wrote 엄마!
획득: 단서 `c3` The First Word(값 엄마, eom-ma: Mom) · 증거 `e3` **Bun-i's First Word** — "The top of Bun-i's letter for her mother: 엄마 (Mom). She wrote it by herself." (C08이 상자 속 분이의 편지로 이 카드를 보여 준다.)
다음 미션과의 인과: 첫 단어가 쓰였고, 나머지 말(고마워요)이 남았다. 세종이 편지를 보러 부른다.

### 3.4 Final — The Letter for Mother

**1단계 — 세종의 질문 (`evidence_talk`, Final 대화의 증거 제시)**
- KING: So this is the girl with the empty paper.
- YOU: It is not empty now, Your Majesty.
- 질문 1 "The King asks: "What does she want to say to her mother?"" — 제시 카드 e1·e2 → 정답 **e1 Bun-i's Message** → YOU: She wants to say thank you. Her mother gives her so much. / KING: A good word to write.
  - 오답: That does not show what she wants to say. / 두 번 틀리면: Bun-i's picture note shows her message.
- 질문 2 "The King asks: "What has she written so far?"" — 제시 카드 e2·e3 → 정답 **e3 Bun-i's First Word** → YOU: Her first word, 엄마. She wrote it by herself. / KING: Then let us finish her letter.
  - 오답: That does not show what she wrote. / 두 번 틀리면: Bun-i's first word is at the top of her letter.

**2단계 — 편지 쓰기 (`order_sequence`, Final 페이지)**
- 편지(letter): 
  - BUN-I'S PRACTICE PAPERS: 어마 · 엄마 · 엄머
  - Only one is her first word.
  - SORA'S WORDS, for letters Bun-i has not learned yet: 고마워요 · 미안해요 · 잘 가요
  - One says THANK YOU. One says I'M SORRY. One says GOODBYE.
  - Sora: "Thank you has the block 마 in it, like the end of 엄마."
- 질문: Write Bun-i's letter: tap 2 papers in order.
- 타일 6장: 어마 · 엄마 · 엄머 · 고마워요 · 미안해요 · 잘 가요
- 정답: `eomma,gomawoyo` (엄마, 고마워요)
- 근거: 첫 단어는 e3(엄마) — 어마는 끝소리 ㅁ이 없고, 엄머는 점이 왼쪽. 메시지는 e1(THANK YOU) — 소라의 단서로 블록 마(ㅁ + 오른쪽 점)를 찾는다: 미안해요의 첫 블록은 미(ㅁ + 점 없는 선), 잘 가요의 가는 ㄱ(M2: 뒤혀). 편지는 받는 사람으로 시작한다.
- 오답 반응
  - 어마, 고마워요: 어마 has no last sound. Mom's first block ends with closed lips.
  - 엄머, 고마워요: 엄머 has its last dot on the left. Mom ends with "ma": the dot on the right.
  - 엄마, 미안해요: Look at its first block: ㅁ and a line with no dot. That is 미, not 마.
  - 엄마, 잘 가요: 가 starts with ㄱ, the back of the tongue, not ㅁ.
  - 고마워요, 엄마 (순서): A letter starts with who it is for.
- HINT 1: Find Bun-i's first word. Check it with your evidence.
- HINT 2: Look for the block 마: ㅁ, and a standing line with the dot on the right.
- 성공: Bun-i's letter is ready!
- 획득: 증거 `e4` **Bun-i's Letter** — "Bun-i's letter for her mother: 엄마, 고마워요. Mom, thank you. Signed with a water drop."

**3단계 — 이름 공개 (연출, 퍼즐 아님)**: §2 Final의 KING 대사. 네 글자를 모으거나 순서를 맞히지 않는다.

**왜 "카드 놓기"로 끝나지 않는가:** 1단계는 사건의 두 결과(메시지, 첫 단어)를 왕에게 증명하고, 2단계는 그 둘과 M2·M3의 글자 지식으로 실제 편지의 두 낱말을 고른다(같은 모양의 함정 블록 미·가·어마·엄머). 3단계는 편지가 완성된 결과로 이름이 공개되고, Ending에서 편지가 전해진다.

### 3.5 8세 시뮬레이션 (ROOKIE, 한글 모름)
- M1: "같은 사람(엄마) 그림 찾기"와 짧은 문장 셋. 칩이 영어(THANK YOU/SORRY/GOODBYE)라 그림 해석에 기대지 않는다. 예상 0~1회 오답. ✔
- M2: ㅁ·ㅇ은 모양만으로도 맞고, ㄴ은 혀 윤곽 └과 같다. 함정 ㄱ(┐)은 "ㄱ bends the other way". 예상 0~2회. ✔
- M3: 가장 어렵다. BLOCK 1에서 ㅁ을 먼저 넣으면 소리 표시가 "meom"이 되어 스스로 고친다. LAST SOUND 칸이 "아래"라는 것은 규칙 문장과 칸 이름이 함께 말한다. 예상 1~3회, 힌트 1개. ✔
- Final: 카드 두 장 고르기. 엄마는 증거 카드 e3에 그대로 있다. 마 찾기는 같은 모양 찾기. 예상 0~2회. ✔
- 추측에만 의존하는 단계 없음: 모든 오답에 이유가 나온다.

### 3.6 난이도 (스토리·퍼즐·정답 동일, 영어만 차등)
| 위치 | ROOKIE | JUNIOR | MASTER |
|---|---|---|---|
| Intro (King) | Bun-i has something to say. But she cannot write it. | Bun-i has something to say, but she cannot write it down. | Bun-i has something she longs to say, yet she cannot write it down. |
| M1 편지 | Mom gives me so much. I never said one word back. | Mom gives me so much, and I have never said one word back. | My mother gives me so much, and I have never once said a word in return. |
| M1 HINT 2 | Mom gives and gives. What do you say when someone gives you something? | Mom keeps giving. What do people say when they are given something? | Her mother gives without end. What do we say to someone who gives us something? |
| M2 질문 | Put each letter on the picture it copies. | Place each letter on the picture of the mouth it copies. | Match each letter to the part of the mouth it is modelled on. |
| M3 질문 | Build Bun-i's word, eom-ma: tap a block, then choose its parts. | Build Bun-i's word, eom-ma, block by block. | Assemble Bun-i's word, eom-ma, one block at a time. |
| Final 질문 | Write Bun-i's letter: tap 2 papers in order. | Write Bun-i's letter: tap the two papers in order. | Compose Bun-i's letter: choose the two papers, in order. |
힌트는 무료, 오답 감점 없음(시즌 규칙). ROOKIE는 한 문장 12단어 이내.

---

## 4. 미션 간 인과관계 검증 (코드 작성 전 자체 검증)

| 질문 | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 1 지금 해결하려는 것 | 분이가 하고 싶은 말 | 말을 글자로 적는 방법 | 첫 단어 엄마 쓰기 | 편지 완성·전달 |
| 2 왜 해야 하나 | 분이가 쓸 내용을 모르면 편지가 없다 | 분이는 한자를 모르고, 대서인의 한자는 어머니가 못 읽는다 | 편지는 받는 사람으로 시작한다 | 내일 새벽 집에 가기 전에 |
| 3 이전 결과 사용 | Intro의 목표 | M1 끝 질문 "How can I write it?" | M2의 ㅁ·ㅇ (첫소리·끝소리) | e1(무엇을), e3(첫 단어), M2·M3 글자 지식(마 찾기) |
| 4 없으면 못 가는 이유 | Final에서 THANK YOU 낱말을 고를 수 없다 | M3 블록의 ㅁ·ㅇ, Final의 마·가 구분 불가 | Final 1단계 질문 2와 연습지 고르기 | — |
| 5 행동이 만드는 변화 | 메시지 확정, 물방울 표시 | 분이가 글자의 원리를 앎 | 종이에 엄마가 써짐 | 편지 완성 → 이름 공개 → 어머니가 읽음 |
| 6 정답 도출 근거 | 세 그림 문장 + 분이의 말 | 소라의 소리 문장 + 빨간 윤곽 | 소라의 규칙 + "eom", "ma" | e1, e3, 소라의 "마" 단서 |
| 7 학습과 사건 연결 | 영어 문장 이해 = 메시지 | 제자 원리 = 쓰는 법 | 음절 조합 = 첫 단어 | 블록 읽기 = 편지의 낱말 |
| 8 삭제해도 같은가 | 아니오 | 아니오 | 아니오 | — |

설계 중 고친 결함
1. 초안: 분이가 어머니와 같이 사는데 왜 편지? → "한 달 만에 집에 가는 날의 선물"로 바꿈(직접 건넴, 새벽 마감).
2. 초안: 어머니가 새 글자를 읽을 수 있나? → 읽지 못한다. 분이가 하룻밤 배운 것을 가르쳐 어머니가 엄마를 읽는다(h6 "열흘이면 배운다", 이름의 뜻 "가르친다"와 연결).
3. 초안 Final: 긴 문장을 혼자 쓰기 → 배우지 않은 글자(고·워·요)는 소라의 본보기, 플레이어는 배운 블록(마, 엄)으로 맞는 종이를 고른다.
4. 초안 M1: 그림만으로 감정 고르기(애매) → 칩을 영어 낱말로, 근거는 분이의 문장.
5. C08 "It says 훈민정음 / One corner is burnt" → 새 사건에 불이 없고 편지에는 엄마, 고마워요가 쓰였다. C08 두 줄만 고친다(§6.4). 증거 id는 그대로.

---

## 5. 이미지 및 오디오

### 5.1 이미지 (게임 폴더 `assets/seasons/season_05_seoul/cases/case_01/`, 기존 파일 덮어쓰기 없음)
| 파일 | 출처 | 쓰는 곳 | 비고 |
|---|---|---|---|
| `m1_picture_memo.webp` | **V4 신규** (`v4_case01/raw/m1_picture_memo_v2.png`) | M1 그림 메모(흔적 읽기 장면) | 어머니 장면 3 · 낙서 3(고양이·물통·새) · 분이 3(절·울음·손 흔들기) · 오른쪽 아래 파란 물방울. 글자 없음 |
| `ending_mother_letter.webp` | **V4 신규** | Ending 새벽 장면 배경 | 초가 마루, 어머니가 종이(뒷면만 보임)를 읽고 분이가 가리킴, 열린 나무 상자, 물통 |
| `m2_mouth_lips/tongue/throat.webp` | V3 재사용 | M2 입 모양 그림 | 혀 그림 빨간 윤곽 └ = ㄴ(얼굴 왼쪽 방향) |
| `intro_side_gate.webp` | V3 재사용 | M2 장소(안문의 등불 아래 소라와 분이) | |
| `m3_writing_desk.webp` | V3 재사용 | M3 장소(빈 종이, 붓) | |
| `final_kings_study.webp` | V3 재사용 | Final 장소, 이름 공개 배경 | 빈 두루마리: 訓民正音·훈민정음은 Flutter 글자 |

쓰지 않는 V3 그림: `m1_letter`, `m1_scribe_chart`(대서인 사건 폐기), `ending_dawn_home`(아픈 어머니 설정 폐기).
버린 V4 그림: `m1_picture_memo.png`(1차) — 등잔이 유리 갓 램프(조선에 없음)로 그려져 다시 생성.
생성: gpt-image-2 medium 1536×1024, 3회, 실제 사용량 **$0.1422** (메모 $0.0433 + $0.0435, 엔딩 $0.0554, 엔딩만 분이 초상 참조). 시즌 예산 $12 중 누적 $5.8658 (`planning/factory.json`). 기록: `content_pipeline/asset_work/s5_seoul/v4_case01/raw/image_manifest.json`(git 제외 폴더). WebP `-q 88 -sharp_yuv -m 6`.
R2: 새 파일 17개는 `appOnlySeasonFiles` + `pubspec.yaml`에 개별 등록(앱 동봉). 다음 R2 업로드 때 팩으로 옮긴다.

### 5.2 오디오 (`…/case_01/audio/*.m4a`)
macOS 한국어 음성 **Yuna**(`say -v Yuna -r 150`) → AAC 64 kbps. 9개: 미음(ㅁ), 니은(ㄴ), 아(ㅏ), 어(ㅓ), 엄, 마, 엄마, 고마워요, 훈민정음.
자음 ㅁ·ㄴ은 홀로 소리 낼 수 없어 글자 이름(미음, 니은)으로 만들었다. 표준 한국어 TTS이지만 **사람 귀로 확인하지 않았다**(§9). 퍼즐은 소리 없이 풀린다(화면 글과 로마자 표기).

---

## 6. 구현 파일과 변경 범위

### 6.1 엔진 매핑
| 단계 | 엔진 | 비고 |
|---|---|---|
| M1 | `trace_deduction` (기존) | 그림 메모가 어머니 장면을 직접 그림 → 스케치 없음. 칩 THANK YOU/SORRY/GOODBYE |
| M2 | **`shape_match` (신규)** | 글자 타일 5개 → 입 그림 3장. `matchPairs`, 답 `letter:picture` |
| M3 | `syllable_compose` (확장) | 새 옵션 `row`(가로 블록, BLOCK 1/2, FIRST SOUND · VOWEL · LAST SOUND 칸 이름, 로마자 소리 표시), `lastSounds`(끝소리 선택지). 옵션을 쓰지 않는 C02–C12 화면은 그대로 |
| Final | `evidence_talk`(Final 대화 증거 제시 2회) + `order_sequence` | 기존 그대로 |
| Ending | `EndingLine` | 계획에 선택 필드 `background` 추가 → 새벽 장면만 엔딩 그림으로 |

### 6.2 변경 파일
**신규:** `lib/data/models/shape_match.dart`(모델 + 규칙 검사, 순수 Dart), `lib/features/mission/widgets/shape_match_board.dart`(위젯), 이 문서.
**앱 공용(옵션 추가, 기존 동작 유지):** `lib/data/mock/season_catalog.dart`(`shapes` 표), `lib/features/mission/mission_screen.dart`(퍼즐·풀린 화면 연결), `lib/data/content/{puzzle_palette,puzzle_engine_collisions,season_content_validator,difficulty_content}.dart`, `lib/puzzles_v2/core/syllable_rules.dart`(`row`, `lastSounds`, `Hangul.reading` 로마자 표기), `lib/features/mission/widgets/syllable_board.dart`(row 모드).
**생성기:** `tool/season_gen/{plan_models,generate_case,play_check,case_levels,palette_facts}.dart`, `schema/mission_plan.schema.json`.
**콘텐츠:** `content_pipeline/seasons/s5_seoul/cases/s5_ep01/{case.plan,levels}.json`(전면 재작성), `season.plan.json`(장소 그림 3개, 지도 미션 위치·이름 2개), `assets.manifest.json`(그림 4개 등록), `planning/history_dossier.json`(s5_ep01의 fiction·puzzles·목표·IN THIS MYSTERY), `planning/factory.json`(비용), `cases/s5_ep08/{case.plan,levels}.json`(두 줄, §6.4), `lib/data/generated/s5_seoul/*`(재생성: 다른 Case 파일은 빈 `shapes` 표 선언만 추가).
**에셋 등록:** `pubspec.yaml`, `tool/season_packs/season_manifests.dart`(`appOnlySeasonFiles` 17개).
**테스트:** `test/sandbox/s5_seoul_case01_test.dart`(전면 교체), `s5_seoul_play_test.dart`(Case 01 플레이 부분), `s5_seoul_syllables_test.dart`(Case 01 부분), `s5_seoul_traces_test.dart`(스케치 기대값), `single_case.dart`·`season_playthrough.dart`(shapes 조작), `test/puzzle_palette_test.dart`, `test/puzzle_engine_collisions_test.dart`, `test/season_gen/palette_facts_test.dart`(개수).

### 6.3 저장 데이터 호환
미션 id(`s5_ep01_m1/m2/m3/final`), 증거 id(`e1`–`e4`), 단서 id(`c1`–`c3`)를 유지했다. 옛 저장의 완료 기록은 id로 그대로 읽힌다(내용은 현재 카드로 보인다). M3의 퍼즐 저장(`pv2:syllables:1:`)은 블록 수가 같아 읽힐 수 있으나, 옛 저장의 ㅈ·ㅡ 등 선택은 새 선택지에 없으면 무시된다(`stateFromJson`이 null → 빈 판).

### 6.4 다른 Case 참조
| Case | 참조 | V4 |
|---|---|---|
| C02 | `s5_ep01_c1` 물방울, `s5_ep01_e2` 소라의 판(다섯 모양, 획 더하기), "the water-carrier of 1446" | c1 = Bun-i's Mark(물방울) 유지. e2 = The Sound Board, 같은 내용. 변경 없음 |
| C04 | `e2` "a stronger sound adds one line (ㄴ, then ㄷ)" | e2 설명과 M2 대사에 유지. 변경 없음 |
| C08 | 엔딩 `e3` + "One corner is burnt." + "It says 훈민정음." | e3 = 분이 편지의 첫 단어 카드. 두 줄 수정: "The paper is yellow with age." / "It says 엄마, 고마워요. This is Bun-i's letter from 1446!" |
| C11 | `c1` "what her bucket held" | 유지 |
| C12 | `e3` "Bun-i's first note … at the bottom", "started it all" | 그대로 맞음. 변경 없음 |

---

## 7. 역사 검증

사실(h1–h15)은 바꾸지 않았다. 모두 기존 dossier의 원문 확인분(`source_checked`, h7만 draft·미사용).

| 게임 속 내용 | 근거 | 판정 |
|---|---|---|
| 1446년 여름, 아는 사람이 적음 | h1 1443년 12월 창제, h2 1446년 9월 책 완성 | 맞음(반포 전). 연도는 Intro 한 줄 |
| ㅁ 입, ㄴ 혀끝이 윗잇몸, ㅇ 목구멍, ㄱ 혀뿌리, ㅅ 이 | h3(제자해) | 그대로 |
| 센 소리는 획을 더함 ㄴ→ㄷ | h10 | M2 성공 대사·e2 |
| 점 + 선 = ㅏ(오른쪽)·ㅓ(왼쪽) | h4, h11 | 그대로. 오늘날 점은 짧은 획(h13, REAL HISTORY) |
| 첫소리 + 옆 모음 + 아래 끝소리 | h12 | 그대로. 끝소리 선택지에서 ㅇ을 뺐다(1446년 받침 ng는 ㆁ) |
| 모음으로 시작하는 블록의 ㅇ | h3(목구멍 글자) | "holds the place"라고만 말하고 소리값을 주장하지 않음 |
| 훈민정음 = 가르치다·백성·바르다·소리 | h14 | 이름 공개 대사 |
| 슬기로운 이는 아침, 어리석은 이도 열흘 | h6 | 분이가 하룻밤에 배우고 어머니에게 가르치는 연출과 맞음(주장하지 않음) |
| 한자로 원하는 말을 쓰지 못함 | h9 | 분이의 대사(대서인의 한자는 어머니도 분이도 못 읽음) |

창작으로 명시(dossier `fiction`, 게임의 IN THIS MYSTERY): 분이·소라·어머니, 그림 메모, 편지, 그 여름밤 / 세종의 모든 말과 행동(분이를 만난 적 없음) / 엄마·고마워요 등 오늘날 맞춤법 / 가로쓰기(1446년은 세로쓰기) / 로마자 소리 표시는 오늘날 표기법.
M1 퍼즐은 역사 사실 없이 창작만으로 푼다(dossier `fiction: true`).


---

## 8. 테스트 결과 (2026-11-07)

| 검증 | 결과 |
|---|---|
| `flutter analyze` | 문제 없음 |
| `generate_season --check` (Seoul·Rome·NY) | 모두 up to date. 다른 Case 생성물은 빈 `shapes` 표 선언만 추가 |
| Case 01 전용 (`s5_seoul_case01_test` 31, `s5_seoul_play_test` 4, `s5_seoul_syllables_test` 17, `s5_seoul_traces_test` 5, `s5_seoul_dev_mode_test` 5) | 모두 통과. R/J/M 각각 오프닝 → M1 오답·힌트 → 앱 재시작 → M2 오답 짝 → M3 오답(어마, BLOCK 1 · CHECK 표시) → Final 대화(뒤로가기·재시작 후 이어짐, 틀린 카드는 오답 아님) → 편지 오답(미안해요) → 정답 → 엔딩 → Case Closed·REAL HISTORY/IN THIS MYSTERY |
| Seoul 시즌 전체 플레이스루 R/J/M (`generated_seasons_test`, 12 Case 순서대로, 재시작 포함) | 통과 |
| 지도(`seoul_case_maps_test`) | 37 통과(V4 위치·이름으로 기대값 갱신) |
| **전체 `flutter test`** | 4013 통과 · 7 건너뜀 · 17 실패 → 지도 테스트 4건 수정 후 남은 **13건은 모두 기존 실패**: HEAD 사본(`git archive`)에서 같은 10건이 실패함을 확인(asset_optimizer, case_talk, icon_upgrade ×3, single_detective, time_code_question, visual_placeholders, world_archive, world_map) + 기존에 기록된 3건(puzzle_rules의 s5_ep03 timeline 키, s9_ep01 카탈로그, season_content의 ep10). 전체 재실행은 하지 않았다(수정한 지도 테스트 파일만 재실행) |
| asset_optimizer | 원래부터 실패(앱 동봉 Seoul 그림이 최적화 기록에 없음). V4 그림 8장도 같은 목록에 추가된다 |
| 320폭 화면 | 위젯 테스트: M2 타일·M3 조각 모두 48dp 이상·화면 안(텍스트 ×1, ×1.6). 실제 오버플로 1건 발견·수정: 엔딩 마지막 줄의 증거 카드 + CLOSE THE CASE 버튼이 320×568에서 55px 넘침 → 마지막 줄의 증거 카드 제거 |
| 화면 캡처 (`qa/s5_c01_v4/`, git 제외, 320×568 R·M, 390×844 R) | M1 선택 단계의 영어 칩(THANK YOU 등)이 원형 마커에서 잘림 → 3자 이상 칩은 알약 모양으로 넓히고 각 그림 아래로 옮김(320폭에서 겹침 없음 확인). 테스트 환경에는 한글 글꼴이 없어 캡처의 한글은 빈칸으로 보인다(기기 확인 필요, §9) |

스토리 개연성은 테스트가 아니라 §4의 표와 §3.5 시뮬레이션으로 검증했다.

## 9. 남은 문제
1. **음성은 게임에 연결하지 않았다.** 파일 9개는 앱에 포함되지만 재생 버튼이 없다. 지시("정확하지 않은 한국어 발음은 사용하지 않는다")에 따라 사람이 들어 확인한 뒤 연결한다. 연결 작업: M3 블록·낱말 듣기 버튼, Final 이름 듣기(오디오 서비스에 파일 재생 추가 필요).
2. **R2 업로드 전:** 새 파일 17개는 앱 동봉(`appOnlySeasonFiles`). 다음 Seoul 팩 업로드 때 팩으로 옮긴다. 쓰지 않게 된 옛 Case 01 그림(`gate_courtyard`, `copy_room`, `book_hall_rain`, `case_01/gate_ledger·letter_found·scholar_papers`)은 지우지 않았다(지시: 기존 이미지 삭제 금지).
3. **실기기 확인 전:** 320×568 등 화면 검증은 위젯 테스트·캡처(§8)로만 했다. 실제 기기의 한글 글꼴, 그림 메모의 확대·이동 감각은 기기에서 봐야 한다.
4. **M1 그림의 등잔·그림체:** 2차 생성에서 조선식 등잔으로 고쳤다. 아이 그림치고 선이 정교하다(게임 그림 관례로 수용).
5. **TraceSketch:** V4에서 어떤 계획도 쓰지 않는다. 엔진 기능은 `s5_seoul_traces_test`가 합성 장면으로 계속 검사한다(코드 주석 `shortcut:`).
6. **옛 저장:** 옛 M3 진행 중 저장은 빈 판으로 다시 시작한다(§6.3). 완료 기록은 유지.

## 10. PART별 진행
- PART 1 (2026-11-07): 스토리·퍼즐·인과 검증 확정. 이 문서 §1–§4.
- PART 2 (2026-11-07): 그림 2장 생성(1장 재생성), V3 6장 재사용, 음성 9개, 앱 등록. §5.
- PART 3 (2026-11-07): `shape_match` 엔진(모델·위젯·카탈로그·검증기·팔레트·생성기·play_check·스키마), M1·M2 계획 데이터.
- PART 4 (2026-11-07): `syllable_compose` row/lastSounds/로마자 표시, M3·Final·Ending 데이터, 엔딩 배경 필드, dossier, C08 두 줄, levels R/J/M 175줄, 재생성.
- PART 5 (2026-11-07): 테스트 교체·추가, 회귀, 화면 캡처. §8.

## 11. 마무리 검증 (2026-11-07 밤, 현재 작업 트리)

- M1: 분이의 말에 "I am not leaving Mom…", "And I broke nothing…"을 넣어 SORRY·GOODBYE를 화면 단서로 배제. Final: 소라가 세 낱말 모두의 블록(마·미·가요)을 알려 주고, 어느 낱말인지는 M1 메시지로만 정해짐. 틀린 낱말은 그 뜻을 말하고 "What does Bun-i want to say?"로 되짚음.
- 음성: OpenAI 음성 인식으로 역확인. 엄마·엄·고마워요·훈민정음 일치, 마·아·어·미음·니은은 판정 불가(짧은 음절 오인식). M3에 '엄마' 듣기 버튼만 연결(`SyllableSpec.voice`, `AudioService.playVoice`, 소리 끄기 존중).
- 이미지 최적화: 신규 8장을 원본 PNG에서 `optimize_assets.dart --apply --only`로 다시 만들어 `optimized_assets.json`에 기록(원본은 `content_pipeline/asset_originals`). 정책 등급이 수동 변환보다 높아 합계 약 2.8MB → 7.3MB. `--verify` 508건 일치. M1 그림 `measuredOn` 갱신·재생성.
- 결과: `flutter analyze` 문제 없음 / Case 01 관련 6개 파일 112 통과 / Seoul 시즌 전체 플레이스루 27 통과(R/J/M) / 전체 `flutter test` **4030 통과 · 7 건너뜀 · 13 실패** — 13건은 모두 HEAD 사본에서도 실패하는 기존 실패(신규 0). asset_optimizer 실패 목록에서 신규 8장은 빠짐(남은 7장은 이전 작업의 C02·C11·표지 그림).
- 미검증: 실기기·시뮬레이터 한글 표시(시뮬레이터 캡처 시도 실패), 시즌 팩 R2 업로드.
