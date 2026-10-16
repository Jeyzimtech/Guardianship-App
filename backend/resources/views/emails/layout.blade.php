<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>@yield('title')</title></head>
<body style="margin:0;padding:0;background:#f5f7fa;color:#172033;font-family:Arial,Helvetica,sans-serif;">
<div style="display:none;max-height:0;overflow:hidden;">@yield('preview')</div>
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f5f7fa;"><tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border:1px solid #e0e6ef;border-radius:12px;">
<tr><td style="padding:28px 32px 22px;border-bottom:1px solid #e0e6ef;font-size:20px;font-weight:bold;color:#25428d;">Edu+Connect</td></tr>
<tr><td style="padding:30px 32px;font-size:15px;line-height:1.7;">@yield('content')</td></tr>
<tr><td style="padding:20px 32px;border-top:1px solid #e0e6ef;font-size:12px;line-height:1.6;color:#68758a;">This link expires in 48 hours and can be used once. If you did not expect this email, you can ignore it.<br>&copy; {{ date('Y') }} Edu+Connect</td></tr>
</table></td></tr></table></body></html>
