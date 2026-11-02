# World Mystery — 정식 출시 준비도 감사

> 감사일: 2026-11-02 · 기준 커밋: `acf8a25` (main, 작업 트리 깨끗함)
> 방식: **읽기 전용.** 코드·에셋·설정·테스트는 바꾸지 않았다. 실행한 것은 `flutter test`(전체)와 `flutter analyze`뿐이며 로그는 프로젝트 밖(임시 폴더)에 남겼다.
> 환경: Windows 11, Flutter 3.47.2 stable. **iOS 빌드·시뮬레이터·실기기, Android 실기기, 릴리스 빌드는 이 감사에서 실행하지 못했다.**
> 표기: ✅ 근거로 확인 · ⚠️ 일부 확인/위험 · ❌ 미비 · 🔍 **별도 확인 필요**(코드로 판정 불가: 스토어 계정·콘솔·실기기·법무)

---

## 0. 요약

| 항목 | 결과 |
|---|---|
| **전체 출시 준비도** | **46 / 100** |
| **현재 위치** | **7단계 중 3단계** (핵심 기능·콘텐츠·자동 테스트 기반은 갖춤. 실기기 QA부터 사실상 시작 전) |
| **가장 큰 차단 요인** | 앱 번들 에셋 **약 1.0 GB**(Google Play 기본 다운로드 한도 초과), 릴리스 서명 키 없음, 개인정보처리방침·스토어 정책 신고 미작성, 실기기 QA 기록 없음 |
| **1인 개발자 기준 남은 기간(추정)** | 런던 단독: **약 4–6주** · 4개 시즌 동시: **약 8–12주** |
| **권장 경로** | **A안(런던 먼저)** — 단, 이미지 압축은 어느 안이든 필수 |
| Android | 빌드 설정은 출시형(업로드 키 강제, targetSdk 36). **키·용량·정책 신고**가 막혀 있음 |
| iOS | 번들 ID·팀·아이콘·세로 고정 설정됨. **릴리스 아카이브·TestFlight 미검증**, iPadOS 26 창 크기 대응 미결 |

---

## 1. 점수 산정 기준과 가중치

| # | 단계 | 가중치 | 무엇을 보는가 |
|---|---|---|---|
| 1 | 핵심 기능 완성도 | 15% | 게임 루프, 저장·복구, 난이도, 시즌 잠금/해제, 오프라인 동작이 코드로 존재하고 테스트로 실행되는가 |
| 2 | 콘텐츠 완성도 | 15% | 4개 시즌 × 12사건 × 3난이도가 들어 있고, 사람이 검수했는가 |
| 3 | 기능 안정성 | 15% | 테스트 결과, 크래시 방어, 저장 손실 방어, 메모리·용량 |
| 4 | 실기기 QA 준비도 | 15% | 실제 기기(iPhone/iPad/Android)에서 돌려 본 기록, 플레이테스트 결과 |
| 5 | 보안·개인정보·스토어 정책 | 15% | 데이터 수집, 아동 대상 정책(Families/Kids), 개인정보처리방침, 등급 |
| 6 | 스토어 등록·배포 준비 | 15% | 서명, 버전, 릴리스 빌드, 스토어 메타데이터, CI |
| 7 | 출시 최종 검증 | 10% | 내부/비공개 테스트 트랙, TestFlight, 심사 대응 |

**채점 원칙**
- 코드·설정·테스트·문서에서 **직접 확인한 것만** 점수로 인정했다.
- 파일이 있다는 것만으로는 동작한다고 보지 않았다. (예: `integration_test/`가 있어도 실행 기록이 없으므로 실기기 QA 점수에 넣지 않음)
- 확인하지 못한 항목은 0점으로 처리하고 🔍로 표시했다.

**전체 점수 계산**

| # | 점수 | 가중치 | 반영 |
|---|---|---|---|
| 1 | 85 | 15% | 12.75 |
| 2 | 68 | 15% | 10.20 |
| 3 | 60 | 15% | 9.00 |
| 4 | 20 | 15% | 3.00 |
| 5 | 45 | 15% | 6.75 |
| 6 | 20 | 15% | 3.00 |
| 7 | 5 | 10% | 0.50 |
| | | **합계** | **45.2 → 46** (반올림. 전체 테스트 99.9% 통과·analyze 0건을 3단계에 반영한 값) |

---

## 2. 단계별 평가와 근거

### 2-1. 핵심 기능 완성도 — 85 / 100

