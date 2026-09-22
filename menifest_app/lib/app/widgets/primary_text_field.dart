import 'package:flutter/material.dart';
import '../../core/common/core.dart';

/// Shared "pill" input used across auth/security/profile screens — hint
/// style, fill color, corner radius, and the error-state border used to
/// live copy-pasted in every screen's own [InputDecoration]; they now stay
/// in sync here instead.
class PrimaryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool hasError;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color fillColor;
  final Color errorColor;
  final double borderRadius;
  final TextStyle? style;

  const PrimaryTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.hasError = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.fillColor = AppColors.surfaceVeryLight,
    this.errorColor = AppColors.errorRed,
    this.borderRadius = 16,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: style ?? AppTextStyles.bodyMedium.copyWith(color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: fillColor,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(
            color: hasError ? errorColor : AppColors.transparent,
            width: 1.5.w,
          ),
        ),
      ),
    );
  }
}
