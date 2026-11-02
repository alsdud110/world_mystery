import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's User Messaging Platform, as the game uses it (the plugin in the
/// app, a stand-in in tests). Each call completes when the SDK answers.
abstract interface class ConsentSdk {
  /// Completes when the consent information is updated; fails with the
  /// SDK's [FormError] otherwise.
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params);

  /// Shows the consent form if one is required; the form's error, or null.
  Future<FormError?> loadAndShowConsentFormIfRequired();

  Future<bool> canRequestAds();

  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus();

  /// The privacy options form; its error, or null.
  Future<FormError?> showPrivacyOptionsForm();
}

class UmpConsentSdk implements ConsentSdk {
  const UmpConsentSdk();

  @override
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params) {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        if (!done.isCompleted) done.complete();
      },
      (error) {
        if (!done.isCompleted) done.completeError(error);
      },
    );
    return done.future;
  }

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() {
    final done = Completer<FormError?>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (!done.isCompleted) done.complete(error);
    }).catchError((Object e) {
      if (!done.isCompleted) done.completeError(e);
    });
    return done.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() =>
      ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

  @override
  Future<FormError?> showPrivacyOptionsForm() {
    final done = Completer<FormError?>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (!done.isCompleted) done.complete(error);
    }).catchError((Object e) {
      if (!done.isCompleted) done.completeError(e);
    });
    return done.future;
  }
}

/// The players' consent to ads, gathered once per app run through the UMP
/// SDK, before the ads SDK starts ([AdService.start] asks [gather]).
///
/// Every player is treated as under the age of consent
/// ([tagForUnderAgeOfConsent]), as every ad request is child-treated: the
/// UMP SDK then asks no one for consent, so no message contrary to the
/// children's protection is shown. Should a form still be required, the SDK
/// shows it.
///
/// Fail-closed: ads may be requested only when the update succeeded and
/// `canRequestAds()` says so. An update that fails or times out, an error,
/// or false turns ads off for the run.
class AdConsent extends ChangeNotifier {
  AdConsent(this._sdk, {this.timeout = const Duration(seconds: 10)});

  /// Every player is treated as a child: see [AdConsent].
  static const tagForUnderAgeOfConsent = true;

  final ConsentSdk _sdk;

  /// How long the update and each read may take (the form, which waits on
  /// the player, has none).
  final Duration timeout;

  Future<bool>? _gather;
  bool _allowsAds = false;
  bool _privacyOptionsRequired = false;
  bool _disposed = false;

  /// The last `canRequestAds()` answer: false until [gather] allows ads, and
  /// read again after the privacy options form.
  bool get allowsAds => _allowsAds;

  /// Whether a privacy options entry point must be offered (known once
  /// [gather] has run).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Updates the consent information, shows a form only if one is required,
  /// and says whether ads may be requested. Called again, it gives the first
  /// call's answer: once per app run.
  Future<bool> gather() => _gather ??= _run();

  Future<bool> _run() async {
    try {
      await _sdk
          .requestConsentInfoUpdate(ConsentRequestParameters(tagForUnderAgeOfConsent: tagForUnderAgeOfConsent))
          .timeout(timeout);
    } catch (e) {
      debugPrint('Ads off: consent not updated (${e is FormError ? e.errorCode : e.runtimeType})');
      return false;
    }
    try {
      final error = await _sdk.loadAndShowConsentFormIfRequired();
      if (error != null) debugPrint('Consent form: ${error.errorCode}');
    } catch (e) {
      debugPrint('Consent form not shown (${e.runtimeType})');
    }
    // What the form left (or its error) is read back: the only answer that counts.
    final bool allowed;
    try {
      allowed = await _sdk.canRequestAds().timeout(timeout);
    } catch (e) {
      debugPrint('Ads off: consent not read (${e.runtimeType})');
      return false;
    }
    _allowsAds = allowed;
    await _readPrivacyOptions();
    if (!allowed) debugPrint('Ads off: consent does not allow ad requests');
    return allowed;
  }

  Future<void> _readPrivacyOptions() async {
    try {
      final status = await _sdk.getPrivacyOptionsRequirementStatus().timeout(timeout);
      _privacyOptionsRequired = status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      _privacyOptionsRequired = false;
    }
    if (!_disposed) notifyListeners();
  }

  /// The privacy options form, from the entry point offered while
  /// [privacyOptionsRequired]. False when it could not be shown.
  Future<bool> showPrivacyOptions() async {
    if (!_privacyOptionsRequired) return false;
    try {
      final error = await _sdk.showPrivacyOptionsForm();
      if (error != null) debugPrint('Privacy options: ${error.errorCode}');
      return error == null;
    } catch (e) {
      debugPrint('Privacy options not shown (${e.runtimeType})');
      return false;
    } finally {
      // The choice may have changed: ads follow it from the next request on.
      try {
        _allowsAds = _allowsAds && await _sdk.canRequestAds().timeout(timeout);
      } catch (_) {
        _allowsAds = false;
      }
      await _readPrivacyOptions();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
