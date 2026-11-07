# Seoul (Season 5) ROOKIE 전수조사

- 작성: 2026-11-06 · 기준: `main` 28825ff + **작업 트리의 미커밋 Case 01 변경**(plan·levels·generated, `scene_deduction.dart`) — Case 01은 이미 진행 중인 ROOKIE 축약본을 기준으로 봤다.
- 범위: `s5_seoul` Case 01~12, 48 미션(M1·M2·M3·Final). 조사·보고만 했고 코드·콘텐츠는 바꾸지 않았다.
- 원본: `content_pipeline/seasons/s5_seoul/cases/s5_epNN/case.plan.json`(ROOKIE 문구 = plan 문구), `levels.json`(JUNIOR/MASTER = `lines[].junior/master`), ROOKIE 단어 풀이 = `lib/data/generated/s5_seoul/s5_epNN.g.dart`의 `glossary`.
- 대상 독자: 한글을 아는 8~12세 한국 어린이. 그래서 한글 조합 자체는 쉬운 부분이고, **영어 설명을 읽어 내는 일**이 난이도를 정한다고 보고 판정했다.

## 0. 조사 방법과 코드 근거

| 확인한 것 | 근거 |
|---|---|
| 힌트 수 | **미션당 최대 2개**(`AppConstants.maxHints = 2`, `lib/core/constants/app_constants.dart:90`; `GameController.useHint`가 2에서 멈춤). 1번 무료, 2번 코인(`tip_shop.dart`). **"힌트 3"은 게임에 없다.** 이 보고서에서 3단계 역할은 오답 피드백(`feedback`/`orderFeedback`/선택지 `feedback`)으로 봤다. |
| 편지 화면 생략 | `PuzzleEngineDispatch.skipsLetter`(`lib/data/content/puzzle_engine_collisions.dart:142`): `deductions·explores·inspections·talks·dialogues·records`는 편지 페이지 없이 장면 안에서 읽는다. 이 미션들은 편지 단어를 "첫 조작 전" 수에서 빼고 장면 과제 문장(task)만 셌다. |
| 타임라인 판정 | `timeline_rules.dart`: 고정 카드(anchor)는 처음부터 제자리, 남는 순서가 하나뿐인지 `_ambiguity` 검사가 있다 → 순서 모호성으로 막히는 미션은 없음. |
| 시간 입력 | `codeFormat: "time"`은 H:MM으로 표시(`puzzle_palette.dart:268`) → C06 M3·C09 M1의 0650/0100은 "6:50/1:00"으로 보인다. |
| 증거 회수 카드 | `EvidenceRecallDock`은 퍼즐 동안 하단에 증거 카드를 띄우고, 카드는 `inscription ?? description`을 보여 준다(`lib/widgets/evidence_card.dart:183`). |
| 단어 수 | 자동 집계(스크립트 아래 부록). **첫 조작 전** = 도착 story + 퍼즐 전 대화(talk.before·goal) + 편지(생략 엔진 제외) + 장면 task/guide/arrival + 대화 opening + question + prompt. 퍼즐을 풀면서 읽는 줄(흔적 문장, 증인 답, 카드 문장)은 넣지 않았다. 고유명사·숫자도 영단어로 셌다. |
| 탭 수 | 엔진별 최소 조작 추정(대화 넘김 탭 제외). 다이얼은 자리마다 ▲▼ 버튼(`final_mission_screen.dart:_Dial`). |

**코드만으로 판단 못 한 UI(실기기 확인 필요)는 표에서 `[UI?]`로 표시했다.**

## 1. 결과 요약

| 등급 | 개수 | 미션 |
|---|---|---|
| **P0** | **1** | C11 M2 |
| **P1** | **10** | C01 M2 · C02 M1 · C02 M2 · C05 M2 · C05 F · C06 F · C07 M2 · C09 M2 · C10 F · C11 M3 |
| **P2** | **19** | C01 M3 · C02 F · C03 M1 · C03 F · C04 M1 · C04 M3 · C04 F · C06 M1 · C07 M1 · C08 M2 · C08 M3 · C08 F · C09 M1 · C09 M3 · C09 F · C10 M3 · C11 M1 · C11 F · C12 M3 |
| **OK** | **18** | C01 M1 · C01 F · C02 M3 · C03 M2 · C03 M3 · C04 M2 · C05 M1 · C05 M3 · C06 M2 · C06 M3 · C07 M3 · C07 F · C08 M1 · C10 M1 · C10 M2 · C12 M1 · C12 M2 · C12 F |

전체 그림:

