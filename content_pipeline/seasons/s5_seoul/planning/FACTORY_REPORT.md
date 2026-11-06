# 시즌 5 Seoul — 시즌팩토리 제작 보고 (PART 10, 2026-11-06)

Case 01(기존 완성본)은 그대로 두고, Case 02~12를 시즌팩토리로 한 번에 제작했다. `season_factory.dart run` 최종 실행 결과는 exit 0이다. 앱 반영(9단계 시즌 팩 스테이징)까지 마쳤고, R2 업로드는 하지 않았다.

## 시즌 구성

- 제목: The King's Letters of Seoul — READ THE NEW LETTERS
- 시즌 미스터리(창작): 물방울 표시가 찍힌 한글 쪽지를 남기는 '지키는 사람'. Case 01의 분이 가문이 500년 동안 편지함을 지켜 온 것으로 설정했다. 2막 공개는 Case 08, 결말은 Case 12(LIGHT = 광복)다.
- 정책: 모든 Case는 출처를 확인한 역사적 사실로 끝난다. 창작 미스터리는 해결되지만 실제 역사의 결과는 바꾸지 않는다.

| Case | 인물 / 연도 | 제목 | 미션(3+파이널) | 파이널 정답 | 그림(계획) | 사실 확인 |
|---|---|---|---|---|---|---|
| 01 | 세종 / 1446 | The Secret of the King's Letters (기존) | 추적·순서·한글 조합·증거 대화 | open | 10 | 12/13 |
| 02 | 이순신 / 1592 | The Turtle Ship Before Dawn | 수색·한글 조합·숫자·글자 타일 | DRAGON | 8 | 6/6 |
| 03 | 정약용 / 1795 | The Crane That Lifts Stones | 연표·그림 선택·순서·다이얼 | 1796 | 8 | 5/6 |
| 04 | 흥선대원군 / 1866 | The Palace of a Thousand Logs | 돋보기·숫자·연표·증거 대화 | (대화) | 5 | 6/7 |
| 05 | 명성황후 / 1895 | The Lights of Geoncheonggung | 둘러보기·연표·숫자·단어 | JAPAN | 8 | 5/5 |
| 06 | 고종 / 1907 | The Emperor's Secret Letter | 추적·순서·숫자·글자 타일 | FORCED | 6 | 6/7 |
| 07 | 안중근 / 1909 | Two Reports from Harbin | 기록 비교·연표·단어·증거 대화 | (대화) | 7 | 3/4 |
| 08 | 유관순 / 1919 | The Fire on the Hill | 증인 비교·순서·단어·다이얼 | 311 | 7 | 5/5 |
| 09 | 김구 / 1920 | The Spy in the Shanghai Office | 숫자·수색·단어·증거 대화 | protect | 7 | 4/4 |
| 10 | 윤봉길 / 1932 | The Two Watches | 순서·그림 선택·글자 타일·숫자 | 1932 | 8 | 4/4 |
| 11 | 윤동주 / 1941 | The Poet's Three Copies | 돋보기·한글 조합·숫자·단어 | KOREAN | 5 | 8/8 |
| 12 | 김원봉 / 1945 | The Day the Light Returned | 둘러보기·연표·숫자·글자 타일 | LIGHT | 8 | 9/9 |

'draft'로 남은 사실 5건(Case 01·03·04·06·07 각 1건)은 어떤 퍼즐이나 공개 문장의 근거로도 쓰지 않았다(History Gate 통과).

## 그림

- 새로 만든 그림은 73장이다. 검수에서 6장을 거절하고 프롬프트를 고쳐 다시 만들었다.
  - 이순신·흥선대원군: 왕의 용 흉배 → 흉배 없음
  - lamp_house: 사람 5명 → 빈 방
  - 경순: 유관순과 구별이 안 됨
  - 해수: 학생처럼 보임
  - 김구: 현대식 옷
- 그림을 만들지 않은 계획 3장: ham·gwak·pyo 초상. 어느 화면에도 나오지 않는다.
- WebP 변환: 장면은 q88, 인물은 q94, 퍼즐 그림은 lossless다.
- 시즌 지도(season_map)의 9개 장소와, 측정이 필요한 퍼즐 그림 10장의 영역을 격자 시트에서 직접 측정했다.
- 비용(시즌팩토리 기록): 누적 $4.3652. 이번 작업분은 약 $3.46이고, 여기에는 만료된 키로 실패한 1회의 추정치 $0.0745가 포함된다. 예산 $12 중 남은 금액은 약 $7.63이다.
- 앱 번들에 들어가는 Seoul 그림은 cover 폴더 1.9 MB뿐이다. 나머지는 시즌 팩으로 내려받는다.
- 작업 폴더 백업: `~/world_mystery_backups/s5_seoul_asset_work_2026-11-06`(파일 194개, sha256 일치).

