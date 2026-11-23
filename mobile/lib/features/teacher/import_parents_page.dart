import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/auth_provider.dart';
import '../common/page_components.dart';

/// Bulk-add parents to the teacher's classes from a CSV file.
class ImportParentsPage extends StatefulWidget {
  const ImportParentsPage({super.key});

  @override
  State<ImportParentsPage> createState() => _ImportParentsPageState();
}

class _ImportParentsPageState extends State<ImportParentsPage> {
  static const _columns = [
    ['student_name', 'Required. Matches a learner in your class, or enrolls a new one.'],
    ['parent_name', 'Required.'],
    ['parent_phone', 'Recommended. Parents sign in with this number (077, 078 or 071).'],
    ['parent_email', 'Optional.'],
    ['class', 'Optional when you teach one class, e.g. Grade 1 Blue.'],
  ];

  String? _fileName;
  List<int>? _bytes;
  bool _importing = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _choose() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (!mounted) return;
      if (length == null || length > 1024 * 1024) {
        setState(() => _error = 'Choose a CSV file smaller than 1 MB.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _bytes = bytes;
        _error = null;
        _result = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open that file. Please choose it again.');
    }
  }

  Future<void> _import() async {
    if (_bytes == null) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/parents/import',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(_bytes!, filename: _fileName ?? 'parents.csv'),
        }),
      );
      if (!mounted) return;
      setState(() => _result = Map<String, dynamic>.from(response.data));
    } catch (e) {
      if (!mounted) return;
      final data = e is DioException ? e.response?.data : null;
      setState(
        () => _error = data is Map
            ? data['message']?.toString() ?? 'Import failed.'
            : 'Import failed. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errors = (_result?['errors'] as List? ?? []);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Import parents'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeading(
              title: 'Import parents',
              subtitle: 'Add many parents at once from a spreadsheet saved as CSV.',
              symbol: AppSymbol.profile,
            ),
            PageCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File format',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The first row must contain these column names:',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  for (final column in _columns)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            column[0],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            column[1],
                            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SelectableText(
                      'student_name,parent_name,parent_phone,parent_email,class\n'
                      'Tatenda Moyo,Tariro Moyo,0771234567,,Grade 1 Blue',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _importing ? null : _choose,
              child: Text(_fileName == null ? 'Choose CSV file' : 'Change file · $_fileName'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _importing || _bytes == null ? null : _import,
              child: Text(_importing ? 'Importing…' : 'Import parents'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              PageCard(
                color: errors.isEmpty ? AppColors.successLight : AppColors.warningLight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!['message']?.toString() ?? 'Import finished.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_result!['created_parents'] ?? 0} new parent accounts · '
                      '${_result!['enrolled_students'] ?? 0} new students',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    for (final e in errors) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Row ${e['row']}: ${e['message']}',
                        style: const TextStyle(color: Color(0xFF92400E)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
