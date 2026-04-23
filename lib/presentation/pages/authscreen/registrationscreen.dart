import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_event.dart';
import 'package:messenger_app/bloc/registration/registration_state.dart';
import 'package:messenger_app/presentation/pages/authscreen/loginscreen.dart';

class Registrationscreen extends StatefulWidget {
  const Registrationscreen({super.key});

  @override
  State<Registrationscreen> createState() => _RegistrationscreenState();
}

class _RegistrationscreenState extends State<Registrationscreen> {
  final _unameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // Helper to validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _onSignUpPressed() {
    final email = _emailController.text.trim();
    final uname = _unameController.text.trim();
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;

    // 1. Check for empty fields
    if (email.isEmpty || uname.isEmpty || pass.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    // 2. Validate Email format
    if (!_isValidEmail(email)) {
      _showError("Please enter a valid email address");
      return;
    }

    // 3. Check if passwords match
    if (pass != confirmPass) {
      _showError("Passwords do not match");
      return;
    }

    // 4. Trigger BLoC event
    context.read<RegistrationBloc>().add(
      RegistrationSubmitted(username: uname, email: email, password: pass),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _unameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration Successful! Login now'),
              ),
            );
            // Navigate to Login after success
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildWelcomeText(),
                  const SizedBox(height: 40),

                  // Fields
                  _buildTextField(
                    controller: _emailController,
                    hintText: "Email",
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _unameController,
                    hintText: "Name",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passController,
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _confirmPassController,
                    hintText: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  const SizedBox(height: 24),

                  // Register Button
                  _buildRegisterButton(state),

                  const SizedBox(height: 40),
                  _buildDivider(),
                  const SizedBox(height: 30),
                  _buildSocialButtons(),
                  const SizedBox(height: 40),
                  _buildFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildRegisterButton(RegistrationState state) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF005BC4), Color(0xFF62A1FF)],
        ),
      ),
      child: ElevatedButton(
        onPressed: state is RegistrationLoading ? null : _onSignUpPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: state is RegistrationLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFEDF1F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Helper widgets for Header, Divider, etc. (kept simple for brevity)
  Widget _buildHeader() => Row(
    children: [
      const Icon(Icons.cloud, color: Color(0xFF005BC4)),
      const SizedBox(width: 10),
      const Text(
        "Cirrus Blue",
        style: TextStyle(color: Color(0xFF005BC4), fontWeight: FontWeight.bold),
      ),
    ],
  );
  Widget _buildWelcomeText() => const Center(
    child: Column(
      children: [
        Text(
          "Join Now",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text("Dive into Cirrus Blue.", textAlign: TextAlign.center),
      ],
    ),
  );
  Widget _buildDivider() => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text("OR CONTINUE WITH"),
      ),
      Expanded(child: Divider()),
    ],
  );
  Widget _buildSocialButtons() => Row(
    children: [
      Expanded(child: _buildSocialButton("Google", Icons.g_mobiledata)),
      const SizedBox(width: 16),
      Expanded(child: _buildSocialButton("Apple", Icons.apple)),
    ],
  );
  Widget _buildFooter() => Center(
    child: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Text(
        "Already have an account? Log In",
        style: TextStyle(color: Color(0xFF005BC4), fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _buildSocialButton(String label, IconData icon) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEDF1F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}
