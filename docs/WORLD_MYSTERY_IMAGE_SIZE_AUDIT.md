# World Mystery — 이미지 용량 전수조사 및 최적화 계획 (PART 5E-5)

- 조사일: 2026-11-03
- 기준 커밋: `fe99d3a` (AAB v0.1.0+1, release, upload key 서명)
- 성격: **조사·계획 전용.** 이 문서 작성 시점에 이미지·코드·pubspec·정책 파일은 바뀌지 않았다.
- 용도: 나중에 이미지 최적화(PART 5E-6)를 할 때 **이 문서를 기준으로 작업한다.** 작업 전에 "현재 상태 재측정"(§9)부터 해서 숫자가 그대로인지 확인한다. 시즌·이미지가 추가됐다면 표의 숫자는 낡은 것이다.

표기: **[측정]** 직접 잰 값 · **[추정]** 측정값에서 계산한 값 · **UNVERIFIED** 확인 못 함

---

## 1. 결론 요약

1. **현재 AAB는 Google Play 제한을 위반하지 않는다.** base module 제한은 **500MB**(압축 다운로드 기준). 200MB는 모바일 데이터 사용자에게 뜨는 *비차단* 경고창 기준일 뿐이다. (5E-4의 "200MB BLOCKER" 판단은 틀렸다.)
2. 기기별 다운로드 **342.0~346.2MB** [측정, bundletool]. 그중 이미지 328.2MB.
3. 용량의 원인은 해상도가 아니라 **압축 정책**이다. `image_policy.json`의 `puzzle` kind(기본 kind이자 twins 규칙 대상)가 PSNR 42 / SSIM 0.997 게이트 때문에 near-lossless·lossless로 떨어져, puzzle 100개가 131.8MB를 차지한다.
4. 해상도를 유지하고 kind별 lossy 품질만 조정해도 이미지 328.2 → **156.8MB** [측정], 다운로드 ≈171~175MB [추정].
5. 권장안: **A(품질만 조정) + character·ui만 선별 축소** → 다운로드 ≈158~162MB [추정]. 퍼즐·배경·좌표가 있는 그림의 해상도와 크롭·focus 정책은 건드리지 않는다.
6. 출시 기준 제안: **200MB 경고창 회피, 목표 180MB 이하.**

---

## 2. Google Play 크기 제한

