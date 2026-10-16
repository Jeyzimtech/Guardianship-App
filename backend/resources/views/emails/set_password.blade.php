@extends('emails.layout')
@section('title', 'Set up your Edu+Connect account')
@section('preview', 'Your account is ready. Choose a password to get started.')
@section('content')
<h1 style="margin:0 0 20px;font-size:25px;line-height:1.3;">Your account is ready</h1>
<p style="margin:0 0 16px;">Hello {{ $name }},</p>
<p style="margin:0 0 16px;">You have been invited to Edu+Connect as {{ $role === 'teacher' ? 'a teacher' : ($role === 'guardian' ? 'a parent or guardian' : 'an administrator') }}. Choose your password to finish setting up your account.</p>
<p style="margin:0 0 24px;"><strong>Sign-in email</strong><br>{{ $email }}</p>
<table role="presentation" cellspacing="0" cellpadding="0"><tr><td bgcolor="#25428d" style="border-radius:6px;"><a href="{{ $setupUrl }}" style="display:inline-block;padding:13px 24px;color:#ffffff;text-decoration:none;font-weight:bold;font-size:15px;">Create my password</a></td></tr></table>
<p style="margin:24px 0 16px;">After setting your password, sign in {{ in_array($role, ['admin','website_admin']) ? 'to the administration portal' : 'to the Edu+Connect app' }} using the email above.</p>
<p style="margin:24px 0 6px;font-size:12px;color:#68758a;">If the button does not work, copy this link into your browser:</p>
<p style="margin:0;word-break:break-all;font-size:12px;"><a href="{{ $setupUrl }}" style="color:#25428d;">{{ $setupUrl }}</a></p>
@endsection
