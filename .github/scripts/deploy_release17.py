"""Deploy wellbeing retirement with backups; retain all existing database records."""
import getpass, shlex
from datetime import datetime, timezone
from pathlib import Path
import paramiko

root = Path(__file__).resolve().parents[2]
remote = '/var/www/guardianship/backend'
ssh = paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password = getpass.getpass('SSH password: ')
try:
    ssh.connect('109.199.99.156', username='root', password=password, timeout=30, look_for_keys=False, allow_agent=False)
finally:
    del password
sftp = ssh.open_sftp()
def run(command):
    _, out, err = ssh.exec_command(command, timeout=120)
    result, error = out.read().decode(), err.read().decode()
    if out.channel.recv_exit_status():
        raise RuntimeError(error or result)
    print(result.strip(), flush=True)
def read(path):
    with sftp.open(path, 'rb') as f:
        return f.read()
backup = '/var/backups/guardianship/' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-release17'
run('mkdir -p ' + backup + ' && chmod 700 ' + backup)
targets = {}
for name in ['app/Http/Controllers/JournalController.php', 'app/Models/JournalEntry.php', 'app/Services/MobileUpdates.php', 'resources/views/legal.blade.php']:
    targets[remote + '/' + name] = (root / 'backend' / name).read_bytes()
# Patch only the retired admin UI, retaining unrelated live portal changes.
adminpath = remote + '/resources/views/admin.blade.php'
s = read(adminpath).decode()
if 'id="journalWellbeingGroup"' in s:
    a = s.index('                                <div id="journalWellbeingGroup"')
    b = s.index('                                <button type="submit"', a)
    s = s[:a] + s[b:]
    a = s.index('            const wellbeingGrp')
    b = s.index('\n        async function loadJournalFeed', a)
    s = s[:a] + "            const mediaGrp = document.getElementById('journalMediaGroup');\n            if (mediaGrp) mediaGrp.style.display = 'block';\n        }\n" + s[b:]
    a = s.index("                    let wellbeingHtml = '';")
    b = s.index('                    return `', a)
    s = s[:a] + s[b:]
    a = s.index("            if (type === 'wellbeing') {")
    b = s.index("            const res = await apiFetch('/api/journal'", a)
    s = s[:a] + "            if (fileInput && fileInput.files[0]) {\n                formData.append('image', fileInput.files[0]);\n            } else if (mediaUrlInput && mediaUrlInput.value.trim()) {\n                formData.append('media_url', mediaUrlInput.value.trim());\n            }\n\n" + s[b:]
    s = '\n'.join(l for l in s.split('\n') if 'value="wellbeing"' not in l and 'wellbeing: { bg:' not in l and '${wellbeingHtml}' not in l)
    s = s.replace('Learning Journal & Daily Wellbeing Feed', 'Learning Journal Feed').replace('Post Work Sample / Wellbeing Log', 'Post Work Sample').replace('work samples or wellbeing updates', 'work samples').replace(' & PREPARATORY WELLBEING LOGS', '').replace(' & WELLBEING', '')
targets[adminpath] = s.encode()
for p in (root / 'privacy-site/dist').iterdir():
    if p.is_file(): targets['/var/www/educonnect-privacy/' + p.name] = p.read_bytes()
originals = {p: read(p) for p in targets}
for p, data in targets.items():
    with sftp.open(backup + '/' + p.strip('/').replace('/', '__'), 'wb') as f: f.write(originals[p])
    with sftp.open(p + '.release17-tmp', 'wb') as f: f.write(data)
    sftp.chmod(p + '.release17-tmp', 0o644)
    if p.endswith('.php') and not p.endswith('.blade.php'): run('php -l ' + shlex.quote(p + '.release17-tmp'))
for p in targets:
    if read(p) != originals[p]: raise RuntimeError('Concurrent modification: ' + p)
for p in targets: sftp.posix_rename(p + '.release17-tmp', p)
run('cd ' + remote + ' && php artisan view:cache && php artisan queue:restart')
run('systemctl reload php8.2-fpm && nginx -t')
print('BACKUP=' + backup)
ssh.close()
