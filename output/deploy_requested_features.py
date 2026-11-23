"""Interactive deployment: password stays in memory; preflight waits for local review."""
import getpass, hashlib, json, shlex, sys, time
from datetime import datetime, timezone
from pathlib import Path
import paramiko
ROOT=Path(__file__).resolve().parents[1]
RELEASE=ROOT/'output/feature-release-2026-11-20'
STATE=ROOT/'output/server-release-status.json'
CONTROL=ROOT/'output/server-release-control.json'
SNAPSHOT=ROOT/'output/server-preflight-2026-11-20'
REMOTE='/var/www/guardianship/backend'
def state(status,**values):
    STATE.write_text(json.dumps({'status':status,**values},indent=2),encoding='utf-8')
    print(status,flush=True)
def main():
    manifest=json.loads((RELEASE/'manifest.json').read_text(encoding='utf-8'))['files']
    for name,digest in manifest.items():
        if hashlib.sha256((RELEASE/'backend'/name).read_bytes()).hexdigest()!=digest: raise RuntimeError('Release checksum changed: '+name)
    ssh=paramiko.SSHClient();ssh.load_system_host_keys()
    known=ROOT/'.github/scripts/.server_known_hosts'
    if known.exists():ssh.load_host_keys(str(known))
    ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
    state('waiting_for_secure_login')
    password=getpass.getpass('Enter the existing server SSH password (not saved): ')
    try:ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
    finally:del password
    def run(command):
        _,out,err=ssh.exec_command(command,timeout=300)
        result,error=out.read().decode(),err.read().decode()
        if out.channel.recv_exit_status():raise RuntimeError(error or result)
        return result.strip()
    sftp=ssh.open_sftp();originals={};SNAPSHOT.mkdir(parents=True,exist_ok=True)
    for name in manifest:
        try:
            with sftp.open(REMOTE+'/'+name,'rb') as f:data=f.read()
        except FileNotFoundError:data=None
        originals[name]=data
        if data is not None:
            target=SNAPSHOT/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    php="require 'vendor/autoload.php'; $app=require 'bootstrap/app.php'; $app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap(); echo json_encode(['driver'=>config('database.default'),'database'=>config('database.connections.'.config('database.default').'.database')]);"
    info=json.loads(run('cd '+REMOTE+' && php -r '+shlex.quote(php)))
    changed=[n for n,d in originals.items() if d is None or hashlib.sha256(d).hexdigest()!=manifest[n]]
    state('preflight_ready',database=info,changed=changed)
    print('Source snapshot downloaded. Waiting for the local review to finish.',flush=True)
    for _ in range(3600):
        if CONTROL.exists():
            action=json.loads(CONTROL.read_text(encoding='utf-8'))
            if action.get('action')=='cancel':state('cancelled');ssh.close();return
            if action.get('action')=='deploy':break
        time.sleep(1)
    else:raise RuntimeError('Review timed out; no server changes made.')
    if info['driver']!='sqlite':raise RuntimeError('Deployment paused: database backup requires a reviewed configuration for this driver.')
    for name,original in originals.items():
        try:
            with sftp.open(REMOTE+'/'+name,'rb') as f:current=f.read()
        except FileNotFoundError:current=None
        if current!=original:raise RuntimeError('Live source changed during review: '+name)
    backup='/var/backups/guardianship/'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-requested-features'
    run('mkdir -p '+backup+' && chmod 700 '+backup)
    existing=[n for n,d in originals.items() if d is not None]
    run('cd '+REMOTE+' && tar -czf '+backup+'/source.tar.gz '+' '.join(shlex.quote(n) for n in existing))
    dbpath=info['database'];dbpath=dbpath if dbpath.startswith('/') else REMOTE+'/'+dbpath
    code="import sqlite3; s=sqlite3.connect("+repr('file:'+dbpath+'?mode=ro')+",uri=True); t=sqlite3.connect("+repr(backup+'/database.sqlite')+"); s.backup(t); assert t.execute('pragma integrity_check').fetchone()[0]=='ok'; t.close(); s.close()"
    run('python3 -c '+shlex.quote(code))
    state('backed_up',backup=backup)
    for name in manifest:
        target=REMOTE+'/'+name
        run('mkdir -p '+shlex.quote(target.rsplit('/',1)[0]))
        sftp.put(str(RELEASE/'backend'/name),target+'.requested-features-tmp')
        sftp.chmod(target+'.requested-features-tmp',0o644)
        run('php -l '+shlex.quote(target+'.requested-features-tmp'))
    for name in manifest:sftp.posix_rename(REMOTE+'/'+name+'.requested-features-tmp',REMOTE+'/'+name)
    state('source_installed',backup=backup)
    migration='database/migrations/2026_11_20_000001_add_payment_proof_and_retention_index.php'
    run('cd '+REMOTE+' && php artisan migrate --path='+migration+' --force && php artisan optimize:clear && php artisan view:cache && php artisan queue:restart')
    # Use the existing Laravel scheduler when present, otherwise install the narrow timer.
    scheduling=run("(crontab -l 2>/dev/null; crontab -u www-data -l 2>/dev/null; cat /etc/crontab /etc/cron.d/* 2>/dev/null; systemctl list-timers --all --no-pager) | grep -E 'artisan.*schedule:run|educonnect-message-retention|guardianship.*schedule' || true")
    if not scheduling:
        for name in ['educonnect-message-retention.service','educonnect-message-retention.timer']:
            sftp.put(str(RELEASE/name),'/etc/systemd/system/'+name);sftp.chmod('/etc/systemd/system/'+name,0o644)
        run('systemctl daemon-reload && systemctl enable --now educonnect-message-retention.timer')
    run('systemctl reload php8.2-fpm && nginx -t')
    health=run('curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health')
    run('cd '+REMOTE+' && php artisan schedule:list --no-ansi')
    state('deployed',backup=backup,health=json.loads(health))
    print('Release deployed. No school-removal request was performed.',flush=True)
    ssh.close()
if __name__=='__main__':
    try:main()
    except Exception as error:
        state('failed',error=str(error));print('Deployment stopped. See server-release-status.json for the safe error.',flush=True);sys.exit(1)
