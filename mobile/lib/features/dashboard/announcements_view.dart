import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/student_provider.dart';
import '../../core/app_colors.dart';

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

  final List<String> _filters = ['All', 'Urgent', 'School Events', 'General'];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final studentProvider = Provider.of<StudentProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await studentProvider.apiClient.dio.get(
        '/announcements',
      );
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
            'title': 'New term preparation',
            'content':
                'Please review the school calendar and prepare your learning materials for the new term.',
          },
          {
            'audience_role': 'guardian',
            'category': 'General',
            'created_at': '2026-08-15',
            'title': 'Term 3 Learning Schedule',
            'content':
                'The Term 3 learning schedule is available from your class teacher.',
          },
          {
            'audience_role': 'all',
            'category': 'School Events',
            'created_at': '2026-08-12',
            'title': 'Annual Sports Day — 28 August 2026',
            'content':
                'All students are requested to arrive in school sports kit by 7:30 AM. Parents are welcome to attend.',
          },
          {
            'audience_role': 'guardian',
            'category': 'General',
            'created_at': '2026-08-05',
            'title': 'Annual Parent-Teacher Consultation Day',
            'content':
                'All parents are invited to consult with homeroom teachers regarding student progress and merits performance.',
          },
          {
            'audience_role': 'all',
            'category': 'General',
            'created_at': '2026-07-28',
            'title': 'Welcome to Edu+Conect!',
            'content':
                'We are pleased to launch the new school communication portal for all parents and teachers.',
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
        return AppColors.error;
      case 'School Events':
        return AppColors.primary;
      case 'General':
      default:
        return AppColors.primaryLight;
    }
  }

  Color _categoryBg(String category) {
    switch (category) {
      case 'Urgent':
        return AppColors.errorLight;
      case 'School Events':
        return AppColors.softBlue;
      case 'General':
      default:
        return AppColors.softBlue;
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
      final matchesSearch =
          _searchQuery.isEmpty ||
          title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase());

      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Announcements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
              onRefresh: _fetchAnnouncements,
              color: AppColors.primary,
              child: Column(
                children: [
                  // Search + Filter bar
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search announcements...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryLight,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _searchQuery = ''),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.softBlue,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.blueBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.blueBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryLight,
                                width: 1.5,
                              ),
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
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.primary
                                          : AppColors.softBlue,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.primary
                                            : AppColors.blueBorder,
                                      ),
                                    ),
                                    child: Text(
                                      f,
                                      style: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : AppColors.primaryDark,
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
                  const Divider(height: 1, color: AppColors.divider),

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
                                      color: AppColors.softBlue,
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: const Icon(
                                      Icons.campaign_outlined,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No announcements found.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              final category = (alert['category'] ?? 'General')
                                  .toString();
                              final catColor = _categoryColor(category);
                              final catBg = _categoryBg(category);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(
                                    left: BorderSide(color: catColor, width: 4),
                                    top: const BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                    right: const BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                    bottom: const BorderSide(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
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
                                            alert['created_at']?.split(
                                                  'T',
                                                )[0] ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        alert['title'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        alert['content'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (category == 'Urgent')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Opening detailed view...',
                                                  ),
                                                  backgroundColor:
                                                      AppColors.primary,
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'View Details →',
                                              style: TextStyle(
                                                color: AppColors.primary,
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
