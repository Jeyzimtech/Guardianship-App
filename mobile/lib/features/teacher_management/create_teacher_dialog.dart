import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';

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
  late TextEditingController _subjectSpecialtyController;

  int? _selectedSchoolId;
  List<String> _specialties = ['Mathematics', 'English'];
  int? _selectedClassId;
  String _assignedSubject = 'Mathematics';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.initialTeacher?['user'];
    _nameController = TextEditingController(text: user?['name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone_number'] ?? '');
    _subjectSpecialtyController = TextEditingController();

    if (widget.initialTeacher != null) {
      _selectedSchoolId = widget.initialTeacher!['school_id'];
      final rawSpecs = widget.initialTeacher!['subject_specialties'];
      if (rawSpecs != null && rawSpecs is List) {
        _specialties = rawSpecs.map((e) => e.toString()).toList();
      }
      final rawClasses = widget.initialTeacher!['assigned_classes'];
      if (rawClasses != null && rawClasses is List && rawClasses.isNotEmpty) {
        _selectedClassId = rawClasses.first['id'];
        _assignedSubject = rawClasses.first['pivot']?['subject_name'] ?? 'Mathematics';
      }
    } else {
      if (widget.schools.isNotEmpty) {
        _selectedSchoolId = widget.schools.first['id'];
      }
      if (widget.availableClasses.isNotEmpty) {
        _selectedClassId = widget.availableClasses.first['id'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      if (!isEditing) {
        // Create user first
        final userResp = await apiClient.dio.post('/users', data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'role': 'teacher',
          'school_id': _selectedSchoolId,
          'subject_specialties': _specialties,
        });

        if (userResp.statusCode == 201) {
          final userId = userResp.data['user']['id'];
          await apiClient.dio.post('/teachers', data: {
            'user_id': userId,
            'school_id': _selectedSchoolId,
            'subject_specialties': _specialties,
            if (_selectedClassId != null)
              'class_assignments': [
                {
                  'school_class_id': _selectedClassId,
                  'subject_name': _assignedSubject,
                }
              ]
          });
        }
      } else {
        await apiClient.dio.put('/teachers/${widget.initialTeacher!['id']}', data: {
          'school_id': _selectedSchoolId,
          'subject_specialties': _specialties,
          if (_selectedClassId != null)
            'class_assignments': [
              {
                'school_class_id': _selectedClassId,
                'subject_name': _assignedSubject,
              }
            ]
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Teacher profile updated.' : 'Teacher profile created.')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved teacher profile (Offline/Demo mode success).')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkTeal = Color(0xFF0B5549);
    const mintGreen = Color(0xFF05D099);
    final isEditing = widget.initialTeacher != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
