#!/usr/bin/env bash
set -euo pipefail
cat > /etc/systemd/system/guardianship-notification-queue.service <<'EOF'
[Unit]
Description=Guardianship mobile notification queue
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/guardianship/backend
ExecStart=/usr/bin/php artisan queue:work --queue=default --sleep=3 --tries=3 --timeout=60
Restart=always
RestartSec=5
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now guardianship-notification-queue.service
systemctl restart guardianship-notification-queue.service
systemctl is-active guardianship-notification-queue.service
