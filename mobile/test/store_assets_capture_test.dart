import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guardianship/core/api_client.dart';
import 'package:guardianship/core/auth_provider.dart';
import 'package:guardianship/core/student_provider.dart';
import 'package:guardianship/main.dart';
import 'package:guardianship/features/chat/chat_view.dart';
import 'package:guardianship/features/parent/assignments_view.dart';
import 'package:guardianship/features/dashboard/announcements_view.dart';
import 'package:guardianship/features/teacher/teacher_dashboard_view.dart';
import 'package:guardianship/features/auth/login_screen.dart';
import 'package:guardianship/features/legal/consent_screen.dart';
import 'package:guardianship/features/legal/legal_document_page.dart';

class StoreAuth extends AuthProvider {
  final String role;
  StoreAuth(super.apiClient, this.role);
  @override Map<String,dynamic> get user => {'id':17,'name':'Alex Moyo','role':role};
  @override bool get isTeacher => role=='teacher';
  @override bool get isGuardian => role=='guardian';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for(final entry in {'Roboto':'test/fixtures/Roboto-Regular.ttf','Cabin':'assets/fonts/Cabin.ttf'}.entries) {
      final bytes=await File(entry.value).readAsBytes();
      await (FontLoader(entry.key)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final pages=<String,Widget>{
    '01-school-notices':const AnnouncementsView(),
    '02-homework':const AssignmentsView(child:{'id':1,'name':'Tariro Moyo'}),
    '03-messaging':const ConversationView(contact:{'id':5,'name':'Mrs Ncube','role':'teacher','students':['Tariro Moyo']}),
    '04-attendance':const TeacherDashboardView(initialTab:1),
    '05-login':const LoginScreen(),
    '06-accept-terms':ConsentScreen(onAccepted: () {}),
    '07-terms-of-use':const LegalDocumentPage(terms:true),
    '08-login-form':const LoginScreen(),
  };
  for(final entry in pages.entries) {
    testWidgets('Capture ${entry.key}',(tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize=const Size(432,768);
      tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api=ApiClient();
      api.dio.interceptors.add(InterceptorsWrapper(onRequest:(o,h){
        h.resolve(Response(requestOptions:o,statusCode:200,data:{
          'status':'success','categories':[],'activities':[],'alerts':[],
          'announcements':[
            {'id':1,'title':'A day to celebrate learning','content':'Join us for our school open day on Friday. Families are welcome from 10:00.','audience_role':'all','category':'School Events','created_at':'2026-10-29T08:00:00Z'},
            {'id':2,'title':'Reading week begins Monday','content':'Bring your favourite story and share it with the class.','audience_role':'all','category':'General','created_at':'2026-10-28T08:00:00Z'},
          ],
          'data':{'all':[
            {'id':1,'title':'Our world of plants','subject_name':'Science','description':'Find three leaves and describe their shapes.','due_date':'2026-11-06'},
            {'id':2,'title':'A little reading, every day','subject_name':'English','description':'Read a story and write your favourite part.','due_date':'2026-11-09'},
          ]},
          'messages':[
            {'id':1,'body':'Good afternoon! Tariro did a wonderful job with her reading today.','from_me':false,'created_at':'2026-10-29 14:15:00','read_at':'2026-10-29 14:16:00'},
            {'id':2,'body':'Thank you for the update. We have been practising together at home.','from_me':true,'created_at':'2026-10-29 14:17:00','read_at':'2026-10-29 14:18:00'},
            {'id':3,'body':'That is lovely to hear. Please bring her reading book on Friday.','from_me':false,'created_at':'2026-10-29 14:19:00'},
            {'id':4,'body':'We will. Thank you, Mrs Ncube!','from_me':true,'created_at':'2026-10-29 14:20:00','delivered_at':'2026-10-29 14:20:00'},
          ],
          'roster':List.generate(5,(i)=>{'student_id':i+1,'name':['Tariro Moyo','Tendai Ncube','Rudo Dube','Kuda Banda','Nyasha Moyo'][i],'grade':'3','class_name':'Blue','status':i==3?'late':'present','marked':true,'guardians':[]}),
        }));
      }));
      final key=GlobalKey();
      await tester.pumpWidget(MultiProvider(providers:[
        ChangeNotifierProvider<AuthProvider>(create:(_)=>StoreAuth(api,entry.key.contains('attendance')?'teacher':'guardian')),
        ChangeNotifierProvider(create:(_)=>StudentProvider(api)),
      ],child:Builder(builder:(context){
        final theme=(const EduConectApp().build(context) as MaterialApp).theme!;
        return MaterialApp(debugShowCheckedModeBanner:false,theme:theme.copyWith(
          appBarTheme:theme.appBarTheme.copyWith(titleTextStyle:theme.appBarTheme.titleTextStyle?.copyWith(fontFamily:'Roboto')),
          outlinedButtonTheme:OutlinedButtonThemeData(style:theme.outlinedButtonTheme.style?.copyWith(textStyle:WidgetStatePropertyAll(theme.outlinedButtonTheme.style?.textStyle?.resolve({})?.copyWith(fontFamily:'Roboto') ?? const TextStyle(fontFamily:'Roboto')))),
        ),home:RepaintBoundary(key:key,child:Scaffold(body:SafeArea(child:entry.value))));
      })));
      await tester.pumpAndSettle();
      if(entry.key=='06-accept-terms') {
        await tester.ensureVisible(find.text('I understand and agree'));
        await tester.pumpAndSettle();
      }
      if(entry.key=='08-login-form') {
        await tester.ensureVisible(find.text('Sign in').last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(),isNull);
      await tester.runAsync(() async {
        final image=await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2.5);
        final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
        final file=File('../output/play-store-assets/raw/${entry.key}.png');
        await file.parent.create(recursive:true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    });
  }
}
