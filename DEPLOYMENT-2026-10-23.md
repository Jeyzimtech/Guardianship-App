Deployment: 23 October 2026

Server: 109.199.99.156
Backend: /var/www/guardianship/backend
Site: https://admin.chewetechnologies.co.zw

Deployed the attendance CSV export, per-user selected/bulk message deletion,
conversation clearing, and corresponding unread-count filtering. UI controls use
the existing app theme, Cabin font, shared colors, and Material button/dialog styles.

Backup: /var/backups/guardianship/20261023T102254Z-register-messages
Source and consistent SQLite database backups were created before switching code.
Migration 2026_10_23_000001_add_message_deletion was applied. Source checksums match.
Routes/views were cached, queue restart requested, PHP-FPM reloaded, and health passed.

Validation:
- Local backend: 114 tests passed, 626 assertions.
- Targeted mobile analysis: no issues.
- Mobile receipt/workflow checks: 4 tests passed.
- Live authenticated HTTP: saved register CSV and guardian access denial passed;
  selected bulk deletion and clearing passed; other participant copies preserved.
- Live attendance, photos, messaging, receipts, notification counts, database integrity,
  and foreign keys passed. Temporary verification accounts and records were removed.

Android 1.0.4, build 5 completed successfully.
Package: educonnect.com
Local APK: mobile/build/app/outputs/flutter-apk/app-release.apk
SHA-256: 3194eb571870b6e5558053ce6cec2460f6f34719aaca072c2243342772405b6d
Published: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.4.apk
Size: 65,384,788 bytes. Server checksum matches local artifact; HTTPS HEAD returns 200.
Install this APK to receive the new CSV and selection/deletion controls.


SOS recipient follow-up

SOS now defaults to one named parent. All parents remains available for the
teacher's assigned classes and requires an explicit review/confirmation in the
updated mobile app. Selected guardian IDs are validated against assigned learners;
an unrelated guardian or missing selection cannot receive an alert.

Controller deployed with matching source checksum and successful API health check.
Backup: /var/backups/guardianship/20261023T104041Z-targeted-sos
SOS tests: 10 passed, 78 assertions, using mocked SMS (no SMS credits spent).
Preview/workflow tests: 3 passed; targeted Dart analysis: no issues.
Actual Flutter screens rendered with sample data to mobile/output/feature-previews/.
Android 1.0.5, build 6 published with matching local/server checksum and HTTP 200.
URL: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.5.apk
Size: 65,384,784 bytes.
SHA-256: 7b75599191a6097192721b94079a887b97ddc8a1d2c52cd1addc1c73374b985c
Install this APK for the updated named-parent selector and all-parents review.


Notification deletion follow-up

Teachers and parents can select one or multiple notifications, select all shown,
and delete with confirmation from Notices/Notifications. Deletion is per account
and persists on the server; original announcements and other users' copies remain.
Parent SOS history and pending alarms omit dismissed SOS entries. Unread counts
and pending notice push delivery exclude deleted notifications.

Migration: 2026_10_23_000002_create_mobile_dismissals (batch 17).
Backup: /var/backups/guardianship/20261023T105402Z-notification-deletion
Deployed controllers, service and routes have matching source checksums.
Local backend: 117 tests passed, 656 assertions.
Mobile: 5 workflow/preview tests passed; targeted analysis has no issues.
Live authenticated deletion passed for teacher and parent; parent copies survive
teacher deletion; dismissed parent SOS does not reappear as an alarm. Verification
fixtures were removed, including the initial cleanup retry. No SMS was sent.

Android 1.0.6, build 7 published with matching server/local checksum and HTTP 200.
URL: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.6.apk
Size: 65,466,760 bytes.
SHA-256: fe52e80e8d915a97eb4f7620e4a6dd19ccec32eab0830d4532c1def345f2ee45
Install this release to use notification selection/deletion in both spaces.


Updated APK rebuild

Requested a fresh APK from the current source. Project release version is now
1.0.7+8 in mobile/pubspec.yaml. Includes saved-register CSV, selected/bulk message
deletion, one-parent/all-parents SOS, and private teacher/parent notification deletion.
The 5 mobile workflow/preview tests passed. Android 1.0.7, build 8 built and published.
URL: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.7.apk
Size: 65,466,760 bytes.
SHA-256: 364ae6ec71277f8d4e617ed46270928b8553f37723bc14574c260699d564f854
Publisher verified package/version, matching server checksum, HTTPS 200, and API health.
