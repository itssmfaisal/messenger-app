import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_event.dart';
import 'package:messenger_app/bloc/registration/registration_state.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/core/app_text_styles.dart';
import 'package:messenger_app/presentation/pages/authscreen/loginscreen.dart';
import 'package:messenger_app/presentation/widgets/app_brand_header.dart';
import 'package:messenger_app/presentation/widgets/app_text_field.dart';
import 'package:messenger_app/presentation/widgets/gradient_button.dart';
import 'package:messenger_app/presentation/widgets/or_divider.dart';
import 'package:messenger_app/presentation/widgets/social_button.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _onSignUpPressed() {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    context.read<RegistrationBloc>().add(
          RegistrationSubmitted(
            username: username,
            email: email,
            password: password,
          ),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful! Login now')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else if (state is RegistrationError) {
            _showError(state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const AppBrandHeader(),
                  const SizedBox(height: 60),
                  const Center(
                    child: Column(
                      children: [
                        Text("Join Now", style: AppTextStyles.headline),
                        Text("Dive into Cirrus Blue.", textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _emailController,
                    hintText: "Email",
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _usernameController,
                    hintText: "Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmPasswordController,
                    hintText: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: "Sign Up",
                    icon: Icons.arrow_forward,
                    isLoading: state is RegistrationLoading,
                    onPressed: _onSignUpPressed,
                  ),
                  const SizedBox(height: 40),
                  const OrDivider(),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: SocialButton(
                          label: "Google",
                          icon: Icons.g_mobiledata,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SocialButton(
                          label: "Apple",
                          icon: Icons.apple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Already have an account? Log In",
                        style: AppTextStyles.link,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
