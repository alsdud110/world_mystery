# 서울 시즌 Case별 Mission Map 계획 (PART 0)

작성일: 2026-11-06 · 기준 커밋: `58c75d5` · 상태: PART 0~3 완료. 결과와 인계는 §11~§13.

## 0. 결론

- **지도 12장 중 1장은 재사용(`palace_map.webp` → Case 01), 11장은 신규 제작한다.**
- `season_map.webp`는 Case 지도로 쓰지 않고, 시즌 보드와 인트로 등 시즌 전체 화면에 그대로 둔다.
- 구현은 `SeasonMap`에 선택 필드 2개(`caseMaps`, `missionPoints`)를 추가하고, 지도 화면에서 지도를 고르는 곳을 한 줄 바꾸는 방식이다. Case 지도가 없으면 지금 지도로 돌아가므로 London, Paris, Rome, New York의 동작은 바뀌지 않는다.
- 원본은 `season.plan.json`의 `art.caseMaps`다. `s5_seoul_art.g.dart`는 직접 고치지 않고 생성기로 만든다.
- 조사에서 나온 설계 변경 사항은 세 가지다.
  1. **"장소 4곳"은 8개 Case에서 성립하지 않는다.** 미션은 48개지만 Case별 고유 장소는 2~4곳, 합계 33곳이다. 스토리를 바꿀 수 없으므로 없는 장소를 만들지 않고, 실제 장소만 그린 뒤 같은 장소의 미션은 그 안의 서로 다른 지점에 놓는다. (§2)
  2. **핀 겹침이 이미 있다.** `mapX/mapY`가 같은 미션이 있어서 기존 그룹 배치로는 핀이 포개진다. 미션별 좌표(`missionPoints`)가 필요하다. (§5.3)
  3. **장소 이름이 답을 미리 알려줄 수 있다.** 지금은 잠긴 미션의 핀만 숨기고 랜드마크 이름은 모두 표시한다. Case 지도에 그대로 적용하면 Case 01 첫 미션의 답인 THE WELL YARD가 시작부터 보인다. Case 지도에서는 핀이 열린 장소의 이름만 표시한다. (§5.4)

## 1. 기존 지도 에셋

| 파일 | 크기 | 실제 내용 | 현재 사용처 | 판단 |
|---|---|---|---|---|
| `locations/map/season_map.webp` | 1536×1024, 616,188 B | 밝은 양피지풍 그림지도. 한반도, 중국 해안, 9개 지역 비네트, 나침반 | 서울 시즌 `SeasonMap` 전체. Mission Map, 시즌 보드(`MapPrint.ofSeason`), 인트로·장면 폴백 | 시즌 전체 지도로 유지. Case 지도로는 부적합(지역당 작은 비네트 1개, Case 내부 장소 표현 불가) |
| `locations/map/palace_map.webp` | 1536×1024, 579,298 B | 궁궐 조감도 야경. 남쪽 대문과 전정, 중앙 중문, 북쪽 정전, 서쪽 긴 전각, 동쪽 전각, 북동 소전각, 연못. 글자와 마커 없음 | 코드 미사용(manifest `use: notWired`). 시즌팩과 R2에는 포함 | **Case 01에 재사용** |

- 그 밖의 지도 파일은 작업본인 `content_pipeline/asset_work/s5_seoul/`의 원본과 검토 그리드뿐이다.
- 31개 장소 이미지는 눈높이 장면이라 지도로 쓸 수 없다.
- `palace_map`의 한계:
  - 전체 이미지 육안 확인으로는 우물이 보이지 않는다. 다만 `well_yard.webp` 장면은 담 너머 서쪽으로 정전이 보여서, 동쪽 전각 앞마당과 방향이 맞는다.
  - 생성 프롬프트는 3곳 기준이었다(게이트, 동쪽 전각, 서쪽 전각). 4곳으로 쓰려면 Writing Room을 북동 소전각으로 분리해야 한다.
  - 이 지도만 야경이고 나머지 11장은 밝은 지도풍이 된다. `MapLettering`에 종이색 외곽선이 있어 글자는 읽을 수 있을 것으로 보지만, 빨간 경로선과 핀의 대비는 PART 1에서 실제 화면으로 확인한다.
- Case 04·05도 같은 경복궁이지만 재사용하지 않는다. 1446년 궁궐에는 1866년 공사장과 목재소, 1895년 건청궁과 전등소가 없고, Case마다 독립 지도라는 기준에도 맞지 않는다.

## 2. Case별 지도 계획과 48개 미션

공통: 고유 장소는 미션의 `play.location` 기준이다. 실내 장소는 그 건물의 외관으로 그린다.

| Case | 시대 / 지역 | 고유 장소 | 현재 지도 | 적합 | 계획 |
|---|---|---|---|---|---|
| 01 The Secret of the King's Letters | 1446 궁궐, 한양 | 4 | season_map | 부적합 | **재사용** `palace_map.webp` |
| 02 The Turtle Ship Before Dawn | 1592 여수 수군기지 | 2 | season_map | 부적합 | 신규 `case_02_map.webp` |
| 03 The Crane That Lifts Stones | 1795 화성, 수원 | 3 | season_map | 부적합 | 신규 `case_03_map.webp` |
| 04 The Palace of a Thousand Logs | 1866 경복궁 중건 | 3 | season_map | 부적합 | 신규 `case_04_map.webp` |
| 05 The Lights of Geoncheonggung | 1895 건청궁 | 3 | season_map | 부적합 | 신규 `case_05_map.webp` |
| 06 The Emperor's Secret Letter | 1907 경운궁 일대 | 3 | season_map | 부적합 | 신규 `case_06_map.webp` |
| 07 Two Reports from Harbin | 1909 하얼빈 | 2 | season_map | 부적합 | 신규 `case_07_map.webp` |
| 08 The Fire on the Hill | 1919 아우내, 천안 부근 | 3 | season_map | 부적합 | 신규 `case_08_map.webp` |
| 09 The Spy in the Shanghai Office | 1920 상하이 | 2 | season_map | 부적합 | 신규 `case_09_map.webp` |
| 10 The Two Watches | 1932 상하이 | 2 | season_map | 부적합 | 신규 `case_10_map.webp` |
| 11 The Poet's Three Copies | 1941 연희전문, 서울 | 3 | season_map | 부적합 | 신규 `case_11_map.webp` |
| 12 The Day the Light Returned | 1945 충칭 | 3 | season_map | 부적합 | 신규 `case_12_map.webp` |

신규 파일 경로는 모두 `assets/seasons/season_05_seoul/locations/map/` 아래다.

### 미션과 장소

