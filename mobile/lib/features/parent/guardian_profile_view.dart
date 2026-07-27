import 'package:flutter/material.dart';

class GuardianProfileView extends StatefulWidget {
  final Map<String, dynamic> child;

  const GuardianProfileView({super.key, required this.child});

  @override
  State<GuardianProfileView> createState() => _GuardianProfileViewState();
}

class _GuardianProfileViewState extends State<GuardianProfileView> {
  static const primaryBlue = Color(0xFF3B5998);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;

  String _preferredLanguage = 'English';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: '+263773333333');
    _emailController = TextEditingController(text: 'john.chewe@gmail.com');
    _addressController = TextEditingController(text: '14 Samora Machel Avenue, Harare');
    _emergencyNameController = TextEditingController(text: 'Mary Chewe');
    _emergencyPhoneController = TextEditingController(text: '+263774444444');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian profile updated successfully! Paperless save completed.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardian Self-Service Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Read-Only Child Identity Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 16, color: primaryBlue),
                        SizedBox(width: 6),
                        Text(
                          'STUDENT CORE RECORD (ADMIN/TEACHER CONTROLLED)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.child['name'] ?? 'Child Name',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class: ${widget.child['class']} • School: ${widget.child['school']}',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Guardians cannot alter student identity, grade, or school enrolment.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Guardian Self-Service Editable Form
              const Text(
                'Guardian Contact Details (Self-Managed)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
              ),
              const SizedBox(height: 4),
              const Text(
                'Updates apply immediately across all linked children and CT Pulse schools.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 14),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Primary Phone Number (SMS Alerts)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Enter phone number' : null,
              ),

              const SizedBox(height: 14),

              // Email Address
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Home Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Physical Home Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              const Text(
                'Emergency Contact Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  prefixIcon: Icon(Icons.person_pin),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone Number',
                  prefixIcon: Icon(Icons.phone_callback),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              const Text(
                'In-App Preferred Language',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryBlue),
              ),
              const SizedBox(height: 4),
              const Text(
                'Drives automatic translation of school messages & journal captions.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _preferredLanguage,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.translate),
                ),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English')),
                  DropdownMenuItem(value: 'Shona', child: Text('ChiShona')),
                  DropdownMenuItem(value: 'Ndebele', child: Text('isiNdebele')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _preferredLanguage = val);
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
