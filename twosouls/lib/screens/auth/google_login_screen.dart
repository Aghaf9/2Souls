import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';

// ---------------------------------------------------------------------------
// GoogleLoginScreen
//
// The entire login/signup entry point now — a single "Continue with
// Google" button. Replaces the old email/password LoginScreen and
// SignUpScreen forms entirely.
//
// On success:
//   - isNewUser == true  -> caller (main.dart's router) should send the
//     user into PostAuthOnboardingScreen (age gate + quiz chain) before
//     MainShell.
//   - isNewUser == false -> caller should go straight to MainShell; this
//     screen doesn't make that routing decision itself, it just reports
//     the result via onResult.
// ---------------------------------------------------------------------------

class GoogleLoginScreen extends StatefulWidget {
  final void Function(bool isNewUser) onResult;
  const GoogleLoginScreen({super.key, required this.onResult});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _continueWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
      return;
    }

    setState(() => _loading = false);
    widget.onResult(result.isNewUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              const Text(
                '2 SOULS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find something real.',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 48),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continueWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.bgDark,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Swap for a real Google "G" logo asset when
                            // one's added to assets/images — a plain
                            // icon is a placeholder for brand accuracy.
                            const Icon(
                              Icons.g_mobiledata,
                              color: AppColors.bgDark,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: AppColors.bgDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
