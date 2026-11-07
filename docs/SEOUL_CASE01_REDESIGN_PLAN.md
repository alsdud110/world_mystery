# Seoul Case 01 전면 재기획 — 훈민정음 네 글자

- 작성: 2026-11-07 · 상태: **기획만. 사용자 승인 전 구현 금지**
- 조사 기준: `/Users/myhwang/flutter-workspace/world_mystery` 작업 트리 (main 28825ff + R1~R3 + C11 M2 미커밋 변경)
- 주의: 이 문서가 있는 컨텐츠 워크스페이스는 28825ff 그대로라서 R1~R3가 없다. 메인 체크아웃의 파일은 읽기만 했다.

## 0. 한눈에 보기

| 단계 | 장소·그림 | 찾는 글자 | 뜻 | 엔진 | 플레이어가 하는 일 | 정답 |
|---|---|---|---|---|---|---|
| M1 | 안문 `gate_courtyard` | **훈** | teach | `trace_deduction` | 흔적 3개를 읽고, 택의 모양 설명과 맞는 장소를 고른다 | `c` |
| M2 | 우물가 `well_yard` | **음** | sound | `order_sequence` | 소라의 판으로 택의 말을 풀어 글자 조각 3개를 고른다 | `ㅇ ㅡ ㅁ` |
| M3 | 글방 `copy_room` | **정** | right | `syllable_compose` | 2음절을 조립한다. 둘째 음절은 M2 단서로 채운다 | `정음` |
| Final A | 서고 `book_hall_rain` | 민의 뜻 | people | 세종 대화 (`CaseTalk`) | 증거를 내밀어 "이 글자는 누구를 위한 것인가"를 밝힌다 | 증거 제시 |
| Final B | 같은 곳 | **민** + 재배열 | — | `order_sequence` | 방해 글자 사이에서 민을 고르고, 뜻으로 네 글자를 줄 세운다 | `훈 민 정 음` |

- **신규 이미지 0장, 신규 퍼즐 엔진 0개.** `syllable_compose`의 "2음절 이상" 제한도 그대로 지킨다.
- **Final 2단계:** 게임 런타임은 이미 지원한다(`final_mission_screen.dart:971`). 생성기만 막고 있어서 도구 쪽을 조금 고쳐야 한다(§5.3). 코드 수정 없는 대안 F1도 있다.
- **다른 Case 수정 필요:** C08과 C12에서 문장 하나씩, 레벨까지 합쳐 8줄(§7.2).

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
2. **M1.** 흔적이 물 나르는 사람을 가리킨다. 소라의 제자 셋이 각자 일하는 곳 근처에 연습 글자를 분필로 써 두었다. 택이 기억한 모양과 맞는 글자는 우물 길의 **훈**이다. 이 글을 쓴 사람은 분이다. 그런데 비가 오면 분필 글씨는 지워진다.
3. **M2.** 소라는 오늘이 분이의 열흘째라고 말한다. 왕의 시험 마지막 과제는 "글자의 이름을 쓰는 것"이었다. 판의 규칙으로 레슨 박스를 열자 분이의 석판에 **음**이 있다. 뜻은 소리다.
4. **M3.** 글방에 분이가 연습하다 지워진 종이가 있다. 두 묶음을 복원하니 "바른 소리"라는 뜻의 **정음**이다. 음이 소리이므로 **정**은 '바른'이다.
5. **Final A.** 비가 내리고, 세종은 새 책을 지키러 서고에 와 있다. 탐정은 세 글자를 내밀고, 왕은 묻는다. "이 글자는 누구를 위한 것인가?" 門을 베낀 쪽지가 답이다. 글을 쓰지 못하던 사람들, 곧 **백성**이다.
6. **Final B.** 택이 기억한 마지막 모양으로 **민**을 찾는다. 이어서 뜻을 따라 줄을 세운다. 무엇을 하는가(훈) → 누구에게(민) → 무엇을(정음). 발견 순서 훈·음·정·민이 **훈민정음**으로 바뀐다.
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
7. **다음 연결:** `"Hun means teach," says a water-carrier. "Sora teaches Bun-i."`
8. **ROOKIE 질문:** `Which place has the writer's group? Tap the place.`
9. **학습:** 많은 사람이 글을 쓰지 못했다는 세종의 서문(h9). 영어 모양 묘사 읽기.
10. **재사용:** 엔진·그림·좌표·스케치 전부 재사용. 코드 변경 없음.
- **단서 출력:** `c1` 유지. 값 `훈`, 노트 `훈 = TEACH. Bun-i carries water. She could not write Chinese characters.` C02·C11이 쓰는 "분이는 물 긷는 사람" 정보가 그대로 남는다.
- **한계:** 분필 글씨는 그림에 없고 칩으로만 보인다. 땅에 보이게 하려면 스케치 추가가 필요하다(D3).

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
3. **질문:**
   - `Who wrote this?` → e1 (대답: `Bun-i. She cannot write Chinese characters.`)
   - `How could she learn in ten days?` → e2 (대답: `Your letters copy the mouth. They are easy to learn.`)
   - `Who are my letters for?` → e1 (대답: `For people like Bun-i. For the people!`)
