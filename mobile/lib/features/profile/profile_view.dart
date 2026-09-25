import 'package:flutter/material.dart';
import 'account_profile_page.dart';

class ProfileView extends StatelessWidget {
  final bool showAppBar;
  const ProfileView({super.key, this.showAppBar = true});
  @override
  Widget build(BuildContext context) =>
      AccountProfilePage(showAppBar: showAppBar);
}
