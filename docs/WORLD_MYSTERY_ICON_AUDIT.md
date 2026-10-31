# World Mystery — 아이콘·기호 전수조사 및 이미지 에셋 교체 분류

- 작성일: 2026-11-01
- 범위: `lib/` 전체(앱 공통 + 런던·파리·로마·뉴욕 4개 시즌 데이터), `assets/`
- 작업 성격: **조사 문서만 작성.** 코드·에셋 변경, 이미지 생성, 테스트 실행 없음.
- 기준 커밋: `b43d8b9` (main, clean)

---

## 0. 요약 (결론 먼저)

| 항목 | 수치 |
|---|---|
| 화면에 표시되는 **아이콘 종류** (의미 단위, 중복 제거) | **58종** |
| ├ A. 이미지 에셋 교체 **적극 권장** | **23종** (사물·증거·단서 심볼 22 + 모노그램 대체 표시 1) |
| ├ B. 선택적 교체 | **14종** |
| └ C. 기존 아이콘 유지 | **21종** |
| 증거(Evidence) 총 개수 | **194건** |
| ├ 이미 사진 그림 있음 (`ArtAssets.evidencePictures`) | 42건 |
| ├ 글자까지 코드로 그린 문서 그림 (`DrawnEvidenceArt`, 파리 Case 02·05–12) | 33건 |
| └ **선 아이콘(InkGlyph)으로만 표시되는 증거** | **119건 (61%)** |
| 단서 카드(Clue) 심볼 배지 | 146건 — 전부 선 아이콘 배지 (런던 Case 01의 4건만 컬러 그림) |
| 다이얼 자물쇠 심볼 | 8개 사건 — 런던 Case 01만 컬러 그림, 나머지 7건 선 아이콘 |

**핵심 진단**

1. 이 프로젝트는 Material/Cupertino 아이콘과 이모지를 **전혀 쓰지 않는다** (`Icons.*` 0건, `CupertinoIcons.*` 0건, 이모지 0건). 모든 아이콘은 자체 선화 시스템 `InkIcon(InkGlyph.x)` ([lib/widgets/ink_icon.dart](../lib/widgets/ink_icon.dart)) 하나로 그려진다. 시스템 UI 아이콘으로서는 일관되고 품질도 괜찮다.
2. 문제는 **같은 24×24 선화가 "증거 사물 그림"의 대체물로도 쓰인다는 것**이다. 증거에 사진 그림이 등록되지 않으면 `_EvidenceArt`가 `GameSymbol.of(evidence.icon).mark()`로 떨어져, 원형 프레임 안에 단색 선 아이콘이 들어간다. Blue Cloth(`cloth` 글리프: 지그재그 다각형+가로줄 2개), Wet Footprint(`footprint` 글리프: 타원 2개)가 이 경로다.
3. 로마·뉴욕(시즌 팩토리 생성)은 아이콘 키가 24개 어휘로 제한되어 **의미가 맞지 않는 아이콘이 다수**다. 예: White Dust·Orange Cat Hair·Pia's Story·Wet Paint Sign → 전부 `footprint`, Rosa's Tune·Karl's Pocket Book·Stone Nest → `feather`, Valli's Confession·Sam's Sunday Story → `mask`.
4. **바로 쓸 수 있는 기존 이미지가 등록만 안 된 경우가 있다.** `blue_cloth.png`, `wet_footprint.png`, `brass_gear.png`는 이미 런던 탐색 장면(`season1_investigations.dart`)에서 쓰이고 있지만 증거 카드에는 연결되어 있지 않다. 이런 재사용 가능 건이 **19건**(일반 12 + 로마 부엉이 카드 7)이다.
5. 증거 보드(`evidence_board.dart`)·스트리트 북(`street_book.dart`)은 **사진 그림이 있는 증거조차** 선 아이콘 배지(`SymbolBadge(evidence.icon)`)로 보여 준다. 그림이 생겨도 이 두 화면은 바뀌지 않는다.

**권장 신규 이미지 수량 (증거 기준)**: 개별 사물 **30장** + 공용 문서 템플릿 **10장** + 공용 진술 메모 **1장** = **41장**으로 증거 119건 전부 해소 (재사용 19건 포함). 선택적으로 단서·자물쇠용 단색 심볼 스탬프 세트 **23장**.

---

## 1. 조사 방법과 범위

### 1.1 검색한 표현과 결과

| 검색 대상 | 결과 | 비고 |
|---|---|---|
| `Icons.*`, `CupertinoIcons.*` | 0건 | `ink_icon.dart` 주석: QR 스캐너 카메라 버튼만 예외라고 적혀 있으나 현재 코드에 QR 스캐너 Material 아이콘 사용 없음 |
| `Icon(` (Flutter `Icon` 위젯) | 0건 | `Icon(` 175건은 전부 `InkIcon(` |
| `IconData` | 0건 | |
| `IconButton` | 21개 파일 28건 | 전부 `icon: InkIcon(...)` 사용. 아이콘 종류는 InkGlyph로 집계 |
| `InkGlyph.<이름>` 참조 | 86개 파일, 48종 정의 중 47종 사용 | `InkGlyph.qr`은 정의만 있고 미사용 |
| 이모지 (U+1F000대 등) | 0건 | 비한글 특수문자 전수 스캔(주석 제외) |
| Unicode 특수기호 | `★☆`은 코드로 그린 별(`InkStar`)로 대체됨. 텍스트 기호: `✓` `↶` `↷` `›` `•` `−` | 2.3절 |
| 텍스트를 아이콘처럼 쓰는 UI | `'?'` 5곳, 원 안 숫자 4곳, 모노그램 1곳 등 | 2.3절 |
| `CustomPainter` | 44개 파일 62개 클래스 | 아이콘 성격은 8개, 나머지는 장면·퍼즐·장식 (2.4절) |
| `BoxShape.circle` | 39개 파일 69건 | 원형 배지 대부분은 `SymbolBadge`·`_EvidenceArt`·지도 핀으로 귀결. 나머지는 버튼 배경·점 장식 |
| 기존 PNG 아이콘·심볼 | 배지 메달 15+프레임, 월드맵 핀 4+링, Royal Box 자물쇠 그림 4, 까마귀 문장 1 | 이미 이미지. 교체 대상 아님 |
| 데이터의 아이콘 키 | 증거 `'icon'` 194건, 단서 `'symbol'` 146건, `'dialSymbols'` 8개 사건, `'symbols'` 1건 | 3절 |

### 1.2 "검색 결과 수"와 "아이콘 종류 수"의 구분

- `InkGlyph.` 참조는 **약 410건**(ink_icon.dart 자체 제외)이지만, 화면에 보이는 **아이콘 종류는 58종**이다.
- 증거 119건은 "종류"로 세지 않고 별도 목록(5절)으로 관리한다. 같은 `letter` 아이콘을 47건의 서로 다른 증거가 공유하기 때문이다.
- 하나의 글리프가 맥락에 따라 다른 그룹에 속하는 경우가 있다 (예: `letter`는 증거 심볼일 땐 A, "Reread Letter" 버튼일 땐 C). 종류 집계는 **가장 강한 용도** 하나로만 세고, 이중 용도는 표에 표기했다.

### 1.3 누락 가능성

| 영역 | 상태 |
|---|---|
| `lib/` 내 아이콘 위젯·글리프·기호 | 정규식 전수 검색 + 공통 위젯 사용처 역추적. 누락 가능성 낮음 |
| 증거 데이터 | `'id','name','icon'` 패턴으로 194건 추출. 시즌당 48~50건으로 사건 수(12×4)와 일치 |
| 단서 심볼 | `'symbol':` 패턴 기준. `*_levels.dart`(난이도 변형)에 같은 단서가 반복되는 것은 중복 제외 |
| 장면 일러스트(`LandmarkArt` 코드 그림) | **아이콘이 아니므로 범위 외.** 참고로 `Artwork` 80종 중 7종(suitcase, lockedDoor, theatre, parkMapA–D)은 그림 파일 없이 코드로 그림 |
| 퍼즐 장면 안의 코드 그림(시계 바늘, 테이프, 찢긴 종이 등) | 퍼즐 메커니즘이므로 범위 외. 단, 글리프를 사물 대신 크게 쓰는 곳은 2.2절에 포함 |
| `assets/sounds`, `web/`, 네이티브 앱 아이콘(launcher icon) | 범위 외 |
| 실제 렌더링 확인 | **실행 화면 캡처로 확인하지 않음.** 코드 경로 추적과 에셋 파일 확인만 수행 |

---

## 2. 전체 아이콘 사용 현황

### 2.1 아이콘 시스템 구조 (공통 컴포넌트)

```
InkGlyph (enum, 48종)  ── _InkGlyphPainter: 24×24 격자, 1.9 선 굵기, 단색
   │
   ├─ InkIcon(glyph)                       ← 모든 UI 아이콘
   ├─ InkTextButton(label, glyph)          ← 글자+아이콘 버튼
   ├─ showGameToast(..., glyph)            ← 토스트
   │
   └─ InkMark(glyph | monogram | asset)    ← "데이터가 고르는 그림"
        ├─ GameSymbol.of(key)   [symbol_icon.dart]  24개 키 → glyph + 색
        │     ├─ SymbolBadge(key)          ← 원형 도장 (단서·증거 보드·자물쇠)
        │     └─ .mark()                   ← 증거 그림의 대체물
        └─ BadgeMedal의 fallback           ← 메달 PNG가 없을 때만
```

