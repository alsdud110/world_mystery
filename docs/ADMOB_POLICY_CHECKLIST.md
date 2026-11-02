# AdMob 정책 체크리스트 (World Mystery, 전 연령 · 아동 포함)

Release 빌드는 이 체크리스트의 해당 플랫폼 항목이 모두 끝나기 전까지 광고를 요청하지 않는다.
코드 게이트: `AdConfig.releaseCleared` (lib/core/constants/ad_config.dart) — 현재 빈 집합.
항목을 모두 확인한 플랫폼만 이 집합에 추가한다. 추가하는 커밋이 곧 정책 승인 기록이다.

Debug/Profile 빌드는 Google 공식 테스트 광고 ID로만 요청한다 (PART 1).

## 코드에 이미 적용된 보호 (PART 2)

| 항목 | 값 | 위치 |
|---|---|---|
| 연령 처리 | `AgeRestrictedTreatment.child` | `ChildSafeAds.configuration` |
| 최대 광고 콘텐츠 등급 | `MaxAdContentRating.g` | 〃 |
| 비맞춤 광고 | `AdRequest(nonPersonalizedAds: true)` | `ChildSafeAds.request` |
| 적용 순서 | 설정 → 읽어서 확인 → `initialize()` → 첫 광고 로드 | `AdService.start()` |
| 실패 시 | SDK 시작·광고 요청 안 함 (fail-closed) | 〃 |
| Android 광고 ID | `AD_ID` 권한을 병합 매니페스트에서 제거 | AndroidManifest.xml |
| iOS ATT | 요청 안 함, `NSUserTrackingUsageDescription` 없음 | Info.plist |

`tagForChildDirectedTreatment` / `tagForUnderAgeOfConsent`는 google_mobile_ads 9.x에서 deprecated이고
`ageRestrictedTreatment`로 대체되었으므로 함께 설정하지 않는다.

## PART 5B 기술 검증 결과 (2026-11-03)

대상 이용자: 전 연령 영어 입문자(아동 포함). iOS는 일반 게임/교육 카테고리 출시 예정 (Kids Category 아님).
이 문서의 이전 표기 "8–12세"와 다르다. 현재 코드는 **모든 이용자를 아동으로 취급**한다
(`AgeRestrictedTreatment.child` + G 등급 + 비맞춤 광고, 연령 확인 화면 없음). 이 방식을 유지할지가 아래 정책 판단의 전제다.

상태: **확인 완료** · **수정 필요** · **정책 판단 필요** · **실기기 확인 필요** · **macOS 확인 필요**
(이번 검증은 macOS에서 수행. 실기기·에뮬레이터 광고 재생은 확인하지 못했다.)

### 1. Android 광고 SDK

| 항목 | 결과 | 상태 |
|---|---|---|
| 네이티브 SDK 버전 | google_mobile_ads 9.2.0 → `com.google.android.gms:play-services-ads:25.5.0`, UMP `com.google.android.ump:user-messaging-platform:4.0.0` (플러그인 android/build.gradle, 병합 리포트에서 `play-services-ads-api:25.5.0` 확인) | 확인 완료 |
| Families 자체 인증 목록 | Google Play 도움말 "Families Self-Certified Ads SDKs" 목록에 Google AdMob (`com.google.android.gms play-services-ads`) "19.0.0 or later"로 등재 → 25.5.0은 범위 안 | 확인 완료 (목록 기준) |
| 개별 버전 준수 상태 | 목록은 "SDK Index에서 개별 버전 확인"을 안내. 25.5.0의 SDK Index 페이지는 확인하지 않음 | 미확인 |
| 미디에이션 | 코드·의존성에 미디에이션 어댑터 없음. AdMob 콘솔 설정은 확인 불가 | 정책 판단 필요 (콘솔) |

### 2. Android 병합 매니페스트 권한 (Debug 병합본, 2026-11-03 빌드)

