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
  String _searchQuery = '';
  String _selectedAudienceFilter = 'ALL';

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
      // Offline fallback: load mock announcements list
      setState(() {
        _announcements = [
          {
            'audience_role': 'all',
            'created_at': '2026-07-14',
            'title': 'Welcome to Edu+Conect!',
            'content': 'We are pleased to launch the new school communication portal for all parents and teachers.',
          },
          {
            'audience_role': 'guardian',
            'created_at': '2026-07-12',
            'title': 'School Fees Terms & Conditions',
            'content': 'Please verify that Term 2 fee balances are paid in full. Late report release lockdowns apply.',
          },
          {
            'audience_role': 'teacher',
            'created_at': '2026-07-10',
            'title': 'Staff Curricular Guidelines',
            'content': 'Ensure all class rosters and syllabus tracking updates are uploaded to the dashboard.',
          }
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    final filteredAnnouncements = _announcements.where((alert) {
      final audience = (alert['audience_role'] ?? 'all').toString().toUpperCase();
      final title = (alert['title'] ?? '').toString().toLowerCase();
      final content = (alert['content'] ?? '').toString().toLowerCase();

      final matchesAudience = _selectedAudienceFilter == 'ALL' || audience == _selectedAudienceFilter;
      final matchesSearch = _searchQuery.isEmpty || title.contains(_searchQuery.toLowerCase()) || content.contains(_searchQuery.toLowerCase());

      return matchesAudience && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchAnnouncements,
                  color: primaryColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search announcements...',
                                prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () => setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['ALL', 'GUARDIAN', 'TEACHER'].map((role) {
                                  final isSelected = _selectedAudienceFilter == role;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(role == 'ALL' ? 'All Roles' : role),
                                      selected: isSelected,
                                      selectedColor: primaryColor,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) setState(() => _selectedAudienceFilter = role);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredAnnouncements.isEmpty ? 1 : filteredAnnouncements.length,
                          itemBuilder: (context, index) {
                            if (filteredAnnouncements.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60.0),
                                  child: Column(
                                    children: [
                                      Icon(Icons.campaign_outlined, size: 64, color: primaryColor.withValues(alpha: 0.3)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No matching announcements.',
                                        style: TextStyle(color: primaryColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final alert = filteredAnnouncements[index];
                            final audience = alert['audience_role'] ?? 'all';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              elevation: 0,
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
                                            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3), width: 1.0),
                                          ),
                                          child: Text(
                                            'TO: ${audience.toString().toUpperCase()}',
                                            style: TextStyle(color: theme.colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(
                                          alert['created_at']?.split('T')[0] ?? '',
                                          style: TextStyle(color: primaryColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      alert['title'] ?? '',
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      alert['content'] ?? '',
                                      style: TextStyle(color: primaryColor.withValues(alpha: 0.7), fontSize: 14, height: 1.4, fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
