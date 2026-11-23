"""Deploy private notification deletion with source/database backup and smoke checks.

SSH credentials are read from the terminal and never written to source or logs.
Run --check for a read-only preflight, --publish-apk after the reviewed build.
"""
import argparse
import base64
from datetime import datetime, timezone
import getpass
import hashlib
from pathlib import Path
import shlex
import subprocess
import os
import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = '/var/www/guardianship/backend'
FILES = [
    'app/Http/Controllers/MobileNotificationController.php',
    'app/Http/Controllers/AnnouncementController.php',
    'app/Http/Controllers/SosController.php', 'app/Services/MobileUpdates.php',
    'database/migrations/2026_10_23_000002_create_mobile_dismissals.php',
    'routes/api.php',
]



def run(ssh, command):
    _, out, err = ssh.exec_command(command, timeout=600)
    result, error = out.read().decode(), err.read().decode()
    if out.channel.recv_exit_status():
        raise RuntimeError(error or result)
    print(result.strip(), flush=True)
    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--publish-apk', action='store_true')
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--upload-progress', action='store_true')
    parser.add_argument('--model-only', action='store_true')
    args = parser.parse_args()
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    known = ROOT / '.github/scripts/.server_known_hosts'
    if known.exists():
        ssh.load_host_keys(str(known))
    class PinFirstKey(paramiko.MissingHostKeyPolicy):
        def missing_host_key(self, client, hostname, key):
            fingerprint = base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip('=')
            print(f'First connection host key: {key.get_name()} SHA256:{fingerprint}', flush=True)
            client.get_host_keys().add(hostname, key.get_name(), key)
            client.save_host_keys(str(known))
    ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
    password = getpass.getpass('SSH password: ')
    try:
        ssh.connect('109.199.99.156', username='root', password=password, timeout=30, look_for_keys=False, allow_agent=False)
    finally:
        del password
    try:
        if args.upload_progress:
            run(ssh, 'stat -c "%n %s bytes" ' + REMOTE + '/public/downloads/educonnect-1.0.6.apk* 2>/dev/null || true')
            return
        run(ssh, f'cd {REMOTE} && php -v | head -n 1 && test -f artisan && php artisan migrate:status --no-ansi')
        if args.check:
            return
        if args.model_only:
            relative = 'app/Models/SchoolDocument.php'
            target = REMOTE + '/' + relative
            stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
            backup = '/var/backups/guardianship/' + stamp + '-document-validation'
            run(ssh, f'mkdir -p {backup} && chmod 700 {backup} && cp {target} {backup}/SchoolDocument.php')
            sftp = ssh.open_sftp()
            try:
                sftp.put(str(ROOT / 'backend' / relative), target + '.notification-deletion-tmp')
                run(ssh, 'php -l ' + shlex.quote(target + '.notification-deletion-tmp'))
                sftp.posix_rename(target + '.notification-deletion-tmp', target)
            finally:
                sftp.close()
            local = hashlib.sha256((ROOT / 'backend' / relative).read_bytes()).hexdigest()
            if run(ssh, 'sha256sum ' + shlex.quote(target)).split()[0] != local:
                raise RuntimeError('Model checksum mismatch.')
            run(ssh, 'systemctl reload php8.2-fpm')
            print('Document validation guard deployed; backup=' + backup)
            return
        if args.verify:
            target = '/tmp/educonnect-verify-notification-deletion.php'
            sftp = ssh.open_sftp()
            try:
                sftp.put(str(ROOT / '.github/scripts/verify_notification_deletion.php'), target)
                sftp.chown(target, 33, 33)
                sftp.chmod(target, 0o600)
                output = run(ssh, f'cd {REMOTE} && runuser -u www-data -- php {target}')
                if 'LIVE NOTIFICATION DELETION VERIFICATION PASSED' not in output:
                    raise RuntimeError('Live document verification did not complete.')
            finally:
                sftp.remove(target)
                sftp.close()
            return
        if args.publish_apk:
            apk = ROOT / 'mobile/build/app/outputs/flutter-apk/app-release.apk'
            sdk = Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
            aapt = next(p / 'aapt.exe' for p in sorted((sdk / 'build-tools').iterdir(), reverse=True) if (p / 'aapt.exe').exists())
            metadata = subprocess.run([str(aapt), 'dump', 'badging', str(apk)], check=True, capture_output=True, text=True).stdout
            if "package: name='educonnect.com' versionCode='7' versionName='1.0.6'" not in metadata:
                raise RuntimeError('Wrong APK package/version; publication stopped.')
            with apk.open('rb') as f:
                digest = hashlib.file_digest(f, 'sha256').hexdigest()
            destination = REMOTE + '/public/downloads/educonnect-1.0.6.apk'
            sftp = ssh.open_sftp()
            try:
                last = [-1]
                def progress(sent, total):
                    step = int(sent * 10 / total)
                    if step != last[0]:
                        print(f'Upload {step * 10}%', flush=True)
                        last[0] = step
                sftp.put(str(apk), destination + '.upload-tmp', callback=progress)
                if run(ssh, 'sha256sum ' + shlex.quote(destination + '.upload-tmp')).split()[0] != digest:
                    raise RuntimeError('APK checksum mismatch.')
                sftp.chmod(destination + '.upload-tmp', 0o644)
                sftp.posix_rename(destination + '.upload-tmp', destination)
            finally:
                sftp.close()
            run(ssh, 'curl --fail --silent --show-error --head https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.6.apk')
            print('PUBLISHED Android 1.0.6 (7) SHA256=' + digest)
            return
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        backup = '/var/backups/guardianship/' + stamp + '-notification-deletion'
        run(ssh, f'mkdir -p {backup} && chmod 700 {backup}')
        # Back up selected existing sources without requiring the new files to exist.
        sftp = ssh.open_sftp()
        try:
            existing = []
            for relative in FILES:
                target = REMOTE + '/' + relative
                try:
                    sftp.stat(target)
                    existing.append(relative)
                except OSError:
                    pass
                sftp.put(str(ROOT / 'backend' / relative), target + '.notification-deletion-tmp')
                if target.endswith('.php'):
                    run(ssh, 'php -l ' + shlex.quote(target + '.notification-deletion-tmp'))
            run(ssh, f'cd {REMOTE} && tar -czf {backup}/source.tar.gz ' + ' '.join(shlex.quote(p) for p in existing))
            # Use SQLite's backup API for a consistent backup while the app is online.
            backup_code = f"import sqlite3; source=sqlite3.connect('file:{REMOTE}/database/database.sqlite?mode=ro',uri=True); target=sqlite3.connect('{backup}/database.sqlite'); source.backup(target); assert target.execute('pragma integrity_check').fetchone()[0]=='ok'; target.close(); source.close()"
            run(ssh, 'python3 -c ' + shlex.quote(backup_code))
            try:
                run(ssh, f'cd {REMOTE} && php artisan down --retry=30')
                # Create the table before switching controllers/routes to avoid partial-schema access.
                migration = FILES[4]
                sftp.posix_rename(REMOTE + '/' + migration + '.notification-deletion-tmp', REMOTE + '/' + migration)
                run(ssh, f'cd {REMOTE} && php artisan migrate --force --path={migration}')
                for relative in FILES:
                    if relative != migration:
                        sftp.posix_rename(REMOTE + '/' + relative + '.notification-deletion-tmp', REMOTE + '/' + relative)
                run(ssh, f'cd {REMOTE} && php artisan route:cache && php artisan view:cache && php artisan queue:restart && systemctl reload php8.2-fpm')
            finally:
                run(ssh, f'cd {REMOTE} && php artisan up')
            for relative in FILES:
                local = hashlib.sha256((ROOT / 'backend' / relative).read_bytes()).hexdigest()
                remote = run(ssh, 'sha256sum ' + shlex.quote(REMOTE + '/' + relative)).split()[0]
                if local != remote:
                    raise RuntimeError('Source checksum mismatch: ' + relative)
            run(ssh, f'cd {REMOTE} && php artisan route:list --path=attendance --no-ansi && php artisan route:list --path=messages --no-ansi && curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
            print('NOTIFICATION DELETION DEPLOYED; backup=' + backup, flush=True)
        finally:
            sftp.close()
    finally:
        ssh.close()

if __name__ == '__main__':
    main()