| Case | 미션 ID | 장소(`play.location`) | placeId | 지도 위 지점 |
|---|---|---|---|---|
| 01 | `s5_ep01_m1` | THE INNER GATE | inner_gate | 남쪽 문루 |
| 01 | `s5_ep01_m2` | THE WELL YARD | well_yard | 동쪽 전각 앞마당 |
| 01 | `s5_ep01_m3` | THE WRITING ROOM | writing_room | 북동 소전각 |
| 01 | `s5_ep01_final` | THE BOOK HALL | book_hall | 서쪽 긴 전각 |
| 02 | `s5_ep02_m1` | THE STORE ROOM | c02_store_room | 창고 입구 |
| 02 | `s5_ep02_m2` | THE STORE ROOM | c02_store_room | 창고 안쪽 끝 |
| 02 | `s5_ep02_m3` | THE TURTLE SHIP | c02_turtle_ship | 거북선 선미 |
| 02 | `s5_ep02_final` | THE TURTLE SHIP | c02_turtle_ship | 거북선 선수 |
| 03 | `s5_ep03_m1` | THE STONE YARD | c03_stone_yard | 거중기 옆 |
| 03 | `s5_ep03_m2` | THE DRAWING ROOM | c03_drawing_room | 공사 사무소 |
| 03 | `s5_ep03_m3` | THE STONE YARD | c03_stone_yard | 석재 더미 옆 |
| 03 | `s5_ep03_final` | THE NEW WALL | c03_stone_yard | 새 성벽 |
| 04 | `s5_ep04_m1` | THE TIMBER YARD | c04_timber_yard | 목재 더미 |
| 04 | `s5_ep04_m2` | THE YARD OFFICE | c04_timber_yard | 목재소 사무소 |
| 04 | `s5_ep04_m3` | THE PALACE SITE | c04_palace_site | 공사장 앞쪽 |
| 04 | `s5_ep04_final` | THE PALACE SITE | c04_palace_site | 공사장 안쪽 |
| 05 | `s5_ep05_m1` | THE LAMP HOUSE | lamp_house | 연못 남쪽 전등소 |
| 05 | `s5_ep05_m2` | THE QUEEN'S COURT | queen_court | 왕비 처소 마당 입구 |
| 05 | `s5_ep05_m3` | THE QUEEN'S COURT | queen_court | 왕비 처소 마당 안쪽 |
| 05 | `s5_ep05_final` | JANGANDANG, THE KING'S HALL | king_hall | 장안당 |
| 06 | `s5_ep06_m1` | THE PALACE GARDEN | c06_palace_garden | 정원 나무 쪽 |
| 06 | `s5_ep06_m2` | THE PALACE GARDEN | c06_palace_garden | 정원 담장 쪽 |
| 06 | `s5_ep06_m3` | THE WEST LANE | c06_west_lane | 서쪽 돌담길 |
| 06 | `s5_ep06_final` | YI JUN'S HOUSE | yi_jun_house | 이준의 집 |
| 07 | `s5_ep07_m1` | MRS. KANG'S INN | kang_inn | 여관 입구 |
| 07 | `s5_ep07_m2` | THE STATION TEA ROOM | harbin_tea_room | 역 찻집 |
| 07 | `s5_ep07_m3` | MRS. KANG'S INN | kang_inn | 여관 안채 |
| 07 | `s5_ep07_final` | MRS. KANG'S INN | kang_inn | 여관 뒷마당 쪽 |
| 08 | `s5_ep08_m1` | AUNAE MARKET | aunae_market | 장터 |
| 08 | `s5_ep08_m2` | GWAN-SUN'S HOME | gwansun_home | 집 마당 |
| 08 | `s5_ep08_m3` | GWAN-SUN'S HOME | gwansun_home | 집 마루 쪽 |
| 08 | `s5_ep08_final` | MAEBONG HILL | maebong_hill | 매봉 정상 |
| 09 | `s5_ep09_m1` | A LANE IN SHANGHAI | shanghai_lane | 골목 |
| 09 | `s5_ep09_m2` | THE GOVERNMENT OFFICE | shanghai_office | 청사 왼쪽 |
| 09 | `s5_ep09_m3` | THE GOVERNMENT OFFICE | shanghai_office | 청사 가운데 |
| 09 | `s5_ep09_final` | THE GOVERNMENT OFFICE | shanghai_office | 청사 오른쪽 |
| 10 | `s5_ep10_m1` | A SMALL HOUSE IN SHANGHAI | breakfast_room | 집 왼쪽 |
| 10 | `s5_ep10_m2` | A SMALL HOUSE IN SHANGHAI | breakfast_room | 집 가운데 |
| 10 | `s5_ep10_m3` | A SMALL HOUSE IN SHANGHAI | breakfast_room | 집 오른쪽 |
| 10 | `s5_ep10_final` | HAESU'S ROOM | haesu_room | 해수의 방이 있는 건물 |
| 11 | `s5_ep11_m1` | YUN'S ROOM | c11_dorm_room | 기숙사 동쪽 |
| 11 | `s5_ep11_m2` | YUN'S ROOM | c11_dorm_room | 기숙사 서쪽 |
| 11 | `s5_ep11_m3` | THE COLLEGE HALL | c11_college_hall | 대강당 |
| 11 | `s5_ep11_final` | THE COLLEGE GATE | c11_college_gate | 교문 |
| 12 | `s5_ep12_m1` | THE GOVERNMENT OFFICE | c12_office | 청사 왼쪽 |
| 12 | `s5_ep12_m2` | BITNA'S ROOM | c12_family_room | 빛나의 집 |
| 12 | `s5_ep12_m3` | THE GOVERNMENT OFFICE | c12_office | 청사 오른쪽 |
| 12 | `s5_ep12_final` | THE RIVER STEPS | c12_river_steps | 강변 돌계단 |

"지도 위 지점"은 제작 의도다. 최종 좌표는 PART 3에서 완성된 이미지를 보고 측정한다. 지도에 표시하는 이름은 위 장소명이고, 지점의 설명은 화면에 나오지 않으므로 스토리는 바뀌지 않는다.

### Case 01 좌표 후보 (`palace_map.webp`, 1536×1024)

| 장소 | 픽셀 | 정규화 | 근거 |
|---|---|---|---|
| THE INNER GATE | (768, 760) | (0.500, 0.742) | 남쪽 문루. 파일럿 좌표 (0.5, 0.7)과 같은 건물 |
| THE WELL YARD | (1310, 425) | (0.853, 0.415) | 동쪽 전각 앞마당. 장면 속 정전 방향과 일치 |
| THE WRITING ROOM | (1280, 205) | (0.833, 0.200) | 북동 소전각. Well Yard와 분리 |
| THE BOOK HALL | (265, 365) | (0.173, 0.356) | 서쪽 긴 전각. 파일럿 좌표 (0.17, 0.35)과 일치 |

PART 1에서 실제 화면으로 확인해 위 값을 미션 지점으로 확정했다. 이름 기준점(`at`)은 §11 참조.

## 3. 재사용 판단과 신규 제작 목록

- 재사용: `palace_map.webp` 1장
- 유지(Case 지도 아님): `season_map.webp`
- 신규 11장: 아래 표. 모두 1536×1024, 글자·마커·핀·번호 없음, `stylePreset: seoul_map`

| 지도 | 구도 (장소를 서로 떨어뜨려 배치) | 주의 |
|---|---|---|
| case_02 | 왼쪽 아래 부두 창고, 오른쪽 부두에 거북선. 새벽 항구 | 1592년, 전투 장면 없음 |
| case_03 | 가운데 석재 마당과 거중기, 왼쪽 위 공사 사무소, 오른쪽 위 건설 중인 성벽 | 1795년, 완성되지 않은 성벽 |
| case_04 | 왼쪽 아래 목재소와 작은 사무소, 오른쪽 위 반쯤 지은 전각 | 1866년 겨울, 공사 중 |
| case_05 | 아래 연못과 남쪽 전등소, 왼쪽 위 왕비 처소, 오른쪽 위 장안당 | 1895년, 인물을 그리지 않음 |
| case_06 | 오른쪽 궁궐 정원, 가운데 돌담길, 왼쪽 궁 밖 이준의 집 | 1907년, 한옥과 서양식 건물 혼재 |
| case_07 | 왼쪽 아래 여관이 있는 거리, 오른쪽 위 역과 찻집 | 1909년, 사건 장면과 인물 없음 |
| case_08 | 아래 장터, 오른쪽 가운데 마을 집, 위쪽 매봉과 봉화 | 정상 지점이 상단 여백 아래에 오도록 산을 낮게 배치 |
| case_09 | 왼쪽 아래 골목, 오른쪽 위 작은 청사 건물 | 1920년, 건물이 작아도 지점 3곳이 구분되는 폭 |
| case_10 | 왼쪽 작은 집, 오른쪽 해수의 방이 있는 건물 | 1932년, 공원이나 사건 장소는 그리지 않음 |
| case_11 | 왼쪽 위 기숙사, 오른쪽 위 대강당, 아래 교문 | 1941년, 석조 교사 |
| case_12 | 왼쪽 위 청사, 오른쪽 가운데 집, 오른쪽 아래 두 강과 돌계단 | 1945년 |