이미지가 끼어드는 지점(모두 [lib/widgets/art_assets.dart](../lib/widgets/art_assets.dart)):

| 레지스트리 | 현재 내용 | 쓰는 곳 |
|---|---|---|
| `ArtAssets.evidencePictures` | 42건 (런던 10, 파리 9, 로마 14, 뉴욕 9) | `_EvidenceArt`, `_EvidencePrint` |
| `SeasonCatalog.evidenceArt` (DrawnEvidenceArt) | 33건 (파리만) | `_EvidenceArt`, `_EvidencePrint` |
| `ArtAssets.symbols` | **비어 있음 `{}`** — 심볼 그림을 넣을 자리는 이미 마련됨 | `GameSymbol.of()` → `InkMark(asset:)` (단색 틴트) |
| `ArtAssets.royalBoxLocks` | 4건 (런던 Case 01 자물쇠) | `RoyalBoxPicture`, 단서 카드, 자물쇠 |
| `ArtAssets.badges` | 15건 + `badgeFrame` | `BadgeMedal` |

### 2.2 InkGlyph 47종 사용 현황 (참조 수 / 주요 화면)

| 글리프 | 참조 | 주요 사용 화면·파일 | 그룹 |
|---|---:|---|:-:|
| check | 70 | 거의 모든 퍼즐 위젯의 완료 표시, 배지, 설정 | C |
| search | 46 | "Look closer", 탐색 버튼, 증거 링크, 힌트 | C |
| letter | 26 | 증거 심볼 + "Reread Letter"/문서 버튼(final_mission, scene_explore, lens_inspect, spot_differences), plan_route 50px 토큰 | **A** (UI 버튼 용도는 C) |
| back | 23 | 모든 화면 뒤로가기 | C |
| hint | 20 | 힌트 버튼·전구(HintBulb), 팁 | B |
| arrow | 19 | 다음/진행, 심볼 순서 화살표 | C |
| notebook | 15 | 수첩 버튼, 메뉴, 증거 회상 헤더 | B |
| lock | 14 | 잠긴 사건·시즌·배지, 토스트 기본값 | C |
| folder | 13 | Case files, 사건 결과, 시즌 화면 | B |
| seal | 12 | 증거 심볼 + World Archive·시즌 파일 도장, "준비 중" 토스트 | **A** (아카이브 도장 용도는 B) |
| pen | 12 | 이름 입력, 질문 표시, 메뉴 "My detective" | C |
| gear | 10 | 증거 심볼 + **파리 시계공 각인**(easy_steps 190px, clockwork_garden MarkGlyph, star_records 명판), 조사 보드 | **A** |
| deerstalker | 9 | 탐정 아바타 대체, 난이도 선택, World Archive 엠블럼, 시작 화면 | B |
| pin | 8 | 메뉴 Season board, CURRENT FILE 태그, 단서 장소 | B |
| down | 8 | 스크롤 안내, 자물쇠 위/아래 | C |
| clock | 8 | 증거 심볼(`clock`, `watch`) + 파리 프롤로그 엠블럼, clock_wall | **A** |
| map | 7 | 증거 심볼 + "Route plate" 버튼 | **A** |
| raven | 6 | 증거 심볼 + 시즌 조사 보드(Who are the ravens?) | **A** |
| chevron | 6 | 펼치기·접기 | C |
| train | 5 | 심볼 + 기차표 헤더(train_ticket), 사건 결과·시즌 화면 | **A** |
| key | 5 | 증거 심볼 + lens_inspect 엠블럼, clockwork_garden 각인 | **A** |
| eye | 5 | "Whole Picture" 버튼, 대화 조사 | B |
| coin | 5 | 코인 잔액, 팁 상점, How to Play | B |
| puzzle | 4 | archive_drawers·hold_rack 버튼 | B |
| footprint | 4 | 증거 심볼 + plan_route 52px 발자국 마커 | **A** |
| close, clear | 4, 4 | 닫기, 입력 지우기 | C |
| speaker, speakerOff | 3, 2 | 소리 켜기/끄기 | C |
| frame | 3 | 증거 심볼 + studio_match 선택 표시 | **A** |
| backspace | 3 | 글자 입력 지우기 | C |
| whistle, umbrella, ticket, park, museum, mask, gem, feather, crown, cloth, button, bag | 각 2 | 증거·단서 심볼 전용 (`symbol_icon.dart`) | **A** |
| sun | 2 | 파리 Case 10 해시계(star_records) | B |
| stopwatch | 2 | Quick Thinker 배지 대체(메달 PNG 있음 → 사실상 미표시) | C |
| menu, home | 2, 2 | 지도 화면 메뉴 | C |
| qr | 0 | 미사용 | — |

### 2.3 InkGlyph 외 아이콘성 요소

