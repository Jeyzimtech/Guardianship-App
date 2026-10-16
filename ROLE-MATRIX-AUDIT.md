# Role matrix audit - fixes verified 16 October 2026

The 10 reproduced access-control and payment defects are fixed and covered by the normal backend test suite. The backend fixes are deployed at https://admin.chewetechnologies.co.zw. Mobile source changes are complete; rebuild the APK to distribute the new screens.

## Role outcomes

| Role | Verified behavior |
|---|---|
| Platform Owner | Onboard schools, view cross-school directory, manage dated child subscriptions. Academic, attendance and messaging authoring remains blocked. Existing owner account retained. |
| School Admin | Manage own-school students, teachers, classes, activities, categories, fees and uniforms; invite teachers by email. Cannot modify another school's catalog or payments. Verify manual fee payments from the Fees section; PesePay uniform payments require gateway verification. |
| Teacher | Own school plus assigned grade/class scope for students, attendance, journal, reports, activities and guardian communication. Assignments enforce assigned subjects; journal checks a supplied subject. Can invite guardians for assigned students. No fee access. Mobile now supports journal posting and report uploads. |
| Parent / Guardian | Linked-child records, attendance, assignments, journal, reports, behaviour and activities. Fee references can be submitted for school verification; uniform checkout uses PesePay. Cannot edit student identity, class or grade. |
| Student | Login remains blocked for the MVP. |

Teachers remain unassigned in production as explicitly requested. Their school administrator must configure class and subject assignments before classroom access is available.

## Resolved audit defects

1. Teacher rosters exclude identically named classes in other grades.
2. Attendance marking rejects students in other grades/classes.
3. Teacher notices target assigned school, grade and class, including all-assigned-class posting.
4. School admins cannot post fee payments for another school.
5. Submitting payment details never automatically completes a payment or reduces a fee balance. References remain pending until an own-school admin confirms actual receipt. Verification credits a fee payment only once.
6. Legacy assignments without class IDs are constrained to the author's school.
7. Assignment authoring rejects subjects outside the teacher's assignments.
8. Direct report downloads respect child subscription state. Uploaded reports are private; five-minute signed links recheck role, child linkage and subscription when opened. Existing report files found in supported legacy storage locations are migrated to private storage.
9. Uniform editing rejects other-school records and school transfers.
10. Uniform deletion rejects other-school records. New catalog items are restricted to the admin's own school.

## Completed UI and data fixes

- Teacher home uses live student/class counts and actual assigned classes; fabricated schedules and learner counts removed.
- Dashboard no longer invents z-score history or uses a 96% attendance fallback.
- Teacher journal form supports notes, photos, drawings, voice, video, links and wellbeing logs. Media links can be opened from the journal.
- Teacher report form accepts PDF/images, student and document type; missing uploads are rejected.
- Parent School fees screen shows balances/history and submits payment references.
- Uniform order history supports PesePay checkout and payment-status checks. Only provider-verified SUCCESS with the matching reference, amount and currency marks an order paid. Manual verification cannot override a PesePay attempt.
- New forms follow the existing clean app styling. No AI artwork or decorative AI icons added. Mobile previews inspected at 320 px width.
- Catalog no longer invents stock quantities or applies a hard-coded USD/ZiG exchange rate; schools configure prices and stock.

## Verification evidence

- Backend: **65 tests passed, 237 assertions** (`php artisan test --compact`).
- All 10 original audit probes are now regression tests in `backend/tests/Feature/RoleBoundaryRegressionTest.php`; additional tests cover payment verification, duplicate references, school isolation, private report links and uploads.
- Mobile: **57 tests passed** (`flutter test --no-pub --reporter expanded`), including three new publishing/payment workflow tests. Preview capture run also passed.
- Flutter analysis: no issues (final check recorded below if applicable).
- Admin portal inline JavaScript syntax check passed.
- Live health: HTTP 200.
- Deployed Fee, Assignment, Attendance, Announcement, Uniform, Journal and Report controllers, subscription middleware and API/web routes match the tested local source hashes.
- Platform-owner directory/schools: 200. Admin students/activities/categories/fee accounts: 200. Teacher activities/assignments: 200. Guardian linked students/notices: 200.
- Admin, teacher and guardian platform-directory requests: 403.
- Teacher attendance roster: 403 with zero assigned classes, as requested.
- Both new migrations completed in production: `2026_10_16_140000_strengthen_role_boundaries`, `2026_10_16_150000_protect_reports_and_record_uniform_payments`.
- Production SQLite integrity: ok; foreign-key violations: zero.
- Backup before deployment: `/var/backups/guardianship/20261016T134022Z` (backend archive and SQLite backup).
- Existing school/student/family records preserved. Sandbox gateway initiation and status checks were performed without collecting real money. Existing school/student/family records were preserved.

## Operational limits

- PesePay is configured in sandbox mode for uniform purchases, using server-side test credentials. USD checkout only. School fees retain their separate manual reference/verification flow. Live-money payments are not enabled.
- Messaging consists of class/school notices to the permitted recipients; two-way chat has not been added.
- The mobile APK must be rebuilt to include the new screens and file-picker dependency. No APK was deployed to the backend server.
- These automated and live checks cover the listed workflows; they are not a claim that every possible device/network/provider scenario is proven.

## PesePay release - 16 October 2026

- Removed the delivery provider UI, quote endpoint, controller, configuration and environment variables. Uniform collection is arranged with the school.
- Added test shirt USD 1 and test jersey USD 2 to Hillside Primary School, sizes S/M/L, 20 units each initially. Test item codes are TEST-PESEPAY-SHIRT and TEST-PESEPAY-JERSEY. Re-running the explicit test catalog command does not duplicate items or reset stock.
- Migration 2026_10_16_160000_create_uniform_payments deployed.
- PesePay checkout and status API returned HTTP 200 with the supplied test keys; decrypted reference and USD amount matched.
- Dedicated payment queue and five-minute reconciliation timer enabled for verified callbacks and missed callbacks.
- Backup: /var/backups/guardianship/20261016T135619Z.
- Rebuild the mobile APK to use PesePay and remove the old delivery controls from installed apps.
- A completed customer payment must still be exercised on the hosted sandbox page; initiation alone is never treated as payment success.