4. **조작:** 기존 CaseTalk 그대로 증거를 내민다. 틀려도 실패가 아니고 miss 대사가 나온다.
5. **정답:** 세 질문 완료. 플레이어는 네 번째 글자의 뜻이 PEOPLE이라는 것을 스스로 증거로 연결한다.
6. **오답:** `That does not show who the letters are for.` / tell: `The copied scrap shows someone who could not write.`

**Stage B: 민 찾기와 재배열**

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
4. **조작:** 타일 7개(훈 음 정 민 문 만 빈) 중 4개를 순서대로 탭
5. **정답과 근거:** `hun,min,jeong,eum`.
   - 민: ㅁ + ㅣ + ㄴ. 문은 납작한 선, 만은 점이 있고, 빈은 획이 더해졌다.
   - 순서: 훈(teach) → 민(people) → 정·음(right sounds, M3 쪽지에서 붙어 있던 쌍)
   - **문은 M1의 門 쪽지가 되돌아오는 함정이다.**
6. **힌트·오답:**
   - 힌트 1: `Read your clues. Each one says what its group means.`
   - 힌트 2: `Keep the two groups of Bun-i's note together.`
   - 문 포함: `Taek saw a standing line, not a flat one.`
   - 만 포함: `Taek saw no dot.`
   - 빈 포함: `The mouth has no added line here.`
   - orderFeedback: `Those are the right groups. Read the 3 questions again.`
7. **전환:** `The King reads the four groups: 훈민정음.` / `"The right sounds, to teach the people."` / `"That is why I made them."`
8. **ROOKIE 질문:** `Find the last group. Then tap all 4 in order.`
9. **학습:** 이름의 뜻(새 사실 h14), 왜 만들었는가(h5, h9), 열흘(h6)
10. **재사용:** 그림·초상·CaseTalk·`order_sequence` 재사용. 엔딩의 분이·소라 대사 유지.

- **단서 사용 정리:** e1 → Stage A(질문 1·3), e2 → Stage A(질문 2), c1·c2·c3의 뜻 → Stage B 순서, M2의 판 규칙 → 민 판별, M3의 쌍 → 힌트와 순서
- **증거 출력:** `e4`는 "The Name of the Letters"로 바꾼다. 후속 Case 참조가 없어서 안전하다.

### 3.5 네 미션이 서로 다른 이유

| | 추리 재료 | 손의 조작 | 앞 단서 사용 |
|---|---|---|---|
| M1 | 현장 흔적 + 영어 모양 묘사 | 그림 탐색, 장소 선택 | 없음 |
| M2 | 규칙표 해독 | 낱자 타일 선택 | 분이·소라 관계 |
| M3 | 조립 설명 | 음절 조립 | 2번 음절 = M2 답 |
| Final A | 증거와 질문의 연결 | 증거 내밀기 | e1, e2 |
| Final B | 뜻으로 문장 구성 | 음절 타일 배열 | 뜻 3개, 판 규칙 |

## 4. 네 글자의 발견과 재배열

| 발견 순서 | 글자 | 뜻 | 플레이어의 근거 | 저장 위치 |
|---|---|---|---|---|
| 1 | 훈 | teach | 모양 묘사 + 흔적 | `c1` |
| 2 | 음 | sound | 판 해독 | `c2` |
| 3 | 정 | right | 조립 + 소거 (정음 − 음) | `c3` |
| 4 | 민 | people | 증거로 뜻 도출 + 모양으로 글자 판별 | Final |