| 기능 | 상태 | 근거 |
|---|---|---|
| 게임 흐름 (타이틀→탐정 생성→How to Play→시즌→사건→미션→최종→보고서) | ✅ | `lib/core/router/app_router.dart`의 라우트·가드, `test/full_playthrough_test.dart`, `test/season_playthrough_test.dart`, `test/season12_controller_playthrough_test.dart` |
| 4개 시즌 | ✅ 코드상 공개 | `lib/data/mock/season_catalog.dart:587` `SeasonCatalog.all = [season1, season2, ...generatedSeasons]`; Paris `released: true`(같은 파일 466행); Rome/NY는 `lib/data/generated/generated_seasons.g.dart`로 등록(기본값 `released = true`). 사진 대기 사건 없음(`season2AwaitingArtJson = {}`) |
| Rookie / Junior / Master | ✅ | 4개 시즌 모두 12사건 × 3난이도 `writtenLevels` 표시(`season1_difficulty.dart:111`, `season2_difficulty.dart:104`, `s3_rome_levels.g.dart:79`, `s4_newyork_levels.g.dart:79`); `test/difficulty_*_test.dart` 다수 |
| 회원가입·로그인 | **해당 없음(의도적 제거)** | `docs/OFFLINE_SINGLE_DETECTIVE.md` §6: 계정·Firebase·동기화 완전 제거. `lib/`에 인증·네트워크 코드 없음(Firebase/HTTP/로그인 검색 결과 0건, 게임 텍스트 제외) |
| 게스트 플레이 | ✅ (유일한 방식) | 기기당 탐정 1명(`ProfileStore`, `lib/data/repositories/profile_store.dart`) |
| 진행 저장·복구 | ✅ | `SaveJournal`(여러 키 원자적 저장, `lib/data/repositories/save_journal.dart`), 손상 JSON은 새로 시작(`progress_repository.dart:120-126`), 타입 방어 파싱(`game_progress.dart:230~`), 이전 데이터 이전(`legacy_migrator.dart`); 테스트 `resume_and_guard_test.dart`, `profile_migration_test.dart`, `difficulty_persistence_test.dart` |
| 오프라인 플레이 | ✅ (코드상) | 의존성은 riverpod·go_router·shared_preferences·audioplayers뿐(`pubspec.yaml`), 폰트 번들, `android/app/src/main/AndroidManifest.xml`에 INTERNET 권한 없음(플러그인 병합 결과는 🔍 릴리스 빌드에서 확인). 🔍 비행기 모드 실기기 확인은 기록 없음 |
| Android 뒤로 가기 | ✅ (코드·테스트) | `BackTo`(`lib/widgets/back_to.dart`, `PopScope`)로 `go`로 연 화면에서 앱이 닫히지 않게 처리; `test/back_navigation_test.dart` |
| iOS 뒤로 가기 | ✅ (코드·테스트) | 자체 가장자리 스와이프 `lib/widgets/edge_swipe_back.dart`; `test/edge_swipe_back_test.dart`; `docs/IOS_USABILITY_PROGRESS.md` §1–2 |
| 광고(보상형) | ⚠️ 미탑재(안전) | `rewarded_ad_service.dart`: 릴리스는 `DisabledRewardedAdGateway`. 디버그만 가짜 광고 |
| 인앱 결제 | 없음 | 결제 SDK 없음. `docs/ECONOMY_EXTENSIONS.md`는 계획뿐(“정책 확인 전 출시 금지” 명시) |

감점: 전역 오류 처리 없음(`main.dart`에 `FlutterError.onError`/`runZonedGuarded`/`ErrorWidget.builder` 없음), 실기기에서 확인된 흐름이 아님(4단계에서 별도 반영), 디버그 전용 코인 획득 경로의 UI 노출 여부는 릴리스 빌드에서 확인 필요.

### 2-2. 콘텐츠 완성도 — 68 / 100

| 시즌 | 사건 | 그림 | 사람 검수 근거 | 평가 |
|---|---|---|---|---|
| S1 London | 12 | 81장 | 게임성 감사·개선(`docs/LONDON_GAMEPLAY_AUDIT.md`, `LONDON_GAMEPLAY_UPGRADE_PROGRESS.md`), 난이도 리뷰는 **Case 01–03만**(`docs/difficulty_reviews/LONDON_CASE_01_03.md`) | 가장 성숙 |
| S2 Paris | 12 | 165장 | 스토리 바이블·사건별 명세·최종 스토리 리뷰(`SEASON2_*`), 난이도 리뷰 Case 01–12 전부 | 성숙 |
| S3 Rome | 12 | 66장 | 시즌 생성기 산출(`tool/season_gen`), 커밋 2026-10-30. **사람의 난이도·문장 리뷰 문서 없음** | 검수 부족 |
| S4 New York | 12 | 68장 | 시즌 생성기로 자동 생성. 커밋 메시지 “**플레이 가능. 아직 승인은 안함**”(2026-10-30). 리뷰 문서 없음 | **미승인 상태로 공개 설정** |

