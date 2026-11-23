import getpass
import sys
from pathlib import Path
import shlex
import paramiko

password=getpass.getpass('Server password: ')
ssh=paramiko.SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect('109.199.99.156',username='root',password=password,timeout=25)
password=None
def run(command,timeout=60):
    _,out,err=ssh.exec_command(command,timeout=timeout)
    output=out.read().decode(); error=err.read().decode()
    status=out.channel.recv_exit_status()
    print(output,flush=True)
    if error: print(error,flush=True)
    if status: raise RuntimeError('Remote command failed')

if '--deploy' in sys.argv:
    target='/var/www/educonnect-privacy'
    config='/etc/nginx/sites-available/educonnect-privacy'
    run('test ! -e '+config+' && test ! -e '+target)
    run('mkdir -p '+target)
    sftp=ssh.open_sftp()
    for item in (Path(__file__).parent/'dist').iterdir():
        sftp.put(str(item),target+'/'+item.name)
        sftp.chmod(target+'/'+item.name,0o644)
    text='''server {
    listen 80;
    server_name codedevs.chewetechnologies.co.zw;
    root /var/www/educonnect-privacy;
    index index.html;
    charset utf-8;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header Content-Security-Policy "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'" always;
    location / { try_files $uri $uri.html $uri/ =404; }
}
'''
    with sftp.open(config,'w') as f: f.write(text)
    sftp.close()
    run('ln -s '+config+' /etc/nginx/sites-enabled/educonnect-privacy')
    try:
        run('nginx -t')
    except Exception:
        run('unlink /etc/nginx/sites-enabled/educonnect-privacy')
        raise
    run('systemctl reload nginx')
    run("curl --fail --silent -H 'Host: codedevs.chewetechnologies.co.zw' http://127.0.0.1/privacy-policy | head -c 220")
    run('certbot --nginx -d codedevs.chewetechnologies.co.zw --non-interactive --agree-tos --register-unsafely-without-email --redirect',180)
    for page in ['', 'privacy-policy','account-deletion','terms','styles.css']:
        run('curl --fail --silent --show-error -o /dev/null -w "%{http_code} %{url_effective}\\n" '+shlex.quote('https://codedevs.chewetechnologies.co.zw/'+page))
else:
    run("hostname; command -v nginx; command -v certbot; ls -la /etc/nginx/sites-enabled; getent ahostsv4 codedevs.chewetechnologies.co.zw")
ssh.close()
