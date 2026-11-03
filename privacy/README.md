# World Mystery Privacy Policy Page

Bilingual Korean/English privacy-policy draft: `privacy/index.html`.

## Current implementation reflected in the draft

- World Mystery is positioned for English learners of different ages, including children and adults.
- Google AdMob banner and optional rewarded ads are integrated; **release ad requests remain disabled**.
- UMP consent checks precede ad requests; the privacy-options entry point is in the parent-gated Game Master screen.
- Child-protective treatment, G-rated content limits, and non-personalized ad requests are configured for all users.
- Android Debug merged manifest excludes AD_ID and the three ACCESS_ADSERVICES permissions. This does not prove that all SDK data collection stops.
- Game progress, coins, and hints are stored locally. Third-party ad SDK processing is separately disclosed.
- Android emulator test ads, rewarded playback, and 30-coin credit have been user-verified. EEA/UK, iOS Archive, and production-ad validation remain outstanding.

## Publishing

The privacy policy is prepared for publication with an effective date of November 3, 2026. Production ad requests remain disabled pending policy and platform review. The public URL must be verified after GitHub Pages is enabled.

A publication copy is located at `docs/privacy/index.html`. To publish it, configure GitHub Pages: **Settings → Pages → Deploy from a branch → main → /docs → Save**. The expected URL is `https://alsdud110.github.io/world_mystery/privacy/`, but it must be opened and verified before submitting it to stores.

## Release blockers

- Confirm final Android/iOS SDK data flows, any other data-collecting SDKs, and device backup behavior.
- Confirm actual target-audience declarations and ad compliance for child users on Google Play and Apple, including whether iOS third-party ads are permissible.
- Verify UMP regional behavior, console messages, privacy-options UI, and real-device ad behavior.
- Verify Android Release merged manifest and iOS Xcode Archive/App Privacy Report.
- Reassess legal sufficiency of operator identity, retention, international-transfer, and user-rights disclosures for each distribution region; effective date is November 3, 2026.
- Align Google Play Data safety and App Store App Privacy answers with the final binaries and this policy.

This PR only updates documentation; it does not turn on production advertising.
