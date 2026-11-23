"""Send the single user-requested SMS through the deployed application service."""
import getpass
from pathlib import Path
import uuid
import paramiko

root = Path(__file__).resolve().parents[1]
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
known = root / '.github/scripts/.server_known_hosts'
if known.exists():
    ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password = getpass.getpass('SSH password: ')
try:
    ssh.connect('109.199.99.156', username='root', password=password, timeout=30, look_for_keys=False, allow_agent=False)
finally:
    del password
tag = uuid.uuid4().hex
remote = '/tmp/educonnect-sms-test-' + tag + '.php'
code = r'''<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
if (config('services.smspop.sender_id') !== 'CheweTech') throw new RuntimeException('Sender ID mismatch; SMS not sent.');
echo "Submitting one test SMS to 0776015100 as CheweTech. No automatic retries.\n";
flush();
try {
    $result = app(App\Services\SmsPop::class)->send(
        ['0776015100'],
        'EduConnect test SMS from CheweTech. This is a test message; no action is required.',
        'EduConnect requested SMS test __TAG__'
    );
    $safe = ['campaign_id' => $result['id'] ?? $result['campaign_id'] ?? null, 'summary' => $result['summary'] ?? null];
    foreach (($result['contacts'] ?? []) as $contact) {
        $safe['contacts'][] = array_intersect_key($contact, array_flip(['message_id', 'status', 'error', 'error_message']));
    }
    echo 'PROVIDER_ACCEPTED '.json_encode($safe).PHP_EOL;
} catch (Throwable $error) {
    echo 'SEND_ERROR '.$error->getMessage().PHP_EOL;
    echo "No retry was attempted. A timeout does not prove the SMS was not sent.\n";
    exit(1);
}
'''.replace('__TAG__', tag)
sftp = ssh.open_sftp()
try:
    with sftp.open(remote, 'w') as f:
        f.write(code)
    sftp.chown(remote, 33, 33)
    sftp.chmod(remote, 0o600)
    _, out, err = ssh.exec_command('cd /var/www/guardianship/backend && runuser -u www-data -- php ' + remote, timeout=180)
    for line in iter(out.readline, ''):
        print(line.rstrip(), flush=True)
    errors = err.read().decode()
    status = out.channel.recv_exit_status()
    if errors:
        print(errors, flush=True)
    if status:
        raise SystemExit(status)
finally:
    try:
        sftp.remove(remote)
    finally:
        sftp.close()
        ssh.close()
