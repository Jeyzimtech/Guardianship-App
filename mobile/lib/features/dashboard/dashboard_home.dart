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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF0B5549);
    const inactiveColor = Color(0xFF0B5549);
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor.withValues(alpha: 0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNavBar(ThemeData theme) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'Home'),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded, 'Chat'),
          _buildNavItem(2, Icons.account_circle_outlined, 'Profile'),
          _buildNavItem(3, Icons.notifications_none_rounded, 'Alerts'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final List<Widget> tabs = [
      const OverviewTab(),
      const ReportsView(),
      const AttendanceView(),
      const PaymentsView(),
      const AnnouncementsView(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: studentProvider.students.isEmpty ? null : _buildCustomBottomNavBar(theme),
      body: studentProvider.isLoadingStudents
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Stack(
              children: [
                // Top blue header background
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
                // Main content
                Column(
                  children: [
                    const SizedBox(height: 12),
                    // Header Bar (AppBar replacement)
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                            if (user?['role'] == 'guardian')
                              _buildChildSwitcher(context, studentProvider)
                            else
                              Text(
                                user?['name'] ?? 'Dashboard',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                    ),
                                    title: Text('Logout', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to sign out?', style: TextStyle(color: primaryColor)),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancel', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Curved Body
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: studentProvider.students.isEmpty
                              ? _buildEmptyState(user)
                              : tabs[_currentIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildChildSwitcher(BuildContext context, StudentProvider provider) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    if (provider.students.isEmpty) {
      return const Text('Edu+Conect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
    }
    
    final selected = provider.selectedStudent;
    if (selected == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: provider.students.firstWhere(
            (element) => element['id'] == selected['id'],
            orElse: () => provider.students.first,
          ),
          dropdownColor: primaryColor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          items: provider.students.map((dynamic item) {
            final student = item as Map<String, dynamic>;
            return DropdownMenuItem<Map<String, dynamic>>(
              value: student,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded, color: Colors.white, size: 18),
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
            Icon(Icons.person_off_outlined, size: 72, color: const Color(0xFF64748B).withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Student Records Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              user?['role'] == 'guardian'
                  ? 'Your account has not been linked to any students yet. Please contact the school administration office to link your children.'
                  : 'There are no students registered in your school class yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    if (studentProvider.isLoadingDashboard || studentProvider.dashboardData == null) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    final data = studentProvider.dashboardData!;
    final attendance = data['attendance_snapshot'];
    final fee = data['fee_snapshot'];
    final zScoreTrend = data['z_score_trend'] as List<dynamic>;
    final velocityStatus = data['velocity_engine_status'] ?? 'OPTIMAL';
    final announcements = data['recent_announcements'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: () => studentProvider.fetchDashboard(studentProvider.selectedStudent!['id']),
      color: primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentProvider.selectedStudent!['name'] ?? '',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade ${studentProvider.selectedStudent!['grade']} • ${studentProvider.selectedStudent!['class_name']}',
                      style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                _buildStatusBadge(context, velocityStatus),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    context: context,
                    title: 'Attendance YTD',
                    value: '${attendance['percentage']}%',
                    subtitle: '${attendance['present_days']}/${attendance['total_days']} Days Present',
                    iconUrl: 'https://img.icons8.com/?id=26055&format=png&size=96',
                    fallbackIcon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    context: context,
                    title: 'Fee Balance Due',
                    value: '\$${fee['balance_usd']}',
                    subtitle: '${fee['balance_zig']} ZiG Outstanding',
                    iconUrl: 'https://img.icons8.com/?id=13224&format=png&size=96',
                    fallbackIcon: Icons.assignment_turned_in_rounded,
                    color: double.parse(fee['balance_usd'].toString()) > 0 || double.parse(fee['balance_zig'].toString()) > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Academic Z-Score History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const SizedBox(height: 12),
            _buildZScoreChart(context, zScoreTrend, primaryColor),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent School Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                Icon(Icons.campaign_rounded, color: primaryColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            if (announcements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No recent announcements.', style: TextStyle(color: primaryColor.withValues(alpha: 0.5))),
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
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        child: Icon(Icons.announcement_rounded, color: theme.colorScheme.secondary, size: 18),
                      ),
                      title: Text(
                        alert['title'] ?? '',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          alert['content'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontSize: 12),
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

  Widget _buildStatusBadge(BuildContext context, String status) {
    final isOptimal = status == 'OPTIMAL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOptimal ? Colors.green.withValues(alpha: 0.08) : Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isOptimal ? Colors.green.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOptimal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 13,
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
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required String iconUrl,
    required IconData fallbackIcon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
              Image.network(
                iconUrl,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildZScoreChart(BuildContext context, List<dynamic> trend, Color darkBlue) {
    if (trend.isEmpty) return const SizedBox();
    final theme = Theme.of(context);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
              color: theme.colorScheme.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 0);
    
    double notchWidth = 80;
    double notchHeight = 28;
    double startX = (size.width - notchWidth) / 2;
    
    path.lineTo(startX, 0);
    
    // Smooth curve down into the notch
    path.cubicTo(
      startX + 20, 0,
      startX + 15, notchHeight,
      size.width / 2, notchHeight,
    );
    
    // Smooth curve back up
    path.cubicTo(
      size.width / 2 + 15, notchHeight,
      size.width / 2 + 20, 0,
      size.width / 2 + notchWidth / 2, 0,
    );
    
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 8.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
