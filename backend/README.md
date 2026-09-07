# Edu+Conect — Backend API & Web Admin Portal

This directory contains the Laravel 11 backend service powering the Edu+Conect Guardianship Platform.

## Core Features
- **Sanctum & Firebase Authentication**: Role-based access tokens for Admins, Teachers, and Guardians.
- **RESTful Endpoints**: Full API surface for school, user, student, and classroom administration.
- **Fee Gating Enforcement**: Built-in middleware and controller-level fee balance verification.
- **Blade Web Admin**: Integrated Web Administration console available at `/admin`.

## Running Locally
```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

## Running Automated Tests
```bash
php artisan test
```
All 22 feature & unit tests should pass.
