# Seoul Case 01 전면 재기획 — 훈민정음 네 글자

- 작성: 2026-11-07 · 최종 방향 승인 반영: 2026-11-07
- 상태: **구현 완료, 미커밋** (2026-11-07, 컨텐츠 워크스페이스). 구현은 `4887645`에서 시작했고, 도중에 다른 세션의 동기화 스크립트가 `eefecef`(Case 02 M2 수정 포함)로 빨리감기했다. 새 기준에서 다시 검증했다. 결과는 §13.
- 조사 기준: `/Users/myhwang/flutter-workspace/world_mystery` 작업 트리 (main 28825ff + R1~R3 + C11 M2 미커밋 변경)
- 주의: 이 문서가 있는 컨텐츠 워크스페이스는 28825ff 그대로라서 R1~R3가 없다. 메인 체크아웃의 파일은 읽기만 했다.

## 0. 한눈에 보기

| 단계 | 장소·그림 | 찾는 글자 | 뜻 | 엔진 | 플레이어가 하는 일 | 정답 |
|---|---|---|---|---|---|---|
| M1 | 안문 `gate_courtyard` | **훈** | teach | `trace_deduction` | 흔적 3개를 읽고, 택의 모양 설명과 맞는 장소를 고른다 | `c` |
| M2 | 우물가 `well_yard` | **음** | sound | `order_sequence` | 소라의 판으로 택의 말을 풀어 글자 조각 3개를 고른다 | `ㅇ ㅡ ㅁ` |
| M3 | 글방 `copy_room` | **정** | right | `syllable_compose` | 2음절을 조립한다. 둘째 음절은 M2 단서로 채운다 | `정음` |
| Final A | 서고 `book_hall_rain` | 민의 뜻 | people | 퍼즐 전 세종 대화 (`CaseTalk`) | 증거를 내밀어 "이 글자는 누구를 위한 것인가"를 밝힌다 | 증거 제시 |
| Final B | 같은 곳 | **민** + 재배열 | — | `order_sequence` | 뜻 카드와 민 후보로 이름을 순서대로 세운다 | `TEACH → 민 → RIGHT → SOUND` |

- **신규 이미지 0장, 신규 퍼즐 엔진 0개.** `syllable_compose`의 "2음절 이상" 제한도 그대로 지킨다.
- **Final 2단계:** 승인됨. 게임 화면 코드는 바꾸지 않지만 공용 생성기·검증기 변경이 필요하다(§9). 이 변경은 조건부 승인이다(§11).
- **다른 Case 수정 필요:** C08과 C12에서 문장 하나씩, 레벨까지 합쳐 8줄(§7.2). D1 승인됨.

### 최종 승인 내용

1. Final A/B 두 단계 방식 승인
2. 이를 위한 공용 생성기·검증기 변경 조건부 승인
3. Final B 뜻 카드 방식 승인. 타일 `TEACH, LEARN, RIGHT, SOUND, GATE, 민, 문, 만, 빈`, 정답 `TEACH → 민 → RIGHT → SOUND`
4. M1은 '훈 = teach'를 직접 알려 주지 않고, 소라가 분이를 가르치는 행동을 근거로 추리
5. M1 후보 글자는 칩 라벨로 표시 (D3)
6. 첫 쪽지 변경과 C08·C12 연결 문구 수정 허용 (D1)
7. 새 이미지와 새 퍼즐 엔진 개발 금지
8. 미커밋 변경을 임의로 커밋하지 않음 (D4 보류)

## 1. 기존 Case 01 구조와 문제점

### 1.1 이야기 (미커밋 ROOKIE 기준)

- **Story Intro** (`kings_study`): 1446년 가을, 세종이 새 글자 28자를 보여 주며 "새벽까지 읽어 보라"고 한다. 수문장 택이 이상한 종이로 등불을 붙이고, 탐정이 꺼낸다. 비가 오고 있다.
- **M1 The Paper Under the Gate:** 門을 세 번 베낀 쪽지, 물동이 자국, 물방울을 찾아 우물 길을 고른다. 물 긷는 소녀 분이가 쓴 것으로 밝혀진다.
- **M2 Sora's Lesson Box:** 소라의 판(발음 기관, 획 추가)과 택의 기억으로 자음 5개를 고른다.
- **M3 Four Little Groups:** 천지인 모음을 조립해 세로쓰기 종이에 `서고지붕`을 완성한다.
- **Final The King's Letters:** 비 오는 서고 앞에서 세종의 세 질문에 증거로 답한다. 서고 문이 열려 책을 구한다.
- **Case Solved:** 분이가 돌아와 "임금님이 내 첫 편지를 읽으셨어요?"라고 묻는다. Reveal은 REAL HISTORY 7줄, IN THIS MYSTERY 3줄이다.

### 1.2 미션별 현재 사양

| | 엔진 | 정답 | 선택지 | 힌트 | 오답 피드백 |
|---|---|---|---|---|---|
| M1 | `trace_deduction` (`deductions`) | `c` 우물 길 | a 학자 전각, b 초소, c 우물 길 | ① 세 흔적 탭 ② 궁에서 물을 나르는 사람은? | a, b 각각 있음 |
| M2 | `order_sequence` | `siot,giyeok,jieut,bieup,ieung` | 타일 9개 중 5개 | ① 판에서 teeth·back of the tongue 찾기 ② ㅅ에 한 줄만 | 4종 + orderFeedback |
| M3 | `syllable_compose` (`syllables`), columnHeight 2 | `서고지붕` | 초성 5개, 선·점·받침 | ① 1·2번 위치 ② 3·4번 위치 | 3종 |
| Final | `evidence_talk` (`talks`) | `open` | 질문 3개 × 증거 2개 | ① 질문마다 증거 하나 ② 쪽지·판·쪽지 | miss / tell |

### 1.3 인물·장소·역사

- **인물:** 세종(실존, 대사는 창작), 택·소라·분이(창작)
- **장소:** 안문, 우물가, 글방, 서고 (궁궐 건물명을 특정하지 않음)
- **검증된 역사(`history_dossier.json`):** h1 1443 창제, h2 1446 책 완성, h3 기관 모양, h4 천지인, h5 서문 목적, h6 열흘, h9 말이 달라 쓰지 못함, h10 가획, h11 모음 결합, h12 합자, h13 사라진 글자. h7은 draft, h7·h8은 미사용
- **창작:** 비 오는 밤, 불탄 종이, 서고와 지붕 구멍, 레슨 박스와 판, 열흘 시험, 세로쓰기 배치

### 1.4 기존 에셋

| 파일 | 현재 용도 | 새 기획 |
|---|---|---|
| `cover/kings_study` | Intro | 재사용 |
| `locations/gate_courtyard` | M1 (좌표 측정 완료) | 재사용, 좌표 유지 |
| `locations/well_yard` | M2 | 재사용 |
| `locations/copy_room` | M3 | 재사용 |
| `locations/book_hall_rain` | Final (세종, 천막을 든 하인들) | 재사용 |
| `characters/sejong, taek, sora, bun_i` | 대화·엔딩 | 재사용 |
| `locations/map/palace_map` | Case 지도 4지점 | 재사용, 좌표 유지 |
| `cases/case_01/gate_ledger, letter_found, scholar_papers` | 미사용 | 쓰지 않음. 어울리는 장면이 없다 |
| `locations/royal_archive, palace_night`, `characters/bae` | 미사용 | 쓰지 않음 |

### 1.5 문제점

1. **이야기의 답이 주제와 떨어져 있다.** 세종의 글자를 배우는데 최종 답은 "서고 지붕"이라는 건물 수리 정보다. 훈민정음이라는 이름은 플레이 중 나오지 않고 Reveal에서만 나온다.
2. **백성이라는 주제가 결과로 남지 않는다.** "왜 만들었나"는 대사로만 지나간다.
3. **M2 → M3의 부담이 크다.** 자음 5개, 4음절, 세로 배치를 한꺼번에 처리해야 한다. M2는 ROOKIE 감사에서 138어로 P1이었다.
4. **세로쓰기 규칙이 출처 미확인이다.** dossier가 스스로 "공공기관 출처를 열지 못했다"고 적어 둔 창작 규칙이다.

