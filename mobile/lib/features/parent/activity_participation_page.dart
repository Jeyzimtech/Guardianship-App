import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class ActivityParticipationPage extends StatefulWidget {
  const ActivityParticipationPage({super.key});
  @override
  State<ActivityParticipationPage> createState() =>
      _ActivityParticipationPageState();
}

class _ActivityParticipationPageState extends State<ActivityParticipationPage> {
  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<StudentProvider>();
    final id = provider.selectedStudent?['id'];
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await provider.apiClient.dio.get(
        '/activities/student/$id',
      );
      if (mounted) {
        setState(
          () => _activities = (response.data['activities'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load activities. Pull down to try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: supportingAppBar(context, 'Tasks & activities'),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            title: 'Beyond the classroom.',
            subtitle:
                'Sports, extra lessons and tasks recorded by your school.',
            symbol: AppSymbol.attendance,
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!)
          else if (_activities.isEmpty)
            const PageEmpty(
              title: 'No activities recorded yet',
              message: 'Participation added by the school will appear here.',
            )
          else
            for (final item in _activities)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? 'Activity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['activity_date']?.toString().split('T').first ??
                            '',
                      ),
                      if ((item['description']?.toString() ?? '')
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(item['description']),
                      ],
                      const SizedBox(height: 12),
                      PageBadge(switch (item['status']) {
                        'present' => 'Took part',
                        'late' => 'Took part · Late',
                        'absent' => 'Did not attend',
                        _ => 'On the register',
                      }),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
