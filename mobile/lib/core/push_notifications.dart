import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../main.dart' show navigatorKey;
import '../features/dashboard/announcements_view.dart';
import '../features/parent/learning_journal_view.dart';
import '../features/parent/messaging_view.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';
import 'student_provider.dart';

class PushNotifications {
  static bool enabled = false;
  static final local = FlutterLocalNotificationsPlugin();
  static void Function(String)? onTap;
  static String? pending;

  static Future<void> initialize() async {
    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    try {
      await Firebase.initializeApp(
        options: project.isEmpty
            ? null
            : const FirebaseOptions(
                apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
                appId: String.fromEnvironment('FIREBASE_APP_ID'),
                messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
                projectId: project,
                iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
              ),
      );
      await local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) open(response.payload!);
        },
      );
      await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'school_updates',
              'School updates',
              description: 'New notices, journal entries and messages',
              importance: Importance.high,
            ),
          );
      final launch = await local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        pending = launch?.notificationResponse?.payload;
      }
      // Foreground alerts use the same local presentation on both platforms.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      enabled = true;
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  static void open(String payload) {
    pending = payload;
    onTap?.call(payload);
  }

  static Future<void> detach(AuthProvider auth) async {
    if (!enabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await auth.apiClient.dio
            .delete('/mobile-notifications/device', data: {'token': token})
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    try {
      await local.cancelAll();
    } catch (_) {}
    pending = null;
  }
}

/// Owns FCM subscriptions once per app, including notification launch handling.
class PushNotificationListener extends StatefulWidget {
  final Widget child;
  const PushNotificationListener({super.key, required this.child});
  @override
  State<PushNotificationListener> createState() =>
      _PushNotificationListenerState();
}

class _PushNotificationListenerState extends State<PushNotificationListener>
    with WidgetsBindingObserver {
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<RemoteMessage>? _opens;
  StreamSubscription<String>? _tokens;
  String? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotifications.onTap = _open;
    if (!PushNotifications.enabled) return;
    _messages = FirebaseMessaging.onMessage.listen((message) async {
      if (!mounted || !context.read<AuthProvider>().isAuthenticated) return;
      await context.read<NotificationProvider>().refresh();
      final notice = message.notification;
      if (notice == null) return;
      await PushNotifications.local.show(
        id:
            (int.tryParse('${message.data['item_id']}') ?? 0) * 3 +
            (message.data['category'] == 'notices'
                ? 0
                : message.data['category'] == 'journal'
                ? 1
                : 2),
        title: notice.title,
        body: notice.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'school_updates',
            'School updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });
    _opens = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => PushNotifications.open(jsonEncode(message.data)),
    );
    _tokens = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _register(token),
    );
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
          if (message != null) PushNotifications.open(jsonEncode(message.data));
        })
        .catchError((Object _) {});
  }

  Future<void> _register(String token) async {
    if (!mounted || !context.read<AuthProvider>().isAuthenticated) return;
    try {
      await context.read<AuthProvider>().apiClient.dio.post(
        '/mobile-notifications/device',
        data: {'token': token},
      );
    } catch (_) {}
  }

  Future<void> _connect() async {
    if (!PushNotifications.enabled) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final session = _session;
      final token = await FirebaseMessaging.instance.getToken();
      if (mounted && session == _session && token != null) {
        await _register(token);
      }
    } catch (_) {}
  }

  void _open(String payload) {
    if (!mounted ||
        !context.read<AuthProvider>().isAuthenticated ||
        navigatorKey.currentState == null) {
      return;
    }
    try {
      final data = jsonDecode(payload) as Map;
      final Widget page;
      switch (data['category']) {
        case 'notices':
          page = const AnnouncementsView();
        case 'journal':
          page = LearningJournalView(
            child: context.read<AuthProvider>().isTeacher
                ? null
                : int.tryParse('${data['student_id']}') != null
                ? {'id': int.parse('${data['student_id']}')}
                : context.read<StudentProvider>().selectedStudent,
          );
        case 'messages':
          page = const MessagingView();
        default:
          return;
      }
      PushNotifications.pending = null;
      navigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => page));
      context.read<NotificationProvider>().refresh();
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (_session == auth.token) return;
    _session = auth.token;
    if (_session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _connect();
        if (PushNotifications.pending != null) {
          _open(PushNotifications.pending!);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null) _connect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messages?.cancel();
    _opens?.cancel();
    _tokens?.cancel();
    PushNotifications.onTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
