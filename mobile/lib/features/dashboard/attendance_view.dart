import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../common/page_components.dart';

class AttendanceView extends StatefulWidget {
  final bool showAppBar;
  const AttendanceView({super.key, this.showAppBar = true});
  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _status = 'All';
  final List<Map<String, dynamic>> _attendanceRecords = [
    {
      'date': '17 Sep 2025',
      'status': 'PRESENT',
      'remarks': 'On time - Morning Assembly',
      'time': '07:45 AM',
    },
    {
      'date': '16 Sep 2025',
      'status': 'PRESENT',
      'remarks': 'On time',
      'time': '07:48 AM',
    },
    {
      'date': '15 Sep 2025',
      'status': 'PRESENT',
      'remarks': 'On time',
      'time': '07:50 AM',
    },
    {
      'date': '12 Sep 2025',
      'status': 'LATE',
      'remarks': '15 mins late - Heavy traffic',
      'time': '08:15 AM',
    },
    {
      'date': '11 Sep 2025',
      'status': 'PRESENT',
      'remarks': 'On time',
      'time': '07:42 AM',
    },
    {
      'date': '10 Sep 2025',
      'status': 'PRESENT',
      'remarks': 'On time',
      'time': '07:46 AM',
    },
    {
      'date': '09 Sep 2025',
      'status': 'ABSENT',
      'remarks': 'Excused medical absence',
      'time': '-',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _query = '';
    _status = 'All';
    _searchController.clear();
  });

  Color _color(String status) => switch (status) {
    'PRESENT' => AppColors.primary,
    'LATE' => const Color(0xFF956100),
    _ => const Color(0xFFB42318),
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _attendanceRecords
        .where(
          (r) =>
              (_status == 'All' || r['status'] == _status.toUpperCase()) &&
              '${r['date']} ${r['remarks']}'.toLowerCase().contains(_query),
        )
        .toList();
    final present = _attendanceRecords
        .where((r) => r['status'] == 'PRESENT')
        .length;
    final late = _attendanceRecords.where((r) => r['status'] == 'LATE').length;
    final absent = _attendanceRecords
        .where((r) => r['status'] == 'ABSENT')
        .length;
    final total = _attendanceRecords.length;
    final rate = total == 0 ? 0.0 : (present + late) / total;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? supportingAppBar(context, 'Attendance records')
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeading(
              title: 'Attendance records',
              subtitle: 'Every school day, clearly recorded.',
              symbol: AppSymbol.attendance,
            ),
            PageCard(
              color: AppColors.primaryDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SEPTEMBER 2025',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(rate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Attendance rate',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 6,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${present + late} of $total recorded days attended, including late arrivals.',
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PageCard(
              child: Wrap(
                spacing: 28,
                runSpacing: 20,
                children: [
                  for (final item in [
                    ('Present', present),
                    ('Late', late),
                    ('Absent', absent),
                  ])
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.$2}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: _color(item.$1.toUpperCase()),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Daily records',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Latest first',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search date or remarks',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            PageFilters(
              labels: const ['All', 'Present', 'Late', 'Absent'],
              selected: _status,
              onSelected: (value) => setState(() => _status = value),
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
                      AppSymbol.attendance,
                      size: 32,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No matching records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try another date, remark or status.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset filters'),
                    ),
                  ],
                ),
              ),
            for (final record in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        runSpacing: 10,
                        children: [
                          Text(
                            record['date'],
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          PageBadge(
                            record['status']
                                .toString()
                                .toLowerCase()
                                .replaceFirstMapped(
                                  RegExp(r'^.'),
                                  (m) => m[0]!.toUpperCase(),
                                ),
                            color: _color(record['status']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        record['time'] == '-'
                            ? 'No check-in recorded'
                            : 'Checked in at ${record['time']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record['remarks'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
