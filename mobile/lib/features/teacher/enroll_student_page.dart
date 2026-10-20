import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';

class EnrollStudentPage extends StatefulWidget {
  const EnrollStudentPage({super.key});
  @override
  State<EnrollStudentPage> createState() => _EnrollStudentPageState();
}

class _EnrollStudentPageState extends State<EnrollStudentPage> {
  final _form = GlobalKey<FormState>();
  final _student = TextEditingController();
  final _parent = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  List<Map<String, dynamic>> _classes = [];
  int? _classId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _student.dispose();
    _parent.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/teacher/assignments',
      );
      final classes = <int, Map<String, dynamic>>{};
      for (final c in response.data['classes'] as List? ?? []) {
        classes[c['id'] as int] = Map<String, dynamic>.from(c);
      }
      if (mounted) setState(() => _classes = classes.values.toList());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load your assigned classes. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().apiClient.dio.post(
        '/students',
        data: {
          'name': _student.text.trim(),
          'class_id': _classId,
          'guardian_name': _parent.text.trim(),
          'guardian_phone': _phone.text.trim(),
          if (_email.text.trim().isNotEmpty)
            'guardian_email': _email.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student enrolled and parent linked. The parent can now sign in with an SMS code.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is DioException && e.response?.data is Map
              ? e.response!.data['message']?.toString() ??
                    'Could not enroll student.'
              : 'Could not connect. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Add student and parent')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Grow your classroom',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add a learner to one of your assigned classes. Their parent can verify their phone and sign in by SMS without an email address.',
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      initialValue: _classId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assigned class',
                      ),
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text('${c['grade']} - ${c['class_name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (id) => setState(() => _classId = id),
                      validator: (id) =>
                          id == null ? 'Select your class' : null,
                    ),
                    if (_classes.isEmpty)
                      const Text(
                        'Ask your administrator to assign you a class first.',
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _student,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Student full name',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parent,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Parent / guardian full name',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Parent phone number',
                        hintText: '0771234567',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      enabled: !_saving,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Parent email (optional)',
                      ),
                      validator: (v) =>
                          v != null &&
                              v.isNotEmpty &&
                              !RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(v.trim())
                          ? 'Enter a valid email'
                          : null,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(_error!),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving || _classes.isEmpty ? null : _save,
                      child: Text(
                        _saving
                            ? 'Saving...'
                            : 'Enroll student and link parent',
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _load,
                      child: const Text('Reload assigned classes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
