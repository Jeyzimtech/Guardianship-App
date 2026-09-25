import 'package:flutter/material.dart';
import '../profile/account_profile_page.dart';

class GuardianProfileView extends StatelessWidget {
  final Map<String, dynamic> child;
  const GuardianProfileView({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      AccountProfilePage(parent: true, child: child);
}
