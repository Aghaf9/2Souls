import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import 'auth_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  DateTime? _dob;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.gold),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _signUp() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (_dob == null) {
      setState(() => _error = 'Please enter your date of birth.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.instance.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      name: _nameCtrl.text,
      dob: _dob!,
    );
    if (mounted)
      setState(() {
        _loading = false;
        _error = result.errorMessage;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              AuthField(controller: _nameCtrl, label: 'Full Name'),
              const SizedBox(height: 14),
              AuthField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _passwordCtrl,
                label: 'Password',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              AuthField(
                controller: _confirmCtrl,
                label: 'Confirm Password',
                obscure: true,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.panelBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.panelBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        color: AppColors.textSecondary.withOpacity(0.5),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _dob == null
                            ? 'Date of Birth'
                            : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                        style: TextStyle(
                          color: _dob == null
                              ? AppColors.textSecondary.withOpacity(0.5)
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBox(message: _error!),
              ],
              const SizedBox(height: 28),
              AuthButton(
                label: 'Create Account',
                loading: _loading,
                onTap: _signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
