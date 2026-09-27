import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/location_service.dart';
import '../../providers/assistance_provider.dart';

class MechanicMatchScreen extends StatefulWidget {
  const MechanicMatchScreen({super.key});

  @override
  State<MechanicMatchScreen> createState() =>
      _MechanicMatchScreenState();
}

class _MechanicMatchScreenState
    extends State<MechanicMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleInfoController = TextEditingController();
  final _issueController = TextEditingController();

  String _vehicleType = 'Car';
  String _category = 'General Repair';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleInfoController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _findMechanics() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final provider = context.read<AssistanceProvider>();

    try {
      final position =
          await LocationService().getCurrentLocation();

      final latitude = position.latitude;
      final longitude = position.longitude;

      provider.setLocation(
        latitude: latitude,
        longitude: longitude,
      );

      await provider.matchMechanics(
        driverName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        vehicleInfo: _vehicleInfoController.text.trim(),
        category: _category,
        issueDescription: _issueController.text.trim(),
        latitude: latitude,
        longitude: longitude,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssistanceProvider>();
    final result = provider.matchResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Assistance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // =========================
            // HEADER
            // =========================

            Card(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                      child: Icon(
                        Icons.handyman_rounded,
                        size: 30,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find a Nearby Mechanic',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'We will match your vehicle problem with available assistance.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // =========================
            // DRIVER & VEHICLE FORM
            // =========================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Driver Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        enabled: !provider.isLoading,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Driver name',
                          hintText: 'Enter your name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        enabled: !provider.isLoading,
                        keyboardType:
                            TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText:
                              'Enter your phone number',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }

                          if (value.trim().length < 10) {
                            return 'Please enter a valid phone number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Vehicle Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _vehicleType,
                        decoration:
                            const InputDecoration(
                          labelText: 'Vehicle type',
                          prefixIcon: Icon(
                            Icons.directions_car_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Car',
                            child: Text('Car'),
                          ),
                          DropdownMenuItem(
                            value: 'SUV',
                            child: Text('SUV'),
                          ),
                          DropdownMenuItem(
                            value: 'Van',
                            child: Text('Van'),
                          ),
                          DropdownMenuItem(
                            value: 'Pickup',
                            child: Text('Pickup'),
                          ),
                          DropdownMenuItem(
                            value: 'Truck',
                            child: Text('Truck'),
                          ),
                          DropdownMenuItem(
                            value: 'Motorcycle',
                            child: Text('Motorcycle'),
                          ),
                        ],
                        onChanged: provider.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  _vehicleType = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller:
                            _vehicleInfoController,
                        enabled: !provider.isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle information',
                          hintText:
                              'Example: Hyundai Creta 2022',
                          prefixIcon: Icon(
                            Icons.car_repair_outlined,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter vehicle information';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Problem Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration:
                            const InputDecoration(
                          labelText: 'Problem category',
                          prefixIcon: Icon(
                            Icons.category_outlined,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Battery',
                            child: Text('Battery'),
                          ),
                          DropdownMenuItem(
                            value: 'Tyre',
                            child: Text('Tyre'),
                          ),
                          DropdownMenuItem(
                            value: 'Engine',
                            child: Text('Engine'),
                          ),
                          DropdownMenuItem(
                            value: 'Electrical',
                            child: Text('Electrical'),
                          ),
                          DropdownMenuItem(
                            value: 'General Repair',
                            child: Text('General Repair'),
                          ),
                          DropdownMenuItem(
                            value: 'Fuel',
                            child: Text('Fuel'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: provider.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  _category = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _issueController,
                        enabled: !provider.isLoading,
                        maxLines: 5,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Describe the problem',
                          hintText:
                              'Example: Vehicle is not starting and dashboard lights are blinking.',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(
                              bottom: 70,
                            ),
                            child: Icon(
                              Icons.warning_amber_outlined,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please describe the problem';
                          }

                          if (value.trim().length < 10) {
                            return 'Please provide more details';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // GPS STATUS

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(14),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'GPS location will be detected automatically.',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: provider.isLoading
                            ? null
                            : _findMechanics,
                        icon: provider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(
                                Icons.search_rounded,
                              ),
                        label: Text(
                          provider.isLoading
                              ? 'Finding Mechanics...'
                              : 'Find Nearby Mechanics',
                        ),
                      ),

                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          provider.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // =========================
            // MATCH RESULTS
            // =========================

            if (result != null) ...[
              const SizedBox(height: 24),

              Text(
                'Recommended Assistance',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                result.recommendationMethod,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 14),

              if (result.matches.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No suitable mechanics found.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please try again or select another problem category.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              ...result.matches.map(
                (mechanic) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 14),
                  child: Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 27,
                                child: const Icon(
                                  Icons.handyman_rounded,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      mechanic
                                          .mechanicName,
                                      style: Theme.of(
                                        context,
                                      )
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                          ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .star_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          mechanic.rating
                                              .toStringAsFixed(
                                            1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons
                                      .location_on_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  mechanic
                                      .distanceDisplay,
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons
                                      .schedule_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '${mechanic.estimatedEtaMinutes} min ETA',
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons
                                      .workspace_premium_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  '${mechanic.experienceYears} yrs',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // =========================
                          // REQUEST THIS MECHANIC
                          // =========================

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: provider.isLoading
                                  ? null
                                  : () async {
                                      // Capture the messenger
                                      // BEFORE the async gap.
                                      final messenger =
                                          ScaffoldMessenger.of(
                                        context,
                                      );

                                      if (provider.latitude ==
                                              null ||
                                          provider.longitude ==
                                              null) {
                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'GPS location is not available. Please find mechanics again.',
                                            ),
                                            behavior:
                                                SnackBarBehavior
                                                    .floating,
                                          ),
                                        );
                                        return;
                                      }

                                      final success =
                                          await provider
                                              .createRequest(
                                        driverName:
                                            _nameController
                                                .text
                                                .trim(),
                                        phoneNumber:
                                            _phoneController
                                                .text
                                                .trim(),
                                        vehicleType:
                                            _vehicleType,
                                        vehicleInfo:
                                            _vehicleInfoController
                                                .text
                                                .trim(),
                                        category:
                                            _category,
                                        issueDescription:
                                            _issueController
                                                .text
                                                .trim(),
                                        latitude:
                                            provider.latitude!,
                                        longitude:
                                            provider.longitude!,
                                      );

                                      if (!mounted) return;

                                      if (success) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Assistance request created with ${mechanic.mechanicName}.',
                                            ),
                                            behavior:
                                                SnackBarBehavior
                                                    .floating,
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              provider.errorMessage ??
                                                  'Failed to create assistance request.',
                                            ),
                                            behavior:
                                                SnackBarBehavior
                                                    .floating,
                                          ),
                                        );
                                      }
                                    },
                              icon: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(
                                      Icons
                                          .check_circle_outline,
                                    ),
                              label: Text(
                                provider.isLoading
                                    ? 'Creating Request...'
                                    : 'Request This Mechanic',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}