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
            --secondary-blue: #5B7BD5;
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
            background: linear-gradient(135deg, rgba(59, 89, 152, 0.82) 0%, rgba(30, 48, 88, 0.92) 100%), url('/assets/control.gif') center/cover no-repeat;
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

    <!-- AUTH SECTION: LOGIN & SIGNUP WITH LOGO ON THE RIGHT -->
    <div class="auth-wrapper" id="authScreen">
        <div class="auth-card">
            
            <!-- Left Side: Form Controls -->
            <div class="auth-form-side">
                <div class="auth-tabs">
                    <button class="auth-tab-btn active" id="tabBtnLogin" onclick="switchAuthTab('login')">Admin Log In</button>
                    <button class="auth-tab-btn" id="tabBtnSignup" onclick="switchAuthTab('signup')">Admin Register</button>
                </div>

                <!-- LOGIN FORM -->
                <form class="auth-form active" id="loginForm" onsubmit="handleLoginSubmit(event)">
                    <h2 class="auth-title">Welcome Back</h2>
                    <p class="auth-subtitle">Sign in to your Edu+Conect Web Admin Portal</p>

                    <div class="form-group">
                        <label>Admin Email</label>
                        <input type="email" id="loginEmail" value="admin@hillside.ac.zw" placeholder="admin@hillside.ac.zw" required>
                    </div>

                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" id="loginPassword" value="password123" placeholder="••••••••" required>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; font-size: 13px;">
                        <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; text-transform: none; color: var(--text-primary);">
                            <input type="checkbox" checked> Remember session
                        </label>
                        <a href="#" style="color: var(--primary-blue); text-decoration: none; font-weight: 600;" onclick="alert('Password reset instructions sent to email.')">Forgot password?</a>
                    </div>

                    <button type="submit" class="btn-auth-submit">LOG IN TO DASHBOARD</button>
                </form>

                <!-- SIGNUP FORM -->
                <form class="auth-form" id="signupForm" onsubmit="handleSignupSubmit(event)">
                    <h2 class="auth-title">Create Admin Account</h2>
                    <p class="auth-subtitle">Register a new administrator credential</p>

                    <div class="form-group">
                        <label>Full Name</label>
                        <input type="text" id="signupName" placeholder="Admin Tinotenda" required>
                    </div>

                    <div class="form-group">
                        <label>Admin Email</label>
                        <input type="email" id="signupEmail" placeholder="admin@hillside.ac.zw" required>
                    </div>

                    <div class="form-group">
                        <label>Phone Number</label>
                        <input type="text" id="signupPhone" placeholder="+263771111111" required>
                    </div>

                    <div class="form-group">
                        <label>Assigned School</label>
                        <select id="signupSchool" required>
                            <option value="Hillside Primary School">Hillside Primary School</option>
                            <option value="Hillside Preparatory">Hillside Preparatory</option>
                            <option value="Hillside Secondary">Hillside Secondary</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" id="signupPassword" placeholder="••••••••" required>
                    </div>

                    <button type="submit" class="btn-auth-submit">CREATE ADMIN ACCOUNT</button>
                </form>
            </div>

            <!-- Right Side: Brand Logo Panel -->
            <div class="auth-logo-side">
                <img src="/assets/logo.png" alt="Edu+Conect Logo" style="height: 90px; width: auto; object-fit: contain; margin-bottom: 20px; filter: drop-shadow(0 4px 12px rgba(0,0,0,0.3));">
                <h1 class="brand-heading">Edu+Conect</h1>
            </div>

        </div>
    </div>


    <!-- MAIN DASHBOARD CONTENT CONTAINER -->
    <div class="app-layout" id="dashboardScreen">
        
        <!-- Sidebar Navigation -->
        <aside class="sidebar">
            <div class="brand-header">
                <img src="/assets/logo.png" alt="Edu+Conect Logo" style="height: 36px; width: 36px; object-fit: contain;">
                <span>Edu+Conect</span>
            </div>
            <ul class="nav-list">
                <li class="nav-item">
                    <a class="nav-link active" onclick="switchTab('dashboard')">
                        <img src="/assets/icons8-dashboard.svg" alt="Dashboard">
                        <span>Dashboard</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('users')">
                        <img src="/assets/icons8-user.svg" alt="User Management">
                        <span>User Management</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('schools')">
                        <img src="/assets/icons8-school-management.svg" alt="School Management">
                        <span>School Management</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('teachers')">
                        <img src="/assets/icons8-teacher.svg" alt="Teachers">
                        <span>Teachers</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('students')">
                        <img src="/assets/icons8-education.svg" alt="Students">
                        <span>Students</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('attendance')">
                        <img src="/assets/icons8-attendance.svg" alt="Attendance">
                        <span>Attendance</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('payments')">
                        <img src="/assets/icons8-wallet.svg" alt="Payments & Fees">
                        <span>Payments & Fees</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('announcements')">
                        <img src="/assets/icons8-messages.svg" alt="Announcements">
                        <span>Announcements</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" onclick="switchTab('reports')">
                        <img src="/assets/icons8-reports.svg" alt="Reports & Circulars">
                        <span>Reports & Circulars</span>
                    </a>
                </li>
                <li class="nav-item">
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
                    <button class="action-btn" title="Notifications" onclick="alert('3 New Administrative Alerts')">
                        <svg viewBox="0 0 24 24"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
                        <span class="badge-dot"></span>
                    </button>
                    <button class="action-btn" title="Messages" onclick="alert('15 Unread Messages')">
                        <svg viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                        <span class="badge-dot"></span>
                    </button>
                    <div class="user-profile-pill">
                        <div class="avatar" id="headerAvatar">AT</div>
                        <div class="user-info">
                            <span class="user-name" id="headerAdminName">Admin Tinotenda</span>
                            <span class="user-role">Super Administrator</span>
                        </div>
                        <button class="btn-logout" onclick="handleLogout()">Log Out</button>
                    </div>
                </div>
            </header>

            <!-- Body Area -->
            <div class="content-body">

                <!-- TAB 1: DASHBOARD OVERVIEW -->
                <div id="tab-dashboard" class="tab-pane active">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title" id="displaySchoolName">Hillside Primary School</h2>
                            <p class="page-subtitle">School Overview & Administrative Performance Dashboard</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('userModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Quick Add User
                        </button>
                    </div>

                    <div class="kpi-grid">
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Total Students</p>
                                <p class="value" id="kpiStudents">1,250</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-education.svg" alt="Students">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Attendance Rate</p>
                                <p class="value">95%</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-attendance.svg" alt="Attendance">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Outstanding Fees</p>
                                <p class="value">USD 24,000</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-wallet.svg" alt="Outstanding Fees">
                            </div>
                        </div>
                        <div class="kpi-card">
                            <div class="kpi-info">
                                <p class="title">Unread Messages</p>
                                <p class="value">15</p>
                            </div>
                            <div class="kpi-icon">
                                <img src="/assets/icons8-messages.svg" alt="Unread Messages">
                            </div>
                        </div>
                    </div>

                    <h3 class="section-title">School Performance & Financial Analytics</h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(420px, 1fr)); gap: 20px; margin-bottom: 24px;">
                        
                        <!-- Chart 1: Revenue Collection -->
                        <div class="table-card" style="padding: 18px; margin-bottom: 0;">
                            <div style="margin-bottom: 12px;">
                                <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-blue); margin: 0;">Term Fee Revenue & Collection Trends</h4>
                                <p style="font-size: 11px; color: var(--text-secondary); margin: 2px 0 0 0;">Monthly fee collection velocity vs. target</p>
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

                        <!-- Chart 3: Payment Method Breakdown -->
                        <div class="table-card" style="padding: 18px; margin-bottom: 0;">
                            <div style="margin-bottom: 12px;">
                                <h4 style="font-size: 14px; font-weight: 700; color: var(--primary-blue); margin: 0;">Payment Channel Distribution</h4>
                                <p style="font-size: 11px; color: var(--text-secondary); margin: 2px 0 0 0;">EcoCash, Paynow/ZIPIT, Card & Cash breakdown</p>
                            </div>
                            <div style="height: 220px; position: relative;">
                                <canvas id="paymentChart"></canvas>
                            </div>
                        </div>

                        <!-- Chart 4: App Activity & Engagement -->
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
                    </div>
                </div>

                <!-- TAB 2: USER MANAGEMENT -->
                <div id="tab-users" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">User Management</h2>
                            <p class="page-subtitle">Manage system users, security credentials, and access roles</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('userModal')">
                            <svg viewBox="0 0 24 24"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                            Add New User
                        </button>
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
                <div id="tab-schools" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">School & Class Management</h2>
                            <p class="page-subtitle">Academic years, term dates, and grade level configurations</p>
                        </div>
                        <button class="btn-primary" onclick="alert('Class Modal Opened')">
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
                            <tbody>
                                <tr>
                                    <td><strong>2026 Academic Year</strong></td>
                                    <td>Term 1</td>
                                    <td>12 Jan 2026</td>
                                    <td>10 Apr 2026</td>
                                    <td><span class="role-badge teacher">Active Term</span></td>
                                    <td><button class="btn-sm">Edit</button></td>
                                </tr>
                                <tr>
                                    <td><strong>2025 Academic Year</strong></td>
                                    <td>Term 3</td>
                                    <td>08 Sep 2025</td>
                                    <td>05 Dec 2025</td>
                                    <td><span class="role-badge guardian">Ended</span></td>
                                    <td><button class="btn-sm">Archive</button></td>
                                </tr>
                            </tbody>
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
                                    <td><strong>Grade 1A</strong></td>
                                    <td>Grade 1</td>
                                    <td>Teacher Grace</td>
                                    <td>32 Students</td>
                                    <td><button class="btn-sm">Edit</button></td>
                                </tr>
                                <tr>
                                    <td><strong>Grade 2B</strong></td>
                                    <td>Grade 2</td>
                                    <td>Teacher Tendai</td>
                                    <td>28 Students</td>
                                    <td><button class="btn-sm">Edit</button></td>
                                </tr>
                                <tr>
                                    <td><strong>Form 4 Science</strong></td>
                                    <td>Form 4</td>
                                    <td>Teacher Robert</td>
                                    <td>30 Students</td>
                                    <td><button class="btn-sm">Edit</button></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 4: TEACHER MANAGEMENT -->
                <div id="tab-teachers" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Teacher Directory</h2>
                            <p class="page-subtitle">Manage school faculty, assigned subjects, and contact records</p>
                        </div>
                        <button class="btn-primary" onclick="openModal('teacherModal')">
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
                <div id="tab-students" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Student Directory</h2>
                            <p class="page-subtitle">Student profiles, parent/guardian links, and academic standing</p>
                        </div>
                        <div style="display: flex; gap: 10px;">
                            <button class="btn-sm" style="padding: 8px 12px; font-weight: 600;" onclick="alert('Link Guardian Modal')">Link Guardian</button>
                            <button class="btn-primary" onclick="openModal('studentModal')">
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
                                    <th>Fee Balance</th>
                                    <th>Attendance %</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="studentsTableBody">
                                <!-- Dynamically filled by JS -->
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 6: ATTENDANCE -->
                <div id="tab-attendance" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Daily Attendance Register</h2>
                            <p class="page-subtitle">Mark and verify student attendance logs</p>
                        </div>
                        <button class="btn-primary" onclick="alert('Attendance saved successfully!')">Save Register</button>
                    </div>

                    <div class="table-card">
                        <div class="table-toolbar">
                            <div class="filter-group">
                                <label style="font-size: 13px; font-weight: 600;">Select Date:</label>
                                <input type="date" class="form-control" style="width: 160px;" value="2026-07-22">
                                <label style="font-size: 13px; font-weight: 600; margin-left: 14px;">Select Class:</label>
                                <select class="form-control" style="width: 160px;">
                                    <option>Grade 1A</option>
                                    <option>Grade 2B</option>
                                    <option>Form 4 Science</option>
                                </select>
                            </div>
                        </div>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Roll No</th>
                                    <th>Student Name</th>
                                    <th>Status</th>
                                    <th>Remarks</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>STU-001</td>
                                    <td>Tafadzwa Chewe</td>
                                    <td>
                                        <label><input type="radio" name="att_1" checked> Present</label> &nbsp;
                                        <label><input type="radio" name="att_1"> Absent</label> &nbsp;
                                        <label><input type="radio" name="att_1"> Late</label>
                                    </td>
                                    <td><input type="text" class="form-control" placeholder="Optional remark..." style="padding: 4px 8px;"></td>
                                </tr>
                                <tr>
                                    <td>STU-002</td>
                                    <td>Anesu Moyo</td>
                                    <td>
                                        <label><input type="radio" name="att_2" checked> Present</label> &nbsp;
                                        <label><input type="radio" name="att_2"> Absent</label> &nbsp;
                                        <label><input type="radio" name="att_2"> Late</label>
                                    </td>
                                    <td><input type="text" class="form-control" placeholder="Optional remark..." style="padding: 4px 8px;"></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 7: PAYMENTS & FEES -->
                <div id="tab-payments" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Fee Management & Billing</h2>
                            <p class="page-subtitle">Track school fee payments, outstanding balances, and invoices</p>
                        </div>
                        <button class="btn-primary" onclick="alert('Payment Recorded!')">Record Payment</button>
                    </div>

                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Student</th>
                                    <th>Class</th>
                                    <th>Term Fee</th>
                                    <th>Amount Paid</th>
                                    <th>Balance Due</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>Tafadzwa Chewe</td>
                                    <td>Grade 1A</td>
                                    <td>USD 450.00</td>
                                    <td>USD 450.00</td>
                                    <td>USD 0.00</td>
                                    <td><span class="role-badge teacher">Paid in Full</span></td>
                                    <td><button class="btn-sm">Statement</button></td>
                                </tr>
                                <tr>
                                    <td>Anesu Moyo</td>
                                    <td>Grade 2B</td>
                                    <td>USD 450.00</td>
                                    <td>USD 200.00</td>
                                    <td>USD 250.00</td>
                                    <td><span class="role-badge guardian">Partial</span></td>
                                    <td><button class="btn-sm">Receipt</button></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- TAB 8: ANNOUNCEMENTS -->
                <div id="tab-announcements" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">School Announcements</h2>
                            <p class="page-subtitle">Publish announcements and circulars to mobile app users</p>
                        </div>
                        <button class="btn-primary" onclick="alert('Announcement Published to Mobile App!')">Publish Announcement</button>
                    </div>

                    <div class="table-card" style="padding: 20px; margin-bottom: 24px;">
                        <h3 class="section-title">New Announcement Form</h3>
                        <div class="form-group">
                            <label>Announcement Title</label>
                            <input type="text" class="form-control" placeholder="e.g. End of Term Parent-Teacher Consultation Meeting">
                        </div>
                        <div class="form-group">
                            <label>Target Audience</label>
                            <select class="form-control">
                                <option>All Users (Guardians & Teachers)</option>
                                <option>Guardians Only</option>
                                <option>Teachers Only</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Message Content</label>
                            <textarea class="form-control" rows="4" placeholder="Enter announcement body text here..."></textarea>
                        </div>
                    </div>
                </div>

                <!-- TAB 9: REPORTS -->
                <div id="tab-reports" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Reports & Academic Documents</h2>
                            <p class="page-subtitle">Upload and issue term report cards for parents</p>
                        </div>
                        <button class="btn-primary" onclick="alert('Report Uploaded!')">Upload Report Card</button>
                    </div>

                    <div class="table-card">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Student Name</th>
                                    <th>Academic Term</th>
                                    <th>Report File</th>
                                    <th>Uploaded Date</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>Tafadzwa Chewe</td>
                                    <td>2026 Term 1 Progress Report</td>
                                    <td><code>Tafadzwa_Chewe_Report.pdf</code></td>
                                    <td>18 Jul 2026</td>
                                    <td><button class="btn-sm">Download</button></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                <!-- TAB 10: UNIFORM SHOP & ACCOUNTS -->
                <div id="tab-uniforms" class="tab-pane">
                    <div class="page-header">
                        <div>
                            <h2 class="page-title">Uniform Shop & Per-Student Accounts</h2>
                            <p class="page-subtitle">Configure uniform inventory storefront, prices, and per-student uniform order accounts</p>
                        </div>
                        <button class="btn-primary" onclick="alert('New Uniform Item Added!')">Add Uniform Item</button>
                    </div>

                    <div class="table-card" style="margin-bottom: 24px;">
                        <h3 class="section-title" style="padding: 16px;">Uniform Inventory Storefront (Admin Controlled)</h3>
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Item Code</th>
                                    <th>Uniform Item</th>
                                    <th>Tier / Category</th>
                                    <th>Price (USD)</th>
                                    <th>Stock Count</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>UNI-BLZ-01</td>
                                    <td><strong>School Blazer (Navy Blue with Crest)</strong></td>
                                    <td>Primary / Secondary</td>
                                    <td>$45.00</td>
                                    <td>120 Available</td>
                                    <td><button class="btn-sm" onclick="alert('Editing Item UNI-BLZ-01')">Edit Price</button></td>
                                </tr>
                                <tr>
                                    <td>UNI-PEK-02</td>
                                    <td><strong>PE Kit (House T-Shirt & Shorts)</strong></td>
                                    <td>All Tiers</td>
                                    <td>$25.00</td>
                                    <td>85 Available</td>
                                    <td><button class="btn-sm" onclick="alert('Editing Item UNI-PEK-02')">Edit Price</button></td>
                                </tr>
                                <tr>
                                    <td>UNI-TIE-03</td>
                                    <td><strong>Official School Tie & Crest Badge</strong></td>
                                    <td>Primary / Secondary</td>
                                    <td>$12.00</td>
                                    <td>200 Available</td>
                                    <td><button class="btn-sm" onclick="alert('Editing Item UNI-TIE-03')">Edit Price</button></td>
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
                            <option value="admin">Administrator (Web Access)</option>
                            <option value="teacher">Teacher (Mobile App Access)</option>
                            <option value="guardian">Guardian / Parent (Mobile App Access)</option>
                        </select>
                    </div>
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
                        <input type="text" id="tClass" class="form-control" placeholder="e.g. Grade 1A" required>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" id="tEmail" class="form-control" placeholder="e.g. grace@hillside.ac.zw" required>
                    </div>
                    <div class="form-group">
                        <label>Phone</label>
                        <input type="text" id="tPhone" class="form-control" placeholder="e.g. +263772222222" required>
                    </div>
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
                    <div class="form-group">
                        <label>Student Full Name</label>
                        <input type="text" id="sName" class="form-control" placeholder="e.g. Tafadzwa Chewe" required>
                    </div>
                    <div class="form-group">
                        <label>Assigned Class</label>
                        <select id="sClass" class="form-control" required>
                            <option>Grade 1A</option>
                            <option>Grade 2B</option>
                            <option>Form 4 Science</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Guardian Name</label>
                        <input type="text" id="sGuardian" class="form-control" placeholder="e.g. John Chewe" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn-sm" onclick="closeModal('studentModal')">Cancel</button>
                    <button type="submit" class="btn-primary">Enrol Student</button>
                </div>
            </form>
        </div>
    </div>

    <!-- JavaScript Handlers -->
    <script>
        let usersList = [
            { id: 1, name: 'Admin Tinotenda', email: 'admin@hillside.ac.zw', phone: '+263771111111', role: 'admin' },
            { id: 2, name: 'Teacher Grace', email: 'grace@hillside.ac.zw', phone: '+263772222222', role: 'teacher' },
            { id: 3, name: 'Guardian John Chewe', email: 'john.chewe@gmail.com', phone: '+263773333333', role: 'guardian' }
        ];

        let teachersList = [
            { name: 'Teacher Grace', subject: 'Mathematics & Science', class: 'Grade 1A', email: 'grace@hillside.ac.zw', phone: '+263772222222' },
            { name: 'Teacher Tendai', subject: 'English & Shona', class: 'Grade 2B', email: 'tendai@hillside.ac.zw', phone: '+263775555555' }
        ];

        let studentsList = [
            { reg: 'STU-001', name: 'Tafadzwa Chewe', class: 'Grade 1A', guardian: 'John Chewe', balance: 'USD 0.00', attendance: '98%' },
            { reg: 'STU-002', name: 'Anesu Moyo', class: 'Grade 2B', guardian: 'Blessing Moyo', balance: 'USD 250.00', attendance: '92%' }
        ];

        let activeRoleFilter = 'all';

        // AUTH SWAPPING (LOGIN / SIGNUP TABS)
        function switchAuthTab(tab) {
            document.getElementById('tabBtnLogin').classList.toggle('active', tab === 'login');
            document.getElementById('tabBtnSignup').classList.toggle('active', tab === 'signup');
            document.getElementById('loginForm').classList.toggle('active', tab === 'login');
            document.getElementById('signupForm').classList.toggle('active', tab === 'signup');
        }

        function handleLoginSubmit(e) {
            e.preventDefault();
            const email = document.getElementById('loginEmail').value;
            const name = email.toLowerCase().includes('admin') ? 'Admin Tinotenda' : 'Administrator';
            
            document.getElementById('headerAdminName').innerText = name;
            document.getElementById('headerAvatar').innerText = name.split(' ').map(n=>n[0]).join('');
            
            document.getElementById('authScreen').classList.add('hidden');
        }

        function handleSignupSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('signupName').value;
            const email = document.getElementById('signupEmail').value;
            const phone = document.getElementById('signupPhone').value;

            usersList.push({ id: usersList.length + 1, name, email, phone, role: 'admin' });
            renderUsersTable();

            document.getElementById('headerAdminName').innerText = name;
            document.getElementById('headerAvatar').innerText = name.split(' ').map(n=>n[0]).join('');

            alert('Admin Account created successfully! Logging in...');
            document.getElementById('authScreen').classList.add('hidden');
        }

        function handleLogout() {
            if (confirm('Are you sure you want to log out of the Admin Portal?')) {
                document.getElementById('authScreen').classList.remove('hidden');
            }
        }

        // TAB NAVIGATION
        function switchTab(tabId) {
            document.querySelectorAll('.nav-link').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));

            const targetNav = Array.from(document.querySelectorAll('.nav-link')).find(el => {
                const attr = el.getAttribute('onclick');
                return attr && attr.includes(tabId);
            });
            if (targetNav) targetNav.classList.add('active');

            const targetPane = document.getElementById('tab-' + tabId);
            if (targetPane) targetPane.classList.add('active');
        }

        function updateSchool(schoolName) {
            document.getElementById('displaySchoolName').innerText = schoolName;
        }

        function renderUsersTable() {
            const tbody = document.getElementById('usersTableBody');
            const searchInput = document.getElementById('userSearchInput');
            const search = searchInput ? searchInput.value.toLowerCase() : '';
            
            let filtered = usersList;
            if (activeRoleFilter !== 'all') {
                filtered = filtered.filter(u => u.role === activeRoleFilter);
            }
            if (search) {
                filtered = filtered.filter(u => u.name.toLowerCase().includes(search) || u.email.toLowerCase().includes(search) || u.phone.includes(search));
            }

            tbody.innerHTML = filtered.map(u => `
                <tr>
                    <td>#${u.id}</td>
                    <td><strong>${u.name}</strong></td>
                    <td>${u.email}</td>
                    <td>${u.phone}</td>
                    <td><span class="role-badge ${u.role}">${u.role}</span></td>
                    <td>
                        <button class="btn-sm" onclick="alert('Editing user #${u.id}')">Edit</button>
                        <button class="btn-sm btn-danger" onclick="deleteUser(${u.id})">Delete</button>
                    </td>
                </tr>
            `).join('');

            document.getElementById('kpiStudents').innerText = (1250 + studentsList.length - 2).toLocaleString();
        }

        function filterUserRole(role, btn) {
            activeRoleFilter = role;
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            renderUsersTable();
        }

        function renderTeachersTable() {
            const tbody = document.getElementById('teachersTableBody');
            tbody.innerHTML = teachersList.map(t => `
                <tr>
                    <td><strong>${t.name}</strong></td>
                    <td>${t.subject}</td>
                    <td>${t.class}</td>
                    <td>${t.email}</td>
                    <td>${t.phone}</td>
                    <td>
                        <button class="btn-sm">Edit</button>
                        <button class="btn-sm btn-danger">Remove</button>
                    </td>
                </tr>
            `).join('');
        }

        function renderStudentsTable() {
            const tbody = document.getElementById('studentsTableBody');
            tbody.innerHTML = studentsList.map(s => `
                <tr>
                    <td><code>${s.reg}</code></td>
                    <td><strong>${s.name}</strong></td>
                    <td>${s.class}</td>
                    <td>${s.guardian}</td>
                    <td>${s.balance}</td>
                    <td><strong style="color:var(--success-green);">${s.attendance}</strong></td>
                    <td>
                        <button class="btn-sm">Profile</button>
                        <button class="btn-sm">Edit</button>
                    </td>
                </tr>
            `).join('');
        }

        function openModal(id) {
            document.getElementById(id).classList.add('open');
        }

        function closeModal(id) {
            document.getElementById(id).classList.remove('open');
        }

        function addUserSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('newUserName').value;
            const email = document.getElementById('newUserEmail').value;
            const phone = document.getElementById('newUserPhone').value;
            const role = document.getElementById('newUserRole').value;

            usersList.push({ id: usersList.length + 1, name, email, phone, role });
            closeModal('userModal');
            renderUsersTable();
            alert('New User "' + name + '" successfully created!');
        }

        function deleteUser(id) {
            if (confirm('Are you sure you want to delete user #' + id + '?')) {
                usersList = usersList.filter(u => u.id !== id);
                renderUsersTable();
            }
        }

        function addTeacherSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('tName').value;
            const subject = document.getElementById('tSubject').value;
            const className = document.getElementById('tClass').value;
            const email = document.getElementById('tEmail').value;
            const phone = document.getElementById('tPhone').value;

            teachersList.push({ name, subject, class: className, email, phone });
            closeModal('teacherModal');
            renderTeachersTable();
            alert('Teacher "' + name + '" added successfully!');
        }

        function recalculateStatistics() {
            const totalStudents = 1250 + (studentsList.length - 2);
            const kpiEl = document.getElementById('kpiStudents');
            if (kpiEl) kpiEl.innerText = totalStudents.toLocaleString();

            const attendances = studentsList.map(s => parseFloat(s.attendance.replace('%', '')));
            const meanAtt = attendances.reduce((a, b) => a + b, 0) / (attendances.length || 1);
            const variance = attendances.reduce((a, b) => a + Math.pow(b - meanAtt, 2), 0) / (attendances.length || 1);
            const stdDev = Math.sqrt(variance) || 1.2;

            const sampleAtt = 98.0;
            const zScoreAtt = ((sampleAtt - meanAtt) / stdDev).toFixed(1);

            const zAttEl = document.getElementById('dynZAtt');
            if (zAttEl) {
                zAttEl.innerText = `Z = ${zScoreAtt >= 0 ? '+' : ''}${zScoreAtt} (${zScoreAtt >= 0 ? 'Normal High' : 'Below Mean'})`;
            }

            const aiAlertEl = document.getElementById('dynAiAlerts');
            if (aiAlertEl) {
                aiAlertEl.innerHTML = `
                    • <strong>Fee Collection Velocity:</strong> Total enrolled students: ${totalStudents.toLocaleString()}. Predicted revenue for current term is $${(totalStudents * 360 * 0.85).toLocaleString()}.<br>
                    • <strong>Statistical Attendance Z-Score:</strong> Mean school attendance is ${meanAtt.toFixed(1)}% (Std Dev σ = ${stdDev.toFixed(1)}%). Current Grade 4 Gold Z-Score is +${zScoreAtt}.<br>
                    • <strong>Uniform Shop Forecast:</strong> Uniform inventory predicted to maintain full coverage across ${studentsList.length} newly registered accounts.
                `;
            }
        }

        function addStudentSubmit(e) {
            e.preventDefault();
            const name = document.getElementById('sName').value;
            const className = document.getElementById('sClass').value;
            const guardian = document.getElementById('sGuardian').value;

            const reg = 'STU-00' + (studentsList.length + 1);
            studentsList.push({ reg, name, class: className, guardian, balance: 'USD 0.00', attendance: '100%' });
            closeModal('studentModal');
            renderStudentsTable();
            recalculateStatistics();
            alert('Student "' + name + '" enrolled successfully!');
        }

        function initDashboardCharts() {
            if (typeof Chart === 'undefined') return;

            // Chart 1: Revenue & Fee Collection Trends
            const ctxRev = document.getElementById('revenueChart');
            if (ctxRev) {
                new Chart(ctxRev, {
                    type: 'line',
                    data: {
                        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
                        datasets: [
                            {
                                label: 'Actual Fee Revenue ($)',
                                data: [12000, 19500, 27000, 34000, 42000, 48000, 54500],
                                borderColor: '#3B5998',
                                backgroundColor: 'rgba(59, 89, 152, 0.12)',
                                fill: true,
                                tension: 0.4,
                                borderWidth: 2.5
                            },
                            {
                                label: 'Term Target ($)',
                                data: [15000, 22000, 30000, 38000, 45000, 52000, 60000],
                                borderColor: '#94A3B8',
                                borderDash: [4, 4],
                                fill: false,
                                tension: 0.4,
                                borderWidth: 1.5
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

            // Chart 2: Attendance Rate by Stream
            const ctxAtt = document.getElementById('attendanceChart');
            if (ctxAtt) {
                new Chart(ctxAtt, {
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

            // Chart 3: Payment Channel Distribution
            const ctxPay = document.getElementById('paymentChart');
            if (ctxPay) {
                new Chart(ctxPay, {
                    type: 'doughnut',
                    data: {
                        labels: ['EcoCash (Mobile)', 'Paynow / ZIPIT', 'Visa / Mastercard', 'Direct Bank Cash'],
                        datasets: [{
                            data: [45, 25, 18, 12],
                            backgroundColor: ['#22C55E', '#3B5998', '#0EA5E9', '#F59E0B'],
                            borderWidth: 2,
                            borderColor: '#FFFFFF'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { position: 'right', labels: { font: { family: 'Cabin' } } } },
                        cutout: '65%'
                    }
                });
            }

            // Chart 4: App Activity & Engagement
            const ctxAct = document.getElementById('activityChart');
            if (ctxAct) {
                new Chart(ctxAct, {
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
                                label: 'Teacher Roster Submissions',
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

        window.addEventListener('DOMContentLoaded', () => {
            renderUsersTable();
            renderTeachersTable();
            renderStudentsTable();
            recalculateStatistics();
            initDashboardCharts();
        });
    </script>
</body>
</html>
