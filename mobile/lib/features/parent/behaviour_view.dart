import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class BehaviourView extends StatefulWidget {
  final Map<String, dynamic>? child;
  const BehaviourView({super.key, this.child});
  @override
  State<BehaviourView> createState() => _BehaviourViewState();
}

class _BehaviourViewState extends State<BehaviourView> {
  String _filter = 'All';
  String _query = '';
  final _search = TextEditingController();
  final _incidents = [
    {
      'polarity': 'positive',
      'category': 'Excellence in Mathematics',
      'note': 'Scored highest mark in mid-term mental arithmetic speed quiz.',
      'author': 'Teacher Grace',
      'date': '2 days ago',
    },
    {
      'polarity': 'positive',
      'category': 'Helpfulness & Leadership',
      'note':
          'Assisted fellow class members in organizing classroom library books.',
      'author': 'Teacher Grace',
      'date': '5 days ago',
    },
    {
      'polarity': 'negative',
      'category': 'Late Homework Submission',
      'note': 'Science observation journal submitted 1 day past due date.',
      'author': 'Teacher Grace',
      'date': '2 weeks ago',
    },
  ];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merits = _incidents.where((i) => i['polarity'] == 'positive').length;
    final notes = _incidents.length - merits;
    // Preserve the existing demonstration house-points tally.
    final points = merits * 5 + 27;
    final filtered = _incidents
        .where(
          (i) =>
              (_filter == 'All' ||
                  (_filter == 'Merits'
                      ? i['polarity'] == 'positive'
                      : i['polarity'] == 'negative')) &&
              '${i['category']} ${i['note']} ${i['author']}'
                  .toLowerCase()
                  .contains(_query),
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Behaviour & merits'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeading(
              title: 'Behaviour & merits',
              subtitle:
                  '${widget.child?['name'] ?? 'Your child'} · Celebrating growth, every day.',
              symbol: AppSymbol.student,
            ),
            PageCard(
              color: AppColors.primaryDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'THIS TERM',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 52,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'House points earned',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text(
                    'Recognising effort, kindness and positive contributions at school.',
                    style: TextStyle(color: Colors.white70, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PageCard(
              child: Wrap(
                spacing: 36,
                runSpacing: 20,
                children: [
                  _stat('$merits', 'Merits recorded', AppColors.primary),
                  _stat('$notes', 'Conduct notes', const Color(0xFF956100)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Small moments worth celebrating.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            const PageCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  PageBadge('Star Reader'),
                  PageBadge('Helpful Peer'),
                  PageBadge('Math Champion'),
                  PageBadge('Punctual'),
                  PageBadge('Clean Desk'),
                  PageBadge('Team Player'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Activity record',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Teacher observations, latest first.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search activity or teacher',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            PageFilters(
              labels: const ['All', 'Merits', 'Conduct notes'],
              selected: _filter,
              onSelected: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 18),
            Text(
              '${filtered.length} ${filtered.length == 1 ? 'record' : 'records'}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              PageCard(
                child: Column(
                  children: [
                    const AppIcon(
                      AppSymbol.report,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No matching activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try another search or view all records.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                        _filter = 'All';
                      }),
                      child: const Text('Reset filters'),
                    ),
                  ],
                ),
              ),
            for (final item in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PageBadge(
                            item['polarity'] == 'positive'
                                ? 'Merit'
                                : 'Conduct note',
                            color: item['polarity'] == 'positive'
                                ? AppColors.primary
                                : const Color(0xFF956100),
                          ),
                          Text(
                            item['date']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['category']!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['note']!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const AppIcon(
                            AppSymbol.teacher,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Recorded by ${item['author']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const PageCard(
              color: AppColors.softBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep the conversation going',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Celebrate a recent achievement together. For a conduct note, ask your child what happened and discuss a helpful next step with their teacher.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    ],
  );
}
