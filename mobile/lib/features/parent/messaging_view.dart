import 'package:flutter/material.dart';
import '../dashboard/announcements_view.dart';

/// Conversation delivery is not configured yet. Show persisted school notices
/// here instead of presenting mock conversations as real messages.
class MessagingView extends StatelessWidget {
  const MessagingView({super.key});

  @override
  Widget build(BuildContext context) => const AnnouncementsView();
}
