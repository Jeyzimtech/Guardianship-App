import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class LearningJournalView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const LearningJournalView({super.key, this.child});

  @override
  State<LearningJournalView> createState() => _LearningJournalViewState();
}

class _LearningJournalViewState extends State<LearningJournalView> {
  String _selectedFilter = 'all';

  late final List<Map<String, dynamic>> _mockEntries;

  @override
  void initState() {
    super.initState();
    final activeChild =
        widget.child ??
        {
          'name': 'Alice Chewe',
          'class': 'Grade 4 Gold',
          'tier': 'primary',
          'school': 'Hillside Primary School',
        };
    final childName = activeChild['name'] ?? 'Child';
    final isPrep =
        (activeChild['tier'] == 'preparatory') ||
        childName.contains('Alice') ||
        childName.contains('Timothy');

    _mockEntries = [
      if (isPrep) ...[
        {
          'type': 'wellbeing',
          'author': 'Caregiver Amai Tendai',
          'date': 'Today, 11:30 AM',
          'caption':
              'Alice had a wonderful morning during circle time and outdoor play!',
          'wellbeing': {
            'meals': 'Ate all of lunch (chicken & rice)',
            'nap': 'Rested 45 mins quietly',
            'hygiene': 'Hands washed before and after meals',
            'mood': 'Cheerful & Energetic',
          },
        },
        {
          'type': 'drawing',
          'author': 'Caregiver Amai Tendai',
          'date': 'Yesterday, 02:15 PM',
          'caption': 'Finger painting activity: "My Family at Home"',
          'image_url': 'https://picsum.photos/400/300?random=1',
          'feedback': 'Great color choice and hand-eye coordination!',
        },
      ],
      {
        'type': 'photo',
        'author': 'Teacher Grace',
        'date': '2 days ago',
        'subject': 'Science Lab',
        'caption':
            'Demonstrating working solar circuit during Science experiment.',
        'image_url': 'https://picsum.photos/400/300?random=2',
        'feedback': 'Excellent problem solving skills displayed today!',
      },
      {
        'type': 'voice',
        'author': 'Teacher Grace',
        'date': '3 days ago',
        'subject': 'Reading & Phonics',
        'caption': 'Recorded reading sample: "The Adventures of Mufaro"',
        'duration': '1 min 24 sec',
        'feedback': 'Fluent expression and clear pronunciation!',
      },
      {
        'type': 'text',
        'author': 'Teacher Grace',
        'date': '4 days ago',
        'subject': 'Mathematics',
        'caption': 'Achieved 100% score on mental arithmetic speed challenge!',
        'feedback': 'Superb progress this week.',
      },
    ];
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
    final entries = _mockEntries
        .where(
          (entry) =>
              _selectedFilter == 'all' || entry['type'] == _selectedFilter,
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Learning journal'),
      body: SafeArea(
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
            if (entries.isEmpty)
              const PageEmpty(
                title: 'No entries yet',
                message:
                    'Choose another category to explore classroom updates.',
              ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _journalEntry(entry),
              ),
          ],
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
        if (entry['image_url'] != null) ...[
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
