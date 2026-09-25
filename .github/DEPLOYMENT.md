# Guardianship App — CI/CD Guide

This project uses **GitHub Actions** for continuous integration and deployment.

---

## Workflow Overview

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | Every push / PR to `master` or `production` | Flutter analyze + tests, Laravel lint + migrations + tests |
| `cd.yml` | Push to `production` branch only | Deploys Laravel backend to production server via SSH |
| `build-apk.yml` | Every push to `master` or `production` | Builds a Flutter debug APK and uploads it as an artifact |

---

## Branch Strategy

```
master      → development / integration branch (CI runs)
production  → triggers both CI and CD (deploys to server)
```

**To deploy to production:**
```bash
git checkout production
git merge master
git push origin production
```

---

## Required GitHub Secrets

Go to: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|---|---|
| `DEPLOY_HOST` | `109.199.99.156` |
| `DEPLOY_USER` | `root` |
| `DEPLOY_PASSWORD` | *(your server root password)* |
| `DEPLOY_SSH_KEY` | *(private SSH key — see below)* |

### Generating an SSH Key for Deployment

Run this on your **local machine**:
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f deploy_key -N ""
```

This creates two files:
- `deploy_key` — private key → paste this into `DEPLOY_SSH_KEY` secret
- `deploy_key.pub` — public key → add to server with:

```bash
ssh root@109.199.99.156 "mkdir -p ~/.ssh && echo '$(cat deploy_key.pub)' >> ~/.ssh/authorized_keys"
```

---

## First-Time Server Setup

SSH into the server and run the setup script once:
```bash
ssh root@109.199.99.156
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Jeyzimtech/Guardianship-App/master/.github/scripts/server-setup.sh)"
```

Or copy and run the script manually from `.github/scripts/server-setup.sh`.

After first deploy, generate the app key on the server:
```bash
ssh root@109.199.99.156 "cd /var/www/guardianship/backend && php artisan key:generate"
```

---

## APK Artifacts

After every push to `master` or `production`, the Flutter debug APK is built and available to download from:

**GitHub repo → Actions → Build — Flutter Debug APK → (select run) → Artifacts**

The APK is retained for **14 days**.

---

## Viewing CI/CD Status

Check the status at: `https://github.com/Jeyzimtech/Guardianship-App/actions`
