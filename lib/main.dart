import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr_FR';

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
      supportedLocales: const [Locale('en', 'US'), Locale('fr', 'FR')],
      home: const Scaffold(body: Center(child: Text('Bonjour!'))),
      debugShowCheckedModeBanner: false,
    );
  }
}
