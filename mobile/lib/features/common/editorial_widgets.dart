import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';

/// Shared typography and surfaces for the selected Editorial direction.
class Editorial {
  static const canvas = Color(0xFFFAF9F6);
  static const headline = TextStyle(
    fontFamily: 'Cabin',
    fontSize: 38,
    height: 1.2,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const section = TextStyle(
    fontFamily: 'Cabin',
    fontSize: 22,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

class EditorialFeature extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const EditorialFeature({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primaryDark,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(symbolForFeature(title), color: Colors.white, size: 26),
            const SizedBox(height: 14),
            Text(
              eyebrow,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Editorial.section.copyWith(
                      color: Colors.white,
                      fontSize: 29,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EditorialMetric extends StatelessWidget {
  final String value;
  final String label;
  const EditorialMetric({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(symbolForFeature(label), color: AppColors.primary, size: 24),
        const SizedBox(height: 12),
        Text(
          value,
          style: Editorial.headline.copyWith(
            fontSize: 38,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class EditorialLink extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const EditorialLink({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              AppIcon(
                symbolForFeature(title),
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
