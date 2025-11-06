import 'dart:developer' as developer;

import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/design/style/app_text_styles.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/design/style/app_colors.dart';
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
      home: const LoadScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key});

  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/marianne/marianne_waiting.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 50,
              height: 50,
              child: const CircularProgressIndicator(
                color: AppColors.primaryGrey,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Initialisation en cours...',
              style: AppTextStyles.regular18,
            ),
          ],
        ),
      ),
    );
  }

  void _initApp() async {
    try {
      await Future.wait([
        AppDb().database,
        Future.delayed(const Duration(seconds: 1)),
      ]);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      developer.log('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur d\'initialisation :(')));
      }
    }
  }
}
