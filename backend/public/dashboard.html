<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guardianship | PT Tech - School Management Portal</title>
    <!-- Google Fonts & Icons -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cabin:ital,wght@0,400..700;1,400..700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    <style>
        /* 14. Global Color Palette & Variables */
        :root {
            --primary-blue: #3B5998;
            --secondary-blue: #5B7BD5;
            --white: #FFFFFF;
            --sidebar-bg: #F5F6F7;
            --border-color: #D8D8D8;
            --success-color: #4CAF50;
            --warning-color: #F39C12;
            --danger-color: #E74C3C;
            --text-primary: #1F2937;
            --text-secondary: #6B7280;
            --body-bg: #F9FAFB;
        }

        /* 15. Typography & Resets */
        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Cabin', sans-serif;
            border-radius: 0 !important;
        }

        body {
            background-color: var(--body-bg);
            color: var(--text-primary);
            font-size: 14px;
            overflow-x: hidden;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        /* 3. Header Specification (Height: 60px, Facebook Blue #3B5998, Shadow Light) */
        header.app-header {
            height: 60px;
            background-color: var(--primary-blue);
            color: var(--white);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 20px;
            position: sticky;
            top: 0;
            z-index: 1000;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        .header-left {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .toggle-sidebar-btn {
            background: none;
            border: none;
            color: var(--white);
            font-size: 18px;
            cursor: pointer;
            display: none; /* Visible on mobile */
        }

        .company-logo {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 700;
            font-size: 18px;
            color: var(--white);
            text-decoration: none;
        }

        .company-logo i {
            font-size: 22px;
        }

        .header-search {
            position: relative;
            width: 320px;
        }

        .header-search input {
            width: 100%;
            height: 36px;
            padding: 0 12px 0 36px;
            border-radius: 4px;
            border: none;
            background-color: rgba(255, 255, 255, 0.15);
            color: var(--white);
            font-size: 14px;
            outline: none;
            transition: background-color 0.2s;
        }

        .header-search input::placeholder {
            color: rgba(255, 255, 255, 0.7);
        }

        .header-search input:focus {
            background-color: rgba(255, 255, 255, 0.25);
        }

        .header-search i {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: rgba(255, 255, 255, 0.8);
        }

        .header-right {
            display: flex;
            align-items: center;
            gap: 20px;
        }

        .header-icon-btn {
            position: relative;
            background: none;
            border: none;
            color: var(--white);
            font-size: 18px;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 36px;
            height: 36px;
            border-radius: 4px;
            transition: background-color 0.2s;
        }

        .header-icon-btn:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .badge-count {
            position: absolute;
            top: 2px;
            right: 2px;
            background-color: var(--danger-color);
            color: var(--white);
            font-size: 10px;
            font-weight: 700;
            padding: 2px 5px;
            border-radius: 10px;
            line-height: 1;
        }

        .school-selector select {
            background-color: rgba(255, 255, 255, 0.15);
            color: var(--white);
            border: none;
            padding: 8px 12px;
            border-radius: 4px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            outline: none;
        }

        .school-selector select option {
            background-color: var(--primary-blue);
            color: var(--white);
        }

        .user-profile {
            display: flex;
            align-items: center;
            gap: 10px;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 4px;
            transition: background-color 0.2s;
        }

        .user-profile:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }

        .user-avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background-color: var(--secondary-blue);
            color: var(--white);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
        }

        .user-name {
            font-size: 14px;
            font-weight: 600;
        }

        /* Layout Container */
        .app-layout {
            display: flex;
            flex: 1;
        }

        /* 4. Sidebar Specification (Width: 250px, Background: #F5F6F7) */
        aside.app-sidebar {
            width: 250px;
            background-color: var(--sidebar-bg);
            border-right: 1px solid var(--border-color);
            padding: 16px 0;
            display: flex;
            flex-direction: column;
            transition: transform 0.3s ease;
        }

        .sidebar-menu {
            list-style: none;
        }

        .sidebar-item {
            margin-bottom: 2px;
        }

        .sidebar-link {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 12px 20px;
            color: var(--text-primary);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-left: 4px solid transparent;
            transition: all 0.2s ease;
        }

        .sidebar-link i {
            width: 20px;
            text-align: center;
            font-size: 16px;
            color: #64748B;
            transition: color 0.2s ease;
        }

        .sidebar-link:hover {
            background-color: var(--primary-blue);
            color: var(--white);
        }

        .sidebar-link:hover i {
            color: var(--white);
        }

        /* Selected Item Specification (Blue Left Border 4px #3B5998, Bold Text) */
        .sidebar-item.active .sidebar-link {
            border-left-color: var(--primary-blue);
            font-weight: 700;
            color: var(--primary-blue);
            background-color: rgba(59, 89, 152, 0.08);
        }

        .sidebar-item.active .sidebar-link i {
            color: var(--primary-blue);
        }

        /* Main Workspace Area */
        main.main-content-wrapper {
            flex: 1;
            padding: 20px 24px;
            overflow-y: auto;
        }

        /* 5. Breadcrumb Specification */
        .breadcrumb {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: var(--text-secondary);
            margin-bottom: 12px;
        }

        .breadcrumb a {
            color: var(--secondary-blue);
            text-decoration: none;
        }

        .breadcrumb a:hover {
            text-decoration: underline;
        }

        .breadcrumb span.separator {
            color: #9CA3AF;
        }

        /* Header Support link */
        .page-header-row {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 20px;
        }

        /* 6. Page Title Specification (24px Cabin) */
        .page-title h1 {
            font-size: 24px;
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 4px;
        }

        .page-title p {
            font-size: 14px;
            color: var(--text-secondary);
        }

        .support-links {
            font-size: 13px;
        }

        .support-links a {
            color: var(--secondary-blue);
            text-decoration: none;
            margin-left: 10px;
        }

        /* 7. KPI Summary Cards Specification */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        /* 17. Card Specification (White bg, 4px radius, #D8D8D8 border, Blue Top Border 4px, Soft shadow) */
        .kpi-card {
            background-color: var(--white);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            border-top: 4px solid var(--primary-blue);
            padding: 16px 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .kpi-info h3 {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: var(--text-secondary);
            margin-bottom: 8px;
        }

        .kpi-info .kpi-value {
            font-size: 26px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .kpi-icon {
            width: 44px;
            height: 44px;
            border-radius: 4px;
            background-color: #EEF2FF;
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        /* 8. Search & Filters Section Specification */
        .filter-toolbar {
            background-color: var(--white);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 14px 18px;
            margin-bottom: 20px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
        }

        .filter-inputs {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            flex: 1;
        }

        .filter-control {
            height: 36px;
            padding: 0 12px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
            font-size: 13px;
            color: var(--text-primary);
            background-color: var(--white);
            outline: none;
        }

        .filter-control:focus {
            border-color: var(--secondary-blue);
        }

        .filter-control.search-box {
            min-width: 200px;
        }

        .filter-actions {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        /* 16. Buttons Specification */
        .btn {
            height: 36px;
            padding: 0 16px;
            border-radius: 4px;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border: 1px solid transparent;
            transition: all 0.2s;
        }

        /* Primary Button (Blue bg, White text) */
        .btn-primary {
            background-color: var(--primary-blue);
            color: var(--white);
        }

        .btn-primary:hover {
            background-color: #2F477A;
        }

        /* Secondary Button (White bg, Blue border) */
        .btn-secondary {
            background-color: var(--white);
            border-color: var(--primary-blue);
            color: var(--primary-blue);
        }

        .btn-secondary:hover {
            background-color: #EEF2FF;
        }

        .btn-success {
            background-color: var(--success-color);
            color: var(--white);
        }

        .btn-danger {
            background-color: var(--danger-color);
            color: var(--white);
        }

        /* 9 & 10. Main Content Area & Standard Table Specification */
        .table-card {
            background-color: var(--white);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            border-top: 4px solid var(--primary-blue);
            margin-bottom: 24px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
            overflow: hidden;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        table.standard-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        table.standard-table th {
            background-color: #F8FAFC;
            color: var(--text-primary);
            font-size: 13px;
            font-weight: 700;
            padding: 12px 16px;
            border-bottom: 2px solid var(--border-color);
            position: sticky;
            top: 0;
        }

        table.standard-table td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border-color);
            font-size: 13px;
            vertical-align: middle;
        }

        /* Zebra Striping Specification */
        table.standard-table tbody tr:nth-child(even) {
            background-color: #F9FAFB;
        }

        table.standard-table tbody tr:hover {
            background-color: #F1F5F9;
        }

        .student-photo {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            object-fit: cover;
            background-color: #E2E8F0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            color: var(--primary-blue);
            font-size: 13px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
        }

        .status-badge.paid {
            background-color: #E8F5E9;
            color: var(--success-color);
        }

        .status-badge.pending {
            background-color: #FEF9E7;
            color: var(--warning-color);
        }

        .status-badge.outstanding {
            background-color: #FDEDEC;
            color: var(--danger-color);
        }

        .table-actions {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .action-btn {
            background: none;
            border: none;
            color: #64748B;
            cursor: pointer;
            font-size: 15px;
            padding: 4px 8px;
            border-radius: 4px;
            transition: all 0.2s;
        }

        .action-btn:hover {
            color: var(--primary-blue);
            background-color: #EEF2FF;
        }

        /* Pagination */
        .pagination-container {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 12px 18px;
            background-color: var(--white);
            border-top: 1px solid var(--border-color);
            font-size: 13px;
            color: var(--text-secondary);
        }

        .pagination-pages {
            display: flex;
            align-items: center;
            gap: 4px;
        }

        .page-btn {
            width: 30px;
            height: 30px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
            background-color: var(--white);
            color: var(--text-primary);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 12px;
        }

        .page-btn.active {
            background-color: var(--primary-blue);
            color: var(--white);
            border-color: var(--primary-blue);
            font-weight: 700;
        }

        /* 11 & 12. Charts & Recent Activity Grid Specification */
        .bottom-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }

        .chart-card, .activity-card {
            background-color: var(--white);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            border-top: 4px solid var(--primary-blue);
            padding: 18px 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
        }

        .section-title {
            font-size: 18px; /* 18px Section Title Specification */
            font-weight: 700;
            color: var(--text-primary);
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .chart-container {
            position: relative;
            height: 260px;
        }

        /* Recent Activity Items */
        .activity-list {
            list-style: none;
        }

        .activity-item {
            padding: 12px 0;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .activity-item:last-child {
            border-bottom: none;
        }

        .activity-desc {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-primary);
        }

        .activity-time {
            font-size: 11px;
            color: var(--text-secondary);
        }

        /* 13. Footer Specification */
        footer.app-footer {
            background-color: var(--white);
            border-top: 1px solid var(--border-color);
            padding: 14px 24px;
            font-size: 12px;
            color: var(--text-secondary);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        footer.app-footer a {
            color: var(--secondary-blue);
            text-decoration: none;
            margin: 0 6px;
        }

        footer.app-footer a:hover {
            text-decoration: underline;
        }

        /* Modal Dialog Styling */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: rgba(0, 0, 0, 0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2000;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s ease;
        }

        .modal-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }

        .modal-box {
            background-color: var(--white);
            border-radius: 4px;
            border-top: 4px solid var(--primary-blue);
            width: 480px;
            max-width: 90%;
            padding: 24px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
        }

        .modal-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 16px;
        }

        .modal-header h3 {
            font-size: 18px;
            color: var(--primary-blue);
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 18px;
            color: var(--text-secondary);
            cursor: pointer;
        }

        .modal-body {
            margin-bottom: 20px;
        }

        .form-group {
            margin-bottom: 14px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            margin-bottom: 6px;
            color: var(--text-primary);
        }

        .form-group input, .form-group select {
            width: 100%;
            height: 36px;
            padding: 0 12px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            font-size: 13px;
        }

        /* Responsive Breakpoints */
        @media (max-width: 992px) {
            aside.app-sidebar {
                position: fixed;
                top: 60px;
                bottom: 0;
                left: 0;
                z-index: 999;
                transform: translateX(-100%);
            }

            aside.app-sidebar.active {
                transform: translateX(0);
            }

            .toggle-sidebar-btn {
                display: block;
            }

            .bottom-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>

    <!-- 3. Header Bar Specification (Height: 60px, Background: #3B5998) -->
    <header class="app-header">
        <div class="header-left">
            <button class="toggle-sidebar-btn" id="sidebarToggle" title="Toggle Navigation">
                <i class="fa-solid fa-bars"></i>
            </button>
            <a href="#" class="company-logo">
                <i class="fa-solid fa-shield-halved"></i>
                <span>Guardianship</span>
            </a>
            <!-- Global Search Component -->
            <div class="header-search">
                <i class="fa-solid fa-magnifying-glass"></i>
                <input type="text" id="globalSearchInput" placeholder="Search Students...">
            </div>
        </div>

        <div class="header-right">
            <!-- Notifications Icon -->
            <button class="header-icon-btn" title="Notifications" onclick="alert('3 new notifications')">
                <i class="fa-regular fa-bell"></i>
                <span class="badge-count">3</span>
            </button>
            <!-- Messages Icon -->
            <button class="header-icon-btn" title="Messages" onclick="alert('15 unread messages')">
                <i class="fa-regular fa-comments"></i>
                <span class="badge-count">15</span>
            </button>
            <!-- School Selector Component -->
            <div class="school-selector">
                <select id="schoolSelect" title="Select School">
                    <option value="all">🏫 Hillside Primary School</option>
                    <option value="prep">🏫 Hillside Preparatory</option>
                    <option value="secondary">🏫 Hillside Secondary</option>
                </select>
            </div>
            <!-- User Profile Component -->
            <div class="user-profile" title="Admin Profile">
                <div class="user-avatar">AT</div>
                <span class="user-name">Admin Tinotenda</span>
            </div>
            <!-- Settings Icon -->
            <button class="header-icon-btn" title="Settings" onclick="switchTab('Settings', 'Settings & System Preferences')">
                <i class="fa-solid fa-gear"></i>
            </button>
        </div>
    </header>

    <!-- App Main Layout -->
    <div class="app-layout">

        <!-- 4. Sidebar Navigation Specification (Width: 250px, Background: #F5F6F7) -->
        <aside class="app-sidebar" id="appSidebar">
            <ul class="sidebar-menu">
                <li class="sidebar-item" data-tab="Dashboard">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Dashboard', 'Main Overview & System Summary')">
                        <i class="fa-solid fa-chart-line"></i>
                        <span>Dashboard</span>
                    </a>
                </li>
                <li class="sidebar-item active" data-tab="Students">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Students', 'Manage student records, attendance, academic reports and fee information.')">
                        <i class="fa-solid fa-user-graduate"></i>
                        <span>Students</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Teachers">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Teachers', 'Manage teachers, subjects and class assignments.')">
                        <i class="fa-solid fa-chalkboard-user"></i>
                        <span>Teachers</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Parents">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Parents', 'Parent & Guardian relationships and contact directory.')">
                        <i class="fa-solid fa-users"></i>
                        <span>Parents</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Classes">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Classes', 'Manage grade streams, classrooms and academic years.')">
                        <i class="fa-solid fa-door-open"></i>
                        <span>Classes</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Attendance">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Attendance', 'Daily student attendance tracking and statistics.')">
                        <i class="fa-solid fa-clipboard-user"></i>
                        <span>Attendance</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Reports">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Reports', 'Term progress report cards and merit certificates.')">
                        <i class="fa-solid fa-file-invoice"></i>
                        <span>Reports</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Fees">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Fees', 'School fee balances and fee-gated report locks.')">
                        <i class="fa-solid fa-money-bill-wave"></i>
                        <span>Fees</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Payments">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Payments', 'EcoCash, OneMoney and Card payment transaction log.')">
                        <i class="fa-solid fa-credit-card"></i>
                        <span>Payments</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Activities">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Activities', 'Extra-curricular sports, clubs and event schedules.')">
                        <i class="fa-solid fa-futbol"></i>
                        <span>Activities</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Uniform Shop">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Uniform Shop', 'School uniform inventory and online shop orders.')">
                        <i class="fa-solid fa-shirt"></i>
                        <span>Uniform Shop</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Messaging">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Messaging', 'Direct messaging with parents and broadcast circulars.')">
                        <i class="fa-solid fa-comments"></i>
                        <span>Messaging</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Analytics">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Analytics', 'School performance metrics, revenue charts & trends.')">
                        <i class="fa-solid fa-chart-pie"></i>
                        <span>Analytics</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Notifications">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Notifications', 'System alerts and push notification logs.')">
                        <i class="fa-solid fa-bell"></i>
                        <span>Notifications</span>
                    </a>
                </li>
                <li class="sidebar-item" data-tab="Settings">
                    <a href="javascript:void(0)" class="sidebar-link" onclick="switchTab('Settings', 'System configurations, roles and security policies.')">
                        <i class="fa-solid fa-gear"></i>
                        <span>Settings</span>
                    </a>
                </li>
            </ul>
        </aside>

        <!-- Main Content Workspace Area -->
        <main class="main-content-wrapper">

            <!-- 5. Breadcrumb Specification -->
            <div class="breadcrumb">
                <a href="javascript:void(0)" onclick="switchTab('Dashboard', 'Main Overview')">Dashboard</a>
                <span class="separator">&gt;</span>
                <span id="breadcrumbModule">Students</span>
                <span class="separator">&gt;</span>
                <span id="breadcrumbSub">Grade 7</span>
            </div>

            <!-- 6. Page Title Specification (24px Cabin) -->
            <div class="page-header-row">
                <div class="page-title">
                    <h1 id="pageTitleHeading">Student Management</h1>
                    <p id="pageTitleDesc">Manage student records, attendance, academic reports and fee information.</p>
                </div>
                <div class="support-links">
                    <a href="javascript:void(0)" onclick="alert('Help documentation center')"><i class="fa-solid fa-circle-question"></i> Help</a> | 
                    <a href="javascript:void(0)" onclick="alert('Support line: support@guardianship.ac.zw')"><i class="fa-solid fa-headset"></i> Support</a>
                </div>
            </div>

            <!-- 7. KPI Cards Summary Specification -->
            <div class="kpi-grid">
                <div class="kpi-card">
                    <div class="kpi-info">
                        <h3>Students</h3>
                        <div class="kpi-value" id="kpiValue1">1,250</div>
                    </div>
                    <div class="kpi-icon">
                        <i class="fa-solid fa-user-graduate"></i>
                    </div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-info">
                        <h3>Attendance</h3>
                        <div class="kpi-value" id="kpiValue2">95%</div>
                    </div>
                    <div class="kpi-icon" style="color: #4CAF50; background-color: #E8F5E9;">
                        <i class="fa-solid fa-chart-line"></i>
                    </div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-info">
                        <h3>Outstanding Fees</h3>
                        <div class="kpi-value" style="color: var(--danger-color);" id="kpiValue3">USD 24,000</div>
                    </div>
                    <div class="kpi-icon" style="color: var(--danger-color); background-color: #FDEDEC;">
                        <i class="fa-solid fa-file-circle-exclamation"></i>
                    </div>
                </div>

                <div class="kpi-card">
                    <div class="kpi-info">
                        <h3>Unread Messages</h3>
                        <div class="kpi-value" id="kpiValue4">15</div>
                    </div>
                    <div class="kpi-icon" style="color: #F39C12; background-color: #FEF9E7;">
                        <i class="fa-solid fa-comment-dots"></i>
                    </div>
                </div>
            </div>

            <!-- 8. Search & Filters Section Specification -->
            <div class="filter-toolbar">
                <div class="filter-inputs">
                    <input type="text" class="filter-control search-box" id="tableSearchBox" placeholder="Search by name, guardian..." onkeyup="filterTable()">
                    
                    <select class="filter-control" id="classFilter" onchange="filterTable()" title="Class Filter">
                        <option value="all">Class: All</option>
                        <option value="Grade 7">Grade 7</option>
                        <option value="Grade 4">Grade 4</option>
                        <option value="ECD B">ECD B</option>
                        <option value="Form 1">Form 1</option>
                    </select>

                    <select class="filter-control" id="teacherFilter" onchange="filterTable()" title="Teacher Filter">
                        <option value="all">Teacher: All</option>
                        <option value="Grace">Teacher Grace</option>
                        <option value="Farai">Teacher Farai</option>
                    </select>

                    <select class="filter-control" id="statusFilter" onchange="filterTable()" title="Status Filter">
                        <option value="all">Status: All</option>
                        <option value="paid">Paid</option>
                        <option value="pending">Pending</option>
                        <option value="outstanding">Outstanding Fees</option>
                    </select>

                    <input type="date" class="filter-control" id="datePicker" title="Date Range" onchange="filterTable()">
                </div>

                <div class="filter-actions">
                    <button class="btn btn-secondary" onclick="exportCSV()"><i class="fa-solid fa-file-csv"></i> Export CSV</button>
                    <button class="btn btn-primary" onclick="exportPDF()"><i class="fa-solid fa-file-pdf"></i> Export PDF</button>
                    <button class="btn btn-secondary" onclick="resetFilters()" title="Refresh"><i class="fa-solid fa-rotate"></i> Refresh</button>
                    <button class="btn btn-primary" onclick="openAddModal()"><i class="fa-solid fa-plus"></i> Add Student</button>
                </div>
            </div>

            <!-- 9 & 10. Main Content Area & Standard Table Specification -->
            <div class="table-card">
                <div class="table-responsive">
                    <table class="standard-table" id="studentTable">
                        <thead>
                            <tr>
                                <th>Photo</th>
                                <th>Student Name</th>
                                <th>Guardian</th>
                                <th>Class</th>
                                <th>Attendance</th>
                                <th>Outstanding Fees</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody id="studentTableBody">
                            <tr>
                                <td><div class="student-photo">AC</div></td>
                                <td><strong>Alice Chewe</strong></td>
                                <td>John Chewe (+263773333333)</td>
                                <td>ECD B (Butterflies)</td>
                                <td>92%</td>
                                <td><strong>USD 150.00</strong></td>
                                <td><span class="status-badge outstanding">Outstanding Fees</span></td>
                                <td>
                                    <div class="table-actions">
                                        <button class="action-btn" title="View Profile" onclick="alert('Viewing Alice Chewe profile')"><i class="fa-regular fa-eye"></i></button>
                                        <button class="action-btn" title="Edit Student" onclick="alert('Editing Alice Chewe')"><i class="fa-regular fa-pen-to-square"></i></button>
                                        <button class="action-btn" title="Delete" onclick="deleteRow(this)"><i class="fa-regular fa-trash-can"></i></button>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td><div class="student-photo">BC</div></td>
                                <td><strong>Bob Chewe</strong></td>
                                <td>John Chewe (+263773333333)</td>
                                <td>Grade 4 (Gold)</td>
                                <td>100%</td>
                                <td><strong>USD 0.00</strong></td>
                                <td><span class="status-badge paid">Paid</span></td>
                                <td>
                                    <div class="table-actions">
                                        <button class="action-btn" title="View Profile" onclick="alert('Viewing Bob Chewe profile')"><i class="fa-regular fa-eye"></i></button>
                                        <button class="action-btn" title="Edit Student" onclick="alert('Editing Bob Chewe')"><i class="fa-regular fa-pen-to-square"></i></button>
                                        <button class="action-btn" title="Delete" onclick="deleteRow(this)"><i class="fa-regular fa-trash-can"></i></button>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td><div class="student-photo">CM</div></td>
                                <td><strong>Chipo Moyo</strong></td>
                                <td>Tariro Moyo (+263778888888)</td>
                                <td>Grade 7 (Alpha)</td>
                                <td>96%</td>
                                <td><strong>USD 50.00</strong></td>
                                <td><span class="status-badge pending">Pending</span></td>
                                <td>
                                    <div class="table-actions">
                                        <button class="action-btn" title="View Profile" onclick="alert('Viewing Chipo Moyo profile')"><i class="fa-regular fa-eye"></i></button>
                                        <button class="action-btn" title="Edit Student" onclick="alert('Editing Chipo Moyo')"><i class="fa-regular fa-pen-to-square"></i></button>
                                        <button class="action-btn" title="Delete" onclick="deleteRow(this)"><i class="fa-regular fa-trash-can"></i></button>
                                    </div>
                                </td>
                            </tr>
                            <tr>
                                <td><div class="student-photo">DM</div></td>
                                <td><strong>David Mpofu</strong></td>
                                <td>Sipho Mpofu (+263779999999)</td>
                                <td>Form 1 (Green)</td>
                                <td>98%</td>
                                <td><strong>USD 0.00</strong></td>
                                <td><span class="status-badge paid">Paid</span></td>
                                <td>
                                    <div class="table-actions">
                                        <button class="action-btn" title="View Profile" onclick="alert('Viewing David Mpofu profile')"><i class="fa-regular fa-eye"></i></button>
                                        <button class="action-btn" title="Edit Student" onclick="alert('Editing David Mpofu')"><i class="fa-regular fa-pen-to-square"></i></button>
                                        <button class="action-btn" title="Delete" onclick="deleteRow(this)"><i class="fa-regular fa-trash-can"></i></button>
                                    </div>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Table Pagination -->
                <div class="pagination-container">
                    <div>Showing <strong>1 - 4</strong> of <strong>1,250</strong> students</div>
                    <div class="pagination-pages">
                        <button class="page-btn"><i class="fa-solid fa-angle-left"></i></button>
                        <button class="page-btn active">1</button>
                        <button class="page-btn">2</button>
                        <button class="page-btn">3</button>
                        <button class="page-btn">...</button>
                        <button class="page-btn">12</button>
                        <button class="page-btn"><i class="fa-solid fa-angle-right"></i></button>
                    </div>
                </div>
            </div>

            <!-- 11 & 12. Charts & Recent Activity Specification Grid -->
            <div class="bottom-grid">
                <!-- 11. Charts Section Specification -->
                <div class="chart-card">
                    <div class="section-title">
                        <span>Attendance & Fee Analytics</span>
                        <select class="filter-control" style="height: 30px; font-size: 12px;" id="chartYearSelect" onchange="updateCharts()">
                            <option value="2026">2026 Term 1</option>
                            <option value="2025">2025 Term 3</option>
                        </select>
                    </div>
                    <div class="chart-container">
                        <canvas id="analyticsChart"></canvas>
                    </div>
                </div>

                <!-- 12. Recent Activity Specification -->
                <div class="activity-card">
                    <div class="section-title">
                        <span>Recent Activity</span>
                        <i class="fa-solid fa-clock-rotate-left" style="font-size: 14px; color: var(--text-secondary);"></i>
                    </div>
                    <ul class="activity-list">
                        <li class="activity-item">
                            <span class="activity-desc">Teacher Grace uploaded Grade 7 report card</span>
                            <span class="activity-time"><i class="fa-regular fa-clock"></i> 2 minutes ago</span>
                        </li>
                        <li class="activity-item">
                            <span class="activity-desc">Parent John Chewe paid school fees (USD 360)</span>
                            <span class="activity-time"><i class="fa-regular fa-clock"></i> 10 minutes ago</span>
                        </li>
                        <li class="activity-item">
                            <span class="activity-desc">Daily attendance completed for Grade 4 Gold</span>
                            <span class="activity-time"><i class="fa-regular fa-clock"></i> Today, 09:15 AM</span>
                        </li>
                        <li class="activity-item">
                            <span class="activity-desc">New student Alice Chewe registered</span>
                            <span class="activity-time"><i class="fa-regular fa-clock"></i> Yesterday</span>
                        </li>
                    </ul>
                </div>
            </div>

        </main>
    </div>

    <!-- 13. Footer Specification -->
    <footer class="app-footer">
        <div>
            © 2026 <strong>Guardianship</strong> | <strong>PT Tech</strong>
        </div>
        <div>
            <a href="javascript:void(0)">Privacy Policy</a> | 
            <a href="javascript:void(0)">Terms</a> | 
            <a href="javascript:void(0)">Support</a> | 
            <span>Version 1.0</span>
        </div>
    </footer>

    <!-- Add Student Modal -->
    <div class="modal-overlay" id="addStudentModal">
        <div class="modal-box">
            <div class="modal-header">
                <h3>Add New Student</h3>
                <button class="modal-close" onclick="closeAddModal()">&times;</button>
            </div>
            <div class="modal-body">
                <form id="newStudentForm">
                    <div class="form-group">
                        <label>Student Full Name</label>
                        <input type="text" id="newStudentName" placeholder="e.g. John Doe" required>
                    </div>
                    <div class="form-group">
                        <label>Guardian Name & Contact</label>
                        <input type="text" id="newGuardianName" placeholder="e.g. Jane Doe (+26377...)" required>
                    </div>
                    <div class="form-group">
                        <label>Class Grade</label>
                        <select id="newStudentClass">
                            <option value="ECD B (Butterflies)">ECD B (Butterflies)</option>
                            <option value="Grade 1 (Green)">Grade 1 (Green)</option>
                            <option value="Grade 4 (Gold)">Grade 4 (Gold)</option>
                            <option value="Grade 7 (Alpha)">Grade 7 (Alpha)</option>
                            <option value="Form 1 (Green)">Form 1 (Green)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Initial Outstanding Balance (USD)</label>
                        <input type="number" id="newStudentFee" value="0.00" step="10.00">
                    </div>
                </form>
            </div>
            <div style="display: flex; justify-content: flex-end; gap: 10px;">
                <button class="btn btn-secondary" onclick="closeAddModal()">Cancel</button>
                <button class="btn btn-primary" onclick="submitNewStudent()">Save Student</button>
            </div>
        </div>
    </div>

    <!-- Client-side JavaScript Controller -->
    <script>
        // Sidebar Toggle
        const sidebarToggle = document.getElementById('sidebarToggle');
        const appSidebar = document.getElementById('appSidebar');
        if (sidebarToggle && appSidebar) {
            sidebarToggle.addEventListener('click', () => {
                appSidebar.classList.toggle('active');
            });
        }

        // Global Tab Switcher Logic
        function switchTab(tabName, description) {
            document.querySelectorAll('.sidebar-item').forEach(item => {
                item.classList.remove('active');
                if (item.getAttribute('data-tab') === tabName) {
                    item.classList.add('active');
                }
            });

            document.getElementById('breadcrumbModule').innerText = tabName;
            document.getElementById('pageTitleHeading').innerText = tabName + ' Management';
            document.getElementById('pageTitleDesc').innerText = description;
        }

        // Search & Filter Logic
        function filterTable() {
            const globalSearch = document.getElementById('globalSearchInput').value.toLowerCase();
            const tableSearch = document.getElementById('tableSearchBox').value.toLowerCase();
            const classVal = document.getElementById('classFilter').value;
            const statusVal = document.getElementById('statusFilter').value;

            const query = globalSearch || tableSearch;
            const rows = document.querySelectorAll('#studentTableBody tr');

            rows.forEach(row => {
                const text = row.innerText.toLowerCase();
                const classText = row.children[3].innerText;
                const statusText = row.children[6].innerText.toLowerCase();

                let matchesSearch = !query || text.includes(query);
                let matchesClass = classVal === 'all' || classText.includes(classVal);
                let matchesStatus = statusVal === 'all' || statusText.includes(statusVal);

                if (matchesSearch && matchesClass && matchesStatus) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        document.getElementById('globalSearchInput').addEventListener('keyup', filterTable);

        function resetFilters() {
            document.getElementById('globalSearchInput').value = '';
            document.getElementById('tableSearchBox').value = '';
            document.getElementById('classFilter').value = 'all';
            document.getElementById('teacherFilter').value = 'all';
            document.getElementById('statusFilter').value = 'all';
            document.getElementById('datePicker').value = '';
            filterTable();
        }

        function deleteRow(btn) {
            if (confirm('Are you sure you want to remove this student record?')) {
                btn.closest('tr').remove();
            }
        }

        // Export CSV Functionality
        function exportCSV() {
            let csv = 'Student Name,Guardian,Class,Attendance,Outstanding Fees,Status\n';
            const rows = document.querySelectorAll('#studentTableBody tr');
            rows.forEach(row => {
                if (row.style.display !== 'none') {
                    const cols = row.querySelectorAll('td');
                    const name = cols[1].innerText.trim();
                    const guardian = cols[2].innerText.trim();
                    const cls = cols[3].innerText.trim();
                    const att = cols[4].innerText.trim();
                    const fee = cols[5].innerText.trim();
                    const status = cols[6].innerText.trim();
                    csv += `"${name}","${guardian}","${cls}","${att}","${fee}","${status}"\n`;
                }
            });

            const blob = new Blob([csv], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.setAttribute('href', url);
            a.setAttribute('download', 'guardianship_students_report.csv');
            a.click();
        }

        // Export PDF Functionality
        function exportPDF() {
            window.print();
        }

        // Modal Dialog Logic
        function openAddModal() {
            document.getElementById('addStudentModal').classList.add('active');
        }

        function closeAddModal() {
            document.getElementById('addStudentModal').classList.remove('active');
        }

        function submitNewStudent() {
            const name = document.getElementById('newStudentName').value;
            const guardian = document.getElementById('newGuardianName').value;
            const cls = document.getElementById('newStudentClass').value;
            const fee = parseFloat(document.getElementById('newStudentFee').value || 0).toFixed(2);

            if (!name || !guardian) {
                alert('Please fill in student and guardian names.');
                return;
            }

            const initials = name.split(' ').map(n => n[0]).join('').toUpperCase();
            const statusBadge = fee > 0 ? '<span class="status-badge outstanding">Outstanding Fees</span>' : '<span class="status-badge paid">Paid</span>';

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><div class="student-photo">${initials}</div></td>
                <td><strong>${name}</strong></td>
                <td>${guardian}</td>
                <td>${cls}</td>
                <td>100%</td>
                <td><strong>USD ${fee}</strong></td>
                <td>${statusBadge}</td>
                <td>
                    <div class="table-actions">
                        <button class="action-btn" title="View Profile" onclick="alert('Viewing ${name}')"><i class="fa-regular fa-eye"></i></button>
                        <button class="action-btn" title="Edit Student" onclick="alert('Editing ${name}')"><i class="fa-regular fa-pen-to-square"></i></button>
                        <button class="action-btn" title="Delete" onclick="deleteRow(this)"><i class="fa-regular fa-trash-can"></i></button>
                    </div>
                </td>
            `;

            document.getElementById('studentTableBody').prepend(tr);
            closeAddModal();
            document.getElementById('newStudentForm').reset();
        }

        // 11. Chart.js Implementation
        let analyticsChart;
        function initChart() {
            const ctx = document.getElementById('analyticsChart').getContext('2d');
            analyticsChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
                    datasets: [
                        {
                            label: 'Attendance Rate (%)',
                            data: [92, 94, 91, 95, 96, 94, 95],
                            borderColor: '#3B5998',
                            backgroundColor: 'rgba(59, 89, 152, 0.1)',
                            fill: true,
                            tension: 0.3
                        },
                        {
                            label: 'Fee Collection ($k USD)',
                            data: [15, 22, 18, 30, 25, 28, 24],
                            borderColor: '#4CAF50',
                            backgroundColor: 'rgba(76, 175, 80, 0.1)',
                            fill: true,
                            tension: 0.3
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'top',
                            labels: {
                                font: {
                                    family: "'Cabin', sans-serif"
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        }

        function updateCharts() {
            if (analyticsChart) {
                const year = document.getElementById('chartYearSelect').value;
                if (year === '2025') {
                    analyticsChart.data.datasets[0].data = [88, 90, 89, 92, 93, 91, 90];
                    analyticsChart.data.datasets[1].data = [12, 18, 15, 22, 20, 24, 21];
                } else {
                    analyticsChart.data.datasets[0].data = [92, 94, 91, 95, 96, 94, 95];
                    analyticsChart.data.datasets[1].data = [15, 22, 18, 30, 25, 28, 24];
                }
                analyticsChart.update();
            }
        }

        window.addEventListener('DOMContentLoaded', initChart);
    </script>
</body>
</html>
