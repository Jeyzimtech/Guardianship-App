import 'package:flutter/material.dart';

class LearningJournalView extends StatefulWidget {
  final Map<String, dynamic>? child;

  const LearningJournalView({super.key, this.child});

  @override
  State<LearningJournalView> createState() => _LearningJournalViewState();
}

class _LearningJournalViewState extends State<LearningJournalView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);

  String _selectedFilter = 'all';

  late final List<Map<String, dynamic>> _mockEntries;

  @override
  void initState() {
    super.initState();
    final activeChild = widget.child ?? {
      'name': 'Alice Chewe',
      'class': 'Grade 4 Gold',
      'tier': 'primary',
      'school': 'Hillside Primary School',
    };
    final childName = activeChild['name'] ?? 'Child';
    final isPrep = (activeChild['tier'] == 'preparatory') || childName.contains('Alice') || childName.contains('Timothy');

    _mockEntries = [
      if (isPrep) ...[
        {
          'type': 'wellbeing',
          'author': 'Caregiver Amai Tendai',
          'date': 'Today, 11:30 AM',
          'caption': 'Alice had a wonderful morning during circle time and outdoor play!',
          'wellbeing': {
            'meals': 'Ate all of lunch (chicken & rice)',
            'nap': 'Rested 45 mins quietly',
            'hygiene': 'Hands washed before and after meals',
            'mood': 'Cheerful & Energetic'
          },
          'fee_gated': false,
        },
        {
          'type': 'drawing',
          'author': 'Caregiver Amai Tendai',
          'date': 'Yesterday, 02:15 PM',
          'caption': 'Finger painting activity: "My Family at Home"',
          'image_url': 'https://picsum.photos/400/300?random=1',
          'feedback': 'Great color choice and hand-eye coordination!',
          'fee_gated': false,
        },
      ],
      {
        'type': 'photo',
        'author': 'Teacher Grace',
        'date': '2 days ago',
        'subject': 'Science Lab',
        'caption': 'Demonstrating working solar circuit during Science experiment.',
        'image_url': 'https://picsum.photos/400/300?random=2',
        'feedback': 'Excellent problem solving skills displayed today!',
        'fee_gated': false,
      },
      {
        'type': 'voice',
        'author': 'Teacher Grace',
        'date': '3 days ago',
        'subject': 'Reading & Phonics',
        'caption': 'Recorded reading sample: "The Adventures of Mufaro"',
        'duration': '1 min 24 sec',
        'feedback': 'Fluent expression and clear pronunciation!',
        'fee_gated': false,
      },
      {
        'type': 'text',
        'author': 'Teacher Grace',
        'date': '4 days ago',
        'subject': 'Mathematics',
        'caption': 'Achieved 100% score on mental arithmetic speed challenge!',
        'feedback': 'Superb progress this week.',
        'fee_gated': false,
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Learning Journal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${widget.child?['name'] ?? 'Student'} • Running Work Record',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Reassurance & Fee-Ungated Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFEFF6FF),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Day-to-day learning journal & wellbeing logs are NEVER fee-gated. Always visible.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue.withValues(alpha: 0.9),
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
                    child: Text('No journal entries match the selected filter.', style: TextStyle(color: Colors.grey)),
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
        selectedColor: primaryBlue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            decoration: BoxDecoration(
              color: isWellbeing ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isWellbeing ? const Color(0xFF10B981) : primaryBlue,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        entry['date'] ?? '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isWellbeing
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isWellbeing
                        ? 'PREPARATORY LOG'
                        : (entry['subject'] ?? entry['type'].toString().toUpperCase()),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isWellbeing ? const Color(0xFF15803D) : const Color(0xFF1E40AF),
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
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),

                // Preparatory Wellbeing Details Box
                if (isWellbeing && entry['wellbeing'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY WELLBEING SNAPSHOT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        _buildWellbeingRow(Icons.restaurant_rounded, 'Meals', entry['wellbeing']['meals']),
                        _buildWellbeingRow(Icons.bed_rounded, 'Nap / Rest', entry['wellbeing']['nap']),
                        _buildWellbeingRow(Icons.clean_hands_rounded, 'Hygiene', entry['wellbeing']['hygiene']),
                        _buildWellbeingRow(Icons.sentiment_satisfied_alt_rounded, 'Mood', entry['wellbeing']['mood']),
                      ],
                    ),
                  ),
                ],

                // Image Work Sample
                if (hasImage) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: Image.network(
                        entry['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.image, size: 48, color: Colors.grey),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: primaryBlue,
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Voice Recording', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Audio sample • Click to play', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          entry['duration'] ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: const Border(left: BorderSide(color: secondaryBlue, width: 3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: secondaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Teacher Feedback: ${entry['feedback']}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF1E3A8A)),
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
        children: [
          Icon(icon, size: 14, color: primaryBlue),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
