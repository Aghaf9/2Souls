import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    Navigator.pushNamed(context, '/signup-dob');
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? hidePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9EC5FF)),
        prefixIcon: Icon(icon, color: const Color(0xFF9EC5FF)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF9EC5FF),
                ),
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.black.withAlpha(90),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget socialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.black.withAlpha(80),
          side: const BorderSide(color: Color(0x669EC5FF)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/archerPic.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withAlpha(100)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 90),

                      const Text(
                        'Create your account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Start with the basics',
                        style: TextStyle(
                          color: Color(0xFF9EC5FF),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 32),

                      inputField(
                        controller: nameController,
                        label: 'Name',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      inputField(
                        controller: emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),

                      const SizedBox(height: 16),

                      inputField(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 18),

                      socialButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata,
                        onPressed: () {},
                      ),

                      const SizedBox(height: 12),

                      socialButton(
                        label: 'Continue with Meta',
                        icon: Icons.facebook,
                        onPressed: () {},
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(color: Color(0xFF9EC5FF)),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}