| 요소 | 위치 | 의미 | 그룹 |
|---|---|---|:-:|
| `InkStar` (코드로 그린 ★/☆) | [case_solved_screen.dart:624](../lib/features/result/case_solved_screen.dart#L624), [:719](../lib/features/result/case_solved_screen.dart#L719), [parent_report_screen.dart:153](../lib/features/result/parent_report_screen.dart#L153) | 사건 평가 별 | B |
| 모노그램 (`InkMark` 글자 대체) | [ink_icon.dart:113](../lib/widgets/ink_icon.dart#L113) | 글리프 없는 심볼: `palace`→"P", 알 수 없는 키→"?" (Mystery). 현재 데이터엔 `palace` 미사용이라 실제 노출은 거의 없음 | **A** |
| `'?'` 텍스트 | [map_pin.dart:234](../lib/features/mission_map/widgets/map_pin.dart#L234), [notebook_screen.dart:489](../lib/features/notebook/notebook_screen.dart#L489), [investigation_board.dart:429](../lib/features/season/widgets/investigation_board.dart#L429), [:593](../lib/features/season/widgets/investigation_board.dart#L593), [:610](../lib/features/season/widgets/investigation_board.dart#L610), [morning_sketches.dart:294](../lib/features/mission/widgets/morning_sketches.dart#L294) | 잠긴 장소·빈 증거 칸·정체 미상 인물 | B |
| 원 안 숫자 / 번호 스탬프 | [evidence_card.dart:286](../lib/widgets/evidence_card.dart#L286), [river_marks.dart:305](../lib/features/mission/widgets/river_marks.dart#L305), [fly_rail.dart:407](../lib/features/mission/widgets/fly_rail.dart#L407), [lift_route.dart:537](../lib/features/mission/widgets/lift_route.dart#L537) | 순서 번호 | B (퍼즐 정보이므로 텍스트 유지 권장) |
| 지도 핀 마크 (`_InkPinPainter`, `_DashedCirclePainter`) | [map_pin.dart:323](../lib/features/mission_map/widgets/map_pin.dart#L323) | 미션 지도의 장소 핀(현재·완료·잠김) | B |
| 밀랍 봉인 모노그램 (`_WaxBlobPainter`) | [letter_card.dart:555](../lib/widgets/letter_card.dart#L555) | 편지 봉인 | B |
| `'✓'` 텍스트 | [clockwork_garden.dart:1298](../lib/features/mission/widgets/clockwork_garden.dart#L1298), [studio_match.dart:570](../lib/features/mission/widgets/studio_match.dart#L570) | 완료 (check 글리프와 중복 의미) | C (글리프로 통일 권장) |
| `'↶' '↷'` | [star_records.dart:1921](../lib/features/mission/widgets/star_records.dart#L1921) | 테이프 되감기/건너뛰기 방향 | C |
| `'›'` | SKIP ›, NEXT › (story_intro, paris_prologue, season_prologue) | 진행 | C |
| `'−' '+'` | [clock_question.dart:425](../lib/features/mission/widgets/clock_question.dart#L425) | 시곗바늘 조정 버튼 | C |
| 장식 돋보기·엠블럼 (`_MagnifierPainter`, `_EmblemPainter`) | [paper.dart:282](../lib/widgets/paper.dart#L282) | 종이 장식 | C |

### 2.4 CustomPainter 62개 분류

| 분류 | 개수 | 예 | 판단 |
|---|---:|---|---|
| 아이콘 성격 | 8 | `_InkGlyphPainter`, `_StarPainter`, `_InkPinPainter`, `_DashedCirclePainter`, `_EmblemPainter`, `_MagnifierPainter`, `HintBulbLight`, `_WaxBlobPainter` | 위 표에 반영 |
| 퍼즐 메커니즘 (바늘·경로·테이프·찢긴 자국) | 약 30 | `ClockHandsPainter`, `_RoutePainter`, `_TearPainter`, `_PencilTrail` | 유지 (상호작용이 그림에 의존) |
| 그림 파일이 없을 때의 대체 장면 | 6 | `_LandmarkPainter`, `LondonMapPainter`, `_RoyalBoxPainter`, `_NightLondonPainter`, `_StrangerPainter`, `LondonSkylinePainter` | 대부분 파일이 있어 평소엔 미표시. 범위 외 |
| 배경·장식 (종이, 비, 램프, 반짝임) | 약 18 | `_PaperPainter`, `_RainPainter`, `_Glint` | 유지 |

---

## 3. 시즌별 현황

### 3.1 증거 표시 방식

| 시즌 | 증거 | 사진 그림 | 코드 문서 그림 | **선 아이콘** | 선 아이콘 비율 |
|---|---:|---:|---:|---:|---:|
| London (S1) | 50 | 10 | 0 | **40** | 80% |
| Paris (S2) | 48 | 9 | 33 | **6** | 13% |
| Rome (S3, 생성) | 48 | 14 | 0 | **34** | 71% |
| New York (S4, 생성) | 48 | 9 | 0 | **39** | 81% |
| **합계** | **194** | **42** | **33** | **119** | **61%** |

파리 Case 05–12는 빈 종이·사물 그림 위에 영어 문장을 코드로 그리는 방식(`DrawnEvidenceArt` + `RiverEvidenceArtView`)이라 이미 완성도가 높다. **이 방식이 다른 시즌 문서형 증거의 모범 사례**다.

### 3.2 증거 아이콘 키 사용 분포 (194건)

| 키 | 전체 | 선 아이콘으로 표시 | 주로 무엇에 쓰였나 |
|---|---:|---:|---|
| letter | 64 | 47 | 편지·메모·일지·목록·메시지 전부 |
| ticket | 19 | 11 | 카드·표·꼬리표·로그 |
| map | 18 | 11 | 지도·지도 조각·경로 카드·석고 사본 |
| seal | 17 | 6 | 봉인·부엉이 카드·각인·이름표 |
| feather | 13 | 10 | 깃털 + **노래·악보·진술·수첩·둥지** (의미 불일치) |
| frame | 11 | 5 | 그림·사진·스케치·찢긴 페이지 |
| key | 9 | 4 | 열쇠 + **상자·금고·돌** (의미 불일치) |
| clock | 8 | 3 | 시계 메모·근무표·출입 기록 |
| footprint | 7 | 6 | 발자국 + **가루·고양이 털·진술·페인트 표지** (의미 불일치) |
| watch / gear / gem | 5 / 5 / 5 | 1 / 3 / 3 | |
| mask | 3 | 3 | 가면 + **진술·자백** (의미 불일치) |
| button, whistle | 2, 2 | 1, 2 | |
| crown, cloth, raven, bag, umbrella | 2, 1, 1, 1, 1 | 0, 1, 1, 1, 0 | |

### 3.3 단서 심볼과 자물쇠 심볼

| 시즌 | 단서 카드 심볼 | 다이얼 자물쇠 | 비고 |
|---|---:|---|---|
| London | 38 | Case 01 (컬러 그림 4종) | Case 01 단서 4건은 `RoyalBoxPicture`로 컬러 그림 표시 |
| Paris | 36 | 없음 | |
| Rome | 36 | Case 01·03·05·07·09 (선 아이콘) | |
| New York | 36 | Case 03·05 (선 아이콘) | |

단서 심볼에 쓰인 키 22종: letter 19, clock 15, feather 13, map 10, frame 10, gear 9, footprint 9, seal 7, watch 7, bag 6, ticket 6, train 6, mask 5, key 5, gem 4, park 4, raven 4, crown 2, umbrella 2, button 1, cloth 1, museum 1.

### 3.4 시즌별 기타 차이

- **배지는 런던 전용이다.** 사건 배지 6종(`clockWatcher`~`londonLegend`)이 모두 `ep02`~`ep12`에 묶여 있고 파리·로마·뉴욕 사건 배지는 없다. 아이콘 문제는 아니지만 "보상" 화면을 조사하면서 확인한 공백이다.
- **시즌 조사 보드의 인물 표시**: 런던(`ravens`, `ravenSociety`, `clockmaker`, `clockmakerWatch`)과 파리(`emile`)만 정의됨. 로마·뉴욕은 `'?'` 텍스트로 표시된다 ([investigation_board.dart:610](../lib/features/season/widgets/investigation_board.dart#L610)). 런던 `ravens`는 선 아이콘(`raven` 글리프), `clockmaker`는 톱니 글리프 위 `'?'`.

---

## 4. 공통 컴포넌트별 사용 현황과 영향 범위

같은 컴포넌트가 여러 화면에 쓰이므로, **컴포넌트 하나를 고치면 아래 화면 전체가 한 번에 바뀐다.**

| 컴포넌트 (파일) | 표시 내용 | 사용 화면 | 이미지 교체 시 영향 |
|---|---|---|---|
| `_EvidenceArt` ([evidence_card.dart:297](../lib/widgets/evidence_card.dart#L297)) | 증거 원형 그림: 그린 문서 → 사진 → **선 아이콘** 순 | `EvidenceTile`(수첩, 시즌 아카이브, 최종 미션 수첩), `EvidenceThumb`(사건 대화, 증거 회상), `EvidencePicture`(증거 회상, 쉬운 단계, 사건 대화), `EvidenceChip`(정답 피드백, 스토리 장면 = **Clue Discovered**), 증거 확대 보기, 증거 연결 행 | `evidencePictures`에 한 줄 추가 = 위 모든 화면에 반영. **코드 변경 불필요** |
| `SymbolBadge` ([symbol_icon.dart:74](../lib/widgets/symbol_icon.dart#L74)) | 원형 도장 안 심볼 | `ClueCard`(미션, 수첩, 시즌 아카이브, 지도 화면, 최종 미션, How to Play), **증거 보드**, **Street Book**, 최종 미션 자물쇠, `SymbolSequence` | `ArtAssets.symbols`에 넣으면 전부 반영 (단색 틴트). 단 증거 보드·Street Book은 증거 그림을 쓰지 않으므로 별도 수정 필요 |
| `GameSymbol` ([symbol_icon.dart:14](../lib/widgets/symbol_icon.dart#L14)) | 24개 키 → 글리프·색·라벨 | 위 둘 + `scene_decode` | 키 체계가 곧 공통 매핑 |
| `ClueCard` ([clue_card.dart](../lib/widgets/clue_card.dart)) | 단서 값 + 심볼 배지 | 6개 화면 | 심볼 이미지화 시 4개 시즌 146건 동시 변경 |
| `BadgeMedal` ([badge_medal.dart](../lib/widgets/badge_medal.dart)) | 메달 PNG (없으면 글리프) | 탐정 프로필, 사건 결과, 배지 다이얼로그 | 15종 모두 PNG 존재. 교체 불필요 |
| `CoinBalance` ([coin_balance.dart:33](../lib/widgets/coin_balance.dart#L33)) | 코인 글리프 + 숫자 | 지도, 팁 상점, How to Play | B |
| `HintBulb` / `detective_tips.dart` | 힌트 전구 글리프 + 불빛 | 미션 화면 힌트, 팁 | B |
| `MapPin` ([map_pin.dart](../lib/features/mission_map/widgets/map_pin.dart)) | 코드로 그린 핀, `'?'`, check | 미션 지도 (런던·파리·로마·뉴욕 공통) | B |
| `InkStar` | 별 | 사건 결과(Case Report), 보호자 리포트 | B |
| `DetectivePortrait`/`detective_character.dart` | 아바타 그림 (없으면 deerstalker) | 전 화면 | 그림 모두 존재 → 대체 표시만 남음 |

### 화면별 체크 (요청 화면 목록 기준)

| 화면 | 주요 아이콘 | 교체 대상 |
|---|---|---|
| Case Files / 시즌 화면 (`season_screen`, `episode_select_screen`) | folder, seal, train, lock, arrow | B (folder·seal 도장) |
| Mission (`mission_screen`) | back, notebook, letter 버튼, hint, ClueCard, EvidenceTile | **A: 단서 심볼, 증거 그림** |
| Investigation / Search (`investigation_search`, `scene_explore`, `lens_inspect`) | search, check, hint, letter 버튼, key 엠블럼 | 장면 내 발견물은 이미 사진(`picture:`) 사용. key 엠블럼 B |
| Puzzle (미션 위젯 50여 개) | check, search, gear·key·sun·footprint·letter 토큰 | **A: 파리 시계공 각인(gear) — 스토리 상징** / B: plan_route 발자국·편지 토큰, 해시계 sun |
| Clue Discovered (`answer_feedback`, `story_scene_screen`) | `EvidenceChip`, notebook | **A: 증거 그림** |
| Evidence (확대 보기, 증거 연결) | `_EvidenceArt`, `SymbolSequence` | **A** |
| Notebook (`notebook_screen`) | EvidenceTile, ClueCard, lock, `'?'` | **A** + B(`'?'` 빈 칸) |
| Inventory | **별도 인벤토리 화면 없음** (수첩이 그 역할) | — |
| Map (`mission_map_screen`, `world_map_screen`) | 메뉴 글리프 6종, 지도 핀, 월드맵 핀(PNG) | B (핀·메뉴) |
| Case Report (`case_solved_screen`) | InkStar, folder, seal, train, pin, lock, notebook | B (별) |
| Investigation Board (`evidence_board`, 시즌 `investigation_board`) | SymbolBadge(증거), raven·gear 글리프, `'?'` | **A: 증거 보드 배지** / B: 시즌 보드 인물 |
| Detective Profile (`detective_settings_screen`, `detective_form`) | deerstalker, pen, check, BadgeMedal | 메달은 이미지. 유지 |
| World Archive (`world_archive_screen`) | seal, lock, deerstalker, pin | B |
| 보상·배지·힌트·코인 | BadgeMedal(PNG), coin, hint, InkStar | B |

---

## 5. 교체 후보 전체 목록 (A 그룹)

### 5.1 A 그룹 아이콘 종류 (23종)

`GameSymbol` 심볼 키 기준. 이 아이콘들은 **같은 글리프가 증거 대체 그림 + 단서 배지 + 자물쇠 + 증거 보드 배지**로 함께 쓰인다.

| # | 심볼 키 (글리프) | 현재 모습 | 의미 | 쓰는 시즌 | 교체 이유 |
|---:|---|---|---|---|---|
| 1 | `letter` | 봉투 사각형+V | 편지·문서 전반 | 4개 시즌 | 64건의 서로 다른 문서가 같은 봉투 → 구분 불가 |
| 2 | `ticket` | 사각형+절취선 | 카드·표·꼬리표 | 4 | 카드·표·이름표·로그가 한 모양 |
| 3 | `map` | 접힌 지도 | 지도·조각·경로 | 4 | 지도 조각 3장이 같은 그림 (런던 Case 07 퍼즐의 핵심 사물) |
| 4 | `seal` | 이중 원+십자 | 봉인·각인·카드 | 4 | 십자 원은 봉인으로 읽히기 어려움 |
| 5 | `feather` | 선 3개 깃털 | 깃털 | 4 | 생성 시즌에서 노래·수첩·둥지에 오용 |
| 6 | `frame` | 액자+산 | 그림·사진 | 4 | 사진·스케치·찢긴 쪽이 한 모양 |
| 7 | `key` | 원+막대 | 열쇠 | 4 | 상자·금고·돌에 오용 |
| 8 | `clock` / `watch` | 원+바늘 | 시계·회중시계·시간 기록 | 4 | 두 키가 같은 글리프 |
| 9 | `footprint` | 타원 2개 | 발자국 | 4 | **사용자 지적 사례.** 발자국으로 안 읽힘. 가루·털·진술에 오용 |
| 10 | `gear` | 원+살 8개 | 톱니 / **시계공 각인(스토리 상징)** | 1, 2, 4 | 파리 전체에 걸친 범인 상징인데 일반 톱니 선화 |
| 11 | `gem` | 다이아 다각형 | 보석·상자·통 | 1, 4 | Blue Star(핵심 도난품)가 선화 |
| 12 | `mask` | 가면 | 가면 | 1, 3, 4 | 진술·자백에 오용 |
| 13 | `button` | 원+구멍 4 | 단추 | 1, 3 | 고양이 목걸이 태그에 오용 |
| 14 | `cloth` | 지그재그 천 | 천 조각 | 1 | **사용자 지적 사례.** 기존 `blue_cloth.png` 있음 |
| 15 | `whistle` | 원+관 | 호루라기 | 1 | Silver Whistle·Toy Train Whistle 구분 불가 |
| 16 | `raven` | 새 윤곽 | 까마귀 | 1 | 시즌 1 핵심 상징. `raven_mark.png`·`raven_master.png` 존재 |
| 17 | `bag` | 가방 | 가방·자루 | 3 | |
| 18 | `umbrella` | 우산 | (Yellow Helmet에 오용) | 3 | 사진 있으나 증거 보드에선 우산으로 보임 |
| 19 | `crown` | 왕관 | 왕관 | 1 | 증거는 이미 사진. 단서 배지 2건만 선화 |
| 20 | `train` | 기관차 | King's Cross | 1 | 단서 배지·기차표 헤더 |
| 21 | `museum` | 신전 정면 | British Museum | 1 | 단서 배지 |
| 22 | `park` | 나무 | Hyde Park | 1 | 단서 배지 |
| 23 | 모노그램 (`palace`·미상 `?`) | 글자 P / ? | 그림 없는 심볼 | (현재 노출 거의 없음) | 코드 주석상 "Custom Asset Required" 자리표시 |

### 5.2 증거별 교체 후보 (선 아이콘으로 표시되는 119건 전부)

**권장 구분**

- **재사용**: 프로젝트에 이미 있는 그림을 `evidencePictures`에 등록만 하면 됨.
- **개별 신규**: 그 증거만의 고유 사물. 스토리상 단 하나여야 하는 물건 → 고유 이미지 필요.
- **공용 문서(템플릿)**: 문서형 증거. 내용(영어 문장)이 핵심이고 겉모양은 종류별로 공유해도 됨. 가능하면 파리처럼 빈 종이 위에 `inscription`을 코드로 그려 영어 학습 요소를 살림.
- **공용(진술)**: 물건이 아니라 증언·이야기·자백. 공용 "진술 메모" 한 장으로 충분.
- **재사용(부엉이 카드)**: 로마의 "Owl Card" 계열 7건은 기존 `owl_card.png`(s3_ep01_e3) 공유.

| 구분 | 건수 | 필요 이미지 |
|---|---:|---:|
| 재사용 | 12 | 0 |
| 재사용(부엉이 카드) | 7 | 0 |
| **개별 신규** | **30** | **30** |
| 공용 문서 (10종 템플릿) | 63 | 10 |
| 공용 진술 | 7 | 1 |
| **합계** | **119** | **41** |

시즌별: London 40건(신규 11 / 문서 22 / 재사용 6 / 진술 1), Paris 6건(신규 1 / 문서 2 / 재사용 3), Rome 34건(신규 7 / 문서 14 / 진술 5 / 부엉이 7 / 재사용 1), New York 39건(신규 11 / 문서 25 / 진술 1 / 재사용 2).

공용 문서 템플릿 사용 건수: 메모·쪽지 25, 카드 11, 기록부·일지 6, 편지 5, 지도 조각 4, 이름표·꼬리표 3, 일기장 3, 표 2, 안내문·표지 2, 악보 2.

#### London

| 증거 ID | 이름 | 현재 아이콘 키 | 권장 | 에셋 / 비고 |
|---|---|---|---|---|
| e04 | London Map | `map` | **개별 신규** | `season_01_london/objects/london_map_two_swans.png` — 두 마리 백조가 그려진 지도(기존 map.png엔 백조 없음 — art_assets.dart 주석) |
| ep02_e1 | Broken Clock Note | `clock` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep02_e2 | Small Brass Gear | `gear` | 재사용 | `season_01_london/objects/brass_gear.png` — 까마귀 각인까지 일치 |
| ep02_e3 | Time Card | `ticket` | 공용 문서(카드) | `doc_card.png` |
| ep02_e4 | Raven Feather | `feather` | **개별 신규** | `season_01_london/objects/raven_feather.png` |
| ep03_e2 | Blue Cloth | `cloth` | 재사용 | `season_01_london/objects/blue_cloth.png` — 투명 배경, 까마귀 자수 일치 |
| ep03_e3 | Wet Footprint | `footprint` | 재사용 | `season_01_london/objects/wet_footprint.png` — 검은 배경·세로 2:3 → 원형 프레임 크롭 확인 필요 |
| ep03_e4 | Luggage Tag | `ticket` | 공용 문서(이름표·꼬리표) | `doc_tag.png` |
| ep04_e2 | Word Card | `ticket` | 공용 문서(카드) | `doc_card.png` |
| ep04_e3 | Postmark | `letter` | **개별 신규** | `season_01_london/objects/postmark_stamp.png` |
| ep04_e4 | The Secret Letter | `letter` | 공용 문서(편지) | `doc_letter.png` — 공용 letter.png 재사용 가능(e01·ep10_e3와 동일 그림이 됨) |
| ep05_e1 | Ravenmaster's Card | `map` | 공용 문서(카드) | `doc_card.png` |
| ep05_e2 | Direction Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep05_e4 | Old Map Fragment | `map` | 공용 문서(지도 조각) | `doc_mappiece.png` |
| ep06_e1 | Witness Notes | `letter` | 공용(진술) | `doc_statement.png` |
| ep06_e2 | Detective Card | `ticket` | 공용 문서(카드) | `doc_card.png` |
| ep06_e3 | Theatre Ticket | `ticket` | 공용 문서(표) | `doc_ticket.png` |
| ep06_e4 | Silver Whistle | `whistle` | **개별 신규** | `season_01_london/objects/silver_whistle.png` |
| ep07_e1 | River Map Piece | `map` | 공용 문서(지도 조각) | `doc_mappiece.png` |
| ep07_e2 | Station Map Piece | `map` | 공용 문서(지도 조각) | `doc_mappiece.png` |
| ep07_e3 | Joined Map | `map` | 재사용 | `shared/objects/map.png` — 이어 붙인 지도 — 이음선 없는 점 확인 필요 |
| ep07_e4 | The Old London Map | `map` | 재사용 | `shared/objects/map.png` — “까마귀가 그려진 지도”와 불일치 시 신규 |
| ep08_e1 | Name Tag | `ticket` | 공용 문서(이름표·꼬리표) | `doc_tag.png` |
| ep08_e2 | Passenger Notes | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep08_e3 | The Raven Tower | `frame` | **개별 신규** | `season_01_london/objects/raven_tower_drawing.png` |
| ep08_e4 | Empty Jewel Box | `gem` | **개별 신규** | `season_01_london/objects/empty_jewel_box.png` — 기존 jewel_case.png는 내용물(티아라)이 있어 부적합 |
| ep09_e1 | Velvet Card | `gem` | 공용 문서(카드) | `doc_card.png` |
| ep09_e2 | Torn Name Tag | `ticket` | 공용 문서(이름표·꼬리표) | `doc_tag.png` |
| ep09_e3 | Guard Timetable | `clock` | 공용 문서(기록부·일지) | `doc_log.png` |
| ep09_e4 | The Blue Star | `gem` | **개별 신규** | `season_01_london/objects/blue_star_jewel.png` |
| ep10_e1 | Poppy's Ring | `raven` | **개별 신규** | `season_01_london/objects/poppys_ring.png` |
| ep10_e2 | Raven Papers | `feather` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep10_e4 | The Raven's Warning | `feather` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep11_e1 | Usher's Notes | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| ep11_e2 | White Mask | `mask` | **개별 신규** | `season_01_london/objects/white_mask.png` |
| ep11_e3 | Toy Train Whistle | `whistle` | **개별 신규** | `season_01_london/objects/toy_train_whistle.png` |
| ep11_e4 | The Shadow's Card | `letter` | 공용 문서(카드) | `doc_card.png` |
| ep12_e1 | The Real Gear | `gear` | 재사용 | `season_01_london/objects/brass_gear.png` — ep02_e2와 같은 톱니(“진짜 톱니”) — 의도된 동일 그림 |
| ep12_e2 | Arrivals Board | `ticket` | **개별 신규** | `season_01_london/objects/arrivals_board.png` |
| ep12_e3 | Poppy's Riddle | `feather` | 공용 문서(메모/쪽지) | `doc_note.png` |

#### Paris

| 증거 ID | 이름 | 현재 아이콘 키 | 권장 | 에셋 / 비고 |
|---|---|---|---|---|
| s2_ep01_e1 | Station Notice | `letter` | 공용 문서(안내문·표지) | `doc_notice.png` |
| s2_ep01_e3 | The Clockmaker's Mark | `seal` | **개별 신규** | `season_02_paris/objects/clockmaker_mark_gear_m.png` — 시즌2 공통 스토리 상징(톱니+M) — 퍼즐 속 각인 글리프도 같은 그림으로 |
| s2_ep02_e2 | The Artist's Notes | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s2_ep02_e4 | The Painter's Message | `letter` | 재사용 | `season_02_paris/cases/case_02/canvas_back.png` — Artwork.paintersMessage와 같은 그림 |
| s2_ep03_e1 | The Conflicting Notices | `letter` | 재사용 | `season_02_paris/cases/case_03/tower_notice_board.png` — 정답 노출 여부 확인 |
| s2_ep03_e2 | The Lift Log | `ticket` | 재사용 | `season_02_paris/cases/case_03/lift_log.png` — 정답 노출 여부 확인 |

#### Rome

| 증거 ID | 이름 | 현재 아이콘 키 | 권장 | 에셋 / 비고 |
|---|---|---|---|---|
| s3_ep01_e2 | White Dust | `footprint` | **개별 신규** | `season_03_rome/objects/white_dust.png` |
| s3_ep01_e4 | The Light Box | `key` | **개별 신규** | `season_03_rome/objects/light_box.png` |
| s3_ep02_e1 | The Owl's Second Card | `seal` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep02_e2 | A Page from Aldo's Notebook | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s3_ep02_e4 | The Owl's Route Card | `map` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep03_e1 | Pia's Order Book | `letter` | 공용 문서(기록부·일지) | `doc_log.png` |
| s3_ep03_e2 | A Bag of White Dust | `bag` | **개별 신규** | `season_03_rome/objects/bag_of_white_dust.png` |
| s3_ep03_e3 | Pia's Story | `footprint` | 공용(진술) | `doc_statement.png` |
| s3_ep04_e1 | The Pantheon Owl Card | `seal` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep04_e2 | The Owl's Note to the Bookseller | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s3_ep04_e3 | The Owl's Test Card | `letter` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep05_e1 | An Orange Cat Hair | `footprint` | **개별 신규** | `season_03_rome/objects/orange_cat_hair.png` |
| s3_ep05_e2 | Tito's Collar Tag | `button` | **개별 신규** | `season_03_rome/objects/cat_collar_tag.png` |
| s3_ep05_e3 | Carla's Copy Steps | `frame` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s3_ep06_e1 | Giulia's Notes on Aldo | `letter` | 공용(진술) | `doc_statement.png` |
| s3_ep06_e2 | The Hall B Door Log | `clock` | 공용 문서(기록부·일지) | `doc_log.png` |
| s3_ep06_e3 | Aldo's Mirror Sketch | `letter` | **개별 신규** | `season_03_rome/objects/mirror_sketch.png` |
| s3_ep07_e1 | The Owl's Steps Card | `seal` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep07_e2 | The Chalk Code | `letter` | **개별 신규** | `season_03_rome/objects/chalk_code.png` |
| s3_ep08_e1 | The Bridge Owl Card | `seal` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |
| s3_ep08_e2 | Livia's Story | `feather` | 공용(진술) | `doc_statement.png` |
| s3_ep08_e3 | Livia's Diary | `letter` | 공용 문서(일기장) | `doc_diary.png` |
| s3_ep09_e1 | Aldo's Latin Card | `letter` | 공용 문서(카드) | `doc_card.png` |
| s3_ep09_e2 | The Old Street on the Map | `map` | 재사용 | `season_03_rome/objects/city_plan.png` — 같은 사건의 e4 그림 — 구분 필요 시 신규 |
| s3_ep09_e3 | Giulia's Word List | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s3_ep10_e1 | The Site Rules | `letter` | 공용 문서(안내문·표지) | `doc_notice.png` |
| s3_ep10_e3 | The Site Gate Log | `letter` | 공용 문서(기록부·일지) | `doc_log.png` |
| s3_ep10_e4 | Your Message to Sofia | `letter` | 공용 문서(편지) | `doc_letter.png` |
| s3_ep11_e2 | Pia's Answer | `letter` | 공용(진술) | `doc_statement.png` |
| s3_ep11_e3 | The Inspector's List | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s3_ep11_e4 | Valli's Confession | `mask` | 공용(진술) | `doc_statement.png` |
| s3_ep12_e1 | The Safety Card | `letter` | 공용 문서(카드) | `doc_card.png` |
| s3_ep12_e2 | Aldo's Library Card | `letter` | 공용 문서(카드) | `doc_card.png` |
| s3_ep12_e4 | The Owl's Last Card | `seal` | 재사용(부엉이 카드) | `season_03_rome/objects/owl_card.png` |

#### New York

| 증거 ID | 이름 | 현재 아이콘 키 | 권장 | 에셋 / 비고 |
|---|---|---|---|---|
| s4_ep01_e1 | Frank's Night Log | `watch` | 공용 문서(기록부·일지) | `doc_log.png` |
| s4_ep01_e4 | The Page Stub | `frame` | **개별 신규** | `season_04_newyork/objects/page_stub.png` |
| s4_ep02_e1 | The Star Print | `footprint` | 재사용 | `season_04_newyork/objects/star_sole.png` — Case 07 증거 그림 — 앞선 사건에서 밑창을 보여 줘도 되는지 확인 |
| s4_ep02_e3 | Eleanor's Egg Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep02_e4 | The Tea House Address | `map` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep03_e2 | Mei Lee's Recipe | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep03_e3 | Mei Lee's Diary | `letter` | 공용 문서(일기장) | `doc_diary.png` |
| s4_ep03_e4 | The Tin Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep04_e1 | The Wet Paint Sign | `footprint` | **개별 신규** | `season_04_newyork/objects/wet_paint_sign.png` |
| s4_ep04_e3 | The Painter's Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep04_e4 | Eleanor's Spare Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep05_e1 | Otto's Letter | `letter` | 공용 문서(편지) | `doc_letter.png` |
| s4_ep05_e2 | Otto's Diary | `letter` | 공용 문서(일기장) | `doc_diary.png` |
| s4_ep05_e3 | Otto's Tiny Screws | `gear` | **개별 신규** | `season_04_newyork/objects/tiny_screws.png` |
| s4_ep05_e4 | Karl's Old Photo | `frame` | **개별 신규** | `season_04_newyork/objects/karl_old_photo.png` |
| s4_ep06_e1 | Otto's Ferry Ticket | `ticket` | 공용 문서(표) | `doc_ticket.png` |
| s4_ep06_e2 | The Seagull Photo | `frame` | **개별 신규** | `season_04_newyork/objects/seagull_photo.png` |
| s4_ep06_e3 | Maya's List | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep06_e4 | Karl's Pocket Book | `feather` | **개별 신규** | `season_04_newyork/objects/karl_pocket_book.png` |
| s4_ep07_e2 | Sam's Sunday Story | `mask` | 공용(진술) | `doc_statement.png` |
| s4_ep07_e3 | The Crew's Schedule | `letter` | 공용 문서(기록부·일지) | `doc_log.png` |
| s4_ep07_e4 | The Scribbled Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep08_e1 | Rosa's Tune | `feather` | 공용 문서(악보) | `doc_music.png` |
| s4_ep08_e2 | Grandma Ana's Note | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep08_e3 | Rosa's Family Tree | `letter` | **개별 신규** | `season_04_newyork/objects/family_tree.png` |
| s4_ep09_e1 | The Keeper's Card | `letter` | 공용 문서(카드) | `doc_card.png` |
| s4_ep09_e2 | Eleanor's Wheel Box | `key` | **개별 신규** | `season_04_newyork/objects/wheel_box.png` |
| s4_ep09_e3 | Eleanor's Last Letter | `letter` | 공용 문서(편지) | `doc_letter.png` |
| s4_ep09_e4 | Eleanor's Last Steps | `map` | 공용 문서(지도 조각) | `doc_mappiece.png` |
| s4_ep10_e1 | Rosa's Notes | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep10_e2 | Nora's Message | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep10_e3 | Dexter's Dropped Page | `letter` | 공용 문서(메모/쪽지) | `doc_note.png` |
| s4_ep10_e4 | Rosa's Copy of the Song | `feather` | 공용 문서(악보) | `doc_music.png` |
| s4_ep11_e1 | Dexter's Library Pass | `ticket` | 공용 문서(카드) | `doc_card.png` |
| s4_ep11_e2 | The Brass Bird, Found | `feather` | 재사용 | `season_04_newyork/objects/brass_bird.png` — Case 04 그림과 같은 새 |
| s4_ep11_e4 | Dexter's Safe | `key` | **개별 신규** | `season_04_newyork/objects/dexter_safe.png` |
| s4_ep12_e1 | The Stone Nest | `feather` | **개별 신규** | `season_04_newyork/objects/stone_nest.png` |
| s4_ep12_e2 | The Open Stone | `key` | **개별 신규** | `season_04_newyork/objects/open_stone.png` |
| s4_ep12_e3 | Eleanor's Letter to the Finder | `letter` | 공용 문서(편지) | `doc_letter.png` |

---

## 6. 증거마다 고유 이미지가 필요한가, 공유해도 되는가

| 경우 | 판단 | 이유 |
|---|---|---|
| 도난품·핵심 사물 (Blue Star, White Mask, Silver Whistle, Poppy's Ring, Stone Nest) | **고유 이미지 필수** | 이야기의 목표물. 다른 증거와 같은 그림이면 몰입이 깨짐 |
| 같은 사물이 다시 나오는 경우 (Small Brass Gear ↔ The Real Gear, Brass Bird ↔ Brass Bird Found) | **같은 그림 공유 권장** | 같은 물건임을 그림이 알려 주는 것이 추리에 도움 |
| 시리즈 사물 (로마 Owl Card 8장, 런던 Map Piece 3장) | **기본 그림 공유 + 글자/조각 차이만 코드로** | 같은 범인이 남긴 카드라는 연속성이 오히려 단서 |
| 문서 (메모, 편지, 목록, 일지) | **종류별 템플릿 공유** | 내용이 핵심. 단, 이름·영어 문장이 함께 보여야 구분됨 |
| 진술·이야기·자백 | **공용 1장** | 물리적 실체가 없음. 억지로 그리면 오히려 잘못된 단서가 됨 |
| 정답이 그림에 드러날 위험 (Lift Log, Conflicting Notices, Wet Footprint의 문양, Star Print ↔ Star Boot Sole) | **사용 전 퍼즐별 확인** | 증거 보드·Street Book·증거 회상·사건 대화에서 증거가 **선택지**로 쓰임. 그림이 이름·각인 이상의 정보를 주면 퍼즐이 쉬워짐 |

---

## 7. A·B 그룹 교체 가능성 분석

### 7.1 A-1. 증거 그림 (최우선)

| 항목 | 내용 |
|---|---|
| 현재 모습·의미 | 원형 종이 프레임 안 24×24 단색 선화 (크기 32–150px로 확대됨). 사물 그림이 없다는 표시에 가까움 |
| 코드 위치 | 대체 경로: [evidence_card.dart:337-338](../lib/widgets/evidence_card.dart#L337-L338) (`picture == null ? mark`). 등록처: [art_assets.dart:575](../lib/widgets/art_assets.dart#L575) `evidencePictures`, 로마·뉴욕은 `lib/data/generated/*/s?_*_art.g.dart`의 `*EvidencePictures` |
| 시즌·화면 | 4개 시즌. 수첩, 시즌 아카이브, 최종 미션, Clue Discovered, 증거 확대, 증거 회상, 사건 대화 |
| 교체 이유 | 증거는 "발견의 보상"이자 추리 도구. 선 아이콘은 무엇을 찾았는지 전달하지 못함 |
| 기존 이미지 재사용 | 19건 가능 (5.2 표) |
| 신규 생성 | 41장 (개별 30 + 문서 10 + 진술 1) |
| 권장 파일명 | 개별: `assets/seasons/season_0N_<city>/objects/<snake_name>.png` (로마·뉴욕 기존 규칙과 동일). 공용: `assets/shared/evidence_docs/doc_<type>.png` |
| 권장 크기·배경 | 정사각 **1024×1024 원본 / 배포 512×512**, **투명 배경(RGBA)**, 사물은 중앙에 두고 사방 12% 이상 여백 (원형 프레임에 잘리지 않게). 가로로 긴 사물(표, 지도)은 `evidencePrints` 비율 등록으로 확대 보기에서 전체 표시. 기존 규칙: 컬러, 틴트하지 않음 |
| 일괄 교체 가능 여부 | **가능.** 런던·파리는 `evidencePictures`에 줄 추가만. 로마·뉴욕은 `content_pipeline/seasons/s?_*/assets.manifest.json` 갱신 후 재생성 (`.g.dart` 직접 수정 금지) |
| 다른 시즌 영향 | 없음 (증거 ID 단위 등록) |

공용 문서 템플릿 10종 + 진술 1종:

| 파일 | 모습 | 쓰는 증거 수 |
|---|---|---:|
| `doc_note.png` | 접힌 쪽지/찢은 메모장 한 장 | 25 |
| `doc_card.png` | 두꺼운 명함형 카드 | 11 |
| `doc_log.png` | 줄 쳐진 장부·근무표 한 쪽 | 6 |
| `doc_letter.png` | 펼친 편지지 (기존 `shared/objects/letter.png`는 봉인된 봉투라 별도) | 5 |
| `doc_mappiece.png` | 찢긴 지도 조각 | 4 |
| `doc_tag.png` | 끈 달린 꼬리표 | 3 |
| `doc_diary.png` | 펼친 일기장 | 3 |
| `doc_ticket.png` | 옛 승차권/입장권 | 2 |
| `doc_notice.png` | 게시 안내문 | 2 |
| `doc_music.png` | 악보 한 장 | 2 |
| `doc_statement.png` | 탐정 수첩의 진술 기록 페이지 | 7 |

- **글자 없이** 그려야 한다. 영어 문장은 코드가 얹는다(파리 `PictureEvidence`/`EasyEvidence` 방식 재사용). 글자를 그림에 넣으면 영어 학습 요소가 고정 이미지에 갇히고, 틀린 철자 위험도 생김.
- 4개 시즌 공용이므로 특정 도시 장식(유니언잭, 에펠탑 등)을 넣지 않는다.

### 7.2 A-2. 증거 보드 / Street Book의 증거 배지

| 항목 | 내용 |
|---|---|
| 현재 | `SymbolBadge(evidence.icon, size: 32–34)` — **사진 있는 증거도 선 아이콘** |
| 위치 | [evidence_board.dart:220](../lib/features/mission/widgets/evidence_board.dart#L220), [street_book.dart:276](../lib/features/mission/widgets/street_book.dart#L276) |
| 시즌·화면 | 파리 Case 03·04·08 증거 보드, Street Book 퍼즐 |
| 교체 방법 | 신규 이미지 없이 `EvidenceThumb(evidence:, size:)`로 바꾸면 증거 그림을 그대로 씀 (코드 2곳). 정답 노출 여부만 확인 |
| 영향 | 해당 퍼즐 위젯만. 다른 시즌은 이 위젯을 쓰는 사건이 생길 때 자동 적용 |

### 7.3 A-3. 단서·자물쇠 심볼 스탬프 세트

| 항목 | 내용 |
|---|---|
| 현재 | `SymbolBadge` 원형 도장 안 선 아이콘 (단서 카드 32px, 자물쇠 46px, scene_decode 큰 크기) |
| 위치 | [symbol_icon.dart:29-60](../lib/widgets/symbol_icon.dart#L29-L60) `_symbols`, [art_assets.dart:732](../lib/widgets/art_assets.dart#L732) `symbols = {}` |
| 시즌·화면 | 4개 시즌 단서 146건, 자물쇠 7개 사건, 증거 대체 표시 |
| 교체 이유 | 단서 카드 하단의 작은 도장이라 사진보다 **목판·도장 느낌의 단색 실루엣**이 적합. 선화보다 면이 있는 실루엣이 18–32px에서 훨씬 잘 읽힘 |
| 재사용 | `raven` ← `raven_mark.png`는 컬러라 틴트용으론 부적합(코드 주석과 테스트에서 금지: `art_assets_test.dart:363`). 신규 필요 |
| 신규 | 22종 + 미상 1종 = **23장** |
| 권장 파일명 | `assets/shared/symbols/symbol_<key>.png` (`symbol_letter.png`, `symbol_footprint.png` …) |
| 권장 크기·배경 | 256×256, 투명 배경, **단색(검정) 실루엣** — `InkMark`가 `BlendMode.srcIn`으로 심볼 색을 입힘. 18px에서도 형태가 남는 굵은 면 위주 |
| 일괄 교체 | **가능, 코드 변경 0.** `ArtAssets.symbols`에 키별 한 줄. 실패하면 글리프로 자동 복귀 |
| 다른 시즌 영향 | **4개 시즌 동시 변경.** 런던 Case 01 자물쇠(컬러 `royalBoxLocks`)는 영향 없음 |
| 주의 | 이 세트는 **증거 그림을 대신하지 못한다.** 단색 도장은 Blue Cloth 문제를 "더 나은 아이콘"으로만 바꿀 뿐. 증거는 7.1로 해결해야 함 |

### 7.4 A-4. 스토리 상징 — 파리 "시계공의 각인"

| 항목 | 내용 |
|---|---|
| 현재 | 일반 톱니 글리프. 문지르기 퍼즐에서 190px로 표시 ([easy_steps.dart:1306](../lib/features/mission/widgets/easy_steps.dart#L1306)), Case 09 각인 비교 ([clockwork_garden.dart:1017](../lib/features/mission/widgets/clockwork_garden.dart#L1017)), Case 10 명판·엠블럼 ([star_records.dart:391](../lib/features/mission/widgets/star_records.dart#L391), [:1964](../lib/features/mission/widgets/star_records.dart#L1964)), 증거 `s2_ep01_e3` |
| 교체 이유 | 시즌 2를 관통하는 범인 표식("tiny carved gear, and the letter M"). 문구에 있는 **M이 그림에 없음** |
| 신규 | 1장 (단색, 투명): `assets/seasons/season_02_paris/symbols/clockmaker_mark.png`. 증거용 컬러 각인 사진은 5.2의 `clockmaker_mark_gear_m.png` |
| 주의 | `docs/SEASON2_PARIS_STORY_BIBLE.md`의 각인 묘사와 맞춰야 함. 일부 퍼즐은 각인의 **모양 비교**가 정답이므로 퍼즐 위젯 수정이 수반됨 (단순 교체 아님) |

### 7.5 B 그룹 (14종) — 선택적 교체

| 아이콘 | 현재 / 위치 | 판단 | 신규 이미지 | 권장 파일명·크기 |
|---|---|---|---|---|
| `coin` | 코인 잔액·팁 상점 | 경제 UI의 얼굴. 컬러 동전 1장이면 보상감 상승 | 1 | `shared/ui/coin.png` 128², 투명, 컬러 |
| `hint` (+HintBulb 불빛) | 힌트 버튼 20곳 | 불빛 애니메이션이 글리프 격자에 맞춰져 있어 교체 시 `HintBulbLight` 재작업 | 1 | `shared/ui/hint_lamp.png` — **보류 권장** |
| `InkStar` | Case Report 별 | 별 자체는 명확. 금박 별 그림으로 보상감 | 2 (채움/빈) | `shared/ui/star_filled.png`, `star_empty.png` 128² |
| `notebook`, `folder` | 수첩·사건 파일 메뉴 | 게임 고유 메뉴. 지금도 의미는 명확 | 2 | `shared/ui/menu_notebook.png`, `menu_case_file.png` 128² |
| `seal` (아카이브 도장 용도) | World Archive, 시즌 파일 | 밀랍 도장 그림이면 분위기 상승 | 1 | `shared/ui/archive_seal.png` |
| `pin` | Season board, CURRENT FILE | 월드맵 핀 PNG와 통일 가능 | 0 (재사용 `world_map/pin_in_progress.png` 축소 검토) | — |
| `deerstalker` | 아바타 대체·난이도·엠블럼 | 아바타 그림이 있어 대체로 미노출. 난이도 모자는 유지 가능 | 0 | — |
| `eye`, `puzzle`, `sun` | 퍼즐 내 보조 버튼, 해시계 | 기능 아이콘에 가까움 | 0 | 유지 권장 |
| 지도 핀 마크 | 미션 지도 핀 | 4개 시즌 공통. 지도 그림 위 코드 핀이 현재 스타일과 잘 맞음 | 0–3 | 유지 권장 |
| 밀랍 봉인 모노그램 | 편지 카드 | 코드 그림 품질 양호 | 0 | 유지 |
| `'?'` 잠김/미상 표시 | 지도 핀, 수첩 빈 칸, 조사 보드 | 로마·뉴욕 조사 보드는 인물 그림 대신 `'?'`만 표시 → 시즌별 "정체 미상 인물" 실루엣 검토 | 0–2 | `season_0N_<city>/characters/unknown_figure.png` |
| 번호 스탬프 | 순서 퍼즐 | 정답 정보이므로 텍스트 유지 | 0 | 유지 |

B 그룹 신규 예상: **최소 0장 ~ 최대 약 10장** (권장 최소안: 코인 1 + 별 2 = 3장).

### 7.6 C 그룹 (21종) — 유지

back, arrow, close, menu, down, chevron, search, check, pen, backspace, clear, speaker, speakerOff, home, lock, stopwatch(배지 대체 전용), 텍스트 `✓`, `↶/↷`, `›`, `−/+`, 종이 장식 페인터.

- 시스템·조작 아이콘이라 선화가 오히려 맞다. 현재 Ink 스타일이 게임 분위기와 일관됨.
- 정리 권장(이미지 아님): `'✓'` 텍스트 2곳을 `InkGlyph.check`로 통일. 사용하지 않는 `InkGlyph.qr`, 호출처 없는 `glyphNamed()`([season_props.dart:205](../lib/features/season/widgets/season_props.dart#L205)) 정리 검토.

---

## 8. 중복 아이콘과 재사용 가능 에셋

### 8.1 의미 중복

| 중복 | 위치 | 정리안 |
|---|---|---|
| `clock` ↔ `watch` 키가 같은 글리프 | `symbol_icon.dart` | 심볼 세트에서 `symbol_watch.png`(회중시계) 분리 |
| `letter` 글리프 = 증거 심볼 + "Reread Letter" 버튼 | 여러 미션 위젯 | **InkGlyph 자체는 바꾸지 않는다.** 이미지는 `GameSymbol`/증거 경로에만 넣음 |
| `seal` 글리프 = 증거 심볼 + 아카이브 도장 + "준비 중" 토스트 | 위와 같음 | 위와 같음 |
| `'✓'` 텍스트 ↔ `check` 글리프 | clockwork_garden, studio_match | 글리프로 통일 |
| `footprint` = 발자국 + 가루·털·진술·페인트 | 생성 데이터 | 생성기 아이콘 어휘 확장 (9절) |

### 8.2 이미 있는데 증거에 연결 안 된 그림

| 파일 | 현재 사용처 | 연결할 증거 |
|---|---|---|
| `season_01_london/objects/blue_cloth.png` (1254², 투명) | 런던 Case 03 탐색 장면 | ep03_e2 Blue Cloth |
| `season_01_london/objects/wet_footprint.png` (1024×1536, **검은 배경**) | 런던 Case 03 탐색 장면 | ep03_e3 Wet Footprint — 원형 프레임엔 어두운 원이 됨. 투명 컷아웃 버전 권장 |
| `season_01_london/objects/brass_gear.png` (512², 까마귀 각인) | 런던 Case 02 탐색 장면 | ep02_e2, ep12_e1 |
| `shared/objects/map.png` | 이야기 사물 | ep07_e3, ep07_e4 (그림 내용 일치 확인 필요) |
| `season_02_paris/cases/case_02/canvas_back.png` | `Artwork.paintersMessage` | s2_ep02_e4 |
| `season_02_paris/cases/case_03/tower_notice_board.png` | `Artwork.towerEntrance` | s2_ep03_e1 |
| `season_02_paris/cases/case_03/lift_log.png` | Case 03 퍼즐 | s2_ep03_e2 |
| `season_03_rome/objects/owl_card.png` | s3_ep01_e3 | 부엉이 카드 7건 |
| `season_03_rome/objects/city_plan.png` | s3_ep09_e4 | s3_ep09_e2 (같은 사건 — 구분 필요 시 신규) |
| `season_04_newyork/objects/star_sole.png` | s4_ep07_e1 | s4_ep02_e1 Star Print (앞 사건에서 밑창 노출 괜찮은지 확인) |
| `season_04_newyork/objects/brass_bird.png` | s4_ep04_e2 | s4_ep11_e2 Brass Bird, Found |
| `season_01_london/objects/small_wooden_box.png` | 런던 탐색 장면 | (증거 아님 — 참고) |

### 8.3 재사용하면 안 되는 것

- `season_01_london/objects/jewel_case.png`: 티아라가 든 붉은 상자. ep08_e4 "Empty Jewel Box"와 내용 불일치 (`art_assets.dart` 주석에서도 의도적으로 제외).
- `season_01_london/symbols/raven_mark.png`: 컬러 문장이라 틴트 심볼로 쓰면 안 됨 (테스트로 금지됨).
- `shared/objects/locked_door.png`: 시즌 오프닝 분위기 컷 전용.

---

## 9. 공통 아이콘 매핑 구조 개선안

현재 구조는 이미 "그림 파일이 있으면 그림, 없으면 글리프"로 설계되어 있어 **구조를 갈아엎을 필요는 없다.** 다음 네 가지만 보강하면 된다.

1. **증거 그림 해석을 한 곳으로**
   지금은 `_EvidenceArt`가 (그린 문서 → 사진 → 심볼) 순으로 판단하고, 증거 보드·Street Book은 이 경로를 우회한다. 증거를 보여 주는 모든 곳이 `EvidenceThumb`/`_EvidenceArt`를 거치게 하면 그림 등록 한 번으로 끝난다.

2. **공용 문서 템플릿 레지스트리 추가**
   `evidencePictures`(증거 ID → 파일) 외에 "증거 종류 → 템플릿" 단계를 하나 둔다. 예:
   ```
   증거 ID별 그림 (evidencePictures)          ← 고유 사물
     → 증거 종류별 템플릿 (evidenceDocs: kind → doc_*.png, inscription을 코드로 얹음)
       → 심볼 스탬프 (ArtAssets.symbols)       ← 최후 대체
         → 잉크 글리프
   ```
   증거 데이터에 `'kind': 'note' | 'card' | 'log' …`를 추가하거나, 생성기에서 `icon`과 별개로 `docKind`를 내보낸다. 파리의 `PictureEvidence`/`EasyEvidence` 렌더러를 그대로 재사용할 수 있다.

3. **아이콘 키 어휘 확장 (시즌 팩토리)**
   `puzzle_palette.dart`·생성기가 허용하는 24개 키에 최소한 `note`, `card`, `log`, `diary`, `photo`, `statement`, `dust`, `box`, `music`, `sign`을 추가해 의미 오용을 막는다. 기존 키는 그대로 두어 호환을 유지한다 (`GameSymbol.of`가 모르는 키는 `?` 모노그램으로 떨어지므로, 새 키는 반드시 심볼 표에 동시 등록).

4. **심볼 스탬프는 `ArtAssets.symbols`로만**
   InkGlyph 페인터는 UI 아이콘 언어로 유지하고, 사물 그림은 `GameSymbol`·증거 경로에서만 바꾼다. 그래야 "Reread Letter" 버튼의 편지 선화와 증거 편지 그림이 서로 영향을 주지 않는다.

---

## 10. 권장 에셋 폴더 구조

기존 규칙(`assets/seasons/season_0N_<city>/objects/`, `assets/shared/objects/`)을 그대로 따른다.

```
assets/
├─ shared/
│  ├─ evidence_docs/          # 신규: 4개 시즌 공용 문서 템플릿 (글자 없음, 컬러, 투명)
│  │  ├─ doc_note.png  doc_card.png  doc_log.png  doc_letter.png  doc_mappiece.png
│  │  ├─ doc_tag.png   doc_diary.png doc_ticket.png doc_notice.png doc_music.png
│  │  └─ doc_statement.png
│  ├─ symbols/                # 신규(선택): 단색 실루엣 스탬프, 틴트용
│  │  └─ symbol_<key>.png     # letter, ticket, map, seal, feather, frame, key, clock,
│  │                          # watch, footprint, gear, gem, mask, button, cloth,
│  │                          # whistle, raven, bag, umbrella, crown, train, museum,
│  │                          # park, mystery
│  ├─ ui/                     # 신규(선택): coin.png, star_filled.png, star_empty.png …
│  ├─ objects/  badges/  world_map/  …   # 기존
└─ seasons/
   ├─ season_01_london/objects/   # 개별 증거 11장 추가 (+ wet_footprint 컷아웃 1)
   ├─ season_02_paris/objects/    # 신규 폴더: clockmaker_mark_gear_m.png
   │  └─ (symbols/clockmaker_mark.png)
   ├─ season_03_rome/objects/     # 개별 증거 7장 추가
   └─ season_04_newyork/objects/  # 개별 증거 11장 추가
```

- 새 폴더는 `pubspec.yaml`의 `assets:`에 등록해야 한다(폴더 단위).
- 로마·뉴욕 그림은 `content_pipeline/seasons/s?_*/assets.manifest.json`에 `outputPath`로 등록 → 생성기로 `*_art.g.dart` 재생성.

---

## 11. 교체 우선순위

| 순위 | 작업 | 신규 이미지 | 코드 변경 | 효과 |
|:-:|---|---:|---|---|
| **P0** | 기존 그림 19건을 증거에 연결 (런던 6, 파리 3, 로마 8, 뉴욕 2) | 0 | `art_assets.dart` 줄 추가 + 로마·뉴욕 매니페스트 | Blue Cloth·Wet Footprint·Brass Gear 즉시 해결 |
| **P0** | 증거 보드·Street Book 배지를 `EvidenceThumb`로 | 0 | 2곳 | 사진 있는 증거가 선택지에서도 그림으로 |
| **P1** | 핵심 사물 개별 이미지 30장 (도난품·스토리 상징 우선: Blue Star, White Mask, Silver Whistle, Poppy's Ring, Clockmaker's Mark, Stone Nest, Raven Feather) | 30 | 등록만 | 사건의 기억에 남는 물건이 제 모습을 가짐 |
| **P2** | 공용 문서 템플릿 10 + 진술 1, 문장 얹기 렌더러 연결 | 11 | 템플릿 레지스트리 + 렌더러 재사용 | 문서 70건 해결, 영어 문장이 증거 위에 보임 |
| **P3** | 단서·자물쇠 심볼 스탬프 23장 | 23 | 0 (`ArtAssets.symbols`) | 단서 카드 146건·자물쇠 7건 동시 개선 |
| **P3** | 생성기 아이콘 어휘 확장 | 0 | 생성기·팔레트 | 향후 시즌의 의미 오용 방지 |
| **P4** | B 그룹(코인, 별, 메뉴 등) | 3–10 | 위젯별 소규모 | 보상감·메뉴 분위기 |

---

## 12. 예상 작업량과 영향 범위

| 단계 | 이미지 | 코드 파일 | 영향 시즌 | 회귀 위험 |
|---|---:|---|---|---|
| P0 | 0 | `lib/widgets/art_assets.dart`, `lib/features/mission/widgets/evidence_board.dart`, `street_book.dart`, 로마·뉴욕 `assets.manifest.json` → 재생성 | 4 | 낮음. `test/art_assets_test.dart`, `generated_seasons_test.dart`, `rome_integration_test.dart`, `paris_case01_test.dart`에 증거 그림 목록 검증이 있어 기대값 갱신 필요 가능 |
| P1 | 30 | 등록만 | 4 | 낮음. 원형 프레임 크롭 품질은 실기기 확인 필요 |
| P2 | 11 | 렌더러 연결, 증거 데이터에 문서 종류 추가(또는 매핑 표) | 런던·로마·뉴욕 | 중간. 데이터 스키마·생성기 변경 |
| P3 | 23 | 0 (심볼) / 생성기 | 4 | 낮음. `art_assets_test.dart:296-363`이 `ArtAssets.symbols` 파일 존재·틴트 규칙을 검사 |
| P4 | 3–10 | 위젯별 | 4 | 낮음 |
| **합계** | **약 64–74장** (증거 41 + 심볼 23 + UI 0–10) | | | |

최소 권장안(P0+P1+P2): **신규 41장**으로 선 아이콘 증거 119건 전부 해소.

### 그림 제작 원칙 (8–12세, 영어 추리 게임)

- 기존 빈티지 수채·잉크 일러스트 스타일 (`blue_cloth.png`, `brass_gear.png`, 로마·뉴욕 `objects/` 계열)과 맞춘다.
- 사물 하나, 단순한 실루엣, 과한 광택·장식 금지. 48px 썸네일에서도 무엇인지 알아볼 것.
- **증거의 `inscription`(영어 문장)이 단서인 경우 그림에 그 정보를 그리지 않는다.** 예: Luggage Tag에 "KING'S CROSS"를 그려 넣지 않고 코드로 얹음.
- 그림이 이름 이상의 추리 정보를 주지 않게 (선택지로 쓰이는 퍼즐: 증거 보드, Street Book, 증거 회상, 사건 대화).
- 4개 시즌 공용 템플릿에는 도시 상징을 넣지 않는다.

---

## 부록 A. 조사에 쓴 핵심 경로

- 아이콘 시스템: [lib/widgets/ink_icon.dart](../lib/widgets/ink_icon.dart), [lib/widgets/symbol_icon.dart](../lib/widgets/symbol_icon.dart)
- 그림 레지스트리: [lib/widgets/art_assets.dart](../lib/widgets/art_assets.dart), `lib/data/generated/generated_season_art.g.dart`
- 증거 표시: [lib/widgets/evidence_card.dart](../lib/widgets/evidence_card.dart)
- 단서 카드: [lib/widgets/clue_card.dart](../lib/widgets/clue_card.dart)
- 배지: [lib/widgets/badge_medal.dart](../lib/widgets/badge_medal.dart), [lib/features/game/scoring.dart](../lib/features/game/scoring.dart)
- 증거 데이터: `lib/data/mock/season1/episode*_mock.dart`, `lib/data/mock/season2/episode*_mock.dart`, `lib/data/generated/s3_rome/s3_ep*.g.dart`, `lib/data/generated/s4_newyork/s4_ep*.g.dart`
- 생성 시즌 원본: `content_pipeline/seasons/s3_rome/`, `content_pipeline/seasons/s4_newyork/`
