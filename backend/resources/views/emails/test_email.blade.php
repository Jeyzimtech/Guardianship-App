<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SMTP / SES Dispatch Test - Edu+Connect</title>
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
            background-color: #10B981;
            padding: 24px;
            text-align: center;
            color: #ffffff;
        }
        .header h1 {
            margin: 0;
            font-size: 20px;
            font-weight: 700;
        }
        .header p {
            margin: 4px 0 0 0;
            font-size: 13px;
            opacity: 0.95;
        }
        .content {
            padding: 30px 24px;
        }
        .status-badge {
            display: inline-block;
            background-color: #D1FAE5;
            color: #065F46;
            font-size: 12px;
            font-weight: 700;
            padding: 4px 12px;
            border-radius: 9999px;
            margin-bottom: 16px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .info-card {
            background-color: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 16px 20px;
            margin-top: 16px;
            margin-bottom: 20px;
        }
        .info-row {
            display: flex;
            margin-bottom: 8px;
            font-size: 13px;
        }
        .info-row:last-child {
            margin-bottom: 0;
        }
        .info-label {
            width: 140px;
            color: #64748b;
            font-weight: 600;
        }
        .info-value {
            color: #0f172a;
            font-weight: 600;
        }
        .footer {
            background-color: #f8fafc;
            padding: 16px;
            text-align: center;
            font-size: 12px;
            color: #94a3b8;
            border-top: 1px solid #e2e8f0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Edu+Connect Mail Transport Verified</h1>
            <p>Outbound Email Configuration Test</p>
        </div>
        <div class="content">
            <span class="status-badge">&#10003; Connection Successful</span>
            <p style="font-size: 15px; line-height: 1.5; margin: 0 0 16px 0;">
                If you are reading this email, your mail delivery service (<strong>{{ $provider ?? 'SMTP' }}</strong>) is working properly on <strong>Edu+Connect Guardianship</strong>.
            </p>
            <div class="info-card">
                <div class="info-row">
                    <span class="info-label">Active Provider:</span>
                    <span class="info-value">{{ $provider ?? 'SMTP' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">SMTP Host:</span>
                    <span class="info-value">{{ $host ?? 'N/A' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Port / Encryption:</span>
                    <span class="info-value">{{ $port ?? 587 }} / {{ strtoupper($encryption ?? 'TLS') }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Sender Address:</span>
                    <span class="info-value">{{ $fromAddress ?? 'N/A' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Recipient:</span>
                    <span class="info-value">{{ $recipient ?? 'N/A' }}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Timestamp:</span>
                    <span class="info-value">{{ $timestamp ?? now()->toIso8601String() }}</span>
                </div>
            </div>
            <p style="font-size: 13px; color: #64748b; line-height: 1.5; margin: 0;">
                New users registered with an email will now automatically receive their invitation and access link.
            </p>
        </div>
        <div class="footer">
            &copy; {{ date('Y') }} Edu+Connect &bull; Chewetech Technologies
        </div>
    </div>
</body>
</html>
