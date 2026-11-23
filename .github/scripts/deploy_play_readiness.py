"""Deploy Play Store readiness: account deletion, support reports and public legal pages.

SSH credentials are read from the terminal and never written to source or logs.
  --check         read-only preflight: confirms the server files are exactly what this change expects
  (no flag)       backup, migrate and deploy the backend
  --publish-apk   upload the 1.0.8 test APK to /downloads
"""
import argparse
from datetime import datetime, timezone
import difflib
import getpass
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess
import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = '/var/www/guardianship/backend'
SITE = 'https://admin.chewetechnologies.co.zw'
MIGRATION = 'database/migrations/2026_10_26_000001_create_support_reports.php'
NEW = [
    'app/Http/Controllers/SupportReportController.php',
    'app/Http/Controllers/LegalPageController.php',
    'resources/views/legal.blade.php',
    MIGRATION,
]
# Shared files: the server copy must equal the local copy with this change's edits removed.
UNDO = {
    'app/Http/Controllers/AuthController.php': lambda s: re.sub(
        r'    /\*\*\n     \* Permanently delete the signed-in.*?(?=    /\*\*\n     \* Change password)', '', s, flags=re.S),
    'routes/api.php': lambda s: s.replace(
        "    Route::post('/auth/delete-account', [AuthController::class, 'deleteAccount'])->middleware('throttle:5,1');\n", '').replace(
        "    Route::post('/support/reports', [\\App\\Http\\Controllers\\SupportReportController::class, 'store'])->middleware('throttle:5,1');\n", ''),
    'routes/web.php': lambda s: re.sub(r'// Public pages linked from the Google Play listing.*?\n\n', '', s, flags=re.S),
    'config/services.php': lambda s: s.replace(
        "    'support' => [\n        'email' => env('SUPPORT_EMAIL', 'admin@teramark.co.zw'),\n    ],\n\n", ''),
}
FILES = NEW + list(UNDO)
TMP = '.play-readiness-tmp'


def run(ssh, command):
    _, out, err = ssh.exec_command(command, timeout=600)
    result, error = out.read().decode(), err.read().decode()
    if out.channel.recv_exit_status():
        raise RuntimeError(error or result)
    print(result.strip(), flush=True)
    return result


def lf(text):
    return text.replace('\r\n', '\n')


def preflight(sftp):
    """Stop if the live server has changes this deploy would overwrite."""
    ok = True
    for relative, undo in UNDO.items():
        local = lf((ROOT / 'backend' / relative).read_text(encoding='utf-8'))
        expected = undo(local)
        if expected == local:
            raise RuntimeError('Change not found locally in ' + relative)
        with sftp.open(REMOTE + '/' + relative) as f:
            remote = lf(f.read().decode('utf-8'))
        if remote == local:
            print('already deployed  ' + relative)
        elif remote == expected:
            print('ready             ' + relative)
        else:
            ok = False
            print('SERVER DIFFERS    ' + relative)
            print(''.join(difflib.unified_diff(expected.splitlines(True), remote.splitlines(True), 'expected', 'server', n=1))[:4000])
    for relative in NEW:
        try:
            sftp.stat(REMOTE + '/' + relative)
            print('exists, replacing ' + relative)
        except OSError:
            print('new               ' + relative)
    if not ok:
        raise SystemExit('Preflight failed: server files differ from what this deploy expects. Nothing was changed.')


def publish_apk(ssh, sftp):
    apk = ROOT / 'mobile/build/app/outputs/flutter-apk/app-release.apk'
    sdk = Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
    aapt = next(p / 'aapt.exe' for p in sorted((sdk / 'build-tools').iterdir(), reverse=True) if (p / 'aapt.exe').exists())
    meta = subprocess.run([str(aapt), 'dump', 'badging', str(apk)], check=True, capture_output=True, text=True).stdout
    if "package: name='educonnect.com' versionCode='9' versionName='1.0.8'" not in meta:
        raise RuntimeError('Wrong APK version; publication stopped.')
    with apk.open('rb') as f:
        digest = hashlib.file_digest(f, 'sha256').hexdigest()
    target = REMOTE + '/public/downloads/educonnect-1.0.8.apk'
    last = [-1]
    def progress(sent, total):
        step = int(sent * 10 / total)
        if step != last[0]:
            print(f'Upload {step * 10}%', flush=True)
            last[0] = step
    sftp.put(str(apk), target + '.upload-tmp', callback=progress)
    if run(ssh, 'sha256sum ' + shlex.quote(target + '.upload-tmp')).split()[0] != digest:
        raise RuntimeError('APK checksum mismatch.')
    sftp.chmod(target + '.upload-tmp', 0o644)
    sftp.chown(target + '.upload-tmp', 33, 33)
    sftp.posix_rename(target + '.upload-tmp', target)
    run(ssh, f'curl --fail --silent --show-error --head {SITE}/downloads/educonnect-1.0.8.apk')
    print(f'PUBLISHED Android 1.0.8 (9) {SITE}/downloads/educonnect-1.0.8.apk SHA256={digest}')