| 권한 | 출처 | 결과 | 상태 |
|---|---|---|---|
| `com.google.android.gms.permission.AD_ID` | play-services-ads-api, ads-identifier, measurement-sdk-api | `tools:node="remove"`로 **REJECTED** — 병합본에 없음 | 확인 완료 |
| `android.permission.ACCESS_ADSERVICES_AD_ID` | play-services-ads-api 25.5.0 | 남아 있음 | 정책 판단 필요 |
| `android.permission.ACCESS_ADSERVICES_ATTRIBUTION` | 〃 | 남아 있음 | 정책 판단 필요 |
| `android.permission.ACCESS_ADSERVICES_TOPICS` | 〃 | 남아 있음 | 정책 판단 필요 |
| `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` | 앱·SDK·WorkManager | 광고·네트워크 동작에 필요 | 확인 완료 |
| `RECEIVE_BOOT_COMPLETED` | SDK가 스스로 `tools:node="remove"` | 병합본에 없음 | 확인 완료 |

- Release 병합본: `config/ads.local.json`과 업로드 키가 없어 Gradle이 Release 작업을 중단하므로 이번에 생성하지 않았다
  (`build/` 안의 Release 병합본은 10월 이전 패키지명의 오래된 산출물). 앱에 `src/release` 소스셋이 없어
  `src/main`의 AD_ID 제거가 Release에도 같은 방식으로 적용된다 — **Release 병합본 직접 확인은 실제 ID로 빌드할 때 필요**.
- ADSERVICES 3종(Privacy Sandbox: 광고 ID 대체, 기여 분석, Topics) 제거 제안 — **아직 제거하지 않음**:
  - 근거: 모든 이용자를 아동으로 처리하므로 관심사·기여 분석 신호를 쓸 이유가 없고, Families 정책은 아동에게
    광고 식별자 전송을 금지한다. 아동 태그 요청에서 SDK가 이 API를 쓰지 않는지는 공개 문서로 확인되지 않았다.
  - 영향: `tools:node="remove"` 3줄 추가. 권한이 없으면 SDK는 해당 API를 건너뛸 뿐 광고 로드는 유지된다(Google 문서상
    선택 기능). 게임 로직 영향 없음. 제거 후 Debug 테스트 광고 로드를 실기기로 다시 확인해야 한다.
  - 결정: 정책 담당 승인 후 PART 5C에서 적용.
- SDK 자동 시작: `MobileAdsInitProvider`(initOrder 100)가 앱 시작 시 실행되며 `OPTIMIZE_INITIALIZATION`·
  `OPTIMIZE_AD_LOADING` 플래그가 켜져 있다. 앱 코드는 첫 배너 화면 전까지 `initialize()`를 부르지 않지만,
  Provider 자체의 네트워크 동작 여부는 미확인 → **정책 판단 필요** (동의 전 측정 지연이 필요하면
  `com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT` 메타데이터 검토).

### 3. UMP / 개인정보 동의

| 항목 | 결과 | 상태 |
|---|---|---|
| UMP 동의 관리 | **없음.** `ConsentInformation`·`ConsentForm` 호출 없음. UMP 네이티브 SDK는 플러그인이 함께 넣는다 (Android 4.0.0, iOS SPM 3.1.0) | 수정 필요 |
| SDK 초기화 시점 | 앱 시작 시 없음. 첫 `BannerAdArea`(Archives·보드·CASE FILES) 또는 힌트 다이얼로그의 GET COINS preload가 `AdService.start()` 호출 | 확인 완료 |
| 광고 요청 시점 | `start()`가 연령 설정 → 읽어서 확인 → `initialize()` 성공 후에만. Release는 `releaseCleared` 비어 있어 `start()`가 즉시 off | 확인 완료 |

UMP 적용 설계 (PART 5C 이후 구현, 이번에는 계획만):

1. 위치: `AdService._run()`의 연령 설정 확인 **뒤**, `initialize()` **앞**. 별도 `ConsentGate` 인터페이스로 감싸
   기존 `AdSdk` 스텁 방식처럼 테스트에서 대체 가능하게 한다.