`seoul_map` 프리셋에는 시대 지시가 없으므로, 프롬프트마다 시대와 "현대 물건 없음"을 명시한다. 실존 인물은 그리지 않는다. Case 05의 왕비 표현 제한과 Case 07·10의 사건 비묘사 원칙도 지도에 그대로 적용된다.

비용과 예산:

- gpt-image-2 `medium` 가로 이미지는 출력 1,568토큰(추정) × $30/M으로 **장당 약 $0.05**다. 11장에 재생성을 더해도 $1 안팎으로 예상한다. 정확한 값은 factory의 dry run으로 확인한다.
- `s5_seoul` 예산은 $12.00이고 사용액은 $4.37이다.
- 이 예산은 "시즌 전체 제작"으로 승인되었다. **지도 11장을 이 예산으로 만들어도 되는지 PART 2 시작 전에 확인한다.**

## 4. 현재 구조

```
season.plan.json (art.map) + cases/*/case.plan.json + assets.manifest.json
   └─ tool/season_gen/generate_case.dart --target game  (_artFile)
        └─ lib/data/generated/s5_seoul/s5_seoul_art.g.dart  (s5SeoulMap)
             └─ generated_season_art.g.dart (generatedSeasonMaps)
                  └─ SeasonMap.bySeason → seasonMapsProvider
                       └─ mission_map_screen.dart (Case의 시즌 지도 → MapWorld.places)
```

`SeasonMap`의 시즌 단위 사용처 (변경하지 않음):

- `MapPrint.ofSeason`: 시즌 보드 배경
- `story_intro_screen.dart`: 인트로 폴백
- `story_scene_screen.dart`, `answer_feedback.dart`: `SeasonMap.ofMission` 폴백
- `place_art.dart`: `SeasonMap.landmarkOf`
- `dev_session.dart`: `season5Map` 오버라이드 (`s5SeoulMap`을 가리키므로 `caseMaps`도 함께 전달됨)

Case 지도로 바꿀 곳은 `mission_map_screen.dart:268-270`, `:340-348` 한 군데다.

## 5. 데이터 구조 설계

### 5.1 계획 데이터 (`season.plan.json`, 선택 항목)

```json
"art": {
  "map": { "...": "기존 그대로" },
  "caseMaps": {
    "s5_ep01": {
      "file": "assets/seasons/season_05_seoul/locations/map/palace_map.webp",
      "pixels": { "width": 1536, "height": 1024 },
      "measuredOn": "sha256:<측정한 파일의 해시>",
      "landmarks": [
        {
          "spotId": "inner_gate",
          "name": "The Inner Gate",
          "at": [768, 760],
          "missions": { "s5_ep01_m1": [768, 760] }
        }
      ]
    }
  }
}
```

- 좌표는 기존 `art.map`과 같이 원본 픽셀로 적고, 생성기가 `x / width` 형태의 분수로 쓴다.
- `caseMaps`가 없는 시즌 계획은 그대로 유효하다.
- 같은 파일을 여러 Case가 지정할 수 있으므로 지도 공유도 지원된다.

### 5.2 Dart (`map_world.dart`)

```dart
class SeasonMap {
  const SeasonMap({
    ...,
    this.caseMaps = const {},
    this.missionPoints = const {},
  });

  /// 자기 지도가 있는 Case의 지도. 없는 Case는 시즌 지도를 쓴다.
  final Map<String, SeasonMap> caseMaps;

  /// 미션별 정확한 지점(지도 비율). 있으면 그룹 배치를 쓰지 않는다.
  final Map<String, Offset> missionPoints;

  SeasonMap forCase(String episodeId) => caseMaps[episodeId] ?? this;
}
```

생성 결과는 `s5SeoulMap`에 `caseMaps: {'s5_ep01': _s5Ep01Map, ...}`가 추가된 형태다. Case 지도의 `landmarks`, `missionLandmarks`, `missionPoints`는 Case 범위의 상수이고, `namesClearOfCurrent: true`를 그대로 쓴다. 최상위 `s5SeoulMap`의 기존 값은 그대로 두므로 시즌 단위 사용처와 기존 테스트는 영향이 없다.

### 5.3 좌표 처리 (`MapWorld.places`)

`raw` 계산에 `map.missionPoints[m.id] ?? <기존 계산>` 한 단계를 추가한다.

기존 `_inGroup`은 같은 랜드마크의 미션을 `mapX/mapY` 모양대로 펼치지만, 좌표가 같으면 `reach == 0`이 되거나 같은 점에 겹친다. 해당 미션은 다음과 같다.

- Case 08: m2, m3
- Case 09: m2, m3, final
- Case 10: m1, m2, m3
- Case 11: m1, m2
- Case 12: m1, m3

`mapX/mapY`는 다른 생성물에도 쓰이므로 건드리지 않고 `missionPoints`로 해결한다.

### 5.4 이름 스포일러 방지 (`_MapWorldView`)

Case 지도(`missionPoints`가 있는 지도)에서는 열린 핀이 있는 랜드마크의 이름만 표시한다. 기존 지도는 지금처럼 전부 표시한다. 그림 자체에는 이름이 없으므로, 이름이 없으면 어떤 건물이 답인지 드러나지 않는다.

### 5.5 생성기 검사 (`plan_check.dart`, `generate_case.dart`)

- `caseId`가 시즌의 Case인지, 파일이 디스크에 있는지, `measuredOn`이 파일 해시와 같은지(`map_remeasure`와 동일) 확인
- Case의 모든 미션이 정확히 한 번 나오는지 확인
- 좌표 안전 영역: x 8~92%, y는 `MapWorld.topMargin`(15%) 이상 92% 이하
- 랜드마크 `name`이 그 미션들의 `play.location`과 대소문자 무시로 일치하는지 확인 (`JANGANDANG, THE KING'S HALL`처럼 긴 이름도 전체 일치)
- 같은 지도 안의 미션 지점끼리 최소 거리 유지 (초기값은 이미지 폭의 6%, PART 3 화면 확인 후 조정)

## 6. 수정 대상 파일

| 구분 | 파일 | PART |
|---|---|---|
| 계획 데이터 | `content_pipeline/seasons/s5_seoul/season.plan.json` | 1, 3 |
| 계획 데이터 | `content_pipeline/seasons/s5_seoul/assets.manifest.json` | 2 |
| 생성기 | `tool/season_gen/plan_models.dart` (`CaseMapPlan`, `SeasonArtPlan`) | 1 |
| 생성기 | `tool/season_gen/schema/season_plan.schema.json` | 1 |
| 생성기 | `tool/season_gen/plan_check.dart` | 1 |
| 생성기 | `tool/season_gen/generate_case.dart` (`_artFile`, 게임 게이트) | 1 |
| 앱 | `lib/features/mission_map/map_world.dart` | 1 |
| 앱 | `lib/features/mission_map/mission_map_screen.dart` | 1 |
| 생성 결과 | `lib/data/generated/s5_seoul/*.g.dart` (생성기로만 변경) | 1, 3 |
| 팩 | `lib/core/assets/season_pack_manifests.g.dart` (`build_manifest.dart`로만 변경) | 4 |
| 이미지 | `assets/seasons/season_05_seoul/locations/map/case_02~12_map.webp` | 2 |
| 테스트 | `test/seoul_case_maps_test.dart` (신규), 필요 시 `test/season_factory/*` | 1, 3 |

`SeasonMap`을 쓰는 다른 파일, 스토리·대사·퍼즐 데이터, London·Paris 지도 정의, Rome·New York 계획 파일은 변경 대상이 아니다.

