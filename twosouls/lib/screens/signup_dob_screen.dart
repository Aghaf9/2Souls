import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignupDobScreen extends StatefulWidget {
  const SignupDobScreen({super.key});

  @override
  State<SignupDobScreen> createState() => _SignupDobScreenState();
}

class _SignupDobScreenState extends State<SignupDobScreen> {
  DateTime? selectedDob;

  Future<void> pickDob() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18),
    );

    if (picked != null) {
      setState(() {
        selectedDob = picked;
      });
    }
  }

  void continueNext() {
    if (selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  String get dobText {
    if (selectedDob == null) return 'Select date of birth';

    return '${selectedDob!.day}/${selectedDob!.month}/${selectedDob!.year}';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),

                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      '2souls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'When were you born?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your date of birth helps us build better matches.',
                    style: TextStyle(
                      color: Color(0xFF9EC5FF),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  OutlinedButton.icon(
                    onPressed: pickDob,
                    icon: const Icon(
                      Icons.cake_outlined,
                      color: Color(0xFF9EC5FF),
                    ),
                    label: Text(
                      dobText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black.withAlpha(90),
                      side: const BorderSide(color: Color(0x669EC5FF)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: continueNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 20, color: Colors.white),
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