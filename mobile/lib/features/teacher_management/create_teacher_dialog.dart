import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';

class CreateTeacherDialog extends StatefulWidget {
  final Map<String, dynamic>? initialTeacher;
  final List<Map<String, dynamic>> schools;
  final List<Map<String, dynamic>> availableClasses;
  final VoidCallback onSaved;

  const CreateTeacherDialog({
    super.key,
    this.initialTeacher,
    required this.schools,
    required this.availableClasses,
    required this.onSaved,
  });

  @override
  State<CreateTeacherDialog> createState() => _CreateTeacherDialogState();
}

class _CreateTeacherDialogState extends State<CreateTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _staffIdController;
  late TextEditingController _departmentController;
  late TextEditingController _qualificationController;
  late TextEditingController _subjectSpecialtyController;

  List<String> _specialties = [];
  int? _selectedSchoolId;
  int? _selectedClassId;
  String _selectedEmploymentType = 'full_time';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTeacher;
    _nameController = TextEditingController(text: t?['user']?['name'] ?? '');
    _emailController = TextEditingController(text: t?['user']?['email'] ?? '');
    _phoneController = TextEditingController(text: t?['user']?['phone_number'] ?? '');
    _staffIdController = TextEditingController(text: t?['staff_id'] ?? '');
    _departmentController = TextEditingController(text: t?['department'] ?? '');
    _qualificationController = TextEditingController(text: t?['qualification'] ?? '');
    _subjectSpecialtyController = TextEditingController();

    if (t?['subject_specialties'] != null && t!['subject_specialties'] is List) {
      _specialties = List<String>.from(t['subject_specialties']);
    }

    _selectedSchoolId = t?['school_id'];
    _selectedClassId = t?['class_id'];
    if (t?['employment_type'] != null) {
      _selectedEmploymentType = t!['employment_type'];
    }

    if (_selectedSchoolId == null && widget.schools.isNotEmpty) {
      _selectedSchoolId = widget.schools.first['id'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _staffIdController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _subjectSpecialtyController.dispose();
    super.dispose();
  }

  void _addSpecialty() {
    final text = _subjectSpecialtyController.text.trim();
    if (text.isNotEmpty && !_specialties.contains(text)) {
      setState(() {
        _specialties.add(text);
        _subjectSpecialtyController.clear();
      });
    }
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final isEditing = widget.initialTeacher != null;
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final payload = {
        if (!isEditing) ...{
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
        },
        'school_id': _selectedSchoolId,
        'class_id': _selectedClassId,
        'staff_id': _staffIdController.text.trim().isEmpty ? null : _staffIdController.text.trim(),
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'qualification': _qualificationController.text.trim().isEmpty ? null : _qualificationController.text.trim(),
        'employment_type': _selectedEmploymentType,
        'subject_specialties': _specialties,
      };

      if (isEditing) {
        await apiClient.dio.put('/teachers/${widget.initialTeacher!['id']}', data: payload);
      } else {
        await apiClient.dio.post('/teachers', data: payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Teacher updated successfully.' : 'Teacher created successfully.')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save teacher profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkTeal = AppColors.primary;
    const mintGreen = AppColors.primaryLight;
    final isEditing = widget.initialTeacher != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.person_add_rounded,
                      color: darkTeal,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Teacher' : 'Add Teacher',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTeal),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                if (!isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline, color: darkTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, color: darkTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address (Optional)',
                      prefixIcon: const Icon(Icons.email_outlined, color: darkTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // School Campus
                DropdownButtonFormField<int>(
                  initialValue: _selectedSchoolId,
                  decoration: InputDecoration(
                    labelText: 'School Campus',
                    prefixIcon: const Icon(Icons.school_outlined, color: darkTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: widget.schools.map((school) {
                    return DropdownMenuItem<int>(
                      value: school['id'],
                      child: Text(school['name'] ?? 'School'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSchoolId = val);
                  },
                ),
                const SizedBox(height: 14),

                // Subject Specialties Chips
                const Text('Subject Specialties', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 14)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ..._specialties.map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12, color: darkTeal, fontWeight: FontWeight.bold)),
                          backgroundColor: const Color(0xFFE6F4F1),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _specialties.remove(s)),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subjectSpecialtyController,
                        decoration: InputDecoration(
                          hintText: 'Add subject (e.g. Science)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: mintGreen, size: 28),
                      onPressed: _addSpecialty,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Class Stream Assignment
                if (widget.availableClasses.isNotEmpty) ...[
                  const Text('Class Stream Assignment', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 14)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'Assigned Class Stream',
                      prefixIcon: const Icon(Icons.meeting_room_outlined, color: darkTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: widget.availableClasses.map((cls) {
                      final grade = cls['grade'] ?? '';
                      final cName = cls['class_name'] ?? '';
                      return DropdownMenuItem<int>(
                        value: cls['id'],
                        child: Text('$grade $cName'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedClassId = val);
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveTeacher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Create Teacher'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
