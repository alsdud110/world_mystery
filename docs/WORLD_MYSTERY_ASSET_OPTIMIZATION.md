# World Mystery — 에셋 최적화 및 신규 시즌 자동 최적화 결과

> 작업일: 2026-11-02 · 기준 커밋: `b486d94` (main) · 커밋·푸시하지 않음
> 환경: Windows 11, Flutter 3.47.2, Dart(`package:image` 4.7.2), Google libwebp **cwebp 1.6.0**
> 외부 이미지 생성 API 호출: **0회** · 신규 이미지 생성: **없음** · 4개 시즌 콘텐츠·퍼즐·문장 변경: **없음**
> 도구 사용법: `tool/asset_optimizer/README.md` · 파이프라인: `tool/asset_pipeline/README.md` "The game's WebP"

---

## 0. 요약

| | 결과 |
|---|---|
| Flutter 번들 대상 에셋 | **1,025.4 MB → 313.8 MB (−69.4%)** |
| 이미지 변환 | 번들 PNG 469개 중 **468개 → WebP**, 1개(스플래시 로고) 의도적 PNG 유지, 실패 0 |
| 화질 정책 | 이미지 유형 8종별 단계(손실 → near-lossless → 무손실) + 자동 품질 게이트(PSNR·SSIM·알파 정확 일치). 퍼즐 핵심 이미지 100개는 near-lossless(26) 또는 무손실(74) |
| 해상도 | **변경 0개** (모든 좌표·측정값 유지) |
| 신규 시즌 | `.webp` 출력 경로면 시즌 파이프라인이 API PNG → 유형별 WebP → 검증 → `assets/` 복사를 자동 수행. PNG 원본은 앱·Git 밖 |
| 오디오 | 조사 후 **변경 없음**(효과음 7개 189 KB, 변환 이득 < 0.1%) |
| 테스트 | 시작 기준 3,456 통과 / 0 실패 → 작업 후 **3,484 통과 / 0 실패**, `flutter analyze` 이슈 0 |
| Android | profile AAB 365.1 MB, 기기별 다운로드 추정 약 348–352 MB → **Play 기본 모듈 한도(200 MB) 초과: 4개 시즌 동시 출시는 Play Asset Delivery 등 추가 조치 필요** (§E-1). 릴리스는 업로드 키 없음으로 미빌드 |
| iOS | 미검증(Windows) — §D-6 |

---

## A. 최적화 전후 비교

측정 기준: 번들 = `pubspec.yaml`의 `flutter: assets:`와 `fonts:`가 앱에 넣는 파일(폴더 항목은 Flutter 규칙대로 하위 폴더 제외). 프로젝트 = `assets/` 폴더 전체.

| 항목 | 최적화 전 | 최적화 후 | 감소율 |
|---|---|---|---|
| 프로젝트 전체 에셋 (`assets/` 폴더) | 1,043.1 MB (494개) | 331.6 MB (494개) | −68.2% |
| Flutter 번들 대상 에셋 | 1,025.4 MB (481개) | 313.8 MB (481개) | **−69.4%** |
| 공통(shared·branding·images, 90개) | 120.8 MB | 33.5 MB | −72.3% |
| London (81개) | 154.5 MB | 36.7 MB | −76.2% |
| Paris (165개) | 403.2 MB | 143.9 MB | −64.3% |
| Rome (66개) | 177.2 MB | 47.7 MB | −73.1% |
| New York (68개) | 168.9 MB | 51.2 MB | −69.7% |
| 오디오 (7개) | 0.2 MB | 0.2 MB | 0% (유지) |
| 폰트 (4개) | 0.6 MB | 0.6 MB | 0% |
| Android APK | 측정 불가(이전 기록: 2026-10-30 **debug** APK 954 MB — 같은 조건 아님) | profile fat APK 413.5 MB | 비교 불가 |
| Android AAB | 측정 불가(빌드 기록 없음) | profile AAB 365.1 MB (기기별 다운로드 추정 약 348–352 MB) | 비교 불가 |

