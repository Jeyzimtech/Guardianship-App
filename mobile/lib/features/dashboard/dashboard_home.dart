import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import 'reports_view.dart';
import 'attendance_view.dart';
import 'payments_view.dart';
import 'announcements_view.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlueColor = Color(0xFF002D62);
    const cardBgColor = Color(0xFFFFFDF0);

    final List<Widget> tabs = [
      const OverviewTab(),
      const ReportsView(),
      const AttendanceView(),
      const PaymentsView(),
      const AnnouncementsView(),
    ];

    return Scaffold(
      backgroundColor: vanillaColor,
      appBar: AppBar(
        backgroundColor: oldDarkBlueColor,
        elevation: 2,
        title: user?['role'] == 'guardian'
            ? _buildChildSwitcher(context, studentProvider, oldDarkBlueColor, cardBgColor)
            : Text(
                user?['name'] ?? 'Dashboard',
                style: const TextStyle(color: vanillaColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: vanillaColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: oldDarkBlueColor, width: 1.5),
                  ),
                  title: const Text('Logout', style: TextStyle(color: oldDarkBlueColor, fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to sign out?', style: TextStyle(color: oldDarkBlueColor)),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: oldDarkBlueColor, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                      onPressed: () {
                        Navigator.pop(context);
                        authProvider.logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: studentProvider.isLoadingStudents
          ? const Center(child: CircularProgressIndicator(color: oldDarkBlueColor))
          : studentProvider.students.isEmpty
              ? _buildEmptyState(user)
              : tabs[_currentIndex],
      bottomNavigationBar: studentProvider.students.isEmpty
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: oldDarkBlueColor,
              selectedItemColor: vanillaColor,
              unselectedItemColor: Colors.white60,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month),
                  label: 'Attendance',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.payment_outlined),
                  activeIcon: Icon(Icons.payment),
                  label: 'Payments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.campaign_outlined),
                  activeIcon: Icon(Icons.campaign),
                  label: 'Announcements',
                ),
              ],
            ),
    );
  }

  Widget _buildChildSwitcher(
      BuildContext context, StudentProvider provider, Color darkBlue, Color cardBg) {
    if (provider.students.isEmpty) {
      return const Text('Edu+Conect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
    }
    
    final selected = provider.selectedStudent;
    if (selected == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: darkBlue, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: provider.students.firstWhere(
            (element) => element['id'] == selected['id'],
            orElse: () => provider.students.first,
          ),
          dropdownColor: cardBg,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
          items: provider.students.map((dynamic item) {
            final student = item as Map<String, dynamic>;
            return DropdownMenuItem<Map<String, dynamic>>(
              value: student,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(student['name'] ?? '', style: const TextStyle(color: Colors.black)),
                ],
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? newStudent) {
            if (newStudent != null) {
              provider.selectStudent(newStudent);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(Map<String, dynamic>? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 72, color: const Color(0xFF002D62).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Student Records Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D62)),
            ),
            const SizedBox(height: 8),
            Text(
              user?['role'] == 'guardian'
                  ? 'Your account has not been linked to any students yet. Please contact the school administration office to link your children.'
                  : 'There are no students registered in your school class yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF002D62)),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    const oldDarkBlueColor = Color(0xFF002D62);

    if (studentProvider.isLoadingDashboard || studentProvider.dashboardData == null) {
      return const Center(child: CircularProgressIndicator(color: oldDarkBlueColor));
    }

    final data = studentProvider.dashboardData!;
    final attendance = data['attendance_snapshot'];
    final fee = data['fee_snapshot'];
    final zScoreTrend = data['z_score_trend'] as List<dynamic>;
    final velocityStatus = data['velocity_engine_status'] ?? 'OPTIMAL';
    final announcements = data['recent_announcements'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: () => studentProvider.fetchDashboard(studentProvider.selectedStudent!['id']),
      color: oldDarkBlueColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Class Badge & Classic Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentProvider.selectedStudent!['name'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: oldDarkBlueColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade ${studentProvider.selectedStudent!['grade']} • ${studentProvider.selectedStudent!['class_name']}',
                      style: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _buildStatusBadge(velocityStatus),
              ],
            ),
            const SizedBox(height: 20),

            // Attendance & Fee Snapshot Cards
            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Attendance YTD',
                    value: '${attendance['percentage']}%',
                    subtitle: '${attendance['present_days']}/${attendance['total_days']} Days Present',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Fee Balance Due',
                    value: '\$${fee['balance_usd']}',
                    subtitle: '${fee['balance_zig']} ZiG Outstanding',
                    icon: Icons.assignment_turned_in_rounded,
                    color: double.parse(fee['balance_usd'].toString()) > 0 || double.parse(fee['balance_zig'].toString()) > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Academic Trajectory Chart
            const Text(
              'Academic Z-Score History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: oldDarkBlueColor),
            ),
            const SizedBox(height: 12),
            _buildZScoreChart(zScoreTrend, oldDarkBlueColor),
            const SizedBox(height: 24),

            // Recent Announcements List
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent School Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: oldDarkBlueColor),
                ),
                Icon(Icons.campaign_rounded, color: oldDarkBlueColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            if (announcements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No recent announcements.', style: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.5))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: announcements.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final alert = announcements[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: oldDarkBlueColor,
                        child: Icon(Icons.announcement_rounded, color: Color(0xFFF3E5AB), size: 18),
                      ),
                      title: Text(
                        alert['title'] ?? '',
                        style: const TextStyle(color: oldDarkBlueColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          alert['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Classic checkmark status badge (removed complex Velocity/AI names)
  Widget _buildStatusBadge(String status) {
    final isOptimal = status == 'OPTIMAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOptimal ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isOptimal ? Colors.green : Colors.amber, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 14,
            color: isOptimal ? Colors.green : Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            isOptimal ? 'STATUS: OK' : 'STATUS: ALERT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOptimal ? Colors.green : Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    const oldDarkBlueColor = Color(0xFF002D62);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: oldDarkBlueColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: oldDarkBlueColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: oldDarkBlueColor, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: oldDarkBlueColor.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildZScoreChart(List<dynamic> trend, Color darkBlue) {
    if (trend.isEmpty) return const SizedBox();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkBlue, width: 1.5),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < trend.length) {
                    final term = trend[idx]['term'] as String;
                    final shortTerm = term.contains('Term 1') ? 'T1' : (term.contains('Term 2') ? 'T2' : 'T3');
                    return Text(shortTerm, style: TextStyle(color: darkBlue.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold));
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), double.parse(entry.value['z_score'].toString()));
              }).toList(),
              isCurved: true,
              color: darkBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: darkBlue.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
