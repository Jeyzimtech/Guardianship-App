<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $isNewUser ?? false ? 'Create Your Password' : 'Reset Your Password' }} - Edu+Connect</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cabin:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #3B5998;
            --primary-dark: #2B4374;
            --primary-light: #5B7BD5;
            --bg-color: #F8FAFC;
            --surface: #FFFFFF;
            --border: #E2E8F0;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --success: #16A34A;
            --error: #DC2626;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Cabin', sans-serif;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .auth-container {
            width: 100%;
            max-width: 440px;
            background: var(--surface);
            border-radius: 12px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.04);
            border: 1px solid var(--border);
            overflow: hidden;
        }

        .auth-header {
            background: linear-gradient(135deg, #1E3A8A 0%, var(--primary) 100%);
            padding: 32px 24px;
            text-align: center;
            color: white;
        }

        .auth-header h1 {
            font-size: 20px;
            font-weight: 700;
            letter-spacing: -0.3px;
            margin-bottom: 4px;
        }

        .auth-header p {
            font-size: 13px;
            opacity: 0.9;
        }

        .auth-body {
            padding: 30px 28px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #334155;
            margin-bottom: 6px;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-wrapper input {
            width: 100%;
            padding: 12px 42px 12px 14px;
            font-size: 14px;
            border: 1px solid var(--border);
            border-radius: 8px;
            background: #F8FAFC;
            outline: none;
            transition: all 0.2s ease;
        }

        .input-wrapper input:focus {
            border-color: var(--primary);
            background: #FFFFFF;
            box-shadow: 0 0 0 3px rgba(59, 89, 152, 0.15);
        }

        .input-wrapper input[readonly] {
            background: #F1F5F9;
            color: #64748B;
            cursor: not-allowed;
            padding-right: 14px;
        }

        .toggle-pwd {
            position: absolute;
            right: 12px;
            background: none;
            border: none;
            cursor: pointer;
            padding: 4px;
            color: #94A3B8;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .toggle-pwd:hover {
            color: var(--primary);
        }

        .btn-submit {
            width: 100%;
            background: var(--primary);
            color: white;
            border: none;
            padding: 13px;
            font-size: 15px;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            transition: background 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }

        .btn-submit:hover {
            background: var(--primary-dark);
        }

        .btn-submit:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }

        .alert-box {
            padding: 12px;
            border-radius: 6px;
            font-size: 13px;
            margin-bottom: 18px;
            display: none;
            line-height: 1.4;
        }

        .alert-error {
            background: #FEE2E2;
            color: var(--error);
            border: 1px solid #FCA5A5;
        }

        .alert-success {
            background: #DCFCE7;
            color: var(--success);
            border: 1px solid #86EFAC;
        }

        /* Success Screen */
        .success-card {
            text-align: center;
            display: none;
            padding: 16px 0;
        }

        .success-icon-wrap {
            width: 64px;
            height: 64px;
            background: #DCFCE7;
            color: #16A34A;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px auto;
        }

        .success-icon-wrap svg {
            width: 36px;
            height: 36px;
            stroke: currentColor;
            fill: none;
            stroke-width: 2.5;
        }

        .success-card h2 {
            font-size: 18px;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 8px;
        }

        .success-card p {
            font-size: 14px;
            color: var(--text-muted);
            line-height: 1.5;
            margin-bottom: 24px;
        }

        .app-steps {
            background: #F8FAFC;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 16px;
            text-align: left;
            font-size: 13px;
            color: #334155;
            margin-bottom: 20px;
        }

        .app-steps ol {
            padding-left: 18px;
            margin-top: 6px;
        }

        .app-steps li {
            margin-bottom: 4px;
        }

        .auth-footer {
            background: #F8FAFC;
            padding: 16px;
            text-align: center;
            font-size: 12px;
            color: var(--text-muted);
            border-top: 1px solid var(--border);
        }
    </style>
</head>
<body>

    <div class="auth-container">
        <div class="auth-header">
            <h1 id="headerTitle">{{ $isNewUser ?? false ? 'Create Your Password' : 'Reset Your Password' }}</h1>
            <p>Edu+Connect Mobile Application & Guardianship</p>
        </div>

        <div class="auth-body">
            <div id="alertBox" class="alert-box"></div>

            <form id="passwordForm" onsubmit="handlePasswordSubmit(event)">
                <input type="hidden" id="resetToken" value="{{ $token ?? '' }}">

                <div class="form-group">
                    <label>Account Email</label>
                    <div class="input-wrapper">
                        <input type="email" id="email" value="{{ $email ?? '' }}" placeholder="your.email@example.com" required readonly>
                    </div>
                </div>

                <div class="form-group">
                    <label>New Password (min 6 characters)</label>
                    <div class="input-wrapper">
                        <input type="password" id="password" placeholder="Enter secure password" required minlength="6">
                        <button type="button" class="toggle-pwd" onclick="togglePasswordVisibility('password', this)">
                            <svg viewBox="0 0 24 24" style="width:18px; height:18px; stroke:currentColor; fill:none; stroke-width:2;"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                </div>

                <div class="form-group">
                    <label>Confirm New Password</label>
                    <div class="input-wrapper">
                        <input type="password" id="password_confirmation" placeholder="Confirm your password" required minlength="6">
                        <button type="button" class="toggle-pwd" onclick="togglePasswordVisibility('password_confirmation', this)">
                            <svg viewBox="0 0 24 24" style="width:18px; height:18px; stroke:currentColor; fill:none; stroke-width:2;"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        </button>
                    </div>
                </div>

                <button type="submit" id="btnSubmit" class="btn-submit">
                    <span>Save Password</span>
                </button>
            </form>

            <!-- Success State -->
            <div id="successCard" class="success-card">
                <div class="success-icon-wrap">
                    <svg viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"/></svg>
                </div>
                <h2>Password Ready!</h2>
                <p>Your password has been successfully configured. You can now use this password on the Edu+Connect mobile app.</p>

                <div class="app-steps">
                    <strong>Next Steps on Mobile:</strong>
                    <ol>
                        <li>Launch the <strong>Edu+Connect</strong> app on your device.</li>
                        <li>Enter your email: <strong><span id="displaySuccessEmail"></span></strong></li>
                        <li>Enter your new password and tap <strong>Sign in</strong>.</li>
                    </ol>
                </div>
            </div>
        </div>

        <div class="auth-footer">
            &copy; {{ date('Y') }} Edu+Connect &bull; Chewetech Technologies
        </div>
    </div>

    <script>
        function togglePasswordVisibility(fieldId, btn) {
            const field = document.getElementById(fieldId);
            if (!field) return;
            if (field.type === 'password') {
                field.type = 'text';
                btn.innerHTML = `<svg viewBox="0 0 24 24" style="width:18px; height:18px; stroke:currentColor; fill:none; stroke-width:2;"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>`;
            } else {
                field.type = 'password';
                btn.innerHTML = `<svg viewBox="0 0 24 24" style="width:18px; height:18px; stroke:currentColor; fill:none; stroke-width:2;"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>`;
            }
        }

        async function handlePasswordSubmit(e) {
            e.preventDefault();
            const alertBox = document.getElementById('alertBox');
            alertBox.style.display = 'none';

            const token = document.getElementById('resetToken').value.trim();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value;
            const passwordConfirmation = document.getElementById('password_confirmation').value;

            if (!token) {
                showAlert('Missing or invalid reset token. Please check your email link.', 'error');
                return;
            }

            if (password.length < 6) {
                showAlert('Password must be at least 6 characters in length.', 'error');
                return;
            }

            if (password !== passwordConfirmation) {
                showAlert('Passwords do not match. Please re-enter.', 'error');
                return;
            }

            const btn = document.getElementById('btnSubmit');
            btn.disabled = true;
            btn.innerHTML = '<span>Saving password...</span>';

            try {
                const response = await fetch('/api/auth/reset-password', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        token: token,
                        email: email,
                        password: password,
                        password_confirmation: passwordConfirmation
                    })
                });

                const data = await response.json();

                if (response.ok && data.status === 'success') {
                    document.getElementById('passwordForm').style.display = 'none';
                    document.getElementById('displaySuccessEmail').innerText = email;
                    document.getElementById('successCard').style.display = 'block';
                    document.getElementById('headerTitle').innerText = 'Password Set Successfully';
                } else {
                    showAlert(data.message || 'Failed to update password. Link may have expired.', 'error');
                    btn.disabled = false;
                    btn.innerHTML = '<span>Save Password</span>';
                }
            } catch (err) {
                showAlert('Network error occurred. Please check your connection and try again.', 'error');
                btn.disabled = false;
                btn.innerHTML = '<span>Save Password</span>';
            }
        }

        function showAlert(msg, type) {
            const alertBox = document.getElementById('alertBox');
            alertBox.innerText = msg;
            alertBox.className = 'alert-box ' + (type === 'error' ? 'alert-error' : 'alert-success');
            alertBox.style.display = 'block';
        }
    </script>
</body>
</html>
