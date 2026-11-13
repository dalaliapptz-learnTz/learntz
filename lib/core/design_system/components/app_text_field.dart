import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// LearnTZ Design System 2.0 — Canonical Text Form Field
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword ? true : widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.isPassword) {
      effectiveSuffix = IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: LearnTzColors.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _isObscured = !_isObscured),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: LearnTzTypography.bodyRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: LearnTzColors.textPrimary,
            ),
          ),
          const SizedBox(height: LearnTzSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          enabled: widget.enabled,
          style: LearnTzTypography.bodyRegular.copyWith(
            color: widget.enabled ? LearnTzColors.textPrimary : LearnTzColors.neutral400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textSecondary.withValues(alpha: 0.7),
            ),
            helperText: widget.helperText,
            helperStyle: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: LearnTzColors.textSecondary)
                : null,
            suffixIcon: effectiveSuffix,
            filled: true,
            fillColor: widget.enabled ? Colors.white : LearnTzColors.neutral100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: LearnTzRadii.borderMd,
              borderSide: const BorderSide(color: LearnTzColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: LearnTzRadii.borderMd,
              borderSide: const BorderSide(color: LearnTzColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: LearnTzRadii.borderMd,
              borderSide: const BorderSide(color: LearnTzColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: LearnTzRadii.borderMd,
              borderSide: const BorderSide(color: LearnTzColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: LearnTzRadii.borderMd,
              borderSide: const BorderSide(color: LearnTzColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
