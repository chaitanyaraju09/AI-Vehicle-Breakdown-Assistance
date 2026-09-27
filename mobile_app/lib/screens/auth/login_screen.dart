import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../driver/driver_dashboard.dart';
import '../mechanic/mechanic_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final role = authProvider.user?.role.toUpperCase();

      // =========================
      // DRIVER LOGIN
      // =========================
      if (role == 'DRIVER') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DriverDashboard(),
          ),
        );
      }

      // =========================
      // MECHANIC LOGIN
      // =========================
      else if (role == 'MECHANIC') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MechanicDashboard(),
          ),
        );
      }

      // =========================
      // UNKNOWN ROLE
      // =========================
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged in successfully as ${authProvider.user?.role}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final message = authProvider.errorMessage ?? 'Login failed.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================
                    // APP LOGO / BRANDING
                    // =========================

                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Vehicle Assistance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Smart roadside assistance, whenever you need it.',
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

                    const SizedBox(height: 40),

                    // =========================
                    // LOGIN CARD
                    // =========================

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Sign in to request vehicle assistance.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),

                            const SizedBox(height: 28),

                            // =========================
                            // EMAIL
                            // =========================

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // =========================
                            // PASSWORD
                            // =========================

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!authProvider.isLoading) {
                                  _login();
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
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

                            const SizedBox(height: 28),

                            // =========================
                            // LOGIN BUTTON
                            // =========================

                            ElevatedButton(
                              onPressed:
                                  authProvider.isLoading ? null : _login,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // REGISTER
                    // =========================

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: const Text('Create account'),
                        ),
                      ],
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