## 2. 새 스토리 전체 줄거리

**핵심 문장:** 분이의 첫 글은 경고문이 아니라 **새 글자의 이름**이었다. 네 번째 글자 '민'의 뜻은 바로 분이 같은 사람들이다.

1. **Intro.** 세종이 28자를 보여 주며 묻는다. "글을 모르는 사람도 열흘이면 배울 수 있을까?" 그날 밤 택이 이상한 종이로 등불을 붙이고, 탐정이 꺼내지만 네 묶음의 글자가 모두 탔다. 택은 모양은 기억하지만 **순서는 기억하지 못한다.**
2. **M1.** 흔적이 물 나르는 사람을 가리킨다. 소라의 제자 셋이 각자 일하는 곳 근처에 연습 글자를 분필로 써 두었다. 택이 기억한 모양과 맞는 글자는 우물 길의 **훈**이다. 이 글을 쓴 사람은 분이다. 물 긷는 사람들은 이 글자가 "소라가 밤마다 분이에게 해 주는 일"이라고 말한다. 그런데 비가 오면 분필 글씨는 지워진다.
3. **M2.** 소라는 오늘이 분이의 열흘째라고 말한다. 왕의 시험 마지막 과제는 "글자의 이름을 쓰는 것"이었다. 판의 규칙으로 레슨 박스를 열자 분이의 석판에 **음**이 있다. 뜻은 소리다.
4. **M3.** 글방에 분이가 연습하다 지워진 종이가 있다. 두 묶음을 복원하니 "바른 소리"라는 뜻의 **정음**이다. 음이 소리이므로 **정**은 '바른'이다.
5. **Final A.** 비가 내리고, 세종은 새 책을 지키러 서고에 와 있다. 왕은 차례로 묻는다. 누가 썼는가, 어떻게 열흘에 배웠는가, 이 글자는 누구를 위한 것인가. 門을 베낀 쪽지가 답이다. 글을 쓰지 못하던 사람들, 곧 **백성**이다.
6. **Final B.** 택이 기억한 마지막 모양으로 **민**을 찾고, 찾은 세 글자는 뜻 카드로 놓는다. 무엇을 하는가(TEACH) → 누구를 위한 것인가(민) → 무엇을 주는가(RIGHT, SOUND). 맞히면 카드가 **훈민정음**으로 드러난다.
7. **Case Solved.** 세종이 읽는다. "백성을 가르치는 바른 소리." 새벽에 분이가 돌아온다. 소라가 작은 상자를 건넨다(시즌 설정 그대로). 불탄 종이는 그 상자 맨 아래로 간다.

**창작과 역사의 구분:** 네 글자가 흩어지거나 사라진 적은 없다. 사라진 것은 게임 속 분이의 연습 종이일 뿐이다. Reveal의 IN THIS MYSTERY에 "훈민정음이라는 이름은 사라진 적이 없다. 네 글자를 찾는 이야기는 만든 이야기다"라고 적는다.

## 3. M1~Final 상세 퍼즐 설계

- 아래 영어는 전부 **ROOKIE 예시**다. JUNIOR·MASTER는 같은 줄을 풀어 쓴다.
- 영어 문장 안의 한글 금지 규칙을 지킨다(`s5_seoul_syllables_test.dart:183`). 낱자(ㅇ, ㅁ)는 허용이고, 음절 글자는 타일·칩·단서 값·전환 문장에만 쓴다.

### 3.1 M1 — The Paper Under the Gate → 훈

1. **시작:** 택: "It was under the inner gate after sunset." / "It had four little groups. I remember the shapes, not the order." / 탐정: "Then we can build them again."
2. **조사 대상:** 안문 앞마당의 흔적 3개, 장소 3곳
3. **화면 단서:**
   - 기존 스케치 3개를 유지한다: 門 쪽지, 물동이 자국, 물방울
   - 새 줄(편지): `Sora's 3 pupils each chalked one group by their place.` / `Taek saw a ring with 2 short lines on top. Under it: a flat line, a dot below it, then a corner.`
   - 장소 칩의 라벨에 후보 글자를 넣는다: a `The scholars' hall: 혼` / b `The guard post: 운` / c `The path to the kitchen well: 훈`
4. **조작:** 흔적 3개 탭 → 장소 칩을 눌러 후보 확인 → 맞는 곳 선택 → SEARCH HERE
5. **정답과 근거:** `c`. 근거가 두 갈래로 일치한다. 흔적은 물 나르는 사람을 가리키고, 택의 설명은 ㅎ·ㅜ·ㄴ으로 혼(점이 위)과 운(위 두 줄 없음)을 배제한다.
6. **힌트·오답:**
   - 힌트 1: `Tap the paper scrap, the wet ring and the drops of water.`
   - 힌트 2: `Who carries water? Then read Taek's shapes again.`
   - a: `Scholars write Chinese characters well. And Taek saw the dot below the line.`
   - b: `No bucket stands here. And Taek saw 2 short lines on top.`
7. **다음 연결 (뜻은 말하지 않는다):** `"That is Bun-i's group," says a water-carrier.` / `"She says it is what Sora does for her every night."` / `"Sora teaches her the new letters."`
8. **ROOKIE 질문:** `Which place has the writer's group? Tap the place.`
9. **학습:** 많은 사람이 글을 쓰지 못했다는 세종의 서문(h9). 영어 모양 묘사 읽기.
10. **재사용:** 엔진·그림·좌표·스케치 전부 재사용. 코드 변경 없음.
- **단서 출력:** `c1` 유지. 값 `훈`, 노트 `Bun-i's group: what Sora does for her. Bun-i carries water. She could not write Chinese characters.` C02·C11이 쓰는 "분이는 물 긷는 사람" 정보가 그대로 남는다.
- **뜻의 추리:** M1의 어떤 문장도 '훈 = teach'라고 말하지 않는다. 플레이어는 "소라가 분이에게 해 주는 일"과 "소라가 가르친다"를 연결해야 한다. 판정은 Final B의 TEACH·LEARN 선택에서 이뤄진다. 분이는 배우고 소라는 가르치므로 LEARN이 함정이다.
- **한계:** 글자는 그림에 없고 칩으로만 보인다(D3 승인).

### 3.2 M2 — Sora's Lesson Box → 음

1. **시작:** 소라: `Today was Bun-i's tenth day.` / `Her last test: write the name of the King's letters.` / `Pupils lock their slates in my box. The lock is one group.`
2. **조사 대상:** 소라의 판과 택의 기억
3. **화면 단서:**
   ```
   SORA'S BOARD
   ㄱ = the back of the tongue
   ㄴ = the tongue on the gums
   ㅁ = the mouth
   ㅅ = the teeth
   ㅇ = the throat
   A flat line = the earth.
   A stronger sound adds one line.
   ㄴ + 1 line = ㄷ
   ㅁ + 1 line = ㅂ

   TAEK REMEMBERS
   1. The throat.
   2. A flat line, no dot.
   3. The mouth at the bottom. No added line.
   ```
4. **조작:** 타일 9개(ㅇ ㅡ ㅁ ㅂ ㅅ ㄴ ㄱ ㅣ ㅗ) 중 3개를 택의 순서대로 탭
5. **정답과 근거:** `ieung,eu,mieum`. 영어 기관명이 자음을, flat line과 no dot이 모음을 결정한다. ㅂ은 획 규칙을 읽어야 배제된다.
6. **힌트·오답:**
   - 힌트 1: `Find the throat and the mouth on Sora's board.`
   - 힌트 2: `Read line 3 again: is a line added?`
   - `ieung,eu,bieup`: `Taek says no added line.`
   - `ieung,o,mieum`: `Taek says no dot.`
   - `ieung,i,mieum`: `The line is flat, not standing.`
   - `siot,eu,mieum`: `Line 1 is the throat, not the teeth.`
   - orderFeedback: `Those are the right letters. Read Taek's lines in order.`