- 프로젝트와 번들의 차이(약 18 MB): 번들에 들어가지 않는 브랜딩 원본(앱 아이콘 소스 등)과 `assets/images/case01/symbols/original/`(납품 원본 4개). 이번 작업은 **번들 대상만** 변환했다.
- 원본 PNG 468개(1,020.5 MB)는 `content_pipeline/asset_originals/`에 같은 경로로 보관(앱·Git 제외, `.gitignore`에 추가). 기존 PNG는 커밋 `b486d94`까지의 Git 기록에도 그대로 있다.

## B. 이미지 최적화 결과

### B-1. 수치

| 항목 | 값 |
|---|---|
| WebP로 변환 | 468개 (알파 포함 198개) |
| PNG 유지 | 1개: `assets/branding/splash_logo.png` (`flutter_native_splash`가 PNG를 읽음; 앱 내 `launch_reveal.dart`도 사용) |
| JPEG 유지 | 1개: `assets/shared/world_map/world_map_v5.jpg` (이미 손실 압축 — 재압축하지 않음) |
| 해상도 변경 | 0개 (`maxEdge` 0: 측정 좌표·`measuredOn`·장면 영역 보존) |
| 변환 실패 / 원본 유지 | 0개 |
| 참조 경로 갱신 | 99개 파일, 1,552개 경로 (+ 생성 코드 재생성, 동적 경로 1곳 수정) |

### B-2. 유형별 정책과 결과

| 유형 | 정책(시도 순서 → 마지막은 항상 무손실) | 품질 게이트 PSNR / SSIM | 파일 | 전 → 후 | 비율 |
|---|---|---|---|---|---|
| scene (장소·표지·지도·프롤로그) | q88 → q92 → near-lossless 60 | 30 / 0.975 | 62 | 199.8 → 31.7 MB | 15.9% |
| character (인물·탐정·How to Play) | q90 → q94 → NL60 | 32 / 0.985 | 50 | 138.9 → 30.4 MB | 21.9% |
| ui (뱃지·핀·잠금 그림) | q90 → q94 → NL60 | 32 / 0.985 | 36 | 43.5 → 8.1 MB | 18.7% |
| evidence (물건·사건 그림) | q92 → q95 → NL60 | 35 / 0.99 | 171 | 377.7 → 93.0 MB | 24.6% |
| document (편지·종이·공지) | q94 → NL60 | 37 / 0.993 | 23 | 36.6 → 17.4 MB | 47.6% |
| **puzzle** (정답을 가르는 미세한 차이) | **NL60만** | 42 / 0.997 | 100 | 220.4 → 125.7 MB | 57.0% |
| glyph (게임이 색을 입히는 단색 스탬프) | 무손실만 | 정확 일치 | 24 | 0.2 → 0.1 MB | 49.4% |
| exact (다른 그림에서 지워 만든 그림) | 무손실만 | 정확 일치 | 2 | 3.5 → 2.5 MB | 72.3% |

- 모든 단계에서 알파는 **정확히 동일**해야 통과(`-alpha_q 100`, 알파 최대 차이 0). near-lossless는 알파도 미세 조정하므로 투명 퍼즐 이미지는 무손실로 저장됐다(puzzle 100개 중 무손실 74, NL60 26).
- 실제 적용 단계 분포: scene q88 59·q92 3 / character q90 21·q94 21·NL 8 / ui q90 31·q94 4·무손실 1 / evidence q92 97·q95 49·NL 14·무손실 11 / document NL 12·무손실 11.

**퍼즐 이미지 판정 방법** (보수적 순서)
1. Rome·New York: 시즌 매니페스트의 `type`/`use` (예: `use: puzzle`인 물건 → puzzle, `document` → document).
2. London·Paris: `image_policy.json`의 `puzzleFiles` 42개(발자국, 톱니 수, 시계 바늘, 해시계, 용의자 스케치, 강 표식 a–d, 찢어진 봉투, 서명 대조, 캔버스 a–d 등) + 경로 규칙.
3. 자동 "쌍둥이" 검출: 같은 폴더·같은 크기의 evidence/document 이미지끼리 유사도(회색 위 휘도 SSIM, 128px) ≥ 0.8이면 구분 퍼즐 변형으로 보고 둘 다 puzzle (예: `royal_box_closed`/`_blank`, Paris Case 07 무대 배경 4종, NY `building_clock`/`_star`/`_spire`, `clock_back_*`).
4. 분류되지 않은 이미지는 가장 보수적인 puzzle이 기본값.

