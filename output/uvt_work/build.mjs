import fs from 'node:fs/promises';
import assert from 'node:assert/strict';
import {Workbook, SpreadsheetFile} from '@oai/artifact-tool';

// Manual business verification scenarios derived from the current EduConnect source.
// Each tuple: description, executor, prerequisites, steps, expected outcome.
const groups = [];
function group(name, rows) { groups.push({name, rows}); }
group('Installation & environment', [
['Install approved Android release','Teacher / Parent','TD-01–04; approved APK and physical Android phone','Install the approved build; launch; record version, package and environment.','App opens without crash; version/package match the approved release; requests use the approved HTTPS API.'],
['Upgrade preserves account and data','Parent','Older supported build installed; linked child; baseline evidence','Upgrade without clearing data; reopen; inspect child and message history.','Upgrade completes; account and server records remain correct; no duplicate children or messages.'],
['Web administration access','School admin','TD-01, TD-08; supported browser','Open approved administration URL; sign in; navigate dashboard and school setup.','HTTPS page loads; correct school and permitted navigation appear; no mixed-content warning.'],
['First launch and empty account','Parent','Approved parent account with no linked children','Sign in; inspect home and child-dependent sections.','Clear empty/linking guidance appears; no crash or another family’s data.'],
['Unavailable server handling','Teacher / Parent','Test network switch or support-controlled outage','Open a data screen while server is unreachable; restore connection; retry.','Readable failure and retry are available; loading stops; data returns after reconnection without false success.'],
['Device date and release evidence','Test lead','TD-04; device automatic time enabled','Record phone OS, time zone, app build and API release in Test Data; compare timestamps.','Evidence identifies the tested release and devices; dates align with the agreed school time zone.']
]);
group('Authentication & sessions', [
['Teacher password login','Teacher','TD-08 assigned teacher; valid credentials kept outside workbook','Sign in with correct email/username and password; inspect landing screen.','Teacher home opens with assigned school/class context and permitted functions.'],
['Parent password login','Parent','TD-08 linked parent','Sign in with valid credentials; open child selector.','Parent home displays only linked children and parent functions.'],
['Invalid credentials','Teacher / Parent','Existing test account','Attempt incorrect password and unknown account; then use valid credentials.','Invalid attempts fail without exposing credentials; valid login still works.'],
['Mobile role restriction','Support + admin witness','TD-08 school admin, platform owner and unsupported role accounts','Attempt mobile login for each unsupported role.','Mobile access is refused; school admin and platform owner continue using their authorised web roles.'],
['Public registration restriction','Support + test lead','Approved test API client','Attempt unrestricted public account registration.','Request is denied; users follow teacher/school-admin invitation paths.'],
['Invitation account activation','Parent / Teacher','Unused valid invitation; TD-09 email','Open invitation; set compliant password; sign in.','Correct invited account activates; school/role/child links remain correct.'],
['Expired and reused invitations','Support + invited user','Expired invitation and previously used invitation','Open each invitation; request an authorised replacement; activate replacement.','Expired/reused tokens cannot grant access; replacement follows the approved activation flow.'],
['Forgot password','Parent / Teacher','TD-09 approved mailbox','Request reset; open email; set new password; log in with old then new password.','Reset reaches the intended mailbox; old password fails and new password succeeds.'],
['Change password while signed in','Parent / Teacher','Authenticated account; current password','Submit incorrect current password; then change with valid current password; sign in again.','Incorrect current password is rejected; valid change persists and new credentials work.'],
['Session restoration','Parent','Signed-in account; app background/closed normally','Close and reopen app; inspect account and child context.','Valid session resumes safely; user is not switched to another account or child.'],
['Expired session and logout','Support + Parent','Disposable test session/token','Invalidate session; request data; sign in again; log out; attempt old-token API call.','Invalid session returns to authentication; logout revokes that session and protected calls fail.'],
['Zimbabwe phone OTP login','Parent / Teacher','TD-10 approved Econet/NetOne number; SMS authorised','Request OTP using supported local/international format; enter received code within five minutes.','Normalised number identifies the correct existing account; valid code signs in to the correct role.'],
['OTP validation and replay','Support + Parent','Approved number; fresh OTP','Try wrong code, expired code, and previously consumed code; exhaust five wrong attempts on a separate challenge.','Wrong/expired/reused codes fail; attempt limit prevents further use of exhausted challenge.'],
['OTP throttling and unavailable SMS','Support + Parent','Staging; authorised gateway failure simulation','Request again within one minute; try unsupported/unregistered number; simulate gateway outage.','Throttling applies; unsupported numbers are handled safely; unknown accounts are not disclosed; outage does not report successful delivery.']
]);
group('Platform & school setup', [
['Create and view school','Platform owner','TD-05 distinct test schools','Create a test school with required details; reopen school list/detail.','School persists once with correct details and a distinct school identity.'],
['School admin onboarding','Platform owner / School admin','TD-08; approved mailbox','Invite/create school administrator; activate account; sign in to web.','Admin is linked to the intended school and sees that school’s administration.'],
['Platform owner permission boundary','Platform owner + support','TD-05; approved API client','Attempt direct updates to attendance, journals and fees as platform owner.','Internal school operations are denied even if an API URL is known.'],
['School identity updates','School admin','Own school; original settings recorded','Update supported school contact/settings fields; save and reload.','Valid changes persist for own school; unrelated schools remain unchanged.'],
['Academic year configuration','School admin','TD-06; disposable academic-year records','Create academic year; select current year; reload relevant class views.','Correct current-year context persists; records remain attached to the intended year.'],
['Grades and classes','School admin','TD-06; classes with same name in different grades','Create grades/classes; edit permitted fields; view class selectors.','Grade/class choices remain distinct and preserve correct school/year associations.'],
['Required-field validation','School admin','Disposable school/class setup inputs','Submit missing required and invalid values; correct and save.','Invalid input is explained without partial records; corrected values save.'],
['School data isolation','Support + two school admins','TD-05; known IDs from both schools','As School A admin, request/edit School B students, staff and settings using direct IDs.','Requests are denied or hidden; no cross-school data is returned or modified.']
]);
group('Staff & subject assignment', [
['Invite teacher','School admin / Teacher','TD-08–09; unused teacher email','Invite teacher; activate; log in on mobile.','Teacher belongs to the intended school and has the teacher role.'],
['Assign teacher class and subject','School admin / Teacher','TD-06–07; assigned teacher','Assign class and subject; refresh teacher app; open class/subject selectors.','Assigned class/subject becomes available without unrelated classes or subjects.'],
['Unassigned teacher state','Teacher','TD-08 unassigned teacher','Sign in; open register, homework and publishing views.','Clear unassigned/empty state appears; teacher cannot select another teacher’s class.'],
['Reassign teacher class','School admin / Teacher','Teacher assigned to Class A; Class B available','Change assignment to Class B; refresh app; try old Class A action.','Current assignment is reflected; old class access is removed; historical records remain intact.'],
['Same class name in two grades','Teacher + support','TD-06 duplicate class names in different grades','Open assigned roster; try posting to the other grade’s identically named class.','Only the assigned grade/class roster is visible; wrong-grade posting is rejected.'],
['Unauthorised subject publishing','Teacher + support','Teacher assigned Subject A but not Subject B','Publish homework for A; attempt B using selector or direct request.','Allowed subject succeeds; unassigned subject is rejected unless teacher has an authorised all-subject assignment.']
]);
group('Student enrolment & links', [
['Teacher enrols student','Teacher','Assigned class; TD-11 fictitious learner','Enter required student details and assigned class; save; reopen roster.','Student appears once in the correct class/school with correct details.'],
['Create guardian during enrolment','Teacher / Parent','TD-11; unused approved guardian email/phone','Enrol learner with a new guardian; complete invitation; sign in as guardian.','Guardian account/link is created correctly; invitation reaches approved destination; learner appears.'],
['Link existing guardian','Teacher / Parent','Existing parent linked to another test child','Enrol another child with the existing guardian; sign in as parent.','Existing account is reused appropriately; both authorised children are visible without duplicate parent accounts.'],
['Enrolment validation','Teacher','Disposable learner input','Submit missing required fields and malformed contact details; correct and resubmit.','Invalid data is rejected clearly; corrected enrolment creates one valid learner.'],
['Enrolment class boundary','Support + Teacher','Assigned Class A; unassigned Class B','Attempt enrolment into Class B or another school via direct request.','Unauthorised class/school enrolment is denied and no orphan student/guardian record is created.'],
['CSV student import','Teacher','TD-12 approved template with several synthetic rows','Import valid CSV; review results and class roster.','Valid rows create correctly linked learners in the assigned class; import outcome identifies successes.'],
['CSV invalid rows and duplicates','Teacher','TD-12 malformed/missing/duplicate rows; baseline count','Import mixed file; inspect error report; retry only corrected failed records.','Invalid rows are identified; created records match reported successes; accidental duplicates are detectable and not silently hidden.'],
['Resend guardian invitation','Teacher / Parent','Unactivated linked guardian; approved mailbox','Resend invitation; follow latest valid link; inspect learner association.','Invitation goes to the correct guardian; account activation retains correct child links.'],
['Guardian link request approval','Parent / School admin','TD-11 valid learner-link test data','Submit supported link request; review and approve as school admin; refresh parent app.','Request appears for the correct school; approval links only the intended parent and child.'],
['Reject invalid link request','School admin / Parent','Invalid or unauthorised pending link request','Reject request; refresh applicant’s child list; attempt direct child access.','Rejected request grants no child access and remains traceable in the review workflow.'],
['Admin edits learner details','School admin / Teacher / Parent','Own-school test student; baseline values','Edit supported learner details/class as admin; refresh authorised views.','Authorised views show saved changes in the correct class; other learners are unchanged.'],
['Guardian and student list privacy','Teacher + support','Assigned and unassigned learners in two schools','Open roster/contact details; request unassigned learner IDs directly.','Only authorised learners and their permitted guardian contacts are exposed.']
]);
group('Parent profile & child selection', [
['Parent contact profile','Parent','TD-08; recorded baseline contact fields','Edit supported profile/contact fields; save; reload.','Valid contact changes persist for that account and appear where authorised staff require them.'],
['Emergency contact and address','Parent','Fictitious contact/address values','Update supported emergency/address fields; reopen profile.','Fields persist accurately without modifying another parent’s profile.'],
['Language selection','Parent','Available language options','Choose each supported language; navigate and restart.','Selected supported language persists; navigation and critical labels remain readable.'],
['Switch linked children','Parent','TD-11 multi-child parent with different classes','Switch child; open journals, attendance, homework, reports and fees for each.','Every child-specific view changes to the selected child without showing the previous child’s records.'],
['Refresh after school update','Parent / Teacher','Parent on child dashboard; teacher authorised to add data','Teacher saves a new relevant record; parent refreshes/reopens its screen.','New record appears for the correct child without needing a new account/login.'],
['Unlinked child direct access','Support + Parent','Known unrelated test student ID','Request unrelated child profile, attendance and files using direct IDs.','Access is denied; no unrelated student details or file contents are returned.']
]);
group('Student photographs', [
['Parent uploads learner image','Parent','TD-13; linked child; valid JPG/PNG under 4 MB','Upload photo; save; reopen child profile and restart app.','Saved photo persists for the correct child without rotation/stretching that prevents identification.'],
['Teacher sees parent-added image','Parent / Teacher','Parent photo saved; teacher assigned to learner','Refresh teacher student list, register, activity roster and student profile.','The same current learner photo is visible in supported teacher roster/profile locations.'],
['Replace image and refresh cache','Parent / Teacher','Existing learner image; second distinct valid image','Replace image; refresh both devices; reopen views.','New image replaces old image consistently; stale cached image is refreshed.'],
['Photo upload validation','Parent','TD-13 oversized file, unsupported format and excessive dimensions','Attempt each invalid file; then upload a valid image.','Invalid files are rejected with useful feedback; existing photo remains; valid file succeeds.'],
['Delete learner image','Parent / Teacher','Linked child with existing photo','Remove image through supported action; refresh teacher roster.','Photo is removed and a usable placeholder appears without broken-image crash.'],
['Photo privacy and access control','Support + unrelated Parent / Teacher','Known protected photo URL/child ID','Request photo as an unrelated user and without authentication.','Protected image is denied; authorised linked parent/assigned teacher can still view it.']
]);
group('Medical information', [
['Parent saves medical information','Parent / Teacher','TD-14 fictitious medical fields; linked child','Save allergies, conditions, medication and care instructions; reopen as parent and assigned teacher.','Saved fields appear accurately to authorised users for the same child.'],
['Clear medical values','Parent','Existing fictitious values','Clear optional medical fields; save; reload.','Cleared values stay cleared; previous medical text does not reappear.'],
['Medical field length validation','Parent','Generated fictitious text at 2,000 and 2,001 characters','Save boundary-length field; attempt over-limit field.','Supported boundary value saves; over-limit text is rejected without truncating unrelated data.'],
['Teacher medical read-only permission','Support + Teacher','Assigned learner with medical information','Read information; attempt update through direct request.','Teacher can read assigned learner information but cannot change guardian-managed medical fields.'],
['Medical privacy','Support + Parent / Teacher','Unrelated child ID; signed-out session','Attempt access from unrelated and signed-out accounts; inspect response/cache behaviour.','No unrelated medical information is disclosed; protected responses use private/no-store handling.']
]);
group('Teacher attendance register', [
['Load assigned register with photos','Teacher','TD-06,11,13; assigned class','Open marks/attendance register for the intended class and date.','Correct student roster, names and available images appear; no students from another grade/class.'],
['Initial register requires save','Teacher','New test date without attendance records','Open register; inspect default selections; leave without saving; reopen.','Default presentation is not falsely reported as a saved register; saved status reflects server records only.'],
['Save all present','Teacher / Parent','New test date; assigned roster','Set all present; save; reload teacher register and parent attendance.','All intended learners are recorded present for that date; parent sees own child’s saved result.'],
['Mixed present, absent and late','Teacher / Parent','At least three learners; selected date','Set one present, one absent and one late; save; reload.','Each learner retains the exact selected status; late saves successfully and displays correctly.'],
['Edit saved register','Teacher','Existing saved mixed register','Change one learner’s status; save twice; reload.','Latest status persists; each learner/date has one attendance record with no duplicate totals.'],
['Date navigation','Teacher','Two dates with distinct attendance data','Switch dates back and forth; reload.','Each date shows its own saved statuses and saved/not-saved indication.'],
['Register persistence after restart','Teacher','Saved date and statuses recorded as evidence','Close/reopen app; sign in if required; open same date.','Saved server attendance is restored correctly.'],
['Partial/invalid register input','Support + Teacher','Staging API client; valid roster','Submit invalid status, missing learner and unrelated learner IDs in controlled requests.','Invalid or unauthorised records are rejected; no unrelated learner is modified; valid saved data stays consistent.'],
['Concurrent register updates','Two Teachers + test lead','Both authorised for same class if supported; agreed conflict expectation','Load same date on two devices; save distinct changes sequentially; reload both.','Final saved state is consistent across devices; overwrite behaviour is recorded and accepted by school lead.'],
['Attendance access boundary','Support + Parent / Teacher','Assigned and unrelated child/class IDs','Try guardian write and teacher write to unassigned class/other school.','Writes are denied; guardian can only read permitted child attendance.'],
['Failed save feedback','Teacher','Unsaved register changes; network can be disabled','Disable network; save; restore connection; retry and reload.','Failed save is clearly identified; no false saved marker; successful retry persists intended statuses.']
]);
group('Merits & demerits', [
['Configure behaviour categories','School admin','Own-school test categories','Create/edit supported merit and demerit categories; refresh teacher selector.','Correct own-school categories are available; other schools’ categories are excluded.'],
['Record merit','Teacher / Parent','Assigned learner; valid merit category','Add a merit with supported note; reload teacher and parent views.','Record belongs to correct learner/category and totals reflect the added merit.'],
['Record demerit','Teacher / Parent','Assigned learner; valid demerit category','Add a demerit; inspect history and totals.','Demerit displays separately and aggregates correctly without changing another learner.'],
['Behaviour validation','Teacher','Assigned learner','Submit missing required category/invalid values; correct and save.','Invalid entries are rejected clearly; valid record saves once.'],
['Behaviour scope and parent permissions','Support + Teacher / Parent','Unassigned learner; own linked learner','Attempt teacher entry for unassigned learner; attempt guardian write.','Unauthorised changes are denied; parent reads only linked child’s permitted records.']
]);
group('Activities & participation', [
['View assigned activity roster','Teacher','Assigned class; learners with and without photos','Open activity/participation roster.','Correct assigned learners and image placeholders/current photos are shown.'],
['Save participation states','Teacher / Parent','At least four assigned learners; test activity/date','Save supported present, late, absent and not-on-roster states; reload.','Each state is stored and displayed for the correct learner/activity; parent sees permitted own-child information.'],
['Change or remove participation','Teacher','Existing participation record','Change status; remove learner from roster using supported action; reload.','Latest status persists; removal clears participation as intended without duplicating records.'],
['Participation date and class scope','Teacher + support','Two dates/classes with different records','Switch context; attempt posting to unassigned class.','Records remain separated by context; unassigned-class writes are denied.'],
['Activity failures and empty roster','Teacher','Empty assigned class and controlled network failure','Open empty roster; attempt save during outage; reconnect.','Empty state and failure are understandable; no crash or false saved state.']
]);
group('Homework & assignments', [
['Publish homework','Teacher / Parent','TD-07 assigned subject; linked parent','Create title, instructions and due date for assigned class/subject; open as parent.','Homework appears with correct title, instructions, teacher, class, subject and due date.'],
['Due-date grouping','Teacher / Parent','Assignments due yesterday, today and tomorrow','Open upcoming/overdue sections and relevant filters.','Past dates appear overdue; today/future appear upcoming according to the agreed school date.'],
['Homework required fields','Teacher','Assigned class/subject','Attempt blank title/missing required input and invalid date; correct and publish.','Invalid input is rejected; corrected homework saves without duplicate blank assignments.'],
['Homework authorisation','Support + Teacher','Unassigned class and unassigned subject IDs','Attempt publish for each unauthorised context.','Server rejects unauthorised class/subject combinations.'],
['Parent assignment isolation','Parent','Multi-child family with different classes','Switch children and apply supported filters.','Only homework relevant to the selected child/class is shown.'],
['Homework read-only parent view','Support + Parent','Existing child homework','Read details; attempt direct create/edit/delete as parent.','Parent can read permitted homework but cannot modify teacher assignments.'],
['Homework refresh and empty state','Parent / Teacher','Class with no homework; later teacher publication','Open empty view; publish one item; refresh parent view.','Helpful empty state changes to the new assignment with correct ordering.']
]);
group('Journals & wellbeing', [
['Publish text journal','Teacher / Parent','Assigned learner/class; active linked parent','Publish a text journal; refresh parent feed and open details.','Text, author, date and intended child/class are correct; unrelated families cannot see it.'],
['Photo and drawing journals','Teacher / Parent','TD-15 valid supported photo/drawing files','Publish one photo and one drawing journal; open each as parent.','Correct images load clearly with associated journal details.'],
['Video journal playback','Teacher / Parent','TD-15 short supported video under limit','Upload video; publish; play on parent phone.','Upload completes; video plays using intended media with usable controls.'],
['Voice journal playback','Teacher / Parent','TD-15 supported audio under limit','Upload voice recording; publish; play on parent phone.','Audio plays for authorised parent with correct journal context.'],
['External-link journal','Teacher / Parent','Approved safe HTTPS URL','Publish supported link entry; open link as parent.','Correct link opens through supported handling; malformed/unsafe input is rejected or safely handled.'],
['Wellbeing entry','Teacher / Parent','Fictitious meals, nap, hygiene and mood values','Save supported wellbeing fields; view as parent.','Saved wellbeing details belong to the intended child and display accurately.'],
['Journal upload limits','Teacher','TD-15: image over 8 MB; media over 10 MB; invalid format','Try each invalid upload; then valid supported file.','Invalid media is rejected clearly; valid media succeeds and no broken published entry is left behind.'],
['Journal filtering and order','Parent','Different journal types and dates for linked child','Use available type/date filters; reopen feed.','Results match selected filter and expected date ordering with correct author details.'],
['Journal unread badge','Parent / Teacher','Parent has read existing feed; teacher publishes a new entry','Observe Journal badge; successfully open/load relevant feed; reopen home.','New relevant entry increases unread count; successfully viewed entries are marked read and badge updates.'],
['Journal privacy and write restriction','Support + Parent / Teacher','Other child/school journal IDs','Attempt unrelated read; guardian write; teacher publish outside assignment.','All unauthorised requests are denied; permitted own-child reading remains available.'],
['Admin journal removal','School admin / Parent','Own-school disposable journal','Delete through authorised admin action; refresh parent feed and media access.','Removed journal is no longer shown; admin cannot delete another school’s journal.']
]);
group('Student reports & files', [
['Upload report PDF','Teacher / Parent','TD-16 valid PDF; assigned learner','Upload report with supported details; open child report list as parent.','Report appears under correct child with accurate metadata.'],
['Download and read report','Parent','Active linked child with report; physical device','Open/download report; inspect PDF pages and filename.','Authorised PDF opens intact and belongs to the selected child.'],
['Invalid report upload','Teacher','Non-PDF/invalid file and missing required fields','Attempt unsupported report uploads; correct and retry.','Invalid input is rejected; no unusable report record is exposed to parent.'],
['Protected report link access','Support + Parent','Known signed/protected report URL','Open with correct account; then unrelated/signed-out account and expired link.','Only authorised, valid access succeeds; protected file cannot be obtained by guessing/copying IDs.'],
['Report access after unlink/suspension','School admin / Platform owner + Parent','Disposable linked child/report; restoration authorised','Unlink or suspend the child using authorised setup; retry list and existing file URL; restore.','Access follows current link/subscription state even for a previously obtained URL.'],
['Missing report file','Support + Parent','Staging-only disposable record whose file is unavailable','Open report with missing file; inspect response and app.','Clear not-found/unavailable handling appears without crash or another file being served.'],
['Unpaid fee does not hide reports','Parent','Active child subscription; outstanding school fee; available report','Open report list and PDF.','Outstanding fees alone do not block academic report access while child access is otherwise authorised.']
]);
group('Notices & announcements', [
['School-wide notice','School admin / Parent / Teacher','TD-05; approved audience accounts','Publish own-school announcement for configured audience; refresh recipients.','Intended own-school recipients see correct title/body/date; other school receives nothing.'],
['Class/grade-targeted notice','School admin / Teacher / Parent','TD-06; same class name in different grades','Publish notice for specific grade/class; inspect matching and nonmatching accounts.','Only intended grade/class audience sees notice and unread increment.'],
['Teacher assigned-class announcement','Teacher / Parent','Assigned class and unrelated class','Publish to assigned class/all assigned classes; attempt unrelated target.','Permitted recipients receive announcement; unrelated target is denied.'],
['Role-targeted audience','School admin / Parent / Teacher','Guardian-only and teacher-only test notices','Publish each supported audience selection; inspect both roles.','Role-specific notices reach only the selected audience.'],
['Notice unread and opening','Parent / Teacher','Unread relevant notice','Observe badge; open individual notice; return to list/home; restart.','Opened notice is marked read; badge decrements and remains correct after restart.'],
['Mark all notices read','Parent / Teacher','Several unread relevant notices','Use supported mark-all-read action; refresh and sign in again.','All eligible notices become read for that account; other accounts remain unread.'],
['Notice search/filter/order','Parent / Teacher','Several notices with distinct dates/text and read states','Search known text; apply available filters; clear filters.','Displayed notices match supported criteria and date ordering; no unrelated notices appear.'],
['Notice validation and access','Support + School admin / Parent','Disposable own-school notice','Submit blank required fields; attempt parent publishing and cross-school mutation.','Invalid input and unauthorised changes are rejected; valid authorised notice saves.']
]);
group('Messaging & delivery receipts', [
['Teacher sends parent message','Teacher / Parent','TD-17 authorised pair; both signed in','Teacher opens permitted parent thread and sends text; parent refreshes/receives.','Message appears once in intended conversation with correct sender, body and time.'],
['Parent replies to teacher','Parent / Teacher','Existing authorised conversation','Parent replies; teacher opens thread.','Reply appears in the same correct conversation and unread indicators update.'],
['Message validation and length','Teacher / Parent','Authorised conversation; 2,000/2,001-character sample','Try whitespace-only text; send allowed boundary text; try over-limit text.','Blank/over-limit messages are rejected; accepted text is displayed accurately.'],
['Single grey sent tick','Teacher / Parent','Recipient app closed/offline; notifications may still be enabled','Send message; inspect sender before recipient foreground synchronisation.','Accepted server message shows single grey sent tick while delivery receipt is absent; push receipt alone does not imply read.'],
['Double grey delivered ticks','Teacher / Parent','Unread sent message; recipient opens app outside that thread','Bring recipient online in foreground; allow normal polling/synchronisation; inspect sender.','Delivery receipt is persisted and sender shows double grey ticks; merely being online does not turn ticks blue.'],
['Blue read ticks','Teacher / Parent','Delivered unread message; two phones','Open the actual recipient conversation; allow receipt refresh; inspect sender.','Message becomes read and sender shows blue ticks; recipient unread count decreases.'],
['Background does not mark read','Teacher / Parent','Unread message; recipient on another screen/background','Receive push; remain outside conversation or cover/background app; inspect sender.','Message remains unread until the relevant conversation is visibly opened under the app’s read rules.'],
['Receipt persistence across restart','Teacher / Parent','One delivered and one read message','Restart sender and recipient apps; reopen conversation.','Persisted delivered/read statuses remain correct; read messages do not revert to sent.'],
['Unread counts and conversation preview','Teacher / Parent','Several unread messages in two conversations','Observe Messages badge/thread counters and latest preview; read one conversation.','Counts reflect unread messages for the account; only viewed thread clears and previews show correct latest content.'],
['Conversation search and history','Teacher / Parent','Permitted contacts and long test conversation','Search contacts/conversations using available control; open history including recent 200-message window.','Search returns permitted matches; latest messages load in correct order within supported history window.'],
['Broadcast to class parents','Teacher / Parent','TD-17; guardian linked to two learners in same class','Send supported all-parents message for assigned class; inspect recipient threads.','Eligible guardians receive one intended copy; duplicate links do not create duplicate recipient messages.'],
['Broadcast recipient receipt isolation','Teacher / two Parents','Broadcast to Parents A and B; B stays offline','A reads; inspect each recipient’s message receipt; then B synchronises.','A’s read action does not falsely mark B’s message read; each recipient receipt follows their own activity.'],
['Messaging relationship boundary','Support + Parent / Teacher','Unrelated teacher/guardian and other-school IDs','Attempt direct message to unrelated contacts using manipulated recipient IDs.','Server rejects unauthorised relationships and does not disclose unrelated conversations.'],
['Network send failure','Teacher / Parent','Authorised thread; network switch','Disable network; attempt send; restore; retry deliberately; refresh both accounts.','Failure is clearly shown without false sent success; accepted retry reaches intended thread; any duplicate is logged as an issue.'],
['Read state on another device','Parent / Teacher','Same recipient account signed in on two approved devices','Read conversation on device A; refresh device B and sender.','Server-backed unread/read status synchronises correctly across devices.']
]);
group('Phone notifications & badges', [
['Notification permission granted','Parent / Teacher','TD-18–19; physical Android; approved installed build','Sign in; grant notification permission; send relevant new content from another account.','Device can register for notifications; intended new content produces a visible phone notification.'],
['Permission denied then enabled','Parent','Physical Android with notifications denied','Send message; open app; enable notifications in OS settings; repeat test.','App remains usable with correct in-app unread state; after enabling/registering, new notifications can appear.'],
['Message notification in background','Teacher / Parent','Two phones; recipient backgrounded; network available','Send new authorised message; record send and receive timestamps; tap notification.','Recipient gets phone notification within agreed threshold; tap opens correct authorised messaging destination.'],
['Foreground message notification','Teacher / Parent','Recipient foregrounded outside target thread','Send new message; inspect foreground alert and unread count.','Supported foreground/local notification and badge update occur without duplicated message records or alerts.'],
['Notice notification and deep link','School admin / Parent','Recipient eligible for new notice','Publish notice while parent app is backgrounded; tap notification.','Only intended recipient is notified; correct notice area/item opens and read state updates when viewed.'],
['Journal notification and child route','Teacher / Parent','Parent linked to two different children','Publish journal for child B while app last showed child A; tap phone notification.','Correct journal/child context opens without leaking or displaying child A content as child B.'],
['Separate icon unread indicators','Parent / Teacher','New messages, relevant notices and journals; counts recorded','Return home/navigation; read one category at a time; refresh.','Each supported icon shows its own accurate unread badge; reading one category does not clear unrelated counters.'],
['Multiple new items and badge reset','Parent','Several new items; all previous content read','Create multiple relevant items; inspect counts; view/mark read using each supported flow.','Unread counts increment accurately, persist across refresh and clear only for content actually marked read.'],
['Multiple signed-in phones','Parent','Same account on two physical phones with permission','Create new relevant content; inspect both phones; read on one; refresh other.','Eligible devices receive notifications and server-backed unread state converges after reading.'],
['Logout token handling','Parent / Teacher','Recipient phone previously received notifications','Log out; send content; sign in as another account; send to former account again.','Logged-out/other-account phone does not expose former user’s new notifications; new account receives only its own.'],
['Notification privacy and invalid access','Support + Parent','Protected content and unrelated signed-in account','Inspect lock-screen preview; tap old notification after access is removed or account switched.','Preview follows approved privacy policy without sensitive medical details; app rechecks authorisation and refuses inaccessible content.'],
['Delayed/offline notification recovery','Parent','Network disabled on recipient; OS not force-stopped','Send content; restore network; reopen app and refresh if required.','Content and unread status recover correctly; delay is measured; push arrival is distinguished from in-app retrieval.'],
['Delivery diagnostics and retry','Support + test lead','Staging/test tokens; worker/log access; no secrets recorded','Verify worker health; send approved test notification; inspect delivery failure/retry and invalid-token cleanup.','Failures are traceable and retried/handled appropriately; invalid tokens do not repeatedly break delivery; evidence omits tokens/keys.'],
['iOS push conditional scope','Support + Parent','Only if iOS is in release scope: approved build, APNs and physical iPhone','Record iOS prerequisites; repeat background/foreground/tap delivery tests.','Actual device delivery/routing is demonstrated; absent prerequisites are Blocked or formally approved N/A, never assumed Pass.']
]);
group('SMS alerts & emergency SOS', [
['SMS alerts history','Parent','TD-20 approved test recipient; authorised test SMS record','Open supported SMS alerts/history screen; inspect own records.','Parent sees only their permitted alert history with correct details/status.'],
['Teacher emergency SOS','Teacher / Parent','TD-20; isolated test class; explicit test-recipient authorisation','Send clearly labelled test SOS from assigned class; inspect approved recipients only.','Intended class guardians receive configured in-app/emergency and SMS channels; unrelated recipients receive nothing.'],
['SOS alarm acknowledgement','Parent','Controlled incoming test SOS','Open alarm; acknowledge; restart/reopen app.','Acknowledgement persists; same acknowledged alarm does not repeatedly sound; history remains available.'],
['SOS scope restriction','Support + Teacher / Parent','Unassigned class; other-school IDs','Attempt SOS for unrelated class and from guardian account.','Unauthorised SOS is denied with no out-of-scope messages sent.'],
['SOS throttling','Support + Teacher','Staging approved recipients; controlled repeated requests','Attempt more than two SOS submissions within one minute.','Rate limit prevents excess submissions; successful/failed outcomes are clear.'],
['SMS gateway failure','Support + Teacher','Staging gateway outage simulation; no real public recipients','Trigger approved SMS/SOS test while gateway unavailable; restore and inspect log.','Failure is recorded accurately; app does not claim confirmed SMS delivery when gateway rejected it.']
]);
group('Fees & payment verification', [
['View child fees in USD/ZiG','Parent','TD-21; linked children with known balances/transactions','Open fees for each child/currency; compare to approved ledger baseline.','Correct child balance and history appear; USD and ZiG amounts are clearly separated and reconciled.'],
['Admin updates fee balance','School admin / Parent','Own-school child; recorded starting balance','Apply authorised balance change; refresh parent details; reconcile.','New balance persists correctly and does not change another child/currency account.'],
['Submit payment reference','Parent','Approved test amount/reference; no real payment; supported fees flow/API','Submit payment details; inspect parent history and admin pending list.','Payment is pending verification; unverified reference does not falsely credit balance.'],
['Verify fee payment once','School admin / Parent','Pending synthetic fee payment with approved evidence','Verify as admin; record resulting balance; repeat verification request with support.','Verified payment credits intended account once; repeat action does not double-credit.'],
['Fee input validation','Parent / School admin','Staging synthetic payment data','Try nonpositive/invalid amount, unsupported currency and missing reference.','Invalid inputs are rejected without corrupting account balances.'],
['Fee role and school boundary','Support + Parent / Teacher / School admin','Other-school payment/account IDs','Try guardian self-verification, teacher balance change and cross-school admin change.','Unauthorised financial changes and unrelated account access are denied.'],
['Outstanding fees and academic access','Parent','Active child subscription; nonzero fee balance','Open journals, attendance, homework and available reports.','Outstanding school fees alone do not hide otherwise authorised academic records.']
]);
group('Uniform catalogue & orders', [
['Admin catalogue maintenance','School admin / Parent','TD-22; disposable own-school SKU, image, sizes and stock','Create/edit item and price/stock; refresh parent catalogue.','Own-school item details, supported sizes, currency and availability are accurate.'],
['School-specific catalogue','Parent','Children in distinct schools; different test catalogues','Switch selected child and open uniforms.','Catalogue context follows intended school/child; no unintended cross-school ordering.'],
['Place valid uniform order','Parent','TD-22; in-stock sizes; known prices','Choose size and quantity; submit order; inspect history/admin view.','Order contains correct child, size, quantity, currency and server-calculated total.'],
['Quantity and stock validation','Parent + support','Known limited stock; controlled API client','Try zero, negative, over-20 quantity and insufficient-stock purchase.','Invalid/excess quantities and unavailable stock are rejected; no negative stock or false order success.'],
['Server-side price calculation','Support + Parent','Disposable sandbox order','Manipulate submitted price/total/currency against catalogue; submit.','Server validates/recalculates trusted catalogue prices and prevents client price tampering.'],
['Missing size and excessive items','Parent + support','Size-required item; more than 50 distinct submitted lines','Try missing/invalid size and excessive distinct item count.','Invalid selections/oversized order are rejected with no incomplete paid order.'],
['Order history and privacy','Parent + support','Two parents with separate test orders','Open order history/details; try unrelated child/order IDs.','Parent sees own permitted orders and correct statuses; unrelated orders are denied.'],
['Manual uniform payment reference','Parent / School admin','Approved non-gateway payment method and synthetic reference','Submit reference; review pending payment; verify as authorised admin.','Pending reference is distinguished from paid order; verified payment updates correct order once.'],
['Catalogue permissions','Support + Parent / Teacher / School admin','Own and other-school catalogue IDs','Attempt guardian/teacher catalogue writes and cross-school admin update.','Only authorised own-school admin changes succeed.']
]);
group('PesePay checkout & callbacks', [
['Hosted sandbox checkout','Parent','TD-23 sandbox confirmed; valid test order; no real funds','Initiate checkout; follow hosted sandbox payment path.','Checkout references correct order, trusted amount and currency without exposing gateway secrets.'],
['Successful verified payment','Parent / Support','Sandbox success scenario; pending order','Complete approved sandbox success; return to app; refresh payment status.','Provider-confirmed transaction marks correct order paid and records correct reference/amount/currency.'],
['Cancelled or failed checkout','Parent','Sandbox cancelled/failed scenarios','Cancel/fail payment; return to app; refresh status.','Order is not marked paid and retry/status guidance is clear.'],
['Pending provider result','Parent / Support','Sandbox pending scenario','Initiate payment; return before final confirmation; refresh later.','Order remains pending until verified provider result; app does not infer paid from navigation/return alone.'],
['Callback authenticity and mismatch','Support + finance witness','Isolated staging; approved callback fixtures','Submit invalid encrypted/authenticity payload and mismatched amount/currency/reference.','Untrusted/mismatched callbacks cannot mark order paid or alter balances/stock.'],
['Duplicate callback/status idempotency','Support + finance witness','Approved sandbox successful transaction','Replay valid callback and repeat payment-status checks; reconcile order/stock/ledger.','Payment and stock/financial effects occur once without duplicate credits or deductions.'],
['Gateway order manual override protection','School admin + support','Gateway-managed test order','Attempt manual reference/verification to bypass provider confirmation.','Gateway-managed payment cannot be falsely paid through the manual-reference path.'],
['Gateway outage and timeout recovery','Parent / Support','Sandbox outage/timeout simulation','Start checkout during failure; restore service; check status before approved retry.','Clear failure/pending state appears; recovery uses authoritative provider status without charging or crediting twice.']
]);
group('Subscriptions & access control', [
['Activate child subscription','Platform owner / Parent','TD-24; authorised child subscription changes','Activate valid current subscription; refresh linked parent access.','Authorised child functions become accessible within approved subscription rules.'],
['Suspended child access','Platform owner / Parent','Disposable child currently active; baseline captured','Suspend subscription for current effective dates; attempt child data and protected files.','Guardian access is blocked with clear subscription-suspended guidance; protected URLs also enforce current state.'],
['Future and expired periods','Platform owner + support / Parent','TD-24 subscription future-start and past-end scenarios','Apply each date scenario; request child content.','Guardian access follows effective start/end dates and documented suspension policy.'],
['Per-child subscription boundary','Parent','Two linked children; only child A suspended','Switch between children and open child-specific data.','Suspension blocks only affected child; authorised child B remains accessible.'],
['Teacher/admin continuity during suspension','Teacher / School admin','Suspended child in own assigned class/school','Read/update authorised internal school records.','Authorised staff retain permitted internal functions while guardian subscription restriction is enforced.'],
['Restore subscription access','Platform owner / Parent','Previously suspended child; restoration approved','Restore valid active period; refresh parent app and report link.','Access resumes according to current subscription without loss of existing records.'],
['Subscription management authority','Support + School admin / Teacher / Parent','Known subscription/child IDs','Attempt unauthorised activation/suspension from non-owner roles.','Only authorised platform management can change subscription status; unauthorised writes fail.'],
['No-subscription record policy','Platform owner + test lead','Disposable learner without subscription record; policy owner present','Inspect current application behaviour; document expected rollout policy and decision.','Observed behaviour is recorded against approved business policy; disagreement is logged before acceptance rather than assumed.']
]);
group('Performance, resilience & usability', [
['Measure representative data loads','Test lead / Support','TD-25 agreed thresholds; seeded realistic test volume; TD-04 network/device','Time cold and warm dashboard, roster, messages, journal and report-list loads; record each duration/evidence.','Each measured load meets its agreed threshold; failure identifies endpoint, data volume, network and device rather than guessing cause.'],
['Long lists and media responsiveness','Teacher / Parent','Representative large roster/history; supported media files','Scroll lists; open images/media; navigate back; repeat on slower approved device.','Usable scrolling and loading feedback; no freezes, out-of-memory crash or persistent blank media.'],
['Slow network and repeated navigation','Teacher / Parent','Controlled slow/unstable connection','Open different child screens quickly; switch child while requests are loading.','Loading completes/fails clearly; late responses do not overwrite the current child/context.'],
['Offline profile and protected data','Parent','Previously signed-in account; network disabled','Open available cached profile; attempt server-only action; log out; inspect cached views.','Supported cached information is clearly limited; unsaved actions show failure; logout prevents previous-account data exposure.'],
['User-visible server errors','Support + Teacher / Parent','Approved staging 401/403/404/500 scenarios','Trigger each controlled error; inspect app; recover with valid request.','Errors are readable and actionable; no stack traces/secrets appear; app can recover safely.'],
['Screen readability and accessibility','Teacher / Parent','Small and large approved phones; increased text size','Inspect navigation, unread badges, tick colours, forms, keyboard and media controls.','Critical labels/inputs remain usable without clipping; status has understandable meaning and readable contrast.'],
['Cross-device end-to-end school day','Teacher / Parent / School admin','All core test data; two phones; approved recipients','Teacher records mixed attendance, homework and journal; sends message; parent receives notifications, reads/replies and downloads report.','Correct child data and badges/receipts converge across devices; no unrelated data appears; evidence traces each step.'],
['Release regression and cleanup','Test lead / Support','Completed execution workbook; approved restore baseline','Retest fixes; reconcile remaining issues; restore test subscriptions/financial fixtures; remove test-only records as authorised.','Retests are recorded separately; no test credentials/secrets enter evidence; environment and outstanding risks are documented before sign-off.']
]);

