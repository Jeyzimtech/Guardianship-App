import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';

class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  List<dynamic> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get('/announcements');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _announcements = response.data['announcements'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load announcements.';
      });
    }

    setState(() {
      _isLoading = false;
    });
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
                  onRefresh: _fetchAnnouncements,
                  color: oldDarkBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.isEmpty ? 1 : _announcements.length,
                    itemBuilder: (context, index) {
                      if (_announcements.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Column(
                              children: [
                                Icon(Icons.campaign_outlined, size: 64, color: oldDarkBlue.withValues(alpha: 0.3)),
                                const SizedBox(height: 16),
                                Text(
                                  'No announcements posted.',
                                  style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final alert = _announcements[index];
                      final audience = alert['audience_role'] ?? 'all';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: oldDarkBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: oldDarkBlue, width: 1),
                                    ),
                                    child: Text(
                                      'TO: ${audience.toString().toUpperCase()}',
                                      style: const TextStyle(color: oldDarkBlue, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    alert['created_at']?.split('T')[0] ?? '',
                                    style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                alert['title'] ?? '',
                                style: const TextStyle(color: oldDarkBlue, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                alert['content'] ?? '',
                                style: TextStyle(color: oldDarkBlue.withValues(alpha: 0.8), fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