## 7. PART별 작업 범위

### PART 1 — 구조와 Case 01

- §5의 계획 모델, 스키마, 검사, 생성기, `SeasonMap`, `MapWorld`, 지도 화면 변경
- Case 01만 `art.caseMaps`에 등록해서 `palace_map.webp` 적용
- 나머지 11개 Case는 `forCase` 폴백으로 `season_map`을 유지하므로 중간 상태에서도 게임이 정상 동작
- 완료 조건: Case 01 지도가 실제 화면에서 정상 표시, 야경 위 핀·경로·글자 대비 확인, Rome·New York 생성 결과 차이 없음

### PART 2 — 지도 11장 제작

- 시작 전 예산 사용 승인 확인
- `assets.manifest.json`에 `case_02~12` 항목 추가 (`type: map`, `stylePreset: seoul_map`, `caseIds` 지정)
- dry run으로 만들 파일과 비용을 먼저 확인. **manifest에 `status: planned`인 항목 4개(`kings_study`, `ham`, `gwak`, `pyo`)가 있으므로 이들이 함께 생성되지 않게 한다.**
- 생성 후 12장을 나란히 검토. 글자가 들어갔거나, 장소가 구분되지 않거나, 시대에 맞지 않는 이미지는 다시 만든다.

### PART 3 — 좌표와 전체 연결

- 완성된 파일에서 장소와 미션 지점을 측정해 `art.caseMaps`에 기록 (`measuredOn` 포함)
- 생성기를 다시 돌려 12개 Case 연결
- 작은 화면과 큰 화면에서 12개 Case 지도 확인: `YOU'RE HERE`, 완료 표시, 다음 미션, 이름 겹침, 지도 가장자리

### PART 4 — 팩과 회귀

- `build_manifest.dart`로 매니페스트 갱신, 팩 검사와 R2 비교(읽기 전용), 스테이징
- `flutter analyze`, 관련 테스트, 시즌 단위 변경이므로 전체 `flutter test` 1회
- **R2 업로드는 별도 승인 후 진행.** 업로드는 앱 배포보다 먼저 끝나야 한다.

## 8. 위험 요소와 검증

| 위험 | 영향 | 대응 / 검증 |
|---|---|---|
| 다른 시즌 동작 변경 | 높음 | 필드 기본값이 빈 맵이고 `forCase`가 `this`를 반환. Rome·New York `.g.dart`의 생성 전후 diff가 0인지 확인. `paris_map_test`, `map_camera_test`, `multi_season_test` 실행 |
| 계획 해시 변경으로 생성 파일 연쇄 변경 | 중간 | `season.plan.json`이 바뀌면 서울 생성 파일 헤더의 해시가 바뀔 수 있음. 내용 차이가 해시뿐인지 diff로 확인. `season.levels.json`과 `change_impact.dart`의 해시 연동도 PART 1에서 확인 |
| 이름 스포일러 | 중간 | §5.4. 잠긴 장소 이름이 표시되지 않는지 위젯 테스트 |
| 핀 겹침 | 중간 | `missionPoints` 및 최소 거리 검사, 48개 지점 전수 테스트 |
| 생성 이미지에 글자 포함 또는 구도 불일치 | 중간 | 프롬프트 금지 문구, 검토 후 재생성 |
| 야경 `palace_map`과 다른 지도의 톤 차이 | 낮음~중간 | 재사용 기준에 따라 유지. 화면에서 어색하면 Case 01 지도 신규 제작을 사용자에게 제안 |
| `planned` 자산 동시 생성 | 중간 | dry run 결과 확인 전에는 실제 생성 금지 |
| 기존 설치자 재다운로드 | 낮음 | 파일 추가로 팩 버전이 바뀌면 설치 상태가 해제됨. 다만 `install`이 같은 파일을 건너뛰므로 실제 다운로드는 신규 11장(약 7MB 예상)뿐 |
| 앱이 R2보다 먼저 배포됨 | 높음 | 새 매니페스트 파일이 R2에 없으면 다운로드 실패. 업로드와 HTTPS 재확인 후 앱 배포 |
| factory 측정 검사 누락 | 낮음 | `unmeasured`는 지도 자산의 첫 항목과 `art.map`만 확인. 이번에는 생성기 게이트의 `measuredOn` 검사로 대신하고, factory 자동화는 후속 작업으로 분리 |

오프라인 동작: `measureSeasonPacks`가 `assets/seasons/` 아래 파일을 전부 포함하므로 신규 지도는 자동으로 팩에 들어간다. 설치 완료 후에는 12장 모두 기기에서 읽는다.

R2: 업로드 계획은 없는 객체만 추가하고 기존 객체와 기존 버전 매니페스트는 삭제하지 않는다. `palace_map`은 이미 올라가 있으므로 R2 재업로드는 신규 11장과 새 매니페스트만 필요하다. PART 1만 끝난 상태에서는 파일이 바뀌지 않으므로 R2 작업이 없다.

## 9. 다음 PART 실행 지침

PART 1은 다음 순서로 바로 시작한다.

1. `tool/season_gen/plan_models.dart`: `MapPlan`(687행) 근처에 `CaseMapPlan`을 추가하고 `SeasonArtPlan`의 `fromJson`, `toJson`에 `caseMaps`를 연결한다. `_Reader.done()`이 모르는 키를 거부하므로 이 작업이 먼저다.
2. `season_plan.schema.json`의 `art`에 `caseMaps`를 추가한다. `additionalProperties: false`다.
3. `plan_check.dart`: 시즌 수준 검사는 `seasonPlan`에(83행 근처), 미션 수준 검사는 `casePlan(plan, season:)`에 넣는다.
4. `generate_case.dart`: `_artFile`이 `caseMaps`가 있을 때만 출력하게 한다. 없으면 출력은 지금과 바이트 단위로 같아야 한다. 게이트(332~338행)에 Case 지도의 파일과 `measuredOn` 검사를 추가한다.
5. `map_world.dart`: §5.2, §5.3을 적용한다.
6. `mission_map_screen.dart`: 268행 다음에서 `seasonMap.forCase(episode.id)`로 지도를 고르고, 이후 코드는 그 지도를 쓴다. §5.4를 적용한다.
7. `season.plan.json`에 Case 01 항목을 넣는다(§2 좌표 후보, `palace_map` 해시 `sha256:712f1c34…`는 파일에서 다시 계산).
8. `dart run`으로 생성기를 실행하고 diff를 확인한다. Rome·New York 변경 없음, 서울은 의도한 변경과 해시뿐이어야 한다.
9. `test/seoul_case_maps_test.dart`를 추가한다.
   - Case 01은 `palace_map`, Case 02는 폴백
   - 4개 미션 지점이 서로 다르고 안전 영역 안에 있음
   - 잠긴 장소 이름 미표시
   - `forSeason`은 계속 `season_map`
   - London, Paris의 `forCase`는 자기 자신
10. `flutter analyze`와 관련 테스트(`seoul_case_maps`, `generated_seasons`, `season_presentation`, `paris_map`, `map_camera`, `multi_season`, `season_factory`)를 실행한다.

지키는 것: 스토리·대사·퍼즐·난이도 변경 금지, `.g.dart` 직접 수정 금지, 기존 이미지 수정 금지, 푸시 금지, R2 업로드는 별도 승인.

## 10. 사용자 확인이 필요한 항목

1. **고유 장소가 2~3곳인 Case 처리:** 이 계획은 없는 장소를 만들지 않고 같은 장소 안의 다른 지점에 핀을 둔다. 지도에 꼭 4곳이 보여야 한다면 스토리 데이터를 바꿔야 해서 작업 제한과 충돌한다.
2. **PART 2 비용:** 지도 11장을 기존 `s5_seoul` 예산으로 제작해도 되는지. (PART 2 시작 전까지만 답하면 된다.)
3. **Case 01 톤:** 야경 `palace_map`을 유지하는 것을 기본으로 한다. PART 1 화면 확인 뒤 다시 판단할 수 있다.