출처: [Play Console 도움말 — Maximum size limits](https://support.google.com/googleplay/android-developer/answer/9859372?hl=en) (원문 HTML에서 직접 확인, 2026-11-03)

| 항목 | 제한 (압축 다운로드 크기) |
|---|---|
| Base module | 500MB |
| Feature module 1개 | 500MB |
| Asset pack 1개 | 1.5GB |
| 모든 모듈 + install-time asset pack 합계 | 4GB |
| on-demand + fast-follow asset pack 합계 | 30GB |
| 앱 전체 최대 | 34GB |
| 200MB 초과 | 모바일 데이터 사용자에게 설치를 막지 않는 경고창 |

- 크기는 업로드 시 Play Console이 계산한다. bundletool은 "비슷하지만 같지 않다".
- [Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery): install-time pack은 스토어 표시 크기에 포함, fast-follow·on-demand는 미포함. install-time pack은 base APK처럼 pack 크기의 2배 디스크 공간 필요.
- **UNVERIFIED:** Play Console 실제 업로드 시 계산값.

### bundletool 실측 [측정]

bundletool 1.18.3 `get-size total --dimensions=ABI,SCREEN_DENSITY`, 21개 조합:

- 최소 341.9MB (armeabi-v7a LDPI) ~ 최대 346.2MB (x86_64 XXXHDPI)
- arm64-v8a XXHDPI: 344.3MB
- 단위는 10진 MB. 이전에 보고한 "326~330MB"는 MiB 단위였다(같은 값).
- 이미지 외(네이티브 lib, dex, 리소스): 약 14~18MB [추정]
- AAB 파일 409.8MB 중 BUNDLE-METADATA(디버그 심볼·proguard map)가 약 105MB — 다운로드에는 포함되지 않음.

---

## 3. 이미지 인벤토리 [측정]

AAB `base/assets/flutter_assets` 안의 이미지 470개, 합계 328.2MB (WebP 468, JPG 1, PNG 1).

### 3.1 시즌별

| 시즌 | 파일 수 | 용량 | 무손실 계열* | 평균 bpp |
|---|---|---|---|---|
| Paris | 165 | **150.8MB** | 78개 / 104.4MB | 4.72 |
| New York | 68 | 53.7MB | 23개 / 29.1MB | 5.15 |
| Rome | 66 | 50.1MB | 25개 / 25.8MB | 5.06 |
| London | 81 | 38.4MB | 17개 / 14.2MB | 4.02 |
| Shared | 85 | 32.9MB | 39개 / 12.4MB | 3.09 |
| branding + images/case01 | 5 | 2.3MB | | |

\* lossless + near-lossless 60 (webpinfo는 둘 다 VP8L로 보고)

### 3.2 kind별 (ledger `tool/asset_optimizer/optimized_assets.json` 기준)

| kind | 수 | 현재 | A | A80 | B |
|---|---|---|---|---|---|
| puzzle | 100 | 131.8 | 38.8 | 24.5 | 38.8 |
| evidence | 171 | 97.5 | 54.1 | 43.3 | 39.2 |
| scene | 62 | 33.3 | 25.7 | 25.7 | 15.2 |
| character | 50 | 31.9 | 18.4 | 14.6 | 8.9 |
| document | 23 | 18.3 | 5.8 | 3.6 | 5.8 |
| ui | 36 | 8.5 | 7.0 | 5.9 | 3.4 |
| exact | 2 | 2.6 | 2.6 | 2.6 | 2.6 |
| glyph | 24 | 0.1 | 0.1 | 0.1 | 0.1 |
| (ledger 없음: world_map jpg, splash png) | 2 | 4.2 | 4.2 | 4.2 | 4.2 |

(단위 MB. A/A80/B는 §6 시나리오의 시험 인코딩 결과)

### 3.3 현재 인코딩 설정별

| setting | 수 | 용량 |
|---|---|---|
| lossless | 123 | 121.1MB |
| near_lossless 60 | 60 | 65.2MB |
| q92 sharp_yuv | 100 | 44.6MB |
| q88 sharp_yuv | 59 | 31.6MB |
| q95 sharp_yuv | 49 | 29.0MB |
| q90 sharp_yuv | 52 | 17.6MB |
| q94 sharp_yuv | 25 | 15.0MB |

### 3.4 Paris가 큰 이유

- puzzle kind 중 Paris가 79.3MB (lossless 43.1 + near-lossless 36.2).
- 한 퍼즐에 비슷한 그림 여러 장을 쓰는 세트가 많아 twins 규칙으로 puzzle 처리됨: canvas a–d, backdrop ×4, corner ×3, sketch_morning ×3, river_mark a–d 등.
- lossy 파일도 q88~95라서 bpp 중앙값 2.9 (q80이면 보통 1 안팎).

### 3.5 기타

- 앱 코드(lib/)에서 참조하지 않는 번들 이미지 2개, 0.85MB:
  `assets/seasons/season_01_london/locations/british_museum/british_museum_gallery.webp`,
  `assets/seasons/season_02_paris/cases/case_11/signature_old_a.webp`
  (파일명 기준 검색. 삭제 전 재확인 필요)
- 내용이 완전히 같은 중복 파일: 0개.
- 해상도 분포: 1536×1024 153개, 1254×1254 63개, 1024×1024 57개, 1024×1536 41개, 512² 30개, 256² 26개.
- 표시 방식: BoxFit fill 116 / scaleDown 106 / contain 58 / cover 45 / fitWidth 1. 확대 가능: ZoomPicture 최대 4배(`zoom_picture.dart`), SceneExplore 최대 3배(`scene_explore.dart`).

---

## 4. 용량 상위 TOP 30 [측정]

A열: 시나리오 A 시험 인코딩 결과. SSIM/PSNR: 원본과 A 결과를 각각 #808080 위에 합성해 ImageMagick으로 비교.

| # | 파일 (assets/seasons/… 생략) | MB | 해상도 | 현재 | A MB | SSIM / PSNR | 사용처 |
|---|---|---|---|---|---|---|---|
| 1 | shared/world_map/world_map_v5.jpg | 2.54 | 5949×2379 | JPG q87 | 유지 | – | 월드맵(확대) |
| 2 | paris case_08/sketch_morning_1_dark | 2.51 | 1536×1024 | lossless, α | 0.79 | .993 / 39.7 | C08 스케치 비교 |
| 3 | london case_01/buckingham_palace_crown_card | 2.49 | 1536×1024 | exact | 유지 | – | C01 해독(짝과 픽셀 동일해야 함) |
| 4 | newyork case_10/building_spire | 2.23 | 1536×1024 | lossless | 0.56 | .981 / 36.9 | C10 건물 고르기 |
| 5 | newyork case_10/building_clock | 2.23 | 1536×1024 | lossless | 0.56 | .983 / 37.3 | C10 |
| 6 | london case_03/great_court_footprints | 2.22 | 1536×1024 | lossless | 0.58 | .988 / 39.2 | C03 발자국 추적 |
| 7 | paris case_07/backdrop_clock_red | 2.15 | 1536×1024 | lossless, α | 0.63 | .989 / 40.2 | C07 라이트보드 |
| 8 | paris case_08/sketch_morning_3_light | 2.10 | 1536×1024 | lossless, α | 0.55 | .993 / 40.4 | C08 |
| 9 | paris case_07/backdrop_tower_red | 2.07 | 1536×1024 | lossless, α | 0.51 | .990 / 40.2 | C07 |
| 10 | paris case_07/backdrop_clock_blue | 2.00 | 1536×1024 | lossless, α | 0.49 | .990 / 40.0 | C07 |
| 11 | paris case_08/sketch_morning_2_bag | 1.93 | 1536×1024 | lossless, α | 0.51 | .995 / 41.2 | C08 |
| 12 | paris case_07/backdrop_lamp_red | 1.91 | 1536×1024 | lossless, α | 0.45 | .990 / 40.4 | C07 |
| 13 | paris case_02/montmartre_street_real | 1.87 | 1536×1024 | near-lossless | 0.79 | .987 / 35.7 | C02 실사·그림 비교 |
| 14 | london special/royal_box_closed | 1.87 | 1659×948 | lossless, α | 0.48 | .986 / 37.4 | C01 로열 박스 |
| 15 | paris case_02/montmartre_street_painted | 1.86 | 1536×1024 | near-lossless | 0.79 | .987 / 35.8 | C02 |
| 16 | london special/royal_box_closed_blank | 1.86 | 1659×948 | lossless, α | 0.49 | .985 / 37.3 | C01 |
| 17 | paris case_07/stage_base | 1.84 | 1536×1024 | lossless | 0.36 | .985 / 40.3 | C07 무대 |
| 18 | paris case_10/sundial_top | 1.84 | 1254×1254 | lossless, α | 0.59 | .992 / 39.7 | C10 해시계(각도를 픽셀로 측정) |
| 19 | paris case_08/corner_2 | 1.83 | 1536×1024 | near-lossless | 0.79 | .990 / 36.8 | C08 모퉁이 |
| 20 | paris case_08/corner_3 | 1.83 | 1536×1024 | near-lossless | 0.78 | .990 / 37.0 | C08 |
| 21 | paris case_08/corner_1 | 1.79 | 1536×1024 | near-lossless | 0.76 | .990 / 37.4 | C08 |
| 22 | paris case_07/programme_page_blank | 1.76 | 1024×1536 | lossless, α | 0.24 | .977 / 40.1 | C07 문서 |
| 23 | paris case_07/stage_foot | 1.74 | 1536×1024 | lossless | 0.32 | .988 / 41.4 | C07 |
| 24 | paris case_02/canvas_a | 1.71 | 1536×1024 | near-lossless | 0.69 | .988 / 37.2 | C02 그림 고르기 |
| 25 | branding/splash_logo.png | 1.70 | 1152×1152 | PNG(keep) | 유지 | – | 실행 화면 |
| 26 | paris case_02/canvas_c | 1.70 | 1536×1024 | near-lossless | 0.66 | .989 / 37.4 | C02 |
| 27 | paris case_02/canvas_b | 1.70 | 1536×1024 | near-lossless | 0.66 | .988 / 37.3 | C02 |
| 28 | paris case_07/light_table_on | 1.69 | 1536×1024 | lossless | 0.31 | .985 / 41.2 | C07 |
| 29 | paris case_07/light_table_off | 1.68 | 1536×1024 | lossless | 0.33 | .985 / 41.7 | C07 |
| 30 | paris case_02/canvas_d | 1.66 | 1536×1024 | near-lossless | 0.63 | .990 / 38.0 | C02 |

TOP 30 권장 해상도: **전부 현재 유지** (확대되는 퍼즐 그림, 파일 픽셀 좌표 의존).

---

## 5. 용도별 권장 해상도

| kind | 현재 | 권장 | 근거 |
|---|---|---|---|
| puzzle / document | 1536×1024, 1254² 등 | **유지** | 3~4배 확대, 핫스팟·각도·글자가 파일 픽셀 좌표 기준 |
| evidence | 1536×1024 등 | 유지 (좌표 없는 것만 개별 검토) | 상당수가 좌표·확대 사용 |
| scene / backdrop | 1536×1024 | **유지** | 세로 화면 cover 시 이미 2배 이상 확대됨. `BackdropArt` focus 표가 픽셀 기준 |
| character | 1024×1536, 1122×1402 등 | 긴 변 1024 | 표시 크기 대비 여유. 좌표 의존 여부 UNVERIFIED |
| ui / badges | 1254² | 긴 변 512~768 | 작은 메달로만 표시 |
| glyph / exact / world_map / splash | – | 유지 | 앱이 색을 입힘 / 픽셀 동일 / 확대 지도 / 네이티브 도구가 PNG 요구 |

### 해상도 변경 시 코드 제약 [측정]

- `test/helpers.dart:184`, `test/story_backdrop_test.dart:83`: 파일 픽셀 크기 == 선언된 `ScenePixels`를 검사.
- `lib/data` 아래 71개 파일에 픽셀 좌표(ScenePixels, Rect 등)가 있음. 예: `season2_case08_scenes.dart`의 `area: Rect.fromLTRB(60, 330, 500, 640)`, `BackdropArt`의 `_wpx(...)`.
- `star_records.dart` 등 위젯이 `pixels.width/height`로 레이아웃 계산.
- → 해상도를 줄이면 선언과 좌표를 함께 고치거나, ScenePixels를 "설계 좌표"로 분리하는 구조 변경이 필요하다. 비율은 정확히 유지해야 한다(1536×1024 → 1152×768 등).

---

## 6. 시나리오 비교

시험 인코딩 조건: cwebp 1.6.0, `-m 4 -sharp_yuv -alpha_q 100 -metadata none`, 소스는 현재 번들 WebP. 결과가 현재보다 크면 현재 파일 유지로 계산. glyph·exact·jpg·png 제외.
다운로드 = 이미지 합계 + 이미지 외 14~18MB.

| | 현재 | **A** 품질만 | A80 | **B** A+해상도 | C PAD |
|---|---|---|---|---|---|
| 설정 | – | puzzle·document q90, evidence·character·ui q85, scene q80 | 전부 q80 | A + 긴 변 cap: scene·evidence 1280, character 1024, ui 768 | 이미지 그대로, 시즌별 pack |
| 이미지 합계 | 328.2 [측정] | **156.8** [측정] | 124.5 [측정] | **118.3** [측정] | 328.2 |
| Paris | 150.8 | 61.7 | 46.2 | 51.6 | – |
| London | 38.4 | 23.7 | 20.2 | 17.9 | – |
| Rome | 50.1 | 24.9 | 19.8 | 16.7 | – |
| New York | 53.7 | 24.0 | 18.7 | 16.6 | – |
| Shared | 32.9 | 20.5 | 17.5 | 13.6 | – |
| 기기별 다운로드 | 342~346 [측정] | ≈171~175 [추정] | ≈139~143 [추정] | ≈132~136 [추정] | 총량 동일, 첫 설치 ≈90 [추정] |
| AAB | 409.8 | ≈238 [추정] | ≈206 [추정] | ≈200 [추정] | ≈410 |
| 화질 | – | SSIM 최소 .967 / p5 .977 / 중앙 .988, PSNR 최소 31.6 / p5 36.7 / 중앙 39.5 (442개) | 더 낮음 | 표시 배율에 따라 흐려짐 위험 | 영향 없음 |
| Android 난이도 | – | 낮음 | 낮음 | 중~상 (좌표·테스트 대량 수정) | 상 |
| iOS | – | 동일 절감 | 동일 | 동일 | 효과 없음 |
| 오프라인 | – | 영향 없음 | 영향 없음 | 영향 없음 | fast-follow·on-demand는 네트워크 필요 |
| 유지보수 | – | 낮음 | 낮음 | 중 | 높음 |

메모:
- A의 품질은 현재 정책의 puzzle 게이트(PSNR 42 / SSIM 0.997)를 통과하지 못한다 → 정책 v3에서 게이트 자체를 조정해야 한다.
- cwebp `-print_ssim`은 투명 영역 RGB 변화 때문에 알파 이미지에서 낮게 나온다(최저 .86). 반드시 배경 합성 후 비교할 것.
- 최종 인코딩은 `-m 6`(정책 기본)이라 위 수치보다 약간 작아질 것 [추정].
- C(PAD): Flutter `flutter_assets`를 asset pack으로 옮기는 방법은 UNVERIFIED. Flutter 공식 기능은 Android 전용 deferred components(feature module). 500MB 제한이 확인됐으므로 지금은 불필요.

---

## 7. 목표별 필요 절감량

기준: 최대 조합 346.2MB [측정]

| 목표 | 필요 절감 | A | B | 권장안 |
|---|---|---|---|---|
| 200MB 미만 (경고창 회피) | ≥146.2MB | ✅ 171.4 | ✅ 209.9 | ✅ |
| 180MB 이하 | ≥166.2MB | ✅ 여유 ~5MB | ✅ | ✅ 여유 ~18MB |
| 150MB 이하 | ≥196.2MB | ❌ | ✅ | ❌ |

권장 출시 기준: **180MB 이하** (200MB 경고창 회피 + 여유).

---

## 8. 화질 보호 대상

아래는 **q92~95 이상(또는 near-lossless 유지) + `compare_sheet` 3배 확대 비교로 사람이 확인**한다. 세트는 반드시 같은 설정으로 인코딩해 압축 흔적이 가짜 "차이"가 되지 않게 한다.

- 차이를 찾는 세트
  - Paris: `case_02/canvas_a~d`, `case_02/montmartre_street_real/painted`, `case_08/sketch_morning_1~3`, `case_08/corner_1~3`, `case_04/river_mark_a~d`, `case_11/signature_old_b`, `clock_model_t1~t3`
  - New York: `case_10/building_*`
- 픽셀 좌표·기하: `paris case_10/sundial_top`, `london case_03/great_court_footprints`, `london special/royal_box_closed(_blank)`, `paris case_05/tracing_sheet`
- 글자 있는 문서: `letter_paper_open`, `programme_page_blank`, `office_record_blank`, `victors_paper`, `trial_log_open`, `cue_card_blank`
- 손대지 않음: `buckingham_palace_crown_card` + `_code_clear` (exact), `shared/symbols` glyph 24개, `world_map_v5.jpg`, `branding/splash_logo.png`
- 랜드마크 배경·시즌 커버: 해상도 유지, q85 이상. `season4_cover_newyork`(SSIM .967, 최저값) 확인 필요.

---

## 9. PART 5E-6 작업 계획 (실제 최적화)

권장안: **A + character·ui 선별 축소** → 이미지 ≈144MB, 다운로드 ≈158~162MB [추정]. 보호 세트를 q92~95로 올려도 180MB 이하 예상 (미측정).

각 단계는 사용자 승인 후 진행한다.

0. **현재 상태 재측정** — 이 문서 이후 이미지·시즌이 늘었는지 확인. AAB 재빌드 후 bundletool 측정(§10).
1. **정책 v3** — `tool/asset_optimizer/image_policy.json`: kind별 lossy 단계 추가, puzzle 게이트 현실화, §8 보호 목록은 높은 품질 고정, glyph·exact 유지. `policyVersion` 3, notes 갱신. 관련 테스트 `test/asset_optimizer/asset_optimizer_test.dart`.
2. **원본 확보** — `content_pipeline/asset_originals/`는 없음(.gitignore 대상).
   - lossless 파일 = 원본과 동일.
   - 커밋 `0b5b429` 이전 PNG는 git 이력에서 복원 가능(ledger의 source sha256으로 대조).
   - New York·Rome 일부 원본 존재 여부 UNVERIFIED. 없으면 lossy 재인코딩(세대 손실) 감수.
3. **재인코딩** — 기존 `optimize_assets.dart` 파이프라인 사용, `-m 6`, ledger `optimized_assets.json` 갱신.
4. **검수** — 보호 세트 `compare_sheet` 3배 확대 확인, iPhone·Android 실기기 각 1대.
5. **미사용 2개(0.85MB)** — 재확인 후 제거 여부 결정.
6. **character·ui 축소** — 좌표 의존 여부 확인 후 별도 단계. ScenePixels 선언·테스트 함께 수정. 비율 정확히 유지.
7. **검증** — `flutter analyze`, `test/asset_bundle_decode_test.dart`, `test/story_backdrop_test.dart`, `test/scene_place_test.dart`, 시즌별 case 테스트, 이후 AAB 재빌드 + bundletool 재측정. 공유 에셋 대량 변경이므로 전체 `flutter test` 1회 권장.

지켜야 할 것: 크롭·focus 정책(`BackdropArt`) 변경 금지, 퍼즐 단서 보존, 광고 설정 무관.

남은 위험:
- 시즌 하나 추가될 때마다 최적화 후 약 25~40MB 증가 [추정]. 시즌 5 추가 시 다시 200MB 근처 → 그때 PAD 재검토.
- iOS IPA 크기 미측정.

---

## 10. 재현 방법

모든 임시 파일은 저장소 밖(scratch 디렉터리)에 둔다.

```sh
# AAB 안의 에셋 목록
unzip -l build/app/outputs/bundle/release/app-release.aab | grep flutter_assets

# 파일별 해상도·알파·포맷
webpinfo <file.webp>        # Canvas size, ALPH, Lossy/Lossless

# 시험 인코딩 (시나리오 A의 한 줄 예)
cwebp -q 90 -m 4 -sharp_yuv -alpha_q 100 -metadata none <in.webp> -o <scratch>/out.webp

# 화질 비교 (알파 이미지는 반드시 합성 후)
magick in.webp  -background '#808080' -flatten o.png
magick out.webp -background '#808080' -flatten n.png
magick compare -metric SSIM o.png n.png null:   # 괄호 안 값 = 1-SSIM
magick compare -metric PSNR o.png n.png null:
```

bundletool (Gradle 캐시 jar 사용, Java는 Android Studio jbr):

```sh
J="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java"
# classpath: bundletool-1.18.3.jar, guava-33.3.1-jre, failureaccess, protobuf-java-3.25.5,
#            aapt2-proto, jakarta.inject-api, javax.inject, dagger, auto-value-annotations, jose4j, gson
#            (모두 ~/.gradle/caches/modules-2/files-2.1 아래)
"$J" -cp "$CP" com.android.tools.build.bundletool.BundleToolMain build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab --output=<scratch>/app.apks \
  --aapt2=$HOME/Library/Android/sdk/build-tools/36.0.0/aapt2
"$J" -cp "$CP" com.android.tools.build.bundletool.BundleToolMain get-size total \
  --apks=<scratch>/app.apks --dimensions=ABI,SCREEN_DENSITY
```

## 출처

- [Google Play — Maximum size limits](https://support.google.com/googleplay/android-developer/answer/9859372?hl=en)
- [Android Developers — Play Asset Delivery](https://developer.android.com/guide/playcore/asset-delivery)
- 기존 최적화 기록: `docs/WORLD_MYSTERY_ASSET_OPTIMIZATION.md`, `tool/asset_optimizer/README.md`
