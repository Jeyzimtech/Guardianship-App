import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/chat/chat_view.dart';
import 'package:guardianship/features/chat/message_status.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Outgoing ticks update through delivery and read; background chat does not poll',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ApiClient();
      var requests = 0;
      var stage = 0;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests++;
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'messages': [
                    {
                      'id': 1,
                      'body': 'Hello',
                      'from_me': true,
                      'created_at': '2026-10-21 09:00:00',
                      'delivered_at': stage > 0 ? '2026-10-21 09:01:00' : null,
                      'read_at': stage > 1 ? '2026-10-21 09:02:00' : null,
                    },
                    {
                      'id': 2,
                      'body': 'Reply',
                      'from_me': false,
                      'created_at': '2026-10-21 09:00:00',
                      'read_at': '2026-10-21 09:02:00',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final auth = AuthProvider(api);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(
            home: ConversationView(contact: {'id': 5, 'name': 'Parent'}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MessageStatus), findsOneWidget);
      expect(find.byTooltip('Sent'), findsOneWidget);
      expect(find.byIcon(Icons.done), findsOneWidget);
      final grey = tester.widget<Icon>(find.byIcon(Icons.done)).color;
      stage = 1;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Delivered'), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.done_all)).color, grey);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final before = requests;
      stage = 2;
      await tester.pump(const Duration(seconds: 30));
      expect(requests, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Read'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.done_all)).color,
        const Color(0xFF70CDFF),
      );
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
}
