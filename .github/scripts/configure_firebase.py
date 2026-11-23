"""Install the user's supplied Firebase key privately, without logging its contents."""
import getpass
import hashlib
import json
from pathlib import Path
import shlex
import sys
import uuid
import paramiko
from server_session import ROOT, REMOTE, run

if len(sys.argv) != 2:
    raise SystemExit('Usage: python configure_firebase.py <service-account-file-path>')
source = Path(sys.argv[1])
credential = json.loads(source.read_text(encoding='utf-8-sig'))
if credential.get('type') != 'service_account' or credential.get('project_id') != 'educonnect-13f25' or not credential.get('private_key'):
    raise SystemExit('Expected a service-account key for educonnect-13f25.')
del credential
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
sftp = ssh.open_sftp()
tag = uuid.uuid4().hex
key_path = '/etc/guardianship/firebase-service-account.json'
key_temp = '/etc/guardianship/.firebase-' + tag + '.tmp'
env_temp = REMOTE + '/.env.firebase-' + tag
verification = '/tmp/guardianship-firebase-' + tag + '.php'
backup = '/var/backups/guardianship/firebase-configuration-' + tag
try:
    run(ssh, 'install -d -o root -g www-data -m 0750 /etc/guardianship && install -d -m 0700 ' + shlex.quote(backup))
    run(ssh, 'cp --preserve=mode,ownership ' + REMOTE + '/.env ' + shlex.quote(backup + '/environment') +
        ' && chmod 0600 ' + shlex.quote(backup + '/environment') +
        ' && if [ -f ' + key_path + ' ]; then cp ' + key_path + ' ' + shlex.quote(backup + '/previous-firebase-key.json') +
        '; chmod 0600 ' + shlex.quote(backup + '/previous-firebase-key.json') + '; fi')
    # Create with restrictive permissions before any private data is written.
    with sftp.open(key_temp, 'w'):
        pass
    sftp.chmod(key_temp, 0o640)
    sftp.chown(key_temp, 0, 33)
    sftp.put(str(source), key_temp)
    with source.open('rb') as local:
        digest = hashlib.file_digest(local, 'sha256').hexdigest()
    # Capture the remote checksum privately rather than printing it.
    _, stdout, stderr = ssh.exec_command('sha256sum ' + shlex.quote(key_temp))
    remote_digest = stdout.read().decode().split()[0]
    if stdout.channel.recv_exit_status() or remote_digest != digest:
        raise RuntimeError('Credential upload checksum verification failed.')
    sftp.posix_rename(key_temp, key_path)
    with sftp.open(REMOTE + '/.env', 'r') as current:
        environment = current.read().decode()
    lines = [line for line in environment.splitlines() if line.partition('=')[0].strip() != 'FIREBASE_CREDENTIALS']
    lines.append('FIREBASE_CREDENTIALS=' + key_path)
    with sftp.open(env_temp, 'w'):
        pass
    sftp.chmod(env_temp, 0o640)
    sftp.chown(env_temp, 0, 33)
    with sftp.open(env_temp, 'w') as target:
        target.write('\n'.join(lines) + '\n')
    sftp.posix_rename(env_temp, REMOTE + '/.env')
    print('Private key uploaded and backend credential path configured.', flush=True)
    run(ssh, 'cd ' + REMOTE + ' && php artisan config:cache && php artisan queue:restart && systemctl restart guardianship-notification-queue.service && systemctl reload php8.2-fpm')
    sftp.put(str(ROOT / '.github/scripts/verify_firebase_connection.php'), verification)
    sftp.chmod(verification, 0o640)
    sftp.chown(verification, 0, 33)
    output = run(ssh, 'cd ' + REMOTE + ' && runuser -u www-data -- php ' + shlex.quote(verification))
    if 'FIREBASE CONNECTION VERIFIED' not in output:
        raise RuntimeError('Firebase connection check did not complete.')
    run(ssh, 'stat -c "%a %U:%G" ' + key_path + ' && systemctl is-active guardianship-notification-queue.service php8.2-fpm nginx && curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
    print('Firebase server setup complete. Protected configuration backup: ' + backup, flush=True)
finally:
    for temporary in [key_temp, env_temp, verification]:
        try:
            sftp.remove(temporary)
        except OSError:
            pass
    sftp.close()
    ssh.close()
