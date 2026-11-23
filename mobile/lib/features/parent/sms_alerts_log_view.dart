import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/auth_provider.dart';
import '../common/page_components.dart';

/// Text messages the school sent this parent, with the network delivery status.
class SmsAlertsLogView extends StatefulWidget {
  const SmsAlertsLogView({super.key});

  @override
  State<SmsAlertsLogView> createState() => _SmsAlertsLogViewState();
}

class _SmsAlertsLogViewState extends State<SmsAlertsLogView> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .apiClient
          .dio
          .get('/sos/history');
      if (!mounted) return;
      setState(
        () => _messages = (response.data['alerts'] as List? ?? [])
            .map((a) => Map<String, dynamic>.from(a))
            .toList(),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to load SMS history. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  (String, Color) _status(String? status) => switch (status) {
    'accepted' => ('Sent by SMS', const Color(0xFF047857)),
    'pending' || 'sending' => ('SMS sending', AppColors.textMuted),
    _ => ('SMS delivery unconfirmed', const Color(0xFF92400E)),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'SMS history'),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeading(
              title: 'SMS history',
              subtitle: 'Text messages your school sent to your phone.',
              symbol: AppSymbol.message,
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              PageCard(
                child: Column(
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Try again')),
                  ],
                ),
              )
            else if (_messages.isEmpty)
              const PageEmpty(
                title: 'No text messages yet',
                message: 'Urgent messages your school sends by SMS will appear here.',
              )
            else
              for (final m in _messages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PageCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const PageBadge('Emergency SOS', color: Color(0xFFB42318)),
                            PageBadge(_status(m['sms_status']?.toString()).$1, color: _status(m['sms_status']?.toString()).$2),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          m['message']?.toString() ?? '',
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'From ${m['teacher_name'] ?? 'your school'} · ${'${m['created_at'] ?? ''}'.split(RegExp('[T ]')).first}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
