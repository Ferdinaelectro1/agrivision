// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/firebase_auth_service.dart';
//import 'features/auth/services/fake_auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/dashboard/screens/home_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'features/splash/screens/splash_screen.dart'; 
import 'firebase_options.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final authService = FirebaseAuthServiceImpl();
    await authService.initGoogle();
    runApp(MyApp(authService: authService));
  } catch (e) {
    FlutterNativeSplash.remove();
    rethrow;
  }
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
      // Le splash s'affiche d'abord, puis bascule vers le StreamBuilder
      home: SplashScreen(
        next: StreamBuilder<AppUser?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return HomeScreen(authService: authService);
            }
            return LoginScreen(authService: authService);
          },
        ),
      ),
    );
  }
}