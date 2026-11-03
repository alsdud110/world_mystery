# 시즌 1 대화 UI — PART C 보고서 (2026-11-03, 예약 실행)

PART B 구조(`MissionSpeech` + `season1Speeches` + `CaseTalk` + `MissionWords`)를 그대로 확장했습니다. 공통 UI는 새로 만들지 않았고, 대사는 각 레벨의 미션 편지 문구를 그대로 씁니다(레벨별 중복 문구 없음). **git commit / push는 하지 않았습니다.**

## 1. 새 초상화 7장과 실제 비용

모두 gpt-image-1.5 (edits), quality medium, 1024×1536, 불투명 배경, 호출당 `--budget-usd 0.12`, 장당 1회 호출(재시도 없음). 스타일 참조는 `flower_seller.webp`를 PNG로 바꾼 것(PART B와 같음)입니다.

| 초상화 | 참조 | 비용(usage 기준) | 파일 |
|---|---|---|---|
| Mrs Bell | flower_seller | $0.0657 | `characters/mrs_bell.webp` |
| Inspector Grey | flower_seller | $0.0649 | `characters/inspector_grey.webp` |
| Ravenmaster (사람) | flower_seller | $0.0672 | `characters/ravenmaster.webp` |
| Mrs Robin | sketch_miss_rose | $0.0654 | `characters/mrs_robin.webp` |
| Head Butler | flower_seller | $0.0655 | `characters/head_butler.webp` |
| Guard Carl | flower_seller | $0.0653 | `characters/guard_carl.webp` |
| Cleaner | flower_seller | $0.0638 | `characters/cleaner.webp` |

- **PART C 합계 $0.4578** (한도 $0.8972), **PART B 포함 누적 $0.7606 / $1.20** (미사용 $0.4394).
- 생성한 그림은 모두 512px로 줄여 직접 확인했습니다. 7장 모두 1차에 사용 가능해서 재시도는 없었습니다.
- 최적화: `optimize_assets.dart --apply --only …`로 22.6 MB → 4.6 MB(WebP)로 줄였고, 원본 PNG는 `content_pipeline/asset_originals/seasons/season_01_london/characters/`로 옮겨졌습니다.
- 기록: `content_pipeline/asset_work/s1_dialogue_part_c/`(README.md 비용표, image_manifest.json, raw/, reference/). 이 폴더는 git 대상이 아닙니다(PART B와 같음).
- 스포일러 방지를 위해 일부러 넣지 않은 것: 집사는 열쇠를 들지 않음(C09 M1 정답이 열쇠 주인), Carl은 모자를 쓰지 않음(C09 Final 정답이 HAT), Mrs Robin은 스카프와 팔짱으로 코트 단추를 가림(C08 Final 정답이 Red Button), Ravenmaster의 까마귀에는 금반지가 없음(C10 M1 정답 Poppy의 특징).

## 2. 변환한 장면(9개)

| 장면 | 화자(이름표) | 배경 | 퍼즐 |
|---|---|---|---|
| ep02_final | MRS BELL | big_ben/clock_mechanism | 시계 바늘 맞추기(finalClocks) |
| ep03_m3 | CLEANER | british_museum_great_court | 발자국 순서(trail) |
| ep07_final | INSPECTOR GREY | landmarks/hyde_park | 지도 그림 선택 |
| ep08_final | MRS ROBIN | landmarks/kings_cross | 증거 선택 |
| ep09_m1 | HEAD BUTLER | landmarks/buckingham_palace | 열쇠 그림 선택 |
| ep09_m2 | GUARD CARL | buckingham_palace_palace_staff_room | 이름 입력 |
| ep10_m1 | RAVENMASTER | landmarks/tower_of_london | 까마귀 그림 선택 |
| ep10_final | RAVENMASTER | landmarks/tower_bridge | 종이 순서 |
| ep12_m1 | MRS BELL | big_ben/clock_mechanism | 톱니 그림 선택 |

- 모두 `fromStory: false`라서 편지 내용 자체가 대사가 됩니다. 편지 단계는 생략되고, 퍼즐의 다시 보기 버튼은 **"Hear It Again"**(SpokenWordsCard)로 바뀌며, 풀이 완료 페이지에도 대사 카드가 나옵니다.
- **Final 4개**(PART B에서 처리하지 않았던 `fromStory:false` final)
  - Final에는 이야기 페이지가 따로 없어서, 대화가 이야기 줄(나레이터, 따옴표 안 문장은 화자)로 시작하고 이어서 편지 문장이 나옵니다. 그래서 대화가 끝난 뒤 최종 페이지에 이야기를 다시 보여주지 않습니다.
  - 최종 페이지에는 LetterCard 대신 SpokenWordsCard가 나옵니다(`MissionWords`). 다시 보기 시트도 같은 카드를 씁니다.
  - 시계 퍼즐(ep02)의 'Reread Letter'는 'Hear It Again'으로 바뀌었습니다. 일반 문제 페이지(ep07·08·10)에는 퍼즐 아래에 'Hear It Again' 버튼을 새로 넣었습니다(이전에는 다시 보기 버튼이 없었음).
  - 4개 퍼즐 모두 3개 레벨에서 대화 → 퍼즐 → 오답 → 정답 흐름이 정상인지 테스트로 확인했습니다. ep08은 화면에서 'Red Button'을 탭해서 푸는 과정까지 확인했습니다.
