# World Mystery Privacy Policy Page

Bilingual Korean/English privacy-policy draft: `privacy/index.html`.

## Current implementation reflected in the draft

- World Mystery is positioned for English learners of different ages, including children and adults.
- Google AdMob banner and optional rewarded ads are integrated; **release ad requests remain disabled**.
- UMP consent checks precede ad requests; the privacy-options entry point is in the parent-gated Game Master screen.
- Child-protective treatment, G-rated content limits, and non-personalized ad requests are configured for all users.
- Android Debug merged manifest excludes AD_ID and the three ACCESS_ADSERVICES permissions. This does not prove that all SDK data collection stops.
- Game progress, coins, and hints are stored locally. Third-party ad SDK processing is separately disclosed.
- No live-device, regional EEA/UK, iOS Archive, or production-ad validation has been completed.

## Publishing

This PR remains a **draft**. The page includes `noindex` and a pre-release notice. Do not merge, remove these notices, enable GitHub Pages, or advertise a public policy URL until the actual release configuration and legal disclosures are reviewed.

GitHub Pages can use `main` / `docs` only after moving the page to `docs/privacy/index.html`, or a separate deployment workflow can publish the existing path. Verify the live URL before using it in store listings.

## Release blockers

- Confirm final Android/iOS SDK data flows, any other data-collecting SDKs, and device backup behavior.
- Confirm actual target-audience declarations and ad compliance for child users on Google Play and Apple, including whether iOS third-party ads are permissible.
- Verify UMP regional behavior, console messages, privacy-options UI, and real-device ad behavior.
- Verify Android Release merged manifest and iOS Xcode Archive/App Privacy Report.
- Complete applicable legal operator identity, retention, international-transfer, and user-rights disclosures, and set the effective date.
- Align Google Play Data safety and App Store App Privacy answers with the final binaries and this policy.

This PR only updates documentation; it does not turn on production advertising.
