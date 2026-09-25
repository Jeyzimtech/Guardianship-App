# Guardianship App — Backend CI/CD Guide

This project uses **GitHub Actions** to automate continuous integration and continuous deployment for the **Laravel backend**.

---

## Workflow Overview

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | Push & PR to `master` or `production` affecting `backend/**` | Runs composer install, SQLite migrations, and PHPUnit test suite |
| `cd.yml` | Push to `production` affecting `backend/**` or manual dispatch | Deploys backend via rsync over SSH to server, caches routes/config, and runs database migrations |

---

## Branch Strategy

```
master      → development / staging branch (Backend CI runs)
production  → deployment branch (Backend CI runs, then deploys to 109.199.99.156)
```

**To deploy latest changes to production:**
```bash
git checkout production
git merge master
git push origin production
```

Or trigger manually anytime from **GitHub → Actions → Deploy Backend to Production → Run workflow**.

---

## Configured GitHub Secrets

All secrets are pre-configured in GitHub Repository Settings:

| Secret Name | Purpose |
|---|---|
| `DEPLOY_HOST` | Production server IP (`109.199.99.156`) |
| `DEPLOY_USER` | Server user (`root`) |
| `DEPLOY_PASSWORD` | Server root password (fallback) |
| `DEPLOY_SSH_KEY` | Dedicated Ed25519 private key for automated passwordless deployment |

---

## Production Server Paths

- Application root: `/var/www/guardianship/backend`
- Nginx root: `/var/www/guardianship/backend/public`
- Environment config: `/var/www/guardianship/backend/.env`
- SQLite Database: `/var/www/guardianship/backend/database/database.sqlite`
