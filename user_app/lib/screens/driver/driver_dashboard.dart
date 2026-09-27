import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/location_service.dart';
import '../../providers/auth_provider.dart';
import 'ai_diagnosis_screen.dart';
import 'mechanic_match_screen.dart';
import 'request_tracking_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isGettingLocation = false;

  Future<void> _getMyLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await LocationService().getCurrentLocation();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on_rounded),
                SizedBox(width: 10),
                Text('My Location'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current GPS coordinates:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Latitude: ${position.latitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Longitude: ${position.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 12),
                Text(
                  'Accuracy: ${position.accuracy.toStringAsFixed(1)} meters',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final firstName =
        user?.fullName.split(' ').first ?? 'Driver';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Assistance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(
              const Duration(milliseconds: 500),
            );
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // =========================
              // WELCOME HEADER
              // =========================

              Text(
                'Hello, $firstName 👋',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'What do you need help with today?',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 24),

              // =========================
              // EMERGENCY ASSISTANCE CARD
              // =========================

              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Theme.of(context)
                                    .colorScheme
                                    .primary,
                            child: Icon(
                              Icons.car_repair_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Need roadside assistance?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Share your vehicle problem and location to find suitable nearby assistance.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MechanicMatchScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.location_on_rounded,
                          ),
                          label: const Text(
                            'Find Assistance',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // QUICK ACTIONS
              // =========================

              Text(
                'Quick Services',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  _ServiceCard(
                    icon: Icons.smart_toy_rounded,
                    title: 'AI Diagnosis',
                    subtitle: 'Analyze vehicle symptoms',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const AiDiagnosisScreen(),
                        ),
                      );
                    },
                  ),

                  _ServiceCard(
                    icon: Icons.location_searching_rounded,
                    title: 'Find Mechanic',
                    subtitle: 'Locate nearby assistance',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const MechanicMatchScreen(),
                        ),
                      );
                    },
                  ),

                  _ServiceCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Track Request',
                    subtitle: 'View assistance status',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const RequestTrackingScreen(),
                        ),
                      );
                    },
                  ),

                  _ServiceCard(
                    icon: Icons.location_on_outlined,
                    title: 'My Location',
                    subtitle: _isGettingLocation
                        ? 'Getting GPS location...'
                        : 'Get current GPS location',
                    onTap: _getMyLocation,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================
              // ACCOUNT INFORMATION
              // =========================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        child: Text(
                          firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Driver',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.verified_user_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),

              const Spacer(),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}