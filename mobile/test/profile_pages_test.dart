import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/profile/profile_view.dart';
import 'package:guardianship/features/parent/guardian_profile_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting_pages_test.dart' show mount, tapVisible;

class ProfileAuth extends AuthProvider {
  ProfileAuth(this.teacher) : super(ApiClient());
  final bool teacher;
  bool fail = false;
  int saves = 0;
  final data = <String, dynamic>{
    'name': 'Grace Moyo',
    'phone_number': '0771234567',
    'email': 'grace@example.com',
    'address': '12 School Road',
  };
  @override
  Map<String, dynamic>? get user => data;
  @override
  bool get isTeacher => teacher;
  @override
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? preferredLanguage,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    saves++;
    if (fail) return false;
    data['name'] = name;
    notifyListeners();
    return true;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final teacher in [true, false]) {
    for (final width in [320.0, 430.0]) {
      testWidgets('${teacher ? 'Teacher' : 'Parent'} profile fits $width', (
        tester,
      ) async {
        final auth = ProfileAuth(teacher);
        addTearDown(auth.dispose);
        await mount(
          tester,
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: teacher
                ? const ProfileView()
                : const GuardianProfileView(
                    child: {'name': 'Tariro Moyo', 'class': 'Grade 4'},
                  ),
          ),
          width: width,
          scale: 1.3,
        );
        expect(find.text('Grace Moyo'), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tapVisible(tester, find.text('Log out'));
        expect(find.text('Log out?'), findsOneWidget);
        await tapVisible(tester, find.text('Cancel'));
      });
    }
  }
  for (final fail in [false, true]) {
    testWidgets(
      'Profile save ${fail ? 'failure retains edits' : 'updates identity'}',
      (tester) async {
        final auth = ProfileAuth(true)..fail = fail;
        addTearDown(auth.dispose);
        await mount(
          tester,
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const ProfileView(),
          ),
          width: 320,
          scale: 1.3,
        );
        await tapVisible(tester, find.text('Edit profile'));
        await tester.enterText(
          find.byType(TextFormField).first,
          'Grace Updated',
        );
        await tapVisible(tester, find.text('Save changes'));
        expect(auth.saves, 1);
        expect(
          find.text(
            fail
                ? 'Could not save your details. Please try again.'
                : 'Profile updated.',
          ),
          findsOneWidget,
        );
        if (!fail) expect(find.text('Grace Updated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
