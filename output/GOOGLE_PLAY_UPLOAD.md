# Upload Edu Connect to Google Play

Prepared 29 October 2026.

## Release

- File: `EduConnect-1.0.12.aab`
- Application ID: `educonnect.com`
- Version: 1.0.12; version code: 13.
- Uses the configured release upload key, not the old debug key used by compatibility APKs.
- PesePay staging configuration is unchanged. This is suitable for testing that existing flow; do not describe staging payments as live payments in review instructions.

The build targets Android API 36. The backend and payment configuration were not changed during this build. Public policy page availability and live payment status must be checked before review.

## Upload process

1. Sign in at https://play.google.com/console and complete the developer account verification tasks.
2. Select the existing `educonnect.com` app, or choose **Create app** if this is its first Play release. Use the name **Edu Connect**, choose the language, App, and Free if that matches your pricing. Complete the declarations.
3. Complete the dashboard setup tasks: app category, contact email, store listing, content rating, ads declaration, target audience, app access, Data safety, and any other declarations shown for this app. Base every answer on actual app and SDK behavior.
4. Prepare a 512 x 512 app icon, 1024 x 500 feature graphic, at least two phone screenshots, a short description, and a full description. Support email: `admin@teramark.co.zw`.
5. Use privacy policy URL `https://admin.chewetechnologies.co.zw/privacy-policy` and account deletion URL `https://admin.chewetechnologies.co.zw/account-deletion`. Confirm these pages and in-app deletion work before review.
6. Under **App access**, supply working teacher and parent reviewer accounts with sample learner data. Explain the PesePay staging flow. Do not supply server/root credentials. Ensure reviewers can sign in without needing your personal phone or SMS.
7. Under **Test and release > Testing > Internal testing**, create a release. Configure Play App Signing as prompted. Upload `EduConnect-1.0.12.aab`, enter release notes, save, resolve errors, and roll out to internal testers. Add tester email addresses and share the opt-in link.
8. Test the Play-installed build: sign-in, profile, learner data, notices, uploads, push notifications, account deletion, and PesePay staging checkout. Review the pre-launch report.
9. For personal developer accounts created after 13 November 2023, complete a closed test with at least 12 testers continuously opted in for at least 14 days, then apply for production access. Follow additional testing or verification tasks shown by Play Console.
10. When eligible, create or promote a release under **Test and release > Production**, choose countries, resolve remaining dashboard errors, and submit for review through Publishing overview. Google approval is separate from successfully building or uploading the bundle.

Suggested release notes:

> Improved profile layout and linked-student display. Updated privacy and App info screens.

## Signing and future updates

- Keep `mobile/android/upload-keystore.jks` and `mobile/android/key.properties` securely backed up. Never upload these files to the store listing or share their passwords.
- If this app already exists on Play, its registered upload certificate must match this bundle's certificate. If Play rejects the certificate, check App integrity and use the registered upload key or the upload-key reset process.
- Play-delivered builds use the Play app-signing certificate. Existing debug-signed sideloaded copies cannot normally update directly to that differently signed build. Test on another device/profile or back up needed local data before uninstalling an old copy.
- Add the Play app-signing SHA-1/SHA-256 certificate fingerprints to Firebase where required by the Firebase/API services in use.
- Every future upload needs a higher version code than the highest code already uploaded to Play. This bundle uses code 13.
- An AAB is uploaded to Play Console; it cannot be installed directly like an APK.

## Official references

- Create app and listing: https://support.google.com/googleplay/android-developer/answer/9859152
- Release upload: https://support.google.com/googleplay/android-developer/answer/9859348
- Testing requirements: https://support.google.com/googleplay/android-developer/answer/14151465
- App signing: https://support.google.com/googleplay/android-developer/answer/9842756
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878

