
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/theme/mechanic_theme.dart';
import '../dashboard/mechanic_dashboard_shell.dart';
import 'mechanic_register_screen.dart';

class MechanicLoginScreen extends StatefulWidget {
  const MechanicLoginScreen({super.key});

  @override
  State<MechanicLoginScreen> createState() =>
      _MechanicLoginScreenState();
}

class _MechanicLoginScreenState extends State<MechanicLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginResponse = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'username': _emailController.text.trim(),
              'password': _passwordController.text,
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (loginResponse.statusCode != 200) {
        String message = 'Login failed. Check your email and password.';

        try {
          final decoded = jsonDecode(loginResponse.body);
          if (decoded is Map && decoded['detail'] != null) {
            message = decoded['detail'].toString();
          }
        } catch (_) {
          // Keep the default error message.
        }

        _showMessage(message);
        return;
      }

      final loginData =
          jsonDecode(loginResponse.body) as Map<String, dynamic>;

      final accessToken = loginData['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        _showMessage('The server did not return an access token.');
        return;
      }

      // Verify the account and its role before opening the dashboard.
      final profileResponse = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (profileResponse.statusCode != 200) {
        _showMessage(
          'Could not verify your account. Please sign in again.',
        );
        return;
      }

      final profile =
          jsonDecode(profileResponse.body) as Map<String, dynamic>;

      final role = profile['role']?.toString().toUpperCase();

      if (role != 'MECHANIC') {
        _showMessage(
          'This account is not registered as a mechanic.',
        );
        return;
      }

      // Pass the access token to the dashboard.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MechanicDashboardShell(
            accessToken: accessToken,
          ),
        ),
      );
    } on FormatException {
      if (!mounted) return;
      _showMessage('The server returned an invalid response.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Unable to connect to the server. '
        'Check that the backend is running and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: MechanicTheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: MechanicTheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.handyman_rounded,
                          color: MechanicTheme.primary,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mechanic Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: MechanicTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to manage road assistance requests',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: MechanicTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: MechanicTheme.textSecondary,
                        ),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _handleLogin();
                        }
                      },
                      style: const TextStyle(
                        color: MechanicTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign-in button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Sign In as Partner'),
                    ),
                    const SizedBox(height: 20),

                    // Registration link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'New service provider? ',
                          style: TextStyle(
                            color: MechanicTheme.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MechanicRegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Register Workshop',
                            style: TextStyle(
                              color: MechanicTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Partnership badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: MechanicTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MechanicTheme.border,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: MechanicTheme.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Verified Partner Network • Fast Dispatch',
                              style: TextStyle(
                                fontSize: 12,
                                color: MechanicTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