## 11. PART 1 결과와 PART 2 인계

### 구현 결과

- `SeasonMap`에 `caseMaps`, `missionPoints`, `forCase()`를 추가했고, 지도 화면은 `forCase(episode.id)`로 Case 지도를 고른다.
- Case 01은 `palace_map.webp`로 표시된다. Case 02~12는 Case 지도가 없어 `season_map.webp`를 그대로 쓴다.
- 시즌 보드, `SeasonMap.forSeason`, `ofMission`, `landmarkOf`는 계속 `season_map.webp` 기준이다.
- 원본은 `season.plan.json`의 `art.caseMaps`다. `.g.dart`는 `generate_season.dart`로만 만들었다.
- `art.caseMaps`가 없는 시즌의 생성 결과는 그대로다. Rome, New York을 다시 생성해 내용 차이가 없음을 확인했다.
- Case 지도에서는 핀이 열린 장소의 이름만 표시한다. 기존 지도는 이름을 전부 표시한다.

### Case 01 확정 좌표 (1536×1024)

| 장소 | 미션 지점 | 이름 기준점 `at` | 실제 지도 위 위치 |
|---|---|---|---|
| THE INNER GATE | (768, 760) | (768, 772) | 남쪽 문루 |
| THE WELL YARD | (1310, 425) | (1310, 437) | 동쪽 전각 앞마당 |
| THE WRITING ROOM | (1280, 205) | (1280, 217) | 북동 소전각 |
| THE BOOK HALL | (265, 365) | (265, 377) | 서쪽 긴 전각 |

**THE WELL YARD의 한계:** `palace_map.webp`에는 우물이 그려져 있지 않다. 이 좌표는 우물의 위치가 아니라 가장 자연스러운 영역이다. 근거는 `well_yard.webp` 장면의 건물, 담, 서쪽 정전 방향이 동쪽 전각 앞마당과 맞는다는 점이다. THE WRITING ROOM도 그림에 표시된 장소가 아니라, Well Yard와 구분하기 위해 고른 북동 소전각이다.

### 계획과 달라진 점

- **이름 기준점을 미션 지점보다 12px 아래로 둔다.** 같은 좌표를 쓰면 완료 표시(반지름 19px)와 이름(18px 아래)이 1px 겹쳐서, 기존 `namesClearOfCurrent` 규칙이 완료된 장소의 이름을 지운다. PART 3의 11장도 같은 규칙을 적용한다.
- `assets.manifest.json`의 `palace_map` 항목은 수정하지 않아 `use: notWired`로 남아 있다. 동작에는 영향이 없다.

### PART 2 인계

제작할 지도는 11장이다. 경로는 `assets/seasons/season_05_seoul/locations/map/case_NN_map.webp`이고, 구도와 주의 사항은 §3 표를 따른다.

| 파일 | Case | 그릴 장소 |
|---|---|---|
| `case_02_map.webp` | 1592 여수 | The Store Room, The Turtle Ship |
| `case_03_map.webp` | 1795 화성 | The Stone Yard, The Drawing Room, The New Wall |
| `case_04_map.webp` | 1866 경복궁 | The Timber Yard, The Yard Office, The Palace Site |
| `case_05_map.webp` | 1895 건청궁 | The Lamp House, The Queen's Court, Jangandang |
| `case_06_map.webp` | 1907 경운궁 | The Palace Garden, The West Lane, Yi Jun's House |
| `case_07_map.webp` | 1909 하얼빈 | Mrs. Kang's Inn, The Station Tea Room |
| `case_08_map.webp` | 1919 아우내 | Aunae Market, Gwan-sun's Home, Maebong Hill |
| `case_09_map.webp` | 1920 상하이 | A Lane in Shanghai, The Government Office |
| `case_10_map.webp` | 1932 상하이 | A Small House in Shanghai, Haesu's Room |
| `case_11_map.webp` | 1941 연희전문 | Yun's Room, The College Hall, The College Gate |
| `case_12_map.webp` | 1945 충칭 | The Government Office, Bitna's Room, The River Steps |

주의 사항:

1. 예산은 사용자가 승인했다. `s5_seoul` $12 범위 안에서 제작한다(사용액 $4.37).
2. 실제 생성 전에 dry run으로 대상을 확인한다. `planned` 상태인 `kings_study`, `ham`, `gwak`, `pyo`가 함께 생성되면 안 된다.
3. `art.caseMaps`는 파일과 `measuredOn`이 있어야 하므로 등록은 이미지 완성 후 PART 3에서 한다.
4. 장소가 2곳뿐인 Case도 미션 4개를 넣을 수 있어야 한다. 미션 지점 간격은 이미지 폭의 6%(92px) 이상이고, 지점은 가로 8~92%, 세로 15~92% 안에 있어야 한다. 건물을 충분히 크게 그린다.
5. R2 업로드는 PART 4 이후 별도 승인으로 진행한다. PART 1에서는 이미지 파일이 바뀌지 않아 R2 작업이 없다.

### 남은 문제

- 지도 이름이 기준점 중앙이 아니라 약 25px 왼쪽에 그려진다(화면에서 관찰). `MapLettering`이 이름 상자 안에서 왼쪽 정렬되는 것으로 보이며, 모든 시즌에 공통인 기존 동작이다. 고치면 다른 시즌의 표시가 바뀌므로 이번에는 두었다.
- `palace_map`만 야경이라 PART 2 지도와 톤이 다르다. PART 3에서 12장을 나란히 보고 판단한다.

### PART 1 테스트 결과

- `flutter analyze`: 문제 없음
- 신규 `test/seoul_case_maps_test.dart`: 13건 통과
- 전체 `flutter test`: 통과 3,925건, 건너뜀 7건, 실패 17건
- 실패 17건은 변경 전 코드(`2f1dd92`)에서 같은 파일을 실행한 결과와 목록이 일치한다. 이번 변경으로 새로 생긴 실패는 없다.

## 12. PART 2 결과와 PART 3 인계

### 제작 결과

| 파일 | 크기 | 비고 |
|---|---|---|
| `case_02_map.webp` | 551,654 B | 왼쪽 창고, 오른쪽 거북선 |
| `case_03_map.webp` | 632,016 B | 가운데 석재 마당과 거중기, 왼쪽 위 사무소, 오른쪽 위 성벽 |
| `case_04_map.webp` | 612,580 B | 왼쪽 아래 목재소, 아래 사무소, 오른쪽 위 공사장 |
| `case_05_map.webp` | 569,350 B | 아래 전등소와 연못, 왼쪽 위 장안당, 오른쪽 위 왕비 처소 |

- 모두 1536×1024 WebP다. dry run으로 대상이 4장뿐임을 확인한 뒤 `--only`로 제한해 생성했다. `planned` 자산 4개는 생성되지 않았다.
- 재생성 없이 1회씩 생성했다.
- 비용은 $0.1724(추정치)이고, 예산 $12.00 중 누적 $4.5376, 잔여 $7.4624다. `planning/factory.json`에 기록했다.
- Case 05는 §3의 초안과 달리 실제 배치대로 장안당을 서쪽(왼쪽), 왕비 처소를 동쪽(오른쪽)에 그렸다.
- 전체 톤은 낮은 호박색 새벽·저녁빛으로 맞췄다. 양피지 지도와 Case 01 야경의 중간 톤이다.

### 미션 좌표 (1536×1024, 이름 기준점은 장소 첫 지점의 12px 아래)

