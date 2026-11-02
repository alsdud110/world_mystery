import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/ad_config.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/core/utils/ad_consent.dart';
import 'package:world_mystery/core/utils/ad_service.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'fake_consent_sdk.dart';
import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// The ads privacy options entry point: in the Game Master page (behind the
/// parent gate), only when the UMP SDK requires one; and the consent is
/// updated at launch without starting the ads SDK.
void main() {
  late WidgetRef appRef;
  late FakeConsentSdk ump;

  Future<void> openApp(WidgetTester t, {required PrivacyOptionsRequirementStatus status}) async {
    t.view.physicalSize = const Size(1080, 1920);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    ump = FakeConsentSdk()..privacyStatus = status;
    await t.pumpWidget(ProviderScope(
      overrides: [
        ...await testOverrides(adsOff: false),
        adServiceProvider.overrideWith((ref) {
          final service = AdService(
            sdk: const GoogleMobileAdsSdk(),
            units: AdConfig.testAndroid,
            requestsAllowed: true,
            consent: AdConsent(ump),
          );
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> openGameMaster(WidgetTester t) async {
    appRef.read(gameMasterAccessProvider.notifier).grant();
    appRef.read(routerProvider).go(Routes.gameMaster);
    await wait(t);
  }

  final entry = find.byKey(const ValueKey('ad-privacy-options'));

  testWidgets('the launch updates the consent once, and starts no ads SDK', (t) async {
    await openApp(t, status: PrivacyOptionsRequirementStatus.notRequired);
    expect(ump.updates, 1);
    expect(ump.params.single.tagForUnderAgeOfConsent, isTrue);
    expect(appRef.read(adServiceProvider).state, AdServiceState.idle);
  });

  testWidgets('not required: no privacy options entry in Game Master', (t) async {
    await openApp(t, status: PrivacyOptionsRequirementStatus.notRequired);
    await openGameMaster(t);
    expect(entry, findsNothing);
  });

  testWidgets('required: the entry is in Game Master and opens the SDK form', (t) async {
    await openApp(t, status: PrivacyOptionsRequirementStatus.required);
    await openGameMaster(t);
    await t.dragUntilVisible(entry, find.byType(ListView).last, const Offset(0, -200));
    await t.drag(find.byType(ListView).last, const Offset(0, -200));
    await wait(t);
    await t.tap(entry);
    await wait(t);
    expect(ump.calls, contains('privacyForm'));
  });
}
