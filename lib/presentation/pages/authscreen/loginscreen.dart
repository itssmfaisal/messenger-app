import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/login/login_bloc.dart';
import 'package:messenger_app/bloc/login/login_event.dart';
import 'package:messenger_app/bloc/login/login_state.dart';
import 'package:messenger_app/core/app_colors.dart';
import 'package:messenger_app/core/app_constants.dart';
import 'package:messenger_app/core/app_text_styles.dart';
import 'package:messenger_app/presentation/pages/main_wrapper/main_wrapper_page.dart';
import 'package:messenger_app/presentation/pages/authscreen/registration_screen.dart';
import 'package:messenger_app/presentation/widgets/app_brand_header.dart';
import 'package:messenger_app/presentation/widgets/app_text_field.dart';
import 'package:messenger_app/presentation/widgets/gradient_button.dart';
import 'package:messenger_app/presentation/widgets/or_divider.dart';
import 'package:messenger_app/presentation/widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainWrapperPage()),
            );
          } else if (state is LoginError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
                    child: Text(
                      "Welcome back",
                      style: AppTextStyles.headline,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppTextField(
                    controller: _usernameController,
                    hintText: "Username",
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Password?",
                        style: AppTextStyles.link,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: "Log In",
                    icon: Icons.arrow_forward,
                    isLoading: state is LoginLoading,
                    onPressed: () {
                      context.read<LoginBloc>().add(
                            LoginSubmitted(
                              _usernameController.text,
                              _passwordController.text,
                            ),
                          );
                    },
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("New to the conversation? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Create an account",
                            style: AppTextStyles.link,
                          ),
                        ),
                      ],
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
