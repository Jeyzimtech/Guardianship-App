"""Authenticated deployment preflight. Password is read only from the terminal."""
import base64
import getpass
import json
import os
from pathlib import Path
import shlex
import sys
import paramiko

ROOT = Path(__file__).resolve().parents[2]
REMOTE = '/var/www/guardianship/backend'

def run(ssh, command, code=None):
    stdin, stdout, stderr = ssh.exec_command(command, timeout=600)
    if code is not None:
        stdin.write(code)
        stdin.flush()
        stdin.channel.shutdown_write()
    output = stdout.read().decode(errors='replace')
    errors = stderr.read().decode(errors='replace')
    status = stdout.channel.recv_exit_status()
    if output:
        print(output, flush=True)
    if errors:
        print(errors, flush=True)
    if status:
        raise RuntimeError(f'Remote command exited with status {status}')
    return output

def main():
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    known = ROOT / '.github' / 'scripts' / '.server_known_hosts'
    if known.exists():
        ssh.load_host_keys(str(known))
    class PinFirstKey(paramiko.MissingHostKeyPolicy):
        def missing_host_key(self, client, hostname, key):
            import hashlib
            fingerprint = base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip('=')
            print(f'First connection host key: {key.get_name()} SHA256:{fingerprint}', flush=True)
            client.get_host_keys().add(hostname, key.get_name(), key)
            client.save_host_keys(str(known))
    ssh.set_missing_host_key_policy(PinFirstKey())
    password = getpass.getpass('SSH password: ')
    ssh.connect('109.199.99.156', username='root', password=password, timeout=30, look_for_keys=False, allow_agent=False)
    del password
    print('CONNECTED', flush=True)
    if '--finish-pesepay' in sys.argv:
        sftp = ssh.open_sftp()
        remote_script = '/tmp/guardianship-payment-workers.sh'
        try:
            for relative in ['app/Http/Controllers/UniformPaymentController.php', 'app/Services/Pesepay.php', 'routes/console.php']:
                sftp.put(str(ROOT / 'backend' / relative), REMOTE + '/' + relative + '.deploy-tmp')
                sftp.posix_rename(REMOTE + '/' + relative + '.deploy-tmp', REMOTE + '/' + relative)
            sftp.put(str(ROOT / '.github/scripts/install_payment_workers.sh'), remote_script)
            run(ssh, f'cd {REMOTE} && php artisan route:cache && php artisan uniforms:seed-payment-test 2 && systemctl reload php8.2-fpm && bash {remote_script}')
        finally:
            sftp.remove(remote_script)
            sftp.close()
            ssh.close()
        return
    if '--configure-pesepay' in sys.argv:
        integration = getpass.getpass('PesePay test integration key: ').strip()
        encryption = getpass.getpass('PesePay test encryption key: ').strip()
        if len(encryption) != 32 or not integration:
            raise ValueError('PesePay requires an integration key and a 32-byte encryption key')
        sftp = ssh.open_sftp()
        try:
            with sftp.open(REMOTE + '/.env', 'r') as source:
                previous = source.read().decode()
            # Retain a protected environment backup; credentials never enter source control.
            with sftp.open(REMOTE + '/.env.before-pesepay', 'w') as backup:
                backup.write(previous)
            sftp.chmod(REMOTE + '/.env.before-pesepay', 0o600)
            values = {'PESEPAY_SANDBOX': 'true', 'PESEPAY_INTEGRATION_KEY': integration, 'PESEPAY_ENCRYPTION_KEY': encryption}
            lines = [line for line in previous.splitlines() if line.partition('=')[0] not in values and not line.startswith('ROADRUNNER_')]
            lines += [key + '=' + value for key, value in values.items()]
            with sftp.open(REMOTE + '/.env.pesepay-tmp', 'w') as target:
                target.write('\n'.join(lines) + '\n')
            sftp.chmod(REMOTE + '/.env.pesepay-tmp', 0o640)
            sftp.chown(REMOTE + '/.env.pesepay-tmp', 0, 33)
            sftp.posix_rename(REMOTE + '/.env.pesepay-tmp', REMOTE + '/.env')
        finally:
            sftp.close()
            ssh.close()
        print('PesePay test credentials saved server-side. Cache refresh occurs during deployment.', flush=True)
        return
    if '--audit-uniform' in sys.argv:
        sftp = ssh.open_sftp()
        try:
            target = ROOT / 'backend/storage/app/role-audit/deployed-UniformController.php'
            sftp.get(REMOTE + '/app/Http/Controllers/UniformController.php', str(target))
            print('Downloaded deployed uniform controller for read-only comparison', flush=True)
        finally:
            sftp.close()
            ssh.close()
        return
    if '--verify-pesepay' in sys.argv:
        remote_file = '/tmp/guardianship-pesepay-check.php'
        sftp = ssh.open_sftp()
        try:
            sftp.put(str(ROOT / '.github/scripts/verify_pesepay.php'), remote_file)
            sftp.chmod(remote_file, 0o600)
            run(ssh, f'cd {REMOTE} && php {remote_file}')
        finally:
            sftp.remove(remote_file)
            sftp.close()
            ssh.close()
        return
    if '--progress' in sys.argv:
        run(ssh, "date -u; ps -eo pid,etime,args | grep -E 'sftp|composer|artisan|tar'; find /var/www/guardianship/backend -name '*.deploy-tmp' -printf '%p %s bytes\\n'")
        ssh.close()
        return
    if '--role-audit' in sys.argv:
        remote_file = '/tmp/guardianship-role-audit.php'
        remote_hashes = '/tmp/guardianship-role-audit-hashes.json'
        sftp = ssh.open_sftp()
        try:
            sftp.put(str(ROOT / '.github/scripts/role_audit_live.php'), remote_file)
            sftp.put(str(ROOT / '.github/scripts/role-audit-source-hashes.json'), remote_hashes)
            run(ssh, f'cd {REMOTE} && php {remote_file}')
        finally:
            sftp.remove(remote_file)
            sftp.remove(remote_hashes)
            sftp.close()
            ssh.close()
        return
    if '--verify' in sys.argv:
        remote_file = '/tmp/guardianship-verify-release.php'
        sftp = ssh.open_sftp()
        try:
            sftp.put(str(ROOT / '.github/scripts/verify_release.php'), remote_file)
            sftp.chmod(remote_file, 0o600)
            run(ssh, f'cd {REMOTE} && php {remote_file}')
        finally:
            sftp.remove(remote_file)
            sftp.close()
            ssh.close()
        return
    run(ssh, f'cd {REMOTE} && php -v && php artisan migrate:status && df -h /var/www && nginx -t')
    inspect = '''<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();
$db = config('database.default');
$result = ['environment' => app()->environment(), 'debug' => config('app.debug'), 'url' => config('app.url'), 'database_driver' => $db, 'database_path' => $db === 'sqlite' ? config('database.connections.sqlite.database') : null];
foreach (['users','schools','students','teachers','uniform_items','announcements','journal_entries','subscriptions'] as $table) {
 if (Illuminate\\Support\\Facades\\Schema::hasTable($table)) $result['counts'][$table] = Illuminate\\Support\\Facades\\DB::table($table)->count();
}
$result['owner_accounts'] = App\\Models\\User::where('role','website_admin')->get(['id','email'])->toArray();
$result['schools'] = App\\Models\\School::get(['id','name'])->toArray();
echo json_encode($result, JSON_PRETTY_PRINT);
'''
    run(ssh, f'cd {REMOTE} && php', inspect)
    print('READY. Enter a remote command, PHP:<base64 script>, DEPLOY, or EXIT.', flush=True)
    for line in sys.stdin:
        command = line.strip()
        if command == 'EXIT':
            break
        try:
            if command == 'DEPLOY':
                import deploy
                deploy.deploy_connected(ssh)
            elif command == 'PAYMENT_WORKERS':
                remote_script = '/tmp/guardianship-payment-workers.sh'
                sftp = ssh.open_sftp()
                try:
                    sftp.put(str(ROOT / '.github/scripts/install_payment_workers.sh'), remote_script)
                    run(ssh, 'bash ' + remote_script)
                finally:
                    sftp.remove(remote_script)
                    sftp.close()
            elif command.startswith('PHP:'):
                run(ssh, f'cd {REMOTE} && php', base64.b64decode(command[4:]).decode())
            elif command:
                run(ssh, command)
        except Exception as exc:
            print(f'ERROR: {exc}', flush=True)
        print('READY', flush=True)
    ssh.close()

if __name__ == '__main__':
    main()
