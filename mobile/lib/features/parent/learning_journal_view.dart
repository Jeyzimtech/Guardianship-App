import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/student_provider.dart';
import '../../core/auth_provider.dart';
import '../teacher/teacher_publish_page.dart';
import '../common/page_components.dart';

class LearningJournalView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const LearningJournalView({super.key, this.child});

  @override
  State<LearningJournalView> createState() => _LearningJournalViewState();
}

class _LearningJournalViewState extends State<LearningJournalView> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEntries());
  }

  Future<void> _fetchEntries() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final studentId = context.read<AuthProvider>().isTeacher
        ? null
        : widget.child?['id'] ??
              context.read<StudentProvider?>()?.selectedStudent?['id'];
    try {
      final dio = context.read<AuthProvider>().apiClient.dio;
      final endpoint = studentId != null ? '/journal/$studentId' : '/journal';
      final res = await dio.get(endpoint);
      final rawEntries = studentId != null
          ? res.data?['data']?['entries']
          : res.data?['entries'];
      if (res.statusCode == 200 && rawEntries is List) {
        final list = List<Map<String, dynamic>>.from(
          rawEntries.map((e) {
            final map = Map<String, dynamic>.from(e);
            return {
              'id': map['id'],
              'type': map['type'] ?? 'text',
              'author': map['author_name'] ?? 'Teacher',
              'date': map['created_at'] ?? map['created_at_date'] ?? '',
              'subject': map['class_name'] ?? map['grade'] ?? 'Classroom',
              'caption': map['caption'] ?? '',
              'image_url': map['media_url'],
              'feedback': map['feedback'] ?? '',
              'wellbeing': map['wellbeing_data'],
            };
          }),
        );
        if (mounted) {
          setState(() {
            _entries = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Journal fetch error: $e');
    }
    if (mounted) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
    }
  }

  static const _filters = {
    'All entries': 'all',
    'Wellbeing': 'wellbeing',
    'Photos': 'photo',
    'Drawings': 'drawing',
    'Voice notes': 'voice',
    'Notes': 'text',
  };

  @override
  Widget build(BuildContext context) {
    final entries = _entries
        .where(
          (entry) =>
              _selectedFilter == 'all' || entry['type'] == _selectedFilter,
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Learning journal'),
      floatingActionButton: context.watch<AuthProvider>().isTeacher
          ? FloatingActionButton.extended(
              label: const Text('Post an entry'),
              onPressed: () async {
                final posted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherPublishPage()),
                );
                if (posted == true && mounted) _fetchEntries();
              },
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchEntries,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PageHeading(
                title: 'Little moments.\nMeaningful progress.',
                subtitle: widget.child == null
                    ? 'Learning, wellbeing and classroom stories.'
                    : '${widget.child!['name']} · Learning journal',
                symbol: AppSymbol.report,
              ),
              PageFilters(
                labels: _filters.keys.toList(),
                selected: _filters.entries
                    .firstWhere((entry) => entry.value == _selectedFilter)
                    .key,
                onSelected: (label) =>
                    setState(() => _selectedFilter = _filters[label]!),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (entries.isEmpty)
                const PageEmpty(
                  title: 'No journal entries yet',
                  message:
                      'Classroom moments and wellbeing logs posted by teachers and administrators will appear here.',
                )
              else
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _journalEntry(entry),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journalEntry(Map<String, dynamic> entry) => PageCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AppIcon(
                AppSymbol.teacher,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['author'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry['date'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PageBadge(
          entry['subject'] ??
              _filters.entries
                  .firstWhere((filter) => filter.value == entry['type'])
                  .key,
        ),
        const SizedBox(height: 14),
        if (entry['caption'] != null)
          Text(
            entry['caption'],
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        if (entry['wellbeing'] != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TODAY’S WELLBEING',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in {
                  'Meals': 'meals',
                  'Rest': 'nap',
                  'Hygiene': 'hygiene',
                  'Mood': 'mood',
                }.entries)
                  if (entry['wellbeing'][item.value] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry['wellbeing'][item.value],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
        if (entry['image_url'] != null &&
            !['photo', 'drawing'].contains(entry['type']))
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(entry['image_url']);
              if (uri == null || !['https', 'http'].contains(uri.scheme)) {
                return;
              }
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open this media.')),
                );
              }
            },
            child: Text(
              entry['type'] == 'link'
                  ? 'Open learning link'
                  : 'Open ${entry['type']}',
            ),
          ),
        if (entry['image_url'] != null &&
            ['photo', 'drawing'].contains(entry['type'])) ...[
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                entry['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => Container(
                  color: AppColors.softBlue,
                  alignment: Alignment.center,
                  child: const Text(
                    'Photo unavailable',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (entry['type'] == 'voice') ...[
          const SizedBox(height: 18),
          PageBadge('Voice note · ${entry['duration']}'),
        ],
        if (entry['feedback'] != null) ...[
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Teacher’s note',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry['feedback'],
            style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ],
    ),
  );
}
