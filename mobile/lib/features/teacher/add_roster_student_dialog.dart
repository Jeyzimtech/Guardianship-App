import 'package:flutter/material.dart';

class AddRosterStudentDialog extends StatefulWidget {
  const AddRosterStudentDialog({super.key});

  @override
  State<AddRosterStudentDialog> createState() => _AddRosterStudentDialogState();
}

class _AddRosterStudentDialogState extends State<AddRosterStudentDialog> {
  static const primaryBlue = Color(0xFF3B5998);
  static const primaryHover = Color(0xFF2D4373);
  static const borderColor = Color(0xFFD8D8D8);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  String _selectedGender = 'Female';
  String _feeStatus = 'Paid';

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newStudent = {
        'id': 'STU${(100 + (DateTime.now().millisecondsSinceEpoch % 899)).toString()}',
        'name': _nameController.text.trim(),
        'roll': _rollController.text.trim().isEmpty ? '06' : _rollController.text.trim(),
        'guardian': '${_guardianNameController.text.trim()} (${_guardianPhoneController.text.trim()})',
        'guardian_phone': _guardianPhoneController.text.trim(),
        'status': 'Present',
        'fees': _feeStatus,
        'merits': 0,
        'gender': _selectedGender,
      };

      Navigator.of(context).pop(newStudent);
    }
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: primaryBlue, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      elevation: 4,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_add_alt_1_outlined, color: primaryBlue, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Add Student to Class Roster',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280), size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24, color: borderColor),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Student Full Name *', Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter student name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rollController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration('Roll Number', Icons.numbers_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: _buildInputDecoration('Gender', Icons.wc_outlined),
                        items: const [
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _guardianNameController,
                  decoration: _buildInputDecoration('Guardian / Parent Name *', Icons.family_restroom_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter guardian name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _guardianPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Guardian Contact Phone *', Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  initialValue: _feeStatus,
                  decoration: _buildInputDecoration('Fee Status', Icons.payments_outlined),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'USD \$120.00 Pending', child: Text('USD \$120.00 Pending')),
                    DropdownMenuItem(value: 'USD \$250.00 Pending', child: Text('USD \$250.00 Pending')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _feeStatus = val);
                  },
                ),

                const SizedBox(height: 20),

                // Button Structure matching Admin Web
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('ADD TO ROSTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) return primaryHover;
                          return primaryBlue;
                        }),
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