7. **다음 연결:** `Inside is Bun-i's slate. It shows 음.` / `"Eum means sound," says Sora.` / `"She practised one more paper in my writing room."`
8. **ROOKIE 질문:** `Which 3 letters open the box? Tap them in Taek's order.`
9. **학습:** 자음이 발음 기관을 본떴다는 원리(h3), 획 추가(h10), 땅을 뜻하는 ㅡ(h4). 음이라는 글자 자체가 목구멍과 입으로 이루어진다는 점이 "소리" 주제와 맞닿는다.
10. **재사용:** 엔진·그림 재사용. **증거 `e2` "Sora's Lesson Board"는 이름과 설명을 그대로 둔다.** C02 M2와 C04 M1이 이 증거를 다시 쓴다.
- **단서 출력:** `c2` 값 `음`, 노트 `음 = SOUND. The throat, a flat line, the mouth.`

### 3.3 M3 — Bun-i's Last Paper → 정

1. **시작:** 소라: `"Vowels have three shapes."` / `"Dot = sky. Flat line = earth. Standing line = person."` / 택: `"The paper had two groups side by side."`
2. **조사 대상:** 지워진 연습 종이
3. **화면 단서:**
   - 편지: `Flat vowels go under.` / `Standing vowels go on the right.` / `Write from left to right.`
   - 조립판: `Group 1: the teeth + 1 line. A standing line, a dot on its left. The throat at the bottom.`
   - 조립판: `Group 2: the group on Bun-i's slate.`
4. **조작:** 칸마다 초성(ㅅ ㅈ ㅊ ㅇ ㅁ ㄴ) → 선 → 점 → 받침. 한 줄 배치라 C02 M2와 같다.
5. **정답과 근거:** `정음`.
   - 1번은 ㅈ(ㅅ + 1획) + ㅓ + ㅇ이다.
   - 2번은 설명이 없고 M2 단서를 봐야 한다. **앞 미션의 단서가 실제로 답을 결정한다.**
6. **힌트·오답:**
   - 힌트 1: `Group 2 is in your notebook. Read your clue from the well.`
   - 힌트 2: `Group 1: add one line to the teeth, not two.`
   - `성음`: `Group 1 is the teeth + 1 line.`
   - `청음`: `Group 1 has 1 added line, not 2.`
   - `장음`: `Group 1's dot is on the left of its line.`
7. **다음 연결:** `"This says: the right sounds," Sora reads.` / `"That is three groups. One is still missing."` / `"The King is at the book hall. Rain is coming in."`
8. **ROOKIE 질문:** `Tap a group. Choose its sound, then its line and dot.`
9. **학습:** 천지인(h4), 모음 결합(h11), 합자와 받침(h12). 정음이 훈민정음의 줄임말로도 쓰였다는 점(새 사실 h15).
10. **재사용:** 엔진 무변경. `columnHeight`를 빼서 세로쓰기 창작 규칙이 사라진다.
- **단서 출력:** `c3` 값 `정`, 노트 `정음 = the right sounds. 음 is sound, so 정 = RIGHT.` 증거 `e3`은 ID와 이름 "Bun-i's Note"를 유지하고 설명만 바꾼다.

### 3.4 Final — The King's Letters → 민 + 재배열

**Stage A: 세종과의 대화 (민의 뜻)**

1. **시작:** `Rain is falling. Servants hold cloth over the book hall.` / `King Sejong turns to you.` / `"Three groups of a girl's paper? Show me."`
2. **조사 대상:** 수첩의 증거
3. **질문 (`requires`로 한 번에 하나씩 연다):**
   - `who` — `Who wrote this?` → e1, 카드 e1·e2 (대답: `Bun-i. She cannot write Chinese characters.`)
   - `how` (`requires: who`) — `How could she learn in ten days?` → e2, 카드 e2·e3 (대답: `Your letters copy the mouth. They are easy to learn.`)
   - `people` (`requires: how`) — `Who are my letters for?` → e1, 카드 e1·e3 (대답: `For people like Bun-i. For the people!`)
4. **조작:** 기존 CaseTalk 그대로 카드를 고른다. 틀려도 오답이 아니고 miss 대사가 나온다.
5. **정답:** 세 질문 완료. 네 번째 글자의 뜻이 PEOPLE이라는 것을 증거로 연결한다.
6. **오답:** `That does not show who the letters are for.` / tell: `The copied scrap shows someone who could not write.`
- **제약:** e1은 `who`와 `people`에서 두 번 쓰인다. `TalkProgress.show`는 열린 질문을 앞에서부터 찾으므로 `requires` 사슬이 없으면 e1이 항상 첫 질문으로 간다. 대화에 `finishLabel`을 두지 않는다(§10).

**Stage B: 민 찾기와 재배열 (뜻 카드)**

3. **화면 단서:**
   ```
   Taek remembers the last group:
   The mouth. A standing line, no dot.
   The tongue on the gums at the bottom.

   The name reads like this:
   1. What does the King want to do?
   2. Who is it for?
   3 and 4. What does he give them?
   ```
4. **조작:** 타일 9개(`TEACH LEARN RIGHT SOUND GATE 민 문 만 빈`) 중 4개를 순서대로 탭
5. **정답과 근거:** 옵션 id `teach,min,right,sound`.
   - TEACH: M1의 "소라가 분이에게 해 주는 일". LEARN은 분이의 일이다.
   - 민: ㅁ + ㅣ + ㄴ. 문은 납작한 선, 만은 점이 있고, 빈은 획이 더해졌다. 2번 칸은 Stage A의 PEOPLE이 가리키는 자리다.
   - RIGHT, SOUND: M3의 `the right sounds`와 M2의 소리
   - GATE와 문은 M1의 門 쪽지가 되돌아오는 함정이다.
6. **힌트·오답:**
   - 힌트 1: `Read your clues. What does Sora do for Bun-i?`
   - 힌트 2: `Read Bun-i's note again: which word comes first?`
   - `learn,min,right,sound`: `Sora does not learn. What does she do for Bun-i?`
   - `teach,mun,right,sound`: `Taek saw a standing line, not a flat one.`
   - `teach,man,right,sound`: `Taek saw no dot.`
   - `teach,bin,right,sound`: `The mouth has no added line here.`
   - `gate,min,right,sound`: `That is the sign on the gate, not what the King wants to do.`
   - orderFeedback: `Those are the right tiles. Read the 3 questions again.`
   - 위 조합에 없는 답은 일반 다시 시도 문구로 처리된다(`AnswerChecker`가 정확히 일치하는 조합만 찾는다).
7. **전환:** `The tiles turn over: 훈민정음.` / `"The right sounds, to teach the people."` / `"That is why I made them."`
8. **ROOKIE 질문:** `Build the name: tap 4 tiles in order.`
9. **학습:** 이름의 뜻(h14), 왜 만들었는가(h5, h9), 열흘(h6)
10. **재사용:** 그림·초상·CaseTalk·`order_sequence` 재사용. 엔딩의 분이·소라 대사 유지.

- **이름을 아는 아이:** 민은 바로 고를 수 있다. 나머지 세 칸은 뜻 카드라서 단서를 읽어야 한다. 이 한계는 수용한다.
- **학습 표현:** `learning.expressions`는 Stage B의 편지에 있는 문장을 쓴다(예: `Who is it for?`). 대화의 질문 문장은 학습 검사가 읽지 못한다(§10).
- **단서 사용 정리:** e1 → Stage A(`who`, `people`), e2 → Stage A(`how`), c1·c2·c3 → Stage B의 뜻 카드, M2의 판 규칙 → 민 판별
- **증거 출력:** `e4`는 "The Name of the Letters"로 바꾼다. 후속 Case 참조가 없어서 안전하다.