- **퍼즐 구조는 대부분 건강하다.** 48개 모두 제시된 단서로 정답을 낼 수 있고, 오답 피드백이 흔한 실수를 짚는다. 고칠 것은 대부분 *읽을 양*과 *말투*다.
- **ROOKIE가 JUNIOR/MASTER보다 별로 짧지 않다.** Case 01을 빼면 ROOKIE의 첫 조작 전 단어 수는 JUNIOR보다 평균 5~10% 적을 뿐이고, 몇 개는 오히려 더 길다(C05 F R135/J133/M130, C02 M3 R93/J90, C09 M2 R119/J117, C10 F R102/J101). JUNIOR/MASTER는 같은 길이로 어휘만 바꾼 셈이라, ROOKIE는 "가장 쉬운 단어"이긴 해도 "가장 짧은 글"은 아니다.
- **첫 조작 전 ROOKIE 단어 수**: 43(C07 F) ~ 150(C02 M1). 120어가 넘는 미션이 10개(C01 M2 138, C02 M1 150, C02 M2 149, C03 M1 128, C05 M2 140, C05 F 135, C07 M2 127, C08 M2 129, C11 M2 143, C11 M3 140).
- **한글 조합 퍼즐 3종(C01 M3·C02 M2·C11 M2)과 자음 고르기(C01 M2)는 같은 영어 체계를 쓰는데, 용어가 Case마다 다르다**: C01은 "+ 1 line"(미커밋 축약본), C02·C11은 "one step stronger / two steps stronger". 핵심 단어 `gums`·`tongue`는 어느 Case의 ROOKIE 단어 풀이에도 없다(C01은 `throat`만 있음).

## 2. Case별 표

열: **단어 수** = ROOKIE 첫 조작 전(JUNIOR/MASTER). **풀이 방법**에 예상 최소 탭 수.

### Case 01 — The Secret of the King's Letters (작업 트리의 미커밋 축약본 기준)

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 흔적 추리 | c 부엌 우물 길 | 흔적 3개(門 베낀 종이·젖은 원·물방울) 탭 → 장소 탭. ~4탭 | 61 (79/75) | 지시 "Tap 3 marks on the ground. Then tap a place."가 명확함. 힌트 1 = 조작 안내, 힌트 2 "Who carries water in the palace?"는 정답에 다가감. 오답 피드백 2개 적절. | OK | — |
| M2 자음 5개 순서 | ㅅ ㄱ ㅈ ㅂ ㅇ | 소라 판(5대응+가획 예시)과 택의 기억(4그룹)을 대조 → 9타일 중 5개 순서대로. ~6탭 | **138** (179/187) | ① 편지 18줄로 읽을 양 최다. ② TAEK REMEMBERS는 **4그룹인데 답은 5글자**(4번 "The mouth + 1 line. The throat under it." = ㅂ+ㅇ) → "Tap them in Taek's order"와 어긋나 보임. ③ 힌트 2 "ㄴ becomes ㄷ, not ㅌ"는 실제로 필요한 ㅅ→ㅈ이 아닌 다른 예시라 정답 유도가 약함. ④ `gums`·`tongue` 단어 풀이 없음. | P1 | 택의 4번을 "4. The mouth + 1 line. 5. The throat."로 나눠 5줄 = 5타일. 힌트 2를 "The teeth + 1 line: ㅅ gets one more line."처럼 실제 그룹으로. glossary에 gums·tongue 추가. 판의 ㄴ+2 lines=ㅌ 줄은 방해 타일(ㅊ·ㅍ) 판단에 필요하므로 유지. |
| M3 음절 조합 | 서고지붕 | 4자리 각각 초성·모음(줄+점)·받침 선택, 세로쓰기(오른쪽 열부터). ~17탭 | 77 (165/154) | 영어는 짧아졌으나 "Two groups a column."(문법 생략), "Dot = sky. Flat line = earth. Standing line = person."은 추상적이고 조작에 쓰이지 않음. 힌트 1·2가 자리를 직접 알려 줌(좋음). 탭 수가 시즌 최다권. [UI?] 320px에서 SyllableBoard 칸 크기. | P2 | "Two groups in each column."으로. 하늘·땅·사람 줄은 이야기용으로 남기되 story 마지막이 아닌 성공 후로 옮기면 첫 조작 전 부담 감소. |
| Final 증거 대화 | open | 질문 3개에 증거 1개씩(각 2개 중 택1). ~6탭 | 55 (57/59) | 힌트 2가 증거 3개 이름을 다 줌. 짧고 명확. | OK | — |

