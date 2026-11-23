import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/features/common/documents_view.dart';
import 'package:guardianship/features/parent/assignments_view.dart';
import 'package:guardianship/features/teacher/create_assignment_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocumentStudents extends StudentProvider {
  DocumentStudents(super.apiClient);
  int id = 1;
  @override
  Map<String, dynamic> get selectedStudent => {'id': id};
  void switchChild(int value) {
    id = value;
    notifyListeners();
  }
}

Future<void> mount(
  WidgetTester tester,
  ApiClient api,
  Widget page, {
  DocumentStudents? students,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)),
        ChangeNotifierProvider<StudentProvider>.value(
          value: students ?? DocumentStudents(api),
        ),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'School documents follow child selection and download errors are recoverable',
    (tester) async {
      final api = ApiClient();
      final students = DocumentStudents(api);
      int? requestedChild;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.path.endsWith('/download')) {
              requestedChild = o.queryParameters['student_id'];
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(requestOptions: o, statusCode: 403),
                ),
              );
            } else {
              h.resolve(
                Response(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'documents': [
                      {
                        'id': o.queryParameters['student_id'],
                        'title':
                            'Class ${o.queryParameters['student_id']} circular',
                        'file_name': 'School circular.docx',
                        'file_size': 2048,
                        'audience': 'Grade 4',
                      },
                    ],
                  },
                ),
              );
            }
          },
        ),
      );
      await mount(tester, api, const DocumentsView(), students: students);
      expect(find.text('Class 1 circular'), findsOneWidget);
      students.switchChild(2);
      await tester.pumpAndSettle();
      expect(find.text('Class 1 circular'), findsNothing);
      expect(find.text('Class 2 circular'), findsOneWidget);
      await tester.tap(find.text('Download School circular.docx'));
      await tester.pumpAndSettle();
      expect(requestedChild, 2);
      expect(
        find.textContaining('Could not download this document.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Homework shows a downloadable attachment without changing text-only assignments',
    (tester) async {
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': {
                    'all': [
                      {
                        'title': 'Word homework',
                        'subject_name': 'Math',
                        'due_date': '2027-01-01',
                        'attachment': {'id': 7, 'file_name': 'Worksheet.docx'},
                      },
                      {
                        'title': 'Reading homework',
                        'subject_name': 'English',
                        'due_date': '2027-01-01',
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
      await mount(tester, api, const AssignmentsView());
      await tester.scrollUntilVisible(
        find.text('Download Worksheet.docx'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Download Worksheet.docx'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Reading homework'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Reading homework'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Document failure shows retry and restores the file list', (
    tester,
  ) async {
    final api = ApiClient();
    bool fail = true;
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (fail) {
            h.reject(DioException(requestOptions: o));
          } else {
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {'documents': []},
              ),
            );
          }
        },
      ),
    );
    await mount(tester, api, const DocumentsView());
    expect(
      find.text('Could not load documents. Please try again.'),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets(
    'Teacher assignment form offers Word and PDF attachment selection',
    (tester) async {
      final api = ApiClient();
      await mount(
        tester,
        api,
        CreateAssignmentPage(
          api: api,
          classes: const [
            {'id': 1, 'grade': '4', 'class_name': 'Blue'},
          ],
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Attach homework document'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('PDF, Word, Excel, PowerPoint or text'),
        findsOneWidget,
      );
      expect(find.text('Attach homework document'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