| Case | 미션 | 장소 | 좌표 |
|---|---|---|---|
| 02 | `s5_ep02_m1` | The Store Room (입구) | (335, 650) |
| 02 | `s5_ep02_m2` | The Store Room (안쪽) | (430, 400) |
| 02 | `s5_ep02_m3` | The Turtle Ship (등판) | (1240, 570) |
| 02 | `s5_ep02_final` | The Turtle Ship (용머리 쪽) | (1030, 625) |
| 03 | `s5_ep03_m1` | The Stone Yard (거중기) | (715, 620) |
| 03 | `s5_ep03_m2` | The Drawing Room | (255, 285) |
| 03 | `s5_ep03_m3` | The Stone Yard (석재 더미) | (930, 730) |
| 03 | `s5_ep03_final` | The New Wall (성문) | (1190, 285) |
| 04 | `s5_ep04_m1` | The Timber Yard | (290, 660) |
| 04 | `s5_ep04_m2` | The Yard Office | (810, 790) |
| 04 | `s5_ep04_m3` | The Palace Site (계단 앞) | (960, 460) |
| 04 | `s5_ep04_final` | The Palace Site (정전) | (1160, 300) |
| 05 | `s5_ep05_m1` | The Lamp House | (705, 905) |
| 05 | `s5_ep05_m2` | The Queen's Court (문) | (1047, 360) |
| 05 | `s5_ep05_m3` | The Queen's Court (전각 앞) | (1175, 265) |
| 05 | `s5_ep05_final` | Jangandang, The King's Hall | (345, 345) |

### 검증

- `flutter analyze`: 문제 없음
- 지도 테스트(`seoul_case_maps`, `season_pack_manifest`): 34건 통과
- 지도 회귀 묶음(기존 시즌 지도, 생성기, 팩, 자산 파이프라인): 696건 통과
- 390×844, 320×568 렌더링과 좌표 오버레이를 눈으로 확인했다. 핀과 이름의 겹침은 없었다.
- **전체 `flutter test`는 완료하지 못했다.** 시스템 메모리 부족으로 약 1,500건 지점에서 중단되었고, 환경 문제로 기록한다. 중단 전 실패 5건은 모두 기준선 17건에 포함된다. 사용자 지시에 따라 재실행하지 않았고, 전체 테스트는 최종 PART에서 한 번만 실행한다.

### 시즌팩 매니페스트 변경과 영향

- `season_pack_manifest_test`가 디스크와 매니페스트의 일치를 요구하므로 `build_manifest.dart`로 갱신했다. 지도 4개 항목이 추가되고 서울 버전이 `1e59ba509f1d0291`에서 `663effa47b5614d8`로 바뀌었다. 기존 항목은 삭제되지 않았다.
- **R2에는 새 버전이 없다.** 이 커밋으로 빌드한 앱은 R2 업로드 전까지 서울 팩을 새로 받을 수 없을 것으로 예상한다(실기기 미확인). 이미 설치한 사용자도 버전이 달라 재설치 대상이 된다. 실기기로 서울을 확인하려면 R2 업로드가 먼저 필요하다.

### PART 3 인계

남은 지도는 Case 06~12의 7장이다. 그릴 장소는 §11 표, 구도와 주의 사항은 §3 표를 따른다.

1. `assets.manifest.json`에 항목을 추가한다. PART 2의 `case_02_map` 항목 형식과 공통 프롬프트 문구를 그대로 쓴다(`stylePreset: seoul_map`).
2. dry run → `--generate --only ... --max-budget --max-calls` → 검토 → `--apply --only ...` 순서로 진행한다. 7장 예상 약 $0.35다.
3. 비용은 파이프라인이 `planning/factory.json`에 기록하지 않으므로, 실행 후 `spentUsd`, `runs`, `reviewed`를 갱신한다.
4. 이미지를 보고 좌표를 측정해 `art.caseMaps`에 등록한다. `measuredOn`은 파일 해시이고, 이름 기준점은 첫 지점의 12px 아래다.
5. `generate_season.dart --target game`과 `build_manifest.dart`를 실행한다.
6. `test/seoul_case_maps_test.dart`의 `ownMaps`에 Case를 추가하고, 폴백 확인을 옮긴다. 모든 Case가 전용 지도를 갖게 되면 폴백 위젯 테스트는 다른 방식으로 바꿔야 한다.
7. 검증은 `flutter analyze`와 변경 관련 테스트만 실행한다. 전체 `flutter test`는 최종 PART에서 한 번만 실행한다.

### 남은 문제

- Case 03·04 지도 아래쪽에 물가가 그려졌고, 네 지도 모두 해가 지평선에 보인다. 장소 표현에는 지장이 없어 재생성하지 않았다.
- §11의 이름 왼쪽 치우침은 그대로다.

## 13. PART 3 결과와 PART 4 인계

### 제작 결과

| 파일 | 크기 | 비고 |
|---|---|---|
| `case_06_map.webp` | 742,676 B | 오른쪽 궁궐 정원과 소나무·문, 가운데 돌담길과 손수레, 왼쪽 아래 이준의 집 |
| `case_07_map.webp` | 726,408 B | 왼쪽 아래 긴 여관과 뒷마당, 가운데 역 찻집, 오른쪽 위 역과 기차 |
| `case_08_map.webp` | 644,652 B | 왼쪽 아래 장터, 오른쪽 초가와 돌담 마당, 위쪽 매봉과 마른 솔가지 더미(불 없음) |
| `case_09_map.webp` | 666,176 B | 왼쪽 아래 골목, 오른쪽 위 2층 벽돌 청사 |

- 모두 1536×1024 WebP다. dry run으로 대상이 4장뿐임을 확인한 뒤 `--only`로 제한해 1회씩 생성했다. `planned` 자산 4개와 기존 이미지는 생성되지 않았고, 재생성도 없었다.
- 비용은 $0.1745(사용량 기준 추정치)다. 예상은 $0.1991이었다. 예산 $12.00 중 누적 $4.7121, 잔여 $7.2879다. `planning/factory.json`에 기록했다.
- 물과 해의 원인은 `seoul_map` 프리셋의 "sea in pale blue-grey"와 공통 문구 "dawn or dusk"였다. 프리셋을 바꾸면 다른 자산의 프롬프트가 달라지므로 그대로 두고, 이번 프롬프트에 "하늘·지평선·해 없음, 물 없음, 땅이 네 변 밖으로 이어짐"을 넣었다. 네 장 모두 물·해·지평선이 없다.
- 이전 지도보다 장소가 크게 그려져 화면을 더 채운다. 하늘이 없어 Case 02~05와 구도가 조금 다르지만 색감과 종이 질감은 같은 계열이다.

### 미션 좌표 (1536×1024, 이름 기준점은 장소 첫 지점의 12px 아래)

| Case | 미션 | 장소 | 좌표 |
|---|---|---|---|
| 06 | `s5_ep06_m1` | The Palace Garden (소나무) | (1027, 400) |
| 06 | `s5_ep06_m2` | The Palace Garden (정원 문) | (1100, 853) |
| 06 | `s5_ep06_m3` | The West Lane (손수레 옆) | (640, 640) |
| 06 | `s5_ep06_final` | Yi Jun's House | (287, 640) |
| 07 | `s5_ep07_m1` | Mrs. Kang's Inn (입구) | (215, 840) |
| 07 | `s5_ep07_m2` | The Station Tea Room | (1013, 433) |
| 07 | `s5_ep07_m3` | Mrs. Kang's Inn (안채) | (427, 667) |
| 07 | `s5_ep07_final` | Mrs. Kang's Inn (뒷마당) | (820, 587) |
| 08 | `s5_ep08_m1` | Aunae Market | (360, 640) |
| 08 | `s5_ep08_m2` | Gwan-sun's Home (마당) | (1130, 725) |
| 08 | `s5_ep08_m3` | Gwan-sun's Home (마루) | (1240, 660) |
| 08 | `s5_ep08_final` | Maebong Hill (정상 가장자리) | (833, 160) |
| 09 | `s5_ep09_m1` | A Lane in Shanghai | (360, 693) |
| 09 | `s5_ep09_m2` | The Government Office (2층 문) | (967, 330) |
| 09 | `s5_ep09_m3` | The Government Office (2층 가운데) | (1150, 350) |
| 09 | `s5_ep09_final` | The Government Office (2층 오른쪽 끝) | (1345, 400) |