function extra(name, row) { groups.find(g=>g.name===name).rows.push(row); }
extra('Activities & participation',['Create class activity','Teacher / School admin','Assigned own-school learners; synthetic activity title/date','Create activity with selected learners; open activity list and roster.','Activity persists with correct title, date and intended roster; invalid required fields are rejected.']);
extra('Activities & participation',['Admin removes activity','School admin + support','Disposable own-school activity; other-school activity ID','Delete own-school activity; attempt another-school deletion; attempt teacher deletion.','Authorised own-school admin deletion succeeds; cross-school and teacher deletion are denied.']);
extra('Student reports & files',['Admin removes report','School admin / Parent','Disposable own-school report and protected URL','Delete report as admin; refresh parent list and retry previous URL.','Deleted report is absent and unavailable; another school’s report cannot be deleted.']);
extra('Student photographs',['Teacher updates shared learner image','Teacher / Parent','Assigned learner; valid replacement JPG/PNG','Teacher replaces learner image; parent refreshes profile; attempt teacher update for unassigned learner.','Permitted teacher change is shared with linked parent; unassigned learner update is denied.']);
extra('Journals & wellbeing',['Author does not gain own-post unread count','Teacher','Existing unread count noted; assigned class','Publish own journal; inspect teacher badge and intended parent badge after refresh.','Teacher’s own authored entry does not count as a newly unread received journal; intended parent gets relevant unread count.']);
extra('Messaging & delivery receipts',['Messaging rate limit','Support + Teacher','Isolated test conversation; approved request harness','Exceed 30 message submissions within one minute using synthetic short messages.','Excess requests are throttled; app handles rejection clearly without claiming an unsent message succeeded.']);
extra('Platform & school setup',['Administration dashboard totals','School admin','Known own-school learner/staff/record counts; other-school baseline','Open dashboard; compare displayed metrics to approved own-school records; refresh after controlled data change.','Supported metrics reconcile with own-school data and exclude other-school counts.']);
extra('Uniform catalogue & orders',['Remove catalogue item safely','School admin / Parent','Disposable SKU; existing historical synthetic order if supported','Remove SKU as authorised admin; refresh catalogue and historical order.','Removed item is not offered for new purchase; existing order details remain accurate and readable.']);
const cases = groups.flatMap(g => g.rows.map(r=>[g.name,...r]));
const wb=Workbook.create();
const names=['Read Me','Test Data','Test Cases','Summary','Issues Log','Client Sign-off'];
for(const n of names) wb.worksheets.add(n);
const C={dark:'#145A32',green:'#287D46',pale:'#EDF5EF',line:'#D2DFD5',text:'#173522',input:'#FFF8DF',white:'#FFFFFF'};
function base(name,last,widths,subtitle){
 const s=wb.worksheets.getItem(name); s.showGridLines=false; s.tabColor=C.green;
 const range=s.getRange(`A1:${last}4`);range.format.font={name:'Calibri',size:11,color:C.text};range.format.wrapText=true;
 for(let i=0;i<widths.length;i++) s.getRange(`${String.fromCharCode(65+i)}:${String.fromCharCode(65+i)}`).format.columnWidth=widths[i];
 s.mergeCells(`A1:${last}1`);s.getRange('A1').values=[['EDUCONNECT | USER VERIFICATION TEST (UVT)']];
 s.getRange(`A1:${last}1`).format.fill=C.dark;s.getRange(`A1:${last}1`).format.font={name:'Calibri',size:18,bold:true,color:C.white};s.getRange('A1').format.rowHeight=38;
 s.mergeCells(`A2:${last}2`);s.getRange('A2').values=[[subtitle]];s.getRange(`A2:${last}2`).format.fill=C.pale;s.getRange('A2').format.rowHeight=34;
 s.freezePanes.freezeRows(4);s.freezePanes.freezeColumns(1);return s;
}
function grid(s,last,end,headers){
 s.getRange(`A4:${last}${end}`).format.font={name:'Calibri',size:11,color:C.text};
 s.getRange(`A4:${last}${end}`).format.wrapText=true;s.getRange(`A4:${last}${end}`).format.verticalAlignment='top';
 s.getRange(`A4:${last}${end}`).format.borders={preset:'all',style:'thin',color:C.line};
 s.getRange(`A4:${last}4`).values=[headers];s.getRange(`A4:${last}4`).format.fill=C.green;s.getRange(`A4:${last}4`).format.font={name:'Calibri',size:11,bold:true,color:C.white};s.getRange('A4').format.rowHeight=34;
 for(let r=5;r<=end;r++) if(r%2===1) s.getRange(`A${r}:${last}${r}`).format.fill=C.pale;
}
function rows2(name,title,headers,rows,widthA=38,widthB=115){
 const s=base(name,'B',[widthA,widthB],title);grid(s,'B',rows.length+4,headers);
 s.getRange(`A5:B${rows.length+4}`).values=rows;
 for(let i=0;i<rows.length;i++){
  s.getRange(`A${i+5}`).format.font={name:'Calibri',size:11,bold:true,color:C.text};
  const lines=Math.max(Math.ceil(rows[i][0].length/(widthA*.9)),Math.ceil(String(rows[i][1]??'').length/(widthB*.9)));
  s.getRange(`A${i+5}`).format.rowHeight=Math.max(38,lines*16+15);
 }
 return s;
}
rows2('Read Me','Prepared 21 October 2026 | Version 1.0 | Execution results are intentionally unexecuted',['Field / Topic','Instructions / Value'],[
 ['Purpose','User Verification Testing (UVT): authorised users execute these scenarios to judge EduConnect against agreed business requirements. This workbook is a test script, not evidence that any feature has passed.'],
 ['Basis','Structure adapted from Seed Co Zimbabwe - Roadrunner UVT Test Script.xlsx. Scenarios are derived from the EduConnect mobile and Laravel backend source, role boundaries and current integration setup. Test the exact approved deployed build; record differences as issues.'],
 ['Test site URL','Proposed administration/API host: https://admin.chewetechnologies.co.zw (API under /api). Test lead must confirm a safe approved environment before execution; do not assume production is a sandbox.'],
 ['Environment / build tested','Complete Test Data and Client Sign-off before execution. Current pubspec source version: 1.0.0+1; application ID educonnect.com; Firebase project educonnect-13f25. Build-time version overrides may differ: record actual installed and server versions.'],
 ['Test dates / EduConnect lead','Enter the agreed test window, business test lead, school representatives, technical support and issue owners in Test Data.'],
 ['Preparation','Use synthetic learners, distinct schools/classes and approved test accounts. Confirm class/subject assignments, linked children, device permissions, integration sandbox settings and restore plan. No passwords, OTPs, device tokens, personal medical data or private keys belong in this workbook.'],
 ['Execution','Run one scenario at a time using the stated role and prerequisites. Record observed results, evidence reference, tester and date. If prerequisite is unavailable, use Blocked and explain. Do not replace an expected result with an observation.'],
 ['Client entry columns','Test Cases H–N: Status, Actual Result, Comment/Evidence/Variation Results, Issue ID, Tested By, Test Date and Retest Result. Initial Status is Not Run; all execution, evidence, signature and retest fields are blank.'],
 ['Status rules','Pass = observed expected outcome with evidence; Fail = observed mismatch; Blocked = cannot execute; Not Run = not executed; N/A = formally out of agreed scope with reason and approver. Retest Result records the latest retest separately; update current Status after an accepted retest.'],
 ['Evidence','Use non-sensitive screenshot/video/log references and timestamps. For performance record timings and conditions; for notifications use two physical devices and send/receive times. Store evidence in an approved folder, not as secrets or private student data.'],
 ['Issues workflow','Give every failure/blocker a unique issue (for example EC-ISS-001); link its EC test ID. Record reproduction, expected/actual result, priority, owner and target date. Close only after retest evidence and client closure approval.'],
 ['Support-assisted cases','Direct API tampering, receipt/worker diagnostics, rate limits, missing-file simulations and payment callback tests require technical support in an isolated approved environment with a business witness. Do not run destructive simulations against live student data.'],
 ['Coverage limits','Covers platform owner and school-admin web workflows plus teacher/parent mobile functions: enrolment, links, images, medical details, attendance register, behaviour, activities, homework, journals, reports, notices, messaging, phone alerts, fees, uniforms, payments and subscriptions. No student login or academic grading/marks gradebook is assumed.'],
 ['Business confirmation required','Confirm subscription/no-subscription policy, school time zone, SMS recipients/cost authorisation, finance approval, acceptable performance/notification timings, concurrency behaviour and iOS release scope. Values marked TBC are prerequisites, not default acceptance thresholds.'],
 ['Known review focus','FCM configuration/validation is not proof of phone delivery: execute real-device cases. Assign teacher classes/subjects before register testing. Verify saved late attendance and shared student images. Confirm PesePay sandbox before payment tests. iOS requires its own approved build/APNs prerequisites.'],
 ['Completion criteria','All agreed in-scope cases executed; no unresolved Critical/High defects unless explicitly waived by authorised client; each Blocked/N/A and lower-priority residual risk reviewed; fixes retested; evidence and summary reconciled. Acceptance is a separate authorised decision.'],
 ['Client authority','School/business representatives own expected behaviour, risk acceptance and sign-off. Technical deployment, automated tests and existing support checks do not substitute for completed UVT.'],
 ['Workbook use','Keep the six-sheet structure. Filter Test Cases/Issues Log as needed. Preserve test IDs and Summary formula cells; complete yellow input areas. Not Run / Blank includes both initial Not Run and blank status cells; Recorded counts Pass, Fail, Blocked and N/A.'],
 ['Files','Deliverable: EduConnect UVT Test Script.xlsx. Keep the completed workbook, referenced evidence and approved issue/waiver records together under controlled versioning.']
]);
const data=[
 ['TD-01 Environment','Proposed host https://admin.chewetechnologies.co.zw; API /api. Approved test URL / production restrictions: TBC by test lead.'],
 ['TD-02 Mobile release','Current pubspec source version 1.0.0+1; application ID educonnect.com. Build-time overrides may differ. Actual installed version/build, APK checksum and release owner: TBC.'],
 ['TD-03 Server release','Backend release/commit, deployment date, database baseline and support contact: TBC.'],
 ['TD-04 Devices & network','At least two physical Android phones. Record models, OS versions, browser versions, Wi-Fi/mobile network and school time zone. iOS only if approved: device/build/APNs confirmation TBC.'],
 ['TD-05 Schools','Synthetic School A and School B with distinct IDs and school-admin accounts. Actual test references: TBC.'],
 ['TD-06 Classes & academic years','School A: two grades with identically named classes, another class and an empty class; current/noncurrent academic year. School B separate class. Actual IDs: TBC.'],
 ['TD-07 Subjects','Assigned Subject A, unassigned Subject B and an authorised all-subject/homeroom assignment if used. Actual subject IDs: TBC.'],
 ['TD-08 Role accounts','Platform owner (website_admin, web), School A/B admins (admin, web), assigned/unassigned teachers (mobile), linked/unlinked/multi-child parents (guardian, mobile), unsupported mobile role. Account aliases only: TBC; credentials stored separately.'],
 ['TD-09 Email/invitations','Approved test mailboxes; working SMTP; fresh, expired and consumed invitation/reset fixtures. Confirm delivery destination and invitation validity before execution.'],
 ['TD-10 OTP numbers','Approved existing teacher/guardian Econet 077/078 and NetOne 071 test recipients, local/+263 formats; unknown and unsupported fixtures. Authorised SMS cost/recipient list held separately. Never record OTPs.'],
 ['TD-11 Learners & guardians','Synthetic learners EC Learner A/B/C and linked parent aliases; multi-child family across classes/schools; guardian linked to two learners in same class; pending/rejected link-request fixtures. Actual IDs: TBC.'],
 ['TD-12 Import files','Current supported CSV template; valid synthetic rows; mixed invalid/missing/duplicate records; expected import counts and baseline roster count: TBC.'],
 ['TD-13 Student images','Distinct valid JPG/PNG under 4 MB; replacement image; oversized file; unsupported format; image exceeding 6,000-pixel dimension limit. No real child images required.'],
 ['TD-14 Medical fixtures','Fictitious allergies/conditions/medication/care notes, blank clearing values and generated 2,000/2,001-character text. No actual medical information.'],
 ['TD-15 Journal media','Approved synthetic photo/drawing at/below and over 8 MB; supported video/audio at/below and over 10 MB; unsupported media; safe HTTPS link; fictitious wellbeing values.'],
 ['TD-16 Reports','Synthetic valid PDF, invalid file, available protected report URL and isolated missing-file fixture. Never remove a real report to simulate failure.'],
 ['TD-17 Messaging pairs','Assigned teacher and two linked guardians on separate phones; unrelated guardian/teacher; duplicate-child guardian link; blank/2,000/2,001-character text; recent/long history fixtures.'],
 ['TD-18 Firebase project','Project educonnect-13f25; Android package educonnect.com. Support confirms backend credential and worker health without copying private keys/tokens into evidence. Actual phone delivery requires execution.'],
 ['TD-19 Notification states','Physical phones: permission allowed/denied, foreground/background, offline/reconnected, logged out and multi-account; device OS restrictions recorded. Force-stop/OS suppression is distinguished from ordinary background state.'],
 ['TD-20 SMS/SOS authorisation','Isolated test class and explicitly approved recipients, gateway test mode/limits and written authorisation for SMS costs/alarms: TBC. Do not send emergency test messages to real school distribution lists.'],
 ['TD-21 Fees','Synthetic USD and ZiG balances/transactions with ledger baseline; pending payment references; approved verification evidence and finance witness. No real funds without separate finance authorisation.'],
 ['TD-22 Uniforms','Own-school and other-school catalogue items; size-required SKU; known USD/ZiG price, limited stock, valid quantities and unavailable variant; disposable order references and stock baseline: TBC.'],
 ['TD-23 PesePay','Confirm sandbox, approved provider fixtures for success/failure/cancel/pending and callback testing; finance witness and stock/payment reconciliation baseline. No gateway secrets in workbook.'],
 ['TD-24 Subscriptions','Disposable children with active, suspended, future-start, expired and no-record states; per-child multi-child scenario; approved effective dates and restore owner: TBC.'],
 ['TD-25 Performance criteria','Business-approved maximum cold/warm load times per dashboard/roster/messages/journals/reports and phone notification delay: TBC before execution. Record data volume, network, device and server conditions.'],
 ['TD-26 Test window & owners','Start/end dates, EduConnect lead, school witnesses, technical support, finance approver, issue owners and final authorised signatory: TBC.'],
 ['TD-27 Evidence repository','Approved evidence folder/link, screenshot naming convention and restricted access owner: TBC. Use EC test ID + execution date in evidence names.'],
 ['TD-28 Restore & cleanup','Backup/synthetic-fixture reset plan, subscription restore values, catalogue stock/payment ledger baseline and approved cleanup owner: TBC.'],
 ['TD-29 Scope decisions','iOS in/out, no-subscription policy, register concurrency rule, supported language list, test SMS authorisation and any approved N/A cases: TBC with decision owner/date.']
];
const ds=rows2('Test Data','Confirm all prerequisites and replace TBC references before execution. Use synthetic data and account aliases.',['Item','Value / EduConnect confirmation'],data);ds.getRange(`B5:B${data.length+4}`).format.fill=C.input;
const end=cases.length+4;
const ts=base('Test Cases','N',[13,26,35,28,44,65,75,20,55,55,16,24,18,22],`${cases.length} manual scenarios | ${groups.length} processes | All results initially Not Run | Yellow cells are execution inputs`);
ts.mergeCells('A3:N3');ts.getRange('A3').values=[['Execute only in an approved environment. Link Fail/Blocked cases to Issues Log; enter evidence, tester and date. Retest is separate from current Status.']];ts.getRange('A3').format.rowHeight=26;
grid(ts,'N',end,['Test ID','Process','Test Case / Description','Executor / Witness','Preconditions / Test Data','Action / Steps','Expected Result','Status (EduConnect)','Actual Result (EduConnect)','Comment / Evidence / Variation Results','Issue ID','Tested By','Test Date','Retest Result (EduConnect)']);
const caseRows=cases.map((r,i)=>[`EC-${String(i+1).padStart(3,'0')}`,...r,'Not Run',null,null,null,null,null,null]);
assert(caseRows.every(r=>r.length===14));ts.getRange(`A5:N${end}`).values=caseRows;
ts.getRange(`H5:N${end}`).format.fill=C.input;ts.getRange(`M5:M${end}`).setNumberFormat('yyyy-mm-dd');
for(let i=0;i<cases.length;i++){
 const r=caseRows[i];const lines=Math.max(...[2,3,4,5,6].map(j=>Math.ceil(String(r[j]).length/([13,26,35,28,44,65,75][j]*.88))));
 ts.getRange(`A${i+5}`).format.rowHeight=Math.max(76,lines*16+16);
}
const statuses=['Pass','Fail','Blocked','Not Run','N/A'];
for(const col of ['H','N']){
 const rg=ts.getRange(`${col}5:${col}${end}`);rg.dataValidation={rule:{type:'list',values:statuses}};
 for(const [value,fill,color] of [['Pass','#D9EEDC','#145A32'],['Fail','#FADBD8','#922B21'],['Blocked','#FCE5BD','#7D4E00'],['Not Run','#EEF0F2','#4B5563'],['N/A','#E4E8F9','#373F75']])rg.conditionalFormats.add('cellIs',{operator:'equal',formula:`"${value}"`,format:{fill,font:{color,bold:true}}});
}
ts.tables.add(`A4:N${end}`,true,'EduConnectCases').showFilterButton=true;
const ss=base('Summary','J',[36,14,14,14,14,22,14,16,16,16],'Live counts from Test Cases | Recorded = Pass + Fail + Blocked + N/A | Retest columns are separate');
const totalRow=groups.length+5;grid(ss,'J',totalRow,['Process','Total','Pass','Fail','Blocked','Not Run / Blank','N/A','Recorded','Retest Pass','Retest Fail']);
const pr=`'Test Cases'!$B$5:$B$${end}`, st=`'Test Cases'!$H$5:$H$${end}`, rt=`'Test Cases'!$N$5:$N$${end}`;
groups.forEach((g,i)=>{
 const r=i+5;ss.getRange(`A${r}`).values=[[g.name]];
 ss.getRange(`B${r}:J${r}`).formulas=[[
 `=COUNTIFS(${pr},A${r})`,`=COUNTIFS(${pr},A${r},${st},"Pass")`,`=COUNTIFS(${pr},A${r},${st},"Fail")`,`=COUNTIFS(${pr},A${r},${st},"Blocked")`,
 `=B${r}-C${r}-D${r}-E${r}-G${r}`,`=COUNTIFS(${pr},A${r},${st},"N/A")`,`=C${r}+D${r}+E${r}+G${r}`,`=COUNTIFS(${pr},A${r},${rt},"Pass")`,`=COUNTIFS(${pr},A${r},${rt},"Fail")`]];
 ss.getRange(`A${r}`).format.rowHeight=38;
});
ss.getRange(`A${totalRow}`).values=[['TOTAL']];ss.getRange(`B${totalRow}:J${totalRow}`).formulas=[[...'BCDEFGHIJ'].map(c=>`=SUM(${c}5:${c}${totalRow-1})`)];
ss.getRange(`A${totalRow}:J${totalRow}`).format.fill=C.dark;ss.getRange(`A${totalRow}:J${totalRow}`).format.font={name:'Calibri',size:11,bold:true,color:C.white};ss.getRange(`A${totalRow}`).format.rowHeight=30;ss.getRange(`B5:J${totalRow}`).setNumberFormat('0');
const is=base('Issues Log','O',[16,16,22,18,65,50,60,18,24,22,18,55,26,20,55],'One row per issue | Use EC-ISS-001 style IDs | No issues have been pre-filled or assumed');
grid(is,'O',54,['Issue ID','EC Test ID','Raised By','Date Raised','Issue / Steps to Reproduce','Expected Result','Actual Result / Evidence','Priority','Assigned To','Status','Target Date','Resolution / Action','Retest By / Date','Retest Result','Client Comment / Closure Approval']);
is.getRange('A5:O54').format.fill=C.input;is.getRange('A5:O54').format.rowHeight=64;
for(const [rg,values] of [['H5:H54',['Critical','High','Medium','Low']],['J5:J54',['Open','In Progress','Ready for Retest','Closed','Deferred']],['N5:N54',['Pass','Fail','Blocked','Not Run']]])is.getRange(rg).dataValidation={rule:{type:'list',values}};
is.getRange('D5:D54').setNumberFormat('yyyy-mm-dd');is.getRange('K5:K54').setNumberFormat('yyyy-mm-dd');is.tables.add('A4:O54',true,'EduConnectIssues').showFilterButton=true;
const sign=rows2('Client Sign-off','Formal business acceptance | Pending until authorised completion and issue review',['Field','EduConnect Entry'],[
 ['Client / project','EduConnect school-parent communication and school management system'],
 ['Environment / release / build tested',null],['Testing period',null],['EduConnect test lead',null],
 ['Total / passed / failed / blocked / N/A reviewed',null],['Outstanding issues / risk and business policy approvals',null],
 ['Approved N/A cases / reason / approver',null],['Waivers / outstanding conditions / owner / deadline',null],
 ['Evidence and completed workbook reference',null],['Client acceptance decision','Pending'],['Decision conditions / comments',null],
 ['Authorised EduConnect representative',null],['Role / title',null],['Signature / written approval reference',null],['Date',null],
 ['Implementation / support representative acknowledgement',null],
 ['Acceptance statement','Only the authorised representative’s completed decision and written approval establish acceptance of the recorded release, subject to documented conditions. An unexecuted script or technical deployment does not establish acceptance.']
],55,110);
sign.getRange('B6:B20').format.fill=C.input;sign.getRange('B14').dataValidation={rule:{type:'list',values:['Pending','Accepted','Accepted with Conditions','Rejected']}};sign.getRange('B19').setNumberFormat('yyyy-mm-dd');

