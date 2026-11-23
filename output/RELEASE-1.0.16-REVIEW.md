# Edu Connect 1.0.16 (17)

Prepared 30 October 2026. Package educonnect.com.

Removed structured meals, nap, hygiene and mood collection from teacher publishing and the school administrator portal; removed parent wellbeing display and filter. Backend rejects wellbeing entry types and wellbeing_data, excludes retired entries from journal feeds and notifications, and hides the retired model field from serialization. Existing records are preserved in storage, not deleted.

Privacy policy now describes classroom media, retirement of wellbeing tracking, historical records and deletion requests. Removed the unverified fixed 90-day backup retention claim. Mobile policy acceptance version updated. Data safety CSV uses the user-provided current Console sample; health selection is false and its conditional usage answers are blank for this release.

Validation: Flutter analysis clean; 92 mobile tests passed; 122 backend tests passed (690 assertions), including legacy-client rejection and historical-feed isolation. Existing reporting, blocking, school role boundaries, payments and account deletion regression suites passed. Real SMS/payment delivery and all individual devices were not exercised.

Production deployment completed with explicit user authorization on 30 October 2026. Backup: /var/backups/guardianship/20261030T145239Z-release17. Updated backend controllers/model/notification visibility, patched the retired admin UI, deployed privacy pages, rebuilt Blade cache and restarted queues/reloaded PHP. No historical records or database schema were deleted. All 23 live verification checks passed; temporary records were rolled back and no real email/SMS/messages were sent. Both HTTPS privacy pages and deletion page returned 200. Evidence: server-release17-verification.log.

Console actions after deployment: replace old artifacts on active tracks with build 17; select Education if it matches the listing; update App content > Health apps accurately to reflect the removed features; import EduConnect-1.0.16-Data-Safety.csv; inspect preview; ensure reviewer credentials work. No Console changes or submission were performed here. Google approval is not guaranteed; the prior notice did not identify the exact declaration that triggered Organization-account requirements. Other Organization-only services, if declared in Console, still need correction or the appropriate verified account.

Data safety assumes provider processing/user-directed school transfers qualify for sharing exceptions. Owner must confirm provider contracts, retention and actual operational practices. Historical restricted information remains subject to access/deletion requests.

Sources checked:
- https://support.google.com/googleplay/android-developer/answer/10788890
- https://support.google.com/googleplay/android-developer/answer/10787469?hl=en
- https://support.google.com/googleplay/android-developer/answer/13327111?hl=en
- https://firebase.google.com/docs/android/play-data-disclosure

AAB built and signature verified: EduConnect-1.0.16-build17.aab. Manifest version 1.0.16, version code 17. SHA256: 250EC9B2D4E6AD263946663149412BAC9649510FD47C023E910B01317F2E23F1. Admin portal JavaScript syntax check passed.
