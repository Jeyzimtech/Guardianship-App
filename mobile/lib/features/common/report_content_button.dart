import 'package:flutter/material.dart';
import '../support/report_issue_page.dart';

class ReportContentButton extends StatelessWidget {
  final String details;
  const ReportContentButton({super.key, required this.details});
  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.flag_outlined, size: 18),
    label: const Text('Report content or user'),
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReportIssuePage(category: 'safety', contextDetails: details),
      ),
    ),
  );
}
