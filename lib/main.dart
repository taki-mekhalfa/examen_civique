import 'dart:developer' as developer;

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/widgets/wait_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Examen Civique',
      locale: const Locale('fr', 'FR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBlue,
          secondary: AppColors.primaryBlue,
        ),
        hoverColor: AppColors.neutral200,
        highlightColor: AppColors.neutral200,
        focusColor: AppColors.neutral200,
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
        ),
      ),
      home: const InitScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitScreen extends StatelessWidget {
  const InitScreen({super.key});

  Future<void> _initApp() async {
    try {
      await Future.wait([
        AppDb().database,
        Future.delayed(const Duration(seconds: 1)),
      ]);
    } catch (e) {
      developer.log('Error initializing app: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureGate<void>(
      future: _initApp(),
      builder: (_, __) => const HomeScreen(),
      errorBuilder: (ctx, error, retry) => WaitScreen(
        message: "Erreur d'initialisation :(\nAppuyez pour réessayer.",
        bottom: ElevatedButton(
          onPressed: retry,
          child: const Text('Réessayer'),
        ),
      ),
    );
  }
}