2. 순서: `ConsentInformation.instance.requestConsentInfoUpdate(params)` →
   성공 시 `ConsentForm.loadAndShowConsentFormIfRequired()` → `ConsentInformation.instance.canRequestAds()`가
   true일 때만 `initialize()` → 광고 요청. 실패·타임아웃·false면 기존처럼 `AdOffReason`(새 값 `noConsent`)로 off.
3. 매 실행 `requestConsentInfoUpdate` 호출(Google 권장). 이전 실행의 `canRequestAds()`가 true면 갱신 결과 전에도
   요청 가능(공식 샘플 패턴).
4. 폼 표시 시점: 지금 구조로는 첫 배너 화면 진입 시 폼이 뜬다. 스토리·퍼즐 도중에는 절대 띄우지 않는다 —
   배너 화면 또는 GET COINS 탭 시점에만. 앱 시작 직후로 옮길지는 UX 결정 필요.
5. `getPrivacyOptionsRequirementStatus()`가 `required`면 개인정보 옵션 진입점 필요 → 보호자 게이트 뒤
   (기존 `ParentGate` 화면) 버튼에서 `ConsentForm.showPrivacyOptionsForm()`. 새 연령 확인 화면은 추가하지 않는다.
6. `ConsentRequestParameters.tagForUnderAgeOfConsent`: UMP는 이 값을 광고 SDK에 전달하지 않으며, true면 동의 폼을
   띄우지 않는다. 광고 요청 쪽 `ageRestrictedTreatment.child`는 그대로 유지.

연령별 광고 처리 — **정책 판단 필요**:

- A안 (현재): 모든 이용자를 아동으로 처리. 개인정보 위험이 가장 낮다. EEA/UK에서는 UMP에
  `tagForUnderAgeOfConsent=true`를 줘 폼이 뜨지 않게 되며, 그 상태에서 광고(제한 광고 포함)가 나가는지는
  실기기·지역 테스트(`ConsentDebugSettings` EEA 지정)로 확인해야 한다. 수익은 낮다.
- B안: 중립적 연령 확인 후 성인만 일반 처리. Families 혼합 연령 규정상 가능하나 연령 확인 화면이 필요하므로
  이번 범위에서 제외(임의 추가 금지).
- 어느 안이든 "아동 대상 앱에 동의 폼을 띄워 아동에게 동의를 받는" 구성은 피한다.

### 4. 광고 UX (코드 검토)

| 항목 | 결과 | 상태 |
|---|---|---|
| 배너 위치 | Archives·보드·CASE FILES 3곳만, 스토리·퍼즐·미션 없음. 로드 성공 후에만 하단 띠, 페이지와 겹치지 않음 | 확인 완료 |
| 배너–주 버튼 간격 | CASE FILES: `BEGIN/CONTINUE INVESTIGATION` 하단 여백 16dp + 배너 띠 상단 8dp + 구분선 ≈ 24dp. 보드는 스크롤 위치에 따라 다름 | 실기기 확인 필요 |
| GET COINS 선택성 | 코인이 부족할 때 힌트 다이얼로그에만, 탭해야만 재생. 힌트 자체가 선택 기능이며 진행에 필수 아님. CANCEL 항상 있음 | 확인 완료 |
| 취소 시 코인 | `onUserEarnedReward`가 없으면 `earned=false` → null → `notEarned`, 지급 없음 | 확인 완료 (테스트 고정) |
| 중복 지급 방지 | 광고별 `earned` 플래그 + 광고마다 고유 reward id + 지갑이 id당 1회만 기록, 서비스 재호출도 같은 id라 0 | 확인 완료 (테스트 고정) |
| 닫기·실패 후 UI | `_watchingAd`는 `finally`에서 해제, 메시지 "No coins this time." / "No ad right now. Try again later.", 다음 광고 preload, 실패는 백오프(30초→최대 10분) | 확인 완료 |
| 광고 신고 기능 | 앱 자체 신고 버튼 없음. AdMob 광고의 AdChoices/피드백 아이콘은 SDK가 그린다 | 실기기 확인 필요 (아이콘 노출), 정책 판단 필요 (앱 내 신고 필요 여부) |
| 보상형 광고 닫기 버튼·길이 | SDK 전체 화면 UI | 실기기 확인 필요 |
| 테스트 배너·보상형 실제 재생 | PART 5A에서 기기 없음, 에뮬레이터 불안정으로 중단 | 실기기 확인 필요 |

