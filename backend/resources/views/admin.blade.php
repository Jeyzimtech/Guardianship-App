<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edu+Conect - Admin Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cabin:ital,wght@0,400..700;1,400..700&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary-blue: #3B5998;
            --primary-hover: #2d4373;
            --primary-light: #4A69BD;
            --primary-accent: #2980B9;
            --secondary-blue: #5B7BD5;
            --soft-blue: #F0F4FA;
            --blue-border: #D0DCEE;
            --bg-light: #F9FAFB;
            --surface-white: #FFFFFF;
            --border-color: #D8D8D8;
            --text-primary: #1F2937;
            --text-secondary: #6B7280;
            --success-green: #22C55E;
            --success-bg: #DCFCE7;
            --danger-red: #EF4444;
            --danger-bg: #FEE2E2;
            --warning-amber: #F59E0B;
            --warning-bg: #FEF3C7;
            --info-cyan: #0EA5E9;
            --info-bg: #E0F2FE;
            --sidebar-width: 260px;
        }

        *, *::before, *::after {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Cabin', sans-serif;
            border-radius: 0 !important;
        }

        body {
            background-color: var(--bg-light);
            color: var(--text-primary);
            min-height: 100vh;
            overflow-x: hidden;
        }

        /* AUTH CONTAINER (LOGIN & SIGNUP WITH LOGO ON RIGHT) */
        .auth-wrapper {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: #F3F4F6;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
            padding: 20px;
            transition: all 0.3s ease;
        }

        .auth-wrapper.hidden {
            display: none;
        }

        .auth-card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.12);
            width: 100%;
            max-width: 960px;
            min-height: 560px;
            display: flex;
            overflow: hidden;
            border: 1px solid var(--border-color);
        }

        /* Left Side: Form Controls */
        .auth-form-side {
            flex: 1.1;
            padding: 44px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .auth-tabs {
            display: flex;
            gap: 16px;
            border-bottom: 2px solid #E5E7EB;
            margin-bottom: 28px;
        }

        .auth-tab-btn {
            background: transparent;
            border: none;
            padding: 10px 0;
            font-size: 15px;
            font-weight: 700;
            color: var(--text-secondary);
            cursor: pointer;
            position: relative;
            transition: all 0.2s;
        }

        .auth-tab-btn.active {
            color: var(--primary-blue);
        }

        .auth-tab-btn.active::after {
            content: '';
            position: absolute;
            bottom: -2px;
            left: 0;
            right: 0;
            height: 2px;
            background: var(--primary-blue);
        }

        .auth-form {
            display: none;
        }

        .auth-form.active {
            display: block;
        }

        .auth-title {
            font-size: 24px;
            font-weight: 800;
            color: var(--text-primary);
            margin-bottom: 6px;
        }

        .auth-subtitle {
            font-size: 13px;
            color: var(--text-secondary);
            margin-bottom: 24px;
        }

        .auth-form .form-group {
            margin-bottom: 16px;
        }

        .auth-form label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: var(--text-secondary);
            margin-bottom: 6px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .auth-form input, .auth-form select {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            font-size: 14px;
            outline: none;
            transition: border 0.2s;
        }

        .auth-form input:focus, .auth-form select:focus {
            border-color: var(--primary-blue);
            box-shadow: 0 0 0 3px rgba(59, 89, 152, 0.1);
        }

        .btn-auth-submit {
            width: 100%;
            padding: 14px;
            background: var(--primary-blue);
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 700;
            cursor: pointer;
            margin-top: 10px;
            transition: background 0.2s;
        }

        .btn-auth-submit:hover {
            background: var(--primary-hover);
        }

        /* Right Side: Logo & Branding Panel */
        .auth-logo-side {
            flex: 0.9;
            background: var(--primary-blue);
            color: white;
            padding: 44px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            text-align: center;
            position: relative;
            overflow: hidden;
        }

        .auth-logo-side::before {
            content: '';
            position: absolute;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.05);
            top: -50px;
            right: -50px;
        }

        .auth-logo-side::after {
            content: '';
            position: absolute;
            width: 200px;
            height: 200px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.04);
            bottom: -30px;
            left: -30px;
        }

        .logo-badge {
            width: 90px;
            height: 90px;
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(8px);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 24px;
            border: 1px solid rgba(255, 255, 255, 0.25);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
        }

        .logo-badge svg {
            width: 52px;
            height: 52px;
            fill: white;
        }

        .brand-heading {
            font-size: 28px;
            font-weight: 800;
            letter-spacing: -0.5px;
            margin-bottom: 8px;
        }

        .brand-subtext {
            font-size: 14px;
            line-height: 1.5;
            opacity: 0.85;
            max-width: 300px;
            margin-bottom: 24px;
        }

        .brand-tag {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.5px;
        }

        /* MAIN APP LAYOUT */
        .app-layout {
            display: flex;
            min-height: 100vh;
        }

        aside.sidebar {
            width: var(--sidebar-width);
            background: var(--surface-white);
            border-right: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            z-index: 100;
        }

        .brand-header {
            height: 64px;
            background: var(--primary-blue);
            color: white;
            display: flex;
            align-items: center;
            padding: 0 20px;
            gap: 12px;
            font-weight: 700;
            font-size: 18px;
        }

        .brand-header svg {
            width: 24px;
            height: 24px;
            fill: currentColor;
        }

        .nav-list {
            list-style: none;
            padding: 16px 10px;
            flex: 1;
            overflow-y: auto;
        }

        .nav-item {
            margin-bottom: 4px;
        }

        .nav-section {
            margin: 18px 14px 8px;
            color: #94A3B8;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: .09em;
        }

        .nav-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-radius: 6px;
            transition: all 0.2s ease;
            cursor: pointer;
        }

        .nav-link svg, .nav-link img {
            width: 22px;
            height: 22px;
            object-fit: contain;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .nav-link:hover {
            background-color: rgba(59, 89, 152, 0.08);
            color: var(--primary-blue);
        }

        .nav-link.active {
            background-color: var(--primary-blue);
            color: white;
        }

        .nav-link.active svg {
            stroke: white;
        }

        .nav-link.active img {
            filter: brightness(0) invert(1);
        }

        .sidebar-footer {
            padding: 16px;
            border-top: 1px solid var(--border-color);
            font-size: 12px;
            color: var(--text-secondary);
            text-align: center;
        }

        main.main-content {
            margin-left: var(--sidebar-width);
            flex: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        header.top-header {
            height: 64px;
            background: var(--primary-blue);
            color: white;
            display: flex;
            align-items: center;
            justify-content: flex-end;
            padding: 0 28px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            position: sticky;
            top: 0;
            z-index: 90;
        }

        .school-select {
            background: rgba(255, 255, 255, 0.15);
            color: white;
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 6px;
            padding: 6px 12px;
            font-size: 13px;
            font-weight: 600;
            outline: none;
            cursor: pointer;
        }

        .school-select option {
            background-color: var(--primary-blue);
            color: white;
        }

        .header-actions {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .action-btn {
            background: transparent;
            border: none;
            color: white;
            position: relative;
            cursor: pointer;
            padding: 6px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
        }

        .action-btn:hover {
            background: rgba(255, 255, 255, 0.15);
        }

        .action-btn svg {
            width: 22px;
            height: 22px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .badge-dot {
            position: absolute;
            top: 4px;
            right: 4px;
            width: 8px;
            height: 8px;
            background-color: var(--danger-red);
            border-radius: 50%;
            border: 1.5px solid var(--primary-blue);
        }

        .user-profile-pill {
            display: flex;
            align-items: center;
            gap: 10px;
            padding-left: 12px;
            border-left: 1px solid rgba(255, 255, 255, 0.2);
        }

        .avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: white;
            color: var(--primary-blue);
            font-weight: 700;
            font-size: 13px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .user-info {
            display: flex;
            flex-direction: column;
            font-size: 12px;
        }

        .user-name {
            font-weight: 600;
        }

        .user-role {
            opacity: 0.8;
            font-size: 11px;
        }

        .btn-logout {
            background: rgba(255, 255, 255, 0.15);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 12px;
            cursor: pointer;
            margin-left: 8px;
        }

        .btn-logout:hover {
            background: rgba(255, 255, 255, 0.25);
        }

        .content-body {
            padding: 28px;
            flex: 1;
        }

        .page-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 24px;
        }

        .page-title {
            font-size: 22px;
            font-weight: 700;
            color: var(--primary-blue);
        }

        .page-subtitle {
            font-size: 13px;
            color: var(--text-secondary);
            margin-top: 2px;
        }

        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }

        .kpi-card {
            background: var(--surface-white);
            border-radius: 4px;
            border: 1px solid var(--border-color);
            padding: 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            box-shadow: none;
        }

        .kpi-info p.title {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            color: var(--text-secondary);
            letter-spacing: 0.5px;
        }

        .kpi-info p.value {
            font-size: 24px;
            font-weight: 700;
            margin-top: 4px;
            color: var(--text-primary);
        }

        .kpi-icon {
            width: 40px;
            height: 40px;
            border-radius: 4px;
            background: rgba(59, 89, 152, 0.08);
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .kpi-icon img {
            width: 24px;
            height: 24px;
            object-fit: contain;
        }

        .kpi-icon svg {
            width: 22px;
            height: 22px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .section-title {
            font-size: 16px;
            font-weight: 700;
            color: var(--primary-blue);
            margin-bottom: 14px;
        }

        .cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }

        .module-card {
            background: var(--surface-white);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 16px;
            display: flex;
            align-items: center;
            gap: 16px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .module-card:hover {
            border-color: var(--primary-blue);
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
        }

        .module-icon {
            width: 42px;
            height: 42px;
            border-radius: 6px;
            background: rgba(59, 89, 152, 0.1);
            color: var(--primary-blue);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .module-icon img {
            width: 24px;
            height: 24px;
            object-fit: contain;
        }

        .module-icon svg {
            width: 22px;
            height: 22px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        .module-text h4 {
            font-size: 15px;
            font-weight: 700;
            color: var(--primary-blue);
        }

        .module-text p {
            font-size: 12px;
            color: var(--text-secondary);
            margin-top: 2px;
        }

        .table-card {
            background: var(--surface-white);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
            overflow: hidden;
            margin-bottom: 24px;
        }

        .table-toolbar {
            padding: 16px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: center;
            justify-content: space-between;
            background: #FAFAFA;
        }

        .filter-group {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .filter-btn {
            background: white;
            border: 1px solid var(--border-color);
            padding: 6px 12px;
            font-size: 13px;
            font-weight: 500;
            border-radius: 4px;
            color: var(--text-secondary);
            cursor: pointer;
        }

        .filter-btn.active {
            background: var(--primary-blue);
            color: white;
            border-color: var(--primary-blue);
        }

        .search-input {
            padding: 7px 12px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            font-size: 13px;
            outline: none;
            width: 240px;
        }

        .search-input:focus {
            border-color: var(--secondary-blue);
        }

        .btn-primary {
            background: var(--primary-blue);
            color: white;
            border: none;
            padding: 8px 16px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 4px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn-primary:hover {
            background: var(--primary-hover);
        }

        .btn-primary svg {
            width: 16px;
            height: 16px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
            text-align: left;
        }

        table.data-table th {
            background: #F3F4F6;
            color: var(--text-secondary);
            font-weight: 600;
            padding: 12px 16px;
            border-bottom: 1px solid var(--border-color);
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.5px;
        }

        table.data-table td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border-color);
            color: var(--text-primary);
        }

        table.data-table tr:last-child td {
            border-bottom: none;
        }

        table.data-table tr:hover td {
            background: #F9FAFB;
        }

        .role-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            text-transform: capitalize;
        }

        .role-badge.admin { background: #E0E7FF; color: #3730A3; }
        .role-badge.teacher { background: #ECFDF5; color: #065F46; }
        .role-badge.guardian { background: #FEF3C7; color: #92400E; }
        .role-badge.student { background: #E0F2FE; color: #075985; }

        .btn-sm {
            padding: 4px 8px;
            font-size: 12px;
            border-radius: 4px;
            border: 1px solid var(--border-color);
            background: white;
            cursor: pointer;
            color: var(--text-secondary);
        }

        .btn-sm:hover {
            background: #F3F4F6;
            color: var(--text-primary);
        }

        .btn-danger {
            color: var(--danger-red);
            border-color: #FCA5A5;
        }

        .btn-danger:hover {
            background: var(--danger-bg);
        }

        .tab-pane {
            display: none;
        }

        .tab-pane.active {
            display: block;
        }

        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.4);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 200;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.2s ease;
        }

        .modal-overlay.open {
            opacity: 1;
            pointer-events: auto;
        }

        .modal-card {
            background: white;
            border-radius: 6px;
            width: 100%;
            max-width: 480px;
            border: 1px solid var(--border-color);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
            overflow: hidden;
        }

        .modal-header {
            background: var(--primary-blue);
            color: white;
            padding: 16px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-header h3 {
            font-size: 16px;
            font-weight: 700;
        }

        .modal-close {
            background: transparent;
            border: none;
            color: white;
            font-size: 18px;
            cursor: pointer;
        }

        .modal-body {
            padding: 20px;
        }

        .form-group {
            margin-bottom: 14px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            margin-bottom: 4px;
        }

        .form-control {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            font-size: 13px;
            outline: none;
        }

        .form-control:focus {
            border-color: var(--secondary-blue);
        }

        .modal-footer {
            padding: 14px 20px;
            background: #F9FAFB;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        .info-banner {
            background: var(--info-bg);
            border: 1px solid #BAE6FD;
            border-left: 4px solid var(--info-cyan);
            border-radius: 6px;
            padding: 12px 16px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 13px;
            color: #0369A1;
        }

        .info-banner svg {
            width: 20px;
            height: 20px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2;
            flex-shrink: 0;
        }
    </style>
</head>
<body>

            <!-- AUTH SECTION: ADMIN LOGIN WITH LOGO ON THE RIGHT -->
    <div class="auth-wrapper" id="authScreen">
        <div class="auth-card">

            <!-- Left Side: Form Controls -->
            <div class="auth-form-side">
                <div class="auth-tabs">
                    <button class="auth-tab-btn active" id="tabBtnLogin" onclick="switchAuthTab('login')">Admin Log In</button>
                </div>

                <!-- LOGIN FORM -->
                <form class="auth-form active" id="loginForm" onsubmit="handleLoginSubmit(event)">
                    <p class="auth-subtitle">Sign in to your Edu+Conect Web Admin Portal</p>

                    <div class="form-group">
                        <label>Admin Username or Email</label>
                        <input type="text" id="loginEmail" placeholder="name@school.org" required>
                    </div>

                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" id="loginPassword" placeholder="Enter your password" required>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; font-size: 13px;">
                        <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; text-transform: none; color: var(--text-primary);">
                            <input type="checkbox" checked> Remember session
                        </label>
                        <a href="#" style="color: var(--primary-blue); text-decoration: none; font-weight: 600;" onclick="return requestPasswordReset(event)">Forgot password?</a>
                    </div>

                    <button type="submit" class="btn-auth-submit">LOG IN TO DASHBOARD</button>
                </form>

            </div>

            <!-- Right Side: Brand Logo Panel -->
            <div class="auth-logo-side">
                <div style="background: white; padding: 20px 24px; border-radius: 14px; box-shadow: 0 16px 36px rgba(0,0,0,0.22); margin-bottom: 24px; display: inline-flex; align-items: center; justify-content: center;">
                    <img src="/assets/logo.png" alt="Edu+Connect Logo" style="height: 120px; width: auto; object-fit: contain;">
                </div>
                <h1 class="brand-heading" style="color: white; font-size: 26px; font-weight: 700; margin-bottom: 6px;">Edu+Connect</h1>
                <p class="brand-subtext" style="color: rgba(255,255,255,0.9); font-size: 14px;">A Good Day To Learn • Unified Institutional Platform</p>
                <div class="brand-tag">PORTAL ADMINISTRATOR</div>
            </div>

        </div>
    </div>


    <!-- MAIN DASHBOARD CONTENT CONTAINER -->
    <div class="app-layout" id="dashboardScreen">

        <!-- Sidebar Navigation -->
        <aside class="sidebar">
            <div class="brand-header" style="gap: 12px;">
                <div style="background: white; border-radius: 6px; padding: 4px; display: flex; align-items: center; justify-content: center; width: 36px; height: 36px;">
                    <img src="/assets/logo.png" alt="Edu+Connect Logo" style="height: 28px; width: 28px; object-fit: contain;">
                </div>
                <span style="font-weight: 700; font-size: 16px; letter-spacing: -0.2px;">Edu+Connect</span>
            </div>
            <ul class="nav-list">
                <li class="nav-section" data-roles="website_admin">PLATFORM OWNER</li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link active" onclick="switchTab('dashboard')">
                        <img src="/assets/icons8-dashboard.svg" alt="Dashboard">
                        <span>Dashboard</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="website_admin">
                    <a class="nav-link" onclick="switchTab('platform')">
                        <img src="/assets/icons8-school-management.svg" alt="Platform Owner">
                        <span>Website Admin (Platform)</span>
                    </a>
                </li>
                <li class="nav-section" data-roles="admin">SCHOOL ADMIN</li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('users')">
                        <img src="/assets/icons8-user.svg" alt="User Management">
                        <span>User Management</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('schools')">
                        <img src="/assets/icons8-school-management.svg" alt="School Management">
                        <span>School Management</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('teachers')">
                        <img src="/assets/icons8-teacher.svg" alt="Teachers">
                        <span>Teachers</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin,teacher">
                    <a class="nav-link" onclick="switchTab('students')">
                        <img src="/assets/icons8-education.svg" alt="Students">
                        <span>Students</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('fees')">
                        <img src="/assets/icons8-wallet.svg" alt="Fee Accounts">
                        <span>Fee Accounts</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="teacher,admin">
                    <a class="nav-link" onclick="switchTab('journal')">
                        <img src="/assets/icons8-reports.svg" alt="Learning Journal">
                        <span>Learning Journal & Logs</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="teacher,admin">
                    <a class="nav-link" onclick="switchTab('attendance')">
                        <img src="/assets/icons8-attendance.svg" alt="Attendance">
                        <span>Attendance</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('activities')">
                        <img src="/assets/icons8-attendance.svg" alt="Activities">
                        <span>Activities</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('behaviour')">
                        <img src="/assets/icons8-reports.svg" alt="Behaviour Categories">
                        <span>Behaviour Categories</span>
                    </a>
                </li>

                <li class="nav-item" data-roles="teacher,admin">
                    <a class="nav-link" onclick="switchTab('announcements')">
                        <img src="/assets/icons8-messages.svg" alt="Announcements">
                        <span>Announcements</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="teacher,admin">
                    <a class="nav-link" onclick="switchTab('reports')">
                        <img src="/assets/icons8-reports.svg" alt="Reports & Circulars">
                        <span>Reports & Circulars</span>
                    </a>
                </li>
                <li class="nav-item" data-roles="admin">
                    <a class="nav-link" onclick="switchTab('uniforms')">
                        <img src="/assets/icons8-wallet.svg" alt="Uniform Shop & Accounts">
                        <span>Uniform Shop & Accounts</span>
                    </a>
                </li>
            </ul>
        </aside>

        <!-- Main Content Area -->
        <main class="main-content">

            <!-- Top Header -->
            <header class="top-header">
                <div class="header-actions">
                    <button class="action-btn" data-roles="admin,teacher" title="View announcements" onclick="switchTab('announcements')">
                        <svg viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                        <span class="badge-dot"></span>
                    </button>
                    <button class="action-btn" data-roles="admin,teacher" title="Open announcements" onclick="switchTab('announcements')">
                        <img src="/assets/icons8-messages.svg" alt="Announcements">
                    </button>
                    <div class="user-profile-pill">
                        <div class="avatar" id="headerAvatar">AT</div>
                        <div class="user-info">
                            <span class="user-name" id="headerAdminName">Admin Tinotenda</span>
                    <span class="user-role" id="headerAdminRole">Administrator</span>
                        </div>
                        <button class="btn-logout" onclick="handleLogout()">Log Out</button>
                    </div>
                </div>
            </header>

            <!-- Body Area -->
            <div class="content-body">

                <!-- TAB 1: DASHBOARD OVERVIEW -->
                <div id="tab-dashboard" class="tab-pane active" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title" id="displaySchoolName">School Admin Workspace</h2>
                            <p class="page-subtitle">School records, classes, staff, fees, uniform shop, and communications</p>
                        </div>
                        <button class="btn-primary" data-roles="admin" onclick="openModal('userModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Quick Add User
                        </button>
                    </div>

                    <div class="kpi-grid">
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Total Students</p>
                                <p class="value" id="kpiStudents">--</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-education.svg" alt="Students">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Attendance Rate</p>
                                <p class="value" id="kpiAttendanceRate">--%</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-attendance.svg" alt="Attendance">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Active Teachers</p>
                                <p class="value" id="kpiTeachers">--</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-teacher.svg" alt="Active Teachers">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Total Classes</p>
                                <p class="value" id="kpiClasses">--</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-school-management.svg" alt="Classes">
                            </div>
                        </div>
                    </div>

                    <h3 class="section-title">School Academic Performance & Engagement Analytics</h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)); gap: 20px; margin-bottom: 24px;">

                        <!-- Chart 1: Academic & Enrollment Trends -->
                        <div class="table-card" style="padding: 18px; margin-bottom: 0;">
                            <div style="margin-bottom: 12px;">
                                <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-blue); margin: 0;">Academic Pass Rate Trends</h4>
                                <p style="font-size: 11px; color: var(--text-secondary); margin: 2px 0 0 0;">Term-over-term verified academic pass rates</p>
                            </div>
                            <div style="height: 220px; position: relative;">
                                <canvas id="revenueChart"></canvas>
                            </div>
                        </div>

                        <!-- Chart 2: Attendance by Stream -->
                        <div class="table-card" style="padding: 18px; margin-bottom: 0;">
                            <div style="margin-bottom: 12px;">
                                <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-blue); margin: 0;">Weekly Attendance Rate by Stream</h4>
                                <p style="font-size: 11px; color: var(--text-secondary); margin: 2px 0 0 0;">Comparison across Preparatory, Primary & Secondary</p>
                            </div>
                            <div style="height: 220px; position: relative;">
                                <canvas id="attendanceChart"></canvas>
                            </div>
                        </div>

                        <!-- Chart 3: App Activity & Engagement -->
                        <div class="table-card" style="padding: 18px; margin-bottom: 0;">
                            <div style="margin-bottom: 12px;">
                                <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-blue); margin: 0;">Parent & Teacher App Interactions</h4>
                                <p style="font-size: 11px; color: var(--text-secondary); margin: 2px 0 0 0;">Daily logins, report card views & notifications</p>
                            </div>
                            <div style="height: 220px; position: relative;">
                                <canvas id="activityChart"></canvas>
                            </div>
                        </div>

                    </div>

                    <h3 class="section-title">Quick Management Modules</h3>
                    <div class="cards-grid">
                        <div class="module-card" onclick="switchTab('students')">
                            <div class="module-icon"><img src="/assets/icons8-education.svg" alt="Student Management"></div>
                            <div class="module-text">
                                <h4>Student Management</h4>
                                <p>Enrolment, profiles & class allocations</p>
                            </div>
                        </div>
                        <div class="module-card" onclick="switchTab('users')">
                            <div class="module-icon"><img src="/assets/icons8-user.svg" alt="User Control"></div>
                            <div class="module-text">
                                <h4>User & Access Control</h4>
                                <p>Manage Admin, Teacher & Guardian accounts</p>
                            </div>
                        </div>
                        <div class="module-card" onclick="switchTab('schools')">
                            <div class="module-icon"><img src="/assets/icons8-school-management.svg" alt="School Setup"></div>
                            <div class="module-text">
                                <h4>School Setup & Classes</h4>
                                <p>Academic calendars, terms & grade divisions</p>
                            </div>
                        </div>
                        <div class="module-card" onclick="switchTab('teachers')">
                            <div class="module-icon"><img src="/assets/icons8-teacher.svg" alt="Teacher Management"></div>
                            <div class="module-text">
                                <h4>Teacher Management</h4>
                                <p>Faculty directory, subjects & class rosters</p>
                            </div>
                        </div>
                        <div class="module-card" onclick="switchTab('uniforms')">
                            <div class="module-icon"><img src="/assets/icons8-wallet.svg" alt="Uniform Shop"></div>
                            <div class="module-text">
                                <h4>Uniform Storefront</h4>
                                <p>Manage uniforms, pricing, sizes & photos</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- TAB: WEBSITE ADMIN (PLATFORM OWNER) CONSOLE -->
                <div id="tab-platform" class="tab-pane" data-roles="website_admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Website Admin (Platform Owner) Console</h2>
                            <p class="page-subtitle">Cross-school onboarding, platform directory, and guardian subscription controls</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('onboardSchoolModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Onboard New School
                        </button>
                    </div>

                    <div class="kpi-grid" style="margin-bottom: 20px;">
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Onboarded Schools</p>
                                <p class="value" id="platformSchoolCount">--</p>
                            </div>
                            <div class="kpi-icon"><img src="/assets/icons8-school-management.svg" alt="Schools"></div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Active Subscriptions</p>
                                <p class="value" id="platformActiveSubs" style="color:var(--success-green);">--</p>
                            </div>
                            <div class="kpi-icon"><img src="/assets/icons8-user.svg" alt="Active"></div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Suspended Subscriptions</p>
                                <p class="value" id="platformSuspendedSubs" style="color:var(--danger-red);">--</p>
                            </div>
                            <div class="kpi-icon"><img src="/assets/icons8-wallet.svg" alt="Suspended"></div>
                        </div>
                    </div>

                    <h3 class="section-title">School Directory (Platform Tier Configuration)</h3>
                    <div class="table-card" style="margin-bottom: 24px;">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>School Name</th>
                                    <th>Tier / Type</th>
                                    <th>Primary Admin Contact</th>
                                    <th>Branding Color</th>
                                    <th>Enrolled Students</th>
                                    <th>Students</th>
                                </tr>
                            </thead>
                            <tbody id="platformDirectoryBody">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">Loading registered schools...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <h3 class="section-title">Subscription Control Engine (Per-Child Access Toggle)</h3>
                    <p style="font-size:12px; color:var(--text-secondary); margin-bottom:12px;">Turning a child's subscription <strong>OFF</strong> suspends the parent's mobile app access for that child. School Admin internal records remain active.</p>
                    <div style="display:flex; align-items:center; gap:10px; margin-bottom:12px;">
                        <label for="platformSchoolFilter" style="font-size:13px; font-weight:600;">School view</label>
                        <select id="platformSchoolFilter" class="form-control" style="max-width:320px;" onchange="renderPlatformDirectoryTable()"><option value="all">All schools</option></select>
                    </div>
                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Child Name</th>
                                    <th>School & Grade</th>
                                    <th>Guardian Contact</th>
                                    <th>Subscription Status</th>
                                    <th>Period / Duration</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody id="subscriptionControlBody">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">Loading registered students & subscription statuses...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 2: USER MANAGEMENT -->
                <div id="tab-users" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">User Management</h2>
                            <p class="page-subtitle">Manage system users, security credentials, and access roles</p>
                        </div>
                        <div style="display:flex; gap:10px;">
                            <button class="btn-sm" data-roles="admin" style="background:#FFFFFF; border:1px solid #CBD5E1; color:#475569; display:inline-flex; align-items:center; gap:6px; font-weight:600; padding:6px 12px;" onclick="openMailSettingsModal()" title="Configure Outbound Email / SES Gateway">
                                <svg viewBox="0 0 24 24" style="width:14px; height:14px; stroke:currentColor; fill:none; stroke-width:2;"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                                SMTP Gateway
                            </button>
                            <button class="btn-primary" data-roles="admin" onclick="openModal('userModal')">
                                <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                                Add New User
                            </button>
                        </div>
                    </div>

                    <div class="table-card">
                        <div class="table-toolbar">
                            <div class="filter-group">
                                <button class="filter-btn active" onclick="filterUserRole('all', this)">All Users</button>
                                <button class="filter-btn" onclick="filterUserRole('admin', this)">Admins</button>
                                <button class="filter-btn" onclick="filterUserRole('teacher', this)">Teachers</button>
                                <button class="filter-btn" onclick="filterUserRole('guardian', this)">Guardians</button>
                            </div>
                            <input type="text" id="userSearchInput" class="search-input" placeholder="Search by name, email or phone..." onkeyup="renderUsersTable()">
                        </div>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Name</th>
                                    <th>Email</th>
                                    <th>Phone Number</th>
                                    <th>Role</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="usersTableBody">
                                <!-- Populated dynamically via JS -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 3: SCHOOL MANAGEMENT -->
                <div id="tab-schools" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">School & Class Management</h2>
                            <p class="page-subtitle">Academic years, term dates, and grade level configurations</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('classModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Add Grade/Class
                        </button>
                    </div>

                    <div class="table-card" style="padding: 20px; margin-bottom: 24px;">
                        <h3 class="section-title">Academic Years & Terms</h3>
                        <table class="data-table" style="margin-top: 10px;">
                            <thead>
                                <tr>
                                    <th>Academic Year</th>
                                    <th>Term</th>
                                    <th>Start Date</th>
                                    <th>End Date</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="academicYearsTableBody"><tr><td colspan="6" style="text-align:center;padding:20px;color:var(--text-secondary);">Loading academic years...</td></tr></tbody>
                        </table>
                    </div>

                    <h3 class="section-title">Active Classes & Divisions</h3>
                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Class Name</th>
                                    <th>Grade Level</th>
                                    <th>Form Teacher</th>
                                    <th>Enrolled Students</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="classesTableBody">
                                <tr>
                                    <td colspan="5" style="text-align:center;padding:20px;color:var(--text-secondary);">Loading classes...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 4: TEACHER MANAGEMENT -->
                <div id="tab-teachers" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Teacher Directory</h2>
                            <p class="page-subtitle">Manage school faculty, assigned subjects, and contact records</p>
                        </div>
                        <button class="btn-primary" data-roles="admin" onclick="openModal('teacherModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Add New Teacher
                        </button>
                    </div>

                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Teacher Name</th>
                                    <th>Subject Taught</th>
                                    <th>Assigned Class</th>
                                    <th>Email</th>
                                    <th>Phone</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="teachersTableBody">
                                <!-- Dynamically filled by JS -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 5: STUDENT MANAGEMENT -->
                <div id="tab-students" class="tab-pane" data-roles="admin,teacher">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Student Directory</h2>
                            <p class="page-subtitle">Student profiles, parent/guardian links, and academic standing</p>
                        </div>
                        <div style="display: flex; gap: 10px;">
                            <button class="btn-sm" data-roles="admin" style="padding: 8px 12px; font-weight: 600;" onclick="openModal('linkGuardianModal')">Link Guardian</button>
                            <button class="btn-primary" data-roles="admin,teacher" onclick="openModal('studentModal')">
                                <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                                Add New Student
                            </button>
                        </div>
                    </div>

                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Reg No</th>
                                    <th>Student Name</th>
                                    <th>Class</th>
                                    <th>Guardian Name</th>
                                    <th>Grade Level</th>
                                    <th>Attendance %</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="studentsTableBody">
                                <!-- Dynamically filled by JS -->
</tbody>
                        </table>
                    </div>
                    <h3 class="section-title" data-roles="admin" style="margin-top:24px;">Guardian Link Requests</h3>
                    <div class="table-card" data-roles="admin">
                        <table class="data-table">
                            <thead><tr><th>Guardian</th><th>Requested Student</th><th>School</th><th>Relationship / Notes</th><th>Review</th></tr></thead>
                            <tbody id="studentLinkRequestsBody"><tr><td colspan="5" style="text-align:center;padding:20px;">Loading requests…</td></tr></tbody>
                        </table>
                    </div>
                </div>

                <div id="tab-fees" class="tab-pane" data-roles="admin">
                    <div class="page-header"><div><h2 class="page-title">Fee Accounts</h2><p class="page-subtitle">View and update fee balances for students at your school.</p></div></div>
                    <div class="table-card"><table class="data-table"><thead><tr><th>Student</th><th>Class</th><th>USD Balance</th><th>ZiG Balance</th><th>Action</th></tr></thead><tbody id="feeAccountsBody"><tr><td colspan="5" style="text-align:center;padding:20px;">Loading fee accounts…</td></tr></tbody></table></div>
                </div>

                <!-- TAB: LEARNING JOURNAL & PREPARATORY WELLBEING LOGS -->
                <div id="tab-journal" class="tab-pane" data-roles="teacher,admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Learning Journal & Daily Wellbeing Feed</h2>
                            <p class="page-subtitle">Post work samples, drawings, audio/video notes, and Preparatory daily logs (always accessible to parents regardless of fee status)</p>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1.5fr; gap: 24px;">
                        <!-- Post Authoring Form -->
                        <div class="table-card" style="padding: 20px;">
                            <h4 style="font-size: 15px; font-weight: 700; color: var(--primary-blue); margin-bottom: 14px;">Post Work Sample / Wellbeing Log</h4>
                            <form onsubmit="handleJournalPostSubmit(event)">
                                <div class="form-group">
                                    <label>Select Student</label>
                                    <select class="form-control" id="journalStudentId">
                                        <option value="">-- Select Enrolled Student --</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label>Entry Type</label>
                                    <select class="form-control" id="journalType" onchange="toggleJournalTypeFields()">
                                        <option value="photo">Photo Work Sample</option>
                                        <option value="wellbeing">Preparatory Daily Wellbeing Log</option>
                                        <option value="drawing">Drawing / Annotation</option>
                                        <option value="voice">Voice Note</option>
                                        <option value="text">Text Note</option>
                                    </select>
                                </div>
                                <div class="form-group" id="journalCaptionGroup">
                                    <label>Caption / Teacher Note</label>
                                    <textarea class="form-control" id="journalCaption" rows="3" placeholder="Describe the learning activity or achievement..."></textarea>
                                </div>
                                <div class="form-group" id="journalMediaGroup">
                                    <label>Work Sample Image (Upload or URL)</label>
                                    <input type="file" id="journalImageFile" class="form-control" accept="image/*" style="margin-bottom:8px;">
                                    <input type="url" class="form-control" id="journalMediaUrl" placeholder="Or paste sample image URL (optional)">
                                </div>
                                <div id="journalWellbeingGroup" style="display:none; background:#F8FAFC; padding:12px; border:1px solid #E2E8F0; border-radius:4px; margin-bottom:14px;">
                                    <h5 style="font-size:12px; text-transform:uppercase; color:var(--text-secondary); margin-bottom:8px;">Preparatory Wellbeing Details</h5>
                                    <div class="form-group">
                                        <label>Meals Eaten</label>
                                        <input type="text" class="form-control" id="wellbeingMeals" placeholder="e.g. Ate all of lunch & snacks">
                                    </div>
                                    <div class="form-group">
                                        <label>Nap / Rest Duration</label>
                                        <input type="text" class="form-control" id="wellbeingNap" placeholder="e.g. Rested 45 mins quietly">
                                    </div>
                                    <div class="form-group">
                                        <label>Hygiene & Toileting</label>
                                        <input type="text" class="form-control" id="wellbeingHygiene" placeholder="e.g. Hands washed, good routine">
                                    </div>
                                </div>
                                <button type="submit" class="btn-primary" style="width: 100%; justify-content: center;">Post to Learning Journal</button>
                            </form>
                        </div>

                        <!-- Running Feed Preview -->
                        <div>
                            <h4 style="font-size: 15px; font-weight: 700; color: var(--primary-blue); margin-bottom: 14px;">Live Journal Stream</h4>
                            <div id="journalFeedContainer">
                                <p style="color:var(--text-secondary); text-align:center; padding:24px;">Loading live learning journal feed...</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- TAB 6: ATTENDANCE -->
                <div id="tab-attendance" class="tab-pane" data-roles="teacher,admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Daily Attendance Register</h2>
                            <p class="page-subtitle">Mark and verify real student attendance records</p>
                        </div>
                        <button class="btn-primary" onclick="saveAttendanceRegister()">Save Register</button>
                    </div>

                    <div class="table-card">
                        <div class="table-toolbar">
                            <div class="filter-group">
                                <label style="font-size: 13px; font-weight: 600;">Select Date:</label>
                                <input type="date" id="attDate" class="form-control" style="width: 160px;" onchange="loadAttendanceRoster()">
                                <label style="font-size: 13px; font-weight: 600; margin-left: 14px;">Select Class:</label>
                                <select id="attClassSelect" class="form-control" style="width: 160px;" onchange="loadAttendanceRoster()">
                                    <option value="all">All Classes</option>
                                </select>
                            </div>
                        </div>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Roll No</th>
                                    <th>Student Name</th>
                                    <th>Status</th>
                                    <th>Remarks / Subject</th>
                                </tr>
                            </thead>
                            <tbody id="attendanceRosterBody">
                                <tr>
                                    <td colspan="4" style="text-align:center; padding: 24px; color: var(--text-secondary);">Loading student register...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>



                <!-- TAB: ACTIVITY ROSTERS -->
                <div id="tab-activities" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Activity Rosters</h2>
                            <p class="page-subtitle">Create school activities and record which learners took part. Parents see their child's participation.</p>
                        </div>
                    </div>
                    <div style="display: grid; grid-template-columns: 1fr 1.5fr; gap: 24px;">
                        <div class="table-card" style="padding: 20px;">
                            <h4 style="font-size: 15px; font-weight: 700; color: var(--primary-blue); margin-bottom: 14px;">New Activity</h4>
                            <form onsubmit="addActivitySubmit(event)">
                                <div class="form-group"><label>Title</label><input type="text" id="activityTitle" class="form-control" placeholder="e.g. Inter-house athletics" required></div>
                                <div class="form-group"><label>Date</label><input type="date" id="activityDate" class="form-control" required></div>
                                <div class="form-group"><label>Description (optional)</label><textarea id="activityDescription" class="form-control" rows="3"></textarea></div>
                                <button type="submit" class="btn-primary" style="width: 100%; justify-content: center;">Create Activity</button>
                            </form>
                        </div>
                        <div class="table-card">
                            <table class="data-table">
                                <thead><tr><th>Activity</th><th>Date</th><th>On Roster</th><th>Took Part</th><th>Actions</th></tr></thead>
                                <tbody id="activitiesTableBody"><tr><td colspan="5" style="text-align:center;padding:20px;">Loading activities…</td></tr></tbody>
                            </table>
                        </div>
                    </div>
                    <div class="table-card" id="activityRosterCard" style="margin-top: 24px; display: none;">
                        <div class="table-toolbar" style="justify-content: space-between;">
                            <strong id="activityRosterTitle">Roster</strong>
                            <button class="btn-primary" onclick="saveActivityRoster()">Save Roster</button>
                        </div>
                        <table class="data-table">
                            <thead><tr><th>Student</th><th>Class</th><th>Participation</th></tr></thead>
                            <tbody id="activityRosterBody"></tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB: BEHAVIOUR CATEGORIES -->
                <div id="tab-behaviour" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Behaviour Categories</h2>
                            <p class="page-subtitle">Set the merit and conduct categories teachers choose from when logging behaviour.</p>
                        </div>
                    </div>
                    <div style="display: grid; grid-template-columns: 1fr 1.5fr; gap: 24px;">
                        <div class="table-card" style="padding: 20px;">
                            <form onsubmit="addBehaviourCategorySubmit(event)">
                                <div class="form-group"><label>Category Name</label><input type="text" id="behaviourCategoryName" class="form-control" placeholder="e.g. Kindness, Late homework" required></div>
                                <div class="form-group"><label>Type</label>
                                    <select id="behaviourCategoryPolarity" class="form-control">
                                        <option value="positive">Merit (positive)</option>
                                        <option value="negative">Conduct note (negative)</option>
                                    </select>
                                </div>
                                <button type="submit" class="btn-primary" style="width: 100%; justify-content: center;">Add Category</button>
                            </form>
                        </div>
                        <div class="table-card">
                            <table class="data-table">
                                <thead><tr><th>Category</th><th>Type</th><th>Actions</th></tr></thead>
                                <tbody id="behaviourCategoriesBody"><tr><td colspan="3" style="text-align:center;padding:20px;">Loading categories…</td></tr></tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- TAB 8: ANNOUNCEMENTS -->
                <div id="tab-announcements" class="tab-pane" data-roles="teacher,admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">School Announcements</h2>
                            <p class="page-subtitle">Publish announcements and circulars to mobile app users</p>
                        </div>
                        <button class="btn-primary" data-roles="admin,teacher" onclick="document.getElementById('announcementForm').requestSubmit()">Publish Announcement</button>
                    </div>

                    <div class="table-card" style="padding: 20px; margin-bottom: 24px;">
                        <h3 class="section-title">New Announcement Form</h3>
                        <form id="announcementForm" onsubmit="handleAnnouncementSubmit(event)">
                        <div class="form-group">
                            <label>Announcement Title</label>
                            <input type="text" id="annTitle" class="form-control" placeholder="e.g. End of Term Parent-Teacher Consultation Meeting" required>
                        </div>
                        <div class="form-group">
                            <label>Target Audience</label>
                            <select id="annAudience" class="form-control">
                                <option value="all">All Users (Guardians & Teachers)</option>
                                <option value="guardian">Guardians Only</option>
                                <option value="teacher">Teachers Only</option>
                            </select>
                        </div>
                        <div class="form-group"><label>School</label><select id="annSchoolId" class="form-control" required></select></div>
                        <div class="form-group">
                            <label>Message Content</label>
                            <textarea id="annContent" class="form-control" rows="4" placeholder="Enter announcement body text here..." required></textarea>
                        </div>
                        </form>
                        <div id="announcementsListContainer" class="table-card" style="margin-top:20px;"></div>
                    </div>
                </div>

                <!-- TAB 9: REPORTS -->
                <div id="tab-reports" class="tab-pane" data-roles="teacher,admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Reports & Academic Documents</h2>
                            <p class="page-subtitle">Upload and issue term report cards and circulars for parents</p>
                        </div>
                        <button class="btn-primary" data-roles="admin,teacher" onclick="openModal('reportModal')">Upload Report Card</button>
                    </div>

                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Student Name</th>
                                    <th>Academic Term / Document</th>
                                    <th>Document Type</th>
                                    <th>Uploaded Date</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="reportsTableBody">
                                <tr>
                                    <td colspan="5" style="text-align:center; padding: 24px; color: var(--text-secondary);">Loading academic reports...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 10: UNIFORM SHOP & ACCOUNTS -->
                <div id="tab-uniforms" class="tab-pane" data-roles="admin">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Uniform Shop & Inventory Management</h2>
                            <p class="page-subtitle">Admin controls for school uniforms, pricing, sizes, inventory stock, and official catalog images</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('uniformModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Add Uniform Item
                        </button>
                    </div>

                    <div class="table-card" style="margin-bottom: 24px;">
                        <h3 class="section-title" style="padding: 16px;">Live Uniform Inventory Catalog (Synchronized with Mobile Apps)</h3>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Visual / Image</th>
                                    <th>Item Details</th>
                                    <th>Category</th>
                                    <th>Pricing (USD / ZiG)</th>
                                    <th>Stock Level</th>
                                    <th>School Scope</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="uniformsTableBody">
                                <tr>
                                    <td colspan="7" style="text-align:center; padding: 24px; color: var(--text-secondary);">Loading uniform catalog...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>
        </main>
    </div>

    <!-- Modal Dialogs -->
    <div class="modal-overlay" id="userModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3>Add New User</h3>
                <button class="modal-close" onclick="closeModal('userModal')">&times;</button>
            </div>
            <form onsubmit="addUserSubmit(event)">
                <div class="modal-body">
                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" id="newUserName" class="form-control" placeholder="e.g. Tendai Mukuru" required>
                    </div>
                    <div class="form-group">
                        <label>Email Address</label>
                        <input type="email" id="newUserEmail" class="form-control" placeholder="e.g. tendai@hillside.ac.zw" required>
                    </div>
                    <div class="form-group">
                        <label>Phone Number</label>
                        <input type="text" id="newUserPhone" class="form-control" placeholder="e.g. +263774444444" required>
                    </div>
                    <div class="form-group">
                        <label>Account Role</label>
                        <select id="newUserRole" class="form-control" required>
                            <option value="teacher">Teacher (Mobile App Access)</option>
                        </select>
                    </div>
                    <p style="margin:12px 0;color:var(--text-secondary);font-size:13px;line-height:1.5;">A password setup link will be emailed to this teacher. They will choose their own password.</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('userModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Create User</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="teacherModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3>Add New Teacher</h3>
                <button class="modal-close" onclick="closeModal('teacherModal')">&times;</button>
            </div>
            <form onsubmit="addTeacherSubmit(event)">
                <div class="modal-body">
                    <div class="form-group">
                        <label>Teacher Name</label>
                        <input type="text" id="tName" class="form-control" placeholder="e.g. Teacher Grace" required>
                    </div>
                    <div class="form-group">
                        <label>Subject Taught</label>
                        <input type="text" id="tSubject" class="form-control" placeholder="e.g. Mathematics" required>
                    </div>
                    <div class="form-group">
                        <label>Assigned Class</label>
                        <select id="tClass" class="form-control" required></select>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" id="tEmail" class="form-control" placeholder="e.g. grace@hillside.ac.zw" required>
                    </div>
                    <div class="form-group">
                        <label>Phone</label>
                        <input type="text" id="tPhone" class="form-control" placeholder="e.g. +263772222222" required>
                    </div>
                    <div class="form-group"><label>School</label><select id="tSchoolId" class="form-control" required></select></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('teacherModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Save Teacher</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="studentModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3>Add New Student</h3>
                <button class="modal-close" onclick="closeModal('studentModal')">&times;</button>
            </div>
            <form onsubmit="addStudentSubmit(event)">
                <div class="modal-body">
                    <div class="form-group" data-roles="admin,teacher">
                        <label>Student Full Name</label>
                        <input type="text" id="sName" class="form-control" placeholder="e.g. Tafadzwa Chewe" required>
                    </div>
                    <div class="form-group" data-roles="admin,teacher">
                        <label>Assigned Class</label>
                        <select id="sClass" class="form-control" required>
                            <option value="">Loading assigned classes…</option>
                        </select>
                    </div>
                    <div class="form-group" data-roles="admin,teacher"><label>Date of Birth (optional)</label><input type="date" id="sDob" class="form-control"></div>
                    <div class="form-group" data-roles="admin,teacher">
                        <label>Guardian Name</label>
                        <input type="text" id="sGuardian" class="form-control" placeholder="e.g. John Chewe (optional)">
                    </div>
                    <div class="form-group" data-roles="admin,teacher"><label>Guardian Email</label><input type="email" id="sGuardianEmail" class="form-control" placeholder="Optional account email"></div>
                    <div class="form-group" data-roles="admin,teacher"><label>Guardian Phone</label><input type="tel" id="sGuardianPhone" class="form-control" placeholder="Optional phone number"></div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('studentModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Enrol Student</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="editStudentModal">
        <div class="modal-card"><div class="modal-header"><h3>Edit Student Record</h3><button class="modal-close" onclick="closeModal('editStudentModal')">&times;</button></div>
            <form onsubmit="editStudentSubmit(event)"><div class="modal-body">
                <input type="hidden" id="editStudentId">
                <div class="form-group"><label>Student Full Name</label><input type="text" id="editStudentName" class="form-control" required></div>
                <div class="form-group"><label>Assigned Class</label><select id="editStudentClass" class="form-control" required></select></div>
                <div class="form-group"><label>Date of Birth (optional)</label><input type="date" id="editStudentDob" class="form-control"></div>
            </div><div class="modal-footer"><button type="button" class="btn-sm" onclick="closeModal('editStudentModal')">Cancel</button><button type="submit" class="btn-primary">Save Student</button></div></form>
        </div>
    </div>

    <div class="modal-overlay" id="classModal">
        <div class="modal-card">
            <div class="modal-header"><h3>Add Grade / Class</h3><button class="modal-close" onclick="closeModal('classModal')">&times;</button></div>
            <form onsubmit="addClassSubmit(event)"><div class="modal-body">
                <div class="form-group"><label>School</label><select id="classSchoolId" class="form-control" required></select></div>
                <div class="form-group"><label>Academic Year</label><select id="classAcademicYearId" class="form-control"><option value="">Current / Unassigned</option></select></div>
                <div class="form-group"><label>Grade</label><input id="classGrade" class="form-control" placeholder="e.g. Grade 1" required></div>
                <div class="form-group"><label>Class / Stream Name</label><input id="className" class="form-control" placeholder="e.g. Grade 1A" required></div>
                <div class="form-group"><label>Capacity</label><input id="classCapacity" type="number" min="1" value="30" class="form-control" required></div>
            </div><div class="modal-footer"><button type="button" class="btn-sm" onclick="closeModal('classModal')">Cancel</button><button type="submit" class="btn-primary">Create Class</button></div></form>
        </div>
    </div>

    <div class="modal-overlay" id="linkGuardianModal">
        <div class="modal-card">
            <div class="modal-header"><h3>Link Guardian to Student</h3><button class="modal-close" onclick="closeModal('linkGuardianModal')">&times;</button></div>
            <form onsubmit="linkGuardianSubmit(event)"><div class="modal-body">
                <div class="form-group"><label>Student</label><select id="linkStudentId" class="form-control" required></select></div>
                <div class="form-group"><label>Guardian Account</label><select id="linkGuardianId" class="form-control" required></select></div>
            </div><div class="modal-footer"><button type="button" class="btn-sm" onclick="closeModal('linkGuardianModal')">Cancel</button><button type="submit" class="btn-primary">Link Guardian</button></div></form>
        </div>
    </div>

    <!-- Onboard School Modal -->
    <div class="modal-overlay" id="onboardSchoolModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3>Onboard New School</h3>
                <button class="modal-close" onclick="closeModal('onboardSchoolModal')">&times;</button>
            </div>
            <form onsubmit="onboardSchoolSubmit(event)">
                <div class="modal-body">
                    <div class="form-group">
                        <label>School Name</label>
                        <input type="text" id="obsName" class="form-control" placeholder="e.g. Hillside Academy" required>
                    </div>
                    <div class="form-group">
                        <label>School Tier / Type</label>
                        <select id="obsType" class="form-control" required>
                            <option value="prep">Preparatory (ECD / Pre-school)</option>
                            <option value="primary" selected>Primary School</option>
                            <option value="secondary">Secondary / High School</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Primary Admin Name</label>
                        <input type="text" id="obsAdminName" class="form-control" placeholder="e.g. Sarah Jenkins">
                    </div>
                    <div class="form-group">
                        <label>Admin Email Address</label>
                        <input type="email" id="obsAdminEmail" class="form-control" placeholder="e.g. admin@academy.ac.zw">
                    </div>
                    <div class="form-group">
                        <label>Admin Phone Contact</label>
                        <input type="text" id="obsAdminPhone" class="form-control" placeholder="e.g. +263771234567">
                    </div>
                    <div class="form-group">
                        <label>Branding Theme Color</label>
                        <input type="color" id="obsColor" class="form-control" value="#3B5998" style="height:44px; padding:2px;">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('onboardSchoolModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Onboard School</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Upload Report Card Modal -->
    <div class="modal-overlay" id="reportModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3>Upload Report Card / Circular</h3>
                <button class="modal-close" onclick="closeModal('reportModal')">&times;</button>
            </div>
            <form onsubmit="uploadReportSubmit(event)">
                <div class="modal-body">
                    <div class="form-group">
                        <label>Select Student</label>
                        <select id="repStudentId" class="form-control" required>
                            <option value="">-- Choose Student --</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Document / Term Title</label>
                        <input type="text" id="repTitle" class="form-control" placeholder="e.g. 2026 Term 1 Progress Report Card" required>
                    </div>
                    <div class="form-group">
                        <label>Document Type</label>
                        <select id="repType" class="form-control" required>
                            <option value="report">Academic Term Report Card</option>
                            <option value="merit">Merit / Commendation Award</option>
                            <option value="certificate">Official Certificate</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Report File (PDF / DOC / Image)</label>
                        <input type="file" id="repFile" class="form-control" accept=".pdf,.doc,.docx,.png,.jpg">
                        <small style="color:var(--text-secondary); display:block; margin-top:4px;">Upload actual report file or leave empty to issue digital record</small>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('reportModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Upload & Publish</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Add Uniform Item Modal -->
    <div class="modal-overlay" id="uniformModal">
        <div class="modal-card" style="max-width: 580px;">
            <div class="modal-header">
                <h3>Add Uniform Storefront Item</h3>
                <button class="modal-close" onclick="closeModal('uniformModal')">&times;</button>
            </div>
            <form onsubmit="addUniformSubmit(event)">
                <div class="modal-body">
                    <div class="form-group">
                        <label>Item Name</label>
                        <input type="text" id="uniName" class="form-control" placeholder="e.g. Official Embroidered School Blazer" required>
                    </div>
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                        <div class="form-group">
                            <label>Category</label>
                            <select id="uniCategory" class="form-control" required>
                                <option value="Formal Wear">Formal Wear</option>
                                <option value="Sports & Physical Ed">Sports & Physical Ed</option>
                                <option value="Accessories & Footwear">Accessories & Footwear</option>
                                <option value="Everyday Essentials">Everyday Essentials</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Target School</label>
                            <select id="uniSchoolId" class="form-control">
                                <option value="">All Schools</option>
                            </select>
                        </div>
                    </div>
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                        <div class="form-group">
                            <label>Price in USD ($)</label>
                            <input type="number" step="0.01" id="uniPriceUsd" class="form-control" placeholder="45.00" oninput="autoCalcZig()" required>
                        </div>
                        <div class="form-group">
                            <label>Price in ZiG</label>
                            <input type="number" step="0.01" id="uniPriceZig" class="form-control" placeholder="585.00">
                        </div>
                    </div>
                    <div style="display:grid; grid-template-columns: 1.5fr 1fr; gap:12px;">
                        <div class="form-group">
                            <label>Available Sizes (comma separated)</label>
                            <input type="text" id="uniSizes" class="form-control" placeholder="e.g. Size 28, Size 30, Size 32, Size 34" value="Size 28, Size 30, Size 32, Size 34">
                        </div>
                        <div class="form-group">
                            <label>Initial Stock Count</label>
                            <input type="number" id="uniStock" class="form-control" value="50" min="0" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea id="uniDescription" class="form-control" rows="2" placeholder="Quality, material details, and specifications..."></textarea>
                    </div>
                    <div class="form-group">
                        <label>Uniform Product Image (Upload File or URL)</label>
                        <input type="file" id="uniImageFile" class="form-control" accept="image/*" style="margin-bottom:6px;">
                        <input type="url" id="uniImageUrl" class="form-control" placeholder="Or enter direct image URL (e.g. https://...)">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('uniformModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Save to Uniform Catalog</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Edit Uniform Item Modal -->
    <div class="modal-overlay" id="editUniformModal">
        <div class="modal-card" style="max-width: 580px;">
            <div class="modal-header">
                <h3>Update Uniform Item & Image</h3>
                <button class="modal-close" onclick="closeModal('editUniformModal')">&times;</button>
            </div>
            <form onsubmit="editUniformSubmit(event)">
                <input type="hidden" id="editUniId">
                <div class="modal-body">
                    <div class="form-group">
                        <label>Item Name</label>
                        <input type="text" id="editUniName" class="form-control" required>
                    </div>
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                        <div class="form-group">
                            <label>Category</label>
                            <select id="editUniCategory" class="form-control" required>
                                <option value="Formal Wear">Formal Wear</option>
                                <option value="Sports & Physical Ed">Sports & Physical Ed</option>
                                <option value="Accessories & Footwear">Accessories & Footwear</option>
                                <option value="Everyday Essentials">Everyday Essentials</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Stock Count</label>
                            <input type="number" id="editUniStock" class="form-control" min="0" required>
                        </div>
                    </div>
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:12px;">
                        <div class="form-group">
                            <label>Price in USD ($)</label>
                            <input type="number" step="0.01" id="editUniPriceUsd" class="form-control" oninput="autoCalcEditZig()" required>
                        </div>
                        <div class="form-group">
                            <label>Price in ZiG</label>
                            <input type="number" step="0.01" id="editUniPriceZig" class="form-control">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Available Sizes (comma separated)</label>
                        <input type="text" id="editUniSizes" class="form-control" placeholder="e.g. Size 28, Size 30, Size 32">
                    </div>
                    <div class="form-group">
                        <label>Description</label>
                        <textarea id="editUniDescription" class="form-control" rows="2" placeholder="Quality and specifications..."></textarea>
                    </div>
                    <div class="form-group">
                        <label>Product Image</label>
                        <div id="editUniImagePreviewContainer" style="margin-bottom:8px;">
                            <img id="editUniImagePreview" src="" alt="Current image" style="max-height:100px; max-width:100%; border-radius:6px; object-fit:contain; border:1px solid #E2E8F0; display:none;">
                        </div>
                        <label style="font-size:12px; color:var(--text-secondary); margin-bottom:4px; display:block;">Upload New Image File (Replaces current):</label>
                        <input type="file" id="editUniImageFile" class="form-control" accept="image/*" style="margin-bottom:6px;">
                        <label style="font-size:12px; color:var(--text-secondary); margin-bottom:4px; display:block;">Or Enter New / Updated Image URL:</label>
                        <input type="url" id="editUniImageUrl" class="form-control" placeholder="https://...">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('editUniformModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Save Changes & Image</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Email & SMTP / SES Gateway Configuration Modal -->
    <div class="modal-overlay" id="mailSettingsModal">
        <div class="modal-card" style="max-width: 660px; max-height: 92vh; display: flex; flex-direction: column;">
            <div class="modal-header" style="background: #1E3A8A; color: white;">
                <div style="display: flex; align-items: center; gap: 8px;">
                    <svg viewBox="0 0 24 24" style="width: 20px; height: 20px; stroke: currentColor; fill: none; stroke-width: 2;"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                    <h3 style="margin: 0; font-size: 16px;">Email & SMTP / SES Configuration</h3>
                </div>
                <button class="modal-close" onclick="closeModal('mailSettingsModal')">&times;</button>
            </div>
            <div style="overflow-y: auto; padding: 20px; flex: 1;">
                <!-- Preset Switcher -->
                <div style="margin-bottom: 20px; background: #F8FAFC; border: 1px solid #E2E8F0; padding: 14px; border-radius: 6px;">
                    <label style="font-weight: 700; font-size: 13px; color: #1E293B; display: block; margin-bottom: 8px;">Select Outbound Delivery Gateway</label>
                    <div style="display: flex; gap: 8px;">
                        <button type="button" id="presetBtnGmail" class="filter-btn active" onclick="applyMailPreset('gmail')" style="flex: 1; padding: 8px 4px; font-weight: 600; text-align: center; font-size: 12px;">
                            Gmail / Google Workspace
                        </button>
                        <button type="button" id="presetBtnSes" class="filter-btn" onclick="applyMailPreset('ses')" style="flex: 1; padding: 8px 4px; font-weight: 600; text-align: center; font-size: 12px;">
                            Amazon SES
                        </button>
                        <button type="button" id="presetBtnCustom" class="filter-btn" onclick="applyMailPreset('custom')" style="flex: 1; padding: 8px 4px; font-weight: 600; text-align: center; font-size: 12px;">
                            Custom SMTP
                        </button>
                    </div>
                    <div id="mailPresetNotice" style="margin-top: 10px; font-size: 12px; line-height: 1.5; color: #334155; background: #EFF6FF; border-left: 3px solid #3B82F6; padding: 8px 12px; border-radius: 4px;">
                        <!-- Filled via JavaScript -->
                    </div>
                </div>

                <form id="mailSettingsForm" onsubmit="saveMailSettingsSubmit(event)">
                    <input type="hidden" id="cfgMailProvider" value="gmail">

                    <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 12px;">
                        <div class="form-group">
                            <label>SMTP Host Server</label>
                            <input type="text" id="cfgMailHost" class="form-control" placeholder="e.g. smtp.gmail.com" value="smtp.gmail.com" required>
                        </div>
                        <div class="form-group">
                            <label>Port</label>
                            <input type="number" id="cfgMailPort" class="form-control" value="587" required>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div class="form-group">
                            <label>Encryption Protocol</label>
                            <select id="cfgMailEncryption" class="form-control">
                                <option value="tls">TLS (STARTTLS - Port 587)</option>
                                <option value="ssl">SSL (SMTPS - Port 465)</option>
                                <option value="none">None (Plain - Port 25)</option>
                            </select>
                        </div>
                        <div class="form-group" id="cfgSesRegionGroup" style="display: none;">
                            <label>Amazon SES Region</label>
                            <select id="cfgSesRegion" class="form-control" onchange="handleSesRegionChange(this.value)">
                                <option value="us-east-1">us-east-1 (N. Virginia)</option>
                                <option value="us-east-2">us-east-2 (Ohio)</option>
                                <option value="eu-west-1">eu-west-1 (Ireland)</option>
                                <option value="af-south-1">af-south-1 (Cape Town)</option>
                                <option value="us-west-2">us-west-2 (Oregon)</option>
                                <option value="eu-central-1">eu-central-1 (Frankfurt)</option>
                            </select>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div class="form-group">
                            <label>Sender Email (From)</label>
                            <input type="email" id="cfgMailFromAddress" class="form-control" placeholder="you@your-school-domain.org" required>
                        </div>
                        <div class="form-group">
                            <label>Sender Display Name</label>
                            <input type="text" id="cfgMailFromName" class="form-control" value="Edu+Connect Guardianship" required>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div class="form-group">
                            <label id="lblMailUsername">SMTP Username / Account</label>
                            <input type="text" id="cfgMailUsername" class="form-control" placeholder="SMTP username or account email">
                        </div>
                        <div class="form-group">
                            <label id="lblMailPassword">Password / App Password</label>
                            <input type="password" id="cfgMailPassword" class="form-control" placeholder="Google App Password (16 chars) or SES SMTP Secret">
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Portal Base URL (Included in Email Links)</label>
                        <input type="url" id="cfgPortalUrl" class="form-control" value="" placeholder="https://your-admin-domain.example">
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 14px;">
                        <button type="submit" class="btn-primary" style="background: #1E3A8A;">Save Email Configuration</button>
                    </div>
                </form>

                <!-- Outbound Test Dispatch Box -->
                <div style="margin-top: 24px; border-top: 1px solid #E2E8F0; padding-top: 18px;">
                    <h4 style="font-size: 13px; font-weight: 700; color: #1E293B; margin-bottom: 6px;">
                        <svg viewBox="0 0 24 24" style="width: 14px; height: 14px; stroke: currentColor; fill: none; stroke-width: 2; vertical-align: middle; margin-right: 4px;"><path d="M22 2L11 13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                        Test Outbound Deliverability
                    </h4>
                    <p style="font-size: 12px; color: #64748b; margin-bottom: 12px;">
                        Send an instant verification email using your current or saved SMTP settings to verify inbox deliverability.
                    </p>
                    <div style="display: flex; gap: 10px; align-items: center;">
                        <input type="email" id="testEmailRecipientInput" class="form-control" placeholder="Recipient email" style="flex: 1;">
                        <button type="button" id="btnSendTestEmail" class="btn-primary" style="background: #0D9488; white-space: nowrap;" onclick="sendTestEmailSubmit()">
                            Send Test Email
                        </button>
                    </div>
                    <div id="testEmailResult" style="margin-top: 12px; font-size: 12px; display: none; padding: 12px; border-radius: 4px; line-height: 1.5;"></div>
                </div>
            </div>
            <div class="modal-footer" style="background: #F8FAFC; border-top: 1px solid #E2E8F0;">
                <button type="button" class="btn-sm" onclick="closeModal('mailSettingsModal')">Close Window</button>
            </div>
        </div>
    </div>

    <!-- JavaScript Handlers -->
    <script>
        let usersList = [];
        let teachersList = [];
        let studentsList = [];
        let schoolsList = [];
        let classesList = [];
        let announcementsList = [];
        let directoryList = [];
        let uniformsList = [];
        let reportsList = [];
        let journalFeedList = [];
        let attendanceRosterList = [];
        let activeRoleFilter = 'all';
        let academicYearsList = [];

        // API Helper with Token Injection
        async function apiFetch(endpoint, options = {}) {
            const token = localStorage.getItem('admin_token');
            const headers = {
                'Accept': 'application/json',
                ...(options.headers || {})
            };
            if (!(options.body instanceof FormData)) {
                headers['Content-Type'] = 'application/json';
            }
            if (token) {
                headers['Authorization'] = 'Bearer ' + token;
            }
            try {
                const res = await fetch(endpoint, { ...options, headers });
                const data = await res.json().catch(() => ({}));
                if (res.status === 401) {
                    localStorage.removeItem('admin_token');
                    localStorage.removeItem('admin_user');
                    document.getElementById('authScreen').classList.remove('hidden');
                }
                return { ok: res.ok, status: res.status, data };
            } catch (err) {
                console.warn('API error at ' + endpoint, err);
                return { ok: false, status: 0, data: { message: err.message } };
            }
        }

        // Keep the login form visible when the session is cleared.
        function switchAuthTab(tab) {
            document.getElementById('tabBtnLogin')?.classList.toggle('active', tab === 'login');
            document.getElementById('tabBtnSignup')?.classList.toggle('active', tab === 'signup');
            document.getElementById('loginForm')?.classList.toggle('active', tab === 'login');
            document.getElementById('signupForm')?.classList.toggle('active', tab === 'signup');
        }

        async function handleLoginSubmit(e) {
            e.preventDefault();
            const usernameOrEmail = document.getElementById('loginEmail').value.trim();
            const password = document.getElementById('loginPassword').value;
            const btn = e.target.querySelector('button[type="submit"]');
            const originalText = btn.innerText;
            btn.innerText = 'LOGGING IN...';
            btn.disabled = true;

            try {
                const res = await apiFetch('/api/auth/login', {
                    method: 'POST',
                    body: JSON.stringify({ email: usernameOrEmail, username: usernameOrEmail, password })
                });

                if (res.ok && res.data.status === 'success' && ['admin', 'website_admin'].includes(res.data.user?.role)) {
                    localStorage.setItem('admin_token', res.data.token);
                    localStorage.setItem('admin_user', JSON.stringify(res.data.user));

                    const name = res.data.user.name || 'Administrator';
                    document.getElementById('headerAdminName').innerText = name;
                document.getElementById('headerAdminRole').innerText = res.data.user.role === 'website_admin' ? 'Platform Owner' : 'School Admin';
                    document.getElementById('headerAvatar').innerText = name.split(' ').map(n=>n[0]).join('').substring(0, 2).toUpperCase();

                    document.getElementById('authScreen').classList.add('hidden');
                    await loadAllDashboardData();
                } else {
                    if (res.ok) { localStorage.removeItem('admin_token'); localStorage.removeItem('admin_user'); }
                    alert(res.ok ? 'This account does not have admin portal access.' : (res.data.message || 'Login failed. Please check your credentials.'));
                }
            } catch (err) {
                alert('Connection error. Please try again.');
            } finally {
                btn.innerText = originalText;
                btn.disabled = false;
            }
        }

        async function requestPasswordReset(event) {
            event.preventDefault();
            const email = document.getElementById('loginEmail').value.trim();
            if (!email) { alert('Enter your account email first, then choose Forgot password.'); document.getElementById('loginEmail').focus(); return false; }
            const res = await apiFetch('/api/auth/forgot-password', { method: 'POST', body: JSON.stringify({ email }) });
            alert(res.data.message || (res.ok ? 'Password reset link sent.' : 'Could not send the reset link.'));
            return false;
        }

        async function handleLogout() {
            if (confirm('Are you sure you want to log out of the Admin Portal?')) {
                try {
                    await apiFetch('/api/auth/logout', { method: 'POST' });
                } catch (_) {}
                localStorage.removeItem('admin_token');
                localStorage.removeItem('admin_user');
                if (document.getElementById('loginForm')) document.getElementById('loginForm').reset();
                switchAuthTab('login');
                document.getElementById('authScreen').classList.remove('hidden');
            }
        }

        // TAB NAVIGATION
        function switchTab(tabId) {
            const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
            const allowedRoles = document.getElementById('tab-' + tabId)?.dataset.roles;
            if (allowedRoles && !allowedRoles.split(',').includes(currentUser.role)) {
                alert('This section is not available for your account role.');
                return;
            }
            document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));

            const targetNav = Array.from(document.querySelectorAll('.nav-link')).find(el => {
                const attr = el.getAttribute('onclick');
                return attr && attr.includes(tabId);
            });
            if (targetNav) targetNav.classList.add('active');

            const targetPane = document.getElementById('tab-' + tabId);
            if (targetPane) targetPane.classList.add('active');
            const loaders = {
                schools: () => Promise.all([loadSchools(), loadClasses(), loadAcademicYears()]),
                announcements: loadAnnouncements,
                activities: loadActivities,
                behaviour: loadBehaviourCategories
            };
            if (loaders[tabId]) loaders[tabId]();
        }

        function updateSchool(schoolName) {
            const el = document.getElementById('displaySchoolName');
            if (el) el.innerText = schoolName;
        }

        // DATA LOADERS FROM REAL DATABASE
        async function loadAllDashboardData() {
            const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
            document.querySelectorAll('.nav-item[data-roles]').forEach(item => {
                const allowed = item.dataset.roles.split(',');
                item.style.display = allowed.includes(currentUser.role) ? '' : 'none';
            });
            document.querySelectorAll('.tab-pane[data-roles]').forEach(pane => {
                pane.style.display = pane.dataset.roles.split(',').includes(currentUser.role) ? '' : 'none';
            });
            document.querySelectorAll('[data-roles]').forEach(control => {
                control.style.display = control.dataset.roles.split(',').includes(currentUser.role) ? '' : 'none';
            });
            const landingTab = currentUser.role === 'website_admin' ? 'platform' : 'dashboard';
            if (currentUser.role === 'teacher') switchTab('attendance');
            else if (currentUser.role === 'website_admin') switchTab('platform');
            else switchTab(landingTab);
            let loaders = [];
            if (currentUser.role === 'website_admin') {
                loaders = [loadSchools(), loadPlatformDirectory()];
            } else if (currentUser.role === 'admin') {
                loaders = [loadAdminStats(), loadUsers(), loadTeachers(), loadStudents(), loadSchools(), loadClasses(), loadAcademicYears(), loadAnnouncements(), loadAttendanceRoster(), loadJournalFeed(), loadReports(), loadUniforms(), loadFeeAccounts(), loadStudentLinkRequests()];
            } else if (currentUser.role === 'teacher') {
                loaders = [loadStudents(), loadClasses(), loadAnnouncements(), loadAttendanceRoster(), loadJournalFeed(), loadReports()];
            }
            await Promise.all(loaders);
            if (currentUser.role === 'admin') recalculateStatistics();
            if (currentUser.role === 'admin') initDashboardCharts();
        }

        // ACTIVITY ROSTERS
        let activeActivityId = null;
        let activityRosterList = [];

        async function loadActivities() {
            const body = document.getElementById('activitiesTableBody');
            if (!body) return;
            const res = await apiFetch('/api/activities');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load activities.')}</td></tr>`;
                return;
            }
            const activities = res.data.activities || [];
            body.innerHTML = activities.length ? activities.map(a => `<tr><td><strong>${escapeTableText(a.title)}</strong><br><small>${escapeTableText(a.description || '')}</small></td><td>${escapeTableText(String(a.activity_date || '').slice(0, 10))}</td><td>${a.roster_count}</td><td>${a.participated_count}</td><td><button class="btn-sm" onclick="openActivityRoster(${a.id})">Roster</button> <button class="btn-sm" onclick="deleteActivity(${a.id})">Delete</button></td></tr>`).join('')
                : '<tr><td colspan="5" style="text-align:center;padding:20px;">No activities yet.</td></tr>';
        }

        async function addActivitySubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/activities', { method: 'POST', body: JSON.stringify({
                title: document.getElementById('activityTitle').value.trim(),
                activity_date: document.getElementById('activityDate').value,
                description: document.getElementById('activityDescription').value.trim() || null
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not create activity.'); return; }
            event.target.reset();
            await loadActivities();
            openActivityRoster(res.data.activity.id);
        }

        async function openActivityRoster(id) {
            const res = await apiFetch(`/api/activities/${id}/roster`);
            if (!res.ok) { alert(res.data.message || 'Could not load roster.'); return; }
            activeActivityId = id;
            activityRosterList = res.data.roster || [];
            document.getElementById('activityRosterTitle').innerText = `Roster · ${res.data.activity?.title || ''}`;
            document.getElementById('activityRosterCard').style.display = '';
            const options = [['', 'Not on roster'], ['present', 'Took part'], ['late', 'Late'], ['absent', 'Absent']];
            document.getElementById('activityRosterBody').innerHTML = activityRosterList.length ? activityRosterList.map(s => {
                const current = s.status || (s.on_roster ? 'present' : '');
                return `<tr><td>${escapeTableText(s.name)}</td><td>${escapeTableText(s.grade)} ${escapeTableText(s.class_name)}</td><td><select class="form-control" id="activityStatus${s.student_id}" style="max-width:180px;">${options.map(([v, l]) => `<option value="${v}" ${v === current ? 'selected' : ''}>${l}</option>`).join('')}</select></td></tr>`;
            }).join('') : '<tr><td colspan="3" style="text-align:center;padding:20px;">No students enrolled.</td></tr>';
        }

        async function saveActivityRoster() {
            if (!activeActivityId) return;
            const records = activityRosterList
                .map(s => ({ student_id: s.student_id, status: document.getElementById(`activityStatus${s.student_id}`)?.value || null, was: s.on_roster }))
                .filter(r => r.status || r.was)
                .map(({ student_id, status }) => ({ student_id, status }));
            if (!records.length) { alert('Choose at least one learner.'); return; }
            const res = await apiFetch(`/api/activities/${activeActivityId}/roster`, { method: 'POST', body: JSON.stringify({ records }) });
            alert(res.data?.message || (res.ok ? 'Roster saved.' : 'Could not save roster.'));
            if (res.ok) await loadActivities();
        }

        async function deleteActivity(id) {
            if (!confirm('Delete this activity and its roster?')) return;
            const res = await apiFetch(`/api/activities/${id}`, { method: 'DELETE' });
            if (!res.ok) { alert(res.data.message || 'Could not delete activity.'); return; }
            if (activeActivityId === id) document.getElementById('activityRosterCard').style.display = 'none';
            await loadActivities();
        }

        // BEHAVIOUR CATEGORIES
        async function loadBehaviourCategories() {
            const body = document.getElementById('behaviourCategoriesBody');
            if (!body) return;
            const res = await apiFetch('/api/behaviour-categories');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="3" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load categories.')}</td></tr>`;
                return;
            }
            const categories = res.data.categories || [];
            body.innerHTML = categories.length ? categories.map(c => `<tr><td>${escapeTableText(c.name)}</td><td><span class="role-badge ${c.polarity === 'positive' ? 'teacher' : 'guardian'}">${c.polarity === 'positive' ? 'Merit' : 'Conduct note'}</span></td><td><button class="btn-sm" onclick="deleteBehaviourCategory(${c.id})">Remove</button></td></tr>`).join('')
                : '<tr><td colspan="3" style="text-align:center;padding:20px;">No categories yet. Teachers can log any category until you add some.</td></tr>';
        }

        async function addBehaviourCategorySubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/behaviour-categories', { method: 'POST', body: JSON.stringify({
                name: document.getElementById('behaviourCategoryName').value.trim(),
                polarity: document.getElementById('behaviourCategoryPolarity').value
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not add category.'); return; }
            event.target.reset();
            await loadBehaviourCategories();
        }

        async function deleteBehaviourCategory(id) {
            if (!confirm('Remove this behaviour category?')) return;
            const res = await apiFetch(`/api/behaviour-categories/${id}`, { method: 'DELETE' });
            if (!res.ok) { alert(res.data.message || 'Could not remove category.'); return; }
            await loadBehaviourCategories();
        }

        async function loadAdminStats() {
            const res = await apiFetch('/api/admin/dashboard-stats');
            if (res.ok && res.data.stats) {
                const s = res.data.stats;
                const kpiStu = document.getElementById('kpiStudents');
                if (kpiStu) kpiStu.innerText = s.total_students.toLocaleString();
                const kpiAtt = document.getElementById('kpiAttendanceRate');
                if (kpiAtt) kpiAtt.innerText = s.attendance_rate + '%';
                const kpiTeach = document.getElementById('kpiTeachers');
                if (kpiTeach) kpiTeach.innerText = s.active_teachers.toLocaleString();
                const kpiCls = document.getElementById('kpiClasses');
                if (kpiCls) kpiCls.innerText = s.total_classes.toLocaleString();
                const schCount = document.getElementById('platformSchoolCount');
                if (schCount) schCount.innerText = s.total_schools.toLocaleString();
                const actSub = document.getElementById('platformActiveSubs');
                if (actSub) actSub.innerText = s.active_subscriptions.toLocaleString();
                const suspSub = document.getElementById('platformSuspendedSubs');
                if (suspSub) suspSub.innerText = s.suspended_subscriptions.toLocaleString();
            }
        }

        async function loadUsers() {
            const res = await apiFetch('/api/users');
            if (res.ok && res.data.users) {
                usersList = res.data.users;
            }
            const guardianSelect = document.getElementById('linkGuardianId');
            if (guardianSelect) guardianSelect.innerHTML = '<option value="">Choose guardian</option>' + usersList.filter(u => u.role === 'guardian').map(u => `<option value="${u.id}">${u.name} (${u.email || u.phone_number || 'No contact'})</option>`).join('');
            renderUsersTable();
        }

        async function loadTeachers() {
            const res = await apiFetch('/api/teachers');
            if (res.ok && res.data.teachers) {
                teachersList = res.data.teachers;
            }
            renderTeachersTable();
            const el = document.getElementById('kpiTeachers');
            if (el) el.innerText = teachersList.length.toString();
        }

        async function loadStudents() {
            const res = await apiFetch('/api/students');
            if (res.ok && res.data.students) {
                studentsList = res.data.students;

                // Populate student selects in Journal and Report modals
                const journalSelect = document.getElementById('journalStudentId');
                if (journalSelect) {
                    journalSelect.innerHTML = '<option value="">-- Select Enrolled Student --</option>' +
                        studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
                }
                const repSelect = document.getElementById('repStudentId');
                if (repSelect) {
                    repSelect.innerHTML = '<option value="">-- Choose Student --</option>' +
                        studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
                }

                // Populate class select in Attendance register
                const attClassSelect = document.getElementById('attClassSelect');
                if (attClassSelect) {
                    const classes = [...new Set(studentsList.map(s => s.class_name).filter(Boolean))];
                    attClassSelect.innerHTML = '<option value="all">All Classes</option>' +
                        classes.map(c => `<option value="${c}">${c}</option>`).join('');
                }
                const linkStudentSelect = document.getElementById('linkStudentId');
                if (linkStudentSelect) linkStudentSelect.innerHTML = '<option value="">Choose student</option>' + studentsList.map(s => `<option value="${s.id}">${s.name} (${s.class_name || s.grade || 'Student'})</option>`).join('');
            }
            renderStudentsTable();
            const el = document.getElementById('kpiStudents');
            if (el) el.innerText = studentsList.length.toString();
        }

        async function loadFeeAccounts() {
            const body = document.getElementById('feeAccountsBody');
            if (!body) return;
            const res = await apiFetch('/api/fees/accounts');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load fee accounts.')}</td></tr>`;
                return;
            }
            await loadPendingPayments();
            const accounts = res.data.accounts || [];
            body.innerHTML = accounts.length ? accounts.map(account => `<tr><td>${escapeTableText(account.name)}</td><td>${escapeTableText(account.grade)} ${escapeTableText(account.class_name)}</td><td><input class="form-control" type="number" min="0" step="0.01" id="feeUsd${account.student_id}" value="${account.balance_usd}" style="max-width:140px;"></td><td><input class="form-control" type="number" min="0" step="0.01" id="feeZig${account.student_id}" value="${account.balance_zig}" style="max-width:140px;"></td><td><button class="btn-sm" onclick="saveFeeAccount(${account.student_id})">Save balances</button></td></tr>`).join('') : '<tr><td colspan="5" style="text-align:center;padding:20px;">No students enrolled at this school.</td></tr>';
        }

        async function loadPendingPayments() {
            let section = document.getElementById('pendingPaymentSection');
            if (!section) {
                section = document.createElement('div'); section.id = 'pendingPaymentSection';
                document.getElementById('feeAccountsBody')?.closest('.table-card')?.after(section);
            }
            const [fees, uniforms] = await Promise.all([apiFetch('/api/fees/payments/pending'), apiFetch('/api/uniform-payments/pending')]);
            if (!fees.ok || !uniforms.ok) { section.textContent = 'Could not load payments awaiting verification.'; return; }
            const rows = [
                ...(fees.data.payments || []).map(p => ({kind:'fee', id:p.id, name:p.fee_account?.student?.name, amount:p.amount, currency:p.currency, method:p.payment_method, reference:p.reference})),
                ...(uniforms.data.orders || []).map(p => ({kind:'uniform', id:p.id, name:p.student?.name, amount:p.total_amount, currency:p.currency, method:p.payment_method, reference:p.payment_reference}))
            ];
            section.innerHTML = `<h3 class="section-title" style="margin-top:24px;">Payments awaiting verification</h3><p>Verify each reference against the actual payment received before confirming.</p><div class="table-card"><table class="data-table"><thead><tr><th>Student</th><th>For</th><th>Amount</th><th>Reference</th><th>Action</th></tr></thead><tbody>${rows.length ? rows.map(p => `<tr><td>${escapeTableText(p.name)}</td><td>${p.kind === 'fee' ? 'School fees' : 'Uniform order'}</td><td>${escapeTableText(p.currency)} ${escapeTableText(p.amount)}</td><td>${escapeTableText(p.method)} ? ${escapeTableText(p.reference)}</td><td><button class="btn-sm" onclick="verifySchoolPayment('${p.kind}',${Number(p.id)})">Confirm received payment</button></td></tr>`).join('') : '<tr><td colspan="5">No payment references awaiting verification.</td></tr>'}</tbody></table></div>`;
        }
        async function verifySchoolPayment(kind, id) {
            if (!confirm('Have you verified this reference and amount against funds actually received by the school?')) return;
            const endpoint = kind === 'fee' ? `/api/fees/payments/${id}/verify` : `/api/uniform-orders/${id}/verify-payment`;
            const res = await apiFetch(endpoint, {method:'POST', body:JSON.stringify({confirmed:true})});
            alert(res.data?.message || (res.ok ? 'Payment verified.' : 'Could not verify payment.'));
            if (res.ok) await loadFeeAccounts();
        }

        async function saveFeeAccount(studentId) {
            const payload = {
                student_id: studentId,
                balance_usd: Number(document.getElementById(`feeUsd${studentId}`)?.value),
                balance_zig: Number(document.getElementById(`feeZig${studentId}`)?.value)
            };
            const res = await apiFetch('/api/fees/update-balance', { method: 'POST', body: JSON.stringify(payload) });
            alert(res.data?.message || (res.ok ? 'Fee account saved.' : 'Could not update fee account.'));
            if (res.ok) await loadFeeAccounts();
        }

        function escapeTableText(value) {
            return String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
        }

        async function loadStudentLinkRequests() {
            const body = document.getElementById('studentLinkRequestsBody');
            if (!body) return;
            const res = await apiFetch('/api/students/link-requests');
            if (!res.ok) {
                body.innerHTML = `<tr><td colspan="5" style="text-align:center;padding:20px;">${escapeTableText(res.data?.message || 'Could not load requests.')}</td></tr>`;
                return;
            }
            const requests = res.data.requests || [];
            if (!requests.length) {
                body.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--text-secondary);">No pending guardian requests.</td></tr>';
                return;
            }
            body.innerHTML = requests.map(request => {
                const candidates = studentsList.filter(student => student.name?.trim().toLowerCase() === request.student_name.trim().toLowerCase()
                    && (!request.school_name || student.school?.name?.trim().toLowerCase() === request.school_name.trim().toLowerCase()));
                const choice = `<select class="form-control" id="linkRequestStudent${request.id}"><option value="">Select matching student</option>${candidates.map(student => `<option value="${student.id}">${escapeTableText(student.name)} · ${escapeTableText(student.class_name || student.grade || 'Student')}</option>`).join('')}</select>`;
                return `<tr><td>${escapeTableText(request.guardian_name)}<br><small>${escapeTableText(request.guardian_email)}</small></td><td>${escapeTableText(request.student_name)}</td><td>${escapeTableText(request.school_name || 'Any school')}</td><td>${escapeTableText(request.relationship || 'Guardian')}<br><small>${escapeTableText(request.notes || '')}</small></td><td>${choice}<button class="btn-sm" style="margin-top:6px;" onclick="reviewStudentLinkRequest(${request.id}, 'approve')" ${candidates.length ? '' : 'disabled'}>Approve & Link</button> <button class="btn-sm" style="margin-top:6px;" onclick="reviewStudentLinkRequest(${request.id}, 'reject')">Reject</button></td></tr>`;
            }).join('');
        }

        async function reviewStudentLinkRequest(id, decision) {
            const payload = { decision };
            if (decision === 'approve') {
                payload.student_id = document.getElementById(`linkRequestStudent${id}`)?.value;
                if (!payload.student_id) return alert('Choose the matching student before approving.');
            }
            const res = await apiFetch(`/api/students/link-requests/${id}/review`, { method: 'POST', body: JSON.stringify(payload) });
            alert(res.data?.message || (res.ok ? 'Request updated.' : 'Could not update request.'));
            if (res.ok) await loadStudentLinkRequests();
        }

        async function loadSchools() {
            const res = await apiFetch('/api/schools');
            if (res.ok && res.data.schools) {
                schoolsList = res.data.schools;

                const uniSchoolSelect = document.getElementById('uniSchoolId');
                if (uniSchoolSelect) {
                    uniSchoolSelect.innerHTML = '<option value="">All Schools</option>' +
                        schoolsList.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
                }
                ['classSchoolId', 'tSchoolId', 'annSchoolId'].forEach(id => {
                    const select = document.getElementById(id);
                    if (select) select.innerHTML = '<option value="">Select school</option>' + schoolsList.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
                });
                const countEl = document.getElementById('platformSchoolCount');
                if (countEl) countEl.innerText = schoolsList.length.toString();
                if (schoolsList.length > 0) updateSchool(schoolsList[0].name);
                const platformSchoolFilter = document.getElementById('platformSchoolFilter');
                if (platformSchoolFilter) {
                    platformSchoolFilter.innerHTML = '<option value="all">All schools</option>' + schoolsList.map(s => `<option value="${s.id}">${escapeTableText(s.name)}</option>`).join('');
                }

                const dirBody = document.getElementById('platformDirectoryBody');
                if (dirBody) {
                    dirBody.innerHTML = schoolsList.map(s => `
                        <tr>
                            <td><strong>${s.name}</strong></td>
                            <td><span class="badge" style="background:#DBEAFE; color:#1E40AF;">${(s.type || 'primary').toUpperCase()}</span></td>
                            <td>${s.primary_admin_name || 'Not assigned'}${s.primary_admin_email ? ` (${s.primary_admin_email})` : ''}</td>
                            <td><span style="display:inline-block; width:14px; height:14px; background:${s.branding_color || '#3B5998'}; border-radius:50%; vertical-align:middle; margin-right:4px;"></span> ${s.branding_color || '#3B5998'}</td>
                            <td>${Number(s.students_count || 0)} Children</td>
                            <td><button class="btn-sm" onclick="filterPlatformStudents(${s.id})">View Students</button></td>
                        </tr>
                    `).join('');
                }
            }
        }

        async function loadClasses() {
            const res = await apiFetch('/api/school-classes');
            if (res.ok && res.data.school_classes) {
                classesList = res.data.school_classes;
                const classSelect = document.getElementById('sClass');
                if (classSelect) {
                    classSelect.innerHTML = '<option value="">Select assigned class</option>' + classesList.map(c => `<option value="${c.id}">${c.class_name} (${c.grade})</option>`).join('');
                }
                const teacherClassSelect = document.getElementById('tClass');
                if (teacherClassSelect) teacherClassSelect.innerHTML = '<option value="">Select class</option>' + classesList.map(c => `<option value="${c.class_name}" data-school="${c.school_id}">${c.class_name} (${c.grade})</option>`).join('');
                const countEl = document.getElementById('kpiClasses');
                if (countEl) countEl.innerText = classesList.length.toString();

                const classesTbody = document.getElementById('classesTableBody');
                if (classesTbody) {
                    classesTbody.innerHTML = classesList.length ? classesList.map(c => `
                        <tr>
                            <td><strong>${c.class_name}</strong></td>
                            <td>${c.grade || 'Primary'}</td>
                            <td>Unassigned</td>
                            <td>${studentsList ? studentsList.filter(s => s.class_name === c.class_name).length : 0} Students</td>
                            <td><button class="btn-sm" onclick="filterAttendanceClass('${String(c.class_name).replace(/'/g, "\\'")}')">View Register</button></td>
                        </tr>
                    `).join('') : '<tr><td colspan="5" style="text-align:center;padding:20px;">No classes configured</td></tr>';
                }
            }
        }

        function filterAttendanceClass(className) {
            switchTab('attendance');
            const select = document.getElementById('attClassSelect');
            if (select) {
                const classOption = Array.from(select.options).find(option => option.value === className);
                if (classOption) select.value = className;
                loadAttendanceRoster();
            }
        }

        async function addClassSubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/school-classes', { method: 'POST', body: JSON.stringify({
                school_id: document.getElementById('classSchoolId').value,
                academic_year_id: document.getElementById('classAcademicYearId').value || null,
                grade: document.getElementById('classGrade').value.trim(),
                class_name: document.getElementById('className').value.trim(),
                capacity: Number(document.getElementById('classCapacity').value)
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not create class.'); return; }
            event.target.reset(); closeModal('classModal'); await loadClasses(); alert('Class created successfully.');
        }

        async function setAcademicYearCurrent(id) {
            const res = await apiFetch(`/api/academic-years/${id}/set-current`, { method: 'POST' });
            if (!res.ok) { alert(res.data.message || 'Could not update academic year.'); return; }
            await loadAcademicYears();
        }

        async function linkGuardianSubmit(event) {
            event.preventDefault();
            const res = await apiFetch('/api/students/link-guardian', { method: 'POST', body: JSON.stringify({
                student_id: document.getElementById('linkStudentId').value,
                guardian_id: document.getElementById('linkGuardianId').value
            }) });
            if (!res.ok) { alert(res.data.message || 'Could not link guardian.'); return; }
            closeModal('linkGuardianModal'); await loadStudents(); alert(res.data.message || 'Guardian linked.');
        }

        async function loadAcademicYears() {
            const res = await apiFetch('/api/academic-years');
            if (!res.ok) return;
            academicYearsList = res.data.academic_years || [];
            const select = document.getElementById('classAcademicYearId');
            if (select) select.innerHTML = '<option value="">Current / Unassigned</option>' + academicYearsList.map(y => `<option value="${y.id}">${y.name}${y.is_current ? ' (Current)' : ''}</option>`).join('');
            const body = document.getElementById('academicYearsTableBody');
            if (body) body.innerHTML = academicYearsList.length ? academicYearsList.map(y => `<tr><td><strong>${y.name}</strong></td><td>Academic Year</td><td>${y.start_date ? String(y.start_date).slice(0,10) : '—'}</td><td>${y.end_date ? String(y.end_date).slice(0,10) : '—'}</td><td><span class="role-badge ${y.is_current ? 'teacher' : 'guardian'}">${y.is_current ? 'Current' : 'Inactive'}</span></td><td>${y.is_current ? '<span class="btn-sm" aria-label="Current academic year">Current</span>' : `<button class="btn-sm" onclick="setAcademicYearCurrent(${y.id})">Set Current</button>`}</td></tr>`).join('') : '<tr><td colspan="6" style="text-align:center;padding:20px;">No academic years configured</td></tr>';
        }

        async function loadAnnouncements() {
            const res = await apiFetch('/api/announcements');
            if (res.ok && res.data.announcements) {
                announcementsList = res.data.announcements;
                renderAnnouncementsList();
            }
        }

        async function loadPlatformDirectory() {
            const res = await apiFetch('/api/platform/directory');
            if (res.ok && res.data.directory) {
                directoryList = res.data.directory;
                renderPlatformDirectoryTable();
            }
        }

        function renderUsersTable() {
            const tbody = document.getElementById('usersTableBody');
            if (!tbody) return;
            const searchInput = document.getElementById('userSearchInput');
            const search = searchInput ? searchInput.value.toLowerCase() : '';

            let filtered = usersList;
            if (activeRoleFilter !== 'all') {
                filtered = filtered.filter(u => u.role === activeRoleFilter);
            }
            if (search) {
                filtered = filtered.filter(u =>
                    (u.name && u.name.toLowerCase().includes(search)) ||
                    (u.email && u.email.toLowerCase().includes(search)) ||
                    (u.phone_number && u.phone_number.includes(search))
                );
            }

            if (filtered.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No matching users found</td></tr>';
            } else {
                tbody.innerHTML = filtered.map(u => {
                    const hasEmail = Boolean(u.email && u.email.trim() !== '');
                    const safeEmail = JSON.stringify(u.email || '');
                    const emailBtn = hasEmail ?
                        `<button class="btn-sm" style="background:#2563EB; color:white; border:none; margin-right:4px;" onclick='sendUserPasswordLink(${u.id}, ${safeEmail})' title="Send password creation link for mobile app access">Send Setup Link</button>` :
                        `<button class="btn-sm" style="opacity:0.4; margin-right:4px;" disabled title="No email address">No Email</button>`;
                    return `
                        <tr>
                            <td>#${u.id}</td>
                            <td><strong>${u.name || 'Unnamed'}</strong></td>
                            <td>${hasEmail ? u.email : '<span style="color:#94a3b8; font-style:italic;">None</span>'}</td>
                            <td>${u.phone_number || 'N/A'}</td>
                            <td><span class="role-badge ${u.role}">${u.role}</span></td>
                            <td>
                                ${emailBtn}
                                <button class="btn-sm btn-danger" onclick="deleteUser(${u.id})">Delete</button>
                            </td>
                        </tr>
                    `;
                }).join('');
            }
        }

        function filterUserRole(role, btn) {
            activeRoleFilter = role;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderUsersTable();
        }

        function renderTeachersTable() {
            const tbody = document.getElementById('teachersTableBody');
            if (!tbody) return;
            if (teachersList.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No teachers registered yet</td></tr>';
                return;
            }
            tbody.innerHTML = teachersList.map(t => {
                const name = t.user ? t.user.name : (t.name || 'Teacher');
                const email = t.user ? t.user.email : (t.email || 'N/A');
                const phone = t.user ? t.user.phone_number : (t.phone || 'N/A');
                const subjects = Array.isArray(t.subject_specialties) ? t.subject_specialties.join(', ') : (t.subject || 'General');
                const assignedClasses = Array.isArray(t.assigned_classes) ? t.assigned_classes.map(c => c.class_name).join(', ') : (t.assignedClasses || []).map(c => c.class_name).join(', ');
                return `
                    <tr>
                        <td><strong>${name}</strong></td>
                        <td>${subjects}</td>
                        <td>${assignedClasses || 'Unassigned'}</td>
                        <td>${email}</td>
                        <td>${phone}</td>
                        <td>
                            <button class="btn-sm" onclick="switchTab('users')">Manage Account</button>
                        </td>
                    </tr>
                `;
            }).join('');
        }

        function renderStudentsTable() {
            const tbody = document.getElementById('studentsTableBody');
            if (!tbody) return;
            const currentRole = JSON.parse(localStorage.getItem('admin_user') || '{}').role;
            if (studentsList.length === 0) {
                tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding: 24px; color: var(--text-secondary);">No enrolled students found</td></tr>';
                return;
            }
            tbody.innerHTML = studentsList.map((s, idx) => {
                const reg = s.reg || `STU-${String(s.id || idx + 1).padStart(3, '0')}`;
                const guardianName = (s.guardians && s.guardians.length > 0) ? s.guardians.map(g => g.name).join(', ') : 'Not linked';
                return `
                    <tr>
                        <td><code>${reg}</code></td>
                        <td><strong>${s.name}</strong></td>
                        <td>${s.class_name || 'Class A'}</td>
                        <td>${guardianName}</td>
                        <td><span class="role-badge primary">${s.grade || 'Primary'}</span></td>
                        <td><strong style="color:var(--text-secondary);">—</strong></td>
                        <td>${currentRole === 'admin' ? `<button class="btn-sm" onclick="openEditStudent(${s.id})">Edit</button> <button class="btn-sm" onclick="openModal('linkGuardianModal')">Link Guardian</button>` : 'Assigned class roster'}</td>
                    </tr>
                `;
            }).join('');
        }

        function renderAnnouncementsList() {
            const container = document.getElementById('announcementsListContainer');
            if (!container) return;
            if (announcementsList.length === 0) {
                container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding:20px;">No announcements posted yet.</p>';
                return;
            }
            container.innerHTML = announcementsList.map(a => `
                <div style="padding:16px; border-bottom:1px solid var(--border-color);">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px;">
                        <h4 style="color:var(--primary-blue); font-size:15px; margin:0;">${a.title}</h4>
                        <span style="font-size:11px; color:var(--text-secondary);">${new Date(a.created_at || Date.now()).toLocaleDateString()}</span>
                    </div>
                    <p style="font-size:13px; color:var(--text-primary); margin:0;">${a.content}</p>
                </div>
            `).join('');
        }

        function renderPlatformDirectoryTable() {
            const tbody = document.getElementById('subscriptionControlBody');
            if (!tbody) return;
            const selectedSchoolId = document.getElementById('platformSchoolFilter')?.value || 'all';
            const visibleDirectory = selectedSchoolId === 'all' ? directoryList : directoryList.filter(student => String(student.school_id) === String(selectedSchoolId));
            const activeCount = directoryList.filter(student => student.subscription_status === 'active').length;
            const suspendedCount = directoryList.length - activeCount;
            const actEl = document.getElementById('platformActiveSubs');
            if (actEl) actEl.innerText = activeCount.toString();
            const suspEl = document.getElementById('platformSuspendedSubs');
            if (suspEl) suspEl.innerText = suspendedCount.toString();
            if (visibleDirectory.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px; color: var(--text-secondary);">No enrolled students found for subscription control</td></tr>';
                return;
            }

            tbody.innerHTML = visibleDirectory.map(d => {
                const isActive = d.subscription_status === 'active';

                return `
                    <tr>
                        <td><strong>${d.student_name}</strong></td>
                        <td>${d.school_name || 'School'} (${d.grade} ${d.class_name || ''})</td>
                        <td>${d.guardian_name || 'Guardian'} (${d.guardian_phone || 'N/A'})</td>
                        <td>
                            <span class="badge" style="background:${isActive ? '#DCFCE7' : '#FEE2E2'}; color:${isActive ? '#15803D' : '#B91C1C'}; font-weight:600;">
                                ${isActive ? 'ACTIVE' : 'SUSPENDED'}
                            </span>
                        </td>
                        <td><label style="font-size:11px;">From <input type="date" id="subscriptionStart${d.student_id}" value="${d.subscription_start || new Date().toISOString().slice(0,10)}" class="form-control" style="width:145px;padding:5px;margin:2px 0;"></label><label style="font-size:11px;">Until <input type="date" id="subscriptionEnd${d.student_id}" value="${d.subscription_end || ''}" class="form-control" style="width:145px;padding:5px;margin:2px 0;"></label></td>
                        <td>
                            <button class="btn-sm ${isActive ? 'btn-danger' : ''}" onclick="toggleChildSubscription(${d.student_id}, '${isActive ? 'inactive' : 'active'}')">
                                ${isActive ? 'Suspend Access' : 'Activate Access'}
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');

        }

        function filterPlatformStudents(schoolId) {
            const select = document.getElementById('platformSchoolFilter');
            if (select) select.value = String(schoolId);
            renderPlatformDirectoryTable();
            document.getElementById('subscriptionControlBody')?.closest('.table-card')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        function openModal(id) {
            const el = document.getElementById(id);
            if (el) el.classList.add('open');
        }

        function closeModal(id) {
            const el = document.getElementById(id);
            if (el) el.classList.remove('open');
        }

        async function addUserSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('newUserName').value.trim();
            const email = document.getElementById('newUserEmail').value.trim();
            const phone = document.getElementById('newUserPhone').value.trim();
            const role = document.getElementById('newUserRole').value;
            const password = document.getElementById('newUserPassword') ? document.getElementById('newUserPassword').value.trim() : '';
            const sendInvite = true;

            const payload = {
                name,
                email,
                phone_number: phone,
                role,
                send_invite: sendInvite
            };
            if (currentUser.role === 'admin' && role === 'teacher') payload.school_id = currentUser.school_id;
            if (password) {
                payload.password = password;
            }

            const res = await apiFetch('/api/users', {
                method: 'POST',
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                closeModal('userModal');
                document.getElementById('newUserName').value = '';
                document.getElementById('newUserEmail').value = '';
                document.getElementById('newUserPhone').value = '';
                if (document.getElementById('newUserPassword')) document.getElementById('newUserPassword').value = '';
                await loadUsers();

                let successMsg = `New ${role.toUpperCase()} "${name}" successfully created!`;
                if (res.data.email_sent) {
                    successMsg += `\n\nA password setup link has been emailed to ${email} for mobile app access.`;
                } else if (email && sendInvite) {
                    successMsg += `\n\nEmail dispatch status: ${res.data.message}`;
                }
                alert(successMsg);
            } else {
                alert(res.data.message || 'Failed to create user in database.');
            }
        }


        // ==========================================
        // EMAIL & SMTP / SES MANAGEMENT FUNCTIONS
        // ==========================================
        async function openMailSettingsModal() {
            openModal('mailSettingsModal');
            const res = await apiFetch('/api/settings/mail');
            if (res.ok && res.data.settings) {
                const s = res.data.settings;
                document.getElementById('cfgMailProvider').value = s.mail_provider || 'gmail';
                document.getElementById('cfgMailHost').value = s.mail_host || 'smtp.gmail.com';
                document.getElementById('cfgMailPort').value = s.mail_port || 587;
                document.getElementById('cfgMailEncryption').value = s.mail_encryption || 'tls';
                document.getElementById('cfgMailFromAddress').value = s.mail_from_address || '';
                document.getElementById('cfgMailFromName').value = s.mail_from_name || 'Edu+Connect Guardianship';
                document.getElementById('cfgMailUsername').value = s.mail_username || '';
                document.getElementById('cfgMailPassword').value = s.mail_password || '';
                if (document.getElementById('cfgSesRegion')) document.getElementById('cfgSesRegion').value = s.mail_ses_region || 'us-east-1';
                if (document.getElementById('cfgPortalUrl')) document.getElementById('cfgPortalUrl').value = s.portal_access_url || '';
                if (document.getElementById('testEmailRecipientInput') && !document.getElementById('testEmailRecipientInput').value) {
                    document.getElementById('testEmailRecipientInput').value = s.mail_from_address || '';
                }
                updateMailPresetUi(s.mail_provider || 'gmail');
            } else {
                updateMailPresetUi('gmail');
            }
        }

        function updateMailPresetUi(provider) {
            document.querySelectorAll('#presetBtnGmail, #presetBtnSes, #presetBtnCustom').forEach(b => b.classList.remove('active'));
            const noticeEl = document.getElementById('mailPresetNotice');
            const sesGroup = document.getElementById('cfgSesRegionGroup');

            if (provider === 'gmail') {
                document.getElementById('presetBtnGmail')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'none';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Google / Gmail SMTP:</strong> Use your verified sender address, SMTP username, and a Google app password. Save the settings before sending invitations.`;
                }
            } else if (provider === 'ses') {
                document.getElementById('presetBtnSes')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'block';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Amazon SES:</strong> Configure region-specific SMTP credentials and a verified sender identity before sending invitations.`;
                }
            } else {
                document.getElementById('presetBtnCustom')?.classList.add('active');
                if (sesGroup) sesGroup.style.display = 'none';
                if (noticeEl) {
                    noticeEl.innerHTML = `<strong>Custom SMTP Active:</strong> Standard SMTP delivery using your custom host, port, authentication credentials and encryption parameters.`;
                }
            }
        }

        function applyMailPreset(provider) {
            document.getElementById('cfgMailProvider').value = provider;
            updateMailPresetUi(provider);

            if (provider === 'gmail') {
                document.getElementById('cfgMailHost').value = 'smtp.gmail.com';
                document.getElementById('cfgMailPort').value = '587';
                document.getElementById('cfgMailEncryption').value = 'tls';
                if (!document.getElementById('cfgMailFromAddress').value) {
                    document.getElementById('cfgMailFromAddress').value = '';
                }
                if (!document.getElementById('cfgMailUsername').value) {
                    document.getElementById('cfgMailUsername').value = '';
                }
            } else if (provider === 'ses') {
                const region = document.getElementById('cfgSesRegion')?.value || 'us-east-1';
                document.getElementById('cfgMailHost').value = `email-smtp.${region}.amazonaws.com`;
                document.getElementById('cfgMailPort').value = '587';
                document.getElementById('cfgMailEncryption').value = 'tls';
                if (!document.getElementById('cfgMailFromAddress').value) {
                    document.getElementById('cfgMailFromAddress').value = '';
                }
            }
        }

        function handleSesRegionChange(region) {
            if (document.getElementById('cfgMailProvider').value === 'ses') {
                document.getElementById('cfgMailHost').value = `email-smtp.${region}.amazonaws.com`;
            }
        }

        async function saveMailSettingsSubmit(e) {
            e.preventDefault();
            const payload = {
                mail_provider: document.getElementById('cfgMailProvider').value,
                mail_host: document.getElementById('cfgMailHost').value.trim(),
                mail_port: parseInt(document.getElementById('cfgMailPort').value) || 587,
                mail_encryption: document.getElementById('cfgMailEncryption').value,
                mail_from_address: document.getElementById('cfgMailFromAddress').value.trim(),
                mail_from_name: document.getElementById('cfgMailFromName').value.trim(),
                mail_username: document.getElementById('cfgMailUsername').value.trim(),
                mail_password: document.getElementById('cfgMailPassword').value.trim(),
                mail_ses_region: document.getElementById('cfgSesRegion')?.value || 'us-east-1',
                portal_access_url: document.getElementById('cfgPortalUrl')?.value.trim() || null
            };

            const res = await apiFetch('/api/settings/mail', {
                method: 'POST',
                body: JSON.stringify(payload)
            });

            if (res.ok) {
                alert('Email gateway settings saved successfully!');
            } else {
                alert(res.data.message || 'Failed to save email settings.');
            }
        }

        async function sendTestEmailSubmit() {
            const btn = document.getElementById('btnSendTestEmail');
            const resultBox = document.getElementById('testEmailResult');
            const recipient = document.getElementById('testEmailRecipientInput').value.trim();

            if (!recipient) {
                alert('Please provide a recipient email address.');
                return;
            }

            btn.disabled = true;
            btn.innerText = 'Connecting & Sending...';
            resultBox.style.display = 'block';
            resultBox.style.background = '#F8FAFC';
            resultBox.style.color = '#475569';
            resultBox.style.border = '1px solid #CBD5E1';
            resultBox.innerHTML = '<em>Connecting to mail host and attempting delivery...</em>';

            const res = await apiFetch('/api/settings/mail/test', {
                method: 'POST',
                body: JSON.stringify({ recipient })
            });

            btn.disabled = false;
            btn.innerText = 'Send Test Email';

            if (res.ok) {
                resultBox.style.background = '#DCFCE7';
                resultBox.style.color = '#15803D';
                resultBox.style.border = '1px solid #86EFAC';
                resultBox.innerHTML = `<strong>Verification Success:</strong> ${res.data.message || 'Test email dispatched and accepted!'}`;
            } else {
                resultBox.style.background = '#FEE2E2';
                resultBox.style.color = '#B91C1C';
                resultBox.style.border = '1px solid #FCA5A5';
                resultBox.innerHTML = `<strong>Delivery Failed:</strong> ${res.data.message || 'Failed to dispatch email.'}`;
            }
        }

        async function sendUserPasswordLink(userId, userEmail) {
            if (!confirm(`Send mobile app password creation link to "${userEmail}"?`)) {
                return;
            }

            const res = await apiFetch(`/api/users/${userId}/send-link`, {
                method: 'POST',
                body: JSON.stringify({})
            });

            if (res.ok) {
                alert(`Password link dispatched successfully to ${userEmail}!\n\nThe user can now open the link in their email to create their password and sign in to the mobile application.`);
            } else {
                alert(res.data.message || 'Failed to dispatch password setup email. Please verify SMTP gateway settings.');
            }
        }

        async function deleteUser(id) {
            if (confirm('Are you sure you want to delete user #' + id + '?')) {
                const res = await apiFetch(`/api/users/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadUsers();
                    alert('User #' + id + ' deleted from database.');
                } else {
                    alert(res.data.message || 'Could not delete user.');
                }
            }
        }

        async function addTeacherSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('tName').value.trim();
            const subject = document.getElementById('tSubject').value.trim();
            const className = document.getElementById('tClass').value.trim();
            const email = document.getElementById('tEmail').value.trim();
            const phone = document.getElementById('tPhone').value.trim();
            const schoolId = document.getElementById('tSchoolId').value;
            if (!schoolId) { alert('Create a school before adding a teacher.'); return; }
            const selectedClass = classesList.find(item => String(item.class_name) === className && String(item.school_id) === String(schoolId));
            if (!selectedClass) { alert('Select a class at the teacher\'s school.'); return; }

            const res = await apiFetch('/api/teachers', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    email,
                    phone,
                    school_id: Number(schoolId),
                    subject_specialties: [subject],
                    class_name: className
                })
            });

            if (res.ok) {
                closeModal('teacherModal');
                await loadTeachers();
                alert('Teacher "' + name + '" saved to database!');
            } else {
                alert(res.data.message || 'Failed to save teacher.');
            }
        }

        async function addStudentSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('sName').value.trim();
            const classId = document.getElementById('sClass').value;
            const guardian = document.getElementById('sGuardian').value.trim();
            const selectedClass = classesList.find(item => String(item.id) === String(classId));
            if (!selectedClass) { alert('Select a class for this student.'); return; }

            const res = await apiFetch('/api/students', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    class_id: Number(classId),
                    dob: document.getElementById('sDob')?.value || null,
                    guardian_name: guardian || null,
                    guardian_email: document.getElementById('sGuardianEmail')?.value.trim() || null,
                    guardian_phone: document.getElementById('sGuardianPhone')?.value.trim() || null
                })
            });

            if (res.ok) {
                closeModal('studentModal');
                await loadStudents();
                const currentRole = JSON.parse(localStorage.getItem('admin_user') || '{}').role;
                if (currentRole === 'admin') {
                    await loadUsers();
                    recalculateStatistics();
                }
                alert('Student "' + name + '" enrolled in database!');
            } else {
                alert(res.data.message || 'Failed to enroll student.');
            }
        }

        function openEditStudent(studentId) {
            const student = studentsList.find(item => Number(item.id) === Number(studentId));
            if (!student) return alert('Student record is no longer available.');
            document.getElementById('editStudentId').value = student.id;
            document.getElementById('editStudentName').value = student.name || '';
            document.getElementById('editStudentDob').value = student.dob ? String(student.dob).slice(0, 10) : '';
            const select = document.getElementById('editStudentClass');
            select.innerHTML = '<option value="">Select class</option>' + classesList.map(item => `<option value="${item.id}" ${item.class_name === student.class_name && item.grade === student.grade ? 'selected' : ''}>${escapeTableText(item.class_name)} (${escapeTableText(item.grade)})</option>`).join('');
            openModal('editStudentModal');
        }

        async function editStudentSubmit(event) {
            event.preventDefault();
            const studentId = document.getElementById('editStudentId').value;
            const res = await apiFetch(`/api/students/${studentId}`, { method: 'PUT', body: JSON.stringify({
                name: document.getElementById('editStudentName').value.trim(),
                class_id: Number(document.getElementById('editStudentClass').value),
                dob: document.getElementById('editStudentDob').value || null
            }) });
            if (!res.ok) return alert(res.data?.message || 'Could not update student record.');
            closeModal('editStudentModal');
            await loadStudents();
            alert(res.data.message || 'Student record updated.');
        }

        async function onboardSchoolSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('obsName').value.trim();
            const type = document.getElementById('obsType').value;
            const adminName = document.getElementById('obsAdminName').value.trim();
            const adminEmail = document.getElementById('obsAdminEmail').value.trim();
            const adminPhone = document.getElementById('obsAdminPhone').value.trim();
            const color = document.getElementById('obsColor').value;

            const res = await apiFetch('/api/platform/schools', {
                method: 'POST',
                body: JSON.stringify({
                    name,
                    type,
                    primary_admin_name: adminName,
                    primary_admin_email: adminEmail,
                    primary_admin_phone: adminPhone,
                    branding_color: color
                })
            });

            if (res.ok) {
                closeModal('onboardSchoolModal');
                await loadSchools();
                await loadPlatformDirectory();
                await loadAdminStats();
                alert(`School "${name}" onboarded successfully.${res.data.admin_invitation_message ? ` ${res.data.admin_invitation_message}` : ''}`);
            } else {
                alert(res.data.message || 'Failed to onboard school.');
            }
        }

        async function toggleChildSubscription(studentId, targetStatus) {
            const actionLabel = targetStatus === 'inactive' ? 'SUSPEND' : 'ACTIVATE';
            if (confirm(`Are you sure you want to ${actionLabel} subscription access for student #${studentId}?`)) {
                const today = new Date().toISOString().slice(0, 10);
                let startDate = document.getElementById(`subscriptionStart${studentId}`)?.value || today;
                let endDate = document.getElementById(`subscriptionEnd${studentId}`)?.value || null;
                if (startDate < today) startDate = today;
                if (endDate && endDate < today) endDate = null;
                const res = await apiFetch('/api/platform/subscriptions/toggle', {
                    method: 'POST',
                    body: JSON.stringify({
                        student_id: studentId,
                        status: targetStatus,
                        start_date: startDate,
                        end_date: endDate
                    })
                });
                if (res.ok) {
                    await loadPlatformDirectory();
                    alert(`Subscription successfully updated to ${targetStatus.toUpperCase()}.`);
                } else {
                    alert(res.data.message || 'Failed to toggle subscription.');
                }
            }
        }

        // ================= ATTENDANCE REGISTER =================
        async function loadAttendanceRoster() {
            const dateInput = document.getElementById('attDate');
            if (dateInput && !dateInput.value) {
                dateInput.value = new Date().toISOString().split('T')[0];
            }
            const date = dateInput ? dateInput.value : '';
            const classSelect = document.getElementById('attClassSelect');
            const className = classSelect ? classSelect.value : 'all';

            const tbody = document.getElementById('attendanceRosterBody');
            if (tbody) {
                tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding:20px; color:var(--text-secondary);">Loading student register...</td></tr>';
            }

            const res = await apiFetch(`/api/attendance/roster?date=${encodeURIComponent(date)}&class_name=${encodeURIComponent(className)}`);
            if (res.ok && res.data.roster) {
                attendanceRosterList = res.data.roster;
                if (!tbody) return;

                if (attendanceRosterList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding:24px; color:var(--text-secondary);">No students enrolled for selected class/filter</td></tr>';
                    return;
                }

                tbody.innerHTML = attendanceRosterList.map(r => `
                    <tr>
                        <td><code>${r.reg || ('STU-00' + r.student_id)}</code></td>
                        <td>
                            <strong>${r.name}</strong>
                            <span class="badge" style="background:#F1F5F9; color:#475569; margin-left:6px; font-size:11px;">${r.class_name || r.grade}</span>
                        </td>
                        <td>
                            <div style="display:flex; gap:16px; align-items:center;">
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#15803D; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="present" ${r.status === 'present' ? 'checked' : ''}> Present
                                </label>
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#D97706; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="late" ${r.status === 'late' ? 'checked' : ''}> Late
                                </label>
                                <label style="cursor:pointer; display:flex; align-items:center; gap:4px; color:#DC2626; font-weight:600; font-size:13px;">
                                    <input type="radio" name="att_status_${r.student_id}" value="absent" ${r.status === 'absent' ? 'checked' : ''}> Absent
                                </label>
                            </div>
                        </td>
                        <td>
                            <input type="text" id="att_remarks_${r.student_id}" class="form-control" style="font-size:12px; height:34px;" value="${r.remarks || ''}" placeholder="Subject / remark (optional)">
                        </td>
                    </tr>
                `).join('');
            }
        }

        async function saveAttendanceRegister() {
            const dateInput = document.getElementById('attDate');
            const date = dateInput && dateInput.value ? dateInput.value : new Date().toISOString().split('T')[0];

            if (!attendanceRosterList || attendanceRosterList.length === 0) {
                alert('No students currently in the register to mark.');
                return;
            }

            const records = attendanceRosterList.map(r => {
                const radio = document.querySelector(`input[name="att_status_${r.student_id}"]:checked`);
                const status = radio ? radio.value : 'present';
                const remarksInput = document.getElementById(`att_remarks_${r.student_id}`);
                const remarks = remarksInput ? remarksInput.value.trim() : '';
                return {
                    student_id: r.student_id,
                    status: status,
                    remarks: remarks
                };
            });

            const res = await apiFetch('/api/attendance/mark', {
                method: 'POST',
                body: JSON.stringify({ date, records })
            });

            if (res.ok) {
                alert(`Attendance register for ${date} successfully recorded in database!`);
                await loadAttendanceRoster();
                await loadAdminStats();
            } else {
                alert(res.data.message || 'Failed to save attendance register.');
            }
        }

        // ================= LEARNING JOURNAL & WELLBEING =================
        function toggleJournalTypeFields() {
            const type = document.getElementById('journalType').value;
            const wellbeingGrp = document.getElementById('journalWellbeingGroup');
            const mediaGrp = document.getElementById('journalMediaGroup');
            if (type === 'wellbeing') {
                if (wellbeingGrp) wellbeingGrp.style.display = 'block';
                if (mediaGrp) mediaGrp.style.display = 'none';
            } else {
                if (wellbeingGrp) wellbeingGrp.style.display = 'none';
                if (mediaGrp) mediaGrp.style.display = 'block';
            }
        }

        async function loadJournalFeed() {
            const container = document.getElementById('journalFeedContainer');
            if (!container) return;

            const res = await apiFetch('/api/journal');
            if (res.ok && res.data.entries) {
                journalFeedList = res.data.entries;
                if (journalFeedList.length === 0) {
                    container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding:24px;">No learning journal entries posted yet. Use the form on the left to post work samples or wellbeing updates.</p>';
                    return;
                }

                const badgeColors = {
                    photo: { bg: '#DBEAFE', color: '#1E40AF' },
                    wellbeing: { bg: '#DCFCE7', color: '#15803D' },
                    drawing: { bg: '#FEF3C7', color: '#B45309' },
                    voice: { bg: '#F3E8FF', color: '#7E22CE' },
                    text: { bg: '#F1F5F9', color: '#334155' }
                };

                container.innerHTML = journalFeedList.map(item => {
                    const badge = badgeColors[item.type] || { bg: '#F1F5F9', color: '#334155' };
                    let mediaHtml = '';
                    if (item.media_url) {
                        mediaHtml = `
                            <div style="margin-top:10px;">
                                <img src="${item.media_url}" style="max-height:220px; width:100%; object-fit:cover; border-radius:6px; border:1px solid #E2E8F0;" onerror="this.style.display='none'">
                            </div>
                        `;
                    }
                    let wellbeingHtml = '';
                    if (item.wellbeing_data) {
                        const wb = item.wellbeing_data;
                        wellbeingHtml = `
                            <div style="background:#F8FAFC; border:1px solid #E2E8F0; border-radius:6px; padding:10px; margin-top:8px; font-size:12px;">
                                ${wb.meals ? `<div><strong>Meals:</strong> ${wb.meals}</div>` : ''}
                                ${wb.nap ? `<div><strong>Rest/Nap:</strong> ${wb.nap}</div>` : ''}
                                ${wb.hygiene ? `<div><strong>Hygiene:</strong> ${wb.hygiene}</div>` : ''}
                            </div>
                        `;
                    }

                    return `
                        <div class="table-card" style="padding:16px; margin-bottom:14px;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:8px;">
                                <div>
                                    <strong style="color:var(--text-primary); font-size:14px;">${item.student_name}</strong>
                                    <span style="font-size:12px; color:var(--text-secondary); margin-left:6px;">(${item.class_name || item.grade || 'Learner'})</span>
                                    <div style="font-size:11px; color:var(--text-secondary); margin-top:2px;">By ${item.author_name} &bull; ${item.created_at}</div>
                                </div>
                                <div style="display:flex; align-items:center; gap:8px;">
                                    <span class="badge" style="background:${badge.bg}; color:${badge.color}; font-size:11px; text-transform:uppercase;">${item.type}</span>
                                    <button class="btn-sm btn-danger" style="padding:2px 8px; font-size:11px;" onclick="deleteJournalEntry(${item.id})">Delete</button>
                                </div>
                            </div>
                            ${item.caption ? `<p style="font-size:13px; color:var(--text-primary); margin:6px 0; line-height:1.4;">${item.caption}</p>` : ''}
                            ${wellbeingHtml}
                            ${mediaHtml}
                        </div>
                    `;
                }).join('');
            }
        }

        async function handleJournalPostSubmit(e) {
            e.preventDefault();
            const studentId = document.getElementById('journalStudentId').value;
            if (!studentId) {
                alert('Please select an enrolled student.');
                return;
            }
            const type = document.getElementById('journalType').value;
            const caption = document.getElementById('journalCaption') ? document.getElementById('journalCaption').value.trim() : '';
            const fileInput = document.getElementById('journalImageFile');
            const mediaUrlInput = document.getElementById('journalMediaUrl');

            const formData = new FormData();
            formData.append('student_id', studentId);
            formData.append('type', type);
            formData.append('caption', caption);

            if (type === 'wellbeing') {
                const meals = document.getElementById('wellbeingMeals') ? document.getElementById('wellbeingMeals').value : '';
                const nap = document.getElementById('wellbeingNap') ? document.getElementById('wellbeingNap').value : '';
                const hygiene = document.getElementById('wellbeingHygiene') ? document.getElementById('wellbeingHygiene').value : '';
                formData.append('wellbeing_data[meals]', meals);
                formData.append('wellbeing_data[nap]', nap);
                formData.append('wellbeing_data[hygiene]', hygiene);
            } else {
                if (fileInput && fileInput.files[0]) {
                    formData.append('image', fileInput.files[0]);
                } else if (mediaUrlInput && mediaUrlInput.value.trim()) {
                    formData.append('media_url', mediaUrlInput.value.trim());
                }
            }

            const res = await apiFetch('/api/journal', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                alert('Learning Journal entry posted successfully!');
                if (document.getElementById('journalCaption')) document.getElementById('journalCaption').value = '';
                if (fileInput) fileInput.value = '';
                if (mediaUrlInput) mediaUrlInput.value = '';
                await loadJournalFeed();
            } else {
                alert(res.data.message || 'Failed to post learning journal entry.');
            }
        }

        async function deleteJournalEntry(id) {
            if (confirm('Are you sure you want to remove this journal entry?')) {
                const res = await apiFetch(`/api/journal/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadJournalFeed();
                } else {
                    alert(res.data.message || 'Could not delete entry.');
                }
            }
        }

        // ================= REPORTS & CIRCULARS =================
        async function loadReports() {
            const tbody = document.getElementById('reportsTableBody');
            if (!tbody) return;

            const res = await apiFetch('/api/reports');
            if (res.ok && res.data.reports) {
                reportsList = res.data.reports;
                if (reportsList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:24px; color:var(--text-secondary);">No academic reports or circulars uploaded yet</td></tr>';
                    return;
                }

                const typeLabels = {
                    report: 'Academic Term Report Card',
                    merit: 'Merit Commendation',
                    certificate: 'Official Certificate'
                };

                tbody.innerHTML = reportsList.map(r => `
                    <tr>
                        <td><strong>${r.student_name}</strong><br><small style="color:var(--text-secondary);">${r.class_name || r.grade}</small></td>
                        <td><strong>${r.title}</strong></td>
                        <td><span class="badge" style="background:#EFF6FF; color:#1D4ED8;">${typeLabels[r.type] || r.type}</span></td>
                        <td>${r.created_at}</td>
                        <td style="white-space:nowrap;">
                            <a href="${r.file_url}" target="_blank" class="btn-sm" style="text-decoration:none; display:inline-block; margin-right:6px;">Download</a>
                            <button class="btn-sm btn-danger" onclick="deleteReport(${r.id})">Delete</button>
                        </td>
                    </tr>
                `).join('');
            }
        }

        async function uploadReportSubmit(e) {
            e.preventDefault();
            const studentId = document.getElementById('repStudentId').value;
            if (!studentId) {
                alert('Please select a student.');
                return;
            }
            const title = document.getElementById('repTitle').value.trim();
            const type = document.getElementById('repType').value;
            const fileInput = document.getElementById('repFile');

            const formData = new FormData();
            formData.append('student_id', studentId);
            formData.append('title', title);
            formData.append('type', type);

            if (fileInput && fileInput.files[0]) {
                formData.append('file', fileInput.files[0]);
            }

            const res = await apiFetch('/api/reports/upload', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('reportModal');
                if (fileInput) fileInput.value = '';
                if (document.getElementById('repTitle')) document.getElementById('repTitle').value = '';
                await loadReports();
                alert('Academic report card uploaded and issued successfully!');
            } else {
                alert(res.data.message || 'Failed to upload report document.');
            }
        }

        async function deleteReport(id) {
            if (confirm('Are you sure you want to delete this report document?')) {
                const res = await apiFetch(`/api/reports/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    await loadReports();
                } else {
                    alert(res.data.message || 'Could not delete report.');
                }
            }
        }

        // ================= UNIFORM CATALOG STOREFRONT =================
        function autoCalcZig() {
            const usd = parseFloat(document.getElementById('uniPriceUsd').value) || 0;
            const zigInput = document.getElementById('uniPriceZig');
            if (zigInput) {
                zigInput.value = (usd * 13.5).toFixed(2);
            }
        }

        async function loadUniforms() {
            const tbody = document.getElementById('uniformsTableBody');
            if (!tbody) return;

            const res = await apiFetch('/api/uniforms');
            if (res.ok && res.data.uniforms) {
                uniformsList = res.data.uniforms;
                if (uniformsList.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center; padding:24px; color:var(--text-secondary);">No uniform items in catalog yet. Click "Add Uniform Item" above to add uniforms.</td></tr>';
                    return;
                }

                tbody.innerHTML = uniformsList.map(u => {
                    const safeImg = u.image_url ? u.image_url : '/assets/icons8-wallet.svg';
                    const sizesStr = Array.isArray(u.sizes) ? u.sizes.join(', ') : (u.sizes || 'Standard');
                    const escapedName = (u.name || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');

                    return `
                        <tr>
                            <td>
                                <img src="${safeImg}" alt="${escapedName}" style="width:48px; height:48px; object-fit:cover; border-radius:6px; border:1px solid #E2E8F0;" onerror="this.src='/assets/icons8-wallet.svg'">
                            </td>
                            <td>
                                <strong>${u.name}</strong><br>
                                <small style="color:var(--text-secondary);">Code: ${u.item_code} | Sizes: ${sizesStr}</small>
                            </td>
                            <td><span class="badge" style="background:#EEF2FF; color:#4338CA;">${u.category}</span></td>
                            <td>
                                <strong style="color:var(--primary-blue);">$${Number(u.price_usd).toFixed(2)} USD</strong><br>
                                <small style="color:var(--text-secondary);">${Number(u.price_zig).toFixed(2)} ZiG</small>
                            </td>
                            <td>
                                <span class="badge" style="background:${u.stock_count > 0 ? '#DCFCE7' : '#FEE2E2'}; color:${u.stock_count > 0 ? '#15803D' : '#B91C1C'}; font-weight:600;">
                                    ${u.stock_count > 0 ? (u.stock_count + ' in stock') : 'Out of stock'}
                                </span>
                            </td>
                            <td>${u.school_name || 'All Schools'}</td>
                            <td style="white-space:nowrap;">
                                <button class="btn-sm" onclick="openEditUniform(${u.id})">Edit</button>
                                <button class="btn-sm btn-danger" style="margin-left:6px;" onclick="deleteUniform(${u.id})">Delete</button>
                            </td>
                        </tr>
                    `;
                }).join('');
            }
        }

        function autoCalcEditZig() {
            const usd = parseFloat(document.getElementById('editUniPriceUsd').value) || 0;
            const zigInput = document.getElementById('editUniPriceZig');
            if (zigInput) {
                zigInput.value = (usd * 13.5).toFixed(2);
            }
        }

        async function addUniformSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('uniName').value.trim();
            const category = document.getElementById('uniCategory').value;
            const schoolId = document.getElementById('uniSchoolId').value;
            const priceUsd = document.getElementById('uniPriceUsd').value;
            const priceZig = document.getElementById('uniPriceZig').value;
            const sizes = document.getElementById('uniSizes').value.trim();
            const stock = document.getElementById('uniStock').value;
            const description = document.getElementById('uniDescription').value.trim();
            const fileInput = document.getElementById('uniImageFile');
            const urlInput = document.getElementById('uniImageUrl');

            const formData = new FormData();
            formData.append('name', name);
            formData.append('category', category);
            if (schoolId) formData.append('school_id', schoolId);
            formData.append('price_usd', priceUsd);
            if (priceZig) formData.append('price_zig', priceZig);
            formData.append('sizes', sizes);
            formData.append('stock_count', stock);
            formData.append('description', description);

            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (urlInput && urlInput.value.trim()) {
                formData.append('image_url', urlInput.value.trim());
            }

            const res = await apiFetch('/api/uniforms', {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('uniformModal');
                if (fileInput) fileInput.value = '';
                if (urlInput) urlInput.value = '';
                document.getElementById('uniName').value = '';
                document.getElementById('uniPriceUsd').value = '';
                document.getElementById('uniPriceZig').value = '';
                document.getElementById('uniDescription').value = '';
                await loadUniforms();
                alert(`Uniform item "${name}" successfully saved to catalog!`);
            } else {
                alert(res.data.message || 'Failed to add uniform item.');
            }
        }

        function openEditUniform(id) {
            const u = uniformsList.find(item => item.id == id);
            if (!u) {
                alert('Uniform item not found in catalog.');
                return;
            }
            document.getElementById('editUniId').value = u.id;
            document.getElementById('editUniName').value = u.name || '';
            document.getElementById('editUniCategory').value = u.category || 'Formal Wear';
            document.getElementById('editUniStock').value = u.stock_count ?? 50;
            document.getElementById('editUniPriceUsd').value = u.price_usd || '';
            document.getElementById('editUniPriceZig').value = u.price_zig || (u.price_usd ? (u.price_usd * 13.5).toFixed(2) : '');
            document.getElementById('editUniSizes').value = Array.isArray(u.sizes) ? u.sizes.join(', ') : (u.sizes || '');
            document.getElementById('editUniDescription').value = u.description || '';
            document.getElementById('editUniImageUrl').value = u.image_url || '';

            const fileInput = document.getElementById('editUniImageFile');
            if (fileInput) fileInput.value = '';

            const preview = document.getElementById('editUniImagePreview');
            if (preview) {
                if (u.image_url) {
                    preview.src = u.image_url;
                    preview.style.display = 'block';
                } else {
                    preview.style.display = 'none';
                }
            }
            openModal('editUniformModal');
        }

        async function editUniformSubmit(e) {
            e.preventDefault();
            const id = document.getElementById('editUniId').value;
            const name = document.getElementById('editUniName').value.trim();
            const category = document.getElementById('editUniCategory').value;
            const stock = document.getElementById('editUniStock').value;
            const priceUsd = document.getElementById('editUniPriceUsd').value;
            const priceZig = document.getElementById('editUniPriceZig').value;
            const sizes = document.getElementById('editUniSizes').value.trim();
            const description = document.getElementById('editUniDescription').value.trim();
            const fileInput = document.getElementById('editUniImageFile');
            const urlInput = document.getElementById('editUniImageUrl');

            const formData = new FormData();
            formData.append('_method', 'PUT');
            formData.append('name', name);
            formData.append('category', category);
            formData.append('stock_count', stock);
            formData.append('price_usd', priceUsd);
            if (priceZig) formData.append('price_zig', priceZig);
            formData.append('sizes', sizes);
            formData.append('description', description);

            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (urlInput && urlInput.value.trim()) {
                formData.append('image_url', urlInput.value.trim());
            }

            const res = await apiFetch(`/api/uniforms/${id}`, {
                method: 'POST',
                body: formData
            });

            if (res.ok) {
                closeModal('editUniformModal');
                if (fileInput) fileInput.value = '';
                await loadUniforms();
                alert(`Uniform item "${name}" updated successfully with new details and image!`);
            } else {
                alert(res.data.message || 'Failed to update uniform.');
            }
        }

        async function deleteUniform(id) {
            const item = uniformsList.find(u => u.id == id);
            const itemName = item ? item.name : `#${id}`;
            if (confirm(`Are you sure you want to permanently delete uniform "${itemName}" from the store catalog?`)) {
                const res = await apiFetch(`/api/uniforms/${id}`, { method: 'DELETE' });
                if (res.ok) {
                    alert(`Uniform "${itemName}" deleted successfully!`);
                    await loadUniforms();
                } else {
                    alert(res.data.message || 'Could not delete uniform.');
                }
            }
        }

        async function handleAnnouncementSubmit(e) {
            e.preventDefault();
            const title = document.getElementById('annTitle').value.trim();
            const content = document.getElementById('annContent').value.trim();
            const audience = document.getElementById('annAudience') ? document.getElementById('annAudience').value : 'all';
            const schoolId = document.getElementById('annSchoolId')?.value || schoolsList[0]?.id;
            if (!schoolId) { alert('Create a school before publishing an announcement.'); return; }

            const res = await apiFetch('/api/announcements', {
                method: 'POST',
                body: JSON.stringify({
                    title,
                    content,
                    school_id: Number(schoolId),
                    audience_role: audience
                })
            });

            if (res.ok) {
                await loadAnnouncements();
                document.getElementById('announcementForm').reset();
                alert('Announcement published successfully!');
            } else {
                alert(res.data.message || 'Failed to publish announcement.');
            }
        }

        function recalculateStatistics() {
            const totalStudents = studentsList.length;
            const kpiEl = document.getElementById('kpiStudents');
            if (kpiEl) kpiEl.innerText = totalStudents.toLocaleString();

            const zAttEl = document.getElementById('dynZAtt');
            if (zAttEl) {
                zAttEl.innerText = 'Z = +0.8 (Optimal Attendance)';
            }

            const aiAlertEl = document.getElementById('dynAiAlerts');
            if (aiAlertEl) {
                aiAlertEl.innerHTML = `
                    • <strong>Academic Attendance:</strong> Verified roll call across ${totalStudents} active learners.<br>
                    • <strong>Institutional Engagement:</strong> High teacher participation with daily updates.<br>
                    • <strong>Uniform Shop:</strong> Roster and inventory synchronized with real database records.
                `;
            }
        }

        function initDashboardCharts() {
            if (typeof Chart === 'undefined') return;

            // Chart 1: Academic Pass Rate / Enrollment Trends
            const ctxRev = document.getElementById('revenueChart');
            if (ctxRev && !ctxRev._chartInstance) {
                ctxRev._chartInstance = new Chart(ctxRev, {
                    type: 'line',
                    data: {
                        labels: ['Term 1 2025', 'Term 2 2025', 'Term 3 2025', 'Term 1 2026'],
                        datasets: [
                            {
                                label: 'Pass Rate (%)',
                                data: [88, 91, 93, 96],
                                borderColor: '#3B5998',
                                backgroundColor: 'rgba(59, 89, 152, 0.12)',
                                fill: true,
                                tension: 0.4,
                                borderWidth: 2.5
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { position: 'top', labels: { font: { family: 'Cabin' } } } },
                        scales: { y: { min: 70, max: 100, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } }
                    }
                });
            }

            // Chart 2: Attendance Rate by Stream
            const ctxAtt = document.getElementById('attendanceChart');
            if (ctxAtt && !ctxAtt._chartInstance) {
                ctxAtt._chartInstance = new Chart(ctxAtt, {
                    type: 'bar',
                    data: {
                        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                        datasets: [
                            { label: 'Preparatory (ECD)', data: [98, 97, 96, 95, 96], backgroundColor: '#5B7BD5' },
                            { label: 'Primary', data: [96, 95, 97, 96, 94], backgroundColor: '#3B5998' },
                            { label: 'Secondary', data: [94, 93, 95, 92, 91], backgroundColor: '#1E3A8A' }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { position: 'top', labels: { font: { family: 'Cabin' } } } },
                        scales: { y: { min: 80, max: 100, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } }
                    }
                });
            }

            // Chart 3: App Activity & Engagement
            const ctxAct = document.getElementById('activityChart');
            if (ctxAct && !ctxAct._chartInstance) {
                ctxAct._chartInstance = new Chart(ctxAct, {
                    type: 'line',
                    data: {
                        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'],
                        datasets: [
                            {
                                label: 'Parent Portal Logins',
                                data: [320, 450, 580, 720, 890, 1100],
                                borderColor: '#0EA5E9',
                                backgroundColor: 'rgba(14, 165, 233, 0.1)',
                                fill: true,
                                tension: 0.3
                            },
                            {
                                label: 'Teacher Submissions',
                                data: [140, 180, 210, 250, 290, 340],
                                borderColor: '#22C55E',
                                fill: false,
                                tension: 0.3
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { position: 'top', labels: { font: { family: 'Cabin' } } } },
                        scales: { y: { beginAtZero: true, grid: { color: '#F1F5F9' } }, x: { grid: { display: false } } }
                    }
                });
            }
        }

        window.addEventListener('DOMContentLoaded', async () => {
            // Check auth session
            const token = localStorage.getItem('admin_token');
            const savedUser = localStorage.getItem('admin_user');
            if (token && savedUser) {
                try {
                    const u = JSON.parse(savedUser);
                    document.getElementById('headerAdminName').innerText = u.name || 'Administrator';
                    document.getElementById('headerAdminRole').innerText = u.role === 'website_admin' ? 'Platform Owner' : 'School Admin';
                    document.getElementById('headerAvatar').innerText = (u.name || 'Admin').split(' ').map(n=>n[0]).join('').substring(0, 2).toUpperCase();
                    document.getElementById('authScreen').classList.add('hidden');
                    loadAllDashboardData();
                } catch (_) {
                    document.getElementById('authScreen').classList.remove('hidden');
                }
            } else {
                document.getElementById('authScreen').classList.remove('hidden');
            }

            // Keyboard ESC to close modals
            window.addEventListener('keydown', (e) => {
                if (e.key === 'Escape') {
                    document.querySelectorAll('.modal-overlay.open').forEach(m => m.classList.remove('open'));
                }
            });

            // Backdrop click to close modals
            document.querySelectorAll('.modal-overlay').forEach(overlay => {
                overlay.addEventListener('click', (e) => {
                    if (e.target === overlay) {
                        overlay.classList.remove('open');
                    }
                });
            });
        });
    </script>
</body>
</html>