- 어린이 플레이테스트: **한 번도 하지 않음** — `WORLD_MYSTERY_LEARNING_PLAYTEST.md` 상단 “실제 플레이테스트는 아직 한 번도 하지 않았다”, `docs/playtest/SEASON1_PLAYTEST_CHECKLIST.md`는 빈 양식.
- 아바타 이미지: `docs/OFFLINE_SINGLE_DETECTIVE.md` §7은 “Custom Asset Required”로 남아 있으나 실제로는 `assets/shared/detectives/avatars/detective_boy.png`, `detective_girl.png`가 있고 `pubspec.yaml`에 등록됨 → 문서가 오래된 것.
- 문서 불일치: `season_catalog.dart:458`의 주석은 Paris를 “not released”라 하지만 값은 `released: true`. 기능 영향은 없으나 출시 판단 시 혼동 요인.

### 2-3. 기능 안정성 — 60 / 100

**테스트 결과** — 전체 3,452 통과 / 4 실패, `flutter analyze` 이슈 0(§7). 위젯 테스트 범위는 넓다(플레이스루, 저장, 뒤로 가기, 작은 화면, 글자 확대, 에셋 등록 일치). 단 모두 Windows 호스트의 위젯 테스트이며 실기기 동작을 보증하지 않는다.

**강점**
- 저장: 원자적 저장(`SaveJournal`), 손상 데이터 복구, 타입 방어 파싱, 레거시 이전은 “복사→재확인→검증” 후에만 기록.
- 메모리: 화면 크기로 디코딩하는 `DisplaySizedImage`(`lib/widgets/display_sized_image.dart`, `cacheWidth` 사용 28개 파일), 5949×2379 세계지도도 `cacheWidth`로 줄여 디코딩(`world_map_screen.dart:498`).
- 운영자 도구는 `kDebugMode || LM_PLAYTEST`일 때만(`game_providers.dart:640`).

**위험**
- ❌ **번들 에셋 약 1,025 MB / 477개 파일**(`pubspec.yaml`이 등록한 파일 합계, 직접 측정). 시즌별: Paris 403 MB, Rome 177 MB, New York 169 MB, London 155 MB, 공용 약 120 MB. 기존 디버그 APK가 **954 MB**(`build/app/outputs/flutter-apk/app-debug.apk`, 2026-10-30). 장면 PNG 하나가 1536×1024에 약 3.3 MB(예: `season_01_london/cases/case_01/big_ben_base_night.png`). 2 MB 넘는 PNG가 318개. → 설치 용량·다운로드·저장공간 부족 기기에서의 설치 실패, 스토어 한도 문제(6단계).
- ⚠️ 전역 오류 처리기·크래시 리포팅 없음. 위젯 예외 시 릴리스에서는 회색 화면, 원인 수집 수단은 스토어 콘솔의 기본 크래시 통계뿐.
- ⚠️ `SaveJournal.commit`은 `setString` 결과를 기다리지 않는다(동기 메모리 반영 후 플랫폼 기록은 비동기). 순서는 플랫폼 채널에서 유지되는 구조이나, 앱 강제 종료 시 마지막 저장의 실기기 동작은 🔍 미검증(`integration_test/offline_detective_test.dart`가 이를 위한 테스트이지만 실행 기록 없음).
- ⚠️ Android `allowBackup="false"`: 기기 변경·재설치 시 진행이 모두 사라진다(의도된 개인정보 선택일 수 있으나 사용자 안내 필요). iOS는 UserDefaults가 기기 백업에 포함되어 플랫폼 간 동작이 다르다.

### 2-4. 실기기 QA 준비도 — 20 / 100

| 항목 | 상태 | 근거 |
|---|---|---|
| iPhone 디버그 실행 | ⚠️ 경로 있음 | `run_iphone.sh`(맥 `/Users/myhwang/...`, 무선 iPhone) — 실행 기록·결과 문서 없음 |
| iOS 사용성 변경(스와이프 뒤로·iPad 설정·글자 확대)의 기기 확인 | ❌ | `docs/IOS_USABILITY_PROGRESS.md` §5: “iOS 시뮬레이터와 실기기에서는 확인하지 않았다.” |
| iPad | ❌ | 실행 기록 없음. 세로 고정 + `UIRequiresFullScreen` |
| Android 실기기 | ❌ | 기록 없음(디버그 APK만 존재) |
| 통합 테스트(`integration_test/` 6개) | ⚠️ 존재만 | 실행 결과·로그 없음. `qa/screenshots`에 Case10·Rome·sandbox 캡처만 |
| 오프라인(비행기 모드) | 🔍 | 코드상 네트워크 없음. 기기 확인 기록 없음 |
| 저사양 Android 메모리·발열·설치 용량 | 🔍 | 미측정 |
| 어린이 플레이테스트 | ❌ | 0회 |

### 2-5. 보안·개인정보·스토어 정책 준비도 — 45 / 100

