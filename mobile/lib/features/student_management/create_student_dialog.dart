import 'package:flutter/material.dart';

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
  late TextEditingController _feeController;

  String _selectedClass = 'Grade 7 (Alpha)';
  String _selectedStatus = 'paid';
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
    _nameController = TextEditingController(text: widget.initialStudent?['name'] ?? '');
    _guardianController = TextEditingController(text: widget.initialStudent?['guardian'] ?? '');
    _feeController = TextEditingController(text: widget.initialStudent?['fee']?.toString() ?? '0.00');

    if (widget.initialStudent != null) {
      if (_classList.contains(widget.initialStudent!['class_name'])) {
        _selectedClass = widget.initialStudent!['class_name'];
      }
      _selectedStatus = widget.initialStudent!['status'] ?? 'paid';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _guardianController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final feeVal = double.tryParse(_feeController.text.trim()) ?? 0.0;
    final String autoStatus = feeVal > 0 ? (_selectedStatus == 'paid' ? 'outstanding' : _selectedStatus) : 'paid';

    final studentData = {
      'id': widget.initialStudent?['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'name': _nameController.text.trim(),
      'guardian': _guardianController.text.trim(),
      'class_name': _selectedClass,
      'attendance': widget.initialStudent?['attendance'] ?? '98%',
      'fee': 'USD ${feeVal.toStringAsFixed(2)}',
      'fee_amount': feeVal,
      'status': autoStatus,
    };

    widget.onSaved(studentData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.initialStudent != null ? 'Student record updated.' : 'New student record added.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3B5998);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: primaryBlue, width: 4.0)),
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
                    const Icon(Icons.person_add_rounded, color: primaryBlue, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      widget.initialStudent != null ? 'Edit Student Record' : 'Add New Student',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
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
                    prefixIcon: Icon(Icons.person_outline, color: primaryBlue, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Student name is required' : null,
                ),
                const SizedBox(height: 12),

                // Guardian Name & Phone
                TextFormField(
                  controller: _guardianController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name & Phone Number',
                    hintText: 'e.g. John Chewe (+26377...)',
                    prefixIcon: Icon(Icons.phone_outlined, color: primaryBlue, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Guardian contact details required' : null,
                ),
                const SizedBox(height: 12),

                // Class Grade Stream
                DropdownButtonFormField<String>(
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class Stream',
                    prefixIcon: Icon(Icons.meeting_room_outlined, color: primaryBlue, size: 20),
                  ),
                  items: _classList.map((cls) => DropdownMenuItem(value: cls, child: Text(cls))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClass = val);
                  },
                ),
                const SizedBox(height: 12),

                // Fee Balance USD
                TextFormField(
                  controller: _feeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Outstanding Fees (USD)',
                    hintText: 'e.g. 150.00',
                    prefixIcon: Icon(Icons.attach_money_rounded, color: primaryBlue, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                // Status
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Payment Status',
                    prefixIcon: Icon(Icons.verified_outlined, color: primaryBlue, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'outstanding', child: Text('Outstanding Fees')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 20),

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
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(widget.initialStudent != null ? 'Save Changes' : 'Add Student'),
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
