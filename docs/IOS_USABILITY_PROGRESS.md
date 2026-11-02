# World Mystery — iOS 사용성 개선 진행 기록

- 기준: `/mobile-ios-design` 앱 전체 감사 결과(2026-11-02)
- 작업일: 2026-11-02, 기준 커밋 `d9bb7ee`(작업 중 들어온 프롤로그 커밋 3개는 이번 변경 파일과 겹치지 않음)
- 범위: iOS 뒤로 가기 스와이프, iOS 막다른 화면(세계지도·스토리 인트로), iPad 방향 설정, 읽기 글자 확대 상한
- 바꾸지 않은 것: 스토리·퍼즐·정답, 미션 ID, 저장 데이터 형식, 사운드, 라우트 구조와 페이드 전환

## 1. iOS 뒤로 가기 스와이프

### Flutter 기본 제스처를 쓰지 않은 이유

Flutter의 iOS 스와이프는 `CupertinoPageRoute`가 제공한다. `ModalRoute.popGestureEnabled`(flutter/lib/src/widgets/routes.dart)는 다음 경우 제스처를 끈다.

| 조건 | 이 게임에서 해당하는 화면 |
|---|---|
| `isFirst` (아래에 화면이 없음) | `go`로 이동한 모든 화면 |
| `popDisposition == doNotPop` (PopScope가 뒤로 가기를 직접 처리) | `BackTo`를 쓰는 모든 화면, 미션맵, 미션 단계 |

이 조건을 피하려면 라우트를 중첩 구조로 다시 짜고 `BackTo` 정책도 걷어내야 한다. 그러면 화면 전환도 Cupertino 슬라이드로 바뀐다. 기본 제스처로는 어느 화면도 해결되지 않아, 커스텀 제스처를 앱 전체에 한 곳만 둔다.

### 구현

- [lib/widgets/edge_swipe_back.dart](../lib/widgets/edge_swipe_back.dart) `EdgeSwipeBack`: 왼쪽 20pt 안에서 시작한 드래그만 받는다. 오른쪽으로 48pt 이상 이동한 상태에서 손을 떼면 뒤로 간다. 위아래 이동이 더 크거나, 왼쪽으로 되돌아가거나, 48pt에 못 미치면 취소된다.
- [lib/app.dart](../lib/app.dart): iOS(웹 제외)에서만 라우터 전체를 감싼다. 동작은 `routerDelegate.popRoute()`, 즉 Android 뒤로 가기 버튼과 같은 경로다. 따라서 화면별 목적지(`BackTo`), 미션 단계 되돌리기, 미션맵의 "Leave the case?" 확인, 이동 중 무시 동작이 그대로 적용된다. 입력값과 진행 상태도 Android 뒤로 가기와 똑같이 다뤄진다.
- 퍼즐과의 충돌 방지: 48pt는 다른 제스처가 손가락을 가져가는 거리보다 길다. 가로 드래그·`Draggable`·`Slider`·`PageView`는 18pt, 팬·`InteractiveViewer`는 36pt에서 먼저 이긴다. 가장자리에서 시작해도 퍼즐 드래그, 지도 팬·핀치, 슬라이더, 페이지 넘김은 그 위젯이 가져간다.
  - 그래서 세계지도와 미션의 둘러보기 그림처럼 화면 가장자리까지 덮는 팬 영역 위에서는 스와이프가 뒤로 가기 대신 그림을 움직인다. 이런 화면은 화면 안의 뒤로 가기·메뉴 버튼을 쓴다.
- Android: 위젯이 붙지 않는다. 기존 뒤로 가기 버튼과 예측형 뒤로 가기는 그대로다.

## 2. iOS 막다른 화면

- 세계지도: 헤더 오른쪽에 메뉴 버튼(48pt, VoiceOver 라벨 "Menu")을 추가했다. 미션맵 메뉴와 같은 종이 시트를 쓰며 항목은 Sound effects, My detective, Title screen이다.
  - 미션맵 메뉴의 시트·항목·소리 스위치를 [lib/widgets/paper_menu.dart](../lib/widgets/paper_menu.dart)로 옮겨 두 화면이 함께 쓴다. 미션맵 메뉴의 내용·순서·동작은 바뀌지 않았다.
- 스토리 인트로: SKIP과 같은 줄 왼쪽에 뒤로 가기 버튼을 추가했다(48pt, Safe Area 안, VoiceOver 라벨 "Back to case files"). `Navigator.maybePop`을 호출하므로 Android 뒤로 가기와 똑같이 `BackTo` 정책에 따라 사건 파일로 돌아간다.

## 3. iPad 설정 — 멀티태스킹 지원 포기