### 3.5 네 미션이 서로 다른 이유

| | 추리 재료 | 손의 조작 | 앞 단서 사용 |
|---|---|---|---|
| M1 | 현장 흔적 + 영어 모양 묘사 | 그림 탐색, 장소 선택 | 없음 |
| M2 | 규칙표 해독 | 낱자 타일 선택 | 분이·소라 관계 |
| M3 | 조립 설명 | 음절 조립 | 2번 음절 = M2 답 |
| Final A | 증거와 질문의 연결 | 증거 내밀기 | e1, e2 |
| Final B | 뜻으로 이름 구성 | 뜻 카드와 음절 타일 배열 | 뜻 3개, 판 규칙 |

## 4. 네 글자의 발견과 재배열

| 발견 순서 | 글자 | 뜻 | 플레이어의 근거 | 저장 위치 |
|---|---|---|---|---|
| 1 | 훈 | teach | 모양 묘사 + 흔적으로 글자를 찾고, 소라의 행동으로 뜻을 추리 | `c1` |
| 2 | 음 | sound | 판 해독 | `c2` |
| 3 | 정 | right | 조립 + 소거 (정음 − 음) | `c3` |
| 4 | 민 | people | 증거로 뜻 도출 + 모양으로 글자 판별 | Final |

- **왜 순서가 뒤섞였나:** 택이 "모양은 기억해도 순서는 모른다"고 처음부터 말한다. 탐색 순서는 분이의 물길을 따른 결과다.
- **왜 재배열이 추리인가:** Final B는 글자가 아니라 뜻으로 줄을 세운다. 답은 이름을 외워서가 아니라 단서의 뜻을 읽어서 나온다.
- **이름의 공개:** 네 글자가 함께 드러나는 순간은 Final B를 푼 뒤의 전환이다.

## 5. 기존 에셋·엔진 재사용 계획

### 5.1 음절별 엔진 적합성

훈(ㅎㅜㄴ), 음(ㅇㅡㅁ), 정(ㅈㅓㅇ), 민(ㅁㅣㄴ)의 모음은 모두 `Hangul.vowelOf`가 만드는 6개 안에 있다. 정음도 조합 가능하다.

### 5.2 엔진 제약 확인 결과

| 제약 | 근거 | 기획의 대응 |
|---|---|---|
| `syllable_compose`는 2~6음절 | `SyllableRules.sizes` | M3를 `정음` 2음절로 설계 |
| `syllable_compose`는 Final 표면 불가 | `palette_facts.dart` | Final에 쓰지 않음 |
| `letter_tile_lock`은 타일 수 = 칸 수 | 구현 보고서 §2 | 방해 타일이 필요해서 `order_sequence` 사용 |
| `talks` Final은 대화가 끝나면 퍼즐 없이 종료 | `final_mission_screen.dart:970` | Final을 `talks`로 두지 않음 |
| 대화의 카드는 증거 id만 받음 | `TalkPresent.choices` | 민 판별을 Stage A에 넣지 않고 Stage B 타일로 처리 |
| `guided_steps`는 사용 금지 | 2026-11-06 사용자가 롤백 | 쓰지 않음 |
| 미션 수는 `m1…`와 `final` 슬롯 구조 | `plan_check.dart:196` | 4단계 구조 유지 |
| 같은 엔진 반복은 경고 | `repeatedInCase` (warning) | M2·Final이 `order_sequence`. 경고는 남는다 |

### 5.3 Final 2단계 구현 판단

**승인된 방식: Stage A = 퍼즐 전 대화, Stage B = `order_sequence`.**

- **런타임:** `_talkBeforeFinal`이 `TalkMission.before`를 `CaseTalk`로 띄운 뒤 일반 Final로 넘어간다. `final_mission_screen.dart`는 수정이 필요 없다.
- **정정:** 이전 판에서 "Paris Case 11이 쓰는 경로"라고 적은 것은 틀렸다. 이 경로를 쓰는 것은 Season 1 Final의 듣기 전용 대화(`season1_speeches.dart`)다. Final 전 대화에서 증거를 내미는 전례는 없고, 일회용 사본 시제품으로만 확인했다.
- **정정:** 이전 판의 "도구 3곳"은 축소된 수치다. 정확한 범위는 §9에 있다.

## 6. 역사적 사실 검증이 필요한 부분

### 6.1 확인된 사실

| 사실 | 초안 문장 | 근거 | 상태 |
|---|---|---|---|
| **h14** 이름의 뜻 | The name Hunminjeongeum means "the right sounds to teach the people". | 1459년 『월인석보』 언해 주석(우리역사넷 수록), 한국민족문화대백과 「한글」, 국립국어원, 우리역사넷 「한글 창제와 훈민정음」, 국가유산청 | 내용 확인 |
| **h15** 정음은 줄임말 | The name was also shortened to Jeongeum. | 한국민족문화대백과 「한글」, 세종실록 28년 9월 29일 정인지 서문 "正音二十八字… 名曰訓民正音" | 내용 확인 |
| 이름의 첫 기록 | (h1에 포함) | 세종실록 25년 12월 30일 "是謂訓民正音" | 기존 h1과 일치 |

**dossier 등록 전 할 일:** 위 페이지 일부는 요약 도구로 읽었고 옛 한글이 빠진 인용도 있다. 구현 때 각 페이지에서 인용문을 직접 옮겨 적은 뒤 `source_checked`로 둔다.

### 6.2 확정하지 않는 것

| 항목 | 위험 | 처리 |
|---|---|---|
| **15세기 한글 표기** | 책 제목은 한자 訓民正音이고, 언해본의 한글 표기는 오늘날과 다르다(동국정운식 한자음). **정확한 옛 표기는 확인하지 못했다** | 역사 사실로 쓰지 않는다. "오늘날 맞춤법으로 썼다"고 Reveal에 명시 |
| 어순 | `Teach the people the right sounds`는 어순을 맞춘 풀이다 | 전환·Reveal에는 `The right sounds, to teach the people`을 쓴다 |
| 음절 뜻 | 뜻은 한글 음절이 아니라 한자의 뜻이다 | Reveal에 "네 글자는 한자 訓民正音을 읽은 소리"라고 적는다 |
| 正의 낱자 풀이 | 확인한 언해 인용은 訓·民·音을 풀이하고 正은 "正한 소리"로 쓴다 | '바른'은 이름 전체의 풀이를 근거로 쓴다 |
| 왕의 시험, 연습 글자, 석판 | 창작 | dossier `fiction`에 등록 |
| 분필·숯의 시대성 | 어느 쪽도 사실로 확인하지 않았다 | 재료를 고르더라도 창작으로만 둔다(D6) |
| h3·h10·h4·h11·h12 | 기존 검증 재사용 | ㅎ은 모양으로만 묘사해서 추가 사실이 필요 없다 |
| 문 = 門 | 게임이 사실로 진술하지 않음 | 피드백은 모양과 문의 표지판만 언급 |

**제외할 내용:** 세로쓰기 규칙, 서고 지붕 설정(fiction에서 제거), 왕이 이름을 새벽에 공표했다는 식의 표현.

## 7. 예상 수정 파일 및 작업량

### 7.1 '서고지붕' 제거 범위

