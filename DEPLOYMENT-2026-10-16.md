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
