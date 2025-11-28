import 'dart:developer' as developer;

import 'package:examen_civique/app_time_tracker.dart';
import 'package:examen_civique/data/app_db.dart';
import 'package:examen_civique/pages/home_page.dart';
import 'package:examen_civique/design/style/app_colors.dart';
import 'package:examen_civique/utils/utils.dart';
import 'package:examen_civique/widgets/screen_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
      navigatorObservers: [routeObserver],
      home: const InitScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitScreen extends StatelessWidget {
  const InitScreen({super.key});

  Future<void> _initApp() async {
    try {
      // Initialize the database
      await Future.wait([
        AppDb().database,
        Future.delayed(const Duration(milliseconds: 500)),
      ]);
    } catch (e) {
      developer.log('Error initializing app: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: retryForever(() => _initApp()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MarianneWaitingScreen();
        }

        // Initialize the time tracker
        AppTimeTracker.instance.init();

        return const HomeScreen();
      },
    );
  }
}