### B-3. 감소 상위 / 감소가 적은 파일

| 파일 | 정책 | 전 | 후 |
|---|---|---|---|
| seasons/season_03_rome/locations/map/rome_map.webp | scene q88 | 4,355 KB | 792 KB |
| seasons/season_01_london/locations/map/london_mystery.webp | scene q88 | 4,295 KB | 810 KB |
| seasons/season_02_paris/locations/map/paris_mystery.webp | scene q88 | 4,268 KB | 790 KB |
| seasons/season_03_rome/locations/pantheon_hall.webp | scene q88 | 4,007 KB | 702 KB |
| seasons/season_04_newyork/locations/map/newyork_map.webp | scene q88 | 4,045 KB | 763 KB |
| shared/evidence_docs/doc_log.webp | document 무손실 | 1,354 KB | 1,014 KB |
| seasons/season_01_london/special/royal_box_closed_blank.webp | puzzle 무손실 | 2,436 KB | 1,816 KB |

### B-4. 품질 검사

**자동(전 파일)**: 각 결과를 다시 읽어(컨테이너 전체 검사) 디코딩하고 원본 PNG와 비교 — 같은 크기, 알파 정확 일치, 유형별 PSNR·SSIM 통과한 것만 채택. 무손실은 가시 픽셀 완전 일치(PSNR 99) 확인. 기록: `tool/asset_optimizer/optimized_assets.json`(파일별 원본·결과 sha256, 유형, 설정, PSNR, SSIM, 인코더 버전, 정책 버전). `--verify`: 468개 모두 기록과 일치.

**Flutter 엔진 디코딩**: `test/asset_bundle_decode_test.dart`가 번들 이미지 전부를 앱이 쓰는 엔진 코덱(`ui.instantiateImageCodec`)으로 디코딩하고 크기를 확인(Windows 테스트 엔진 기준).

**육안 비교** (`dart run tool/asset_optimizer/compare_sheet.dart`, 전체 축소 + 가장 세밀한 영역 3배 확대, `qa/asset_compare/` — 앱·Git 밖)

| 이미지 | 유형/설정 | 육안 확인 |
|---|---|---|
| London 사건 지도 `london_mystery` | scene q88 (SSIM 0.996) | ✅ 차이 식별 불가 |
| Paris Case 03 `lift_log` (괘선 문서) | evidence q95 | ✅ 괘선·모서리 동일 |
| Paris Case 03 `tower_notice_board` | evidence q92 | ✅ 동일 |
| Paris Case 04 `river_mark_a` (퍼즐 표식) | puzzle NL60 (PSNR 46.5) | ✅ 물결·화살표 표식 동일 |
| 뱃지 `badge_map_master` (투명) | ui q90 | ✅ 가장자리·투명 동일 |
| 탐정 `girl/happy` (투명) | character q90 | ✅ 외곽선 동일 |
| Rome 프롤로그 `season3_prologue_night` | scene q88 (SSIM 0.980) | ✅ 3배 확대 시 하늘 수채 질감이 아주 약간 부드러움, 1:1에서는 식별 불가 |
| London Case 01 `big_ben_base_night` (2배, 사전 시험) | evidence q92 | ✅ 동일 |
| Paris Case 08 `sketch_morning_1_dark` (2배, 사전 시험 q92) | 최종은 puzzle 무손실 | ✅ (최종본은 무손실이라 동일) |
| Paris Case 08 `corner_1` (퍼즐 모퉁이 비교) | puzzle NL60 (PSNR 46.5) | ✅ 동일 |
| New York 사건 지도 `newyork_map` | scene q88 (SSIM 0.993) | ✅ 나침반 선·색 동일 |

