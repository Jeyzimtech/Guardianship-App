import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart' show AuthGate;
import 'auth_provider.dart';
import 'student_provider.dart';

/// Replaces the whole navigation stack with [AuthGate], which shows the
/// dashboard (behind the role guard) when signed in and the login screen otherwise.
void resetToAuthGate(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}

/// Single sign-out path used by every logout button.
Future<void> signOut(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  final students = context.read<StudentProvider>();
  final navigator = Navigator.of(context, rootNavigator: true);
  students.clearData();
  await auth.logout();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthGate()),
    (route) => false,
  );
}
