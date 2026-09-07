# Edu+Conect — School Guardianship & Educational Management System

A multi-platform educational guardianship ecosystem connecting schools, teachers, and parents. The system features a responsive Flutter mobile client for guardians and educators, a modern corporate-themed Web Administration Portal, and a robust Laravel REST API backend.

---

## System Architecture

```
Guardianship App/
├── mobile/                  # Flutter Client (Android, iOS & Desktop)
│   ├── lib/
│   │   ├── core/            # API clients, authentication, colors & state providers
│   │   └── features/        # Dashboards, attendance, gradebook, reports, SMS logs
│   └── test/                # Flutter unit and widget smoke tests
│
└── backend/                 # Laravel REST API & Web Admin
    ├── app/
    │   ├── Http/Controllers# REST API Controllers (Schools, Users, Reports, Fees)
    │   └── Models/          # Eloquent Models & relationships
    ├── database/migrations/ # Relational database schema definitions
    ├── resources/views/     # Blade templates (Admin Portal, Landing Page)
    ├── routes/api.php       # Sanctum & API endpoints
    └── tests/               # PHPUnit feature & unit tests
```

---

## Key Modules & Capabilities

1. **Daily Roll Call Register**: Real-time present/absent/late attendance recording for homeroom classes with statistics calculation.
2. **Academic Gradebook & Assessment Marks**: Track continuous assessment scores and compute overall term averages with validation.
3. **Fee Gating & Dual-Currency Billing**: Supports USD and Zimbabwe Gold (ZiG) billing with automated fee gating for term report card downloads.
4. **Learning Journal**: Multimedia feed documenting classroom activities, social-emotional check-ins, and learner milestones.
5. **Guardian SMS Alerts Log**: Complete audit trail for delivered SMS notifications (Africa's Talking, Econet, Telecel) ensuring coverage in low-connectivity areas.
6. **School & User Administration**: Provision schools, academic terms, grade streams, teachers, and guardian accounts with secure role-based access control.

---

## Getting Started

### Backend Setup (Laravel)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

Run test suite:
```bash
php artisan test
```

### Mobile App Setup (Flutter)

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

---

## API Endpoints Overview

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/firebase-login` | Authenticate user via Firebase UID |
| `GET` | `/api/dashboard/{student_id}` | Fetch student KPIs, fee balance, and attendance |
| `GET` | `/api/reports/{student_id}` | Retrieve student academic report documents |
| `POST` | `/api/attendance/mark` | Mark student roll call attendance |
| `POST` | `/api/assignments` | Create homework or assessment task |
| `GET` | `/api/assignments/{student_id}` | List upcoming and overdue assignments |
| `GET` | `/api/users` | List system users (Admin only) |
| `GET` | `/api/teachers` | List teacher profiles and class assignments |
| `GET` | `/api/schools` | List registered school institutions |
| `GET` | `/api/school-classes` | List grade classes and streams |

---

## Quality & Code Hygiene Standards
- **Flutter Analyzer**: Strict linting compliance (`flutter_lints`), zero compilation warnings.
- **PHPUnit**: 22 passing automated feature and unit tests covering fee gating, user management, and security boundaries.