### Case 02 — The Turtle Ship Before Dawn

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 어두운 창고 수색 | bucket | 보고서 3줄의 위치(under/next to/on)로 물건 3개 찾기 → "위험을 보여 주는 것" 선택. ~6탭 | **150** (158/158) | ① 시즌 최다 단어. story 3 + 대화 3 + 보고서 5줄 + arrival 2 + task + question이 다 첫 조작 전. ② **보고서 줄(letter)과 수색 화면 reportLine이 같은 문장의 반복.** ③ "Quartermaster", "danger to the powder"(추상). 힌트 2가 "What came through the roof?"로 잘 유도. | P1 | arrival 2줄과 story 1줄 삭제, 함 이름 앞 직함 생략("Ham, the store keeper"), question을 "Which thing can ruin the powder?"로. 보고서는 한 곳에서만 보여 주기(현재 구조 유지 시 letter를 짧은 요약으로). |
| M2 음절 조합 | 거북선 | 소라 판 대응 + 그룹 3개 설명 → 왼쪽부터 3자리 조합. ~13탭 | **149** (157/162) | ① 편지 6줄, 그룹 설명 한 줄이 최대 20어("Group 2: the mouth, one step stronger. A flat line, with a dot under it. The back of the tongue at the bottom."). ② 판은 "A stronger sound adds one line", 그룹은 "one step stronger" → 같은 뜻 다른 말. ③ `gums`·`tongue` 풀이 없음. 정답은 사건 맥락(거북선)으로 짐작 가능해 추리 부담은 낮음. | P1 | 용어를 C01과 같게 "+ 1 line"으로 통일. 그룹 줄을 "Group 2: the mouth + 1 line. Dot under a flat line. Bottom: the back of the tongue." 정도로. glossary 보강. |
| M3 수 입력 | 12 | 4통 × 3번. 2자리 + 확인. ~3탭 | 93 (90/96) | 계산 1단계, 힌트·오답 피드백(04/03/07) 모범적. JUNIOR보다 길다(93>90)는 점만 어색. | OK | (선택) story 3줄째 축약. |
| Final 글자 자물쇠 | DRAGON | 제독의 말 5줄 → 6타일 배열. ~7탭 | 103 (111/108) | 정답 단어가 편지에 그대로("a dragon's head") + 힌트 1이 그 줄을 지목 → 추리 거의 없음. "Knives and spikes stand on the roof, with a narrow path for my men."(14어)은 풀이에 불필요. | P2 | 불필요한 2·3줄 삭제. 추리를 살리려면 "not a turtle's head. It breathes fire in old stories." 식으로 단어를 직접 쓰지 않는 단서로(정답·증거 문구 불변 조건 확인 필요). |

### Case 03 — The Crane That Lifts Stones

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 타임라인 | start,lift,copy,note,fail | 카드 6장(버림 1: RICE) 배열, 1794·THIS MORNING 고정. ~7탭 | 128 (138/134) | 작업 일지 5줄이 **정답 순서 그대로** 적혀 있어 until/after 추리가 필요 없다. 질문 "Was the machine broken, or changed?"는 배열과 별개의 추상 질문. | P2 | 일지 줄 순서를 섞기(관계 문장 유지) 또는 그대로 두고 story를 줄여 단어 수만 감축. |
| M2 그림 고르기 | gate_wheels | 정약용의 설명 4줄 → 그림 3장 중 택1(이름 숨김). ~1탭 | 80 (87/91) | pulley·beam은 glossary 있음. 두 조건(도르래 두 곳·바퀴 양쪽)을 대조하는 좋은 관찰 퍼즐. | OK | — |
| M3 순서 | tie,hook,turn,rise | before/after 문장 → 6개 중 4개. ~5탭 | 73 (81/84) | 편지 순서가 뒤섞여 있어 진짜 추리, 방해 2개는 마지막 줄이 배제. 오답 피드백 정확. | OK | — |
| Final 다이얼 | 1796 | 1794년 1월 + 2년 8개월 → 1796. ▲▼ 4자리. ~9탭 | 80 (88/87) | "two years and eight months later" 월 계산은 8~12세에 한 단계 어려움(힌트 2가 보완). 질문의 "Hwaseong Fortress"는 이 미션 화면에 처음 나오는 이름(story는 Suwon·the wall). | P2 | question을 "Turn the dials to the year the wall was finished."로. 계산 줄을 "Today, two years and eight months later, the work is done."처럼 시점 명확히. |

### Case 04 — The Palace of a Thousand Logs

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 돋보기 + 단어 | GATES | 통나무 끝 표식 비교 → 새 획 찾기(다) → 획 빼면 나 → 판에서 "palace gates" → 입력. ~4탭+타이핑 | 83 (89/86) | 좋은 2단계 추리. 다만 question이 두 문장 결합("Find the log with a new line. Before the new line, where was it going?")이고 편지 6줄에 판·쪽지·소라 판이 섞임. | P2 | question을 "Which log has a new line? Take the line away: where was it going?"로. |
| M2 수 입력 | 10 | 16 − 6 (또는 나 10 → 0). ~3탭 | 75 (79/76) | 두 길 모두 10, 피드백 16/06 적절. | OK | — |
| M3 타임라인 | burn,ruins,begin,coin,logs | 카드 6장(버림: KING MOVES IN). ~7탭 | 103 (109/107) | C03 M1과 같이 두리의 말이 정답 순서대로. 힌트 2 "Set aside what has not happened yet."의 set aside는 어려운 구동사. | P2 | 힌트 2 → "The King has not moved in yet. Put that card away." |
| Final 증거 대화 | rebuilt | 질문 4개에 증거(2개 중 택1). ~8탭 | 59 (62/61) | question "Who wrote the note, and who took the logs? …"는 실제 4개 질문(표식·수·쪽지·비용)과 맞지 않음. "Then no one person wrote them all."(3번 답)은 아이에게 추상적. | P2 | question → "Answer the Daewongun's four questions with your evidence." 하나만. |