**좋은 점(코드로 확인)**
- 서버·계정·광고·분석·결제 SDK 없음 → 수집·전송하는 개인정보 없음. 탐정 이름(1–12자)과 아바타는 기기에만 저장(`OFFLINE_SINGLE_DETECTIVE.md` §2).
- 외부 링크·`url_launcher`·웹뷰 없음 → Apple Kids Category의 “외부 링크/구매 전 보호자 게이트” 요건에 걸리는 요소 없음.
- 어른용 화면은 곱셈 Parent Gate(`lib/features/game_master/parent_gate.dart`), 보호자 보고서는 게이트 통과 직후에만(`app_router.dart:181-185`).
- 역직렬화는 평문 JSON만(`progress_repository.dart:108`). 비밀정보 하드코딩 없음, 업로드 키는 `.gitignore` 처리(`.gitignore:73-75`, `android/.gitignore`). `google-services.json` 잔재(`android/app/src/dev|prod/`)는 git 추적 제외 확인(`.gitignore:70`).

**미비**
- ❌ **개인정보처리방침 없음**(저장소 전체 검색 0건). 두 스토어 모두 URL 필수, 아동 대상은 특히 필수.
- ❌ Google Play **데이터 보안(Data safety)** 양식, **타겟층·콘텐츠(Families 정책)** 신고, **콘텐츠 등급(IARC)** 설문 — 작성 근거 없음. 🔍
- ❌ App Store **개인정보 라벨(“데이터 수집 안 함”)**, **연령 등급 설문**, Kids Category 선택 여부 결정 — 근거 없음. 🔍
- ⚠️ iOS `PrivacyInfo.xcprivacy`(앱 자체) 없음. 앱 코드가 필수 사유 API를 직접 쓰지 않고 플러그인이 자체 매니페스트를 가지므로 문제없을 가능성이 크나, 업로드 시 경고로 🔍 확인.
- ⚠️ `ITSAppUsesNonExemptEncryption` 미설정(`ios/Runner/Info.plist`) → 업로드마다 수출 규정 질문. 차단 요인은 아님.
- 🔍 한국 출시 시 아동 개인정보 관련(만 14세 미만) 법무 판단: 서버 수집이 없으므로 부담은 낮지만 방침에 “수집하지 않음”을 명시해야 한다.

### 2-6. 스토어 등록 및 배포 준비도 — 20 / 100

| 항목 | Android | iOS |
|---|---|---|
| 앱 ID | ✅ `com.worldmystery.app`(`android/app/build.gradle.kts`) | ✅ `com.worldmystery.app`, 팀 `5G27CPCN56`, 자동 서명(`project.pbxproj`) |
| 표시 이름 | ✅ “World Mystery” | ✅ `APP_DISPLAY_NAME = "World Mystery"` |
| 버전 | ⚠️ `0.1.0+1`(`pubspec.yaml`) — 출시용 번호 정해야 함 | ⚠️ 같은 값 사용(Info.plist가 `FLUTTER_BUILD_NAME` 참조). `MARKETING_VERSION = 1.0`은 테스트 타깃 |
| SDK | ✅ targetSdk 36 / minSdk 24(Flutter 3.47 기본값, `FlutterExtension.kt`) | ✅ iOS 15.0 이상, Swift Package Manager |
| 릴리스 서명 | ❌ `android/key.properties` **없음** → 빌드 스크립트가 릴리스 빌드를 일부러 중단(`build.gradle.kts`의 `GradleException`). 설계는 올바름 | 🔍 배포 인증서·프로비저닝·App Store Connect 앱 레코드 |
| 릴리스 빌드 생성 | ❌ 현재 불가(키 없음). 이 감사에서 시도하지 않음 | 🔍 Windows라 확인 불가. `flutter build ipa` 기록 없음 |
| 크기 | ❌ **약 1 GB 에셋**. Google Play AAB의 기본 다운로드 한도(압축 기준 약 200 MB)를 크게 넘음 → Play Asset Delivery 없이는 업로드 거부 예상. PNG는 재압축 효과가 작아 AAB도 수백 MB~1 GB 예상(🔍 실제 AAB로 확인) | ⚠️ 4 GB 한도 안이지만 셀룰러 다운로드 경고(200 MB 초과), 아동·가정용 기기 저장공간 부담 |
| 아이콘·스플래시 | ✅ 런처 아이콘·적응형 아이콘·스플래시 생성 설정(`pubspec.yaml`), iOS AppIcon 1024 포함 | ✅ |
| 스토어 메타데이터(설명, 스크린샷, 피처 그래픽, 키워드) | ❌ 없음 | ❌ 없음(iPad 스크린샷 포함 필요: `TARGETED_DEVICE_FAMILY = "1,2"`) |
| CI/CD | ❌ 없음(`.github/`에 워크플로 없음, fastlane/codemagic 없음) | ❌ |

### 2-7. 출시 최종 검증 준비도 — 5 / 100

- 내부 테스트 트랙·비공개 테스트·TestFlight 사용 근거 없음. 🔍
- 🔍 **Google Play 개인 개발자 계정(2023-11 이후 생성)이라면 프로덕션 신청 전 “비공개 테스트 12명 이상 × 14일 연속” 요건**이 있다. 계정 유형 확인이 일정에 직접 영향.
- 출시 전 회귀 체크리스트·릴리스 노트·롤백 계획 없음.
- 5점은 “전체 자동 테스트를 돌릴 수 있는 기반”에 대한 점수다.