- ep03_m3(trail)은 원래 일반 편지 단계로 편지를 보여주던 미션이라 똑같이 변환했습니다.
- 정답, 선택지, 힌트, 코인, 보상, 저장 데이터는 바꾸지 않았습니다(데이터 파일 변경 없음).
- 대화는 기존 CaseTalk 방식 그대로입니다. 진행 중 저장되고 다시 들어오면 이어지며, 한 번 들은 대화는 다시 재생되지 않습니다. SKIP과 TALK LOG도 그대로 쓸 수 있습니다.
- 같은 인물은 어디서나 같은 초상화를 씁니다(Mrs Bell: C02·C12, Grey: C07·C12, Ravenmaster: C10 두 장면). 이 점은 테스트로 고정했습니다.
- 이름표, 목표 문장, 초상화 설명 어디에도 정답 단어가 없는지 레벨별로 테스트합니다. 이 검사에서 Mrs Bell 설명의 'brass'(C12 M1 정답 단서)를 찾아 'old keys'로 고쳤습니다.

## 3. C12 M2 — Inspector Grey 분리 결과

- 미션 데이터(`letter`)는 **바꾸지 않았습니다.** 기존 교차 사건 테스트들이 보드 문구와 Grey 문구를 글자 그대로 확인하기 때문입니다.
- `MissionSpeech.inLetter` 모드를 새로 만들었습니다. 편지 끝의 `Inspector Grey: "…"`를 화면에서만 떼어 대사로 쓰고, 나머지 보드는 종이(편지)로 남깁니다.
  - 흐름: INVESTIGATE → Grey 대화(한 문장: "The Clockmaker always arrives on the platform with the small red clock, after the train from Edinburgh.") → 도착 보드 봉투(Grey 문구 없이 4개 열차만) → 퍼즐.
  - 퍼즐의 'Reread Letter' 시트에는 Grey의 대사 카드와 보드 카드가 함께 나옵니다. 각각 **한 번씩만** 나오고, 3개 레벨 모두 퍼즐에 필요한 사실(보드 4줄 + Grey 문장)이 화면에 있습니다.
- 정답 1140은 그대로입니다. 고정 해시 테스트(`difficulty_london_6d`의 `ep12_m2.letter`)는 데이터가 그대로라 수정하지 않았습니다.
- `cross_case_language_test`는 Grey 문장을 LetterCard에서 찾던 기대를 SpokenWordsCard로 옮겼고, 보드 줄은 LetterCard에서 확인하도록 바꿨습니다. 변경 이유는 주석으로 남겼으며, 검사를 약하게 만들지 않고 오히려 하나 늘렸습니다.

## 4. 시즌 1 대화 UI 전/후

| | PART B 후(=PART C 전) | PART C 후 |
|---|---|---|
| CaseTalk로 말하는 사람 장면(speeches) | 2 (ep11_m3, ep11_final) | **12** (+9 장면, +C12 M2 Grey) |
| 사람 말을 편지로 보여주던 장면 | 10 (9 장면 + C12 M2 Grey 줄) | **0** |
| 편지 UI로 유지(지시대로) | C03 M1·M2, C03 Final 택시 메모, C05 M1·M3, C06 M3, C08 M2, C10 M3, C11 M1, C12 M3 | 동일(테스트로 고정) |

일관성 점검(시즌 1 전체 letterIntro 확인):
- 사람이 편지 UI로 말하는 장면이 더는 없습니다. C04 M2(짐꾼)는 장소에서 읽는 deduction 퍼즐이고, C06 M1(목격자)은 기존 대화 조사 화면이라 편지가 아닙니다. 둘 다 이번 범위가 아니어서 바꾸지 않았습니다.
- 초상화는 대화 화면, Hear It Again 카드, 풀이 완료 카드에 나오고 같은 인물은 같은 모습입니다. 수첩과 증거 데이터는 바꾸지 않았습니다.
- C11/C12의 PART B 동작은 `s1_dialogue_part_b_test` 전체 통과로 확인했습니다. speeches 키 목록 기대값만 새 장면을 포함하도록 갱신하고 주석을 남겼습니다.

## 5. flutter analyze / 실행한 테스트

- `flutter analyze`: **No issues found** (코드 변경 후, 테스트 수정 후 두 번 실행).
- 새 테스트 `test/s1_dialogue_part_c_test.dart`의 검사 항목:
  - 데이터: 레벨별 화자, 초상화, 대사 = 편지 줄, final은 이야기 먼저
  - 정답 불변, 스포일러 없음, 같은 인물 같은 초상화
  - C12 M2 분리, 편지 유지 목록
  - 이미지 존재(missingAssets) 및 디코드(1024×1536)
  - 화면: 대화 → 퍼즐(편지 없음) → Hear It Again
  - 재진입(들은 대화 미재생), 풀이 완료된 옛 저장
  - C12 M2 화면 흐름, final 4개 × 3레벨, C08 화면 풀이, 풀린 final 재방문