### Case 05 — The Lights of Geoncheonggung

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 장면 탐색 + 선택 | belt | 쪽지 찾기 → 기계 → 그림 3개 중 택1. ~4탭 | 56 (58/60) | 쪽지가 답을 직접 말하지만 "did NOT touch" 2개 배제가 들어가 ROOKIE에 적당. 잠금 안내(lockedLine/unreadLine)가 친절. | OK | — |
| M2 타임라인 | lit,lamphouse,dark,gate,hall,back | 카드 7장(버림: MAIN GATE), 8:00·9:00 고정. ~9탭 | **140** (148/142) | 진술 7줄, 배치 카드 4장 + 버림 1. 줄 순서가 거의 정답 순서. 힌트 1의 "account"는 ROOKIE에 어려운 단어(편지엔 "tells you"). | P1 | 진술에서 "They are far away." 등 보충 문장 정리, story 1줄 삭제, 힌트 1 "Find first, after and before in Lady Han's words." |
| M3 수 입력 | 37 | 큰 매듭 3×10 + 작은 7. ~3탭 | 91 (93/97) | 규칙 한 줄 + 개수 한 줄로 명확, 오답 피드백 10/30/73 모범적. | OK | — |
| Final 단어 입력 | JAPAN | 한 부인의 말에서 두 나라 중 "막는" 쪽. 타이핑 | **135** (133/130) | ① ROOKIE가 MASTER보다 김. story 4줄 + 편지 6줄. ② "Japan's power in Korea is growing", "hold back Japan's power", "want her out of the way" — 8~12세에 추상적 정치 표현. 단, prompt가 편지 문장을 거의 그대로 반복해 글자 맞추기로는 풀린다. | P1 | 편지 앞 3줄(이미 수첩에 있는 사실) 삭제. "Japan wants to rule Korea. The Queen asks Russia for help against Japan."처럼 구체 동사로. prompt "The Queen stands against ____." 검토. |

### Case 06 — The Emperor's Secret Letter

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 흔적 추리 | b 오래된 소나무 구멍 | 흔적 3개 → 장소 3곳 중 택1. ~4탭 | 64 (70/71) | 흔적 문장에 `moss`·`knelt`·`silk`·`bark at hand height`, story에 `dusk`. hollow·bark은 glossary에 있으나 **moss·knelt·dusk·silk는 없음**. | P2 | glossary 추가, "Someone knelt there." → "Someone sat down there." |
| M2 순서 | library,well,west_gate,lane | First/After/Then/Last + 피할 곳 2개. ~5탭 | 94 (101/98) | 신호어가 분명하고 방해 2개 배제 추리가 좋음. 오답 피드백 2개. | OK | — |
| M3 시간 입력 | 6:50 | 6:40 + 10분. ~5탭 | 69 (71/73) | H:MM 표시로 입력 명확. 피드백 3개. | OK | — |
| Final 글자 자물쇠 | FORCED | 빈칸 "It was ______ on Korea." + 6타일. ~7탭 | 74 (84/81) | 타일 = 정답 글자뿐이라 **단어를 모르면 6글자 애너그램**. "forced on"은 숙어, `treaty`·`signed freely`도 어려움. 힌트 2 "made to happen, with no free choice"도 추상적. | P1 | 빈칸 문장을 "Japan ______ Korea to sign it." 식 동사로(답 FORCED 유지), 힌트 2 → "It starts with F. It means 'made someone do it'." |

### Case 07 — Two Reports from Harbin

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 기록 대조 | called:called | 두 신문 4줄씩 비교 → 다른 줄 양쪽 탭 → 확인. ~5탭 | 67 (72/68) | 힌트 2가 "Look at the last line."으로 사실상 정답. `hurrah` glossary 있음. **[UI?] 값 "KOREA, HURRAH!"는 14자** — 기록 엔진은 320px에서 13자 이하 값이 9~11px로 줄어든다는 기존 측정이 있어 잘림·축소 확인 필요. | P2 | 실기기 320px 확인. 힌트 2 → "Three lines are the same. Which one is not?" |
| M2 타임라인 | open,platform,noon,tea,write,print | 카드 7장(버림: GOODS TRAIN), 7:00·12:00·5 PM 고정. ~7탭 | **127** (131/127) | 진술 7줄에 시간 표현 혼재(7:00, That morning, 12:00, 5:00 PM), "goods train"(화물열차)·"It does not matter."(왜 나왔는지 혼란). 진술 순서가 정답 순서. | P1 | goods train 줄을 "A train with only boxes came too."로, story 1줄 삭제. 힌트 2 "set it aside" → "Put it away." |
| M3 단어 입력 | KOREA | "Korea, hurrah!"에서 나라 이름. 타이핑 | 80 (87/80) | 짧고 명확, 오답 피드백(MONEY/HIMSELF/HARBIN) 좋음. | OK | — |
| Final 증거 대화 | for_korea | 질문 3개에 증거. ~6탭 | 43 (47/46) | 시즌 최소 단어. 3번 답 줄의 envoys·The Hague는 듣기만 하는 대사. | OK | — |

