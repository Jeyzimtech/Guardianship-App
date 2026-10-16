#!/usr/bin/env bash
set -euo pipefail
cat > /etc/systemd/system/guardianship-payment-queue.service <<'EOF'
[Unit]
Description=Guardianship payment verification queue
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/guardianship/backend
ExecStart=/usr/bin/php artisan queue:work --queue=payments --sleep=3 --tries=3 --timeout=60
Restart=always
RestartSec=5
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/guardianship-payment-reconcile.service <<'EOF'
[Unit]
Description=Reconcile pending Guardianship uniform payments
After=network.target
[Service]
Type=oneshot
User=www-data
Group=www-data
WorkingDirectory=/var/www/guardianship/backend
ExecStart=/usr/bin/php artisan payments:reconcile-uniforms
NoNewPrivileges=true
EOF
cat > /etc/systemd/system/guardianship-payment-reconcile.timer <<'EOF'
[Unit]
Description=Check pending uniform payments every five minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true
[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now guardianship-payment-queue.service guardianship-payment-reconcile.timer
systemctl restart guardianship-payment-queue.service
systemctl is-active guardianship-payment-queue.service guardianship-payment-reconcile.timer
