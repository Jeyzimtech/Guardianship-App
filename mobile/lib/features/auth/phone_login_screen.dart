import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/session.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _challenge;
  String? _error;
  bool _busy = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/auth/phone/request',
        data: {'phone_number': _phone.text.trim()},
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      if (!mounted) return;
      setState(() {
        _challenge = response.data['challenge_id'];
        _remaining = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _remaining--);
        if (_remaining <= 0) timer.cancel();
      });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object e) => e is DioException && e.response?.data is Map
      ? e.response!.data['message']?.toString() ?? 'Please try again.'
      : 'Could not connect. Check your connection and try again.';

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the six digit code from your SMS.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().verifyPhoneCode(
        _challenge!,
        _code.text.trim(),
      );
      if (mounted) resetToAuthGate(context);
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Phone verification')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.sms_outlined, size: 40, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              _challenge == null ? 'Welcome back' : 'Check your messages',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the phone number your teacher registered. No email or password is needed. SMS codes expire after five minutes.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phone,
              enabled: !_busy && _challenge == null,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0771234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (_challenge != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: const InputDecoration(
                  labelText: 'SMS verification code',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              TextButton(
                onPressed: _busy || _remaining > 0 ? null : _send,
                child: Text(
                  _remaining > 0 ? 'Resend in ${_remaining}s' : 'Resend code',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _challenge = null;
                        _code.clear();
                      }),
                child: const Text('Use another phone number'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || (_challenge == null && _remaining > 0)
                  ? null
                  : (_challenge == null ? _send : _verify),
              child: Text(
                _busy
                    ? 'Please wait...'
                    : _challenge == null
                    ? 'Send SMS code'
                    : 'Verify and sign in',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
