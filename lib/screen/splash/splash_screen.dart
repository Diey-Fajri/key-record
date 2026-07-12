import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../firebase_options.dart';
import '../../services/app_notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/key_repository.dart';
import '../../services/notification_service.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  String _versionLabel = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();
    _prepareApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _prepareApp() async {
    try {
      await _loadVersionInfo();
      await _initializeFirebase();
      await _initializeNotificationService();
      await _initializeAuth();
      await _loadInitialData();
      await _navigateToNextScreen();
    } catch (error) {
      debugPrint('SplashScreen initialization error: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to start the app right now.';
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _navigateToNextScreen();
    }
  }

  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _initializeNotificationService() async {
    await NotificationService.initialize(navigatorKey: appNavigatorKey);
    await NotificationService.handleInitialMessage();
  }

  Future<void> _initializeAuth() async {
    await AuthService.initialize();
  }

  Future<void> _loadInitialData() async {
    if (AuthService.isAuthenticated) {
      await KeyRecordRepository.watchAllKeys().first;
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;
    final nextPage = AuthService.isAuthenticated
        ? const HomeScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer.withAlpha(245),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(31),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/icon.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'KeyRecord',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure key tracking for your team',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withAlpha(217),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                if (_isLoading)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      CircularProgressIndicator(
                        color: colorScheme.onPrimaryContainer,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _versionLabel.isEmpty
                            ? 'Loading app...' : 'Version $_versionLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withAlpha(204),
                        ),
                      ),
                    ],
                  )
                else ...[
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