### 5. iOS (일반 게임/교육 카테고리 기준)

| 항목 | 결과 | 상태 |
|---|---|---|
| 네이티브 SDK | SPM `swift-package-manager-google-mobile-ads` 13.11.0, UMP 3.1.0 (`Package.resolved`) | 확인 완료 |
| Release 광고 차단 | `releaseCleared` 비어 있음 → `requestsAllowedNow` false → `AdService` off. 빌드 단계 `ios/scripts/admob_app_id.sh`는 Release에 실제 ID가 없으면 빌드 중단 | 확인 완료 (코드) |
| Kids Category가 아님 | 아동 개인정보 의무는 면제되지 않는다고 본다(COPPA·GDPR-K 등은 카테고리와 무관). 현재 아동 처리 유지 | 정책 판단 필요 |
| ATT | 요청 안 함, `NSUserTrackingUsageDescription` 없음 → IDFA 접근 불가 | 확인 완료 |
| Privacy Manifest | GMA 13.11.0 xcframework에 `PrivacyInfo.xcprivacy` 포함 확인 (DerivedData) | 확인 완료 |
| App Store 앱 개인정보 항목 (SDK 매니페스트 기준) | 아래 표 | 정책 판단 필요 (최종 신고) |
| `SKAdNetworkItems` | Info.plist에 없음. 아동 처리·비추적 구성에서는 필수 아님(기여 측정용) | 정책 판단 필요 |
| Xcode Release Archive·App Privacy Report 생성 | 실제 ID 없어 Release 빌드 불가, 미실행 | macOS 확인 필요 |
| 실기기 `getRequestConfiguration()` 읽기 결과 | 미실행 | 실기기 확인 필요 |

GMA 13.11.0 Privacy Manifest 선언 (수집 유형 / 연결 / 추적):
coarse location(IP) 연결·비추적 · advertising data 연결·비추적 · product interaction 연결·비추적 ·
device ID **연결·추적** · performance data 비연결 · crash data 비연결 · other diagnostic data 비연결.
Required Reason API: UserDefaults, SystemBootTime, DiskSpace.
Device ID 추적은 ATT 미허용 시 IDFA가 0이 되어 실제 전송되지 않지만, 앱 개인정보 신고에서 어떻게 답할지는 정책 판단 필요.

### 6. 개인정보처리방침에 반영할 항목 (아직 반영하지 않음)

- 광고 SDK: Google Mobile Ads SDK(AdMob), Google User Messaging Platform
- 수집 항목 (Google 공개 문서 기준, Android 25.5.0): IP 주소(대략적 위치 추정), 앱 상호작용(실행·탭·영상 조회),
  진단 정보(실행 시간·멈춤·전력), 기기 식별자(앱 세트 ID 등. Android 광고 ID는 매니페스트에서 제거) — 전송 중 TLS 암호화
- iOS 추가: 광고 데이터(본 광고), 성능·충돌 데이터, IDFV/IDFA(ATT 미요청으로 IDFA 미사용)
- 목적: 광고 제공·측정·부정 방지. 맞춤 광고 없음, 아동 처리(G 등급, 비맞춤)
- 보상형 광고 코인은 기기 안에만 저장, 서버 전송 없음
- EEA/UK 동의 관리 방식(UMP 도입 시)과 개인정보 옵션 위치
- 보호자 문의처, 데이터 삭제 요청 방법

