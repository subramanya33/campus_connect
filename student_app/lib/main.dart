import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password.dart';
import 'screens/profile_screen.dart';
import 'screens/questionbanks_screen.dart';
import 'screens/resume_builder_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Connect',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/question-banks': (context) => const QuestionBanksScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return ResetPasswordScreen(
            usn: args?['usn'] as String? ?? '',
            isFirstLogin: args?['isFirstLogin'] as bool? ?? false,
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/resume_builder') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<Map<String, dynamic>>(
                future: AuthService().checkSession(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final usn = args?['usn'] as String? ?? snapshot.data?['usn'] as String? ?? '4MT21AI058';
                  return ResumeBuilderScreen(usn: usn);
                },
              );
            },
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        print('DEBUG: Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Route Not Found')),
            body: Center(
              child: Text('Error: Route "${settings.name}" not found'),
            ),
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AuthService().checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Campus Connect', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final sessionData = snapshot.data ?? {'isLoggedIn': false};
        final isLoggedIn = sessionData['isLoggedIn'] as bool;
        final firstLogin = sessionData['firstLogin'] as bool?;
        final usn = sessionData['usn'] as String?;

        debugPrint('DEBUG: SplashScreen - isLoggedIn: $isLoggedIn, firstLogin: $firstLogin, usn: $usn');

        if (isLoggedIn) {
          if (firstLogin == true && usn != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(
                context,
                '/reset-password',
                arguments: {'usn': usn, 'isFirstLogin': true},
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}