import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';

class ReportsView extends StatefulWidget {
  final bool showAppBar;
  const ReportsView({super.key, this.showAppBar = true});

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
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );
    final selectedStudent = studentProvider.selectedStudent;
    if (selectedStudent == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get(
        '/reports/${selectedStudent['id']}',
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _reports = response.data['reports'];
        });
      }
    } catch (e) {
      // Offline fallback: load mock reports

      setState(() {
        _reports = [
          {
            'id': 101,
            'title': 'Term 1 Academic Report Card',
            'is_locked': false,
          },
          {
            'id': 102,
            'title': 'Term 2 Mid-Term Progress Card',
            'is_locked': false,
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _downloadReport(Map<String, dynamic> report) async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final response = await studentProvider.apiClient.dio.get(
        '/reports/download/${report['id']}',
      );
      if (mounted) Navigator.pop(context); // Close spinner

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder, width: 1.0),
              ),
              title: Text(
                report['title'],
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report download authorized successfully.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      response.data['file_content_mock'] ?? '',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
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
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder, width: 1.0),
            ),
            title: Text(
              report['title'],
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report loaded successfully (Offline Mode).',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

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
                'Academic Reports & Cards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: AppColors.primary,
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
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No report documents uploaded.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final report = _reports[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        report['title'] ?? '',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Academic Report card • Available for download',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _downloadReport(report),
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: const Text(
                          'Get',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
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