## PART 5B-2 구현 결과 (2026-11-03)

결정: 전 연령 대상, 연령 확인 화면 없음, 모든 이용자에게 아동 보호 광고 설정 유지, 맞춤 광고 없음, Release 광고 차단 유지.

| 항목 | 결과 | 상태 |
|---|---|---|
| ADSERVICES 3종 제거 | `src/main/AndroidManifest.xml`에 `tools:node="remove"`. Debug 병합 리포트에서 `ACCESS_ADSERVICES_AD_ID`·`ATTRIBUTION`·`TOPICS` 모두 REJECTED, 병합본 권한은 INTERNET·ACCESS_NETWORK_STATE·WAKE_LOCK·FOREGROUND_SERVICE·앱 내부 수신자 권한만 | 확인 완료 (Debug) |
| AD_ID 제거 유지 | 그대로 REJECTED | 확인 완료 (Debug) |
| Release 병합본 | 실제 ID·업로드 키 없이는 생성 불가 (같은 `src/main` 규칙 적용) | 실제 ID 빌드 시 확인 필요 |
| UMP 서비스 | `lib/core/utils/ad_consent.dart` `AdConsent` (UMP 호출은 `ConsentSdk` 인터페이스 뒤, 테스트는 가짜로 대체) | 확인 완료 (단위 테스트) |
| UMP 요청 파라미터 | `ConsentRequestParameters(tagForUnderAgeOfConsent: true)` — 공식 문서: TFUA가 true면 UMP SDK는 동의를 요청하지 않음. 광고 요청 쪽은 기존 `ageRestrictedTreatment.child` 유지 (UMP는 TFUA를 광고 SDK에 전달하지 않음) | 확인 완료 (API 기준) |
| 실행 순서 | 앱 첫 프레임 뒤 `refreshConsent()` → `requestConsentInfoUpdate` (광고 SDK 시작·광고 요청 없음). 첫 광고가 필요할 때 `AdService.start()`: 아동 보호 설정 → 읽어서 확인 → 같은 `gather()` 결과 대기 → `canRequestAds()` true일 때만 `initialize()` → 광고 요청 | 확인 완료 (단위 테스트) |
| 중복 실행 방지 | `gather()`·`start()` 모두 실행당 1회 (memoized). 실행 시 갱신과 여러 `start()`가 업데이트 1회·초기화 1회를 공유 | 확인 완료 (단위 테스트) |
| 실패 시 | 업데이트 실패·10초 타임아웃·`canRequestAds()` 읽기 실패·false → `AdOffReason.noConsent`, SDK 시작·광고 요청 없음 | 확인 완료 (단위 테스트) |
| 폼 오류 | 폼 오류·표시 실패여도 `canRequestAds()`로 결정 (Google 권장 흐름) | 확인 완료 (단위 테스트) |
| 광고 요청 전 확인 | `AdService.canRequestAds` = 시작 완료 && `AdConsent.allowsAds`(마지막 `canRequestAds()` 결과). 모든 슬롯이 광고 단위를 이 값으로만 받음 | 확인 완료 (단위 테스트) |
| 개인정보 옵션 | `getPrivacyOptionsRequirementStatus()`가 `required`일 때만 GAME MASTER(보호자 게이트 뒤) 하단에 "광고 개인정보 옵션 열기" → `ConsentForm.showPrivacyOptionsForm()`. 선택 후 `canRequestAds()`를 다시 읽어 false면 광고 끄고 로드된 광고 해제 | 확인 완료 (위젯·단위 테스트) |
| Release | `releaseCleared` 비어 있음 → `mayStart` false → UMP도 호출하지 않음 | 확인 완료 (코드·단위 테스트) |
| EEA/UK에서 TFUA=true일 때 `canRequestAds()` 값과 광고 노출 여부 | 공식 문서에 명시 없음. false면 그 지역은 광고가 꺼진다(fail-closed) | 실기기 확인 필요 (`ConsentDebugSettings` 지역 지정) |
| AdMob 콘솔 개인정보·메시지(GDPR/미국 주) 설정 | 콘솔 미확인. 메시지를 만들지 않으면 폼이 없다 | 정책 판단 필요 |
| 실제 폼·개인정보 옵션 표시 | Android Activity/iOS 화면 위 표시 | 실기기 확인 필요 |

