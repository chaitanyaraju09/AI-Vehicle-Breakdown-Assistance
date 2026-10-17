
import 'package:flutter/material.dart';

import 'core/theme/mechanic_theme.dart';
import 'screens/auth/mechanic_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MechanicApp());
}

class MechanicApp extends StatelessWidget {
  const MechanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VehicleAssist Mechanic',
      debugShowCheckedModeBanner: false,
      theme: MechanicTheme.darkTheme,
      home: const MechanicLoginScreen(),
    );
  }
}
