"""Set the approved SMS sender without exposing tokens or sending a real SMS."""
import getpass
from pathlib import Path
import re
import shlex
from datetime import datetime, timezone
import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = '/var/www/guardianship/backend'

def run(ssh, command):
    _, out, err = ssh.exec_command(command, timeout=180)
    result, error = out.read().decode(), err.read().decode()
    if out.channel.recv_exit_status():
        raise RuntimeError(error or result)
    print(result.strip(), flush=True)

def main():
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
    sftp = ssh.open_sftp()
    temporary = []
    try:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        backup = '/var/backups/guardianship/' + stamp + '-sms-sender'
        run(ssh, f'install -d -m 0700 {backup} && cp --preserve=mode,ownership {REMOTE}/.env {backup}/environment && chmod 0600 {backup}/environment && cp {REMOTE}/config/services.php {backup}/services.php')
        for relative in ['.env', 'config/services.php']:
            target = REMOTE + '/' + relative
            attributes = sftp.stat(target)
            with sftp.open(target, 'r') as f:
                content = f.read().decode()
            if relative == '.env':
                pattern = r'(?m)^\s*(?:export\s+)?SMSPOP_SENDER_ID\s*=.*$'
                if re.search(pattern, content):
                    content = re.sub(pattern, 'SMSPOP_SENDER_ID=CheweTech', content)
                else:
                    content = content.rstrip('\n') + '\nSMSPOP_SENDER_ID=CheweTech\n'
            else:
                content, count = re.subn(r"env\('SMSPOP_SENDER_ID',\s*'[^']*'\)", "env('SMSPOP_SENDER_ID', 'CheweTech')", content)
                if count != 1:
                    raise RuntimeError('Expected one SMS sender configuration; stopped without replacing config.')
            temp = target + '.sms-sender-tmp'
            temporary.append(temp)
            with sftp.open(temp, 'w'):
                pass
            sftp.chmod(temp, 0o600)
            sftp.chown(temp, attributes.st_uid, attributes.st_gid)
            with sftp.open(temp, 'w') as f:
                f.write(content)
            if relative.endswith('.php'):
                run(ssh, 'php -l ' + shlex.quote(temp))
            sftp.chmod(temp, attributes.st_mode & 0o777)
            sftp.posix_rename(temp, target)
        run(ssh, f'cd {REMOTE} && php artisan config:cache && php artisan queue:restart && systemctl reload php8.2-fpm')
        verification = r'''<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if (config('services.smspop.sender_id') !== 'CheweTech') throw new RuntimeException('Sender configuration mismatch.');
if (!config('services.smspop.token')) throw new RuntimeException('SMS token is not configured.');
Illuminate\Support\Facades\Http::preventStrayRequests();
Illuminate\Support\Facades\Http::fake(['smspop.co.zw/*' => Illuminate\Support\Facades\Http::response(['success' => true, 'data' => ['summary' => ['sent' => 1]]])]);
app(App\Services\SmsPop::class)->send(['0771234567'], 'Configuration verification - not sent', 'sender-verification');
$recorded = Illuminate\Support\Facades\Http::recorded(fn ($request) => $request['sender_id'] === 'CheweTech');
if ($recorded->count() !== 1) throw new RuntimeException('SMS payload sender mismatch.');
echo "PASS cached SMS sender: CheweTech\nPASS SMS payload uses CheweTech (mock gateway; no SMS sent)\n";
'''
        verify_path = '/tmp/educonnect-sms-sender-' + stamp + '.php'
        temporary.append(verify_path)
        with sftp.open(verify_path, 'w') as f:
            f.write(verification)
        sftp.chown(verify_path, 33, 33)
        sftp.chmod(verify_path, 0o600)
        run(ssh, f'cd {REMOTE} && runuser -u www-data -- php {shlex.quote(verify_path)}')
        run(ssh, 'curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
        print('SMS sender configured; backup=' + backup, flush=True)
    finally:
        for path in temporary:
            try:
                sftp.remove(path)
            except OSError:
                pass
        sftp.close()
        ssh.close()

if __name__ == '__main__':
    main()
