# Edu Connect 1.0.15 (16): release review

Prepared 30 October 2026. Package: `educonnect.com`.

## Changes

- Retained removal of medical-profile screens and collection endpoints. Existing historical records were not deleted.
- Added in-app reporting from conversations, notices, journal entries, assignments, documents and Help center.
- Added server-enforced direct-message blocking and unblocking, including teacher broadcasts and notification visibility.
- Added a platform-administrator safety-report queue at https://admin.chewetechnologies.co.zw/moderation. Sign into the normal administration portal as a platform administrator first. Ordinary users and school administrators cannot read this central queue.
- Moderators can record review outcomes and remove objectionable direct messages from both participants. Other school content should be managed through the existing school administration tools.
- Deployed the previously missing account-deletion and support-report endpoints. Deletion removes private messages and support reports while preserving school records as disclosed.
- Updated the terms and privacy policy to describe reporting and blocking. Policy acceptance version changed so existing users see the updated consent.
- Preserved HTTPS API connections, existing app policy URLs and the release upload certificate.

## Verification

The initial backend suite passed 118 tests. With the new safety tests it passed 121 tests / 681 assertions. Final results are saved alongside this report.

Final verification: all 92 mobile tests and all 121 backend tests passed. Flutter analysis reported no issues. Three outdated mobile test selectors were corrected during the full-suite run; no tests were skipped to obtain this result. Release manifest: version 1.0.15, build 16, target API 36.

Live server verification passed production/debug configuration, SQLite integrity, school-scoped contacts, messaging, blocking, unblocking, safety reports, moderator authorization, review, account deletion, associated-message deletion and retention of learner records. All temporary verification records were rolled back. Email and queued jobs were faked during verification; no real messages or SMS were sent.

Nginx/PHP were active. Notification and payment workers were active at inspection. Public policy, terms, deletion and moderation pages returned HTTP 200; authenticated mutation endpoints rejected anonymous requests with HTTP 401. Endpoint existence is not proof of external-provider delivery.

## Before submitting in Play Console

1. Replace build 12/13/14 with build 16 in the closed-testing release. Check every active track for older bundles with removed functionality.
2. Review the Health apps declaration using the actual new functionality. Medical profiles are removed. Classroom daily-care notes (including meals, naps and observations) still exist: do not make false declarations about remaining data or functionality. If Google still considers the app within a restricted category, request clarification or use the required organization account.
3. Review Data safety against actual behavior: personal information and user IDs, messages, learner photos, uploaded content/documents, transaction history, read/dismissal interactions, optional support diagnostics and Firebase installation/push identifiers. Review videos/audio if those uploads are enabled. External checkout card details are not accessed by this app. Service-provider and user-initiated transfer exceptions require their actual conditions to hold.
4. Choose Education if it accurately represents the app. Verify all Financial features and government declarations. School payments and physical-uniform checkout are not banking or lending services; do not select financial-product categories that the app does not offer.
5. Supply working reviewer teacher and guardian accounts with fictional sample learner records. The reviewer must not need access to your personal phone or root/server login. The reviewer accounts and submitted Console declarations could not be inspected from this environment.
6. Staff the safety-report process. Review and act on reports, document decisions, and confirm the support inbox receives reports. Tools alone do not fulfill the ongoing human-moderation requirement.
7. Confirm the operator/contact details and retention commitments in the policy. Existing 30-day request and 90-day backup statements require an operational process; backup rotation and support response times were not independently established by this audit.
8. Independently test on physical devices via Google Play: notification delivery, SMS login, file/photo selection, PesePay checkout, order status and update installation. No real payment or SMS transaction was initiated during this audit. Payment live/sandbox settings were not changed.
9. Run the closed test with real users, collect feedback, and follow the production-access criteria shown by Play Console.

This is an engineering and policy-readiness review, not a certification or assurance of Google approval. The reported rejection was for build 12; a new AAB alone does not change existing Play Console declarations.

## Official policy references

- Play Console Requirements: https://support.google.com/googleplay/android-developer/answer/10788890
- User-generated content: https://support.google.com/googleplay/android-developer/answer/9876937
- User data: https://support.google.com/googleplay/android-developer/answer/10144311
- Account deletion: https://support.google.com/googleplay/android-developer/answer/13327111

## Release notes

Release name: `1.0.15 (16) - Closed Testing`

```text
<en-US>
• Added controls to report content and users.
• Added blocking and unblocking for direct messages.
• Improved account deletion and support reporting.
• Updated privacy and terms information.
</en-US>
```
