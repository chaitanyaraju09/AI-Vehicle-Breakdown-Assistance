import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/assistance_request_model.dart';
import '../../providers/assistance_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class MechanicDashboard extends StatefulWidget {
  const MechanicDashboard({super.key});

  @override
  State<MechanicDashboard> createState() =>
      _MechanicDashboardState();
}

class _MechanicDashboardState extends State<MechanicDashboard> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AssistanceProvider>().loadRequests();
    });
  }

  Future<void> _refreshRequests() async {
    if (!mounted) return;

    await context.read<AssistanceProvider>().loadRequests();
  }

  Future<void> _acceptRequest(
    AssistanceProvider provider,
    int requestId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.acceptRequest(requestId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Assistance request accepted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await provider.loadRequests();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Failed to accept assistance request.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startRequest(
    AssistanceProvider provider,
    int requestId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.startRequest(requestId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Assistance started successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await provider.loadRequests();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Failed to start assistance.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeRequest(
    AssistanceProvider provider,
    int requestId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final success =
        await provider.completeRequest(requestId);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Assistance completed successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await provider.loadRequests();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Failed to complete assistance.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldLogout != true) return;

    // Read the provider BEFORE the async logout operation.
    final authProvider = context.read<AuthProvider>();

    await authProvider.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Color _statusColor(
    BuildContext context,
    String status,
  ) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;

      case 'ACCEPTED':
        return Colors.blue;

      case 'IN_PROGRESS':
        return Colors.green;

      case 'COMPLETED':
        return Colors.grey;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'battery':
        return Icons.battery_alert_rounded;

      case 'tyre':
      case 'tire':
        return Icons.tire_repair_rounded;

      case 'engine':
        return Icons.settings_rounded;

      case 'electrical':
        return Icons.electrical_services_rounded;

      case 'fuel':
        return Icons.local_gas_station_rounded;

      case 'brake':
        return Icons.car_repair_rounded;

      case 'cooling':
        return Icons.thermostat_rounded;

      case 'ac':
        return Icons.ac_unit_rounded;

      case 'towing':
        return Icons.local_shipping_rounded;

      case 'accident':
        return Icons.warning_rounded;

      default:
        return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<AssistanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mechanic Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh requests',
            onPressed: provider.isLoading
                ? null
                : _refreshRequests,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: provider.isLoading
                ? null
                : _logout,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child: _buildBody(
          context,
          provider,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AssistanceProvider provider,
  ) {
    if (provider.isLoading &&
        provider.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null &&
        provider.requests.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color:
                Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 20),
          Text(
            'Unable to load requests',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _refreshRequests,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    if (provider.requests.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 54,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No Assistance Requests',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'New roadside assistance requests '
            'will appear here.',
            textAlign: TextAlign.center,
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
          OutlinedButton.icon(
            onPressed: _refreshRequests,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Refresh',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Assistance Requests',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '${provider.requests.length} request'
          '${provider.requests.length == 1 ? '' : 's'}',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        ...provider.requests.map(
          (request) => Padding(
            padding:
                const EdgeInsets.only(bottom: 16),
            child: _RequestCard(
              request: request,
              statusColor: _statusColor(
                context,
                request.status,
              ),
              categoryIcon: _categoryIcon(
                request.category,
              ),
              isLoading: provider.isLoading,
              onAccept: () {
                _acceptRequest(
                  provider,
                  request.id,
                );
              },
              onStart: () {
                _startRequest(
                  provider,
                  request.id,
                );
              },
              onComplete: () {
                _completeRequest(
                  provider,
                  request.id,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AssistanceRequestModel request;
  final Color statusColor;
  final IconData categoryIcon;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _RequestCard({
    required this.request,
    required this.statusColor,
    required this.categoryIcon,
    required this.isLoading,
    required this.onAccept,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      statusColor.withValues(
                    alpha: 0.10,
                  ),
                  child: Icon(
                    categoryIcon,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request #${request.id}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.category,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),

            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Driver',
              value: request.driverName,
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: request.phoneNumber,
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon:
                  Icons.directions_car_outlined,
              label: 'Vehicle',
              value: request.vehicleInfo,
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.car_repair_outlined,
              label: 'Vehicle Type',
              value: request.vehicleType,
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.issueDescription,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w600,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _InfoRow(
              icon:
                  Icons.location_on_outlined,
              label: 'Location',
              value:
                  '${request.latitude.toStringAsFixed(5)}, '
                  '${request.longitude.toStringAsFixed(5)}',
            ),

            const SizedBox(height: 20),

            if (request.status.toUpperCase() ==
                'PENDING')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isLoading ? null : onAccept,
                  icon: const Icon(
                    Icons.check_circle_outline,
                  ),
                  label: const Text(
                    'Accept Request',
                  ),
                ),
              ),

            if (request.status.toUpperCase() ==
                'ACCEPTED')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isLoading ? null : onStart,
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                  ),
                  label: const Text(
                    'Start Assistance',
                  ),
                ),
              ),

            if (request.status.toUpperCase() ==
                'IN_PROGRESS')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      isLoading ? null : onComplete,
                  icon: const Icon(
                    Icons.task_alt_rounded,
                  ),
                  label: const Text(
                    'Complete Assistance',
                  ),
                ),
              ),

            if (request.status.toUpperCase() ==
                'COMPLETED')
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Assistance Completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}