---

## 3. 집중 확인 항목 결과

| 항목 | 결과 | 근거·비고 |
|---|---|---|
| 기존 Flutter 테스트 실패 | ⚠️ 4건 / 3,452 통과 | 런던 콘텐츠 해시 스냅숏 2건(최근 런던 개선 이후 미갱신 추정), 시즌 기획 도구 2건. 게임 런타임 실패는 없음. analyze 0건(§7) |
| iOS 뒤로 가기 | ✅ 코드·위젯 테스트 / 🔍 기기 | `edge_swipe_back.dart`, `edge_swipe_back_test.dart`. 기기 미확인 |
| iPad 설정 | ⚠️ | 세로 전용 + `UIRequiresFullScreen = true`(`Info.plist`). 프로젝트 문서도 **iPadOS 26에서 이 키가 지원 중단 예정이라 창 크기 조절이 강제될 수 있다**고 기록(`IOS_USABILITY_PROGRESS.md:43`). 출시 SDK가 iOS 26이면 iPad 좁은 창·가로 레이아웃을 🔍 실기기로 확인해야 함. 대안: iPhone 전용 출시(`TARGETED_DEVICE_FAMILY = 1`)도 선택지 |
| Android 시스템 뒤로 가기 | ✅ 코드·테스트 / 🔍 기기 | `PopScope` 기반 `BackTo`. targetSdk 36이라 **예측형 뒤로 가기**가 기본 — Android 15/16 실기기에서 앱이 닫히지 않는지 확인 필요 |
| 앱 크래시 가능성 | ⚠️ | 저장 파싱은 방어됨. 전역 오류 처리 없음. 가장 큰 위험은 **에셋 용량으로 인한 설치 실패·저장공간 부족**과 저사양 기기의 이미지 메모리(🔍) |
| 저장 데이터 손실 | ⚠️ 낮음(앱 내) / 높음(기기 변경) | 원자적 저장·복구 있음. 클라우드 저장 없음 + Android 백업 꺼짐 → 기기 변경·재설치 시 전부 손실. 앱 업데이트 시에는 유지(같은 키) |
| 인터넷 없이 플레이 | ✅ 코드상 | 네트워크 코드·권한 없음. 🔍 비행기 모드 실기기 확인 |
| 아동 대상 개인정보·계정 정책 | ⚠️ | 계정·수집 없음은 강점. 방침·Families/Kids 신고는 미작성 |
| 앱스토어 심사 필요 정보 | ❌ | 방침 URL, 지원 URL, 연령 등급, 개인정보 라벨, 스크린샷, 심사 메모(계정 불필요·오프라인 명시) 없음 |
| 배포 빌드 생성 가능 여부 | ❌ Android(키 없음) / 🔍 iOS | Android는 키만 만들면 빌드 자체는 가능할 구조이나, 크기 한도로 업로드 단계에서 막힐 것 |

---

## 4. 출시 차단 요인

### P0 — 해결하지 않으면 출시 불가

| ID | 문제 | 근거 |
|---|---|---|
| P0-1 | **번들 에셋 약 1 GB** → Google Play 기본 모듈 다운로드 한도 초과, iOS도 과대 | 측정값 1,025 MB, 디버그 APK 954 MB |
| P0-2 | **Android 업로드 키 없음** → 릴리스 AAB 생성 불가 | `android/key.properties` 없음, `build.gradle.kts`가 의도적으로 중단 |
| P0-3 | **iOS 릴리스 아카이브·업로드 미검증** | Windows 감사로 확인 불가, `flutter build ipa` 기록 없음 🔍 |
| P0-4 | **개인정보처리방침 없음**(공개 URL 필요) | 저장소 검색 0건 |
| P0-5 | **스토어 정책 신고 미작성**: Play Data safety·타겟층/Families·IARC 등급, App Store 개인정보 라벨·연령 등급 | 근거 없음 🔍 |
| P0-6 | **스토어 등록 정보 없음**: 설명, 스크린샷(휴대폰·iPad), 피처 그래픽, 지원 연락처 | 근거 없음 |
| P0-7 | **실기기 QA 0건**(Android·iPhone·iPad, 오프라인, 뒤로 가기, 재시작 후 이어하기) | `IOS_USABILITY_PROGRESS.md` §5, 기록 부재 |

### P1 — 출시 전 해결 권장

