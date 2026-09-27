import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
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

      if (role == 'DRIVER') {
        Navigator.of(context).pushReplacementNamed('/premium');
      } else if (role == 'MECHANIC') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MechanicDashboard(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged in successfully as ${authProvider.user?.role}.',
            ),
          ),
        );
      }
    } else {
      final message = authProvider.errorMessage ?? 'Login failed.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Premium ambient glow — top right.
          Positioned(
            top: -140,
            right: -100,
            child: _glowCircle(
              size: 330,
              color: AppColors.primary,
            ),
          ),

          // Premium ambient glow — bottom left.
          Positioned(
            bottom: -180,
            left: -130,
            child: _glowCircle(
              size: 360,
              color: AppColors.cyan,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 460,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: 34),
                        _buildLoginCard(authProvider),
                        const SizedBox(height: 22),
                        _buildRegisterPrompt(authProvider),
                        const SizedBox(height: 28),
                        _buildSecurityNote(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 120,
              spreadRadius: 35,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.cyan,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'VehicleAssist',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Smart roadside assistance',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to access your vehicle assistance dashboard.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 25),

          // Email
          const Text(
            'Email address',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }

              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }

              return null;
            },
          ),

          const SizedBox(height: 17),

          // Password
          const Text(
            'Password',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
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

          const SizedBox(height: 24),

          // Sign in button
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.cyan,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 9),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterPrompt(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account?",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          TextButton(
            onPressed: authProvider.isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
            child: const Text(
              'Create account',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15,
          color: AppColors.success,
        ),
        SizedBox(width: 7),
        Text(
          'Secure authentication',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
