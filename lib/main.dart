// lib/main.dart
import 'package:flutter/material.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/fake_auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(MyApp(authService: FakeAuthService())); // <- on remplacera par FirebaseAuthServiceImpl() plus tard
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriVision',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      routes: {
        '/register': (context) => RegisterScreen(authService: authService),
      },
      home: StreamBuilder<AppUser?>(
        stream: authService.authStateChanges,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen(authService: authService);
          }
          return LoginScreen(authService: authService);
        },
      ),
    );
  }
}