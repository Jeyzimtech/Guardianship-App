<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Edu+Connect Guardianship Portal</title>
    <style>
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background-color: #f4f6f9;
            margin: 0;
            padding: 0;
            color: #334155;
        }
        .container {
            max-width: 600px;
            margin: 30px auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
            border: 1px solid #e2e8f0;
        }
        .header {
            background-color: #1E3A8A;
            padding: 28px 24px;
            text-align: center;
            color: #ffffff;
        }
        .header h1 {
            margin: 0;
            font-size: 22px;
            font-weight: 700;
            letter-spacing: -0.5px;
        }
        .header p {
            margin: 6px 0 0 0;
            font-size: 13px;
            opacity: 0.9;
        }
        .content {
            padding: 32px 28px;
        }
        .greeting {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 14px;
            color: #1e293b;
        }
        .body-text {
            font-size: 14px;
            line-height: 1.6;
            color: #475569;
            margin-bottom: 20px;
        }
        .cred-box {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-left: 4px solid #3B5998;
            border-radius: 6px;
            padding: 16px 20px;
            margin-bottom: 24px;
        }
        .cred-row {
            display: flex;
            margin-bottom: 8px;
            font-size: 14px;
        }
        .cred-row:last-child {
            margin-bottom: 0;
        }
        .cred-label {
            font-weight: 600;
            color: #64748b;
            width: 140px;
        }
        .cred-value {
            font-weight: 600;
            color: #0f172a;
        }
        .btn-wrapper {
            text-align: center;
            margin: 28px 0;
        }
        .btn-primary {
            display: inline-block;
            background-color: #3B5998;
            color: #ffffff !important;
            text-decoration: none;
            padding: 14px 32px;
            font-size: 15px;
            font-weight: 600;
            border-radius: 6px;
            box-shadow: 0 2px 4px rgba(59, 89, 152, 0.25);
        }
        .btn-primary:hover {
            background-color: #2D4373;
        }
        .footer {
            background-color: #f8fafc;
            padding: 20px 24px;
            text-align: center;
            font-size: 12px;
            color: #94a3b8;
            border-top: 1px solid #e2e8f0;
        }
        .footer p {
            margin: 4px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Edu+Connect Guardianship</h1>
            <p>Integrated School Administration & Parent Engagement Portal</p>
        </div>
        <div class="content">
            <div class="greeting">Hello {{ $name }},</div>
            <p class="body-text">
                Your account has been created on the <strong>Edu+Connect Guardianship</strong> system as a <strong>{{ strtoupper($role) }}</strong>.
                You can now log in to access the portal and mobile services.
            </p>

            <div class="cred-box">
                <div class="cred-row">
                    <span class="cred-label">Login Identifier:</span>
                    <span class="cred-value">{{ $email }}</span>
                </div>
                @if(!empty($password))
                <div class="cred-row">
                    <span class="cred-label">Temporary Password:</span>
                    <span class="cred-value">{{ $password }}</span>
                </div>
                @endif
                <div class="cred-row">
                    <span class="cred-label">Assigned Role:</span>
                    <span class="cred-value">{{ ucfirst($role) }}</span>
                </div>
            </div>

            <div class="btn-wrapper">
                <a href="{{ $loginUrl }}" class="btn-primary" target="_blank">Access Portal & Log In</a>
            </div>

            <p class="body-text" style="font-size: 13px; color: #64748b;">
                Or copy and paste this link directly into your browser:<br>
                <a href="{{ $loginUrl }}" style="color: #3B5998; word-break: break-all;">{{ $loginUrl }}</a>
            </p>

            <p class="body-text" style="font-size: 12px; color: #94a3b8; margin-top: 24px;">
                For security reasons, we recommend updating your password after logging in for the first time.
            </p>
        </div>
        <div class="footer">
            <p>&copy; {{ date('Y') }} Edu+Connect &bull; Chewetechnologies</p>
            <p>If you did not expect this invitation, please contact your school administrator.</p>
        </div>
    </div>
</body>
</html>