| 파일 | 변경 |
|---|---|
| `s5_ep01/case.plan.json`, `levels.json` | 전면 재작성 |
| `planning/history_dossier.json` | ep01 puzzles·fiction·reveal, h14·h15 추가 |
| `planning/story_bible.json` | Case 01 solution, clueThreads 3건, 질문 1건, sora·bun_i 설명 |
| `planning/puzzle_selection.json`, `quality_report.json`, `FACTORY_REPORT.md`, `generated.manifest.json` | 재생성 |
| `lib/data/generated/s5_seoul/*` | ep01, ep08, ep12, 콘텐츠 재생성 |
| `test/sandbox/s5_seoul_syllables_test.dart` | M2·M3 그룹 대폭 수정 (라인 19, 73, 102, 132, 152~181, 218~229) |
| `test/sandbox/s5_seoul_play_test.dart` | 표 이름과 답, 플레이 순서 수정 (33~36, 40 이후). `season.talks` 기대값이 `talkMissions`로 바뀐다 |
| `test/sandbox/single_case.dart` | `solveFinal`이 Final 전 대화의 카드 선택을 처리하도록 수정 |
| `test/sandbox/s5_seoul_traces_test.dart` | M1 라벨·단서 |
| `test/puzzles_v2/syllable_rules_test.dart` | 수정 불필요. 자체 `_spec`의 서고지붕은 엔진 단위 예시라 남겨도 된다 |

`test/seoul_case_maps_test.dart`는 장소가 그대로라 영향이 없다. `game_master_screen.dart:441`은 제목 유지 시 무변경이다.

### 7.2 후속 Case 영향

| 참조 | 내용 | 영향 |
|---|---|---|
| `c1` → C02 M1·Final, C11 M1 | 분이 = 물 긷는 사람 | 유지, 수정 없음 |
| `e2` → C02 M2, C04 M1 | 소라의 판 | 이름·설명 고정, 수정 없음 |
| `e3` → C08 Final | `It says 서고 지붕.` | **수정**: `It says 훈민정음.` (case plan 1줄, levels 3줄) |
| `e3` → C12 Final | 증거 링크 | ID 유지, 수정 없음 |
| C12 M2 타임라인 카드 | `The first note, about a book hall roof.` | **수정**: `The first note: the name of the letters.` (1줄 + 3줄) |
| `s5_ep08`, `s5_ep12` 불탄 모서리, 상자 맨 아래 | 시즌 설정 | 유지 |

- **시즌 전체 흐름:** 진실(분이의 가문이 글자를 지켰다)과 범인 없는 구조는 그대로다. 오히려 강해진다. 500년 지킨 첫 쪽지가 글자의 이름이 되고, 시즌 끝의 `광복`과 대칭을 이룬다.
- **`languageArc`:** Act 1의 "how the letters are made, place words"는 유지된다.
- **Season 시작 문구 `startingSituation`:** "a half-burnt paper in the new letters is found at the inner gate"는 그대로 맞다.

### 7.3 미커밋 변경과의 관계

**분류 (59건 시점의 스냅샷):**

| 묶음 | 건수 | 내용 |
|---|---|---|
| Case 01 ROOKIE·기기 피드백 | 8 | ep01 4개, `scene_deduction`, `episode.dart`, `episode_content_test`, traces 테스트 |
| R1~R3 | 31 | ep02·05·06·07·09·10·12 (28개), rookie 테스트, syllables 테스트, 감사 문서 |
| C11 M2 | 15 | ep11 4개, 이미지 2장, 매니페스트류 3개, pubspec, 팩 도구, 배포 테스트, case11 테스트, 리뷰 문서, 역사 생성물 |
| 공용 파생 파일 | 5 | dossier, bible, `puzzle_selection`, `quality_report`, `generated.manifest` |

- ep01, ep02, ep11과 공용 파생 파일은 여러 작업이 섞여 있어서 파일 단위로 나눌 수 없다.
- C11 M2는 구현 완료로 확인했다. 관련 Seoul 묶음 58개 통과, analyze 문제 없음, 생성물 최신. 실기기 확인과 이미지의 R2 팩 이동이 남아 있다.
- 조사 이후 메인 체크아웃에 Case 02 관련 항목이 더 나타났다. 이 문서는 그 작업의 완료 여부를 판단하지 않는다.

**구현 시 충돌:**

- 컨텐츠 워크스페이스는 R1~R3가 없는 기준이라 그대로 구현하면 충돌한다. 작업 기준은 사용자가 정한다(§12).
- R1의 C01 M2·M3 ROOKIE 문장은 재작성으로 대체된다. "+ 1 line" 표현, `tongue`·`gums`·`throat` glossary, dossier 단서 문구가 전 레벨에 나타나야 하는 게이트는 유지한다.
- R1이 바꾼 M1의 탭 영역, 안내 위치, opening은 그대로 쓴다.
- R2·R3는 다른 Case만 바꿔서 충돌이 없다. C08의 `서고 지붕` 줄과 C12의 타임라인 카드 줄은 조사 시점에 R 시리즈가 건드리지 않았다.
- `test/sandbox/s5_seoul_rookie_test.dart`에는 Case 01 참조가 없다. Sora's board 공용 테스트 그룹만 조정한다.
- R4의 "SyllableBoard 실기기 확인" 항목은 재기획 후 M3 기준으로 다시 본다.

### 7.4 작업량

| 묶음 | 내용 | 규모 |
|---|---|---|
| A | Final 전 대화 지원 | 소스 6개, 생성 1개, 테스트 수정·추가(§9). 중간 |
| B | Case 01 plan·levels 재작성 | 3레벨, 약 150줄. 큼 |
| C | dossier, bible, h14·h15 | 중간 |
| D | C08·C12 문장 | 8줄. 작음 |
| E | 재생성·게이트 | 작음 |
| F | 테스트 수정, 3레벨 끝까지 플레이 | 중간 |
| G | §9.3의 테스트 계획과 §11의 검증 조건 | 작음 |

이미지 비용은 $0이고 R2 재업로드도 필요 없다.

## 8. 결정 현황

| # | 결정 | 상태 |
|---|---|---|
| **D1** | 첫 쪽지를 훈민정음으로 변경, C08·C12 문구 수정 | **승인** |
| **D2** | Final A/B 두 단계 | **승인.** 공용 변경은 §11 조건부 |
| **D3** | M1 후보 글자는 칩 라벨 | **승인** |
| **D4** | 구현 위치와 기준점, 미커밋 변경 처리 | **보류.** 임의로 커밋하지 않는다 |
| Final B | 뜻 카드 방식 | **승인** |
| M1 뜻 | 소라의 행동으로 추리 | **승인** |
| **D5** | 서고 지붕 구멍 설정 삭제, 서고와 비는 유지 | 개별 답변 없음. 권장안으로 기획, 구현 지시 때 재확인 |
| **D6** | 연습 글자의 재료: 분필 또는 숯 (둘 다 창작) | 개별 답변 없음. 권장은 숯, 구현 지시 때 재확인 |
| **D7** | M3 세로쓰기 제거 | 개별 답변 없음. 권장안으로 기획, 구현 지시 때 재확인 |
| **D8** | 제목 "The Secret of the King's Letters" 유지 | 개별 답변 없음. 권장안으로 기획, 구현 지시 때 재확인 |

## 9. Final A/B 공용 변경 목록과 테스트 계획

일회용 사본에서 시제품으로 확인한 범위다. 시제품 patch는 세션 임시 폴더에만 있고 저장소에는 없다.

### 9.1 공용 소스

| 파일 | 변경 | 시제품 |
|---|---|---|
| `tool/season_gen/plan_models.dart` | `TalkPartPlan`에 선택 필드 `presents` 추가 (읽기·쓰기) | 적용 |
| `tool/season_gen/schema/mission_plan.schema.json` | `talkPart`에 `presents` 추가. `interview`의 present 정의를 공용 `$defs`로 옮겨 재사용 | 간이 적용 (`type: array`만) |
| `tool/season_gen/generate_case.dart` | `_talkMission`이 `presents`와 `finishWhen`을 생성. `_interview`와 코드 공유 | 적용 (복사본) |
| `tool/season_gen/play_check.dart` | Final의 `talk.before` 허용, `talk.after`는 계속 거부. `presents`가 있으면 `_interview`와 같은 검사 수행 | 허용만 적용. **검사는 미적용** |
| `lib/data/content/puzzle_engine_collisions.dart` | `finalCompanions`에 `talkMissions` 추가 | 적용 |
| `lib/data/content/puzzle_palette.dart` | `evidence_talk`의 `talkMissions` 바인딩 `surfaces`에 `finalMission` 추가 | **미적용** |

