@extends('emails.layout')
@section('title', 'Reset your Edu+Connect password')
@section('preview', 'Use this secure link to choose a new password.')
@section('content')
<h1 style="margin:0 0 20px;font-size:25px;line-height:1.3;">Reset your password</h1>
<p style="margin:0 0 16px;">Hello {{ $name }},</p>
<p style="margin:0 0 24px;">We received a request to reset the password for {{ $email }}. Use the button below to choose a new password.</p>
<table role="presentation" cellspacing="0" cellpadding="0"><tr><td bgcolor="#25428d" style="border-radius:6px;"><a href="{{ $resetUrl }}" style="display:inline-block;padding:13px 24px;color:#ffffff;text-decoration:none;font-weight:bold;font-size:15px;">Reset my password</a></td></tr></table>
<p style="margin:24px 0 6px;font-size:12px;color:#68758a;">If the button does not work, copy this link into your browser:</p>
<p style="margin:0;word-break:break-all;font-size:12px;"><a href="{{ $resetUrl }}" style="color:#25428d;">{{ $resetUrl }}</a></p>
@endsection