// Check the live status formula behaviour, then restore every execution cell.
ts.getRange('H5:H8').values=[['Pass'],['Fail'],['Blocked'],['N/A']];ts.getRange('N5:N6').values=[['Pass'],['Fail']];
wb.recalculate();
assert.deepEqual(ss.getRange('B5:J5').values[0],[groups[0].rows.length,1,1,1,groups[0].rows.length-4,1,4,1,1]);
ts.getRange('H5:H8').values=[['Not Run'],['Not Run'],['Not Run'],['Not Run']];ts.getRange('N5:N6').clear({applyTo:'contents'});
wb.recalculate();
assert.deepEqual(ss.getRange(`B${totalRow}:J${totalRow}`).values[0],[cases.length,0,0,0,cases.length,0,0,0,0]);
assert.equal(new Set(caseRows.map(r=>r[0])).size,cases.length);
assert(ts.getRange(`H5:H${end}`).values.every(r=>r[0]==='Not Run'));
assert(ts.getRange(`I5:N${end}`).values.every(r=>r.every(v=>v===null||v==='')));
const report={cases:cases.length,processes:groups.length,totalRow,summary:ss.getRange(`A${totalRow}:J${totalRow}`).values,modules:groups.map(g=>[g.name,g.rows.length])};
await fs.writeFile('output/uvt_work/verification.json',JSON.stringify(report,null,2));
console.log(JSON.stringify(report));
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:20},maxChars:2000})).ndjson);
await (await SpreadsheetFile.exportXlsx(wb)).save('output/EduConnect UVT Test Script.xlsx');
for(const [sheetName,range,file] of [
 ['Read Me','A1:B10','readme'],['Test Data','A1:B10','data'],['Test Cases','A4:G8','cases'],['Test Cases','H4:N8','results'],['Summary',`A1:J${totalRow}`,'summary'],['Issues Log','A4:H7','issues'],['Client Sign-off','A1:B21','signoff']
]){
 const image=await wb.render({sheetName,range,scale:1,format:'png'});await fs.writeFile(`output/uvt_work/${file}.png`,new Uint8Array(await image.arrayBuffer()));
}
