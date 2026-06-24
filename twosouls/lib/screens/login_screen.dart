import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
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
            child: Container(
              color: Colors.black.withAlpha(90),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),


                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: const Text(
                      '2souls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                  ),
              ),


                  const SizedBox(height: 8),

                  const Text(
                    'Find the soul that matches yours',
                    style: TextStyle(
                      color: Color(0xFF9EC5FF),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 36),

                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Color(0xFF9EC5FF)),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF9EC5FF),
                      ),
                      filled: true,
                      fillColor: Colors.black.withAlpha(90),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFF9EC5FF)),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF9EC5FF),
                      ),
                      suffixIcon: IconButton(
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
                      ),
                      filled: true,
                      fillColor: Colors.black.withAlpha(90),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
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
                      Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: Color(0xFF9EC5FF)),
                    ),
                  ),
              

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}