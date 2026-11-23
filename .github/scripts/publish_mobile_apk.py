"""Publish the reviewed Android build; SSH password stays in terminal input."""
import getpass
import hashlib
from pathlib import Path
import shlex
import os
import subprocess
import paramiko

root = Path(__file__).resolve().parents[2]
apk = root / 'mobile/build/app/outputs/flutter-apk/app-release.apk'
if not apk.is_file():
    raise SystemExit('Build the release APK first.')
sdk = Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or
           str(Path(os.environ['LOCALAPPDATA']) / 'Android/Sdk'))
aapt = next((folder / 'aapt.exe' for folder in sorted((sdk / 'build-tools').iterdir(), reverse=True)
             if (folder / 'aapt.exe').is_file()), None)
if aapt is None:
    raise SystemExit('Android aapt is needed to validate the APK before publishing.')
metadata = subprocess.run([str(aapt), 'dump', 'badging', str(apk)], check=True,
                          capture_output=True, text=True).stdout
if "package: name='educonnect.com' versionCode='3' versionName='1.0.2'" not in metadata:
    raise SystemExit('APK must be educonnect.com version 1.0.2, build 3; nothing published.')
print('Verified APK package educonnect.com, version 1.0.2 (build 3).', flush=True)
with apk.open('rb') as source:
    digest = hashlib.file_digest(source, 'sha256').hexdigest()
destination = '/var/www/guardianship/backend/public/downloads/educonnect-1.0.2.apk'
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
known = root / '.github/scripts/.server_known_hosts'
if known.exists():
    ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password = getpass.getpass('SSH password: ')
ssh.connect('109.199.99.156', username='root', password=password, timeout=30,
            look_for_keys=False, allow_agent=False)
del password

def run(command):
    _, stdout, stderr = ssh.exec_command(command, timeout=180)
    output = stdout.read().decode().strip()
    error = stderr.read().decode().strip()
    if stdout.channel.recv_exit_status():
        raise RuntimeError(error or output)
    return output

try:
    run('mkdir -p /var/www/guardianship/backend/public/downloads')
    sftp = ssh.open_sftp()
    temporary = destination + '.upload-tmp'
    try:
        print('Uploading Android 1.0.2 (build 3)...', flush=True)
        sftp.put(str(apk), temporary)
        remote_digest = run('sha256sum ' + shlex.quote(temporary)).split()[0]
        if remote_digest != digest:
            raise RuntimeError('APK checksum mismatch; upload was not published.')
        sftp.chmod(temporary, 0o644)
        sftp.chown(temporary, 33, 33)
        sftp.posix_rename(temporary, destination)
    finally:
        try:
            sftp.remove(temporary)
        except OSError:
            pass
        sftp.close()
    print('SHA256=' + digest)
    print('BYTES=' + str(apk.stat().st_size))
    print(run('curl --fail --silent --show-error --head https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.2.apk'))
    print('PUBLISHED https://admin.chewetechnologies.co.zw/downloads/educonnect-1.0.2.apk', flush=True)
finally:
    ssh.close()
