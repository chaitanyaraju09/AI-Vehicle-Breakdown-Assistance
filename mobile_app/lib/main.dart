import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/assistance_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AssistanceProvider(),
        ),
      ],
      child: const VehicleAssistanceApp(),
    ),
  );
}

class VehicleAssistanceApp extends StatelessWidget {
  const VehicleAssistanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Assistance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}