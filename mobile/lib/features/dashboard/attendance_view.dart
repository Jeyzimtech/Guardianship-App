import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class AttendanceView extends StatefulWidget {
  final bool showAppBar;
  const AttendanceView({super.key, this.showAppBar = true});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';

  final List<Map<String, dynamic>> _attendanceRecords = [
    {'date': '17 Sep 2025', 'status': 'PRESENT', 'remarks': 'On time - Morning Assembly', 'time': '07:45 AM'},
    {'date': '16 Sep 2025', 'status': 'PRESENT', 'remarks': 'On time', 'time': '07:48 AM'},
    {'date': '15 Sep 2025', 'status': 'PRESENT', 'remarks': 'On time', 'time': '07:50 AM'},
    {'date': '12 Sep 2025', 'status': 'LATE', 'remarks': '15 mins late - Heavy traffic', 'time': '08:15 AM'},
    {'date': '11 Sep 2025', 'status': 'PRESENT', 'remarks': 'On time', 'time': '07:42 AM'},
    {'date': '10 Sep 2025', 'status': 'PRESENT', 'remarks': 'On time', 'time': '07:46 AM'},
    {'date': '09 Sep 2025', 'status': 'ABSENT', 'remarks': 'Excused medical absence', 'time': '-'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
              title: const Text(
                'Attendance Records',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date & Progress Card
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'September 17, 2025',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '11:32:23 AM',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Blue Gradient Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 4,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Record Attendance Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Record Attendance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Search Bar & Filter Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search date or remarks...',
                        hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.primaryLight, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blueBorder, width: 1),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Pill tag button (Form 2 A)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.blueBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Form 2 A (Term 1 2025)',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Attendance Summary Metrics Card
            Builder(
              builder: (context) {
                final filtered = _attendanceRecords.where((rec) {
                  final status = rec['status'].toString();
                  final date = rec['date'].toString().toLowerCase();
                  final remarks = rec['remarks'].toString().toLowerCase();

                  final matchesStatus = _selectedStatusFilter == 'ALL' || status == _selectedStatusFilter;
                  final matchesSearch = _searchQuery.isEmpty || date.contains(_searchQuery) || remarks.contains(_searchQuery);

                  return matchesStatus && matchesSearch;
                }).toList();

                final presentCount = _attendanceRecords.where((r) => r['status'] == 'PRESENT').length;
                final absentCount = _attendanceRecords.where((r) => r['status'] == 'ABSENT').length;
                final lateCount = _attendanceRecords.where((r) => r['status'] == 'LATE').length;
                final totalDays = _attendanceRecords.length;
                final presentPct = totalDays > 0 ? ((presentCount / totalDays) * 100).toStringAsFixed(1) : '100.0';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Chips Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['ALL', 'PRESENT', 'ABSENT', 'LATE'].map((st) {
                          final isSel = _selectedStatusFilter == st;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(st),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.softBlue,
                              side: BorderSide(color: isSel ? AppColors.primary : AppColors.blueBorder),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _selectedStatusFilter = st);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Term Attendance Summary',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.blueBorder),
                                ),
                                child: Text(
                                  '$presentPct% Attendance',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Present', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('$presentCount Days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Absent', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('$absentCount Days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Late', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('$lateCount Days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Daily Logs',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 10),
                    ...filtered.map((record) {
                      final status = record['status'];
                      final isPresent = status == 'PRESENT';
                      final isLate = status == 'LATE';
                      final statusColor = isPresent
                          ? AppColors.primaryLight
                          : isLate
                              ? AppColors.warning
                              : AppColors.error;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 38,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record['date'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    record['remarks'],
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
