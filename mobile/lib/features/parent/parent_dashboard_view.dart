import 'package:flutter/material.dart';
import '../dashboard/payments_view.dart';
import '../dashboard/reports_view.dart';
import 'learning_journal_view.dart';
import 'behaviour_view.dart';
import 'assignments_view.dart';
import 'guardian_profile_view.dart';
import 'sms_alerts_log_view.dart';
import 'messaging_view.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const borderColor = Color(0xFFD8D8D8);

  // Unified Guardian Account Children (across all linked CT Pulse schools)
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
      'z_score': '+0.60 SD',
      'velocity_status': 'On Track for O-Level Distinction',
      'merits_pos': 18,
      'merits_neg': 2,
    },
  ];

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
          // 1. Unified Guardian Account & Always-Visible Child Switcher (Section 5.1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
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
                          radius: 20,
                          backgroundColor: secondaryBlue,
                          child: Text(
                            currentChild['name'].toString().substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                                  message: 'Student core identity is read-only for parents and managed by School Admin/Teacher.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
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
                const Text(
                  'LINKED CHILDREN (Unified Account Across CT Pulse Schools)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280), letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),

                // Always-Visible Child Switcher Pill Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_mockChildren.length, (index) {
                      final child = _mockChildren[index];
                      final isSelected = index == _selectedChildIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedChildIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isSelected ? primaryBlue : const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.child_care_rounded, size: 14, color: isSelected ? Colors.white : const Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                child['name'],
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Above-The-Fold Summary KPI Cards (Section 5.2 Module 1)
          Row(
            children: [
              Expanded(
                child: _buildWebKpiCard('ATTENDANCE', currentChild['attendance_rate'] ?? '96%', Icons.fact_check_outlined, const Color(0xFF22C55E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWebKpiCard('Z-SCORE TREND', currentChild['z_score'] ?? '+0.45 SD', Icons.trending_up_rounded, primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWebKpiCard('FEE BALANCE', isFeeGated ? 'USD \$${feeBalance.toStringAsFixed(2)}' : 'USD \$0.00', Icons.account_balance_wallet_outlined, isFeeGated ? const Color(0xFFEF4444) : primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Required Velocity Engine Banner (Above the Fold)
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
                    'REQUIRED VELOCITY ENGINE: ${currentChild['velocity_status']} • Positive Merits: +${currentChild['merits_pos']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Core Modules Grid (Section 5.2 - 10 MVP Modules)
          const Text(
            'Edu-Connect Core Modules (MVP)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
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
                color: const Color(0xFFEC4899),
                title: 'Messaging & Support',
                subtitle: 'Auto-Translate & PT Tech',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MessagingView()),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.sms_rounded,
                color: const Color(0xFF0EA5E9),
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
                icon: Icons.person_pin_rounded,
                color: const Color(0xFF14B8A6),
                title: 'Guardian Profile',
                subtitle: 'Paperless Self-Service',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GuardianProfileView(child: currentChild)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Official Report Cards Module (Fee-Gated Communication)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
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
                        borderRadius: BorderRadius.circular(4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(isFeeGated ? 'Unlock' : 'View PDF', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
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

  Widget _buildWebKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
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
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ],
      ),
    );
  }
}
