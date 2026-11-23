"""Deploy reviewed release fixes, preserving unrelated server changes and records."""
import getpass, hashlib, shlex
from datetime import datetime, timezone
from pathlib import Path
import paramiko

root=Path(__file__).resolve().parents[2]
remote='/var/www/guardianship/backend'
ssh=paramiko.SSHClient();ssh.load_system_host_keys()
known=root/'.github/scripts/.server_known_hosts'
if known.exists():ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password=getpass.getpass('SSH password: ')
try:ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
finally:del password
sftp=ssh.open_sftp()
def run(command,timeout=90):
 _,out,err=ssh.exec_command(command,timeout=timeout)
 output=out.read().decode();error=err.read().decode()
 if out.channel.recv_exit_status():raise RuntimeError(error or output)
 print(output.strip(),flush=True);return output
def read(path):
 try:
  with sftp.open(path,'rb') as f:return f.read()
 except FileNotFoundError:return None
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup='/var/backups/guardianship/'+stamp+'-release16'
run('mkdir -p '+backup+' && chmod 700 '+backup)
targets={}
for relative in ['app/Http/Controllers/SupportReportController.php','app/Http/Controllers/MessageController.php','app/Services/MessageSafety.php','app/Services/MobileUpdates.php','resources/views/moderation.blade.php','resources/views/legal.blade.php','app/Http/Controllers/LegalPageController.php','database/migrations/2026_10_26_000001_create_support_reports.php','database/migrations/2026_10_30_000001_add_message_safety_controls.php']:
 targets[remote+'/'+relative]=(root/'backend'/relative).read_bytes()
# Only insert the reviewed account-deletion method into the current server controller.
authpath=remote+'/app/Http/Controllers/AuthController.php'
auth=read(authpath).decode('utf-8')
local=(root/'backend/app/Http/Controllers/AuthController.php').read_text(encoding='utf-8')
start=local.index('    public function deleteAccount(')
end=local.index('    /**',start)
method=local[start:end]
if 'public function deleteAccount(' not in auth:
 position=auth.rfind('}')
 auth=auth[:position]+'\n'+method+auth[position:]
elif method.strip() not in auth:
 raise RuntimeError('Existing server deletion implementation differs; stop for review.')
for namespace in ['Illuminate\\Support\\Facades\\DB','Illuminate\\Support\\Str']:
 if 'use '+namespace+';' not in auth:
  auth=auth.replace('namespace App\\Http\\Controllers;','namespace App\\Http\\Controllers;\nuse '+namespace+';')
targets[authpath]=auth.encode()
# Preserve all unrelated live API routes.
routepath=remote+'/routes/api.php';routes=read(routepath).decode()
additions=[]
for line in (root/'backend/routes/api.php').read_text().splitlines():
 if any(marker in line for marker in ["'/auth/delete-account'","'/moderation/reports", "'/messages/block/"]):
  if line.strip() not in routes:additions.append(line)
if "'/support/reports'" not in routes:
 additions.append("    Route::post('/support/reports', [\\App\\Http\\Controllers\\SupportReportController::class, 'store'])->middleware('throttle:5,1');")
if additions:
 anchor="Route::middleware('auth:sanctum')->group(function () {"
 if anchor not in routes:raise RuntimeError('Authenticated route group not found')
 routes=routes.replace(anchor,anchor+'\n'+'\n'.join(additions),1)
targets[routepath]=routes.encode()
webpath=remote+'/routes/web.php';web=read(webpath).decode()
if "'/moderation'" not in web:web+="\nRoute::get('/moderation', fn () => view('moderation'));\n"
targets[webpath]=web.encode()
adminpath=remote+'/resources/views/admin.blade.php';admin=read(adminpath).decode()
if 'href="/moderation"' not in admin:
 admin=admin.replace('</body>','<a href="/moderation" style="position:fixed;bottom:10px;right:14px;z-index:100;font:13px system-ui;background:white;padding:8px 12px;border:1px solid #dce2ed;border-radius:6px;color:#213e92">Safety reports</a>\n</body>')
targets[adminpath]=admin.encode()
for item in (root/'privacy-site/dist').iterdir():targets['/var/www/educonnect-privacy/'+item.name]=item.read_bytes()
original={path:read(path) for path in targets}
changed=[path for path in targets if targets[path]!=original[path]]
for path in changed:
 old=original[path]
 if old is not None:
  with sftp.open(backup+'/'+path.strip('/').replace('/','__'),'wb') as f:f.write(old)
 with sftp.open(path+'.release16-tmp','wb') as f:f.write(targets[path])
 sftp.chmod(path+'.release16-tmp',0o644)
 if path.endswith('.php') and not path.endswith('.blade.php'):run('php -l '+shlex.quote(path+'.release16-tmp'))
dbbackup="import sqlite3; a=sqlite3.connect('file:"+remote+"/database/database.sqlite?mode=ro',uri=True); b=sqlite3.connect('"+backup+"/database.sqlite'); a.backup(b); assert b.execute('pragma integrity_check').fetchone()[0]=='ok'; b.close(); a.close()"
run('python3 -c '+shlex.quote(dbbackup))
# Check live files have not changed since preflight.
for path in changed:
 if read(path)!=original[path]:raise RuntimeError('Concurrent edit: '+path)
for path in changed:
 if '/database/migrations/' in path:sftp.posix_rename(path+'.release16-tmp',path)
for migration in ['2026_10_26_000001_create_support_reports.php','2026_10_30_000001_add_message_safety_controls.php']:
 run('cd '+remote+' && php artisan migrate --force --path=database/migrations/'+migration)
for path in changed:
 if '/database/migrations/' not in path:sftp.posix_rename(path+'.release16-tmp',path)
run('cd '+remote+' && php artisan route:cache && php artisan view:cache && php artisan queue:restart')
run('systemctl reload php8.2-fpm && nginx -t')
for path in changed:
 assert hashlib.sha256(read(path)).digest()==hashlib.sha256(targets[path]).digest(),path
run('cd '+remote+' && php artisan route:list --path=moderation --no-ansi && php artisan route:list --path=auth/delete-account --no-ansi && php artisan route:list --path=messages/block --no-ansi')
for path in ['/api/health','/privacy-policy','/terms','/account-deletion','/moderation']:
 run('curl --fail --silent --show-error -o /dev/null -w "%{http_code}\\n" '+shlex.quote('https://admin.chewetechnologies.co.zw'+path))
for path in ['/api/auth/delete-account','/api/support/reports','/api/messages/block/1']:
 result=run('curl --silent -o /dev/null -w "%{http_code}" -X POST -H "Accept: application/json" '+shlex.quote('https://admin.chewetechnologies.co.zw'+path))
 assert result=='401',path+' must require authentication'
print('RELEASE16 DEPLOYED. Backup: '+backup,flush=True)
sftp.close();ssh.close()