- **재생성:** `tool/season_gen/palette_facts.dart`는 `PALETTE_FACTS_WRITE=1 flutter test test/season_gen/palette_facts_test.dart`로 다시 쓴다. 손으로 고치지 않는다.
- **변경 없음:** `final_mission_screen.dart`, `case_talk.dart`, `case_levels.dart`
- **`play_check` 검사의 범위:** `_interview`의 검사(단계 id 중복, `requires`, `finishWhen`, `talk_evidence_unheld`, 카드 2장)를 공용 함수로 분리한다. 이 검사가 없으면 없는 증거 id를 적어도 생성이 통과한다.
- **`mission` 쪽 대화의 `presents`:** 필드는 일반 미션에서도 읽히지만 이번에는 쓰지 않는다. `play_check`에서 Final의 `before`에만 허용해 범위를 좁힌다.

### 9.2 테스트 파일

| 파일 | 변경 |
|---|---|
| `test/puzzle_engine_collisions_test.dart` | §10의 1·4번 수정 |
| `test/season_gen/play_check_test.dart` | 새 규칙 추가 |
| `test/sandbox/single_case.dart` | Final 전 대화 진행 지원 |
| `test/sandbox/s5_seoul_play_test.dart`, `s5_seoul_syllables_test.dart`, `s5_seoul_traces_test.dart` | Case 01 새 내용 |
| 새 Final 시험 | 시제품 시나리오를 정식 테스트로 등록 |

### 9.3 테스트 계획

**새로 넣을 시험**

| 대상 | 확인 내용 |
|---|---|
| `play_check` | Final `talk.before` 허용 / Final `talk.after` 거부 / 일반 미션의 `presents` 거부 / 없는 증거 id 거부 / 잘못된 `requires` 거부 / 카드가 2장이 아니면 거부 |
| 생성기 | `presents` 없는 대화의 출력이 지금과 같음 / 있는 대화는 `finishWhen`이 단계 전체 |
| 검증기 | Final의 `talkMissions` 허용 / 다른 표 `wrong_surface` 유지 |
| 플레이 | R/J/M × 390·320폭: 대화 → 오답 카드(오답 수 0) → e1 재사용 → 앱 재시작 후 대화 위치 복원 → Stage B 오답 → 정답 → 엔딩 → Case Closed |
| 뜻 카드 | `learn,min,right,sound` 등 오답마다 영어 피드백 / 같은 타일 순서 오류는 orderFeedback / 영어 문구에 한글 음절 없음 |
| 레벨 | J/M 대화 문구가 반영됨 / 대화 구조가 세 레벨에서 같음 |

**실행 순서**

1. 공용 변경 후: 관련 단위 테스트 → §11 검증
2. 콘텐츠 변경 후: Seoul 샌드박스 테스트, `flutter analyze`
3. 완료 시: 공용 도구와 검증기를 바꿨으므로 **전체 `flutter test`** (CLAUDE.md §21의 공용 변경 기준). 기존 실패는 기준점의 결과와 비교해 구분한다.
4. 실기기: 320폭 Final B 타일, 한글 칩, 대화 화면

**시제품에서 이미 확인한 것:** R/J/M × 390·320폭 플레이 6건과 `SeasonContentValidator` 통과. 다만 시제품의 임시 문구와 임시 레벨 문장으로 확인한 결과다.

**확인하지 못한 것:** 전체 `flutter test`, 실기기, 글자 크기 확대, §10 수정 후의 통과 여부.

## 10. 기존 가드 테스트 5건

시제품(`finalCompanions`만 수정)에서 실패한 테스트다. 시제품 문구 문제 1건을 빼면 모두 "Final에서 `talkMissions`를 읽지 않는다"는 전제를 기록한 테스트다. **테스트를 지우거나 건너뛰지 않는다.**

| # | 테스트 | 실패 내용 | 원인 | 해결 |
|---|---|---|---|---|
| 1 | `puzzle_engine_collisions_test.dart:167` every table a page reads… | 기대 목록에는 `talkMissions`가 있는데 실제 목록에 없음 | 테스트의 `finalReads`가 `talks, easySteps, endings`만 손으로 더한다. Final 화면은 이미 `talkMissionOfProvider`를 읽는다(`final_mission_screen.dart:971`) | `finalReads`에 `'talkMissions'` 추가. Mission 쪽 목록과 같은 방식이며 실제 동작을 맞추는 수정이다 |
| 2 | `puzzle_engine_collisions_test.dart:209` the palette's engines are where the pages play them | `evidence_talk talkMissions finalMission`: 동반 표에는 있는데 팔레트 표면에 없음 | 팔레트 미수정 | `puzzle_palette.dart`의 `surfaces`에 `finalMission` 추가. **테스트 수정 없음** |
| 3 | `puzzle_palette_test.dart:191` every table is a season's table… | `talkMissions s5_ep01_final`의 표면이 바인딩에 없음 | 2번과 같음 | 2번으로 해결. **테스트 수정 없음** |
| 4 | `puzzle_engine_collisions_test.dart:~414` a table on the other page's slot is never read | `talkMissions`의 `wrong_surface`가 더 이상 나오지 않음 | 이 테스트가 Final의 `talkMissions`를 금지 사례로 쓴다. **승인으로 바뀌는 규칙이다** | 금지 사례를 Mission 전용 표로 교체한다(예: `compares`를 Final 슬롯에). `wrong_surface` 양방향 검사는 그대로 유지한다 |
| 5 | `difficulty_content_test.dart` 36번 | `Who wrote this?`가 페이지 영어에서 안 보임 | `LearningCheck.sceneText`는 대화의 `goal`과 `opening`만 읽고 `presents`는 읽지 않는다. 시제품이 Final의 학습 표현을 그대로 둔 탓이다 | **콘텐츠에서 해결.** `learning.expressions`를 Stage B 편지의 문장으로 쓴다(§3.4). `LearningCheck`는 바꾸지 않는다 |

- 1~4번은 공용 변경과 한 묶음으로 처리한다.
- 4번은 규칙이 바뀌는 유일한 테스트다. 승인 2번(조건부)에 포함된 변경으로 본다.
- 표의 해결책이 모두 통과로 이어지는지는 아직 시험하지 않았다.

## 11. 다른 시즌 무영향 검증 조건

공용 변경의 조건부 승인을 충족하려면 아래를 **전부** 만족해야 한다. 하나라도 어기면 멈추고 보고한다.

**A. 코드 작성 조건**

1. `presents`는 선택 필드다. 없는 계획은 지금과 같은 코드로 생성한다.
2. Final의 대화는 `before`만 허용한다. `after`와 일반 미션의 `presents`는 계속 거부한다.
3. `final_mission_screen.dart`, `case_talk.dart`, 기존 시즌의 계획·레벨 파일은 수정하지 않는다.
4. `wrong_surface` 검사는 다른 모든 표에서 그대로 작동한다.

**B. 생성물 동일성 (공용 변경 직후, Case 01 콘텐츠 변경 전에 실행)**

5. `generate_season.dart --target game --check`가 s3_rome, s4_newyork, s5_seoul 모두 up to date다.
6. `git diff`로 `lib/data/generated/s3_rome`, `lib/data/generated/s4_newyork`의 변경이 0줄이다.
7. Paris와 London은 생성기를 쓰지 않으므로 `lib/data/mock/season1`, `season2`의 변경이 0줄이다.
8. `test/sandbox/generated/`의 샌드박스 시즌(`s3_rome_slice`, `s8_timeline`, `s9_sandbox`)도 재생성 결과가 같다.

**C. 콘텐츠 변경 후**

9. s5_seoul 생성물의 변경은 ep01, ep08, ep12와 그 레벨 파일, 역사·매니페스트 파일로 한정된다.
10. s3_rome, s4_newyork은 다시 `--check` 통과.

