import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The same local Icons8 artwork used by the admin portal.
enum AppSymbol {
  home('dashboard'),
  school('school-management'),
  student('education'),
  teacher('teacher'),
  attendance('attendance'),
  report('reports'),
  message('messages'),
  profile('user'),
  store('commercial');

  final String assetName;
  const AppSymbol(this.assetName);
}

class AppIcon extends StatelessWidget {
  final AppSymbol symbol;
  final double size;
  final Color? color;
  const AppIcon(this.symbol, {super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/icons8-${symbol.assetName}.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(
      color ?? IconTheme.of(context).color ?? Colors.black,
      BlendMode.srcIn,
    ),
  );
}

/// Meaning-based mappings keep home shortcuts and the drawer consistent.
AppSymbol symbolForFeature(String title) => switch (title.toLowerCase()) {
  'home' || 'dashboard' => AppSymbol.home,
  'attendance' ||
  'class attendance' ||
  'start with attendance' => AppSymbol.attendance,
  'students' || 'positive merits' || 'behaviour & merits' => AppSymbol.student,
  'classroom' || 'sessions ahead' => AppSymbol.school,
  'teacher conversations' => AppSymbol.teacher,
  'school notices' ||
  'notifications' ||
  'messages' ||
  'sms history' => AppSymbol.message,
  'profile' || 'my profile' || 'link another child' => AppSymbol.profile,
  'uniform store' => AppSymbol.store,
  _ => AppSymbol.report,
};
