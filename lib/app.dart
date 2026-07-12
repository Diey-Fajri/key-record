import 'package:flutter/material.dart';

import 'screen/home/home_screen.dart';
import 'screen/login/login_screen.dart';
import 'screen/notifications/notifications_screen.dart';
import 'services/app_notification_service.dart';
import 'services/auth_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Key Record',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF263238)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      routes: {
        '/notifications': (_) => const NotificationsScreen(),
      },
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    if (AuthService.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
