import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/common/student_avatar.dart';
import 'package:guardianship/features/teacher/teacher_dashboard_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherPhotoAuth extends AuthProvider {
  TeacherPhotoAuth(super.apiClient);
  @override
  String? get token => 'teacher-photo-token';
  @override
  Map<String, dynamic>? get user => {'name': 'Teacher', 'role': 'teacher'};
}

void main() {
  for (final tab in [0, 1, 2]) {
    testWidgets('Teacher tab $tab displays the shared student photo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const photo = 'https://school.test/api/students/1/photo?v=parent-upload';
      final api = ApiClient();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'roster': [
                    {
                      'student_id': 1,
                      'name': 'Alice',
                      'photo_url': photo,
                      'class_name': 'Blue',
                      'grade': '1',
                      'guardians': [],
                      'marked': false,
                    },
                  ],
                  'categories': [],
                  'activities': [
                    {'id': 7, 'title': 'Sports', 'activity_date': '2026-10-21'},
                  ],
                },
              ),
            );
          },
        ),
      );
      final auth = TeacherPhotoAuth(api);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: TeacherDashboardView(initialTab: tab),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (tab == 2) {
        await tester.scrollUntilVisible(
          find.text('Mark roster'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, 'Mark roster'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark roster'));
        await tester.pumpAndSettle();
      } else {
        await tester.scrollUntilVisible(
          find.byType(StudentAvatar),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      final avatars = tester.widgetList<StudentAvatar>(
        find.byType(StudentAvatar),
      );
      expect(
        avatars.any(
          (avatar) => avatar.name == 'Alice' && avatar.photoUrl == photo,
        ),
        isTrue,
      );
      final image = tester.widget<Image>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Image &&
                  widget.image is ResizeImage &&
                  (widget.image as ResizeImage).imageProvider is NetworkImage,
            )
            .first,
      );
      expect(
        ((image.image as ResizeImage).imageProvider as NetworkImage)
            .headers?['Authorization'],
        'Bearer teacher-photo-token',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    });
  }
}
