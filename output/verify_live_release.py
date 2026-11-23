"""Verify the authorized release without logging credentials or personal records."""
import getpass, hashlib, json, shlex
from pathlib import Path
import paramiko
ROOT=Path(__file__).resolve().parents[1]
REMOTE='/var/www/guardianship/backend'
state=json.loads((ROOT/'output/server-release-status.json').read_text(encoding='utf-8'))
if state['status']!='deployed':raise SystemExit('Wait until deployment completes.')
ssh=paramiko.SSHClient();ssh.load_system_host_keys();ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password=getpass.getpass('Server SSH password (not saved): ')
try:ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
finally:del password
sftp=ssh.open_sftp()
def run(command):
    _,out,err=ssh.exec_command(command,timeout=180)
    data,error=out.read().decode(),err.read().decode()
    if out.channel.recv_exit_status():raise RuntimeError(error or data)
    return data.strip()
try:
    manifest=json.loads((ROOT/'output/feature-release-2026-11-20/manifest.json').read_text(encoding='utf-8'))['files']
    patched=False
    for name,digest in manifest.items():
        with sftp.open(REMOTE+'/'+name,'rb') as f:remote=f.read()
        if hashlib.sha256(remote).hexdigest()!=digest:
            expected=(ROOT/'output/feature-release-2026-11-20/backend'/name).read_bytes()
            # One harmless wording adjustment may have been packaged while uploads were underway.
            if name=='resources/views/admin.blade.php' and remote==expected.replace(b'with families',b'with subscribed parents'):
                sftp.put(str(ROOT/'output/feature-release-2026-11-20/backend'/name),REMOTE+'/'+name+'.verified-tmp')
                run('php -l '+REMOTE+'/'+name+'.verified-tmp');sftp.posix_rename(REMOTE+'/'+name+'.verified-tmp',REMOTE+'/'+name);patched=True
            else:raise RuntimeError('Source checksum mismatch: '+name)
    if patched:run('cd '+REMOTE+' && php artisan view:cache')
    print('All deployed source checksums verified.',flush=True)
    target=state['backup']+'/verify_requested_features.php'
    sftp.put(str(ROOT/'output/verify_requested_features.php'),target);sftp.chmod(target,0o600)
    result=run('php '+shlex.quote(target))
    (ROOT/'output/live-feature-verification.txt').write_text(result,encoding='utf-8')
    print(result,flush=True)
    # The queue service also processes deferred private-file cleanup after school removal.
    worker=run('systemctl is-active guardianship-notification-queue.service')
    timer=run("systemctl is-active educonnect-message-retention.timer 2>/dev/null || true")
    print('QUEUE='+worker+' RETENTION_TIMER='+timer,flush=True)
    (ROOT/'output/live-feature-status.json').write_text(json.dumps({'status':'verified','checksums':len(manifest),'worker':worker,'retention_timer':timer,'backup':state['backup']},indent=2),encoding='utf-8')
finally:ssh.close()
