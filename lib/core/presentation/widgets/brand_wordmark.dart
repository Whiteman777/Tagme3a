import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.size = 24,
    this.color = AppColors.ink,
    this.tagline = true,
    this.taglineColor = AppColors.muted,
    this.alignment = CrossAxisAlignment.end,
  });

  final double size;
  final Color color;
  final bool tagline;
  final Color taglineColor;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تجميعة',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: size,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: size * 0.22,
              height: size * 0.22,
              margin: EdgeInsets.only(top: size * 0.08),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        if (tagline) ...[
          const SizedBox(height: 2),
          Text(
            'ابنِ أذكى. اشتري أوفر.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: size * 0.36,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: taglineColor,
            ),
          ),
        ],
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 52,
    this.background,
    this.foreground,
  });

  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.memory_rounded,
            size: size * 0.5,
            color: foreground ?? Colors.white,
          ),
          PositionedDirectional(
            top: size * 0.16,
            end: size * 0.16,
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