**D. 회귀**

11. `SeasonContentValidator.validate`가 모든 시즌에서 문제 없음.
12. 전체 `flutter test`의 실패 목록이 구현 전 기준점의 목록과 같다. 기준점 실패 목록은 구현 시작 때 먼저 기록한다.
13. `flutter analyze` 문제 없음.
14. `season_pack_deploy_test` 통과, 이미지 변경 0건, R2 재업로드 불필요.

**시제품 참고:** 도구 변경 후 Rome·NY·Seoul은 up to date였고, 검증기 변경 후 Rome·NY도 up to date였다. 위 5번의 일부를 사본에서 본 것이고, 구현 때 다시 실행한다.

## 12. 구현 시작 조건

아래가 모두 갖춰지고 **사용자가 별도로 지시**해야 구현을 시작한다.

1. 메인 체크아웃의 진행 중 작업이 끝났다고 사용자가 알린다. 이쪽에서 임의로 판단하지 않는다.
2. 기준점이 정해진다: 어느 체크아웃과 어느 커밋 위에서 작업하는가 (D4).
3. D5~D8을 재확인한다.
4. 기준점에서 전체 테스트 실패 목록을 먼저 기록한다.

**구현 순서:** 공용 변경과 §10의 1~4번 → §11 B → Case 01 콘텐츠 → C08·C12 문구 → dossier·bible → §11 C·D → 보고.

## 13. 구현 결과 (2026-11-07)

컨텐츠 워크스페이스에서 구현했다. 기준점 `4887645`에서 시작했고 현재 HEAD는 `eefecef`다. 겹치는 파일은 `generated.manifest.json` 하나이며, 새 기준에서 `--check` up to date, Seoul 테스트·시즌 플레이스루 240개 통과를 다시 확인했다. 커밋·푸시 없음, 새 이미지 없음, 새 엔진 없음.

### 13.1 실제 퍼즐과 정답

| 단계 | 엔진 | 정답 | 뜻을 얻는 방법 |
|---|---|---|---|
| M1 | `trace_deduction` | `c` (칩 `The path to the kitchen well: 훈`) | 전환 대사 "소라가 밤마다 분이에게 해 주는 일" + "소라가 가르친다". 뜻은 말하지 않고 Final B에서 TEACH·LEARN으로 판정 |
| M2 | `order_sequence`, 타일 9개 | `ㅇ ㅡ ㅁ` | 소라: "목구멍과 입, 이 묶음은 소리" |
| M3 | `syllable_compose`, 위아래 2칸 | `정음` | 2번 칸은 설명 없이 M2 석판 단서로만 채운다. "음이 소리이니 정은 바르다" |
| Final A | 퍼즐 전 세종 대화 | who→e1, how→e2, people→e1 | "새 글자는 누구를 위한 것인가" = 백성 |
| Final B | `order_sequence`, 타일 9개 | `TEACH → 민 → RIGHT → SOUND` | 맞히면 `훈민정음 (訓民正音)`과 "The right sounds, to teach the people" |

### 13.2 기획과 달라진 점

| 항목 | 기획 | 구현 | 이유 |
|---|---|---|---|
| M3 배치 | 두 묶음을 좌우로 | **위아래** (`TOP`, `BOTTOM`) | `columnHeight` 없는 조립판은 한 열로 그린다. 문구도 "one above the other"로 맞췄다. 1446년 규칙으로 주장하지 않는다 |
| M3 오답 | `정은` | `정응` | 받침 후보가 ㅇ·ㅁ뿐이라 `정은`은 만들 수 없다 |
| 엔딩 | 기존 3줄 | 내레이션 1줄 추가: 분이가 반쯤 탄 종이에 네 묶음을 다시 쓴다 | C08에서 "It says 훈민정음"으로 읽히려면 필요하다 |
| Final 편지 | 질문 3개 | 3·4번에 `(Bun-i's note: the right sounds.)` 추가 | RIGHT·SOUND 순서의 근거를 화면에 둔다 |
| 팔레트 | 표면만 추가 | `numberCode`, `matchPairs` 유형도 추가 | 가드 테스트 3번의 진짜 원인. 기준 커밋에서도 실패하던 누락이다(s5_ep02_m3, s5_ep07_m1) |
| `play_check` | Final `before` 허용 | 추가로 Final 대화에는 증거 제시가 필수. 일반 미션의 `presents`, 대화 후 `presents`, `talks` Final과의 병용은 거부. 같은 증거를 두 번 받으면 뒤 질문이 앞 질문을 `requires`해야 함 | 승인 조건 1·3·4번 |
| 가드 4번 | 다른 표로 교체 | `exhibits`를 Final 슬롯에 둔 사례로 교체 | 기존 `wrong_surface` 검사 유지 |
| D5~D8 | 권장안 | 권장안 그대로 반영. 연습 글자는 숯(charcoal, 창작) | 구현 지시에 "D1~D8 반영"으로 포함 |

### 13.3 변경 파일

**공용 (생성기·검증기):** `tool/season_gen/plan_models.dart`, `generate_case.dart`, `play_check.dart`, `schema/mission_plan.schema.json`, `palette_facts.dart`(재생성), `lib/data/content/puzzle_engine_collisions.dart`, `lib/data/content/puzzle_palette.dart`

**콘텐츠:** `content_pipeline/seasons/s5_seoul/cases/s5_ep01/{case.plan,levels}.json`, `s5_ep08`·`s5_ep12`의 같은 두 파일(한 줄씩), `planning/{history_dossier,story_bible,puzzle_selection,quality_report}.json`, `lib/data/generated/s5_seoul/` 8개 (ep01·ep08·ep12와 레벨 파일, 역사, 매니페스트)

**테스트:** `test/puzzle_engine_collisions_test.dart`, `test/season_gen/play_check_test.dart`(규칙 5개 추가), `test/sandbox/single_case.dart`, `test/sandbox/season_playthrough.dart`, `test/sandbox/s5_seoul_play_test.dart`, `test/sandbox/s5_seoul_syllables_test.dart`, 새 파일 `test/sandbox/s5_seoul_case01_test.dart`

**변경 없음:** `final_mission_screen.dart`, `case_talk.dart`, `case_levels.dart`, 이미지, 다른 시즌의 계획·생성물. 이미지 0건이라 R2 재업로드도 필요 없다.

### 13.4 역사 (dossier)

- h14·h15를 추가했다. 2026-11-07에 각 페이지를 직접 받아 본문을 그대로 인용했다(우리역사넷 「세종어제훈민정음」, 한국민족문화대백과 「한글」, 국립국어원, 세종실록 28년 9월 29일).
- 『월인석보』 주석의 옛 한글은 그 페이지에서 일부 글자가 빠져 보여서 그대로 옮기지 않았다. 생략 부분은 `…`로 표시했다.
- 15세기 한글 표기는 사실로 쓰지 않는다. 이름은 오늘날 맞춤법이라고 IN THIS MYSTERY에 적었다.
- REAL HISTORY는 7줄에서 9줄로 늘었다: 이름의 뜻(h14), 한자 訓民正音과 줄임말 정음(h1, h15).

### 13.5 검증 결과

| 검증 | 결과 |
|---|---|
| Case 01 신규 테스트(구조·뜻 비노출·오답·대화 순서·레벨 문구·C08/C12, R/J/M × 320폭 위젯) | 통과 |
| Seoul 샌드박스 테스트 전체, 시즌 전체 플레이스루 R/J/M (`generated_seasons_test`: Seoul·Rome·NY), 학습 표현 검사 | 290개 통과 |
| 생성기·플래너·팩토리·검증기·팔레트·충돌·퍼즐 규칙 등 회귀 묶음 | 771 통과, **2 실패** |
| 위 2 실패 | `puzzle_rules_test`의 timeline 키 검사, `s9_ep01_test`의 카탈로그 기대값. **기준 커밋 사본에서도 같은 이유로 실패한다** |
| §11 B: `generate_season --check` | Rome·NY·Seoul·s9 샌드박스 모두 up to date. Rome·NY 생성물, `lib/data/mock`, `test/sandbox/generated`, `assets` 변경 0줄 |
| `flutter analyze` | 문제 없음. 한글 경로에서는 분석 서버가 죽어서 ASCII 경로 사본에서 실행했다 |
| `plan_season check` | ERROR 3건: C02 M1 조각 이미지 크기(`4887645`에서 들어온 것, 이번 변경과 무관). 그래서 품질 보고서의 생성기 단계가 `generator_skipped`로 기록된다 |
| 전체 `flutter test` | **실행하지 않음** (지시에 따름) |

