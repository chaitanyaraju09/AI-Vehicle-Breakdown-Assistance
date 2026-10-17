
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/theme/mechanic_theme.dart';

class MechanicRegisterScreen extends StatefulWidget {
  const MechanicRegisterScreen({super.key});

  @override
  State<MechanicRegisterScreen> createState() =>
      _MechanicRegisterScreenState();
}

class _MechanicRegisterScreenState
    extends State<MechanicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _experienceController = TextEditingController(text: '3');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final List<String> _availableCategories = [
    'Engine',
    'Battery',
    'Tyre',
    'Brake',
    'Electrical',
    'Towing',
    'Cooling',
    'Lockout',
    'General Repair',
  ];

  final Set<String> _selectedCategories = {
    'General Repair',
    'Battery',
    'Tyre',
  };

  final List<String> _availableVehicles = [
    'Car',
    'SUV',
    'Bike',
    'Scooter',
    'Van',
    'Commercial Vehicle',
    'Truck',
  ];

  final Set<String> _selectedVehicles = {'Car', 'SUV'};

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _experienceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];

        if (detail is String) return detail;

        return detail.toString();
      }
    } catch (_) {
      // Use the fallback message for non-JSON responses.
    }

    return 'Request failed (${response.statusCode}). Please try again.';
  }

  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? null : MechanicTheme.success,
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      _showMessage('Please select at least one service category.');
      return;
    }

    if (_selectedVehicles.isEmpty) {
      _showMessage('Please select at least one vehicle type.');
      return;
    }

    final latitude =
        double.tryParse(_latitudeController.text.trim());
    final longitude =
        double.tryParse(_longitudeController.text.trim());

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _showMessage(
        'Please enter valid latitude and longitude coordinates.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseUrl = AppConfig.apiBaseUrl;

      // STEP 1: Create the mechanic user account.
      final registerResponse = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'full_name': _contactPersonController.text.trim(),
              'role': 'MECHANIC',
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (registerResponse.statusCode != 200 &&
          registerResponse.statusCode != 201) {
        _showMessage(_errorMessage(registerResponse));
        return;
      }

      // STEP 2: Log in to obtain an access token.
      // The backend OAuth2 endpoint expects form data.
      final loginResponse = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'username': _emailController.text.trim(),
              'password': _passwordController.text,
            },
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (loginResponse.statusCode != 200) {
        _showMessage(
          'Your account was created, but automatic sign-in failed. '
          'Please return to login and sign in again.',
        );
        return;
      }

      final loginData =
          jsonDecode(loginResponse.body) as Map<String, dynamic>;

      final accessToken = loginData['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        _showMessage(
          'Your account was created, but the server did not return '
          'an access token. Please sign in again.',
        );
        return;
      }

      // STEP 3: Create the mechanic profile linked to this account.
      final profileResponse = await http
          .post(
            Uri.parse('$baseUrl/mechanics/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'name': _businessNameController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'service_categories':
                  _selectedCategories.join(', '),
              'supported_vehicle_types':
                  _selectedVehicles.join(', '),
              'latitude': latitude,
              'longitude': longitude,
              'is_available': true,
              'rating': 5.0,
              'experience_years':
                  int.parse(_experienceController.text.trim()),
              'status': 'AVAILABLE',
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (profileResponse.statusCode != 200 &&
          profileResponse.statusCode != 201) {
        _showMessage(
          'Your user account was created, but the mechanic profile '
          'could not be created: ${_errorMessage(profileResponse)} '
          'Please contact support before registering again.',
        );
        return;
      }

      // STEP 4: Registration completed successfully.
      _showMessage(
        'Mechanic account and profile created successfully. '
        'Please sign in.',
        isError: false,
      );

      Navigator.of(context).pop();
    } on FormatException {
      _showMessage(
        'The server returned an invalid response. Please try again.',
      );
    } catch (_) {
      _showMessage(
        'Unable to connect to the server. Check your connection '
        'and try again. If registration already started, check '
        'whether your account was created before retrying.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double minimum,
    required double maximum,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: const TextStyle(
        color: MechanicTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: MechanicTheme.textSecondary,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }

        final number = double.tryParse(value.trim());

        if (number == null ||
            !number.isFinite ||
            number < minimum ||
            number > maximum) {
          return 'Enter a valid value ($minimum to $maximum)';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join Roadside Network',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: MechanicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register your workshop or mobile service '
                      'to receive breakdown requests.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MechanicTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Workshop name
                    TextFormField(
                      controller: _businessNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Workshop / Business Name',
                        prefixIcon: Icon(
                          Icons.storefront_outlined,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter workshop or technician name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Contact person
                    TextFormField(
                      controller: _contactPersonController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Contact Person Name',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact person name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact phone number';
                        }

                        if (value.trim().length < 8) {
                          return 'Please enter a valid phone number';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Login ID)',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter an email';
                        }

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Create Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: MechanicTheme.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: MechanicTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Experience
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Experience (Years)',
                        prefixIcon: Icon(
                          Icons.timeline_outlined,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        final years = int.tryParse(value ?? '');

                        if (years == null || years < 0 || years > 100) {
                          return 'Enter valid years of experience';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    // Workshop location
                    const Text(
                      'Workshop Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MechanicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the coordinates of your workshop or '
                      'service location. These help match nearby requests.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MechanicTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hint: 'Example: 17.3850',
                      icon: Icons.location_on_outlined,
                      minimum: -90,
                      maximum: 90,
                    ),
                    const SizedBox(height: 14),
                    _buildLocationField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hint: 'Example: 78.4867',
                      icon: Icons.map_outlined,
                      minimum: -180,
                      maximum: 180,
                    ),
                    const SizedBox(height: 22),

                    // Service categories
                    const Text(
                      'Service Categories Offered',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MechanicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCategories.map((category) {
                        final isSelected =
                            _selectedCategories.contains(category);

                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor:
                              MechanicTheme.primary.withValues(
                            alpha: 0.25,
                          ),
                          checkmarkColor: MechanicTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? MechanicTheme.primaryLight
                                : MechanicTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? MechanicTheme.primary
                                : MechanicTheme.border,
                          ),
                          onSelected: _isLoading
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // Supported vehicle types
                    const Text(
                      'Supported Vehicle Types',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MechanicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableVehicles.map((vehicle) {
                        final isSelected =
                            _selectedVehicles.contains(vehicle);

                        return FilterChip(
                          label: Text(vehicle),
                          selected: isSelected,
                          selectedColor:
                              MechanicTheme.primary.withValues(
                            alpha: 0.25,
                          ),
                          checkmarkColor: MechanicTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? MechanicTheme.primaryLight
                                : MechanicTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? MechanicTheme.primary
                                : MechanicTheme.border,
                          ),
                          onSelected: _isLoading
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedVehicles.add(vehicle);
                                    } else {
                                      _selectedVehicles.remove(vehicle);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    FilledButton(
                      onPressed:
                          _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Complete Partner Registration',
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
