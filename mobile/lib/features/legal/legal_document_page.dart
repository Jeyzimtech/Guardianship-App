import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_icon.dart';
import '../../core/legal.dart';
import '../common/page_components.dart';

/// In-app privacy policy or terms, with a link to the full public page.
class LegalDocumentPage extends StatelessWidget {
  final bool terms;
  const LegalDocumentPage({super.key, this.terms = false});

  @override
  Widget build(BuildContext context) {
    final title = terms ? 'Terms of use' : 'Privacy policy';
    final sections = terms ? termsSections : privacySections;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeading(
              title: title,
              subtitle: 'Edu Connect · Updated ${Legal.updated}',
              symbol: AppSymbol.report,
            ),
            for (final section in sections)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PageCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      for (final point in section.points)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8, right: 10),
                                child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
                              ),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(height: 1.55, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (terms) OutlinedButton.icon(
              onPressed: () => Legal.open(terms ? Legal.termsUrl : Legal.privacyUrl),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('Read the full ${title.toLowerCase()} online'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Questions? Email ${Legal.supportEmail}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
