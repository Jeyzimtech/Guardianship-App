"""Verify the deployed mobile backend without touching real attendance records."""
import getpass
import hashlib
from pathlib import Path
import shlex
import uuid
import sys
from datetime import datetime, timezone
import paramiko
from server_session import run, ROOT, REMOTE

ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
known = ROOT / '.github/scripts/.server_known_hosts'
if known.exists():
    ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password = getpass.getpass('SSH password: ')
ssh.connect('109.199.99.156', username='root', password=password, timeout=30,
            look_for_keys=False, allow_agent=False)
del password
if '--diagnose-attendance' in sys.argv:
    try:
        run(ssh, 'cd ' + REMOTE + ' && php', r'''<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
echo json_encode(Illuminate\Support\Facades\DB::select("SELECT sql FROM sqlite_master WHERE name='attendance_records'"), JSON_PRETTY_PRINT).PHP_EOL;
$lines = file(storage_path('logs/laravel.log'));
foreach (array_reverse($lines) as $line) {
    if (str_contains($line, 'production.ERROR:') && str_contains($line, 'attendance_records')) {
        echo substr(explode('(Connection:', $line)[0], 0, 500).PHP_EOL;
        break;
    }
}
''')
    finally:
        ssh.close()
    raise SystemExit(0)
sftp = ssh.open_sftp()
temporary = []
try:
    if '--apply-attendance-upgrade' in sys.argv:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        backup = '/var/backups/guardianship/' + stamp + '-attendance'
        try:
            run(ssh, 'cd ' + REMOTE + ' && php artisan down --retry=30')
            run(ssh, 'bash -se', f'''umask 077
mkdir -p {backup}
cd {REMOTE}
python3 - <<'PY'
import sqlite3
source = sqlite3.connect('file:{REMOTE}/database/database.sqlite?mode=ro', uri=True)
target = sqlite3.connect('{backup}/database.sqlite')
source.backup(target)
assert target.execute('pragma integrity_check').fetchone()[0] == 'ok'
target.close()
source.close()
print('Attendance upgrade database backup: {backup}')
PY
''')
            relative = 'database/migrations/2026_10_21_000003_align_attendance_statuses.php'
            destination = REMOTE + '/' + relative
            sftp.put(str(ROOT / 'backend' / relative), destination + '.deploy-tmp')
            sftp.posix_rename(destination + '.deploy-tmp', destination)
            run(ssh, 'cd ' + REMOTE + ' && php artisan migrate --force && chown -R www-data:www-data database && php artisan queue:restart')
        finally:
            run(ssh, 'cd ' + REMOTE + ' && php artisan up')
    for filename, interpreter in [('install_notification_worker.sh', 'bash'), ('verify_mobile_release.php', 'php')]:
        if '--verify-only' in sys.argv and interpreter == 'bash':
            continue
        target = '/tmp/guardianship-' + uuid.uuid4().hex + '-' + filename
        temporary.append(target)
        sftp.put(str(ROOT / '.github/scripts' / filename), target)
        sftp.chmod(target, 0o600)
        if interpreter == 'php' and '--verify-only' not in sys.argv:
            run(ssh, 'systemctl reload php8.2-fpm')
        output = run(ssh, 'cd ' + REMOTE + ' && ' + interpreter + ' ' + shlex.quote(target))
        if interpreter == 'php' and 'LIVE MOBILE RELEASE VERIFICATION PASSED' not in output:
            raise RuntimeError('Live checks did not finish successfully.')

    files = [
        'app/Http/Controllers/AttendanceController.php',
        'app/Http/Controllers/MessageController.php',
        'app/Http/Controllers/MobileNotificationController.php',
        'app/Http/Controllers/StudentPhotoController.php',
        'app/Http/Controllers/ActivityController.php',
        'app/Services/MessageReceipts.php', 'app/Services/MobileUpdates.php',
        'app/Services/FirebasePush.php', 'app/Jobs/SendMobilePush.php',
        'routes/api.php', 'resources/views/admin.blade.php',
        'database/migrations/2026_10_21_000003_align_attendance_statuses.php',
    ]
    for relative in files:
        local = hashlib.sha256((ROOT / 'backend' / relative).read_bytes()).hexdigest()
        output = run(ssh, 'sha256sum ' + shlex.quote(REMOTE + '/' + relative))
        if output.split()[0] != local:
            raise RuntimeError('Source hash mismatch: ' + relative)
    print('PASS deployed source hashes match local release', flush=True)
    run(ssh, 'systemctl is-active nginx php8.2-fpm guardianship-notification-queue.service guardianship-payment-queue.service && curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
finally:
    for target in temporary:
        try:
            sftp.remove(target)
        except OSError:
            pass
    sftp.close()
    ssh.close()
