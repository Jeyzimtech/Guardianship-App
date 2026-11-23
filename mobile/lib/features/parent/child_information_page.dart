import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';
import '../common/student_avatar.dart';

class ChildInformationPage extends StatelessWidget {
  const ChildInformationPage({super.key});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<StudentProvider>().selectedStudent ?? {};
    return Scaffold(
      appBar: supportingAppBar(context, 'Child information'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            title: 'Your child, at a glance.',
            subtitle:
                'Details held by your school. Contact the school to request a correction.',
            symbol: AppSymbol.profile,
          ),
          PageCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudentAvatar(
                  name: child['name']?.toString() ?? 'Your child',
                  photoUrl: child['photo_url'] as String?,
                  size: 72,
                ),
                const SizedBox(height: 20),
                for (final row in [
                  ('Name', child['name']),
                  (
                    'School',
                    child['school'] is Map
                        ? child['school']['name']
                        : child['school'],
                  ),
                  ('Grade', child['grade']),
                  ('Class', child['class_name']),
                  ('Date of birth', child['dob']?.toString().split('T').first),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row.$1),
                    subtitle: Text(row.$2?.toString() ?? 'Not provided'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
