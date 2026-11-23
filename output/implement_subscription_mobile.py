from pathlib import Path
r=Path('mobile/lib')
(r/'core/subscription_provider.dart').write_text('''import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  AuthProvider? _auth;
  String? _identity;
  Timer? _timer;
  int _generation = 0;
  bool loading = true;
  bool allowed = false;
  String? error;
  List<Map<String, dynamic>> children = [];

  void bind(AuthProvider auth) {
    final identity = auth.isAuthenticated && auth.isGuardian
        ? '${auth.user?['id']}:${auth.token}' : null;
    if (identity == _identity) return;
    _identity = identity;
    _auth = auth;
    _generation++;
    _timer?.cancel();
    children = [];
    allowed = false;
    loading = identity != null;
    error = null;
    if (identity == null) return;
    scheduleMicrotask(refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_identity == null) return;
    final generation = _generation;
    try {
      final response = await _auth!.apiClient.dio.get('/subscription');
      if (generation != _generation) return;
      allowed = response.data['access_allowed'] == true;
      children = (response.data['children'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e)).toList();
      error = null;
    } catch (_) {
      if (generation != _generation) return;
      error = 'We could not check your subscription. Please try again.';
      allowed = false;
    }
    loading = false;
    notifyListeners();
  }

  InterceptorsWrapper get interceptor => InterceptorsWrapper(onError: (e, h) {
    if (e.response?.data is Map && e.response?.data['code'] == 'subscription_suspended') {
      allowed = false;
      notifyListeners();
      refresh();
    }
    h.next(e);
  });

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
''')
(r/'features/parent/subscription_page.dart').write_text('''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/subscription_provider.dart';
import '../../core/app_colors.dart';
import '../common/page_components.dart';

const subscriptionPhone = '079 054 3013';

Future<void> showSubscriptionNotice(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  if (!auth.isGuardian) return;
  final prefs = await SharedPreferences.getInstance();
  final key = 'subscription_notice_${auth.user?['id'] ?? auth.user?['email']}';
  if (prefs.getBool(key) == true || !context.mounted) return;
  await prefs.setBool(key, true);
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Stay connected to school'),
    content: const Text('Your account is ready. For subscription information and activation, contact $subscriptionPhone. Your school records become available once your subscription is active.'),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood'))],
  ));
}

class SubscriptionPage extends StatefulWidget {
  final bool restricted;
  const SubscriptionPage({super.key, this.restricted = false});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}
class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showSubscriptionNotice(context));
  }
  @override
  Widget build(BuildContext context) {
    final access = context.watch<SubscriptionProvider>();
    return PopScope(canPop: !widget.restricted, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(automaticallyImplyLeading: !widget.restricted, title: const Text('Subscription')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(title: 'Closer to every\nschool day.', subtitle: 'One place for your child’s learning, progress and school updates.', symbol: AppSymbolPlaceholder.symbol),
        PageCard(color: AppColors.primaryDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR SCHOOL CONNECTION', style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Text(widget.restricted ? 'Let’s get you connected' : 'Learning, together.', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Follow classroom moments, attendance, homework, activities and school documents. Keep in touch with your child’s teachers.', style: TextStyle(color: Colors.white, height: 1.6)),
        ])),
        const SizedBox(height: 24),
        const Text('Your subscription opens', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final item in ['Child information and attendance', 'Learning journal and homework', 'Sports, tasks and extra lessons', 'School documents and academic reports', 'Teacher messages and school notices'])
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline, color: AppColors.primary), title: Text(item)),
        const SizedBox(height: 20),
        PageCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Activation & information', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const SelectableText(subscriptionPhone, style: TextStyle(color: AppColors.primary, fontSize: 27, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text('Your account comes first. Contact us with your account and school details to arrange subscription activation. School fee payments do not activate a subscription.', style: TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () async {
            final opened = await launchUrl(Uri(scheme: 'tel', path: '0790543013'));
            if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please call $subscriptionPhone.')));
          }, icon: const Icon(Icons.phone_outlined), label: const Text('Contact for activation')),
        ])),
        const SizedBox(height: 20),
        if (access.loading) const Center(child: CircularProgressIndicator()),
        if (access.error != null) Text(access.error!, style: const TextStyle(color: AppColors.error)),
        for (final child in access.children) ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(child['name']?.toString() ?? 'Your child'),
          subtitle: Text('${child['school'] ?? ''} · ${child['access_allowed'] == true ? 'Active' : 'Activation needed'}'),
          trailing: widget.restricted && child['access_allowed'] == true ? TextButton(onPressed: () {
            final students = context.read<StudentProvider>();
            final matches = students.students.where((s) => s['id'] == child['id']);
            if (matches.isNotEmpty) students.selectStudent(Map<String, dynamic>.from(matches.first));
          }, child: const Text('Open')) : null,
        ),
        OutlinedButton(onPressed: access.loading ? null : access.refresh, child: const Text('Check activation status')),
        if (widget.restricted) TextButton(onPressed: () async {
          context.read<StudentProvider>().clearData();
          await context.read<AuthProvider>().logout();
        }, child: const Text('Sign out')),
      ])),
    ));
  }
}
'''.replace("import '../common/page_components.dart';", "import '../common/page_components.dart';\nimport '../../core/app_icon.dart';").replace('AppSymbolPlaceholder.symbol', 'AppSymbol.report'))
(r/'features/parent/subscription_boundary.dart').write_text('''import 'package:flutter/material.dart';
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
class _SubscriptionBoundaryState extends State<SubscriptionBoundary> with WidgetsBindingObserver {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<SubscriptionProvider>().refresh();
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final access = context.watch<SubscriptionProvider>();
    final selected = context.watch<StudentProvider>().selectedStudent?['id'];
    final blockedChild = access.children.any((c) => c['id'] == selected && c['access_allowed'] != true);
    final blocked = auth.isAuthenticated && auth.isGuardian && (access.loading || !access.allowed || blockedChild);
    return Stack(children: [
      Offstage(offstage: blocked, child: TickerMode(enabled: !blocked, child: widget.child)),
      if (blocked) Positioned.fill(child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const SubscriptionPage(restricted: true)),
      )),
    ]);
  }
}
''')
p=r/'main.dart';s=p.read_text().replace("import 'core/student_provider.dart';", "import 'core/student_provider.dart';\nimport 'core/subscription_provider.dart';\nimport 'features/parent/subscription_boundary.dart';")
s=s.replace('  runApp(\n', '  final subscription = SubscriptionProvider();\n  apiClient.dio.interceptors.add(subscription.interceptor);\n  runApp(\n')
s=s.replace('        ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),', '''        ChangeNotifierProvider(create: (_) => StudentProvider(apiClient)),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => subscription,
          update: (_, auth, access) => access!..bind(auth),
        ),''')
s=s.replace('      navigatorKey: navigatorKey,', '      navigatorKey: navigatorKey,\n      builder: (context, child) => SubscriptionBoundary(child: child!),');p.write_text(s)
p=r/'features/parent/parent_shell.dart';s=p.read_text().replace("import 'sos_listener.dart';", "import 'sos_listener.dart';\nimport 'subscription_page.dart';");s=s.replace('      Provider.of<StudentProvider>(context, listen: false).fetchStudents();', '      Provider.of<StudentProvider>(context, listen: false).fetchStudents();\n      showSubscriptionNotice(context);');p.write_text(s)
p=r/'features/teacher/teacher_publish_page.dart';s=p.read_text().replace("                                        'drawing': 'Drawing',\n",'');p.write_text(s)
