# AdMob 정책 체크리스트 (World Mystery, 8–12세)

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

## Android — Google Play Families (확인 필요)

- [ ] Play Console 타깃 연령층 설정(8–12세 포함)과 Families 정책 적용 여부 확인
- [ ] Google Mobile Ads SDK 버전(25.5.0, plugin 9.2.0)이 Families 자체 인증 광고 SDK 목록 조건을 충족하는지 확인
- [ ] AdMob 콘솔: 앱 단위 "아동 대상" 설정, 광고 콘텐츠 등급 G, 민감 카테고리 차단 확인
- [ ] AdMob 콘솔: 미디에이션을 쓰지 않음(또는 쓰는 네트워크도 Families 인증) 확인
- [ ] Release 병합 매니페스트에 `com.google.android.gms.permission.AD_ID`가 없는지 확인
      (Debug 병합 매니페스트에서는 제거 확인됨, 2026-11-02)
- [ ] SDK가 추가하는 Privacy Sandbox 권한 `android.permission.ACCESS_ADSERVICES_AD_ID`
      (및 ATTRIBUTION/TOPICS 등)도 제거해야 하는지 결정 — 현재 병합 매니페스트에 남아 있음
- [ ] Data safety 신고: SDK가 수집하는 항목(기기 식별자/앱 상호작용/진단 등) — Google 공식 문서 기준으로 작성
- [ ] 광고 포함 앱 표시("광고 포함") 설정

## iOS — App Store (확인 필요, Windows에서 검증 불가)

- [ ] **Kids Category 등록 여부 결정.** App Review Guidelines 1.3 / 5.1.4는 Kids Category 앱의 제3자 광고를
      엄격히 제한한다. AdMob 사용이 허용되는지 최신 가이드라인으로 확인하기 전까지 iOS Release 광고 금지
- [ ] ATT 프롬프트를 띄우지 않는 구성이 심사 기준에 맞는지 확인 (아동 대상 앱은 추적 금지)
- [ ] Google Mobile Ads SDK의 Privacy Manifest(PrivacyInfo.xcprivacy) 포함 여부를 Xcode 빌드에서 확인
- [ ] App Privacy(영양 성분표) 신고: SDK 수집 항목을 Google 공식 문서 기준으로 작성
- [ ] SKAdNetwork 식별자 목록(`SKAdNetworkItems`) 필요 여부 확인 (현재 미설정)
- [ ] 실기기에서 `getRequestConfiguration()` 읽기 결과가 G / child로 돌아오는지 확인
      (불일치하면 서비스가 광고를 꺼 버린다 — 안전하지만 iOS 광고가 영원히 꺼진다)

## 동의 (GDPR/EEA·UK 등) — 미구현

- [ ] 동의가 필요한 지역의 처리 방식 결정 (UMP `ConsentInformation` + 연령 태그 등)
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

## 공통

- [ ] AdMob 계정·앱 등록, 실제 광고 단위 ID를 `config/ads.local.json`에 입력 (저장소 제외)
- [ ] 보호자 게이트 뒤가 아닌 위치의 광고 클릭 동작(외부 이동) 정책 확인 — 배너는 PART 3에서
      보호자 게이트 없이 노출됨. 아동 대상 앱에서 허용되는지 확인 전까지 Release 광고 금지 유지
