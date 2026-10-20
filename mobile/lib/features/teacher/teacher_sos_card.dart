import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';

class TeacherSosCard extends StatefulWidget {
  const TeacherSosCard({super.key});
  @override
  State<TeacherSosCard> createState() => _TeacherSosCardState();
}

class _TeacherSosCardState extends State<TeacherSosCard> {
  bool _busy = false;
  String? _requestId;
  String? _pendingMessage;

  String _uuid() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _send() async {
    final message = TextEditingController(
      text:
          _pendingMessage ??
          'An emergency has been reported. Please contact the school immediately.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send emergency SOS?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This sends an urgent app alert and SMS to every parent linked to your assigned classes. SMS uses school credits.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: message,
                maxLength: 500,
                maxLines: 4,
                readOnly: _pendingMessage != null,
                decoration: const InputDecoration(
                  labelText: 'Emergency message',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (message.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    final text = message.text.trim();
    // The field remains mounted during its route exit animation.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    message.dispose();
    if (confirmed != true || !mounted) return;
    _requestId ??= _uuid();
    _pendingMessage ??= text;
    setState(() => _busy = true);
    String result;
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/sos',
        data: {'request_id': _requestId, 'message': _pendingMessage},
        options: Options(receiveTimeout: const Duration(seconds: 150)),
      );
      result =
          '${response.data['message']} (${response.data['recipients']} parents)';
      _requestId = null;
      _pendingMessage = null;
    } catch (e) {
      result = e is DioException && e.response?.data is Map
          ? e.response!.data['message']?.toString() ??
                'SOS could not be confirmed.'
          : 'SOS could not be confirmed. Retry to check this same alert, or call the school.';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SOS status'),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.cardBorder),
    ),
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLASSROOM SAFETY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Emergency SOS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reach your families with an urgent alert and SMS, including parents without internet.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.sos_outlined),
            label: Text(
              _busy
                  ? 'Sending SOS...'
                  : _requestId != null
                  ? 'Check / retry SOS'
                  : 'Send SOS to parents',
            ),
          ),
        ],
      ),
    ),
  );
}
