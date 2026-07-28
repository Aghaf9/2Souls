import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// GoogleLoginScreen — "Continue with Google" + temp skip button for testing.
// onSkip bypasses auth entirely so the app can be tested without Firebase.

class GoogleLoginScreen extends StatefulWidget {
  final void Function(bool isNewUser) onResult;
  final VoidCallback? onSkip;
  const GoogleLoginScreen({super.key, required this.onResult, this.onSkip});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _continueWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    // TODO: wire real Google Sign-In once Firebase is configured.
    // For now show an error since AuthService.signInWithGoogle is not
    // fully set up — use the Skip button below for testing.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _loading = false;
        _error = 'Google Sign-In not configured yet. Use Skip for now.';
      });
    }
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
              Image.asset('assets/images/logo.png', width: 120, height: 120),
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
                'Find your other half.',
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
                    style: const TextStyle(color: AppColors.danger, fontSize: 12),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.bgDark))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, color: AppColors.bgDark, size: 26),
                            SizedBox(width: 8),
                            Text('Continue with Google',
                                style: TextStyle(color: AppColors.bgDark, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Temp skip button — remove before launch
              GestureDetector(
                onTap: widget.onSkip,
                child: Text(
                  'Skip for now →',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.7),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
