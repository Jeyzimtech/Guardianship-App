import getpass,json,shlex
from datetime import datetime,timezone
from pathlib import Path
import paramiko
r=Path(__file__).resolve().parents[1];remote='/var/www/guardianship/backend'
s=paramiko.SSHClient();s.load_system_host_keys();s.set_missing_host_key_policy(paramiko.RejectPolicy())
p=getpass.getpass('Server SSH password (not saved): ')
try:s.connect('109.199.99.156',username='root',password=p,timeout=30,look_for_keys=False,allow_agent=False)
finally:del p
def run(cmd):
 _,out,err=s.exec_command(cmd,timeout=120);data,error=out.read().decode(),err.read().decode()
 if out.channel.recv_exit_status():raise RuntimeError(error or data)
 return data.strip()
try:
 backup='/var/backups/guardianship/'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-release19-policy'
 run('mkdir -p '+backup+' && chmod 700 '+backup)
 ftp=s.open_sftp()
 for name in ['app/Http/Controllers/LegalPageController.php','resources/views/legal.blade.php']:
  with ftp.open(remote+'/'+name,'rb') as f:data=f.read()
  with ftp.open(backup+'/'+name.replace('/','__'),'wb') as f:f.write(data)
  ftp.put(str(r/'backend'/name),remote+'/'+name+'.r19-tmp');ftp.chmod(remote+'/'+name+'.r19-tmp',0o644)
  run('php -l '+shlex.quote(remote+'/'+name+'.r19-tmp'));ftp.posix_rename(remote+'/'+name+'.r19-tmp',remote+'/'+name)
 run('cd '+remote+' && php artisan view:cache && systemctl reload php8.2-fpm')
 php="require 'vendor/autoload.php'; $app=require 'bootstrap/app.php'; $app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap(); App\\Http\\Controllers\\EmailSettingsController::configureMailTransport(); $ok=false; try { $t=Illuminate\\Support\\Facades\\Mail::mailer()->getSymfonyTransport(); $t->start(); $ok=true; $t->stop(); } catch (Throwable $e) {} echo json_encode(['configured_transport'=>config('mail.default'),'smtp_connection_authenticated'=>$ok,'smtp_host_configured'=>filled(config('mail.mailers.smtp.host')),'sender_configured'=>filled(config('mail.from.address'))]);"
 result=json.loads(run('cd '+remote+' && php -r '+shlex.quote(php)))
 result['policy_backup']=backup
 result['api_subscription_status']=run("curl --silent --show-error -H 'Accept: application/json' --output /dev/null --write-out '%{http_code}' https://admin.chewetechnologies.co.zw/api/subscription")
 result['privacy_updated']= '20 November 2026' in run('curl --silent --show-error https://admin.chewetechnologies.co.zw/privacy-policy')
 (r/'output/release19-mail-policy-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
 print(json.dumps(result,indent=2),flush=True)
finally:s.close()
