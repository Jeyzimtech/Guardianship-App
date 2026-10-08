import os
import sys
import posixpath
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

def deploy(password):
    local_backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "backend"))
    if not os.path.exists(local_backend_dir):
        print(f"Error: Backend directory not found at {local_backend_dir}")
        sys.exit(1)

    print(f"--> Connecting to {SERVER_USER}@{SERVER_HOST}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(SERVER_HOST, username=SERVER_USER, password=password, timeout=15)
    except Exception as e:
        print(f"Authentication / Connection failed: {e}")
        sys.exit(1)

    print("--> Connection successful!")
    sftp = ssh.open_sftp()

    print(f"--> Uploading backend files to {REMOTE_PATH}...")
    count = 0
    for root, dirs, files in os.walk(local_backend_dir):
        rel_dir = os.path.relpath(root, local_backend_dir)
        if rel_dir == ".":
            rel_dir = ""
        
        # Prune excluded dirs
        dirs[:] = [d for d in dirs if not should_exclude(os.path.join(rel_dir, d))]

        remote_target_dir = posixpath.join(REMOTE_PATH, rel_dir.replace("\\", "/"))
        sftp_mkdirs(sftp, remote_target_dir)

        for f in files:
            rel_file = os.path.join(rel_dir, f).replace("\\", "/")
            if should_exclude(rel_file):
                continue
            
            local_file = os.path.join(root, f)
            remote_file = posixpath.join(remote_target_dir, f)
            sftp.put(local_file, remote_file)
            count += 1
            if count % 20 == 0:
                print(f"    Uploaded {count} files...", flush=True)

    print(f"--> Upload complete! Total files uploaded: {count}")
    sftp.close()

    print("--> Running post-deployment commands on server...")
    remote_script = f"""
    set -e
    cd {REMOTE_PATH}
    chown -R www-data:www-data storage bootstrap/cache
    chmod -R 775 storage bootstrap/cache
    composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
    php artisan config:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan migrate --force
    php artisan db:seed --force
    php artisan queue:restart
    chown -R www-data:www-data storage bootstrap/cache
    """
    stdin, stdout, stderr = ssh.exec_command(f"bash -c '{remote_script}'")
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    
    if out:
        print(out)
    if err:
        print("STDERR:\n", err)

    exit_code = stdout.channel.recv_exit_status()
    ssh.close()

    if exit_code == 0:
        print("\nDeployment finished successfully!")
    else:
        print(f"\nDeployment commands exited with status {exit_code}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        pwd = sys.argv[1]
    else:
        pwd = input("Enter server root password: ").strip()
    deploy(pwd)