시트는 만들었지만 **직접 보지 않은 것**(육안 검수 완료로 보지 않음): Paris·Rome 지도, London 표지, `covent_garden_market_hall`(q88), 그리고 `sketch_mr_green`·`building_clock`·`gear_brass_8_stamp`·`sundial_top`·`doc_map`(모두 무손실 → 가시 픽셀 동일이 자동 검증됨). 무손실이 아닌 나머지 약 350개는 자동 게이트만 통과했다.

**품질 문제로 정책을 바꾼 사례** (테스트가 잡아냄)
- 단색 스탬프 24개: 손실 WebP가 검정 잉크 RGB를 흔들 수 있어 `glyph`(무손실) 유형 신설 후 재생성 (`icon_upgrade_test`의 "잉크만" 검사).
- 크라운 카드와 코드 지운 카드: 둘이 잉크 밖에서 픽셀 동일해야 함 → `exact`(무손실) 유형으로 재생성 (`case01_decode_test`).
- 비교 코드 버그 1건: `package:image`의 `convert(alpha:)`가 기존 알파까지 덮어써 투명 이미지 비교가 틀렸던 것을 발견해 수정(시험 변환 단계, 실제 결과에는 영향 없음).

## C. 신규 시즌 자동 최적화 구조

### C-1. 흐름

```
plan-season: assets.manifest.json의 outputPath = assets/seasons/season_NN_<city>/…/name.webp
  → asset_pipeline --generate : OpenAI Images API (기존 그대로, PNG) → asset_work/<season>/raw/…/name.png   (앱·Git 밖, 보존)
  → _validate                 : PNG 검사 → 필요 시 크기 맞춤 → 유형 판정(매니페스트 type/use)
                                → ImageOptimizer(단계별 인코딩·디코딩·품질 게이트) → game/…/name.webp(.part → 검사 → 이동)
                                → pipeline_state.json: raw(PNG), game(WebP), optimized{kind, setting, quality, encoder, policyVersion}
  → season_factory 검토 시트(WebP 디코딩) → 측정(그리드 시트, measuredOn = WebP의 sha256)
  → asset_pipeline --apply    : game WebP를 assets/로 sha256 확인 복사, 매니페스트 generated, pubspec 폴더 등록
  → season_factory            : 시즌 용량 줄과 경고 출력 → 생성기(generate_season --target game) → analyze, 테스트
```

### C-2. 관련 코드

| 파일 | 변경 |
|---|---|
| `tool/asset_optimizer/*` (신규) | 정책, 인코더, 품질, 최적화기, 기존 에셋 일괄 변환·참조 재작성·검증·복원, 용량 리포트, 비교 시트 |
| `tool/asset_pipeline/asset_pipeline.dart` | `.webp` 출력의 최적화 단계(`_optimize`), 참조 이미지는 항상 PNG로 전송(`_referenceFile`), 게임 WebP 복구, `doctor --fix`의 이관(`migrated`)·WebP 채택 |
| `tool/asset_pipeline/asset_plan.dart` | raw 경로는 항상 `.png`, `optimized()` |
| `tool/asset_pipeline/asset_state.dart` | 파일 기록이 PNG/WebP 모두 검사, `optimized` 기록 |
| `tool/season_planner/asset_manifest.dart` | `outputPath`에 `.webp` 허용 |
| `tool/season_gen/play_check.dart` | 그림 크기 검사가 WebP도 읽음(이전엔 PNG가 아니면 **조용히 건너뜀**), 읽을 수 없는 파일은 `asset_unreadable` 오류 |
| `tool/season_factory/season_factory.dart`, `sheets.dart` | 최적화기 연결, reject 시 게임 사본도 보관, 적용 후 용량 줄, 시트가 WebP 디코딩 |
| `.claude/skills/create-season/SKILL.md`, `tool/season_planner/PLAYBOOK.md` | `.webp` 출력 경로, cwebp 전제, 용량 리포트 절차 |