| ID | 문제 | 근거 |
|---|---|---|
| P1-1 | 전체 테스트 스위트에 실패 존재(스냅숏 해시) | §7 |
| P1-2 | New York 시즌 **미승인 상태로 공개**, Rome도 사람 검수 문서 없음 | 커밋 메시지, `docs/difficulty_reviews/` |
| P1-3 | iPadOS 26 창 크기 조절 대응 또는 iPhone 전용 결정 | `Info.plist`, `IOS_USABILITY_PROGRESS.md:43` |
| P1-4 | 전역 오류 처리(`FlutterError.onError`, `PlatformDispatcher.onError`, 사용자용 오류 화면) | `main.dart` |
| P1-5 | 버전 번호 정리(`0.1.0+1` → 출시 번호) | `pubspec.yaml` |
| P1-6 | 어린이 플레이테스트 최소 1회(런던) | `WORLD_MYSTERY_LEARNING_PLAYTEST.md` |
| P1-7 | Google Play 비공개 테스트 12명×14일(개인 계정일 때) | 🔍 계정 유형 |
| P1-8 | 런던 Case 04–12 난이도 문장 리뷰 | `docs/difficulty_reviews/LONDON_CASE_01_03.md`만 존재 |
| P1-9 | 기기 변경 시 진행 손실 안내 또는 백업 정책 결정 | `allowBackup="false"` |

### P2 — 출시 후 개선 가능

| ID | 문제 |
|---|---|
| P2-1 | CI(테스트·analyze 자동화, 빌드 번호 자동 증가) 없음 |
| P2-2 | `ITSAppUsesNonExemptEncryption = false` 추가(업로드마다 질문 방지) |
| P2-3 | 앱 자체 `PrivacyInfo.xcprivacy` 점검 |
| P2-4 | 오래된 주석·문서 정리(Paris “not released” 주석, 아바타 “Custom Asset Required”) |
| P2-5 | `android/app/src/dev|prod/google-services.json` 로컬 잔재 삭제 |
| P2-6 | 접근성: 시맨틱 라벨 사용 88개 파일·모션 줄이기 대응 21곳 존재 — 스크린리더 실기기 점검 |
| P2-7 | 광고·구독 확장(`ECONOMY_EXTENSIONS.md`)은 정책 검토 후 별도 릴리스 |

---

## 5. 출시 차단 요인 TOP 10

1. **에셋 1 GB** — 압축·해상도 정리 없이는 Google Play 업로드 불가 (P0-1)
2. **Android 업로드 키·Play App Signing 미설정** (P0-2)
3. **iOS 릴리스 아카이브·TestFlight 업로드 미검증** (P0-3)
4. **개인정보처리방침 URL 없음** (P0-4)
5. **Families/Kids·Data safety·연령 등급 신고 미작성** (P0-5)
6. **실기기 QA 0건** (P0-7)
7. **스토어 등록 정보(스크린샷·설명) 없음** (P0-6)
8. **테스트 스위트 실패 상태** (P1-1)
9. **Rome·New York 사람 검수 없음(NY 미승인)** (P1-2)
10. **iPad 창 크기 조절(iPadOS 26) 미대응** (P1-3)

---

## 6. 출시까지 남은 작업

작업량은 1인 개발자 기준 **추정**이며, 근거가 약한 항목은 “추정(근거 약함)”으로 적었다.

