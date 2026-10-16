# Edu+Conect — Backend API & Web Admin Portal

This directory contains the Laravel 11 backend service powering the Edu+Conect Guardianship Platform.

## Core Features
- **Server-hosted Sanctum Authentication**: Role-based access tokens for Admins, Teachers, and Guardians.
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
All 65 feature and unit tests should pass.


## Uniform payments (PesePay)

Keep PESEPAY_INTEGRATION_KEY and PESEPAY_ENCRYPTION_KEY in the server environment only. PESEPAY_SANDBOX=true selects the sandbox; the current checkout supports USD. Refresh configuration with php artisan config:cache after changing credentials.

- POST /api/uniform-orders/{id}/checkout returns the hosted payment URL for an authorized guardian or own-school administrator. Repeat checkout reuses the pending transaction.
- GET /api/uniform-orders/{id}/payment-status verifies the reference, amount, currency and status directly with PesePay. Only SUCCESS credits the order.
- POST /api/payments/pesepay/result receives authenticated callbacks and queues verification. The browser return URL never credits an order.
- The payments queue worker must run with --queue=payments; the payments:reconcile-uniforms command checks missed callbacks. Production has a dedicated systemd queue service and five-minute reconciliation timer, installed by .github/scripts/install_payment_workers.sh.
- php artisan uniforms:seed-payment-test SCHOOL_ID explicitly creates two school-scoped test catalog items; normal database seeding remains free of demo uniforms.

Rebuild the APK, select a child, open Uniform store, add a test uniform, place the order and follow Pay with PesePay. Return to Orders and tap Check payment status. The sandbox success EcoCash number is 0777777777; the failure number is 0770000000. No real money moves in sandbox. Use the official test credentials only on the sandbox payment page: https://developers.pesepay.com/testing/test-credentials/ .

Protocol references: https://developers.pesepay.com/security/encryption/ and https://developers.pesepay.com/webhooks/result-callback/ .