- **왜 순서가 뒤섞였나:** 택이 "모양은 기억해도 순서는 모른다"고 처음부터 말한다. 탐색 순서는 분이의 물길을 따른 결과다.
- **왜 재배열이 추리인가:** 플레이어가 아는 것은 뜻이다. 답은 이름을 외워서가 아니라 "할 일 → 대상 → 내용"을 영어로 읽어서 나온다.
- **한국어 사용자 주의:** 훈민정음을 아는 플레이어는 재배열을 바로 풀 수 있다. 다만 민 판별은 영어 설명이 있어야 확실하고, 영어 학습 목표는 여전히 달성된다. 이 점은 수용한다.

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
| `guided_steps`는 사용 금지 | 2026-11-06 사용자가 롤백 | 쓰지 않음 |
| 미션 수는 `m1…`와 `final` 슬롯 구조 | `plan_check.dart:196` | 4단계 구조 유지 |
| 같은 엔진 반복은 경고 | `repeatedInCase` (warning) | M2·Final이 `order_sequence`. 경고는 남는다 |

### 5.3 Final 2단계 구현 판단

| 방식 | 내용 | 코드 | 평가 |
|---|---|---|---|
| **F2 (권장)** | Stage A = 퍼즐 전 대화, Stage B = `order_sequence` | 도구 3곳 | 두 단계가 실제로 분리된다 |
| F1 (대안) | 대화 없이 `order_sequence` 한 화면. King의 대사는 story로 옮김 | 없음 | 한 화면에서 두 추리를 다 요구한다. 증거 제시는 사라진다 |

- **런타임:** `_talkBeforeFinal`이 `TalkMission.before`를 `CaseTalk`로 띄운 뒤 일반 Final로 넘어간다. `TalkScene`이라 증거 제시도 받는다. Paris Case 11이 쓰는 경로다.
- **생성기:** 세 곳이 막고 있다.
  1. `play_check.dart:866`: Final의 `talk`를 금지
  2. `MissionTalkPlan`: `presents` 필드 없음
  3. `_talkMission`: 대사만 생성하고 레벨 패치도 대사만 다룬다
- 이 변경은 시즌 공용 도구를 건드린다. 구현 시 Rome·NY `generate_season --check`로 바이트 동일을 확인해야 한다.

## 6. 역사적 사실 검증이 필요한 부분

### 6.1 이번에 확인한 것

| 항목 | 결과 | 출처 |
|---|---|---|
| 뜻: 백성을 가르치는 데 쓸 바른 소리(글자) | 확인 | 국립국어원 |
| 정음이라는 이름도 쓰임 | 확인 | 국립국어원 |
| 正音 표기, "correct sounds for the instruction of the people" | 확인, 단 위키 미러 수준 | 공공기관 출처로 재확인 필요 |
| 글자 이름이자 책 이름 | 2차 자료 확인 | 공공기관 출처로 재확인 필요 |

### 6.2 구현 전 확인할 것

| 항목 | 위험 | 처리 |
|---|---|---|
| **h14 (신규)** 이름의 뜻 | `Teach the people the right sounds`는 어순을 맞춘 풀이다. 정확한 뜻은 "백성을 가르치는 바른 소리"다 | 전환·Reveal에는 `The right sounds, to teach the people`을 쓴다 |
| **h15 (신규)** 정음은 줄임말 | 출처 1건 | 2차 출처 추가 후 `source_checked` |
| **1446년 표기** | 책 제목은 한자 訓民正音이고, 15세기 언해본의 한글 표기는 오늘날과 다르다(동국정운식 한자음). **정확한 옛 표기는 이번 검색으로 확인하지 못했다** | 게임에서 옛 표기를 주장하지 않는다. "오늘날 맞춤법으로 썼다"고 Reveal에 명시 |
| 음절 뜻 | 훈=가르치다, 민=백성, 정=바르다, 음=소리는 한자 뜻이다. 한글 음절 자체에 뜻이 있다고 오해할 수 있다 | Reveal에 "네 글자는 한자 訓民正音을 읽은 소리"라고 적는다 |
| 왕의 시험, 분필, 석판 | 창작 | dossier `fiction`에 등록 |
| 분필의 시대성 | 15세기 궁궐 분필 사용은 미확인 | "charcoal"(숯)로 바꾸는 것을 권장. 아궁이 옆 물 긷는 소녀에게도 어울린다 |
| h3·h10·h4·h11·h12 | 기존 검증 재사용 | ㅎ은 모양으로만 묘사해서 추가 사실이 필요 없다 |
| 문 = 門 | 일반 지식, 게임 진술 없음 | 피드백은 모양만 언급 |

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
| `test/sandbox/s5_seoul_play_test.dart` | 표 이름과 답, 플레이 순서 수정 (33~36, 40 이후) |
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

