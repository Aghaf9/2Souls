import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.6),
          fontSize: 13,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.panelBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.7)),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const AuthButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE05B5B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE05B5B).withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFE05B5B), fontSize: 13),
      ),
    );
  }
}
