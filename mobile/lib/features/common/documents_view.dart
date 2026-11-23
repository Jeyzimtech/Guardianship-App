import 'report_content_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/student_provider.dart';
import 'document_download_button.dart';
import 'page_components.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});
  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  List<dynamic> _documents = [];
  bool _loading = false;
  String? _error, _scope;
  int? _studentId;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final student =
        context.watch<StudentProvider?>()?.selectedStudent?['id'] as int?;
    final scope = '${auth.isTeacher}:$student';
    if (_scope != scope) {
      _scope = scope;
      _studentId = auth.isTeacher ? null : student;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
      _documents = [];
    });
    if (!auth.isTeacher && _studentId == null) {
      setState(() {
        _loading = false;
        _error = 'Select a linked child to view school documents.';
      });
      return;
    }
    try {
      final response = await auth.apiClient.dio.get(
        '/documents',
        queryParameters: {if (_studentId != null) 'student_id': _studentId},
      );
      if (!mounted || request != _request) return;
      setState(() => _documents = response.data['documents'] as List? ?? []);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Could not load documents. Please try again.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: supportingAppBar(context, 'School documents'),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'School documents',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Download files shared by your school. Homework files are available under Homework.',
          ),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
          if (!_loading && _error == null && _documents.isEmpty)
            const PageEmpty(
              title: 'No documents yet',
              message: 'Files shared by your school will appear here.',
            ),
          for (final document in _documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PageCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['title'] ?? 'Document',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((document['description'] ?? '')
                        .toString()
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(document['description']),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${document['audience'] ?? ''} • ${((document['file_size'] as num? ?? 0) / 1024).ceil()} KB',
                    ),
                    const SizedBox(height: 12),
                    ReportContentButton(
                      details:
                          'School document ${document['id']}: ${document['title']}',
                    ),
                    DocumentDownloadButton(
                      document: Map<String, dynamic>.from(document),
                      studentId: _studentId,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
