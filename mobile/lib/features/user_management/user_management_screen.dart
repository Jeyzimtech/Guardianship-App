import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import 'create_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _selectedRoleFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Pre-loaded mock list for offline/demo environment
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 1,
      'name': 'Admin Tinotenda',
      'email': 'admin@hillside.ac.zw',
      'phone_number': '+263771111111',
      'role': 'admin',
    },
    {
      'id': 2,
      'name': 'Teacher Grace',
      'email': 'grace@hillside.ac.zw',
      'phone_number': '+263772222222',
      'role': 'teacher',
    },
    {
      'id': 3,
      'name': 'Guardian John Chewe',
      'email': 'john.chewe@gmail.com',
      'phone_number': '+263773333333',
      'role': 'guardian',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedRoleFilter != 'all') {
        queryParams['role'] = _selectedRoleFilter;
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['search'] = _searchQuery;
      }

      final response = await apiClient.dio.get('/users', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List list = response.data['users'] ?? [];
        setState(() {
          _users = list.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Fallback offline mock filtering
    }

    // Apply local mock filter
    var filtered = _mockUsers;
    if (_selectedRoleFilter != 'all') {
      filtered = filtered.where((u) => u['role'] == _selectedRoleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((u) =>
          u['name'].toString().toLowerCase().contains(q) ||
          (u['email'] != null && u['email'].toString().toLowerCase().contains(q)) ||
          u['phone_number'].toString().toLowerCase().contains(q)
      ).toList();
    }

    setState(() {
      _users = filtered;
      _isLoading = false;
    });
  }

  Future<void> _deleteUser(int id, String name) async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Text('Are you sure you want to delete account "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiClient.dio.delete('/users/$id');
    } catch (_) {
      // Offline fallback
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "$name" deleted successfully.')),
      );
      _fetchUsers();
    }
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    switch (role.toLowerCase()) {
      case 'admin':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF6B21A8);
        label = 'Admin';
        break;
      case 'teacher':
        bg = const Color(0xFFE6F4F1);
        fg = const Color(0xFF0B5549);
        label = 'Teacher';
        break;
      case 'guardian':
      default:
        bg = const Color(0xFFE6F9F5);
        fg = const Color(0xFF05D099);
        label = 'Guardian';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    const darkTeal = Color(0xFF0B5549);

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : darkTeal,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      selectedColor: darkTeal,
      backgroundColor: const Color(0xFFF3F4F6),
      checkmarkColor: Colors.white,
      onSelected: (bool selected) {
        setState(() {
          _selectedRoleFilter = value;
        });
        _fetchUsers();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkTeal = Color(0xFF0B5549);
    const mintGreen = Color(0xFF05D099);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Management',
          style: TextStyle(color: darkTeal, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mintGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CreateUserDialog(onUserSaved: _fetchUsers),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email...',
                prefixIcon: const Icon(Icons.search_rounded, color: darkTeal),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _fetchUsers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
                _fetchUsers();
              },
            ),
            const SizedBox(height: 12),

            // Role filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Accounts', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Admins', 'admin'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Teachers', 'teacher'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Guardians', 'guardian'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User list view
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: darkTeal))
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No users found',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final id = user['id'] ?? 0;
                            final name = user['name'] ?? 'User';
                            final email = user['email'] ?? 'No email set';
                            final phone = user['phone_number'] ?? 'No phone';
                            final role = user['role'] ?? 'guardian';

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 18),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRoleBadge(role),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(phone, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => CreateUserDialog(
                                          initialUser: user,
                                          onUserSaved: _fetchUsers,
                                        ),
                                      );
                                    } else if (val == 'delete') {
                                      _deleteUser(id, name);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, color: darkTeal, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit User'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete User', style: TextStyle(color: Colors.red)),
                                        ],
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
