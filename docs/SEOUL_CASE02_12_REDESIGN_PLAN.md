# Seoul Case 02~12 — 전면 품질 개선 설계 (PART 0, 독립 사건 정정판)

- 작성: 2026-11-09 · 근거 문서: `docs/SEOUL_CASE02_12_FULL_AUDIT.md`(보존, 수정 안 함) · 기준: `main` 5c870fd + 작업 트리(미커밋 Case 01 V4 등)
- **정정판:** 같은 날 사용자 지시에 따라 "Seoul Case 01~12는 서로 독립적인 역사 탐정 사건"으로 다시 썼다. 이전 판에 있던 시즌 공통 연결(시대 이동 규칙, 지키미 가족, 쪽지 상자, 분이 편지의 시즌 증거화)은 모두 철회하고 이 문서에서 지웠다(§I-0).
- 이번 단계는 **설계만** 했다. 게임 코드·콘텐츠·이미지 수정, R2 업로드, 커밋·푸시는 하지 않았다. Case 01 V4는 건드리지 않는다.
- "어린이 플레이 시뮬레이션"은 **설계 검토**이고 실제 어린이 테스트가 아니다. 생성기와 테스트도 돌리지 않았다.
- 대상: 영어를 배우는 한국 어린이 8~12세(ROOKIE 8 / JUNIOR 10 / MASTER 12). 단어 풀이와 보호자 리포트는 한국어로 유지한다. 그래서 감사 문서의 S-1(단어 풀이가 한국어)은 해결 대상이 아니다.
- 문서 구성: §I 통합 요약·결정·독립성 검증·PART 계획 → §0 정책 → §E 엔진·저장·테스트 → §C1~C3 Case별 상세 설계(각 Case에 외부 의존 원장과 독립성 검증 표 포함).

# §I 통합 요약 · 결정 · 구현 PART 계획 (정정판)

## I-0. 정정 내용 (2026-11-09 사용자 지시)

**Seoul Case 01~12는 서로 독립적인 역사 탐정 사건이다.** Case 사이의 스토리 연결이나 공통 미스터리는 없다. 이전 PART 0에서 Case를 서로 잇기 위해 넣었던 설정은 모두 **철회**했다. 이전 판 문서는 이 파일에서 지웠고, 감사 문서 `docs/SEOUL_CASE02_12_FULL_AUDIT.md`는 그대로 보존했다.

| 철회한 설정 | 대신 |
|---|---|
| 물방울 쪽지로 시대를 이동하는 공통 규칙, Intro 첫 줄 통일 | 각 Intro는 그 Case만으로 상황이 이해되게 쓴다("You are a guest of…" 같은 기존 방식) |
| 분이 집안에 전해지는 탐정과의 약속, C08 가족 공개, C04 "But why?"를 C08에서 회수 | 삭제. C04 Ending의 "But why?" 줄도 지운다 |
| Case마다 지키미 쪽지를 상자에 넣는 구조, 상자 전달 경로, 봉수 → 강 부인 | 삭제 |
| C12의 쪽지 11장·12장 누적, 시즌 쪽지 순서 퍼즐 | C12를 독립 사건 "The Box That Waited"로 새로 설계(§C3) |
| 분이의 편지·나무 상자를 시즌 핵심 증거로 사용(`s5_ep01_e4` 참조) | Case 01 V4 안에서만 유지한다(Case 01은 변경하지 않음). 다른 Case에서 참조하던 곳은 모두 지운다 |
| 이전 Case 증거를 쓰는 recall, Final present, 미끼 카드 | 그 Case 증거만 쓴다. 이전 Case 지식이 필요하던 퍼즐(C02 M2 자음 원리, C04 M1 가획 규칙)은 **그 Case 화면 안에서 다시 가르친다** |

## I-1. Case별 독립 설계 한눈에

| Case | 독립 사건 목표 | Final (정답 · 방식 · 이 Case 증거) | 지운·바꾼 외부 의존 | 엔진 | 새 그림 | 크기 |
|---|---|---|---|---|---|---|
| 02 거북선 1592 | 대포 시험 직전 사라진 화약이 도둑맞은 것인지, 누가 왜 옮겼는지 증명해 시험을 진행시킨다 | `seok` · 이순신에게 e1·e2·e3를 보인 뒤 진술 판정 | C01 Sound Board recall → **창고 벽 "수병 글자판"**이 ㅁ+1=ㅂ와 받침을 화면에서 가르친다. Bun-i discovery, Sora 문구, C01 clueInputs 2건 삭제. 물방울 = 석이 한자만 읽는 함에게 "비"를 알리려고 그린 표시 | 2b1·2b2·2b3 | 없음 | M |
| 03 거중기 1795–96 | 거중기가 고장인지 바뀐 것인지 밝혀 돌을 올리고, 경고 쪽지를 쓴 사람을 찾는다 | `okbun` · 용의자 4명 소거(text_choice) · e1·c2·M1 단서 | C02 e1 recall, "THE SAME WATER DROP" discovery, 석 언급 Ending 삭제. 물방울 = 물 긷는 아이가 이름 대신 그린 표시(Ending에서 옥분이 이유를 말함) | 없음 | 없음 | M |
| 04 경복궁 1866 | 통나무의 행방, 표식을 바꾼 사람, 경고 쪽지를 붙인 사람을 대원군에게 증명한다 | `rebuilt` · 대원군 present 3단계(새 id p_mark2→e1, p_cut2→e3, p_writer2→e2) | C01 recall과 "Sora's board" → 두리 대사와 **"Carvers' rule"**, 1592·1795 쪽지 present와 가문 대사 삭제, "But why?" 삭제 | 2b1·2b2·2b3, **M3 timeline → trace_deduction** | 없음(흔적 좌표 재측정) | L |
| 05 건청궁 1887~95 | 전등이 꺼진 한 시간 동안 낯선 두 사람이 한 일을 밝혀 그들이 노리는 문을 왕과 왕비에게 보인다 | `queen` · 판의 점을 밧줄 규칙으로 읽기(picture_choice) · e1·e2·e3 | C04 Duri recall → **같은 Case `s5_ep05_e1` recall**, "our letters" 대사 삭제, Intro에서 왕이 탐정을 부른다 | 없음 | 없음(320폭 확인) | M |
| 06 헤이그 1907 | 황제의 비밀 편지를 아무에게도 들키지 않고 이준에게 건넨다 | `unseen` · 대화 e1 실, e2 서문 길, e3 감시 시각 | C05 recall과 "1895 지도" 줄 삭제, 봉수 쪽지의 물방울 삭제, 1897 "왕 → 황제"는 Intro에서 설명 | 2b1·2b2·2b3 | 없음 | M |
| 07 하얼빈 1909 | 두 신문 중 어느 기사가 사실인지, 안중근이 무엇을 외쳤는지 밝혀 바른 기사를 싣게 한다 | `for_korea` · 소린 설득, 카드 3장 · why의 정답을 C06 e4 → **이 Case e1(강 부인 쪽지에 이토·1905 줄)** | recall 2건, "letter box", 1919 예고 줄 삭제. 1905 조약과 이토는 Intro에서 설명 | 2b1·2b2·2b3 | 없음 | M |
| 08 아우내 1919 | 진짜 만세 날짜와 신호를 찾고 계획을 낯선 사람에게서 지킨다 | `311` · 다이얼(기호 map·map·clock) · c1(4월 1일) + c2(전날 밤 불) | 분이 편지 엔딩, 가족 공개, 지키미 상자, `s5_ep01_e3`, C07 recall 삭제. M3 recall → **같은 Case `s5_ep08_e1`**. M3 철자 입력 → text_choice. 1910 병합·3·1운동·Hangeul은 Intro에서 설명 | 없음 | 없음 | S~M |
| 09 상하이 1920 | 비밀 명단을 베낀 사람을 찾아 김구에게 증명하고 사본을 막는다 | `copy_found` · 남기호의 거짓말 3개 반박 · e1 초, e2 얇은 종이, e3 퇴근부 | C08 상자 recall, 경순 사촌·상자 줄, C10 예고, 물방울 삭제. 해수는 밀정이 있을까 봐 이름을 쓰지 않았다고 직접 말한다. Mr. Pak → Mr. Choi 개명은 **취소**(C07과의 이름 충돌은 Case 간 문제였음) | 2b1·2b2·2b3 | 없음 | M |
| 10 두 시계 1932 | 오늘 밤까지 정부 기록부에 "오늘 아침의 기록"을 사실대로 쓴다(어느 시계를 쥐었는지, 왜 바꿨는지) | `why` · 기록 3줄 증명 · e1 목격 기록, e2 시계, e3 말(미끼도 이 Case 증거) | C09 recall, 물방울 서명, "Miri takes the box", 지키미 해수 삭제. 해수는 Intro에서 임시정부 서기로 소개. **M2 시계 모순(P1) 해소**, M3 HOUR | 2b1·2b2·2b3 | 없음 | M |
| 11 윤동주 1941 | 새벽에 친구가 오기 전에 사라진 사본을 찾아 건넨다 | `319` · 2단계: 윤의 목록 대화 → 번호 자물쇠 · 미끼 e1·e3 | Bun-i 힌트, 해수, 상자, 충칭 연결, "keepers' mark" 삭제. 물방울은 미리의 서명 하나로 남김(c11_drop_card 그림, M1 정답 WATER). 이유는 Case 안에서 말함(매일 방에 물을 나르는 사람, 사무실 사람이 누군지 모르게). M3 PIANO, 편지 R/J/M 같은 4줄 | 2b2(카드 2장이면 변경 불필요) | 없음 | M |
| 12 광복 1945 | 빛나의 어머니가 남긴 상자를 찾아, 어머니의 규칙대로 "전쟁이 끝난 바로 그날" 연다 | `LIGHT` · 2단계: 날짜 카드와 편지 대화 → 글자 자물쇠(7장 중 5장, 미끼 2) · 상자 안에 태극기 | 외부 의존 32건 모두 삭제. 미리·해수·분이·물방울·11장 쪽지 없음. 빛나와 어머니(광복군)는 Case 안에서 소개. M1 트렁크 추론 유지, M2 어머니 편지 4장 + 그림 1장 순서, M3 815 + 미끼 810. 김원봉은 맞이·라디오·직책(군무부장)만. **제목 변경 "The Box That Waited"** | **2a 필수**, 2b1~2b3 권장 | 없음 | L |
| 시즌 | 12개의 서로 다른 역사 사건 | — | 프롤로그(키·줄 수·그림 유지) 17줄 중 11줄 교체: 쪽지·물방울·지키미·"pieces together" 삭제. 아웃트로·피날레를 시즌 미스터리 없이 다시 씀. `season.plan.json` mainMystery, `story_bible.json` coreMystery 정정, Case 간 clueThread 19개 삭제 | — | 없음 | S |

## I-2. 통합 결정 (이번 정정에서 새로 정한 것)

| 질문 | 결정 | 이유 |
|---|---|---|
| "이름 대신 물방울" 표식이 C02·C03·C05·C08·C11 다섯 곳에 남아 시즌 공통 표식처럼 읽힐 수 있다 | **네 곳은 유지하고 C08만 Case 고유 표식으로 바꾼다.** 유지하는 곳과 이유: C02 석이 그린 "비" 표시(사건의 단서). C03 물 긷는 아이 옥분(추리 조건). C05 한 상궁(그림 `lamp_house.webp`의 석탄 삽 밑 쪽지에 파란 물방울이 실제로 그려져 있음, `assets.manifest.json`). C11 미리(그림 `c11_drop_card.webp`, M1 정답 WATER). 교체: **C08 경순 → 작은 불꽃 그림**(봉화 사건). C08 M3 공책 특징 "a small water drop"도 "a small flame"으로 바꾼다 | C08의 물방울은 글에만 있고 그림이 없어서(plan 그림 목록과 manifest로 확인) 그림 교체 없이 바꿀 수 있다. 남는 네 곳은 저마다 Case 안에서 이유가 설명된다. 세 레벨 문구 어디에도 "the same mark"처럼 Case를 잇는 말은 두지 않는다. PART 7 플레이스루에서 공통 표식처럼 보이는지 다시 본다. dossier clue에 water drop이 있으면 C08만 함께 고친다 |
| 프롤로그 pieces[0] `find_note.webp`에 물방울이 그려져 있다 | **유지** | C02 자기 단서의 그림이고, 바뀐 프롤로그 문구가 물방울을 공통 표식으로 말하지 않는다. 그림 교체는 하지 않는다 |
| C12 Final 타일 N H T I R G L로 LIGHT 말고도 영어 단어가 만들어진다(GLINT, NIGHT, RIGHT, THING, GIRTH) | **수수께끼가 LIGHT 하나만 가리키게 하고, 다섯 단어 모두에 전용 오답 피드백을 둔다.** 특히 GLINT는 "A glint is only a tiny flash. The riddle says the light comes back for the whole country."처럼 뜻 차이를 짚는다 | 미끼를 어떻게 골라도 5글자 영어 단어가 생긴다. 미끼를 피하기보다 수수께끼와 피드백으로 하나로 정한다 |
| C12 제목 | **"The Box That Waited"** | 지금 제목에 정답 LIGHT가 들어 있다 |
| C06 Final 대화형 vs 한 문항 고르기 | 대화형 유지 | 한 문항 4지선다는 찍어서 통과할 확률이 25%다 |
| 대화형 Final이 많다(C04·C06·C07·C09·C10 + 앞 단계 C02·C11·C12) | 수용한다 | 질문 틀이 Case마다 다르다(심문, 안전 확인, 설득, 반박, 기록 검증). PART 7 플레이스루에서 다시 판단한다 |
| C09 Mr. Pak → Mr. Choi | 취소 | 독립 사건에서는 이름이 겹쳐도 문제가 아니다 |
| C02 "officials wrote in Chinese letters" | 삭제 | 미검증 일반 주장이다 |
| 새 dossier 사실 | 추가하되 **출처 URL을 붙인 뒤에만** 넣는다: C02 h7~h11, C03 h7 조심태, C04 h8 가획, C07 9:30·코레아 우라, C10 h5·h6 백범일지, C12 h10(8월 10일 첫 소식)·h11(1910) | C12 h10·h11과 C10 h5·h6은 설계 단계에서 출처를 확인하지 못했다. 구현 때 확인하지 못하면 그 문구를 뺀다 |
| levels가 timeline 관계 문장·대화 present 문구를 레벨별로 바꾸는가 | 바꾼다(levels.json lines에 있다) | 정보량만 같게 유지한다 |

## I-3. 독립성 검증 결과 (설계 기준)

**판정: 정정된 설계에서 Case 02~12는 서로 독립적으로 플레이할 수 있다.** 단, 이것은 설계 문서를 기준으로 한 판정이다. 실제 데이터와 화면에서는 PART 1·7에서 다시 확인해야 한다.

| 검사 | 방법 | 결과 |
|---|---|---|
| Case마다 다른 Case 없이 Intro 이해 → 모든 미션·Final 풀이 → Ending 이해가 되는가 | 각 Case 설계의 "독립성 검증" 표(§C1~C3) | 11개 Case 모두 "다른 Case 참조 없음" |
| 제안 문구에 다른 Case id가 남았는가 | 설계 파일 전체에서 `s5_epNN_`(자기 Case 제외)과 keeper·letter box·Bun-i·Sora를 기계적으로 검색하고, "기존 → 변경" 원장 행을 빼고 다시 확인 | **0건.** 남은 언급은 모두 원장의 "기존 값" 칸이다 |
| Final이 그 Case 증거만 쓰는가 | I-1 표 | 11개 모두 그 Case 증거 id만 사용(미끼 카드 포함) |
| 이전 Case 지식이 필요한 퍼즐 | C02 M2(자음 원리), C04 M1(가획 규칙)이 Case 01 Sound Board에 기대고 있었다 | 둘 다 그 Case 화면에서 가르치도록 바꿨다(수병 글자판, Carvers' rule) |
| recall | 지금은 C02~C12 11개 Case 모두 앞 Case 증거를 recall한다(데이터 확인) | 모두 삭제하거나 **같은 Case 증거 recall**로 바꿨다(C05 → e1, C08 → e1, C12 M3 → e2) |
| 역사 배경을 그 Case 안에서 설명하는가 | 1897 대한제국(C06), 1905 조약·이토(C07), 1910 병합·3·1운동(C08·C09·C12), 임시정부(C09·C10·C12), 대원군(C04), 조선어 금지(C11) | 필요한 Case마다 Intro나 대사에서 설명한다. 여러 Case에서 같은 배경을 반복 설명하는 것은 의도한 것이다 |

아직 남은 데이터 측 연결도 구현 때 함께 지운다.
- `lib/data/generated/s5_seoul/s5_seoul_*.g.dart`의 `s5SeoulEvidenceLinks` 중 Case 사이를 잇는 항목
- 다른 Case를 가리키는 `clueInputs`
- 다른 Case를 말하는 discovery 카드
- `story_bible.json`의 clueThread 19개

Case 잠금 해제 순서(앞 Case를 끝내야 다음이 열림)는 이야기 연결이 아니라 진행 구조라서 이번 정정 범위 밖이다. 유지 여부는 사용자가 정할 일이다.

## I-4. 엔진 변경 (정정 후)

| ID | 내용 | 필요 Case | 크기 |
|---|---|---|---|
| 2b2 | present당 카드 3~4장 + 2열 배치 (`play_check.dart:894`, `case_talk.dart:661-679`) | C02·C04·C06·C07·C09·C10·(C11)·C12 | S |
| 2b3 | 2회 오답 → 다시 볼 증거 안내, 3회부터 정답 카드 빛남 (`case_talk.dart:632-670`). **C01 V4와 파리 C11 대화 동작도 바뀐다** | 위와 같음 | S |
| 2b1 | Final 대화 힌트 버튼 (`final_mission_screen.dart:868-879`) | 대화 Final 전부 | S |
| 2a | 글자 자물쇠 미끼 타일 (`letter_lock.dart:44`, `puzzle_selection_check.dart:358-363`, `season_content_validator.dart:325-329`) | **C12** | S |
| 2c·2d | 순서 미션 화면 안내, 숫자 오답 뒤 입력 유지 | 권장 | S |
| 2f | Final recall 표시 | **쓰지 않음** | — |
| — | 다른 Case 증거를 present로 받는 기능 | **쓰지 않음**(정책상 금지) | — |

## I-5. 저장·ID 규칙

§E 3장 그대로 따른다. 원칙은 이렇다.
- mission·evidence·clue id는 하나도 지우지 않고 미션 수도 그대로 둔다.
- 뜻이 바뀌는 timeline 카드와 talk present·question에는 새 id를 쓴다.
- decode가 모르는 id는 버리고 처음부터 시작한다(오류 없음).
- 이미 완료한 Case는 완료로 남는다.

이번 정정으로 더 바뀌는 점은 세 가지다.
1. 지우는 recall: recall 선택 기록은 저장되지만 콘텐츠에 없는 recall은 쓰이지 않는다(§E 3.1).
2. 다른 Case를 가리키던 증거가 그 Case 안의 이름으로 바뀐다. 예: 증거 이름의 "(연도)" 4개를 id는 그대로 두고 이름만 바꾼다. 증거는 저장되지 않고 매번 콘텐츠에서 다시 계산되므로 수첩에 바로 새 내용이 보인다.
3. C12는 timeline 카드 4장과 present `today`·`riddle`이 새 id다. M2에 저장된 진행 상태는 처음으로 돌아간다.

## I-6. 구현 PART 계획 (정정판)

공통 파이프라인은 PART마다 같다(§E 4.4).
- `case_levels check` → `plan_season check` → `generate_season --target game` → `build_manifest`
- 이어서 dossier clue 노출 검사(history_clue_not_shown), Case 테스트, Seoul R/J/M 플레이스루를 한다.
- **Case 하나씩 생성기를 먼저 돌린다.** `dart format`은 프로젝트 파일에 쓰지 않는다.

| PART | 범위 (정정) | 수정 파일 | 크기 |
|---|---|---|---|
| **1 — P1 모순 + Case 내부 개연성** | ① **C10 M2 시계 모순(P1)**: 김구는 손을 펴지 않고, 해수가 그림 3장을 보이며, 손가락 사이로 줄이 보이는 단서. ② **C12 외부 의존 제거(P1)**: C12 전체를 독립 사건으로 재구성(§C3). 분이 카드는 사라진다. ③ **모든 Case의 외부 의존 제거와 그 Case 안에서의 완결**(각 Case "외부 의존 원장"): recall과 clueInputs를 그 Case 증거로 바꾸거나 지우기, discovery·evidenceLinks 정리, 지키미·상자·분이·Sora 대사 교체, C02 수병 글자판과 C04 Carvers' rule 도입, C08 표식 교체(물방울 → 불꽃), C04 "But why?" 삭제. ④ 시즌 프롤로그·아웃트로·피날레, `season.plan.json` mainMystery, `story_bible.json` coreMystery와 clueThread 정정 | `s5_ep02~12/case.plan.json`·`levels.json`, `season.plan.json`, `season.levels.json`, `planning/story_bible.json`, `planning/history_dossier.json`(C02의 C01 fact 참조 → 새 fact), 재생성 `lib/data/generated/s5_seoul/*`. 테스트: `s5_seoul_case01_test.dart:164-170`(C08 엔딩 단언 → "C08 엔딩에 없음"), `s5_seoul_rookie_test.dart`(C10·C12), `s5_seoul_syllables_test`(C02 글자판), 시즌 플레이스루 | **L** |
| **1.5 — 엔진** | 2b1·2b2·2b3·2a(+2c·2d) | `case_talk.dart`, `final_mission_screen.dart`, `letter_lock.dart`, `question_widgets.dart`, `play_check.dart`, `puzzle_selection_check.dart`, `season_content_validator.dart` + C01 V4·파리 C11 대화 테스트 | S~M |
| **2 — C02~C05** | 퍼즐·Final 재설계(§C1): C02 진술 판정 Final, C03 용의자 소거, C04 M3 엔진 교체·M2 숫자·Final present, C05 판 읽기 Final·M2 순서 섞기, 정답 노출 제거, 역사(조심태·대원군) | `s5_ep02~05` plan·levels, dossier, 재생성, C02~C05 기대값 테스트, `s5_seoul_traces_test`(C04 M3) | L |
| **3 — C06~C09** | §C2: C06 Final 대화, M2 순서 섞기, M3 "as soon as"; C07 9:30·Koreya Ura·Final 카드; C08 M3 고르기·다이얼 기호·유관순 "helped lead"; C09 거짓말 반박·사본 회수 | `s5_ep06~09` plan·levels, dossier, 재생성, 테스트 | M~L |
| **4 — C10~C11** | §C3: C10 M3 HOUR·Final 기록 증명, C11 M3 PIANO·Final 2단계·편지 통일 | `s5_ep10~11` plan·levels, dossier, 재생성, `s5_seoul_case11_test`, rookie 테스트 | M |
| **5 — 공용 UX** | 감사 5-C의 나머지 P2(편지 다시 보기 접근성, 단어 풀이 표시, 320폭 타일, 쓰이지 않는 오답 피드백, 보기 순서 경고) | 위젯·`play_check.dart` | M |
| **6 — 난이도 영어** | R/J 차별화, M 길이 억제, 레벨 정보량 동일 검사 | `s5_ep02~12/levels.json` | L |
| **7 — 전체 검증** | analyze, 관련·전체 테스트(기존 실패 13건 기준), Seoul 12 Case 플레이스루, **Case별 단독 플레이 검사**(다른 Case를 하지 않은 새 저장에서 각 Case 진입), 저장 호환, 모바일 화면, 역사 출처, 독립성 재감사(데이터 grep) | — | M |

**PART 1이 P1 두 건과 독립화를 함께 맡는 이유가 있다.** C12는 시즌 연결 위에 서 있어서 연결을 끊는 일과 다시 설계하는 일을 나눌 수 없다. 다른 Case의 독립화도 대사와 데이터 참조를 같이 바꿔야 해서, Case별 퍼즐 재설계(PART 2~4)보다 먼저 한 번에 하는 것이 중복이 적다. PART 2~4는 PART 1에서 고친 Intro·대사 위에서 미션과 Final만 바꾼다.

전체 작업량은 이전 판과 비슷하게 **9~13 세션**이다. PART 1이 커진 대신(L), PART 4가 C10~C11로 줄었다.

## I-7. 위험과 대응

| 위험 | 대응 |
|---|---|
| 작업 트리의 미커밋 C08 엔딩 2줄("엄마, 고마워요" 관련)이 C08 엔딩을 바꾸면 사라진다 | PART 1을 시작하기 전에 사용자에게 알린다(Case 01 V4 작업의 일부였음). Case 01 파일 자체는 바꾸지 않는다 |
| 설계 문구가 생성기 규칙에 걸린다 | Case 하나씩 생성기를 먼저 돌린다. 규칙을 바꿔야 하면 멈추고 보고한다 |
| 2b3이 C01 V4·파리 C11 동작을 바꾼다 | PART 1.5에서 해당 테스트를 같이 고친다(문구는 그대로) |
| 다른 Case가 쓰지 않게 되는 증거에 `clue_never_used` 경고가 생긴다 | 경고라 생성은 막지 않는다. PART 7에서 목록을 확인한다 |
| C04 M3 흔적 좌표, C05 Final 320폭 | 격자 시트로 재측정하고 시뮬레이터에서 확인한다(안 되면 text_choice) |
| C12 M2 순서의 필연성이 약하다(C12 설계가 스스로 밝힘) | PART 1에서 관계 문장을 한 줄 더 넣어 해가 하나로 정해지는지 다시 검사한다 |
| 출처를 확인하지 못한 새 사실(C10 h5·h6, C12 h10·h11 등) | 출처 URL을 확인한 뒤에만 넣는다 |
| 어린이 플레이 검증 | 이 문서의 시뮬레이션은 설계 검토다. 실제 어린이 테스트가 아니다 |

## I-8. 확인하지 않은 것

- 생성기, play_check, 테스트, 앱은 하나도 돌리지 않았다.
- 레벨별 단어 수는 Case마다 핵심 줄만 셌다.
- 그림은 일부만 직접 열어 봤다(C03, C04, C10, C11, C12 6장).

---

# §0 정책 (독립 사건)


## 핵심
Seoul Case 01~12는 **서로 독립적인 역사 탐정 사건**이다. Case 간 스토리 연결이나 공통 미스터리는 없다.

## 철회 (설계에서 제거)
- 물방울 쪽지로 시대를 이동하는 공통 규칙(S-F1), Intro 첫 줄 통일 규칙
- 분이 집안에 전해지는 탐정과의 약속, C08 가족 공개, C04 "But why?"를 C08에서 회수하는 연결
- Case마다 지키미 쪽지를 상자에 넣는 구조, 상자 전달 경로, C12의 11장·12장 누적
- 분이의 편지·나무 상자를 시즌 핵심 증거로 쓰는 구조(s5_ep01_e4 참조 등)
- 이전 Case를 알아야 이해되는 대사·퍼즐, 이전 Case 증거를 쓰는 recall·Final present·미끼 카드
- Case 01 V4의 분이 편지와 나무 상자는 **Case 01 안에서만** 그대로 유지한다(Case 01은 변경 금지).

## 기존 요소 처리 원칙
다른 Case에 이미 있는 연결 요소(물방울 표시, 지키미, 상자, Sora's board, Bun-i 언급, recall, clueInputs의 타 Case ref, discovery, evidenceLinks)는 **무조건 삭제하지 않는다.** 그 Case가 혼자 설 때 필요한지 검토한다:
- 사건 안에서 기능이 있으면(예: 쪽지 자체가 단서) **그 Case 안에서 완결**되게 다시 설명한다(누가, 왜 썼는지 Case 안에서 밝혀짐).
- 기능이 없으면 제거한다.
- 그 Case 이해에 필요한 지식(예: 한글 자음 모양 원리)은 **그 Case 화면 안에서 다시 가르친다**(앞 Case 증거 recall 금지).

## 각 Case 흐름 (독립 완결)
Intro: 해결할 사건 발생 → M1: 첫 증거 발견 → M2: 증거 조사·새 사실 → M3: 핵심 단서 확보·추론 → Final: **이 Case에서 모은 증거**로 해결 → Ending: Intro 문제 해결.
미션 수·구조는 기존 데이터 기준(M1~M3 + Final). 모든 미션은 사건 해결에 필요한 이유가 있어야 한다. 역사 배경·인물은 그 Case만 보고 이해할 수 있어야 한다(필요한 배경 설명은 그 Case 안에서).

## 유지하는 개선
C10 시계 모순 해결, C12 외부 의존 제거, 정답 선공개 방지, 단서 없는 퍼즐 개선, 반복 퀴즈 개선, Final을 실제 사건 해결로, R/J/M 영어 개선, 역사 고증·배경 설명(조심태, 유관순 "helped lead", 1910 병합 등은 필요한 Case 안에서), 조작·힌트 개선.

## 그대로 유효한 앞의 정책
대상: 영어를 배우는 한국 어린이 8~12세(한국어 glossary 유지). 세 레벨 사건·단서·정답·핵심 정보 동일. 김원봉 유지(검증 가능한 활동만). Final 정답 변경 허용(증거·논리로 결정). id 유지 원칙(미션·증거·clue id 삭제 금지, 뜻이 바뀌는 카드·present는 새 id). 새 그림은 생성하지 말고 사양만. 콘텐츠 규칙(play_check, history_clue_not_shown, 레벨 줄 수, Hangul 단어 위치 규칙) 준수. 타일·카드·보기는 섞이지 않으므로 정답 순서로 나열 금지.

---

# §E 엔진 능력 · 엔진 변경 · 저장 호환 · 테스트 영향

> 정정판 메모: 이 절의 "앞 Case 증거를 talk present로 받기"(§1)는 기능 설명일 뿐이다. 독립 사건 정책 때문에 **쓰지 않는다.** 2f(Final recall 표시)도 쓰지 않는다. 엔진 변경 목록은 §I-4를 따른다.

## Seoul Case 02–12 재설계 — 엔진·저장·테스트·에셋 영향 참조서

읽기 전용 코드 분석이다(2026-11-09, main 5c870fd + 작업 트리의 미커밋 Seoul 변경 포함). 감사 문서 PART 5-C(`docs/SEOUL_CASE02_12_FULL_AUDIT.md:1603-`)의 사실을 다시 확인해서 썼다. 줄 번호가 달라진 곳은 이 문서의 번호를 따른다.

**한 줄 요약**
- 코드 변경 없이 되는 것: timeline 미끼·고정 카드, order_sequence 미끼, 앞 Case 증거 제시(Final talk), 앞 Case 증거 recall(미션만), Final을 "증거 대화 → 자물쇠" 두 단계로 만들기, 단어 입력 다중 정답.
- 코드 변경이 필요한 것: 글자 자물쇠 미끼 타일, 증거 제시 카드 3~4장, 2회 오답 자동 공개 완화, Final 대화 힌트 버튼, **Final의 recall 표시**(지금은 런던 id 두 개만 허용).
- 테스트: Case 02–12 문장·정답을 직접 박은 테스트는 `s5_seoul_rookie_test`(13), `s5_seoul_case11_test`, `s5_seoul_syllables_test`, `seoul_case_maps_test`(장소·핀), `s5_seoul_case01_test:164-170`(C08 엔딩 "엄마, 고마워요")이다. 재설계 PART마다 의도를 옮겨 갱신한다. 전체 suite 기존 실패 13건(§4.3).
- 그림: 재사용이면 R2 작업이 없다(영역 재측정만). 새 그림은 재설계 동안 `appOnlySeasonFiles` + pubspec으로 쌓고, 시즌이 끝나면 한 번 팩으로 업로드한다(사용자 승인, §5.4).
- 저장: 콘텐츠 버전·마이그레이션 장치가 없다. 증거는 저장하지 않고 매번 콘텐츠에서 다시 계산한다. **mission id·evidence id를 지우거나 미션 수를 바꾸지 않으면** 별도 마이그레이션은 필요 없다.

---

## 1. 엔진 기능 카탈로그 (코드 변경 없이 데이터로 되는 것)

### 1.0 공통 규칙 (모든 엔진)

- **plan 필드 위치**: 퍼즐 정답 = `missions[].puzzle.answerSpec`(`tool/season_gen/schema/puzzle_plan.schema.json:25-37`: `answer`, `acceptedAnswers`, `options[{id,label,feedback,altText,picture}]`, `codeLength`, `codeFormat`(enum `time`만), `dialSymbols`). 화면 글 = `missions[].play`(`mission_plan.schema.json`의 `$defs/play`: title, location, story, letterIntro, letter, question, prompt, hints, successMessage, transition, feedback, orderFeedback, clue, evidence, recall, lockTitle, hideOptionNames, 엔진 장면 키 explore/search/dialogue/timeline/syllables/shapes/traces/inspect/records/interview/talk, discovery, ending).
- **생성기가 만드는 엔진** = `PlayCheck.generatable`(`tool/season_gen/play_check.dart:62-81`): text_choice, order_sequence, word_entry, letter_tile_lock, combo_dial_lock, picture_choice, scene_explore_choose(`explores`), dark_room_search(`investigations`), witness_compare(`dialogues`), timeline_board(`timelines`), syllable_compose(`syllables`), shape_match(`shapes`), number_entry, trace_deduction(`deductions`), lens_inspect_word(`inspections`), record_mismatch(`records`), evidence_talk(`talks`). 그림이 필요한 엔진(`pictured`, `:84-87`)은 status가 `devRequest`만 아니면 되고, 나머지는 `ready`여야 한다.
- **팔레트에 있지만 생성기가 못 만드는 엔진**(plan으로 쓰면 `generate_unsupported`): object_decode, spot_difference, room_find_match, layer_reveal, clue_filter_choice, symbol_dial_lock, viewpoint_match, guided_steps, clock_set, scene_compare_report, evidence_board, closeup_compare_choose, token_place_map, symbol_join (`lib/data/content/puzzle_palette.dart:445-1100`). 런던·파리 손코딩 콘텐츠용이다. Seoul에 쓰려면 생성기·play_check·plan 모델 작업이 필요하다(L). **재설계는 생성 가능한 17개 안에서 고르는 것을 권한다.**
- **화면 순서는 plan 순서 그대로다.** 글자 타일, timeline 카드, order_sequence 보기, 선택지를 섞는 코드가 없다(`shuffle`/`Random` 검색 0건: letter_lock.dart, timeline_board.dart, question_widgets.dart). 정답 순서와 다르게 plan에 적어야 한다. 이것을 검사하는 도구 규칙도 없다(정답 순서 그대로 나열해도 통과).
- **힌트** 1~2개(`play_check.dart:53,181-185`). 1번 무료, 2번 20코인(`app_constants.dart:90,126`).
- **선택형 최소 보기 수** 3개(`play_check.dart:50,148-151`; multipleChoice/imageChoice/canvasChoice). 선택형의 오답 문구는 `options[].feedback`이고 `play.feedback`은 쓰면 안 된다(`:203-205`).
- **orderFeedback**("같은 글자/숫자/항목인데 순서만 틀림")은 sequence, letterLock, wordInput, numberCode, finalCode, examine에서만 쓸 수 있다(`:102,206-208`).
- **정답 비교**: 대문자로 바꾸고 A–Z·0–9·한글만 남겨 `answer` + `acceptedAnswers`와 비교한다(`lib/core/utils/answer_checker.dart:12-14,75-86`). wordInput, numberCode, finalCode, letterLock, examine 모두 acceptedAnswers를 읽는다.
- **mission `feedback` 맵**(특정 오답 → 문구)은 텍스트형 엔진에서 정규화해서 비교한다(`answer_checker.dart:47-53`).
- **evidence 아이콘·clue 기호**는 GameSymbol 24개 중에서 고른다(`tool/season_gen/palette_facts.dart:411`: train, museum, clock, park, palace, crown, raven, gear, letter, key, watch, map, ticket, feather, footprint, button, cloth, seal, frame, mask, gem, bag, umbrella, whistle). 거북선, 붓, 물방울 같은 서울 전용 기호는 없다. 추가하려면 `lib/widgets/symbol_icon.dart`와 생성 테이블을 바꿔야 한다.

### 1.1 엔진별 표

| paletteId (missionType / table) | 지금 데이터로 할 수 있는 것 | 못 하는 것 (코드 필요) | plan 필드 · 검사 규칙 |
|---|---|---|---|
| **letter_tile_lock** (`letterLock`, 미션·파이널. 선택: lockBoxes 그림 상자) | 타일 순서 지정, `lockTitle`, orderFeedback, feedback 맵, acceptedAnswers. 파이널에서 talk.before 뒤에 둘 수 있다 | **미끼 타일 불가.** 슬롯 수 = `options.length`(`lib/features/mission/widgets/letter_lock.dart:44`)이고 꽉 차야 OPEN이 켜진다(`:55,181`). 검사도 "타일 글자 = 정답 글자, 각 한 번"(`tool/season_gen/puzzle_selection_check.dart:358-363`). 타일 라벨은 지금 모두 한 글자다 | answerSpec.options(타일 = 글자 하나), answer. play.lockTitle |
| **combo_dial_lock** (`finalCode`, 파이널 전용) | 자리 수 = `codeLength`, 자리마다 `dialSymbols`(24개 중 하나, 개수 = codeLength, `puzzle_selection_check.dart:340-344`) | 숫자 0–9만. 글자나 기호 다이얼은 없다(symbol_dial_lock은 생성 불가). 재진입하면 0으로 초기화된다(`final_mission_screen.dart:486`) | answerSpec.answer(숫자), codeLength, dialSymbols |
| **number_entry** (`numberCode`, 미션·파이널) | 2자리 이상의 숫자. `codeFormat: "time"`이면 HH:MM 4자리 시계 표시(`mission.dart:555`, 검사 `play_check.dart:661-664`). feedback 맵, orderFeedback | 글자 섞인 코드, `time` 외 형식(날짜 등). codeLength가 반드시 answer 길이와 같아야 한다(`play_check.dart:653-657`). 오답 제출 후 입력이 지워진다(`question_widgets.dart:526-528`) | answer(숫자만, `:649-651`), codeLength, codeFormat |
| **word_entry** (`wordInput`, 미션·파이널) | acceptedAnswers 여러 개(부분 정답, 다른 철자), feedback 맵, orderFeedback(애너그램 순서 오답), `prompt`(빈칸 문장에 입력이 들어감, `question_widgets.dart:341-365`) | 한글 입력(필터가 A–Z와 공백만 허용, `:384-386`), 20자 초과(`:369-394`) | answer, acceptedAnswers, play.prompt, play.feedback |
| **order_sequence** (`sequence`, 미션·파이널) | **미끼 보기 가능**(보기 > 단계: 각 보기 한 번만), 보기 재사용(보기 < 단계일 때, `question_widgets.dart:823`), `codeLength` = 단계 수, 보기에 picture, feedback 맵(특정 순서 → 문구), orderFeedback | 화면에 "순서대로 탭" 안내 없음(§2c). 단계 줄 라벨을 데이터로 줄 수 없음 | options, answer(쉼표로 이은 id), codeLength. 검사 `puzzle_selection_check.dart:346-357` |
| **timeline_board** (`sequence` / `timelines`, 미션만) | 놓을 카드 2–6, **시각 고정(anchor) 카드 1–3, 미끼(discard, "NOT PART OF IT") 최대 2**(`play_check.dart:504,520-529`). 카드에 `evidence`(증거 id), `factIds`(dossier), `fiction`. relations(earlier/later/line). 중간 상태 저장됨 | 파이널 불가(`surfaces: _m`). anchor 0개 불가 | play.timeline.cards[], relations[]. options는 카드와 같은 순서·같은 제목(`:531-534`). 관계 문장은 letter/story/question/prompt에 글자 그대로 있어야 한다(`timeline_line_unread`, `:557-561`). 놓을 카드마다 관계 문장 하나 이상(`:549-553`). 이동 시뮬레이션(`timeline_unplayable`). orderFeedback 필수(`:535`) |
| **evidence_talk** (`examine` / `talks`, 미션·파이널) + **talk 둘레**(`talkMissions`) | ① Final 자체를 대화로(`play.interview`): questions(+requires), presents 여러 개, finishWhen. ② Final 퍼즐 앞 대화에서 증거 제시(`play.talk.before.presents`) → 그 뒤 다른 퍼즐(자물쇠 등). present마다: `accepted`(여러 증거 허용), `miss`, `requires`(순서), `offered`(카드), `tell`(2회 오답 후 문구). **앞 Case 증거도 제시 가능**: 같은 시즌의 앞 Case 증거면 된다(`play_check.dart:871-892` `holds()`; 실제 사용 C04F `s5_ep03_e1`, C07F `s5_ep06_e4`). `offered`를 비우면 SHOW EVIDENCE → 수첩 전체에서 고르기(오답 시 miss 대사만, 자동 공개 없음) | `offered`는 **정확히 2장**(`play_check.dart:894`)이고 화면은 2장 가로 배치(`case_talk.dart:661-679`). 2번 틀리면 정답 카드가 빛난다(`:647,670`). 오답 수는 저장되지 않는다(`:63,132`). 대화에 힌트 버튼이 없다(`final_mission_screen.dart:868-879`, 미션 쪽 `mission_screen.dart:1254-1262`도 같음). present별 증거마다 다른 miss(`TalkPresent.misses`, `case_talk.dart` model:149)는 모델에 있지만 schema에 없다. 다른 시즌 증거 제시는 검사가 막는다 | interview{speaker, portrait, goal, opening, questions[{id,text,lines,requires}], presents[talkPresent], finishWhen, finishLabel}, talkPresent{id, prompt, accepted, lines, miss, offered, tell, requires}. 같은 증거를 두 present가 받으면 뒤 present가 앞 present를 requires해야 한다(`:857-863`). 증거 제시는 파이널의 talk.before에서만 된다(`:932-941`) |
| **evidence recall 독** (`play.recall` + clueInputs `use: recall`) | 미션마다 증거 1개. **앞 Case 증거 가능**(C02M2←`s5_ep01_e2`, C12M2←`s5_ep08_e4`). title, prompt, feedback, miss | **파이널에서는 보이지 않는다**: `_recallFinals = {'ep03_final','ep11_final'}`(`final_mission_screen.dart:600-614`, 런던 id). Seoul 파이널에 recall을 써도 생성은 되지만 화면에는 나오지 않는다 → §2f | clueInputs[{ref, use:"recall"}] 1개(`play_check.dart:230-237`), play.recall |
| **picture_choice** (`imageChoice`) | 그림 보기 3개 이상, altText, `hideOptionNames`, option feedback | — | options[].picture(디스크에 있고 크기가 맞아야 함) |
| **text_choice** (`multipleChoice`) | 보기 3개 이상, 보기별 feedback | — | options |
| **scene_explore_choose** (`multipleChoice` / `explores`) | 둘러볼 spots(kind, `requires`로 잠금, lockedLine, unreadLine), others(빈 곳), 그림 선택지 choices(optionId = options), documentLabel, opening/inside | 선택지 그림은 새로 그려야 한다(requiresAssets). 중간 상태 저장 안 됨 | play.explore. 좌표 `measuredOn`(sha256) 필수(`play_check.dart:283-295`) |
| **dark_room_search** (`investigations`) | finds(보고서 줄 ↔ 그림 위치), spots(헛탭 대사), arrival, doneLine | **오답 제출이 없다**: 다 찾으면 자동 정답(`investigation_search.dart:385-396`). options feedback은 화면에 안 나온다. 저장 안 됨 | play.search |
| **witness_compare** (`dialogues`) | 증인·질문·답, deduction.pair(맞는 진술 짝), `then`(두 번째 비교) | 틀린 짝은 공용 문구 "THE STORIES ARE DIFFERENT"만 나온다. options feedback은 안 나온다. 저장 안 됨 | play.dialogue |
| **trace_deduction** (`deductions`) | clues(흔적), places(optionId), others | 저장 안 됨 | play.traces |
| **lens_inspect_word** (`wordInput` / `inspections`) | spots(`checks`, `requires` 잠금), 라벨 카드 안 word 입력, acceptedAnswers | 저장 안 됨 | play.inspect, play.prompt |
| **record_mismatch** (`records`) | 기록 2장, 줄별 label/value. **다른 줄은 정확히 한 쌍**이고 answer = `id:id`(`play_check.dart:798-804`) | 기록 글씨를 그림 위 좌표(sheet)에 쓰므로 새 기록지는 측정이 필요하다 | play.records{first, second, readTask, compareTask, checkLabel} |
| **syllable_compose** (`wordInput` / `syllables`) | 묶음 2–6개, 모음 ㅣㅏㅓㅡㅗㅜ, `sounds`(첫소리를 고르게, 2–9개), `given`(예시 칸), `final`(받침), `columnHeight`/`row`, `voice`(듣기). 저장됨 | 겹모음, 7묶음 이상 | play.syllables. 정답 = 묶음을 이은 한글(`SyllableRules.validate`) |
| **shape_match** (`matchPairs` / `shapes`, 미커밋·C01 V4 신규) | 그림보다 많은 글자 타일(미끼 포함), answer `letter:picture` 쌍 | 그림 필요 | play.shapes{task, pictures[≥2], letters[≥3]} |

### 1.2 설계자가 자주 물을 질문 — 답

| 질문 | 답 |
|---|---|
| 글자 자물쇠에 미끼 타일? | **불가**(슬롯 = 타일 수). §2a가 필요하다(S) |
| 슬롯 수 = 타일 수? | 그렇다(`letter_lock.dart:44`) |
| timeline 고정 카드·버림 카드? | 된다. 고정 1–3, 버림 ≤2, 놓을 카드 2–6 |
| order_sequence 미끼? | 된다(보기 > 단계) |
| evidence_talk present당 선택지 수? | 카드 방식은 **정확히 2**. 카드 없이 쓰면 수첩 전체(시즌 증거 전부)에서 고른다. 3~4장은 §2b |
| present 수? | 제한 없음(현재 3~4개). finishWhen에 모두 들어 있어야 한다 |
| present가 앞 미션·앞 Case 증거를 요구? | 된다(같은 시즌의 앞 Case까지). 다른 시즌은 검사가 막는다 |
| 2회 오답 자동 공개 끄기? | 카드 방식에서는 못 끈다(`tell`을 빼도 카드는 빛난다, `case_talk.dart:670`). 수첩 방식은 자동 공개가 없다 |
| 앞 Case 증거 recall? | 미션은 된다. 파이널은 §2f 전까지 안 보인다 |
| 다이얼 기호? | 24개 GameSymbol 중에서. 숫자만 |
| number_entry 형식? | 숫자만, `time`(HHMM)만 |
| 단어 입력 다중 정답? | `acceptedAnswers`(정규화 비교). 부분 정답도 목록에 넣으면 된다 |
| Final을 두 단계로("증거로 설득 → 자물쇠")? | 된다: `final.play.talk.before.presents` + 다른 final 퍼즐. C01 V4가 이 방식이다: talk.before(2장 카드 present 2개) → order_sequence(`s5_ep01.g.dart:700-757`) |

---

## 2. 제안하는 엔진 변경

### 2.0 엔진별 시즌 사용 현황 (mission `'type'` 집계: `lib/data/mock/season1|season2`, `lib/data/generated/s3_rome|s4_newyork|s5_seoul`, levels 파일 제외)

| 엔진 | 런던 | 파리 | 로마 | 뉴욕 | 서울 |
|---|---|---|---|---|---|
| letterLock | 0 | 1 (`episode01_mock` TIME) | 8 | 8 | 4 (C02F, C06F, C10M3, C12F) |
| sequence (order_sequence + timeline) | 5 | 2 | 11 | 5 | 10 (timeline 5, order 4, C01F 1) |
| numberCode | 4 | 1 | 0 | 0 | 8 |
| evidence_talk 카드(`choices`) | 0 | C11 (`season2_case11_scenes.dart:453-476`) | 0 | 0 | C01F, C04F, C07F, C09F |
| CaseTalk(대화) 전반 | — | C11·C12 | talkMissions(둘레 대화) | talkMissions | C01, C04, C07, C09 |

지금 있는 letterLock 21개는 모두 타일 = 정답 글자 한 개씩이다(분석 스크립트로 확인). 그래서 "슬롯 = 정답 글자 수"로 바꿔도 기존 콘텐츠의 동작은 같다.

### 2a. 글자 자물쇠 미끼 타일 — **필요**(S4 기준 "미끼 포함"), 크기 S, 위험 낮음

- `lib/features/mission/widgets/letter_lock.dart:44`: 슬롯 수를 `options.length`에서 정답 글자 수(`AnswerChecker.normalize(mission.answer).length`)로 바꾼다. `codeLength`를 쓰는 방법도 있지만, 기존 letterLock에는 codeLength가 없는 것이 대부분이라 정답 길이가 더 안전하다.
- 같은 파일 `:162` 안내 문구: `_loose.isEmpty` → `_full`일 때 "The lock is full. Tap a letter in it to take it out." 같은 문구로. 꽉 찼는데 남은 타일을 탭하면 지금은 아무 반응이 없다(`:73-79`). 작은 흔들림이나 문구를 넣는다.
- `tool/season_gen/puzzle_selection_check.dart:358-363`: "타일 = 정답 글자"를 "정답 글자 ⊆ 타일(중복 수 포함)"로 바꾸고, 미끼 수 상한(예: 정답 +4)과 "미끼 없음" 경고를 시즌 정책에 맞게 추가한다.
- 문서: `puzzle_palette.dart:301` 설명 "each used once"에 "extra tiles are left out" 추가. `palette_facts.dart`도 같은 생성 블록이면 다시 생성한다.
- 영향: 다른 시즌은 동작이 같다(위 표). LockBoxStage(파리 상자)는 슬롯 그림이 정답 길이에 맞춰져 있어 문제가 없다(`lock_box.dart:63,93`).
- 화면: 타일은 `Wrap`이라(`letter_lock.dart:164-176`) 9~10장도 줄이 바뀐다. 6칸 슬롯의 320폭 문제(감사 P2-8)는 그대로이므로 6글자 이상 정답이면 320×568 위젯 테스트를 하나 추가한다.
- 테스트: 미끼가 있을 때 OPEN이 정답 길이에서 켜지고, 미끼를 넣으면 오답이 되는 위젯 테스트 1개.

### 2b. evidence_talk (Final 대화)

| 항목 | 필요도 | 파일·변경 | 크기 | 위험 / 영향 |
|---|---|---|---|---|
| **b1. 힌트 버튼** | **필요**(다른 엔진과 같은 힌트 UX. S4 Final 3개가 대화형) | `case_talk.dart`의 `CaseTalk`에 `hints`, `hintsShown`, `onHint`(선택)를 추가하고 `_Panel`의 "Talk log" 줄(`:496-517`)에 힌트 링크와 열린 힌트를 둔다. `DialogueInvestigation`이 이미 같은 매개변수를 받는다(`mission_screen.dart:1175-1185`). 호출부: `final_mission_screen.dart:868-879`(_talkFinal), `:884-895`(_talkBeforeFinal, 선택), `mission_screen.dart:1254-1262`(_caseTalkStage), `:1192-`(_aroundTalkStage, 선택). 열기는 기존 `_showHint`/`requestTip`(`final_mission_screen.dart:647-655`) | S | 낮음. 파리 C11·C12 대화 미션에도 힌트 링크가 생긴다(힌트가 있으면). 매개변수가 없으면 지금과 같다 |
| **b2. present당 카드 3~4장** | **필요**(Final 찍기 방지) | `tool/season_gen/play_check.dart:894`: `!= 2` → `2..4` 범위. `case_talk.dart:661-679` `_EvidenceChoice`: 3~4장이면 `Row` 대신 2열 `Wrap`/Grid(카드 minHeight 유지, 320폭에서 한 장 ≈ 140dp). `mission_plan.schema.json` talkPresent.offered에 `maxItems: 4` | S~M | 낮음. 2장 콘텐츠(C01, 파리 C11)는 그대로 Row. 3장 이상에서만 새 배치 |
| **b3. "2회 오답 → 정답 카드 빛남" 대체** | **필요**(2회 오답 후 정답 공개 문제) | `case_talk.dart:647,670`. 제안: 1회 오답 = `miss` 대사(지금과 같음). 2회 = `tell`을 **"어느 증거를 다시 볼지"** 문장으로 보여 주고(데이터만: 예 "Read the stone count again."), 카드는 빛나지 않는다. **3회 이상**(상수, 예: `_litAfter = 3`) = 정답 카드 빛남(최후 안전망). 오답 수는 지금처럼 저장하지 않는다(재진입 시 초기화. 안전망이 늦게 오는 정도라 허용) | S | **C01 V4와 파리 C11 동작도 바뀐다**(빛남이 2회 → 3회). C01은 "변경 금지"라서 빛남 시점을 present 데이터로 고르게 하거나(`litAfter` 필드, 기본 2) 사용자에게 확인한다. 파리 테스트 `test/paris_case11_test.dart:385` 주석("Wrong twice: said plainly")과 단언을 확인해야 한다 |
| b4. 증거별 miss 문구 | 선택 | 모델에는 `TalkPresent.misses`(증거 id → 대사)가 이미 있다(`lib/data/models/case_talk.dart:130,149,153`). schema `talkPresent`와 `plan_models.dart`, `generate_case.dart`에 `misses` 맵을 열면 된다 | S | 낮음. "왜 그 증거가 아닌지"를 증거마다 말할 수 있어 b3의 안내가 좋아진다 |

### 2c. order_sequence 화면 안내 — 권장(필요도 중), 크기 S, 위험 낮음
- `lib/features/mission/widgets/question_widgets.dart` `_SequenceQuestionState.build`(`:851-`)의 단계 줄 위에 캡션 한 줄을 넣는다: 비었을 때 "Tap the steps in order.", 진행 중 "Now tap step ${n}."(timeline `timeline_board.dart:156`, letter lock `letter_lock.dart:162`과 같은 `AppText.caption`).
- 영향: 런던 5, 파리 2, 로마 11, 뉴욕 5, 서울 5개 화면에 문구가 생긴다. 텍스트 검색 테스트(`findsOneWidget`)가 같은 문구를 찾는 곳이 있는지는 확인하지 않았다. 문구가 새로 생기는 것이라 충돌 가능성은 낮다.

### 2d. number_entry 오답 뒤 입력 유지 — 권장(P3), 크기 S, 위험 낮음
- `question_widgets.dart:523-528`의 `setState(() => _code = '')`를 지운다. 정답이면 화면이 바뀌므로 지울 필요가 없다. 다이얼(`final_mission_screen.dart:663-688`)과 동작이 같아진다.
- 영향: numberCode 화면 전체(런던 4, 파리 1, 서울 8)와 time 형식. `test/time_code_question_test.dart`에는 초기화 단언이 없다(`clear|empty|reset` 검색). 다른 테스트의 "오답 뒤 다시 입력" 흐름이 Clear를 전제하는지는 확인하지 않았다.

### 2e·2f. 감사 UX P2 목록의 나머지 + 파이널 recall

| 항목 | 필요도 | 파일 | 크기 | 비고 |
|---|---|---|---|---|
| **f. 파이널 recall 표시** | **S4에서 Final이 앞 증거 2개 이상을 쓰려면 사실상 필요** | `final_mission_screen.dart:600-614` `_recallFinals`: 생성 시즌(id가 `s<n>_`로 시작)은 `m.recall`이 있으면 항상 보이게 하는 한 줄 조건 추가. 런던 id는 지금 규칙 유지 | S | 중간. **이미 recall이 생성돼 있지만 숨어 있는 파이널**이 있다: 로마 C07·C11, 서울 C08·C11(생성 파일 검색, 문자열 휴리스틱). 조건을 넓히면 이 네 화면에 독이 새로 생기므로 플레이 확인과 playthrough 드라이버 점검이 필요하다. 원하지 않으면 plan 쪽 플래그(예: `play.recall.onFinal`)로 opt-in한다. 대안: Final talk.before의 present로 앞 증거를 요구하는 방식은 지금도 된다 |
| 퍼즐 중간 상태 저장 확대 | 선택 | 저장 패턴 `mission_screen.dart:1442-1458`(`recordPuzzleState(key, encode)`). 값이 단순한 엔진부터: letterLock 슬롯(id 목록), sequence picks, number `_code`, 다이얼 digits(`final_mission_screen.dart:486`), dark_room_search 찾은 id(`investigation_search.dart:209-213`) | 엔진당 S, 묶어서 M | decode는 모르는 id를 버리도록(timeline/talk처럼) 써야 콘텐츠 변경에 안전하다(§3). 모든 시즌에 영향 |
| dark_room_search·witness_compare의 죽은 오답 피드백 | 선택(정리) | 런타임이 options feedback을 읽지 않는다(`investigation_search.dart:385-396`, `dialogue_investigation.dart` 맨 위 주석). 둘 중 하나: (1) play_check에서 이 두 엔진의 options feedback을 경고로 → plan에서 삭제(S, 권장), (2) 헛탭·틀린 짝에 그 문구를 보여 주도록 연결(M) | S / M | (1)은 데이터만 바뀐다 |
| 6칸 자물쇠 320폭 측정 | 권장(6글자 이상 정답을 쓰면) | `letter_lock.dart:128-141` | S(테스트) | 2a와 함께 |
| 정답 순서 그대로 나열 경고 | 권장(도구) | `puzzle_selection_check.dart`: letterLock 타일 순서 = 정답, sequence/timeline options 순서 = 정답이면 경고. 정답 단어가 letter/question에 그대로 있으면 경고(감사의 "답 노출" 유형) | S | 콘텐츠 영향 없음. 다른 시즌 plan에도 경고가 나올 수 있다(경고만) |
| 편지 고정 보기·용어집 표시·한글 듣기 | 선택(시즌 공통 S6/S7) | 감사 P2-4·5·12 | M | 이번 재설계 범위 밖으로 둔다 |

**필요 / 선택 정리**: 필요 = 2a, 2b1, 2b2, 2b3, 2f. 권장 = 2c, 2d, 정답 순서 경고, 6칸 측정. 선택 = 2b4, 상태 저장 확대, 죽은 피드백 정리.
**작업 순서 제안**: 엔진 PART(2a·2b·2f·2c·2d) 하나로 먼저 끝내고, 전 시즌 회귀(관련 위젯 테스트 + 파리 C11 + 로마·뉴욕 playthrough)를 돌린 다음 Case 재설계 데이터를 넣는다. 데이터가 엔진 변경을 전제하면(미끼 타일, 카드 3장) 엔진 없이 생성하면 검사에서 막힌다(2b2) 또는 화면이 깨진다(2a: 미끼가 슬롯으로 들어감).


---

## 3. 저장 데이터 호환성

모두 코드 정적 읽기 결과다. 테스트·기기 확인은 하지 않았다.

### 3.1 무엇이 어디에 저장되는가

- **Case별 저장**: `GameProgress`는 episode id(`s5_ep05` 등)마다 따로 저장된다. 키는 `AppConstants.progressKeyFor(episodeId)`이고 프로필 이름공간 안에 있다(`lib/data/repositories/progress_repository.dart:66,129-138`, `lib/features/game/game_controller.dart:53-56,73-83`). 시즌 기록은 `SeasonProgress`(activeEpisodeId, solvedEpisodeIds, prologueSeen, difficulty)에 따로 있다(`lib/data/models/season_progress.dart`, `progress_repository.dart:149-160`).
- **GameProgress 필드**(`lib/data/models/game_progress.dart:9-30`): `completedMissionIds`(푼 순서, final 포함), `attempts`/`wrongAnswers`/`hintsUsed`(mission id → 수), `missionStartedAt`/`missionStartPlayMillis`(퍼즐 단계에 들어간 시각), `solveSeconds`, `xpRules`, `badgeIds`, `lookedUpWords`, `behavior`(rechecked, evidenceViewed = 증거 id, words), `examined`(`missionId:thing` 문자열 목록, `:84-89`), `revealed`, `puzzleStates`(키 → 문자열, `:104-107`), `startedAt`/`completedAt`/`playMillis`.
- **mission id는 Case 안에서만 의미가 있다.** id 자체가 `s5_ep05_m1`, `s5_ep05_final`처럼 시즌·Case를 포함하고, 저장도 Case별이다. 지갑(코인)은 프로필 단위이며 `mission:<id>`(보상 1회), `tip:<id>:<n>`(산 힌트) 키를 쓴다(`lib/data/models/wallet.dart:85-86,95`).
- **증거·단서는 저장하지 않는다. 매번 현재 콘텐츠에서 다시 계산한다.**
  - 진행 중 Case: `collectedEvidence`/`collectedClues` = `completedMissionIds`의 각 미션이 **현재 콘텐츠에서** 가진 evidence/clue다(`game_progress.dart:157-165`). 콘텐츠에 없는 미션 id는 `missionById`가 null이어서 조용히 빠진다.
  - 푼 Case: Case Archive가 `e.allEvidence`, `e.allClues`, 즉 현재 콘텐츠의 전부를 보여준다(`lib/features/notebook/season_archive.dart:57-58`, 진행 중은 `:69`).
- **Case 완료는 저장된 값이다.** final을 맞히면 `completedAt`이 기록되고(`game_controller.dart:345-353`) `SeasonProgress.solvedEpisodeIds`에 Case가 추가된다(`:361,393-398`). 미션 id로 다시 계산하지 않는다. 다음 미션은 `currentMission`이 현재 `episode.missions` 순서에서 처음 안 푼 미션을 찾는다(`game_progress.dart:140-155`).
- **퍼즐 중간 상태**(`puzzleStates`)를 쓰는 서울 엔진과 키:
  - timeline_board, syllable_compose: 키 = mission id. 값 = `pv2:<kind>:<version>:<json>`(`lib/puzzles_v2/core/puzzle_rules.dart:98-117`, 연결 `lib/features/mission/mission_screen.dart:1442-1458`).
  - evidence_talk(미션·Final): 키 = `<missionId>:talk`(`lib/data/models/case_talk.dart:9`, `mission_screen.dart:1255-1260`, `final_mission_screen.dart:868-879`).
  - 미션 앞뒤 대화: `<missionId>:talk-before` / `:talk-after`(`case_talk.dart:29-30`, `mission_screen.dart:1190-1200`). 다 들은 대화는 같은 키로 `examined`에 남는다(`:1198`, `final_mission_screen.dart:892`).
  - 회상 독(recall): `examined`에 `<missionId>:recall`로 남는다(`lib/features/mission/widgets/evidence_recall.dart:19-21,113,124`).
  - 나머지 서울 엔진(letterLock, dial, number, word, order, picture, search, explore, trace, lens, record, witness)은 퍼즐 상태를 저장하지 않는다(PART 5-C §0 확인). Final 다이얼은 다시 들어오면 0이다(`final_mission_screen.dart:485-486`).
- **콘텐츠 버전/마이그레이션 장치는 없다.** grep 결과 `migrat`은 프로필 이전용 `lm.migration.legacy.v1` 하나뿐이다(`lib/core/constants/app_constants.dart:53`, `lib/data/repositories/legacy_migrator.dart`). 버전은 pv2 엔진별 `stateVersion`(timeline/syllables 모두 1, `timeline_rules.dart:185`, `syllable_rules.dart:239`)과 에셋 팩 버전(`lib/core/assets/season_pack_storage.dart:109-111`)만 있다. 그 대신 모든 decode가 관대하다: `GameProgress.fromJson`은 이상한 값을 기본값으로 바꾼다(`game_progress.dart:229-300`).

### 3.2 decode가 바뀐 콘텐츠를 견디는가

| 상태 | decode 규칙 | 콘텐츠가 바뀌면 |
|---|---|---|
| timeline (`timeline_rules.dart:341-353`) | 칸 수 ≠ `spec.order.length`, 모르는 카드 id, 중복, 고정 칸 불일치, 고정 카드가 버림 더미에 있음 → null → **처음부터** | 카드 id 하나라도 바뀌거나 카드 수가 바뀌면 깨끗하게 새로 시작한다(안전). **id와 수가 같고 정답 순서만 바뀌면** 예전 배치가 그대로 복원된다. 판이 다 찬 상태일 수 있지만 자동 제출은 없고, 틀리면 다시 배치하면 된다(무해) |
| syllable (`syllable_rules.dart:380-401`) | 블록 수 ≠ `spec.blocks.length`, 모르는 소리 → null | 블록 수가 같고 목표 글자만 바뀌면 예전 조각이 복원된다(무해. 다시 탭하면 된다). C02 M2 한 곳뿐이다 |
| TalkProgress (`case_talk.dart:375-397`) | 현재 장면에 있는 question/present id만 `done`에 남긴다(`:381`). 모르는 beat → opening(`:385`), 줄 번호는 clamp(`:391`). JSON 오류 → start | id를 새로 쓰면 그 단계는 안 한 것으로 돌아간다(안전). **id를 유지한 채 내용·accepted 증거를 바꾸면 예전 완료가 그대로 인정된다.** 새 present를 "이미 보여 준 것"으로 건너뛴다. 남은 `finishWhen`이 모두 done이면 바로 마무리 버튼이 뜬다(`:432,476`. 자동 제출은 아님) |
| 2회 오답 시 정답 표시 카운트 `_misses` | 메모리만(`case_talk.dart:63,132`) | 영향 없음 |
| `examined` `missionId:talk-before` 등 | 문자열 존재 여부만 본다 | 앞 대화를 이미 들은 플레이어에게는 **바뀐 대화가 다시 나오지 않는다**. 이야기 정보가 대화에만 있다면 놓친다 |
| `missionStartedAt` | mission id 키 | 퍼즐 단계에 이미 들어갔던 미션은 다시 열면 **장소·편지를 건너뛰고 퍼즐부터** 보여준다(`mission_screen.dart:257-262`). 새 편지는 "Reread Letter"로만 볼 수 있다 |

### 3.3 재설계 변경 종류별 영향 (진행 중 플레이어)

| 변경 | 이미 푼 미션/Case | 진행 중(미션 안 풂) | 권장 가드 |
|---|---|---|---|
| **문구만** (story/letter/hints/feedback/증거 이름·설명, id 유지) | 수첩과 Archive에 새 문구가 바로 나온다(현재 콘텐츠에서 다시 계산) | 새 문구. 단 이미 퍼즐 단계에 들어간 미션은 새 story/letter를 지나친다(3.2) | 없음. 핵심 정보는 편지와 퍼즐 화면 양쪽에 두기 |
| **정답 변경** (미션/Final) | 영향 없음. 완료는 `completedMissionIds`에 남고 다시 채점하지 않는다(`game_controller.dart:325`). 코인은 이미 지급됨(`wallet.dart:85`) | 새 정답이 필요하다. 이전 `attempts`/`wrongAnswers`가 남아 careful 보너스 XP가 줄 수 있다(사소함) | 필요 없음. 원하면 바뀐 미션만 attempts/wrong 정리(선택) |
| **timeline 카드 id·수 변경** | 무관(푼 미션은 solved로 읽기 전용, `puzzle_rules.dart:125-128`) | decode가 null → 처음부터(안전) | **의미가 바뀐 카드는 id도 바꾼다**(가장 싼 무효화). 수와 id가 같고 순서만 바뀌는 경우는 그대로 둬도 된다 |
| **talk 장면/present 변경**(C04·C07·C09 Final 등) | 무관 | 같은 present/question id를 재사용하면 예전 완료가 이어진다 → 새 질문을 건너뛸 수 있다 | **바뀐 present·question은 새 id**(예: `p_logs` → `p_logs_v2`). 장면 전체를 바꿀 때는 모든 id를 새로 쓰면 decode가 자동으로 start로 만든다 |
| **증거 이름 변경, id 유지** | 수첩/Archive/recall/talk 모두 새 이름·그림. 이후 Case recall도 그대로 동작(id 기준) | 동일 | 없음(권장 방식) |
| **증거 id 추가** | **이미 푼 미션에 붙인 새 증거는 바로 수첩에 나온다**(진행 중: `game_progress.dart:163-164`, 푼 Case: `season_archive.dart:57-58`). 플레이어는 "찾은 적 없는" 카드를 갖게 된다(서사상 어색할 뿐 동작은 정상) | 해당 미션을 풀면 생긴다 | 이후 Case가 그 증거를 recall/present로 **필수** 요구해도 동작은 한다(푼 Case는 allEvidence). 다만 새 카드가 과거 Case에 있다고 Intro나 recall prompt에서 알려 주면 좋다 |
| **증거 id 삭제·변경** | 수첩에서 사라진다. 그 id를 recall하는 미션은 독이 숨는다(`evidence_recall.dart:46-47,132-133`). talk present가 그 id를 accepted로 가지면 **정답 카드가 없어서 Final이 막힌다**. 프로필의 `behavior.evidenceViewed`에 남은 옛 id는 무해 | 동일 | **id 삭제 금지**(정책과 같음). 꼭 필요하면 `season_content_validator` / play_check로 모든 recall·accepted·`earlierEvidence` 참조가 실제 id인지 확인 |
| **증거를 다른 미션으로 이동**(id 유지) | 푼 Case: 무관(allEvidence) | 옛 미션은 풀고 새 미션은 안 푼 플레이어는 그 증거를 잠시 잃는다. 반대 경우는 미리 얻는다 | 같은 Case 안에서 그 증거를 요구하는 뒤 미션이나 Final이 있으면 순서를 확인 |
| **미션 엔진 교체**(id 유지, 예: letterLock → evidence_talk) | 무관. 푼 미션은 새 엔진의 solved 화면으로 보인다 | 옛 엔진 상태는 키나 `pv2:kind`가 달라 읽히지 않는다(timeline→talk는 `id` vs `id:talk`, timeline↔syllable은 kind 접두어가 다름) → 새로 시작(안전). 퍼즐 단계부터 열리므로 새 story/letter를 건너뛴다(3.2) | 엔진을 바꾼 미션은 stale `puzzleStates[missionId]`가 남아도 무해. 정리는 선택. 편지를 꼭 읽혀야 하면 `missionStartedAt`에서 그 미션 키를 지우는 1회 정리를 고려(선택, S) |
| **미션 추가**(Case 중간) | 푼 Case라도 `currentMission`이 새 미션을 "다음"으로 돌려준다(`game_progress.dart:141-143`). Case는 계속 solved(`completedAt` 유지). 지도에 안 푼 미션이 하나 생긴다 | 플레이어가 이미 뒤 미션을 풀었어도 새 미션부터 해야 Final이 열린다 | 미션 수 유지(정책). 바꿔야 하면 기존 id 재사용 |
| **미션 삭제** | `completedMissionIds`의 옛 id는 무시된다(카운트는 현재 미션 기준, `:133-135`). 그 미션의 증거는 진행 중 Case에서 사라진다 | 동일 | 삭제 금지. 그 미션의 evidence id를 다른 미션으로 옮긴다 |
| **Final 변경**(엔진·정답·대화) | 푼 Case는 그대로 solved | 진행 중이면 위 규칙(talk id, 다이얼은 원래 저장 안 함) | talk Final이면 present id를 새로 쓴다 |

### 3.4 질문별 답

- **완료는 시즌/Case별로 저장되는가?** 그렇다. Case별 저장 키 + 시즌·Case가 들어간 mission id(`s5_ep05_m1`). Case 완료는 `completedAt` + `solvedEpisodeIds`로 **저장된 값**이다. 미션 목록에서 다시 계산하지 않는다.
- **옛 콘텐츠로 C05를 푼 플레이어가 재설계된 C08의 C05 증거 recall을 할 수 있는가?** 된다(id 유지 전제). C05가 solved이면 Archive가 현재 콘텐츠의 `allEvidence`를 주고(`season_archive.dart:57-58`), recall과 talk 선택 시트는 이 Archive에서 고른다(`evidence_recall.dart:27-44,85-87,132`; talk 기본 picker `case_talk.dart:116-118`). 이름과 그림은 새 콘텐츠로 보인다.
- **이미 푼 Case에 새 증거 id를 추가하면 수첩에 생기는가?** 생긴다. 푼 Case는 `allEvidence`이고, 진행 중 Case는 이미 푼 미션에 붙인 경우에 생긴다.
- **참고(엔진 카탈로그 담당에게)**: Final의 `recall`은 `_recallFinals`에 등록된 `ep03_final`, `ep11_final`(시즌 1)에서만 화면에 나온다(`final_mission_screen.dart:600-614`). 서울 Final에 plan `recall`을 넣어도 지금은 **보이지 않는다**. 대신 talk Final의 present는 시즌 전체 수첩(이전 Case 포함)에서 증거를 고를 수 있다.

### 3.5 권장 (최소)

1. **정책만으로 충분하다. 콘텐츠 버전이나 마이그레이션 코드는 만들지 않는다.** 증거와 진행이 id 기준으로 다시 계산되고 decode가 모르는 id를 버리기 때문이다.
2. 재설계 규칙 세 줄:
   - (a) mission id와 evidence id는 유지하고 삭제하지 않는다.
   - (b) **뜻이 바뀐 timeline 카드, talk present/question은 id를 새로 짓는다.** 그러면 저장 상태가 자동으로 무효가 된다.
   - (c) 미션 수와 순서를 유지한다.
3. 선택(S): 엔진을 바꾼 미션의 `missionStartedAt` 키를 1회 지워 새 story/letter를 보이게 하는 정리. 출시 전 개발 단계라면 생략해도 된다.
4. 검증: 생성 후 play_check / season_content_validator로 recall·accepted 증거 id가 실제로 있는지 확인한다(담당 섹션 4).

확인하지 않은 것: 배지 규칙(`GameBadge.forEpisode`)이 미션 수 변화에 어떻게 반응하는지, 기기에서 실제 옛 저장을 불러오는 테스트.

---

## 4. 테스트 영향

조사 방법: `test/` 전체에서 `s5_seoul|s5_ep[01]\d|seoul` grep(34개 파일), 각 파일의 expect 확인. 실제 실행은 아래 "실행한 것"만.

### 4.1 Seoul Case 02–12 내용을 직접 박아 둔 테스트 (재설계 시 수정 대상)

| 테스트 | 무엇을 단정하나 | 깨지는 재설계 종류 |
|---|---|---|
| `test/sandbox/s5_seoul_rookie_test.dart` (13개) | **문장·정답 하드코딩.** C02 M1: letter에 `under the hole in the roof`, 마지막 힌트 `wet powder will not fire`, 찾기 보고서 줄 = letter 줄, 오답 straw/note(:39-49). C05 M2·C07 M2: 타임라인 relations 줄이 letter에 있음, `main gate saw nothing`, `goods train`, 정답 = spec.order(:51-62). C05 F: `hold back Japan's power`, `Russia`, `37 steps`, 오답 RUSSIA/CHINA/KOREA 피드백(:64-70, :146-153). C09 M2: `Names are pressed into it.`, 오답 key/ink(:72-81). C11 M3: 정답 `319`, `copy 2 of 3`, `18 + 1 opening poem`, 오답 119/219/318(:83-97). C06 F: 정답 `FORCED`, `Japan ______ Korea to sign it.`, orderFeedback(:101-109). C09 F: talk present id `protect`, prompt `so far from home`(:111-117). C10 F: `nineteen thirty-two`, 숫자 연도 없음, 오답 1919/0429(:119-125). C11 F: `choice subject`, 오답 JAPANESE/HANGEUL/…(:127-132). C12 M3: `the fifteenth of August`, `August is month eight`, 715/814/915(:134-140). glossary 키 moss/knelt/dusk/silk(C06), bureau/pressed(C09), attacked(C10), choice(C11)(:155-171). 첫 테스트: 6개 미션에서 Rookie 단어 수 < Junior, 정답이 레벨마다 같음(:28-37) | 문장 변경 → 해당 `contains` 실패. 정답 변경(C06 F, C10 F, C11 F, C11 M3, C12 M3) → 실패. 타임라인 카드 변경(C05 M2, C07 M2) → relations 단정은 데이터 기반이라 유지되지만 `main gate`/`goods train` 줄 실패. evidence_talk present id 변경(C09 F `protect`) → 실패. Rookie가 Junior보다 길어지면 첫 테스트 실패. **R2/R3 결과를 지키는 회귀 테스트이므로 재설계 PART마다 새 문장으로 갱신(삭제 금지, 의도를 새 설계로 옮김).** |
| `test/sandbox/s5_seoul_case11_test.dart` (3개 + R/J/M 플레이) | C11 M2 = `MissionType.matchPairs`, 정답 `string:string`, 기록 줄 id `copy,for,poems,string`, 값 `WHITE`/`BLACK AND WHITE`/`2 OF 3`/`18 + 1 OPENING`/`JEONG BYEONG-UK`, 카드 note `It is safe under keys of these colours.`, M2에 piano 없음, M3 story에 piano, M3 정답 319(:30-64). 위젯 플레이 M1→M2(맞는 짝 거부)→M3(219 거부)→Final(:97-) | C11 문장·기록 줄 id·정답·엔진 변경 모두 실패. Final(KOREAN) 변경 시 플레이 단계도 영향 |
| `test/sandbox/s5_seoul_syllables_test.dart` (10개) | C02 M2: `거`가 Rookie/Junior에 예시로 고정(`TOP · EXAMPLE`), 정답 `거북선`, Master는 전부 빈칸(:214-240). glossary `tongue`,`gums`(C02)(:193-205). 저장 형식 `pv2:syllables:1:`(:107) | C02 M2 블록·정답·`given` 변경, 엔진 변경 → 실패 |
| `test/sandbox/s5_seoul_case01_test.dart` (21개) | 주로 C01. **C08 Final 엔딩 줄**에 `엄마, 고마워요` 포함, `burnt`/`scorched` 없음(R/J/M, :164-170). C01 V4 파일 17개가 `appOnlySeasonFiles`·pubspec에 있음(:175-187) | C08 엔딩을 다시 쓸 때 `엄마, 고마워요` 문구를 빼면 실패(시즌 틀 S-F2와도 일치하므로 유지 권장). R2 업로드로 C01 파일을 팩으로 옮기면 :184-185 실패 → 테스트도 같이 수정 |
| `test/seoul_case_maps_test.dart` (16개) | Case별 지도 테이블 `ownMaps`: 미션 id → (장소 이름, x, y) 픽셀(:43-~110, C02~C12 전부). 지도 파일 `measuredOn` = 파일 해시, 미션 `location` = 지도 이름(:155-170). 미션 4개 = 핀 4개. 긴 이름 `THE GOVERNMENT OFFICE`(C09), `A SMALL HOUSE IN SHANGHAI`(C10)(:322) | 미션의 장소(location/place) 이름 변경, 핀 위치 변경, 지도 그림 교체 → 실패. 미션 수 변경(4개 아님) → 실패. 문장·정답만 바뀌면 영향 없음 |
| `test/sandbox/s5_seoul_play_test.dart`, `s5_seoul_dev_mode_test.dart`, `s5_seoul_traces_test.dart` | C01 전용(오프닝→Case Closed, 개발자 모드, trace sketch) | C02–12 재설계는 영향 없음 |
| `test/sandbox/s5_seoul_gate_test.dart` (5개) | 시즌이 historical, 12 Case, HistoryGate 막힘 이유는 `history_fact_unchecked|history_levels_pending`만, 통과 시 `s5_seoul_history.g.dart` 생성(:22-63) | dossier를 맞추지 않으면(정답·단서 문구) blocker가 다른 코드로 나와 실패 |

### 4.2 데이터로 동작하는 일반 테스트 (Seoul을 자동으로 돈다)

| 테스트 | 무엇을 단정하나 | 깨지는 경우 |
|---|---|---|
| `test/generated_seasons_test.dart` → `test/sandbox/season_playthrough.dart` (Seoul R/J/M) | ① 생성물이 plan과 같음(`generate_season --target game --check` 동일, :56-61) ② `SeasonContentValidator` 이슈 0(엔진 충돌 검사 포함, `season_content_validator.dart:180`) + 모든 그림 번들(:64-76) ③ 프롤로그 R/J/M 줄 수 동일 ④ 지도 랜드마크가 그 파일 해시에서 측정됨(:97-112) ⑤ 둘러보기 영역 측정·겹침 없음, `UNMEASURED` 없음, `measuredOn` 해시(:116-139) ⑥ picture choice 정답 그림이 장소 그림이 아님 ⑦ 증거 그림 등록·번들 ⑧ **12 Case 순서대로 앱에서 플레이**: 미션마다 힌트 1개, 오답 1회(선택형), Discovery, 엔딩 줄, 재시작 저장 | 생성 안 하고 plan만 고치면 ① 실패. 그림 교체 시 측정 해시 ④⑤ 실패. **엔진 드라이버가 아는 조작만 플레이 가능**: `CasePlayer.answer`(`test/sandbox/single_case.dart:122-188`)는 timeline/records/deductions/syllables/shapes/inspections, `SandboxPlay.answer`(`test/sandbox/sandbox_play.dart:66-125`)는 multipleChoice/imageChoice/sequence/wordInput/letterLock/numberCode/finalCode. evidence_talk Final은 `solveFinal`이 `present.accepted.first` 카드를 탭(:209-222). 새 엔진 조작(예: 미끼 타일의 다른 시맨틱 라벨, 힌트 버튼이 있는 talk의 레이아웃)이 이 드라이버와 어긋나면 실패 |
| `test/sandbox/single_case.dart` / `single_case_test.dart` | 위 드라이버 자체. Seoul 단독 Case 플레이 경로 | 엔진 위젯의 Key(`timeline-card-*`, `case-talk-choice-*`, `syllable-*`, `record-tab-*`)나 시맨틱 라벨(`Letter X`, `Lock n up`) 변경 시 |
| `test/multi_season_test.dart` | Seoul 제목 `The King's Letters of Seoul`, 에피소드 `s5_ep01..12`(:125-140, :165), Seoul 잠금/해제(:425) | Case 수·id 변경, 시즌 제목 변경 |
| `test/season_presentation_test.dart`, `paris_map_test.dart:75`, `rome_integration_test.dart:58,113`, `scene_place_test.dart:191`, `world_map_test.dart:143-188`, `world_archive_test.dart:162,425` | 시즌 목록·지도 파일·표지·World Map 좌표 | Case 재설계는 영향 없음(시즌 단위 변경만) |
| `test/puzzle_palette_test.dart` | 팔레트 id 목록(ready/conditional, :25-51), 개수 | **새 paletteId 추가 시만** 실패(목록에 추가해야 함). 옵션 추가는 무관 |
| `test/season_gen/palette_facts_test.dart:75` | `PaletteFacts.all.length == 31` + 팔레트와 동일 | 새 paletteId 추가 시 `tool/season_gen/palette_facts.dart`도 갱신 |
| `test/puzzle_engine_collisions_test.dart` | London 50 + Paris 48 = 98 슬롯(:236-245). Seoul은 직접 단정 안 함(검사는 validator 경유로 ②에서) | Seoul 영향 없음. 엔진 테이블을 새로 만들면 `puzzle_engine_collisions.dart:145-178`(skipsLetter 표) 쪽 테스트 영향 |
| `test/case_talk_test.dart`, `test/case_talk_mission_test.dart` | talk 저장 문자열 왕복, "이상한 저장은 처음부터"(:123-137), 위젯 동작(질문 열림, 다른 증거는 오답 아님) | evidence_talk 엔진 변경(힌트 버튼, 선택지 수, 2회 오답 후 공개 규칙) 시 위젯 테스트 갱신 필요. 2회 오답 후 빛나는 동작을 단정하는 테스트는 **grep으로 못 찾음**(`glow|tell|twice` 검색) |
| `test/time_code_question_test.dart` | number_entry time 형식. 제출 뒤 초기화 여부를 단정하는 테스트는 **못 찾음** | number_entry "오답 뒤 입력 유지" 변경은 이 파일·`test/mission_play.dart` 드라이버(Clear 동작) 확인 필요 |
| `test/letter_lock_title_test.dart` | 모든 시즌 letter lock 제목 | 미끼 타일 추가 시 영향 적음. 단, `SandboxPlay` letterLock 드라이버가 `find.bySemanticsLabel('Letter X').first`를 탭(`sandbox_play.dart:97-104`) → 미끼에 정답과 같은 글자가 있으면 `.first`가 미끼를 고를 수 있음(정답은 같은 글자라 무해하지만 슬롯 라벨과 겹치는지 확인 필요) |
| `test/difficulty_content_test.dart`, `test/puzzles_v2/puzzle_rules_test.dart:112` | 레벨 구조 일반 규칙, timeline 키 | 일반 규칙 위반 시만 |
| `test/art_assets_test.dart:294`, `test/pubspec_assets_test.dart:60`, `test/season_pack_manifest_test.dart:111-136` | 등록 그림이 디스크·번들(pubspec 또는 팩)에 있음, pubspec 항목이 디스크에 있음, **팩 manifest = 디스크 파일**(경로·크기·SHA-256·version) | 그림 추가·교체 시 `build_manifest.dart` 재실행 안 하면 실패(§5) |

### 4.3 기존 실패 기준선 (Seoul과 무관, 재설계 전부터)
- 메모리 `seoul_case01_v4.md` / `docs/SEOUL_CASE01_V4_GAME_DESIGN.md:376`: 전체 `flutter test` **4030 통과 / 7 건너뜀 / 13 실패**, 13건 모두 기존: asset_optimizer(앱 동봉 Seoul 그림이 최적화 원장에 없음), case_talk_test `only Case 11's final…`(:148, 번들 에피소드 전체에서 talk가 `s2_ep11_final`만이라고 단정 — Seoul talk 때문에 실패), icon_upgrade ×3, single_detective, time_code_question(`only Case 12's train time`, :45 — 시간 형식 미션 목록), visual_placeholders, world_archive, world_map, puzzle_rules(s5_ep03 timeline 키), s9_ep01 카탈로그, season_content `a case mixes puzzle types`(ep10).
- 이전 기준(2026-11-07 `seoul_rookie_audit.md`)은 14건. 새 앱 동봉 그림은 asset_optimizer 실패 목록에 더해진다(새 실패 건수는 아님).
- 재설계로 Seoul evidence_talk·time number_entry가 늘거나 줄어도 case_talk / time_code 기존 실패는 계속 실패(건수 변화 없음). "기존 실패"로 넘기기 전 실패 메시지가 Seoul id를 새로 포함하는지만 확인.

### 4.4 콘텐츠 재생성 파이프라인 (실제 명령, 저장소 루트에서)

```
## 1) plan·levels 수정 후 레벨 검사 (R/J/M 줄 수·같은 게임 여부)
dart run tool/season_gen/case_levels.dart check --season content_pipeline/seasons/s5_seoul/season.plan.json
##    새 줄이 생기면 skeleton으로 J/M 칸을 만든다(쓴 줄 유지)
dart run tool/season_gen/case_levels.dart skeleton content_pipeline/seasons/s5_seoul/cases/s5_ep0N/case.plan.json

## 2) 계획 전체 검사(SeasonQuality + HistoryGate: dossier 정답·단서 문구·사실 연결)
dart run tool/season_planner/plan_season.dart check content_pipeline/seasons/s5_seoul

## 3) 게임 콘텐츠 생성 (validate_plan + PlayCheck 통과해야만 씀; 전부 아니면 전무)
dart run tool/season_gen/generate_season.dart --season content_pipeline/seasons/s5_seoul/season.plan.json --target game
##    확인만: 같은 명령 + --check  (2026-11-09 실행: exit 0, lib/data/generated/s5_seoul 31 files up to date)

## 4) 그림을 바꿨다면 팩 manifest
dart run tool/season_packs/build_manifest.dart [--check]

## 5) 테스트 (위험 기반)
flutter test test/sandbox/s5_seoul_rookie_test.dart test/sandbox/s5_seoul_case11_test.dart test/sandbox/s5_seoul_syllables_test.dart test/sandbox/s5_seoul_case01_test.dart test/seoul_case_maps_test.dart --reporter compact
flutter test test/generated_seasons_test.dart --reporter compact   # Seoul 12 Case R/J/M 플레이스루 (느림)
flutter analyze
```
- 한 번에 하는 길: `dart run tool/season_factory/season_factory.dart run content_pipeline/seasons/s5_seoul [--skip-tests|--full-tests]` (단계: plans → history → doctor → review → pictures → apply → measured(미측정 그림이면 exit 30) → levels(빈 줄이면 exit 35) → generate(`--target game`) → `flutter analyze` + `generated_seasons_test` → packs staging; `season_factory.dart:38-108`). `generated_seasons_test` 실패 메시지도 이 명령을 안내한다(:58).
- 생성 파일 직접 수정 금지: 헤더 해시(`generated.manifest.json`)와 다르면 덮어쓰기 거부(`generate_case.dart:36-41`, `--force`로만).
- **승인(approve.dart)**: Seoul plan은 모두 `draft` 상태로 게임에 들어가 있고 생성기는 note만 출력한다("s5_ep11 is not approved … in the game as drafted", `--check` 출력). 메모리 `historical_mode_part0.md`: 사람 승인 단계는 제거됨 — 역사 게이트는 dossier 자동 검사다. 따라서 **재승인 절차는 필요 없음.** 대신 dossier(`planning/history_dossier.json` cases[].puzzles[])의 `answer`(불일치 시 `history_answer_mismatch`, `tool/season_gen/history_dossier.dart:443`), `clues[].text`(모든 레벨 미션 문장에 있어야 함: `history_clue_not_shown(_at_level)`), `whyOnly`/`whyNot`(`history_uniqueness_missing`, :451-458), timeline 카드 출처(`history_timeline_card_source`, :596)를 정답·카드와 함께 고쳐야 생성된다.
- 내용 규칙(PlayCheck, `tool/season_gen/play_check.dart`): records는 단어가 다른 줄 짝이 정확히 하나, glossary 키는 한 단어, 레벨 줄 수 동일, 같은 Rookie 줄은 J/M도 하나(메모리).

### 4.5 실행한 것 (2026-11-09, 읽기 전용)
- `flutter test test/sandbox/s5_seoul_rookie_test.dart test/sandbox/s5_seoul_case11_test.dart --reporter compact`: **20 통과 / 0 실패**, 약 12초.
- `generate_season.dart … --target game --check`: exit 0, 생성물 최신.
- `case_levels.dart check --season …s5_seoul/season.plan.json`: exit 0, 12 Case 모두 "every level written, the same game".
- `build_manifest.dart --check`: 최신, `season_05_seoul` 101 files, 86,991,042 bytes, v`3fc49c8ba85d80f6`.
- 전체 `flutter test`, `generated_seasons_test`, `flutter analyze`는 **실행하지 않음**.

---

## 5. R2 / 에셋 팩 영향

### 5.1 현재 구조
- London만 앱에 통째로 들어가고, 다른 시즌은 `cover/`만 앱에, 나머지 그림은 R2 시즌 팩으로 내려받는다(`tool/season_packs/season_manifests.dart:9-21` `shipsInApp`).
- 팩 내용은 `pubspec`이 아니라 **디스크의 `assets/seasons/<folder>/` 전체**를 측정한다(`measureSeasonPacks`, :52-71). 단 `appOnlySeasonFiles`(:27-50)에 있는 파일은 팩에서 빠지고 pubspec에 파일 단위로 등록되어 앱에 동봉된다(`pubspec.yaml:100-126`).
- 앱이 쓰는 manifest: `lib/core/assets/season_pack_manifests.g.dart` (Seoul: `:444-446`, version `3fc49c8ba85d80f6`, 101 files). version = 파일 목록(경로·크기·SHA-256)의 해시. R2 객체는 `objects/<sha256>.<ext>`, `manifests/<folder>/<version>.json`(`stage_packs.dart:17-19`).
- R2 현황(메모리 `seoul_case01_v4.md`): Seoul 팩 `3fc49c8ba85d80f6` 2026-11-09 업로드(지도 우물 패치 1개 + manifest). 이전 `f4a5c1af…` 유지. 파일은 SHA 이름이라 바뀐 것만 다시 받는다.
- 현재 앱 동봉(팩 밖) Seoul 파일 22개: C11 M2 2장, C02 M1 3장, C01 V4 8장 + 음성 9개(`season_manifests.dart:26` shortcut 주석: "다음 업로드 때 팩으로").
- 주의: git status상 `palace_map.webp`, `season_pack_manifests.g.dart`가 아직 미커밋(업로드는 끝났지만 커밋 전).

### 5.2 Case가 기존 그림을 재사용할 때 (그림 파일 불변)
- 팩·manifest·R2 **변경 없음.** plan의 그림 경로만 바꾸고 생성.
- 확인할 것: `generated_seasons_test`의 "모든 그림 번들"(:64-76)과 `art_assets_test.dart:294`. 다른 Case 폴더 그림을 써도 같은 팩 안이면 문제 없음.
- 그림을 둘러보기·찾기·지도 핀에 새로 쓰면 그 그림 위 영역을 **측정**해야 한다(plan `measuredOn` = 파일 해시, `UNMEASURED` 노트 금지; `generated_seasons_test.dart:116-139`). 팩토리 6단계가 격자 시트를 만들고 exit 30.
- 미션 장소 이름·핀을 바꾸면 Case 지도(`season.plan.json` art.caseMaps)와 `seoul_case_maps_test.dart` 테이블 갱신.

### 5.3 새 그림을 추가하거나 기존 그림을 교체할 때
- 생성: 사용자 정책상 새 그림은 **사양만 적고 생성 금지**(시즌 틀). 생성이 승인되면 `assets.manifest.json`에 항목(assetId, type, use, caseIds, outputPath는 시즌 폴더 안) → `dart run tool/asset_pipeline/asset_pipeline.dart --manifest content_pipeline/seasons/s5_seoul/assets.manifest.json --generate --max-budget <usd> --only <assetId>` → `--apply --only <assetId>`. 예산: `ImageBudgets.of('s5_seoul') == 12.00`(`season_factory_test.dart:144`), 누적 `planning/factory.json` spentUsd ≈ 6.0857(메모리).
- 주의(메모리 `seoul_case11_m2.md`): `asset_pipeline --wiring --write`는 다른 Case 행까지 다시 써서 오래된 Case 지도를 되살린다 → 자기 행만 손으로 추가.
- **시즌 폴더에 파일이 하나라도 생기면 팩 version이 바뀐다.** 두 가지 길:

| 길 | 할 일 | 결과 |
|---|---|---|
| A. 앱 동봉(업로드 없이, 지금까지 쓴 shortcut) | 파일 경로를 `appOnlySeasonFiles`(`tool/season_packs/season_manifests.dart:27`)에 추가 + `pubspec.yaml`에 파일 단위 항목 추가 → `build_manifest.dart`(version 그대로여야 함, `--check`로 확인) | 팩 version 불변, R2 작업 없음. 앱 크기만 증가. `asset_optimizer` 기존 실패 목록에 그 파일 추가됨. 투명 PNG→WebP 등 최적화는 `asset_pipeline`이 처리 |
| B. 팩에 넣기(R2 업로드) | `build_manifest.dart` → 팩토리 9단계 `dart run tool/season_factory/season_factory.dart packs content_pipeline/seasons/s5_seoul`(manifest 재작성, 버킷과 비교, 새 객체만 stage, 전송 없음) → **사용자 승인 후** `season_factory.dart upload content_pipeline/seasons/s5_seoul --approved`(그림 먼저, manifest 마지막, HTTPS로 다시 읽어 확인). 수동 경로: `dart run tool/season_packs/stage_packs.dart --season season_05_seoul --known keys.txt --stage build/season_packs` | 새 version. 업로드 전에 앱을 빌드하면 **다운로드가 깨진다**(새 version manifest가 버킷에 없음; 메모리 `seoul_case11_m2.md`). 업로드는 별도 승인 필요(배포 행위) |

- 기존 그림을 같은 경로로 **교체**: 팩 SHA가 바뀌므로 길 B만 가능(appOnly는 경로 단위라 같은 경로를 팩에서 빼면 옛 R2 파일 대신 앱 파일을 쓰게 되지만, 그 경로 전체가 팩 밖으로 나감). 교체 시 그 그림 위 측정(`measuredOn`)도 다시 해야 함. 원본은 `content_pipeline/asset_originals/…`에 백업(지도 우물 작업 관례).
- 파일 삭제: 사용자 지시로 기존 이미지는 지우지 않아 왔다(V4 §9-2). 쓰지 않는 파일도 팩에 남아 다운로드 용량에 포함된다(Play 기준 500MB 상한, 메모리 `release_part5d.md`).
- 다음 Seoul 업로드 때 한꺼번에: appOnly 22개 + 재설계 신규 파일을 `appOnlySeasonFiles`·pubspec에서 빼고 팩으로 옮기기 → `s5_seoul_case01_test.dart:180-187`(appOnly·pubspec 포함 단정)과 `season_pack_deploy_test.dart:42`(c11_copy_list가 앱 동봉) 테스트도 같이 수정.

### 5.4 권장
- 재설계 PART 동안은 **길 A**(appOnly + pubspec)로 쌓고, 시즌 재설계가 끝난 뒤 한 번 길 B로 업로드(사용자 승인). 업로드 뒤 앱 빌드 순서 지키기.
- 그림 재사용이 가능하면 우선(팩·측정 비용 0). 단 둘러보기/찾기 그림은 영역 재측정 필요.

---

# §C1 Case 02~05 (독립 사건 설계)

## Seoul Case 02–05 재설계안 v2 — 독립 사건판 (구현용)

- 작성 2026-11-09. 저장소는 읽기만 했다(수정·생성·커밋 없음). 이 문서만 썼다.
- **정책**: §0 정책(2026-11-09 확정)가 이전 `season_frame.md`의 S-F1(물방울 쪽지 시대 이동·Intro 첫 줄), S-F2(편지 상자·지키미 쪽지 사슬), 가문 공개·"But why?" 회수, 앞 Case 증거 recall/present를 **철회**했다. 이 문서는 `redesign_c02_05.md`(v1)를 그 정책에 맞게 고친 것이다. v1에서 연속성과 무관한 개선(Final 재설계, 정답 노출 제거, 섞은 timeline, C04 M3 엔진 교체, 조심태·정약용 역할, 대원군 한 줄 등)은 모두 유지했다.
- 근거(직접 읽음): 각 `s5_ep0{2..5}/case.plan.json`·`levels.json`(교차 참조는 grep으로 전수 확인), `lib/data/generated/s5_seoul/s5_ep0N.g.dart`(recall·present·ending evidence), `s5_seoul_*.g.dart`, `planning/history_dossier.json`(Case 02–05 puzzle·fact·fiction), `engine_save_impact.md`, `tool/season_gen/play_check.dart:229-236`(recall 규칙), `clue_graph_check.dart`(경고 규칙), `lib/features/mission/widgets/evidence_recall.dart`.
- 대상: 영어를 배우는 한국 어린이 8~12세. glossary 한국어 유지. "어린이 시뮬레이션"은 **설계 검토**이며 실제 테스트가 아니다.
- 단어 수는 `scratchpad/wc2/count.py`로 실제 셌다(영문 토큰, "King's"·"Yak-yong"은 1어, 자모 기호는 세지 않음).

## 공통 전제 (4개 Case)

1. **엔진 전제(v1과 같음)**: (T1) present당 카드 3장, 2회 오답 뒤 `tell`은 "어느 카드를 다시 볼지" 안내, 정답 카드 빛내기는 3회째부터. (T2) talk Final(`_talkFinal`)에 힌트 버튼. C04만 T1·T2를 쓰고, C02는 talk.before present에 T1만 쓴다.
2. **화면 순서 = plan 순서**(셔플 없음). 모든 선택지·카드는 정답 순서가 아닌 순서로 적었다.
3. **Seoul Final의 recall은 화면에 안 나온다**(`final_mission_screen.dart:600-614`). 새 Final은 근거를 letter나 이 Case의 카드 present로 보여 준다. 이제 Final이 다른 Case 증거를 쓰지 않으므로 "Final recall 해제" 엔진 변경은 **필요 없다**.
4. **저장 규칙**: mission id·evidence id·clue id 유지·삭제 없음, 미션 수 유지. 뜻이 바뀐 present·카드는 새 id. 증거는 id를 유지하고 이름·설명만 바꾼다.
5. **Intro 형식(새)**: 첫 줄은 "계절·연도 + 탐정이 어디의 누구 손님인지". 시대 이동 줄·물방울 쪽지 규칙 줄은 없다. 탐정이 그 자리에 있는 이유는 "손님" 또는 "왕이 불렀다"로 Case 안에서 끝난다.
6. **물방울**: 4개 Case 모두 그림에 쪽지의 물방울이 있거나(C02 `find_note*.webp`, C05 `c05_coal_box.webp` 계열) 텍스트에서 쪽지의 표지 역할을 한다. 그래서 지우지 않고 **그 Case의 인물이 자기 이유로 그린 표시**로 다시 설명한다(가문 표시 아님). 서로 다른 Case의 물방울이 같다는 말은 어디에도 남기지 않는다.
7. **증거 이름에서 "(연도)" 시리즈 이름 제거**: `The Water-Drop Note (1592/1795/1866/1895)`는 시리즈를 암시하므로 Case별 고유 이름으로 바꾼다(id 유지).
8. **역사 사실 id**: C02 M2·C04 M1이 dossier에서 Case 01의 fact(`s5_ep01_h3/h10/h11/h12`)를 가리킨다. 같은 진술·같은 출처를 그 Case의 새 fact id로 복사해 Case 안에서 닫는다(내용 변경 없음, 출처 재확인 불필요 — 원본이 source_checked).
9. Hangul 규칙: 새 문구에 한글 단어를 추가하지 않았다(기존 C02 `거북선`, C04 `나/다`·자모 표기만 그대로).
10. `history_clue_not_shown`: dossier clue 구절은 R/J/M 모든 레벨 텍스트에 글자 그대로 넣는다(각 Case에 구절 명시).
11. **들어오는 참조(이 문서 범위 밖)**: C06 recall `s5_ep05_e4`·`s5_ep05_e1`, C07 `s5_ep05_e1`은 해당 Case 재설계에서 처리한다. 이 문서는 id를 유지하므로 그쪽이 바뀌기 전에도 아무것도 깨지지 않는다.

---

## Case 02 — The Turtle Ship Before Dawn

### 1. 제목·역사 배경
- 제목 유지: **The Turtle Ship Before Dawn**.
- 1592년 음력 4월 11~12일 밤, 여수 전라좌수영. 이순신은 1591년 2월부터 전라좌수사(h6). 거북선 포 시험 4/12(난중일기, h5), 4/13 일본 선단 부산 도착(h3), 5월 옥포 첫 승리(h4).

### 2. 독립 사건 목표(한 문장)
새벽 대포 시험 직전 창고에서 사라진 화약이 도둑맞은 것인지, 누가 왜 옮긴 것인지를 이 밤의 증거로 이순신에게 증명해 시험을 진행시킨다.

### 3. 인물 동기
| 인물 | 동기 |
|---|---|
| 이순신 | 전쟁이 곧 올 수 있어 시험을 꼭 해야 한다("Wet powder will not fire."). 명령 없이 화약을 옮긴 수병을 판결해야 한다. |
| 함(보급 군관) | 화약 책임자. 빈 창고를 보고 도둑이라 믿는다. 한자만 읽고 King's letters는 못 읽는다. |
| 석(젊은 수병) | 자정 뒤 지붕 구멍으로 비가 들이치자 화약 12통을 거북선으로 옮겼다. 함은 멀리서 자고 있었고 비는 기다려 주지 않았다. 그가 쓸 줄 아는 글자는 **창고 벽 글자판과 할머니에게서 배운 King's letters**뿐이라 그 글자로 쪽지를 썼고, 함도 알아보게 **물방울(= 비)** 을 그려 두었다. |

(v1의 "할머니가 '물방울 쪽지를 쓰면 탐정이 온다'고 했다" 동기는 **삭제**. 물방울은 함에게 "비가 들어왔다"를 알리는 그림이다.)

### 4. Intro — 새 Intro (R 전문, 6줄 — 기존과 같은 줄 수)
1. Spring, 1592: the fourth month of the moon calendar.
2. You are a detective, a guest of Admiral Yi Sun-sin at Yeosu, on the south coast.
3. He commands the navy here. War with Japan may come soon.
4. Before the war, he built a turtle ship, with a roof over its deck.
5. "Today we test its cannons," he says. "We must be ready."
6. Before dawn, a bell rings at the store room.
- synopsis 유지(`A note with a small water drop is waiting on the empty shelf.` — 이 Case 안의 사물). hook 유지(`The cannon test is at dawn.`).
- objectives (R): `Search the empty store room.` / `Read the blurred note.` / `Count the barrels on the ship.` / `Show the Admiral what really happened.`
- 이해 검사: 시대(1592), 탐정의 자리(이순신의 손님), 왜 시험이 급한가(전쟁이 올 수 있음), 사건 시작(종) — 모두 이 6줄 안에 있다.

### 5. Mission 1 — The Empty Store Room
- **목적**: 화약이 왜 위험했는지(비) 확인하고 쪽지를 확보한다.
- **유형**: `dark_room_search` · `investigations` · `multipleChoice`(변경 없음, 그림 4장).
- **화면 단서 (R)**: story[1] `"All the gunpowder is gone!" Ham shouts. "A thief took it!"`(v1: "Twelve barrels" 삭제 — M3 정답 노출 제거). Ham's report 3줄(under / next to / on) 유지. question `Which thing shows that rain came in over the powder?`(J `Find all three things. Which one shows that rain came in over the powder?` / M `Locate all three things. Which one proves that rain came in over the powder?`).
- **options (plan 순서)**: `straw` The wet straw → `note` The small paper → `bucket` The bucket of rain.
- **정답**: `bucket`.
- **8세 풀이 경로**: ① 이순신 "Wet powder will not fire." → ② 보고서 3줄의 under/next to/on으로 세 물건 탭 → ③ 질문 핵심어 "rain came in over" → ④ 지붕 구멍 아래 = 양동이.
- **선택지 대입**: straw — 젖었지만 문 옆, 통을 끌고 나간 자리. note — 선반 위 종이, 물방울은 **그린 것**이지 비가 아니다. bucket — 지붕 구멍 아래, 빗물 가득 → 유일.
- **힌트**: H1 `Read each line of the report. Each one says where a thing is.` / H2 `Which thing is under the hole in the roof?`
- **오답**: straw `The straw is wet, but it is next to the door. It shows the way the barrels went out.` / note **(변경)** `The water drop on the paper is drawn, not rain. What is under the hole in the roof?`
- **discovery (변경)**: title `A WATER DROP` 유지 / detail R `Letters Ham cannot read, and a drawn water drop. Who left this note, and why?` (J `Letters that Ham cannot read, and a water drop drawn beside them. Who left this note, and why?` / M `Letters Ham cannot read, beside a drawn water drop. Who left this note, and to what end?`)
- **상태 변화**: 비가 지붕으로 들어와 화약 위에 떨어졌다. 누군가 통을 옮겼고, King's letters로 쪽지를 남겼다.
- **다음 미션 필요 이유**: 번진 쪽지에 화약 행방이 적혀 있다.
- **증거 e1 (id 유지, 이름 변경)**: name `The Note on the Shelf` / description `A short note in the King's letters, with a small water drop drawn on it. It lay on the shelf, under the hole in the roof. The rain has blurred it.`

### 6. Mission 2 — The Blurred Note (글자 원리를 이 화면에서 가르친다)
- **목적**: 번진 쪽지를 해독해 화약 행방을 안다.
- **유형**: `syllable_compose` · `syllables` · `wordInput`(변경 없음). 정답 `거북선`, blocks 3개, sounds `[ㄱ,ㄴ,ㅁ,ㅂ,ㅅ,ㅈ]` 불변.
- **recall 제거**: `play.recall`(Read the Blurred Note / Which page of your notebook shows how the letters are made?)과 clueInputs `s5_ep01_e2`(use recall) 삭제. 미션은 recall 독 없이 바로 퍼즐로 간다.
- **story (R, 새 전문)**
  1. `On the store room wall hangs a small wooden board.`
  2. `"The young sailors learn the King's letters from it," Ham says. "I cannot read them."`
  3. `"I read only Chinese letters."`
  4. `The rain has blurred the note. Only parts of three letters are left.`
- **가르치는 주체**: 창고 벽의 **수병용 글자판**(이 Case의 물건)과 그것을 가리키는 함. M3에서 석이 "I learned from the board in the store room"으로 확인한다. (대안 "이순신이 직접 원리를 설명"은 쓰지 않는다: 1592년 해례본 원리를 실존 인물이 강의하는 것은 근거 없는 창작이 커진다.)
- **letterIntro (R)**: `The board on the store room wall:` (J `The board on the store room wall, and what the rain left:` / M `The board on the store room wall, and what the rain spared:`)
- **letter (R 전문)**
  ```
  THE SAILORS' LETTER BOARD
  The King's letters copy the mouth:
  ㄱ = the back of the tongue
  ㄴ = the tongue
  ㅁ = the lips
  ㅅ = the teeth
  A stronger sound adds one line.
  ㄴ + 1 line = ㄷ
  ㅁ + 1 line = ㅂ
  A flat line goes under the first sound.
  A standing line goes on its right.
  A sound at the bottom comes last.
  ```
  - J/M: 같은 정보, "one step stronger" 대신 dossier clue `stronger`를 그대로 포함("A stronger sound adds one more line." / "Each stronger sound earns one more line."). 레벨별 줄 수 동일(12).
- **blocks.line (R)**: G1 `Group 1: the back of the tongue. A standing line, with a dot on its left.` / G2 `Group 2: the lips + 1 line. A flat line, with a dot under it. The back of the tongue at the bottom.` / G3 `Group 3: the teeth. A standing line, with a dot on its left. The tongue at the bottom.`
- **정답**: `거북선`.
- **8세 풀이 경로**: ① 벽 글자판을 읽는다(이 화면) → ② G1: back of the tongue = ㄱ, standing+dot left = ㅓ → 거 → ③ G2: lips + 1 line = 판의 `ㅁ + 1 line = ㅂ`, flat+dot under = ㅜ, bottom back of the tongue = ㄱ → 북 → ④ G3: teeth = ㅅ, ㅓ, bottom tongue = ㄴ → 선.
- **선택지 대입**: 초성 6개 중 "lips + 1"은 ㅂ 하나(ㅁ은 +1이 아님), "teeth"는 ㅅ(ㅈ은 teeth + 1). 모음은 점 위치로 하나, 받침은 각 1개 → 단일 정답.
- **힌트**: H1 `Group 1 is at the top. Find the back of the tongue on the board.` / H2 `The lips + 1 line is ㅂ. Choose each sound, then its line and dot.`
- **오답**: 거묵선 `Group 2 is the lips + 1 line: ㅂ, not ㅁ.` / 거북서 `Group 3 has a sound at the bottom: the tongue.` / 가북선·거북전(유지).
- **상태 변화**: 쪽지 = 거북선 → 화약은 거북선에 있다.
- **다음 미션 필요 이유**: 배에 가서 화약이 다 있는지 세어야 한다.
- **증거 e2**: 이름 유지, description `The note, rebuilt with the sailors' letter board. It says 거북선: the turtle ship.`(← "rebuilt with Sora's board")
- glossary: `gums` 삭제, `lips: 입술`, `chinese: 중국 글자(한자)`, `board: 판` 추가.

### 7. Mission 3 — Under the Turtle's Back
- **유형**: `number_entry` · numberCode, codeLength 2, 정답 **12** 불변.
- **화면 단서**: 석의 4줄 letter 유지(after midnight / four barrels each time / three times / ship's roof keeps rain off).
- **8세 풀이**: four, three를 찾고 "each time"·"three times" → 4×3 = 12(H2 `Four barrels each time. How many times did he go?`로 4+4+4 가능).
- **대입**: 04(한 번)·03(횟수)·07(덧셈) 피드백 유지, 21 = orderFeedback.
- **transition (R)**: `Ham opens his book from sunset: twelve barrels.` / `"All twelve are here," Ham says. "But he moved them with no order!"` / `The sky turns grey. The Admiral is coming aboard.`
- **talk.after (Seok, 새 R 전문)**
  - SEOK `I left a note. Did you read it?` / YOU `I did. Why not wake Ham?`
  - SEOK `Ham was asleep. The rain would not wait. So I moved the barrels.`
  - SEOK `I learned the King's letters from the board in the store room, and from my grandmother.`
  - SEOK `Ham cannot read the King's letters. So I drew a water drop for him. It means rain.`
  - (← 현행 `I did. And the water drop on it.` / `My grandmother taught me that mark.` 교체, v1의 "a detective will come" 줄 삭제)
- **증거 e3 "The Dry Barrels"**: `Twelve barrels of gunpowder, all dry under the turtle ship's roof: as many as at sunset. Seok carried them there in three trips.`
- **상태 변화**: 화약 12통 무사, 석이 옮김, 물방울 = 비. 함은 처벌을 요구한다.
- **다음 미션 필요 이유**: 이순신이 판결한다.

### 8. Final — The Admiral's Judgment (v1 유지, 이 Case 증거만)
- **유형**: talk.before(present 3, `talkMissions`, speaker `yi_sunsin`) → `text_choice` · `finalMission` · `multipleChoice`. 기존 `letter_tile_lock`(DRAGON) 폐기.
- **talk.before**: goal `Show the Admiral what really happened to his powder.` / ADMIRAL `Ham says Seok took my powder with no order.` / ADMIRAL `Show me what happened, Detective.`
  | id | prompt (R) | offered (plan 순서) | accepted | 맞힌 뒤 | miss | tell |
  |---|---|---|---|---|---|---|
  | `p_danger` | "Was my powder safe in the store room?" | e3, e1, e2 | **s5_ep02_e1** | YOU No, sir. The note lay under a hole in the roof. Rain came in over the powder. / ADMIRAL And wet powder will not fire. | That does not show the store room. | Which card was found in the store room? |
  | `p_how` | "How did you know where to look?" (requires p_danger) | e1, e3, e2 | **s5_ep02_e2** | YOU Seok's note named the turtle ship. / ADMIRAL A note in the King's letters. Clever boy. | That does not show where the powder went. | Which card says what the note says? |
  | `p_count` | "Is any of my powder missing?" (requires p_how) | e2, e3, e1 | **s5_ep02_e3** | YOU None, sir. Twelve barrels, all dry, as many as at sunset. / ADMIRAL Then nothing was stolen. | That does not count the barrels. | Which card counts the barrels? |
- **퍼즐**: letterIntro `Your three cards say:` / letter `Rain came in through the store room roof.` / `Seok's note named the turtle ship.` / `Twelve dry barrels are on the ship, as many as at sunset.` / question `What really happened to the powder? Tell the Admiral.`
- **options (plan 순서)**: `thief` A thief took four barrels in the night. → `shiproof` Seok moved the powder because the ship's roof let rain in. → `seok` **Seok moved all twelve barrels to the turtle ship, out of the rain.** → `ham` Ham moved the powder to the ship before the rain.
- **정답**: `seok`.
- **8세 풀이 경로**: ① 카드 3장을 차례로 보여 줌(비/쪽지/12통) → ② letter 3줄 → ③ 문장마다 틀린 곳: 4통 도둑? 12통 다 있음 / 배 지붕? 비는 창고 지붕 / 함? 함은 자고 있었고 석이 "I moved the barrels" → ④ seok.
- **대입 검사**: thief ↔ e3(12 = 해 질 녘 수) 모순. shiproof ↔ e1·M3 letter("The ship's roof keeps the rain off") 모순. ham ↔ M3 talk "Ham was asleep … So I moved the barrels" 모순. seok = e1+e2+e3 일치. 단일.
- **힌트**: H1 `Check each sentence with your three cards.` / H2 `Who carried the barrels? How many? Which roof had a hole?`
- **오답**: thief `Twelve barrels are on the ship, as many as at sunset. Nothing was stolen.` / shiproof `The ship's roof keeps the rain off. Which roof had a hole?` / ham `Ham was asleep. Who said, "So I moved the barrels"?`
- successMessage `That is the truth. Seok saved the powder!`
- **transition (R)**: `"Seok, you broke an order," says the Admiral. "But you saved my test."` / `Dawn comes. The Admiral walks along his turtle ship.` / `Its roof is like a turtle's back, with spikes. At the front is a dragon's head, with a cannon in its mouth.` (v1의 "Seok puts his note in his family's letter box." **삭제**)
- **Final 증거(이 Case만)**: `s5_ep02_e1`, `s5_ep02_e2`, `s5_ep02_e3`. clueInputs: c1/c2/c3(또는 e1~e3) `answerDerivation`만. `s5_ep01_c1` 삭제.

### 9. Ending (새 전문 핵심)
- ADMIRAL `My powder is dry, and my ship is ready.` (← Intro 문제 해결)
- 역사(유지): `That day, the twelfth of the fourth month, the cannons were tested.` / `Yi Sun-sin wrote it down in his war diary.` / `The next day, Japanese ships covered the sea at Busan.` / `The war had begun. Yi Sun-sin had prepared for it.` / `In the fifth month, his navy won its first victory at sea, at Okpo.`
- **교체**: `Seok's water drop is just like Bun-i's.` → SEOK `The King made these letters so that people could learn them easily.` / `Who taught my grandmother? I never asked.` → SEOK `Even a sailor like me can write.` (근거: 새 fact `s5_ep02_h11` = 서문 "쉽게 익혀 날마다 편하게 쓰게", C01 h5 복사)
- caseSummary (R): `Rain came through the store room roof. Seok, a young sailor, carried all twelve barrels of gunpowder to the turtle ship. He left a note in the King's letters, with a water drop for the rain. The detective showed the Admiral that nothing was stolen. Yi Sun-sin had built the turtle ship before the war. Its front was a dragon's head. On the twelfth day of the fourth month of 1592, its cannons were tested. His war diary records it. The next day, Japanese ships came to Busan, and the war began. In the fifth month, his navy won its first victory at sea, at Okpo.`

### 10. 역사 학습 + 사실/창작
- 사실: 거북선 구조(h1), 여수 전라좌수영(h2·h6), 4/12 포 시험(h5), 4/13 부산(h3), 5월 옥포(h4). **새 fact(Case 안 복사)**: `s5_ep02_h7`(= ep01_h3 자음은 발음 기관을 본뜸), `h8`(= h10 센소리는 획을 더함), `h9`(= h11 모음은 점과 선), `h10`(= h12 모음 위치·받침), `h11`(= h5 서문: 쉽게 익혀 쓰게). reveal realHistory에 1줄 추가(R): `In 1446, a book explained the King's letters. Their shapes copy the mouth, and a stronger sound adds a line.` `The King wrote that he made them so that people could learn them easily.`
- v1의 미검증 일반화 "officials wrote in Chinese letters. Many ordinary people learned…"는 **삭제**(출처 있는 h11로 대체).
- IN THIS MYSTERY (R): `Seok, Quartermaster Ham, the rain, the missing gunpowder and Seok's note are made up.` / `The sailors' letter board is made up. Its rules come from the 1446 book about the letters.` / `Yi Sun-sin was real, but his words and his judgment in this story are made up.`

### 11. R/J/M 예시와 실제 단어 수
| # | R | J | M | R/J/M |
|---|---|---|---|---|
| 1 | He commands the navy here. War with Japan may come soon. | He commands the navy here, because a war with Japan may come soon. | He commands the navy on this coast, for war with Japan may come at any time. | 11/13/16 |
| 2 | "The young sailors learn the King's letters from it," Ham says. "I cannot read them." | "The young sailors learn the King's letters from this board," Ham says, "but I cannot read them." | "The young sailors study the King's letters from this board," Ham says, "though I cannot read a word of them." | 15/17/20 |
| 3 | A stronger sound adds one line. ㅁ + 1 line = ㅂ. | A stronger sound adds one more line, so ㅁ with one more line is ㅂ. | Each stronger sound earns one more line, which turns ㅁ into ㅂ. | 8/13/10 |
| 4 | Ham cannot read the King's letters. So I drew a water drop for him. It means rain. | Ham cannot read the King's letters, so I drew a water drop for him. It means rain. | Ham reads no King's letters, so I drew him a water drop that even he could read: rain. | 17/17/18 |
| 5 | What really happened to the powder? Tell the Admiral. | Which sentence tells what really happened to the powder? Tell the Admiral. | Which account of the night fits every piece of your evidence? Tell the Admiral. | 9/12/14 |
- 정보량은 레벨마다 같다. 3번 J/M은 letter 안에서 두 줄로 나뉘어도 같은 정보(줄 수는 레벨 공통으로 맞춘다).

### 12. 외부 의존 원장
| # | 위치 (현행 또는 v1) | 현재 내용 | 결정 | 대체 텍스트 / 데이터 변경 |
|---|---|---|---|---|
| X1 | plan M1 `clueInputs` | `s5_ep01_c1` textMention ("Bun-i, the water-carrier of 1446…") | **제거** | 항목 삭제(M1 clueInputs 비움) |
| X2 | M1 `discovery.detail` | "Bun-i, the girl who carried water, wrote the first note in 1446. Who draws her water drop now?" | **Case 안에서 완결** | §5 discovery 문구(Letters Ham cannot read…) |
| X3 | e1 name | "The Water-Drop Note (1592)"(연도 시리즈) | **Case 안에서 완결** | `The Note on the Shelf` + §5 description |
| X4 | M2 `play.recall` + clueInputs `s5_ep01_e2` (use recall) | Case 01 Sound Board 회상 | **제거** | recall 블록·clueInput 삭제. 원리는 §6 벽 글자판이 가르친다 |
| X5 | M2 letterIntro·letter·hints | "Sora's board:", "SORA'S BOARD", "on Sora's board" | **Case 안에서 완결** | "The board on the store room wall:", "THE SAILORS' LETTER BOARD", H1 "on the board" |
| X6 | M2 `notes` | "Sora's board (Case 01)", "as Case 01 and Case 11 do" | **Case 안에서 완결** | `The rain blurred the note; what is left names each group's sounds by the part of the mouth on the sailors' board, which the mission shows.` / Rookie 줄: `Rookie says '+ 1 line'; Junior and Master say 'one more line'.` |
| X7 | M2 `learning.objective` | "Sora의 글자판 설명…" | **Case 안에서 완결** | `창고 벽 글자판(입 모양을 본뜬 자음, a stronger sound adds one line)과 위치 표현(a dot on its left, under it, at the bottom)을 읽고 번진 쪽지의 세 글자를 다시 만든다.` |
| X8 | e2 description | "rebuilt with Sora's board" | **Case 안에서 완결** | §6 e2 문구 |
| X9 | dossier `s5_ep02_m2.factIds` | `s5_ep01_h3, h10, h11, h12` | **Case 안에서 완결** | `s5_ep02_h7, h8, h9, h10`(같은 진술·출처 복사). derivation "Sora's board (Case 01, …)" → `The sailors' board (the book's mouth letters h7 and the added stroke h8): …` |
| X10 | dossier `learningObjectives` | "Use Sora's board to rebuild blurred letters." | **Case 안에서 완결** | `Use the sailors' letter board to rebuild blurred letters.` |
| X11 | M3 talk.after | "I did. And the water drop on it." / "My grandmother taught me that mark." | **Case 안에서 완결** | §7 talk.after 4줄(물방울 = 비, 함을 위해 그림) |
| X12 | Final `clueInputs` | `s5_ep01_c1` answerDerivation ("Seok's water drop is Bun-i's mark") | **제거** | 삭제. e1~e3 answerDerivation만 |
| X13 | ending | "Seok's water drop is just like Bun-i's." / "Who taught my grandmother? I never asked." | **제거 후 대체** | §9 SEOK 두 줄(King made letters easy / sailor can write) |
| X14 | v1 Intro 1행 | "A water-drop note finds you. You read it. Now it is spring, 1592." | **제거** | §4 1행 `Spring, 1592: …` |
| X15 | v1 M3 talk | "She said: write a note with this water drop, and a detective will come." | **제거** | — |
| X16 | v1 Final transition | "Seok puts his note in his family's letter box." | **제거** | — |
| X17 | v1 discovery | "In 1446, Bun-i signed her letter with a water drop…" | **제거** | X2 문구 |
| X18 | v1 M2 board 제목·recall miss | "(Sora's board, 1446)", "Look for the Sound Board." | **제거** | X4·X5 |
| X19 | v1 reveal | "King's letters … (C01 연결)" | **Case 안에서 완결** | §10 h11 기반 realHistory |
| X20 | 들어오는 참조 | C03 M1 recall `s5_ep02_e1`, C04 Final present `s5_ep02_e1` | **제거(그 Case 쪽)** | C03 X1, C04 X7 참고. e1 id는 유지 |
| X21 | `s5SeoulEvidenceLinks` / `s5Ep02EvidenceLinks` | `{}` (비어 있음) | 유지 | 변경 없음 |
| X22 | synopsis·Ham's report·find 그림의 물방울 | 이 Case 쪽지의 물방울 | **유지(이유: Case 안 단서)** | 석이 함에게 "비"를 알리려 그린 표시로 M3에서 밝혀짐 |

### 13. 물방울 설명 (Case 안)
- 누가: 석. 왜: 함은 King's letters를 못 읽으니, 그림 한 개로 "비가 들어왔다"를 알리려고. 어디서 밝혀지나: M3 talk.after(석의 말), Final 오답 피드백·caseSummary. 가족 표시·다른 시대와의 관계 없음.

### 14. 독립성 검증
| 검사 | 근거(이 Case 화면) | 결과 |
|---|---|---|
| (a) Intro 이해 | 1592, 이순신의 손님, 전쟁 임박, 대포 시험, 창고 종 — Intro 6줄 | 가능 |
| (b) M1 | 이순신 대사 + 보고서 3줄 + 그림 | 가능 |
| (b) M2 | 벽 글자판(자음 4개·획 더하기·ㅁ+1=ㅂ·모음 위치·받침) + blocks 3줄 | 가능(recall 없음) |
| (b) M3 | 석의 4줄 | 가능 |
| (b) Final | 카드 e1~e3(이 Case) + letter 3줄 + M3 대화 | 가능 |
| (c) Ending | 판결·역사 5줄·석의 두 줄 | 가능 |
| 남은 타 Case 참조 | — | **없음** (grep 대상: Bun-i, Sora, 1446 이외 연도, letter box, same mark, `s5_ep01_`) |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 wet straw 모호·12 노출 | 수색 엔진·그림·3물건 | 질문 문구, "Twelve" 삭제, note 오답 문구 |
| M2 Sora 보드 recall | 탭 조립·정답·blocks·sounds | 보드를 창고 벽 수병 글자판으로, ㅁ+1=ㅂ·받침 줄 추가, recall 삭제 |
| 석 동기·물방울 | 석이 옮김·쪽지 | 함은 자고 있었음, 글자판·할머니, 물방울 = 비 |
| Final DRAGON | 거북선 구조(이야기·e4) | talk(present 3) + 진술 판정 |
| Ending Bun-i 연결 | 역사 5줄 | 서문(h11) 두 줄 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 시험 날 아침 | — | 읽기 | 창고 종 | 창고 확인 |
| M1 | 무엇이 위험했나 | "Wet powder will not fire" | 3물건 → bucket | 비, 쪽지, 함의 도둑 의심 | 쪽지 해독 |
| M2 | 행방 | 쪽지 | 벽 글자판으로 거북선 조립 | 화약은 거북선에 | 배로 감 |
| M3 | 다 있나, 누가 | 행방 | 4×3 = 12 | 12통 무사, 석, 물방울 = 비 | 판결 |
| Final | 도둑인가 구조인가 | e1·e2·e3 | present 3 + 진술 판정 | 도둑 아님 증명 | 결말 |
| Ending | Intro 해결 | — | 읽기 | 시험 진행, 전쟁 시작(역사) | (Case 끝) |

### 17. 어린이 시뮬레이션 (설계 검토)
| 항목 | 판단 |
|---|---|
| 무엇을 보나 | 창고 그림·보고서 / 벽 글자판 12줄·3그룹 / 석 4줄 / 이순신 대화·카드 3장·문장 4개 |
| 무엇을 누르나 | 그림 탭·선택 / 소리·선·점 탭 / 숫자 / 카드 / 문장 |
| 근거가 화면에 있나 | 예. M2 원리가 이 화면에 있다(Case 01을 안 해도 됨) |
| 함정 | M1 note(물방울 그림) — 피드백 "drawn, not rain". Final shiproof — "ship's roof" 반대 |
| 재시도·힌트 | M2 힌트 2(H2가 ㅂ 직접 제시), Final present 2회 뒤 안내 |
| 목표 기억 | objectives 4번, 함의 의심이 M1·M3·Final에 반복 |
| 위험 | 글자판 12줄이 Rookie에게 길다 → 자음 4줄은 표 형태로 짧고, 퍼즐 화면에서 다시 볼 수 있다(letter 다시 읽기) |

### 18. ID·저장 영향
- id 불변: m1~m3·final, e1~e4, c1~c3. 이름 변경 e1. 설명 변경 e1·e2·e3.
- recall 삭제(M2): 저장된 `examined`의 `s5_ep02_m2:recall`은 읽히지 않을 뿐 무해.
- 정답 변경: Final `DRAGON` → `seok`(letterLock → multipleChoice). 새 present id `p_danger/p_how/p_count`, 저장 키 `s5_ep02_final:talk-before` 신규.
- dossier: 새 fact `s5_ep02_h7~h11`, `s5_ep02_final` answer `seok`·`fiction: true`·clues `all twelve barrels`, `out of the rain`. `s5_ep02_m1` clue `Wet powder will not fire` 유지, `s5_ep02_m2` clues `back of the tongue`, `stronger`, `a dot on its left` 유지(모든 레벨에 있음).
- clue graph: 타 Case 입력 삭제로 `clue_not_found` 위험 없음. `s5_ep02_e4`가 이후 어디에도 안 쓰이면 `clue_never_used` **경고**(오류 아님)가 날 수 있다 — 허용.

### 19. 엔진 변경
- 없음(T1 전제). talk.before + text_choice Final은 C01 V4에서 동작.

### 20. 이미지
- 신규 없음. `find_note*.webp`의 파란 물방울은 "석이 그린 비 표시"로 그대로 맞는다. 글자판은 앱 텍스트(그림에 글자 없음). 이순신·석 초상화 재사용.

### 21. 작업량
- **M**: `s5_ep02/case.plan.json`, `levels.json`, `history_dossier.json`(fact 5개 복사, m2 factIds, final, reveal), 생성물 재생성, C02 테스트(DRAGON 기대값, M2 recall 기대값이 있으면).

### 22. 위험
| 위험 | 대응 |
|---|---|
| 글자판이 정답 글자 ㅂ을 보여 줘 쉬움 | 8세 기준 적정. 모음·받침 위치는 여전히 읽어야 함 |
| M2 recall 독이 사라져 미션 상호작용이 하나 줄어듦 | 판 읽기가 대신한다. 필요하면 같은 Case e1(쪽지) recall로 대체 가능(play_check 허용) — 기본안은 없음 |
| 석의 할머니가 누구에게서 배웠나 궁금함 | 질문을 남기지 않는다(현행 "I never asked" 삭제) |

---

## Case 03 — The Crane That Lifts Stones

### 1. 제목·역사 배경
- 제목 유지: **The Crane That Lifts Stones**.
- 1795년 봄, 수원 화성 축성 현장(1794.1 착공 ~ 1796.9 완공, h1). 정약용은 성의 계획과 거중기 설계(「기중도설」, h2). 현장 총괄은 조심태 등(새 fact `s5_ep03_h7`). 정약용이 현장을 "찾아온다"는 것은 창작.

### 2. 독립 사건 목표(한 문장)
거중기가 고장 난 것인지 바뀐 것인지 밝혀 돌을 올리고, 밤사이 밧줄에 경고 쪽지를 묶은 사람을 이 공사장의 증거로 찾아낸다.

### 3. 인물 동기
| 인물 | 동기 |
|---|---|
| 정약용 | 자기 설계를 믿고 "고장"을 받아들이지 않는다. 경고해 준 사람에게 고마워하고 싶다. |
| 곽 반장 | 일정이 급하다. 윗부분을 다시 짠 사실을 모르고 "고장"이라 외친다. 도면실에는 들어가지 않는다. |
| 새 목수 | 글을 못 읽어 도면의 이름을 읽지 못하고 "문 모양" 도면 중 틀린 것을 집었다(악의 없음). |
| 서기 | 장부 담당. 밤에는 읍내에서 잔다. 밤에는 마당 문이 닫힌다. |
| 옥분(물 긷는 아이) | 매일 정약용의 먹물용 물을 도면실에 가져가 진짜 도면(바퀴 2개)을 봤다. 새벽 전 물항아리를 채우다 새 윗부분에 바퀴가 없는 것을 봤다. **물 긷는 아이가 장인들에게 틀렸다고 말할 수는 없어** 이름을 쓰지 않고, 정약용이 알아볼 표시로 **물방울**을 그렸다. 글자는 어머니에게 배웠다. |

### 4. Intro — 새 Intro (R 전문, 6줄)
1. Spring, 1795. You are a detective, a guest of Jeong Yak-yong at Hwaseong Fortress in Suwon.
2. A long stone wall is rising around the new town.
3. Jeong planned this fortress for the King. He also designed a lifting machine, the geojunggi.
4. It lifts heavy stones with ropes and pulleys. Today Jeong has come to see it work.
5. But Foreman Gwak shouts across the stone yard.
6. "Your machine is broken! It cannot lift one stone!"
- 현행 5줄 → 6줄(세 레벨 같이 6줄). 역사 P2: "planned / designed / has come to see"로 역할 한정.
- synopsis 유지(`A note with a small water drop is tied to its rope.`). goal 유지 `Find out if the lifting machine is broken, and who wrote the warning.`
- objectives (R): `Put the work log in order.` / `Find Jeong's own drawing.` / `Lift the stone in the right order.` / `Find who tied the note to the rope.`

### 5. Mission 1 — Broken, or Changed?
- **목적**: 고장인지 변경인지 시간 순서로 밝힌다. 쪽지가 "밤에" 묶였음을 안다.
- **유형**: `timeline_board` · `timelines` · `sequence`. 정답 `start,lift,copy,note,fail` 불변, 카드 id·수 불변.
- **recall 제거**: `play.recall`("The Same Mark?" / "Which note in your notebook has the same mark?" / "Look for a note from 1592.")과 clueInputs `s5_ep02_e1`(use recall) 삭제.
- **화면 단서 — Gwak's work log (R, 정답 순서가 아닌 줄 순서)**
  ```
  This morning, the machine could not lift a stone.
  The note was tied to the rope in the night, after the carpenter's work.
  The machine lifted big stones every day, until the new carpenter came.
  The King's builders began the wall in 1794.
  The new carpenter rebuilt the top from a copied drawing.
  ```
- **cards (plan 순서)**: `note`, `rice`, `copy`, `fail`, `lift`, `start`(start·fail은 anchor).
- **talk.before (Jeong)**: `My machine lifts heavy stones with ropes and pulleys.` / `Gwak says it is broken. I do not believe it.` / YOU `Then let us read his log.`
- **정답**: start → lift → copy → note → fail.
- **8세 풀이 경로**: ① 1794(처음)·this morning(끝) 고정 → ② "until the new carpenter came" → lift < copy → ③ "after the carpenter's work" → copy < note → ④ rice는 어느 줄에도 없음 → 버림.
- **선택지 대입**: 가운데 3칸 순열 6개 중 lift<copy<note를 만족하는 것은 1개. rice 배치 시 orderFeedback.
- **힌트**: H1 `Look for 'until' and 'after' in the log. The lines are not in order.` / H2 `What happened before the new carpenter came? What came after his work?`
- **오답(orderFeedback)**: `Read the log again. What happened until the new carpenter came?`
- **discovery (변경)**: title `A WARNING IN THE NIGHT` / detail R `Someone knew the drawing was different, and tied this note in the night. Who?` (J `Someone knew that the drawing was different and tied this note in the night. Who?` / M `Someone knew the drawing had been changed, and tied this note in the dark. Who?`)
- **transition (R)**: `The machine is not broken. It was changed.` / `Gwak says, "Nobody works here at night. The gate is shut. Only the water carriers come in before dawn."` / `"A copied drawing?" says Jeong. "Then which drawing is mine?"`
- **상태 변화**: 변경됨, 쪽지는 밤에, 밤·새벽엔 물 긷는 사람만 들어옴(작성자 단서 1).
- **다음 이유**: 어느 도면이 진짜인가.
- **증거 e1 (id 유지, 이름 변경)**: name `The Note on the Rope` / description `A short note in the King's letters, with a small water drop and no name. It says: the drawing is different. It was tied to the rope in the night.`

### 6. Mission 2 — Which Drawing Is Mine? (퍼즐 유지, 작성자 단서 2·3)
- **유형**: `picture_choice`(그림 3장, 이름 숨김, 정답 `gate_wheels`, options 순서 pole → gate_wheels → gate_plain 유지).
- **story (R 전문)**: `Three drawings of lifting machines lie on the table. Each has a name written on it.` / `The new carpenter stands by the door. "I cannot read. I took the drawing with a gate on it."` / `"Only three people come in here," Jeong says. "The carpenter, my clerk, and the girl who brings water for my ink."` / `"Read my words, and find my drawing."`
- letter(Jeong's words 4줄)·question·hints·feedback 유지(dossier clues `like a gate`, `More pulleys hang under them`, `A big wheel stands on each side`).
- **정답**: `gate_wheels`.
- **8세 풀이**: 문 모양 → 위·아래 도르래 → 양쪽 바퀴. **대입**: pole(문 모양 아님) ✗, gate_plain(바퀴 없음) ✗, gate_wheels ✓.
- **transition (R)**: `The machine in the yard has pulleys only at the top, and no wheels.` / `"He took the gate with no wheels," says Jeong. "Let us rebuild it, and lift that stone."`
- **상태 변화**: 진짜 도면 확정. 목수는 글을 못 읽음(단서 3). 도면실 출입자 = 목수·서기·물 긷는 아이(단서 2).
- clue c2 note (R): `Jeong's machine is like a gate, with pulleys in two places and two wheels. Only the carpenter, the clerk and the water girl come into the drawing room.`
- **다음 이유**: 진짜 도면대로 돌을 올린다.

### 7. Mission 3 — The Stone Rises (유지)
- `order_sequence` 그대로(정답 tie,hook,turn,rise / options turn, pull, tie, rise, push, hook).
- transition (R): `The ropes go tight. Slowly, the big stone rises onto the wall.` / `Gwak takes off his hat. "It was never broken," he says.` / `Below, a girl with a water bucket looks at the two wheels, and smiles.`
- **다음 이유**: 기계는 해결. 경고한 사람이 남았다.

### 8. Final — Who Tied the Note? (v1 유지, 라벨만 수정)
- **유형**: `text_choice` · `finalMission` · `multipleChoice`. 기존 `combo_dial_lock`(1796) 폐기. location `THE STONE YARD, AT SUNSET`.
- **story (R)**: `The big stone sits on the wall. The workers cheer.` / `Jeong holds up the note. "Someone warned us. Who?"` / `Four people stand in the yard.`
- letterIntro `Your notebook, and what the four people say:`
- **letter (R 전문)**
  ```
  The note says: "The drawing is different."
  It is written in the King's letters.
  It was tied to the rope in the night.
  Gwak: "I never go into the drawing room."
  The carpenter: "I cannot read or write."
  The clerk: "I sleep in town. The yard gate is shut at night."
  Okbun: "I take water to the drawing room. I fill the jars before dawn."
  ```
- question (R) `Who tied the note to the rope?`
- **options (plan 순서)**: `clerk` The clerk → `okbun` **Okbun**(v1 "Okbun, the water girl" → 물방울 연상을 줄이려고 이름만) → `gwak` Foreman Gwak → `carpenter` The new carpenter.
- **정답**: `okbun`.
- **8세 풀이 경로**: ① 쪽지 사실 3개(도면이 다르다 / King's letters / 밤) → ② H1 "도면이 다르다는 걸 알려면 진짜 도면을 봤어야" → ③ Gwak ✗(도면실 안 감), 목수 ✗(못 씀), 서기 ✗(밤에 없음) → ④ 옥분.
- **대입 검사**
  | 후보 | 도면 봄 | 글 씀 | 밤·새벽 마당 | 결과 |
  |---|---|---|---|---|
  | Gwak | ✗ | 미상 | 미상 | 탈락 |
  | carpenter | ✓ | ✗ | 미상 | 탈락 |
  | clerk | ✓ | ✓ | ✗ | 탈락 |
  | Okbun | ✓ | 모순 없음 | ✓ | **유일** |
- 물방울은 소거에 쓰지 않는다(엔딩에서 옥분이 이유를 밝힘). 아이가 "물 → 물 긷는 아이"로 먼저 짐작해도 정답과 모순되지 않는 보조 단서다.
- **힌트**: H1 `To write "the drawing is different", the writer had seen Jeong's drawing.` / H2 `Check each person: the drawing room, the writing, the night. Only one fits all three.`
- **오답**: gwak `Gwak never goes into the drawing room. How could he know the drawing was different?` / carpenter `The carpenter cannot write. The note is written in the King's letters.` / clerk `The clerk sleeps in town, and the gate is shut at night. The note came in the night.`
- successMessage `Okbun! Only she fits all three.`
- transition (R): `Okbun puts down her bucket.` / `"I saw the new top had no wheels," she says. "Jeong's drawing has two."`
- **증거 e4 (id·이름 유지 "The Finished Fortress")**: `Okbun, a water girl at the yard, wrote the warning note. Hwaseong was finished in 1796. Machines like the geojunggi helped lift big stones. A record book lists the workers and their pay.`
- **Final 증거(이 Case만)**: `s5_ep03_e1`(밤·글·내용) + `s5_ep03_c2`(출입자·목수 문맹) + M1 transition(새벽 물 긷는 사람). clueInputs: `s5_ep03_c1`, `s5_ep03_c2` answerDerivation. v1의 `s5_ep02_e1` textMention **삭제**.

### 9. Ending (새 전문 핵심)
- OKBUN `The new top had no wheels. Jeong's drawing has two. So I wrote the note.`
- OKBUN `A water girl may not tell the builders they are wrong. So I wrote no name.`
- OKBUN `I drew a water drop. Jeong knows the girl who brings his water.`
- JEONG `Then I thank the girl who brings my water.` / OKBUN `My mother taught me the King's letters.`
- 역사: `The next autumn, in the ninth month of 1796, Hwaseong Fortress was finished.` / `Machines like Jeong's helped lift its big stones.` / `A record book tells how it was built. It lists the workers and their pay.`
- **삭제**: `Your water drop is just like Seok's, in 1592.` / `Seok? My mother told me that name.` / v1 `Okbun puts her note in her family's letter box.` / v1 `…and this water drop.`
- caseSummary (R): `The lifting machine was not broken. A new carpenter, who could not read, rebuilt its top from the wrong drawing. Okbun, who carries water to the builders, had seen Jeong's drawing. She tied a warning note to the rope in the night, with a water drop and no name. Rebuilt from Jeong Yak-yong's drawing, the machine lifted the stone. Hwaseong Fortress was finished in 1796. Machines like Jeong's geojunggi helped lift big stones. A record book lists the workers and their pay.`

### 10. 역사 학습 + 사실/창작
- 사실: 1794.1 착공·1796.9 완공(h1), 정약용 거중기·기중도설(h2), 새 기계가 큰 돌을 옮김(h3), 1801 의궤에 일꾼·품삯(h4·h5). 새 fact `s5_ep03_h7`: 현장 총괄 조심태(우리역사넷, 감사 PART 5-B 확인).
- 삭제(P3): "two years and eight months", "Even the water girl is in it", 4자리 다이얼.
- IN THIS MYSTERY (R): `Okbun, Foreman Gwak, the carpenter, the clerk, the copied drawing and the stopped machine are made up. So is Okbun's note with its water drop.` / `Jeong Yak-yong planned the fortress and designed the machine. Officials such as Jo Sim-tae ran the building site.` / `Jeong was real, but his visit and his words in this story are made up.` / `The three drawings are the game's own, not copies of the real ones.`

### 11. R/J/M 예시와 실제 단어 수
| # | R | J | M | R/J/M |
|---|---|---|---|---|
| 1 | Spring, 1795. You are a detective, a guest of Jeong Yak-yong at Hwaseong Fortress in Suwon. | Spring, 1795. You are a detective, staying as a guest of Jeong Yak-yong at Hwaseong Fortress in Suwon. | Spring, 1795. You are a detective, and the guest of Jeong Yak-yong at Hwaseong Fortress in Suwon. | 16/18/17 |
| 2 | Jeong planned this fortress for the King. He also designed a lifting machine, the geojunggi. | Jeong made the plans for this fortress, and he designed a lifting machine, the geojunggi, to help build it. | Jeong drew up the plans for this fortress and devised a lifting machine, the geojunggi, so its stones could be raised. | 15/19/21 |
| 3 | Who tied the note to the rope? | Who tied the note to the rope? Check each person against your notes. | Which of the four could have tied the note to the rope? Test each one against your notes. | 7/13/18 |
| 4 | A water girl may not tell the builders they are wrong. So I wrote no name. | A water girl may not tell the builders that they are wrong, so I wrote no name. | A water girl is not allowed to tell the builders they are wrong, so I left my name off. | 16/17/19 |
| 5 | I drew a water drop. Jeong knows the girl who brings his water. | I drew a water drop instead, because Jeong knows the girl who brings his water. | Instead I drew a water drop; Jeong knows well the girl who brings his water. | 13/15/15 |
- Final letter의 네 진술은 세 레벨 같은 정보(J/M은 연결어만).

### 12. 외부 의존 원장
| # | 위치 | 현재 내용 | 결정 | 대체 |
|---|---|---|---|---|
| X1 | M1 `clueInputs` + `play.recall` | `s5_ep02_e1` recall, "The Same Mark?" / "…has the same mark?" / "Look for a note from 1592." | **제거** | 둘 다 삭제. M1은 talk.before → timeline |
| X2 | M1 `discovery` | "THE SAME WATER DROP" / "Seok drew it in 1592. Two hundred years later, it is here again." | **Case 안에서 완결** | §5 "A WARNING IN THE NIGHT" |
| X3 | e1 name | "The Water-Drop Note (1795)" | **Case 안에서 완결** | `The Note on the Rope` + "no name" 설명 |
| X4 | ending | "Your water drop is just like Seok's, in 1592." / "Seok? My mother told me that name." | **제거 후 대체** | §9 옥분 3줄 + 정약용 1줄 |
| X5 | v1 Intro 1행 | 물방울 쪽지 시대 이동 | **제거** | §4 1행 |
| X6 | v1 ending | "My mother taught me the King's letters, and this water drop." / "Okbun puts her note in her family's letter box." | **변경/제거** | "My mother taught me the King's letters." 만 |
| X7 | v1 Final clueInputs | `s5_ep02_e1` textMention | **제거** | — |
| X8 | v1 인과·시뮬·ID 항목 | "C02 물방울(M1 recall)", "C04 물방울", "C04 Final이 s5_ep03_e1 사용" | **제거** | 이 문서 §15~18 |
| X9 | 들어오는 참조 | C04 Final present `note`(accepted/offered `s5_ep03_e1`), C04 ending evidence `s5_ep03_e1` | **제거(C04 쪽)** | C04 X7·X10. e1 id 유지 |
| X10 | Final option 라벨(v1) | "Okbun, the water girl" | **변경** | `Okbun` |
| X11 | 쪽지의 물방울(synopsis·M1 story·e1) | 이 Case 쪽지 | **유지(이유: 서명 대신 그린 표시)** | §13 |
| X12 | `s5Ep03EvidenceLinks` | `{}` | 유지 | — |
| X13 | dossier | m1 factIds h1(자기 Case), 타 Case fact 없음 | 유지 | final 항목만 교체, h7 추가 |

### 13. 물방울 설명 (Case 안)
- 누가: 옥분. 왜: 물 긷는 아이가 장인들의 일을 틀렸다고 이름을 걸고 말할 수 없어서, 이름 대신 정약용이 알아볼 "물 가져오는 아이"의 표시를 그렸다. 어디서 밝혀지나: Final 후 transition·Ending 옥분 대사. 소거 추리(Final)는 물방울 없이 성립한다.

### 14. 독립성 검증
| 검사 | 근거 | 결과 |
|---|---|---|
| (a) Intro | 1795, 정약용의 손님, 거중기, 곽의 "고장" | 가능 |
| (b) M1 | 섞인 일지 5줄(until/after) | 가능(recall 없음) |
| (b) M2 | 정약용 4줄 + 도면 3장 | 가능 |
| (b) M3 | 순서 규칙 letter | 가능 |
| (b) Final | letter 7줄(쪽지 사실 3 + 진술 4) | 가능 |
| (c) Ending | 옥분의 이유, 1796 완공 | 가능 |
| 남은 타 Case 참조 | — | **없음** |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 일지 시간순 | 엔진·카드 id·정답·anchor | 줄 섞음, "in the night", recall 삭제 |
| 작성자 자백 | 옥분·물방울 | 3조건 소거, 물방울 = 이름 대신 표시 |
| Final 1796 다이얼 | 1796(엔딩) | text_choice |
| 정약용 현장 책임자처럼 | 정약용 | planned/designed/has come to see, 조심태 |
| Seok 연결 | — | 삭제 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전 정보 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 고장 주장 | — | 읽기 | 갈등 | 일지 |
| M1 | 고장 vs 변경 | 쪽지 "drawing is different" | 일지 정렬 | 변경됨, 쪽지는 밤, 새벽엔 물 긷는 사람만 | 진짜 도면? |
| M2 | 진짜 도면 | 복사 도면 | 그림 대조 | 진짜 확정, 목수 문맹, 출입자 3명 | 재조립 |
| M3 | 돌 올리기 | 진짜 도면 | 순서 | 돌이 올라감 | 경고한 사람? |
| Final | 작성자 | M1·M2 단서 | 4명 소거 | 옥분 | 엔딩 |
| Ending | 확인 | — | 읽기 | 옥분의 이유, 1796 완공 | (Case 끝) |

### 17. 어린이 시뮬레이션 (설계 검토)
| 항목 | 판단 |
|---|---|
| 무엇을 보나 / 누르나 | 일지·카드 드래그 / 도면 탭 / 순서 탭 / 이름 탭 |
| 근거가 화면에 있나 | 예. Final letter 7줄에 소거 근거 전부 |
| 함정 | 서기(도면실 출입·글 씀) → "밤에 문 닫힘"으로만 탈락. 피드백 명확 |
| 재시도·힌트 | 즉시 재시도, 힌트 2개 |
| 목표 기억 | objectives 4번, Jeong "Someone warned us. Who?" |
| 위험 | "옥분이 글을 쓰나?" → 소거상 모순 없음, 엔딩 "My mother taught me"로 확인 |

### 18. ID·저장 영향
- id 불변: m1~m3·final, e1~e4, c1~c3. 이름 변경 e1. 설명 변경 e1·e4·c2.
- recall 삭제(M1): `s5_ep03_m1:recall` 저장값 무해.
- 정답 변경: Final `1796`(finalCode) → `okbun`(multipleChoice). 다이얼은 저장 없음.
- timeline: 카드 id·수·정답 같음 → 옛 배치 복원 무해.
- dossier: `s5_ep03_m1` clues 유지(`in 1794`, `until the new carpenter came`, `after the carpenter's work` 모두 새 지문에). `s5_ep03_final` answer `okbun`, `fiction: true`, clues `tied to the rope in the night`, `I cannot read or write`, `The yard gate is shut at night`. factIds h1·h3·h4·h5는 ending, h7 신규.

### 19. 엔진 변경
- 없음.

### 20. 이미지
- 신규 없음. stone_yard·drawing_room·도면 3장 재사용, Final 배경 stone_yard, 옥분 초상화 `characters/okbun.webp`.

### 21. 작업량
- **M**: `s5_ep03/case.plan.json`, `levels.json`, `history_dossier.json`(final 교체, h7, reveal), 생성물, C03 테스트(1796·M1 recall 기대값).

### 22. 위험
| 위험 | 대응 |
|---|---|
| 물방울로 정답을 짐작 | 라벨을 `Okbun`으로, 물방울 뜻은 엔딩에서만 |
| 이미 M2 퍼즐 단계에 들어간 플레이어가 새 story를 못 봄 | Final letter에 모두 다시 적음 |
| C03·C04 둘 다 "쪽지 작성자" | C03은 Final 전체가 소거 퍼즐, C04는 present 한 단계 — 형식이 다름 |

---

## Case 04 — The Palace of a Thousand Logs

### 1. 제목·역사 배경
- 제목 유지: **The Palace of a Thousand Logs**.
- 1866년 겨울, 한양 경복궁 중건 현장. 1592 소실·오랜 폐허(h1), 1865.4 착공·대원군 지휘(h2), 1868 완공·이어(h3), 원납전 강제(h4), 1866.11 당백전 → 물가 급등(h5), 농민 부역(h6). 대원군 = 어린 왕을 대신해 다스린 왕의 아버지.

### 2. 독립 사건 목표(한 문장)
궁궐 문에 쓸 통나무가 어디로 갔는지 찾고, 누가 표식을 바꿔 가져갔는지와 누가 경고 쪽지를 붙였는지를 이 목재장의 증거로 대원군에게 증명한다.
- plan.goal (R): `Find out where the palace logs went, and who took them.`

### 3. 인물 동기
| 인물 | 동기 |
|---|---|
| 흥선대원군 | 불탄 궁궐을 다시 세우려 한다. 통나무를 빼돌린 자를 벌하려 한다. |
| 표 씨(목재상) | 당백전 뒤 쌀값이 매주 오른다. "Coins buy less and less. Logs do not." → 밤에 나→다 획을 새기고(끌), 합법적으로 살 수 있는 다 통나무를 "전부" 샀다. |
| 두리(목수 견습) | 날마다 통나무가 갈라지지 않게 물을 적신다. 그래서 목재장에서 "Water Drop"이라 불리고 장부에 **물방울로 서명**한다. 어젯밤 통나무를 셌고, 아침에 표식이 바뀐 것을 알았다. 표 씨는 부자고 자신은 아이라 **이름 없이 물방울만** 그린 쪽지를 기둥에 박았다. |
| 서기 | 장부대로 다 통나무를 팔았을 뿐(속음). |

(v1의 "아버지에게 배운 물방울 쪽지", "가문" 동기는 **삭제**.)

### 4. Intro — 새 Intro (R 전문, 6줄)
1. Winter, 1866. You are a detective in Hanyang, a guest of the Heungseon Daewongun.
2. He is the King's father. He rules for the young King.
3. He is building Gyeongbokgung, the great palace, again.
4. It burned in the war of 1592, and lay in ruins for a long time.
5. Now great pine logs fill the timber yard.
6. But this morning, logs for the palace gates are missing.
- "Ten" 삭제(M2 정답 노출 제거). "the war of 1592"는 역사 사실이며 다른 Case 참조가 아니다(이 Intro와 M3 talk에서 설명됨).
- synopsis (R): `Great logs for the palace gates are missing from the timber yard.` / `A note with a small water drop says one mark has a new line.`
- hook (R): `Palace logs are gone before the gates are built.`
- objectives (R): `Find the mark with a new line.` / `Count the changed logs.` / `Follow the logs.` / `Answer the Daewongun's questions.`

### 5. Mission 1 — The New Line (획 규칙을 이 화면에서 가르친다)
- **목적**: 무엇이 바뀌었나(표식) — 원래 뜻을 찾는다.
- **유형**: `lens_inspect_word` · `inspections` · `wordInput` 그대로. 정답 `GATES` 불변. 마당 표·통나무 3개·꼬리표 유지.
- **recall 제거**: `play.recall`("One More Line" / "Which page of your notebook says how a stronger sound is written?" / "Look for Sora's board.")과 clueInputs `s5_ep01_e2`(use recall) 삭제. M1은 이 Case 첫 미션이라 같은 Case recall 대상도 없다.
- **talk.before (Duri, R 전문)**
  - DURI `Every log here is marked for the palace, or for sale.`
  - DURI `We carve the marks in the King's letters. A stronger sound gets one more line.`
  - DURI `Twelve great logs were 나 last night. This morning I find only two.`
  - YOU `Then let us look at every mark.`
  - (가르치는 주체 = 두리. 현행 "Ten great logs… Now I cannot find them" 교체)
- **letter (R 전문)**
  ```
  Yard board: each log has a mark carved on its end.
  가: the best logs, for the great halls.
  나: good logs, for the palace gates.
  다: not for the palace. They may be sold.
  The note: "One mark has a new line. Find it."
  Carvers' rule: a stronger sound adds one line: ㄴ, then ㄷ.
  ```
  - 현행 마지막 줄 `Sora's board: a stronger sound adds one line: ㄴ, then ㄷ.` → `Carvers' rule: …`. dossier clue `a stronger sound adds one line`, `One mark has a new line`, `good logs, for the palace gates`는 세 레벨 그대로.
- **정답**: `GATES`.
- **8세 풀이 경로**: ① 두리·마당 표에서 "강한 소리 = 한 획 더" → ② 돋보기로 새 획(희고 새로운 칼자국)이 있는 통나무 찾기 → ③ 다에서 새 획을 빼면 나 → ④ 나 = palace gates → GATES 입력(찢긴 꼬리표 단서).
- **선택지 대입**(입력형): HALLS(가) — 새 획을 빼도 가가 되지 않음. SOLD/SALE — 지금 보이는 다의 뜻(원래 뜻 아님). GATES만 성립.
- **힌트**: 현행 유지 + H2 `Take the new line away from 다. Which mark is left?`
- **오답**: `HALLS` `가 is for the halls. Take the new line away from 다: which mark is left?`(신규 키).
- **discovery (변경)**: title `WHO NAILED THE NOTE?` / detail R `Someone saw the new line before dawn. The note has no name, only a water drop.` (J `Someone saw the new line before dawn. The note gives no name, only a water drop.` / M `Someone spotted the new line before dawn, and signed the note with nothing but a water drop.`)
- **상태 변화**: 나→다 조작 확인. 쪽지 작성자 미상(물방울).
- **다음 이유**: 몇 개가 바뀌었나, 누가 샀나.
- **증거 e1 (id 유지, 이름 변경)**: name `The Note on the Post` / description `A short note in the King's letters, with a small water drop and no name. It says one mark has a new line.`

### 6. Mission 2 — The Yard Book (v1 유지)
- **유형**: `number_entry`, codeLength 2, 정답 **10** 불변.
- **letter (R 전문)**
  ```
  Yard book, last night. Counted by Duri, with a small water drop by his name:
  나 logs: twelve. 다 logs: six.
  Yard book, this morning. Counted by the clerk:
  다 logs: sixteen. 나 logs: two.
  Mr. Pyo's paper: "I bought every 다 log in the yard."
  ```
- question (R) `How many palace logs got a new line? Put in the number.`
- **8세 풀이**: 다 6 → 16, 늘어난 10 / 또는 나 12 → 2, 줄어든 10(검산).
- **대입**: 12 ✗(2개는 아직 나) / 16 ✗(원래 다 6 포함) / 06 ✗ / 02 ✗ / 10 ✓.
- **힌트**: H1 `Compare the 다 logs last night and this morning.` / H2 `Six were 다 already. How many more are there now?`
- **오답**: `12` `That is all the 나 logs last night. Two are still 나.` / `16` `That is all the 다 logs this morning. Six were 다 already.` / `02` `Two logs are still 나. How many are not 나 any more?` / `06` `Six logs were 다 last night. How many more are there now?`
- transition (R): `Ten palace logs got a new line.` / `And Mr. Pyo bought every 다 log.` / `"But where are they now?" asks Duri.`
- **증거 e2 "The Yard Book"**: `Last night Duri counted twelve 나 logs and six 다 logs, and signed with a small water drop. This morning: two 나 logs, sixteen 다 logs. Mr. Pyo bought every 다 log.`
- clue c2: `Ten 나 logs became 다 overnight. Mr. Pyo bought them all.`
- **상태 변화**: 10개, 표 씨가 다를 전부 구매, 두리의 서명 = 물방울(쪽지의 물방울과 같다는 연결은 Final에서 플레이어가 한다).
- **다음 이유**: 통나무는 어디에?

### 7. Mission 3 — Where Did the Logs Go? (엔진 교체 유지: timeline → trace_deduction)
- **유형**: `trace_deduction` · `deductions` · `multipleChoice`. 그림 `case_04/palace_site.webp`(1536×1024). 흔적 표시는 앱이 그린다.
- **talk.before (Duri, 역사 학습)**: `The palace burned in the war of 1592. It lay in ruins for a long time.` / `In 1865 the rebuilding began. Every house had to give money. Most had no choice.` / `My uncle was called from his farm to work here.` / `And with the new coin, rice costs more every week.` / YOU `Then where would ten palace logs go?`
- **letter = Duri's yard rule (R)**: `Logs for the halls are carried up the steps.` / `Logs for the gates wait by the gate.` / `Logs to sell leave by the east gate, on a dealer's cart.`
- task `Look for three marks.` / chooseTask `Where are the ten changed logs? Tap the place.`
- **clues (plan 순서)**: `carry` Two men with a log — `Two men carry a log up to the hall. Its mark is 가. All its cuts are old.` [590,620,800,790] / `tracks` Deep wheel tracks — `Deep wheel tracks. A heavy cart came here from the timber yard.` [880,660,1020,760] / `dust` Pale wood dust — `Pale wood dust on the stones, like the new cut on the log.` [820,770,1010,850]
- **places (plan 순서)**: `hall` The great hall [60,80,980,560] → `cart` The ox cart [1030,600,1450,760] → `gate` The half-built gate [1090,240,1530,585]. others: officials [20,640,330,960], stone workers [1150,770,1470,960]. (좌표는 눈대중 → 격자 시트 재측정 필수)
- **정답**: `cart`.
- **8세 풀이**: 바뀐 통나무는 이제 다 = 팔 통나무처럼 보임 → 규칙 3줄째 "logs to sell … on a dealer's cart" → 바퀴 자국·흰 나무 가루 → 수레.
- **대입**: hall(가, 옛 획) ✗ / gate(아직 통나무를 기다림) ✗ / cart ✓.
- **힌트**: H1 `The changed logs now look like 다 logs: logs to sell. Where do logs to sell go?` / H2 `Follow the wheel tracks and the pale wood dust.`
- **오답**: hall `The logs going up to the hall are marked 가, with old cuts.` / gate `The gate is still waiting for its logs. Where do logs to sell go?`
- successMessage `Ten logs, under a straw mat on Mr. Pyo's cart!`
- transition (R): `Each 다 mark has one pale, new cut.` / `In the straw lies a small chisel, white with fresh wood dust.` / `"Mr. Pyo says coins buy less and less," Duri says. "Logs do not. So he wants logs."`
- **증거 e3 (id 유지, 이름·뜻 변경)**: name `Mr. Pyo's Cart`, icon `bag`, description `Ten pine logs on Mr. Pyo's cart, ready to leave by the east gate. A small chisel lies in the straw, white with fresh wood dust.`
- clue c3: title `The Cart`, note `The ten logs are on Mr. Pyo's cart, with a chisel and fresh wood dust.`
- **다음 이유**: 대원군이 도착해 설명을 요구한다.

### 8. Final — What the Palace Cost (evidence_talk, 이 Case 카드만, present 3단계)
- **유형**: `evidence_talk` · `talks` · `examine`(`_talkFinal`). T1·T2 전제.
- **story (R)**: `The Daewongun rides up to the new throne hall. Its roof is not done.` / `Mr. Pyo stands by his cart. "I only bought logs marked 다!" he says.` / `"Explain this," says the Daewongun.`
- **letter (Your notebook, R)**: `One new cut turns 나 into 다.` / `Ten palace logs were changed last night.` / `The logs are on Mr. Pyo's cart, with a chisel.` / `The note has no name, only a water drop.` (← 현행·v1 `The same water drop is on notes from 1592 and 1795.` 교체)
- **interview** (speaker `heungseon_daewongun`, 배경 palace_site)
  - opening: DW `These logs are marked 다. They are not for my palace.` / YOU `Look closely, sir.`
  - questions: `why`(유지) `Why rebuild the palace?` → `The great palace burned in a war long ago.` / `I want it to stand again.`; `q_cost`(새) `What does the palace cost the people?` → `Every house gives money for it. Farmers come to work.` / `Since the new coin, prices are high. It is hard, but the palace must stand.`
  - presents (모두 새 id; 옛 `mark/count/note/cost` 제거):
    | id | prompt (R) | offered (plan 순서) | accepted | 대사 | miss | tell |
    |---|---|---|---|---|---|---|
    | `p_mark2` | "How do you know they are palace logs?" | e2, e3, **e1** | s5_ep04_e1 | YOU One cut on each mark is new. 나 became 다. / DW One more line. Clever, and wrong. | That does not show the new line. | Which card says one mark has a new line? |
    | `p_cut2` | "Mr. Pyo says he only bought them. Who cut the new lines?" (requires p_mark2) | e1, **e3**, e2 | s5_ep04_e3 | YOU The chisel in his cart is white with fresh wood dust. / DW Then the new lines are his work. | That shows the logs were sold, not who cut them. | Which card shows what was in Mr. Pyo's cart? |
    | `p_writer2` | "And who nailed this note to my post? It has no name, only a water drop." (requires p_cut2) | e3, e1, **e2** | s5_ep04_e2 | YOU Duri, sir. He signs the yard book with that water drop. / DW Duri. Step forward. | That card does not name anyone in the yard. | Whose name in the yard book has a water drop by it? |
  - v1의 `p_family2`(1592·1795 쪽지, `s5_ep03_e1`/`s5_ep02_e1`)는 **삭제**.
  - **카드 단일성**: p_mark2 — e1만 "new line". p_cut2 — e3만 끌·가루(e2는 "샀다"뿐). p_writer2 — e2만 사람 이름 옆 물방울(e1은 물방울이 있지만 이름이 없다: miss가 짚음).
  - finishWhen `[p_mark2, p_cut2, p_writer2]`, finishLabel `CLOSE THE CASE`, answer `rebuilt`(유지).
  - **힌트(T2)**: H1 `Each question needs its own card. Read the words on each card.` / H2 `The chisel is on the cart card. The water drop by a name is in the yard book.`
- **8세 풀이 경로**: 질문 핵심어(new line / cut / no name, only a water drop) → 그 말이 적힌 카드. p_writer2: 쪽지 카드 e1에는 이름이 없고, 장부 카드 e2에 "Duri … signed with a small water drop" → 두리.
- **대입 검사(p_writer2)**: e3(수레·끌: 사람 이름 없음) ✗ / e1(쪽지 자체, 이름 없음) ✗ / e2(두리 + 물방울 서명) ✓. 장부의 서기 줄에는 물방울이 없다.
- **Final 증거(이 Case만)**: `s5_ep04_e1`, `s5_ep04_e3`, `s5_ep04_e2`. clueInputs: `s5_ep04_c1`, `s5_ep04_c2`, `s5_ep04_c3` answerDerivation. `s5_ep03_e1`·`s5_ep02_e1` **삭제**.

### 9. Ending (새 전문 핵심)
- `Mr. Pyo's cart turns back to the timber yard.` / `The ten logs will stand in the palace gates.` (← Intro 해결)
- DURI `Yes. I wrote the note.` / DURI `I wet the logs every day, so they do not crack. The yard calls me Water Drop.` / DURI `Mr. Pyo is a rich man. I am only a boy. So I wrote no name.`
- YOU (evidence `s5_ep04_e2`) `Your water drop in the yard book told me.` (← 현행 `1592, 1795, 1866: the same water drop.` evidence `s5_ep03_e1` 교체)
- **삭제**: `Not one person. A family keeps writing them. But why?` / `I wrote the note. My father taught me the mark.` / v1 `Duri puts his note in his family's letter box.`
- 역사: `The rebuilding had begun in the fourth month of 1865.` / `In 1868 the palace was finished, and the King moved in.` / `It cost the people a lot: money they had to give, high prices and hard work.`
- caseSummary (R): `Mr. Pyo, a timber dealer, cut a new line on ten palace logs at night. So 나 became 다: logs that may be sold. He bought them and hid them on his cart, because coins were buying less and less. Duri, a young carpenter, wrote the note and signed it only with his water drop. The real story: Gyeongbokgung burned in 1592. The Heungseon Daewongun, the King's father, rebuilt it from 1865, and it was finished in 1868. It cost the people a lot. People had to give money. A new coin made prices go up. Many were called to hard work.`

### 10. 역사 학습 + 사실/창작
- 사실: h1~h6(위). **새 fact** `s5_ep04_h8`(= ep01_h10: 센소리는 획을 더해 만든다, ㄴ→ㄷ 등; 같은 진술·출처 복사). `h7`(1866.3 화재, draft)은 쓰지 않음.
- 시점 주의: 당백전은 1866년 11월부터 — "winter 1866"이므로 "rice costs more every week" 맞음. "last month"는 쓰지 않음.
- reveal realHistory 1줄 추가(R): `The King's letters add a line for a stronger sound: ㄴ, then ㄷ. A book of 1446 says so.`
- IN THIS MYSTERY (R): `Duri, Mr. Pyo, the clerk, the missing logs, the marks, the cart and Duri's water drop are made up.` / `The Heungseon Daewongun was real, but his words in this story are made up.`

### 11. R/J/M 예시와 실제 단어 수
| # | R | J | M | R/J/M |
|---|---|---|---|---|
| 1 | Winter, 1866. You are a detective in Hanyang, a guest of the Heungseon Daewongun. | Winter, 1866. You are a detective in Hanyang, staying as a guest of the Heungseon Daewongun. | Winter, 1866. You are a detective in Hanyang, and the guest of the Heungseon Daewongun. | 14/16/15 |
| 2 | He is the King's father. He rules for the young King. | He is the King's father, and he rules because the King is still young. | He is the King's father, ruling in his son's place while the King is still young. | 11/14/16 |
| 3 | Carvers' rule: a stronger sound adds one line: ㄴ, then ㄷ. | Carvers' rule: a stronger sound adds one line, so ㄴ becomes ㄷ. | Carvers' rule: a stronger sound adds one line, which is how ㄴ becomes ㄷ. | 9/10/12 |
| 4 | "And who nailed this note to my post? It has no name, only a water drop." | "And who nailed this note to my post? It has no name, only a water drop on it." | "And who nailed this note to my post? It bears no name, only a water drop." | 16/18/16 |
| 5 | I wet the logs every day, so they do not crack. The yard calls me Water Drop. | I wet the logs every day so that they do not crack, so the yard calls me Water Drop. | Every day I wet the logs to keep them from cracking; the whole yard calls me Water Drop. | 17/19/18 |
- 3번은 dossier clue `a stronger sound adds one line`을 세 레벨에 그대로 포함.

### 12. 외부 의존 원장
| # | 위치 | 현재 내용 | 결정 | 대체 |
|---|---|---|---|---|
| X1 | M1 `clueInputs` + `play.recall` | `s5_ep01_e2` recall, "One More Line", "Look for Sora's board." | **제거** | 둘 다 삭제 |
| X2 | M1 letter 마지막 줄 (R/J/M) | "Sora's board: a stronger sound adds one line: ㄴ, then ㄷ." | **Case 안에서 완결** | `Carvers' rule: …`(§11-3) + 두리 talk 2행 |
| X3 | M1 `notes`·`learning.objective` | "Sora's rule: a stronger sound adds one line", "Sora의 규칙" | **Case 안에서 완결** | notes: `Take the new line away (the carvers' rule on the yard board, told by Duri: a stronger sound adds one line, ㄴ then ㄷ) and 다 was 나.` / objective: `목재장 게시판과 두리가 알려 주는 새김 규칙(a stronger sound adds one line)을 읽고 …` |
| X4 | M1 `discovery` | "THE WATER DROP AGAIN" / "1592, 1795, and now 1866. Can one person write them all?" | **Case 안에서 완결** | §5 "WHO NAILED THE NOTE?" |
| X5 | e1 name | "The Water-Drop Note (1866)" | **Case 안에서 완결** | `The Note on the Post` |
| X6 | dossier `s5_ep04_m1.factIds`·derivation | `s5_ep01_h10`, "Sora's rule (… h10 of Case 01)" | **Case 안에서 완결** | `s5_ep04_h8`, `The carvers' rule (the book's added stroke, h8): ㄴ then ㄷ.` |
| X7 | Final present `note` (현행) | accepted `s5_ep03_e1, s5_ep02_e1`, offered `s5_ep03_e1, s5_ep04_e2`, tell "The note of 1795 has the same water drop." | **제거 후 대체** | `p_writer2`(e2, 이 Case) |
| X8 | Final `clueInputs` | `s5_ep03_e1`, `s5_ep02_e1` answerDerivation ("the same mark") | **제거** | c1~c3 answerDerivation |
| X9 | Final letter 4행 (R/J/M) | "The same water drop is on notes from 1592 and 1795." | **Case 안에서 완결** | `The note has no name, only a water drop.` |
| X10 | ending | "1592, 1795, 1866: the same water drop." (evidence `s5_ep03_e1`) / "Not one person. A family keeps writing them. But why?" / "My father taught me the mark." | **제거 후 대체** | §9 두리 3줄 + YOU 1줄(evidence `s5_ep04_e2`) |
| X11 | Final `notes` | "who wrote the note (the water-drop notes of 1592 and 1795: Act 1's turning point, a family not one person)" | **Case 안에서 완결** | `Three questions, each answered by one card of this case: the new cut (the note), who cut it (the cart), who wrote the note (the yard book's water drop by Duri's name). The palace's cost is a question and the ending.` |
| X12 | dossier `s5_ep04_final` | clue `The same water drop`, derivation "an older water-drop note (1592 or 1795: a family…)" | **Case 안에서 완결** | clues `One new cut turns 나 into 다`, `with a chisel`, `only a water drop`; derivation 위 X11 문장 |
| X13 | v1 Intro 1행, v1 `p_family2`, v1 ending "But why?"·letter box, v1 "C01 획 더하기"(인과·시뮬) | 연속성 | **제거** | 이 문서 |
| X14 | 들어오는 참조 | C05 M2 recall `s5_ep04_e1`("A Drop Like Duri's") | **변경(C05 쪽)** | C05 X1. e1 id 유지 |
| X15 | 쪽지·장부의 물방울 | 이 Case | **유지(이유: Final p_writer2의 핵심 단서)** | §13 |
| X16 | Intro·M3 "the war of 1592" | 역사 사실 | 유지(이유: 궁궐이 불탄 사실, 다른 Case 참조 아님) | — |
| X17 | `s5Ep04EvidenceLinks` | `{}` | 유지 | — |

### 13. 물방울 설명 (Case 안)
- 누가: 두리. 왜: 목재장에서 통나무에 물을 적시는 일을 해 "Water Drop"이라 불리고, 늘 그 표시로 장부에 서명한다. 부자 상인을 고발하는 쪽지라 이름은 쓰지 않았지만 습관대로 물방울을 그렸다. 어디서 밝혀지나: M2 장부(서명), Final p_writer2(연결), Ending(이유).

### 14. 독립성 검증
| 검사 | 근거 | 결과 |
|---|---|---|
| (a) Intro | 1866, 대원군 = 왕의 아버지, 궁궐 재건, 문 통나무 실종 | 가능 |
| (b) M1 | 두리 talk(획 규칙) + 마당 표 + 돋보기 | 가능(recall 없음) |
| (b) M2 | 장부 5줄 | 가능 |
| (b) M3 | 두리 규칙 3줄 + 흔적 3 | 가능 |
| (b) Final | 이 Case 카드 e1·e3·e2 + letter 4줄 | 가능 |
| (c) Ending | 반환, 두리의 이유, 역사 | 가능 |
| 남은 타 Case 참조 | — | **없음** |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 Sora 규칙 recall | 돋보기·GATES | 두리·마당 표가 규칙을 가르침, recall 삭제 |
| M2 정답 10 노출 | number_entry 10 | 12→2 / 6→16, "Ten" 삭제 |
| M3 timeline | 역사(대화로) | trace_deduction |
| Final 가문 단계 | evidence_talk, 대원군, 물방울 단서 | 장부 서명으로 두리(이 Case), present 4 → 3 |
| Ending "But why?" | 역사 3줄 | 두리의 이유 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전 정보 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 문 통나무 실종 | — | 읽기 | 문제 | 마당 조사 |
| M1 | 어떻게 사라졌나 | 두리의 획 규칙 | 돋보기 → GATES | 나→다 조작 | 몇 개? |
| M2 | 규모·구매자 | 나→다 | 장부 계산 10 | 10개, 표가 구매, 두리의 물방울 서명 | 어디에? |
| M3 | 행방 | 바뀐 = 팔 통나무 | 흔적 → 수레 | 수레·끌 | 대원군 도착 |
| Final | 증명 | e1·e3·e2 | present 3 | 표 = 획을 새김, 쪽지 = 두리 | 엔딩 |
| Ending | 반환·역사 | — | 읽기 | 통나무 반환, 비용 | (Case 끝) |

### 17. 어린이 시뮬레이션 (설계 검토)
| 항목 | 판단 |
|---|---|
| 무엇을 보나 / 누르나 | 마당 그림·돋보기·입력 / 숫자 / 흔적·장소 탭 / 카드 탭 |
| 근거가 화면에 있나 | 예. 획 규칙은 두리 대사·마당 표, 서명은 장부 |
| 함정 | M3 gate, Final p_cut2의 e2, p_writer2의 e1(물방울은 있으나 이름 없음) — 각 miss가 차이 설명 |
| 재시도·힌트 | M2 즉시, M3 재선택, Final 2회 뒤 안내 + 힌트 버튼 |
| 목표 기억 | objectives, 두리 "But where are they now?" |

### 18. ID·저장 영향
- id 불변: m1~m3·final, e1~e4, c1~c3. 이름 변경 e1·**e3**("The Palace's Story" → "Mr. Pyo's Cart"). 설명 변경 e1·e2·e3·c3.
- M3 엔진 교체: 옛 timeline 저장값은 SceneDeduction이 읽지 않음(무해).
- Final: present id 새로(`p_mark2`, `p_cut2`, `p_writer2`), `q_cost` 신규, `why` 유지, finishWhen 3. 옛 `mark/count/note/cost` 완료는 decode에서 버려짐.
- recall 삭제(M1): `s5_ep04_m1:recall` 무해.
- dossier: `s5_ep04_m1` factIds → `s5_ep04_h8`. `s5_ep04_m2` clues 유지. `s5_ep04_m3` → `fiction: true`, answer `cart`, clues `Logs to sell leave by the east gate`, `Pale wood dust`. `s5_ep04_final` clues X12, factIds h2~h6(q_cost·ending).

### 19. 엔진 변경
- T1·T2(계획됨)만. trace_deduction은 C06 M1에서 이미 동작(새 코드 없음).

### 20. 이미지
- 신규 없음. palace_site.webp 재사용 — **격자 시트로 영역 재측정 후 `picture.measuredOn` 기록 필수**. 흔적은 앱 표시.

### 21. 작업량
- **L**(M3 엔진 교체 + Final 재작성): `s5_ep04/case.plan.json`, `levels.json`, `history_dossier.json`, 생성물, C04 테스트(M3 timeline, Final present id, M1 recall).

### 22. 위험
| 위험 | 대응 |
|---|---|
| 그림 좌표 오차 | 격자 시트 측정, PlayCheck 겹침 검사 |
| M2 장부의 물방울로 두리가 일찍 드러남 | 연결은 Final에서 플레이어가 함. 미리 짐작해도 모순 없음 |
| "Water Drop" 별명이 엔딩에서 처음 나옴 | Final은 장부 서명만으로 풀린다. 별명은 이유 설명일 뿐 |

---

## Case 05 — The Lights of Geoncheonggung

### 1. 제목·역사 배경
- 제목 유지: **The Lights of Geoncheonggung**.
- 1895년 가을, 경복궁 안 건청궁(왕·왕비의 거처, h3). 1887년 한국 첫 전등(h1), 자주 깜빡여 "건달불"(h2). 1895년 왕비가 러시아와 손잡아 일본 세력을 견제(h4). 1895.10.8 미우라 공사가 보낸 무리가 궁을 습격, 왕비 시해(h5).

### 2. 독립 사건 목표(한 문장)
전등이 꺼진 한 시간 동안 낯선 두 사람이 무엇을 했는지 이 궁궐의 증거로 밝혀, 그들이 노리는 문이 누구의 것인지 왕과 왕비에게 보여 준다.
- goal 유지: `Find out what the strangers were doing in the dark, and why the Queen is in danger.`

### 3. 인물 동기
| 인물 | 동기 |
|---|---|
| 왕 | 정전과 낯선 이들이 걱정되어 아침에 탐정을 불렀다(Intro). |
| 한 상궁 | 왕비 처소 가까이에서 자고, 새벽마다 왕비의 물을 나른다. 그날 밤 발소리를 들었고 새벽에 전기실 벨트를 다시 걸었다. 궁 안에 누가 엿보는지 몰라 **말 대신 쪽지**를 탐정이 조사할 전기실에 숨겼고, 낯선 이들이 읽어도 누군지 모르게 **이름 대신 자기 표시인 물방울**을 그렸다. |
| 낯선 두 사람 | 벨트를 벗겨 일부러 어둠을 만들고, 동쪽 문 → 왕비 처소 문까지 걸음을 재어 판에 그렸다. 다시 어둠을 만들 계획. |
| 왕비 | 러시아와 손잡아 일본 세력을 막으려 한다. 그래서 감시당한다. |

(v1의 "집안에 전해진 대로 물방울 쪽지를 써서 탐정을 부른다"는 **삭제**: 부른 사람은 왕, 쪽지는 한 상궁의 조심.)

### 4. Intro — 새 Intro (R 전문, 6줄)
1. Autumn, 1895. This morning, the King has called you, a detective, to Geoncheonggung.
2. Here, inside the great palace, the King and the Queen live.
3. In 1887, the first electric lamps in Korea were lit here.
4. They often blink on and off. People call them the good-for-nothing lights.
5. Last night they went dark for an hour.
6. And two strangers were seen in the Queen's court.
- 궁 이름은 Geoncheonggung 하나(Jangandang·Gonnyeonhap·Gyeongbokgung 삭제). Final location `THE KING'S HALL`.
- objectives (R): `Find out why the lamps went dark.` / `Put the night in order.` / `Count the steps on the rope.` / `Find whose door the map marks.`

### 5. Mission 1 — The Lamp House
- **목적**: 정전이 사고인가 고의인가.
- **유형**: `scene_explore_choose` 그대로(정답 `belt`, 그림 4장).
- **letter (R 전문, 변경)**
  ```
  Detective,
  Last night the lamps did not go out on their own.
  One of the two strangers came into the lamp house.
  He did not touch the fire. He did not touch the coal.
  He took off the long leather belt that turns the big wheel.
  I put it back at dawn. His muddy hand is still on it.
  ```
  - 변경: 3행 `A stranger came…` → `One of the two strangers came…`(단수/복수). 마지막 `— Han` 서명 행 **삭제**(세 레벨 같이 7 → 6줄). 쓴 사람은 talk.after에서 밝혀진다. dossier clues `did not touch the fire`, `did not touch the coal`, `leather belt` 유지.
  - letterIntro 유지 `Under the coal scoop, a note in the King's letters, with a small water drop:`(그림의 물방울과 일치).
- **오답 피드백(변경)**: fire `The note says he did not touch the fire. Read it again.` / coal `The note says he did not touch the coal. What did he take off?` (← "Lady Han says…": 이 시점엔 작성자 미상)
- **정답**: `belt`. **8세 풀이**: 쪽지 "did not touch the fire / coal" → 남는 것 belt + 진흙 손자국. **대입**: fire ✗, coal ✗(쪽지가 부정), belt ✓.
- **힌트**: 현행 유지(쪽지에서 not을 찾기 / 무엇을 벗겼나).
- **talk.after (Lady Han, R 전문)**
  - LADY HAN `You found my note. Good. I wrote no name. The strangers may read it too.`
  - LADY HAN `The water drop is my mark. I carry the Queen's water each dawn.`
  - LADY HAN `The lamps blink every week. Nobody looks twice.`
  - YOU `So the strangers hid in a dark that seemed normal.`
- discovery 유지(`THE DARK WAS MADE` / `Someone took the belt off on purpose. The strangers needed the dark.`).
- **상태 변화**: 어둠은 고의, 쪽지는 한 상궁.
- **다음 이유**: 어둠 속에서 무엇을 했나 — 한 상궁의 증언.
- **증거 e1 (id 유지, 이름 변경)**: name `Lady Han's Note` / description `Lady Han's note in the King's letters, marked with her water drop. The dark was made on purpose: a stranger took off the belt on the big wheel.`

### 6. Mission 2 — One Hour in the Dark (timeline, 섞은 증언 유지)
- **유형**: `timeline_board`. 정답 `lit,lamphouse,dark,gate,hall,back`, 카드 7개 id·수 불변.
- **recall (같은 Case로 변경)**: clueInputs `s5_ep04_e1` → **`s5_ep05_e1`**(use recall). play.recall: title `Where It Began` / prompt R `Lady Han's story of the night begins in the lamp house. Which card is from there?` (J `… Which card in your notebook is from there?` / M `Lady Han's account of the night begins in the lamp house. Which card in your notebook comes from there?`) / miss `That card is not from the lamp house.` / feedback `The belt came off there. Then the lamps went dark.` — 기능: 타임라인 첫 관계(lamphouse < dark)를 이 Case 증거로 다시 보게 한다.
- **talk.before (Lady Han)**: `I sleep near the Queen's rooms.` / `Last night I heard steps in the dark.` / YOU `Tell me, in order.`(유지)
- **letter = Lady Han tells you (R, 정답 순서가 아닌 줄 순서)**
  ```
  The lamp man came back at 9:00. By then, the men were gone.
  Before the Queen's hall, the men stood at the east gate.
  One man had a flat board under his arm.
  They went to the east gate only after the lamps went dark.
  The lamps went dark after the strangers came into the lamp house.
  The lamp man lit the lamps at 8:00.
  The guards at the main gate saw nothing. They are far away.
  ```
- **cards (plan 순서)**: `hall`, `guards`, `dark`, `lit`, `gate`, `back`, `lamphouse`(lit 8:00·back 9:00 anchor).
- **정답**: lit → lamphouse → dark → gate → hall → back.
- **8세 풀이**: 8:00·9:00 고정 → "dark after … lamp house" → "east gate only after … dark" → "Before the Queen's hall … east gate" → "By then, the men were gone" → guards는 관계 없음·"far away" → 버림. 줄 순서를 따라 하면 틀린다.
- **대입**: 가운데 4칸 24순열 중 lamphouse<dark<gate<hall 하나만. 단일.
- **힌트**: H1 `Find after and before in Lady Han's words. Her words are not in order.` / H2 `The main gate is far away. Is it part of that night?`
- orderFeedback `Read Lady Han's words again. What came after the dark?`
- **transition (R)**: `From the east gate to the Queen's hall, in one hour of dark.` / `"They whispered numbers," Lady Han says. "Ten, twenty, thirty…"` / `You look under the Queen's steps. A long rope with knots lies there!`
- clue c2 (R): `In the dark, the strangers walked from the east gate to the Queen's hall. One carried a flat board.`
- **다음 이유**: 밧줄로 무엇을 쟀나.

### 7. Mission 3 — The Knotted Rope (유지)
- **유형**: `number_entry`, 정답 **37** 불변. 매듭 규칙 letter 유지(dossier clues `A big knot is ten steps`, `three big knots, then seven small knots`).
- story (R): `You found the rope under the Queen's steps.` / `One stranger dropped it as the lamps came back.` / `"Builders measure with ropes like this," Lady Han says.`
- **8세 풀이**: 큰 매듭 3 × 10 + 작은 매듭 7 = 37. **대입**: 10/30/07 등은 기존 피드백 유지.
- **transition (R)**: `Why measure a path? To draw a map of it.` / `You remember the man with the flat board. You look behind the steps again.` / `There it is, in the leaves: a flat board with lines and dots!` / `"The King must see this," Lady Han says.`
- discovery 유지(`THEY MEASURED THE WAY`). clue c3·e3 유지(`37 steps from the east gate to the Queen's door`).
- **다음 이유**: 판이 어느 문을 노리는지 왕에게 보여 준다.

### 8. Final — The Board with No Names (v1 유지)
- **유형**: `picture_choice` · `finalMission` · `imageChoice`. 기존 `word_entry`(JAPAN) 폐기. location `THE KING'S HALL`, 배경 king_hall.webp.
- **story (R)**: `You bring the strangers' board to the King and the Queen.` / `It has no names. Only lines, dots and marks.` / `The Queen asks, "Whose door is marked?"`
- letterIntro `The board:`
- **letter (R 전문)**
  ```
  A line starts at the east gate.
  It goes to a door with a circle.
  By the circled door: three big dots and seven small dots.
  Another line goes to a far door. By it: five big dots and two small dots. No circle.
  By the pond is a square with an X. A wheel is drawn in the square.
  The dots count like the knots on the rope.
  ```
- question (R) `Whose door has the circle? Tap the picture.`
- **options (plan 순서)**: `king` The King's hall(king_hall.webp) → `lamp` The lamp house(lamp_house.webp) → `queen` **The Queen's hall**(queen_court.webp). altText v1과 같음.
- **정답**: `queen`.
- **8세 풀이**: 점을 밧줄 규칙으로: 동그라미 문 = 37, 먼 문 = 52 → M3: 밧줄 37걸음 = 동쪽 문 → 왕비의 문 → 연못 옆 X + 바퀴 = M1 전기실(문 아님) → Queen's hall.
- **대입**: king — 52·동그라미 없음 ✗ / lamp — X와 바퀴, 문 아님 ✗ / queen — 37(e3)·동쪽 문 출발(e2) ✓. 단일.
- **힌트**: H1 `A big dot is ten steps. A small dot is one step, like the rope.` / H2 `Your rope measured 37 steps from the east gate. To whose door?`
- **오답**: king `The far door has 52 steps, and no circle. How many steps to the circled door?` / lamp `The lamp house is the square with the X and the wheel. It is not a door with a circle.`
- successMessage `The circle is the Queen's door: 37 steps from the east gate!`
- **transition (R)**: `"And the X is the lamp house," says the King. "They will make the dark again."` / `Lady Han says, "Japan wants more power in Korea. The Queen works with Russia to stop it."` / `"Some men want to stop her."` / `The King folds the map slowly.` (v1의 `Lady Han puts her note in her family's letter box.` **삭제**)
- **증거 e4 "The Strangers' Map"**: `The strangers' board, with no names. A circle marks the Queen's door, 37 steps from the east gate. An X marks the lamp house.`
- **Final 증거(이 Case만)**: `s5_ep05_e3`(37), `s5_ep05_e2`(동선·판), `s5_ep05_e1`(전기실 바퀴·벨트). clueInputs c1~c3 answerDerivation.

### 9. Ending (새 전문 핵심)
- GOJONG `Thank you, Detective. I will keep this map.`(유지)
- QUEEN `Now I know they are watching me.` / QUEEN `Korea must choose its own way. I will not stop.`
- YOU (evidence e4) `The map shows the way to the Queen's door.`(유지)
- 역사(유지): `In 1895, the Queen worked with Russia to hold back Japan's power.` / `On 8 October 1895, men sent by Japan's minister attacked the palace.` / `The Queen was killed in that attack.`
- LADY HAN **(변경)** `I will not forget the truth of these days.` (← `I will keep our letters, and the truth of these days.` — "our letters"가 가문 편지를 암시)
- caseSummary (R): `Strangers made the lamps go dark and measured the way from the east gate to the Queen's door. Court Lady Han left a note with her water drop. The detective found the strangers' rope and their map. The map's circle marked the Queen's door. In 1895 the Queen worked with Russia to hold back Japan's power. On 8 October 1895, men sent by Japan's minister attacked the palace, and the Queen was killed.`

### 10. 역사 학습 + 사실/창작
- 사실: h1·h2(첫 전등·건달불), h3(건청궁 — 이름 하나만 본문, 처소 이름은 reveal), h4(왕비·러시아), h5(을미사변). 얼굴을 그리지 않는 원칙 유지. 시해 서술 한 문장.
- IN THIS MYSTERY (R): `Court Lady Han, the lamp man and the strangers are made up. So are Lady Han's note with its water drop, the dark night, the rope and the map.` / `The Queen and the King were real, but their words in this story are made up.` / `No photograph is surely the Queen, so the game never shows her face.`
- dossier fiction 줄 `Duri's note of 1866 (Case 04) is recalled for its water drop only.` **삭제**.

### 11. R/J/M 예시와 실제 단어 수
| # | R | J | M | R/J/M |
|---|---|---|---|---|
| 1 | Autumn, 1895. This morning, the King has called you, a detective, to Geoncheonggung. | Autumn, 1895. This morning, the King has called you, a detective, to Geoncheonggung. | Autumn, 1895. This morning, the King has summoned you, a detective, to Geoncheonggung. | 13/13/13 |
| 2 | You found my note. Good. I wrote no name. The strangers may read it too. | You found my note. Good. I wrote no name, because the strangers may read it too. | You found my note. Good. I left no name on it, in case the strangers read it as well. | 15/16/19 |
| 3 | The water drop is my mark. I carry the Queen's water each dawn. | The water drop is my mark, because I carry the Queen's water each dawn. | The water drop is my mark; each dawn I carry the Queen's water. | 13/14/13 |
| 4 | Lady Han's story of the night begins in the lamp house. Which card is from there? | Lady Han's story of the night begins in the lamp house. Which card in your notebook is from there? | Lady Han's account of the night begins in the lamp house. Which card in your notebook comes from there? | 16/19/19 |
| 5 | Whose door has the circle? Tap the picture. | Whose door did the strangers circle? Tap its picture. | Whose door have the strangers marked with a circle? Tap its picture. | 8/9/12 |
- 1번 J는 R과 같아도 된다(이미 짧고 쉬움). Final letter 3행 M은 dossier clue `three big dots`를 넣어 `Beside the circled door sit three big dots followed by seven small ones.`(13어).

### 12. 외부 의존 원장
| # | 위치 | 현재 내용 | 결정 | 대체 |
|---|---|---|---|---|
| X1 | M2 `clueInputs` recall + `play.recall` | `s5_ep04_e1`, "A Drop Like Duri's" / "Which note in your Notebook has one too?" / "Look for a note from the rebuilt palace." | **Case 안에서 완결** | ref `s5_ep05_e1`, §6 recall 문구 |
| X2 | e1 name | "The Water-Drop Note (1895)" | **Case 안에서 완결** | `Lady Han's Note` |
| X3 | M1 letter 서명 `— Han`, 인사 `Detective,` | 탐정을 아는 사람이 부름(v1은 가문 전승) | **Case 안에서 완결** | 서명 행 삭제, "Detective,"는 유지 — Intro "the King has called you"로 설명됨 |
| X4 | M1 talk.after | "You found my note. Good." 외 | **Case 안에서 완결** | §5 talk.after 4줄(이름 없는 이유, 물방울 = 왕비의 물을 나르는 사람의 표시) |
| X5 | ending Lady Han | "I will keep our letters, and the truth of these days." | **변경** | `I will not forget the truth of these days.` |
| X6 | dossier fiction | "Duri's note of 1866 (Case 04) is recalled for its water drop only." | **제거** | — |
| X7 | plan notes | "Case 06 recalls s5_ep05_e4 (the strangers' map: the palace is watched)." | **제거** | (C06 재설계가 결정. 이 Case 서술에서 뺌) |
| X8 | v1 Intro 1행, v1 transition letter box, v1 동기 "집안에 전해진 대로" | 연속성 | **제거** | §3·§4·§8 |
| X9 | v1 인과 "C06 지도 회상", ID "C06·C07 참조 유지" | 연속성 서술 | **제거** | §16·§18 |
| X10 | 들어오는 참조 | C06 recall `s5_ep05_e4`·`s5_ep05_e1`, C07 `s5_ep05_e1` | **그 Case 쪽에서 결정** | id 유지 → 깨지지 않음 |
| X11 | 쪽지 그림의 물방울(coal scoop) | 이 Case | **유지(이유: 이름 대신 쓴 한 상궁의 표시)** | §13 |
| X12 | `s5Ep05EvidenceLinks` | `{}` | 유지 | — |
| X13 | dossier factIds | 모두 `s5_ep05_h*` | 유지 | final 항목만 교체 |

### 13. 물방울 설명 (Case 안)
- 누가: 한 상궁. 왜: 낯선 이들이 쪽지를 먼저 볼 수도 있어 이름을 쓰지 않고, 새벽마다 왕비의 물을 나르는 자기 표시인 물방울만 그렸다. 어디서 밝혀지나: M1 talk.after. 퍼즐 정답에는 쓰이지 않는다(작성자 확인용).

### 14. 독립성 검증
| 검사 | 근거 | 결과 |
|---|---|---|
| (a) Intro | 1895, 왕이 탐정을 부름, 첫 전등, 정전, 낯선 두 사람 | 가능 |
| (b) M1 | 쪽지 6줄 + 그림 4장 | 가능 |
| (b) M2 | 이 Case e1 recall + 섞인 증언 7줄 | 가능 |
| (b) M3 | 매듭 규칙 | 가능 |
| (b) Final | 판 letter 6줄 + 그림 3장 + M3의 37(힌트 2가 다시 말함) | 가능 |
| (c) Ending | 왕·왕비 대사, 역사 3줄 | 가능 |
| 남은 타 Case 참조 | — | **없음** |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| Final JAPAN 베끼기 | 일본·러시아 사실(이야기·엔딩) | 판 읽기 → 왕비의 문 |
| 탐정 수동 | 한 상궁 증언·밧줄 규칙 | 탐정이 밧줄·판을 직접 발견 |
| 지도 돌출 | e4 | "flat board" 복선, "why measure → map" |
| M2 지문 시간순 | 카드 id·정답 | 9:00부터 섞음 |
| M2 recall Duri | recall 독 | 이 Case 쪽지 recall |
| 쪽지 "— Han"·"our letters" | 쪽지·물방울 | 이름 없는 쪽지, 물방울 = 한 상궁의 표시 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전 정보 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 정전·낯선 이 | — | 읽기 | 왕이 부름 | 전기실 |
| M1 | 사고인가 고의인가 | — | 탐색·벨트 | 고의, 한 상궁의 쪽지 | 증언 |
| M2 | 동선 | e1(전기실) | recall + 정렬 | 동쪽 문→왕비 처소, 판 든 사람, 밧줄 | 밧줄 읽기 |
| M3 | 무엇을 쟀나 | 동선 | 37 | 37걸음, 판 발견 | 왕에게 |
| Final | 누구를 노리나 | e1·e2·e3 | 점 읽기 → 그림 | 왕비의 문, 다시 어둠 계획 | 엔딩 |
| Ending | 왜 위험한가 | — | 읽기 | 을미사변 | (Case 끝) |

### 17. 어린이 시뮬레이션 (설계 검토)
| 항목 | 판단 |
|---|---|
| 무엇을 보나 / 누르나 | 전기실 그림·쪽지 탭 / 카드 recall·드래그 / 숫자 / 그림 탭 |
| 근거가 화면에 있나 | 예. "like the knots on the rope" + 힌트 2(37) |
| 함정 | lamp(X 표시) — 질문이 "circle", king — 52 |
| 재시도·힌트 | 즉시 재시도, 힌트 2개 |
| 목표 기억 | objectives 4번, 왕비 "Whose door is marked?" |
| 위험 | 쪽지 서명이 없어져 M1에서 "누가 썼지?" → 바로 talk.after가 답함 |

### 18. ID·저장 영향
- id 불변: m1~m3·final, e1~e4, c1~c3. 이름 변경 e1. 설명 변경 e1·e4·c2.
- M2 recall 대상 변경: 저장 키 `s5_ep05_m2:recall`은 증거 id를 담지 않는다 → 옛 진행에서 Duri 카드를 가져온 플레이어는 새 카드도 "가져옴" 상태로 보인다(무해).
- 정답 변경: Final `JAPAN` → `queen`(imageChoice). 저장 없음.
- M1 letter 줄 수 7 → 6(세 레벨 같이): levels.json 줄 키 갱신.
- dossier: `s5_ep05_m2` clue `before the lamp man came back` → `By then, the men were gone`. `s5_ep05_final` answer `queen`, `fiction: true`, clues `three big dots`, `a door with a circle`, factIds h4·h5는 transition·ending.

### 19. 엔진 변경
- 없음. 확인 1건: `picture_choice` Final에서 1536×1024 장소 그림 3장이 320폭에 맞게 배치되는지. 문제 시 `text_choice`로 대체(논리 동일).

### 20. 이미지
- 신규 없음. king_hall·lamp_house·queen_court 재사용. coal scoop 쪽지의 물방울은 "한 상궁의 표시"로 맞는다. (선택 사양, 생성 안 함) `case_05/strangers_board.webp` — v1과 같은 사양, 현재 설계에 불필요.

### 21. 작업량
- **M**: `s5_ep05/case.plan.json`, `levels.json`, `history_dossier.json`(m2 clue, final, fiction 줄), 생성물, C05 테스트(JAPAN, M1 letter 줄, M2 recall id).

### 22. 위험
| 위험 | 대응 |
|---|---|
| "큰 점 = 10" 잊음 | letter 마지막 줄 + 힌트 1 |
| 정답 그림이 3번째 | 4개 Case 정답 위치 3·2·(talk)·3 — 필요하면 queen을 2번째로 |
| 비극을 성공 직후 들음 | 담담한 1문장, 왕·왕비 대사로 완충 |

---

## 요약 — 4개 Case

| Case | 새 Final | 정답 | 쓰는 증거(이 Case만) | 엔진 |
|---|---|---|---|---|
| 02 | 이순신 present 3 → 진술 판정 | `seok` | e1·e2·e3 | talk.before + text_choice (기존) |
| 03 | 4명 소거(도면·글·밤) | `okbun` | e1, c2, M1 transition | text_choice (기존) |
| 04 | 대원군 present 3(표식·끌·장부 서명) | 대화 완료(`rebuilt`) | e1·e3·e2 | evidence_talk + T1·T2 |
| 05 | 판의 점 → 동그라미 문 | `queen` | e1·e2·e3 | picture_choice (기존 그림) |

- 제거한 타 Case 요소: recall 3개(C02 M2←C01 e2, C03 M1←C02 e1, C04 M1←C01 e2), clueInputs 4개(C02 M1·Final ←C01 c1, C04 Final ←C02/C03 e1), C04 present `note`, Bun-i/Seok/"same water drop"/"But why?"/"our letters" 대사, discovery 3개, 연도 시리즈 증거 이름 4개, dossier 타 Case factIds(C02 M2, C04 M1)와 fiction 줄, v1의 시대 이동 첫 줄·편지 상자 줄·가문 동기·`p_family2`.
- Case 안에서 완결: 글자 원리(C02 창고 벽 수병 글자판, C04 두리·새김 규칙), 물방울 4개(석 = 비, 옥분 = 이름 대신, 두리 = 별명·서명, 한 상궁 = 이름 대신 자기 표시), C05 M2 recall은 같은 Case e1으로.
- 미션 엔진 교체: C04 M3 timeline → trace_deduction(좌표 재측정). 새 엔진 코드: T1·T2(계획됨) 외 없음. 새 그림 없음.

---

# §C2 Case 06~09 (독립 사건 설계)

> §I-2 결정 반영: C08의 물방울 표식은 **작은 불꽃 그림(a small flame)**으로 바꾼다. 아래 C08 설계의 "water drop" 문구(M1 쪽지, M3 공책 특징, 경순의 표시)는 구현할 때 모두 flame으로 읽는다. C09의 Mr. Pak → Mr. Choi 개명은 취소한다.

## Seoul Case 06–09 재설계안 v2 — Case마다 독립 사건 (구현용)

작성 2026-11-09 · 읽기 전용 분석(앱 실행·실제 어린이 테스트 없음).
근거: §0 정책(이 문서의 상위 정책, 이전 `season_frame.md`의 S-F1·S-F2와 가족 공개를 대체), 이전 설계 `redesign_c06_09.md`(이하 "v1"), `engine_save_impact.md`, `docs/SEOUL_CASE02_12_FULL_AUDIT.md` PART 3, 각 `case.plan.json`(C08은 작업 트리: 엔딩 2줄만 미커밋 변경), `history_dossier.json` cases[5..8], 그림 `case_08/maebong_hill.webp`·`village_home.webp`(직접 확인).

## 0. 공통 전제 (4개 Case 모두)

- **독립 원칙**: 각 Case의 Intro·미션·Final·Ending은 그 Case 화면만으로 이해되고 풀린다. 다른 Case의 증거 id, 인물, 물건(편지 상자·지키미·분이), 사건("1895 지도", "황제의 편지")을 쓰지 않는다. 필요한 역사 배경(1897 황제, 1905 조약, 이토, 1910 병합, 3·1운동, 임시정부)은 **그 배경이 필요한 Case 안에서 각각** 설명한다. 그래서 1905 조약은 C06과 C07 양쪽 Intro에 따로 나온다(중복은 의도).
- **시대 이동 첫 줄 없음**: v1의 "A water-drop note finds you. You read it. Now it is …"를 모두 지운다. Intro 첫 줄은 지금 데이터처럼 "계절, 연도. 탐정이 어디에 누구의 손님으로 있는가"다.
- **물방울**: C06·C07·C09에서는 사건 기능이 없으므로 **제거**한다(서명은 이름 또는 무명). C08에서만 M3 추리 단서로 남기고, 누가·왜 그렸는지 C08 안에서 밝힌다.
- **가정한 엔진 변경**(v1과 같음): 2b1 대화 Final 힌트 버튼, 2b2 present당 카드 3장, 2b3 2회 오답 = `tell` 안내(카드 빛남은 3회부터). C06·C07·C09 Final이 쓴다. C08은 엔진 변경 없음. **독립화 자체로 새로 필요한 엔진 변경은 없다**(recall·clueInputs 삭제는 데이터만).
- **화면 순서 = plan 순서**(섞는 코드 없음). 보기·카드는 화면 순서 그대로 적었고 정답 순서와 다르게 했다.
- **저장**: mission·evidence·clue id 유지, 미션 수 유지. 뜻이 바뀐 present·timeline 카드는 새 id. 이름·설명만 바뀐 증거는 id 유지.
- **생성기 경고(신규)**: 다른 Case가 더 이상 이 Case의 e4를 받지 않으므로 `clue_never_used`(경고, `tool/season_gen/clue_graph_check.dart:28,348-355`)가 Case마다 e4에 1건씩 생길 수 있다. 오류가 아니라 경고다(생성은 막지 않음). 독립 정책상 의도된 결과로 기록한다.
- 단어 수 = `[A-Za-z0-9:'ō-]` 토큰 실측(`scratchpad/wc2/lines.txt`). "6:40", "1907"은 1단어.
- 레벨: 사건·단서·정답 R/J/M 동일, 줄 수 동일. J = 원인·결과(because/so/but), M = 맥락·추론.

### 외부 의존이 들어오는 곳 (Case 06–09 밖에서 이 4개 Case를 읽는 것)
| 받는 쪽 | 현재 | 이 문서의 영향 | 처리 주체 |
|---|---|---|---|
| C10 M1 `clueInputs` recall `s5_ep09_e4` ("Kim Gu trusts Haesu") | C09 e4를 기억 카드로 씀 | C09 e4 설명에서 "trusts Haesu"를 뺀다 → C10 쪽 recall은 어차피 독립 정책으로 제거 대상 | C10 설계 |
| C12 M? `clueInputs` recall `s5_ep08_e4` ("The letter box Gyeongsun showed in 1919") | C08 상자 카드 | C08 e4가 "경순의 잠긴 상자(계획)"로 바뀌어 C12 카드와 뜻이 어긋남 → C12 쪽 recall 제거 필요 | C12 설계 |
| `test/sandbox/s5_seoul_case01_test.dart:164-170` | C08 엔딩에 "엄마, 고마워요"가 있다고 단언 | C08 엔딩에서 분이 편지를 뺀다 → 이 테스트는 **반대 단언으로 교체**(C08 엔딩에 "Bun-i"·"엄마"가 없다). 테스트 약화가 아니라 정책 변경에 맞춘 기대값 교체 | 구현 |
| `test/sandbox/s5_seoul_rookie_test.dart:104-119` | C06 Final 자물쇠 글, C09 Final letter 문장 | v1과 같은 이유로 갱신 | 구현 |

---

## Case 06 — The Emperor's Secret Letter (1907)

### 1. 제목·역사 배경
- 제목 유지: **The Emperor's Secret Letter**.
- 배경(이 Case 안에서 모두 설명): 1897 고종이 황제가 됨(대한제국) → 1905 일본이 조약을 강요, 외교권 상실 → 1907 헤이그 만국평화회의에 특사 3인(이준·이상설·이위종) 비밀 파견 → 회의 입장 거부 → 이준 7월 헤이그에서 사망 → 같은 달 일본이 이를 구실로 고종 강제 퇴위.

### 2. 독립 사건 목표 (한 문장)
궁에 숨겨진 황제의 비밀 편지를 찾아 **어떤 감시자에게도 보이지 않게** 궁 밖으로 빼내 특사 이준에게 건넨다. (`goal` 유지: "Find the hidden letter, take it out unseen, and give it to the envoy Yi Jun.")

### 3. 인물 동기
| 인물 | 동기 (이 Case 안에서만) |
|---|---|
| 고종 황제 | 1905 조약은 자신이 원한 것이 아니라고 세계에 알리고 싶다. 편지가 감시자에게 들키면 계획이 끝난다 |
| 서 비서(창작, dossier의 Mr. Seo) | 해 질 녘 편지를 숨기고, 감시가 붙어 곧바로 궁을 떠나야 했다 |
| 봉수(심부름꾼, 창작) | 숨기는 장면 일부를 보았다. 잊지 않으려고 본 것을 쪽지에 적어 두었다. 궁 길을 다 안다. 숙부가 작은 서문을 지킨다 |
| 이준 | 편지가 한 번이라도 감시자 눈에 띄었으면 떠날 수 없다 → **Final의 의심** |
| 감시자(창작, 무명) | 일본 관리에게 보고하는 사람들. 궁 문과 이준의 골목을 지킨다 |

### 4. Intro (R, 6줄 — 현행 줄 수 그대로)
문제(현행): King→Emperor 변화 설명 없음(C06-6), 1905 조약 추상어 몰림. v1 문제: 시대 이동 첫 줄(철회).
```
Spring, 1907. You are a guest of Emperor Gojong at Gyeongun Palace.
In 1897, King Gojong became Emperor Gojong. He wanted the world to see Korea as a free country.
In 1905, Japan forced Korea to sign a paper. Korea lost the right to deal with other countries.
Now many countries meet at The Hague, far away in Europe.
The Emperor will send three envoys there in secret, to tell the world the truth.
But his secret letter is hidden, and watchers stand at every gate.
```
- "Emperor"는 2줄째에서 이 Case 안에 설명된다(1897). 다른 Case의 "King Gojong"을 몰라도 "왕이었던 사람이 황제가 되었다"로 읽힌다.
- J/M 1~3줄은 15번 표. 4~6줄 J/M은 현행 levels.json 문장을 정보량만 맞춰 유지.

### 5. Mission 1 — The Thread on the Bark (v1 유지, 물방울 제거)
- **목적**: 편지가 숨겨진 곳을 찾는다.
- **유형**: `trace_deduction` · `deductions` · `multipleChoice`. 그림 `c06_palace_garden.webp`·영역 그대로.
- **변경점(v1 유지)**: 쪽지가 흔적 3개를 미리 다 말하지 않는다(흔적 문장은 그림 탭 시 `clues[].line`). e1 설명에 실 흔적. **(v2 추가)** letterIntro의 "in the King's letters, with a small water drop" 삭제, recall 삭제, clueInputs `s5_ep05_e1` 삭제.
- **letterIntro(R)**: "Bongsu wrote down what he saw, so he would not forget. He reads it to you:"
- **letter(R)**: `The secretary hid the Emperor's letter at dusk. Then he ran.\nI saw him go into the garden. He left marks.\nLook for three marks. They show the place.\n— Bongsu`
- **흔적 line(유지)**: "Footprints leave the path. They go to the trees, not to the steps." / "A yellow silk thread is caught on rough bark, at hand height." / "By a root, the moss is pushed aside. Someone knelt there."
- **화면 단서**: 정원 그림 + 흔적 3개(탭할 때마다 영어 한 줄 + 한국어 glossary).
- **정답**: b "The hollow of the old pine". 보기: a lantern, b pine, c pots(그림 위 장소 탭이라 순서 무관).
- **8세 풀이 경로**: 쪽지에서 "three marks" → 발자국·실·이끼 탭 → 장소 고르기 열림 → "trees, not steps"로 화분 X, "bark"로 석등 X, "root"로 나무 → 소나무 구멍.
- **선택지 대입**: lantern(돌: bark·root 불충족) / pots(계단 옆: "not to the steps" 위배) / pine(3개 충족) → 단일.
- **힌트(R)**: 1 "Tap the footprints, the thread and the moss." 2 "Which place has bark and roots, and stands among the trees?"
- **오답**: lantern "A lantern is stone. The thread was on rough bark." / pots "The footprints go to the trees, not to the steps."
- **상태 변화**: 편지(노란 비단 두루마리, 황제 인장) 확보. 비단 실 한 올이 뜯겨 있음.
- **다음 미션 필요 이유**: 문마다 감시자 — 보이지 않게 나가야 한다.
- **e1**(id 유지) name "The Water-Drop Note (1907)" → **"Bongsu's Note"**, description: "Bongsu's note about the hiding place. A yellow silk thread was caught on rough bark by the old pine."

### 6. Mission 2 — The Way Past the Watchers (v1 유지, 1895 지도 줄 교체)
- **목적**: 감시를 피해 궁을 빠져나갈 길의 순서를 정한다.
- **유형**: `order_sequence` · `sequence`, codeLength 4, 보기 6(미끼 2).
- **story(R)**: `The letter is under your coat now.` / `The watchers report to Japan's officials. They watch the palace paths.` / `Bongsu knows every path. He whispers the way.`
  (현행 2줄째 "You remember the strangers' map of 1895. Palace paths get counted." 삭제 — C05 사건 기억에 기댐. clueInputs `s5_ep05_e4` textMention 삭제.)
- **letter(R, 화면 순서 그대로)**:
```
After the old well, go out by the little west gate. My uncle keeps it.
The watchers stand at the big front gate all day.
Outside the west gate is the lane by the stone wall. Walk down it.
Do not cross the throne hall's yard: everyone sees it.
Start behind the library hall. From there, go to the old well.
```
- **보기 화면 순서**: lane, front_gate, well, throne, library, west_gate.
- **정답**: `library,well,west_gate,lane`.
- **8세 풀이 경로**: "Start" 줄 → library 1 → 같은 줄 "go to the old well" → well 2 → "After the old well … west gate" → west gate 3 → "Outside the west gate is the lane" → lane 4. front gate("watchers stand"), throne("Do not cross")는 빠진다.
- **대입**: 관계 4개(library 처음, library<well, well<west_gate, west_gate<lane) → 4칸 전순서 하나. 미끼 2개는 각각 문장 하나로 배제 → 단일.
- **힌트(R)**: 1 "Find the word Start. Then find what comes after each place." 2 "Two places are watched or seen by everyone. Leave them out."
- **오답**: `throne,well,west_gate,lane` "Everyone sees the throne hall's yard. Bongsu says to start behind the library." / `library,well,front_gate,lane` "Watchers stand at the big front gate all day." / `library,west_gate,well,lane` "Read again: you go to the west gate AFTER the old well." / orderFeedback "The right places. Which line says Start? What comes after it?"
- **상태 변화**: 서문으로 궁 밖. 숙부가 문을 닫아 줌.
- **다음 미션 필요 이유**: 이준의 골목에도 감시자가 걷는다.
- c2·e2 유지("LIBRARY → WELL → WEST GATE → LANE", Bongsu's Way). e2 description: "Behind the library, by the old well, out the little west gate his uncle keeps, down the lane. No watchers there."

### 7. Mission 3 — The Watchers' Walks (v1 유지: "as soon as")
- **목적**: 감시자가 없는 순간에 이준의 문을 두드린다.
- **유형**: `number_entry` · `numberCode` · time · 답 `0650`.
- **story(R)**: "Bongsu's uncle knows the watchers' times. He gives you a paper."(현행 유지)
- **letter(R)**: `Yi Jun lives at the end of this lane.\nWatchers walk past his door at 6:00, 6:40 and 7:20.\nEach walk takes ten minutes.\nKnock as soon as the 6:40 walk has passed.`
- **question(R)**: "At what time do you knock? Use four numbers. (Seven o'clock is 07:00.)"
- **8세 풀이 경로**: 6:40 → 10분 → 6:50 → "as soon as" = 바로 그때 → 0,6,5,0(예시 07:00이 앞자리 0을 알려 줌).
- **대입**: 0640(지나가는 중) / 0650 ✓ / 0700·0710(as soon as 위배) / 0720(다음 순찰) / 0610(6:00 순찰) → 단일.
- **힌트**: 1 "Find the walk at 6:40. How long does one walk take?" 2 "6:40 and ten more minutes. Knock right then."
- **오답**: 0640 "At 6:40 the watchers are just walking past." / 0700 "Too late! Knock as soon as the walk has passed." / 0720 "That is the next walk. Watchers are there." / 0610 "That is the 6:00 walk. The paper says 6:40."
- **상태 변화**: 6:50 노크, 이준이 문을 연다.
- **다음 미션 필요 이유**: 이준이 비단의 뜯긴 실을 보고 "감시자가 봤나?"라고 의심한다.
- e3 description: "Watchers walk Yi Jun's lane at 6:00, 6:40 and 7:20. Each walk takes ten minutes. You knocked at 6:50."

### 8. Final — No One Saw It (v1 유지: 이 Case 증거 3장)
- **유형**: `evidence_talk` · `talks` · `examine` · answer `unseen`(id `s5_ep06_final` 유지; letterLock FORCED 애너그램 삭제).
- **story(R)**: `Yi Jun unrolls the yellow silk. He stops.` / `"A thread is pulled out of this silk," he says.` / `"If a watcher saw this letter, the Emperor's plan is lost."`
- **letterIntro / letter(R)**: "Yi Jun's three worries:" / `A thread is pulled out of the silk.\nWatchers stand at every palace gate.\nWatchers walk past my door.`
- **question(R)**: "Show Yi Jun that no watcher saw the letter."
- **interview**: speaker `yi_jun`, goal 같음, opening "Watchers are everywhere in Seoul. I must be sure.", 선택 질문 `watchers` "Who are the watchers?" → "Men who report to Japan's officials." / "They watch the Emperor and his friends."

| present id(새) | prompt (R) | 카드 화면 순서 | accepted | 정답 대사 | miss | tell (안내) |
|---|---|---|---|---|---|---|
| `thread` | Yi Jun asks: "Who pulled this thread?" | e3, e1, e2 | s5_ep06_e1 | YOU "No one. It caught on the pine's rough bark when he hid it." / YI JUN "Bongsu saw the thread there. Good." | "That does not tell me about the thread." | "Which card talks about a yellow thread? Read it again." |
| `gate` (req thread) | "Watchers stand at every palace gate. Did they see you leave?" | e1, e3, e2 | s5_ep06_e2 | YOU "We left by the little west gate. Bongsu's uncle keeps it." / YI JUN "Not the front gate. Good." | "That does not show how you left the palace." | "Which card shows your way out of the palace?" |
| `door` (req gate) | "Watchers walk past my door. Did one see you knock?" | e2, e3, e1 | s5_ep06_e3 | YOU "The 6:40 walk takes ten minutes. We knocked at 6:50, when it had passed." / YI JUN "And the next walk is at 7:20. No one saw you." | "That does not show when you knocked." | "Which card has the watchers' times?" |

finishWhen `[thread, gate, door]`, finishLabel "GIVE YI JUN THE LETTER".
- **Final 증거(이 Case 것만)**: s5_ep06_e1(실), e2(서문 길), e3(감시 시각). 3개 모두 필수. 다른 Case 카드 없음.
- **해결 방식**: 이준의 걱정 3개(실/궁 문/내 문)를 각각 그 대상 낱말이 있는 카드로 답한다.
- **대입 검사**: thread = 실 문장이 있는 e1만, gate = 서문 길 e2만, door = 시각 e3만. 나머지 두 장은 그 질문의 대상을 담지 않는다 → 각 단계 단일.
- **힌트(b1)**: 1 "Each worry is about one place: the pine, the palace gate, Yi Jun's door." 2 "Thread: Bongsu's Note. Gate: Bongsu's Way. Door: the Watchers' Times."
- **successMessage**: "Yi Jun smiles. \"No one saw it. The plan is safe.\""
- **transition(R)**: `Yi Jun lays the letter in his travel box and locks it.` / `"I leave Seoul today, in secret," he says.` / `Bongsu folds his note and keeps it.` (현행 3줄째 그대로 — v1의 "family's old letter box" 줄과 통합안의 "Bongsu gives the box to his aunt, Mrs. Kang" 줄은 **삭제**.)
- **e4**(id 유지) name "The Emperor's Letter, with Yi Jun", description: "The Emperor's secret letter, safe in Yi Jun's travel box. No watcher saw it. It says Japan forced the 1905 treaty on Korea." (v1의 "C07 Final이 이 카드를 쓴다"는 이유는 철회. 문장은 이 Case 역사 요약으로서 유지.)

### 10. Ending (새 핵심 줄)
- YI JUN "The letter is safe. We leave in secret." / YOU "No watcher saw it. Not at the pine, not at the gate, not at your door." (evidence s5_ep06_e4)
- narrator "In 1907, Yi Jun, Yi Sang-seol and Yi Wi-jong went to The Hague." / "The Emperor's letter said he never agreed to the 1905 treaty." / "But the envoys were not let into the conference." / "Yi Jun died in The Hague that July." / "Japan used the envoys as an excuse. It forced the Emperor to give up his throne."
- BONGSU "I will keep my note. One day people will read the truth." (현행 유지. v1의 "My note is in the box now"와 귀환 줄 "The water drop on your note dries" **삭제**)
- 해결되는 Intro 문제: 숨겨진 편지가 보이지 않게 이준에게 전달됨.
- `hook`(UI 미표시, 데이터만): "The world did not let the envoys in. Who will listen to Korea now?" → **"The envoys were not let in, but the Emperor's letter left Seoul unseen."**(다음 Case 예고 제거)

### 11. 역사 학습 + 사실/창작
- 배움: 1897 황제 즉위(왜 황제가 되었나 한 줄), 1905 조약 강요·외교권 상실, 1907 헤이그 특사 3인·입장 거부·이준 사망·고종 강제 퇴위.
- IN THIS MYSTERY(R): "Bongsu, Mr. Seo, the watchers, the old pine, the watchers' times and the travel box are made up. The three envoys, the 1905 treaty and The Hague are real history."
- 근거 주의: "황제가 동의하지 않았다"는 친서의 주장 형태("The Emperor's letter said …"). 1897 줄의 "free country"는 대한제국 선포의 자주독립 의도를 아동용으로 쓴 것(단정 아님, "He wanted …").
- dossier `fiction[1]` "so is Bongsu's water-drop note of 1907" → "so is Bongsu's note".

### 12. 난이도별 핵심 줄 (실측 단어 수)
| # | R | J | M |
|---|---|---|---|
| 1 Intro 첫 줄 | Spring, 1907. You are a guest of Emperor Gojong at Gyeongun Palace. (12) | It is spring, 1907, and you are a guest of Emperor Gojong at Gyeongun Palace. (15) | Spring, 1907: you are staying at Gyeongun Palace as a guest of Emperor Gojong. (14) |
| 2 1897 | In 1897, King Gojong became Emperor Gojong. He wanted the world to see Korea as a free country. (18) | In 1897, King Gojong became Emperor Gojong, because he wanted the world to see Korea as a free country. (19) | In 1897, King Gojong took the title of Emperor, so that the world would treat Korea as a free and equal country. (22) |
| 3 1905 | In 1905, Japan forced Korea to sign a paper. Korea lost the right to deal with other countries. (18) | In 1905, Japan forced Korea to sign a treaty, so Korea lost the right to deal with other countries. (19) | In 1905, Japan forced a treaty on Korea, taking away its right to deal with other countries on its own. (20) |
| 4 M3 규칙 | Knock as soon as the 6:40 walk has passed. (9) | As soon as the 6:40 walk has passed, knock on the door. (12) | Knock the very moment the 6:40 walk has passed, not a minute later. (13) |
| 5 Final 답 | It caught on the pine's rough bark when he hid it. (11) | The thread caught on rough bark when the secretary hid the letter in the pine. (15) | The thread snagged on the pine's rough bark as the secretary pushed the letter into the hollow. (17) |

### 13. 외부 의존 원장 (C06)
| # | 위치 | 현재 | 결정 | 교체 내용 |
|---|---|---|---|---|
| 1 | `missions[0].clueInputs[0]` | recall `s5_ep05_e1` (한 상궁 물방울 쪽지) | **제거** | clueInputs 항목 삭제 |
| 2 | `missions[0].play.recall` | "A Drop Like Lady Han's" / "…Which note in your Notebook matches it?" / "Find the court lady's note…" | **제거** | `recall` 키 삭제(입력이 없으면 `play_recall` 오류이므로 둘 다 지움) |
| 3 | `missions[0].play.letterIntro` | "A note in the King's letters, with a small water drop. Bongsu reads it to you:" | **Case 안에서 완결**(쪽지는 단서라 유지, 물방울·"King's letters"는 기능 없음) | "Bongsu wrote down what he saw, so he would not forget. He reads it to you:" (J/M 같은 정보) |
| 4 | `missions[0].play.evidence.name/description` | "The Water-Drop Note (1907)" / "…with a small water drop…" | **Case 안에서 완결** | "Bongsu's Note" / 5절 e1 문구 |
| 5 | `missions[1].clueInputs[1]` | textMention `s5_ep05_e4` (1895 낯선 사람들의 지도) | **제거** | 항목 삭제 |
| 6 | `missions[1].play.story[1]` | "You remember the strangers' map of 1895. Palace paths get counted." | **Case 안에서 완결** | "The watchers report to Japan's officials. They watch the palace paths." |
| 7 | v1 Intro 첫 줄 | "A water-drop note finds you…" | **제거** | 4절 Intro 1줄 |
| 8 | v1 Final transition 3줄째 | "Bongsu puts his water-drop note in his family's old letter box." | **제거** | 현행 "Bongsu folds his note and keeps it." |
| 9 | 통합안(integration.md:47) C06 Ending | "Bongsu gives the box to his aunt, Mrs. Kang. She is going to Harbin." | **제거** | 없음 |
| 10 | v1 Ending | "My note is in the box now…" / "The water drop on your note dries. You are home again." | **제거** | 현행 "I will keep my note. One day people will read the truth." |
| 11 | v1 e4 근거 | "C07 Final이 e4를 받는다" | **제거(근거만)** | e4 문장은 이 Case 요약으로 유지 |
| 12 | `hook` | 다음 Case 예고형 질문 | **Case 안에서 완결** | 10절 hook |
| 13 | dossier `cases[5].fiction[1]` | "Bongsu's water-drop note of 1907" | **Case 안에서 완결** | "Bongsu's note" |
| — | discovery, evidenceLinks | C06에는 discovery 없음, `s5Ep06EvidenceLinks` 비어 있음 | 해당 없음 | — |

### 14. 독립성 검증 (C06)
| 검사 | 결과 | 근거 |
|---|---|---|
| (a) Intro 이해 | 가능 | 황제(1897)·1905 조약·헤이그·감시자를 Intro와 M2 story에서 설명 |
| (b) 미션·Final 풀이 | 가능 | M1 흔적 = 그림, M2 = 봉수 쪽지, M3 = 숙부 쪽지, Final = e1·e2·e3(모두 이 Case) |
| (c) Ending 이해 | 가능 | 결과(특사·퇴위)를 Ending에서 직접 서술 |
| 남은 다른 Case 참조 | **없음** | clueInputs의 타 Case ref 0, recall 0, Bun-i·상자·물방울 0 |
| "Emperor" | Intro 2줄째에서 설명 | "In 1897, King Gojong became Emperor Gojong…" |

### 15. 유지/변경 표 (현행 → v2)
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 흔적 추리 | 엔진·그림·영역·정답 | 쪽지가 흔적을 미리 말하지 않음, 물방울·recall 제거, e1 이름 |
| M2 순서 = 쪽지 순서(C06-3) | 엔진·보기·정답 | 쪽지 줄 섞기 + 관계어, 보기 순서, 1895 지도 줄 교체 |
| M3 범위 정답(C06-2), 0 입력(C06-7) | 0650 | "as soon as", 예시 07:00, 0700 피드백 |
| Final FORCED 애너그램(C06-1) | final id, e4 id | evidence_talk "unseen", 이 Case 증거 3개 |
| King→Emperor 미설명(C06-6) | — | Intro 2줄째(1897) |
| v1 시즌 연결 줄(시대 이동·상자·가족) | — | 모두 삭제 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 편지 숨김·감시 | — | 읽기 | 목표 | 봉수 쪽지 |
| M1 | 위치 모름 | 봉수 쪽지 | 흔적 3 탭 → 장소 | 편지 확보(실 뜯김) | 문마다 감시 |
| M2 | 궁 탈출 | 편지 | 관계어로 길 순서 | 서문 탈출 | 골목 감시 |
| M3 | 이준 문 앞 순찰 | 골목 | 6:40+10 | 6:50 노크 | 이준이 실을 보고 의심 |
| Final | "보였나?" | e1·e2·e3 | 걱정 3개에 증거 | 이준이 믿고 상자에 넣음 | 엔딩 |
| Ending | 결과 | e4 | 대화·서술 | 특사 출발·역사 결과 | (끝) |

### 17. 어린이 플레이 시뮬레이션 (설계 검토, 실제 테스트 아님)
| 항목 | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 보는 것 | 정원 그림 | 쪽지 5줄 + 보기 6 | 쪽지 4줄 + 키패드 | 이준 대사 + 카드 3 |
| 누르는 것 | 흔적 3 → 장소 | 보기 4개 순서 | 4칸 숫자 | 카드 1장 × 3 |
| 근거가 화면에 | 흔적 line | 관계어 줄 | 시각·10분·as soon as | 카드 설명 |
| 정답처럼 보이는 오답 | 없음 | Start 없이 읽으면 혼동 → Start로 해결 | 0700 → 피드백 | 카드마다 대상 낱말 다름 |
| 다른 Case 지식 필요 | 없음(v1의 C05 물방울 recall 제거) | 없음(1895 지도 제거) | 없음 | 없음 |
| 재시도·힌트 | 무제한·2단계 | 무제한·Undo | 무제한 | miss → tell → 3회 빛남, b1 힌트 |
| 목표 기억 | "Where is it hidden?" | "Past the watchers" | "Watchers walk this lane too" | 이준이 "unseen"을 다시 말함 |

### 18. ID·저장 영향
- id 변화 없음(m1~m3, final, c1~c3, e1~e4). Final present `thread/gate/door` 신규(이전 Final은 letterLock이라 present 없음). Final missionType letterLock→examine: 저장된 자물쇠 상태는 키가 달라 무시(engine_save_impact §3).
- 텍스트 변경 증거: e1(이름·설명), e2, e3, e4 설명. 이 Case 증거를 받는 다른 Case: 현재 C07(e1 recall, e4 Final) — C07 v2에서 모두 제거되므로 정합.
- `history_dossier.json` cases[5]: puzzles[1]·[2]의 clue 문구를 새 letter 줄로, puzzles[3]은 answer `unseen`·whyOnly/whyNot을 대화 기준으로 다시 씀(FORCED 문구 삭제), fiction[1] 수정.

### 19. 엔진 변경
- 공통 2b1·2b2·2b3. C06 고유 없음. 독립화로 인한 변경 없음.

### 20. 이미지
- 새 그림 없음. `c06_palace_garden`·`c06_west_lane`·`yi_jun_house` 재사용. 물방울·상자가 그려진 그림 없음(확인: 파일 목록 3장, 상자 그림은 이준의 여행 상자뿐).

### 21. 작업량
- **M**(v1과 같음, 독립화 몫은 S 미만: recall·clueInputs 3건 삭제, 문장 6곳). 파일: `s5_ep06/case.plan.json`, `levels.json`, `planning/history_dossier.json`, 재생성 `s5_ep06*.g.dart`·`s5_seoul_history.g.dart`, `test/sandbox/s5_seoul_rookie_test.dart`.

### 22. 위험과 대응
| 위험 | 대응 |
|---|---|
| 엔진 2b2 전에 생성하면 play_check(`offered != 2`) 실패 | 엔진 PART 먼저 |
| 1905 설명이 C07 Intro와 중복 | 독립 정책상 의도. 문장 표현을 조금 달리함(C06 "sign a paper", C07 "made Korea sign a treaty by force") |
| "황제가 동의하지 않았다" 단정 | 친서의 주장 형태 유지 |
| e4 `clue_never_used` 경고 | 경고만. 기록 |

---
## Case 07 — Two Reports from Harbin (1909)

### 1. 제목·역사 배경
- 제목 유지: **Two Reports from Harbin**.
- 배경(이 Case 안에서 모두 설명): 1905 일본이 대한제국에 조약을 강요(외교권 상실), 그 일을 이끈 일본 지도자가 이토 히로부미 → 1909년 10월 26일 오전 9시 30분경 하얼빈역(중국 땅, 러시아가 운영한 철도역)에서 안중근이 이토를 처단하고 러시아어로 "코레아 우라(Корея! Ура!)"를 외침 → 옥중에서 1910년 3월 『동양평화론』 집필 시작, 미완.

### 2. 독립 사건 목표 (한 문장)
하얼빈 한인들이 읽는 두 신문 중 어느 기사가 사실인지, 안중근이 실제로 무엇을 외쳤는지 밝혀 틀린 기사를 쓴 기자가 바른 기사를 싣게 한다. (`goal` 유지: "Find out which report is true, and what An Jung-geun really called out.")

### 3. 인물 동기
| 인물 | 동기 (이 Case 안에서만) |
|---|---|
| 강 부인(한인 여관 주인, 창작) | 여관 손님들이 "돈 때문에 그랬다"는 거짓 기사를 믿을까 걱정. 탐정을 손님으로 불러 쪽지로 사건을 맡김 |
| 박 씨(짐꾼, 창작) | 그날 아침 플랫폼에서 직접 들음. 역에서 일해 러시아 말을 조금 안다 |
| 소린(Evening Sheet 기자, 창작) | 정오 기차로 늦게 와 찻집에서 들은 이야기를 확인 없이 씀. 증거를 보면 인정 |
| 안중근 | 대한제국의 외교권을 빼앗은 이토를 처단하고 나라를 위해 외침(장면 묘사 없음) |

### 4. Intro (R, 6줄 — 현행 4줄 → 6줄)
문제(현행): 이토가 누구인지(C07-2), 사건이 아침이었다는 정보(C07-1), 하얼빈 위치(C07-7) 없음. v1 문제: 시대 이동 첫 줄, "He had forced the 1905 treaty" 한 줄로 1905 조약을 C06이 설명했다고 가정(철회 — 여기서 직접 설명).
```
Autumn, 1909. You stay at Mrs. Kang's Korean inn in Harbin, a city in China.
Itō Hirobumi was a top Japanese leader. In 1905, he made Korea sign a treaty by force.
With that treaty, Korea lost the right to deal with other countries.
On the morning of 26 October, at Harbin Station, a Korean named An Jung-geun killed Itō.
Everyone in Harbin is talking about it.
Two newspapers on Mrs. Kang's table tell his story in two ways.
```
(무기·장면 묘사 없음. "killed" 1회.)

### 5. Mission 1 — Two Papers on the Table (v1 유지 + 강 부인 쪽지 교체)
- **목적**: 두 기사가 어긋나는 줄을 찾는다. **유형** `record_mismatch` · `records` · `matchPairs`, answer `called:called`.
- **변경점(v1 유지)**: Paper B의 HE CALLED 값 "KOREA, HURRAH!" → **"KOREYA! URA!"**(들린 그대로, M3에서 해독). Paper B 이름 "THE MORNING NEWS" → **"THE HARBIN DAILY"**(아침 신문이 그날 아침 사건을 보도하는 모순 제거). 글씨는 앱이 빈 종이에 씀 → 그림 변경 없음.
- **변경점(v2)**: 물방울·"King's letters" 제거. 쪽지의 "Only one writer was on the platform."(M2 정답 예고이자 Final `where` 질문에 e1이 답처럼 보이게 하는 줄) 삭제 → 대신 **이토와 1905 조약 줄**을 넣어 Final `why`가 이 Case 증거(e1)로 풀리게 한다(v1은 C06 e4를 썼음).
- **story(R)**: `Two newspaper reports lie on Mrs. Kang's table.` / `Folded inside one is a small note from her.`
- **letterIntro(R)**: "Mrs. Kang's note says:"
- **letter(R, 5줄 — 현행 줄 수 같음)**:
```
Detective,
Itō forced the 1905 treaty on Korea. But Paper A says An Jung-geun did it for money.
Two papers came today. They should agree.
Read both, line by line. One line is not the same.
— Kang
```
- **talk.before(R)**: MRS. KANG "Every Korean in Harbin reads these papers." / "One of them is not true. I am sure of it." / YOU "Then we read them side by side." (현행 4줄째 "The same drop as Bongsu's note, and Lady Han's before him." **삭제** → 3줄. levels 줄 수 같이 줄임)
- **화면 단서(R)**: Paper A "THE EVENING SHEET" DATE 26 OCTOBER / PLACE HARBIN STATION / NAME AN JUNG-GEUN / HE CALLED NOTHING, note "A traveller told us he wanted money." · Paper B "THE HARBIN DAILY" 같은 3줄 / HE CALLED KOREYA! URA!, note "Written by a man on the platform."
- **정답 / 대입**: 4줄 중 HE CALLED만 다름 → 단일.
- **8세 풀이 경로**: 두 종이의 같은 줄 이름(DATE…)을 차례로 탭 → 값이 같은지 본다 → 마지막 줄만 다르다.
- **힌트**(현행): 1 "Read the four lines of each paper, one by one." 2 "The date, the place and the name agree. Look at the last line."
- **오답**: 현행 유지(다른 줄을 고르면 "These two lines say the same thing.").
- **transition(R)**: `One paper says he called out nothing.` / `The other says he called out, "Koreya! Ura!"` / `Mrs. Kang nods. "Ask Mr. Pak. He carries bags at the station."`
- **상태 변화**: 쟁점 = "무엇을 외쳤나". 다음 이유: 둘 중 누가 현장에 있었나.
- c1 value "WHAT HE CALLED OUT"(유지), note "Paper A says he called out nothing. Paper B says he called out, \"Koreya! Ura!\""
- **e1**(id 유지) name "The Water-Drop Note (1909)" → **"Mrs. Kang's Note"**, description: "Mrs. Kang's note. Itō forced the 1905 treaty on Korea. Paper A says An Jung-geun did it for money."
- recall·clueInputs(`s5_ep06_e1` recall, `s5_ep05_e1` textMention) **삭제** → M1은 clueInputs 없음(첫 미션, 허용).

### 6. Mission 2 — The Noon Train (v1 유지)
- **목적**: Paper A 기자가 외침 때 플랫폼에 없었음을 보드로 확인한다.
- **유형** `timeline_board` · `timelines` · `sequence`.
- **카드(화면 순서 = options 순서)**

| id | title | text | 종류 |
|---|---|---|---|
| write | THE REPORT IS WRITTEN | The writer writes his report at a tea room table. | 놓기 |
| goods | A GOODS TRAIN | A goods train comes in. | 버림 |
| shout (**새**) | HE CALLS OUT | An Jung-geun calls out on the platform. | 고정 `9:30` |
| tea | A STORY OVER TEA | A traveller tells the writer a story over tea. | 놓기 |
| print | THE EVENING SHEET IS PRINTED | The Evening Sheet is printed. | 고정 `5:00 PM` |
| pak_start (**새**) | MR. PAK STARTS WORK | Mr. Pak carries bags on the platform. | 놓기 |
| noon | THE NOON TRAIN | The Evening Sheet's writer comes on the noon train. | 고정 `12:00` |

(삭제: `open`(7:00), `platform`.)
- **relations**: pak_start<shout "I started work early, before he called out." / noon<tea "After the noon train, a traveller told the writer a story over tea." / tea<write "The writer wrote his report after that story."
- **letter(R, 관계 순서와 다르게)**:
```
He called out at half past nine in the morning. I heard it.
After the noon train, a traveller told the writer a story over tea.
The Evening Sheet's writer came on the noon train.
I started work early, before he called out.
The writer wrote his report after that story.
The Evening Sheet was printed at 5:00 PM.
A goods train came too. Leave it out.
```
- **question(R)**: "Put Mr. Pak's day in order. Was the writer there when he called out?"
- **정답**: `pak_start,shout,noon,tea,write,print`.
- **8세 풀이 경로**: 시각 카드 3장 고정 → "before he called out" → Pak 카드는 9:30 앞(빈칸 하나) → "After the noon train … tea" → tea는 12:00 뒤 → "after that story" → write는 tea 뒤 → goods는 버림 → 보드에서 9:30이 12:00보다 앞 = 기자는 못 봤다.
- **대입**: 9:30 앞 칸 1개 = pak_start만(tea·write는 noon 뒤). 12:00~5:00 PM 사이 2칸 = tea<write → 단일. `TimelineRules.validate`로 생성 시 검증.
- **힌트**: 1 "Find the words before and after. The cards with times stay put." 2 "He called out at 9:30. The writer came at 12:00. Which came first?"
- **orderFeedback**: "Look at the times. When did he call out? When did the writer come?"
- **successMessage**: "He called out at 9:30. The writer came at noon. He did not see it!"
- **상태 변화**: Paper A = 찻집 소문. c2·e2(id 유지) note/description: "Paper A's writer came at noon, after An Jung-geun called out at 9:30. He wrote a story told over tea."
- **다음 이유**: 그럼 무엇을 외쳤나 — 들은 사람에게.
- 주의: relation `line`은 각 레벨 letter에 글자 그대로 있어야 함(`timeline_line_unread`). levels.json에 relation 줄 키가 있으므로(integration.md:50) 레벨별 문장을 같이 바꾼다.

### 7. Mission 3 — What Mr. Pak Heard (v1 유지: 러시아어 해독)
- **목적**: "KOREYA! URA!"의 뜻을 목격자의 말과 낱말 카드로 풀어, 그가 무엇을 위해 외쳤는지 확정.
- **유형** `word_entry` · `wordInput`, answer `KOREA`, acceptedAnswers `["COREA"]`.
- **story(R)**: `Back at the inn, Mr. Pak drinks hot tea.` / `Many people at Harbin Station speak Russian. Mr. Pak knows some Russian words.`
- **letterIntro**: "Mr. Pak says, and shows you a card from the station:"
- **letter(R)**: `I was on the platform. I heard him.\nMany people there spoke Russian. He called out, "Koreya! Ura!"\nHe did not ask anyone for money.\nMY WORD CARD: Rossiya = Russia. Ura = Hurrah. Dengi = Money. Koreya = Korea.`
- **question(R)**: "What country did he call out for? Type it in English." prompt "He called out for ____."
- **8세 풀이 경로**: 외친 말 "Koreya! Ura!" → 카드에서 Koreya = Korea, Ura = Hurrah → 나라는 Koreya → KOREA.
- **대입**: RUSSIA(카드엔 있으나 외치지 않음) / MONEY(Dengi, 외치지 않음) / HURRAH(나라 아님) / KOREYA(러시아어) / HARBIN(장소) / KOREA ✓ → 단일.
- **힌트**: 1 "Find the two words he called out. Find them on the word card." 2 "Koreya is on the card. What is it in English?"
- **오답**: RUSSIA "Rossiya is on the card, but he did not call it out." / MONEY "Dengi means money. He did not say it." / HURRAH "Ura means hurrah. That is not a country." / KOREYA "That is the Russian word. Type it in English." / HARBIN "Harbin is the place, not his country."
- **successMessage**: "\"Koreya! Ura!\" means \"Korea, hurrah!\" He called out for Korea!"
- **transition(R)**: `Paper A was wrong about his words, and about money.` / `Mrs. Kang takes Paper B to the Evening Sheet's office.` / `Its writer, Mr. Sorin, comes back with her.`
- c3·e3(id 유지): value "KOREA, HURRAH!", e3 description "Mr. Pak was on the platform. He heard \"Koreya! Ura!\": Korea, hurrah! Not a word about money."
- discovery(현행 "NOT FOR MONEY")은 이 Case 내용 → 유지, detail만 "Paper A's story came from tea-room talk. The man on the platform heard \"Koreya! Ura!\"".
- **다음 이유**: 기자가 인정해야 바른 기사가 실린다.

### 8. Final — The True Report (3카드 × 3, 모두 이 Case 증거)
- **유형** `evidence_talk` · `talks` · `examine`, answer `for_korea`. present id `where/what/why` 유지(묻는 대상 같음).
- **변경점**: 노트 요약 letter 삭제 → 소린의 주장으로 교체(C07-3). 카드 2→3. **(v2)** `why`의 정답을 `s5_ep06_e4`(C06 황제의 편지) → **`s5_ep07_e1`(강 부인의 쪽지: 이토와 1905 조약)** 로 바꾸고, 헤이그 특사 대사를 삭제. Final `clueInputs`의 `s5_ep06_e4` answerDerivation → `s5_ep07_e1` answerDerivation.
- **story(R)**: `Mr. Sorin comes to the inn with his paper.` / `"My paper is right," he says. "Prove it is not."`
- **letterIntro / letter(R)**: "The Evening Sheet says:" / `Our writer knows what happened.\nHe called out nothing.\nHe wanted money.`
- **question(R)**: "Answer Mr. Sorin's three questions with your evidence."

| id | prompt (R) | 카드 화면 순서 | accepted | 정답 대사(R) | miss | tell(안내) |
|---|---|---|---|---|---|---|
| where | Mr. Sorin says: "My writer saw it all." (v1의 "Who says my writer got it wrong?"는 e3[박 씨]도 답처럼 보여 교체) | e3, e1, e2 | s5_ep07_e2 | YOU "He called out at 9:30. Your writer came at noon. He did not see it." / SORIN "True. He wrote what the traveller said." | "That does not show where my story came from." | "Which card has the times of that day?" |
| what (req where) | "Then what did he call out?" | e1, e3, e2 | s5_ep07_e3 | YOU "\"Koreya! Ura!\" It means \"Korea, hurrah!\" Mr. Pak heard it." / SORIN "Not a word about money, then." | "That does not say what he called out." | "Which card has the words Mr. Pak heard?" |
| why (req what) | "Why would a man do this for Korea? What had Itō done to Korea?" | e1, e2, e3 | s5_ep07_e1 | YOU "Itō forced the 1905 treaty on Korea. Korea lost the right to deal with other countries." / SORIN "So he did it for his country, not for money. I will print that." | "That does not tell me what Itō did." | "Which card talks about Itō and 1905?" |

finishWhen `[where, what, why]`, finishLabel "CLOSE THE CASE".
- **Final 증거(이 Case 것만)**: s5_ep07_e1(이토·1905), e2(시각), e3(들은 말). 3개 모두 필수. 다른 Case 카드 없음.
- **해결 방식**: 소린의 주장 3개(우리 기자가 안다 / 아무것도 안 외쳤다 / 돈 때문)를 시각·들은 말·이토의 일로 반박.
- **대입 검사**: where = "기자가 다 봤다"를 반박하는 시각(9:30 < 정오)이 있는 e2만(e1에는 시각 없음 — "Only one writer was on the platform" 줄을 지웠기 때문, e3은 "on the platform"이지만 기자의 도착 시각 없음). what = 외친 말 e3만(e1은 "money", e2는 시각). why = 이토·1905가 있는 e1만(e2·e3에 이토 없음; prompt가 "What had Itō done"이라 e3의 "not money"로 답이 되지 않는다) → 각 단계 단일.
- **힌트(b1)**: 1 "Each question needs one card: the times, the words, or Itō." 2 "Where: Mr. Pak's Day. What: Mr. Pak's Words. Why: Mrs. Kang's Note."
- **successMessage**: "Mr. Sorin puts down his pen. \"I was wrong.\""
- **transition(R)**: `Mr. Sorin writes a new report at Mrs. Kang's table.` / `Mrs. Kang pins Paper B on the inn wall, for every Korean guest to read.` / `Outside, the trains go on, east and west.` (현행 "This one goes in my letter box" **삭제**, v1의 "her family's old letter box" **삭제**)
- **e4**(id 유지) name "The True Report, Kept by Mrs. Kang" → **"The True Report"**, description: "The Harbin Daily: he called out, \"Koreya! Ura!\": Korea, hurrah! Mr. Sorin will print it too." (현행 "The Morning News … keeps it with her note" 교체)

### 10. Ending (새 핵심 줄)
SORIN "Tomorrow I will print what Mr. Pak heard." / YOU "He called out, \"Korea, hurrah!\" Not for money." (e4) / narrator "In prison, An Jung-geun began writing 'On Peace in East Asia'." / "He wrote about Korea's independence and peace between the countries of East Asia." / "He began it in March 1910, and could not finish it." / MRS. KANG "Now every guest in my inn will read the truth."(현행 "One day, all of Korea will call out too." — 1919 예고 성격이라 교체. 이 Case의 문제[손님들이 거짓 기사를 믿음] 해결로 끝냄)
- "independence"는 엔딩에서 처음 나오므로 glossary(독립) 유지 + J/M에서 "freedom" 병기 가능.
- `hook`: "Ten years later, people all over Korea will stand up."(C08 예고) → **"Two papers, one truth: \"Koreya! Ura!\""**
- caseSummary: "Mrs. Kang kept the true report." → "Mrs. Kang pinned the true report on her inn wall." / "Korea, hurrah!" 앞에 "\"Koreya! Ura!\" —"

### 11. 역사 학습 + 사실/창작
- 배움: 1905 조약 강요·외교권 상실(이 Case에서 설명), 이토 = 그 조약을 강요한 일본 지도자, 1909.10.26 오전 하얼빈역, "코레아 우라"(러시아어), 동양평화론 1910.3 시작·미완.
- IN THIS MYSTERY(R): "Mrs. Kang, Mr. Pak, Mr. Sorin and the two newspapers are made up. The day, the place, the time and the words \"Koreya! Ura!\" are real history."
- 8세 민감도: "killed" 1회, 무기·장면 묘사 없음. 평가 문장 없음.
- dossier: fiction[0]의 "the Morning News" → "the Harbin Daily", fiction[1] "Mrs. Kang's water-drop note of 1909" → "Mrs. Kang's note", 사실 추가 "오전 9시 30분경"·"러시아어 외침 코레아 우라"(integration.md:48), "이토 = 1905 조약 강요 주도"(근거: 을사조약 체결 시 이토 특파대사). puzzles[3].derivation의 "the Emperor's letter" → "Mrs. Kang's note".

### 12. 난이도별 핵심 줄 (실측)
| # | R | J | M |
|---|---|---|---|
| 1 이토 | Itō Hirobumi was a top Japanese leader. In 1905, he made Korea sign a treaty by force. (17) | Itō Hirobumi was a top Japanese leader who had forced Korea to sign a treaty in 1905. (17) | Itō Hirobumi, one of Japan's most powerful leaders, had forced a treaty on Korea in 1905. (16) |
| 2 조약 결과 | With that treaty, Korea lost the right to deal with other countries. (12) | Because of that treaty, Korea lost the right to deal with other countries. (13) | That treaty had taken away Korea's right to deal with other countries. (12) |
| 3 M1 쪽지 | Itō forced the 1905 treaty on Korea. But Paper A says An Jung-geun did it for money. (17) | Itō forced the 1905 treaty on Korea, but Paper A says An Jung-geun did it for money. (17) | Itō forced the 1905 treaty on Korea; yet Paper A claims An Jung-geun did it for money. (17) |
| 4 M3 | Many people there spoke Russian. He called out, "Koreya! Ura!" (10) | Because many people on the platform spoke Russian, he called out, "Koreya! Ura!" (13) | He called out in Russian, the language most people on that platform understood: "Koreya! Ura!" (15) |
| 5 Final why | Itō had forced the 1905 treaty on Korea. He called out for his country, not money. (16) | He called out for his country, not for money, because Itō had forced the 1905 treaty on Korea. (18) | Itō had forced the 1905 treaty on Korea; that is why he called out for his country, not for money. (20) |

### 13. 외부 의존 원장 (C07)
| # | 위치 | 현재 | 결정 | 교체 내용 |
|---|---|---|---|---|
| 1 | `missions[0].clueInputs[0]` | recall `s5_ep06_e1`(봉수 물방울 쪽지) | **제거** | 삭제 |
| 2 | `missions[0].clueInputs[1]` | textMention `s5_ep05_e1`("three keepers, one mark") | **제거** | 삭제 |
| 3 | `missions[0].play.recall` | "A Drop Like Bongsu's" / "…errand boy's note…" | **제거** | `recall` 키 삭제 |
| 4 | `missions[0].play.story[1]` | "Folded inside one is a small note with a water drop." | **Case 안에서 완결**(쪽지는 단서, 물방울은 기능 없음) | "Folded inside one is a small note from her." |
| 5 | `missions[0].play.letterIntro` | "Mrs. Kang's note, in the King's letters, says:" | **Case 안에서 완결** | "Mrs. Kang's note says:" |
| 6 | `missions[0].play.talk.before.lines[3]` | "The same drop as Bongsu's note, and Lady Han's before him." | **제거** | 줄 삭제(3줄) |
| 7 | `missions[0].play.evidence` | "The Water-Drop Note (1909)" / "…with a small water drop…" | **Case 안에서 완결** | "Mrs. Kang's Note" / 5절 e1 |
| 8 | `final.clueInputs[2]` | answerDerivation `s5_ep06_e4` | **Case 안에서 완결** | answerDerivation `s5_ep07_e1` ("Itō forced the 1905 treaty: Mrs. Kang's note") |
| 9 | `final.play.interview.presents[2]` (`why`) | accepted/offered `s5_ep06_e4`, 대사 "The Emperor's envoys went to The Hague…", tell "The Emperor's letter shows…" | **Case 안에서 완결** | 8절 표(accepted `s5_ep07_e1`, offered e1·e2·e3, 헤이그 대사 삭제) |
| 10 | `final.play.hints[1]` | "Use Mr. Pak's day, Mr. Pak's words, and the Emperor's letter." | **Case 안에서 완결** | b1 힌트 2 "Where: Mr. Pak's Day. What: Mr. Pak's Words. Why: Mrs. Kang's Note." |
| 11 | `final.play.letter` 3줄째 | "In 1905, Japan forced a treaty on Korea."(요약) | **교체**(요약 삭제, C07-3) | 소린의 주장 3줄 |
| 12 | `final.play.transition[1]` | "\"This one goes in my letter box,\" she says." | **Case 안에서 완결**(상자 = 시즌 상자 암시) | "Mrs. Kang pins Paper B on the inn wall, for every Korean guest to read." |
| 13 | `final.play.evidence` | "…Kept by Mrs. Kang" / "…keeps it with her note." | **Case 안에서 완결** | 8절 e4 |
| 14 | ending 마지막 줄 | "One day, all of Korea will call out too." | **교체**(다음 Case 예고) | "Now every guest in my inn will read the truth." |
| 15 | `hook` | "Ten years later…" | **교체** | 10절 hook |
| 16 | v1 Intro 첫 줄·"He had forced the 1905 treaty"(C06 전제) | 시대 이동 + C06 의존 | **제거 / Case 안에서 완결** | 4절 Intro 2~3줄 |
| 17 | v1 transition "Bongsu's note is in it too", "봉수–강 부인 관계" 미결 항목 | 시즌 상자 경로 | **제거** | 없음 |
| 18 | dossier cases[6] fiction[1]·puzzles[3].derivation | 물방울 쪽지·황제의 편지 | **Case 안에서 완결** | 11절 |
| — | evidenceLinks | `s5Ep07EvidenceLinks` 비어 있음 | 해당 없음 | — |

### 14. 독립성 검증 (C07)
| 검사 | 결과 | 근거 |
|---|---|---|
| (a) Intro 이해 | 가능 | 하얼빈 위치, 이토의 정체, 1905 조약과 그 결과, 사건 시각(아침)을 Intro에서 설명 |
| (b) 풀이 | 가능 | M1 두 신문, M2 박 씨의 하루, M3 낱말 카드, Final = e1·e2·e3 |
| (c) Ending 이해 | 가능 | 기자 정정·여관 벽·동양평화론을 Ending에서 직접 서술 |
| 남은 다른 Case 참조 | **없음** | 타 Case ref 0(이전 3건), recall 0, 물방울·상자·봉수·한 상궁·황제의 편지 0 |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 좋음 | 엔진·정답·그림 | B값 KOREYA! URA!, 신문 이름, 강 부인 쪽지 줄(이토·1905), 물방울·recall 제거 |
| M2 아침 정보 없음(C07-1) | timeline, 정오·5PM 고정 | 9:30 고정 카드, 7:00 카드 삭제, letter 섞기 |
| M3 베끼기(C07-4), who(C07-8) | word_entry KOREA | 러시아어 해독 카드, what |
| Final 2지×3 + 요약(C07-3), C06 e4 의존 | present id, e2·e3 | 3카드, 요약 삭제, why = e1(이 Case) |
| 이토·하얼빈 무설명(C07-2/7) | — | Intro |
| 상자·예고 줄 | — | 여관 벽에 붙임, 예고 삭제 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 두 기사 | — | 읽기 | 이토·1905·아침 사건 | 강 부인 쪽지 |
| M1 | 어디가 다른가 | 쪽지(이토, 돈 주장) | 줄 비교 | HE CALLED만 다름 | 누가 현장에? |
| M2 | A 기자 현장 여부 | 쟁점 | 보드 배치 | 9:30 < 12:00 → 못 봄 | 무엇을 외쳤나 |
| M3 | 외친 말 뜻 | Paper B 값 | 카드로 해독 | Korea, hurrah | 기자 설득 |
| Final | 기자 반박 | e1·e2·e3 | 3질문 증거 | 기자 인정 | 엔딩 |
| Ending | 결과 | e4 | 대화·서술 | 바른 기사·여관 벽 | (끝) |

### 17. 어린이 플레이 시뮬레이션 (설계 검토, 실제 테스트 아님)
| 항목 | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 보는 것 | 신문 2장 + 쪽지 5줄 | 고정 카드 3 + 놓을 3 + 버림 1 | 박 씨 말 + 낱말 카드 | 소린 주장 3줄 + 카드 3 |
| 누르는 것 | 줄 짝 탭 | 카드 끌기 | 단어 입력 | 카드 1장 × 3 |
| 근거가 화면에 | 두 값 | 관계 문장 | 카드 4줄 | 카드 설명 |
| 정답처럼 보이는 오답 | 없음 | 없음(9:30 앞 칸 하나) | RUSSIA(카드 첫 줄) → 피드백 | why에 e3("not money") → prompt가 "What had Itō done"이라 배제, tell 안내 |
| 다른 Case 지식 필요 | 없음(v1·현행 recall 제거) | 없음 | 없음 | 없음(v1·현행 C06 e4 제거) |
| 재시도·힌트 | 무제한 | 무제한, 중간 저장 | 무제한 | miss → tell → 빛남, b1 |
| 목표 기억 | 쪽지 "Paper A says … money" | question "Was the writer there…" | prompt | 소린 주장 letter |

### 18. ID·저장 영향
- id 유지: m1~m3, final, c1~c3, e1~e4. timeline 카드 `open`·`platform` 삭제, `shout`·`pak_start` 신규 → 저장된 M2 중간 상태는 decode가 버림(안전). present `why`는 id 유지하되 accepted가 바뀜: 저장된 대화 진행 상태에 `why`가 이미 풀렸다면 그대로 풀린 것으로 남음(무해). 이미 푼 Case 영향 없음.
- e1·e4 이름·설명 변경. 이 Case 증거를 받는 다른 Case: 현재 C08 M3 recall `s5_ep07_e1` — C08 v2에서 제거되므로 정합.

### 19. 엔진 변경
- 공통 2b1·2b2·2b3. C07 고유 없음. 독립화로 인한 변경 없음.

### 20. 이미지
- 없음. `c07_paper_a/b`(빈 종이, 글은 앱), `kang_inn`, `harbin_tea_room` 재사용. 물방울·상자가 그려진 그림 없음.

### 21. 작업량
- **M**. `s5_ep07/case.plan.json`, `levels.json`(레벨 차 보강, relation 줄, talk.before 3줄), `history_dossier.json`, 재생성, `test/sandbox/s5_seoul_rookie_test.dart` C07 기대값(goods train 문구는 유지되므로 :62 통과).

### 22. 위험과 대응
| 위험 | 대응 |
|---|---|
| 1905 설명이 C06과 중복 | 독립 정책상 의도 |
| 강 부인 쪽지가 Final 답(e1)을 M1에서 미리 말함 | 정답 "단어"가 아니라 배경 사실이며, M1의 질문(어긋난 줄)과 무관. Final에서 "어느 카드가 이토를 말하나"를 찾는 것이 과제 |
| 러시아어 낱말이 영어 학습을 흐림 | 카드 4줄만, 결과는 영어. glossary: Koreya "코레야(러시아어)=한국", Ura "우라(러시아어)=만세" |
| relation 문장 레벨 불일치 | relation `line`을 레벨별 letter 문장과 같게 |
| 폭력 서술 | killed 1회, 묘사 없음 |

---
## Case 08 — The Fire on the Hill (1919)

### 1. 제목·역사 배경
- 제목 유지: **The Fire on the Hill**.
- 배경(이 Case 안에서 모두 설명): 1910 일본의 국권 강탈(병합) → 1919.3.1 3·1운동 → 이화학당 휴교로 유관순(16세) 귀향 → 3월 31일 밤 매봉산 등 봉화 → 4월 1일 아우내 장터 만세 시위(유관순은 조인원·유중권·유중무 등 마을 어른들과 함께 **이끈 사람 중 한 명**) → 일본 헌병 발포, 유관순의 부모 사망 → 유관순 체포, 1920년 서대문형무소에서 사망.

### 2. 독립 사건 목표 (한 문장)
마을에 퍼진 가짜 날짜 속에서 만세 행진의 **진짜 날짜와 신호**를 찾고, 그 계획을 낯선 사람이 읽지 못하게 지킨다. (`goal` 확장: "Find the true day of the march and the sign, and keep the plan from the stranger.")

### 3. 인물 동기
| 인물 | 동기 (이 Case 안에서만) |
|---|---|
| 유관순 | 서울에서 본 만세를 고향에서도. 경찰이 길을 지켜 편지를 못 보냄 → 불 신호. 글로 쓴 계획을 낯선 사람이 노린다 |
| 경순(16세, 창작, M1 증인 중 한 명) | 진짜 날을 전한 전령. 표 씨가 돈을 받은 것을 알고 탐정에게 **이름 없이** 쪽지로 알림 — 경찰이 쪽지를 주우면 이름이 친구를 감옥에 보낼 수 있어서. 이름 대신 늘 물방울을 그린다(자기 공책 이름 옆에도) |
| 동일(창작) | 진짜 날을 전한 아이 |
| 표 씨(소금장수, 창작) | 낯선 사람에게 동전을 받고 틀린 날(4월 2일)·틀린 곳(역)을 퍼뜨림 |
| 낯선 사람(창작, 등장 안 함) | 계획을 알아내 막으려 함 → 계획 문서를 노림(M3·Final의 이유) |

### 4. Intro (R, 6줄 — 현행 5줄 → 6줄)
문제(현행): 1910 병합·independence의 대상·3·1운동 이름 없음(C08-3), police가 누구인지 모름. v1 문제: 시대 이동 첫 줄(철회).
```
Spring, 1919. You are a guest of Yu Gwan-sun's family, near Cheonan.
In 1910, Japan took over Korea. Koreans could not rule their own country.
On 1 March 1919, people all over Korea called for independence. This is the March First Movement.
Now Gwan-sun, a schoolgirl of sixteen, and the village elders plan a march at Aunae Market.
They will call for independence: a free Korea, ruled by Koreans.
But Japan's police watch the roads, and a wrong day is going round.
```
("The schools were closed, so Gwan-sun came home."는 M2 story에 이미 있음.)

### 5. Mission 1 — Three Messengers (유지 + 쪽지의 수수께끼를 세움)
- **유형** `witness_compare` · `dialogues` · `multipleChoice`, answer `april_first`. 증인(경순·동일·표 씨)·질문·deduction 그대로(witness_compare는 레벨 변형 없음).
- **story(R)**: `Aunae Market is busy with baskets, rice and salt.` / `Under your teacup at the noodle stall, a folded note waits.` / `It is written in Hangeul, Korea's own letters. There is no name, only a small water drop.`
  (v1의 "That is the name of the King's letters now"는 C01 의존이라 **삭제**. "There is no name"이 M3의 질문 "누가 썼나"를 여기서 세운다.)
- **letterIntro / letter**(현행): "The water-drop note says:" / `Three people told Gwan-sun's day to the villages.\nTwo of them say the same day.\nOne man says another day. Someone paid him to ask.\nAsk what each one heard.\n— a small water drop`
- **정답·대입**(현행): 경순·동일 = 4월 1일 일치, 표 씨 = 4월 2일 + 동전 → april_first 단일. march_tenth는 아무도 말하지 않음.
- **8세 풀이 경로**: 세 사람에게 같은 질문(day) → 두 사람이 같은 날 → 쪽지 "Two of them say the same day" → 4월 1일.
- **힌트·오답**(현행): 1 "Ask every person the same question about the day." 2 "Two people say the same thing. Compare their answers." / april_second "Only Mr. Pyo says the second…" / march_tenth "Nobody says March…"
- **상태 변화**: 4월 1일 확정 + "낯선 사람이 표 씨에게 돈을 줬다" + 쪽지 쓴 사람은 아직 모름.
- clue c1 symbol `clock` 유지(→ Final 3번째 다이얼).
- **e1**(id 유지) name "The Water-Drop Note (1919)" → **"The Water-Drop Note"**, description: "A note in Hangeul with no name, only a small water drop. Two messengers tell the truth."
- **다음 이유**: 먼 마을엔 어떻게 알리나.

### 6. Mission 2 — Gwan-sun's Plan (현행 + v1 기호)
- **유형** `order_sequence`, answer `fire,walk,full,march`, 미끼 bell. 보기 화면 순서 march, bell, fire, full, walk(정답 순서와 다름, 유지). letter가 시간 표현으로 섞여 있어 실제 재배열(현행 좋음).
- **변경점**: clue c2에 **symbol `map`** 추가(Final 1·2번 다이얼 그림과 일치). talk.before 1줄째 "People in Seoul called for independence." → "On 1 March, people in Seoul called for independence. Now it is our turn."
- discovery detail: "The villages will know by the fire. But the stranger wants this plan."
- 풀이·대입·힌트: 현행(밤 → 아침 걷기 → 장터 가득 → 행진, 종은 "No bell"로 배제 → 단일).
- **다음 이유**: 낯선 사람이 **글로 쓴 계획**을 노린다 → 믿을 수 있는 사람에게 맡겨야.

### 7. Mission 3 — Who Wrote the Note? (v1의 "계획을 맡길 사람", 완전 내부화)
- **목적**: 계획 종이를 맡길 믿을 사람 = **표 씨의 거짓을 미리 알려 준 쪽지의 주인**을 찾는다. (v1은 "비밀을 지키는 집안"·강 부인과 같은 물방울을 근거로 했으나, v2는 **이 Case의 M1 쪽지**만 근거로 한다.)
- **유형** `text_choice` · `multipleChoice`, answer `gyeongsun`(현행 word_entry 9글자 철자 제거, C08-2). 미션 id·c3·e3 유지.
- **story(R)**: `"The stranger wants my written plan," Gwan-sun says.` / `"Give it to the one who wrote the water-drop note. That friend warned us about Mr. Pyo."` / `Three school friends' notebooks lie on the low table.`
- **letterIntro**: "What you see on the table:"
- **letter(R, 그림 `village_home.webp`의 꽃 표지·파란 리본·갈색 공책과 일치)**:
```
Your note: only in Hangeul. No name, only a small water drop.
Sunja's notebook: a pressed flower on the cover. She writes only in Hangeul. A little flower sits by her name.
Okhui's notebook: a blue ribbon. She writes in Chinese characters. Little stars sit by her name.
Gyeongsun's notebook: plain and brown. She writes only in Hangeul. A small water drop sits by her name.
```
- **question(R)**: "Who wrote the water-drop note? Give her the plan."
- **보기(화면 순서)**: `sunja` "Sunja" / `gwansun` "Gwan-sun" / `gyeongsun` "Gyeongsun" / `okhui` "Okhui".
- **recall(이 Case 안)**: clueInputs `s5_ep08_e1` use `recall`(M1에서 이미 얻음 → `play_check` 통과). title "The note from the market", prompt "Your note has a small water drop. Find it in your Notebook.", miss "Find the note from under your teacup."
- **8세 풀이 경로**: ① 수첩에서 M1 쪽지를 다시 본다(특징 2개: Hangeul만 / 이름 대신 물방울) ② Okhui: 한자·별 → 둘 다 다름 ③ Sunja: Hangeul은 같지만 꽃 → 표시가 다름(의도된 함정) ④ Gyeongsun: 둘 다 같음 ⑤ Gwan-sun: 쪽지 주인을 찾아 달라고 한 사람, 공책 없음.
- **대입**: sunja(표시 불일치) / okhui(글자·표시 불일치) / gwansun(부탁한 사람) / gyeongsun ✓ → 단일.
- **힌트**: 1 "Your note has two things: the kind of letters, and a mark." 2 "Which notebook has the same letters AND the same mark?"
- **오답**: sunja "Sunja writes in Hangeul too. But her mark is a flower." / okhui "Okhui writes in Chinese characters, with stars." / gwansun "Gwan-sun asked you to find the writer. It is not her."
- **successMessage**: "Gyeongsun wrote the water-drop note!"
- **talk.after(R)** — 누가·왜 썼는지 이 Case 안에서 밝힘:
  GYEONGSUN "Yes. I wrote it. I saw a stranger give Mr. Pyo a coin." / GYEONGSUN "I never sign my name. A name on a note can send a friend to prison." / YOU "So you drew a water drop. But the same drop is by your name." / GYEONGSUN "Only on my own notebook. I did not think a detective would look!"
- **transition(R)**: `Gyeongsun smiles. "Water is quiet, but it gets everywhere. So does our news."` / `Gwan-sun gives her the plan.` / `"Tonight I will lock it in my old box," Gyeongsun says.`
  (현행 "My family has used that water drop for a long time." / "Tonight, on the hill, I will show you why." **삭제**)
- **상태 변화**: 계획이 경순에게. 쪽지의 수수께끼 해결.
- c3 title "The Keeper" → **"The Note Writer"**, value "GYEONGSUN" 유지, note "Gyeongsun wrote the water-drop note. She will keep Gwan-sun's plan safe." e3(Gyeongsun's Notebook) 유지.
- discovery: "ONE MARK, ONE FAMILY" → type `storyDiscovery` 유지, title **"THE NOTE WRITER"**, detail "Gyeongsun warned you about Mr. Pyo. Now she will keep the plan."
- talk.goal "Find out who leaves the water-drop notes." → "Find out who wrote the water-drop note."
- **다음 이유**: 계획을 상자에 넣고 낯선 사람이 모르는 날짜로 잠가야 한다.

### 8. Final — The Fire on the Hill (다이얼 311, 탐정이 잠근다)
- **유형** `combo_dial_lock` · `finalCode` · answer `311`, codeLength 3.
- **변경점(v1 유지)**: 탐정이 두 날짜로 **잠근다**(C08-7). dialSymbols `["clock","watch","map"]` → **`["map","map","clock"]`**(1·2번 = c2 계획, 3번 = c1 날짜; 노트북 "Match each picture to its number."와 일치, C08-1). **(v2)** 상자는 **경순의 낡은 나무 상자**일 뿐(그림 `maebong_hill.webp`의 다이얼 상자 그대로). "keepers' letter box", 분이 편지, 증거 링크 `s5_ep01_e3/e4` **삭제**.
- **story(R)**: `At dusk, Gyeongsun leads you up Maebong hill.` / `She opens her old wooden box and lays Gwan-sun's plan inside.` / `"Set the lock to our two days. The stranger only knows Mr. Pyo's day."`
- **letter(R)**:
```
First two dials: the night of the sign. It is a night in March.
Last dial: the day of the march, in April.
The sign burns the night before the march.
Remember: March has thirty-one days.
```
- **question(R)**: "Set the dials: first the night of the sign, then the day of the march."
- **Final 증거(이 Case 것만)**: c1/e1 측 "4월 1일"(M1), c2/e2 "전날 밤의 불"(M2). 둘 다 필수. 다른 Case 증거 없음.
- **8세 풀이 경로**: 지도 그림 다이얼 2개 = 계획(불은 전날 밤) → 시계 그림 다이얼 = 날짜(4월 1일) → 4월 1일 전날 밤 = 3월의 마지막 밤 → 3월은 31일 → 3·1 → 마지막 1 → 311.
- **대입 검사**: 311 ✓ / 301(3월은 31일까지) / 131(순서) / 302·312(4월 2일) / 012(표 씨의 날) → 각 피드백, 단일.
- **힌트**: 1 "The map dials are for the plan. The clock dial is for the day." 2 "The night before the first of April is the last night of March."
- **오답**: 131 "First the night of the sign, then the day of the march." / 301 "March has thirty-one days. The night before April 1 is the last night of March." / 302 "The march is on the first of April, not the second." / 312 "The march is on the first of April, not the second." / 012 "That is Mr. Pyo's day. Two messengers said the first of April."
- **successMessage**: "Click! The box is locked. Only friends know the days." (현행 "The old box opens!" 교체)
- **transition**(현행 유지): `Below, the villages are dark and quiet.` / `Then a small flame rises on Maebong hill.` / `Far away, on other hills, you see more lights.`
- **해결 방식**: 낯선 사람은 표 씨의 날(4월 2일)만 알아 상자를 열 수 없다 → "계획을 낯선 사람에게서 지킨다" 해결.
- **e4**(id 유지) name "The Keepers' Letter Box" → **"The Locked Plan"**, description: "Gyeongsun's old wooden box, locked with the true days. Gwan-sun's plan is inside. Mr. Pyo's day cannot open it." `clueInputs[2]`(`s5_ep01_e3` textMention) **삭제**.

### 10. Ending (새 — 가족 공개 전부 삭제)
```
narrator  That night, Gwan-sun lights the fire on Maebong hill.
narrator  On 1 April 1919, thousands of people gather at Aunae Market.
narrator  Gwan-sun helps lead them, with the village elders. They call for independence.   [evidence s5_ep08_e2]
narrator  The stranger waits at the station, on Mr. Pyo's wrong day. He never reads the plan.   [evidence s5_ep08_e4]
GYEONGSUN No name, only a water drop. And the plan stayed safe.
```
- 현행 7줄 → 5줄(levels.json 엔딩 줄 수 R/J/M 같이 5). 현행의 "Under the plan lie old notes…", "The oldest is at the bottom…", "It says 엄마, 고마워요… Bun-i's letter from 1446!"(evidence `s5_ep01_e3`), "Bun-i was our first keeper. We are all her family." **삭제**. v1의 가족의 말 "When our letters need help…" **삭제**.
- 이 삭제로 C08의 **Hangul 대사 규칙 예외가 사라진다**(엔딩에 한글 없음).
- 해결되는 Intro 문제: 진짜 날·신호가 지켜졌고, 낯선 사람은 계획을 읽지 못함(C08-6).
- `hook`: "The keepers are one family. Where will the box go next?" → **"The fire spoke for the villages. The stranger never read the plan."**
- objectives[3] "Open the old letter box." → **"Lock the plan away."** · keyWords `keeper` → **`stranger`**(glossary "낯선 사람") · `notes[0]` "Act 2's reveal … the box goes to Shanghai with Haesu" → "The note writer is found inside the case (M1 note, M3 notebooks); the box is Gyeongsun's own."
- caseSummary(R): "Two messengers said the true day: the first of April. Gwan-sun's sign was a fire on Maebong hill the night before. Gyeongsun, who wrote the water-drop note, kept the plan in a box locked with the true days. On 1 April 1919, Gwan-sun helped lead thousands of people at Aunae Market. They called for Korea's independence."

### 11. 역사 학습 + 사실/창작
- 배움: 1910 국권 강탈, independence의 뜻, 3·1운동 이름, 봉화(전날 밤), 4월 1일 아우내 만세, 유관순은 "helped lead".
- history reveal 보강(R): "Japan's military police fired on the crowd. Gwan-sun's father and mother died that day." / "Gwan-sun was arrested. She died in Seodaemun Prison in 1920." (묘사 없음)
- IN THIS MYSTERY(R): "Gyeongsun, Dong-il, Mr. Pyo, the stranger, the notebooks, the water-drop note and the box are made up. The fire on the hill the night before, and the march on 1 April 1919, are real history. Yu Gwan-sun helped lead it with the village elders."
- dossier cases[7]: fiction[2] "the keepers' letter box with its dial lock" → "Gyeongsun's box with its dial lock", fiction[4](Bun-i·Mrs. Kang 쪽지) **삭제**, reveal.inThisMystery[2] "…part of this season's story" → "The water-drop note and Gyeongsun's box are made up for this case."(R/J/M), puzzles[2] derivation/whyOnly를 text_choice·두 특징 기준으로, answer `gyeongsun`.

### 12. 난이도별 핵심 줄 (실측)
| # | R | J | M |
|---|---|---|---|
| 1 1910 | In 1910, Japan took over Korea. Koreans could not rule their own country. (13) | In 1910, Japan took over Korea, so Koreans could no longer rule their own country. (15) | In 1910, Japan took over Korea, and Koreans lost the right to rule their own land. (16) |
| 2 3·1 | On 1 March 1919, people all over Korea called for independence. This is the March First Movement. (17) | On 1 March 1919, people all over Korea called for independence, and this became the March First Movement. (18) | On 1 March 1919, people across Korea called for independence, in what we now call the March First Movement. (19) |
| 3 M3 이유 | Give it to the one who wrote the water-drop note. That friend warned us about Mr. Pyo. (18) | Give it to whoever wrote the water-drop note, because that friend warned us about Mr. Pyo. (17) | Hand it to whoever wrote the water-drop note; that friend warned us about Mr. Pyo. (16) |
| 4 왜 이름 대신 물방울 | I never sign my name. A name on a note can send a friend to prison. (15) | I never sign my name, because a name on a note can send a friend to prison. (16) | I never sign my name; a single name on a note could send a friend to prison. (16) |
| 5 Final | Set the lock to our two days. The stranger only knows Mr. Pyo's day. (14) | Set the lock to our two days, so the stranger, who only knows Mr. Pyo's day, cannot open it. (19) | Set the lock to our two days; the stranger knows only Mr. Pyo's day, so the box will stay shut to him. (22) |

### 13. 외부 의존 원장 (C08)
| # | 위치 | 현재 | 결정 | 교체 내용 |
|---|---|---|---|---|
| 1 | `missions[2].clueInputs[0]` | recall `s5_ep07_e1`(강 부인 쪽지 1909) | **Case 안에서 완결** | recall `s5_ep08_e1`(M1 쪽지) |
| 2 | `missions[2].play.recall` | "The same mark" / "…same small water drop?" / "Find the note from Harbin, written in 1909." | **Case 안에서 완결** | 7절 recall 문구 |
| 3 | `missions[2].puzzle.notes[0]` | "Mrs. Kang's note of 1909 (s5_ep07_e1, recalled) carries the same mark." | **Case 안에서 완결** | "The M1 note (s5_ep08_e1, recalled) is the one to match." |
| 4 | `missions[2].play.talk.after` | "Mrs. Kang in Harbin is my family too." / "Her note has the very same water drop." / "We all learned it from the same old box." | **Case 안에서 완결** | 7절 talk.after(표 씨를 본 일·이름을 쓰지 않는 이유) |
| 5 | `missions[2].play.transition[1..2]` | "My family has used that water drop for a long time." / "Tonight, on the hill, I will show you why." | **Case 안에서 완결** | 7절 transition |
| 6 | `missions[2].play.clue.title/note` | "The Keeper" / "Her family uses the same mark." | **Case 안에서 완결** | "The Note Writer" / 7절 |
| 7 | `missions[2].play.discovery` | "ONE MARK, ONE FAMILY" / "Harbin in 1909, Aunae in 1919…" | **Case 안에서 완결** | "THE NOTE WRITER" / 7절 |
| 8 | `missions[2].play.talk.goal`, `successMessage` | "…who leaves the water-drop notes" / "…wrote the water-drop notes!"(복수 = 여러 Case 쪽지) | **Case 안에서 완결** | 단수 "note" |
| 9 | `final.clueInputs[2]` | textMention `s5_ep01_e3`(분이 쪽지 1446) | **제거** | 삭제 |
| 10 | `final.play.ending[0..3]` + evidence `s5_ep01_e3` | 상자 속 옛 쪽지들, 분이 편지(엄마, 고마워요), "Bun-i was our first keeper. We are all her family." | **제거** | 10절 엔딩(5줄) |
| 11 | `final.play.evidence` | "The Keepers' Letter Box" / "…Bun-i's note of 1446 is at the bottom." | **Case 안에서 완결** | "The Locked Plan" / 8절 |
| 12 | `final.play.successMessage` | "The old box opens!" | **교체**(탐정이 잠금) | "Click! The box is locked. Only friends know the days." |
| 13 | `final.puzzle.notes[0]` | "The keepers' letter box, locked by Gyeongsun…" | **Case 안에서 완결** | "Gyeongsun's box, locked by the detective with the plan's two days…" |
| 14 | `hook`, `play.objectives[3]`, `play.keyWords[4]`, `play.caseSummary`, `notes[0]` | 지키미 가족·상자 이동·Bun-i | **Case 안에서 완결** | 10절 |
| 15 | `missions[0].play.story[2]`, `evidence.name` | "(1919)" 연도 꼬리표(Case별 쪽지 시리즈 표시) | **Case 안에서 완결** | 5절 story·e1 |
| 16 | v1 M1 story "That is the name of the King's letters now." | C01 의존 | **제거** | "Hangeul, Korea's own letters" |
| 17 | v1 M3 "Her family keeps secrets" / "Mrs. Kang in Harbin is my family too" / "I know a box that keeps secrets" | 시즌 가족 | **제거** | 7절 |
| 18 | v1 Ending 가족 공개·가족의 말·"seven old notes", 쪽지 수 계산 | 시즌 공개 | **제거** | 10절 |
| 19 | 작업 트리 미커밋 변경(엔딩 2줄: "yellow with age", "엄마, 고마워요") | 이 줄들 자체가 삭제됨 | **제거** | 미커밋 diff는 v2 구현 시 엔딩 교체로 함께 사라짐(사용자에게 알림 필요) |
| 20 | dossier cases[7] fiction[2]·[4], reveal.inThisMystery[2] | keepers' box, 분이·강 부인 쪽지 | **Case 안에서 완결 / 제거** | 11절 |
| 21 | 물방울 표시 | 시즌 가족 표식 | **유지(Case 안 단서)** | M1에서 "이름 없음, 물방울만" 제시 → M3에서 공책 대조로 경순 → talk.after에서 왜 이름 대신 물방울인지(경찰·친구 보호)를 경순이 직접 말함. 표 씨와 낯선 사람을 본 것도 경순이 말함 |
| — | evidenceLinks | `s5Ep08EvidenceLinks` 비어 있음 | 해당 없음 | — |

### 14. 독립성 검증 (C08)
| 검사 | 결과 | 근거 |
|---|---|---|
| (a) Intro 이해 | 가능 | 1910 병합, 3·1운동, independence 뜻, 유관순이 누구인지, 경찰 |
| (b) 풀이 | 가능 | M1 증인 대화, M2 계획 쪽지, M3 = M1 쪽지(recall, 이 Case) + 공책 4줄, Final = c1·c2(이 Case) |
| (c) Ending 이해 | 가능 | 불 → 4월 1일 행진 → 낯선 사람 실패, 경순 한 줄 |
| 남은 다른 Case 참조 | **없음** | `s5_ep07_e1`·`s5_ep01_e3` 0, Bun-i·Mrs. Kang·가족·지키미·"letters of the King" 0 |
| 물방울 | Case 안에서 완결 | 쓴 사람(경순)·이유(이름 대신, 경찰)·드러난 방법(자기 공책)이 모두 C08 화면에 있음 |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1·M2 수작 | 엔진·정답·대사 | M1 "no name" 줄, M2 c2 symbol map, 3·1 연결 |
| M3 철자 9글자·시즌 메타 미션(C08-2/8) | id, 공책 3권(그림 일치), 물방울 대조 | text_choice, 특징 2개, 근거 = M1 쪽지(내부 recall), 목적 = 계획을 맡길 사람 |
| Final 기호 불일치(C08-1), 경순이 연 상자(C08-7) | 311, letter | dialSymbols map,map,clock, 탐정이 잠금 |
| 1910·3·1운동 공백(C08-3) | — | Intro 2·3줄 |
| 엔딩 분이 편지·가족 공개 | 역사 줄 | 전부 삭제, 낯선 사람 결말(C08-6) |
| 유관순 단독 지도 | — | "helped lead … with the village elders" |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 가짜 날짜 | — | 읽기 | 1910·3·1 맥락 | 이름 없는 쪽지 |
| M1 | 진짜 날 | 쪽지 | 전령 비교 | 4월 1일, 낯선 사람, 쪽지 주인 미상 | 먼 마을 신호 |
| M2 | 신호 | 4월 1일 | 계획 재배열 | 전날 밤 불 | 낯선 사람이 계획을 노림 |
| M3 | 계획 맡길 사람 | M1 쪽지(recall) | 특징 2개 대조 | 경순 = 쪽지 주인, 계획 맡김 | 잠가야 함 |
| Final | 잠금 | c1·c2 | 다이얼 311 | 잠김, 불 신호 | 엔딩 |
| Ending | 결과 | e2·e4 | 서술 | 4월 1일 행진, 낯선 사람 실패 | (끝) |

### 17. 어린이 플레이 시뮬레이션 (설계 검토, 실제 테스트 아님)
| 항목 | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 보는 것 | 장터 + 쪽지 + 증인 3 | 계획 5줄 + 보기 5 | 공책 그림 + 4줄 + 보기 4 | 언덕 그림 + 다이얼 3 + 4줄 |
| 누르는 것 | 질문 → 날짜 고르기 | 4단계 순서 | 이름 1개 | 다이얼 3개 |
| 근거가 화면에 | 증인 답 | 시간 표현 | 쪽지 특징·공책 줄 | 다이얼 그림 = 단서 그림 |
| 정답처럼 보이는 오답 | 없음 | 종(bell) → "No bell" | Sunja(Hangeul 같음) → 피드백이 둘째 특징 | 301 → "thirty-one days" |
| 다른 Case 지식 필요 | 없음 | 없음 | 없음(현행 C07 recall 제거) | 없음 |
| 재시도 | 무제한 | 무제한 | 무제한 | 무제한(재진입 시 다이얼 0) |
| 목표 기억 | "a wrong day" | "how will far villages know" | "The stranger wants my plan" | "The stranger only knows Mr. Pyo's day" |

### 18. ID·저장 영향
- id 유지: m1~m3, final, c1~c3, e1~e4. M3 answer 형식 `GYEONGSUN` → 보기 id `gyeongsun`(저장은 mission id 기준, 무해). 이미 C08을 푼 플레이어의 수첩 e4는 새 이름·설명으로 보임(문구는 저장되지 않고 콘텐츠에서 읽음).
- 이 Case 증거를 받는 다른 Case: C09 M1 recall `s5_ep08_e4`(C09 v2에서 제거), C12 recall `s5_ep08_e4`(C12 설계에서 제거 필요 — 위 0절 표).
- 테스트: `test/sandbox/s5_seoul_case01_test.dart:164-170` "Case 08 finds Bun-i's letter in the box" → 기대값을 "C08 엔딩에 Bun-i·엄마가 없다"로 교체(C01 소유 테스트이므로 C01 편지가 C01 밖으로 나가지 않음을 지키는 단언이 됨).

### 19. 엔진 변경
- 없음(dialSymbols·symbol·text_choice·in-case recall 모두 데이터).

### 20. 이미지
- 새 그림 없음. `maebong_hill.webp`(다이얼 자물쇠가 달린 나무 상자 + 장작 더미 — 상자가 "경순의 상자"로 읽혀도 그림과 모순 없음), `village_home.webp`(꽃 표지·파란 리본·갈색 공책 3권 — M3 글과 일치), `aunae_market.webp` 재사용. 물방울이 그려진 그림 없음(공책 표지에도 없음; 물방울은 글로만).

### 21. 작업량
- **S~M**. `s5_ep08/case.plan.json`(미커밋 엔딩 변경 위에서 엔딩 교체), `levels.json`(엔딩 5줄, M3 줄), `history_dossier.json`, 재생성, `s5_seoul_case01_test.dart:164-170`.

### 22. 위험과 대응
| 위험 | 대응 |
|---|---|
| M3가 단순 선택으로 보임 | 특징 2개(Sunja 함정), recall로 M1 쪽지를 다시 보게 함 |
| 작업 트리의 미커밋 엔딩 수정이 v2에서 사라짐 | 구현 전에 사용자에게 알리고 같은 PART에서 처리 |
| 부모 사망 줄의 수위 | 사실 1줄, reveal에만 |
| 물방울이 다른 Case에도 남으면 연결로 읽힘 | C06·C07·C09에서 물방울 제거(이 문서). C02~C05·C10~C12는 각 설계에서 확인 필요 |

---
## Case 09 — The Spy in the Shanghai Office (1920)

### 1. 제목·역사 배경
- 제목 유지: **The Spy in the Shanghai Office**.
- 배경(이 Case 안에서 모두 설명): 1910 일본의 국권 강탈 → 1919.3.1 3·1운동 → 1919년 4월 상하이에서 대한민국 임시정부 수립(일본이 한국을 지배해 나라 밖에서) → 김구 1919년 8월 경무국장("문지기라도 하겠다"고 청함) → 경무국은 정부를 지키고 밀정을 감시 → 1940년 김구 임시정부 주석.

### 2. 독립 사건 목표 (한 문장)
비밀 명단을 베낀 사람을 찾아 김구에게 증거로 보이고, **베낀 사본이 상하이 밖으로 나가지 못하게 한다**. (`goal` 확장: "Find out who copied the secret list, prove it to Kim Gu, and stop the copy.")

### 3. 인물 동기
| 인물 | 동기 (이 Case 안에서만) |
|---|---|
| 김구(경무국장) | 명단 속 사람들이 위험해질까 걱정. 증거 없이 사람을 잡지 않는다 |
| 해수(젊은 점원, 창작) | 새 초를 갈아 둔 사람이라 초가 반 탄 것을 알아챘다. 사무실에 밀정이 있을 수 있어 **이름 없이** 쪽지를 떨어뜨려 탐정에게 알림 |
| 남기호(새 점원, 창작) | 명단을 베껴 일본 쪽에 넘기려 함. "아무 일도 안 했다"고 버팀 |
| 서 씨·박 씨(점원, 창작) | 일찍 퇴근 — 용의선상 밖 |
| 야간 경비(창작) | 1층 정문에만 있음, 사무실 열쇠 없음 → 용의선상 밖(C09-2) |

### 4. Intro (R, 7줄 — 현행 5줄 → 7줄)
문제(현행): 3·1운동을 이미 안다고 가정("After the March First Movement"), 임시정부가 왜 나라 밖에 있는지 설명 없음(C09-6), 상하이 위치. v1 문제: 시대 이동 첫 줄, 3·1운동 설명을 C08에 맡김(철회 — 여기서 직접).
```
Autumn, 1920. You are in Shanghai, a big city in China, as a guest of Kim Gu.
In 1910, Japan took over Korea. Koreans could not rule their own country.
On 1 March 1919, people all over Korea called for independence. This is the March First Movement.
That spring, Koreans began their own government here. It works outside Korea, because Japan rules Korea.
Its name is the Provisional Government of the Republic of Korea.
Kim Gu is its police chief. He keeps it safe from spies.
This morning, he is worried. "Someone was at our secret list," he says.
```
- 1910·3·1 문장은 C08 Intro와 같은 정보지만 이 Case 안에서 다시 설명(독립 정책상 의도).

### 5. Mission 1 — Half a Candle (v1 유지 + 물방울 제거)
- **유형** `number_entry` · `numberCode` · time, answer `0100`.
- **변경점(v1)**: "saw a light … at eleven" → "saw the light **go on** at eleven"(켜진 시각 명시, C09-1), 4칸 예시(C09-9). **(v2)** 물방울 서명 삭제, recall·clueInputs(`s5_ep08_e4`) 삭제, 사촌·상자 줄 삭제.
- **story(R)**: `Early morning in a narrow Shanghai lane.` / `A young clerk hurries past you and drops a folded note.` / `It is in Hangeul, Korea's own letters. It has no name.`
- **letterIntro**: "The note says:"
- **letter(R)**:
```
Detective, someone used the list desk last night.
At eleven, the guard saw the light go on.
It was a new candle. A new candle burns for four hours.
This morning, half of it was gone.
— a friend in this office
```
- **question(R)**: "What time did the light go out? Use four numbers. (Seven in the morning is 07:00.)"
- **8세 풀이 경로**: 켜진 시각 11시 → 4시간의 절반 = 2시간 → 11 + 2 = 밤 1시(자정 넘김: "eleven, twelve, one") → 01:00 → 0,1,0,0.
- **대입**: 0100 ✓ / 1300(오후) / 2300(켜진 시각) / 0300(초 전부) / 1100(켜진 시각, 12시간제) / 0200(절반 착오) → 단일.
- **힌트**: 1 "The light went on at eleven. How many hours did half the candle burn?" 2 "Half of four hours is two hours. Eleven, twelve, one."
- **오답**: 1300 "It was night, not the afternoon. One in the night is 01:00." / 2300 "Eleven is when the light went ON. When did it go out?" / 0300 "Only half of the candle burned, not all of it." / 1100 "Eleven is when the light went ON. When did it go out?" / 0200 "Half of four hours is two. Count two hours from eleven."
- **successMessage**: "The light went out at one in the night!"
- **transition(R)**: `Someone sat at the list desk from eleven until one.` / `The young clerk comes back. "I am Haesu. I wrote that note."` / `"A spy may be in this office. So I did not sign my note."`
  (현행 3줄째 "Gyeongsun of Aunae is my cousin. She gave me the old box." **삭제**)
- **상태 변화**: 11시~1시 책상 사용. 쪽지 주인 = 해수(곧바로 밝혀짐, 수수께끼로 끌지 않음).
- c1/e1(id 유지): e1 name "The Water-Drop Note (1920)" → **"Haesu's Note"**, description "Haesu's note. At eleven, the light at the list desk went on. Half of a new candle burned." (Final `when` 카드)
- **다음 이유**: 무엇을 남겼나.

### 6. Mission 2 — The Police Report (v1 유지)
- **유형** `dark_room_search` · `investigations`, answer `paper`. 위치어 탐색(next to / on / under) 유지(감사: 잘 설계됨). 다 찾으면 자동 정답(오답 제출 없음).
- **letter**(현행): 경찰 보고서 3줄(key next to the stove / ink bottle on the window sill / thin paper under the list desk).
- **successMessage**: "You found all three things!" → "The thin paper has names pressed into it. The list was copied!"(C09-7)
- **transition(R)**: `Someone wrote a copy on top of this thin paper.` / `His pen pressed the names into it. There is no ink on it.` / `The copy itself is gone.` / `Haesu frowns. "At night, only clerks have a key to this office."` (현행 3줄 → 4줄, levels 같이)
- **e2** description: "Kim Gu's police found thin paper under the list desk. It lay under a copy: the pen pressed the names into it."
- **다음 이유**: 열쇠가 있는 점원 중 누가 1시까지 있었나.

### 7. Mission 3 — The Sign-Out Book (v1 유지, 이름은 원래대로 Mr. Pak)
- **유형** `word_entry` · `wordInput`, answer `NAM GIHO`, acceptedAnswers 유지(NAM, GIHO, MR NAM 등).
- **변경점**: 경비 배제(C09-2), 퇴근부 줄을 시간순이 아니게(정답이 마지막 줄이 아니게). **(v2)** v1의 Mr. Pak → Mr. Choi 개명은 **취소**: 이름 충돌은 C07 박 씨와의 Case 간 문제였고, C09 안에서는 박 씨가 한 명뿐이다. 현행 `PAK` 피드백 키 그대로.
- **talk.before(R)**: HAESU "Three other clerks work here, and me." / HAESU "At night this office is locked. Only clerks have a key." / YOU "Then the copier is a clerk who stayed late."
- **letter(R, 화면 순서)**:
```
Mr. Seo: left at half past eleven.
Mr. Nam Giho: left at a quarter past one.
Haesu: left at nine.
Mr. Pak: left at ten.
The night guard: at the front door all night. He has no office key.
```
- **question(R)**: "Who was still in the office when the light went out? Type his name."
- **8세 풀이 경로**: 불이 꺼진 때 = 1시(M1) → 1시보다 늦게 나간 점원: 11:30·9·10 < 1, 1:15 > 1 → 경비는 열쇠 없음 → NAM.
- **대입**: Seo(11:30) / Pak(10시, 불 켜지기 전) / Haesu(9시) / guard(열쇠 없음) / Nam ✓ → 단일.
- **힌트**: 1 "Your first clue says when the light went out." 2 "A quarter past one is after one. Who left then?"
- **오답**: SEO "Mr. Seo left at half past eleven. The light burned until one." / PAK "Mr. Pak left at ten, before the light went on." / HAESU "Haesu left at nine." / GUARD "The guard has no office key. He stayed downstairs."
- **successMessage**: "Only Mr. Nam Giho was still here at one!"
- **transition(R)**: `Mr. Nam Giho came to the office only last month.` / `His desk is empty this morning.` / `Haesu runs to tell Kim Gu.`
- c3/e3 유지.
- **다음 이유**: 증거로 김구를 설득하고 사본을 찾아야.

### 8. Final — Mr. Nam Says No (v1 유지: 3카드 × 3, 사본 회수)
- **유형** `evidence_talk` · `talks` · `examine`. answer `protect` → **`copy_found`**(값만 변경, mission id 유지).
- **변경점**: 김구 자기소개 모순 제거(C09-4: Intro에서 이미 손님으로 만남), 노트 요약 삭제·카드 2→3·`protect` present 삭제(C09-5), 사본 행방·범인 도주 해소(C09-3).
- **story(R)**: `At dawn, Kim Gu's police stop Mr. Nam Giho by the river.` / `Kim Gu comes back up the stairs.` / `"Mr. Nam says he did nothing," he says. "Show me your proof."`
- **letterIntro / letter(R)**: "Mr. Nam says:" / `Nobody was at the list desk last night.\nNothing was copied.\nI went home at nine.`
- **question(R)**: "Show Kim Gu that each thing Mr. Nam says is wrong."
- **interview**: speaker `kim_gu`, goal "Show Kim Gu who copied the list.", opening KIM GU "That list has the names of our friends. Without proof, I must let him go." · 선택 질문 `begin`(현행: "In April 1919, here in Shanghai." / "It began after the March First Movement at home." — Intro가 3·1운동을 설명하므로 이 Case 안에서 이해됨) · `work`(현행).

| id | prompt (R) | 카드 화면 순서 | accepted | 정답 대사(R) | miss | tell(안내) |
|---|---|---|---|---|---|---|
| when | Kim Gu asks: "He says nobody was at the list desk. Was someone?" | e3, e1, e2 | s5_ep09_e1 | YOU "Yes. The light went on at eleven. Half a new candle burned: until one." / KIM GU "Two hours with our list." | "That does not show anyone at the desk." | "Which card is about the candle and the light?" |
| how (req when) | "He says nothing was copied." | e1, e3, e2 | s5_ep09_e2 | YOU "This thin paper was under his copy. His pen pressed the names into it." / KIM GU "So a copy was made. Where is it?" | "That does not show a copy." | "Which card is about the thin paper?" |
| who (req how) | "He says he went home at nine." | e2, e3, e1 | s5_ep09_e3 | YOU "The sign-out book says a quarter past one. Everyone else left before one." / KIM GU "And the guard has no key. It was Mr. Nam." | "That does not show when he left." | "Which card has the times the clerks left?" |

finishWhen `[when, how, who]`, finishLabel "SEARCH HIS COAT". (`protect` 삭제.)
- **Final 증거(이 Case 것만)**: s5_ep09_e1(불·초), e2(눌린 이름), e3(퇴근 시각). 3개 모두 필수.
- **해결 방식**: 남기호의 거짓말 3개를 증거로 반박 → 외투 수색 → 사본 회수.
- **대입 검사**: when = 불·초가 있는 e1만, how = 눌린 이름 e2만, who = 퇴근 시각 e3만. 각 카드가 다른 질문의 대상(불/종이/퇴근)을 담지 않음 → 단일. ("nine"이 e3에 Haesu로 나오지만 질문은 "그가 9시에 갔다"의 반박이라 e3이 정답 — 일치.)
- **힌트(b1)**: 1 "Each thing Mr. Nam says has one card that shows it is wrong." 2 "Desk: Haesu's Note. Copy: the police report. Nine: the sign-out book."
- **successMessage**: "Kim Gu nods. \"Search his coat.\""
- **transition(R)**: `Sewn inside Mr. Nam's coat is the copied list. It never left Shanghai.` / `Kim Gu locks the real list and the copy in an iron box.` / `"Haesu," he says, "you saw the first clue. Thank you."` (현행 3줄째 "Haesu puts her note in the old wooden box. One more water drop." **삭제**, 현행 2줄째 감사 대사를 3줄째로)
- **e4**(id 유지) name "Kim Gu's Case Note", description: "The copied list was found sewn in Mr. Nam's coat. It never left Shanghai. Haesu's note, the thin paper and the sign-out book proved it." (현행·v1의 "Kim Gu trusts Haesu"는 C10 recall용이었으므로 삭제)

### 10. Ending (새 핵심 줄)
HAESU "I only counted a candle, sir." / KIM GU "Small things keep big things safe, Haesu." / narrator "Mr. Nam Giho can never spy in this office again." / "Korea's Provisional Government began in Shanghai in April 1919." / "Kim Gu was its police chief. His police guarded it and watched for spies." / "In 1940, Kim Gu became the chairman, the leader, of that government."
- 현행 1줄째 "By noon, Mr. Nam Giho has left Shanghai. The real list is safe."(범인 도주) → "Mr. Nam Giho can never spy in this office again."
- `hook`: "Kim Gu trusts Haesu now. What will he ask of her next?"(C10 예고) → **"A candle, a thin paper and a book of times caught a spy."**
- caseSummary: "Haesu, a keeper, saw the first clue." → "Haesu, a young clerk, saw the first clue." / "Mr. Nam Giho, a new clerk, left last." 뒤에 "The copy was found in his coat." / "Later, in 1940, Kim Gu became its head." → "…its chairman."

### 11. 역사 학습 + 사실/창작
- 배움: 1910 병합, 3·1운동(이 Case에서 설명), 1919.4 상하이 임시정부(나라 밖 정부인 이유), 김구 경무국장(1919.8), 밀정 감시, 1940 주석. 영어: go on, half past, a quarter past, under/next to/on.
- IN THIS MYSTERY(R): "Haesu, Mr. Nam Giho, the clerks, the candle and the list are made up. The Provisional Government in Shanghai and Kim Gu's police are real history."
- dossier cases[8]: fiction[1] "Haesu is made up; she brings the keepers' box from Aunae (the season's story)." → "Haesu is made up; so is her unsigned note." puzzles[0] clue 문구 → "At eleven, the guard saw the light go on.", puzzles[2] → 새 경비 줄·whyOnly(Mr. Pak 유지), puzzles[3] answer `copy_found`·clues·whyOnly 갱신. 1910·3·1운동 사실 항목이 cases[8].facts에 없으면 추가(Intro에서 보이므로). cases[9]가 `s5_ep09_h1`을 쓰므로 h1 문구는 바꾸지 않는다.

### 12. 난이도별 핵심 줄 (실측)
| # | R | J | M |
|---|---|---|---|
| 1 나라 밖 정부 | That spring, Koreans began their own government here. It works outside Korea, because Japan rules Korea. (16) | That spring, Koreans began their own government here, outside Korea, because Japan ruled Korea. (14) | That spring, Koreans founded their own government here, abroad, since Japan ruled Korea itself. (14) |
| 2 M1 | At eleven, the guard saw the light go on. (9) | At eleven o'clock, the guard saw the light in the office go on. (13) | At eleven, the guard watched the office light flicker on. (10) |
| 3 서명 없는 이유 | A spy may be in this office. So I did not sign my note. (14) | A spy may be working in this office, so I did not sign my note. (15) | There may be a spy in this very office; that is why my note bore no name. (17) |
| 4 M3 경비 | The night guard sat at the front door all night. He has no office key. (15) | The night guard sat at the front door all night, but he has no key to the office. (18) | The night guard kept to the front door all night, and he holds no key to the office upstairs. (19) |
| 5 Final | Sewn inside his coat is the copied list. It never left Shanghai. (12) | The copied list is sewn inside his coat, so it never left Shanghai. (13) | Sewn into the lining of his coat is the copied list; it never left Shanghai. (15) |

### 13. 외부 의존 원장 (C09)
| # | 위치 | 현재 | 결정 | 교체 내용 |
|---|---|---|---|---|
| 1 | `missions[0].clueInputs[0]` | recall `s5_ep08_e4`("The keepers' letter box came to Shanghai with Haesu") | **제거** | 삭제(M1 clueInputs 없음) |
| 2 | `missions[0].play.recall` | "The box from Aunae" / "…holds notes with this water drop?" / "Find the old wooden box from Maebong hill." | **제거** | `recall` 키 삭제 |
| 3 | `missions[0].play.story[2]` | "It is in Hangeul, with a small water drop in the corner." | **Case 안에서 완결**(물방울은 기능 없음 → 제거, 무명 쪽지는 밀정 때문) | "It is in Hangeul, Korea's own letters. It has no name." |
| 4 | `missions[0].play.letter` 서명 | "— a small water drop" | **Case 안에서 완결** | "— a friend in this office" |
| 5 | `missions[0].play.letterIntro` | "The water-drop note says:" | **Case 안에서 완결** | "The note says:" |
| 6 | `missions[0].play.transition[2]` | "Gyeongsun of Aunae is my cousin. She gave me the old box." | **Case 안에서 완결** | "A spy may be in this office. So I did not sign my note." |
| 7 | `missions[0].play.evidence` | "The Water-Drop Note (1920)" / "…with a small water drop…" | **Case 안에서 완결** | "Haesu's Note" / 5절 |
| 8 | `final.play.transition[2]` | "Haesu puts her note in the old wooden box. One more water drop." | **제거** | 8절 transition |
| 9 | `final.play.evidence.description` | "…Haesu saw the first clue."(현행) / v1 "Kim Gu trusts Haesu"(C10 recall용) | **Case 안에서 완결** | 8절 e4 |
| 10 | `hook` | C10 예고 | **교체** | 10절 hook |
| 11 | `play.caseSummary` | "Haesu, a keeper" | **Case 안에서 완결** | "Haesu, a young clerk" |
| 12 | `notes[0]` | "Haesu, a young clerk and keeper, brings the keepers' box (s5_ep08_e4) to Shanghai; …reused in Case 10." | **Case 안에서 완결** | "Haesu, a young clerk, warns the detective with an unsigned note; her portrait and Kim Gu's are made here." |
| 13 | `play.intro[1]` | "After the March First Movement, …"(3·1운동을 안다고 가정) | **Case 안에서 완결** | 4절 Intro 2·3줄 |
| 14 | v1 Intro 첫 줄, v1 "C08에서 이름 등장 → C09가 이어 씀" | 시대 이동·C08 의존 | **제거** | 4절 |
| 15 | v1 Mr. Pak → Mr. Choi | Case 간 이름 충돌 회피 | **취소(원래 이름 유지)** | Mr. Pak |
| 16 | dossier cases[8].fiction[1] | keepers' box | **Case 안에서 완결** | 11절 |
| — | discovery 3개 | 모두 이 Case 내용("TWO HOURS…", "A COPY OF THE LIST", "THE NEW CLERK") | **유지(이유: 내부 사건 진행만 말함)** | 그대로 |
| — | evidenceLinks | `s5Ep09EvidenceLinks` 비어 있음 | 해당 없음 | — |

### 14. 독립성 검증 (C09)
| 검사 | 결과 | 근거 |
|---|---|---|
| (a) Intro 이해 | 가능 | 1910, 3·1운동, 임시정부가 나라 밖에 있는 이유, 김구의 일 |
| (b) 풀이 | 가능 | M1 해수 쪽지, M2 경찰 보고서·그림, M3 퇴근부, Final = e1·e2·e3 |
| (c) Ending 이해 | 가능 | 사본 회수, 임시정부·김구 서술 |
| 남은 다른 Case 참조 | **없음** | `s5_ep08_e4` 0, 경순·상자·물방울·지키미 0, C10 예고 0 |
| 해수의 쪽지 | Case 안에서 완결 | 누가(해수, M1 transition에서 직접), 왜 이름 없이(사무실 밀정) |

### 15. 유지/변경 표
| 기존 | 유지 | 변경 |
|---|---|---|
| M1 켜진 시각 불명(C09-1), 0 입력(C09-9) | 0100, 계산 | "go on", 예시, 1100·0200 피드백, 물방울·사촌·recall 제거 |
| M2 좋음, 성공 문구(C09-7), 복사 방식(C09-3) | 탐색·그림·영역 | 성공 문구, transition, e2 |
| M3 경비 미배제(C09-2) | 퇴근부, NAM, **Mr. Pak** | 열쇠 없음, 순서 섞기 |
| Final 2지×4·요약·역사 4번(C09-5), 자기소개(C09-4), 도주(C09-3) | 대화 엔진, present when/how/who | 3카드, 주장 반박, protect 삭제, 사본 회수 |
| 3·1운동·임시정부 설명(C09-6), 1940 head | — | Intro, chairman |
| 상자·사촌·예고 | — | 삭제 |

### 16. 인과관계 표
| 단계 | 필요 이유 | 이전에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 명단 위험 | — | 읽기 | 임시정부 맥락 | 골목 쪽지 |
| M1 | 언제 | 해수 쪽지 | 11+2 | 11~1시 | 무엇을 남겼나 |
| M2 | 어떻게 | 시간대 | 위치어 탐색 | 사본이 만들어짐(사본 없음) | 열쇠 가진 점원 |
| M3 | 누가 | 1시 | 퇴근부 대조 | 남기호 | 증명·사본 |
| Final | 김구 설득 | e1·e2·e3 | 3주장 반박 | 사본 회수 | 엔딩 |
| Ending | 결과 | e4 | 대화·서술 | 명단 안전, 역사 | (끝) |

### 17. 어린이 플레이 시뮬레이션 (설계 검토, 실제 테스트 아님)
| 항목 | M1 | M2 | M3 | Final |
|---|---|---|---|---|
| 보는 것 | 골목 + 쪽지 5줄 + 시계 키패드 | 사무실 그림 + 보고서 3줄 | 퇴근부 5줄 | 남기호 주장 3줄 + 카드 3 |
| 누르는 것 | 4칸 숫자 | 물건 3개 탭 | 이름 입력 | 카드 1장 × 3 |
| 근거가 화면에 | go on, four hours, half | 위치어 | 시각 표현 | 카드 설명 |
| 정답처럼 보이는 오답 | 1100/2300 → "went ON" 피드백 | 없음 | 마지막 줄 습관 → 정답이 둘째 줄 | 질문 낱말(desk/copied/nine)과 카드(light/paper/times) |
| 다른 Case 지식 필요 | 없음(현행 C08 상자 recall 제거) | 없음 | 없음 | 없음 |
| 재시도 | 무제한 | 자동 정답 | 무제한, 관대한 철자 | miss → tell → 빛남, b1 |
| 목표 기억 | "Someone was at our secret list" | "What did they leave?" | "Who stayed late?" | letter의 주장 3줄 |

### 18. ID·저장 영향
- id 유지: m1~m3, final, c1~c3, e1~e4. present `protect` 삭제(저장된 대화 상태의 모르는 id는 버려짐). Final answer 값 `protect`→`copy_found`.
- 텍스트 변경 증거: e1(이름·설명), e2, e4. 이 Case 증거를 받는 다른 Case: C10 M1 recall `s5_ep09_e4` — C10 설계에서 제거 필요(0절 표). e4에서 "trusts Haesu"가 빠지므로 C10이 그대로 두면 recall 문구 "Kim Gu's case note: he trusts Haesu"와 어긋난다.
- 테스트: `test/sandbox/s5_seoul_rookie_test.dart:115-119`(C09 Final letter "The police guard the government…"와 talk 단언) 기대값 갱신.

### 19. 엔진 변경
- 공통 2b1·2b2·2b3. C09 고유 없음. 독립화로 인한 변경 없음.

### 20. 이미지
- 없음. `shanghai_lane`·`government_office`·`desk_key`·`ink_bottle`·`thin_paper` 재사용. 남기호 초상 없음 → 대화 화자는 김구. 물방울·상자 그림 없음.

### 21. 작업량
- **M**. `s5_ep09/case.plan.json`, `levels.json`(Intro 7줄, M2 transition 4줄, Final), `history_dossier.json`, 재생성, `test/sandbox/s5_seoul_rookie_test.dart`.

### 22. 위험과 대응
| 위험 | 대응 |
|---|---|
| "밀정" 서술 수위 | 게임 문장은 "spy"만, 일본 경찰 언급은 notes에만 |
| 경비 배제가 M2·M3 두 곳에 나뉨 | 두 곳 모두 "only clerks have a key" 같은 문장 |
| 1910·3·1 설명이 C08과 중복 | 독립 정책상 의도 |
| answer 값 변경이 테스트에 박혀 있음 | rookie_test 갱신 |

---

## 부록 A — 4개 Case 독립화 요약

| Case | 새 Final 정답 / 증거(모두 이 Case) | 제거한 타 Case 요소 | Case 안에서 완결한 요소 | 엔진 |
|---|---|---|---|---|
| C06 | talk `unseen` / e1 실·e2 서문 길·e3 감시 시각 | recall `s5_ep05_e1`, textMention `s5_ep05_e4`(1895 지도 줄), 상자·봉수→강 부인·귀환 줄 | 1897 황제 설명, 봉수 쪽지(물방울 제거) | 2b1·2b2·2b3 |
| C07 | talk `for_korea` / e2 시각·e3 들은 말·**e1 강 부인 쪽지(이토·1905)** | recall `s5_ep06_e1`, textMention `s5_ep05_e1`, Final `s5_ep06_e4`(황제의 편지·헤이그), "letter box", 1919 예고 | 1905 조약·이토 설명, 강 부인 쪽지에 이토 줄 | 2b1·2b2·2b3 |
| C08 | dial `311` / c1 4월 1일·c2 전날 밤 불 | recall `s5_ep07_e1`, `s5_ep01_e3`, 분이 편지·가족 공개·지키미 상자·강 부인 친척 | 물방울 = 경순이 이름 대신 그린 표시(M1 쪽지 → M3 공책 대조, recall `s5_ep08_e1`), 상자 = 경순의 상자 | 없음 |
| C09 | talk `copy_found` / e1 초·e2 얇은 종이·e3 퇴근부 | recall `s5_ep08_e4`, 경순 사촌·상자 줄, C10 예고 | 1910·3·1·임시정부 설명, 해수의 무명 쪽지(밀정 때문), Mr. Pak 원래 이름 | 2b1·2b2·2b3 |

## 부록 B — 구현 순서와 공통 확인
1. 엔진 PART(2b1·2b2·2b3) → 관련 위젯 테스트.
2. C08(엔진 의존 없음, 미커밋 엔딩 변경 위에서) → C06 → C07 → C09. Case마다 plan·levels·dossier 수정 후 재생성(`generate_season --target game --check`), `play_check`·`selection_check`, `test/sandbox/s5_seoul_rookie_test.dart`, `test/sandbox/s5_seoul_case01_test.dart`(C08 기대값 교체).
3. C10·C12 설계자에게 전달: C10 M1 recall `s5_ep09_e4`, C12 recall `s5_ep08_e4`를 각 Case에서 제거해야 이 4개 Case의 e4 문구 변경과 어긋나지 않는다.
4. 생성기 `clue_never_used` 경고가 e4마다 생길 수 있음(경고, 생성 통과). 독립 정책의 결과로 수용.
5. 시즌 문서(`story_bible.json`, `season.plan.json`의 지키미·상자 서술)는 이 문서 범위 밖 — 독립 정책에 맞춘 정리는 별도 작업.

---

# §C3 Case 10~12 · 시즌 문구 (독립 사건 설계)

## Seoul Case 10·11 + 시즌 프롤로그/아웃트로/피날레 — 독립 사건 정정 설계 (redesign2)

- 작성 2026-11-09. 읽기 전용 분석. 저장소 파일은 하나도 바꾸지 않았다.
- 기준: §0 정책(2026-11-09 확정, `season_frame.md` 대체). 정정 대상: `redesign_c10_12.md`의 Case 10·Case 11·Season 절(그 Case 12 절은 다른 담당이 다시 한다).
- 근거 데이터: `cases/s5_ep1{0,1}/case.plan.json`, `season.plan.json`·`season.levels.json`, `planning/story_bible.json`, `planning/history_dossier.json`, `lib/data/generated/s5_seoul/s5_ep1{0,1}.g.dart`(discoveries·evidenceLinks), `s5_seoul_history.g.dart`(reveal), `s5_seoul_cases.g.dart`, `engine_save_impact.md` §1–4, 화면 코드 `case_solved_screen.dart:222,364`(finale), `season_screen.dart:762`(outro). 그림 직접 확인: `case_10/breakfast_room.webp`·`haesu_room.webp`, `case_11/dorm_room.webp`·`c11_drop_card.webp`, `case_02/find_note.webp`.
- 대상: 영어를 배우는 한국 어린이 8~12세. glossary는 한국어.
- "시뮬레이션"은 모두 **설계 검토**이며 실제 어린이 테스트가 아니다.
- 단어 수: 글자나 숫자가 하나 이상 든 토큰을 스크립트로 셌다(`scratchpad/wc2/count.py`). `____`, `+`, 문장부호만 있는 토큰은 세지 않는다.
- 탐정이 그 시대에 있는 이유: 물방울 쪽지 시간 이동 규칙은 철회되었으므로, 원래 데이터처럼 **"그 사람의 손님(guest)"**으로 둔다. 다른 Case를 전제하지 않는다.
- 이전 설계에서 그대로 유지하는 개선(정책 "유지하는 개선"): C10 M2 시계 모순 해결, C10 M3 HOUR(『백범일지』 "한 시간"), C10 Final 기록 검증(이제 **이 Case 증거만**), C11 M3 PIANO, C11 Final 2단계(대화 → 319), C11 Final 편지 R/J/M 같은 줄·같은 정보.

---

## Case 10 — The Two Watches

### 1. 제목·역사 배경
- 제목 유지: **The Two Watches**.
- 배경: 1932년 4월 29일 아침, 상하이. 일본은 1910년부터 한국을 지배했다. 한국 지도자들은 1919년 중국 상하이에 대한민국 임시정부를 세웠다. 김구는 임시정부의 지도자이고, 비밀 단체 한인애국단을 이끌었다. 그 단원 윤봉길이 이날 아침 김구와 아침을 먹고 회중시계를 바꿨다. 김구는 『백범일지』에 윤봉길의 말을 남겼다. "제 시계는 6원, 선생님 시계는 2원짜리이니 바꿉시다. 제 시계는 앞으로 한 시간밖에 쓸 데가 없습니다." 그날 윤봉길은 훙커우공원의 일본군 기념식에서 의거를 일으켰고 곧 체포되어 12월 일본에서 사형되었다. 이후 중국 지도자들이 임시정부를 적극적으로 도왔다.
- **이 Case 안에서 설명하는 배경**: 일본의 지배(1910~), 임시정부가 상하이에 있는 이유, 김구가 누구인지, 해수가 누구인지(임시정부 서기, 김구 밑에서 일함). 모두 Intro 1~5줄에 있다.

### 2. 독립 사건 목표 (한 문장)
김구는 손에 시계를 쥔 채 아무 말도 하지 않는다. 임시정부 서기 해수는 **오늘 밤까지 정부 기록부에 "오늘 아침의 기록"을 써야 한다.** 탐정은 무슨 일이 있었는지, 김구가 쥔 시계가 누구 것인지, 왜 바꿨는지를 증거로 밝혀 해수의 기록을 한 줄씩 사실로 만든다.

### 3. 인물 동기 (모두 이 Case 안에서 밝혀짐)
- **윤봉길**(실존): 돌아오지 못할 수 있다는 것을 안다. 좋은 새 시계는 오래 쓸 사람에게 주고 싶었다 → M3에서 김구의 입으로 밝혀진다.
- **김구**(실존): 슬픔 때문에 말을 못 한다. M3에서 처음으로 입을 연다.
- **해수**(창작): 임시정부 서기. 김구의 지시로 정부의 그날 기록을 쓴다. 부엌에서 본 것을 서둘러 적어서 쪽지 순서가 섞였다(M1). 기록에 틀린 줄이 있으면 안 되므로 줄마다 증거를 요구한다(Final). **지키미·상자·물방울·사촌 미리·딸 빛나와의 관계는 모두 지운다.**
- 탐정: 김구의 손님. 의거 현장에는 가지 않는다.

### 4. Intro (ROOKIE 전문, 6줄 — 지금 4줄에서 늘어남, R/J/M 같은 줄 수)
1. Spring, 1932. Japan has ruled Korea since 1910.
2. So Korean leaders made a government in Shanghai, China: the Provisional Government.
3. Kim Gu is one of its leaders. You are his guest.
4. Early on 29 April, Kim Gu eats breakfast with a young man, Yun Bong-gil.
5. Then Haesu, Kim Gu's clerk, runs to you. "Mr. Kim holds a watch. He will not say a word."
6. "Tonight I must write the government's record of this morning. Please help me get every line right."

- 지금의 Intro("…a guest of Kim Gu in Shanghai **again**." / "Haesu, the young clerk, **now** works close to him.")는 C09를 전제하므로 위로 바꾼다.
- synopsis: "Shanghai, the morning of 29 April 1932." / "Kim Gu and a young man, Yun Bong-gil, ate breakfast, then swapped watches." / "Now Kim Gu will not say a word. What happened, and why?"
- goal: "Find out what happened at breakfast, whose watch Kim Gu holds, and why, so Haesu's record is true."
- objectives: "Put the morning in order." / "Find the watch in Mr. Kim's hand." / "Find out why they swapped." / "Prove every line of Haesu's record."
- hook(화면에 나오지 않는 데이터. `Episode.hook`은 `case_solved_screen.dart:226` 주석대로 표시 안 함): "The box goes home to Seoul. Who will keep it there?" → **"One watch, two men, and a morning no one must forget."**
- learningGoal: "Order and years: first, before that, nineteen thirty-two" → **"Order and time: first, after, one more hour"** / titleKo "순서와 시간: first, after, one more hour".

### 5~10. Mission

#### M1 Breakfast for Two — 유지 (외부 의존과 물방울만 걷어냄)
- 목적: 아침에 일어난 일의 순서를 세운다. 교환이 식사 **뒤**라는 것을 확인한다.
- 유형: `order_sequence` / engineTable null / `sequence`. 정답 `eat,swap,goodbye,alone`. 보기 순서는 지금 그대로(alone, buy, swap, eat, goodbye). 정답 순서가 아니다.
- talk.before(윤봉길 3줄)는 유지한다(이 Case 안의 인물).
- story (R): "At the door, a young man in a grey suit passes you." / "Inside, two rice bowls are empty on the table." / "Haesu gives you her note. \"I wrote it fast in the kitchen. It is all mixed up.\""
- letterIntro: "The water-drop note says:" → **"Haesu's note says:"**
- letter: 1~5줄은 그대로(At the end… / Before that… / They ate breakfast first, quietly. / After breakfast, they swapped their watches. / Mr. Yun's watch was new. He did not buy it this morning.). 서명 줄 "— a small water drop" → **"— Haesu"**.
- 화면 단서: 순서어 first / after breakfast / before that / at the end. "He did not buy it this morning." → buy 탈락.
- 8세 풀이: ① "first" 줄 → eat. ② "After breakfast" → swap. ③ "At the end" → alone(마지막). ④ "Before that" → goodbye는 alone 바로 앞. ⑤ buy는 "did not buy it this morning"으로 빠진다.
- 대입 검사: 4장 조합 중 buy가 들어가면 모두 오답. eat·swap·goodbye·alone의 순서는 각 순서어가 한 자리씩 고정하므로 하나뿐.
- 힌트: 현행 유지("One line says what they did first." / "At the end means the last step. Before that means just before it.").
- 오답: orderFeedback(R/J/M) "Those are the right steps, but in the wrong order. Read first, after, before that and at the end again."(감사 C10-6).
- **recall 삭제**: `play.recall`("Who is Haesu?" / police chief's note)과 clueInputs `s5_ep09_e4` recall을 지운다. 해수는 Intro 5줄이 소개한다. M1 clueInputs는 빈 배열(s5_ep01·05·08 M1과 같은 형태, `play_check.dart:235`는 recall 입력과 play.recall을 함께 지우면 문제 없음).
- 상태 변화: c1 "The Swap"(유지), e1 이름 "The Water-Drop Note (1932)" → **"Haesu's Kitchen Note"**, description → "Haesu's note from the kitchen, written fast and all mixed up. After breakfast, the two men swapped watches." inscription 유지.
- transition: "Breakfast, the swap, goodbye, and Mr. Kim alone." / "Haesu comes in from the kitchen with tea." / "\"Mr. Kim is still holding the watch. He has not said a word.\""(유지)
- discovery 유지("TWO WATCHES SWAPPED" / "Mr. Kim holds a watch now. But whose watch is it?").
- 다음 필요 이유: 김구가 쥔 시계가 누구 것인지 모른다.

#### M2 Which Watch? — 변경 (P1 장면 모순 해소, 이전 설계 유지)
- 목적: 교환 뒤 김구 손에 있는 시계를 추론한다.
- 유형: `picture_choice` / null / `imageChoice`, `hideOptionNames: true`. 정답 `new_watch`.
- 모순 해소: 탁자에 실물 시계 셋을 놓지 않는다. 김구는 손을 펴지 않고, 해수가 **아침에 본 시계를 공책에 그린 그림 세 장**을 보여 준다. 그림 파일은 그대로, altText만 "Haesu's drawing of …"로.
- story (R): "Mr. Kim sits by the window. His hand is closed around the watch." / "Haesu opens her notebook. \"I drew every watch I saw this morning.\"" / "\"Which one is in his hand now?\" she whispers."
- letterIntro "Haesu tells you:" / letter (R 5줄):
  1. Mr. Kim's old watch has a worn case with many small scratches.
  2. Mr. Yun's watch is new. Its case is smooth, with no scratches.
  3. My own watch is small, on a leather strap. It is on my arm.
  4. I can see a chain between Mr. Kim's fingers.
  5. They swapped. Each man took the other's watch.
- question: "Which drawing shows the watch in Mr. Kim's hand?"
- 보기(plan 순서): old_watch, new_watch, strap_watch. 피드백 — old: "That was Mr. Kim's old watch. After the swap, who took it?" / strap: "A strap, not a chain. And Haesu's watch is on her arm."
- 8세 풀이: ① 4줄 chain → 가죽 끈 시계 탈락. ② 5줄 + c1 "after breakfast they swapped" → 김구는 윤봉길의 시계를 쥠. ③ 2줄 → 긁힘 없는 매끈한 시계.
- 대입 검사: old_watch는 chain 조건은 맞지만 교환 조건과 모순. strap_watch는 chain·"내 팔에 있다" 두 조건과 모순. new_watch만 둘 다 만족 → 정답 하나.
- 힌트: H1 "Read your first clue: what did the two men do after breakfast?" / H2 "After the swap, Mr. Kim has the other man's watch. What did Haesu say about Mr. Yun's watch?"(답을 말하지 않음, C10-5).
- successMessage "Mr. Kim opens his hand: the smooth new watch!"
- transition: "Mr. Kim opens his hand. The watch is smooth and new." / "Mr. Yun took the old, scratched one with him." / "\"But why?\" Haesu asks. \"Why give away a good new watch?\""
- talk.after(김구 "I gave him money for a good watch." …) 삭제. 김구는 M3에서 처음 입을 연다.
- discovery: 지금 detail "His new watch stays in Shanghai. Haesu wants to keep this morning safe." → **"His new watch stays with Mr. Kim. But why did they swap?"**(title "WHAT YUN LEFT BEHIND" 유지).
- 상태: c2 "The New Watch", e2 "Yun's New Watch"(내용 유지). 다음 이유: **왜** 바꿨는지 모른다. 이유가 없으면 기록의 세 번째 줄을 쓸 수 없다.

#### M3 One More Hour — 교체 (DROP 상자 자물쇠 삭제 → HOUR, 부드러운 문구)
- 목적: 교환의 이유를 아이가 시계 추론으로 찾는다. 『백범일지』의 "앞으로 한 시간밖에 쓸 데가 없다"를 쓴다.
- 유형: `word_entry` / null / `wordInput`. 정답 `HOUR`. acceptedAnswers `hour`, `ONE HOUR`, `AN HOUR`.
- 지금 M3(해수가 아우내에서 가져온 지키미 상자, 물방울 표시 = DROP)는 C08·시즌 상자에 기대므로 전부 지운다.
- story (R): "At last, Mr. Kim speaks, very softly." / "\"Before the swap, Yun looked at his new watch.\"" / "\"Then he said something I will never forget.\""
- letterIntro "Mr. Kim tells you:" / letter (R 7줄):
  1. Yun held up his new watch.
  2. He pointed at its long hand.
  3. "When this hand goes round one more time, I will not need a watch."
  4. "My watch is new, and yours is old. Let us swap."
  5. "I will need a watch for only one more ____."
  6. "You will need one for a long, long time."
  7. Then he took my old watch and gave me his.
- 이전 설계의 "I must be at the park"는 **뺐다**(실제 시각 관계를 지어내지 않고, 장소 언급 없이 부드럽게). 긴바늘 문장은 게임의 창작이며 IN THIS MYSTERY에 밝힌다.
- question: "What did Mr. Yun say? Write the missing word." / prompt: "I will need a watch for only one more ____."
- 8세 풀이: ① 3줄: 긴바늘이 **한 바퀴** 더 돌면 시계가 필요 없다. ② 긴바늘 한 바퀴 = 60분 = 1시간(초등 시계 읽기). ③ 5줄 빈칸 → HOUR.
- 대입 검사(feedback, R): MINUTE "One minute is one small step of the long hand. Yun said it goes round one whole time." / DAY "In one day, the long hand goes round many times. Yun said one time." / WEEK·YEAR "That is much longer. The long hand goes round one more time: how long is that?" / TIME "Close! Which word means one turn of the long hand?" 정답 표기는 HOUR / ONE HOUR / AN HOUR뿐.
- 힌트: H1 "Read Yun's words: the long hand goes round one more time." / H2 "When the long hand goes round once, sixty minutes pass. What do we call sixty minutes?"
- successMessage "One more hour. After that, Yun would not need a watch."
- transition: "Mr. Kim closes his eyes. \"He knew he might not come back.\"" / "\"So he gave the good watch to me.\"" / "Haesu writes it all down, line by line."
- clue c3: title "The Keepers' Mark" → **"One More Hour"** / value "DROP" → **"ONE MORE HOUR"** / note → "Yun needed a watch for only one more hour. He gave Kim Gu the good one." / symbol `watch`.
- evidence e3(id 유지): "Haesu's Morning Note" → **"Yun's Words"** / icon `watch` / description "What Yun Bong-gil said at the swap: he would need a watch for only one more hour, and Kim Gu would need one for a long time." / inscription "I will need a watch for only one more hour."
- clueInputs: `s5_ep10_e1` textMention → **`s5_ep10_c2` textMention**("Kim Gu holds Yun's new watch: why?").
- discovery: "ONE MORE NOTE IN THE BOX" / "The morning is kept. But what will this day mean for the government?" → **"WHY THEY SWAPPED" / "Yun gave his good watch away. Now Haesu can write her record."**
- 다음 이유: 해수의 기록 세 줄이 모두 사실인지 증명해야 정부 기록부에 들어간다.

### 11. Final에 쓰는 증거 (이 Case 증거만)
`s5_ep10_e1` Haesu's Kitchen Note(목격 기록), `s5_ep10_e2` Yun's New Watch(물건), `s5_ep10_e3` Yun's Words(말). 미끼 카드도 **이 셋 안에서만** 쓴다. 이전 설계의 `s5_ep09_e4`, `s5_ep09_e1` 미끼는 삭제.

### 12. Final — The True Record (`evidence_talk`, 정답 `why`)
- 유형: `evidence_talk` / engineTable `talks` / `examine`. answerSpec.answer `why`(마지막 present). placeId `s5_seoul.haesu_room`, location "HAESU'S ROOM" 유지(지도 테스트 영향 없음).
- 지금 Final(연도 1932 숫자 입력, 1919는 C09 사실 `s5_ep09_h1`)은 폐지. 1932는 Ending·reveal의 역사 문장에만 남는다(C10-2).
- story (R): "That night, Haesu reads her record to you by the lamp." / "\"Mr. Kim will sign it for the government's record book.\"" / "\"But first, show me the proof for each line.\""
- letterIntro "Haesu's record says:" / letter (R 3줄): "After breakfast, Mr. Yun and Mr. Kim swapped watches." / "The watch in Mr. Kim's hand is Mr. Yun's new watch." / "Mr. Yun needed a watch for only one more hour."
- question "Show Haesu the proof for each line of her record."
- interview(speaker `haesu`, portrait `characters/haesu.webp`, goal "Prove every line of Haesu's record.")
  - opening: Haesu "Mr. Kim asked me to write this morning down." / detective "Then let us make every line true."
  - questions(선택, 정보만): `book` "Who will read your record?" → Haesu "It goes into our government's record book." / Haesu "People must know what really happened today." (지금 이전 설계의 `keep` "My family keeps a box of water-drop notes." 대체)
  - presents (카드 3장 = 이 Case 증거 3개를 순서만 바꿔 제시. 엔진 2b2 필요. 정답 위치를 2·3·1번째로 흩음)

| id | prompt (R) | offered (화면 순서) | accepted | miss | tell(2회 오답) | 맞힌 뒤 | requires |
|---|---|---|---|---|---|---|---|
| `after` | Haesu asks: "Line one: they swapped after breakfast. Who saw it happen?" | e2, e1, e3 | s5_ep10_e1 | "That does not show who saw the swap." | "Read the note you put in order this morning." | D "Your own note, from the kitchen: breakfast first, then the swap." / H "Yes. I saw it with my own eyes." | — |
| `whose` | Haesu asks: "Line two: Mr. Kim holds Mr. Yun's watch. Show me that watch." | e3, e1, e2 | s5_ep10_e2 | "That is not a watch." | "Find the watch with no scratches." | D "The smooth new watch, with no scratches." / H "And Mr. Kim keeps it in his pocket." | after |
| `why` | Haesu asks: "Line three: why did Mr. Yun give his new watch away?" | e3, e2, e1 | s5_ep10_e3 | "That does not say why." | "Read what Mr. Kim told you Yun said." | D "He needed a watch for only one more hour." / H "Then that is the truest line of all." | whose |

  - finishWhen [after, whose, why], finishLabel "PUT IT IN THE BOX" → **"SIGN THE RECORD"**.
- 대입 검사(정답 하나): 세 카드는 종류가 다르다 — e1 = **목격자의 기록**(누가 봤나), e2 = **물건**(시계 자체), e3 = **말**(이유). `after`는 "누가 봤나" → 목격 기록만. e3은 교환을 말하지만 해수가 본 것이 아니고 식사 뒤라는 말도 없다. `whose`는 "그 시계를 보여 달라" → 물건만. e1·e3은 종이·말이라 시계가 아니다(e3이 '새 시계를 줬다'를 암시해도 '보여 줄 시계'가 아님). `why`는 이유 → e3만. e2는 결과, e1은 순서. 같은 증거가 두 present에서 받아지지 않는다(겹침 규칙 `play_check.dart:857-863` 해당 없음).
- 힌트(엔진 2b1): H1 "Show one piece of evidence for each line. All three are in your notebook from this morning." / H2 "Who saw it? Which watch? Why? Haesu's note, the smooth watch, and Yun's words."
- successMessage "Haesu's record is true!"
- transition(지금 "closes the box with its small water-drop lock" / "Bitna will read this one day… My daughter." / "My cousin Miri will take the box home to Seoul." 전부 교체): "Haesu signs her record. Mr. Kim reads it, and signs it too." / "\"Now it goes into the government's record book,\" she says." / "Mr. Kim looks at the watch, then out of the window."
- evidence e4(id 유지): "Haesu's Page: After That Day" → **"Haesu's Record of the Morning"** / icon `letter` / description "Haesu's true record of 29 April 1932, signed by Kim Gu: the swap, the new watch, and Yun's words." / inscription "After breakfast, Mr. Yun and Mr. Kim swapped watches."
- clueInputs: c2·c3 textMention → **c1·c2·c3 answerDerivation**.
- 엔진 없이 하려면(2b2 미적용): 카드 2장 — after [e2, e1], whose [e2, e3]→정답 앞 위치 피하려 [e3, e2], why [e1, e3]. 대입 결과 같음.

### 13. Ending (Intro 문제 해결: 기록이 사실로 완성되고 김구가 입을 염)
- Kim Gu: "His watch still ticks, Haesu. I will not forget him."
- Haesu: "Our box will not forget him either." → **"Our record will not forget him either."**
- narr (evidence s5_ep10_e2): "On 29 April 1932, Yun Bong-gil acted at a Japanese army event in Hongkou Park."
- narr: "He was caught at once. He died in Japan that December."(C10-8)
- narr: "After that day, Chinese leaders helped the Provisional Government strongly."
- Haesu: "One day, children in Korea will read this."(이전 설계 "my child"도 빛나 암시라 일반 문장으로)
- caseSummary (R): "On the morning of 29 April 1932, Yun Bong-gil and Kim Gu ate breakfast, then swapped watches. Yun said he would need a watch for only one more hour, so he left his new watch with Kim Gu. Haesu wrote the true record for the Provisional Government, and Kim Gu signed it. That day Yun acted at Hongkou Park and was caught. After it, Chinese leaders helped the Provisional Government strongly."

### 14. 역사·사실/창작
- 배우는 것: 1910년부터의 일본 지배, 1919년 상하이 임시정부, 김구, 1932.4.29 시계 교환과 그 이유(『백범일지』), 의거·체포·사형, 이후 중국의 임시정부 지원.
- reveal realHistory: 지금 4줄 유지 + 맨 앞에 1줄 추가(R) "Japan ruled Korea from 1910. In 1919, Korean leaders set up the Provisional Government in Shanghai." + 교환 줄 뒤에 1줄 추가(R) "Kim Gu wrote that Yun said his watch would be needed for only one more hour."
- inThisMystery: "Haesu, her notes and the keepers' box are made up." → **R "Haesu, her note, her drawings and her record are made up."** / J "Haesu, her note, her drawings and her record were invented for this case." / M "Haesu, her note, her drawings and her record are inventions of this story." + 새 줄 R "The words about the long hand are the game's." 둘째 줄(실존 인물, 말은 창작) 유지. 단, Yun의 "one more hour" 말은 김구 기록에 근거한다고 위 realHistory에 있으므로 둘째 줄 끝을 "…but most of their words in this story are made up."으로 고친다.
- dossier: fact 추가 `s5_ep10_h5`(1910 지배·1919 상하이 임시정부·김구가 지도자), `s5_ep10_h6`(『백범일지』 시계 교환 대화, "한 시간") — 출처 확인 필요(`status` source_checked 전에는 생성기 게이트 확인). 퍼즐: m3 `fiction:true, DROP` → factIds [h6], answer HOUR, clues "one more time"·"one more ____"·"the long hand"; final factIds [h4,h1,**s5_ep09_h1**] → **[h2, h6]**(다른 Case 사실 참조 제거), answer `why`, clues "Who saw it happen?"·"Show me that watch."·"only one more hour". fiction 1번째 줄에서 "the keepers' box with its letter lock" 삭제, "her drawings and her record" 추가.

### 15. R/J/M 예시 (실제 단어 수)

| 위치 | ROOKIE | 단어 | JUNIOR | 단어 | MASTER | 단어 |
|---|---|---|---|---|---|---|
| Intro 1 | Spring, 1932. Japan has ruled Korea since 1910. | 8 | It is spring, 1932. Japan has ruled Korea since 1910. | 10 | It is the spring of 1932, and Korea has been under Japanese rule since 1910. | 15 |
| Intro 2 | So Korean leaders made a government in Shanghai, China: the Provisional Government. | 12 | So Korean leaders have set up a government in Shanghai, China, called the Provisional Government. | 15 | So Korean leaders have formed a government of their own in Shanghai, China: the Provisional Government. | 16 |
| Intro 6 | "Tonight I must write the government's record of this morning. Please help me get every line right." | 17 | "Tonight I have to write the government's record of this morning. Please help me get every line right." | 18 | "By tonight I must write the government's record of this morning. Help me make certain every line is right." | 19 |
| M2 letter 4 | I can see a chain between Mr. Kim's fingers. | 9 | I can see a chain between Mr. Kim's fingers. | 9 | A chain shows between Mr. Kim's fingers. | 7 |
| M3 letter 3 | "When this hand goes round one more time, I will not need a watch." | 14 | "When this hand has gone round one more time, I will not need a watch." | 15 | "Once this hand has gone round one more time, I shall have no need of a watch." | 17 |
| M3 letter 5 | "I will need a watch for only one more ____." | 9 | "I will need a watch for only one more ____." | 9 | "I shall need a watch for only one more ____." | 9 |
| Final whose | Haesu asks: "Line two: Mr. Kim holds Mr. Yun's watch. Show me that watch." | 14 | Haesu asks: "Line two says Mr. Kim is holding Mr. Yun's watch. Can you show me that watch?" | 18 | Haesu asks: "Line two claims Mr. Kim holds Mr. Yun's watch. Can you produce that very watch?" | 17 |
| Ending 4 | He was caught at once. He died in Japan that December. | 11 | He was caught at once, and he died in Japan that December. | 12 | He was arrested at once, and in December he was put to death in Japan. | 15 |

(M3 letter 3 R/J/M는 2·3줄을 나눈 뒤의 3줄만 셌다.) 세 레벨이 주는 정보(사람·물건·시각·숫자)는 같다. 레벨별 줄 수는 ROOKIE 키와 같다.
- Glossary 추가: `hour: 시간(한 시간)`, `minute: 분`, `hand: (시계) 바늘`, `chain: (시계) 줄`, `record: 기록`, `proof: 증거`, `ruled: 다스렸다(지배했다)`, `clerk: 서기`, `Provisional Government: 임시정부`. 삭제: `water-drop`, `twenty-ninth`, `thirty-two`, `attacked`(Final 편지가 사라짐. `s5_seoul_rookie_test` glossary 단언도 바꿈). `ceremony`·`arrested`는 reveal에 남으므로 유지.

### 16. 외부 의존 원장 (C10)

| # | 현재(데이터) 또는 이전 설계의 요소 | 위치 | 결정 | 정확한 대체 |
|---|---|---|---|---|
| 1 | clueInputs `s5_ep09_e4` recall + play.recall("Who is Haesu?" / "Find the police chief's note…") | m1 | 제거 | clueInputs `[]`, play.recall 삭제. 해수 소개는 Intro 5 |
| 2 | Intro "a guest of Kim Gu in Shanghai **again**" / "Haesu… **now** works close to him" | play.intro | Case 안에서 완결 | §4 Intro 6줄 |
| 3 | M1 "Under one bowl is a note with a small water drop." / letterIntro "The water-drop note says:" / 서명 "— a small water drop" | m1 | 제거(물방울은 이 사건에서 기능 없음) | "Haesu gives you her note…" / "Haesu's note says:" / "— Haesu" |
| 4 | e1 이름 "The Water-Drop Note (1932)", desc "…in Hangeul, with a small water drop" | m1 evidence | Case 안에서 완결 | "Haesu's Kitchen Note" / §M1 description |
| 5 | M3 "old wooden box from Aunae", letter lock DROP "our mark", "Every note in this box…", c3 "The Keepers' Mark", e3 "kept in the keepers' box", notes "as every water-drop note of the season shows" | m3 | 제거 | M3 HOUR 전체 교체(§M3) |
| 6 | discovery m2 "Haesu wants to keep this morning safe" / m3 "ONE MORE NOTE IN THE BOX" | s5Ep10Discoveries | Case 안에서 완결 | §M2·§M3 discovery |
| 7 | Final 연도 1932, dossier factIds `s5_ep09_h1`(C09 사실) | final | 제거 | Final evidence_talk, factIds [h2,h6] |
| 8 | Final transition "closes the box with its small water-drop lock" / "Bitna will read this one day… My daughter." / "My cousin Miri will take the box home to Seoul." | final | 제거 | "Haesu signs her record…" 3줄(§12) |
| 9 | Ending Haesu "Our box will not forget him either." | final.ending | Case 안에서 완결 | "Our record will not forget him either." |
| 10 | hook "The box goes home to Seoul. Who will keep it there?" | hook | 제거(다음 Case 예고) | "One watch, two men, and a morning no one must forget." |
| 11 | caseSummary "Haesu kept the story in the keepers' box." | play.caseSummary | Case 안에서 완결 | §13 caseSummary |
| 12 | reveal inThisMystery "…and the keepers' box are made up." | history | Case 안에서 완결 | §14 |
| 13 | dossier fiction "keepers' box with its letter lock" | history_dossier | 제거 | §14 |
| 14 | glossary `water-drop` | play.glossary | 제거 | — |
| 15 | plan notes "Haesu is the same keeper as Case 09 (one portrait, reused); Kim Gu's portrait is Case 09's" | notes | 유지(초상 파일 재사용은 사실) + 문구 수정 | "Haesu and Kim Gu use the season's shared portraits; Haesu's role is told inside this case." |
| 16 | evidenceLinks | s5Ep10EvidenceLinks | 유지 | 이미 `{}`(외부 링크 없음) |
| 17 | 이전 설계 Intro "A water-drop note finds you… You are in Shanghai again" | redesign_c10_12 | 제거 | §4 |
| 18 | 이전 설계 M1 "Haesu hands you a note with a small water drop" | 〃 | 제거 | §M1 story |
| 19 | 이전 설계 Final 미끼 `s5_ep09_e4`·`s5_ep09_e1` | 〃 | 제거 | 미끼 = 이 Case e1·e2·e3(§12 표) |
| 20 | 이전 설계 question `keep` "My family keeps a box of water-drop notes." | 〃 | 제거 | `book` 질문(정부 기록부) |
| 21 | 이전 설계 story "Before it goes in the box…", finishLabel "PUT IT IN THE BOX" | 〃 | 제거 | "Mr. Kim will sign it…", "SIGN THE RECORD" |
| 22 | 이전 설계 transition "adds a small water drop… on top of her note from 1920 (해수의 두 번째 쪽지)" / "My cousin Miri will take the box home to Seoul." | 〃 | 제거 | §12 transition |
| 23 | 이전 설계 e4 "…It went into the keepers' box." / inscription "Someone must remember…" | 〃 | Case 안에서 완결 | §12 e4 |
| 24 | 이전 설계 Ending "One day my child will read this." | 〃 | 변경 | "One day, children in Korea will read this." |
| 25 | story_bible cases[s5_ep10] fromPrevious "Haesu again; Kim Gu of Case 09 (s5_ep09_e4)" / toNext "The box goes back to Seoul with Haesu's cousin Miri." / solution "(the answer 1932)" | story_bible | 문서 정정 | fromPrevious "None: a standalone case." / toNext "None." / solution 정답을 "the record's three lines, proved with this case's evidence (answer why)"로 |
| 26 | story_bible characters haesu "keeper of Shanghai… keeps the true story in the box. Bitna's mother", relationships gyeongsun cousin; kim_gu "Trusts her after Case 09" | story_bible | 문서 정정 | haesu role "A clerk of the Provisional Government (made up)"; purpose "Case 09: …(그 Case 담당 문구) / Case 10: writes the government's record of 29 April 1932"; relationships 삭제; kim_gu 관계 "His clerk." |
| 27 | season.plan characters haesu "…and the keeper of Shanghai (made up)" | season.plan | 문서 정정 | "A clerk of the Provisional Government (made up)" |
| 28 | C11 M1 clueInputs `s5_ep10_e1` (C10 증거를 C11이 참조) | C11 | C11에서 제거 | C11 원장 #1 |

- 독립 검증 메모: 해수는 C09에도 나오지만(같은 이름·초상), C10은 해수를 Intro에서 새로 소개하고 C09 사건을 언급하지 않는다. C09를 하지 않은 플레이어도, 한 플레이어도 모순이 없다.

### 17. 독립성 검증

| 항목 | 이 Case만 본 새 플레이어 | 근거 |
|---|---|---|
| Intro 이해 | 된다 | 일본 지배·임시정부·김구·해수·윤봉길·문제(기록을 써야 함)를 Intro 1~6줄이 모두 말한다 |
| M1 풀기 | 된다 | 해수의 쪽지(화면)만으로 순서 결정 |
| M2 풀기 | 된다 | c1(M1) + 해수의 설명 5줄 + 그림 |
| M3 풀기 | 된다 | 김구가 전한 말 7줄 + 시계 상식 |
| Final 풀기 | 된다 | 카드 3장 모두 이 Case 증거(e1~e3) |
| Ending 이해 | 된다 | 기록 완성 + 역사 3줄. 다른 인물 이름 없음 |
| 남은 다른 Case 참조 | **없음** | recall·clueInputs·미끼·대사·hook·dossier factIds 모두 C10 안 |

### 18. 유지/변경 표

| 기존 문제·요소 | 처리 |
|---|---|
| C10-1 낡은 시계가 탁자에 있음(P1) | 변경: 쥔 손 + 해수의 그림 + chain |
| C10-2 Final = 연도 1932 | 변경: 기록 증명 evidence_talk(이 Case 증거만) |
| C10-3 M3 DROP | 삭제 → HOUR |
| C10-4 교환 이유 없음 | 변경: M3 『백범일지』 "한 시간" |
| C10-5 M2 힌트2 답 공개 | 변경 |
| C10-6 orderFeedback | 변경 |
| C10-7 "the last word" | M3 삭제로 소멸 |
| C10-8 죽음 서술 | 변경: Ending 한 줄 |
| I-12 빛나 나이 | 변경: "children in Korea" |
| C09 recall·미끼, 상자, 물방울, 미리, 빛나 | 제거(원장) |
| M1 순서 퍼즐, M2 그림 3장, 장소·지도 핀 | 유지 |

### 19. 인과관계 표

| 단계 | 필요 이유 | 이 Case에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 해수는 오늘 밤 기록을 써야 하는데 김구가 말을 안 함 | — | 읽기 | 질문: 무엇이·누구의 시계·왜 | 해수의 섞인 쪽지 |
| M1 | 교환 시점을 알아야 함 | 해수의 쪽지 | 순서 배열 | c1 식사 뒤 교환 / e1 | 쥔 시계는 누구 것? |
| M2 | 기록 2줄 | c1 + 해수의 그림·설명 | 그림 고르기 | 손을 폄: 새 시계 / e2 | 왜 좋은 시계를 줬나? |
| M3 | 기록 3줄 | 김구가 전한 윤봉길의 말 | 시계 추론 → HOUR | e3 Yun's Words | 기록을 증명해야 서명 |
| Final | 기록 검증 | e1·e2·e3 | 줄마다 증거 제시 | 기록 완성·김구 서명 / e4 | Ending |
| Ending | Intro 문제 해결 | — | 읽기 | 1932 의거·체포·중국 지원 | (없음) |

### 20. 시뮬레이션 (설계 검토, 실제 어린이 테스트 아님)
- 8세 R Intro: "Provisional Government"가 어렵다 → glossary `임시정부`, 2줄이 "Korean leaders made a government"로 먼저 쉬운 말을 준다.
- M2: chain을 모르면 glossary, 그림의 줄로도 판단. strap 오답 피드백이 이유 두 개를 말한다.
- M3: MINUTE이 가장 흔한 오답으로 예상, 맞춤 피드백 있음. "long hand"는 `hand` glossary와 H2.
- Final: `whose`에서 e3(말)을 고를 수 있다 → miss "That is not a watch." 두 번 틀리면 tell. 3회부터 빛남(2b3).
- 막힐 곳: Intro 6줄이 길다(R 최대 19단어: 5줄). 위험 낮음~중.

### 21. ID·저장 영향
- id 전부 유지: m1~m3, final, c1~c3, e1~e4. 내용이 바뀌는 것: e1 이름·설명, c2 note(그대로 가능), c3, e3, e4, discoveries m2·m3.
- 유형 변화: m3 letterLock → wordInput, final numberCode → examine(evidence_talk). 둘 다 퍼즐 상태를 저장하지 않던 엔진이라 남는 상태가 없다. 새 키 `s5_ep10_final:talk`는 처음부터. 완료 기록은 id 기준이라 유지. 산 힌트 `tip:s5_ep10_m3:n`은 새 힌트에 그대로 적용(무해).
- 증거는 콘텐츠에서 다시 계산되므로 이미 푼 사람의 수첩에도 새 이름이 보인다(의도).
- C11이 참조하던 `s5_ep10_e1`은 C11 정정으로 참조가 사라진다. `s5_ep10_e4`를 참조하는 다른 Case 없음(이전 설계의 C11 미끼는 삭제).
- story_bible clueThreads #22(`s5_ep09_e4`→`s5_ep10_m1`) 삭제, #26(c1→m2) 유지, 새 스레드: c2→m3("Kim Gu holds the new watch: why?"), e1·e2·e3→final("each line's proof").

### 22. 엔진 변경
- 2b2(present당 카드 3장) 필요, 2b1(대화 Final 힌트) 권장, 2b3(2회 오답 tell) 권장. 2b2 없이는 §12 끝의 2장안으로 지금 코드에서 된다. 이 Case만을 위한 추가 엔진 변경 없음.

### 23. 이미지
- 새 그림 없음. `old_watch`·`new_watch`·`strap_watch`를 "해수의 그림"으로 재사용(altText만 변경). breakfast_room·haesu_room 그림에 물방울이나 상자 이야기를 요구하는 요소 없음(탁자 옆 나무 상자는 배경 소품이며 대사로 언급하지 않는다). Final 초상 `haesu.webp`.

### 24. 작업량: **M**
- 파일: `s5_ep10/case.plan.json`, `s5_ep10/levels.json`, `planning/history_dossier.json`(h5·h6 추가, m3·final 퍼즐, fiction), 재생성 `s5_ep10.g.dart`·`s5_ep10_levels.g.dart`·`s5_seoul_history.g.dart`·manifest, `test/sandbox/s5_seoul_rookie_test.dart`(C10 F `nineteen thirty-two`·1919/0429 → 새 Final 의도로, glossary `attacked` 단언 교체), `story_bible.json`·`season.plan.json`(문서 정정).

### 25. 위험
- 『백범일지』 h6 출처 확인 전에는 dossier 게이트가 막을 수 있다 → 출처(국사편찬위원회 우리역사넷 또는 『백범일지』 판본)를 붙인다.
- "He knew he might not come back"이 8세에게 무거울 수 있다 → 무기·폭발 묘사 없음. 다른 Case 사망 서술과 수위가 같다.
- Intro가 4줄 → 6줄로 길어진다(배경 설명 때문에 불가피). R 최대 19단어(5줄: 해수 소개 + 문제). 너무 길면 5줄을 "Then Haesu, Kim Gu's clerk, runs to you." / "\"Mr. Kim holds a watch. He will not say a word.\""로 나눠 7줄로 한다.
- evidence_talk가 시즌에 많다(C01·C04·C07·C09) → 이번 틀은 "기록 검증 + 카드 종류(목격·물건·말) 구분"으로 다르다.

---

## Case 11 — The Poet's Three Copies

### 1. 제목·역사 배경
- 제목 유지: **The Poet's Three Copies**.
- 배경: 1941년 늦가을, 서울 연희전문학교. 일본이 한국을 지배하고, 1938년(제3차 조선교육령)부터 학교에서 조선어는 선택 과목이 되어 수업이 크게 줄었고 학교는 일본어로 가르쳤다. 연희전문 학생 윤동주는 졸업을 앞두고 시 19편(18편 + 서시)을 골라 시집 『하늘과 바람과 별과 시』를 내려 했지만 출판하지 못했다. 그래서 손으로 세 부를 베껴 이양하 교수, 후배 정병욱, 자기에게 한 부씩 두었다. 정병욱 집안은 사본을 마루 밑에 숨겼고, 1948년 시집이 나왔다.
- **이 Case 안에서 설명하는 배경**: 일본의 지배, 학교에서 한국어가 밀려남(Intro 1~2), 윤동주가 누구인지·연희전문(Intro 3~4), 시를 한국어로 썼다는 것(Intro 4), 사본 세 부(Intro 5). 미리가 누구인지(M1 편지 + Final 대화).

### 2. 독립 사건 목표 (한 문장)
윤동주가 친구에게 줄 사본이 책상에서 사라졌다. **새벽에 친구가 오기 전에** 사본을 찾아 친구에게 건넨다.

### 3. 인물 동기 (모두 이 Case 안에서 밝혀짐)
- **윤동주**(실존, 대사 창작): 출판할 수 없는 시를 친구에게 맡겨 지키고 싶다.
- **미리**(창작): 매일 아침 기숙사 방에 물을 날라 주며 학교 일을 돕는 젊은 여성(연희전문은 남학교였으므로 학생이라 부르지 않는다). 오늘 밤 사무실 사람이 방을 검사한다는 말을 들었다. 한국어 원고가 나오면 학생이 곤란해질 수 있어서, 윤이 없는 사이 사본을 **자기 작은 나무 상자**에 넣어 강당 피아노 안에 숨겼다. 상자의 번호 자물쇠는 **윤이 직접 쓴 목록의 숫자**로 맞췄다(윤만 열 수 있게). 남긴 카드는 윤의 목록을 그대로 베끼고 한 줄만 바꿔 위치를 알렸다(남이 읽으면 그냥 목록으로 보이게). 이름 대신 **물방울**로 서명했다: 물을 나르는 사람이라서, 그리고 사무실 사람이 누가 썼는지 모르게 하려고. → Final 대화에서 미리가 직접 말한다.
- **사무실 직원**(창작, 이름 없음): 등불과 문 열쇠 꾸러미를 들고 강당을 지난다. 긴장 역할만.
- **지키미·해수의 사촌·집안 상자·충칭의 빛나와의 관계는 모두 지운다.**

### 4. Intro (ROOKIE 전문, 7줄 — 지금 5줄, R/J/M 같은 줄 수)
1. Late autumn, 1941. Japan rules Korea.
2. Schools must teach in Japanese now. Korean lessons are pushed out.
3. At Yonhi College in Seoul, you are the guest of a young poet, Yun Dong-ju.
4. He writes his poems in Korean.
5. He could not print his book. So he copied it by hand, three times.
6. Tonight the copy for his friend is gone. His friend comes for it at dawn.
7. "Please help me find it," Yun says.

- synopsis: "A young poet copied his book of poems by hand, three times." / "Tonight the copy for his friend is gone. His friend comes for it at dawn."
- goal: "Find the copy Yun Dong-ju made for his friend, and give it to his friend at dawn."
- objectives: "Search Yun's desk." / "Compare the card with Yun's list." / "Find the keys of black and white." / "Open the box and give the copy to Yun's friend."
- hook 유지: "A man from the office checks the rooms tonight."(이 Case 안의 긴장. 화면 비표시 데이터)
- learningGoal 유지("Reading lists, numbers and a language's story").

### 5~10. Mission

#### M1 The Desk by the Window — 유지 (물방울을 이 Case 안에서 설명, 윤의 사전 지식 제거)
- 목적: 사본이 있던 자리에서 첫 증거(미리의 카드)를 찾고, 카드의 서명으로 누가 가져갔는지 안다.
- 유형: `lens_inspect_word` / `inspections` / `wordInput`. 정답 `WATER`(accepted `water`). 렌즈 지점·좌표(dorm_room.webp) 그대로.
- talk.before(윤 3줄: 세 부를 베꼈다 / 선생님·친구·나 / "Then let us look at your desk.") 유지.
- story (R): "Yun Dong-ju lights his lamp." / "\"My friend's copy had a white string. Now it is gone,\" he says." / "Someone moved the dictionary." (지금 3줄째 "Nothing is written on the dictionary's cover. But someone moved it."는 줄인다)
- letterIntro "Yun tells you:" / letter (R 4줄):
  1. Someone moved my dictionary. It is the thick book with a red spine.
  2. My friend's copy was next to it, tied with a white string.
  3. Only Miri came in tonight. She brings water to our rooms.
  4. Please look at the desk. I have not touched anything.
  - 지금의 "Something small is under the dictionary now. / The blue spot on it is not ink. It is a drop of ____."는 지운다(윤이 아직 보지 못한 것을 말하던 문제 C11-4).
- spot 반응(찾은 **뒤**): `note` "A folded card. A small blue drop is drawn in its corner." / `ink` "Blue ink. But the drop on the card is drawn, not spilled." 나머지 spot 줄 유지.
- question "Find what is under the dictionary. Write the missing word." / prompt **"The card is signed with a drop of ____."**
- 화면 단서: 붉은 책등의 두꺼운 책 → 그 밑 카드 → 그려진 파란 방울(잉크 아님) + "Only Miri came in… She brings water to our rooms."
- 8세 풀이: ① 붉은 책등 책을 찾는다. ② 밑의 카드를 연다. ③ 방울은 잉크가 아니라 그린 것. ④ 오늘 밤 들어온 사람은 물을 나르는 미리뿐 → 물방울 → WATER.
- 대입 검사: INK — 잉크병 spot 문장이 "drawn, not spilled"로 배제. RAIN — 방에 비가 들어오지 않았고 미리가 나르는 것은 water. TEA·MILK 등 — 미리는 water를 나른다. 정답 WATER 하나.
- 힌트: H1 "Find the thick book with a red spine, then look under it." / H2 "Who came in tonight? What does she bring to the rooms?"(지금 H2 "What did Bun-i carry in her bucket?" 대체)
- 오답: INK "The drop is drawn, not spilled ink. Who came in tonight, and what does she bring?" / RAIN "Rain did not come into the room. What does Miri bring?" / orderFeedback "Not that word. Read Yun's words about Miri again."(지금 "What did Bun-i carry from the well?" 대체)
- successMessage "A drop of water: Miri's sign!"(지금 "…the keepers' mark!")
- transition: "Yun looks at the card. \"Miri signs her notes with a water drop. She took my friend's copy!\"" / "\"But why? And where is it now?\"" / "The card looks just like a list. Maybe it tells us where."
- 상태: c1 title "The Keeper's Drop" → **"Miri's Sign"** / value "WATER" / note "Miri signs her notes with a water drop. Her card was under the dictionary." e1 이름 "The Water-Drop Note (1941)" → **"Miri's Card"** / description "A folded card with a small blue water drop, Miri's sign. It was under Yun's dictionary."
- clueInputs: `s5_ep10_e1` textMention, `s5_ep01_c1` textMention → **삭제(빈 배열)**.
- discovery: "A WATER-DROP NOTE" / "A keeper has been here. The note is in the King's letters." → **"MIRI'S CARD" / "Miri took the copy. Her card may tell where it is."**
- 다음 필요 이유: 사본이 어디 있는지 카드가 말해 줄 수 있다.

#### M2 Yun's List — 유지 (외부 표현과 추리 대신하기만 제거)
- 유형: `record_mismatch` / `records` / `matchPairs`. 정답 `string:string`. 기록지 그림·좌표 유지.
- story (R): "You open Miri's card. Yun reads it to you in English, line by line." / "Yun takes a paper from his drawer. \"This is my list of the copies.\"" / "\"The card looks just like my list,\" he says. \"Why?\""
- letter 유지(5줄: This list is for my friend's copy. / The card says the same things, line by line. / But one line on the card is not true. / Maybe that line is a message. / Read the card's last words too.).
- records.second: name "THE WATER-DROP CARD" → **"MIRI'S CARD"**, label "The keeper's card, with a small blue water drop in its corner" → **"Miri's card, with a small blue water drop in its corner"**, title "YOUR FRIEND'S COPY" → **"MY FRIEND'S COPY"**(C11-7). note "It is safe under keys of these colours." 유지.
- 8세 풀이·대입 검사 현행 유지: 네 줄 중 string만 다름. M1에서 윤이 "white string"이라 했으므로 카드 줄이 거짓.
- 힌트 유지(H2 "What colour is the string on his friend's copy? Yun told you in his room." — M1 편지 2줄에 있음).
- transition (R): "\"My friend's string is white, not black and white,\" Yun says." / "\"So that line is a message.\"" / "The card's last words: safe under keys of these colours. Keys of black and white?"(지금의 "Black and white keys!" / "Something in the college hall has keys like that"는 삭제, C11-1)
- clue c2: value "BLACK AND WHITE KEYS" → "BLACK AND WHITE · KEYS" / note 유지.
- e2 "Yun's List of Copies" 유지(description: copy 2 of 3, 18 + 1 opening poem, a white string).
- discovery 추가(m2): "THE CARD'S MESSAGE" / "Keys of black and white. Where are keys like that?"
- 다음 이유: 그런 'keys'가 있는 곳을 찾아야 한다.

#### M3 Keys of Black and White — 교체 (PIANO 추론, 319는 Final로)
- 목적: "keys"의 두 뜻(열쇠/건반)과 색 조건으로 숨긴 곳을 추론한다.
- 유형: `word_entry` / null / `wordInput`. 정답 `PIANO`(accepted `piano`, `THE PIANO`, `PIANO KEYS`). placeId `s5_seoul.c11_college_hall`, location "THE COLLEGE HALL" 유지.
- story (R): "You hurry to the college hall with Yun." / "Students sit on the benches. A man with a lantern walks between them." / "His ring of door keys jingles. \"That man is from the office,\" Yun whispers."
- letterIntro "You think it through:" / letter (R 6줄): "The card says the copy is safe under keys of these colours." / "Its untrue line says: BLACK AND WHITE." / "In this hall: a ring of door keys, all black." / "Students in black jackets and white shirts. They have no keys." / "And an old piano by the stage." / "What has keys of black and white?"
- question "Where is the copy hidden? Write the thing's name." / prompt "The copy is safe in the ____."
- 8세 풀이: ① M2: 색 = 검정·흰색, 물건에 keys. ② 문 열쇠: keys지만 모두 검정 → 탈락. ③ 학생 옷: 색은 맞지만 keys 없음 → 탈락. ④ 피아노: 검은 건반·흰 건반 → 둘 다 만족. glossary `keys: 열쇠; (피아노) 건반`.
- 대입 검사(feedback R): KEYS/DOORKEYS/KEY "Door keys are keys, but they are all black." / JACKET/SHIRT/STUDENTS/CLOTHES "Black and white, yes. But clothes have no keys." / LANTERN/BENCH/STAGE "That has no keys of black and white." 정답 PIANO 계열뿐.
- 힌트: H1 "Read the card's untrue line for the colours. Then read its last words." / H2 "A key can open a door. Some keys make music. Which thing here has them?"
- successMessage "The piano! Its keys are black and white."
- transition (R): "When the man leaves, you lift the piano's top." / "Inside lies a small wooden box with a number lock." / "Miri runs in. \"Wait! He may come back. Come outside, quick!\""(지금 "letter box…" / "I am Miri, Haesu's cousin." 대체)
- talk.before(미리: "I wrote the card…" / "Papers in Korean…" / detective "So you hid it with your family's notes.")는 **M3에서 삭제** → Final talk로 옮겨 고침.
- recall(`s5_ep11_e2`, "Yun's List")은 M3에서 삭제 → Final present로.
- clue c3: "The Lock" / "3 · 19" → **"The Piano" / "INSIDE THE PIANO" / note "The keys of black and white were the piano's. Miri's box was inside."**
- evidence e3(id 유지): "The Friend's Copy" → **"The Box in the Piano"** / icon `key` / description "Miri's small wooden box, hidden inside the college piano, with a number lock."
- clueInputs: `s5_ep11_c2` textMention + `s5_ep11_e2` recall → **`s5_ep11_c2` answerDerivation** 하나.
- discovery: "THE FRIEND'S COPY" / "The copy is safe. Now it must reach Yun's friend." → **"THE BOX IN THE PIANO" / "The copy is locked inside. Dawn is coming."**(showEvidence 유지)
- 다음 이유: 상자가 잠겨 있고 새벽에 친구가 온다.

### 11. Final에 쓰는 증거 (이 Case 증거만)
`s5_ep11_e2` Yun's List(present로 받음, 숫자의 출처), `s5_ep11_e3` The Box in the Piano(미끼), `s5_ep11_e1` Miri's Card(미끼), c2·c3. 이전 설계의 미끼 `s5_ep10_e4` 삭제.

### 12. Final — The Lock at the Gate (2단계: 대화 → 번호 자물쇠 **319**, KOREAN 폐지)
- 유형: `number_entry` / null / `numberCode`, codeLength 3. 앞에 `play.talk.before`(speaker `miri`) + present 1개(C01 V4와 같은 talkMissions 패턴). placeId `s5_seoul.c11_college_gate`, location "THE COLLEGE GATE" 유지.
- story (R): "Dawn comes over the stone college buildings." / "Miri sets her box on the gate's stone step." / "\"My friend comes at sunrise,\" Yun says. \"Quick!\""
- talk.before (Miri, portrait `characters/miri.webp`, goal "Find out why Miri took the copy.")
  - lines: Miri "I took it. I am sorry I scared you." / Miri "A man from the office is checking the rooms tonight." / Miri "Papers in Korean can get a student in trouble now." / Miri "I bring water to the rooms every morning, so I sign my notes with a water drop." / Miri "I did not write my name. The office man must not know who wrote it." / detective "And your card looked like Yun's list, so only Yun could read the message."
  - present `list`: prompt "Miri asks: \"I set my lock with numbers from the paper in Yun's own hand. Show me that paper.\"" / offered **[s5_ep11_e1, s5_ep11_e3, s5_ep11_e2]** / accepted [s5_ep11_e2] / miss "That is not in Yun's own hand." / tell "Find the paper from Yun's drawer." / lines: detective "Yun's list: copy 2 of 3, and 18 + 1 opening poem." / Miri "Then you can open it."
  - 대입 검사: e1(미리의 카드)도 같은 숫자를 베꼈지만 "Yun's own hand"가 아니다(미리가 썼다고 방금 말함). e3는 종이가 아니다. → e2 하나.
- letterIntro "Miri and Yun tell you:" / letter (**R·J·M 모두 4줄, 정보 같음** — C11-3 해소. 동기 문장은 위 대화로 옮겼으므로 편지는 자물쇠 규칙만):
  1. Miri: "My lock wants two numbers from Yun's list, side by side."
  2. "First: the number of copies. Then: the poems in each copy."
  3. "Like this: 2 copies and 15 poems is 215."
  4. Yun: "My list says copy 2 of 3, and 18 + 1 opening poem."
- question "Put in the lock's number."
- 8세 풀이: ① 앞자리 = 사본 수. "copy 2 of 3"에서 전체 3. ② 뒷자리 = 한 부의 시: 18 + 1 = 19. ③ 예시(2와 15 → 215)처럼 붙인다 → 319.
- 대입 검사(feedback): 119 "Count the copies again: Yun made more than one." / 219 "Copy 2 is the friend's copy. How many copies are there in all?" / 318 "18 poems + 1 opening poem: add them." / 215 "That is Miri's example, not Yun's list." / 193·931 → orderFeedback "The right numbers, in the wrong order. The copies come first." 3자리 휠이라 길이 고정. 두 조건을 만족하는 값은 319 하나.
- 힌트: H1 "Find the number of copies in all, then the poems in each copy." / H2 "18 poems + 1 opening poem: add them."
- successMessage "Click! The box opens."
- transition: "Inside lies a thin book with a white string." / "\"My friend's copy,\" Yun whispers. Its pages are in Korean." / "A young man comes up the path. It is Jeong Byeong-uk."(지금 "Weeks later, Miri sends the old letter box far away. / It goes to Haesu's family, in Chongqing. / One more note will be written in it." 전부 삭제)
- evidence e4(id·이름 유지 "Poems in Korean"): description "Yun Dong-ju's poems in Korean, copied by hand. He gave this copy to his friend at dawn; in 1948 his poems became a book." / inscription "Sky, Wind, Stars and Poems".
- clueInputs: c3·c2 answerDerivation 유지 + **`s5_ep11_e2` evidenceLink**(present).
- learning.objective: "copy 2 of 3, 18 + 1 opening poem을 읽고 계산해 자물쇠 번호 319를 넣는다." expressions "opening poem", "side by side".

### 13. Ending (Intro 문제 해결: 사본이 새벽에 친구 손으로)
- narr: "Yun gives the copy to his young friend, Jeong Byeong-uk."
- Yun: "Keep it safe. It is in our own words." → **"Keep it safe. It is in our own language."**
- narr (evidence s5_ep11_e4): "From 1938, Korean was pushed out of the schools."
- narr: "Yun Dong-ju still wrote his poems in Korean."
- narr: "His friend's family hid the copy under their floor."
- narr: "In 1948, his poems became a book: Sky, Wind, Stars and Poems."(지금 "it became a book" → 초판 31편과 어긋나지 않게)
- Miri "Where will our old letter box go now?" → **Yun: "Thank you, Miri. You kept my words safe."**
- caseSummary (R): "Miri, who brings water to the college rooms, hid Yun Dong-ju's copy for his friend in her box inside the college piano, because a man from the office was checking the rooms. Her card, signed with a water drop, pointed to keys of black and white. At dawn the box opened with the numbers on Yun's list, and Yun gave the copy to his friend. Yun wrote his poems in Korean when Korean was pushed out of the schools. In 1948 they became a book."

### 14. 역사·사실/창작
- 배우는 것: 1938년 이후 학교에서 한국어가 밀려남, 윤동주·연희전문, 시 19편(18 + 서시), 손으로 쓴 사본 3부, 정병욱 집안의 보관, 1948년 시집.
- reveal: realHistory 5줄 유지(옥사는 reveal에만, Ending에 넣지 않음). 4번째 줄 "In 1948 it became a book." → R "In 1948 his poems became a book." (J/M 같은 방향).
- inThisMystery 유지("Miri, her card, Yun's list, the piano, the lock and that night are made up." / "Yun Dong-ju was real, but his words…").
- dossier: m1 derivation에서 "what Bun-i carried (Case 01)" 삭제 → "The drop on Miri's card is drawn, not ink; only Miri, who brings water to the rooms, came in: WATER, her sign." clues "red spine", "drawn, not spilled", "brings water". whyOnly "INK by 'drawn, not spilled'; RAIN by 'brings water'." / m3 → `fiction:true`, answer PIANO, clues "keys of these colours", "all black", "They have no keys.", whyOnly 위 대입 / final → factIds [h2,h3], answer 319, clues "2 of 3", "18 + 1 opening poem", derivation(지금 m3의 것 이동, "recalled here" → "shown to Miri") / fiction 마지막 줄 "The keepers' letter box and its old notes (from 1446 on) are the season's fiction." → **"Miri's small wooden box, its number lock and her water-drop sign are made up."**, fiction 2번째 줄 "her water-drop card" 유지.

### 15. R/J/M 예시 (실제 단어 수)

| 위치 | ROOKIE | 단어 | JUNIOR | 단어 | MASTER | 단어 |
|---|---|---|---|---|---|---|
| Intro 1 | Late autumn, 1941. Japan rules Korea. | 6 | It is late autumn, 1941, and Japan rules Korea. | 9 | It is late autumn, 1941, and Korea is under Japanese rule. | 11 |
| Intro 2 | Schools must teach in Japanese now. Korean lessons are pushed out. | 11 | Schools have to teach in Japanese now, and Korean lessons are being pushed out. | 14 | Schools are now made to teach in Japanese, and Korean lessons are being pushed aside. | 15 |
| Intro 3 | At Yonhi College in Seoul, you are the guest of a young poet, Yun Dong-ju. | 15 | At Yonhi College in Seoul, you are the guest of a young poet named Yun Dong-ju. | 16 | At Yonhi College in Seoul, you are staying as the guest of a young poet, Yun Dong-ju. | 17 |
| Intro 5 | He could not print his book. So he copied it by hand, three times. | 14 | His book could not be printed, so he copied it by hand three times. | 14 | Unable to print his book, he has copied it out by hand three times. | 14 |
| M1 letter 3 | Only Miri came in tonight. She brings water to our rooms. | 11 | Only Miri came in tonight. She is the one who brings water to our rooms. | 15 | No one but Miri came in tonight; she carries water to our rooms. | 13 |
| M3 letter 3 | In this hall: a ring of door keys, all black. | 10 | In this hall there is a ring of door keys, all of them black. | 14 | In this hall hangs a ring of door keys, every one of them black. | 14 |
| M3 letter 6 | What has keys of black and white? | 7 | What has keys that are black and white? | 8 | What here has keys of black and white? | 8 |
| Final talk (sign) | "I bring water to the rooms every morning, so I sign my notes with a water drop." | 17 | (J) "I bring water to the rooms every morning, so I sign my notes with a little water drop." | 18 | (M) "Each morning I carry water to the rooms, so I sign my notes with a water drop." | 17 |
| Final letter 1 | Miri: "My lock wants two numbers from Yun's list, side by side." | 12 | Miri: "My lock needs two numbers from Yun's list, put side by side." | 13 | Miri: "My lock takes two numbers from Yun's list, placed side by side." | 13 |
| Ending 7 | Thank you, Miri. You kept my words safe. | 8 | Thank you, Miri. You have kept my words safe. | 9 | Thank you, Miri. You have kept my words safe tonight. | 10 |

(모든 칸을 같은 스크립트 규칙으로 셌다.) 세 레벨 정보 같음, 줄 수 같음.
- Glossary 추가: `keys: 열쇠; (피아노) 건반`, `lantern: 등불`, `jingles: 짤랑거리다`, `lock: 자물쇠`, `sign: 서명(하다)`, `lessons: 수업`. 유지: `choice`(reveal "choice subject"가 남으므로, `s5_seoul_rookie_test` glossary 단언도 유지), `water-drop`(미리의 서명으로 이 Case 안에서 쓰임). 삭제 없음.

### 16. 외부 의존 원장 (C11)

| # | 현재 또는 이전 설계의 요소 | 위치 | 결정 | 정확한 대체 |
|---|---|---|---|---|
| 1 | clueInputs `s5_ep10_e1` textMention("Haesu's water-drop note") | m1 | 제거 | m1 clueInputs `[]` |
| 2 | clueInputs `s5_ep01_c1` textMention("Bun-i… her bucket") | m1 | 제거 | 〃 |
| 3 | H2 "The blue spot is not ink. What did Bun-i carry in her bucket?" | m1 hints | Case 안에서 완결 | "Who came in tonight? What does she bring to the rooms?" |
| 4 | feedback RAIN "…what Bun-i carried in her bucket." / orderFeedback "What did Bun-i carry from the well?" | m1 | Case 안에서 완결 | §M1 오답 |
| 5 | 물방울 = 지키미 집안 표시("the keepers' mark", "Haesu's notes had the same drop", "A keeper took the copy") | m1 success/transition/c1 | **Case 안에서 완결**(카드 그림 c11_drop_card에 방울이 그려져 있어 단서로 유지) | 미리가 물을 나르기 때문에 그리는 서명, 이름을 숨기려고. M1 편지 3줄 + Final 대화 2줄 |
| 6 | "card in the King's letters", e1 "in the King's letters", discovery "The note is in the King's letters" (C01의 세종 글자 지식) | m1 | 제거 | "Yun reads it to you in English"(M2), e1 §M1 |
| 7 | e1 이름 "The Water-Drop Note (1941)"(시즌 연도 붙은 쪽지 시리즈) | m1 | Case 안에서 완결 | "Miri's Card" |
| 8 | records.second "THE WATER-DROP CARD" / "The keeper's card" | m2 | Case 안에서 완결 | "MIRI'S CARD" / "Miri's card, …" |
| 9 | M3 "I am Miri, Haesu's cousin." | m3 story | 제거 | Miri는 M1에서 소개됨. "Miri runs in. \"Wait! He may come back…\"" |
| 10 | M3 "letter box", "Under old notes with water drops lies a thin book", talk "So you hid it with your family's notes." | m3 | 제거 | "small wooden box", Final transition "Inside lies a thin book…" |
| 11 | e3 "Its pages are in the King's letters." / transition "pages are in the King's letters" | m3 | 제거 | e3 = The Box in the Piano; "Its pages are in Korean." |
| 12 | Final letter "King Sejong made his letters for the people's own language." / hints "King Sejong's letters…" / CHINESE feedback(C01 지식) | final | 제거(Final 교체) | Final 319 |
| 13 | Final transition "Miri sends the old letter box far away. / It goes to Haesu's family, in Chongqing. / One more note will be written in it." | final | 제거 | §12 transition |
| 14 | Ending Miri "Where will our old letter box go now?" | final.ending | 제거 | Yun "Thank you, Miri. You kept my words safe." |
| 15 | caseSummary "Miri, a keeper, …" | play | Case 안에서 완결 | §13 |
| 16 | dossier m1 "what Bun-i carried (Case 01)", final "Case 01's letters", fiction "keepers' letter box and its old notes (from 1446 on)" | dossier | Case 안에서 완결 | §14 |
| 17 | plan notes "the water-drop mark of every keeper's note (Haesu's of Case 10 the last one seen)" | m1 notes | 제거 | "The blue drop is Miri's sign: she brings water to the rooms (M1 letter, Final talk)." |
| 18 | discoveries m1 "A keeper has been here…", m3 "THE FRIEND'S COPY" | s5Ep11Discoveries | Case 안에서 완결 | §M1·§M3 |
| 19 | evidenceLinks | s5Ep11EvidenceLinks | 유지 | 이미 `{}` |
| 20 | C12 M1 clueInputs `s5_ep11_e4` textMention / story_bible thread #33 "Miri sent the box to Chongqing" | C12 / story_bible | C12 담당이 제거. thread 삭제 | — (C11 쪽 변경 없음, e4 id 유지) |
| 21 | 이전 설계 Intro "A water-drop note finds you… autumn, 1941." | redesign_c10_12 | 제거 | §4 |
| 22 | 이전 설계 M1 H2 "Every keeper's note has the same small mark. What did Bun-i carry in her bucket?" / transition "Haesu's notes had the same drop" / "A keeper took the copy" | 〃 | 제거 | §M1 |
| 23 | 이전 설계 M3 transition "old wooden letter box with a new number lock" / "I am Miri, Haesu's cousin" | 〃 | 제거 | §M3 transition |
| 24 | 이전 설계 Miri 동기 "사본을 지키미 상자에 넣고… 새 번호 자물쇠"(I-13 상자 자물쇠가 바뀐 이유) | 〃 | Case 안에서 완결 | 미리의 작은 상자, 윤의 목록 숫자로 맞춘 자물쇠(I-13은 상자가 시즌 물건이 아니므로 소멸) |
| 25 | 이전 설계 Final talk "My family says: when our letters need help, write a note with a water drop. The detective will come." | 〃 | 제거 | §12 talk(물을 나르는 사람의 서명) |
| 26 | 이전 설계 Final 미끼 `s5_ep10_e4` | 〃 | 제거 | 미끼 e1·e3 |
| 27 | 이전 설계 Final letter "I hid the copy in our family's letter box." / "I put a new lock on the box." | 〃 | 제거 | §12 letter 4줄 |
| 28 | 이전 설계 Ending Miri "I will send our letter box to Haesu's family, far away in Chongqing." | 〃 | 제거 | §13 |
| 29 | 이전 설계 caseSummary "Miri, a keeper, … in the keepers' box" | 〃 | 제거 | §13 |
| 30 | story_bible cases[s5_ep11] fromPrevious "Haesu's water-drop note (s5_ep10_e1) and the letters themselves (s5_ep01)" / toNext "Miri sends the box to the family in Chongqing." / solution "(the answer KOREAN)" | story_bible | 문서 정정 | fromPrevious "None: a standalone case." / toNext "None." / solution "…Miri, who brings water to the rooms, hides the copy in her box inside the piano; answer 319 opens it." |
| 31 | story_bible characters miri "A keeper in 1941, Haesu's cousin… loves the King's letters… sends the box to Chongqing", relationships bitna; yun_dongju 관계 유지 | story_bible | 문서 정정 | role "A young woman who brings water to the rooms and helps at Yonhi College (made up)"; personality "Brave, quick, a little impatient."; purpose "Case 11: hides the poet's copy in her box inside the college piano before the rooms are checked."; bitna 관계 삭제 |
| 32 | season.plan characters miri "A keeper, Haesu's cousin, who helps at Yonhi College (made up)" | season.plan | 문서 정정 | "A young woman who helps at Yonhi College (made up)" |
| 33 | story_bible clueThreads #28(`s5_ep10_e1`→`s5_ep11_m1`), #29(`s5_ep01_c1`→`s5_ep11_m1`) | story_bible | 삭제 | — |

- 물방울 쪽지 확인(필수 2): 이 Case에 남는 물방울은 **미리의 카드 서명 하나**다. 쓴 사람 = 미리. 이유 = 매일 아침 방에 물을 나르는 사람이라 이름 대신 물방울을 그리고, 사무실 사람이 누가 썼는지 모르게 하려고. M1 편지 3줄(복선) → M1 transition(윤이 알아봄) → Final 대화(미리 본인 설명)에서 모두 이 Case 안에서 밝혀진다.

### 17. 독립성 검증

| 항목 | 이 Case만 본 새 플레이어 | 근거 |
|---|---|---|
| Intro 이해 | 된다 | 일본 지배·학교의 한국어·윤동주·연희전문·사본 3부·문제(새벽 전)를 Intro 7줄이 말한다 |
| M1 풀기 | 된다 | 윤의 편지(붉은 책등, 흰 끈, 미리는 물을 나름) + 렌즈 장면 |
| M2 풀기 | 된다 | 목록·카드 두 장 + M1의 "white string" |
| M3 풀기 | 된다 | c2 + 강당 편지 6줄 + 'keys' glossary |
| Final 풀기 | 된다 | present 카드 3장 모두 C11 증거, 자물쇠 규칙·숫자 모두 화면에 |
| Ending 이해 | 된다 | 친구에게 전달 + 역사 4줄. 다른 Case 인물·상자 없음 |
| 남은 다른 Case 참조 | **없음** | clueInputs·recall·미끼·대사·dossier derivation 모두 C11 안. (C12가 `s5_ep11_e4`를 참조하던 것은 C12 쪽에서 제거) |

### 18. 유지/변경 표

| 기존 | 처리 |
|---|---|
| C11-1 M2 transition이 피아노를 대신 추리 | 변경: 삭제, M3에서 PIANO 추론 |
| C11-2 Final KOREAN(첫 줄에 답) | 변경: Final = 대화 + 319. Korean은 Intro·Ending |
| C11-3 R 편지 누락·J/M 예시 누락 | 변경: Final 편지 R/J/M 같은 4줄 |
| C11-4 윤의 사전 지식 | 변경: 찾은 뒤 반응 |
| C11-5 HANGUL 피드백 | Final 교체로 소멸 |
| C11-6 "choice subject" | Final에서 사라짐(reveal에만) |
| C11-7 카드 제목 차이 | 변경: 같은 제목 |
| C11-8 1948 맥락 | "his poems became a book", 옥사는 reveal에만 |
| I-13 자물쇠가 바뀐 이유 | 소멸(미리 자신의 상자) |
| M1 렌즈 장면, M2 기록 비교, 319 계산 퍼즐 | 유지(319는 Final로 이동) |
| 지키미·상자·해수·분이·세종 글자·충칭 | 제거(원장) |

### 19. 인과관계 표

| 단계 | 필요 이유 | 이 Case에서 얻은 것 | 행동 | 상태 변화 | 다음 이유 |
|---|---|---|---|---|---|
| Intro | 새벽 전에 사본을 찾아야 함 | — | 읽기 | 윤의 방 | 책상을 봐야 함 |
| M1 | 첫 증거 | 윤의 말(붉은 책등, 흰 끈, 미리) | 돋보기 → WATER | 미리의 카드 / c1·e1 | 카드가 위치를 말할 수도 |
| M2 | 카드가 목록과 같은 이유 | 목록 + 흰 끈 | 다른 줄 찾기 | "black and white", "keys of these colours" / c2·e2 | 그런 keys는 어디? |
| M3 | 숨긴 곳 | c2 | keys의 두 뜻 + 색 → PIANO | 피아노 속 잠긴 상자, 미리 등장 / c3·e3 | 상자를 열어야 함 |
| Final | 자물쇠 | 미리의 설명 + 목록(present) | 증거 제시 → 319 | 사본 회수, 친구 도착 / e4 | 친구에게 건넴 |
| Ending | Intro 문제 해결 | 사본 | 읽기 | 한국어 시, 1948 | (없음) |

### 20. 시뮬레이션 (설계 검토)
- M1 R: 렌즈로 붉은 책 → 카드. 방울이 그림이라는 spot 줄과 "She brings water" 편지 줄을 이어야 한다. 막히면 H2가 정확히 두 정보를 가리킨다. RAIN이 예상 오답이며 맞춤 피드백이 있다.
- M3 R: key = 열쇠로만 알면 KEYS → "all black" 피드백, glossary에서 '건반'.
- Final: 미리 카드(e1)를 고르기 쉽다(같은 숫자가 적혀 있음) → miss "That is not in Yun's own hand." 이것이 이 present의 의도된 함정이다.
- 위험: Intro 7줄(최대 R 15단어). M1에서 미리를 먼저 언급해 "누가"는 일찍 풀린다 → 이 Case의 질문은 "어디·언제까지"이므로 괜찮다.

### 21. ID·저장 영향
- id 전부 유지: m1~m3, final, c1~c3, e1~e4. 내용 변경: c1, c2 value, c3, e1, e3, e4 description, discoveries m1·m3(+m2 추가).
- 유형 변화: m3 numberCode → wordInput, final wordInput → numberCode(+ talk.before). 둘 다 퍼즐 상태를 저장하지 않는 엔진. 새 키 `s5_ep11_final:talk-before`.
- 이미 m3(319)를 푼 저장본: m3 완료로 남아 PIANO 미션은 건너뛴 상태가 된다. Final에서 319를 다시 풀게 되므로 흐름은 깨지지 않는다.
- recall: m3 `s5_ep11_e2` recall → Final present(Final recall은 화면에 안 나오므로, engine_save_impact §1.1).
- story_bible clueThreads: #27(c1→m2) 문구를 "Miri's card copies Yun's list: one line on it is not true."로, #31(e2→m3) → e2→final, #32(c3→final "King's letters… Korean") → c3→final "The box in the piano opens with 319: the friend's copy, in Korean." #30(c2→m3) 유지.

### 22. 엔진 변경
- 2b2(present 카드 3장). 없이 하려면 offered [s5_ep11_e1, s5_ep11_e2](2장, 정답 2번째)로 지금 코드에서 된다. 2b3 권장. 그 밖에 없음.

### 23. 이미지
- 새 그림 없음. M1 `dorm_room.webp`(붉은 책 밑 파란 방울 카드), M2 `c11_copy_list.webp`·`c11_drop_card.webp`(카드 오른쪽 아래 물방울 = 미리의 서명으로 설명됨), M3 `college_hall.webp`, Final `college_gate.webp`, 초상 `miri.webp`·`yun_dongju.webp`. dorm_room 옷걸이의 한복은 대사에서 언급하지 않는다.

### 24. 작업량: **M**
- 파일: `s5_ep11/case.plan.json`, `s5_ep11/levels.json`, `planning/history_dossier.json`(m1·m3·final 퍼즐, fiction), 재생성 `s5_ep11.g.dart`·`s5_ep11_levels.g.dart`·`s5_seoul_history.g.dart`·manifest, `test/sandbox/s5_seoul_case11_test.dart`(M2 카드 이름·제목, M3 '219 거부' → 'KEYS 거부', Final '219 거부', M3 story piano 단언은 유지), `test/sandbox/s5_seoul_rookie_test.dart`(C11 M3 319 단언 → Final로, C11 Final KOREAN 단언 → 319 의도로), 문서 `story_bible.json`·`season.plan.json`.

### 25. 위험
- 연희전문은 남학교였다(plan notes) → 미리는 "물을 나르고 학교 일을 돕는 사람"이며 학생이라 부르지 않는다. 1941년 기숙사 급수 일을 젊은 여성이 했는지는 확인하지 않은 창작 설정이다(IN THIS MYSTERY "Miri… made up"에 포함).
- 피아노를 치는 학생이 그림에 있다 → "When the man leaves, you lift the piano's top"으로 사람이 빠진 뒤 연다.
- word_entry가 시즌에 많다 → '단어의 두 뜻 + 색 조건' 추론이라 성격이 다르다.

---

## Season prologue/outro/finale

### 원칙
- `season.plan.json` prologue의 키(city / cases / separate / question / bigger / promise / firstCase)와 그림(hero `cover/season5_prologue_night.webp`, pieces 4장, firstCase.picture `cover/kings_study.webp`)은 **바꾸지 않는다.** 키마다 줄 수도 유지: city 1, cases 4, separate 2, question 1, bigger 1, promise 3, firstCase.line 1, outro 2, finale 2 = `season.levels.json` lines 17개, 순서 그대로. 문구만 바뀐다.
- 새 프롤로그가 말하는 것: 서울의 역사 속 **서로 다른 12개 사건**, 각 사건은 **그 사건만의 단서로** 푼다, 사건 뒤에는 실제 역사가 있다. 말하지 않는 것: "누가 계속 쪽지를 쓰나", 물방울, 지키미, "조각을 맞춘다"(하나의 미스터리 암시), 쪽지가 탐정을 부른다.
- 화면 위치(확인함): prologue = `season_prologue_screen.dart`, outro = 시즌 화면 완료 카드(`season_screen.dart:762`), finale = 마지막 Case 해결 화면 "SEOUL COMPLETE" 아래(`case_solved_screen.dart:222`, finale가 비면 outro).

### 현재 값 → 새 값 (R / J / M, 단어 수)

| levels 줄 | 키 | 현재 ROOKIE | 새 ROOKIE (단어) | 새 JUNIOR (단어) | 새 MASTER (단어) | 판단 |
|---|---|---|---|---|---|---|
| 0 | city | Seoul is very old.\nIts story is full of secrets. | (유지) | (유지) | (유지) | 문제 없음 |
| 1 | cases[0] | A wet note waits by a turtle ship. | Gunpowder for a turtle ship goes missing. (7) | Gunpowder for a turtle ship disappears. (6) | Gunpowder meant for a turtle ship vanishes. (7) | **변경**: 쪽지 대신 C02의 사건 자체 |
| 2 | cases[1] | A lifting machine will not lift. | (유지) | (유지) | (유지) | C03 사건 |
| 3 | cases[2] | Logs for the palace go missing. | (유지) | (유지) | (유지) | C04 사건 |
| 4 | cases[3] | And the palace lights go dark. | (유지) | (유지) | (유지) | C05 사건 |
| 5 | separate[0] | They look like different cases. | Twelve cases, in twelve times of Seoul's story. (8) | Twelve cases, set in twelve times of Seoul's story. (9) | Twelve cases, set in twelve different ages of Seoul's story. (10) | **변경**: "다르게 보이지만 사실은…" 복선 제거, 12개 독립 사건 명시 |
| 6 | separate[1] | But a good detective\nputs the pieces together. | Each one is a mystery\nof its own. (8) | Each one is a separate mystery\nwith its own clues. (10) | Every one is a mystery\nwith clues all its own. (10) | **변경**: 하나의 미스터리 암시 제거 |
| 7 | question | Who keeps writing the notes? | What really happened, and why? (5) | What really happened, and why did it happen? (8) | What truly happened, and for what reason? (7) | **변경**: 시즌 질문 → 매 사건의 질문 |
| 8 | bigger | Every note has\nthe same small water drop. | Behind every case\nis a true story from history. (9) | Behind each case\nlies a true story from history. (9) | Behind every case\nlies a true chapter of history. (9) | **변경**: 물방울 제거, 역사 사건임을 말함 |
| 9 | promise[0] | Find the notes. | Look closely. (2) | Look closely at everything. (4) | Observe every detail. (3) | **변경** |
| 10 | promise[1] | Read the letters. | Read the clues. (3) | Read every clue carefully. (4) | Weigh every clue. (3) | **변경** |
| 11 | promise[2] | Find the keepers. | Solve each case. (3) | Solve each case on its own. (6) | Solve each case in turn. (5) | **변경**: 지키미 제거 |
| 12 | firstCase.line | Your first case starts\nin old Hanyang. | (유지) | (유지) | (유지) | 이미 "case". 이전 설계의 "first note…1446"은 철회 |
| 13 | outro[0] | Bun-i's first note lies under all the others. | From 1446 to 1945: twelve cases, all solved. (8) | From 1446 to 1945, all twelve cases are solved. (9) | From 1446 to 1945, every one of the twelve cases is solved. (12) | **변경**: 분이 쪽지·상자 회수 제거 |
| 14 | outro[1] | The letters she learned in 1446 are read freely again. | In each one, you found what really happened. (8) | In each one, you found out what really happened. (9) | In each one, you uncovered what truly happened. (8) | **변경**: "she"(분이) 제거 |
| 15 | finale[0] | Seoul keeps its story in its letters. | (유지) Seoul keeps its story in its letters. (7) | (유지) Seoul holds its story in its letters. (7) | (유지) Seoul preserves its story within its letters. (7) | 유지: 시즌 미스터리 없이도 성립(글로 남은 역사) |
| 16 | finale[1] | This time, you read it note by note. | This time, you read it case by case. (8) | This time, you have read it one case at a time. (11) | This time, you have pieced it together case by case. (10) | **변경**: "note by note"(쪽지 연쇄) 제거 |

- 현재 J/M 값은 `season.levels.json` 그대로(위 표의 "유지" 칸). 바뀌는 줄: 1, 5, 6, 7, 8, 9, 10, 11, 13, 14, 16(11줄). `season.plan.json`에는 ROOKIE 문구를 같은 키에 넣는다(prologue.cases[0], separate[0..1], question, bigger, promise[0..2], outro[0..1], finale[1]).
- 이전 설계(redesign_c10_12)의 프롤로그 변경(promise에 "A water-drop note finds you." / "Read it, and you are in its time.", separate[0] "Hundreds of years lie between them.", question·bigger 유지, firstCase "Your first note waits…1446", 아웃트로 "Bun-i's letter… Mom, thank you.", 피날레 "Twelve notes. Twelve water drops. One family." / "Every time a note called, you came.")는 **전부 철회**한다.
- "1446 to 1945": C01(1446)과 C12(1945, 광복)의 연도다. C12 재설계가 연도를 바꾸면 outro[0]의 1945만 맞춘다.
- pieces[0] 그림 주의: `cases/case_02/find_note.webp`는 **물방울이 그려진 쪽지** 그림이다. 키·그림 유지 원칙에 따라 기본안은 그림을 두되, 새 문장(화약 분실)과 그림이 어긋나고 물방울 모티프가 프롤로그에 남는다. **선택안(사용자 확인 필요)**: pieces[0]을 이미 있는 `cases/case_02/turtle_ship.webp`(거북선과 화약통, 물방울 없음)로 바꾼다. 새 그림 생성 없음. 단, 프롤로그가 팩 다운로드 전에 보이는지와 `turtle_ship.webp`가 앱 동봉인지(R2 팩 전용이면 프롤로그에서 안 보일 수 있음)를 먼저 확인해야 한다(확인하지 않음).

### season.plan.json mainMystery (문서 정정, 스키마 필수 4필드 `season_plan.schema.json` $defs/mainMystery)

| 필드 | 현재 | 새 값 |
|---|---|---|
| truth | "Bun-i, the water-carrier who wrote the first letter … For five hundred years her family kept it: in every hard time a keeper wrote one short note … signed it with her water drop … they kept the letters alive." | "There is no single season mystery. Season 5 is twelve separate history cases set across Seoul's story, from King Sejong's new letters in 1446 to the light of 15 August 1945. Each case has its own problem, its own people and its own evidence, and is solved inside that case." |
| culprit | "No one: the season's mystery is a family of keepers, not a crime; each case has its own small, made-up wrongdoer or puzzle." | "No one across the season: each case has its own small, made-up wrongdoer or puzzle; history itself is never changed." |
| motive | "To keep the people's own letters alive, as Bun-i promised her teacher Sora." | "None across the season: each case's motive is told in that case." |
| revealCase | "s5_ep08" | "s5_ep12"(필수 caseId 필드라 비울 수 없음. 시즌 마지막 Case를 적고, 시즌 공개 장면이 없다는 뜻은 truth가 말한다) |

- 같은 파일의 characters: haesu role "…and the keeper of Shanghai" → "A clerk of the Provisional Government (made up)", miri "A keeper, Haesu's cousin, who helps at Yonhi College" → "A young woman who helps at Yonhi College (made up)", bitna "The last keeper, Haesu's daughter" → C12 담당이 정함. notes 안의 "keepers"·"water-drop" 연결 설명도 함께 정리(C12 담당과 겹치지 않게 문서 PART에서 한 번에).

### planning/story_bible.json (문서 정정)

**coreMystery** (현재: question "Who leaves the notes in the King's letters, marked with a small water drop, …?" / truth 분이 집안 500년 지키미 / culprit 지키미 집안 / motive "as Bun-i promised Sora" / method "A short note in Hangeul with a water-drop mark… the letter box passed from parent to child." / revealCase s5_ep08 / resolvedCase s5_ep12) → 새 값:
- question: "What really happened at twelve turning points of Seoul's story? Each case asks its own question."
- truth: mainMystery.truth와 같은 문장.
- culprit: mainMystery.culprit와 같은 문장.
- motive: "None across the season; each case's motive is its own."
- method: "Each case is solved only with the clues found in that case; no evidence, note or object carries from one case to another."
- revealCase "s5_ep12" / resolvedCase "s5_ep12"(필드를 지울 수 있으면 지운다. 이 파일의 스키마는 생성기 검사 대상인지 확인하지 않았다).

**clueThreads** (39개): 같은 Case 안에서 시작하고 끝나는 스레드만 남긴다. **삭제할 Case 간 스레드 19개**(색인 0부터): #3 `s5_ep01_c1`→ep02, #4 `s5_ep01_e2`→ep02_m2·ep04_m1, #6 `s5_ep02_e1`→ep03_m1·ep04_final, #8 `s5_ep03_e1`→ep04_final, #13 `s5_ep05_e1`→ep06_m1, #14 `s5_ep05_e4`→ep06_m2, #16 `s5_ep06_e1`→ep07_m1, #17 `s5_ep06_e4`→ep07_final, #19 `s5_ep05_e1`→ep07_m1, #20 `s5_ep01_e3`→ep08_final, #21 `s5_ep08_e4`→ep09_m1, #22 `s5_ep09_e4`→ep10_m1, #28 `s5_ep10_e1`→ep11_m1, #29 `s5_ep01_c1`→ep11_m1, #33 `s5_ep11_e4`→ep12_m1, #34 `s5_ep08_e4`→ep12_m2, #35 `s5_ep01_e3`→ep12_final, #37 `s5_ep04_e1`→ep05_m2, #38 `s5_ep07_e1`→ep08_m3. 각 Case 재설계가 그 Case 안의 새 스레드를 더한다(C10·C11은 §21 각 절). 같은 Case 안 스레드라도 meaning에 다른 Case를 말하는 것(예: #0~2의 C01 내용은 C01 안이라 유지, #27 "water-drop note" 문구 등)은 각 Case 담당이 문구를 고친다.

**그 밖에 같은 파일에서 고칠 곳(보고만)**: logline("At each one a short note… marked with a small water drop, asks for help. Who keeps writing them, across five hundred years?") → "From King Sejong's new letters in 1446 to the light of 1945, the detective is a guest at twelve turning points of Seoul's story, and solves a separate mystery at each one." / startingSituation의 "a note with a small water drop is waiting" 문장 삭제 / ending의 "Bitna… opens the old letter box: Bun-i's first note… under eleven more" → C12 담당 / mysteryQuestions 5개 중 시즌 질문 4개(물방울·지키미·상자·마지막 쪽지) 삭제, C01 질문만 유지 / cases[].fromPrevious·toNext 전 Case "None: a standalone case." / characters의 keeper·cousin·ancestor 관계.

### 독립성 검증 (시즌 줄)

| 항목 | 결과 |
|---|---|
| 프롤로그만 본 새 플레이어가 "12개 서로 다른 역사 사건"으로 이해 | 된다(separate[0]·[1], bigger) |
| 시즌 공통 미스터리 암시(쪽지·물방울·지키미·조각 맞추기) | 없음(pieces[0] 그림의 물방울만 남음 → 선택안) |
| outro·finale가 시즌 미스터리 해답을 전제 | 없음(분이·쪽지·상자 언급 제거) |

### 작업량: **S**
- `season.plan.json`(prologue 8곳, outro 2, finale 1, mainMystery, characters), `season.levels.json`(11줄 R/J/M), 재생성 `s5_seoul_season.g.dart`·`s5_seoul_levels.g.dart`, `story_bible.json`(문서). 그림 변경 없음(선택안 제외). 프롤로그·outro 문구를 직접 단언하는 테스트는 `test/`·`lib/`에서 찾지 못했다("Who keeps writing", "puts the pieces", "Seoul is very old" grep, 생성 파일 제외).

### 위험
- revealCase를 s5_ep12로 둔 것은 스키마 때문이며 의미는 없다 → truth 문장이 "no single season mystery"를 명시.
- finale[0] "letters"가 '편지/글자'로 읽혀 분이 이야기를 떠올릴 수 있다 → 시즌 공통 미스터리를 주장하지 않으므로 유지했다. 더 중립을 원하면 R "Seoul keeps its story in its streets and stones." 대안(9단어).

---

## 부록 — 요약

| 대상 | 새 Final / 정답 | Final 증거 | 바뀌는 미션 | 엔진 | 새 그림 | 남은 외부 참조 |
|---|---|---|---|---|---|---|
| C10 | 기록 검증 `evidence_talk`, answer `why` | e1·e2·e3만(미끼도 이 셋) | M1 문구·recall 삭제, M2 그림 장면, M3 DROP→HOUR, Final | 2b2(없으면 2장안), 2b1·2b3 권장 | 없음 | 없음 |
| C11 | 대화(목록 제시) → `number_entry` 319 | e2 정답, e1·e3 미끼 | M1 물방울=미리 서명, M2 이름, M3 319→PIANO, Final | 2b2(없으면 2장안) | 없음 | 없음 |
| 시즌 | — | — | 프롤로그 8줄·outro 2·finale 1 문구, mainMystery·story_bible 문서 | 없음 | 없음(선택: pieces[0] 교체) | 없음 |

확인하지 않은 것: 생성기 실행(새 plan이 play_check·dossier 게이트를 통과하는지), levels.json이 talk present·interview 문구를 레벨별로 패치하는 방식, `s5_ep10_h5/h6` 출처, 앱 실행·기기 플레이, `turtle_ship.webp`의 동봉 여부, story_bible 스키마 검사 여부.

## Case 12 — The Box That Waited (현재 제목 "The Day the Light Returned")

- 작성 2026-11-09. 읽기 전용 설계안이다. 저장소 파일은 하나도 바꾸지 않았다.
- 근거: §0 정책(독립 Case 정책, 이 문서의 최상위 기준), `redesign_c10_12.md` Case 12 절(재사용: M1 트렁크 추론, M3 815·810 미끼, Final 미끼 타일 N·R, Ending 역사 줄), `docs/SEOUL_CASE02_12_FULL_AUDIT.md` PART 4 C12(C12-1~9)·PART 5-B C12 표, `engine_save_impact.md` §1–4, `s5_ep12/case.plan.json`, `planning/history_dossier.json`(s5_ep12), `season.plan.json`(characters·places·caseMaps), 코드 확인 `lib/puzzles_v2/core/timeline_rules.dart:192,345,348`, `tool/season_gen/play_check.dart:500-575`, `lib/features/mission/final_mission_screen.dart:883-895,975-977`, `tool/season_gen/history_dossier.dart:490,499`.
- 그림을 직접 열어 봤다: `case_12/office.webp`, `family_room.webp`, `river_steps.webp`, `trunk_one_strap_lock.webp`, `characters/bitna.webp`, `kim_wonbong.webp`.
- 단어 수: 공백으로 나눈 토큰 가운데 글자나 숫자가 있는 것을 스크립트로 셌다.
- "어린이 시뮬레이션"은 설계 검토다. 실제 어린이 테스트가 아니다.

### 0. 한 줄 요약
충칭 임시정부 사무실이 짐을 싸는 1945년 8월. 광복군에 가 있는 어머니가 빛나에게 남긴 상자가 아빠의 실수로 사무실 트렁크에 들어갔다. 어머니의 규칙은 "전쟁이 **끝난** 날에만 자물쇠를 열어라. '끝날지도 모른다'로는 안 된다." 탐정은 상자를 찾고(M1), 어머니 편지를 순서대로 놓아 뒷면의 수수께끼를 읽고(M2), 라디오로 '오늘이 그날'임을 확인하고(M3), 강가 계단에서 증거로 빛나를 설득한 뒤 자물쇠를 연다(Final, LIGHT). 상자 안에는 어머니가 바느질한 태극기가 있다. Ending에서 김원봉이 "이날을 광복, 빛이 돌아옴이라 부른다"고 말하고, 빛나는 어머니의 낱말이 왜 LIGHT였는지 깨닫는다.

---

### 1. 제목·역사 배경
- **제목 변경: "The Box That Waited"**(한국어 메모: 기다린 상자). 현재 제목 "The Day the Light Returned"에는 Final 정답 LIGHT가 들어 있다. 새 제목은 사건(상자)과 주제(기다림)를 말하고 답은 말하지 않는다. 제목은 표시용이라 저장과 무관하다.
- 시대·장소: **1945년 8월 10일~15일, 중국 충칭.** 일본은 1910년부터 한국을 지배했다. 대한민국 임시정부는 1940년 충칭으로 옮겨 한국광복군을 만들었다(h1). 김원봉은 1944년부터 임시정부 군무부장이었다(h2). 8월 10일 무렵 일본이 항복할 수 있다는 첫 소식이 전해졌고(새 h10, 출처 확인 필요), 8월 15일 일본이 연합국에 항복했다(h3). 광복군은 국내 진공 작전을 준비했지만 일본의 항복이 먼저 왔다(h6). 광복(光復) = 빛이 돌아옴(h5).
- 이 Case 안에서 배경을 모두 설명한다(앞 Case 지식 불필요): Intro 2번 줄이 1910년 지배와 '멀리서 일하는 정부'를, M1 대화가 8월 10일 첫 소식과 짐 싸기를, Ending이 광복의 뜻·연합국·한국인의 노력·김원봉의 직책을 말한다.

### 2. 독립 사건 목표 (한 문장)
**빛나의 어머니가 남긴 상자를 찾아, 어머니의 규칙대로 '전쟁이 끝난 바로 그날' 그 자물쇠를 연다.**
- Intro에서 문제가 생기고(상자 분실 + 오늘이 그날일지도), Ending에서 풀린다(상자가 열리고 태극기가 나옴).
- 물방울 쪽지, 지키미, 해수, 미리, 분이, 열두 장 쪽지, 서울에서 온 상자는 **하나도 나오지 않는다.**

### 3. 인물과 동기

| 인물 | 사실/창작 | 이 Case 안에서 밝혀지는 정체 | 동기 |
|---|---|---|---|
| **빛나**(11세) | 창작 | 충칭에 사는 한국인 소녀. 아빠는 임시정부 사무실에서 서류를 정리하는 직원이고, 어머니는 한국광복군과 함께 멀리 가 있다. 남동생 둘(그림 family_room의 학생모 소년, 꼬마) | 어머니가 떠나며 남긴 상자를 '그날' 열겠다는 약속. 규칙을 어기지 않으려고 증거를 확인하고서야 연다(Final 대화의 이유) |
| **빛나의 어머니** | 창작(등장 안 함) | 4월에 광복군으로 떠남. 편지마다 작은 그림(소나무·비구름·달)을 그려 보냄 | 아이들이 미리 열지 못하게 낱말 자물쇠를 걸고, 수수께끼를 편지 **뒷면**에 한 줄씩 나눠 적음. "'May' is not enough." — 소문에 들떠 미리 열지 말라는 당부 |
| **빛나의 아빠** | 창작(family_room의 안경 쓴 남자) | 사무실 직원 | 8월 10일 첫 소식 뒤 서류를 트렁크에 싸다가 **실수로** 어머니의 상자를 함께 넣음. 책상에 쪽지를 남기고 집으로 아이들을 보러 감 |
| **김원봉** | 실존(직책만 사실, 대사는 창작) | 임시정부의 군무부장("the government's minister for the army") | 탐정을 맞고, 사무실 짐 싸기와 라디오 소식을 알려 줌. Ending에서 광복의 뜻과 '많은 사람의 노력'을 말함. 평가 문장 없음, 1945년 이후 행적 언급 없음 |
| 탐정(플레이어) | — | 임시정부의 손님 | 빛나의 부탁 |

- 남동생 둘은 이름 없이 "her brothers / her little brother"로만 부른다(새 초상 불필요). 미끼 타일의 동기에 쓰인다: "My brothers tried to guess it many times!"

### 4. Intro — ROOKIE 전문
1. August, 1945. You are a guest of Korea's government in Chongqing, China. (12어)
2. Japan has ruled Korea since 1910. So this government works far from home. (13어)
3. Kim Won-bong, the government's minister for the army, meets you at the door. (13어)
4. A girl runs up to you: "I am Bitna. My mother's box is lost!" (14어)
5. "Mother said: open its lock on the day the war is over. That day may be soon!" (17어)

- synopsis(R): "A girl's box is lost in a busy office in Chongqing." / "Her mother said: open it on the day the war is over."
- goal(R): "Find Bitna's mother's box and open its lock on the right day."
- objectives(R): "Find Mother's box." / "Put Mother's letters in order." / "Find the day the lock may open." / "Open Mother's lock."
- hook: "The radio in the office is on all day."(유지)
- 현재 intro의 "Miri sent the old letter box here from Seoul."과 "On your chair lies a small note with a water drop."은 삭제(외부 의존, C12-5 위치 불일치도 함께 사라짐).

### 5. M1 — The Trunk by the Wall (유지: 트렁크 추론 / 변경: 쪽지의 주인과 이유)
- **목적**: 잃어버린 상자를 찾는다. 상자와 그 자물쇠(5칸, 타일 7장)가 이 Case의 '잠긴 문제'로 처음 눈에 보인다.
- **유형**: paletteId `scene_explore_choose` / engineTable `explores` / missionType `multipleChoice`. 정답 `one_strap_lock`. 그림·좌표·choices·options·feedback은 **그대로**(office.webp `measuredOn` 해시도 그대로).
- **그림 확인**: office.webp 왼쪽 아래 책상에 파란 봉인이 찍힌 접힌 쪽지, 선반 위 나무 라디오, 오른쪽 창문(강과 언덕 도시), 오른쪽 벽의 트렁크 3개, 열린 문(모자 쓴 소년), 책장, 서류를 든 땋은 머리 소녀. 이야기와 어긋나는 것이 없다. 쪽지의 파란 점은 "blue seal"로 부른다(물방울 표시 아님).
- talk.before (speaker `kim_wonbong`, R)
  - "Welcome, Detective. Since the first news on 10 August, we pack our papers." (12어)
  - "Bitna's father packed her mother's box with them, by mistake." 
  - "He went home to the little ones. He left a note on the desk."
  - detective: "Then I will find that note." / finishLabel "LOOK AROUND"
  - (C12-6 "A girl knows where" 해결: 아빠의 쪽지가 위치를 안다고 명시)
- story (R)
  1. The office is hot and busy. People pack papers into trunks.
  2. Bitna looks at the trunks. "They all look the same!"
  3. On the desk lies a folded note with a blue seal.
- letterIntro "Bitna's father wrote:"
- letter (R, 4줄)
  1. "Bitna, I am sorry! I packed Mother's box in a trunk by mistake."
  2. "It is the trunk with ONE leather strap."
  3. "It has a round brass lock, too."
  4. "Do not open Mother's lock before the day! — Father"
- question: "Which trunk holds Mother's box?"
- explore 문구 변경: task "Look around the office. Find the note from Bitna's father." / nextTask "Which trunk holds the box? Look at the trunks." / missLine "Nothing here. Look for the note." / spot `note` title "FATHER'S NOTE", label "A folded note on the desk" / others 책장 line "Books and papers. No note here."(현행 "No water drop here." 교체). 라디오·창문·문·트렁크 줄은 유지. spot id·areas·mark는 그대로.
- **화면 단서**: 쪽지 2·3번 줄(끈 하나 + 둥근 놋쇠 자물쇠), 트렁크 그림 3장.
- **정답**: `one_strap_lock`.
- **8세 풀이 경로**: ① 책상 쪽지를 탭해 읽는다(읽기 전엔 트렁크가 잠김: unreadLine). ② 끈 개수를 센다 → 끈 둘인 트렁크 제외. ③ 남은 둘 중 둥근 놋쇠 자물쇠가 있는 것.
- **선택지 대입 검사**
  - `two_straps`: 놋쇠 자물쇠 O, 끈 하나 X → 오답. 피드백(현행) "This trunk has two straps. The note says ONE strap."
  - `one_strap_peg`: 끈 하나 O, 놋쇠 자물쇠 X(나무못) → 오답. 피드백(현행) "One strap, yes. But the note says it has a round brass lock."
  - `one_strap_lock`: 두 조건 모두 O → **유일 정답**(감사 "좋은 설계" 그대로).
- 힌트(현행 유지): H1 "Read the note on the desk first. Then look at the trunks." / H2 "Count the straps. Then look at the lock."
- successMessage: "You found the trunk with Mother's box!"
- transition (R)
  1. In the trunk lies a small wooden box.
  2. Its top opens. Its bottom has a lock: five slots and seven letter tiles.
  3. Mother carved on the lock: "Five letters. Two tiles are extra."
- **상태 변화**: 상자를 손에 넣음. 자물쇠의 규칙(5글자, 타일 7장 중 2장은 가짜)을 앎. 낱말은 모름.
- clue `s5_ep12_c1`: title "Mother's Lock" / value "5 SLOTS · 7 TILES" / note "Mother's lock: a five-letter word. Two of its seven tiles are extra." / symbol `key`
- evidence `s5_ep12_e1`(id 유지, 내용 교체): name "Father's Note" / icon `letter` / description "Bitna's father packed Mother's box in the trunk with one leather strap and a round brass lock, by mistake. He says: do not open her lock before the day."
- discovery: type `newLead` / title "MOTHER'S LOCK" / detail "Seven tiles, five slots. Which word did Mother choose?"
- clueInputs: **없음**(현행 `s5_ep11_e4` textMention 삭제. 빈 목록은 C01·C05·C08 M1과 같다).
- **다음 미션이 필요한 이유**: 낱말을 모른다. 자물쇠에는 '5글자, 2장은 가짜'뿐이다. 어머니의 다른 말은 집에 있는 편지에 있다 → 상자를 빛나의 방으로 가져간다.

### 6. M2 — Mother's Letters (변경: 지키미 쪽지 순서 → 어머니 편지 순서)
- **목적**: 쏟아진 어머니 편지를 보낸 순서대로 놓는다. 어머니의 첫 편지가 "순서대로 놓은 뒤 뒷면을 읽어라"라고 했기 때문이다. 뒷면 세 줄이 **수수께끼 두 줄 + 여는 날의 규칙 한 줄**이다.
- **유형**: paletteId `timeline_board` / engineTable `timelines` / missionType `sequence`. 엔진 변경 없음(카드 5장: 고정 1, 놓을 카드 3, 버림 1 → `play_check.dart:504` 한도 안).
- **그림 확인**: family_room.webp — 바닥에 종이가 흩어져 있고 가운데 작은 나무 상자가 열려 있다. 꼬마가 종이를 들고 있고, 땋은 머리 소녀(빛나), 학생모 소년, 안경 쓴 아빠가 함께 본다. 벽에 아이가 그린 집 그림이 붙어 있다 → 버림 카드 "A DRAWING"(남동생이 그린 집)과 맞는다. "윗칸은 열리고 아랫칸이 잠긴 상자"라 열린 상자 그림과 모순이 없다.
- talk.before (speaker `bitna`, R)
  - "My little brother opened the top. Now Mother's letters are all mixed up!"
  - "Mother drew a little picture on each one."
  - detective: "Let us put them back the right way."
- story (R)
  1. You carry the box to Bitna's room. Her father and brothers are there.
  2. Her little brother opens the top. Mother's letters fall out.
  3. "Mother sends a letter when she can," Bitna says.
- letterIntro "What Mother's letters say:"
- letter (R, 5줄. 관계 문장 두 개는 **R/J/M 모두 같은 글자**로 둔다)
  1. First letter (April): "I go to the Liberation Army today. I will write to you."
  2. "Keep my letters in order. Then turn them over and read the backs."
  3. Pine letter: "I am far away now. There are pine trees on the hill."
  4. Rain letter: "After my pine letter, the rain came. My boots are wet."
  5. Moon letter: "The rain is over now. The moon is bright tonight."
- question: "Put Mother's letters in order, from the first."
- timeline.cards (**plan·화면 순서. 정답 순서 아님**)

| id | title | text (R) | anchor | 비고 |
|---|---|---|---|---|
| `rain_letter` (새) | THE RAIN LETTER | A little rain cloud is drawn on it. | — | |
| `drawing` (유지) | A DRAWING | Bitna's little brother drew a house. It is not a letter. | — | discard. 뜻(이야기에 속하지 않는 그림)이 같아 id 유지 |
| `first_letter` (새) | THE FIRST LETTER | Mother wrote it the day she left. | APRIL | 고정(칸 1) |
| `moon_letter` (새) | THE MOON LETTER | A little moon is drawn on it. | — | |
| `pine_letter` (새) | THE PINE LETTER | A little pine tree is drawn on it. | — | |

- relations: `pine_letter → rain_letter` line "After my pine letter, the rain came." / `rain_letter → moon_letter` line "The rain is over now." (두 줄 모두 letter 4·5번 줄에 글자 그대로 있음 → `timeline_line_unread` 통과. 놓을 카드 3장 모두 관계가 하나 이상 → `timeline_card_unrelated` 통과)
- answerSpec: answer `first_letter,pine_letter,rain_letter,moon_letter`, codeLength 4, options = 카드 순서·제목 그대로(rain_letter "THE RAIN LETTER", drawing "A DRAWING", first_letter "THE FIRST LETTER", moon_letter "THE MOON LETTER", pine_letter "THE PINE LETTER").
- **유일 해 증명**(엔진 `timeline_ambiguous`와 같은 절차: 칸마다 '앞선 카드가 다 놓인' 자유 카드가 하나뿐)
  - 칸1: first_letter(고정, APRIL).
  - 칸2: 자유 카드 pine·rain·moon 중 선행 조건이 없는 것은 pine 하나(rain←pine, moon←rain) → pine.
  - 칸3: rain만 준비됨 → rain. 칸4: moon. drawing은 편지가 아님 → 버림. **해는 하나.**
- **8세 풀이 경로**: ① 첫 편지는 APRIL이 적혀 있고 이미 놓여 있다. ② 그림 카드는 "It is not a letter." → 옆으로. ③ 비 편지: "소나무 편지 다음에 비가 왔다" → 소나무가 먼저. ④ 달 편지: "이제 비가 그쳤다" → 비 편지 다음. ⑤ 순서: 첫 편지, 소나무, 비, 달.
- 힌트: H1 "The first letter has its month on it. Now read the rain letter." / H2 "The moon letter says the rain is over. So it came after the rain letter."
- orderFeedback: "Read the rain letter and the moon letter again. Which came first?"(틀린 카드에는 엔진이 그 카드의 관계 문장을 짚어 준다)
- successMessage: "Mother's letters are back in order!"
- transition (R) — **편지 뒷면(이 Case의 핵심 증거)**
  1. You turn the letters over. Mother wrote one line on each back.
  2. "The sun gives it." "At night, it goes away."
  3. "It comes back on the day the war is over. 'May' is not enough."
- **상태 변화**: 수수께끼 두 줄(해가 준다 / 밤에는 사라진다), 세 번째 줄(전쟁이 끝난 날 돌아온다), 여는 날의 규칙('May' is not enough)을 얻음. 낱말 후보가 좁혀지지만, 오늘이 그날인지는 모름.
- clue `s5_ep12_c2`(id 유지): title "Mother's Riddle" / value "THE SUN GIVES IT" / note "On the backs of Mother's letters: the sun gives it; at night, it goes away; it comes back on the day the war is over." / symbol `letter`
- evidence `s5_ep12_e2`(id 유지, 내용 교체): name "Mother's Letters" / icon `letter` / description "Four letters from Bitna's mother, in order. On the backs: The sun gives it. At night, it goes away. It comes back on the day the war is over. 'May' is not enough."
- recall: **삭제**(현행 `s5_ep08_e4` "Is this the box?"). clueInputs: `s5_ep08_e4` recall 삭제, `s5_ep12_c1` textMention 유지(note "Mother's box from the trunk.").
- **다음 미션이 필요한 이유**: 규칙이 "전쟁이 **끝난** 날, 'may'로는 안 된다"이다. 사무실의 라디오가 오늘 무엇을 말하는지 들어야 한다. 빛나: "The radio! Let us run back to the office."(talk 없이 transition 다음 장면 연결은 M3 story 1번 줄이 맡음)
- **순서가 왜 필요한가(정직한 평가)**: 뒷면 세 줄은 순서가 틀려도 대체로 읽힌다. 순서의 몫은 ① 어머니의 지시(첫 편지 2번 줄)라는 이야기상 이유, ② before/after 읽기 학습, ③ "준다 → 사라진다 → 돌아온다"라는 이야기 흐름(=광복의 '돌아옴')이다. 더 강한 잠금(순서대로 놓아야만 글자가 이어지는 뒷면)은 그림 없이 화면에 보여 줄 수 없어 쓰지 않았다.

### 7. M3 — News on the Radio (유지: 815 / 변경: 어머니 규칙으로 810을 거름)
- **목적**: 오늘이 어머니가 말한 '그날'인지 확인하고, 그 날짜를 빛나의 카드에 적는다. 이 카드가 Final에서 빛나를 설득하는 증거가 된다.
- **유형**: paletteId `number_entry` / engineTable null / missionType `numberCode`, codeLength 3. 정답 **`815`**.
- talk.before (speaker `kim_wonbong`, R)
  - "Quiet, everyone. The radio has news."
  - "Five days ago, it said Japan may give up. Now listen."
- recall (새, **같은 Case 증거**): title "Mother's rule" / prompt "Which thing in your Notebook says when the lock may open?" / miss "Find the backs of Mother's letters." / clueInputs `s5_ep12_e2` use `recall`(play_check: 미션당 recall 1개). → M2의 규칙이 M3 판단에 쓰인다는 것을 화면에서 확인시킨다.
- story (R)
  1. You and Bitna run back to the office. Everyone stands by the radio.
  2. People hold their breath. Then some of them cry.
  3. Bitna takes out a card and her pen.
- letterIntro "The radio, Mother's rule, and Bitna's card:"
- letter (R, 7줄)
  1. Radio: "On the tenth of August, the first news came: Japan may give up."
  2. "Today it is true. Japan has given up. The war is over!"
  3. "Today is the fifteenth of August."
  4. Mother's letter: "'May' is not enough."
  5. Bitna's card: July is month seven. August is month eight. September is month nine.
  6. Bitna: "Korean dates put the month before the day."
  7. "Write the day Mother's lock may open, in numbers."
- question: "On what day may Mother's lock open? Write it in numbers, month first."(C12-8 "today's number" 해결)
- **화면 단서**: 1·2번(10일은 'may', 오늘은 'is over'), 3번(15일), 4번(어머니 규칙), 5번(August = 8), 6번(월 먼저).
- **정답 도출**: 'may'인 10일은 규칙상 안 됨 → 오늘 15일. 8월 = 8. 월 먼저 → 8, 15 → **815**.
- **8세 풀이 경로**: ① 라디오 두 날짜 중 'may'가 붙은 날은 어머니가 안 된다고 했다. ② 오늘은 the fifteenth. ③ 카드에서 August를 찾는다 → 8. ④ 월 먼저: 8 그리고 15.
- **대입 검사**(화면 조건: 'is over'인 날 / 8월 = 8 / 15일 / 월 먼저 → 넷을 다 만족하는 값은 815 하나)
  - `810`: "That was the 'may' day. Mother said 'may' is not enough."(새. 8월 10일은 사실에 근거한 미끼)
  - `715`: "July is month seven. The radio says August."(현행)
  - `915`: "September is month nine. The radio says August."(현행)
  - `814`: "Listen again: the fifteenth of August."(현행)
  - `158`/`1508` 등 순서 오류: orderFeedback "The right numbers, in the wrong order. The month goes before the day."(현행)
- 힌트: H1 "Mother said 'may' is not enough. Which day is the war really over?" / H2 "Find August on Bitna's card. Write the month, then the day."
- successMessage: "8.15: the fifteenth of August! Today is the day."
- transition (R)
  1. Bitna writes 8.15 on her card.
  2. "Not a 'may' day," she says. "Today the war is over."
  3. "Let us open it on the river steps. Mother said goodbye to me there."
- discovery: type `storyDiscovery` / title "THE WAR IS OVER" / detail "Japan gave up. Today Mother's lock may open."(R에서 surrendered 쓰지 않음, C12-9)
- clue `s5_ep12_c3`(id 유지): title "The Day" / value "TODAY: 8.15" / note "The radio: the war is over on the fifteenth of August. The tenth was only a 'may' day." / symbol `key`
- evidence `s5_ep12_e3`(id 유지, 내용 보강): name "Bitna's Date Card" / icon `letter` / description "Bitna's card: today is 8.15, the fifteenth of August. The war is over. The tenth of August was only a 'may' day."
- clueInputs: `s5_ep12_c2` textMention(유지, note 교체 "Mother's rule: 'may' is not enough."), `s5_ep12_e2` recall(새).
- **상태 변화**: '오늘이 그날'이라는 증거(날짜 카드)를 얻음. 자물쇠를 열 시간과 장소(해 질 녘 강가 계단)가 정해짐.
- **다음 미션이 필요한 이유**: 열어도 되는 날은 확인됐지만 낱말은 아직 넣지 않았다. 빛나는 규칙을 어기지 않으려고 '오늘이 그날'과 '수수께끼'를 다시 확인한 뒤에 열겠다고 한다.
- `s5_seoul_rookie_test` C12 M3 단언(Allies 없음, "the fifteenth of August", "August is month eight", 715/814/915 피드백, 158 피드백 없음)은 **그대로 통과**한다. 810 피드백 단언 1개 추가를 권한다.

### 8. Final — Mother's Lock (2단계: 증거 대화 → 미끼가 있는 글자 자물쇠. 정답 **LIGHT** 유지)
- **유형**: paletteId `letter_tile_lock` / engineTable null / missionType `letterLock`(엔진 **2a 필요**). 앞에 `play.talk.before`(speaker `bitna`) present 2개(카드 3장 = **2b2**, 3회 안전망 = **2b3**, 힌트 버튼 = **2b1**). lockTitle "MOTHER'S LOCK". placeId `s5_seoul.c12_river_steps` 유지. location "THE RIVER STEPS" 유지.
- **그림 확인**: river_steps.webp — 해 질 녘, 강과 배가 내려다보이는 돌계단에 땋은 머리 소녀가 작은 상자를 안고 앉아 있다. 등불이 켜져 있다. 이야기와 그대로 맞는다.
- story (R)
  1. The sun goes down over the river. Families meet on the steps.
  2. Bitna sits with Mother's box on her knees.
  3. "Before I open it, I must be sure," she says.
- talk.before (speaker `bitna`)
  - lines: Bitna "Mother's rule is strict." / detective "Then let us check it together."
  - present `today`(새 id): prompt "Bitna asks: \"Is today really the day? Mother said 'may' is not enough.\"" / offered [`s5_ep12_e2`, `s5_ep12_e3`, `s5_ep12_e1`] / accepted [`s5_ep12_e3`] / miss "That does not say what day it is." / tell "Find the card with today's date on it." / lines: detective "The radio said it: the war is over. Today is 8.15." / Bitna "Not a 'may' day. Today is the day!"
  - present `riddle`(새 id, requires `today`): prompt "Bitna asks: \"And Mother's word? Where did she hide her riddle?\"" / offered [`s5_ep12_e3`, `s5_ep12_e1`, `s5_ep12_e2`] / accepted [`s5_ep12_e2`] / miss "There is no riddle on that." / tell "Mother wrote on the backs of her letters." / lines: detective "On the backs: the sun gives it. At night, it goes away." / Bitna "Five letters. My brothers tried to guess it many times!"
  - 2b2가 먼저 들어가지 않으면(카드 2장 한도) offered를 [`s5_ep12_e1`, `s5_ep12_e3`]과 [`s5_ep12_e1`, `s5_ep12_e2`]로 줄인다(정답 위치가 두 번 다 오른쪽이 되지 않게 두 번째는 [`s5_ep12_e2`, `s5_ep12_e1`]).
- letterIntro "Mother's lock, and her riddle:"
- letter (R, 4줄. 어머니의 말 세 줄은 R/J/M 모두 같은 글자)
  1. On the lock: "Five letters. Two tiles are extra."
  2. "The sun gives it."
  3. "At night, it goes away."
  4. "It comes back on the day the war is over."
- question: "What is Mother's word? Spell it with five tiles."
- **타일(plan·화면 순서)**: **N, H, T, I, R, G, L**(7장, 슬롯 5칸 = 정답 길이. 정답 순서가 아님)
- **미끼의 이유(Case 안)**: M1에서 어머니가 자물쇠에 "Two tiles are extra."라고 새겼다. 남동생들이 몇 번이고 맞혀 보려 했다(Final 대화). 타일 수집이 아니라 **자물쇠에 달린 타일**이라 "왜 이 글자들이 여기 있나"가 설명된다.
- **8세 풀이 경로**: ① 대화로 '오늘이 그날'(날짜 카드)과 '수수께끼'(편지 뒷면)를 확인한다. ② 해가 주는 것, 밤에는 사라지는 것 → 빛. ③ 영어로 light. ④ L·I·G·H·T를 놓고 N·R은 남긴다. (한국 어린이는 4번 줄 "전쟁이 끝난 날 돌아온다"에서 광복 = 빛을 떠올릴 수도 있다. 몰라도 2·3번 줄로 풀린다.)
- **대입 검사**(사전 검색: 이 7장으로 만들 수 있는 5글자 영어 단어는 LIGHT, NIGHT, RIGHT, THING, GLINT, GIRTH와 희귀어 GRITH, THIRL. `/usr/share/dict/words`)
  - **NIGHT**: feedback "Night is when it goes away. What does the sun give us?"
  - **RIGHT**: "Right is a real word. But the sun does not give us 'right'."
  - **THING**: "A thing? Read the riddle again: what does the sun give us?"
  - **GLINT**: "A glint is only a tiny flash. Mother's word fills the whole day."(남는 위험: 아래 '위험' 참조)
  - GIRTH·GRITH·THIRL: 별도 피드백 없이 기본 오답 문구(8~12세가 칠 가능성이 낮다).
  - LIGHT만 "해가 준다 + 밤에는 사라진다 + 전쟁이 끝난 날 돌아온다"를 모두 만족한다 → 정답 하나. 같은 다섯 글자의 순서만 틀리면 orderFeedback "All five letters are right. Put them in order: what the sun gives us."
- 힌트: H1 "What does the sun give us in the day? At night, it is gone." / H2 "N and R are the extra tiles. Use the other five."
- successMessage: "LIGHT. Mother's lock opens!"
- transition (R)
  1. Inside lies a flag, folded small. It is Korea's flag.
  2. Mother sewed it for the day the war is over.
  3. Bitna holds it up in the last light of the sun.
- evidence `s5_ep12_e4`(id 유지, 내용 교체): name "Mother's Flag" / icon `seal`(현행 유지. 깃발 아이콘 없음) / description "The flag Bitna's mother sewed and locked in her box. Her word was LIGHT. Bitna opened it on 8.15, 1945, the day the war was over." / inscription "LIGHT: on the day the war is over, it comes back."(현행 inscription의 한글 "광복:" 제거 — evidence 필드 한글 금지 규칙)
- clueInputs: `s5_ep12_c1`(answerDerivation, "five letters; two tiles are extra"), `s5_ep12_c2`(answerDerivation, "the sun gives it; at night, it goes away"), `s5_ep12_c3`(answerDerivation, "today is the day: the lock may open"), `s5_ep12_e2`(answerDerivation, present `riddle`), `s5_ep12_e3`(answerDerivation, present `today`). **`s5_ep01_e3` evidenceLink 삭제 → `play.evidenceLinkLine`도 삭제**(play_check `:244-246`: 링크 입력이 없으면 줄도 없어야 함).
- learning: objective "어머니의 수수께끼(The sun gives it. At night, it goes away.)를 읽고 7장 가운데 5장으로 LIGHT를 만든다. 미끼 NIGHT·RIGHT를 수수께끼로 거른다." / expressions ["The sun gives it.", "At night, it goes away."] / recallFrom `s5_ep12_m2`(현행 m3 → m2. 표현이 M2 transition에도 있다)
- **Final이 Intro 문제를 푸는가**: 상자를 열어야 했고(Intro 4·5번), 열린다. 여는 '날'은 M3 증거로, 여는 '낱말'은 M2 증거로, 자물쇠의 규칙(5글자, 2장 가짜)은 M1 증거로 정해진다. 낱말만 맞히는 퀴즈가 아니라 세 미션의 증거를 합쳐 '규칙대로' 여는 결말이다.

### 9. Ending — 상자가 열리고, 이날의 이름이 밝혀진다 (R)
1. narr: "On 15 August 1945, Japan gave up. The war was over."(J/M: surrendered / to the Allies)
2. speaker `kim_wonbong`: "In Korean, this day is gwangbok: the light comes back."
3. speaker `bitna`: "Light! That is Mother's word!"
4. speaker `kim_wonbong`: "The Allies, the countries that fought Japan, won the war."
5. speaker `kim_wonbong`: "Many Koreans worked for this day too, at home and far away."
6. narr: "Kim Won-bong was the government's minister for the army." (9어)
7. narr: "The Korean Liberation Army was getting ready, but Japan gave up first." (12어)
8. speaker `bitna`: "Mother is one of them. Soon she will come back too."
9. detective (evidence `s5_ep12_e4`): "Mother's flag waited in the box. Today it came out."
- 현재의 "Kim Won-bong had worked for independence since 1919."(C12-7)는 6·7번 줄(확인 가능한 직책 + 광복군의 준비, h2·h6)로 바꾼다. R/J/M 줄 수를 같게 하려고 두 줄로 나눴다. 1919년 의열단(h7)은 history reveal에만 남긴다(평가 문장 없음).
- 현재 7번 줄 detective "Bun-i's first note started it all."(evidence `s5_ep01_e3`)은 삭제 → 8번 줄(evidence `s5_ep12_e4`).
- caseSummary (R): "Bitna's mother left her a box with a word lock. Open it on the day the war is over, she said. 'May' is not enough. Bitna's father packed it in a trunk by mistake. On 15 August 1945, Japan gave up and the war was over. Bitna opened the lock with Mother's word: LIGHT. Inside was the flag Mother sewed. In Korean, this day is gwangbok: the light comes back. The Allies won the war, and many Koreans worked for this day."
- keyWords: ["trunk", "before", "after", "date", "light"](유지)
- glossary: 유지 trunk·strap·brass·surrendered·allies·government·minister·independence. 삭제 exile(J/M intro에 쓰면 유지)·oldest·water-drop. 추가 `extra: 남는, 여분의`, `riddle: 수수께끼`, `flag: 깃발(태극기)`, `liberation army: 광복군`, `gwangbok: 광복(빛이 돌아옴)`, `pine: 소나무`.

### 10. 역사 학습 + 사실/창작 (IN THIS MYSTERY)
- **배우는 것**: 1910년부터의 일본 지배와 '멀리서 일하는 정부'(Intro), 충칭 임시정부, 8월 10일의 첫 소식("may")과 8월 15일의 항복("is over"), 영어 날짜 읽기(the fifteenth of August, 월 먼저), 연합국의 승리와 국내외 한국인의 노력, 광복 = 빛이 돌아옴, 김원봉의 확인 가능한 직책(군무부장)과 광복군이 준비하던 작전이 일본의 항복으로 실행되지 못한 것.
- **사실**: 임시정부의 충칭 이전·광복군 창설(h1), 김원봉 1944년 군무부장(h2), 1945.8.15 항복(h3), 광복은 연합국 승리 + 한국인의 독립운동(h4), 광복의 뜻(h5), 광복군의 국내 진공 준비와 취소(h6), 1919 의열단(h7, reveal만), 1938 조선의용대(h8, reveal만), 1942 광복군 부사령관(h9, reveal만). **새로 필요한 사실**: h10 "8월 10일 무렵 일본의 항복 의사 첫 소식", h11 "1910년 일본의 한국 병합"(§17).
- **창작**: 빛나와 가족(어머니·아빠·남동생), 어머니의 편지 네 통과 뒷면, 상자·자물쇠·타일·태극기, 트렁크, 아빠의 쪽지, 날짜 카드, 라디오의 문장, 사무실·빛나의 방·강가 계단 장면, 김원봉의 모든 대사.
- reveal.inThisMystery (R/J/M)
  - R: "Korea's government in Chongqing, Kim Won-bong's work for its army, the news of 10 and 15 August 1945, and the meaning of gwangbok are real." (25어)
  - R: "Bitna, her mother and father, the letters, the box, the lock, the flag and the radio's words are made up." (20어)
  - R: "Kim Won-bong was real, but his words in this story are made up."(현행 유지)
  - J/M은 현행 문체 패턴("were invented for this story" / "are inventions of this story")을 따른다.
- 김원봉: 1945년 이후 행적은 다루지 않는다. 평가 문장 없음. 감사 PART 5-B의 민감도 메모(P2-3)는 사용자 결정 사항으로 남는다(이번 지시는 "유지").
- 광복군의 여성 대원(어머니 설정): 광복군에 여성 대원이 있었다는 점은 통설이나 dossier에 출처가 없다. 게임 문장은 "Mother is far away with the Liberation Army" 수준만 말하고 역할을 특정하지 않는다. 확인 원하면 h12로 추가(§17).

### 11. R/J/M 핵심 줄 (실제 단어 수, 스크립트로 셈)

| 위치 | ROOKIE | 단어 | JUNIOR | 단어 | MASTER | 단어 |
|---|---|---|---|---|---|---|
| Intro 2 (배경) | Japan has ruled Korea since 1910. So this government works far from home. | 13 | Japan has ruled Korea since 1910, so this government has to work far from home. | 15 | Japan has ruled Korea since 1910; this government must therefore work far from home. | 14 |
| Intro 4 (문제) | A girl runs up to you: "I am Bitna. My mother's box is lost!" | 14 | A girl runs up to you. "I'm Bitna, and my mother's box is lost!" | 14 | A girl hurries over to you. "I'm Bitna, and my mother's box has gone missing!" | 15 |
| Intro 5 (규칙) | "Mother said: open its lock on the day the war is over. That day may be soon!" | 17 | "Mother said to open its lock on the day the war is over. That day may come soon!" | 18 | "Mother told me to open its lock on the day the war is over. That day may come soon!" | 19 |
| M1 letter 1 | "Bitna, I am sorry! I packed Mother's box in a trunk by mistake." | 13 | "Bitna, I'm so sorry! By mistake, I packed Mother's box into a trunk." | 13 | "Bitna, forgive me! In the rush, I packed Mother's box into a trunk by mistake." | 15 |
| M2 letter 4 (관계 문장 포함) | Rain letter: "After my pine letter, the rain came. My boots are wet." | 13 | Rain letter: "After my pine letter, the rain came. My boots are soaked." | 13 | Rain letter: "After my pine letter, the rain came. My boots never dry." | 13 |
| M3 letter 1 | Radio: "On the tenth of August, the first news came: Japan may give up." | 14 | Radio: "The first news came on the tenth of August: Japan may give up." | 14 | Radio: "The first news arrived on the tenth of August: Japan may give up." | 14 |
| Ending 1 | On 15 August 1945, Japan gave up. The war was over. | 11 | On 15 August 1945, Japan surrendered. The war was over. | 10 | On 15 August 1945, Japan surrendered to the Allies, and the war was over. | 14 |
| Ending 2 | "In Korean, this day is gwangbok: the light comes back." | 10 | "In Korean, we call this day gwangbok: the light comes back." | 11 | "In Korean, this day is called gwangbok: the return of the light." | 12 |

- **레벨마다 글자까지 같게 두는 줄**(정보 동일 + 엔진/검사 대조): M2 관계 문장 2개("After my pine letter, the rain came." / "The rain is over now."), 어머니의 뒷면 세 줄과 규칙("The sun gives it." / "At night, it goes away." / "It comes back on the day the war is over." / "'May' is not enough."), 자물쇠 문구("Five letters. Two tiles are extra."), M3 "the fifteenth of August"·"August is month eight". dossier clue 문구가 레벨마다 보이는지 검사하므로(`history_dossier.dart:499` `history_clue_not_shown_at_level`) 이 고정이 필요하다. 'may'는 J/M에서도 might로 바꾸지 않는다(규칙 "'May' is not enough."와 맞물림).
- J M1 줄은 처음 12어였으나 R(13)보다 짧아 "so"를 넣어 13어로 맞췄다(rookie 테스트 첫 단언은 R < J 비교를 하므로, C12가 비교 대상이면 이 줄 하나가 아니라 미션 전체 합으로 판단된다. 전체 합은 생성 후 확인).

### 12. 기존 대비 유지/변경

| 항목 | 기존 | 새 설계 | 처리 |
|---|---|---|---|
| 제목 | The Day the Light Returned(정답 노출) | The Box That Waited | 변경 |
| 사건 목표 | 서울 상자의 쪽지 순서 + 마지막 쪽지 | 어머니 상자를 찾아 '그날' 연다 | 변경(독립) |
| Intro | 미리가 상자를 보냄, 의자 위 물방울 쪽지 | 1910 배경, 빛나의 분실 신고와 어머니 규칙 | 변경 |
| 김원봉 | 맞이 + 라디오 + "since 1919" 결말 | 맞이 + 짐 싸기/첫 소식 + 라디오 + 광복 뜻·직책 | 유지(확인 가능한 활동만) |
| 빛나 | 해수의 딸, 마지막 지키미 | 충칭의 소녀, 광복군 어머니와 사무실 직원 아빠의 딸 | 유지(정체를 Case 안에서 새로 밝힘) |
| M1 트렁크 추론 | 끈 하나 + 둥근 놋쇠 | 같음. 쪽지 주인 = 아빠(실수로 쌈) | **유지**(그림·좌표·보기·피드백 그대로) |
| M1 보상 | 타일 H | 자물쇠 규칙(5칸, 7장, 2장 가짜) | 변경 |
| M2 | 지키미 쪽지 6장(분이~미리) 순서 | 어머니 편지 4장 순서 + 뒷면 수수께끼 | 변경(엔진 같음) |
| M2 recall | `s5_ep08_e4`(C08 상자) | 없음 | 삭제 |
| M3 | 815, 715/814/915 | 815, + 810('may' 날) 미끼, 어머니 규칙 줄, 같은 Case recall(e2) | 유지 + 보강 |
| Final | 정답 글자 5장 애너그램, "opposite of dark" | 증거 대화 2단계 + 7장 중 5장(N·R 미끼), 수수께끼 | 변경(정답 LIGHT 유지) |
| Final evidenceLink | `s5_ep01_e3`(C01) | 없음 | 삭제 |
| Ending | 분이 첫 쪽지 회수, 시즌 종료 | 상자 열림·태극기·광복 뜻·연합국과 한국인·직책 | 변경 |
| 장소·지도 | 사무실/빛나의 방/강가 계단, 핀 4개 | 같음 | 유지 |

### 13. 외부 의존 원장 (현재 C12의 모든 타 Case 요소 → 처리)

| # | 위치(현행) | 내용 | 기능이 이 Case 안에 있나 | 처리 |
|---|---|---|---|---|
| 1 | `title` | "…Light Returned" | — (정답 노출) | 새 제목 |
| 2 | `synopsis` | old letter box, keeper, last water-drop note | 없음 | 교체(§4) |
| 3 | `goal`, `play.objectives` | letter box, keepers' notes, last water-drop note | 없음 | 교체(§4) |
| 4 | `play.intro[3]` | "Miri sent the old letter box here from Seoul." | 없음(C11) | 삭제 |
| 5 | `play.intro[4]` | 의자 위 물방울 쪽지 | 쪽지는 필요 → 아빠 쪽지로 Case 안에서 설명 | 교체(책상, 아빠) |
| 6 | M1 `clueInputs` `s5_ep11_e4` textMention | 미리가 상자를 보냄 | 없음 | 삭제(빈 목록) |
| 7 | M1 story "Miri's box came from Seoul", "blue water drop" | | 없음 | 교체 |
| 8 | M1 talk "A box came for you from Seoul. A girl knows where." | | 없음 | 교체(아빠가 실수로 쌈) |
| 9 | M1 letter "The box from Seoul…", "small wooden tile" | | 트렁크 조건만 필요 | 2·3번 줄 유지, 1·4번 교체 |
| 10 | M1 explore task/spot title "WATER-DROP NOTE", 책장 "No water drop here." | | 없음 | 교체(spot id·좌표 유지) |
| 11 | M1 evidence e1 "The Water-Drop Note (1945)… King's letters…" | | 쪽지 자체는 필요 | 내용 교체(Father's Note) |
| 12 | M1 transition "letter box from Seoul", discovery "An H, with a water drop" | | 없음 | 교체 |
| 13 | M2 `clueInputs` `s5_ep08_e4` recall + `play.recall`("Gyeongsun showed you") | C08 상자 | 없음 | 삭제 |
| 14 | M2 timeline 카드 `bun_i`·`seok`·`okbun`·`duri`·`gyeongsun`·`miri` | C01~C11 지키미 | 순서 메커니즘만 필요 | 카드 삭제 → 어머니 편지 새 카드 4장, `drawing` 유지 |
| 15 | M2 letter "Inside the lid, Haesu wrote", relations(Seok/Okbun/Duri/Gyeongsun) | C09·C10 해수 | 없음 | 교체(어머니 편지 줄) |
| 16 | M2 story "My mother Haesu keeps this box", talk "Every note in here has a water drop." | | 없음 | 교체 |
| 17 | M2 evidence e2 "Haesu's Lid", clue c2 "TILES: T · I", transition "tiny water drop painted" | | 없음 | 내용 교체(Mother's Letters / Mother's Riddle) |
| 18 | M2 learning expressions "Seok wrote before Okbun." / "It is the oldest." | | 없음 | 교체("After my pine letter, the rain came." / "The rain is over now.") |
| 19 | M2 puzzle.notes(keepers, dossier fiction years) | | 없음 | 교체 |
| 20 | M3 discovery "Bitna writes the date on the last note.", c3 "TILES: G · L", transition 타일 | | 날짜만 필요 | 교체 |
| 21 | Final story "I am the keeper now", lockTitle "THE KEEPERS' LAST LOCK" | | 없음 | 교체 |
| 22 | Final transition "Bun-i's first note lies under eleven more." / "The season ends." | C01, 시즌 | 없음 | 교체(태극기) |
| 23 | Final `clueInputs` `s5_ep01_e3` evidenceLink + `evidenceLinkLine` | C01 | 없음 | 삭제(둘 다) |
| 24 | Final ending detective "Bun-i's first note started it all." (evidence `s5_ep01_e3`) | C01 | 없음 | 삭제 → e4 줄 |
| 25 | Final evidence e4 "The Last Note… 광복" / inscription 한글 | 시즌 | 없음 + 한글 규칙 | 내용 교체(Mother's Flag) |
| 26 | `caseSummary` "Haesu's daughter, last keeper… Bun-i's first note" | | 없음 | 교체(§9) |
| 27 | case `notes`[1] "Haesu (Case 09-10) is named only" | | 없음 | 교체 |
| 28 | `levels.json` J/M의 위 모든 줄 | | | R과 함께 교체 |
| 29 | dossier `fiction`[0] keepers' notes 1446–1941, Haesu's lid; `puzzles` m2·final | | 없음 | 교체(§17) |
| 30 | `season.plan.json` characters bitna role "The last keeper, Haesu's daughter" | | 없음 | "A girl in Chongqing whose mother is with the Korean Liberation Army (made up)" |
| 31 | `planning/story_bible.json` bitna·상자 서술, `season.plan.json` story.truth(지키미 가족) | 시즌 틀 | C12 범위 밖이지만 C12 서술과 충돌 | 시즌 문서 정리 PART에서 함께 처리(이 문서는 C12 줄만 지정) |
| 32 | `season.levels.json` "Find the keepers." 등 시즌 목표 | 시즌 틀 | C12 범위 밖 | 시즌 정리 PART에 넘김 |

- 검색으로 확인: C12를 참조하는 다른 Case는 없다(`grep s5_ep12` → C12 자기 파일, 생성물, `seoul_case_maps_test`, `s5_seoul_rookie_test`뿐). 그러므로 C12 증거 내용을 바꿔도 다른 Case가 깨지지 않는다.

### 14. 인과관계 표

| 단계 | 필요 이유 | 이전 단계에서 얻은 것 | 행동 | 상태 변화 | 다음으로 가는 이유 |
|---|---|---|---|---|---|
| Intro | 빛나의 상자가 사라짐, 오늘이 그날일지도 | — | 읽기 | 문제와 규칙(전쟁이 끝난 날에만) | 상자 찾기 |
| M1 | 상자의 위치 | 김원봉: 아빠가 실수로 쌌고 쪽지를 남김 | 둘러보기 → 쪽지 → 트렁크 고르기 | 상자 확보, 자물쇠 규칙(5글자, 2장 가짜) | 낱말을 모름 → 어머니 편지가 있는 방 |
| M2 | 어머니의 말 찾기 | 상자(윗칸의 편지), 첫 편지의 지시 | 편지 4장 순서 + 그림 버리기 | 수수께끼 2줄 + "돌아온다" + 'may' 규칙 | 오늘이 '끝난 날'인지 라디오로 확인 |
| M3 | 여는 날 확인 | 'may' 규칙(recall e2) | 815 입력(810 거름) | 날짜 카드(오늘이 그날) | 낱말을 넣기 전, 빛나가 확인을 원함 |
| Final | 규칙대로 열기 | e3(날짜), e2(수수께끼), c1(타일 규칙) | 증거 2개 제시 → 7장 중 5장 LIGHT | 상자 열림, 태극기 | 이날의 이름 |
| Ending | Intro 문제의 해결과 역사 | e4 | 읽기 | 광복 = 빛이 돌아옴, 어머니의 낱말의 뜻 | — |

### 15. 독립성 검증 표

| 검사 | 결과 |
|---|---|
| 다른 Case의 증거·clue id 참조(clueInputs, recall, present offered/accepted, evidenceLink, ending evidence) | **0건**(모두 `s5_ep12_*`) |
| 다른 Case 인물 이름(분이·석·옥분·두리·한 상궁·봉수·강 부인·경순·해수·미리·소라) | 0건 |
| 시즌 틀 표현(water drop, keeper, letter box from Seoul, twelfth/last note, the season ends) | 0건 |
| 앞 Case를 알아야 풀리는 퍼즐 | 없음. M2 순서는 편지 문장만으로, M3는 라디오·카드·규칙으로, Final은 이 Case의 수수께끼로 풀린다 |
| 역사 배경을 이 Case 안에서 설명 | 1910 지배·멀리 있는 정부(Intro 2), 8.10 첫 소식(M1 대화, M3), 8.15(M3), 광복·연합국·한국인·직책(Ending) |
| 등장인물 정체를 이 Case 안에서 설명 | 빛나·어머니·아빠·남동생(Intro, M1 대화, M2), 김원봉(Intro 3, Ending 6) |
| Case 01을 바꾸는가 | 아니다 |

### 16. 어린이 시뮬레이션 (설계 검토이며 실제 어린이 테스트가 아님)
- **M1 (8세 R)**: 트렁크를 먼저 누르면 "Read the note on the desk first." → 쪽지 → 끈을 센다. 감사에서 이미 좋은 설계로 평가된 흐름이라 막힐 곳이 적다. "by mistake"를 모를 수 있다 → glossary에 `by mistake: 실수로` 추가 권장.
- **M2 (8세 R)**: 카드 5장, 놓을 것 3장이라 짧다. 가장 흔한 실수는 달 편지를 칸 2에 놓는 것(달 그림이 눈에 띔) → 엔진이 "The rain is over now." 줄을 짚고 H2가 같은 줄을 풀어 준다. "The rain is over now"에서 '비 편지 다음'을 끌어내는 것이 이 미션의 작은 추리다.
- **M3 (8세 R)**: 810을 먼저 칠 가능성이 있다(첫 줄에 나오는 숫자) → 피드백이 어머니 규칙을 짚는다. 한국 어린이는 8·15를 이미 알 수 있다. 그래도 영어 서수와 'may/is over'를 읽어 확인하는 구조라 퍼즐이 무너지지 않는다.
- **Final (8세 R)**: 앞 대화에서 날짜 카드와 편지를 헷갈릴 수 있다 → miss가 "what day / no riddle"로 구분하고, 2회 오답이면 tell(2b3). 자물쇠에서는 첫 타일 N 때문에 NIGHT를 먼저 칠 수 있다 → "Night is when it goes away." 피드백. 12세 M은 대화와 자물쇠 모두 쉽게 넘길 것이다(Final 난도는 '증거를 모아 규칙대로 여는 이야기' 쪽에 무게).
- **막힐 수 있는 곳**: 편지 본문(M2 letter)은 퍼즐 화면에서 Reread로만 다시 보인다(공통 P2-4). 관계 문장은 엔진이 오답 때 짚어 준다.

### 17. dossier 변경 (`planning/history_dossier.json` s5_ep12)
- `subject`: 유지. `location`: "Chongqing, China (the office, Bitna's room and the river steps made up)".
- `facts` h1~h9: 유지. **추가 제안**(status는 출처를 연 뒤 `source_checked`):
  - **h10** "Around 10 August 1945 the first news came that Japan would surrender; Japan surrendered on 15 August." — 후보 출처: 한국민족문화대백과 「8·15광복」, 『백범일지』(김구가 시안에서 8월 10일 소식을 들은 기록), 우리역사넷. **출처 미확인**(이번 작업은 웹 확인을 하지 않았다). 확인 전에는 M3 1번 줄과 M1 대화의 "10 August"를 "first news"로만 쓰고 날짜는 빼는 대안이 있다(그러면 810 미끼는 "the first news" 날로 유지).
  - **h11** "In 1910 Japan annexed Korea and ruled it until 1945." — Intro 2번 줄의 근거. 다른 Case(C07/C08)에 같은 사실이 들어갈 예정이면 각 Case dossier에 따로 둔다(독립 정책).
  - (선택) **h12** 광복군에 여성 대원이 있었음 — 어머니 설정의 개연성. 게임 문장이 역할을 특정하지 않으므로 필수 아님.
- `fiction` 교체:
  - "Bitna, her mother, father and brothers, Mother's four letters and the lines on their backs, the box, its word lock and tiles, and the flag inside are made up."
  - "The trunks, Father's note, Bitna's date card, the radio's words, the office, Bitna's room and the river steps are made up; how the news reached the office is not claimed."
  - "Kim Won-bong is real, but everything he says and does in the case is made up; none of his lines is a quotation. His life after 1945 is outside the case."(유지)
- `puzzles` 교체(clue `text`는 **R/J/M 모두에 글자 그대로 있는 문구**만):
  - m1: 유지(clues "ONE leather strap", "round brass lock").
  - m2: answer `first_letter,pine_letter,rain_letter,moon_letter` / clues ["After my pine letter, the rain came.", "The rain is over now."] / derivation "The first letter (April) is fixed. The rain letter came after the pine letter; the moon letter says the rain is over, so it came after the rain letter. The drawing is not a letter." / whyOnly "Two relations make one chain after the fixed first letter."
  - m3: factIds [h3, h10] / clues ["the fifteenth of August", "August is month eight", "'May' is not enough."] / derivation "The tenth was only a 'may' day; Mother's rule rules it out. Today, the fifteenth, the war is over: month eight first, 815." / whyOnly에 810 추가.
  - final: factIds [h5, h3, h4] / clues ["Two tiles are extra.", "The sun gives it.", "At night, it goes away."] / derivation "Five of the seven tiles: the sun gives it and at night it goes away: LIGHT. NIGHT is what takes it away; RIGHT and THING are not given by the sun." / whyOnly "Of the five-letter words the tiles make, only LIGHT fits all three lines."
- `learningObjectives` m2·final 교체(위 learning.objective와 같은 뜻의 영어).
- `reveal.realHistory`: 유지(6줄). `reveal.inThisMystery`: §10의 줄로 교체.
- h7(1919 의열단) factId는 final `factIds`에서 빠진다(Ending에서 1919 줄을 뺐으므로). reveal에는 남는다.

### 18. ID·저장 영향
- **mission id**: `s5_ep12_m1`·`m2`·`m3`·`s5_ep12_final` 모두 유지. 미션 수 3 + Final 유지. placeId·location 이름 유지(지도 핀 영향 없음).
- **evidence id** e1~e4, **clue id** c1~c3: 모두 유지, 내용만 교체. 증거는 콘텐츠에서 다시 계산되므로 이미 C12를 푼 사람의 수첩에도 새 이름이 보인다(의도한 동작). 다른 Case가 C12 증거를 참조하지 않으므로 파급 없음.
- **새 id**: timeline 카드 `first_letter`·`pine_letter`·`rain_letter`·`moon_letter`, Final present `today`·`riddle`. 삭제되는 카드 id: `bun_i`·`seok`·`okbun`·`duri`·`gyeongsun`·`miri`(카드 id는 정책상 보존 대상 id가 아니고, 뜻이 바뀌므로 새 id가 맞다). `drawing`은 뜻이 같아 유지.
- **M2 진행 중 저장**: `puzzleStates['s5_ep12_m2']`(`pv2:timeline`)는 슬롯 6 → 4로 바뀌어 `fromJson`이 null을 돌려준다(`timeline_rules.dart:345` 길이 검사, `:348` 모르는 카드 id 검사) → 보드가 처음 상태로 돌아간다. 오류 없음.
- **M2 recall 흔적**: `examined`의 `s5_ep12_m2:recall`은 무해하게 남는다(recall이 없어지면 읽히지 않음). M3의 새 recall 키 `s5_ep12_m3:recall`은 새로 생긴다.
- **Final**: 새 대화 키 `TalkMission.beforeKey('s5_ep12_final')`(`final_mission_screen.dart:884,976`). 이미 Final을 푼 사람은 `solved`라 대화를 건너뛴다. 자물쇠 상태는 저장되지 않는다.
- **answer 문자열 변경**: M2만(`bun_i,…,miri` → 새 4장). M1 `one_strap_lock`, M3 `815`, Final `LIGHT`는 그대로. 완료 기록(completedAt)은 정답 문자열과 무관하게 유지된다.

### 19. 필요한 엔진 변경 (engine_save_impact.md §2의 계획된 변경만 사용, 새 변경 없음)
- **2a 글자 자물쇠 미끼 타일 — 필수.** 지금은 슬롯 수 = 타일 수(`letter_lock.dart:44`)이고 검사는 "타일 = 정답 글자"(`puzzle_selection_check.dart:358-363`)라 7장 데이터가 생성 단계에서 막힌다. 2a 후: 슬롯 5 = 정답 길이, 검사 "정답 글자 ⊆ 타일".
- **2b2 present 카드 3장 — 권장**(없으면 §8의 2장 대안). **2b3 2회 오답 → tell, 3회 → 빛남 — 권장.** **2b1 대화 힌트 버튼 — 권장**(present가 2개뿐이라 없어도 진행 가능).
- 2f(Final recall 표시)는 쓰지 않는다. M3 recall은 미션 recall이라 지금 코드로 보인다.
- timeline·number_entry·scene_explore는 엔진 변경 없음.
- 플레이 드라이버: `SandboxPlay.answer`의 letterLock 경로가 2a 뒤 미끼 타일을 무시하고 정답 글자만 탭하는지 엔진 PART에서 확인(`test/sandbox/sandbox_play.dart:66-125`).

### 20. 이미지
- **새 그림 없음.** 재사용: `office.webp`(M1·M3), `trunk_two_straps`·`trunk_one_strap_peg`·`trunk_one_strap_lock`(M1 보기), `family_room.webp`(M2), `river_steps.webp`(Final), 초상 `bitna.webp`·`kim_wonbong.webp`. 모두 열어서 이야기와 맞는지 확인했다(§5·6·8의 '그림 확인').
- 그림과 이야기의 작은 차이(허용 범위): ① office의 쪽지는 파란 봉인 → "a folded note with a blue seal"로 부른다. ② family_room의 상자는 뚜껑이 열려 있다 → "윗칸은 열리고 아랫칸이 잠긴 상자"로 설정해 맞춘다. ③ 빛나 초상은 작은 나무 조각(타일)과 붓을 들고 있다 → 자물쇠 타일·날짜 카드와 어울린다. ④ 태극기는 그림이 없다 → Final transition과 Ending 텍스트로만 보여 준다(e4 아이콘 `seal`). 태극기 증거 그림이 꼭 필요하면 사양: "작게 접힌 손바느질 태극기, 1945년 무명천, 나무 상자 아랫칸 안, 해 질 녘 빛, 시즌 수채 톤, 1536×1024, 사람 없음" — 지금은 **요청하지 않는다**(텍스트로 충분).
- R2 팩 영향 없음(그림 파일 불변).

### 21. 테스트 영향
- `test/sandbox/s5_seoul_rookie_test.dart` C12 M3(:139-145): 단언 그대로 통과. **810 피드백 단언 추가 권장**(`answers(m, {'810': true, …})` 패턴).
- `test/seoul_case_maps_test.dart`(:103-107): 미션 장소 이름·핀 그대로 → 영향 없음.
- `test/generated_seasons_test.dart` → `season_playthrough`(Seoul R/J/M): 생성물 일치, validator, 둘러보기 측정(office 해시 불변), 12 Case 플레이. Final 대화 present 2개와 미끼 자물쇠를 드라이버가 처리해야 한다(2a·2b 엔진 PART에서 함께 확인).
- 생성 검사에서 볼 규칙: `timeline_line_unread`, `timeline_card_unrelated`, `timeline_size`, `timeline_options_mismatch`, `play_link`(evidenceLinkLine 삭제), recall 1개 규칙, `history_clue_not_shown(_at_level)`, Hangul 위치 규칙, 레벨 줄 수 동일.
- 새 테스트 권장 1개: C12 Final — 타일 7장, 슬롯 5칸, NIGHT/RIGHT/GLINT 피드백, LIGHT 통과(2a 위젯 테스트와 함께).

### 22. 작업량: **M**
- 바뀌는 파일: `s5_ep12/case.plan.json`, `s5_ep12/levels.json`(J/M 전부), 재생성 `s5_ep12.g.dart`·`s5_ep12_levels.g.dart`·`s5_seoul_history.g.dart`·`s5_seoul_cases.g.dart`(제목)·manifest, `planning/history_dossier.json`(§17), `season.plan.json`(bitna role 한 줄), `test/sandbox/s5_seoul_rookie_test.dart`(810 단언 추가). 시즌 문서(story_bible·season.plan truth·season.levels 목표)는 시즌 정리 PART.
- 선행 조건: 엔진 PART 2a(필수), 2b1~2b3(권장).

### 23. 위험과 대응
- **2a 없이 데이터를 넣으면 생성이 막힌다** → 엔진 PART를 먼저(engine_save_impact 권고 순서).
- **GLINT 다중 정답 위험**: 사전상 GLINT도 7장으로 만들어지고 '해가 주는 반짝임'으로 억지 해석이 가능하다. 대응: 전용 피드백("Mother's word fills the whole day."). 더 줄이려면 미끼를 N·R 대신 R·P 등으로 바꿀 수 있으나 그러면 NIGHT 미끼(수수께끼 2번 줄과 맞물리는 좋은 미끼)가 사라진다. 권장: N·R 유지.
- **h10(8월 10일) 출처 미확인**: 확인 전에는 날짜를 "the first news"로만 쓰는 대안(§17).
- **M2 순서의 필연성이 약하다**(§6 정직한 평가): 순서는 어머니의 지시·읽기 학습·이야기 흐름의 몫이고, 뒷면 문장 자체는 순서와 무관하게 읽힌다. 더 강하게 하려면 그림(뒷면을 이으면 한 줄이 되는 편지)이 필요하다 → 지금은 하지 않는다.
- **Final 난도**: 수수께끼가 쉬워 12세 M에게는 가볍다. 결말의 무게는 '증거로 빛나를 설득하고 규칙대로 연다'와 '어머니의 낱말 = 광복의 빛'이라는 Ending의 깨달음에 둔다.
- **김원봉 민감도**(감사 P2-3): 사용자 결정 "유지". 이 설계는 직책(h2)·광복군 준비(h6)만 말하고 평가하지 않는다.
- **시즌 문서 불일치**: season.plan의 story.truth(지키미 가족)와 story_bible은 C12 범위 밖이라 그대로 두면 문서와 게임이 어긋난다 → 시즌 정리 PART에서 함께 고친다.

> §I-2 결정 반영(C12 Final): 타일 N H T I R G L로 만들 수 있는 GLINT·NIGHT·RIGHT·THING·GIRTH 모두에 전용 오답 피드백을 두고, 수수께끼가 LIGHT 하나만 가리키는지 구현 때 다시 검사한다.

---

# PART 1A 결과 (2026-11-09 구현) — Case 02~11 독립화 + C10 P1

**범위:** Case 02~11의 Case 간 의존성 제거, C10 M2 모순 수정, 시즌 공통 설정 정리. 아래는 하지 않았다.
- C12 콘텐츠 → PART 1B
- Final 재설계, 엔진 변경, 그림, R2, 다른 시즌, Case 01 V4, 커밋·푸시

## 1. 변경 파일

| 구분 | 파일 |
|---|---|
| Case 데이터 | `content_pipeline/seasons/s5_seoul/cases/s5_ep{02..11}/case.plan.json`, `levels.json` (20개) |
| 시즌 | `content_pipeline/seasons/s5_seoul/season.plan.json`, `season.levels.json` |
| 기획 문서 | `planning/story_bible.json`, `planning/history_dossier.json` |
| 생성물(재생성) | `lib/data/generated/s5_seoul/` 중 `s5_ep02~11.g.dart`·`_levels.g.dart`, `s5_seoul_season.g.dart`, `s5_seoul_levels.g.dart`, `s5_seoul_history.g.dart`, `generated.manifest.json`. **`s5_ep01*`·`s5_ep12*`·art·cases·content는 바이트 단위로 같다** |
| 테스트 | `test/sandbox/s5_seoul_case01_test.dart`: "Case 08이 분이 편지를 찾는다" 3개 → "Case 08 엔딩은 자기 이야기다(엄마·Bun-i·letter box 없음)". `test/sandbox/s5_seoul_syllables_test.dart`: C02 단어 풀이 `gums` → `lips`, 그리고 C02 M2 글자판이 모든 레벨에서 ㅁ·ㅂ을 가르치고 Sora를 말하지 않는다는 검사 추가 |
| 되돌린 파일 | 검사 도구가 다시 쓴 파생 보고서 `planning/quality_report.json`, `planning/puzzle_selection.json`은 작업 전 상태로 복원했다 |

## 2. Case·Mission별 수정 (외부 의존 제거)

| Case | 지운 외부 의존 | Case 안에서 완결한 내용 |
|---|---|---|
| C02 | M2 recall `s5_ep01_e2`(Sound Board), M1·Final clueInputs `s5_ep01_c1`, Bun-i discovery, Sora 문구, 엔딩 "just like Bun-i's", "Who taught my grandmother?" | M2 **"THE SAILORS' LETTER BOARD"**(창고 벽)가 ㅁ = the lips, a stronger sound adds one line, ㄴ+1=ㄷ, **ㅁ+1=ㅂ**를 가르친다. 함은 "I read only Chinese letters." M3에서 석이 "I drew a water drop for him. It means rain."이라고 말한다. 엔딩은 석의 두 줄(누구나 배울 수 있는 글자). 단어 풀이 `gums` → `lips`, `chinese`, `board` |
| C03 | M1 recall `s5_ep02_e1`, discovery "THE SAME WATER DROP", 석·1592 엔딩 두 줄 | discovery "A WARNING ON THE ROPE". 엔딩에서 옥분이 이름 대신 물방울을 그린 이유를 말한다(물 긷는 아이는 일꾼들에게 틀렸다고 말할 수 없다) |
| C04 | M1 recall `s5_ep01_e2`, "Sora's board" 줄, Final present `note`(C02·C03 증거를 받던 것), 가문 대사, **"But why?"** | 두리가 M1 대화에서 **"Carvers' rule"**(a stronger sound gets one more line)을 가르친다. M2 장부와 e2에 "counted by Duri, a small water drop by his name"을 넣었다. Final present **새 id `p_writer2`**는 e2를 받는다(장부의 물방울 = 쪽지를 쓴 사람). 엔딩에서 두리가 이유를 말한다 |
| C05 | M2 recall `s5_ep04_e1`(두리의 쪽지), "our letters" 대사, 다음 쪽지 예고, 나무 상자 전환 | M2 recall → **같은 Case `s5_ep05_e1`**. 한 상궁이 물방울을 자기 표시라고 말한다 |
| C06 | M1 recall `s5_ep05_e1`, M2 "strangers' map of 1895" 줄, 봉수 쪽지의 물방울, 다음 Case 예고 hook | Intro에 1897 왕 → 황제 한 줄. e1 "Bongsu's Note" |
| C07 | M1 recall `s5_ep06_e1`, "letter box", 1919 예고, Final present `why`가 받던 `s5_ep06_e4` | Intro에 이토·1905 조약 설명. 강 부인 쪽지(e1)에 이토·1905 줄을 넣었고 `why`는 e1을 받는다(질문이 같아 id 유지). 엔딩은 여관 벽에 바른 기사를 붙이는 것 |
| C08 | M3 recall `s5_ep07_e1`, **엔딩의 분이 편지·"엄마, 고마워요"·`s5_ep01_e3` 줄(사용자 승인 삭제)**, 가족 공개, 지키미 상자 | 표식을 **물방울 → 작은 불꽃**으로 바꿨다(M1 쪽지, M3 공책 특징, 단서·증거). M3 recall → **같은 Case `s5_ep08_e1`**. e4 "The Locked Plan". 경순이 이름을 쓰지 않은 이유를 말한다. Intro에 1910 병합·3·1운동 |
| C09 | M1 recall `s5_ep08_e4`(지키미 상자), "Gyeongsun is my cousin / old box", C10 예고, 물방울 | 해수: "A spy may be in this office. So I did not sign my note." Intro에 1910·3·1·상하이 정부 설명. 단어 풀이 `independence` 추가. Mr. Pak 유지 |
| C10 | M1 recall `s5_ep09_e4`, 물방울 서명, 지키미·상자·"Miri takes the box" 줄 | Intro에 "Haesu, a young clerk of the Provisional Government, works for him." M1 쪽지는 "signed by Haesu"(e1 "Haesu's Breakfast Note") |
| C11 | clueInputs `s5_ep10_e1`, `s5_ep01_c1`, Bun-i 힌트·오답, 해수 사촌, "keepers' mark", 상자·충칭 줄, "King's letters" | 물방울은 **미리의 서명**이다. M1에서 윤동주: "Only Miri came in tonight. She brings water to our rooms." M3에서 미리가 이유를 말한다. Final 편지는 Hangeul을 Case 안에서 설명한다(정답 KOREAN 유지) |

## 3. C10 P1 모순 수정 (M2 "Which Watch?")

- **전:** 김구가 손에 시계를 쥐고 있는데, 해수가 "그의 낡은 시계"를 탁자에 놓는다. 그런데 윤봉길이 그 낡은 시계를 가져갔다고 한다. 같은 시계가 두 곳에 있었다.
- **후 (R):** "Mr. Kim sits by the window. His hand is closed around the watch." / Haesu opens her notebook. "I drew every watch I saw this morning." / 편지에 "My own watch is small, on a leather strap. It is on my arm." 그리고 "I can see a chain between Mr. Kim's fingers."
- **보기:** 그림 파일은 그대로 두고 altText만 "Haesu's drawing of …"로 바꿨다. 정답 `new_watch`는 그대로다.
- **풀이 경로:**
  1. 줄이 보인다 → 가죽 끈 시계가 아니다.
  2. 끈 시계는 해수의 팔에 있다.
  3. 두 사람은 시계를 바꿨다 → 낡은 시계는 윤봉길이 가졌다.
  4. 남는 것은 매끈한 새 시계다.
- 김구의 M2 대사는 지웠다(장면에서 말하지 않으므로). J/M도 같은 정보를 담는다.
- 역사 구분: 1932년 4월 29일 두 사람의 시계 교환은 『백범일지』의 사실이다. 해수와 그림은 창작이다(dossier fiction·reveal에 반영).

## 4. 시즌 공통 설정

- **프롤로그:** 키, 줄 수, 그림은 유지하고 17줄 중 11줄을 바꿨다. 12개의 서로 다른 역사 사건으로 소개한다("Twelve cases, in twelve times of Seoul's story." / "Each one is a mystery of its own." / "What really happened, and why?" / "Every case is built on a true story of Korea." / "Look closely. Read the clues. Solve each case."). 아웃트로·피날레는 시즌 미스터리 없이 다시 썼다. R/J/M 모두.
- **`season.plan.json`:** mainMystery를 "시즌을 잇는 범인·미스터리 없음"으로 바꿨다(필수 필드라서 `revealCase`는 `s5_ep12`). 인물 설명의 keeper·가족·사촌·딸 표현을 지웠다. Act 1 주제는 "THE WATER-DROP NOTES" → "LETTERS, SHIPS AND PALACES".
- **`story_bible.json`:** coreMystery, logline, ending, act 전환점을 다시 썼다. 모든 Case의 fromPrevious/toNext는 "None: a standalone case." mysteryQuestions는 5 → 1(Case 01 것만). **clueThreads는 39 → 20**이다(Case 간 19개 삭제, Case 내부 것과 Case 01 것은 유지).
- **dossier:**
  - Case 간 fact 참조 4곳을 **출처가 확인된 같은 사실의 Case 내 사본**으로 바꿨다: C02 `s5_ep02_h7~h10` ← C01 h3·h10·h11·h12, C04 `s5_ep04_h8` ← C01 h10, C07 `s5_ep07_h5` ← C06 h1, C10 `s5_ep10_h5` ← C09 h1.
  - fiction·reveal·derivation의 keeper·box·Bun-i 문구를 Case 안의 표현으로 바꿨다.
  - clue 문구 2개: C08 "A small flame sits by her name.", C11 "in Hangeul".

## 5. 검증 결과 (실제 실행)

| 검사 | 결과 |
|---|---|
| `case_levels check --season` | exit 0. 12 Case + 시즌 줄 "every level written, the same game" |
| `generate_season --target game` → `--check` | 생성 exit 0, 이후 check exit 0(최신) |
| `plan_season check` | **ERROR 8건, 모두 작업 전과 같은 기준선**(Case 01 그림 경로 3, 그림 크기 3, Case 01 내부 clueThread 2). 새로 생긴 오류 0. 새 경고는 `clue_never_used`뿐(원래 다음 Case가 쓰던 증거, 예상된 결과)이다. 처음 생겼던 ROOKIE 15어 초과 6건, `independence` 어려운 단어, 프롤로그 오탐은 고쳐서 0 |
| `build_manifest --check` | 최신(그림 변경 없음) |
| **Case 02~11 외부 참조 검사**(plan, levels, 생성 `.g.dart`에서 다른 Case id, keeper, letter box, Bun-i, Sora, 1446, "same mark/drop", "But why?") | **다른 Case id 0건.** 남은 단어는 모두 그 Case 안의 비교다(C04 쪽지 ↔ 장부, C08 쪽지 ↔ 공책, C11 "But why?"는 윤동주의 질문) |
| id·정답 비교(작업 전 백업 대비) | mission·evidence·clue id 삭제 0. **정답 변경 0.** present 변경은 C04 `note` → `p_writer2` 1건. timeline 카드 id 변경 0 |
| 난이도별 일치 | `case_levels check`로 정답·선택지·줄 수가 같은지 확인했다. 바꾼 줄은 R/J/M 모두 같은 정보로 썼다. C10 M2는 세 레벨을 직접 대조했다 |
| Case 01 V4 | `cases/s5_ep01/*`, `s5_ep01*.g.dart`, V4 설계 문서의 SHA-256이 작업 전과 같다 |
| 다른 시즌 | 다른 시즌의 `lib/data/generated/**`, `content_pipeline/seasons/*`(s5 제외), `lib/data/mock/**` SHA-256이 작업 전과 같다 |
| `flutter analyze` | **No issues found** |
| Seoul 테스트 10개 파일 | 작업 전 기준선 308 통과 / 1 실패(테스트 도중 plan이 바뀌어 난 "생성물 최신" 검사, 작업 중 상태 탓) → 작업 후 **309 통과 / 0 실패**. 대상: `s5_seoul_rookie`, `case11`, `syllables`, `case01`, `play`, `traces`, `gate`, `dev_mode`, `seoul_case_maps`, `generated_seasons` |
| 기타 관련 테스트 | `season_factory/season_pack_deploy_test`, `season_factory_test`, `puzzle_palette_test`, `puzzle_engine_collisions_test`: **59 통과** |
| 전체 `flutter test` | **실행하지 않았다**(엔진·공용 코드 변경이 없는 콘텐츠 PART). 신규 회귀는 위 범위에서 0 |

## 6. 저장 호환성

- 완료 기록은 유지된다. 미션 id와 Case 잠금·해금 방식은 바뀌지 않았다.
- 증거는 저장되지 않고 콘텐츠에서 매번 다시 계산된다. 그래서 이름과 설명이 바뀐 증거(예: C08 e4 "The Locked Plan")는 이미 푼 플레이어의 수첩에도 새 내용으로 보인다.
- recall: 지운 recall 7건(C02·C03·C04·C06·C07·C09·C10)과 같은 Case 증거로 바꾼 2건(C05·C08)은 recall 선택 기록이 저장돼 있어도 콘텐츠에 없으면 쓰이지 않는다.
- **C04 Final을 진행하던 플레이어:** 저장된 대화 진행에서 `note` 단계는 버려지므로 `p_writer2` 단계를 다시 해야 한다(decode가 모르는 id를 버린다, §E 3.2). 오류는 나지 않는다.
- C07 `why`는 id를 유지했다. 이미 그 단계를 끝냈다면 완료로 남는다.
- **C12에 남는 영향(PART 1B):** C12가 recall하는 `s5_ep08_e4`의 내용이 "The Locked Plan"으로 바뀌었다. C12를 1B 전에 플레이하면 recall 카드의 내용이 C12 대사와 맞지 않는다.

## 7. PART 1B로 넘길 것

- **C12 외부 참조**(이번 범위 밖, 그대로 둠):
  - id 3개: `s5_ep01_e3`(evidenceLink·엔딩), `s5_ep08_e4`(recall), `s5_ep11_e4`
  - 문구: keeper 8, letter box 14, Bun-i 10, water drop 12, Haesu 6, Miri 11회
  - §C3 "The Box That Waited" 설계로 다시 만든다
- story_bible의 C12 항목(Bitna의 역할, 제목), dossier C12 항목, history reveal C12 문구("the letter box")
- 1B 이후 `s5_ep11_e4`·`s5_ep08_e4` 등에 남는 `clue_never_used` 경고 목록 확인

## 8. 이후 PART에 남긴 것 (확인된 사항)

- **C10 M3 정답 DROP:** 해수 상자 뚜껑의 물방울(Case 안 설명). §I-2의 "물방울은 C02·C03·C05·C11만"과 어긋나지만, M3를 HOUR로 바꾸는 PART 4에서 사라진다.
- **물방울 표식이 C04에도 남았다:** 두리의 장부 서명, Final `p_writer2`의 단서다. §I-2 목록 밖이지만 Case 안 기능이 있어 유지했다. 지금 물방울이 있는 Case는 C02·C03·C04·C05·C10·C11이다. 공통 표식처럼 보이는지는 PART 7 플레이스루에서 다시 판단하고, 필요하면 C04·C10을 Case 고유 표식으로 바꾼다.
- **C08 Final:** 경순의 편지는 "내가 잠갔다"고 하고, 새 성공 문구는 탐정이 잠근다고 한다. PART 3 Final 재설계 때 맞춘다.
- **PART 3 범위로 남은 것:** C07 Final의 카드 2장 구성, C08 M3 이름 입력, C08 caseSummary "Gwan-sun led"(→ "helped lead").

---

# PART 1B 결과 (2026-11-09 구현) — Case 12 "The Box That Waited"

**상태:** C12의 스토리, M1~M3, Ending, 외부 참조 제거는 완료했다. **Final은 미완성이다(PART 1.5 대기).** 글자 자물쇠에 미끼 타일을 넣으려면 공용 엔진 변경(2a)이 필요한데, 이번 PART에서는 엔진을 바꿀 수 없다. 그래서 지금은 정답 글자 5장(H T I G L)만 있고, 수수께끼를 읽지 않아도 철자를 바꿔 가며 풀 수 있다. 엔진 우회 구현은 하지 않았다.

**하지 않은 것:** 공용 엔진·lib 코드·tool 수정, 다른 Case(01~11)·다른 시즌 수정, 그림, R2, 커밋·푸시.

## 1. 변경 파일

| 파일 | 내용 |
|---|---|
| `content_pipeline/seasons/s5_seoul/cases/s5_ep12/case.plan.json`, `levels.json` | C12 전체 재작성. 176줄 모두 R/J/M 작성 |
| `planning/history_dossier.json` | **s5_ep12 항목만**: 사실 h10·h11 추가, h1·h2·h6·h9 출처 재확인, fiction, puzzles, learningObjectives, reveal |
| `planning/story_bible.json` | **C12 항목만**: cases[11], 빛나 인물 설명, `s5_ep12_c3` thread 뜻, englishReview의 C12 3줄 |
| 재생성 | `lib/data/generated/s5_seoul/s5_ep12.g.dart`, `s5_ep12_levels.g.dart`, `s5_seoul_history.g.dart`, `generated.manifest.json`. 백업 대비 이 4개만 다르다 |
| 테스트 | `test/sandbox/s5_seoul_rookie_test.dart`: **추가만 했다**(지운 줄 0). C12 M3에 "814는 'may' 날" 단언을 넣고, 새 테스트 "C12 stands alone"을 추가했다. 이 테스트는 R/J/M 모두에서 제목, 다른 Case 인물·상자 단어 없음, M3 전에 8.15·LIGHT 미노출, Final 수수께끼 줄을 확인한다 |
| 복원 | 검사 도구가 다시 쓴 `planning/quality_report.json`, `planning/puzzle_selection.json` |

## 2. 스토리와 퍼즐 (ROOKIE 기준)

| 단계 | 내용 | 다음으로 가는 이유 |
|---|---|---|
| Intro | 1945년 8월 충칭. 탐정은 한국 정부의 손님이다. "Japan has ruled Korea since 1910. So this government works far from home." 김원봉 = "the government's minister for the army". 빛나: "My mother's box is lost!" / "Mother said: open its lock only on the day the war is over." | 상자를 찾아야 한다 |
| M1 The Trunk by the Wall (scene_explore, `one_strap_lock`, **기존 그림·좌표·보기·피드백 유지**) | 짐을 싸다가 아빠가 실수로 상자를 트렁크에 넣었고, 책상에 쪽지를 남겼다. 쪽지: 가죽끈 하나 + 둥근 놋쇠 자물쇠, "Do not open Mother's lock before the day!" | 상자를 찾았지만 자물쇠 낱말을 모른다(슬롯 5칸, "My word has five letters.") → 어머니 편지로 |
| M2 Mother's Letters (timeline, **새 카드 id**) | 남동생이 윗칸을 열어 편지가 섞였다. 카드 화면 순서는 rain, drawing(버림), first(APRIL 고정), moon, pine이다(정답 순서 아님). 관계 문장: "After my pine letter, the rain came." / "The rain is over now." **해는 first → pine → rain → moon 하나다** | 순서대로 놓으면 뒷면이 읽힌다: "The sun gives it." "At night, it goes away." "It comes back on the day the war is over." "'May' is not enough." → 오늘이 그날인지 확인해야 한다 |
| M3 News on the Radio (number, `815`) | 라디오: "Japan has given up. The war is over!" / "Today is the fifteenth of August." 빛나의 카드: "The fourteenth: my brothers said the war may end." 어머니 규칙 "'May' is not enough." 달→숫자 카드(July 7, August 8, September 9). recall은 **같은 Case `s5_ep12_e2`** | 오늘이 그날이다 → 강가 계단(어머니가 작별한 곳)에서 연다 |
| Final Mother's Lock (talk → letterLock `LIGHT`) | 앞 대화 present 2개(새 id `today`·`riddle`, 카드 각 2장, 이 Case 증거만): `today` ← e3, `riddle` ← e2. 수수께끼 4줄. 타일 H T I G L(정답 순서 아님. 이 다섯 글자로 만드는 흔한 영어 단어는 LIGHT 하나) | 상자 안에 접힌 태극기가 있다 |
| Ending | 1945년 8월 15일 일본 항복 → 김원봉 "gwangbok: the light comes back" → 빛나 "Light! That is Mother's word!" → 연합국 승리와 국내외 한국인의 노력 → 광복군은 준비 중이었으나 일본이 먼저 항복 → "Mother's flag waited in the box." | Intro 문제(상자, 그날) 해결 |

**설계와 달라진 점:**
- "8월 10일 첫 소식"은 출처를 찾지 못해 쓰지 않았다.
- 그래서 M3 미끼는 810 → **814**로 바꿨다(빛나 남동생들의 "may" 말, 창작).
- 제목은 "The Box That Waited"다(정답 LIGHT가 제목에 없음).

## 3. 제거한 외부 참조

- `s5_ep11_e4`(M1 clueInputs)
- `s5_ep08_e4`(M2 recall, clueInputs, play.recall)
- `s5_ep01_e3`(Final evidenceLink, 엔딩 증거)
- 지키미 카드 6장(bun_i·seok·okbun·duri·gyeongsun·miri)
- Miri·Haesu·Bun-i·keeper·letter box·water drop·"서울에서 온 상자" 줄

**재검사(plan, levels, 생성 `.g.dart`): 다른 Case id 0건, 위 단어 0건.** 상자는 이 Case에서 처음 나온다.

## 4. 역사 검증

| 주장 | 출처 | 판정·사용 |
|---|---|---|
| 1910~1945 일본 지배 (새 h11) | korea.kr 정책브리핑 https://www.korea.kr/news/policyNewsView.do?newsId=148932667 , 한국민족문화대백과 8·15광복 https://encykorea.aks.ac.kr/Article/E0059769 | 확인 → Intro, reveal |
| 임시정부 1940년 충칭 이전, 광복군 1940.9.17 창설 (h1) | 대한민국역사박물관 archive.much.go.kr, encykorea E0005134 | 재확인 → 사용 |
| 김원봉 1944년 임시정부 군무부장 (h2) | encykorea E0010036 "1944년에는 임시정부의 군무부장에 취임" | 재확인 → "minister for the army"(M "of military affairs"). 직책만 쓰고 평가는 하지 않았다 |
| 김원봉 1942년 광복군 부사령관 (h9) | encykorea E0052178 | 재확인 → reveal에서만 |
| 광복군·OSS 국내 진공 준비, 일본 항복으로 무산 (h6) | much.go.kr, encykorea E0005134 | 재확인 → Ending |
| 8월 15일 정오 일왕 항복 라디오 방송 (새 h10) | korea.kr https://www.korea.kr/briefing/policyBriefingView.do?newsId=148797800 , AHF https://ahf.nuclearmuseum.org/ahf/key-documents/jewel-voice-broadcast/ | 확인 → M3 라디오, reveal |
| 8월 10일 첫 소식 | 우리역사넷·encykorea·역사박물관에서 찾지 못함 | **사용 안 함** |
| 광복군 여성 대원 | 선호 기관 출처를 찾지 못함 | 사실로 주장하지 않음(어머니는 창작이고 역할을 특정하지 않음) |
| 김원봉의 대사, 라디오 문장, 빛나 가족 | 창작 | reveal "IN THIS MYSTERY" R/J/M에 창작이라고 명시 |

## 5. 저장 호환성

- **유지:** mission `s5_ep12_m1~m3`·`final`, evidence e1~e4, clue c1~c3(내용만 교체). 정답 M1 `one_strap_lock`, M3 `815`, Final `LIGHT`는 그대로다. 완료 기록과 순차 해금도 그대로다.
- **바뀐 것:**
  - M2 정답과 카드 id가 바뀌었다. 새 카드는 `first_letter`·`pine_letter`·`rain_letter`·`moon_letter`이고, `drawing`은 유지, `bun_i`~`miri`는 삭제했다. 이야기 뜻이 완전히 달라졌기 때문에 기존 id를 재사용하지 않았다. M2 진행 중 저장은 보드가 처음부터 열린다(decode가 모르는 id를 버린다, 오류 없음).
  - Final 앞 대화 present `today`·`riddle`은 새로 생겼다(전에는 대화가 없었다).
  - 쓰이지 않게 된 M2 recall 기록은 남아 있어도 쓰이지 않는다.
- **이미 C12를 끝낸 플레이어:** 완료로 남는다. 수첩의 C12 증거는 새 내용으로 보인다(증거는 콘텐츠에서 다시 계산된다).

## 6. 검증 결과 (통합자가 직접 다시 실행)

| 검사 | 결과 |
|---|---|
| `case_levels check --season` | exit 0 |
| `generate_season --check` | exit 0(최신) |
| `plan_season check` | **ERROR 8건 = 기준선 그대로**, 새 오류 0. C12 경고는 5 → 3건(`clue_never_used` e1, `puzzle_selection_none` m1·final 2건, 모두 작업 전에도 있던 종류). 새 en_long_sentence·en_hard_word 0 |
| 외부 Case id(C12 plan·levels·생성물) | **0건** |
| 정답 사전 노출 | Intro·M1·M2(R/J/M)에 LIGHT·815·8.15 없음. "the fifteenth of August"는 M3 퍼즐 자체의 단서다. 시즌 Act 3 주제 "THE LIGHT RETURNS"는 `season.plan.json`에만 있고 게임 코드(`lib/`)에는 없어 화면에 나오지 않는다 |
| C12 자체 증거만으로 Final 풀이 | Final present가 받는 증거는 e1·e2·e3(모두 C12)이다. 수수께끼는 M2 편지 뒷면(C12)에서 나온다 |
| R/J/M 핵심 정보 동일 | `case_levels check`(정답·선택지·줄 수 같음) + 새 테스트 "C12 stands alone"이 세 레벨에서 수수께끼·제목·노출 금지를 확인 |
| Case 01~11·다른 시즌 불변 | 작업 전 해시 495개 파일(다른 Case plan·levels·생성물, 다른 시즌, lib 전체) **모두 같음**. dossier는 `s5_ep12` 항목만, story_bible은 C12 항목만 달라졌다(키 단위 비교) |
| `flutter analyze` | **No issues found** |
| 관련 테스트 14개 파일 | **369 통과 / 0 실패**: Seoul 10개 + season_factory 2 + puzzle_palette + puzzle_engine_collisions |
| 전체 `flutter test` | 실행하지 않았다(엔진 변경 없는 콘텐츠 PART) |

## 7. PART 1.5에 필요한 엔진 작업 (C12 Final 완성 조건)

**엔진:**
- **2a 글자 자물쇠 미끼 타일:** 슬롯 수 = 정답 길이, 검사 규칙 "정답 글자 ⊆ 타일"로 변경. 파일 `lib/features/mission/widgets/letter_lock.dart:44`, `tool/season_gen/puzzle_selection_check.dart:358-363`, `lib/data/content/season_content_validator.dart:325-329`. letterLock의 오답 단어별 피드백이 화면에 쓰이는지, `test/sandbox/sandbox_play.dart`의 letterLock 드라이버가 미끼를 건너뛰는지도 확인한다.
- **2b2 present당 카드 3장:** `tool/season_gen/play_check.dart:894`, `case_talk.dart` 배치.

**그다음 C12 데이터만 바꾼다:**
1. `final.puzzle.answerSpec.options` → N, H, T, I, R, G, L (이 순서).
2. `final.play.feedback`에 NIGHT·RIGHT·THING·GLINT·GIRTH 전용 피드백을 넣는다(R/J/M). 예: GLINT "A glint is only a tiny flash. The riddle says it comes back for the whole country."
3. 문구를 바꾼다(levels R 키와 J/M 함께):
   - M1 transition: "five letter tiles" → "seven letter tiles", "My word has five letters." → "Five letters. Two tiles are extra."
   - Final 편지 1번 줄과 question: "five of the seven tiles"
   - Final 힌트 2: "N and R are the extra tiles. Use the other five."
   - c1 value "5 SLOTS · 7 TILES"와 note, discovery 문구
4. dossier final clue `My word has five letters.` → `Two tiles are extra.`, whyOnly에 미끼를 포함한다.
5. 2b2가 들어간 뒤 present offered: `today` [e2, e3, e1], `riddle` [e3, e1, e2].
6. 테스트: 7타일·5슬롯, NIGHT·RIGHT·GLINT 피드백, LIGHT 통과 단언을 추가한다.

## 8. 남은 위험

- **Final은 1.5 전까지 철자 바꾸기만으로 풀 수 있다**(위 상태 참고).
- M2 순서의 필연성이 약하다. 뒷면 문장은 순서와 상관없이 읽힌다. 설계 평가 그대로이며 PART 4·7에서 다시 본다.
- 실기기·시뮬레이터 화면, 특히 Final 대화 화면은 확인하지 않았다. 생성 플레이스루 테스트만 통과했다.
- `s5_ep12_e1`의 `clue_never_used` 경고는 남는다. e1은 Final에서 카드로만 나온다.

---

# PART 1.5 결과 (2026-11-09 구현) — 공용 퍼즐 엔진 + C12 Final·M2

## 1. 엔진 변경 (모든 시즌 공용, 기존 콘텐츠 동작 유지)

| ID | 변경 | 파일 | 기존 시즌 영향 |
|---|---|---|---|
| 2a 미끼 타일 | 슬롯 수 = 정답 글자 수(`LetterLockQuestion.slotCount`, 정답이 비었거나 타일보다 길면 타일 수). 가득 찼을 때 안내 "The lock is full. Tap a letter in it to take it out." 검사: 생성기 `puzzle_selection_check`(정답 글자 ⊆ 타일, 미끼 최대 4)와 앱 `SeasonContentValidator`(정답 글자 ⊆ 타일). 팔레트 설명에 "any extra tiles are left out" | `letter_lock.dart`, `puzzle_selection_check.dart`, `season_content_validator.dart`(+`answerProblems` 공개 위임), `puzzle_palette.dart` | 없음. 번들된 모든 글자 자물쇠가 슬롯 = 정답 길이임을 테스트로 확인(파리 C01 = 타일 수 그대로) |
| 2b1 Final 대화 힌트 | `CaseTalk`에 `hints`·`hintsShown`·`onHint`(선택). 패널 아래 "Talk log" 옆에 힌트 링크, 연 힌트는 `DetectiveTipNotes`로 표시. 기존 `_showHint`/`requestTip`(코인 규칙) 재사용 | `case_talk.dart`, `final_mission_screen.dart`(_talkFinal), `mission_screen.dart`(_caseTalkStage) | 힌트가 있는 대화 미션에 링크가 생긴다(파리 C11 talk Final 포함). `_talkBeforeFinal`에는 붙이지 않았다(그 미션의 힌트는 뒤 퍼즐용) |
| 2b2 카드 3~4장 | `offered` 2~4장. 3~4장은 두 장씩 줄 배치(홀수 마지막은 반 폭). play_check 범위 2..4, schema `maxItems: 4` | `case_talk.dart`, `play_check.dart`, `mission_plan.schema.json` | 2장 화면은 그대로 한 줄 |
| 2b3 오답 처리 | `TalkPresent.litAfter`(기본 2 = 기존 동작). plan `litAfter`(≥2, offered가 있을 때만). 2회 오답 = `tell`, `litAfter`회부터 정답 카드 빛남 | `case_talk.dart`(모델·위젯), `plan_models.dart`, `generate_case.dart`, `play_check.dart`, schema | **C01 V4·파리 C11은 litAfter 기본 2로 동작 불변**. 새 Seoul Final만 3을 쓴다 |
| 2c 순서 안내 | 순서 퍼즐 위 캡션: "Tap the steps below in order." → "Now tap step N." → "All steps are set. Check, or undo one." | `question_widgets.dart` | 모든 시즌 순서 퍼즐에 캡션 한 줄 |
| 2d 숫자 유지 | 숫자 입력 오답 뒤 입력값 유지(Clear로 비움) | `question_widgets.dart` | 모든 시즌 숫자 입력. 테스트 드라이버 2곳(`test/sandbox/sandbox_play.dart`, `test/mission_play.dart`)이 입력 전에 Clear를 누르도록 수정(오답 뒤 재입력 흐름) |

## 2. C12 적용
- Final 타일 **N H T I R G L**(정답 순서 아님), 슬롯 5. 자물쇠 문구 "Five letters. Two tiles are extra."(M1 전환·단서·discovery·Final 편지·질문, R/J/M).
- 오답 단어 5개 전용 피드백(R/J/M): NIGHT(사라지게 하는 것), RIGHT·THING·GIRTH(해가 주는 것이 아님), GLINT(작은 반짝임일 뿐, 나라 전체에 돌아오는 것이 아님). 어느 줄에도 LIGHT 없음(테스트).
- 힌트 2개(상한 2): ① 해가 낮에 주는 것 ② "N and R are the extra tiles. Use the other five."
- 대화 present `today` [e2, e3, e1], `riddle` [e3, e1, e2], 둘 다 `litAfter: 3`.
- **M2 필연성:** 첫 편지에 "My riddle is on the backs, one piece on each. Only the right order makes sense."(배열 전에 제공). 정답 후 전환 "You turn them over, in order. The pieces join into one riddle." → 수수께끼 줄. 순서를 맞춰야 조각이 하나의 수수께끼가 된다는 이유가 Case 안에 생겼다. 카드 id·정답 불변(저장 영향 없음).
- dossier final clue `My word has five letters.` → `Two tiles are extra.`, whyOnly에 다섯 단어 배제 이유.

## 3. 검증 (실제 실행)
| 검사 | 결과 |
|---|---|
| `flutter analyze lib tool` | No issues |
| 새 테스트 `test/letter_lock_decoy_test.dart`(4), `case_talk_test.dart` 새 그룹(6: 320폭 3·4장, litAfter 3, 기본 2 유지, 힌트 링크, 힌트 없음) | 통과 |
| 회귀 묶음(full_playthrough, season_playthrough, paris_case01/08/11, time_code, case_talk_mission, season_scene_playthrough, mission_stage_layout, inline_hints, puzzle_palette, puzzle_engine_collisions, test/season_gen 전체) | **715 통과 / 1 실패** = 기준선 `time_code_question … only Case 12's train time`(§4.3) |
| `case_talk_test` | 1 실패 = 기준선 `only Case 11's final…`(§4.3) |
| case_levels check | exit 0 |
| plan_season check | ERROR 8 = 기준선. 새 오류 0 |
| generate_season --target game | 성공. 다른 시즌 생성물 변경 0 |
| Seoul 7개 파일(rookie+C12 새 테스트, case11, syllables, case01, play, traces, maps) | 통과(C11 3건은 2d로 드라이버 수정 후 통과) |

# 체크포인트 (2026-11-09, PART 2~4 진행 중)

- **완료:** PART 1.5(위 결과).
- **진행 중:** PART 2~4 — Case 02~11을 Case별로 병렬 작업. 각 작업은 자기 Case의 `case.plan.json`·`levels.json`만 고치고, dossier 변경은 `scratchpad/dossier_cNN.py`(`patch(d)`)로, 새 테스트는 `test/sandbox/s5_seoul_cNN_test.dart`로 제출한다. 통합(dossier 패치 적용 → `case_levels check` → `plan_season check` → `generate_season --target game` → Seoul 테스트)은 한 곳에서 한다.
- 세션이 끊기면 다음 세션: `git status`로 각 Case 파일 변경 확인 → `dart run tool/season_gen/case_levels.dart check --season content_pipeline/seasons/s5_seoul/season.plan.json` → 실패 Case만 고침 → 위 통합 순서. `planning/quality_report.json`·`puzzle_selection.json`은 검사 도구가 다시 쓰므로 `git checkout`으로 되돌린다(세션 시작 때 미수정 상태였음).
- **남은 PART:** 5(공용 UX), 6(난이도 영어: Case별 작업에 포함, 이후 전체 점검), 7(전체 검증), 그리고 사용자 추가 지시(2026-11-09): 필요한 그림은 예산(`content_pipeline/image_budgets.json` s5_seoul $12) 안에서 생성·적용·문서화.

---

# PART 2~7 결과 (2026-11-09 구현) — Case 02~11 재설계, 공용 UX, 난이도 영어, 전체 검증

체크포인트(위)의 "진행 중" 상태는 이 결과로 끝났다. 작업 방식은 Case별 병렬 작업(각 Case의 plan·levels만 수정) → 한 곳에서 dossier 패치 적용·생성·테스트였다.

## 1. Case별 변경 (ROOKIE 기준 요약, R/J/M 같은 정답·선택지·줄 수)

| Case | 미션 | Final | Ending·기타 |
|---|---|---|---|
| 02 거북선 | M1 "Twelve barrels" 노출 제거, 질문 "Which thing shows that rain came in over the powder?", 보기 straw·note·bucket, 오답 피드백. M3 석의 대사(함은 자고 있었고 비는 기다려 주지 않았다, 글자판·할머니, 물방울 = 비) | DRAGON 글자 자물쇠 폐지 → 이순신과 대화(present p_danger·p_how·p_count, 카드 3장, litAfter 3) → 4문장 고르기 정답 `seok`(문장마다 틀린 이유) | 엔딩 "My powder is dry, and my ship is ready." dossier `s5_ep02_h11`(C01 h5 복사), h12(1446, C01 h2 복사) |
| 03 거중기 | M1 기록 순서 섞음(밤에 묶인 경고 쪽지), M2 목수는 글을 못 읽는다·도면실 출입자 3명, M3 유지 | 1796 다이얼 → 용의자 4명 고르기 `okbun`(세 조건) | 옥분이 이유를 말함. dossier h7 조심태(출처 2: 우리역사넷, 수원시 팔달구청), h8 정약용 1792 성설(출처 2: 우리역사넷, 한국민족문화대백과 성제도설) |
| 04 경복궁 | Intro 6줄, M1 GATES 노출 제거, M2 장부 나 12→2·다 6→16, **M3 timeline → trace_deduction(새 그림)** | present 3단계(p_mark2·p_cut2·p_writer2) 카드 3장, litAfter 3, 힌트 2, 질문 q_cost | **두리의 표식 물방울 → 작은 소나무**(PART 7 판단, §5). dossier h9(1446) |
| 05 건청궁 | M1 쪽지·전환 모순 정리, M2 증언 순서 섞음(9:00 먼저, 판 복선), M3 밧줄을 찾는 장면 | JAPAN 입력 → 판 읽기 고르기 `queen`. **그림 고르기에서 글 고르기로 바꿈**(세 장소 그림이 모두 앞에서 이미 본 장소라 정답 그림이 먼저 노출됨: season_playthrough "nothing given away" 검사) | 왕비 대사 추가. 1895년 시해는 한 문장 사실만. Rookie 엔딩 "to stop Japan's power from growing"(J/M "hold back") |
| 06 헤이그 | M2 쪽지 줄 섞음, M3 "as soon as the 6:40 walk has passed" + 07:00 예시 | FORCED 폐지 → 대화형 Final `unseen`(thread·gate·door, 카드 3장, litAfter 3, 힌트 2) | M1 흔적 문장은 엔진 규칙(쪽지에 그대로 있어야 함) 때문에 유지 |
| 07 하얼빈 | M1 신문 B "THE HARBIN DAILY", "KOREYA! URA!", M2 보드 재구성(shout 9:30 고정 카드, factIds h6), M3 낱말 카드에서 KOREA | 소린의 주장 3개 반박(where·what·why, 카드 3장, 정답 카드가 첫 자리 아님) | dossier h6 "약 9:30"(출처 2: 인천시, 한국민족문화대백과 이토 포살 의거). 외침의 언어는 단정하지 않음 |
| 08 아우내 | M3 이름 입력 → 고르기 `gyeongsun`(글자·표식 두 조건) | 311 다이얼: 기호 map·map·clock, 편지에 날짜를 쓰지 않아 c1(4월 1일)·c2(전날 밤 불)가 있어야 풂. **경순이 상자에 넣고 탐정이 잠근다**(모순 해소) | "helped lead". Case 01 연상 요소 0 |
| 09 상하이 | M1 쪽지 "At eleven…", 오답 1100·0200, M2 전환 "only clerks have a key", M3 퇴근부 섞음 | 정답 `protect` → `copy_found`: 남기호의 거짓말 3개 반박(when·how·who), 외투에서 사본 회수 | 엔딩 "can never spy in this office again" |
| 10 두 시계 | M1 해수의 쪽지, M2 PART 1A 수정 유지(시계는 김구 손에만, 탁자 위 시계 없음), **M3 DROP → HOUR** | 대화형 `why`(after·whose·why, 카드 3장, litAfter 3, 힌트 2, "SIGN THE RECORD") | 윤봉길 의거는 중립 한 줄. dossier h6 "one more hour"(서울시 미디어허브, 세계일보 — 공공기관 1 + 언론 1), h7(1910, C12 h11 복사) |
| 11 윤동주 | M1 WATER(쪽지 3줄), M2 유지, **M3 PIANO**(낱말 입력) | 2단계: 미리와 대화(present list, 카드 3장) → 숫자 자물쇠 **319**(KOREAN 폐지). 319 = 윤의 목록 "copy 2 of 3"의 3 + "18 + 1 opening poem"의 19, 예시 215 | 319·"nineteen"이 정답 전에 나오지 않음(테스트) |
| 12 | (PART 1.5) 미끼 타일, M2 필연성 | | |

## 2. 새 그림 (사용자 2026-11-09 지시)
- 조사: Case 02~12의 그림 100여 장을 manifest와 대조. 10개 Case 작업자 모두 "새 그림 불필요"로 보고했고, 통합자가 C03 도면 2장(바퀴 유무)과 C04 M3를 직접 확인했다.
- **새로 만든 그림 1장:** `assets/seasons/season_05_seoul/cases/case_04/palace_site_traces.webp`(1536×1024, 365KB). 용도: C04 M3 흔적 찾기. 이유: 기존 `palace_site.webp`에는 단서 "깊은 바퀴 자국"과 "옅은 나무 가루"가 그려져 있지 않았다(좌표가 빈 바닥돌을 가리킴). 방법: 기존 그림을 참조로 gpt-image-2 편집(medium, **$0.0543**), 구도 유지 확인 후 두 단서 영역을 다시 쟀다(tracks [850,765,1150,905], dust [625,795,830,870]). 등록: manifest `s5_seoul.asset.c04_palace_site_traces`, pubspec, `appOnlySeasonFiles`(R2 업로드 전까지 앱 동봉). 예산: spentUsd 6.085679 → **6.139979 / $12**.
- 만들지 않은 것: 함·곽·표 초상(manifest에 planned). 세 인물은 대사 화면에 초상 자리가 없는 해설 인물이라 만들어도 화면에 쓰이지 않는다(불필요한 그림).
- 원본 PNG와 편집 참조는 `qa/seoul_images/`(gitignore).

## 3. 공용 UX (PART 5)
- PART 1.5의 엔진 변경(힌트 링크, 카드 3~4장, 순서 안내, 숫자 유지, 자물쇠 안내)이 전 Seoul Case에 적용된다.
- 생성기 경고 `answer_order_shown`: 글자 타일이나 순서 보기가 정답 순서 그대로 나열되면 경고(테스트 추가). 현재 Seoul 경고 0.
- 오답 카드가 첫 자리에 정답이 오지 않도록 모든 새 present를 확인(C07 why 1건 수정).
- Rookie 15어 초과 문장 9개, 어려운 낱말 2개(half-built, downstairs) 정리 → Seoul 경고는 Case 01(변경 금지)의 1건만 남음.
- 하지 않은 것: 단어 풀이 표시 개선, 편지 다시 보기 접근성, 실기기 화면 점검.

## 4. 난이도 영어 (PART 6)
- 새 테스트 `test/sandbox/s5_seoul_levels_english_test.dart`(12): Case마다 R/J/M의 미션 id·유형·정답·보기 id가 같고, 5어 이상 글의 60% 넘게 J·M이 다시 쓰였고, Rookie가 가장 짧다.
- 측정(levels.json, 5어 이상 줄): J≠R 79~95%, M≠R·J 83~96%. 같은 줄의 대부분은 dossier 단서 문장(모든 레벨에 글자 그대로 있어야 함).

## 5. 독립성 (PART 7)
- 데이터: Case 01~12의 plan·levels·생성물에서 다른 Case id **0건**. Bun-i·Sora·keeper·letter box·"same mark/drop" 0건(C08 "the same mark"는 자기 공책 비교). evidenceLinks 모두 비어 있음.
- 표식: 물방울이 C02·C03·C04·C05·C11 다섯 Case에 남아 시즌 공통 표식처럼 읽힐 수 있었다. §I-2 결정 목록 밖이던 **C04를 작은 소나무로 바꿨다**(두리: "I love the pine logs best. So I draw a little pine tree by my name."). 남은 넷은 §I-2대로 Case마다 자기 이유가 있다.

## 6. 검증 (실제 실행)
| 검사 | 결과 |
|---|---|
| case_levels check | exit 0 |
| plan_season check | ERROR 8 = 기준선(Case 01 그림 경로·크기, Case 01 clueThread). 새 오류 0 |
| generate_season --target game / build_manifest --check | 성공 / 최신 |
| flutter analyze | No issues |
| Seoul 테스트(16 파일 + maps + difficulty_content) | 모두 통과 |
| `generated_seasons_test` Seoul R/J/M 시즌 전체 플레이스루(앱에서 Case 01→12, 저장·재시작, 320폭 등) | 통과 |
| 전체 `flutter test` 1회차(콘텐츠 마지막 수정 전) | 4101 통과 / 7 건너뜀 / 16 실패 = 기준선 13 + 3(C04 테스트·생성물 최신 검사: 실행 중 plan 수정 탓, C10 학습 표현) → 3건 고쳐 해당 테스트 통과 |
| 전체 `flutter test` 2회차(모든 수정 후) | **4104 통과 / 7 건너뜀 / 13 실패 = 기준선 13건 그대로**(§4.3). 기준선 실패 메시지에 늘어난 Seoul 항목: case_talk 목록에 s5_ep06·s5_ep10 Final(새 대화형 Final, 설계대로), asset_optimizer에 palace_site_traces(새 앱 동봉 그림, §4.3 예고대로), puzzle_rules에 Seoul timeline plan(이 테스트는 Engine 2.0 schema의 `timeline` 키 자체를 금지하는 기존 전제 충돌) |

## 7. 저장 호환성
- mission·evidence·clue id 삭제 0, 미션 수 동일, 순차 해금 불변.
- 진행 중 상태만 초기화되는 곳(오류 없음, decode가 모르는 id를 버림): C02 Final(새 대화 키), C04 M3(엔진 교체)·Final(present 교체), C05 Final(유형 교체), C06·C09·C10 Final(present 교체), C08 M3·Final, C11 M3·Final. 완료 기록과 증거(콘텐츠에서 재계산)는 유지.
- C11 M3를 이미 끝낸 플레이어: M3 완료 유지, Final에서 319를 푼다.

## 8. 남은 것
- 실기기·시뮬레이터 화면 확인 안 함(특히 C04 흔적 영역, 카드 3장 Final, C11 2단계 Final). 실제 어린이 플레이 테스트 안 함.
- C10 h6 출처 하나는 언론(세계일보)이다. 공공기관 출처 하나 더 찾으면 바꾼다.
- R2 업로드 전까지 새 그림은 앱 동봉(`appOnlySeasonFiles`).
- `clue_never_used` 경고 40건(원래 다음 Case가 쓰던 증거 등, 경고만).

---

# 최종 안정화 (2026-11-09) — 테스트 실패 13건, 화면 검증, UX, 역사

## 1. 전체 테스트 실패 13건: 원인과 처리

| # | 테스트 | 원인 | 처리 | 종류 |
|---|---|---|---|---|
| 1 | `time_code_question_test` "only Case 12's train time" | Seoul에 시각 입력(C06 M3, C09 M1)이 생긴 뒤 갱신 안 된 기대값 | 런던은 ep12_m2 하나, Seoul은 두 개를 명시하고 **게임의 모든 시각 입력**에 HH:MM 검사 적용(검사 범위 확대) | 오래된 기대값 |
| 2 | `case_talk_test` "only Case 11's final is played as a case talk" | Seoul 대화형 Final 추가 | 손으로 만든 시즌은 파리 C11만, Seoul은 C04·C06·C07·C09·C10 Final을 정확히 명시 | 오래된 기대값 |
| 3 | `single_detective_test` "no network package" | 2026-11-06 커밋(5c1a6b0)의 R2 시즌 팩 다운로드가 `dart:io` HttpClient 사용 | 네트워크 코드는 `season_pack_downloads/storage` 두 파일에서만 허용, 그 외 전부 금지 유지, 다운로드는 HTTPS만이라는 검사 추가 | 오래된 기대값(제품 결정 반영) |
| 4 | `world_map_test` "CONTINUE comes back, nothing changed" | 메뉴가 코인을 보여 주면서 첫 지갑(시작 코인)이 처음 읽힐 때 저장됨. World Map 왕복이 바꾼 것이 아님 | 스냅샷 전에 지갑을 만들어 **왕복 자체가 아무것도 쓰지 않음**을 그대로 검증 | 테스트 준비 순서 |
| 5 | `world_archive_test` "the map menu opens the archives" | 2026-11-03 메뉴 개편(6개 항목)에서 지도 메뉴의 World Archive가 빠짐. 아카이브는 World Map 헤더에 있음 | 실제 경로(지도 메뉴 → World Map → 헤더 아카이브)로 갱신 | 오래된 기대값 |
| 6 | `visual_placeholders_test` "every symbol has a glyph" | **제품 결함**: C04 증거 아이콘 `palace`에 그림 글리프가 없어 글자 "P"로 표시 | `InkGlyph.palace`(한국 전각: 들린 처마, 기둥 셋, 기단) 추가, 렌더링 확인 | 제품 수정 |
| 7–9 | `icon_upgrade_test` 3건 | (a) **제품 결함**: Seoul 증거 48개 중 45개가 그림·문서 등록 없이 선 아이콘으로만 표시 (b) 런던 지도 조각 5개가 승인된 커밋(3c7e9b7)에서 그림으로 바뀜 (c) R2 팩 전환 뒤 "번들" 판정이 pubspec만 봄 | (a) Seoul 48개 모두 등록: 그림 7(기존 사건 그림), 문서 41(쪽지·편지·장부·지도·보고서 등 종류별). **C09 경찰 보고서가 책상 열쇠 그림으로 나오던 오류**도 manifest subject를 고쳐 얇은 종이 그림으로 바로잡음 (b) 지도 조각은 그림, 까마귀가 그림에 남아 있음을 확인 (c) `shippedAssets()`(앱 번들 + 시즌 팩)로 판정 | 제품 수정 + 오래된 기대값 |
| 10 | `asset_optimizer_test` "every bundled picture is recorded" | 앱 동봉 Seoul WebP 8개가 최적화 원장에 기록 없음 | 7개는 원본 PNG(raw 3개, 손실 없는 디코딩 4개, 새 그림 1개)로 `optimize_assets --apply --only` 실행 → 원장 기록·품질 게이트 통과(PSNR 46~99). 다시 인코딩한 그림은 기존과 동일(PSNR 120)하거나 원본에 더 가까움. **`season5_prologue_night.webp`는 R2에 올라간 팩(v3fc49c8)의 파일이기도 해 다시 인코딩하면 팩 버전이 바뀐다** → 원본 바이트로 되돌리고, 테스트 제목이 말하는 "lossy original never re-encoded"를 구현: 기록 없는 WebP는 **팩 manifest의 SHA-256과 바이트가 같을 때만** 허용 | 원장 정리 + 검사 구현 |
| 11 | `puzzle_rules_test` "no plan uses the timeline's own keys" | 2026-11-04 테스트가 plan에 timeline이 들어오기 전 전제. 2026-11-06부터 plan schema가 `play.timeline`을 공식으로 읽음 | 원래 걱정(레벨 도구가 timeline 키를 글로 읽는 것)을 직접 검증: 카드 제목·내용·관계 문장은 레벨 글, id·시각·카드 참조는 절대 글이 아님 | 오래된 전제 |
| 12 | `s9_ep01_test` "the catalog is as it was" | Seoul 시즌 채택(2026-11-05) | 카탈로그 5시즌 명시 + 샌드박스(s9) 시즌이 게임에 없음 검사 | 오래된 기대값 |
| 13 | `season_content_test` "a case mixes puzzle types" | 런던 C10 M1이 실기기 피드백(3c7e9b7)에서 그림 고르기가 되어 유형이 2개(그림 고르기 2, 순서 2) | **런던 콘텐츠를 바꾸지 않고** C10만 지금 구성을 정확히 고정(더 바뀌면 실패), 다른 Case는 규칙 그대로. 런던 C10 퍼즐 다양성은 **사용자 결정이 필요한 열린 항목**으로 남김 | 예외 고정(보고) |

## 2. UX 개선
- **단어 풀이 "Words" 링크:** 단어는 계속 표시 없이 영어를 먼저 읽게 두고(기존 원칙), **Reread Letter 시트 안**, **Talk log 시트 안**, Final 화면(모든 Final 퍼즐 공통 영역, 스크롤되는 화면)에 "Words" 링크를 넣었다. (처음에는 퍼즐 화면 링크 줄과 대화 패널에 넣었으나, 320폭에서 링크 줄이 두 줄이 되어 고정 높이 화면이 11px 넘쳐 시트 안으로 옮겼다.) 그 화면에서 이미 읽은 글의 단어 목록이 열리고, 뜻은 탭해야 보인다. 단어가 없으면 링크가 없다. 기존 `showTalkWords` 시트를 재사용했다(새 화면 없음). 스크린리더용 힌트("Shows N words to look up"). 테스트 `test/words_link_test.dart`.
- **편지 다시 보기:** C04 M3 흔적 화면에 Reread Letter를 켰다(`rereadLetter: true`, Case 01과 같은 방식). 다른 Seoul 퍼즐 화면은 이미 Reread Letter(편지 단계 엔진) 또는 Talk log(대화)가 있다.

## 3. 역사
- C10 "one more hour": 김구 『백범일지』의 기록임을 공공 출처 2개로 확인(국가보훈부 공식블로그 "앞으로 시계를 볼 시간이 한 시간밖에 없으니까요", 김구재단 『백범일지』 인용 "제 시계는 앞으로 한 시간밖에는 쓸 데가 없으니까요"). 언론 출처(세계일보)를 대체했다. 게임의 영어 문장은 김구의 기록을 옮긴 것이며, 게임 안에서도 김구가 회상하는 말로 나오고 reveal에 "Kim Gu wrote that Yun said…"로 적혀 있다. 긴바늘 문장은 창작으로 표시돼 있다.

## 4. 증거 카드 배치 (시뮬레이터에서 발견)
- iPhone SE(375×667)에서 카드 3장이 2줄이면 셋째 카드가 화면 아래로 밀렸다 → **3장은 한 줄**, 4장은 2×2, 3장 이상은 썸네일 48·최소 높이 96. 2장(C01 V4·파리 C11)은 그대로. 320폭 위젯 테스트(카드 너비 ≥80, 높이 ≥48, 넘침 없음) 갱신.

## 5. 화면 검증 (iOS 시뮬레이터 iPhone SE 3rd gen, 375×667, `integration_test/seoul_final_qa_test.dart` + `test_driver/seoul_final_qa_driver.dart`, 스크린샷 `qa/screenshots/seoul_final/375x667/`)
- Seoul 그림 팩: R2 다운로드가 매우 느려(약 1MB/45초) 저장소의 같은 파일(팩 manifest의 크기·SHA-256 대조 확인)을 시뮬레이터 앱 폴더에 넣어 설치했다.
- **C04 M3 통과:** 그림 전체가 375폭에 보이고, 측정한 좌표를 탭해 흔적 3개(운반·바퀴 자국·나무 가루)가 모두 찾아졌다. 빈 돌바닥 탭은 "Tap a place where the logs could be." 안내, 수레 선택 → SEARCH HERE → 해결.
- **C11 Final 통과:** 미리 대화 → 틀린 카드 2번(2번째에 "Find the paper from Yun's drawer.", 카드 빛남 없음) → 맞는 카드 → 자물쇠 219 거절 → 입력 유지 확인 → Clear → 319 → 해결 → 지도로 갔다가 다시 열어도 해결 상태 유지.
- **C12 M2 통과:** 틀린 순서 거절("Read the rain letter and the moon letter again…"), 수수께끼 미노출 확인, Undo로 되돌려 정답 순서 → 해결.
- **C12 M3·Final 통과(추가 실행, `--dart-define=QA_REST=true`):** 814 거절("That was only a 'may' day…"), 815 → Final 대화 카드 3장 한 줄(today·riddle) → 글자 자물쇠 슬롯 5칸·타일 7장 → NIGHT 거절("Night is when it goes away. What does the sun give?") → 타일 되돌리기 → LIGHT → 엔딩("On 15 August 1945, Japan gave up…").
- **C02·06·07·09·10 Final 통과:** 각 Final의 첫 질문에서 카드 3장이 한 줄로 화면 안에 보임(힌트·Talk log 링크 포함). 같은 틀린 카드 2번 → "다시 볼 단서" 안내만, 카드 빛남 없음 → 3번째에 정답 카드 빛남(litAfter 3).
- **이 실행에서 발견해 고친 것:** 카드 3장 한 줄에서 긴 증거 이름이 2줄에서 잘렸다("The Watchers' [Times]", "Haesu's Kitchen [Note]", "The Police Bureau's [Report]", "The Note on the [Shelf]") → 3~4장일 때 이름 14pt·최대 4줄. 위젯 테스트 추가: Seoul의 모든 대화 카드 묶음(15개 이상)을 320폭·실제 글꼴로 그려 이름이 잘리지 않음을 확인(예전 설정으로 되돌리면 실패하는 것을 확인함).
- **미검증:** 큰 화면 기기, 실기기, 어린이 플레이 테스트.

## 6. 최종 검증
- `flutter analyze`: No issues
- 전체 `flutter test` 1회차(이번 안정화 중간): 4108 통과 / 7 건너뜀 / 11 실패 → 모두 Words 링크 넘침(위 2절) → 고친 뒤 실패했던 파일 재실행 252 통과
- 전체 `flutter test` 최종(카드 이름 수정 후): **4120 통과 / 7 건너뜀 / 0 실패**, `flutter analyze` No issues
- 남은 열린 항목: 런던 C10 퍼즐 유형 다양성(사용자 결정), C12 M3·Final과 카드 3장 Final의 기기 화면, 실기기·어린이 플레이 테스트, 새 그림·재인코딩 그림의 R2 반영(업로드 금지라 앱 동봉 유지).

### R2 업로드 (2026-11-09, 사용자 승인)
- 앱 전용이던 Seoul 그림 14장(C01 V4 8장, C02 방 3장, C04 흔적 1장, C11 종이 2장)을 팩으로 옮김. 음성 9개는 팩이 그림만 받으므로 앱에 그대로.
- `season_factory.dart packs` → `upload --approved`: season_05_seoul **v1418483ef36c4e83**, 15개 객체(그림 14 + 매니페스트, 11,527,223 bytes) 업로드, HTTPS로 다시 받아 크기·SHA-256 확인. 이전 버전 객체는 지우지 않음.
- 앱 업데이트에는 새 `season_pack_manifests.g.dart`와 pubspec 변경이 함께 가야 함.
