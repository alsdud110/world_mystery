import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:world_mystery/core/utils/ad_consent.dart';

/// The UMP SDK in tests: records every call, in order; each step can fail,
/// hang or answer otherwise. By default consent is not required and ads may
/// be requested.
class FakeConsentSdk implements ConsentSdk {
  final List<String> calls = [];
  final List<ConsentRequestParameters> params = [];

  FormError? updateError;
  Completer<void>? hangUpdate;
  FormError? formError;
  bool throwOnForm = false;

  /// What `canRequestAds()` answers, in turn (the last one repeats).
  List<bool> canRequest = [true];
  bool failCanRequest = false;

  PrivacyOptionsRequirementStatus privacyStatus = PrivacyOptionsRequirementStatus.notRequired;
  FormError? privacyFormError;

  /// Called when the privacy options form "closes" (the player's choice).
  void Function()? onPrivacyForm;

  int get updates => calls.where((c) => c == 'update').length;

  @override
  Future<void> requestConsentInfoUpdate(ConsentRequestParameters params) async {
    calls.add('update');
    this.params.add(params);
    if (hangUpdate != null) await hangUpdate!.future;
    if (updateError != null) throw updateError!;
  }

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async {
    calls.add('form');
    if (throwOnForm) throw Exception('no activity');
    return formError;
  }

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequestAds');
    if (failCanRequest) throw Exception('channel');
    return canRequest.length > 1 ? canRequest.removeAt(0) : canRequest.single;
  }

  @override
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() async {
    calls.add('privacyStatus');
    return privacyStatus;
  }

  @override
  Future<FormError?> showPrivacyOptionsForm() async {
    calls.add('privacyForm');
    onPrivacyForm?.call();
    return privacyFormError;
  }
}

/// Consent that allows ads, for tests about something else.
AdConsent allowingConsent() => AdConsent(FakeConsentSdk());
