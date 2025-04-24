import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String> _getInitialRoute() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    print('DEBUG: Initial route check - isLoggedIn: $isLoggedIn');
    return isLoggedIn ? '/home' : '/login';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/login', // Fallback, overridden by homeBuilder
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/resume_builder': (context) => const Placeholder(),
        '/question_banks': (context) => const Placeholder(),
        '/livestream': (context) => const Placeholder(),
        '/notifications': (context) => const Placeholder(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/reset_password') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              usn: args?['usn'] ?? '',
              isFirstLogin: args?['isFirstLogin'] ?? false,
            ),
          );
        }
        return null;
      },
      home: FutureBuilder<String>(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final initialRoute = snapshot.data ?? '/login';
          print('DEBUG: Setting initial route to $initialRoute');
          return Navigator(
            onGenerateRoute: (settings) {
              if (settings.name == initialRoute) {
                return MaterialPageRoute(
                  builder: (context) => initialRoute == '/home' ? const HomeScreen() : const LoginScreen(),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}