def deploy(ssh, sftp):
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    backup = '/var/backups/guardianship/' + stamp + '-play-readiness'
    run(ssh, f'mkdir -p {backup} && chmod 700 {backup}')
    existing = []
    for relative in FILES:
        target = REMOTE + '/' + relative
        try:
            sftp.stat(target)
            existing.append(relative)
        except OSError:
            pass
        sftp.put(str(ROOT / 'backend' / relative), target + TMP)
        sftp.chown(target + TMP, 33, 33)
        if relative.endswith('.php') and not relative.endswith('.blade.php'):
            run(ssh, 'php -l ' + shlex.quote(target + TMP))
    if existing:
        run(ssh, f'cd {REMOTE} && tar -czf {backup}/source.tar.gz ' + ' '.join(shlex.quote(p) for p in existing))
    backup_code = f"import sqlite3; source=sqlite3.connect('file:{REMOTE}/database/database.sqlite?mode=ro',uri=True); target=sqlite3.connect('{backup}/database.sqlite'); source.backup(target); assert target.execute('pragma integrity_check').fetchone()[0]=='ok'; target.close(); source.close()"
    run(ssh, 'python3 -c ' + shlex.quote(backup_code))
    try:
        run(ssh, f'cd {REMOTE} && php artisan down --retry=30')
        # Create the table before the controller that writes to it goes live.
        sftp.posix_rename(REMOTE + '/' + MIGRATION + TMP, REMOTE + '/' + MIGRATION)
        run(ssh, f'cd {REMOTE} && php artisan migrate --force --path={MIGRATION}')
        for relative in FILES:
            if relative != MIGRATION:
                sftp.posix_rename(REMOTE + '/' + relative + TMP, REMOTE + '/' + relative)
        run(ssh, f'cd {REMOTE} && (test ! -f bootstrap/cache/config.php || php artisan config:cache) && php artisan route:cache && php artisan view:cache && php artisan queue:restart && systemctl reload php8.2-fpm')
    finally:
        run(ssh, f'cd {REMOTE} && php artisan up')
    for relative in FILES:
        local = hashlib.sha256((ROOT / 'backend' / relative).read_bytes()).hexdigest()
        if run(ssh, 'sha256sum ' + shlex.quote(REMOTE + '/' + relative)).split()[0] != local:
            raise RuntimeError('Source checksum mismatch: ' + relative)
    run(ssh, f'cd {REMOTE} && php artisan route:list --path=auth/delete-account --no-ansi && php artisan route:list --path=support --no-ansi')
    for page in ['privacy-policy', 'terms', 'account-deletion']:
        run(ssh, f'curl --fail --silent --show-error {SITE}/{page} | grep -c admin@teramark.co.zw')
    # Without a token both new endpoints must refuse (401), proving they are routed and protected.
    run(ssh, f'test "$(curl -s -o /dev/null -w "%{{http_code}}" -X POST -H "Accept: application/json" {SITE}/api/auth/delete-account)" = 401')
    run(ssh, f'test "$(curl -s -o /dev/null -w "%{{http_code}}" -X POST -H "Accept: application/json" {SITE}/api/support/reports)" = 401')
    run(ssh, f'curl --fail --silent --show-error {SITE}/api/health')
    print('PLAY READINESS DEPLOYED; backup=' + backup, flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--publish-apk', action='store_true')
    args = parser.parse_args()
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    known = ROOT / '.github/scripts/.server_known_hosts'
    if known.exists():
        ssh.load_host_keys(str(known))
    ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
    password = getpass.getpass('SSH password: ')
    try:
        ssh.connect('109.199.99.156', username='root', password=password, timeout=30, look_for_keys=False, allow_agent=False)
    finally:
        del password
    try:
        sftp = ssh.open_sftp()
        try:
            if args.publish_apk:
                publish_apk(ssh, sftp)
                return
            run(ssh, f'cd {REMOTE} && php -v | head -n 1 && test -f artisan')
            preflight(sftp)
            if args.check:
                print('PREFLIGHT OK (nothing changed)')
                return
            deploy(ssh, sftp)
        finally:
            sftp.close()
    finally:
        ssh.close()


if __name__ == '__main__':
    main()
