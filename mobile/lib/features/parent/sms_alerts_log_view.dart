import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class SmsAlertsLogView extends StatefulWidget {
  const SmsAlertsLogView({super.key});

  @override
  State<SmsAlertsLogView> createState() => _SmsAlertsLogViewState();
}

class _SmsAlertsLogViewState extends State<SmsAlertsLogView> {
  String _searchQuery = '';

  final List<Map<String, String>> _mockSmsLog = [
    {
      'date': 'July 25, 2026 • 08:30 AM',
      'channel': 'Africa\'s Talking (SMS Delivered)',
      'sender': 'Hillside Primary',
      'message': 'Edu-Connect Alert: Bob Chewe attendance marked PRESENT for Grade 4 Gold.',
    },
    {
      'date': 'July 22, 2026 • 02:15 PM',
      'channel': 'Econet Wireless SMS',
      'sender': 'Hillside Admin',
      'message': 'Fee Alert: Term 2 fee balance outstanding for Alice Chewe (\$150 USD). Please pay via EcoCash or Card in app.',
    },
    {
      'date': 'July 18, 2026 • 09:00 AM',
      'channel': 'Telecel SMS',
      'sender': 'Hillside Prep',
      'message': 'Notice: Early Childhood Sports Day postponed to Friday July 24th due to weather.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _mockSmsLog.where((log) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return log['message']!.toLowerCase().contains(q) ||
          log['sender']!.toLowerCase().contains(q) ||
          log['date']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Guardian SMS Alerts Log',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Info banner for low-connectivity guardians
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.softBlue,
            child: const Row(
              children: [
                Icon(Icons.sms_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SMS guarantees delivery for low-connectivity guardians. Search complete alert history below.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search SMS alerts by keyword or date...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryLight),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // Searchable List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No SMS alerts match your search.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['sender'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                                ),
                                Text(
                                  item['date'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['message'] ?? '',
                              style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  item['channel'] ?? '',
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
