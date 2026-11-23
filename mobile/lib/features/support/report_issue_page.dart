import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/auth_provider.dart';
import '../../core/legal.dart';
import '../common/page_components.dart';
import 'app_info_page.dart';

/// Sends a bug report or feedback to support (stored on the server and emailed to support).
class ReportIssuePage extends StatefulWidget {
  final String category;
  final String? contextDetails;
  const ReportIssuePage({
    super.key,
    this.category = 'bug',
    this.contextDetails,
  });
  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  static const _categories = {
    'bug': 'Something is not working',
    'login': 'Signing in',
    'notifications': 'Notifications or SMS',
    'payments': 'Uniform payments',
    'feedback': 'Suggestion or feedback',
    'safety': 'Report content or a user',
    'other': 'Something else',
  };
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  late String _category = widget.category;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final dio = context.read<AuthProvider>().apiClient.dio;
    final details = await appDetails();
    try {
      await dio.post(
        '/support/reports',
        data: {
          'category': _category,
          'message':
              '${_message.text.trim()}${widget.contextDetails == null ? '' : '\n\nContext: ${widget.contextDetails}'}',
          'app_version': details.version,
          'platform': details.platform,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Thank you. Your report has been sent to our support team.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error =
              'Could not send your report. Check your connection, or send it by email instead.';
        });
      }
    }
  }

  Future<void> _sendByEmail() async {
    final details = await appDetails();
    final opened = await Legal.email(
      subject: 'Edu Connect: ${_categories[_category]}',
      body:
          '${_message.text.trim()}\n${widget.contextDetails ?? ''}\n\n---\nApp ${details.version}\n${details.platform}',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No email app found. Email us at ${Legal.supportEmail}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'Report a problem'),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeading(
              title: 'Report a problem',
              subtitle:
                  'Tell us what went wrong or what we could do better. We reply by email or phone.',
              symbol: AppSymbol.report,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'What is it about?'),
              items: [
                for (final entry in _categories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 18),
            if (widget.contextDetails != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.contextDetails!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            TextFormField(
              controller: _message,
              enabled: !_sending,
              minLines: 5,
              maxLines: 10,
              maxLength: 5000,
              decoration: const InputDecoration(
                labelText: 'What happened?',
                hintText:
                    'What were you doing, what did you expect, and what happened instead?',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? 'Please describe the problem in a little more detail'
                  : null,
            ),
            const Text(
              'Your app version and phone model are included to help us fix the problem.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send report'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _sending ? null : _sendByEmail,
              child: const Text('Send by email instead'),
            ),
          ],
        ),
      ),
    ),
  );
}
