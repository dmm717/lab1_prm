import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Custom Brand Logo Widget for PaperChat AI
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBadgeBorder;

  const AppLogo({
    super.key,
    this.size = 28,
    this.showBadgeBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        color: AppTheme.surface,
        border: showBadgeBorder
            ? Border.all(color: AppTheme.border, width: 1)
            : null,
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Padding(
          padding: const EdgeInsets.all(2.5),
          child: Image.asset(
            'assets/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _FallbackLogoPainter(size: size),
          ),
        ),
      ),
    );
  }
}

class _FallbackLogoPainter extends StatelessWidget {
  final double size;
  const _FallbackLogoPainter({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
