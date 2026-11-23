import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/features/chat/chat_view.dart';
import 'package:guardianship/features/support/report_issue_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(appName:'Edu Connect',packageName:'educonnect.com',version:'1.0.15',buildNumber:'16',buildSignature:'');
  });
  testWidgets('Blocking stops composing, supports empty chats, and unblocking restores composing', (tester) async {
    final api=ApiClient();bool blocked=false;final mutations=<String>[];
    api.dio.interceptors.add(InterceptorsWrapper(onRequest:(o,h){
      if(o.path.contains('/block/')) { mutations.add(o.method);blocked=o.method=='POST'; }
      h.resolve(Response(requestOptions:o,statusCode:200,data:{'messages':[],'blocked':blocked,'messaging_unavailable':blocked}));
    }));
    await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>AuthProvider(api),child:const MaterialApp(home:ConversationView(contact:{'id':5,'name':'Teacher','role':'teacher'}))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));await tester.pumpAndSettle();
    await tester.tap(find.text('Block user'));await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,'Block'));await tester.pumpAndSettle();
    expect(mutations,['POST']);expect(tester.widget<TextField>(find.byType(TextField)).enabled,false);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Send')).onPressed,isNull);
    await tester.tap(find.byType(PopupMenuButton<String>));await tester.pumpAndSettle();
    await tester.tap(find.text('Unblock user'));await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,'Unblock'));await tester.pumpAndSettle();
    expect(mutations,['POST','DELETE']);expect(tester.widget<TextField>(find.byType(TextField)).enabled,true);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Safety report includes the referenced user and content with the user description', (tester) async {
    final api=ApiClient();Map? sent;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest:(o,h){sent=Map.from(o.data);h.resolve(Response(requestOptions:o,statusCode:201,data:{'status':'success'}));}));
    await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>AuthProvider(api),child:const MaterialApp(home:ReportIssuePage(category:'safety',contextDetails:'Message 42 from user 5'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField),'Please review this threatening message.');
    await tester.ensureVisible(find.text('Send report'));await tester.tap(find.text('Send report'));await tester.pumpAndSettle();
    expect(sent?['category'],'safety');expect(sent?['message'],contains('Message 42 from user 5'));
    expect(sent?['message'],contains('threatening message'));
    await tester.pumpWidget(const SizedBox());
  });
}
