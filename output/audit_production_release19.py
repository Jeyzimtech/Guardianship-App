import getpass,json,shlex
from pathlib import Path
import paramiko
root=Path(__file__).resolve().parents[1]
ssh=paramiko.SSHClient();ssh.load_system_host_keys();ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password=getpass.getpass('Server SSH password (not saved): ')
try:ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
finally:del password
remote='/var/www/guardianship/backend'
def run(command):
 _,out,err=ssh.exec_command(command,timeout=120);data,error=out.read().decode(),err.read().decode()
 if out.channel.recv_exit_status():raise RuntimeError(error or data)
 return data.strip()
try:
 php="require 'vendor/autoload.php'; $app=require 'bootstrap/app.php'; $app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap(); echo json_encode(['environment'=>config('app.env'),'debug'=>(bool)config('app.debug'),'pesepay_sandbox'=>(bool)config('services.pesepay.sandbox'),'pesepay_configured'=>filled(config('services.pesepay.integration_key')) && strlen(config('services.pesepay.encryption_key',''))===32,'firebase_credentials_readable'=>is_readable(config('services.firebase.credentials')??''),'mail_transport'=>config('mail.default'),'proof_column'=>Illuminate\\Support\\Facades\\Schema::hasColumn('fee_transactions','proof_path')]);"
 report={'configuration':json.loads(run('cd '+remote+' && php -r '+shlex.quote(php)))}
 report['services']=run('systemctl is-active nginx php8.2-fpm guardianship-notification-queue.service educonnect-message-retention.timer').splitlines()
 report['http']=run("for p in /api/health /privacy-policy /terms /account-deletion /api/subscription; do printf '%s ' \"$p\"; curl --max-time 20 --silent --show-error --output /dev/null --write-out '%{http_code}\\n' https://admin.chewetechnologies.co.zw$p; done")
 report['disk']=run('df -h / | tail -1')
 (root/'output/release19-server-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print(json.dumps(report,indent=2),flush=True)
finally:ssh.close()
