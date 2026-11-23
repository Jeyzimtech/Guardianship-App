from pathlib import Path
p=Path('mobile/lib/features/parent/subscription_page.dart');s=p.read_text(encoding='utf-8');a=s.index('Future<void> showSubscriptionNotice(');b=s.index('class SubscriptionPage',a);s=s[:a]+s[b:];s=s.replace("import 'package:shared_preferences/shared_preferences.dart';\n",'').replace("import 'package:url_launcher/url_launcher.dart';\n",'');s=s.replace('    WidgetsBinding.instance.addPostFrameCallback(\n      (_) => showSubscriptionNotice(context),\n    );\n','');s=s.replace("const Text('Subscription')", "const Text('Account access')").replace("'Your subscription opens'", "'With active school access'").replace("'Activation & information'", "'Account support'").replace("'Let\u2019s get you connected'", "'Your account access'").replace("'Your account comes first. Contact us with your account and school details to arrange subscription activation. School fee payments do not activate a subscription.'", "'This app lets existing subscribers access their school records. If your account should already have access, ask your school to check it. The number above is for account support.'")
a=s.index('                    FilledButton.icon(');b=s.index('\n                  ],',a);s=s[:a]+s[b:];s=s.replace("const Text('Check activation status')", "const Text('Refresh account status')");p.write_text(s,encoding='utf-8',newline='\n')
p=Path('mobile/lib/features/parent/parent_shell.dart');s=p.read_text(encoding='utf-8').replace("import 'subscription_page.dart';\n",'').replace('      showSubscriptionNotice(context);\n','');p.write_text(s,encoding='utf-8',newline='\n')
p=Path('mobile/lib/features/parent/parent_dashboard_view.dart');s=p.read_text(encoding='utf-8').replace('Information and activation support', 'Account access and support');p.write_text(s,encoding='utf-8',newline='\n')
p=Path('mobile/lib/core/legal.dart');s=p.read_text(encoding='utf-8').replace("'2026-10-30-r17'", "'2026-11-20-r18'").replace("'30 October 2026'", "'20 November 2026'");s=s.replace("  LegalSection('Your choices', [", "  LegalSection('Message retention', [\n    'Direct messages expire seven days after sending and are removed by scheduled cleanup. Other school records follow the school’s retention requirements.',\n  ]),\n  LegalSection('Your choices', [");p.write_text(s,encoding='utf-8',newline='\n')
p=Path('backend/app/Http/Controllers/LegalPageController.php');s=p.read_text(encoding='utf-8').replace('30 October 2026','20 November 2026');p.write_text(s,encoding='utf-8',newline='\n')
p=Path('backend/resources/views/legal.blade.php');s=p.read_text(encoding='utf-8').replace('<h2>How long we keep it</h2>', '<h2>How long we keep it</h2>\n  <p>Direct parent-teacher messages expire seven days after sending and are removed by scheduled cleanup. Other school records, including attendance, reports, notices and safety alerts, follow the school’s retention requirements.</p>');p.write_text(s,encoding='utf-8',newline='\n')
p=Path('mobile/test/requested_features_test.dart');s=p.read_text(encoding='utf-8').replace("find.text('Subscription')", "find.text('Account access')");a=s.index("  testWidgets('Subscription popup");b=s.index('  for (final width',a);s=s[:a]+'''  testWidgets('Account access has support information without purchase prompts', (tester) async {
    final access = SubscriptionProvider()..loading = false;
    await mountFeature(tester, const SubscriptionPage(restricted: true), access: access);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Contact for activation'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('079 054 3013'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
'''+s[b:];p.write_text(s,encoding='utf-8',newline='\n')