- **매봉 핀은 솔가지 더미가 아니라 정상 평지의 앞쪽 가장자리에 있다.** 더미는 y≈117로 안전 영역(15%, 154px) 위에 있다. 화면에서는 핀이 산꼭대기에 놓인 것으로 보여 재생성하지 않았다.
- **Case 09 지점은 창문이 아니라 건물 폭 기준이다.** 처음에 창문 세 곳에 맞췄더니 320 화면에서 완료 표시가 현재 핀의 이름 칸을 피해 움직여 두 표시가 붙었다. 건물 폭을 넓게 쓰도록 m3, final을 옮겼다.

### 계획과 달라진 점

- **핀 이름이 잘리는 문제를 고쳤다(`map_pin.dart`의 `_PlaceName`).** `THE GOVERNMENT OFFICE`가 세 줄로 줄바꿈되어 OFFICE가 사라졌다. 두 줄에 들어가지 않는 이름만 글자 크기를 13.5에서 최소 11.5까지 줄인다. 두 줄에 들어가는 이름의 표시는 바뀌지 않는다. 모든 시즌의 공용 위젯이므로, 다른 시즌에서 같은 식으로 잘리던 이름이 있다면 그 이름도 작아져서 전부 표시된다.

### 검증

- `flutter analyze`: 문제 없음
- `seoul_case_maps_test`: 30건 통과(Case 06~09 지도, 미션 연결, 파일 해시, Case 10~12 폴백, 긴 이름 포함)
- 지도 회귀 묶음(기존 시즌 지도, 생성기, 팩, 자산 파이프라인, 시즌 팩토리): 386건 중 383건 통과, 3건 실패
  - 1건은 신규 테스트의 문제였고, 수정 후 `seoul_case_maps_test`만 다시 실행해 통과했다.
  - 2건은 기존 실패다. 변경 전 커밋 `27c05c5`에서도 같은 테스트가 실패한다: `world_map_test`의 "the case map's menu leaves to the World Map"(지갑 저장 키), `season_factory_test`의 "the opening's city at night"(Rome 계획 파일의 줄바꿈).
- 390×844, 320×568 렌더링과 좌표 오버레이를 Case별 진행 단계(미션 1~3 해결)로 눈으로 확인했다.
- 전체 `flutter test`는 지시대로 실행하지 않았다. 실기기도 확인하지 않았다.

### 시즌팩 매니페스트 변경과 영향

`build_manifest.dart`로 지도 4개 항목을 추가했고 서울 버전이 `663effa47b5614d8`에서 `c51d3d21afe0d3e5`로 바뀌었다. 기존 항목은 삭제되지 않았다. R2에는 이 버전도, PART 2의 버전도 없으므로 §12의 주의 사항이 그대로 적용된다.

### PART 4 인계

남은 지도는 Case 10~12의 3장이다. 절차는 §12와 같다.

1. `assets.manifest.json`에 `case_10~12_map`을 `case_09_map` 뒤에 추가한다. **프롬프트 끝의 공통 문구는 `case_09_map`의 것을 쓴다.** 단, Case 12는 강과 돌계단이 실제 장소이므로 "no water" 문장을 빼고 그 강만 허용한다.
2. dry run → `--generate --only ... --max-budget --max-calls` → 검토 → `--apply --only ...` 순서로 진행한다. 3장 예상 약 $0.15다.
3. `planning/factory.json`의 `spentUsd`, `runs`, `reviewed`를 갱신한다.
4. 좌표를 측정해 `art.caseMaps`에 등록한다. 같은 건물에 지점이 3개인 Case 10은 **지점끼리 가로로 넓게 떨어뜨리고, 320 화면에서 완료 표시가 붙지 않는지 본다.** 현재 핀 기준 가로 약 215px 안의 완료 표시는 320 화면에서 옆으로 밀린다.
5. `generate_season.dart --target game`과 `build_manifest.dart`를 실행한다.
6. `test/seoul_case_maps_test.dart`의 `ownMaps`에 추가한다. 모든 Case가 전용 지도를 갖게 되므로 폴백 테스트 2건(`a case without its own map...`, `moving to a case without its own map...`)은 다른 방식으로 바꿔야 한다.
7. 최종 PART이므로 전체 `flutter test`를 한 번 실행한다. 이번에 확인한 기존 실패 2건과 §11의 기준선 17건을 비교한다.
8. R2 업로드는 별도 승인 후 진행하고, 앱 배포보다 먼저 끝나야 한다.

### 남은 문제

- Case 02~05의 물가와 해는 재생성 금지에 따라 그대로다.
- `palace_map`만 야경인 톤 차이와 §11의 이름 왼쪽 치우침은 그대로다.
- 매봉이 다소 둥근 언덕 모양이다. 위치 표현에는 지장이 없다.

## 14. PART 4 결과와 PART 5 인계

### 제작 결과

| 파일 | 크기 | 비고 |
|---|---|---|
| `case_10_map.webp` | 668,046 B | 아래쪽 긴 벽돌집(왼쪽 대문, 가운데 초록 덧창, 오른쪽 뒷마당), 오른쪽 위 3층 집 꼭대기 창 |
| `case_11_map.webp` | 678,770 B | 왼쪽 위 석조 기숙사(양 끝 현관), 오른쪽 위 탑이 있는 석조 강당, 아래 돌기둥 정문 |
| `case_12_map.webp` | 773,716 B | 왼쪽 위 3층 청사(발코니, 트렁크), 오른쪽 가운데 담장 안 작은 집, 오른쪽 아래 돌계단과 나루, 두 강 |

- 모두 1536×1024 WebP다. dry run으로 대상이 3장뿐임을 확인한 뒤 `--only`로 제한해 1회씩 생성했다. `planned` 자산과 기존 이미지는 생성되지 않았고, 재생성도 없었다.
- 비용은 $0.1313(사용량 기준 추정치)이다. 예상은 $0.1498이었다. 예산 $12.00 중 누적 $4.8434, 잔여 $7.1566이다. `planning/factory.json`에 기록했다.
- 프롬프트 끝 공통 문구는 `case_09_map`과 같다. Case 12만 "no water" 문장 대신 "물은 오른쪽 아래 두 강뿐"으로 바꿨다. 세 장 모두 하늘·해·지평선·글자가 없고, Case 10·11에는 물이 없다.
- Case 10은 사건 장소(공원)와 인물을 그리지 않았다.

### 미션 좌표 (1536×1024, 이름 기준점은 장소 첫 지점의 12px 아래)

| Case | 미션 | 장소 | 좌표 |
|---|---|---|---|
| 10 | `s5_ep10_m1` | A Small House in Shanghai (대문) | (237, 768) |
| 10 | `s5_ep10_m2` | A Small House in Shanghai (덧창) | (554, 782) |
| 10 | `s5_ep10_m3` | A Small House in Shanghai (뒷마당) | (963, 824) |
| 10 | `s5_ep10_final` | Haesu's Room (꼭대기 창) | (1236, 210) |
| 11 | `s5_ep11_m1` | Yun's Room (기숙사 왼쪽 현관) | (196, 342) |
| 11 | `s5_ep11_m2` | Yun's Room (기숙사 오른쪽 현관) | (680, 230) |
| 11 | `s5_ep11_m3` | The College Hall | (1257, 321) |
| 11 | `s5_ep11_final` | The College Gate | (691, 824) |
| 12 | `s5_ep12_m1` | The Government Office (왼쪽) | (335, 279) |
| 12 | `s5_ep12_m2` | Bitna's Room | (1131, 398) |
| 12 | `s5_ep12_m3` | The Government Office (오른쪽, 트렁크) | (691, 237) |
| 12 | `s5_ep12_final` | The River Steps (나루) | (1145, 824) |

