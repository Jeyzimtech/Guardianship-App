# Role matrix audit — 16 October 2026

Result: the implementation does not fully satisfy the supplied picture. Earlier statements that everything was working were too broad. Existing happy-path tests do not establish complete role isolation or complete mobile functionality.

The user's later instructions also apply: school admins invite teachers; teachers invite guardians for assigned students; Firebase is removed; existing teachers stay unassigned until configured through the admin portal.

## Row-by-row result

| Role | Implemented | Outstanding |
|---|---|---|
| Platform Owner | School onboarding, cross-school directory, dated subscription controls; school academic/attendance/message authoring blocked by API roles | Direct report-download route bypasses a child's subscription suspension |
| School Admin | Own-school student, teacher, class, year, fee, uniform, notification, activity and behaviour-category interfaces | Other-school fee payments and uniform modification/deletion lack school checks |
| Teacher | Attendance, activity participation, behaviour notes, assignments, class notices, guardian invitations; fee endpoint access denied | Duplicate class names across grades break some scope checks; subject assignments not enforced; mobile journal is read-only; no teacher report-upload control |
| Parent / Guardian | Linked-child records and attendance, notices, journal, reports, behaviour and activities; own contact/profile editing; child identity/class updates forbidden | Fees endpoint simulates success without collecting or verifying payment; no mobile fee-payment flow; uniform orders stay pending for school settlement; legacy assignments can cross schools |
| Student | Student login rejected; not enabled in MVP | Matches the picture's MVP exclusion |

## Reproduced defects

All mutation tests ran against Laravel's isolated, in-memory SQLite test database. No production school, student, attendance, uniform, fee or payment records were changed.

| Priority | Probe | Expected | Actual |
|---|---|---|---|
| High | Teacher roster with Grade 1 Blue and Grade 2 Blue | Only assigned grade | Both grades returned |
| High | Teacher marks attendance for the other grade's Blue class | 403 | 200; record written in test DB |
| High | Teacher class notice and guardian in other grade's Blue class | No notice | Notice returned |
| High | School A admin submits fee payment for School B child | 403 | 200 |
| High | Guardian submits payment details without verified provider transaction | No completed payment | Transaction marked completed and balance reduced |
| High | Guardian requests assignments; other school's legacy assignment has matching grade and no class ID | No foreign assignment | Other school's assignment returned |
| Medium | Mathematics-assigned teacher creates English assignment | Subject access denied | 201 |
| Medium | Suspended parent accesses direct report-download endpoint | 403, consistent with report list | 200; download URL returned |
| High | School A admin edits School B uniform | 403 | 200 |
| High | School A admin deletes School B uniform | 403 | 200 |

Relevant implementations:

- `backend/app/Http/Controllers/AttendanceController.php`: roster/marking use class_name without grade.
- `backend/app/Http/Controllers/AnnouncementController.php`: recipients use school_id + class_name without grade/class ID.
- `backend/app/Http/Controllers/FeeController.php`: processPayment lacks admin school scoping and immediately completes simulated payments.
- `backend/app/Http/Controllers/UniformController.php`: update/destroy do not verify the administrator's school against the item.
- `backend/app/Http/Controllers/AssignmentController.php`: legacy unclassified assignments lack school filtering; authoring accepts arbitrary subject_name.
- `backend/app/Http/Middleware/CheckChildSubscription.php`: resolves student_id but not report_id; download controller checks parent linkage but not subscription state.

## UI and dummy-data gaps

- `mobile/lib/features/parent/learning_journal_view.dart` loads and displays entries; the teacher menu's “Post Learning Entry” opens this read-only screen.
- The teacher shell, home, drawer and classroom have no report-upload form. Backend upload support alone does not complete this requirement.
- Mobile has no fee-payment screen or call to `/fees/pay`. Uniform checkout explicitly says payment is arranged with the school and stores orders as pending.
- `mobile/lib/features/teacher/teacher_home_view.dart` still hard-codes Grade 4A and a sample daily schedule.
- `backend/app/Http/Controllers/DashboardController.php` still hard-codes z-score history and uses a 96% attendance fallback when no attendance exists.
- Messages currently present persisted notices, not two-way conversations. The picture permits communication but does not explicitly require chat, so class notices provide partial/basic communication rather than a proven full messaging system.

## Verification evidence

- Existing backend suite: **41 passed, 154 assertions**.
- Separate audit probes: **10 failed, 15 assertions**. These are desired-policy assertions that reproduce the defects above; they are outside the normal test suite.
- Probe source: `backend/storage/app/role-audit/RoleAuditTest.php`.
- Probe output: `backend/storage/app/role-audit/results.txt`.
- Baseline output: `backend/storage/app/role-audit/baseline.txt`.
- Reproduce probes: from backend, run `php artisan test storage/app/role-audit/RoleAuditTest.php --compact`.
- Live health: HTTP 200.
- Owner directory/schools: HTTP 200; school admin/teacher/guardian access to platform directory: HTTP 403.
- Admin students/activities/categories/fees: HTTP 200. Parent linked students/notices: HTTP 200.
- Teacher attendance: HTTP 403 because no classes are assigned. Assigned-class count remains zero by user instruction.
- Live SQLite integrity: ok; foreign-key violations: zero. Data integrity does not prove access-control correctness.
- Deployed Fee, Assignment, Attendance, Announcement, subscription middleware and API route source match local audit source. Uniform controller initially differed by file hash; downloaded source has no line-content differences, so the reviewed update/delete logic also applies to deployment.

## Remediation order

1. Stop unverified payments from becoming completed and enforce school scoping for financial and uniform mutations.
2. Use school + grade + class (preferably explicit class IDs) consistently for roster, attendance, activities and notice recipients; constrain legacy assignments to their school.
3. Enforce teacher subject assignments and subscription checks on report downloads.
4. Complete teacher report/journal authoring and the parent payment workflows.
5. Replace remaining fabricated display data with live values or honest empty states.

This turn is an audit. Application behaviour and production permissions were not modified.