| # | 우선 | 작업 | 현재 상태 | 수정 대상 | 작업량 | 선행 조건 | 완료 판정 기준 |
|---|---|---|---|---|---|---|---|
| T1 | P0 | 이미지 재압축(장면 PNG→JPEG/WebP, 투명 필요한 것만 PNG 유지, 최대 해상도 정리) | 1,025 MB | `assets/**`, `ArtAssets`·생성 코드의 확장자, `pubspec.yaml`, `test/pubspec_assets_test.dart` 등 에셋 테스트 | 3–5일 (변환은 도구로 반나절, 경로 갱신·화질 확인이 대부분) | 시즌 범위 결정(A/B) | 릴리스 AAB 다운로드 크기 < 150 MB(여유 포함), 전체 테스트 통과, 대표 화면 화질 육안 확인 |
| T2 | P0 | Android 업로드 키 생성, `key.properties`, Play App Signing 등록 | 키 없음 | `android/key.properties`(git 제외), Play Console | 0.5일 | Play 개발자 계정 🔍 | `flutter build appbundle --release` 성공, 서명 확인 |
| T3 | P0 | iOS 배포 인증서·App Store Connect 앱 레코드·`flutter build ipa`·TestFlight 업로드 | 미검증 | Xcode 서명, App Store Connect | 1일 | Apple Developer Program 🔍, Mac | TestFlight에서 설치·실행 |
| T4 | P0 | 개인정보처리방침 작성·공개 호스팅(한/영) | 없음 | 외부 웹페이지 | 1일 | 법무 판단 🔍 | 공개 URL 접속, “수집 없음·기기 저장만” 명시 |
| T5 | P0 | Play: 타겟층(아동)·Families·Data safety·IARC / Apple: 개인정보 라벨·연령 등급·Kids Category 결정 | 없음 | 두 콘솔 | 1–2일 | T4 | 콘솔 경고 0건 |
| T6 | P0 | 스토어 등록 정보(설명, 휴대폰·iPad 스크린샷, 피처 그래픽 1024×500, 지원 이메일) | 없음 | 콘솔, 캡처 | 2–3일 | T1 이후 화면 확정 | 두 스토어 등록 정보 “완료” |
| T7 | P0 | 실기기 QA: Android(저사양 1 + 최신 1), iPhone, iPad — 신규 설치→탐정 생성→사건 완료→강제 종료→재실행 이어하기, 비행기 모드, 시스템 뒤로 가기, 글자 확대 | 0건 | 체크리스트 문서, 발견 버그 수정 | 런던만: 4–6일 / 4시즌: 12–18일 (추정) | T1, T2, T3 | 체크리스트 전 항목 통과·기록, 크래시 0 |
| T8 | P1 | 실패 테스트 원인 확인 후 수정(스냅숏은 의도된 변경인지 검토 후 갱신, 기획 도구는 `generator` 오류 원인 수정) | 4건 실패 | `test/audit_fix_d4_d5_test.dart`, `test/final_small_pass_test.dart`, `tool/season_planner` + `test/season_planner/season_planner_test.dart` | 0.5–1일 | 없음 | `flutter test` 전체 통과 |
| T9 | P1 | 전역 오류 처리 + 사용자용 오류 화면(내부 정보 노출 없이) | 없음 | `lib/main.dart`, 새 오류 위젯 | 0.5일 | 없음 | 강제 예외 시 앱이 회색 화면 대신 안내 화면, 위젯 테스트 |
| T10 | P1 | iPad 결정: iPhone 전용 출시 또는 iPad 창 크기 대응 | 미결 | `project.pbxproj`(`TARGETED_DEVICE_FAMILY`) 또는 레이아웃 | 0.5일(iPhone 전용) / 3–5일(대응, 추정·근거 약함) | 없음 | iPad 실기기에서 깨짐 없음, 또는 iPhone 전용 빌드 |
| T11 | P1 | 버전 정리 `1.0.0+1`, 빌드 번호 규칙 | `0.1.0+1` | `pubspec.yaml` | 0.1일 | 없음 | 두 스토어 버전 표시 확인 |
| T12 | P1 | 어린이 플레이테스트 1–2회(런던 Case 01–03) | 0회 | `docs/playtest/` 기록 | 2–3일(모집 포함, 추정) | T7 일부 | 결과 기록, 막힌 지점 수정 |
| T13 | P1 | 런던 Case 04–12 난이도 문장 리뷰 | 01–03만 | `docs/difficulty_reviews/` | 2–3일 | 없음 | 리뷰 문서·수정 반영 |
| T14 | P1 | (B안만) Rome·NY 사람 검수 + 승인 | 미승인 | 생성 콘텐츠, 리뷰 문서 | 시즌당 5–8일(추정) | 없음 | 시즌별 리뷰 문서·승인 기록 |
| T15 | P1 | Play 비공개 테스트 12명×14일(개인 계정이면) | 미시작 | Play Console | 달력상 14일(작업 0.5일) | T2, T5 | 프로덕션 신청 자격 획득 |
| T16 | P2 | CI(analyze·test, 빌드 번호) | 없음 | `.github/workflows/` | 1일 | 없음 | PR마다 자동 실행 |

---

## 7. 실행한 검증

| 항목 | 결과 |
|---|---|
| `flutter test` (전체, 2026-11-02) | **3,452 통과 / 4 실패 / 0 건너뜀**, 178개 파일, 약 10분 |
| `flutter analyze` | **No issues found** (63초) |

**실패 4건**
| 파일 | 테스트 | 성격 |
|---|---|---|
| `test/audit_fix_d4_d5_test.dart` | D5 — … every other field of every case is as before | 런던 사건 JSON 해시 스냅숏 불일치. 2026-10-31 런던 Case 02–12 개선 이후 갱신 안 된 것으로 보임 → **의도된 변경인지 확인 후** 갱신 |
| `test/final_small_pass_test.dart` | 17. no other case changed in this pass | 같은 성격(해시 스냅숏) |
| `test/season_planner/season_planner_test.dart` | puzzles a hint that says the answer is a WARNING, not an ERROR | 시즌 기획 도구 검사에서 `generator` 오류가 3건 나옴(기대: 없음). 앱 런타임이 아닌 **도구** 회귀 |
| `test/season_planner/season_planner_test.dart` | English heuristics only warn, and say they are heuristics | 같은 원인(`generator` 오류 8건) |

> **후속 조치(2026-11-02, 감사 후):** 4건 모두 해결(T8 완료).
> - 해시 2건: 원인은 커밋 3d0f852(Case 03 M2 스케치에 `note` 추가). `note`를 빼고 계산하면 기존 기준값과 정확히 일치함을 확인한 뒤, 이전 값을 주석으로 남기고 기준값을 갱신.
> - 기획 도구 2건: 테스트가 계획서 문장만 바꾸고 `levels.json`은 그대로 둬서 생성기의 난이도 문장 검사(`level_missing`/`level_stale`)가 오류를 냄. 계획서와 `levels.json`을 함께 고치는 `editCase` 도우미로 테스트 픽스처를 바로잡음(검사 기준은 그대로).
> - 해당 3개 파일 77개 테스트 통과, `flutter analyze` 이슈 0.