- Case 10의 한 집 안 세 지점은 가로로 317px, 409px 떨어져 있다. 320 화면에서도 완료 표시가 현재 핀 이름에 붙지 않았다.

### 최종 서울 Case 지도

Case 01 `palace_map.webp`, Case 02~12 `case_02_map.webp`~`case_12_map.webp`. 시즌 보드와 월드맵은 계속 `season_map.webp`를 쓴다.

### 테스트 변경

- `ownMaps`에 Case 10~12를 추가했다.
- 폴백 단위 테스트 "a case without its own map stays on the season map"을 "every Seoul case has its own map"(12개 Case가 서로 다른 전용 파일)으로 바꿨다. 다른 시즌의 `forCase` 폴백은 기존 "the other seasons have none" 테스트가 계속 검증한다.
- 폴백 위젯 테스트는 서울 Case 10 대신 뉴욕 Case 03으로 바꿨다. 뉴욕 시즌 지도가 표시되고, 현재 핀의 장소를 뺀 모든 장소 이름이 보이는지 확인한다(현재 핀의 장소 이름은 핀이 표시하는 기존 규칙).
- 긴 이름 테스트에 `A SMALL HOUSE IN SHANGHAI`를 추가했다.

### 검증

- `flutter analyze`: 문제 없음
- `seoul_case_maps_test`: 37건 통과
- 지도 회귀 묶음(기존 시즌 지도, 월드맵, 생성기, 팩, 자산 파이프라인, 시즌 팩토리, season_gen): 771건 중 770건 통과. 실패 1건은 §13의 기존 실패 `world_map_test` "the case map's menu leaves to the World Map"(지갑 저장 키)이다.
- 390×844, 320×568에서 Case별 진행 단계(미션 0~3 해결)를 임시 골든 캡처로 눈으로 확인했다. 겹침, 잘린 이름, 잠긴 장소 이름 노출은 없었다. 임시 테스트는 삭제했다.
- 전체 `flutter test`는 지시대로 실행하지 않았다. 실기기도 확인하지 않았다.

### 시즌팩 매니페스트 변경과 영향

`build_manifest.dart`로 지도 3개 항목을 추가했고 서울 버전이 `c51d3d21afe0d3e5`에서 `f4a5c1af27a2bdfb`로 바뀌었다. 기존 항목은 삭제되지 않았고 다른 시즌의 버전은 그대로다.

**주의:** 처음 실행 때 `assets/` 아래의 macOS `.DS_Store` 파일(Git 미추적)이 팩에 들어가 Paris 버전까지 바뀌었다. 파일을 지우고 다시 실행해 바로잡았다. R2 배포 전 `build_manifest.dart`를 다시 돌릴 때는 `.DS_Store`가 없는지 먼저 확인한다.

### PART 5 인계

1. 최종 검증: 전체 `flutter test`를 한 번 실행하고 §11의 기준선 17건, §13·§14의 기존 실패와 비교한다(PART 2에서는 메모리 부족으로 중단된 적이 있다).
2. 실기기에서 서울 Case 01~12 지도를 확인한다. R2에 새 버전이 없으므로 실기기 확인은 R2 업로드 뒤에 가능하다.
3. R2 배포(별도 승인 필요): `tool/season_packs`의 스테이징·업로드 절차로 서울 버전 `f4a5c1af27a2bdfb`를 올리고 HTTPS로 Case 지도 12개 객체를 재확인한다. 앱 배포보다 먼저 끝나야 한다.
4. 푸시는 PART 2~4 커밋과 함께 별도 승인 후 진행한다.

### 남은 문제

- Case 02~05의 물가와 해, `palace_map`의 야경 톤 차이, §11의 이름 왼쪽 치우침은 그대로다.
- Case 12는 물이 오른쪽 아래 구석보다 조금 넓게(아래 가운데까지) 그려졌다. 실제 장소가 강변이라 재생성하지 않았다.

## 15. PART 5 결과 (2026-11-06)

### 무결성

- `assets/` 아래 `.DS_Store` 없음(루트·`lib/`·`qa/`·`docs/`에만 있고 팩 대상 아님).
- `build_manifest.dart` 재실행: `season_pack_manifests.g.dart` 변경 없음. 버전 Paris `a9018c0d12941172`, Rome `925831b811fc822c`, New York `ab063cbc1c01a5b3`, Seoul `f4a5c1af27a2bdfb`(101파일, 86,991,040 B).
- 12개 지도(`palace_map` + `case_02`~`case_12`)와 `season_map.webp` 존재. 48개 미션 좌표, plan↔Dart 일치, 다른 시즌 무변경은 `seoul_case_maps_test`가 검증.
- `season_factory.dart packs`: 101파일 크기·SHA-256 확인, 버킷이 90개 보유, 신규 11장(7,266,044 B) + 매니페스트 1개(19,975 B) 스테이징. `palace_map`은 기존 객체 재사용.

### 테스트

- `flutter analyze`: 문제 없음
- `seoul_case_maps_test`: 37건 통과
- 지도 회귀 묶음: 595건 통과, 1건 실패(`world_map_test` 지갑 저장 키, 기존)
- 전체 `flutter test -j 2`: 통과 3,952 / 건너뜀 7 / 실패 14, 15분 35초, 메모리 중단 없음
- 실패 14건을 변경 전 `2f1dd92`에서 같은 파일로 다시 실행: 같은 14건 실패. **신규 실패 0건.** (기준선 17건 중 3건은 현재 통과)

### R2 업로드: 완료

- 첫 시도(10:23 UTC)는 wrangler 미로그인으로 첫 객체에서 실패, 전송 0건. 사용자 `wrangler login` 뒤 다시 실행.
- `season_factory.dart upload … --approved`: 12객체 전송(신규 지도 11장 7,266,044 B + 매니페스트 19,975 B, 합계 7,286,019 B). 파이프라인이 HTTPS 200·크기·SHA-256을 모두 다시 읽어 확인. `factory.json` deploy `deployed`, sent 12.
- 별도 HTTPS 확인(curl): `manifests/season_05_seoul/f4a5c1af27a2bdfb.json` 200, version `f4a5c1af27a2bdfb`. Case 지도 12개(`palace_map` 포함) 객체 모두 크기·SHA-256이 매니페스트 및 로컬 파일과 일치.
- 앱이 참조하는 버전(`season_pack_manifests.g.dart`)도 `f4a5c1af27a2bdfb`.
- 기존 객체 삭제 없음, 다른 시즌 매니페스트 변경 없음.
- `SEASON_PACK_LIVE_URL=… flutter test test/season_pack_live_r2_test.dart`: 7건 모두 통과(앱 다운로드 코드로 실제 버킷에서 팩 다운로드·검증, 10분 이상 소요). 전체 `flutter test`는 재실행하지 않음(위 결과 유지).

### 실기기 체크리스트 (업로드 뒤)

- [ ] 서울 시즌팩 다운로드 완료
- [ ] Case 01~12가 각자 전용 지도로 열림(01은 궁궐 지도)
- [ ] 지도 확대·이동
- [ ] 미션별 핀 위치가 §11~§14 좌표의 장소에 있음
- [ ] 잠긴 장소 이름 숨김
- [ ] 다운로드 완료 후 비행기 모드에서 실행

### 남은 문제

- §14 남은 문제 그대로
