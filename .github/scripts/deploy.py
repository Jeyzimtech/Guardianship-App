import os
import sys
import posixpath
import getpass
import socket
import paramiko

SERVER_HOST = "109.199.99.156"
SERVER_USER = "root"
REMOTE_PATH = "/var/www/guardianship/backend"

EXCLUDE_DIRS = {
    ".git",
    "vendor",
    "node_modules",
    ".github",
    ".idea",
    ".vscode",
    "storage",
    "tests",
    "backups",
    "__pycache__",
}

EXCLUDE_FILES = {
    ".env",
    "database.sqlite",
    ".phpunit.result.cache",
}

def should_exclude(rel_path):
    parts = rel_path.replace("\\", "/").strip("/").split("/")
    for p in parts:
        if p in EXCLUDE_DIRS:
            return True
        if p in EXCLUDE_FILES:
            return True
        if p.startswith('.env') or p.endswith(('.sqlite', '.sqlite-wal', '.sqlite-shm', '.log', '.sql', '.bak')):
            return True
    if rel_path.replace('\\', '/').startswith('bootstrap/cache/'):
        return True
    if rel_path.startswith("storage/logs/"):
        return True
    if rel_path.startswith("storage/framework/cache/"):
        return True
    if rel_path.startswith("storage/framework/sessions/"):
        return True
    if rel_path.startswith("storage/framework/views/"):
        return True
    return False

def sftp_mkdirs(sftp, remote_dir):
    dirs = []
    current = remote_dir
    while len(current) > 1:
        dirs.append(current)
        current = posixpath.dirname(current)
    dirs.reverse()
    for d in dirs:
        try:
            sftp.stat(d)
        except IOError:
            try:
                sftp.mkdir(d)
            except Exception:
                pass

def deploy_connected(ssh):
    """Deploy only backend source, preserving production environment and uploads."""
    from datetime import datetime, timezone
    import shlex
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    backup = '/var/backups/guardianship/' + stamp
    def remote(script):
        stdin, stdout, stderr = ssh.exec_command('bash -se', timeout=900)
        stdin.write(script)
        stdin.flush()
        stdin.channel.shutdown_write()
        output = stdout.read().decode(errors='replace')
        errors = stderr.read().decode(errors='replace')
        if output:
            print(output, flush=True)
        if errors:
            print(errors, flush=True)
        status = stdout.channel.recv_exit_status()
        if status:
            raise RuntimeError('Deployment stopped: remote exit status ' + str(status))
    remote(f'''umask 077
mkdir -p {backup}
cd {REMOTE_PATH}
php artisan down --retry=60
tar --exclude=./vendor --exclude=./node_modules --exclude=./storage/logs --exclude=./storage/framework -czf {backup}/backend.tar.gz .
python3 -c "import sqlite3; s=sqlite3.connect('file:{REMOTE_PATH}/database/database.sqlite?mode=ro',uri=True); d=sqlite3.connect('{backup}/database.sqlite'); s.backup(d); print('Database backup integrity:',d.execute('pragma integrity_check').fetchone()[0]); d.close(); s.close()"
echo 'Backup saved: {backup}'
''')
    local = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'backend'))
    sftp = ssh.open_sftp()
    count = 0
    try:
        for root, dirs, files in os.walk(local):
            rel = os.path.relpath(root, local)
            rel = '' if rel == '.' else rel.replace('\\', '/')
            dirs[:] = [d for d in dirs if not should_exclude(posixpath.join(rel, d)) and not os.path.islink(os.path.join(root,d))]
            target = posixpath.join(REMOTE_PATH, rel)
            sftp_mkdirs(sftp, target)
            for name in files:
                if should_exclude(posixpath.join(rel, name)):
                    continue
                destination = posixpath.join(target, name)
                sftp.put(os.path.join(root, name), destination + '.deploy-tmp')
                sftp.posix_rename(destination + '.deploy-tmp', destination)
                count += 1
                if count % 100 == 0:
                    print(f'Uploaded {count} backend files', flush=True)
    finally:
        sftp.close()
    print(f'Upload complete: {count} backend files', flush=True)
    remote(f'''cd {REMOTE_PATH}
if [ -f app/Services/FirebaseAuthService.php ]; then rm -- app/Services/FirebaseAuthService.php; fi
if [ -f app/Http/Controllers/RoadrunnerController.php ]; then rm -- app/Http/Controllers/RoadrunnerController.php; fi
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
php artisan config:clear
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan queue:restart
chown -R www-data:www-data storage bootstrap/cache database
chmod -R ug+rwX storage bootstrap/cache database
php artisan up
nginx -t
curl --fail --silent --show-error https://admin.chewetechnologies.co.zw/api/health
''')
    print('DEPLOYMENT VERIFIED. Backup: ' + backup, flush=True)

def deploy(password):
    local_backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backend"))
    if not os.path.exists(local_backend_dir):
        print(f"Error: Backend directory not found at {local_backend_dir}")
        sys.exit(1)

    try:
        socket.getaddrinfo(SERVER_HOST, 22)
    except OSError as e:
        print(f"Cannot resolve the deployment host in current network environment: {e}")
        sys.exit(1)

    print(f"--> Connecting to {SERVER_USER}@{SERVER_HOST}...")
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
    print("SSH host verification uses your system known_hosts. Add the server's independently verified host key before deploying.")
    try:
        ssh.connect(SERVER_HOST, username=SERVER_USER, password=password, timeout=30)
    except Exception as e:
        print(f"Authentication / Connection failed: {e}")
        sys.exit(1)

    try:
        deploy_connected(ssh)
    finally:
        ssh.close()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print("Do not pass VPS passwords as command-line arguments. Rotate any password already exposed in chat or process history.")
        sys.exit(2)
    else:
        pwd = getpass.getpass("Enter rotated server SSH password: ").strip()
    deploy(pwd)
