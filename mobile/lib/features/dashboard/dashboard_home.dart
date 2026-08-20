import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../parent/parent_shell.dart';
import '../teacher/teacher_shell.dart';

/// Routes to the correct role shell after login.
/// Each shell owns its own Scaffold (AppBar + Drawer + BottomNav).
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isTeacher) {
          return const TeacherShell();
        }
        return const ParentShell();
      },
    );
  }
}
