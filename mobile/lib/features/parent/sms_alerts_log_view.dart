import 'package:flutter/material.dart';
import '../dashboard/announcements_view.dart';

/// Until an SMS provider and delivery log are configured, school notices are
/// the persisted communication channel available in the app.
class SmsAlertsLogView extends StatelessWidget {
  const SmsAlertsLogView({super.key});

  @override
  Widget build(BuildContext context) => const AnnouncementsView();
}
