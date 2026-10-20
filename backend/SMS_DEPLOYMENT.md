# SMS and SOS deployment

Deploy directly through SSH/SFTP using the existing `deploy.ps1` script, after
confirming server access. This does not require GitHub Actions.

Production `.env` must contain `SMSPOP_API_TOKEN` and `SMSPOP_SENDER_ID`. Keep the
token exclusively on the server. The default shared sender is `SMSPoP`; confirm
that the account can use it or configure an approved sender before live testing.
The account needs sufficient SMS credits. Do not put the token in Flutter builds.

Run `php artisan migrate --force` and rebuild the Laravel configuration cache.
Install a rebuilt Flutter application on teacher and parent devices; deploying
the backend alone does not update installed mobile apps. The current Android
project signs release builds with its debug key; configure production signing
before publishing to an app store.

Smoke checks with an authorized test account and phone:

1. A school admin adds a teacher and assigns classes.
2. That teacher enrolls a student with a parent phone and no email.
3. The parent requests an SMS code, verifies it, and sees the linked student.
4. Wrong, expired, exhausted and reused codes must not issue tokens.
5. The teacher sends one clearly labelled test SOS. Only linked class parents
   receive it; repeating the same request ID must not send another campaign.
6. Check real SMS reception with the parent app closed or without data.
7. Open the parent app and verify the repeating sound/vibration and acknowledgment.

The app checks pending SOS alerts every ten seconds while in the foreground and
on resume. Background push and an operating-system alarm are not configured;
SMS is the channel for offline/closed-app parents. Phone settings may mute sound.

`sms_status=accepted` means the provider reported network acceptance, not confirmed
handset delivery. Partial or unconfirmed campaigns remain saved and show a warning.
Campaigns are deliberately not retried automatically after timeouts to prevent
duplicate emergency messages. SOS recipient snapshots survive student/class changes.

SMSPoP currently supports Zimbabwe Econet 077/078 and NetOne 071 numbers, with a
limit of ten campaign requests per minute per account. SOS uses one campaign for
all supported recipients. See https://smspop.co.zw/documentation.
