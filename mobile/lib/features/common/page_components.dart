import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// Supporting-page components, intentionally separate from the home design.
class PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppSymbol symbol;
  final IconData? icon;
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    required this.symbol,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: icon == null
              ? AppIcon(symbol, color: AppColors.primary, size: 24)
              : Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class PageCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const PageCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: child,
  );
}

class PageBadge extends StatelessWidget {
  final String text;
  final Color color;
  const PageBadge(this.text, {super.key, this.color = AppColors.primary});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class PageFilters extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;
  const PageFilters({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: labels
          .map(
            (label) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == label,
                showCheckmark: false,
                onSelected: (_) => onSelected(label),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected == label
                      ? AppColors.primary
                      : AppColors.cardBorder,
                ),
                labelStyle: TextStyle(
                  color: selected == label
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class PageEmpty extends StatelessWidget {
  final String title;
  final String message;
  const PageEmpty({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => PageCard(
    child: Column(
      children: [
        const AppIcon(AppSymbol.report, size: 32, color: AppColors.textMuted),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: AppColors.textMuted, height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

AppBar? supportingAppBar(BuildContext context, String title) =>
    Navigator.canPop(context)
    ? AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      )
    : null;
