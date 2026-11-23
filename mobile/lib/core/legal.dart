import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support contact, public policy pages and the user's acceptance of them.
class Legal {
  /// Bump when the privacy policy or terms change; everyone is asked to accept again.
  /// Keep the date in step with LegalPageController::UPDATED on the backend.
  static const version = '2026-11-20-r18';
  static const updated = '20 November 2026';
  static const supportEmail = 'admin@teramark.co.zw';
  static const _site = 'https://admin.chewetechnologies.co.zw';
  static final privacyUrl = Uri.parse('$_site/privacy-policy');
  static final termsUrl = Uri.parse('$_site/terms');
  static final deletionUrl = Uri.parse('$_site/account-deletion');

  /// Survives logout, which clears the rest of SharedPreferences.
  static const acceptedKey = 'legal_accepted_version';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(acceptedKey) == version;
  }

  static Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(acceptedKey, version);
  }

  /// Opens the phone's email app; returns false when none is installed.
  static Future<bool> email({
    String subject = 'Edu Connect help',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

class LegalSection {
  final String title;
  final List<String> points;
  const LegalSection(this.title, this.points);
}

/// Plain-language summaries shown in the app; the full text lives on the public pages.
const privacySections = [
  LegalSection('What we collect', [
    'Your name, phone number, email, address, preferred language and emergency contact.',
    'Learner records your school adds: class, attendance, homework, behaviour notes, journal posts, reports and documents.',
    'A learner photo only if a parent chooses to add it.',
    'Messages, school notices, safety alerts and reports of objectionable content or users.',
    'Uniform orders and payment status. Card and mobile-money details are entered on PesePay and never reach Edu Connect.',
    'A notification token for your phone, and the app version when you send a support report.',
  ]),
  LegalSection('What we do not collect', [
    'Your location, contacts or advertising ID.',
    'We do not show ads and we do not sell personal information.',
  ]),
  LegalSection('Who can see it', [
    'Your school administrators and the teachers assigned to your child\'s class.',
    'Service providers that run Edu Connect for us: hosting, Google Firebase (notifications), our SMS gateway and PesePay (payments).',
  ]),
  LegalSection('Message retention', [
    'Direct messages expire seven days after sending and are removed by scheduled cleanup. Other school records follow the school’s retention requirements.',
  ]),
  LegalSection('Your choices', [
    'Edit your details in Profile → Edit profile.',
    'Turn notifications off in your phone settings.',
    'Delete your account in Profile → Delete account. Records the school must keep, such as attendance and reports, stay with the school without your contact details.',
    'Ask for a copy of your data or raise a concern by emailing ${Legal.supportEmail}.',
  ]),
  LegalSection('Security', [
    'All data travels over encrypted HTTPS and access is limited by role and school.',
  ]),
];

const termsSections = [
  LegalSection('Your account', [
    'Your school creates your account. Keep your password and sign-in codes private.',
    'Keep your contact details accurate and up to date.',
  ]),
  LegalSection('Acceptable use', [
    'Use Edu Connect only for communication about learners at your school.',
    'Be respectful. Harassment, bullying, threats, sexual exploitation, hateful content and unlawful content are prohibited. Do not share other people\'s information outside the app.',
    'Report objectionable content or users using the report controls or Help center. Block direct-message contacts from the conversation menu. Our support team reviews reports and may remove content or restrict access.',
    'Teachers send SOS alerts only for real safety events or announced drills.',
    'Do not try to open records you are not allowed to see.',
  ]),
  LegalSection('School content and payments', [
    'Attendance, homework, reports and notices come from your school, which is responsible for them.',
    'Uniform payments are made through PesePay. Orders, delivery and refunds are handled by the school or its supplier.',
  ]),
  LegalSection('Emergencies', [
    'In an emergency, always contact the school or emergency services directly. Do not rely on the app alone.',
  ]),
  LegalSection('Suspension and deletion', [
    'An account that breaks these terms may be suspended. You can delete your account at any time from your profile.',
  ]),
];
