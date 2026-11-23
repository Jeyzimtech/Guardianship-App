import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/subscription_provider.dart';
import 'subscription_page.dart';

/// This sits above the app navigator, so open pages and Back cannot bypass it.
class SubscriptionBoundary extends StatefulWidget {
  final Widget child;
  const SubscriptionBoundary({super.key, required this.child});
  @override
  State<SubscriptionBoundary> createState() => _SubscriptionBoundaryState();
}

class _SubscriptionBoundaryState extends State<SubscriptionBoundary>
    with WidgetsBindingObserver {
  bool _wasBlocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SubscriptionProvider?>()?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || !auth.isGuardian) {
      _wasBlocked = true;
      return widget.child;
    }
    final access = context.watch<SubscriptionProvider>();
    final selected = context.watch<StudentProvider>().selectedStudent?['id'];
    final blockedChild = access.children.any(
      (c) => c['id'] == selected && c['access_allowed'] != true,
    );
    final blocked =
        auth.isAuthenticated &&
        auth.isGuardian &&
        (access.loading || !access.allowed || blockedChild);
    if (_wasBlocked &&
        !blocked &&
        auth.isGuardian &&
        context.read<StudentProvider>().students.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<StudentProvider>().fetchStudents();
      });
    }
    _wasBlocked = blocked;
    return Stack(
      children: [
        Offstage(
          offstage: blocked,
          child: TickerMode(enabled: !blocked, child: widget.child),
        ),
        if (blocked)
          Positioned.fill(
            child: HeroControllerScope.none(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const SubscriptionPage(restricted: true),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