[ios/Runner/Info.plist](../ios/Runner/Info.plist)

- `UIRequiresFullScreen = true` 추가. **iPad의 Split View, Slide Over, Stage Manager 창 크기 조절 등 멀티태스킹 지원을 포기하는 설정이다.** 세로 전용으로 설계한 화면이 가로로 돌거나 좁은 창으로 찌그러지는 것을 막기 위해서다.
- iPhone 방향: Portrait만 남김(Landscape Left/Right 제거).
- iPad 방향: Portrait만 남김(Upside Down, Landscape 제거).
- Flutter의 `SystemChrome.setPreferredOrientations([portraitUp])`(lib/main.dart)는 그대로 두어 네이티브 설정과 같다.
- 주의: Apple은 iPadOS 26부터 `UIRequiresFullScreen`을 지원 중단(deprecated) 예정 항목으로 안내했다. 앞으로의 iPadOS에서는 이 키가 무시되어 창 크기 조절이 강제될 수 있으므로, iPad 레이아웃 대응은 별도 과제로 남는다.

## 4. 읽기 글자 확대

- 앱 전체 상한 1.3은 유지하고 토큰 `AppTextScale.page`로 옮겼다.
- 새 상한 `AppTextScale.reading = 1.6`과 [lib/widgets/reading_text_scale.dart](../lib/widgets/reading_text_scale.dart)를 추가하고, 스크롤 안에서 줄바꿈되는 읽기 글에만 적용했다.
  - 노트북 단서 카드(ClueCard)
  - 증거 확대 화면의 설명 문단과 각인 문단
- 적용하지 않은 것: 탭, 표지, 증거·배지 그리드 칸(비율 고정), 빈 칸(높이 고정), 종이 그림 위에 쓰인 문장, 버튼.
- 오답 햅틱은 이번 작업에 넣지 않았다.

## 5. 검증

모든 검증은 Windows의 Flutter 위젯 테스트로 했다. iOS는 `TargetPlatformVariant.only(TargetPlatform.iOS)`로 흉내 냈다. **iOS 시뮬레이터와 실기기에서는 확인하지 않았다.**

| 검증 | 결과 |
|---|---|
| `flutter analyze` | 문제 없음 |
| [test/edge_swipe_back_test.dart](../test/edge_swipe_back_test.dart)(신규): 가장자리·거리·방향·취소·탭, 제스처 유형 6종 충돌, 세로 스크롤 | 12/12 통과 |
| [test/back_navigation_test.dart](../test/back_navigation_test.dart): 기존 시나리오 + iOS 스와이프 경로 3개 + 스토리 인트로 버튼·스와이프 + 미션맵 확인 + 세계지도 팬 + Android 스와이프 무반응 | 23/23 통과 |
| [test/world_map_test.dart](../test/world_map_test.dart)(메뉴 테스트 추가) + [test/map_menu_sheet_test.dart](../test/map_menu_sheet_test.dart) | 33/33 통과 |
| [test/reading_text_scale_test.dart](../test/reading_text_scale_test.dart)(신규): 320×568 ~ 390×844, 시스템 글자 1.0/1.5/2.0 | 8/8 통과 |
| 관련 회귀 15개 파일(상태바, 레이아웃, 사건 파일, How to Play, 노트북 증거 등) | 245/245 통과 |
| 전체 `flutter test` | 3,452 통과 / 4 실패. 4개 모두 기존 실패(`d9bb7ee` 원본에서도 똑같이 실패): `audit_fix_d4_d5_test` D5, `final_small_pass_test` 17번, `season_planner_test` 2개 |

### iOS 기기에서 확인할 것

1. 미션 화면과 사건 파일 등에서 왼쪽 가장자리 스와이프 → 한 단계 뒤로(Android 뒤로 가기와 같은 목적지)
2. 미션맵에서 스와이프 → "Leave the case?" 확인
3. 세계지도와 둘러보기 그림 위에서는 가장자리 스와이프가 그림을 움직이는지(의도된 동작)
4. 세계지도 메뉴 → 소리, 탐정 설정(돌아오면 세계지도), 타이틀
5. 스토리 인트로 뒤로 가기 버튼 → 사건 파일
6. VoiceOver: "Menu", "Back to case files" 라벨, 두 손가락 Z 제스처(되돌리기)의 동작
7. 퍼즐 드래그(글자 조각, 톱니, 슬라이더, 확대 그림)를 화면 왼쪽 끝에서 시작했을 때 퍼즐이 그대로 움직이는지
8. iPhone·iPad 세로 고정, iPad에서 Split View·Slide Over가 뜨지 않는지
9. 설정 > 손쉬운 사용 > 더 큰 텍스트에서 노트북 단서와 증거 확대 화면
