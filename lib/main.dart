import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lindashopp/Elements/achatrecentprovider.dart';
import 'package:lindashopp/Elements/favoriteProdvider.dart';
import 'package:lindashopp/Elements/panierprovider.dart';
import 'package:lindashopp/Elements/splashscreen.dart';
import 'package:lindashopp/firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => PanierProvider()),
      ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ChangeNotifierProvider(create: (_) => AcrProvider()),
    ], child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: SplashScreen(),
    );
  }
}