### Case 08 — The Fire on the Hill

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 증인 비교 | april_first | 3명에게 day 질문 → 같은 답 2개 비교 → 표 씨에게 who. ~10~12탭 | 53 (55/62) | 탭이 많지만 엔진 안내(guide·compareHow·thenHow)가 단계마다 있음. 답이 1인칭 짧은 문장. | OK | — |
| M2 순서 | fire,walk,full,march | 역순으로 적힌 계획 → 5개 중 4개(버림: bell). ~5탭 | 129 (144/148) | 추리가 좋음(night before → morning → full → march). 단어 수가 많은 이유는 story·대화 6줄(independence 포함). | P2 | story 1줄("It is closed now.") 삭제, 대화 1줄 축약. |
| M3 이름 입력 | GYEONGSUN | 공책 3개 중 물방울 표식 → 이름 타이핑 | 101 (104/103) | 추리 명확. 다만 **로마자 9글자 이름 타이핑**은 ROOKIE에 조작 부담(대안 표기 3종은 허용). | P2 | 편지 공책 줄을 "Gyeongsun's notebook: …"처럼 이름을 줄 맨 앞에 두는 현 구조 유지, 입력칸에 글자 수 표시 여부 [UI?] 확인. |
| Final 다이얼 | 311 | 3월 마지막 밤 31 + 4월 1일 → "31"+"1". ▲▼ 3자리. ~5탭 | 91 (98/103) | 두 날짜를 이어 붙이는 규칙("First two dials … Last dial")이 한 단계 추상적. 힌트 2가 31을 거의 알려 줌. 피드백 "012"(표 씨의 날)는 뜻이 불분명. | P2 | 추리(4월 1일의 전날 = 3월 31일)는 유지. 편지 순서를 "The sign burns the night before the march." → "March has thirty-one days." → 다이얼 규칙 순으로 바꿔 생각 순서대로 읽히게 하고, 피드백 "012" 문구를 실제 오답 뜻에 맞게 정리. |

### Case 09 — The Spy in the Shanghai Office

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 시간 입력 | 1:00 (0100) | 11시 + 양초 4시간의 반 = 2시간 → 자정을 넘김. ~5탭 | 95 (101/103) | 자정 넘김 계산 + "Count the hours, then put in the time as a number."(질문 18어). H:MM 표시와 오답 피드백(13:00/23:00/03:00)이 보완. | P2 | question → "What time did the light go out?" |
| M2 수색 + 선택 | paper | 보고서 위치로 3개 찾기 → 베낀 증거 선택. ~6탭 | **119** (117/123) | ① ROOKIE가 JUNIOR보다 김. ② "Provisional Government"(story), "The Police Bureau", "window sill", "common office ink", "Names are pressed into it."(눌린 자국 개념) — exile·sill은 glossary 있으나 **bureau·pressed 없음**. ③ C02 M1과 같은 보고서 중복. | P1 | story 1줄째 → "The government office is upstairs." 서명 "— Kim Gu's police". "pressed into it" → "You can see names on it, pressed in by a pen." |
| M3 이름 입력 | NAM GIHO | 1시 이후 나간 사람(1:15). 타이핑(NAM만도 허용) | 105 (116/117) | "half past eleven", "a quarter past one" 시각 영어가 퍼즐의 핵심 — 학습 목표로는 좋지만 ROOKIE엔 숫자 병기가 필요. | P2 | "a quarter past one (1:15)"처럼 괄호 숫자 병기는 ROOKIE만. |
| Final 증거 대화 | protect | 질문 4개에 증거. ~8탭 | 59 (60/66) | 4번 "So why does a government in exile need police?" 추상적. 1·4번 모두 같은 증거(e2)가 정답이라 혼란 가능. | P2 | 4번 prompt → "Why does your government need police?" |

### Case 10 — The Two Watches

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 순서 | eat,swap,goodbye,alone | At the end / Before that / first / After → 5개 중 4개(버림: buy). ~5탭 | 115 (128/124) | 역순 신호어 추리가 좋고 버림 근거("He did not buy it this morning.")도 명시. | OK | — |
| M2 그림 고르기 | new_watch | 교환 후 김 씨는 윤 씨의 새 시계. ~1탭 | 90 (95/103) | 이전 미션 결과를 쓰는 좋은 연결 추리. | OK | — |
| M3 글자 자물쇠 | DROP | 4타일. ~5탭 | 70 (75/75) | 답이 편지 문장 끝 단어 그대로("a small water drop. The lock wants the last word."), 힌트 2는 정답 노출. 추리가 없다. | P2 | "The lock wants the last word."를 빼고 "Its word is our mark." 만으로 충분(시즌 내내 본 표식). |
| Final 연도 입력 | 1932 | 영어로 쓴 연도 두 개 중 윤봉길의 날. ~5탭 | 102 (101/106) | ① 편지 5줄 중 3줄이 12어 이상. ② `attacked`·`ceremony`·`arrested`(glossary 있음)와 "saw our fight in a new way"(추상). ③ question 15어. 연도 단어 읽기 자체는 좋은 영어 과제. | P1 | question → "Which year did China begin to help strongly?", 4번째 줄 삭제 또는 "After that day, China began to help us." 한 줄로 병합. |