### 13.6 발견한 기존 버그 (수정하지 않음)

**Final 화면에서 앱 바의 뒤로 버튼으로 지도에 돌아오면, 지도의 "OPEN THE FINAL CASE"가 눌리지 않는다.** 지도는 앱을 다시 열어야 정상으로 돌아온다.

- **재현:** 기준 커밋 사본에서도 같다. 모든 시즌의 Final에 해당한다.
- **원인:** 지도는 Final을 `context.push`로 열고, 그 결과를 기다려 이동 상태(`_goingTo`)를 푼다. 그런데 Final 화면의 뒤로 버튼은 `context.go(Routes.map)`이다(`final_mission_screen.dart` 949, 1003행). 그래서 이동 상태가 풀리지 않고 지도가 입력을 막는다.
- **수정하지 않은 이유:** §11 조건 3번이 이 파일 수정을 금지한다.
- **수정 방향 (제안):** 뒤로 버튼을 `context.canPop() ? context.pop() : context.go(Routes.map)`으로 바꾸고, 회귀 테스트를 추가한다.
- **테스트 처리:** Case 01 위젯 테스트는 뒤로 간 뒤 앱을 다시 열어서, 대화 위치가 유지되는지 확인한다.

### 13.7 남은 위험과 실기기 확인

- 실기기: 320폭 Final B 타일 9개, M1 칩 라벨의 한글, 세종 대화의 카드 2장, M3 위아래 조립판, 글자 크기 확대
- §13.6의 뒤로가기 버그: 이번 대화형 Final은 지도로 돌아가는 일이 많아질 수 있다
- 이름을 이미 아는 아이는 민을 바로 고를 수 있다. 수용한 한계다
- 품질 보고서의 ERROR 3건(C02)이 남아 있는 한 `plan_season generate`는 막힌다. `generate_season`은 영향받지 않는다

## 14. 화면 UX 수정 (2026-11-07)

6가지 화면 조건(320×568, 375×667, 390×844, 430×932, ROOKIE·MASTER 글자 1.3배) 검증 결과에 따른 수정. 정답·퍼즐 엔진·이미지 변경 없음.

| 문제 | 수정 |
|---|---|
| M1 장소 선택 때 혼(학자들의 집)이 화면 밖, 우물 마커가 가장자리에서 잘림 | 새 선택 필드 `traces.choosing`(=`DeductionScene.choosing`): 마지막 흔적을 적으면 화면이 세 장소 범위로 다시 맞춰지고, 그 위의 연필 메모를 지운다. `opening`은 그대로(흔적 찾기 구도 유지). 필드가 없는 장면(London m03·ep04_m2, Seoul C06)은 동작이 같다 |
| M1 마커가 "?"뿐이라 탭해야 혼/운/훈을 알 수 있음 | `places[].chip`(=`DeductionPlace.chip`): 마커 안에 "?" 대신 그 장소의 묶음을 표시. 선택하면 남색 바탕의 금색 글자. 칩은 선택지 라벨에 있는 글자만 쓸 수 있다(`play_check`) |
| M1 추리 화면에 편지 다시 읽기가 없음 | `traces.rereadLetter`(=`DeductionScene.rereadLetter`): 하단에 Reread Letter. Case 01만 켬(London C04는 작은 화면에서 구도가 바뀌어 제외) |
| M2 자모가 작아 ㅡ/ㅗ, ㅇ/ㅁ 구분이 약함 | `SequenceQuestion`: 라벨이 한글 자모 한 글자(U+3131–318E)일 때만 30pt 굵게. 다른 시즌의 순서 타일은 해당 없음 |
| M3 질문("Tap a group")과 종이 안내("Tap a place"), 받침 단계 누락, 단서 "at the bottom"이 BOTTOM 칸과 겹침 | 질문과 단서가 화면 라벨을 그대로 부른다: "Tap TOP or BOTTOM. Then choose FIRST SOUND, LINE, DOT and AT THE BOTTOM.", "Group 1 (TOP): … AT THE BOTTOM: the throat.", "Group 2 (BOTTOM): …". J/M도 같은 방식. 받침은 C02와 엔진 줄 이름("AT THE BOTTOM")에 맞춰 "at the bottom"으로 유지(C02에서 "under it"은 모음의 점을 뜻함) |
| Final A 목표 줄이 320폭에서 잘림, YOU가 세종 초상화의 설명처럼 보임 | `CaseTalk`: 목표 줄 최대 2줄. 말한 사람 이름이 말풍선 가장자리에 붙는다(상대는 왼쪽, YOU는 오른쪽) |
| 정답 직후 새벽 에필로그가 먼저 나오고 이름은 Case Complete에서야 공개 | 엔딩 첫 줄 "The tiles turn over, one by one: 훈민정음 (訓民正音)." 뒤에 새벽 에필로그. Case Complete의 첫 줄은 "훈민정음 (訓民正音): the name of the King's letters."로 바꿔 같은 문장이 두 번 나오지 않게 했다 |

확인만 한 것:
- Final B 상단의 검은 영역은 테스트에서 이미지 디코딩이 끝나기 전이었다(실제 비동기 대기 후 촬영하면 책의 전당 그림이 나온다). 이미지 파일은 바꾸지 않았다.
- Final B 첫 타일까지의 거리: 320×568에서 약 1,470pt(화면 2.6개), 글자 1.3배에서 약 2,010pt. 위에 장소 그림, 이야기 3줄, 택의 쪽지, 질문, 빈 칸 4개가 있다. 기존 레이아웃 안에서 줄일 곳이 없어 그대로 두었다.
- 증거 카드 3장(The Copied Scrap, Sora's Lesson Board, Bun-i's Note)은 이름으로 구분된다. 아이콘은 모두 편지 봉투로 같다.

## 출처

- [국립국어원, 한글의 명칭](https://www.korean.go.kr/hangeul/another/001.html)
- [세종실록 25년 12월 30일](https://sillok.history.go.kr/id/kda_12512030_002)
- [세종실록 28년 9월 29일](https://sillok.history.go.kr/id/kda_12809029_004)
- [우리역사넷: 세종어제훈민정음](https://contents.history.go.kr/mobile/kc/view.do?levelId=kc_r300900)
- [우리역사넷: 한글 창제와 훈민정음](https://contents.history.go.kr/mobile/km/view.do?levelId=km_037_0070_0020_0010)
- [한국민족문화대백과: 한글](https://encykorea.aks.ac.kr/Article/E0061508)
- [국가유산청: 훈민정음 해례본](https://www.heritage.go.kr/heri/html/HtmlPage.do?pg=%2Funesco%2FMemHeritage%2FMemHeritage_01.jsp&pageNo=1_1_2_0)
- [훈민정음 언해 (위키백과, 참고용)](https://ko.wikipedia.org/wiki/%ED%9B%88%EB%AF%BC%EC%A0%95%EC%9D%8C_%EC%96%B8%ED%95%B4)
- [동국정운 (위키백과, 참고용)](https://ko.wikipedia.org/wiki/%EB%8F%99%EA%B5%AD%EC%A0%95%EC%9A%B4)
- 기존 h1~h13의 출처는 `content_pipeline/seasons/s5_seoul/planning/history_dossier.json` 참조
