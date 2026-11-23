Mobile notices, journal entries and direct messages
=================================================

The bottom navigation shows red unread counts (capped at 99+). Counts refresh every
20 seconds, on resume, and on foreground push delivery. Counts and read receipts
belong to the signed-in account on the server. Notices clear when opened or marked
read; journal entries clear after successfully loading their feed; messages clear
when their conversation loads. Unvisited tabs do not mark content read.

Deployment
----------

1. Deploy the backend and run `php artisan migrate --force`.
2. Create/register Android and iOS apps in Firebase for the real application IDs.
   Android now uses `educonnect.com` in project `educonnect-13f25`, matching the
   supplied google-services.json. Its namespace and launcher activity also match.
   iOS still uses `com.ctpulse.guardianship.guardianship` and requires its own config.
   Enable the Firebase Cloud Messaging HTTP v1 API. Put Android's downloaded
   `google-services.json` at `mobile/android/app/google-services.json` (the Google
   Services Gradle plugin is applied only when that file exists).
3. For iOS, add `GoogleService-Info.plist` to the Runner target using Xcode, enable
   Push Notifications and Background Modes > Remote notifications, and upload the
   APNs authentication key to Firebase. iOS push requires Apple provisioning.
4. On the server, store a Firebase service account JSON outside the public web
   directory. Set `FIREBASE_CREDENTIALS` to its absolute path. Never package this
   private key in the mobile app or commit it. Run `php artisan config:cache`.
5. Keep a queue worker running: `php artisan queue:work --tries=3 --timeout=60`.
   New notices, journal posts and messages enqueue delivery jobs. They recheck
   recipients' access and read status before sending. Invalid device tokens are
   removed. Notifications contain a generic preview; opening the app requires its
   authenticated session. Retried jobs can repeat delivery after partial success.
6. Rebuild/install the mobile app, sign in, and allow notifications. Native Firebase
   configuration is supported. Alternatively, initialize using build defines:
   `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
   `FIREBASE_SENDER_ID`, and (on iOS) `FIREBASE_IOS_BUNDLE_ID`. Native configuration
   is recommended for background delivery and must match the build defines if used.

Without Firebase configuration, unread badges still work; phone push is disabled.
No Firebase project files or server private credentials were available during
implementation. Delivery to real devices therefore requires the configuration
above and has not been verified from this workspace.

Configuration status update, 21 October 2026: the Android Firebase configuration
is included in version 1.0.2, and the server credential is now installed privately.
Authentication and an FCM validation-only request passed as the queue worker user.
The notification worker is active. Real-phone registration/delivery remains to be
checked after a user installs the app, signs in, and allows notifications.

Device acceptance check
-----------------------

Use linked teacher and parent accounts on separate devices. Send a direct message,
publish a notice, and publish a journal entry. Check the red badges and notifications
with the recipient app foregrounded, backgrounded and closed normally. Tap each
notification, read its content, and verify its unread count clears. Check a second
child's journal notification opens that child's feed. Check another school/class
receives no alerts. Sign out and verify the device receives no further notifications.
Android force-stop and iOS swipe-away can prevent delivery until reopening, and
notification permissions/network/device power settings also affect delivery.

Firebase reference: https://firebase.google.com/docs/cloud-messaging/flutter/get-started

Message ticks
-------------

Outgoing messages show one grey tick when saved on the server, two grey ticks
after the recipient's app next syncs in the foreground, and two blue ticks when
the recipient opens the conversation. Ticks appear in chat bubbles and sent-message
previews. Delivery receipts persist even if the recipient later goes offline.
The app syncs receipts every 15–20 seconds; they are not instantaneous presence.
Background/covered conversation polling does not mark incoming messages read.
Run the new `2026_10_21_000002_add_message_delivery_receipts` migration along with
the backend update, then rebuild the mobile app. Existing read messages retain
their read status and have delivery timestamps backfilled.