### Case 11 — The Poet's Three Copies

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 돋보기 + 단어 | WATER | 빨간 책등 사전 찾기 → 아래 쪽지 → "drop of ____" 입력 | 100 (113/112) | 추리는 쉬움(Bun-i의 물). 단어 수가 많고 같은 정보 반복(story "Nothing is written on the dictionary's cover" + 편지 "My dictionary was moved"). | P2 | story 3줄째 삭제. |
| M2 음절 조합 | 피아노안 | 그룹 4개(초성은 신체 부위 + 가획 2단계), 세로쓰기. ~18탭 | **143** (152/167) | **ROOKIE 단독으로 단서에서 도출 불가.** 편지에 신체 부위→자음 대응표가 없다(C02 M2는 편지에 있음). 회수 증거 카드(s5_ep01_e2)의 description도 "The first letters copy the tongue, the mouth, the teeth and the throat. A stronger sound adds a line."뿐이라 mouth=ㅁ, throat=ㅇ, gums=ㄴ을 알려 주지 않는다. 힌트 1 "Look at Sora's board"는 **화면에 없는 판**을 가리킨다. 10개 Case 전의 기억 또는 한글 모양 짐작에 기대야 함. 그 위에 "two steps stronger", 7줄 편지, 4그룹 세로쓰기가 겹친다. story "Only a person that knows…"는 문법 어색. | **P0** | 편지에 C02처럼 대응표 3줄(ㅁ = the mouth, ㄴ = the tongue on the gums, ㅇ = the throat) 추가, "two steps stronger" → "+ 2 lines". 힌트 1 → "The mouth is ㅁ. Add two lines." (증거 문구는 시즌 공통이라 바꾸지 않는다.) |
| M3 수 입력 | 319 | 사본 3 + (18+1=19)를 "나란히". ~4탭 | **140** (144/145) | ① story 3 + 대화 3 + 편지 6줄. ② "two numbers, side by side" 이어 붙이기 + 덧셈 2단계. ③ "a man from the office is checking rooms tonight"는 풀이와 무관. 오답 피드백 3개는 좋음. | P1 | 편지 2번째 줄 삭제, "side by side" → "First the copies, then the poems: like 2 and 15 → 215." 같은 예시 1줄(정답 노출 없는 예시). |
| Final 단어 입력 | KOREAN | Yun의 원고가 어떤 언어인지. 타이핑 | 88 (94/96) | "Korean became only a choice subject in the schools"(choice subject 추상). 오답 피드백 4개 우수. | P2 | 1번째 줄 → "In 1938, schools stopped teaching in Korean." |

### Case 12 — The Day the Light Returned

| Mission | 정답 | 풀이 방법 | 단어 수 | 문제점 | 등급 | 개선안 |
|---|---|---|---|---|---|---|
| M1 장면 탐색 + 선택 | one_strap_lock | 쪽지 → 트렁크 3개 중 끈 1개 + 둥근 자물쇠. ~4탭 | 80 (89/92) | 두 조건 교차 관찰 퍼즐의 모범. 힌트 단계적. | OK | — |
| M2 타임라인 | bun_i,seok,okbun,duri,gyeongsun,miri | 6명 쪽지 + 버림 1(그림), 1446·1941 고정, before/after 사슬. ~8탭 | 114 (118/124) | 시즌을 회수하는 좋은 마무리. 관계 문장 3개가 순서를 유일하게 정함. | OK | — |
| M3 수 입력 | 815 | 8월 = 8, 15일, 월 먼저. ~4탭 | 107 (118/119) | 라디오 문장 "Japan has surrendered to the Allies."는 풀이에 불필요한 어려운 문장(glossary는 있음). | P2 | 라디오 줄 → "The war is over! Today is the fifteenth of August." |
| Final 글자 자물쇠 | LIGHT | 광 = opposite of dark → 5타일. ~6탭 | 75 (79/82) | 쉬운 반의어 추리, 모은 타일로 완성하는 시즌 Final Mission 구조. | OK | — |

## 3. Case별 난이도 요약

