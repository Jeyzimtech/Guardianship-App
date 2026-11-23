from pathlib import Path
import hashlib, json, shutil, zipfile
root=Path.cwd(); dest=root/'output'/'feature-release-2026-11-20'; dest.mkdir(parents=True,exist_ok=True)
files=['app/Services/GuardianAccess.php','app/Http/Middleware/GuardianSubscription.php','app/Http/Middleware/CheckChildSubscription.php','app/Http/Controllers/WebsiteAdminController.php','app/Services/SchoolRemoval.php','app/Jobs/PurgeSchoolFiles.php','app/Http/Controllers/UserController.php','app/Http/Controllers/JournalController.php','app/Http/Controllers/MessageController.php','app/Services/MessageRetention.php','app/Services/MobileUpdates.php','app/Http/Controllers/AnnouncementController.php','app/Http/Controllers/FeeController.php','app/Models/FeeTransaction.php','app/Http/Controllers/DashboardController.php','resources/views/admin.blade.php','routes/api.php','routes/console.php','database/migrations/2026_11_20_000001_add_payment_proof_and_retention_index.php']
checks={}
for name in files:
 src=root/'backend'/name; out=dest/'backend'/name; out.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,out);checks[name]=hashlib.sha256(src.read_bytes()).hexdigest()
(dest/'manifest.json').write_text(json.dumps({'date':'2026-11-20','files':checks,'server_rename':False,'migration':'2026_11_20_000001_add_payment_proof_and_retention_index.php'},indent=2),encoding='utf-8')
(dest/'educonnect-message-retention.service').write_text('[Unit]\nDescription=Remove EduConnect messages older than seven days\n\n[Service]\nType=oneshot\nUser=www-data\nWorkingDirectory=/var/www/guardianship/backend\nExecStart=/usr/bin/php artisan messages:prune\n',encoding='utf-8')
(dest/'educonnect-message-retention.timer').write_text('[Unit]\nDescription=Hourly EduConnect message retention\n\n[Timer]\nOnCalendar=hourly\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n',encoding='utf-8')
(dest/'DEPLOYMENT.txt').write_text('''REQUESTED FEATURES - 20 NOVEMBER 2026

STATUS: Prepared locally. Production access/deployment has not been authorized by automatic approval review. Do not install the new live-connected APK before the matching backend release.

SCOPE
- Suspended parents authenticate but cannot bypass the subscription screen or API restrictions.
- Subscription benefits, account-first activation popup, contact 079 054 3013.
- Teachers and school admins retain school access without subscription UI.
- Parent identity can be linked at multiple schools; credentials and other-school links are preserved.
- Owner-only school removal requires exact school-name confirmation; DB cascades are transactional and private/public assets are queued for cleanup. This deployment does not invoke school removal.
- Direct messages expire at seven days; message bodies and notification references are physically removed.
- Drawings cannot be newly published. Existing historical entries are retained.
- Parent dashboard links to child information, proof of payment, documents, profile and activity participation. Existing school activity authoring/registers are reused.
- Receipt uploads are private and require school verification. Fee payments do not activate app subscriptions.
- Server name and API domain remain unchanged.

BACKEND DEPLOYMENT
1. Back up the live source files in manifest.json and take a consistent database backup. Preserve existing environment, storage, server identity and credentials.
2. Compare each bundled file with live source before replacement to avoid overwriting newer server-only changes.
3. Copy the listed source files. Run PHP syntax checks first.
4. Run only: php artisan migrate --path=database/migrations/2026_11_20_000001_add_payment_proof_and_retention_index.php --force
5. Refresh application route/view caches and restart the queue worker so file cleanup and push jobs use the new code. Verify that queue processing is running.
6. Install the bundled hourly message-retention systemd timer/service if Laravel scheduling is not already running. If an existing scheduler is active, the hourly route/console.php entry is sufficient; do not install a duplicate timer.
7. Verify /api/health, parent login, /api/subscription, suspended parent 403 responses, staff publishing, multi-school links and private proof access with test accounts. Do not delete a real school as a smoke test.
8. Install the new release APK on the connected device and verify live activation/restriction behavior.

ROLLBACK
Restore the backed-up source and application caches, then restart workers. Leave the additive nullable proof_path column and message index in place during source rollback so receipt references are preserved. Expired messages and a deliberately removed school cannot be restored without the database/storage backups.

COMPATIBILITY
Existing children with no subscription row retain their legacy access. Existing suspension dates keep their established behavior. New app access checks require /api/subscription; failed checks display a retry screen rather than expose records.

DEVICE TESTS
The device test runner uses fixtures to exercise the UI on the connected Pixel. Flutter removes that runner after tests; the normal pre-release app is restored afterward. Backend behavior is verified with the Laravel test database. Production end-to-end verification requires deployment approval.
''',encoding='utf-8')
archive=root/'output'/'EduConnect-feature-backend-2026-11-20.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in dest.rglob('*'):
  if p.is_file():z.write(p,p.relative_to(dest))
print(str(archive))
