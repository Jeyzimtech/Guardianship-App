import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      debugPrint('Reports load error: $e');
      setState(() {
        _reports = [];
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
      if (!mounted) return;
      Navigator.pop(context); // Close spinner

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        if (mounted) {
          final url = Uri.tryParse(response.data['download_url']?.toString() ?? '');
          final opened = url != null && ['http', 'https'].contains(url.scheme) && await launchUrl(url, mode: LaunchMode.externalApplication);
          if (!mounted) return;
          if (!opened) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The report file could not be opened.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download report. Please check your connection or contact school administration.'),
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