| Case | 등급 분포 | 한 줄 요약 |
|---|---|---|
| 01 | OK 2 · P1 1 · P2 1 | 미커밋 축약으로 M1·M3이 짧아졌으나 M2 자음 판이 여전히 무겁고 그룹 수(4)와 답(5)이 어긋남. |
| 02 | OK 1 · P1 2 · P2 1 | 시즌에서 가장 읽을 양이 많은 Case(M1 150, M2 149). 용어 "one step stronger"가 C01과 다름. |
| 03 | OK 2 · P2 2 | 퍼즐 다양하고 건강. M1 일지가 정답 순서 그대로라 추리가 비어 있음. |
| 04 | OK 1 · P2 3 | 2단계 추리(M1)가 좋음. 질문 문장 정리 수준. |
| 05 | OK 2 · P1 2 | M2 진술 7줄, Final의 정치 추상어("hold back power")가 ROOKIE에 무거움. |
| 06 | OK 2 · P1 1 · P2 1 | Final FORCED가 숙어 + 애너그램이라 어휘를 모르면 막힘. |
| 07 | OK 2 · P1 1 · P2 1 | 기록 대조·증거 대화는 쉬움. M2 진술이 길고 "goods train"이 혼란. [UI?] 기록 값 14자. |
| 08 | OK 1 · P2 3 | 증인 비교·역순 계획 추리 좋음. 이름 타이핑·날짜 이어 붙이기 조작 부담. |
| 09 | P1 1 · P2 3 | 정부·경찰 용어(Provisional, Bureau, exile)와 시각 영어(quarter past)가 몰림. |
| 10 | OK 2 · P1 1 · P2 1 | M1·M2 추리 좋음. M3 DROP은 추리 없음, Final 문장이 길고 어려움. |
| 11 | P0 1 · P1 1 · P2 2 | **가장 우선.** M2가 화면에 없는 대응표에 의존. M3 이어 붙이기 + 덧셈. |
| 12 | OK 3 · P2 1 | 시즌 마무리 구조가 깔끔. 라디오 문장만 정리. |

## 4. 가장 심각한 미션 TOP 10

| 순위 | 미션 | 등급 | 핵심 이유 |
|---|---|---|---|
| 1 | C11 M2 음절 조합 | P0 | 신체 부위→자음 대응이 화면 어디에도 없음(편지·증거 카드 모두), 힌트 1이 보이지 않는 판을 가리킴 |
| 2 | C02 M2 음절 조합 | P1 | 149어, 20어짜리 그룹 문장, C01과 다른 용어, gums/tongue 풀이 없음 |
| 3 | C02 M1 창고 수색 | P1 | 시즌 최다 150어, 보고서 문장 중복 |
| 4 | C01 M2 자음 5개 | P1 | 138어, 4그룹/5글자 불일치, 힌트 2가 엉뚱한 예시 |
| 5 | C05 Final JAPAN | P1 | 135어(MASTER보다 김), 정치 추상 표현 |
| 6 | C11 M3 319 | P1 | 140어, 이어 붙이기 + 덧셈 2단계, 무관한 문장 |
| 7 | C06 Final FORCED | P1 | 숙어 "forced on" + 6글자 애너그램 |
| 8 | C05 M2 타임라인 | P1 | 140어, 7줄 진술, 힌트의 "account" |
| 9 | C10 Final 1932 | P1 | 12어 이상 문장 3개, 15어 질문 |
| 10 | C09 M2 경찰 보고서 | P1 | Provisional/Bureau/pressed, JUNIOR보다 김 |

(11위 C07 M2 — 고정 카드 3장이 있어 조작은 쉬운 편이라 10위 밖.)

## 5. ROOKIE에서 반복되는 어려운 영어 표현

| 표현 | 나오는 곳 | 문제 | 제안 |
|---|---|---|---|
| the back of the tongue / the tongue on the gums | C01 M2·M3, C02 M2, C11 M2 | 퍼즐 핵심어인데 `tongue`·`gums` glossary 없음 | C01·C02·C11 glossary에 추가 |
| one step stronger / two steps stronger | C02 M2, C11 M2 (C01은 "+ 1 line") | 같은 규칙에 다른 말 | 시즌 전체 "+ 1 line / + 2 lines"로 통일 |
| set (it) aside | C04 M3·C07 M2 힌트 | 구동사 | "Put it away." |
| …, then put in the time/number as a number | C09 M1, C02 M3, C04 M2 | 질문이 길어짐 | 질문만 남기고 입력 안내는 UI에 맡기기 |
| hold back ~'s power / forced on / signed freely / in exile / surrendered to the Allies / Provisional | C05 F, C06 F, C09 M2·F, C12 M3 | 역사 추상어. glossary는 대부분 있으나 문장 구조가 어려움 | 구체 동사(rule, made … sign, stopped fighting)로 |
| a quarter past / half past | C09 M3·F | 시각 영어 | ROOKIE만 숫자 병기 |
| report 문장 반복(letter = reportLine) | C02 M1, C09 M2 | 같은 문장을 두 번 읽음 | 한쪽만 |
| "Read X again." 형태 orderFeedback | 31개 미션 | 문제는 아님 — 짧고 일관 | 유지 |

## 6. 힌트가 부족하거나 정답 유도가 약한 미션

