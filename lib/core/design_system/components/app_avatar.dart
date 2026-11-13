import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

enum AppAvatarSize { sm, md, lg, xl }

/// LearnTZ Design System 2.0 — Canonical Avatar Component
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.presetIcon,
    this.size = AppAvatarSize.md,
    this.backgroundColor,
    this.foregroundColor,
    this.isOnline,
  });

  final String? imageUrl;
  final String? initials;
  final IconData? presetIcon;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    final dimension = switch (size) {
      AppAvatarSize.sm => 28.0,
      AppAvatarSize.md => 36.0,
      AppAvatarSize.lg => 48.0,
      AppAvatarSize.xl => 64.0,
    };

    final effectiveBg = backgroundColor ?? LearnTzColors.primary50;
    final effectiveFg = foregroundColor ?? LearnTzColors.primary700;

    Widget inner;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      inner = ClipOval(
        child: Image.network(
          imageUrl!,
          width: dimension,
          height: dimension,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(dimension, effectiveFg),
        ),
      );
    } else if (presetIcon != null) {
      inner = Icon(presetIcon, size: dimension * 0.55, color: effectiveFg);
    } else if (initials != null && initials!.isNotEmpty) {
      inner = Text(
        initials!.toUpperCase(),
        style: LearnTzTypography.button.copyWith(
          color: effectiveFg,
          fontSize: dimension * 0.38,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      inner = _buildFallback(dimension, effectiveFg);
    }

    final avatarCircle = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
        border: Border.all(color: LearnTzColors.border, width: 1.0),
      ),
      child: Center(child: inner),
    );

    if (isOnline != null) {
      final dotSize = dimension * 0.28;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isOnline! ? LearnTzColors.success : LearnTzColors.neutral400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return avatarCircle;
  }

  Widget _buildFallback(double dimension, Color color) {
    return Icon(Icons.person, size: dimension * 0.6, color: color);
  }
}
