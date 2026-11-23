import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/legal.dart';
import '../common/page_components.dart';
import 'report_issue_page.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqs = [
    (
      'I cannot sign in',
      'Use the phone number or email your school registered. If you forgot your password, tap "Forgot password" on the sign-in screen. If your school has not added you yet, ask your child\'s teacher.',
    ),
    (
      'My child is not showing',
      'Your child\'s teacher links learners to parent accounts. Ask the teacher to check your phone number on the class list.',
    ),
    (
      'I am not getting notifications',
      'Allow notifications for Edu Connect in your phone settings and keep the app signed in. SMS alerts go to the phone number in your profile.',
    ),
    (
      'My uniform payment is not showing',
      'Open the order in the Uniform store and tap "Check payment status". If it still shows unpaid after paying, send us a report with the order number.',
    ),
    ('How do I change my details?', 'Open Profile and tap "Edit profile".'),
    (
      'How do I delete my account?',
      'Open Profile and tap "Delete account". This cannot be undone.',
    ),
  ];

  Future<void> _email(BuildContext context) async {
    if (!await Legal.email() && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: Legal.supportEmail));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email app found. Address copied: ${Legal.supportEmail}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'Help center'),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeading(
            title: 'Help center',
            subtitle: 'Answers to common questions, and how to reach us.',
            symbol: AppSymbol.message,
          ),
          PageCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact support',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const SelectableText(
                  Legal.supportEmail,
                  style: TextStyle(fontSize: 15, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'We usually reply within two working days.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _email(context),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Email us'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ReportIssuePage(category: 'safety'),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Report content or user'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportIssuePage(),
                        ),
                      ),
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: const Text('Report a problem'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Common questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          PageCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                for (final (question, answer) in _faqs)
                  ExpansionTile(
                    shape: const Border(),
                    title: Text(
                      question,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer,
                        style: const TextStyle(
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
