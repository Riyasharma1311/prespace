import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/register_screen.dart';
import 'main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PhotosApp());
}

class PhotosApp extends StatelessWidget {
  const PhotosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/splash',
      routes: {
        '/splash':     (_) => const SplashScreen(),
        '/subscribe':  (_) => const SubscriptionScreen(),
        '/register':   (_) => const RegisterScreen(),
        '/home':       (_) => const MainShell(),
      },
    );
  }
}
