import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/features/auth/login_screen.dart';
import 'package:guardianship/features/parent/uniform_marketplace_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supporting_pages_test.dart' show mount, reveal, tapVisible;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Cabin',
    )..addFont(rootBundle.load('assets/fonts/Cabin.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final pages = {
    'login': const LoginScreen(),
    'uniform-store': const UniformMarketplaceView(),
  };
  for (final page in pages.entries) {
    for (final width in [320.0, 430.0]) {
      testWidgets('${page.key} fits $width with large text', (tester) async {
        await mount(tester, page.value, width: width, scale: 1.3);
        expect(tester.takeException(), isNull);
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 5; i++) {
          await tester.drag(scrollable, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
    if (const bool.fromEnvironment('CAPTURE_PREVIEW')) {
      testWidgets('Preview ${page.key}', (tester) async {
        final boundary = GlobalKey();
        await mount(tester, page.value, boundary: boundary);
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final picture = await render.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory('output/supporting-pages').create(recursive: true);
          await File(
            'output/supporting-pages/${page.key}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      });
    }
  }
  testWidgets(
    'Login preserves entered credentials across role selection and toggles password visibility',
    (tester) async {
      await mount(tester, const LoginScreen(), width: 320);
      await reveal(tester, find.byType(TextField).first);
      await tester.enterText(
        find.byType(TextField).first,
        'person@example.com',
      );
      await tapVisible(tester, find.text('Teacher'));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'person@example.com',
      );
      await tapVisible(tester, find.byTooltip('Show password'));
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        false,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Login validates missing credentials without authentication', (
    tester,
  ) async {
    await mount(tester, const LoginScreen());
    await tapVisible(tester, find.text('Sign in'));
    expect(find.text('Please enter email and password.'), findsOneWidget);
  });
  testWidgets('Store search clears and bag tracks size and quantity totals', (
    tester,
  ) async {
    await mount(tester, const UniformMarketplaceView(), width: 320);
    await tester.enterText(find.byType(TextField), 'nothing matches');
    await tester.pumpAndSettle();
    expect(find.text('No matching items'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Clear search'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await tapVisible(tester, find.text('Official Embroidered School Blazer'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Size 32'));
    await tapVisible(tester, find.byTooltip('Increase quantity'));
    await tapVisible(tester, find.text('Add to bag'));
    await tapVisible(tester, find.text('Bag (2)'));
    expect(find.text('Size 32'), findsOneWidget);
    expect(find.text('USD \$90.00'), findsWidgets);
    await tapVisible(tester, find.text('Remove'));
    expect(find.text('Your bag is waiting'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Order review fits and records a local order', (tester) async {
    await mount(tester, const UniformMarketplaceView(), width: 320, scale: 1.3);
    await tapVisible(tester, find.text('Official Embroidered School Blazer'));
    await tapVisible(tester, find.text('Add to bag'));
    await tapVisible(tester, find.text('Bag (1)'));
    await tapVisible(tester, find.text('Review order'));
    expect(find.text('Review your order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Place order'));
    await reveal(tester, find.text('Your orders'));
    expect(
      find.text('Processing · School Store (Main Campus)'),
      findsOneWidget,
    );
    await reveal(tester, find.text('Bag (0)'));
    expect(find.text('Bag (0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
