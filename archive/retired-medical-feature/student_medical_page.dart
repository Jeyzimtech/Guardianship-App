import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/auth_provider.dart';
import '../common/page_components.dart';

class StudentMedicalPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final bool editable;
  const StudentMedicalPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.editable = true,
  });

  @override
  State<StudentMedicalPage> createState() => _StudentMedicalPageState();
}

class _StudentMedicalPageState extends State<StudentMedicalPage> {
  final _fields = {
    'allergies': TextEditingController(),
    'conditions': TextEditingController(),
    'medications': TextEditingController(),
    'care_instructions': TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  bool _loaded = false;
  String? _error;
  String? _updated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/students/${widget.studentId}/medical',
      );
      if (!mounted) return;
      final data = response.data['data'] as Map? ?? {};
      for (final entry in _fields.entries) {
        entry.value.text = data[entry.key]?.toString() ?? '';
      }
      setState(() {
        _loaded = true;
        _updated = data['updated_at']?.toString();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load medical details. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.put(
        '/students/${widget.studentId}/medical',
        data: {
          for (final entry in _fields.entries)
            entry.key: entry.value.text.trim().isEmpty
                ? null
                : entry.value.text.trim(),
        },
      );
      if (!mounted) return;
      setState(
        () => _updated = response.data['data']?['updated_at']?.toString(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Medical details saved.')));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is DioException && e.response?.data is Map
              ? e.response!.data['message']?.toString() ??
                    'Could not save. Your changes are still here.'
              : 'Could not save. Check your connection and try again. Your changes are still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _updatedLabel() {
    final date = DateTime.tryParse(_updated ?? '')?.toLocal();
    if (date == null) return 'Recently updated';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Last updated ${date.day} ${months[date.month - 1]} ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _field(String key, String label, String hint) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (widget.editable)
          TextField(
            controller: _fields[key],
            enabled: !_saving,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          )
        else
          Text(
            _fields[key]!.text.isEmpty ? 'Not provided' : _fields[key]!.text,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'Medical details'),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const PageHeading(
                    title: 'Care starts with knowing.',
                    symbol: AppSymbol.student,
                    subtitle: 'Health information for a safer school day.',
                  ),
                  PageCard(
                    color: AppColors.primaryDark,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STUDENT MEDICAL PROFILE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.studentName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.editable
                                    ? 'Updated by a parent or guardian'
                                    : 'Parent / guardian information',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loaded) ...[
                    Text(
                      widget.editable
                          ? 'Shared with your child\'s assigned teachers.'
                          : 'Provided by this student\'s parent or guardian.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PageCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(
                            'allergies',
                            'Allergies & sensitivities',
                            'Food, medicine or other known allergies',
                          ),
                          _field(
                            'conditions',
                            'Medical conditions',
                            'Any conditions the school should know about',
                          ),
                          _field(
                            'medications',
                            'Medication details',
                            'Current medication and clinician instructions',
                          ),
                          _field(
                            'care_instructions',
                            'Care instructions',
                            'What would you like the teacher to know?',
                          ),
                          if (widget.editable)
                            const Text(
                              'All fields are optional. Keep this information up to date.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_updated != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _updatedLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    if (widget.editable)
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _saving ? 'Saving...' : 'Save medical details',
                        ),
                      ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (!_loaded)
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                ],
              ),
            ),
          ),
  );
}
