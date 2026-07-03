import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../login/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('App settings will be available here soon.'),
              const SizedBox(height: 16),
              const ListTile(
                title: Text('Profile'),
                subtitle: Text('Manage user profile and security'),
                enabled: false,
              ),
              const ListTile(
                title: Text('Notifications'),
                subtitle: Text('Manage push and system alerts'),
                enabled: false,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  AuthService.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF263238),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
