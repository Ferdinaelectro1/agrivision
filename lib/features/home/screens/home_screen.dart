// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService authService;
  const HomeScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriVision"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text("Bienvenue sur AgriVision 🌱"),
      ),
    );
  }
}