판단: 4건 모두 게임 런타임 동작의 실패는 아니지만, “전체 스위트 통과”가 출시 기준이므로 P1로 둔다. 실패 원인을 고치지 않고 테스트를 약화하면 안 된다.
| 릴리스 빌드(Android/iOS) | **실행하지 않음**(업로드 키 없음 / Windows) |
| 통합 테스트·실기기 | **실행하지 않음** |

---

## 8. 출시 전략 비교

| | **A. London 먼저** | **B. 4개 시즌 동시** |
|---|---|---|
| 장점 | 가장 검수된 콘텐츠로 시작, 에셋 약 155 MB+공용(압축 후 수십 MB 예상)으로 크기 문제가 가장 작음, QA 범위 1/4, 실사용 피드백을 다음 시즌에 반영 | 첫인상에 “4개 도시” 볼륨, 업데이트 운영 부담 적음 |
| 위험 | 출시 시 볼륨이 작게 보일 수 있음. 시즌 2–4를 숨기는 처리(`released: false` → COMING SOON, 해당 에셋 `pubspec.yaml`에서 제외) 후 업데이트로 여는 과정에서 회귀 위험 | 검수 안 된 Rome·NY(NY 미승인)가 그대로 노출, QA 범위 4배(48사건×3난이도), 압축 후에도 크기 여유 적음, 출시 지연 |
| 추가 작업 | 시즌 2–4 비공개 처리·에셋 제외, 해당 상태의 테스트 보정 | T14(Rome·NY 검수), 4시즌 실기기 QA |
| 예상 기간 | **약 4–6주**(Play 14일 비공개 테스트와 병행 시) | **약 8–12주** |

**권장: A안.** 단 Paris는 검수 수준이 높아 첫 업데이트(출시 후 2–4주)로 바로 열 수 있다. 시즌 잠금 해제 구조(`SeasonAvailability`, `released` 플래그)가 이미 있어 운영 방식과 잘 맞는다.

---

## 9. 가장 빠른 현실적 출시 경로 (A안)

1. **1주차:** T8 테스트 정리 → T1 이미지 압축(런던+공용 우선) → T2·T3 서명·첫 릴리스 빌드 → T11 버전 → T9 오류 처리 → 시즌 2–4 비공개 처리
2. **2주차:** T4 방침 → T5 정책 신고 → T10 iPad 결정 → T7 실기기 QA(Android·iPhone) 1차 → 내부 테스트 트랙/TestFlight 업로드
3. **3–4주차:** (개인 계정이면) Play 비공개 테스트 14일 시작 → 그동안 T12 플레이테스트, T13 런던 리뷰, T6 스크린샷·설명, QA 2차·버그 수정
4. **5–6주차:** App Store 심사 제출(보통 1–3일, Kids Category는 더 걸릴 수 있음) → Play 프로덕션 신청 → 출시

---

## 10. 플랫폼별 준비 상태

**Android — 약 40%**
- 준비됨: 앱 ID, 업로드 키 강제 로직, targetSdk 36, 적응형 아이콘·Android 12 스플래시, 시스템 뒤로 가기 처리(코드·테스트), 네트워크 권한 없음, 백업 끔.
- 막힘: 업로드 키, **크기 한도**, Families·Data safety·IARC, 등록 정보, 실기기(예측형 뒤로 가기·저사양 메모리), 비공개 테스트 요건 🔍.

**iOS — 약 40%**
- 준비됨: 번들 ID·팀, SPM, AppIcon 전 크기, 세로 고정, 가장자리 스와이프 뒤로 가기, 상태 표시줄 처리, iPhone 디버그 실행 경로.
- 막힘: 릴리스 아카이브·TestFlight 🔍, iPad 정책(iPadOS 26), 개인정보 라벨·연령 등급, 스크린샷(iPhone·iPad), 실기기 확인, 크기(경고 수준).

---

## 11. 별도 확인 필요 (코드로 판정 불가)

- Google Play 개발자 계정 유형(개인/조직)과 생성 시기 → 비공개 테스트 12명×14일 요건 여부
- Apple Developer Program 가입·배포 인증서·App Store Connect 앱 레코드
- “World Mystery” 앱 이름의 두 스토어 사용 가능 여부·상표
- 개인정보처리방침의 법무 검토(한국 아동 개인정보, 미국 COPPA 배포 시)
- 출시 국가·언어(스토어 설명 언어)
- 실기기: 설치 크기, 첫 실행 시간, 저사양 Android 메모리, iPad 창 크기, 비행기 모드, 강제 종료 후 저장
- AI 생성 이미지·텍스트의 권리 확인(사용 도구의 상업 이용 조건)