### C-3. 원본 보존과 Git 용량

- 신규 시즌: API PNG는 `content_pipeline/asset_work/<season>/raw/`(기존과 같음, Git 제외 — 기존 백업 절차 `~/world_mystery_backups/` 유지). 앱에는 WebP만.
- 기존 4개 시즌: `content_pipeline/asset_originals/`(경로는 `image_policy.json`의 `originalsDir`로 설정 가능, Git 제외). **이 폴더는 백업 필요**(1,020.5 MB). 단, 이번에 변환한 PNG는 모두 이전 커밋에 있으므로 Git 기록에서도 복원 가능.
- Git 영향: 이번 변경을 커밋하면 WebP 약 312 MB가 새로 추가되고 PNG 468개는 삭제로 기록된다. 저장소 기록 크기는 **줄지 않고 약 0.3 GB 늘어난다**(기존 PNG가 기록에 남음). 줄이려면 기록 재작성(git filter-repo)이 필요하지만 공유 기록을 바꾸는 일이라 이번 작업 범위 밖(사용자 결정 필요). 앞으로의 시즌은 PNG를 커밋하지 않으므로 증가분은 WebP 크기뿐이다.

### C-4. 실패 처리와 반복 실행 안전성

| 상황 | 동작 |
|---|---|
| cwebp 없음 | 그림은 `generated`로 대기(`WAITING`, 사유 기록), `game/`·`assets/`에 아무것도 쓰지 않음, **API 재호출 없음**. cwebp 설치 후 재실행하면 WebP만 만든다 |
| 품질 미달 | 무손실로 내려가므로 사실상 없음. 인코더 오류 시 위와 같이 대기 |
| 손상된 원본 | 인코딩 전에 거부(`OptimizeFailure`), 기존 파이프라인 규칙대로 blocked/failed |
| 이미 최적화된 파일 | 기록(sha256)과 일치하면 건너뜀. WebP/JPEG 원본은 절대 다시 인코딩하지 않음(이중 손실 방지) |
| 중단 후 재실행 | `.part`로 쓰고 검사 후 이동. WebP는 썼는데 PNG 삭제 전 중단 → 재실행 시 인코딩 없이 마무리 |
| 기록 없는 WebP가 있음 | CONFLICT, 둘 다 그대로 |
| 경로 중복 등록 | `pubspec.yaml` 폴더는 한 번만 추가(기존 로직), 기록부는 경로 키 |
| 다른 기기의 오래된 기록 | `--doctor --fix`: 기록부가 "그 기기 그림에서 만든 WebP"라고 확인할 때만 이관, 아니면 CONFLICT |
| 되돌리기 | `optimize_assets.dart --restore <webp>`: 원본(sha256 확인)을 되살리고 WebP·기록 제거 |

정책 버전(`policyVersion`, 현재 2)과 원본 sha256이 기록되므로, 정책을 바꾼 뒤에는 `--restore` 후 재변환으로 원본에서 다시 만든다(손실 재압축 없음).

### C-5. Tokyo 등 새 시즌 적용 방법

