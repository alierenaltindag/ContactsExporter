import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContactsExporterApp());
}

class ContactsExporterApp extends StatelessWidget {
  const ContactsExporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contacts Exporter',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
