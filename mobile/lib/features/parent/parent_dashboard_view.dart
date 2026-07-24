import 'package:flutter/material.dart';
import '../dashboard/payments_view.dart';
import '../dashboard/reports_view.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const borderColor = Color(0xFFD8D8D8);

  // Selected child index for multi-child parents
  int _selectedChildIndex = 0;

  final List<Map<String, dynamic>> _mockChildren = [
    {
      'name': 'Alice Chewe',
      'class': 'Grade 4 Gold',
      'tier': 'primary',
      'school': 'Hillside Primary School',
      'homeroom_teacher': 'Teacher Grace',
      'fee_balance': 0.0,
      'attendance_today': 'Present (Homeroom)',
      'attendance_rate': '96%',
    },
    {
      'name': 'Timothy Chewe',
      'class': 'ECD B - Sunflowers',
      'tier': 'preparatory',
      'school': 'Hillside Preparatory (ECD)',
      'caregiver': 'Amai Tendai',
      'fee_balance': 150.0,
      'attendance_today': 'Present (Caregiver Checked-In)',
      'attendance_rate': '98%',
    },
    {
      'name': 'Brian Chewe',
      'class': 'Form 3 Blue',
      'tier': 'secondary',
      'school': 'Hillside Secondary School',
      'tutor': 'Mr. Moyo',
      'fee_balance': 360.0,
      'attendance_today': '4/4 Subjects Present',
      'attendance_rate': '94%',
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
          // 1. Read-Only Child Scope Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: primaryBlue, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: primaryBlue, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'READ-ONLY PARENT VIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        childTier.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Child Selector Tabs if multiple children
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_mockChildren.length, (index) {
                      final child = _mockChildren[index];
                      final isSelected = index == _selectedChildIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedChildIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? primaryBlue : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.child_care_rounded,
                                size: 16,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                child['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Read-Only Identity Card
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
                    Expanded(
                      child: Column(
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
                                message: 'Child identity and grade are set by School Admin/Teacher and cannot be edited by parents.',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Fee Balance & Direct Payment Card with Gating Logic
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isFeeGated ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isFeeGated ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                Icon(
                  isFeeGated ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isFeeGated ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFeeGated ? 'OUTSTANDING FEE BALANCE' : 'FEE ACCOUNT IN GOOD STANDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isFeeGated ? const Color(0xFF991B1B) : const Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFeeGated
                            ? 'USD \$${feeBalance.toStringAsFixed(2)} Pending'
                            : 'USD \$0.00 Balance (Term Fully Paid)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isFeeGated ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
                        ),
                      ),
                      if (isFeeGated)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            '⚠️ Fee-gated: Report cards unlock automatically upon zero balance.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                          ),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsView()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFeeGated ? const Color(0xFFDC2626) : primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(isFeeGated ? 'Pay Fees' : 'View Ledger'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. School Tier Specific Content
          if (childTier == 'preparatory') ...[
            _buildPreparatoryEcdView(),
          ] else if (childTier == 'primary') ...[
            _buildPrimarySchoolView(currentChild),
          ] else ...[
            _buildSecondarySchoolView(currentChild),
          ],

          const SizedBox(height: 16),

          // 4. Report Cards Gated Document Module
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment_rounded, color: primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Official Term Report Cards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue)),
                      ],
                    ),
                    if (isFeeGated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text('FEE GATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_open_rounded, size: 12, color: Color(0xFF16A34A)),
                            SizedBox(width: 4),
                            Text('UNLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFeeGated
                      ? 'Report card for ${currentChild['name']} is currently fee-gated due to outstanding balance (USD \$${feeBalance.toStringAsFixed(2)}). Pay fee balance to view/download official transcript.'
                      : 'Term 2 2026 Official Report Card for ${currentChild['name']} is ready for review and PDF download.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsView()));
                    },
                    icon: Icon(isFeeGated ? Icons.lock_rounded : Icons.download_rounded, size: 18),
                    label: Text(isFeeGated ? 'Locked — Pay Fees to Unlock' : 'View & Download Report Card'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFeeGated ? const Color(0xFFDC2626) : primaryBlue,
                      side: BorderSide(color: isFeeGated ? const Color(0xFFDC2626) : primaryBlue),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Uniform Shop Quick Access with Direct Payment Link
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.checkroom_rounded, color: Color(0xFF7E22CE), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('School Uniform Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                      SizedBox(height: 2),
                      Text('Order blazers, PE kits, ties & badges with instant online payment', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening School Uniform Shop & Payment Gateway...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E22CE),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text('Order & Pay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PREPARATORY (ECD) TIER VIEW ---
  Widget _buildPreparatoryEcdView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.child_care_rounded, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Text('Daily Wellbeing Snapshot (ECD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0284C7))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(4)),
                child: const Text('UNGATED DAY LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wellbeing Grid items
          _buildWellbeingItem(Icons.restaurant_rounded, 'Meals Eaten', 'Breakfast: Finished • Lunch: Ate 80% • Snack: Fruit Juice', const Color(0xFFF59E0B)),
          _buildWellbeingItem(Icons.bed_rounded, 'Nap / Rest Period', '12:30 PM - 02:00 PM (Slept peacefully for 1.5 hrs)', const Color(0xFF3B82F6)),
          _buildWellbeingItem(Icons.clean_hands_rounded, 'Hygiene & Care', 'Diaper changed at 10:00 AM & 01:30 PM (All clean)', const Color(0xFF10B981)),
          _buildWellbeingItem(Icons.photo_camera_rounded, 'Caregiver Note & Photo', '"Timothy loved finger painting and building wooden blocks today!" — Amai Tendai', const Color(0xFF8B5CF6)),

          const Divider(height: 20, color: borderColor),
          const Text('Developmental Milestone Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          const Text('• Fine Motor Skills: Holds crayons firmly with tripod grip.\n• Social Skills: Shares toys enthusiastically during group circle.', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildWellbeingItem(IconData icon, String title, String detail, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PRIMARY SCHOOL TIER VIEW ---
  Widget _buildPrimarySchoolView(Map<String, dynamic> child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Primary Homeroom & Activities',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryBlue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Homeroom: ${child['homeroom_teacher']}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Daily Attendance Mark
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance: ${child['attendance_today']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF065F46)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Rate: ${child['attendance_rate']}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text('Grade-Level Extracurricular Activities Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
          const SizedBox(height: 6),
          _buildActivityRow('Junior Chess Club', '01:30 PM - 02:30 PM', 'Present', const Color(0xFF059669)),
          _buildActivityRow('Grade 4 Athletics Practice', '03:00 PM - 04:00 PM', 'Scheduled', const Color(0xFFD97706)),
        ],
      ),
    );
  }

  // --- SECONDARY SCHOOL TIER VIEW ---
  Widget _buildSecondarySchoolView(Map<String, dynamic> child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_timeline_rounded, color: Color(0xFF6B21A8), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Secondary Timetable & Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6B21A8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Tutor: ${child['tutor']}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Per subject timetable items
          _buildSubjectRow('08:00 - 08:45 AM', 'Mathematics', 'Mr. Moyo', 'Room 102', 'Present', const Color(0xFF059669)),
          _buildSubjectRow('09:00 - 09:45 AM', 'Physical Science', 'Mrs. Sibanda', 'Lab 2', 'Present', const Color(0xFF059669)),
          _buildSubjectRow('10:15 - 11:00 AM', 'English Language', 'Ms. Ncube', 'Room 204', 'Present', const Color(0xFF059669)),
          _buildSubjectRow('11:15 - 12:00 PM', 'History & Heritage', 'Mr. Ndlovu', 'Room 108', 'Present', const Color(0xFF059669)),

          const SizedBox(height: 10),
          const Text('Subject-Linked Clubs & Extracurriculars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
          const SizedBox(height: 6),
          _buildActivityRow('Science & Innovation Club', '02:30 PM - 04:00 PM', 'Science Club', const Color(0xFF6B21A8)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String title, String time, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(String time, String subject, String teacher, String room, String attendance, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis),
                Text('$teacher • $room', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(attendance, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