---

## Android — Google Play Families (확인 필요)

- [ ] Play Console 타깃 연령층 설정(아동 연령대 포함 혼합 연령)과 Families 정책 적용 여부 확인
- [x] Google Mobile Ads SDK 버전(25.5.0, plugin 9.2.0)이 Families 자체 인증 광고 SDK 목록 조건(19.0.0 이상)을 충족 — SDK Index 개별 버전 확인은 남음 (PART 5B)
- [ ] AdMob 콘솔: 앱 단위 "아동 대상" 설정, 광고 콘텐츠 등급 G, 민감 카테고리 차단 확인
- [ ] AdMob 콘솔: 미디에이션을 쓰지 않음(또는 쓰는 네트워크도 Families 인증) 확인
- [ ] Release 병합 매니페스트에 `com.google.android.gms.permission.AD_ID`가 없는지 확인
      (Debug 병합 매니페스트에서는 제거 확인됨, 2026-11-02)
- [x] SDK가 추가하는 Privacy Sandbox 권한 `android.permission.ACCESS_ADSERVICES_AD_ID` — 3종 제거 (PART 5B-2, Debug 병합본 확인)
      (및 ATTRIBUTION/TOPICS 등)도 제거해야 하는지 결정 — 현재 병합 매니페스트에 남아 있음
- [ ] Data safety 신고: SDK가 수집하는 항목(기기 식별자/앱 상호작용/진단 등) — Google 공식 문서 기준으로 작성
- [ ] 광고 포함 앱 표시("광고 포함") 설정

## iOS — App Store (확인 필요, Xcode 항목은 macOS에서 확인)

- [x] **Kids Category 등록 여부 결정** — 일반 게임/교육 카테고리로 출시 (2026-11-03). 아동 개인정보 의무는 그대로 적용.
      이전 메모: App Review Guidelines 1.3 / 5.1.4는 Kids Category 앱의 제3자 광고를
      엄격히 제한한다. AdMob 사용이 허용되는지 최신 가이드라인으로 확인하기 전까지 iOS Release 광고 금지
- [ ] ATT 프롬프트를 띄우지 않는 구성이 심사 기준에 맞는지 확인 (아동 대상 앱은 추적 금지)
- [x] Google Mobile Ads SDK의 Privacy Manifest(PrivacyInfo.xcprivacy) 포함 확인 (13.11.0, PART 5B)
- [ ] App Privacy(영양 성분표) 신고: SDK 수집 항목을 Google 공식 문서 기준으로 작성
- [ ] SKAdNetwork 식별자 목록(`SKAdNetworkItems`) 필요 여부 확인 (현재 미설정)
- [ ] 실기기에서 `getRequestConfiguration()` 읽기 결과가 G / child로 돌아오는지 확인
      (불일치하면 서비스가 광고를 꺼 버린다 — 안전하지만 iOS 광고가 영원히 꺼진다)

## 동의 (GDPR/EEA·UK 등) — UMP 구현됨 (PART 5B-2), 실기기 미검증

- [x] 동의가 필요한 지역의 처리 방식 결정 — 모든 이용자 TFUA=true + 광고 요청 아동 처리 (2026-11-03)
- [ ] 동의 흐름이 구현되기 전까지 Release 광고 금지 — 현재 동의 완료를 가정하지 않으며,
      `releaseCleared`가 비어 있어 Release 요청 자체가 없다
- [ ] 개인정보처리방침에 광고 SDK와 수집 항목 명시

## 배너 배치 (PART 3)

