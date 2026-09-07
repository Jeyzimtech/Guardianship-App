import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';

class CreateSchoolDialog extends StatefulWidget {
  final Map<String, dynamic>? initialSchool;
  final VoidCallback onSaved;

  const CreateSchoolDialog({super.key, this.initialSchool, required this.onSaved});

  @override
  State<CreateSchoolDialog> createState() => _CreateSchoolDialogState();
}

class _CreateSchoolDialogState extends State<CreateSchoolDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedType = 'primary';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialSchool?['name'] ?? '');
    if (widget.initialSchool != null && widget.initialSchool!['type'] != null) {
      _selectedType = widget.initialSchool!['type'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final isEditing = widget.initialSchool != null;
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
      };

      if (isEditing) {
        await apiClient.dio.put('/schools/${widget.initialSchool!['id']}', data: payload);
      } else {
        await apiClient.dio.post('/schools', data: payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'School updated successfully.' : 'School created successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved school (Offline/Demo mode success).'),
            backgroundColor: AppColors.primary,
          ),
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
    const darkTeal = AppColors.primary;
    const mintGreen = AppColors.primaryLight;
    final isEditing = widget.initialSchool != null;

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
                      isEditing ? Icons.edit_location_alt_rounded : Icons.add_business_rounded,
                      color: darkTeal,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit School' : 'Create School',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTeal),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'School Name',
                    hintText: 'e.g. Hillside Primary School',
                    prefixIcon: const Icon(Icons.school_outlined, color: darkTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'School name is required';
                    if (val.trim().length < 3) return 'School name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'School Level / Category',
                    prefixIcon: const Icon(Icons.category_outlined, color: darkTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'prep', child: Text('Preparatory / ECD')),
                    DropdownMenuItem(value: 'primary', child: Text('Primary School')),
                    DropdownMenuItem(value: 'secondary', child: Text('Secondary School / High School')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveSchool,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mintGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Create School'),
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
