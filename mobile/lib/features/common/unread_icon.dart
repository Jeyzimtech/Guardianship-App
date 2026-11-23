import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_icon.dart';
import '../../core/notification_provider.dart';

class UnreadIcon extends StatelessWidget {
  final AppSymbol symbol;
  final String category;
  const UnreadIcon(this.symbol, this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider?>()?.count(category) ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: const Color(0xFFEF1524),
      textColor: Colors.white,
      label: Text(count > 99 ? '99+' : '$count'),
      child: AppIcon(symbol),
    );
  }
}
