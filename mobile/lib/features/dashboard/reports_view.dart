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
      setState(() {
        _errorMessage = 'Failed to load report cards.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _downloadReport(Map<String, dynamic> report) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    // Enforce fee-gating feedback on UI
    if (report['is_locked'] == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Access Locked', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'This report card is fee-gated. Please settle your child\'s outstanding fee balance in the Payments tab to unlock academic records.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // Attempting normal report card download
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      final response = await studentProvider.apiClient.dio.get('/reports/download/${report['id']}');
      if (mounted) Navigator.pop(context); // Close spinner

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(report['title'], style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report download authorized successfully.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text(response.data['file_content_mock'] ?? '', style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace')),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download report card. Check connectivity.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _fetchReports,
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
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No report documents uploaded.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final report = _reports[index];
                      final isGated = report['is_locked'] == true;

                      return Card(
                        color: Colors.white.withOpacity(0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.06)),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isGated ? Colors.redAccent.withOpacity(0.1) : Colors.blueAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isGated ? Icons.lock_outline_rounded : Icons.file_present_rounded,
                              color: isGated ? Colors.redAccent : Colors.blueAccent,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            report['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              isGated ? 'Locked due to outstanding fees' : 'Academic Report card • Available for download',
                              style: TextStyle(
                                color: isGated ? Colors.redAccent.withOpacity(0.8) : Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          trailing: isGated
                              ? IconButton(
                                  icon: const Icon(Icons.info_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => _downloadReport(report),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _downloadReport(report),
                                  icon: const Icon(Icons.download_rounded, size: 14),
                                  label: const Text('Get', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
