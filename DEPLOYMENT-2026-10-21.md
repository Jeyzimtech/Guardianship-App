Deployment to 109.199.99.156
===========================

Backend: /var/www/guardianship/backend
Site: https://admin.chewetechnologies.co.zw

Deployed current backend source, including student photos/medical profiles, parent
import, message contact query batching, unread counts, read/delivery receipts,
notification jobs, and the current teacher attendance workflow. Existing runtime
configuration, users, school data, uploaded files, and database were preserved.

Backups
-------

* /var/backups/guardianship/20261021T075539Z — backend archive and consistent SQLite backup.
* /var/backups/guardianship/20261021T080620Z-attendance — database backup before fixing the legacy attendance constraint.

Database integrity checks passed. Production debug remains disabled. Source hashes
for the updated routes, controllers, services, view, and corrective migration match
the local release. Nginx and PHP-FPM are active; PHP-FPM was reloaded. Configuration,
routes and Blade views were cached. The payment worker remains active, and the new
guardianship-notification-queue.service processes the default notification queue.

Attendance correction and live verification
-------------------------------------------

The old production database allowed only present/absent, despite the app offering
Late. Migration 2026_10_21_000003_align_attendance_statuses expands that constraint
without deleting saved attendance. A regression test recreates the old schema,
upgrades it, and verifies the same record can be saved as Late.

Live API checks used an isolated temporary school, class, teacher, parent and learner:

* All three attendance statuses save and reload correctly in the teacher register.
* The parent sees each saved status; changes update one daily record.
* Parents and teachers outside the learner's class cannot mark that register.
* A parent photo upload is returned in the teacher roster and the teacher can fetch it.
* Message delivery and read receipts update through authenticated HTTP requests.
* Database integrity and foreign-key checks pass.

The temporary accounts, school, learner, attendance, messages, tokens and photo
were removed. No real learner's attendance was changed for verification.

Local backend test suite: 102 passed, 519 assertions.

Mobile release
---------------

Android version 1.0.1, build 2 was built from the updated mobile source.
Local artifact: mobile/build/app/outputs/flutter-apk/app-release.apk
Size: 64,987,795 bytes.
SHA-256: fcf7a587c1bed7cdc35fe367a4d3021253b7a0edf374ad0c47c65cc7fbf8cd91
Download path: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.1.apk
Publication is verified by the publisher script using a matching server checksum
before atomic publication and a successful HTTPS HEAD response.

Remaining configuration
-------------------------

Only one of four existing teacher profiles has assigned classes. Teacher profile
IDs 2, 3 and 6 require class assignments in the admin portal before their class
registers can load. Assignments were not guessed or changed during deployment.

Firebase server credentials and mobile Firebase project configuration are absent.
Unread badges and message ticks work; phone push delivery needs that configuration.
See NOTIFICATIONS.md. Publishing backend code does not update installed phone apps;
users need to install the new APK to receive the mobile UI changes.

Firebase Android configuration follow-up
----------------------------------------

At the user's request, Android now uses application ID and namespace `educonnect.com`.
The launcher activity is in the matching Kotlin package. iOS remains unchanged.
The supplied google-services.json belongs to project `educonnect-13f25` and Firebase
App ID `1:422222327458:android:0c799cd20fdb34e425b1fb`. Generated Google Services
resources were checked against those values, and the Android release build passed.

Android 1.0.2, build 3:
* Local artifact: mobile/build/app/outputs/flutter-apk/app-release.apk
* Download: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.2.apk
* Size: 64,990,595 bytes.
* SHA-256: d573b2ee135f5a160f6e8f3a45e89fe123c82ee9bf6aba363fbf69f02e4d5b29

The publisher validates the APK package/version before upload and checks the remote
checksum before atomic publication. Changing the application ID makes Android treat
this as a separate app, so existing users must sign in again. Their server records
remain associated with their accounts. The mobile Firebase configuration is now
included; server-generated push still requires the server service-account key.

Messaging verification after Firebase client configuration
----------------------------------------------------------

Rechecked the live server with isolated temporary accounts and records. Teacher
messages, parent replies, class broadcasts, conversation history, sent/delivered/read
receipts, unread message counts, notice/journal badge counts, and read clearing all
passed. Attempts to contact an unrelated parent or send a guardian broadcast returned
403. Attendance and protected student photos passed again. Temporary records and
uploaded test photos were removed. Deployed source hashes match; all four checked
services are active and the public health endpoint returns 200.

Local checks: 10 backend messaging/notification tests and 22 Flutter receipt/badge/
notice/supporting-screen tests passed. Flutter analysis reports no issues.

Push readiness is incomplete: FIREBASE_CREDENTIALS is not configured on the server,
there are zero registered push devices, and zero failed push jobs. No actual phone
notification delivery was claimed or tested. Completing server credentials and
installing/signing into Android 1.0.2 with notification permission are still needed
before a real-device foreground/background delivery test. Three teacher profiles
still lack class assignments; their registers require admin configuration.

Firebase server credentials configured
---------------------------------------

Installed the user-supplied service-account credential outside the application and
web root at /etc/guardianship/firebase-service-account.json. The directory uses
0750 root:www-data and the credential uses 0640 root:www-data. No private key was
copied into this repository or the mobile application. The environment was backed
up under /var/backups/guardianship/firebase-configuration-726415b5952245029e8737baf9a2bf2d
with restricted permissions, then FIREBASE_CREDENTIALS was configured atomically.

Configuration cache was refreshed, the notification worker restarted, and PHP-FPM
reloaded. Verification ran as www-data through the deployed FirebasePush service:
the credential is readable, its project matches educonnect-13f25, OAuth authentication
succeeded, and FCM HTTP v1 accepted a validation-only request. No notification was
delivered by this dry run. Nginx, PHP-FPM and the notification worker are active;
the API health check succeeds. Registered push devices: 0. Failed push jobs: 0.

Server setup is now complete. Actual delivery still requires signing into Android
1.0.2 on a phone, allowing notifications, and sending a message between linked
teacher/parent accounts. No further APK rebuild is needed for this server key.
