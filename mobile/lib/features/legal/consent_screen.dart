import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/legal.dart';
import '../common/page_components.dart';
import 'legal_document_page.dart';

/// Shows [ConsentScreen] until the current privacy policy and terms are accepted.
class ConsentGate extends StatefulWidget {
  final Widget child;
  const ConsentGate({super.key, required this.child});
  @override
  State<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<ConsentGate> {
  bool? _accepted;

  @override
  void initState() {
    super.initState();
    Legal.hasAccepted().then((value) {
      if (mounted) setState(() => _accepted = value);
    });
  }

  @override
  Widget build(BuildContext context) => switch (_accepted) {
    null => const Scaffold(backgroundColor: AppColors.background),
    true => widget.child,
    false => ConsentScreen(onAccepted: () => setState(() => _accepted = true)),
  };
}

class ConsentScreen extends StatelessWidget {
  final VoidCallback onAccepted;
  const ConsentScreen({super.key, required this.onAccepted});

  static const _points = [
    'Your school uses Edu Connect to share attendance, homework, reports, notices and safety alerts with you.',
    'We store your contact details and the learner records your school adds.',
    'We send notifications and SMS alerts about your child. We do not show ads or sell your information.',
    'You can edit your details or delete your account at any time from your profile.',
  ];

  Future<void> _accept() async {
    await Legal.accept();
    onAccepted();
  }

  void _explain(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('That\'s okay. Here it is simply:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'Edu Connect is how your school talks to you about your child. To do that, the school keeps your name and phone number and your child\'s school records in the app. Only your school and your child\'s teachers can see them. Nobody else gets your information to advertise to you.\n\n'
              'You must agree before you can use the app. If you are still unsure, ask your school or email us and we will explain.',
              style: TextStyle(height: 1.6, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                if (!await Legal.email(subject: 'Question about the Edu Connect privacy policy') && sheet.mounted) {
                  ScaffoldMessenger.of(sheet).showSnackBar(const SnackBar(content: Text('Email us at ${Legal.supportEmail}')));
                }
              },
              icon: const Icon(Icons.mail_outline),
              label: const Text('Email us a question'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.push(sheet, MaterialPageRoute(builder: (_) => const LegalDocumentPage())),
              child: const Text('Read the privacy policy'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(sheet),
              child: const Text('Go back'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Close the app'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/e.png', height: 48, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
          const SizedBox(height: 20),
          const Text('Before you start', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
          const SizedBox(height: 6),
          const Text(
            'Please read how Edu Connect uses your information.',
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          PageCard(
            child: Column(
              children: [
                for (final point in _points)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 12),
                          child: Icon(Icons.check_circle_outline, size: 20, color: AppColors.primary),
                        ),
                        Expanded(child: Text(point, style: const TextStyle(height: 1.55))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentPage())),
                child: const Text('Privacy policy'),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalDocumentPage(terms: true))),
                child: const Text('Terms of use'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'By tapping "I understand and agree" you accept the Privacy policy and Terms of use.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _accept, child: const Text('I understand and agree')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => _explain(context), child: const Text('I don\'t understand')),
        ],
      ),
    ),
  );
}
