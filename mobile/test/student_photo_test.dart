import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/app_colors.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/features/common/student_avatar.dart';
import 'package:guardianship/features/profile/account_profile_page.dart';
import 'package:guardianship/features/common/student_photo_page.dart';
import 'package:guardianship/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PhotoFixture extends PlatformFile {
  PhotoFixture(this.bytes, {this.reportedSize});
  final Uint8List bytes;
  final int? reportedSize;
  @override
  String get name => 'student.png';
  @override
  Future<int?> length() async => reportedSize ?? bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PhotoPickerFixture extends FilePickerPlatform {
  PhotoPickerFixture(this.file);
  PlatformFile? file;
  List<String>? extensions;
  @override
  Future<PlatformFile?> pickFile({String? dialogTitle, String? initialDirectory, FileType type = FileType.any,
    List<String>? allowedExtensions, Function(FilePickerStatus)? onFileLoading, int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(), DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(), LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions()}) async {
    extensions = allowedExtensions;
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List picture;
  setUpAll(() async {
    await (FontLoader('Cabin')..addFont(rootBundle.load('assets/fonts/Cabin.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = AppColors.softBlue);
    final image = await recorder.endRecording().toImage(64, 64);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture = data!.buffer.asUint8List();
    image.dispose();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final boundary = GlobalKey();
  bool failSave = false;
  bool postedPhoto = false;
  Map<String, dynamic>? result;

  Future<void> mount(WidgetTester tester, {double width = 430, double scale = 1, bool direct = false}) async {
    tester.view.physicalSize = Size(width, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.method == 'POST') {
        postedPhoto = o.data is FormData && (o.data as FormData).files.single.key == 'photo';
        if (failSave) { h.reject(DioException(requestOptions: o, type: DioExceptionType.connectionError)); return; }
        h.resolve(Response(requestOptions: o, statusCode: 200, data: {'photo_url': '/api/students/1/photo?v=new'}));
      } else { h.resolve(Response(requestOptions: o, statusCode: 200, data: {'photo_url': null})); }
    }));
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AuthProvider(api), child: Builder(builder: (ctx) {
      final app = const EduConectApp().build(ctx) as MaterialApp;
      return MaterialApp(theme: app.theme, builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: direct ? RepaintBoundary(key: boundary, child: const StudentPhotoPage(studentId: 1, studentName: 'Tariro Moyo'))
          : Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () async {
              result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => const StudentPhotoPage(studentId: 1, studentName: 'Tariro Moyo')));
            }, child: const Text('Open photo editor')))));
    })));
    await tester.pumpAndSettle();
    if (!direct) { await tester.tap(find.text('Open photo editor')); await tester.pumpAndSettle(); }
  }

  for (final width in [320.0, 430.0]) {
    testWidgets('Photo upload fits $width and icon uses brand blue', (tester) async {
      await mount(tester, width: width, scale: 1.3, direct: true);
      expect(tester.widget<Icon>(find.byIcon(Icons.image_outlined)).color, AppColors.primary);
      expect(find.textContaining('max 4 MB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selected photo is sent as multipart, retained after failure and returned after success', (tester) async {
    final original = FilePickerPlatform.instance;
    final picker = PhotoPickerFixture(PhotoFixture(picture));
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = original);
    postedPhoto = false; failSave = true; result = null;
    await mount(tester);
    await tester.tap(find.byType(StudentPhotoUploadArea));
    await tester.pumpAndSettle();
    expect(picker.extensions, ['jpg', 'jpeg', 'png']);
    expect(find.text('student.png'), findsOneWidget);
    await tester.ensureVisible(find.text('Save student photo'));
    await tester.tap(find.text('Save student photo'));
    await tester.pumpAndSettle();
    expect(postedPhoto, isTrue);
    expect(find.textContaining('Your selection is still here.'), findsOneWidget);
    expect(find.text('student.png'), findsOneWidget);
    failSave = false;
    await tester.ensureVisible(find.text('Save student photo'));
    await tester.tap(find.text('Save student photo'));
    await tester.pumpAndSettle();
    expect(result?['photo_url'], '/api/students/1/photo?v=new');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Oversized file is rejected before upload', (tester) async {
    final original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = PhotoPickerFixture(PhotoFixture(picture, reportedSize: 4 * 1024 * 1024 + 1));
    addTearDown(() => FilePickerPlatform.instance = original);
    postedPhoto = false;
    await mount(tester);
    await tester.tap(find.byType(StudentPhotoUploadArea));
    await tester.pumpAndSettle();
    expect(find.text('Choose a JPG or PNG smaller than 4 MB.'), findsOneWidget);
    expect(postedPhoto, isFalse);
  });

  testWidgets('Parent profile refreshes when the shared child photo changes on another screen', (tester) async {
    final original = FilePickerPlatform.instance;
    FilePickerPlatform.instance = PhotoPickerFixture(PhotoFixture(picture));
    addTearDown(() => FilePickerPlatform.instance = original);
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const first = 'https://example.test/photo.png?v=first';
    const second = 'https://example.test/photo.png?v=second';
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      h.resolve(Response(requestOptions: o, statusCode: 200, data: o.path == '/students'
        ? {'status': 'success', 'students': [{'id': 1, 'name': 'Tariro Moyo', 'photo_url': null}]}
        : o.method == 'POST' ? {'photo_url': first} : {'status': 'success', 'photo_url': null}));
    }));
    final students = StudentProvider(api);
    await tester.runAsync(students.fetchStudents);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(api)),
      ChangeNotifierProvider<StudentProvider>.value(value: students),
    ], child: Builder(builder: (context) {
      final app = const EduConectApp().build(context) as MaterialApp;
      return MaterialApp(theme: app.theme, home: Builder(builder: (context) => AccountProfilePage(parent: true, child: context.watch<StudentProvider>().selectedStudent)));
    })));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Add / change student photo'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Add / change student photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudentPhotoUploadArea));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save student photo'));
    await tester.tap(find.text('Save student photo'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(StudentAvatar), -200, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<StudentAvatar>(find.byType(StudentAvatar)).photoUrl, first);
    students.updateStudentPhoto(1, second);
    await tester.pumpAndSettle();
    expect(tester.widget<StudentAvatar>(find.byType(StudentAvatar)).photoUrl, second);
    await tester.pumpWidget(const SizedBox());
    students.dispose();
  });

  testWidgets('Student photo upload preview', (tester) async {
    await mount(tester, direct: true);
    final render = boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('output/photo-preview').create(recursive: true);
      await File('output/photo-preview/student-photo-upload.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
