import 'package:flutter/material.dart';
import '../dashboard/payments_view.dart';
import '../dashboard/reports_view.dart';
import '../dashboard/announcements_view.dart';
import 'learning_journal_view.dart';
import 'behaviour_view.dart';
import 'assignments_view.dart';
import 'guardian_profile_view.dart';
import 'sms_alerts_log_view.dart';
import 'messaging_view.dart';
import 'uniform_marketplace_view.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const borderColor = Color(0xFFD8D8D8);

  // Unified Guardian Account Children
  int _selectedChildIndex = 0;

  final List<Map<String, dynamic>> _mockChildren = [
    {
      'name': 'Alice Chewe',
      'class': 'Grade 4 Gold',
      'tier': 'primary',
      'school': 'Hillside Primary School',
      'homeroom_teacher': 'Teacher Grace',
      'fee_balance': 0.0,
      'attendance_rate': '96%',
      'days_present': 58,
      'total_days': 60,
      'z_score': '+0.45 SD',
      'velocity_status': 'On Track for A-Level',
      'merits_pos': 14,
      'merits_neg': 1,
    },
    {
      'name': 'Timothy Chewe',
      'class': 'ECD B - Sunflowers',
      'tier': 'preparatory',
      'school': 'Hillside Preparatory (ECD)',
      'caregiver': 'Amai Tendai',
      'fee_balance': 150.0,
      'attendance_rate': '98%',
      'days_present': 59,
      'total_days': 60,
      'z_score': '+0.20 SD',
      'velocity_status': 'On Track for Preparatory',
      'merits_pos': 8,
      'merits_neg': 0,
    },
    {
      'name': 'Brian Chewe',
      'class': 'Form 3 Blue',
      'tier': 'secondary',
      'school': 'Hillside Secondary School',
      'tutor': 'Mr. Moyo',
      'fee_balance': 360.0,
      'attendance_rate': '94%',
      'days_present': 56,
      'total_days': 60,
      'z_score': '+0.60 SD',
      'velocity_status': 'On Track for O-Level Distinction',
      'merits_pos': 18,
      'merits_neg': 2,
    },
  ];

  final List<Map<String, dynamic>> _schoolAnnouncements = [
    {
      'title': 'Term 2 Report Cards & Fee Clearance',
      'date': 'July 28, 2026',
      'category': 'URGENT',
      'category_color': Color(0xFFEF4444),
      'summary': 'Term 2 academic reports are now compiled. Please ensure fee balances are settled to unlock digital PDF downloads.',
    },
    {
      'title': 'Annual Parent-Teacher Consultation Day',
      'date': 'August 05, 2026',
      'category': 'EVENT',
      'category_color': Color(0xFF3B5998),
      'summary': 'All parents are invited to consult with homeroom teachers regarding student progress and merits performance.',
    },
    {
      'title': 'School Transportation & Extension Notice',
      'date': 'August 01, 2026',
      'category': 'NOTICE',
      'category_color': Color(0xFF10B981),
      'summary': 'Updated bus routes and timetable schedules for Term 3 enrollment are now available in the portal.',
    },
  ];

  void _showRequestAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final schoolController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Student to Account',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        'School Admin Verification Required',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: primaryBlue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'For student security, additional children are added and linked exclusively by the School Administrator. Submit your request below for admin approval.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Full Name or ID Number',
                hintText: 'e.g. Tendai Chewe (Grade 1)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(
                labelText: 'School Name',
                hintText: 'e.g. Hillside Primary School',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Relationship / Notes to Admin',
                hintText: 'e.g. Parent / Legal Guardian',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter student name or ID.')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link request for "$name" submitted to School Admin! You will be notified once approved.'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Link Request to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChild = _mockChildren[_selectedChildIndex];
    final childTier = currentChild['tier'] as String;
    final feeBalance = currentChild['fee_balance'] as double;
    final isFeeGated = feeBalance > 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. STUDENT PROFILE & CHILD SWITCHER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: secondaryBlue,
                          child: Text(
                            currentChild['name'].toString().substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentChild['name'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                ),
                                const SizedBox(width: 6),
                                const Tooltip(
                                  message: 'Student identity is verified and added by School Admin.',
                                  child: Icon(Icons.verified_user_rounded, color: Color(0xFF22C55E), size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Class: ${currentChild['class']} • ${currentChild['school']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        childTier.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 14, color: Color(0xFF6B7280)),
                        SizedBox(width: 4),
                        Text(
                          'LINKED CHILDREN (ADMIN MANAGED)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GuardianProfileView(child: currentChild)),
                        );
                      },
                      child: const Row(
                        children: [
                          Text('Student Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue)),
                          Icon(Icons.chevron_right_rounded, size: 14, color: primaryBlue),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Child Switcher Pill Bar + Admin Add Student Pill
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...List.generate(_mockChildren.length, (index) {
                        final child = _mockChildren[index];
                        final isSelected = index == _selectedChildIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedChildIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.child_care_rounded, size: 15, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(
                                  child['name'],
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Dashed / Outlined Admin Add Student Button
                      GestureDetector(
                        onTap: () => _showRequestAddStudentDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: primaryBlue, width: 1.2),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_add_alt_1_rounded, size: 15, color: primaryBlue),
                              SizedBox(width: 4),
                              Text(
                                '+ Add Child (Admin Link)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryBlue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. ATTENDANCE & FEE BALANCES KEY METRICS CARDS
          Row(
            children: [
              Expanded(
                child: _buildWebKpiCard(
                  'ATTENDANCE',
                  currentChild['attendance_rate'] ?? '96%',
                  '${currentChild['days_present'] ?? 58}/${currentChild['total_days'] ?? 60} Days Present',
                  Icons.fact_check_outlined,
                  const Color(0xFF22C55E),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Attendance Details: ${currentChild['days_present']} of ${currentChild['total_days']} school days attended (${currentChild['attendance_rate']}).')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWebKpiCard(
                  'FEE BALANCE',
                  isFeeGated ? 'USD \$${feeBalance.toStringAsFixed(2)}' : 'USD \$0.00',
                  isFeeGated ? 'Balance Due' : 'Paid in Full',
                  Icons.account_balance_wallet_outlined,
                  isFeeGated ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentsView()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. VELOCITY ENGINE BANNER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ACADEMIC VELOCITY ENGINE: ${currentChild['velocity_status']} • Positive Merits: +${currentChild['merits_pos']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. SCHOOL ANNOUNCEMENTS SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'School & Class Announcements',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementsView()),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            children: _schoolAnnouncements.map((notice) {
              final Color catColor = notice['category_color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notice['category'],
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                        Text(
                          notice['date'],
                          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice['title'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notice['summary'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 5. EDU-CONNECT CORE MODULES GRID
          const Text(
            'Edu-Connect Services & Features',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _buildEduModuleCard(
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF10B981),
                title: 'Learning Journal',
                subtitle: 'Ungated Multimedia Feed',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LearningJournalView(child: currentChild)),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.analytics_rounded,
                color: primaryBlue,
                title: 'Academic Z-Scores',
                subtitle: 'Performance Charts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Fee Payments',
                subtitle: isFeeGated ? 'USD \$${feeBalance.toStringAsFixed(2)} Due' : 'Dual Currency USD/ZiG',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.campaign_rounded,
                color: const Color(0xFFEC4899),
                title: 'Announcements',
                subtitle: 'School & Class Notices',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementsView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.star_rate_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Behaviour & Merits',
                subtitle: '+${currentChild['merits_pos']} Merits / ${currentChild['merits_neg']} Incidents',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BehaviourView(child: currentChild)),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.assignment_rounded,
                color: const Color(0xFF6366F1),
                title: 'Homework Tracker',
                subtitle: 'Upcoming & Overdue',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AssignmentsView(child: currentChild)),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.forum_rounded,
                color: const Color(0xFF0EA5E9),
                title: 'Messaging & Support',
                subtitle: 'Direct Teacher Chat',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagingView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.sms_rounded,
                color: const Color(0xFF14B8A6),
                title: 'SMS Alerts Log',
                subtitle: 'Econet / Telecel History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SmsAlertsLogView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFFD97706),
                title: 'Uniform Store',
                subtitle: 'Buy Online & Select Sizes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UniformMarketplaceView(child: currentChild)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6. OFFICIAL REPORT CARDS MODULE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.assessment_rounded, color: primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Term Report Card',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFeeGated ? 'Fee Gated — Pay balance to unlock PDF' : 'Term 2 2026 Ready for Download',
                          style: TextStyle(fontSize: 11, color: isFeeGated ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsView()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFeeGated ? const Color(0xFFDC2626) : primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(isFeeGated ? 'Unlock' : 'View PDF', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEduModuleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebKpiCard(String label, String value, String subtext, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
