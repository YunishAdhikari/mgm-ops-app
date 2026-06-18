import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/landing_page.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MgmOpsApp());
}

class MgmOpsApp extends StatefulWidget {
  const MgmOpsApp({super.key});

  @override
  State<MgmOpsApp> createState() => _MgmOpsAppState();
}

class _MgmOpsAppState extends State<MgmOpsApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppLinks? appLinks;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initDeepLinks();
      initFirebaseMessaging();
    });
  }

  Future<void> initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('Permission status: ${settings.authorizationStatus}');

      final token = await messaging.getToken();

      debugPrint('============== FCM TOKEN ==============');
      if (token != null) {
        for (int i = 0; i < token.length; i += 50) {
          debugPrint(
            token.substring(
              i,
              i + 50 > token.length ? token.length : i + 50,
            ),
          );
        }
      } else {
        debugPrint('FCM token is null');
      }
      debugPrint('=======================================');

      await messaging.subscribeToTopic('test');
      debugPrint('Subscribed to topic: test');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground notification received');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
        debugPrint('Data: ${message.data}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked');
        debugPrint('Data: ${message.data}');
      });
    } catch (e) {
      debugPrint('Firebase messaging error: $e');
    }
  }

  Future<void> initDeepLinks() async {
    try {
      appLinks = AppLinks();

      appLinks!.uriLinkStream.listen((Uri uri) {
        handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint('Deep link error: $e');
    }
  }

  void handleDeepLink(Uri uri) {
    if (uri.scheme == 'mgmops' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token != null && email != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              token: token,
              email: email,
            ),
          ),
        );
      }
    }

    if (uri.scheme == 'mgmops' && uri.host == 'login') {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MGM Ops',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffdc2626),
          brightness: Brightness.light,
        ),
      ),
      home: const LandingPage(),
    );
  }
}