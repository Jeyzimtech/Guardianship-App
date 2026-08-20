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
  String _selectedFilter = 'All';

  static const primaryBlue = Color(0xFF3B5998);

  final List<String> _filters = ['All', 'Urgent', 'Fee Circulars', 'School Events', 'General'];

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
        _announcements = [
          {
            'audience_role': 'all',
            'category': 'Urgent',
            'created_at': '2026-08-19',
            'title': 'Outstanding Fees Reminder',
            'content': 'Please ensure all outstanding fee balances are settled before Aug 30 to avoid report card lockdowns.',
          },
          {
            'audience_role': 'guardian',
            'category': 'Fee Circulars',
            'created_at': '2026-08-15',
            'title': 'Term 3 Fee Payment Schedule',
            'content': 'Term 3 fees are due by September 5, 2026. Dual-currency (USD & ZiG) payment is accepted.',
          },
          {
            'audience_role': 'all',
            'category': 'School Events',
            'created_at': '2026-08-12',
            'title': 'Annual Sports Day — 28 August 2026',
            'content': 'All students are requested to arrive in school sports kit by 7:30 AM. Parents are welcome to attend.',
          },
          {
            'audience_role': 'guardian',
            'category': 'General',
            'created_at': '2026-08-05',
            'title': 'Annual Parent-Teacher Consultation Day',
            'content': 'All parents are invited to consult with homeroom teachers regarding student progress and merits performance.',
          },
          {
            'audience_role': 'all',
            'category': 'General',
            'created_at': '2026-07-28',
            'title': 'Welcome to Edu+Conect!',
            'content': 'We are pleased to launch the new school communication portal for all parents and teachers.',
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Urgent':
        return const Color(0xFFEF4444);
      case 'Fee Circulars':
        return const Color(0xFFF59E0B);
      case 'School Events':
        return const Color(0xFF3B5998);
      case 'General':
      default:
        return const Color(0xFF22C55E);
    }
  }

  Color _categoryBg(String category) {
    switch (category) {
      case 'Urgent':
        return const Color(0xFFFEE2E2);
      case 'Fee Circulars':
        return const Color(0xFFFEF3C7);
      case 'School Events':
        return const Color(0xFFEFF6FF);
      case 'General':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _announcements.where((alert) {
      final category = (alert['category'] ?? 'General').toString();
      final title = (alert['title'] ?? '').toString().toLowerCase();
      final content = (alert['content'] ?? '').toString().toLowerCase();

      final matchesCat =
          _selectedFilter == 'All' || category == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase());

      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Announcements',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: primaryBlue, fontWeight: FontWeight.bold)))
              : RefreshIndicator(
                  onRefresh: _fetchAnnouncements,
                  color: primaryBlue,
                  child: Column(
                    children: [
                      // Search + Filter bar
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          children: [
                            // Search bar
                            TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search announcements...',
                                hintStyle: const TextStyle(fontSize: 14),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    color: primaryBlue, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded,
                                            size: 18),
                                        onPressed: () => setState(
                                            () => _searchQuery = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: primaryBlue, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Filter chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _filters.map((f) {
                                  final isSel = _selectedFilter == f;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedFilter = f),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? primaryBlue
                                              : const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSel
                                                ? primaryBlue
                                                : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          f,
                                          style: TextStyle(
                                            color: isSel
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Announcement list
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: primaryBlue.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(32),
                                        ),
                                        child: const Icon(
                                            Icons.campaign_outlined,
                                            color: primaryBlue,
                                            size: 32),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No announcements found.',
                                        style: TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final alert = filtered[index];
                                  final category =
                                      (alert['category'] ?? 'General')
                                          .toString();
                                  final catColor = _categoryColor(category);
                                  final catBg = _categoryBg(category);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(
                                        left: BorderSide(
                                            color: catColor, width: 4),
                                        top: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        right: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                        bottom: const BorderSide(
                                            color: Color(0xFFE2E8F0)),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: catBg,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  category.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: catColor,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                alert['created_at']
                                                        ?.split('T')[0] ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            alert['title'] ?? '',
                                            style: const TextStyle(
                                                color: Color(0xFF1E293B),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            alert['content'] ?? '',
                                            style: const TextStyle(
                                                color: Color(0xFF475569),
                                                fontSize: 13,
                                                height: 1.4),
                                          ),
                                          if (category == 'Urgent')
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10),
                                              child: GestureDetector(
                                                onTap: () {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Opening detailed view...'),
                                                      backgroundColor:
                                                          primaryBlue,
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'View Details →',
                                                  style: TextStyle(
                                                    color: primaryBlue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
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
