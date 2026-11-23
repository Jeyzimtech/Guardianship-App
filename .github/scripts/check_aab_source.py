"""Read-only check of server-side Android build sources and tools."""
import getpass
from pathlib import Path
import paramiko

root=Path(__file__).resolve().parents[2]
ssh=paramiko.SSHClient()
ssh.load_system_host_keys()
known=root/'.github/scripts/.server_known_hosts'
if known.exists(): ssh.load_host_keys(str(known))
ssh.set_missing_host_key_policy(paramiko.RejectPolicy())
password=getpass.getpass('SSH password: ')
try:
    ssh.connect('109.199.99.156',username='root',password=password,timeout=30,look_for_keys=False,allow_agent=False)
finally:
    del password
command="""printf 'SOURCE FILES\\n'; find /var/www/guardianship /opt /srv -maxdepth 5 -type f \\( -name pubspec.yaml -o -name '*.aab' -o -name flutter \\) 2>/dev/null; printf 'BUILD TOOLS\\n'; command -v flutter || true; command -v java || true; printf 'PROJECT DIRECTORIES\\n'; ls -la /var/www/guardianship; printf 'API HEALTH\\n'; curl --fail --silent --show-error --max-time 20 https://admin.chewetechnologies.co.zw/api/health"""
_,out,err=ssh.exec_command(command,timeout=60)
print(out.read().decode()); print(err.read().decode())
ssh.close()
