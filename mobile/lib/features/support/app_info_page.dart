import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/legal.dart';
import '../common/page_components.dart';

/// "1.0.8 (9)" and "android 14" style details attached to support reports.
Future<({String version, String platform})> appDetails() async {
  var version = 'unknown';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version} (${info.buildNumber})';
  } catch (_) {}
  final platform = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  return (version: version, platform: platform.length > 120 ? platform.substring(0, 120) : platform);
}

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted))),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: supportingAppBar(context, 'App info'),
    body: SafeArea(
      child: FutureBuilder(
        future: appDetails(),
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeading(title: 'App info', subtitle: 'Edu Connect for parents and teachers.', symbol: AppSymbol.report),
            PageCard(
              child: Column(
                children: [
                  _row('Version', snapshot.data?.version ?? '…'),
                  const Divider(height: 1),
                  _row('Device', snapshot.data?.platform ?? '…'),
                  const Divider(height: 1),
                  _row('Policies updated', Legal.updated),
                  const Divider(height: 1),
                  _row('Support', Legal.supportEmail),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Edu Connect',
                applicationVersion: snapshot.data?.version,
              ),
              child: const Text('Open-source licences'),
            ),
          ],
        ),
      ),
    ),
  );
}
