# 서울 시즌 Case별 Mission Map 계획 (PART 0)

작성일: 2026-11-06 · 기준 커밋: `58c75d5` · 상태: 조사와 계획만 완료. 코드와 이미지는 수정하지 않았다.

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

전체 이미지를 눈으로 보고 잡은 후보이며, PART 1에서 실제 화면으로 확정한다.

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
