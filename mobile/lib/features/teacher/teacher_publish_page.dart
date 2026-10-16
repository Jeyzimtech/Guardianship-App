import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/app_colors.dart';
import '../common/page_components.dart';

class TeacherPublishPage extends StatefulWidget {
  final bool report;
  const TeacherPublishPage({super.key, this.report = false});
  @override
  State<TeacherPublishPage> createState() => _TeacherPublishPageState();
}

class _TeacherPublishPageState extends State<TeacherPublishPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _link = TextEditingController();
  final _meals = TextEditingController();
  final _nap = TextEditingController();
  final _hygiene = TextEditingController();
  List<Map<String, dynamic>> _students = [], _classes = [];
  int? _student;
  String? _subject;
  String _type = 'text';
  PlatformFile? _file;
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.report) _type = 'report';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().apiClient;
      final results = await Future.wait([api.dio.get('/students'), api.dio.get('/teacher/assignments')]);
      if (!mounted) return;
      setState(() {
        _students = (results[0].data['students'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        _classes = (results[1].data['classes'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        _student = _students.isEmpty ? null : _students.first['id'] as int;
        _subject = _subjects.firstOrNull;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your assigned students. Please try again.');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  List<String> get _subjects {
    final student = _students.where((s) => s['id'] == _student).firstOrNull;
    if (student == null) return [];
    return _classes.where((c) => c['grade'] == student['grade'] && c['class_name'] == student['class_name'])
        .map((c) => c['pivot']?['subject_name']?.toString() ?? 'General').toSet().toList();
  }

  Future<void> _chooseFile() async {
    try {
      final allowed = widget.report ? ['pdf', 'jpg', 'jpeg', 'png'] : switch (_type) {
        'voice' => ['mp3', 'wav', 'm4a', 'ogg'],
        'video' => ['mp4', 'webm'],
        _ => ['jpg', 'jpeg', 'png', 'gif'],
      };
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: allowed);
      if (file == null || !mounted) return;
      final length = await file.length();
      if (!mounted) return;
      if (length == null || length > 10 * 1024 * 1024) {
        setState(() => _error = 'Choose a readable file smaller than 10 MB.'); return;
      }
      setState(() { _file = file; _error = null; });
    } catch (_) { if (mounted) setState(() => _error = 'Could not open that file. Please choose it again.'); }
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate() || _student == null) return;
    if ((widget.report || ['photo','drawing','voice','video'].contains(_type)) && _file == null) {
      setState(() => _error = 'Choose a file to upload.'); return;
    }
    setState(() { _saving = true; _error = null; });
    final api = context.read<AuthProvider>().apiClient;
    try {
      final data = <String, dynamic>{'student_id': _student, 'type': _type};
      if (widget.report) { data['title'] = _title.text.trim(); }
      else {
        data['caption'] = _note.text.trim();
        if (_subject != null) data['subject_name'] = _subject;
        if (_type == 'link') data['media_url'] = _link.text.trim();
        if (_type == 'wellbeing') data['wellbeing_data'] = {'meals': _meals.text.trim(), 'nap': _nap.text.trim(), 'hygiene': _hygiene.text.trim()};
      }
      if (_file != null) data['file'] = MultipartFile.fromBytes(await _file!.readAsBytes(), filename: _file!.name);
      await api.dio.post(widget.report ? '/reports/upload' : '/journal', data: FormData.fromMap(data));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (exception) {
      if (!mounted) return;
      final data = exception is DioException ? exception.response?.data : null;
      setState(() => _error = data is Map ? data['message']?.toString() ?? 'Could not publish. Please try again.' : 'Could not publish. Please check your connection.');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  void dispose() {
    for (final controller in [_title,_note,_link,_meals,_nap,_hygiene]) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, widget.report ? 'Upload report' : 'Post learning entry'),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.report ? 'Share a student report' : 'Share a learning moment', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const Text('Only students in your assigned classes are available here.'),
      const SizedBox(height: 20),
      if (_error != null) ...[Text(_error!, style: const TextStyle(color: AppColors.error)), const SizedBox(height: 12)],
      if (_students.isEmpty) ...[
        const Text('No assigned students yet. Ask your school administrator to assign your classes.'),
        TextButton(onPressed: _load, child: const Text('Refresh students')),
      ] else Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<int>(initialValue: _student, isExpanded: true, decoration: const InputDecoration(labelText: 'Student'),
          items: _students.map((s) => DropdownMenuItem<int>(value: s['id'] as int, child: Text('${s['name']} · ${s['grade']} ${s['class_name']}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _saving ? null : (v) => setState(() { _student = v; _subject = _subjects.firstOrNull; })),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: _type, decoration: const InputDecoration(labelText: 'Entry type'),
          items: (widget.report ? {'report':'Report','merit':'Merit','certificate':'Certificate'} : {'text':'Note','photo':'Photo','drawing':'Drawing','voice':'Voice note','video':'Video','link':'Learning link','wellbeing':'Wellbeing log'})
              .entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: _saving ? null : (v) => setState(() { _type = v!; _file = null; })),
        if (!widget.report && _subjects.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(key: ValueKey(_student), initialValue: _subject, isExpanded: true, decoration: const InputDecoration(labelText: 'Assigned subject'),
            items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: _saving ? null : (v) => setState(() => _subject = v)),
        ],
        const SizedBox(height: 16),
        if (widget.report) TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Report title'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null)
        else TextFormField(controller: _note, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Note for the family'), validator: (v) => _type == 'text' && (v == null || v.trim().isEmpty) ? 'Write a note' : null),
        if (_type == 'link') ...[const SizedBox(height: 16), TextFormField(controller: _link, decoration: const InputDecoration(labelText: 'HTTPS link'), validator: (v) => Uri.tryParse(v ?? '')?.scheme == 'https' ? null : 'Enter a valid HTTPS link')],
        if (_type == 'wellbeing') ...[
          const SizedBox(height: 16), TextFormField(controller: _meals, decoration: const InputDecoration(labelText: 'Meals')),
          const SizedBox(height: 12), TextFormField(controller: _nap, decoration: const InputDecoration(labelText: 'Rest / nap')),
          const SizedBox(height: 12), TextFormField(controller: _hygiene, decoration: const InputDecoration(labelText: 'Hygiene')),
        ],
        if (widget.report || ['photo','drawing','voice','video'].contains(_type)) ...[
          const SizedBox(height: 20), OutlinedButton(onPressed: _saving ? null : _chooseFile, child: Text(_file?.name ?? 'Choose file (up to 10 MB)')),
        ],
        const SizedBox(height: 24), FilledButton(onPressed: _saving ? null : _publish, child: Text(_saving ? 'Publishing…' : widget.report ? 'Upload report' : 'Publish entry')),
      ])),
    ]),
  );
}
