import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_provider.dart';

class DocumentDownloadButton extends StatefulWidget {
  final Map<String, dynamic> document;
  final int? studentId;
  const DocumentDownloadButton({
    super.key,
    required this.document,
    this.studentId,
  });

  @override
  State<DocumentDownloadButton> createState() => _DocumentDownloadButtonState();
}

class _DocumentDownloadButtonState extends State<DocumentDownloadButton> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/documents/${widget.document['id']}/download',
        queryParameters: {
          if (widget.studentId != null) 'student_id': widget.studentId,
        },
      );
      if (!mounted) return;
      final url = Uri.tryParse(response.data['download_url']?.toString() ?? '');
      if (url == null ||
          !['http', 'https'].contains(url.scheme) ||
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open download');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not download this document. Check your connection and access, then try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: _busy ? null : _download,
    icon: _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_outlined),
    label: Text(
      _busy
          ? 'Opening download…'
          : 'Download ${widget.document['file_name'] ?? 'document'}',
    ),
  );
}
