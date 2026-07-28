import 'package:flutter/material.dart';
import '../dashboard/payments_view.dart';
import '../dashboard/reports_view.dart';
import 'learning_journal_view.dart';
import 'behaviour_view.dart';
import 'assignments_view.dart';

class ParentDashboardView extends StatefulWidget {
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  static const primaryBlue = Color(0xFF3B5998);
  static const secondaryBlue = Color(0xFF5B7BD5);
  static const borderColor = Color(0xFFD8D8D8);

  final Map<String, dynamic> _linkedChild = {
    'name': 'Alice Chewe',
    'class': 'Grade 4 Gold',
    'tier': 'primary',
    'school': 'Hillside Primary School',
    'homeroom_teacher': 'Teacher Grace',
    'fee_balance': 0.0,
    'attendance_today': 'Present (Homeroom)',
    'attendance_rate': '96%',
  };

  @override
  Widget build(BuildContext context) {
    final currentChild = _linkedChild;
    final childTier = currentChild['tier'] as String;
    final feeBalance = currentChild['fee_balance'] as double;
    final isFeeGated = feeBalance > 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Student Summary Header & Child Selector
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
                            Text(
                              currentChild['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
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
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Summary KPI Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildWebKpiCard('ATTENDANCE', currentChild['attendance_rate'] ?? '96%', Icons.fact_check_outlined, const Color(0xFF22C55E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWebKpiCard('FEE BALANCE', isFeeGated ? 'USD \$${feeBalance.toStringAsFixed(2)}' : 'USD \$0.00', Icons.account_balance_wallet_outlined, isFeeGated ? const Color(0xFFEF4444) : primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWebKpiCard('MERITS', '+12 Points', Icons.star_outline_rounded, const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 14),

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

          // 3. Core Quick Access Modules Grid
          const Text(
            'Core Features',
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
                subtitle: 'Ungated Daily Feed',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LearningJournalView(child: currentChild)),
                  );
                },
              ),
              _buildEduModuleCard(
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Fee Payments',
                subtitle: isFeeGated ? 'USD \$${feeBalance.toStringAsFixed(2)} Due' : 'Paid',
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
                subtitle: '+12 Merit Points',
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
                subtitle: 'Assignments Due',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AssignmentsView(child: currentChild)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Official Report Cards Card
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
                          isFeeGated ? 'Fee Gated — Pay balance to view' : 'Term 2 2026 Ready',
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
