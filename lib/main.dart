import 'screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
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
  late final AppLinks appLinks;

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    appLinks = AppLinks();

    appLinks.uriLinkStream.listen((Uri uri) {
      handleDeepLink(uri);
    });
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

      if (uri.scheme == 'mgmops' && uri.host == 'login') {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
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
          seedColor: const Color(0xff1583ff),
          brightness: Brightness.light,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}