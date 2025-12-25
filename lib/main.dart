import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/features/pages/splashscreen.dart';
import 'package:lindashopp/core/firebase/firebase_options.dart';
import 'package:lindashopp/features/pages/utils/notifucation_service.dart';
import 'package:lindashopp/theme/apptheme.dart';
import 'package:lindashopp/theme/themecontroller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadTheme();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: SplashScreen(),
        );
      },
    );
  }
}
