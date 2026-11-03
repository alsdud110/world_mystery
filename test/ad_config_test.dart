import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/ad_config.dart';

void main() {
  const realAndroid = AdUnitIds(
    banner: 'ca-app-pub-1111111111111111/1111111111',
    rewarded: 'ca-app-pub-1111111111111111/2222222222',
  );
  const realIos = AdUnitIds(
    banner: 'ca-app-pub-1111111111111111/3333333333',
    rewarded: 'ca-app-pub-1111111111111111/4444444444',
  );
  const configured = {AdPlatform.android: realAndroid, AdPlatform.ios: realIos};

  group('AdConfig.resolve', () {
    test('debug and profile use the sample ad units, even with real IDs passed', () {
      expect(
        AdConfig.resolve(platform: AdPlatform.android, release: false, configured: configured),
        AdConfig.testAndroid,
      );
      expect(
        AdConfig.resolve(platform: AdPlatform.ios, release: false, configured: configured),
        AdConfig.testIos,
      );
    });

    test('release uses the configured ad units', () {
      expect(
        AdConfig.resolve(platform: AdPlatform.android, release: true, configured: configured),
        realAndroid,
      );
      expect(
        AdConfig.resolve(platform: AdPlatform.ios, release: true, configured: configured),
        realIos,
      );
    });

    test('release never falls back to the sample ad units', () {
      for (final ids in [
        const AdUnitIds(banner: '', rewarded: ''),
        AdUnitIds(banner: realIos.banner, rewarded: ''),
        AdConfig.testIos,
        AdUnitIds(banner: realIos.banner, rewarded: AdConfig.testIos.rewarded),
        const AdUnitIds(banner: 'ca-app-pub-1111111111111111~1', rewarded: 'not-an-id'),
      ]) {
        expect(
          AdConfig.resolve(
            platform: AdPlatform.ios,
            release: true,
            configured: {AdPlatform.ios: ids},
          ),
          isNull,
        );
      }
      expect(
        AdConfig.resolve(platform: AdPlatform.android, release: true, configured: const {}),
        isNull,
      );
    });

    test('other platforms show no ads', () {
      expect(AdConfig.resolve(platform: null, release: false, configured: configured), isNull);
      expect(AdConfig.resolve(platform: null, release: true, configured: configured), isNull);
    });
  });

  test('the sample ad units are Google\'s and never count as real', () {
    for (final id in [
      AdConfig.testAndroid.banner,
      AdConfig.testAndroid.rewarded,
      AdConfig.testIos.banner,
      AdConfig.testIos.rewarded,
    ]) {
      expect(id, startsWith('${AdConfig.samplePublisher}/'));
      expect(AdConfig.isRealAdUnitId(id), isFalse);
    }
  });

  test('tests build without dart-defines, so they get the sample ad units', () {
    // flutter test is not a release build.
    final current = AdConfig.current;
    expect(
      current == null || current == AdConfig.testAndroid || current == AdConfig.testIos,
      isTrue,
    );
  });

  test('config/ads.example.json names the six keys with placeholder values', () {
    final example =
        jsonDecode(File('config/ads.example.json').readAsStringSync()) as Map<String, dynamic>;
    expect(example.keys.toSet(), {
      'ADMOB_ANDROID_APP_ID',
      'ADMOB_ANDROID_BANNER_ID',
      'ADMOB_ANDROID_REWARDED_ID',
      'ADMOB_IOS_APP_ID',
      'ADMOB_IOS_BANNER_ID',
      'ADMOB_IOS_REWARDED_ID',
    });
    for (final value in example.values) {
      expect(value, contains('XXXX'));
    }
  });

  test('config/ads.local.json is git-ignored', () {
    final ignored = File('.gitignore').readAsLinesSync().map((l) => l.trim());
    expect(ignored, contains('/config/ads.local.json'));
  });

  group('native ads settings', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    int count(String source, String text) => text.allMatches(source).length;

    test('Android delays the SDK\'s app measurement, once', () {
      expect(count(manifest, 'com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT'), 1);
      expect(
        manifest,
        matches(RegExp(r'android:name="com\.google\.android\.gms\.ads\.DELAY_APP_MEASUREMENT_INIT"\s+android:value="true"')),
      );
    });

    test('iOS delays the SDK\'s app measurement, once', () {
      expect(count(plist, '<key>GADDelayAppMeasurementInit</key>'), 1);
      expect(plist, matches(RegExp(r'<key>GADDelayAppMeasurementInit</key>\s*<true/>')));
    });

    test('the App IDs are still injected by the builds, and the ad permissions still removed', () {
      expect(manifest, matches(RegExp(r'com\.google\.android\.gms\.ads\.APPLICATION_ID"\s+android:value="\$\{admobAppId\}"')));
      for (final permission in [
        'com.google.android.gms.permission.AD_ID',
        'android.permission.ACCESS_ADSERVICES_AD_ID',
        'android.permission.ACCESS_ADSERVICES_ATTRIBUTION',
        'android.permission.ACCESS_ADSERVICES_TOPICS',
      ]) {
        expect(manifest, matches(RegExp('android:name="${RegExp.escape(permission)}"\\s+tools:node="remove"')),
            reason: permission);
      }
      // Info.plist holds the sample App ID; the build phase sets the real one
      // in a release, and touches nothing else.
      expect(count(plist, '<key>GADApplicationIdentifier</key>'), 1);
      expect(plist, contains('${AdConfig.samplePublisher}~1458002511'));
      final script = File('ios/scripts/admob_app_id.sh').readAsStringSync();
      expect(RegExp(r'PlistBuddy -c "(\w+) :(\w+)').allMatches(script).map((m) => '${m[1]} ${m[2]}'),
          ['Set GADApplicationIdentifier']);
    });
  });
}
