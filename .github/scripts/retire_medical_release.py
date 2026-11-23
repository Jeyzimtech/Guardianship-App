"""Disable retired endpoints and publish matching disclosures; preserve all data."""
from pathlib import Path
from datetime import datetime, timezone
import getpass
import shlex
import paramiko

root=Path(__file__).resolve().parents[2]
ssh=paramiko.SSHClient(); ssh.load_system_host_keys()
known=root/'.github/scripts/.server_known_hosts'
if known.exists(): ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password=getpass.getpass('SSH password: ')
try: ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
finally: del password
def run(command):
    _,out,err=ssh.exec_command(command,timeout=90)
    output=out.read().decode();error=err.read().decode()
    if out.channel.recv_exit_status(): raise RuntimeError(error or output)
    print(output.strip(),flush=True)
    return output

sftp=ssh.open_sftp()
backend='/var/www/guardianship/backend'
stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
backup='/var/backups/guardianship/'+stamp+'-retire-medical'
run('mkdir -p '+backup+' && chmod 700 '+backup)
def replace(path,transform):
    try:
        with sftp.open(path,'rb') as f: old=f.read()
    except FileNotFoundError:
        if path.endswith('/resources/views/legal.blade.php') or path.endswith('/app/Http/Controllers/LegalPageController.php'):
            old=b''
        else: raise
    updated=transform(old.decode('utf-8')).encode('utf-8')
    if updated==old: print('Already current: '+path);return
    with sftp.open(backup+'/'+path.strip('/').replace('/','__'),'wb') as f: f.write(old)
    with sftp.open(path+'.release-tmp','wb') as f: f.write(updated)
    sftp.chmod(path+'.release-tmp',0o644)
    if path.endswith('.php') and not path.endswith('.blade.php'): run('php -l '+shlex.quote(path+'.release-tmp'))
    sftp.posix_rename(path+'.release-tmp',path)

replace(backend+'/routes/api.php',lambda text:'\n'.join(line for line in text.split('\n') if 'StudentMedicalController::class' not in line))
def policy(text):
    text=text.replace('Learner photo and medical details','Learner photo').replace(" that a parent chooses to add (allergies, conditions, medication and care instructions). Medical details are encrypted when stored and are shown only to the linked parent and the learner's assigned teachers.",' that a parent chooses to add.').replace(' Medical details are encrypted at rest.','')
    paragraph='<p>Information provided under earlier versions may remain in existing records. Contact support to request access or deletion; removing a feature does not automatically delete existing records.</p>'
    if paragraph not in text: text=text.replace('<h2>Your choices and rights</h2>',paragraph+'\n\n<h2>Your choices and rights</h2>')
    return text
replace(backend+'/resources/views/legal.blade.php',lambda t:policy(t) if t else (root/'backend/resources/views/legal.blade.php').read_text(encoding='utf-8'))
replace(backend+'/app/Http/Controllers/LegalPageController.php',lambda t:t.replace('26 October 2026','29 October 2026') if t else (root/'backend/app/Http/Controllers/LegalPageController.php').read_text(encoding='utf-8'))
def legal_routes(text):
    for slug,page in [('privacy-policy','privacy'),('terms','terms'),('account-deletion','deletion')]:
        if "'/"+slug+"'" not in text:
            text+="\nRoute::get('/"+slug+"', [\\App\\Http\\Controllers\\LegalPageController::class, 'show'])->defaults('page', '"+page+"');\n"
    return text
replace(backend+'/routes/web.php',legal_routes)
for file in (root/'privacy-site/dist').iterdir():
    destination='/var/www/educonnect-privacy/'+file.name
    replace(destination,lambda _,file=file:file.read_text(encoding='utf-8'))
run('cd '+backend+' && php artisan route:cache && php artisan view:cache')
run('systemctl reload php8.2-fpm')
for host in ['https://admin.chewetechnologies.co.zw','https://codedevs.chewetechnologies.co.zw']:
    run("curl --fail --silent --show-error "+host+"/privacy-policy | python3 -c 'import sys; text=sys.stdin.read(); assert \"medical\" not in text.lower(); assert \"Learner photo\" in text; print(\"Privacy policy verified\")'")
run('cd '+backend+' && php artisan route:list --path=medical --no-ansi')
run('curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
print('Deployed. No database records changed. Backup: '+backup)
sftp.close();ssh.close()
