import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/app_colors.dart';

class CreateAssignmentPage extends StatefulWidget {
  final ApiClient api;
  final List<dynamic> classes;
  const CreateAssignmentPage({
    super.key,
    required this.api,
    required this.classes,
  });
  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  int? _classId;
  DateTime? _due;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_due == null) {
      setState(() => _error = 'Choose a due date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await widget.api.dio.post(
        '/assignments',
        data: {
          'school_class_id': _classId,
          'title': _title.text.trim(),
          'subject_name': _subject.text.trim(),
          'description': _description.text.trim(),
          'due_date': _due!.toIso8601String().split('T').first,
        },
      );
      if (response.data['status'] != 'success') throw StateError('Save failed');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Assignment was not saved. Check your connection and class access, then try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Create assignment')),
    body: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'A clear task. A confident start.',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add homework or an assignment for your class.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Class'),
              items: widget.classes
                  .map(
                    (c) => DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text('${c['grade']} ${c['class_name']}'),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => _classId = v,
              validator: (v) => v == null ? 'Choose a class' : null,
            ),
            if (widget.classes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No assigned classes. Ask your school administrator to link your class.',
                ),
              ),
            const SizedBox(height: 18),
            for (final field in [
              (_title, 'Title'),
              (_subject, 'Subject'),
              (_description, 'Instructions'),
            ]) ...[
              TextFormField(
                controller: field.$1,
                enabled: !_saving,
                maxLength: field.$1 == _title ? 255 : null,
                minLines: field.$1 == _description ? 4 : 1,
                maxLines: field.$1 == _description ? 8 : 1,
                decoration: InputDecoration(
                  labelText: field.$2,
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? '${field.$2} is required'
                    : null,
              ),
              const SizedBox(height: 18),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _due == null
                    ? 'Choose due date'
                    : 'Due ${_due!.day}/${_due!.month}/${_due!.year}',
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      final today = DateUtils.dateOnly(DateTime.now());
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _due ?? today.add(const Duration(days: 1)),
                        firstDate: today,
                        lastDate: DateTime(today.year + 5),
                      );
                      if (date != null && mounted) setState(() => _due = date);
                    },
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            FilledButton(
              onPressed: _saving || widget.classes.isEmpty ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Create assignment'),
            ),
          ],
        ),
      ),
    ),
  );
}
