import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class CreateStudentDialog extends StatefulWidget {
  final Map<String, dynamic>? initialStudent;
  final Function(Map<String, dynamic>) onSaved;

  const CreateStudentDialog({
    super.key,
    this.initialStudent,
    required this.onSaved,
  });

  @override
  State<CreateStudentDialog> createState() => _CreateStudentDialogState();
}

class _CreateStudentDialogState extends State<CreateStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _guardianController;

  String _selectedClass = 'Grade 7 (Alpha)';
  bool _isSubmitting = false;

  final List<String> _classList = [
    'ECD B (Butterflies)',
    'Grade 1 (Green)',
    'Grade 4 (Gold)',
    'Grade 7 (Alpha)',
    'Form 1 (Green)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialStudent?['name'] ?? '',
    );
    _guardianController = TextEditingController(
      text: widget.initialStudent?['guardian'] ?? '',
    );

    if (widget.initialStudent != null) {
      if (_classList.contains(widget.initialStudent!['class_name'])) {
        _selectedClass = widget.initialStudent!['class_name'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _guardianController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final studentData = {
      'id':
          widget.initialStudent?['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'name': _nameController.text.trim(),
      'guardian': _guardianController.text.trim(),
      'class_name': _selectedClass,
      'attendance': widget.initialStudent?['attendance'] ?? '98%',
    };

    widget.onSaved(studentData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialStudent != null
                ? 'Student record updated.'
                : 'New student record added.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            top: BorderSide(color: AppColors.primary, width: 4.0),
          ),
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
                    const Icon(
                      Icons.person_add_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.initialStudent != null
                          ? 'Edit Student Record'
                          : 'Add New Student',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Full Name',
                    hintText: 'e.g. Alice Chewe',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Student name is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Guardian Name & Phone
                TextFormField(
                  controller: _guardianController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name & Phone Number',
                    hintText: 'e.g. John Chewe (+26377...)',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Guardian contact details required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Class Grade Stream
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class Stream',
                    prefixIcon: Icon(
                      Icons.meeting_room_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  items: _classList
                      .map(
                        (cls) => DropdownMenuItem(value: cls, child: Text(cls)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClass = val);
                  },
                ),
                const SizedBox(height: 12),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _save,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.initialStudent != null
                                  ? 'Save Changes'
                                  : 'Add Student',
                            ),
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
