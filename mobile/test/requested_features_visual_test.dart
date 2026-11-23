import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianship/core/subscription_provider.dart';
import 'package:guardianship/features/parent/subscription_page.dart';
import 'package:guardianship/features/parent/parent_dashboard_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'requested_features_test.dart' show mountFeature;

void main() {
  setUpAll(() async {
    final cabin = FontLoader('Cabin')
      ..addFont(rootBundle.load('assets/fonts/Cabin.ttf'));
    await cabin.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final item in <String, Widget>{
    'subscription': const SubscriptionPage(restricted: true),
    'parent-dashboard': const Scaffold(body: ParentDashboardView()),
  }.entries) {
    testWidgets('Render ${item.key} for visual review', (tester) async {
      SharedPreferences.setMockInitialValues({'subscription_notice_42': true});
      final key = GlobalKey();
      await mountFeature(
        tester,
        RepaintBoundary(key: key, child: item.value),
        access: SubscriptionProvider()..loading = false,
      );
      expect(tester.takeException(), isNull);
      final render =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('../output/feature-previews');
        await dir.create(recursive: true);
        await File(
          '${dir.path}/${item.key}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
