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
    const darkBlueColor = Color(0xFF0F1E36);
    const cardBgColor = Color(0xFF1B263B);

    final List<Widget> tabs = [
      const OverviewTab(),
      const ReportsView(),
      const AttendanceView(),
      const PaymentsView(),
      const AnnouncementsView(),
    ];

    return Scaffold(
      backgroundColor: darkBlueColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0,
        title: user?['role'] == 'guardian'
            ? _buildChildSwitcher(context, studentProvider, vanillaColor, cardBgColor)
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
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: vanillaColor)),
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
          ? const Center(child: CircularProgressIndicator(color: vanillaColor))
          : studentProvider.students.isEmpty
              ? _buildEmptyState(user)
              : tabs[_currentIndex],
      bottomNavigationBar: studentProvider.students.isEmpty
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: cardBgColor,
              selectedItemColor: vanillaColor,
              unselectedItemColor: Colors.white54,
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
      BuildContext context, StudentProvider provider, Color vanillaColor, Color cardBg) {
    if (provider.students.isEmpty) {
      return Text('Edu+Conect', style: TextStyle(color: vanillaColor, fontWeight: FontWeight.bold));
    }
    
    final selected = provider.selectedStudent;
    if (selected == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: provider.students.firstWhere(
            (element) => element['id'] == selected['id'],
            orElse: () => provider.students.first,
          ),
          dropdownColor: cardBg,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: vanillaColor),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          items: provider.students.map((dynamic item) {
            final student = item as Map<String, dynamic>;
            return DropdownMenuItem<Map<String, dynamic>>(
              value: student,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face_unlock_rounded, color: vanillaColor, size: 18),
                  const SizedBox(width: 8),
                  Text(student['name'] ?? '', style: const TextStyle(color: Colors.white)),
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
            Icon(Icons.person_off_outlined, size: 72, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Student Records Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              user?['role'] == 'guardian'
                  ? 'Your account has not been linked to any students yet. Please contact the school administration office to link your children.'
                  : 'There are no students registered in your school class yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
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
    const vanillaColor = Color(0xFFF3E5AB);

    if (studentProvider.isLoadingDashboard || studentProvider.dashboardData == null) {
      return const Center(child: CircularProgressIndicator(color: vanillaColor));
    }

    final data = studentProvider.dashboardData!;
    final attendance = data['attendance_snapshot'];
    final fee = data['fee_snapshot'];
    final zScoreTrend = data['z_score_trend'] as List<dynamic>;
    final velocityStatus = data['velocity_engine_status'] ?? 'OPTIMAL';
    final announcements = data['recent_announcements'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: () => studentProvider.fetchDashboard(studentProvider.selectedStudent!['id']),
      color: vanillaColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Class Badge & Velocity Indicator Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentProvider.selectedStudent!['name'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${studentProvider.selectedStudent!['grade']} • ${studentProvider.selectedStudent!['class_name']}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                    ),
                  ],
                ),
                _buildVelocityBadge(velocityStatus),
              ],
            ),
            const SizedBox(height: 24),

            // Attendance & Fee Snapshot Cards
            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Attendance YTD',
                    value: '${attendance['percentage']}%',
                    subtitle: '${attendance['present_days']}/${attendance['total_days']} Days Present',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Fee Balance Due',
                    value: '\$${fee['balance_usd']}',
                    subtitle: '${fee['balance_zig']} ZiG Outstanding',
                    icon: Icons.receipt_long_outlined,
                    color: double.parse(fee['balance_usd'].toString()) > 0 || double.parse(fee['balance_zig'].toString()) > 0
                        ? Colors.redAccent
                        : vanillaColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Z-Score Academic Trajectory (FL Chart representation)
            const Text(
              'Z-Score Academic Trajectory',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildZScoreChart(zScoreTrend, vanillaColor),
            const SizedBox(height: 24),

            // Recent Announcements List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent School Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.4), size: 14),
              ],
            ),
            const SizedBox(height: 12),
            if (announcements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No recent announcements.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
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
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: vanillaColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign, color: vanillaColor, size: 20),
                      ),
                      title: Text(
                        alert['title'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          alert['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityBadge(String status) {
    final isOptimal = status == 'OPTIMAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOptimal ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOptimal ? Colors.greenAccent : Colors.amberAccent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimal ? Icons.offline_bolt : Icons.warning_amber_rounded,
            size: 14,
            color: isOptimal ? Colors.greenAccent : Colors.amberAccent,
          ),
          const SizedBox(width: 4),
          Text(
            isOptimal ? 'VELOCITY: OPTIMAL' : 'VELOCITY: SLOWING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOptimal ? Colors.greenAccent : Colors.amberAccent,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildZScoreChart(List<dynamic> trend, Color vanillaColor) {
    if (trend.isEmpty) return const SizedBox();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                    return Text(shortTerm, style: const TextStyle(color: Colors.white38, fontSize: 10));
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
              color: vanillaColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: vanillaColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