- **힌트 3은 존재하지 않는다**(코드상 최대 2개). 3단계 역할은 오답 피드백이 맡는데, 다음 미션은 **흔한 오답에 맞춘 피드백이 없고 일반 orderFeedback 하나뿐**이다: C03 M1, C04 M3, C05 M2, C07 M2, C12 M2(타임라인 5종 — 엔진이 관계 문장으로 틀린 자리를 짚어 주므로 실제 부담은 작음), C01 M3(3개 있음, 양호).
- 힌트가 정답 쪽으로 가지 않음: **C11 M2**(힌트 1이 화면에 없는 판), **C01 M2**(힌트 2가 ㄴ→ㄷ 예시, 필요한 건 ㅅ→ㅈ·ㅁ→ㅂ), C06 Final(힌트 2가 정의만 줌).
- 힌트 2가 정답을 그대로 줌(ROOKIE엔 허용 범위지만 추리가 사라짐): C02 Final, C07 M1, C10 M3, C12 Final.

## 7. 수정 우선순위(Case 순서)

1. **Case 11** — P0(M2)과 P1(M3).
2. **Case 02** — 시즌 초반 이탈 위험(P1 둘). M2는 C11과 같은 용어 통일 작업으로 묶인다.
3. **Case 01** — 이미 미커밋 축약이 진행 중. M2만 마무리하면 됨(그 변경과 충돌하지 않게 같은 작업 안에서).
4. **Case 05** — P1 둘(M2 길이, Final 추상).
5. **Case 06·10·09** — Final 어휘(P1)와 정부 용어.
6. **Case 07** — M2 정리 + 기록 값 UI 실기기 확인.
7. **Case 03·04·08·12** — P2 정리.

## 8. 수정 작업량과 PART 분할안

수정 방식은 기존 원칙대로: plan의 ROOKIE 문구와 `levels.json`의 rookie 키를 함께 바꾸고 JUNIOR/MASTER 문구는 유지, 증거 문구(evidence)는 전 난이도 공통이므로 손대지 않는다. 정답·엔진·옵션 ID 불변.

| PART | 범위 | 미션 | 예상 작업 |
|---|---|---|---|
| **R1** 한글 퍼즐 규칙 통일 | P0 해소 + 용어 "+ 1 line" 통일 + gums/tongue glossary | C11 M2, C02 M2, C01 M2(+M3 문장 1개) | 미션 3~4개, 문장 ~25줄. 재생성 + `test/sandbox/s5_seoul_traces_test.dart`·관련 Seoul 플레이 테스트. 작음~중간 |
| **R2** 긴 글 감축 | 120어 이상 P1 감축(story·대화·중복 보고서) | C02 M1, C05 M2, C05 F, C07 M2, C09 M2, C11 M3 | 미션 6개, 문장 ~35줄. 수색 엔진은 letter/reportLine 중복을 문구로만 줄임. 중간 |
| **R3** 역사 추상어·자물쇠 어휘 | 정치 표현 구체화, 어려운 빈칸 단어 | C06 F, C10 F (+C09 F, C12 M3, C11 F) | 미션 5개, 문장 ~15줄 + glossary(moss, knelt, dusk, bureau, pressed). 작음 |
| **R4** P2 일괄 정리 + 실기기 확인 | 나머지 P2(질문 문장, 힌트 set aside 등) + [UI?] 항목 | C03 M1·F, C04 M1·M3·F, C06 M1, C07 M1, C08 M2·M3·F, C09 M1·M3, C10 M3, C11 M1 | 미션 14개, 대부분 1~2줄. 실기기 320px: C07 M1 기록 값, SyllableBoard(C01 M3·C02 M2·C11 M2), 긴 순서 버튼 라벨(C03 M3 "Hook the stone to the lower pulleys", C10 M1) |

R1·R2만 해도 P0 1개와 P1 7개가 해소된다. 각 PART 끝에 `flutter analyze` + Seoul 관련 테스트만 실행하고, 전체 회귀는 R4 후 한 번.

## 9. 확인하지 못한 것

- 실기기·시뮬레이터 화면은 보지 않았다. `[UI?]` 항목(텍스트 잘림, 320px 칸 크기, 순서 버튼 줄바꿈, 이름 입력칸)은 코드로만 위험을 추정했다.
- 탭 수는 엔진 구조로 추정한 최솟값이다(대화 넘김·편지 열기 탭 제외).
- 단어 수의 "첫 조작 전" 경계는 위 규칙으로 자동 집계했다. 장면 안에서 흔적·증인을 누르며 읽는 문장은 포함하지 않았다.
- 테스트·analyze는 실행하지 않았다(읽기 전용 조사).

## 부록 — 자동 집계 재현

세션 임시 스크립트(저장소 밖): plan의 `play` 필드에서 위 "첫 조작 전" 필드를 모아 영단어(`[A-Za-z][A-Za-z'-]*`)를 세고, `levels.json`의 같은 rookie 키로 JUNIOR/MASTER를 치환해 같은 방식으로 셌다. 12어 이상 문장, 3음절 이상 단어, R/J 동일 문장 비율도 같이 뽑았다. 저장소에 넣을 필요가 생기면 `tool/season_gen/case_levels.dart`의 `keyLines`를 쓰는 서브커맨드로 옮기는 것이 맞다.
