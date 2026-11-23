import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/auth_provider.dart';

class StudentAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  const StudentAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    final fallback = Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * .30,
        ),
      ),
    );
    return Semantics(
      label: '$name profile photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .28),
        child: SizedBox(
          width: size,
          height: size,
          child: ColoredBox(
            color: AppColors.softBlue,
            child: photoUrl == null || photoUrl!.isEmpty
                ? fallback
                : Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    headers: {
                      if (token != null) 'Authorization': 'Bearer $token',
                    },
                    cacheWidth: (size * 3).round(),
                    errorBuilder: (_, error, stack) => fallback,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
