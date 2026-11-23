# Document uploads and homework attachments

## Using the feature

- School administrators: open **Documents** in the administration sidebar. Enter a title, optional description, choose **Whole school** or a class, select a file and upload it. The section lists documents with Download and Delete actions.
- Teachers: open **Class Assignments → Create assignment** in the mobile app. Choose the class, subject, title and due date. Add instructions if needed and use **Attach homework document** to select a file. Attachments are optional, so text-only homework continues to work.
- Parents: open **School documents** in the mobile drawer for school/class files. Open **Homework Tasks** for homework attachments. Tap the named Download button to open the system browser/download handler. Word files require a compatible viewer to edit or read after downloading.
- Teachers can also read school-wide documents and documents for their assigned classes through the mobile **School documents** menu.

Supported files: PDF, Word (`.doc`, `.docx`), Excel (`.xls`, `.xlsx`), PowerPoint (`.ppt`, `.pptx`) and plain text (`.txt`), up to 10 MB per file. Each homework assignment can have one optional attachment. Original filenames are retained for downloads.

The mobile screens require Android **1.0.3, build 4**. Existing installed apps continue to use their previous screens until updated. An iOS build was not produced in this release.

## Access and storage

Files use Laravel's private local storage under `school-documents/`, not a publicly accessible upload directory. The API checks school/class/guardian relationships and child subscription access. Download links expire after five minutes; the app requests a fresh link on each tap, and link opening rechecks current authorisation. Unlinking a child or suspending their subscription therefore also affects an existing signed link. These signed URLs are temporary access credentials and should not be posted publicly.

Only school administrators can upload/delete general school documents. Teachers upload homework attachments only for their assigned class and permitted subject. General Documents lists exclude homework attachments, which remain under Homework. File-size, extension and detected content-type validation run on the server as well as client-side file selection.

## API and schema

- `GET /api/documents`: staff list; guardians supply `student_id`.
- `POST /api/documents`: school administrator multipart upload; `title`, optional `description`, optional `school_class_id`, and required `file`.
- `DELETE /api/documents/{document_id}`: school administrator deletes an own-school general document and its private file.
- `GET /api/documents/{document_id}/download`: obtains a fresh signed download link; guardians supply `student_id`.
- `GET /document-files/{document_id}`: signed file response, attachment disposition and original filename.
- `POST /api/assignments`: existing fields plus optional multipart `file`. Assignment listing responses add an optional `attachment` object.

Migration: `2026_10_22_000001_create_school_documents_table.php`. Apply the migration before serving the updated controllers. Back up private file storage along with the database. Deleting a school/class/assignment outside the general-document Delete endpoint can leave an unreferenced private file; database cascade deletes alone do not remove storage objects.

## Verification and release

- Full backend suite: **110 tests, 601 assertions passed**.
- Selected mobile workflow suites: **21 tests passed** (`school_documents_test`, `supporting_pages_test`, `role_workflows_test`).
- Dart analysis of the changed screens and new test: **no issues found**.
- Admin inline JavaScript syntax and PHP source syntax checks passed.
- Android release build: **1.0.3 (4)**, package `educonnect.com`, 64,990,755 bytes.
- APK SHA-256: `c53830ef3a84d4376668be95bf4f71ee88528e661fa6264fcaf06ed3912270e3`.
- Published APK: https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.3.apk (remote checksum and HTTP 200 confirmed).
- Backend deployed to Contabo; migration completed, routes/views cached, workers notified and PHP-FPM reloaded. API health check passed and deployed source checksums matched.
- Backup: `/var/backups/guardianship/20261021T095541Z-documents` (selected source files and a consistent SQLite database backup).
- Live smoke verification ran as `www-data`: administrator upload, private bytes, scoped parent listing, signed download, revoked child access, teacher homework upload and parent attachment listing passed. Disposable database fixtures were rolled back and temporary files removed.

Operational scripts: `.github/scripts/deploy_documents.py` supports `--check`, deployment, `--verify` and `--publish-apk`. Passwords are entered through the terminal and are not saved in the scripts. Device-level downloading/opening of Word/PDF files still needs an actual phone check; widget, backend and live server tests cannot prove the behaviour of every installed browser/viewer.
