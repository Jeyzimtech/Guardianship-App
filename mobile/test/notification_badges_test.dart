import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/app_icon.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/notification_provider.dart';
import 'package:guardianship/features/common/unread_icon.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTestAuth extends AuthProvider {
  NotificationTestAuth(super.apiClient);
  String? session = 'parent-session';
  @override
  String? get token => session;
}

void main() {
  testWidgets(
    'Badges follow server reads, preserve offline counts, and reset by account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ApiClient();
      var messages = 120;
      var notices = 2;
      var offline = false;
      final readIds = <int>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (offline) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
              return;
            }
            if (options.path.endsWith('/read')) {
              readIds.addAll(List<int>.from(options.data['ids']));
              notices = 0;
            }
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'counts': {
                    'notices': notices,
                    'journal': 1,
                    'messages': messages,
                  },
                  'notice_reads': readIds,
                },
              ),
            );
          },
        ),
      );
      final auth = NotificationTestAuth(api);
      final updates = NotificationProvider()..bind(auth);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: updates,
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  UnreadIcon(AppSymbol.message, 'notices'),
                  UnreadIcon(AppSymbol.report, 'journal'),
                  UnreadIcon(AppSymbol.message, 'messages'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      await tester.runAsync(() => updates.markRead('notices', [11, 12]));
      await tester.pumpAndSettle();
      expect(readIds, [11, 12]);
      expect(find.text('2'), findsNothing);
      offline = true;
      messages = 0;
      await tester.runAsync(updates.refresh);
      await tester.pump();
      expect(updates.count('messages'), 120);
      offline = false;
      await tester.runAsync(updates.refresh);
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsNothing);
      auth.session = null;
      updates.bind(auth);
      expect(updates.count('journal'), 0);
      expect(updates.noticeReads, isEmpty);
      await tester.pumpWidget(const SizedBox());
      updates.dispose();
      auth.dispose();
    },
  );
}