## 앱 반영 (다음 앱 업데이트에 포함해야 할 것)

- `lib/data/generated/s5_seoul/`(새로 생성), `generated_seasons.g.dart`, `generated_season_art.g.dart`, `generated.manifest.json`
- `lib/core/assets/season_pack_manifests.g.dart`(season_05_seoul v1e59ba509f1d0291)
- 손으로 등록하던 Seoul을 생성본으로 교체했다:
  - `SeasonCatalog.partialSeasons`를 비웠다.
  - `map_world.dart`·`art_assets.dart`에서 손으로 넣은 항목을 지웠다.
  - `lib/data/season5/`는 생성본을 가리키는 별칭만 남겼다.
  - 예전 sandbox 생성본 `lib/data/season5/s5_seoul/`을 삭제했다.
- 생성기: 시즌 계획에 `art.introBackdrops`를 추가했다. Case 01 오프닝 배경(kings_study)을 유지하기 위해서다.
- 세이브 호환: Case 01의 id(s5_ep01, 미션 id)는 바뀌지 않았다.

## R2 배포 준비 (업로드 안 함)

- 팩 v1e59ba509f1d0291: 그림 90장, 그중 17장은 이미 버킷에 있다.
- 업로드 예정: 새 그림 73장(67,691,592 bytes ≈ 64.6 MB)과 새 매니페스트(`manifests/season_05_seoul/1e59ba509f1d0291.json`)
- 스테이징 위치: `build/season_packs/season_05_seoul/1e59ba509f1d0291/`(`upload_list.tsv`)
- 업로드는 사용자 승인 후 `season_factory.dart upload content_pipeline/seasons/s5_seoul --approved`로 한다.

## 검증

- `plan_season check`: ERROR 0, WARNING 65. 대부분 `clue_never_used`, 퍼즐 선택 규칙 경고, 의도적으로 반복한 문구다.
- `case_levels check`: 12개 Case와 시즌 문장 모두 ok다.
- 시즌팩토리 8단계: `flutter analyze` 이상 없음, `test/generated_seasons_test.dart` 175개 통과. Seoul 12개 Case를 ROOKIE/JUNIOR/MASTER로 실제 앱에서 끝까지 플레이하는 테스트와, 기기 크기별 둘러보기 테스트가 들어 있다.
- 관련 테스트 묶음(약 1,000개): Seoul sandbox, season_factory/planner/gen, difficulty, multi_season, art_assets, season_pack, season 화면, world_map, asset_pipeline/optimizer. 남은 실패 5건은 모두 변경 전 HEAD에서도 똑같이 실패한다:
  - season_factory_test의 prologue.hero(Rome 파일 줄바꿈)
  - season_content_test의 London ep10
  - history_dossier_test의 hook(Windows에서 `dart` 실행 경로)
  - asset_optimizer_test의 kings_study 기록 없음
  - world_map_test의 hub(지갑 저장)
- 전체 `flutter test`는 실행하지 않았다(지시사항).

## 수정한 테스트 (Seoul이 Case 1개에서 12개 시즌이 된 데 맞춘 갱신)

- s5_seoul_gate/play/dev_mode, multi_season, season_presentation(시즌 지도), art_assets(s5_ 생성분), season_factory(예산 $12)
- season_pack_download: 팩이 커져서 대기 시간만 늘렸다.
- season_playthrough 하네스: STEP 1/2.0 엔진, 수색, 증거 대화 파이널을 기존 `CasePlayer`로 플레이하도록 했다.

## 남은 위험과 확인하지 못한 것

- 실기기에서는 확인하지 않았다.
- 출처가 약한 부분이 있다(dossier에 기록함).
  - Case 02의 거북선 포 시험 날짜(음력 4.12): 날짜는 일기를 인용한 언론 3곳에만 있고, 공공기관 자료는 "왜란 전"까지만 확인된다.
  - Case 06·07: 일부 사실의 두 번째 출처가 언론이다.
  - Case 08: 봉화 날짜는 언론 출처다.
- Case 01의 기존 WARNING(문장 길이 등)은 Case 01을 바꾸지 않는다는 원칙에 따라 그대로 두었다.
- 1941년 연희전문은 남학교로 보여 미리를 '학교 일을 돕는 사람'으로 설정했다. 이 사실은 출처로 확인하지 못했다.
- 버킷 URL은 개발용 r2.dev 주소다. 출시 전에 커스텀 도메인으로 바꿔야 한다.
