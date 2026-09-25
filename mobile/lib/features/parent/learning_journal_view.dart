import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _mockEntries.where((e) {
      if (_selectedFilter == 'all') return true;
      return e['type'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Learning Journal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Learning journal introduction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.softBlue,
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Follow classroom learning, teacher feedback and everyday progress.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('all', 'All Entries'),
                _buildFilterChip('wellbeing', 'Wellbeing Logs'),
                _buildFilterChip('photo', 'Photos'),
                _buildFilterChip('drawing', 'Drawings'),
                _buildFilterChip('voice', 'Voice Notes'),
                _buildFilterChip('text', 'Notes'),
              ],
            ),
          ),

          // Journal Stream
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(
                    child: Text(
                      'No journal entries match the selected filter.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return _buildJournalCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _selectedFilter = key);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: AppColors.softBlue,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.blueBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> entry) {
    final isWellbeing = entry['type'] == 'wellbeing';
    final hasImage = entry.containsKey('image_url');
    final hasVoice = entry['type'] == 'voice';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              border: Border(bottom: BorderSide(color: AppColors.blueBorder)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    isWellbeing ? Icons.child_care : Icons.face,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['author'] ?? 'Teacher',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        entry['date'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.blueBorder),
                  ),
                  child: Text(
                    isWellbeing
                        ? 'PREPARATORY LOG'
                        : (entry['subject'] ??
                              entry['type'].toString().toUpperCase()),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry['caption'] != null)
                  Text(
                    entry['caption'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),

                // Preparatory Wellbeing Details Box
                if (isWellbeing && entry['wellbeing'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      border: Border.all(color: AppColors.blueBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY WELLBEING SNAPSHOT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildWellbeingRow(
                          Icons.restaurant_rounded,
                          'Meals',
                          entry['wellbeing']['meals'],
                        ),
                        _buildWellbeingRow(
                          Icons.bed_rounded,
                          'Nap / Rest',
                          entry['wellbeing']['nap'],
                        ),
                        _buildWellbeingRow(
                          Icons.clean_hands_rounded,
                          'Hygiene',
                          entry['wellbeing']['hygiene'],
                        ),
                        _buildWellbeingRow(
                          Icons.sentiment_satisfied_alt_rounded,
                          'Mood',
                          entry['wellbeing']['mood'],
                        ),
                      ],
                    ),
                  ),
                ],

                // Image Work Sample
                if (hasImage) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      border: Border.all(color: AppColors.blueBorder),
                    ),
                    child: Image.network(
                      entry['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.softBlue,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Voice Note Sample
                if (hasVoice) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      border: Border.all(color: AppColors.blueBorder),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voice Recording',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Audio sample • Click to play',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          entry['duration'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Teacher Feedback Note
                if (entry['feedback'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      border: Border.all(color: AppColors.blueBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Teacher Feedback: ${entry['feedback']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingRow(IconData icon, String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
