Deployment completed to 109.199.99.156, backend only.

- Application: https://admin.chewetechnologies.co.zw
- Backend path: /var/www/guardianship/backend
- Verified backup: /var/backups/guardianship/20261016T125655Z (backend archive and SQLite backup)
- All pending migrations applied; production environment and debug=false preserved.
- Production database integrity: ok; foreign-key violations: 0.
- Eight unchanged demonstration catalog products removed. Existing school, two students, family accounts, journal entries, and uploads preserved.
- Existing school administrator linked to school 2. Existing Grade 1 Blue class reconciled with the students' stored class data.
- Teacher class assignments intentionally left empty at the user's request; configure them in the admin portal.
- Production platform-owner account: owner@educonnect.local. Password delivered in chat, not stored in this repository.
- Live checks passed for owner, school administrator, guardian, catalog bearer authentication, blocked anonymous access, and teacher restrictions without assigned classes.
- Local checks: 41 backend tests, 53 mobile tests; Flutter analysis clean.
- Firebase authentication, its service, API endpoint, and mobile SDK dependencies removed. Existing account identifiers migrated to account_uid without changing passwords. Authentication uses this server and Sanctum.
- School admins invite teachers; teachers invite guardians only for their assigned students. Invitations and resend links use the saved SMTP configuration, whose authentication was verified on the server.
- Setup and reset emails use shared, inline-styled templates with one action, a fallback link, and a 48-hour expiry notice.
- No APK built or uploaded. Generate a new APK from the updated mobile source.

The deployment script now preserves the server environment, database, uploaded files, and runtime caches; backs up before uploading; and uses atomic replacement for source files.


## Role audit remediation release

Deployed the role audit fixes, pending fee/uniform payment references with own-school verification, and protected report downloads. Production migrations 140000 and 150000 completed. Backup: `/var/backups/guardianship/20261016T134022Z`. PHP-FPM reloaded. Source hashes match, health 200, SQLite integrity ok, foreign-key violations zero. Teacher assignments remain zero by user instruction. Backend tests: 56 passed / 196 assertions. Mobile: 56 passed; rebuild APK for the new publishing and payment screens. See ROLE-MATRIX-AUDIT.md for scope and operational limits.


## PesePay sandbox and delivery removal

Backend deployed with migration 160000, server-only PesePay sandbox credentials, encrypted checkout/status integration, authenticated callback verification, and dedicated payment worker/reconciliation timer. Old delivery route/controller/configuration removed. Two explicit test uniforms added for school 2: test shirt USD 1 and test jersey USD 2. Backup: /var/backups/guardianship/20261016T135619Z. Backend 65 tests / 237 assertions; mobile 57 tests; analysis clean. Real sandbox initiation and status checks returned 200, matching USD 1. Rebuild APK for the checkout UI. No real-money charge or completed customer checkout was performed.


## APK build and live server recheck

Requested release-mode APK build uses https://admin.chewetechnologies.co.zw/api. Live role/source verification passes; health HTTP 200, all migrations applied through 160000, SQLite integrity ok, zero foreign-key violations. Nginx, PHP-FPM, payment queue and reconciliation timer are active; the last reconciliation service run completed successfully (exit 0). Two test uniforms remain available. PesePay sandbox initiation, hosted checkout and encrypted status checks returned HTTP 200; application checkout worked and an unpaid probe stayed pending. Temporary probe orders were removed without changing stock.

Limits: sandbox customer payment completion is still unverified; automatic Android App Link return has not been implemented. Release build currently uses the existing Android debug signing configuration, suitable for direct testing rather than a Play Store release. No real-money payment is enabled.
