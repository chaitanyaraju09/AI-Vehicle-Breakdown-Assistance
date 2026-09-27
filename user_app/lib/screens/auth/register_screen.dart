import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: 'DRIVER',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully. Please sign in.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    } else {
      final message =
          authProvider.errorMessage ??
          'Registration failed.';

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
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              child: Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 34,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          'Create your account',
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
                          'Get fast and smart roadside assistance.',
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

                        const SizedBox(height: 28),

                        // FULL NAME
                        TextFormField(
                          controller: _nameController,
                          textCapitalization:
                              TextCapitalization.words,
                          textInputAction:
                              TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(
                              Icons.person_outline,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your name';
                            }

                            if (value.trim().length < 2) {
                              return 'Please enter a valid name';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // EMAIL
                        TextFormField(
                          controller: _emailController,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction:
                              TextInputAction.next,
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

                            if (!value.contains('@') ||
                                !value.contains('.')) {
                              return 'Please enter a valid email';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction:
                              TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Create a password',
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
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Please enter a password';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // CONFIRM PASSWORD
                        TextFormField(
                          controller:
                              _confirmPasswordController,
                          obscureText:
                              _obscureConfirmPassword,
                          textInputAction:
                              TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!authProvider.isLoading) {
                              _register();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_reset_outlined,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Please confirm your password';
                            }

                            if (value !=
                                _passwordController.text) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // REGISTER BUTTON
                        ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _register,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LoginScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Already have an account? Sign in',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}