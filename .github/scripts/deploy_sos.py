"""Deploy targeted SOS or publish its Android build without storing SSH credentials."""
import argparse
import getpass
import hashlib
import os
from pathlib import Path
import shlex
import subprocess
from datetime import datetime, timezone
import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = '/var/www/guardianship/backend'

def run(ssh, command):
    _, out, err = ssh.exec_command(command, timeout=180)
    text, error = out.read().decode(), err.read().decode()
    if out.channel.recv_exit_status():
        raise RuntimeError(error or text)
    print(text.strip(), flush=True)
    return text

def main():
    parser = argparse.ArgumentParser()
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
        with ssh.open_sftp() as sftp:
            if args.publish_apk:
                apk = ROOT / 'mobile/build/app/outputs/flutter-apk/app-release.apk'
                sdk = Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
                aapt = next(p / 'aapt.exe' for p in sorted((sdk / 'build-tools').iterdir(), reverse=True) if (p / 'aapt.exe').exists())
                meta = subprocess.run([str(aapt), 'dump', 'badging', str(apk)], check=True, capture_output=True, text=True).stdout
                if "package: name='educonnect.com' versionCode='6' versionName='1.0.5'" not in meta:
                    raise RuntimeError('Wrong APK version; publication stopped.')
                digest = hashlib.sha256(apk.read_bytes()).hexdigest()
                target = REMOTE + '/public/downloads/educonnect-1.0.5.apk'
                last = [-1]
                def progress(sent, total):
                    step = int(sent * 10 / total)
                    if step != last[0]:
                        print(f'Upload {min(step * 10, 100)}% ({sent}/{total} bytes)', flush=True)
                        last[0] = step
                sftp.put(str(apk), target + '.upload-tmp', callback=progress)
                if run(ssh, 'sha256sum ' + shlex.quote(target + '.upload-tmp')).split()[0] != digest:
                    raise RuntimeError('APK checksum mismatch')
                sftp.chmod(target + '.upload-tmp', 0o644)
                sftp.chown(target + '.upload-tmp', 33, 33)
                sftp.posix_rename(target + '.upload-tmp', target)
                run(ssh, 'curl --fail --silent --show-error --head https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.5.apk')
                print('PUBLISHED Android 1.0.5 (6) SHA256=' + digest)
                return
            relative = 'app/Http/Controllers/SosController.php'
            target = REMOTE + '/' + relative
            stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
            backup = '/var/backups/guardianship/' + stamp + '-targeted-sos'
            run(ssh, f'mkdir -p {backup} && chmod 700 {backup} && cp {target} {backup}/SosController.php')
            sftp.put(str(ROOT / 'backend' / relative), target + '.sos-tmp')
            run(ssh, 'php -l ' + shlex.quote(target + '.sos-tmp'))
            sftp.chmod(target + '.sos-tmp', 0o644)
            sftp.chown(target + '.sos-tmp', 33, 33)
            sftp.posix_rename(target + '.sos-tmp', target)
            local = hashlib.sha256((ROOT / 'backend' / relative).read_bytes()).hexdigest()
            if run(ssh, 'sha256sum ' + shlex.quote(target)).split()[0] != local:
                raise RuntimeError('Controller checksum mismatch')
            run(ssh, 'systemctl reload php8.2-fpm && curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
            print('TARGETED SOS DEPLOYED; backup=' + backup)
    finally:
        ssh.close()

if __name__ == '__main__':
    main()
