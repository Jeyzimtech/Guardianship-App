import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import '../../core/subscription_provider.dart';
import '../../core/app_colors.dart';
import '../common/page_components.dart';
import '../../core/app_icon.dart';

const subscriptionPhone = '079 054 3013';

class SubscriptionPage extends StatefulWidget {
  final bool restricted;
  const SubscriptionPage({super.key, this.restricted = false});
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    final access = context.watch<SubscriptionProvider>();
    return PopScope(
      canPop: !widget.restricted,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.restricted,
          title: const Text('Account access'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const PageHeading(
                title: 'Closer to every\nschool day.',
                subtitle:
                    'One place for your child’s learning, progress and school updates.',
                symbol: AppSymbol.report,
              ),
              PageCard(
                color: AppColors.primaryDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR SCHOOL CONNECTION',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.restricted
                          ? 'Your account access'
                          : 'Learning, together.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Follow classroom moments, attendance, homework, activities and school documents. Keep in touch with your child’s teachers.',
                      style: TextStyle(color: Colors.white, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'With active school access',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (final item in [
                'Child information and attendance',
                'Learning journal and homework',
                'Sports, tasks and extra lessons',
                'School documents and academic reports',
                'Teacher messages and school notices',
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(item),
                ),
              const SizedBox(height: 20),
              PageCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account support',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SelectableText(
                      subscriptionPhone,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This app lets existing subscribers access their school records. If your account should already have access, ask your school to check it. The number above is for account support.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (access.loading)
                const Center(child: CircularProgressIndicator()),
              if (access.error != null)
                Text(
                  access.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              for (final child in access.children)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(child['name']?.toString() ?? 'Your child'),
                  subtitle: Text(
                    '${child['school'] ?? ''} · ${child['access_allowed'] == true ? 'Active' : 'Access unavailable'}',
                  ),
                  trailing: widget.restricted && child['access_allowed'] == true
                      ? TextButton(
                          onPressed: () {
                            final students = context.read<StudentProvider>();
                            final matches = students.students.where(
                              (s) => s['id'] == child['id'],
                            );
                            if (matches.isNotEmpty) {
                              students.selectStudent(
                                Map<String, dynamic>.from(matches.first),
                              );
                            }
                          },
                          child: const Text('Open'),
                        )
                      : null,
                ),
              OutlinedButton(
                onPressed: access.loading ? null : access.refresh,
                child: const Text('Refresh account status'),
              ),
              if (widget.restricted)
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    context.read<StudentProvider>().clearData();
                    await context.read<AuthProvider>().logout();
                    navigator.popUntil((route) => route.isFirst);
                  },
                  child: const Text('Sign out'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
