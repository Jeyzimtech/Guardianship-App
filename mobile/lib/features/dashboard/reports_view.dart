import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  List<dynamic> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final selectedStudent = studentProvider.selectedStudent;
    if (selectedStudent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get('/reports/${selectedStudent['id']}');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _reports = response.data['reports'];
        });
      }
    } catch (e) {
      // Offline fallback: load mock reports
      final double balanceUsd = double.parse(studentProvider.dashboardData?['fee_snapshot']?['balance_usd']?.toString() ?? '0.0');
      final double balanceZig = double.parse(studentProvider.dashboardData?['fee_snapshot']?['balance_zig']?.toString() ?? '0.0');
      final bool hasFees = balanceUsd > 0 || balanceZig > 0;

      setState(() {
        _reports = [
          {
            'id': 101,
            'title': 'Term 1 Academic Report Card',
            'is_locked': hasFees,
          },
          {
            'id': 102,
            'title': 'Term 2 Mid-Term Progress Card',
            'is_locked': hasFees,
          }
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _downloadReport(Map<String, dynamic> report) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlue = Color(0xFF002D62);
    const cardBgColor = Color(0xFFFFFDF0);
    
    if (report['is_locked'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: oldDarkBlue, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Access Locked', style: TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'This report card is locked. Please settle your child\'s outstanding fee balance in the Payments tab to unlock academic records.',
            style: TextStyle(color: oldDarkBlue),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: oldDarkBlue,
                foregroundColor: vanillaColor,
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: oldDarkBlue)),
    );

    try {
      final response = await studentProvider.apiClient.dio.get('/reports/download/${report['id']}');
      if (mounted) Navigator.pop(context); // Close spinner

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: oldDarkBlue, width: 1.5),
              ),
              title: Text(report['title'], style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report download authorized successfully.', style: TextStyle(color: oldDarkBlue)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: vanillaColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(response.data['file_content_mock'] ?? '', style: const TextStyle(color: oldDarkBlue, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Close', style: TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context); // Close spinner
        // Offline fallback: display mock report dialog directly
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: oldDarkBlue, width: 1.5),
            ),
            title: Text(report['title'], style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report loaded successfully (Offline Mode).', style: TextStyle(color: oldDarkBlue)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: vanillaColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '===================================\n'
                    '     OFFICIAL ACADEMIC REPORT      \n'
                    '===================================\n'
                    'Student: ${studentProvider.selectedStudent?['name'] ?? 'Student'}\n'
                    'Term: ${report['title'].toString().contains('Term 1') ? 'Term 1' : 'Term 2'}\n'
                    '-----------------------------------\n'
                    'Mathematics: A\n'
                    'English: B+\n'
                    'Science: A\n'
                    'Overall Position: 3rd in Class\n'
                    '===================================',
                    style: const TextStyle(color: oldDarkBlue, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Close', style: TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const vanillaColor = Color(0xFFF3E5AB);
    const oldDarkBlue = Color(0xFF002D62);

    return Scaffold(
      backgroundColor: vanillaColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: oldDarkBlue))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchReports,
                  color: oldDarkBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.isEmpty ? 1 : _reports.length,
                    itemBuilder: (context, index) {
                      if (_reports.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Column(
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: oldDarkBlue.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No report documents uploaded.',
                                  style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final report = _reports[index];
                      final isGated = report['is_locked'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isGated ? Colors.red.withValues(alpha: 0.1) : oldDarkBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isGated ? Icons.lock_rounded : Icons.file_present_rounded,
                              color: isGated ? Colors.red : oldDarkBlue,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            report['title'] ?? '',
                            style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              isGated ? 'Locked due to outstanding fees' : 'Academic Report card • Available for download',
                              style: TextStyle(
                                color: isGated ? Colors.red : oldDarkBlue.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          trailing: isGated
                              ? IconButton(
                                  icon: const Icon(Icons.info_rounded, color: Colors.red),
                                  onPressed: () => _downloadReport(report),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _downloadReport(report),
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('Get', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: oldDarkBlue,
                                    foregroundColor: vanillaColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
