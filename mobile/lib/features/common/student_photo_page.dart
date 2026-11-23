import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';
import '../../core/app_icon.dart';
import 'page_components.dart';

class StudentPhotoUploadArea extends StatelessWidget {
  final VoidCallback? onChoose;
  final Widget? preview;
  const StudentPhotoUploadArea({
    super.key,
    required this.onChoose,
    this.preview,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Choose student photo',
    enabled: onChoose != null,
    child: Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onChoose,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          foregroundPainter: _DashedPhotoBorder(),
          child: SizedBox(
            width: double.infinity,
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: preview == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                          size: 44,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tap to upload a JPG or PNG\n(max 4 MB)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: preview!,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DashedPhotoBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(14),
        ),
      );
    final paint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      for (double distance = 0; distance < metric.length; distance += 12) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 7).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StudentPhotoPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String? photoUrl;
  const StudentPhotoPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.photoUrl,
  });
  @override
  State<StudentPhotoPage> createState() => _StudentPhotoPageState();
}

class _StudentPhotoPageState extends State<StudentPhotoPage> {
  Uint8List? _bytes;
  String? _filename;
  String? _url;
  String? _error;
  bool _loading = true, _loaded = false, _busy = false;

  @override
  void initState() {
    super.initState();
    _url = widget.photoUrl;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.get(
        '/students/${widget.studentId}/photo-details',
      );
      if (mounted) {
        setState(() {
          _url = response.data['photo_url'];
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load this student\'s photo. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (file == null || !mounted) return;
      final length = await file.length();
      if (length == null || length > 4 * 1024 * 1024) {
        throw const FormatException('Choose a JPG or PNG smaller than 4 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 4 * 1024 * 1024) {
        throw const FormatException('Choose a photo smaller than 4 MB.');
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _filename = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : 'Could not open this image. Please choose a JPG or PNG.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_bytes == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await context.read<AuthProvider>().apiClient.dio.post(
        '/students/${widget.studentId}/photo',
        data: FormData.fromMap({
          'photo': MultipartFile.fromBytes(
            _bytes!,
            filename: _filename ?? 'student.png',
          ),
        }),
        options: Options(
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      if (mounted) {
        Navigator.pop(context, {'photo_url': response.data['photo_url']});
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is DioException && e.response?.data is Map
              ? e.response!.data['message']?.toString() ??
                    'Could not save your photo. Please try again.'
              : 'Could not save your photo. Your selection is still here. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove student photo?'),
        content: const Text('You can upload a new photo whenever you need to.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove photo'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().apiClient.dio.delete(
        '/students/${widget.studentId}/photo',
      );
      if (mounted) Navigator.pop(context, {'photo_url': null});
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not remove this photo. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    Widget? preview;
    if (_bytes != null) {
      preview = Image.memory(
        _bytes!,
        fit: BoxFit.contain,
        cacheWidth: 600,
        errorBuilder: (_, error, stack) => const Center(
          child: Text(
            'This image could not be opened. Choose another JPG or PNG.',
          ),
        ),
      );
    } else if (_url != null) {
      preview = Image.network(
        _url!,
        fit: BoxFit.contain,
        headers: {
          if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
        },
        errorBuilder: (_, error, stack) => const Center(
          child: Text('Photo unavailable. Tap to choose a new picture.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: supportingAppBar(context, 'Student photo'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PageHeading(
                title: widget.studentName,
                subtitle: 'A familiar face for a connected school day.',
                symbol: AppSymbol.student,
              ),
              PageCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student photo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      StudentPhotoUploadArea(
                        onChoose: _busy || !_loaded ? null : _choose,
                        preview: preview,
                      ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tap the image area to choose a new picture. Use a clear photo of the student.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (_filename != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _filename!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This photo appears on the child\'s profile and their teacher\'s student roster. Linked parents and assigned teachers can update it.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || _bytes == null ? null : _save,
                child: Text(_busy ? 'Please wait...' : 'Save student photo'),
              ),
              if (_url != null && _bytes == null)
                TextButton(
                  onPressed: _busy ? null : _remove,
                  child: const Text('Remove photo'),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              if (!_loaded && !_loading)
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
}
