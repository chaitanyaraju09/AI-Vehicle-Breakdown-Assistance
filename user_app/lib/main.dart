
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/assistance_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/driver/ai_diagnosis_screen.dart';
import 'screens/driver/mechanic_match_screen.dart';
import 'screens/driver/request_tracking_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<AssistanceProvider>(
          create: (_) => AssistanceProvider(),
        ),
      ],
      child: const VehicleUserApp(),
    ),
  );
}

class VehicleUserApp extends StatelessWidget {
  const VehicleUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VehicleAssist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routes: {
        // Do not add '/' here because home defines the initial screen.
        '/login': (_) => const LoginScreen(),
        '/premium': (_) => const PremiumHomeScreen(),
      },
      home: const LoginScreen(),
    );
  }
}

class PremiumHomeScreen extends StatelessWidget {
  const PremiumHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VehicleAssist'),
        actions: [
          IconButton(
            tooltip: 'Reload Home',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Home screen refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1220),
              Color(0xFF070B14),
              Color(0xFF05070D),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 28),
                _buildWelcome(theme),
                const SizedBox(height: 22),
                _buildAiCard(context, theme),
                const SizedBox(height: 18),
                _buildQuickActions(context, theme),
                const SizedBox(height: 22),
                _buildEmergencyCard(context, theme),
                const SizedBox(height: 24),
                _buildSectionTitle('Your vehicle', 'Manage'),
                const SizedBox(height: 12),
                _buildVehicleCard(theme),
                const SizedBox(height: 24),
                _buildSectionTitle('Recent activity', 'View all'),
                const SizedBox(height: 12),
                _buildActivityCard(theme),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AiDiagnosisScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RequestTrackingScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DriverProfileScreen(),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4F8CFF),
                Color(0xFF35D6FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8CFF).withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VehicleAssist',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Smart roadside assistance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF718198),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF101927),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF22344F),
            ),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good evening,',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFA9B7CA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can we help you?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildAiCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18335F),
            Color(0xFF10213B),
            Color(0xFF0D1727),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF31598E),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F8CFF).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8CFF).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF70A7FF),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Vehicle Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Describe what is happening with your vehicle and get intelligent guidance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFA9B7CA),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiDiagnosisScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Talk to AI Assistant'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.location_searching_rounded,
            title: 'Find Help',
            subtitle: 'Nearby mechanics',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MechanicMatchScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.settings_input_component_rounded,
            title: 'OBD Scan',
            subtitle: 'Check vehicle',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF101927),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFF22344F),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F8CFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF70A7FF),
                  size: 22,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF4F7FC),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF718198),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF28141B),
        border: Border.all(
          color: const Color(0xFF5A2834),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5C70).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: Color(0xFFFF6E7F),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency assistance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Need immediate roadside help?',
                  style: TextStyle(
                    color: Color(0xFFA9B7CA),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MechanicMatchScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFFF6E7F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF4F7FC),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: Color(0xFF70A7FF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101927),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF22344F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF18263A),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              size: 30,
              color: Color(0xFF70A7FF),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Vehicle',
                  style: TextStyle(
                    color: Color(0xFFF4F7FC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Add your vehicle details',
                  style: TextStyle(
                    color: Color(0xFF718198),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF718198),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101927),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF22344F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF35D39A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF35D39A),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent assistance',
                  style: TextStyle(
                    color: Color(0xFFF4F7FC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your assistance requests will appear here.',
                  style: TextStyle(
                    color: Color(0xFF718198),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Basic driver profile screen. This intentionally does not log the user out
/// or redirect to the login screen.
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(
          child: Text('Please sign in to view your profile.'),
        ),
      );
    }

    Widget detailRow(IconData icon, String label, String value) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label, style: theme.textTheme.bodySmall),
        subtitle: Text(value, style: theme.textTheme.titleMedium),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 44,
              child: Icon(Icons.person, size: 48),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                detailRow(Icons.badge_outlined, 'Driver ID', user.id.toString()),
                const Divider(height: 1),
                detailRow(Icons.person_outline, 'Full Name', user.fullName),
                const Divider(height: 1),
                detailRow(Icons.email_outlined, 'Email', user.email),
                const Divider(height: 1),
                detailRow(Icons.manage_accounts_outlined, 'Role', user.role),
                const Divider(height: 1),
                detailRow(
                  Icons.verified_user_outlined,
                  'Account Status',
                  user.isActive ? 'Active' : 'Inactive',
                ),
                const Divider(height: 1),
                detailRow(
                  Icons.calendar_today_outlined,
                  'Registered On',
                  '${user.createdAt.day.toString().padLeft(2, '0')}/'
                  '${user.createdAt.month.toString().padLeft(2, '0')}/'
                  '${user.createdAt.year}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text(
                      'Are you sure you want to sign out of your driver account?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldSignOut != true || !context.mounted) return;

                try {
                  await context.read<AuthProvider>().logout();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign out failed: $e')),
                    );
                  }
                  return;
                }

                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