### 7.3 R1~R3와의 관계

- Case 01의 미커밋 변경은 전부 메인 체크아웃에 있고, 이 재기획은 그 위에서 진행해야 한다. **컨텐츠 워크스페이스에서 구현하면 R1~R3 없는 기준이라 충돌한다.**
- R1의 C01 M2·M3 ROOKIE 문장은 재작성으로 대체된다. R1의 규칙 자체는 유지한다: "+ 1 line" 표현, `tongue`·`gums`·`throat` glossary, dossier 단서 문구가 전 레벨에 나타나야 하는 게이트.
- R1이 바꾼 M1의 탭 영역, 안내 위치, opening은 그대로 쓴다.
- R2·R3는 다른 Case만 바꿔서 충돌이 없다. C08, C12 문장은 R 시리즈가 건드리지 않았다.
- `test/sandbox/s5_seoul_rookie_test.dart`에는 Case 01 참조가 없다. Sora's board 공용 테스트 그룹만 조정한다.
- R4의 "SyllableBoard 실기기 확인" 항목은 재기획 후 M3 기준으로 다시 본다.

### 7.4 작업량

| 묶음 | 내용 | 규모 |
|---|---|---|
| A | 생성기 Final talk 지원 (F2일 때만) | 도구 3곳 + 테스트. 중간 |
| B | Case 01 plan·levels 재작성 | 3레벨, 약 150줄. 큼 |
| C | dossier, bible, h14·h15 | 중간 |
| D | C08·C12 문장 | 8줄. 작음 |
| E | 재생성·게이트 | 작음 |
| F | 테스트 수정, 3레벨 끝까지 플레이 | 중간 |
| G | `flutter analyze`, Seoul 관련 테스트, Rome·NY 동일성. 공용 도구를 바꾸면 전체 회귀 권장 | 작음 |

이미지 비용은 $0이고 R2 재업로드도 필요 없다.

## 8. 구현 전 사용자 승인이 필요한 결정

| # | 결정 | 권장 |
|---|---|---|
| **D1** | 분이의 첫 쪽지 내용을 서고 지붕에서 훈민정음으로 바꾸고, C08·C12 문장을 수정해도 되는가 | 예. 작업 제한상 이번에는 안 건드렸고, 구현 때 승인이 필요하다 |
| **D2** | Final 방식 | F2 (공용 생성기 수정 포함). 도구를 건드리기 싫다면 F1 |
| **D3** | M1 글자 표시 | 칩 라벨(코드 없음)로 시작. 땅에 글자가 보여야 한다면 `TraceSketch`에 3종 추가 (앱이 그리는 글자, 이미지 아님) |
| **D4** | 구현 위치 | R1~R3와 C11 M2를 먼저 커밋한 뒤, 그 위에서 작업 |
| **D5** | 서고 지붕 구멍 설정 | 삭제. 서고와 비는 무대로 유지 |
| **D6** | 연습 글자의 재료 | 분필 대신 숯 |
| **D7** | M3 세로쓰기 제거 | 제거 |
| **D8** | Case 제목 | "The Secret of the King's Letters" 유지 |

## 출처

- [국립국어원, 한글의 명칭](https://www.korean.go.kr/hangeul/another/001.html)
- [Hunminjeongeum Haerye (Wikipedia 미러)](https://www.Wikipedia.com/wiki/Hunminjeongeum_Haerye)
- [훈민정음 언해 (위키백과)](https://ko.wikipedia.org/wiki/%ED%9B%88%EB%AF%BC%EC%A0%95%EC%9D%8C_%EC%96%B8%ED%95%B4)
- [동국정운 (위키백과)](https://ko.wikipedia.org/wiki/%EB%8F%99%EA%B5%AD%EC%A0%95%EC%9A%B4)
- 기존 h1~h13의 출처는 `content_pipeline/seasons/s5_seoul/planning/history_dossier.json` 참조
