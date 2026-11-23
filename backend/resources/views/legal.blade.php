<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ $title }} · Edu Connect</title>
<style>
  :root { --ink:#0f172a; --muted:#475569; --line:#e2e8f0; --brand:#1e40af; --bg:#f8fafc; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--ink); font:16px/1.65 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; }
  main { max-width:760px; margin:0 auto; padding:32px 16px 64px; }
  nav a { color:var(--brand); margin-right:16px; font-size:14px; text-decoration:none; }
  h1 { font-size:30px; line-height:1.2; margin:24px 0 4px; }
  h2 { font-size:19px; margin:32px 0 8px; }
  p.meta { color:var(--muted); font-size:14px; margin:0 0 24px; }
  li { margin:4px 0; }
  a { color:var(--brand); }
  .box { background:#fff; border:1px solid var(--line); border-radius:12px; padding:16px 20px; margin:16px 0; }
</style>
</head>
<body>
<main>
  <nav><a href="/privacy-policy">Privacy policy</a><a href="/terms">Terms of use</a><a href="/account-deletion">Delete your account</a></nav>
  <h1>{{ $title }}</h1>
  <p class="meta">Edu Connect · Last updated {{ \App\Http\Controllers\LegalPageController::UPDATED }}</p>

@if ($page === 'privacy')
  <p>Edu Connect connects schools with parents, guardians and teachers. This policy explains what information the Edu Connect mobile app and web portal collect, why, who can see it and the choices you have. Questions: <a href="mailto:admin@teramark.co.zw">admin@teramark.co.zw</a>.</p>

  <h2>Who can use Edu Connect</h2>
  <p>Accounts are created by a participating school for its teachers and for the parents or guardians of its learners. The app is for adults; learners do not sign in. We do not knowingly collect information directly from children.</p>

  <h2>Information we collect</h2>
  <ul>
    <li><strong>Account details</strong>: name, phone number, email address, home or postal address, preferred language, emergency contact name and phone.</li>
    <li><strong>Learner records your school adds</strong>: learner name, school, grade and class, attendance, homework, behaviour and merit notes, learning-journal posts, reports and school documents.</li>
    <li><strong>Learner photo</strong> that a parent chooses to add.</li>
    <li><strong>Classroom media</strong>: photos, videos, voice recordings and files that school staff choose to upload for learning activities.</li>
    <li><strong>Messages</strong> between parents and teachers, announcements and SOS safety alerts.</li>
    <li><strong>Uniform orders</strong>: items, amounts and payment status. Card and mobile-money details are entered on the PesePay payment page; Edu Connect does not receive or store them.</li>
    <li><strong>Device information</strong>: a push-notification token (Firebase Cloud Messaging) so we can deliver school alerts, plus the app version and device type when you send a support report.</li>
    <li><strong>Support reports</strong> you send from the app.</li>
  </ul>
  <p>Edu Connect does not use your location, contacts, camera roll (other than a photo you choose), advertising identifiers or third-party advertising, and does not sell personal information.</p>

  <p>Medical profiles and structured wellbeing tracking are no longer available. Please do not submit medical, medication, meals, sleep, hygiene or mood records through journals or messages. Historical information from retired features may remain in restricted storage and can be included in access or deletion requests.</p>

  <h2>How we use information</h2>
  <ul>
    <li>To let your school share attendance, homework, reports, notices and safety alerts with you.</li>
    <li>To deliver messages, push notifications and SMS alerts.</li>
    <li>To process uniform orders and confirm payments.</li>
    <li>To secure accounts, prevent misuse and fix technical problems.</li>
  </ul>

  <h2>Who can see it</h2>
  <ul>
    <li>Your school's administrators and the teachers assigned to your child's class.</li>
    <li>Service providers that operate the service for us: our hosting provider, Google Firebase (push notifications), our SMS gateway (text alerts) and PesePay (payments). They may use the data only to provide their service.</li>
    <li>Authorities when the law requires it, or to protect a learner's safety.</li>
  </ul>

  <h2>Content reports and blocking</h2>
  <p>You can report objectionable content or a user from messages, notices, learning journals, assignments, documents or Help center. Reports include your description and the item or account reference. Our support team reviews reports, may remove content or restrict access, and may contact you or the school. Use the conversation menu to block or unblock direct messages. School-wide notices remain available.</p>

  <h2>Security and storage</h2>
  <p>All data is sent over encrypted HTTPS connections. Access is limited by role and by school. No system is perfectly secure, so please keep your sign-in details private.</p>

  <h2>How long we keep it</h2>
  <p>Direct parent-teacher messages expire seven days after sending and are removed by scheduled cleanup. Other school records, including attendance, reports, notices and safety alerts, follow the school’s retention requirements.</p>
  <p>We keep account information while your account is active. When you delete your account (see below) we delete it within 30 days, except records your school must keep, such as attendance, reports and safety alerts, which stay with the school without your contact details. Backup copies follow the hosting retention schedule and may remain until they expire; contact support for details about a deletion request.</p>

  <p>Information provided under earlier versions may remain in existing records. Contact support to request access or deletion; removing a feature does not automatically delete existing records.</p>

  <h2>Your choices and rights</h2>
  <ul>
    <li>View and correct your details in the app under <em>Profile → Edit profile</em>.</li>
    <li>Turn notifications off in your phone's settings.</li>
    <li>Delete your account in the app under <em>Profile → Delete account</em>, or as described on the <a href="/account-deletion">account deletion page</a>.</li>
    <li>Ask for a copy of your data or raise a concern by emailing <a href="mailto:admin@teramark.co.zw">admin@teramark.co.zw</a>. You may also complain to the Postal and Telecommunications Regulatory Authority of Zimbabwe (POTRAZ) under the Cyber and Data Protection Act.</li>
  </ul>

  <h2>Changes</h2>
  <p>If we change this policy we will update the date above and ask you to review it in the app before continuing.</p>

@elseif ($page === 'terms')
  <p>By using Edu Connect you agree to these terms. If you do not agree, please do not use the app.</p>

  <h2>Your account</h2>
  <ul>
    <li>Your school creates your account. Keep your password and sign-in codes private and tell your school if you think someone else has used your account.</li>
    <li>Make sure the details you provide are accurate and keep them up to date.</li>
  </ul>

  <h2>Acceptable use</h2>
  <ul>
    <li>Use Edu Connect only for communication about learners at your school.</li>
    <li>Harassment, bullying, threats, hateful content, sexual exploitation, unlawful content and sharing other people's personal information without permission are prohibited. Report content or users through the in-app reporting controls. You can block direct-message contacts from the conversation menu. Support reviews reports and can remove content or restrict access.</li>
    <li>Teachers must only send SOS alerts for real safety events or announced drills.</li>
    <li>Do not try to access records you are not authorised to see, or interfere with the service.</li>
  </ul>

  <h2>School content</h2>
  <p>Attendance, homework, reports and notices are provided by your school, which is responsible for their accuracy. Contact the school directly about their content.</p>

  <h2>Payments</h2>
  <p>Uniform purchases are paid through PesePay. Orders, prices, delivery and refunds are handled by the school or its supplier.</p>

  <h2>Availability</h2>
  <p>We work to keep Edu Connect available and accurate but cannot guarantee it will be uninterrupted or error-free. In an emergency, always contact the school or emergency services directly; do not rely on the app alone.</p>

  <h2>Suspension and deletion</h2>
  <p>Your school or Edu Connect may suspend an account that breaks these terms. You can delete your account at any time from your profile.</p>

  <h2>Contact</h2>
  <p>Help and questions: <a href="mailto:admin@teramark.co.zw">admin@teramark.co.zw</a>.</p>

@else
  <p>You can permanently delete your Edu Connect account at any time.</p>

  <div class="box">
    <h2 style="margin-top:0">In the app</h2>
    <ol>
      <li>Open Edu Connect and sign in.</li>
      <li>Open <strong>Profile</strong>.</li>
      <li>Tap <strong>Delete account</strong> and confirm.</li>
    </ol>
  </div>

  <div class="box">
    <h2 style="margin-top:0">Without the app</h2>
    <p>Email <a href="mailto:admin@teramark.co.zw?subject=Delete%20my%20Edu%20Connect%20account">admin@teramark.co.zw</a> from the email address on your account, or include the phone number on your account, with the subject "Delete my Edu Connect account". We will confirm the request and delete the account within 30 days.</p>
  </div>

  <h2>What is deleted</h2>
  <ul>
    <li><strong>Parents and guardians</strong>: your account, contact details, emergency contacts, messages, links to your children, notification tokens and sign-in sessions.</li>
    <li><strong>Teachers</strong>: your name, email, phone, address, emergency contacts, class assignments, notification tokens and sign-in sessions.</li>
  </ul>

  <h2>What the school keeps</h2>
  <p>Learner records belong to the school and are kept for its records: attendance, reports, homework, behaviour notes and safety alerts. After a teacher deletes their account these records show "Former teacher" instead of their name. Backup copies follow the hosting retention schedule and may remain until they expire; contact support for details about a deletion request.</p>
@endif
</main>
</body>
</html>