`BannerAdArea` (lib/widgets/banner_ad_area.dart)를 화면별로 명시적으로 감싼 곳에만 배너가 있다.
공통 Scaffold에는 없다. 배치 목록은 `test/banner_ad_area_test.dart`가 고정한다.

| 화면 | 배너 |
|---|---|
| Detective Archives (`/seasons`) | 있음 |
| 탐정 보드 (`SeasonScreen`, 시즌 시작 후 보드 상태) | 있음 |
| 사건 목록 CASE FILES (`/episodes`) | 있음 |
| 타이틀, 월드맵, 시즌 커버, 프롤로그, 스토리, 대화·현장·퍼즐·미션, 사건 결과, 엔딩, 힌트/코인 상점 | 없음 |

- 첫 배너 화면에서 `AdService.start()` (지연 초기화). 앱 시작 시 SDK 호출 없음
- 로드 성공 후에만 하단 띠 표시. 로딩 중·실패·광고 꺼짐이면 영역 없음
- 띠는 화면 콘텐츠 아래(겹치지 않음), 시스템 내비게이션 영역 위, 상단 구분선 + 8px 간격
- 광고 주변에 클릭 유도 문구 없음
- 화면 이탈 시 광고 dispose, 재진입 시 새 광고 객체, 회전 시 새 폭으로 재요청

- [ ] **사건 목록·보드의 주 버튼(BEGIN/CONTINUE INVESTIGATION 등)과 배너 사이 간격이 실수 클릭 방지에 충분한지**
      실기기에서 확인 (AdMob "광고 배치" 정책: 버튼 바로 옆 배치 금지). 부족하면 간격을 늘리거나 그 화면을 제외
- [ ] Families 정책상 아동 앱의 배너가 "게임 플레이를 방해하지 않는 위치"인지 Play Console 검토 기준으로 확인

## 보상형 광고 GET COINS (PART 4)

- 위치: 퍼즐 힌트 다이얼로그에서 코인이 부족할 때만 `GET COINS` + "Watch an ad to earn 30 Coins"
- 플레이어가 버튼을 눌렀을 때만 표시. 시청하지 않아도 게임 진행에 영향 없음(힌트는 선택 사항)
- 지급: SDK `onUserEarnedReward`에서만 30 Coins(고정, SDK 보상값 무시), 광고 인스턴스당 1회
- Release: `releaseCleared`가 비어 있어 버튼과 광고 문구가 아예 나타나지 않음

- [ ] **아동 대상 앱의 보상형 광고 허용 여부** (Play Families 광고 정책: 보상형 광고는 허용되나 "광고를 보도록
      압박하거나 게임 진행에 필수"이면 안 됨) — 현재 문구·배치가 기준에 맞는지 Play Console 검토 전 확인
- [ ] **보호자 게이트 재사용 검토 결과**: 기존 `ParentGate`는 보호자 전용 화면(게임 마스터, 리포트)에 쓰인다.
      광고 시청 자체에는 붙이지 않았다(Families 정책의 보호자 게이트 요구는 앱 밖 이동·구매 대상이며,
      광고 안의 클릭은 인증 SDK가 처리). 정책 담당 확인 후 필요하면 GET COINS 앞에 추가
- [ ] 앱 강제 종료 한계: 보상은 콜백 즉시 로컬 저장하지만, 콜백 전에 앱이 죽으면 지급되지 않음.
      서버 검증(SSV)이 없으므로 기기 조작에 의한 부정 지급을 막을 수 없음
- [ ] 실기기에서 테스트 보상형 광고 재생·보상 콜백·닫기 확인 (PART 5A·5B 미검증)

## 공통

- [ ] AdMob 계정·앱 등록, 실제 광고 단위 ID를 `config/ads.local.json`에 입력 (저장소 제외)
- [ ] 보호자 게이트 뒤가 아닌 위치의 광고 클릭 동작(외부 이동) 정책 확인 — 배너는 PART 3에서
      보호자 게이트 없이 노출됨. 아동 대상 앱에서 허용되는지 확인 전까지 Release 광고 금지 유지
