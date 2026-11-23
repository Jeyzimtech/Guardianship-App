# Google Play release checklist: Edu Connect 1.0.8 (build 9)

## Fixed in code

| Rejection risk | Fix |
| --- | --- |
| Release build signed with the debug key | `android/app/build.gradle.kts` signs with the upload key from `android/key.properties` |
| "Delete account" called a backend route that did not exist, then told the user the account was gone | New `POST /api/auth/delete-account`. Guardians are deleted. Teachers have their personal details erased and school records kept as "Former teacher". The app only signs out after the server confirms. Teachers can now delete their account too. |
| No privacy policy in the app or at a public URL | First-launch consent screen, plus Privacy policy and Terms in Profile. Public pages: `/privacy-policy`, `/terms`, `/account-deletion` |
| Cleartext HTTP allowed | `android:usesCleartextTraffic="false"` (the API is HTTPS only) |
| No support contact or bug reporting | Profile → Help center (admin@teramark.co.zw), Report a technical issue, Send feedback, App info |
| Version not increased | `1.0.8+9` |

## Before uploading

1. **Deploy the backend first.** The new app depends on it.
   - Run `php artisan migrate` (creates `support_reports`).
   - Optionally add `SUPPORT_EMAIL=admin@teramark.co.zw` to `.env`. This is the default anyway.
   - Check that these pages open:
     - https://admin.chewetechnologies.co.zw/privacy-policy
     - https://admin.chewetechnologies.co.zw/terms
     - https://admin.chewetechnologies.co.zw/account-deletion
2. **Switch PesePay to live mode.** If the server still returns `sandbox: true`, the app shows "PesePay test checkout. No real money will be collected." Reviewers reject apps with test or placeholder flows.
3. **Back up the upload key.** Keep `mobile/android/upload-keystore.jks` and `mobile/android/key.properties` in a password manager or other safe place. Both are git-ignored. When you create the app, enrol in **Play App Signing**. If the upload key is then lost, Google can reset it.
4. **Upload the App Bundle, not an APK:** `mobile/build/app/outputs/bundle/release/app-release.aab`.

## Play Console answers

- **App access:** the whole app requires sign-in, so reviewers need working credentials. Give them a teacher account and a parent account that use email and password. Reviewers cannot receive SMS codes. Link the parent to a learner that has sample attendance and homework.
- **Privacy policy URL:** https://admin.chewetechnologies.co.zw/privacy-policy
- **Data safety → Account deletion URL:** https://admin.chewetechnologies.co.zw/account-deletion
- **Data safety → data collected:**
  - **Personal info:** name, email, phone, address. Shared with service providers only.
  - **Health info:** learner medical details. Optional.
  - **Photos:** learner photo. Optional.
  - **Messages:** in-app messages.
  - **App activity:** support reports.
  - **Device IDs:** FCM push token.
  - **Financial info:** purchase history (uniform orders). Payment details go to PesePay.
  - Data is encrypted in transit, users can request deletion, and nothing is used for ads.
- **Target audience:** 18 and over. Users are parents and teachers, and learners do not sign in. Do **not** opt into the Designed for Families programme.
- **Content rating:** complete the questionnaire. The app has user-to-user communication (messages), but no violence and no gambling.
- **Ads:** No.
- **Store listing:**
  - 512×512 icon
  - 1024×500 feature graphic
  - at least 2 phone screenshots
  - short description (80 characters or fewer) and full description
  - support email: admin@teramark.co.zw
- **Permissions:**
  - Internet and notifications only. No sensitive-permission declarations are needed.
  - The Firebase `google-services.json` must stay registered to the package name `educonnect.com`. That name cannot be changed after the first upload.

## Review before publishing

The privacy policy and terms were drafted from what the code does. Read them and confirm:

- the operator name and contact
- the 30-day deletion and 90-day backup retention promises

Change `LegalPageController::UPDATED` and `Legal.version` / `Legal.updated` together whenever the text changes. Bumping `Legal.version` makes every user accept again.
