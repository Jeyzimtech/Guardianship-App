# Data safety CSV for Edu Connect 1.0.16 (17)

File: `EduConnect-1.0.16-Data-Safety.csv`.

Rebuilt using the current Play Console example supplied by the user (782 response rows, five columns). Sample answers were replaced with EduConnect answers. CSV structure and round-trip parsing passed; Console import still needs confirmation.

## Account answers

- No in-app account creation; school-created external accounts are supported.
- External account type: Other, with school administrator explanation.
- Data deletion requests: Yes; data deletion URL points to the published account-deletion page. Account deletion URL is blank because Console disallows it when PSL_ACM_NONE is selected.

## Review before import

- Import overwrites existing form answers. Export your current form first if you want a backup.
- Photos, videos, voice recordings, and files/documents are selected because the teacher publishing/upload flows support them. These were missing from some earlier manual guidance.
- Other personal information includes optional language preferences and related profile details.
- Email and phone are marked required because some roles require them; Google's optional designation must hold for all users. Address remains optional.
- Diagnostics is marked required because Firebase may automatically transmit app/device metadata as well as the optional support-report flow. Turning notification display off does not necessarily stop Firebase installation-ID collection. Device IDs are also required.
- App interactions covers server-side read receipts/dismissals; other user-generated content covers journal entries, school content, reports and feedback.
- Collected is selected; Shared is not selected on the assumption that hosting/Firebase/SMS processing qualifies for the service-provider exception and that school communications are reasonably expected user-initiated transfers. Verify contracts, school/operator relationships and actual SDK configuration. If any transfer falls outside Google's exceptions, update the relevant Shared answers before submission.
- No location collection is declared: no device-location features or IP-to-location inference were identified. No advertising, browsing-history, installed-app inventory, contact-book or SMS-inbox access is declared.
- Payment account/card details are not declared because checkout is external and the app does not access them. Uniform transaction/purchase history is declared.
- All selected data is marked non-ephemeral because backend records and/or SDK identifiers persist beyond an individual real-time request.
- Advertising/marketing and personalization purposes are not selected. Analytics is selected for diagnostics used to investigate app issues, not for every data category.

This file is a code-based draft for owner review. It does not verify every SDK setting, service-provider contract, retention practice or Google Console declaration. Review the preview before submitting.

Privacy policy: https://codedevs.chewetechnologies.co.zw/privacy-policy

Deletion information: https://codedevs.chewetechnologies.co.zw/account-deletion

References:

- https://support.google.com/googleplay/android-developer/answer/10787469?hl=en
- https://firebase.google.com/docs/android/play-data-disclosure

Health info is FALSE for release 17 after removing structured wellbeing collection and hiding retired entries on the server. Matching backend deployed and verified on 30 October 2026. Replace older releases on active tracks before submitting the aligned declaration. Historical restricted records remain subject to deletion requests.
