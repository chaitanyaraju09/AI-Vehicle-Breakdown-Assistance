import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/assistance_request_model.dart';
import '../../providers/assistance_provider.dart';

class RequestTrackingScreen extends StatefulWidget {
  const RequestTrackingScreen({super.key});

  @override
  State<RequestTrackingScreen> createState() =>
      _RequestTrackingScreenState();
}

class _RequestTrackingScreenState
    extends State<RequestTrackingScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssistanceProvider>().loadRequests();
    });

    // Automatically refresh request status every 10 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted) {
          context.read<AssistanceProvider>().loadRequests();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<AssistanceProvider>().loadRequests();
  }

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return scheme.primary;
      case 'IN_PROGRESS':
        return scheme.tertiary;
      case 'ACCEPTED':
        return scheme.secondary;
      case 'PENDING':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle_rounded;
      case 'IN_PROGRESS':
        return Icons.build_circle_rounded;
      case 'ACCEPTED':
        return Icons.handyman_rounded;
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _statusDescription(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Waiting for a mechanic to accept your request.';
      case 'ACCEPTED':
        return 'A mechanic has accepted your assistance request.';
      case 'IN_PROGRESS':
        return 'Your assistance is currently in progress.';
      case 'COMPLETED':
        return 'Your assistance request has been completed.';
      default:
        return 'Request status updated.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(context, provider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AssistanceProvider provider,
  ) {
    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null &&
        provider.requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_rounded,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load requests',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _refresh,
            child: const Text('Try Again'),
          ),
        ],
      );
    }

    if (provider.requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          Icon(
            Icons.assignment_outlined,
            size: 70,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 8),
          Text(
            'Your roadside assistance requests will appear here.',
            textAlign: TextAlign.center,
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
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Assistance History',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '${provider.requests.length} request${provider.requests.length == 1 ? '' : 's'}',
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
            padding: const EdgeInsets.only(bottom: 14),
            child: _RequestCard(request: request),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AssistanceRequestModel request;

  const _RequestCard({
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final parent =
        context.findAncestorStateOfType<
            _RequestTrackingScreenState>();

    final statusColor =
        parent?._statusColor(context, request.status) ??
            Theme.of(context).colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: () {
          _showRequestDetails(context, request);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =========================
              // TOP ROW
              // =========================

              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    child: Icon(
                      Icons.car_repair_rounded,
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
                          request.vehicleInfo,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(
                    status: request.status,
                    color: statusColor,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =========================
              // STATUS MESSAGE
              // =========================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(14),
                  color: statusColor.withValues(
                    alpha: 0.08,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      parent?._statusIcon(request.status) ??
                          Icons.info_outline_rounded,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        parent?._statusDescription(
                              request.status,
                            ) ??
                            'Request status updated.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // REQUEST INFO
              // =========================

              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: request.category,
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle',
                      value: request.vehicleType,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _InfoItem(
                icon: Icons.warning_amber_outlined,
                label: 'Problem',
                value: request.issueDescription,
              ),

              const SizedBox(height: 14),

              _InfoItem(
                icon: Icons.access_time_rounded,
                label: 'Created',
                value: _formatDate(request.createdAt),
              ),

              if (request.mechanicId != null) ...[
                const SizedBox(height: 14),
                _InfoItem(
                  icon: Icons.handyman_outlined,
                  label: 'Mechanic ID',
                  value: '#${request.mechanicId}',
                ),
              ],

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    _showRequestDetails(
                      context,
                      request,
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  label: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(
    BuildContext context,
    AssistanceRequestModel request,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Request #${request.id}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  label: 'Status',
                  value: request.status,
                ),
                _DetailRow(
                  label: 'Driver',
                  value: request.driverName,
                ),
                _DetailRow(
                  label: 'Phone',
                  value: request.phoneNumber,
                ),
                _DetailRow(
                  label: 'Vehicle',
                  value: request.vehicleInfo,
                ),
                _DetailRow(
                  label: 'Vehicle Type',
                  value: request.vehicleType,
                ),
                _DetailRow(
                  label: 'Category',
                  value: request.category,
                ),
                _DetailRow(
                  label: 'Problem',
                  value: request.issueDescription,
                ),
                _DetailRow(
                  label: 'Location',
                  value:
                      '${request.latitude.toStringAsFixed(5)}, '
                      '${request.longitude.toStringAsFixed(5)}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
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
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}