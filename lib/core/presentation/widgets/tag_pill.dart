import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.softBlue,
    this.foreground = AppColors.primary,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    this.borderColor,
    this.bold = false,
  });

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: fontSize,
              height: 1.35,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.compact = false});

  final int percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'خصم $percent%',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: compact ? 9.5 : 10.5,
          height: 1.35,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