1. (기기당 1회) cwebp 설치: Windows는 libwebp 1.6.0 zip을 `%USERPROFILE%\.world_mystery\`에, macOS는 `brew install webp`.
2. `plan-season`/`create-season` 그대로 사용 — 매니페스트 `outputPath`와 계획서의 그림 경로를 `.webp`로(PLAYBOOK에 명시).
3. `season_factory.dart run …` — 최적화·검증·등록·용량 출력이 자동.
4. 완료 후 `asset_size_report.dart`로 확인, 시즌 승인 시 `--write-baseline`.
5. 실수로 `.png` 출력 경로를 쓰면: 동작은 기존과 같고(최적화 안 됨) `test/asset_optimizer`의 "번들의 모든 그림은 최적화 기록이 있거나 의도적 유지" 테스트가 실패해 알려 준다.

### C-6. OpenAI Images API의 WebP 직접 출력 검토

API 요청은 `output_format: png`(`tool/ai_agents/image_manifest.dart`). API가 WebP를 직접 줄 수 있더라도 PNG 유지가 맞다고 판단했다: ① 참조 이미지(images/edits)와 기존 검사(`PngCheck`)가 PNG 기반, ② 원본을 무손실로 보존해야 정책 변경 시 재압축 가능, ③ 유형별 품질(퍼즐 무손실 등)을 우리 쪽에서 검증해야 함, ④ 비용 동일. 실제 API는 호출하지 않았다.

### C-7. 자동화 테스트 (요구 12항목 대응)

| # | 요구 | 테스트 |
|---|---|---|
| 1 | PNG → 최적화 이미지 | `asset_optimizer_test` "a background PNG becomes a smaller WebP…" |
| 2 | 투명도 보존 | "a transparent PNG keeps its alpha, every pixel of it" |
| 3 | 배경 해상도·형식 | "…within its kind's gate", "a kind with a maxEdge: shrunk…" |
| 4 | 퍼즐 보수 정책 | "a puzzle picture: near-lossless at most…" (픽셀당 변화 ≤ 8), 정책 테스트 |
| 5 | 손상 원본 | "a damaged PNG: refused before any encoding" |
| 6 | 재압축 방지 | "a picture already lossy (WebP, JPEG) is never encoded again", 일괄 재실행 시 인코딩 0회 |
| 7 | 재실행 중복 없음 | "--apply: … again: nothing new, nothing encoded", "a run cut short…" |
| 8 | 변환 실패 시 기존 유지 | "an encoder that fails: the PNG left as it was…", 파이프라인 "no optimizer here, or none good…" |
| 9 | 콘텐츠 경로 등록 | 파이프라인 "a .webp picture: made by its kind…, then copied by --apply" (매니페스트 generated) |
| 10 | Flutter 에셋 등록 | 같은 테스트의 `pubspec.yaml` 폴더 확인, `asset_bundle_decode_test`, `pubspec_assets_test` |
| 11 | 신규 시즌 용량 리포트 | "a new season shows as a new area, with its size…" |
| 12 | 기존 생성 테스트 회귀 없음 | `test/season_gen`, `test/season_planner`, `test/season_factory`, `test/sandbox`, `generated_seasons_test` 전체 |

추가: 다른 기기 기록 이관, WebP만 있는 참조 그림을 PNG로 전송, 게임 WebP 분실 복구, 참조 재작성 오탐 방지. 실제 cwebp가 필요한 테스트는 cwebp가 없는 기기에서 이유를 출력하고 건너뛴다(이 기기에서는 모두 실행).

## D. 출시 용량 관리

1. **현재 번들 대상 에셋**: 313.8 MB (이미지 309.0 MB WebP + 2.4 MB JPEG + 1.6 MB PNG, 폰트 0.6, 오디오 0.2).
2. **시즌별**: London 36.7 · Paris 143.9 · Rome 47.7 · New York 51.2 · 공통 33.5 MB. Paris가 큰 이유: 그림 165장(다른 시즌의 2배 이상), 퍼즐 이미지 비중이 높아 무손실/near-lossless가 많음.
3. **신규 시즌 예상 증가량**: Rome·NY 실측 기준 약 **45–55 MB/시즌**(그림 60–70장). 경고 기준(`image_policy.json` → `sizeWarnings`, 진단 전용): 번들 200 MB, 시즌 60 MB, 기준선 대비 시즌 증가 50 MB, 파일 1,200 KB. 기준선: `tool/asset_optimizer/size_baseline.json`(현재 값으로 기록).
4. **Android 빌드 크기**: profile APK 413.5 MB(fat), AAB 365.1 MB, 기기별 다운로드 추정 약 348–352 MB(§E-1).
5. **추가 최적화 후보** (모두 화질·기능 위험이 있어 이번에는 하지 않음)
   - 투명 퍼즐 이미지 74개가 무손실(약 100 MB): 알파 오차 1–2 단계를 허용하면 NL60으로 약 30–40% 추가 감소 가능 — 퍼즐 검수자 확인 필요.
   - 뱃지·탐정 표정 등 1254² 이미지를 실제 표시 크기(약 512px)로 축소 — 화면별 표시 크기·확대 여부 확인 필요.
   - Paris를 Play Asset Delivery(설치 시/요청 시 팩)로 분리.
   - Google Play 기본 모듈 한도(압축 다운로드 200 MB)는 현재 에셋만으로 넘는다(bundletool 추정 약 348 MB): **4개 시즌 동시 출시에는 Play Asset Delivery가 필요하다**(최종 판정은 Play Console 업로드).
6. **iOS 검증 필요 사항**: Flutter의 이미지 코덱은 iOS에서도 WebP(손실·무손실·알파)를 지원하지만 **실기기·시뮬레이터에서 확인하지 않았다**. macOS에서: `flutter build ipa` 후 앱 크기 확인(App Store Connect의 "App Store 파일 크기"), 시뮬레이터/실기기에서 각 시즌 표지·지도·사건 그림·투명 컷아웃 표시 확인, `flutter test test/asset_bundle_decode_test.dart` 실행(macOS 엔진).

## E. 검증 결과

| 항목 | 결과 |
|---|---|
| 작업 시작 기준 `flutter test`(전체) | **3,456 통과 / 0 실패** (836초) — 감사 문서의 실패 4건은 이미 해결된 상태였음을 확인 |
| 작업 후 `flutter test`(전체, 1차) | 3,458 통과 / 26 실패 → 원인: 테스트 안의 PNG 전용 판독(헤더 오프셋·서명·`.png` 개수, 24건)과 London 해시 스냅숏 2건. **에셋·게임 동작 문제는 없었음** |
| 작업 후 `flutter test`(전체, 최종) | **3,484 통과 / 0 실패 / 0 건너뜀** (492초). 신규 테스트 28개 포함 |
| `flutter analyze` | **No issues found** |
| 시즌 생성 도구 테스트 | `test/asset_pipeline`, `test/season_gen`, `test/season_planner`, `test/season_factory`, `test/sandbox`, `generated_seasons_test` — 전체 실행에 포함, 통과 |
| 신규 최적화 테스트 | `test/asset_optimizer/asset_optimizer_test.dart`(실제 cwebp 1.6.0으로 실행, 건너뜀 0), 파이프라인 WebP 테스트 6개 |
| 이미지 로딩(엔진 디코딩) | `test/asset_bundle_decode_test.dart`: 번들 이미지 470개 전부 디코딩·크기 일치 |
| 증거·퍼즐 회귀 | `icon_upgrade_test`(증거 194개, 스탬프 잉크 검사), `case01_*`(측정 크기, 지운 카드 픽셀 동일성), `paris_case01–12`, `london_upgrade_test`(스케치 연필색), `world_map_test`, `badge_medal_test` 등 — 통과 |
| 오디오 | 변경 없음. `audio_assets_test`, `sound_prototype_test` 전체 실행에 포함, 통과 |
| 생성 코드 일치 | Rome·NY 게임 코드와 샌드박스 2종을 생성기로 재생성. 이전과의 차이는 `.png→.webp`와 해시뿐(정규화 비교 차이 0줄) |
| 콘텐츠 불변 증명 | London 사건 해시: `.webp`를 `.png`로 되돌려 계산하면 기존 스냅숏 값과 **4개 모두 정확히 일치**(ep03, ep12; D5와 small pass 두 테스트). `lib/` 손편집 파일 변경 624줄은 모두 확장자(예외: 오래된 주석 예시 1줄), 계획서 변경 534줄은 경로·해시뿐 |
| 기록부 검증 | `optimize_assets.dart --verify`: 468개 모두 기록과 일치 |
| 파이프라인 기록 | 이 기기 Rome `asset_work`: `--doctor --fix`로 60개 이관(migrated)·1개 채택, 재검사 "all as recorded". New York은 이 기기에 기록 없음(60개 adopt 대기 — 이전과 같은 상태) |
| Android 빌드 | §E-1 |

**테스트를 바꾼 원칙**: 검사 강도는 유지하고 형식만 바꿨다 — PNG 헤더 오프셋 → 파일 전체 검사(`ImageFileCheck`), PNG 서명 → WebP 서명, `.png` 개수 → `.webp` 개수 + PNG 0개, 원본 바이트 크기 → 기록부의 원본 바이트·sha256. 기대값을 바꾼 것은 ① 해시 스냅숏(위 증명 후, 이전 값 주석 보존), ② Paris Case 05의 "알파 채널 있음" 3개(`clock_back_spring`, `clock_back_extra_wheel`, `writing_desk_blotter`: 원본이 RGBA였지만 모든 픽셀 알파 255 — WebP는 쓰지 않는 알파를 저장하지 않음, 화면 동일).

### E-1. Android 빌드

릴리스 빌드는 `android/app/build.gradle.kts`가 업로드 키(`android/key.properties`) 없이는 의도적으로 중단한다. 키를 임시로 만들면 첫 업로드 시 잘못된 키가 등록될 위험이 있어 만들지 않았다. 대신 같은 스크립트가 디버그 키로 허용하는 **profile 빌드**(AOT 컴파일, 에셋은 릴리스와 동일)로 측정했다.

| 산출물 | 크기 | 비고 |
|---|---|---|
| `flutter build apk --profile` | **413.5 MB** | 3개 ABI(arm, arm64, x86_64)를 모두 담은 fat APK. 사용자 다운로드 크기 아님 |
| `flutter build appbundle --profile` | **365.1 MB** | 업로드 파일 크기. 사용자 다운로드 크기 아님 |
| bundletool 1.18.3 `get-size total` (기기별 다운로드 추정) | arm64-v8a **347.6–351.6 MB** · armeabi-v7a 347.6–351.6 MB · x86_64 347.9–351.9 MB | Google Play가 기기별로 나눠 보내는 APK의 압축 다운로드 크기 추정(바이트 기준, MiB로는 약 332–335) |

- 비교: 최적화 전 같은 조건의 빌드는 측정하지 않았다(이전 기록은 2026-10-30 **debug** APK 954 MB — 빌드 종류가 달라 직접 비교 불가). 에셋만 보면 1,025 MB → 314 MB.
- profile은 릴리스보다 코드가 약간 크다(프로파일링 지원). 릴리스 다운로드는 이보다 조금 작을 것이나 **에셋이 대부분(약 90%)이라 큰 차이는 없을 것**(추정).
- **판단**: 4개 시즌을 기본 모듈에 모두 넣으면 Google Play의 기본 모듈 압축 다운로드 한도(200 MB)를 약 150 MB 넘는다. 출시 전 선택지: Play Asset Delivery(예: Rome·New York 또는 Paris를 install-time/fast-follow 에셋 팩으로), §D-5의 추가 압축 후보, 또는 시즌 단계 출시. 실제 한도 판정은 Play Console 업로드로 확인해야 한다.

### E-2. 미검증 항목

- **iOS 빌드·실행**: Windows라 불가. WebP 디코딩은 Flutter 엔진 공통 코덱이지만 iOS 실기기·시뮬레이터에서 확인하지 않았다(§D-6 절차).
- **Android 실기기**: 설치·표시·메모리 미확인. 릴리스 서명 빌드 미실행(업로드 키 없음).
- **Google Play 실제 다운로드 크기**: Play Console 기준 값은 미측정(§E-1의 bundletool 추정치만).
- **육안 검수**: §B-4 표의 11장만 직접 확인. 나머지는 자동 품질 게이트로만 검증.
- **macOS 기기의 `asset_work`**: 그 기기에서 `asset_pipeline.dart --manifest … --doctor --fix`를 한 번 실행해 기록을 이관해야 한다(이관 로직은 테스트로 검증).
- 원본 보관 폴더 `content_pipeline/asset_originals/`(1,020.5 MB)는 Git 밖이다: **별도 백업 필요**(이전 커밋에도 원본이 있어 복원 가능).
