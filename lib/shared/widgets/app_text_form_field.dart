import 'package:flutter/material.dart';

import '../../core/design_system/components/app_text_field.dart';

/// Backwards-compatible wrapper around canonical AppTextField
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.label,
    super.key,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      validator: validator,
      obscureText: obscureText,
    );
  }
}