- 관련 테스트(미션 id·final 화면·공용 헬퍼를 grep해서 고른 **51개 파일**)를 실행했습니다. 로그는 `content_pipeline/asset_work/s1_dialogue_part_c/scratch/test*.log`에 있습니다.
  - 첫 실행에서 실패한 테스트는 모두 같은 원인이었습니다. 새 대화가 퍼즐 앞에 들어가서, 퍼즐/최종 페이지로 바로 들어가던 테스트가 막힌 것입니다.
  - 해당 테스트들에 `hearTalk`(PART B 헬퍼)를 넣어 플레이어와 같은 흐름으로 고쳤습니다. 공용 `openPuzzle`과 `mission_stage_layout` 헬퍼는 대화 → 보드 → 퍼즐(C12 M2) 경로를 지원하도록 고쳤습니다. 퍼즐 중간 상태를 가정한 C12 M2 테스트 2개(time_code, season_archive)는 저장에 'Grey 대화 들음'을 넣었습니다. 모두 주석을 달았고, 검사를 삭제하거나 완화하지 않았습니다.
  - `new_artwork_test`의 Case 02는 대화 뒤 새로 그려진 페이지의 시계 그림이 테스트 환경에서 디코딩되지 않아 실패했습니다. 열기 직후와 같은 `settle`(디코딩 대기)을 추가해 해결했습니다.
  - **최종 결과: 51개 파일 중 1건만 실패.** `sound_prototype_test: sound off …`는 AdMob 동의(`AdConsent`) 10초 타이머가 남아서 생긴 실패입니다. Case 01 화면이고 광고 코드라 이번 변경과 무관하며, 이 파일과 광고 코드는 건드리지 않았습니다. 다만 변경 전 코드에서 다시 돌려 확인하지는 못했습니다(이번 실행에서 허용되지 않은 git 명령이 필요).
  - 마지막 실행 기준 통과 수: 51개 파일 실행 1204 통과 / 10 실패(이 중 9건 수정) → 수정 파일 재실행 136 통과 / 1 실패(위 광고 타이머 건). PART B+C 테스트: 통과.
- **전체 `flutter test`는 실행하지 않았습니다.** 빌드도 하지 않았습니다.

## 6. 실기기에서 확인할 것

1. C02 Final: Mrs Bell 대화(이야기 → 귓속말)가 끝나면 시계 페이지로 넘어가는지, 'Hear It Again', 9:17 정답, 종소리.
2. C03 M3: 청소부 대화 → 발자국 순서 퍼즐(편지 봉투 없음) → Hear It Again.
3. C07 / C08 / C10 Final: 대화 후 페이지 위에 대사 카드가 나오는지, 퍼즐 아래 'Hear It Again', 정답 처리.
4. C09 M1·M2, C10 M1, C12 M1: 초상화 얼굴이 작은 화면에서도 잘 보이는지, 이름표.
5. C12 M2: Grey 대화 → 보드 봉투(Grey 줄 없음) → 퍼즐 → Reread Letter에 Grey 카드와 보드가 한 번씩 나오는지.
6. 대화 중 앱을 나갔다 들어오면 이어지는지, SKIP / TALK LOG.
7. Mrs Robin 초상화는 스케치만 참조해서 다른 초상화보다 선이 조금 옅습니다. 나란히 놓았을 때 괜찮은지 봐 주세요.
8. 이전 버전에서 C02 Final이나 C12 M2를 시작만 해 둔 저장으로 들어가면, 대화가 한 번 재생된 뒤 퍼즐로 갑니다(PART B C11 M3와 같은 규칙). C12 M2는 대화 뒤 보드 봉투를 한 번 더 엽니다.

## 7. 실패했거나 하지 않은 것, 그 이유

- Mrs Robin을 두 장 참조(스타일 + 스케치)로 요청하려 했으나, 견적이 $0.1797로 호출당 상한 $0.12를 넘어 도구가 보내지 않았습니다(비용 없음). 스케치 한 장만 참조하고 화풍은 프롬프트로 지정해 생성했습니다.
- `rig whoami` / `rig queue`(OpenRig 작업 등록)와 dev-review 핸드오프는 이번 실행의 허용 명령 밖이라 하지 않았습니다.
- 변경 전 코드에서 광고 타이머 실패를 재현하려면 git stash/checkout이 필요한데, 허용되지 않아 하지 않았습니다.
- 셸 파이프와 `awk`/`sed -E`로 로그를 정리하는 명령이 승인 대상이라, Grep 도구로 대신 확인했습니다. 테스트 로그와 미리보기 이미지는 git에서 제외되는 `content_pipeline/asset_work/s1_dialogue_part_c/scratch/`에 남겨 두었습니다.
- 전체 회귀 테스트, 빌드, commit, push는 지시대로 하지 않았습니다.
